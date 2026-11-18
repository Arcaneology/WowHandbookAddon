local ADDON_NAME, ns = ...
local L = ns.L

-- 专业工作台：打开游戏专业窗口时贴在右侧，针对窗口里打开的那个专业回答三件事——
--   冲级路线：按拍卖行与商人价格算出的最省路线（Core/LevelingPlan.lua），成品按流通性估回收；
--             有攻略的专业可以换成手册路线（wowhandbook.com 专业攻略的固定顺序，不看价格，只按现在的价格计价）；
--             可选是否计入回收、是否买图纸；附魔可以逐个勾选哪些接代工（客人出材料）；
--             顶上四个数字（材料、图纸、回收、净花费），下面分段：步骤、要自己做的材料、要买的图纸、购物清单、
--             成品去向，每段标题可点击收起；
--   图纸：还没学的配方要多少技能、从哪来（训练师 / 商人 / 掉落 / 任务）、商人价与拍卖价，点一行在地图上标出商人；
--   利润：按现在的价格，做哪个最赚（材料成本、卖出能拿到的钱、利润、利润率、好不好卖），点表头排序。
-- 三个视图里的行都能点开看明细：每种材料的数量、单价与来源，成品的拍卖价、卖店价与流通判断的依据。
-- 可拖动、记住相对位置、右键复位，可收起成一个小按钮。主窗口 /wh 不再重复放这些内容。
-- 数据：Data/Recipes.lua（tools/export_recipe_data.py 从网站导出）；配方名称、图标运行时向客户端取。
-- 已学配方：IsPlayerSpell，加上打开专业窗口时读到的（本次登录内有效，不存档）。
-- 设置存在模块设置里：panel（视图、收起、位置）、route（冲级路线选项）、profit（利润视图选项）。
-- 关闭模块后不注册事件、不建界面；已挂在专业窗口上的 OnShow / OnHide 钩子取消不了，只在模块开启时做事。

local Module = ns:NewModule("Workbench", {})
local UI, Theme = ns.UI, ns.Theme
local Prices = ns.Prices

local Recipes = Module -- 供测试使用（ns.modules.Workbench）

-- 暴雪专业窗口的框架名与所在的按需加载插件（Forever 为 ProfessionsFrame，经典旧世为 TradeSkillFrame / CraftFrame）
local WINDOWS = {
    { frame = "ProfessionsFrame", addon = "Blizzard_Professions" },
    { frame = "TradeSkillFrame", addon = "Blizzard_TradeSkillUI" },
    { frame = "CraftFrame", addon = "Blizzard_CraftUI" },
}

local function Color(text, name)
    return Theme:Color(text, name)
end

local function Settings(key, defaults)
    local store = ns:GetModuleSettings(Module)
    store[key] = store[key] or {}
    local settings = store[key]
    for k, v in pairs(defaults or {}) do
        if settings[k] == nil then
            settings[k] = v
        end
    end
    return settings
end

local function Name(names)
    if type(names) ~= "table" then
        return names
    end
    return names[ns.locale] or names.enUS
end

local function ItemLink(itemID)
    local _, link = C_Item.GetItemInfo(itemID)
    if not link and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return link or ("#" .. itemID)
end

local function Professions()
    return ns.Data.recipes or {}
end

-- 玩家已学的专业：{ [slug] = { rank, max } }。Forever 用 GetProfessions / GetProfessionInfo 按技能线 ID 对照，
-- 名字兜底；经典旧世客户端读技能列表
local function LearnedSkills()
    local learned, byLine, byName = {}, {}, {}
    for _, profession in ipairs(Professions()) do
        for _, line in ipairs(profession.skillLines or {}) do
            byLine[line] = profession.slug
        end
        for _, name in pairs(profession.name or {}) do
            byName[name:lower()] = profession.slug
        end
    end
    if GetProfessions and GetProfessionInfo then
        for _, index in pairs({ GetProfessions() }) do
            local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
            local slug = byLine[skillLine] or (type(name) == "string" and byName[name:lower()])
            if slug then
                learned[slug] = { rank = rank or 0, max = maxRank or 0 }
            end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        for index = 1, GetNumSkillLines() or 0 do
            local name, header, _, rank, _, _, maxRank = GetSkillLineInfo(index)
            local slug = not header and type(name) == "string" and byName[name:lower()]
            if slug and not learned[slug] then
                learned[slug] = { rank = rank or 0, max = maxRank or 0 }
            end
        end
    end
    return learned
end
Recipes.LearnedSkills = LearnedSkills

--------------------------------------------------------------------------------
-- 配方：名称、图标、已学、难度
--------------------------------------------------------------------------------

local function RecipeName(recipe)
    return C_Spell.GetSpellName(recipe.id) or ("#" .. recipe.id)
end

-- 有成品的用成品物品图标（与游戏专业窗口一致），附魔等没有成品的用技能图标
local function RecipeIcon(recipe)
    local icon = recipe.makes and C_Item.GetItemIconByID(recipe.makes)
        or C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(recipe.id)
    return icon and ("|T%s:16:16:0:0:64:64:5:59:5:59|t "):format(icon) or ""
end
Recipes.RecipeIcon = RecipeIcon

-- 本次登录内读到的已学配方：新版接口按配方 ID，旧版按配方名（小写）
local knownIDs, knownNames = {}, {}
local function RecordKnownRecipes()
    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo then
        for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
            local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
            if info and info.learned then
                knownIDs[recipeID] = true
            end
        end
    end
    if GetNumTradeSkills and GetTradeSkillInfo then
        for index = 1, GetNumTradeSkills() or 0 do
            local name, kind = GetTradeSkillInfo(index)
            if name and kind ~= "header" and kind ~= "subheader" then
                knownNames[name:lower()] = true
            end
        end
    end
    if GetNumCrafts and GetCraftInfo then
        for index = 1, GetNumCrafts() or 0 do
            local name, _, kind = GetCraftInfo(index)
            if name and kind ~= "header" then
                knownNames[name:lower()] = true
            end
        end
    end
end
Recipes.RecordKnownRecipes = RecordKnownRecipes

local function KnownRecipe(recipe)
    if (IsPlayerSpell and IsPlayerSpell(recipe.id)) or knownIDs[recipe.id] then
        return true
    end
    local name = C_Spell.GetSpellName(recipe.id)
    return name and knownNames[name:lower()] or false
end
Recipes.KnownRecipe = KnownRecipe

-- 按当前技能的难度：还没到变黄点是橙色（每次必涨），到变绿点前黄色，到变灰点前绿色，之后灰色
local function Difficulty(recipe, skill)
    local points = recipe.skill
    if not (points and skill) then
        return nil
    end
    if skill.rank < points[1] then
        return "skillOrange"
    elseif skill.rank < points[2] then
        return "skillYellow"
    elseif skill.rank < points[3] then
        return "skillGreen"
    end
    return "skillGray"
end
Recipes.Difficulty = Difficulty

-- 配方提示：游戏的技能提示（含材料），另加三档技能点与学习来源
local function ShowRecipeTooltip(owner, recipe)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(recipe.id)
    if recipe.skill then
        GameTooltip:AddLine((L["Yellow at %d, green at %d, gray at %d"]):format(recipe.skill[1], recipe.skill[2],
            recipe.skill[3]), 1, 1, 1)
    end
    if recipe.learn then
        GameTooltip:AddLine((L["Needs skill %d to learn"]):format(recipe.learn), 1, 1, 1)
    end
    if recipe.learnedFrom then
        GameTooltip:AddLine((L["Learned from %s"]):format(ItemLink(recipe.learnedFrom)), 0.85, 0.8, 0.69)
    end
    GameTooltip:Show()
end

--------------------------------------------------------------------------------
-- 工作台的表格（表头、分组标题、数据行；隔行底色）
--------------------------------------------------------------------------------

local bench, tab
local STRATA_ABOVE = { BACKGROUND = "LOW", LOW = "MEDIUM", MEDIUM = "HIGH", HIGH = "DIALOG", DIALOG = "FULLSCREEN",
    FULLSCREEN = "FULLSCREEN_DIALOG", FULLSCREEN_DIALOG = "TOOLTIP" }
local Refresh
local deferred = false -- 战斗中没算的路线，脱战后补上
local ROW_HEIGHT = 22
local CELLS = { "a", "b", "c", "d", "e", "f" }
local COLUMNS = {
    route = {
        { key = "a", label = "Skill", width = 90 },
        { key = "b", label = "Recipe", width = 290 },
        { key = "c", label = "Crafts", width = 70 },
        { key = "d", label = "Materials", width = 110 },
        { key = "e", label = "Resale" },
    },
    pick = {
        { key = "a", label = "Free at skill", width = 110 },
        { key = "b", label = "Enchant", width = 330 },
        { key = "c", label = "Materials per cast", width = 150 },
        { key = "d", label = "" },
    },
    list = {
        { key = "a", label = "Item", width = 380 },
        { key = "b", label = "Count", width = 70 },
        { key = "c", label = "Cost" },
    },
    sources = {
        { key = "a", label = "Skill to learn", width = 80 },
        { key = "b", label = "Recipe", width = 280 },
        { key = "c", label = "Source", width = 160 },
        { key = "d", label = "Price" },
    },
    profit = {
        { key = "a", label = "Recipe", width = 260, sort = "name" },
        { key = "b", label = "Cost", width = 90, sort = "cost" },
        { key = "c", label = "Sells for", width = 90, sort = "value" },
        { key = "d", label = "Profit", width = 100, sort = "profit" },
        { key = "e", label = "Margin", width = 70, sort = "margin" },
        { key = "f", label = "Sells", sort = "tier" },
    },
}
local HEADING = { { key = "a" } }

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(unpack(Theme.colors.stripe))
    row.highlight = row:CreateTexture(nil, "BORDER")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(unpack(Theme.colors.raised))
    row.highlight:Hide()
    row.cells, row.sorters = {}, {}
    for _, key in ipairs(CELLS) do
        local cell = UI:Text(row, "Small")
        cell:SetJustifyH("LEFT")
        cell:SetWordWrap(false)
        row.cells[key] = cell
    end
    row:SetScript("OnEnter", function(self)
        self.highlight:Show()
        if self.recipe then
            ShowRecipeTooltip(self, self.recipe)
        elseif self.item then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.item)
            GameTooltip:Show()
        end
        if self.spot and GameTooltip:IsShown() then
            GameTooltip:AddLine(L["Click to mark the vendor on the map"], 0.27, 0.75, 0.45)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        GameTooltip_Hide()
    end)
    -- Shift 点击：把成品链接发到聊天框；有商人位置的明细行点击在地图上标出；带 onClick 的行（分段标题、
    -- 勾选行、操作行）调用它；其余的行点击展开或收起明细
    row:SetScript("OnClick", function(self)
        local recipe = self.recipe
        if recipe and recipe.makes and IsModifiedClick and IsModifiedClick("CHATLINK") then
            local _, link = C_Item.GetItemInfo(recipe.makes)
            if link and ChatEdit_InsertLink then
                ChatEdit_InsertLink(link)
            end
        elseif self.spot then
            ns.Waypoints:ShowOnMap(self.spot[1], self.spot[2], self.spot[3], self.spot.title)
        elseif self.onClick then
            self.onClick()
        elseif self.key then
            bench.expanded[self.key] = not bench.expanded[self.key] or nil
            Refresh()
        end
    end)
    return row
end

-- 表头上的排序按钮：盖在表头单元格上，点击按这一列排序（再点一次反过来）
local function Sorter(row, key)
    local button = row.sorters[key]
    if not button then
        button = CreateFrame("Button", nil, row)
        button:SetScript("OnClick", function(self)
            if self.onSort then
                self.onSort(self.sortKey)
            end
        end)
        row.sorters[key] = button
    end
    return button
end

-- 行首的勾选框（与 UI:Checkbox 同样的画法）：row.check 为 true / false 时显示，nil 时隐藏
local function RowCheck(row)
    if row.check == nil then
        if row.box then
            row.box:Hide()
        end
        return
    end
    if not row.box then
        row.box = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.box:SetSize(14, 14)
        row.box:SetPoint("LEFT", 8, 0)
        Theme:Skin(row.box, "panel", "line")
        row.box.mark = row.box:CreateTexture(nil, "OVERLAY")
        row.box.mark:SetPoint("TOPLEFT", 3, -3)
        row.box.mark:SetPoint("BOTTOMRIGHT", -3, 3)
        row.box.mark:SetColorTexture(unpack(Theme.colors.gold))
    end
    row.box:Show()
    row.box.mark:SetShown(row.check)
end

-- 按列宽摆放单元格；没有宽度的列占到行尾
local function LayoutRow(row, columns, onSort)
    for _, cell in pairs(row.cells) do
        cell:Hide()
    end
    for _, button in pairs(row.sorters) do
        button:Hide()
    end
    RowCheck(row)
    local x = row.check ~= nil and 30 or 8
    for index, column in ipairs(columns) do
        local cell = row.cells[column.key]
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", x, 0)
        if column.width and index < #columns then
            cell:SetWidth(column.width - 8)
            x = x + column.width
        else
            cell:SetPoint("RIGHT", -8, 0)
        end
        cell:Show()
        if onSort and column.sort then
            local button = Sorter(row, column.key)
            button.sortKey, button.onSort = column.sort, onSort
            button:SetAllPoints(cell)
            button:Show()
        end
    end
end

local function Table()
    local child = bench.detail.child
    local rows, used, y = bench.rows, 0, 0
    local t = {}

    local function NextRow(recipe, key, spot, item)
        used = used + 1
        local row = rows[used] or CreateRow(child)
        rows[used] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
        row:Show()
        row.recipe, row.key, row.spot, row.item = recipe, key, spot, item
        row.onClick, row.check = nil, nil
        row:EnableMouse((recipe or key or spot or item) and true or false)
        y = y + ROW_HEIGHT
        return row
    end

    local function Fill(row, columns, cells, striped, onSort)
        row.stripe:SetShown(striped and true or false)
        for _, column in ipairs(columns) do
            row.cells[column.key]:SetText(cells[column.key] or "")
        end
        LayoutRow(row, columns, onSort)
    end

    -- sort = { key, descending }：当前排序的那一列标上箭头；onSort(列的排序键) 在点击表头时调用
    function t:Header(columns, sort, onSort)
        local cells = {}
        for _, column in ipairs(columns) do
            local label = L[column.label]
            if sort and column.sort == sort[1] then
                label = label .. (sort[2] and " v" or " ^")
            end
            cells[column.key] = Color(label, "gold")
        end
        Fill(NextRow(nil), columns, cells, false, onSort)
    end

    function t:Heading(text, gapBefore)
        y = y + (gapBefore or 0)
        Fill(NextRow(nil), HEADING, { a = text })
    end

    -- 数据行：key 不为空时可点击展开，第一列前面带 + / -；返回是否已展开。item 用于没有配方的行的鼠标提示
    function t:Row(columns, recipe, cells, striped, key, item)
        local open = key and bench.expanded[key] or false
        if key then
            local first = columns[1].key
            cells[first] = Color(open and "- " or "+ ", "muted") .. (cells[first] or "")
        end
        Fill(NextRow(recipe, key, nil, item), columns, cells, striped)
        return open
    end

    -- 展开后的明细行：缩进的一整行文字；spot = { 地图, x, y, title = 名字 } 时点击在地图上标出
    function t:Detail(text, spot)
        Fill(NextRow(nil, nil, spot), HEADING, { a = "        " .. text })
    end

    -- 分段标题：点击收起或展开这一段（默认展开，closed 为真时默认收起）；返回是否展开。
    -- bench.collapsed[key]：true 收起、false 展开、nil 按默认
    function t:Section(title, key, gapBefore, closed)
        y = y + (gapBefore or 0)
        local state = bench.collapsed[key]
        local open
        if state == nil then
            open = not closed
        else
            open = not state
        end
        local row = NextRow(nil)
        row.onClick = function()
            bench.collapsed[key] = open
            Refresh()
        end
        row:EnableMouse(true)
        Fill(row, HEADING, { a = Color(open and "- " or "+ ", "muted") .. Color(title, "gold") })
        return open
    end

    -- 带勾选框的行：点击调用 onClick
    function t:Check(columns, recipe, cells, striped, checked, onClick)
        local row = NextRow(recipe)
        row.onClick, row.check = onClick, checked and true or false
        row:EnableMouse(true)
        Fill(row, columns, cells, striped)
    end

    -- 操作行：一行可点击的文字
    function t:Action(text, onClick)
        local row = NextRow(nil)
        row.onClick = onClick
        row:EnableMouse(true)
        Fill(row, HEADING, { a = Color(text, "gold") })
    end

    function t:Finish()
        for index = used + 1, #rows do
            rows[index]:Hide()
        end
        bench.detail:SetContentHeight(y + 8)
        return used
    end
    return t
end

--------------------------------------------------------------------------------
-- 冲级路线：按价格算（LevelingPlan.lua）
--------------------------------------------------------------------------------

-- commissionPicks = { [附魔的配方 ID] = true }：勾选了接代工的附魔
-- mode = "live" 按价格算的最省路线 / "handbook" 手册路线（专业有 route 数据时才能选）
local ROUTE_DEFAULTS = { recovery = true, buyRecipes = true, mode = "live", priority = "balanced" }
local Profit, ReagentCost, ProfessionOf
local TARGETS = { 75, 150, 225, 300 }
-- 物品大类（Enum.ItemClass）对应的流通档；没列出的按 mid
-- 背包（容器，大类 1）流通性很高，归 high、不设件数上限
local CLASS_TIER = { [0] = "high", [5] = "high", [6] = "high", [7] = "high", [1] = "high", [2] = "low", [4] = "low" }
local reagentItems -- 所有专业配方用到的材料：是材料的成品（布卷、锭、熟皮等）卖得动

local function Money(copper)
    copper = floor((copper or 0) + 0.5)
    if copper <= 0 then
        return "0"
    end
    return GetMoneyString and GetMoneyString(copper) or tostring(copper)
end

-- 汇总数字用：一金以上不显示铜
local function Brief(copper)
    copper = copper or 0
    if copper >= 10000 then
        copper = floor(copper / 100 + 0.5) * 100
    end
    return Money(copper)
end

local function Count(value)
    return tostring(math.ceil(value - 1e-6))
end

local function IsReagent(itemID)
    if not reagentItems then
        reagentItems = {}
        for _, profession in ipairs(Professions()) do
            for _, recipe in ipairs(profession.recipes or {}) do
                local reagents = recipe.reagents or {}
                for index = 1, #reagents, 2 do
                    reagentItems[reagents[index]] = true
                end
            end
        end
    end
    return reagentItems[itemID] or false
end

-- 成品的流通档与依据。这是按物品种类的粗略判断，不是成交数据（客户端看不到成交记录）：
--   绑定的不能卖（none）；是别的配方的材料（布卷、锭、熟皮等）算好卖（high），
--   但武器护甲兼作材料的（亚麻披风之类）只有做那个配方的人收，算居中（mid）；
--   否则按物品大类：消耗品、材料、弹药、背包好卖（high），武器护甲难卖（low），其他居中（mid）。
-- 返回 档位, 依据（"bound" / "reagent" / "gearReagent" / "class"）
local function Tier(itemID)
    local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = C_Item.GetItemInfo(itemID)
    if bindType == 1 or bindType == 4 then
        return "none", "bound"
    end
    local classID
    if C_Item.GetItemInfoInstant then
        _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
    end
    if IsReagent(itemID) then
        if classID == 2 or classID == 4 then
            return "mid", "gearReagent"
        end
        return "high", "reagent"
    end
    return CLASS_TIER[classID or -1] or "mid", "class"
end
Recipes.Tier = Tier

local function VendorSell(itemID)
    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemID)
    if sellPrice == nil and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return sellPrice
end

-- 商人卖价：本机在商人窗口记下的优先（带声望折扣），没记过的用数据里的商人价（Data/Recipes.lua 的 reagentVendorPrices）
local function VendorBuy(item)
    local recorded = Prices.Vendor(item)
    if recorded then
        return recorded
    end
    local known = ns.Data.reagentVendorPrices and ns.Data.reagentVendorPrices[item]
    if not known then
        return nil
    end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return known[faction == "Horde" and "H" or "A"]
end
Recipes.VendorBuy = VendorBuy

local function Market()
    local prices = Prices
    return {
        levels = function(item) return prices.Depth and prices.Depth(item) end,
        auction = function(item) return (prices.Auction(item)) end,
        vendorBuy = VendorBuy,
        vendorSell = VendorSell,
        tier = function(item) return (Tier(item)) end,
    }
end

local function HasCommissions(profession)
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.skill and not recipe.makes then
            return true
        end
    end
    return false
end

local function CommissionPicks()
    local settings = Settings("route", ROUTE_DEFAULTS)
    settings.commissionPicks = settings.commissionPicks or {}
    return settings.commissionPicks
end

-- 这个专业里勾选了接代工的附魔（配方 ID 列表）
local function ChosenCommissions(profession)
    local picks, chosen = CommissionPicks(), {}
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.skill and not recipe.makes and not recipe.nip and picks[recipe.id] then
            tinsert(chosen, recipe.id)
        end
    end
    return chosen
end
Recipes.ChosenCommissions = ChosenCommissions

-- 背包或银行里有没有这件工具
local function HasTool(itemID)
    local count = C_Item.GetItemCount and C_Item.GetItemCount(itemID, true)
    return (count or 0) > 0
end

-- 目标技能：没选时取当前技能之后的下一档
local function RouteTarget(settings, from)
    local target = settings.target
    if not target or target <= from then
        for _, value in ipairs(TARGETS) do
            if value > from then
                return value
            end
        end
        return TARGETS[#TARGETS]
    end
    return target
end

-- from / to 不给时按玩家技能与设置的目标；给了就算这一段（工作台用它算玩家已经走过的 1 到当前技能）
local function BuildRoute(profession, skill, from, to)
    local settings = Settings("route", ROUTE_DEFAULTS)
    from = from or (skill and skill.rank or 1)
    to = to or RouteTarget(settings, from)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return ns.LevelingPlan.Build({
        recipes = profession.recipes or {}, from = from, to = to, faction = faction == "Horde" and "H" or "A",
        known = KnownRecipe, hasTool = HasTool, market = Market(),
        fixed = settings.mode == "handbook" and profession.route or nil,
        options = { recovery = settings.recovery, buyRecipes = settings.buyRecipes, priority = settings.priority,
            commission = ChosenCommissions(profession) },
    }), from, to
end
Recipes.BuildRoute = BuildRoute

local function Destination(product)
    local parts = {}
    if product.used > 0.5 then
        tinsert(parts, (L["%s used in later steps"]):format(Count(product.used)))
    end
    if product.auction > 0.5 then
        tinsert(parts, (L["%s to the auction house"]):format(Count(product.auction)))
    end
    if product.vendor > 0.5 then
        tinsert(parts, (L["%s to a vendor"]):format(Count(product.vendor)))
    end
    return table.concat(parts, " · ")
end

local TIER_LABEL = {
    high = { "Sells well", "green" }, mid = { "Sells okay", "text" }, low = { "Slow to sell", "red" },
    none = { "Cannot be sold", "muted" },
}
local TIER_REASON = {
    bound = "it binds, so it cannot be sold",
    reagent = "other recipes use it as a material",
    gearReagent = "gear that a few recipes use as a material",
    class = "judged by the kind of item",
}

-- 明细：每种材料的数量、单价与来源、小计（crafts 为制作次数）。
-- deep 为真时（利润页）材料按 ReagentCost 计：本专业自己做更便宜的，写出自己做的单价、用到的下一层材料与买入价
local function ReagentDetails(t, recipe, crafts, deep, unlearned)
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        local item, each = reagents[index], reagents[index + 1] or 1
        local total = each * crafts
        local price, source, via, buy
        if deep then
            price, source, via, buy = ReagentCost(ProfessionOf(recipe), item, unlearned)
        else
            price, source = Prices.BuyCost(item)
        end
        if via then
            t:Detail(("%s x%s  ·  %s %s  =  %s"):format(ItemLink(item), Count(total), Money(price),
                Color(L["made yourself"], "green"), Money(price * total)))
            local made = via.count or 1
            local parts = via.reagents or {}
            for sub = 1, #parts, 2 do
                local subPrice, subSource = Prices.BuyCost(parts[sub])
                t:Detail("    " .. (L["from %s x%s at %s each, %s"]):format(ItemLink(parts[sub]),
                    Count((parts[sub + 1] or 1) / made), Money(subPrice),
                    Color(subSource == "vendor" and L["from a vendor"] or L["on the auction house"], "muted")))
            end
            t:Detail("    " .. Color(buy and (L["buying it instead: %s each"]):format(Money(buy))
                or L["cannot be bought right now"], "muted"))
        elseif price then
            t:Detail(("%s x%s  ·  %s %s  =  %s"):format(ItemLink(item), Count(total), Money(price),
                Color(source == "vendor" and L["from a vendor"] or L["on the auction house"], "muted"),
                Money(price * total)))
        else
            t:Detail(("%s x%s  ·  %s"):format(ItemLink(item), Count(total), Color(L["no price yet"], "red")))
        end
    end
end

-- 明细：回本率 = 一次制作的成品能卖的钱（拍卖价扣手续费与卖店价取高）÷ 一次制作的材料花费
local function PaybackDetail(t, recipe)
    local entry = recipe and Profit(recipe)
    if not (entry and entry.cost > 0) then
        return
    end
    local rate = entry.value / entry.cost
    t:Detail(Color((L["Payback %d%%"]):format(floor(rate * 100 + 0.5)), rate >= 1 and "green" or "gold")
        .. Color("  ·  " .. (L["materials %s per craft, the product sells for %s"]):format(Money(entry.cost),
            Money(entry.value)), "muted"))
end

-- 明细：成品卖多少钱、为什么算好卖或难卖；给了 recipe 时先列回本率
local function SaleDetails(t, itemID, recipe)
    PaybackDetail(t, recipe)
    local prices = Prices
    local auction = prices.Auction(itemID)
    local vendor = VendorSell(itemID)
    local parts = {}
    if auction then
        local listed = prices.Available and prices.Available(itemID)
        tinsert(parts, (L["auction %s"]):format(Money(auction))
            .. (listed and (" (" .. (L["%d listed"]):format(listed) .. ")") or ""))
        tinsert(parts, (L["%s after the 5%% cut"]):format(Money(auction * (1 - ns.LevelingPlan.AH_CUT))))
    else
        tinsert(parts, Color(L["no auction price yet"], "muted"))
    end
    if vendor and vendor > 0 then
        tinsert(parts, (L["vendor pays %s"]):format(Money(vendor)))
    end
    t:Detail(ItemLink(itemID) .. "  ·  " .. table.concat(parts, "  ·  "))
    local tier, reason = Tier(itemID)
    local label = TIER_LABEL[tier]
    t:Detail(Color(L[label[1]], label[2]) .. Color("  ·  " .. L[TIER_REASON[reason]], "muted"))
end

-- 一次制作的材料按现在的买入价要多少钱；有材料没价格时返回 nil
local function CastCost(recipe)
    local total = 0
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        local price = Prices.BuyCost(reagents[index])
        if not price then
            return nil
        end
        total = total + price * (reagents[index + 1] or 1)
    end
    return total
end

-- 每个专业里做出某件物品的配方：{ [专业] = { [物品 ID] = { 配方, ... } } }，配方归属哪个专业：{ [配方] = 专业 }
local makersOf, professionOf = {}, nil
function ProfessionOf(recipe)
    if not professionOf then
        professionOf = {}
        for _, profession in ipairs(Professions()) do
            for _, entry in ipairs(profession.recipes or {}) do
                professionOf[entry] = profession
            end
        end
    end
    return professionOf[recipe]
end

local function MakersOf(profession, itemID)
    local makers = makersOf[profession]
    if not makers then
        makers = {}
        for _, recipe in ipairs(profession.recipes or {}) do
            if recipe.makes and not recipe.cooldown and not recipe.nip then
                makers[recipe.makes] = makers[recipe.makes] or {}
                tinsert(makers[recipe.makes], recipe)
            end
        end
        makersOf[profession] = makers
    end
    return makers[itemID]
end

-- 一件材料的单价：买（商人价与拍卖价取低）与用本专业的配方自己做取便宜的。
-- 自己做只往下看一层：做它的材料按买入价算，不再找更下一层；只用已学的配方（unlearned 为真时没学的也算），
-- 有冷却的配方（月布等）不算。返回 单价, 来源（"vendor" / "auction" / "craft"）, 自己做时用的配方, 买入单价；
-- 买不到也做不了时单价为 nil
function ReagentCost(profession, itemID, unlearned)
    local buy, source = Prices.BuyCost(itemID)
    local best, from, via = buy, source, nil
    for _, maker in ipairs(profession and MakersOf(profession, itemID) or {}) do
        if unlearned or KnownRecipe(maker) then
            local cost = CastCost(maker)
            local unit = cost and cost / (maker.count or 1)
            if unit and (not best or unit < best) then
                best, from, via = unit, "craft", maker
            end
        end
    end
    return best, from, via, buy
end
Recipes.ReagentCost = ReagentCost

-- 这一步的明细：买了什么（数量、均价、来源、小计）、用了前面做的什么、先自己做了什么
local function StepDetails(t, step, byID)
    for _, entry in ipairs(step.bought or {}) do
        local item, count, cost = entry[1], entry[2], entry[3]
        local _, source = Prices.BuyCost(item)
        t:Detail(("%s x%s  ·  %s %s  =  %s"):format(ItemLink(item), Count(count), Money(cost / count),
            Color(source == "vendor" and L["from a vendor"] or L["on the auction house"], "muted"), Money(cost)))
    end
    for _, entry in ipairs(step.used or {}) do
        t:Detail(("%s x%s  ·  %s"):format(ItemLink(entry[1]), Count(entry[2]),
            Color(L["made in an earlier step"], "green")))
    end
    for _, entry in ipairs(step.prepared or {}) do
        local recipe = byID[entry[1]]
        if recipe then
            t:Detail((L["Make it yourself first: %s x%s"]):format(RecipeIcon(recipe) .. RecipeName(recipe),
                Count(entry[2])))
        end
    end
end

-- 路线的步骤行；prefix 区分展开状态的键（已走过的那段与当前的不混）
local function RenderSteps(t, plan, byID, prefix)
    for index, step in ipairs(plan.steps) do
        local range = ("%d-%d"):format(step.from, step.to)
        local recipe = step.recipe
        if step.gap then
            t:Row(COLUMNS.route, nil, { a = range, b = Color(L["No recipe with known prices pays here"], "muted") },
                index % 2 == 1)
        elseif step.forced or step.stock then
            -- 不为涨点做的：先做一件工具（后面的配方要它在背包里），或给后面的步骤备料
            local tool = step.forced
            local open = t:Row(COLUMNS.route, recipe, {
                a = Color(tool and L["Tool"] or L["Stock up"], "gold"),
                b = RecipeIcon(recipe) .. RecipeName(recipe), c = Count(step.crafts),
                d = step.unpriced and Color(L["no price yet"], "red") or Money(step.cash),
                e = Color(tool and L["Keep it"] or L["For later steps"], "muted"),
            }, index % 2 == 1, prefix .. index .. ":" .. recipe.id)
            if open then
                t:Detail(tool and L["Later recipes need this in your bags: make one and keep it"]
                    or L["Makes materials for the steps after it; it gives no skill"])
                StepDetails(t, step, byID)
            end
        else
            local resale = ""
            if recipe.makes and plan.options.recovery then
                local label = TIER_LABEL[(Tier(recipe.makes))]
                resale = Color(L[label[1]], label[2])
            end
            local open = t:Row(COLUMNS.route, recipe, {
                a = range,
                b = RecipeIcon(recipe)
                    .. Color(RecipeName(recipe), Difficulty(recipe, { rank = step.from }) or "text"),
                c = Count(step.crafts),
                d = step.commission and Color(L["Customer's materials"], "green")
                    or step.unpriced and Color(L["no price yet"], "red") or Money(step.cash),
                e = resale,
            }, index % 2 == 1, prefix .. step.from .. ":" .. recipe.id)
            if open then
                local first = ns.LevelingPlan.Chance(recipe, step.from)
                local last = ns.LevelingPlan.Chance(recipe, step.to - 1)
                t:Detail((L["Skill-up chance %d%% to %d%%, about %s crafts for %d points"]):format(
                    floor(first * 100 + 0.5), floor(last * 100 + 0.5), Count(step.crafts), step.to - step.from))
                if step.commission then
                    t:Detail(Color(L["Enchant other players' gear with their materials: no cost to you"], "green"))
                elseif step.unpriced then
                    ReagentDetails(t, recipe, step.crafts)
                else
                    StepDetails(t, step, byID)
                end
                if recipe.makes then
                    SaleDetails(t, recipe.makes, recipe)
                end
            end
            for _, other in ipairs(step.alternatives or {}) do
                t:Row(COLUMNS.route, other.recipe, {
                    b = "    " .. Color(L["or"], "muted") .. " " .. RecipeIcon(other.recipe)
                        .. Color(RecipeName(other.recipe), "muted"),
                }, index % 2 == 1)
            end
        end
    end
end

local function RenderRoute(t, profession, skill)
    if not (Prices and ns.LevelingPlan) then
        return { L["Price data is not available"] }, ""
    end
    if InCombatLockdown() then
        deferred = true
        return { L["The route is worked out after you leave combat"] }, ""
    end
    local plan, from, to = BuildRoute(profession, skill)
    local byID = {}
    for _, recipe in ipairs(profession.recipes or {}) do
        byID[recipe.id] = recipe
    end
    local crafted, makers = false, {} -- makers：成品是路线里哪个配方做的（成品去向里算回本率用）
    for _, step in ipairs(plan.steps) do
        crafted = crafted or not step.gap
        if step.recipe and step.recipe.makes then
            makers[step.recipe.makes] = makers[step.recipe.makes] or step.recipe
        end
    end
    plan.fixed = Settings("route", ROUTE_DEFAULTS).mode == "handbook" and profession.route ~= nil
    -- 已经走过的 1 到当前技能：按现在的价格算一遍同样的路线，默认收起，展开时才算
    if from > 1 and t:Section((L["Earlier steps, skill %d-%d"]):format(1, from), "earlier", 0, true) then
        local earlier = BuildRoute(profession, skill, 1, from)
        t:Header(COLUMNS.route)
        RenderSteps(t, earlier, byID, "earlier:")
        t:Detail(Color(L["Worked out with today's prices, for reference: these are the steps that would get you here"], "muted"))
    end
    if t:Section((L["Steps, skill %d-%d"]):format(from, to), "steps", from > 1 and 10 or 0) then
        t:Header(COLUMNS.route)
        RenderSteps(t, plan, byID, "route:")
    end
    if not crafted then
        t:Heading(Color(L["Scan the auction house or visit vendors first: material prices are needed"], "muted"), 6)
    end

    if #plan.prepared > 0 and t:Section((L["Make these materials yourself (%d)"]):format(#plan.prepared), "make", 10) then
        t:Header(COLUMNS.list)
        for index, entry in ipairs(plan.prepared) do
            local open = t:Row(COLUMNS.list, entry.recipe, {
                a = RecipeIcon(entry.recipe) .. RecipeName(entry.recipe), b = Count(entry.crafts),
            }, index % 2 == 1, "make:" .. entry.recipe.id)
            if open then
                ReagentDetails(t, entry.recipe, entry.crafts)
            end
        end
    end
    if #plan.recipesToBuy > 0
        and t:Section((L["Recipe items to buy (%d)"]):format(#plan.recipesToBuy), "recipes", 10) then
        t:Header(COLUMNS.list)
        for index, entry in ipairs(plan.recipesToBuy) do
            t:Row(COLUMNS.list, entry.recipe, {
                a = ItemLink(entry.recipe.learnedFrom),
                b = entry.source == "vendor" and L["Vendor"] or L["Auction"],
                c = Money(entry.fee),
            }, index % 2 == 1)
        end
    end
    if #plan.shopping > 0 and t:Section((L["Shopping list (%d)"]):format(#plan.shopping), "shopping", 10) then
        t:Header(COLUMNS.list)
        for index, entry in ipairs(plan.shopping) do
            local note = ""
            if entry.short then
                note = "  " .. Color((L["%s short on the auction house"]):format(Count(entry.short)), "red")
            elseif entry.unknownDepth then
                note = "  " .. Color(L["lowest price only"], "muted")
            elseif entry.vendor then
                note = "  " .. Color(L["from a vendor"], "muted")
            end
            local open = t:Row(COLUMNS.list, nil, {
                a = ItemLink(entry.item), b = Count(entry.count), c = Money(entry.cost) .. note,
            }, index % 2 == 1, "shop:" .. entry.item, entry.item)
            if open then
                local vendor = Prices.Vendor(entry.item)
                if vendor then
                    t:Detail((L["A vendor sells it for %s each, any amount"]):format(Money(vendor)))
                end
                local levels = Prices.Depth and Prices.Depth(entry.item)
                for _, level in ipairs(levels or {}) do
                    t:Detail((L["Auction house: %d at %s each"]):format(level[2], Money(level[1])))
                end
                if not levels then
                    local auction = Prices.Auction(entry.item)
                    t:Detail(auction and (L["Auction house lowest price %s; how many are listed is not known"]):format(
                        Money(auction)) or Color(L["no auction price yet"], "muted"))
                end
            end
        end
    end
    if #plan.products > 0
        and t:Section((L["What to do with what you make (%d)"]):format(#plan.products), "products", 10) then
        t:Header(COLUMNS.list)
        for index, product in ipairs(plan.products) do
            local open = t:Row(COLUMNS.list, nil, {
                a = ItemLink(product.item) .. "  " .. Color(Destination(product), "muted"),
                b = Count(product.made), c = product.value > 0 and ("+" .. Money(product.value)) or "",
            }, index % 2 == 1, "made:" .. product.item, product.item)
            if open then
                SaleDetails(t, product.item, makers[product.item])
            end
        end
    end

    local hint = L["Click a row for the cost breakdown, a section title to fold it"]
    if plan.fixed then
        hint = L["Handbook route: the guide's fixed order at today's prices"] .. " · " .. hint
    end
    if plan.unpriced > 0 then
        hint = (L["%d recipes left out: a material has no price yet"]):format(plan.unpriced) .. " · " .. hint
    end
    if plan.missing and #plan.missing > 0 then
        local ranges = {}
        for index = 1, math.min(3, #plan.missing) do
            ranges[index] = ("%d-%d"):format(plan.missing[index][1], plan.missing[index][2])
        end
        local text = (L["Not counted, no prices: skill %s"]):format(table.concat(ranges, ", "))
        if #plan.missing > 3 then
            text = text .. (L[" and %d more"]):format(#plan.missing - 3)
        end
        hint = Color(text, "red") .. " · " .. hint
    end
    return {}, hint, plan
end

-- 代工附魔的勾选表：当前技能到目标技能之间还能按代工算的附魔（学得到、还没变绿），点一行勾选或取消
local function RenderPicker(t, profession, skill)
    local settings = Settings("route", ROUTE_DEFAULTS)
    local from = skill and skill.rank or 1
    local to = RouteTarget(settings, from)
    local picks = CommissionPicks()
    -- 手册路线上只有路线里用到的附魔有意义（勾了就不论颜色都算客人出材料）
    local onRoute
    if settings.mode == "handbook" and profession.route then
        onRoute = {}
        for _, entry in ipairs(profession.route) do
            if entry.to > from and entry.from < to then
                onRoute[entry.recipe] = true
            end
        end
    end
    local list = {}
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.skill and not recipe.makes and not recipe.nip then
            local listed
            if onRoute then
                listed = onRoute[recipe.id]
            else
                listed = (recipe.learn or recipe.skill[1]) < to and recipe.skill[2] > from
            end
            if listed then
                tinsert(list, recipe)
            end
        end
    end
    table.sort(list, function(a, b)
        local la, lb = a.learn or a.skill[1], b.learn or b.skill[1]
        if la ~= lb then
            return la < lb
        end
        return a.id < b.id
    end)
    local function SetAll(value)
        for _, recipe in ipairs(list) do
            picks[recipe.id] = value
        end
        Refresh()
    end
    t:Heading(Color(L["Tick only the enchants people actually bring you materials for."], "muted"))
    t:Heading(Color(onRoute and L["On the handbook route a ticked enchant is free for all its casts."]
        or L["They count as free skill-ups while orange or yellow; every other enchant uses your own materials."],
        "muted"))
    t:Action(L["Tick all"], function() SetAll(true) end)
    t:Action(L["Clear all"], function() SetAll(nil) end)
    t:Header(COLUMNS.pick)
    local chosen = 0
    for index, recipe in ipairs(list) do
        local checked = picks[recipe.id] and true or false
        chosen = chosen + (checked and 1 or 0)
        local cost = Prices and CastCost(recipe)
        t:Check(COLUMNS.pick, recipe, {
            a = ("%d-%d"):format(math.max(from, recipe.learn or recipe.skill[1]), recipe.skill[2]),
            b = RecipeIcon(recipe) .. Color(RecipeName(recipe), Difficulty(recipe, { rank = from }) or "text"),
            c = cost and Money(cost) or Color(L["no price yet"], "muted"),
            d = KnownRecipe(recipe) and "" or Color(L["not learned"], "muted"),
        }, index % 2 == 1, checked, function()
            picks[recipe.id] = not checked or nil
            Refresh()
        end)
    end
    return { (L["Skill %d-%d"]):format(from, to), (L["%d of %d enchants ticked"]):format(chosen, #list) },
        L["Click an enchant to tick it; go back to the route to see the new cost"]
end

--------------------------------------------------------------------------------
-- 图纸：还没学的配方要多少技能、从哪来、多少钱
--------------------------------------------------------------------------------

local VIA_LABEL = { vendor = "Vendor", drop = "Drop", quest = "Quest" }

local function Side()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return faction == "Horde" and "H" or "A"
end

-- 来源文字、价格文字、商人位置
local function Source(recipe, side)
    if recipe.auto then
        return Color(L["Comes with the rank"], "muted"), ""
    elseif not recipe.learnedFrom then
        return L["Trainer"], ""
    end
    local labels = {}
    for _, via in ipairs(recipe.via or {}) do
        tinsert(labels, L[VIA_LABEL[via] or via])
    end
    local prices = {}
    local vendor = recipe.buy and recipe.buy[side]
    if vendor then
        tinsert(prices, Money(vendor))
    end
    local auction = Prices and Prices.Auction(recipe.learnedFrom)
    if auction then
        tinsert(prices, (L["auction %s"]):format(Money(auction)))
    end
    local source = #labels > 0 and table.concat(labels, " / ")
        or (auction and L["Auction"] or Color(L["Source unknown"], "muted"))
    return source, table.concat(prices, " · "), recipe.spot and recipe.spot[side]
end
Recipes.Source = Source

local function MapName(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return info and info.name or ("#" .. mapID)
end

local function SourceDetails(t, recipe, side)
    if recipe.learn then
        t:Detail((L["Needs skill %d to learn"]):format(recipe.learn))
    end
    if recipe.auto then
        t:Detail(L["Comes with the rank"])
        return
    elseif not recipe.learnedFrom then
        t:Detail(L["Taught by a profession trainer"])
        return
    end
    local item = recipe.learnedFrom
    local vendor = recipe.buy and recipe.buy[side]
    local spot = recipe.spot and recipe.spot[side]
    if vendor then
        local where = spot and ("%s %.1f, %.1f"):format(MapName(spot[1]), spot[2], spot[3]) or L["place unknown"]
        t:Detail(("%s  ·  %s %s  ·  %s"):format(ItemLink(item), L["Vendor"], Money(vendor), where),
            spot and { spot[1], spot[2], spot[3], title = RecipeName(recipe) } or nil)
    else
        t:Detail(ItemLink(item))
    end
    local auction = Prices and Prices.Auction(item)
    if auction then
        local listed = Prices.Available and Prices.Available(item)
        t:Detail((L["auction %s"]):format(Money(auction))
            .. (listed and (" (" .. (L["%d listed"]):format(listed) .. ")") or ""))
    end
    for _, via in ipairs(recipe.via or {}) do
        if via == "drop" then
            t:Detail(L["Drops from creatures: check the auction house first"])
        elseif via == "quest" then
            t:Detail(L["A quest rewards it"])
        end
    end
    if #(recipe.via or {}) == 0 and not auction then
        t:Detail(Color(L["Source unknown"], "muted"))
    end
end

local function RenderSources(t, profession, skill)
    local rank = skill and skill.rank or 0
    local side = Side()
    local now, later = {}, {}
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.skill and not recipe.nip and not KnownRecipe(recipe) then
            local learn = recipe.auto and 1 or recipe.learn
            tinsert((learn and learn <= rank) and now or later, recipe)
        end
    end
    local function Order(a, b)
        local la, lb = a.learn or 999, b.learn or 999
        if la ~= lb then
            return la < lb
        end
        return a.id < b.id
    end
    local function Section(title, list, gap)
        if #list == 0 then
            return
        end
        table.sort(list, Order)
        t:Heading(Color(title, "gold"), gap)
        t:Header(COLUMNS.sources)
        for index, recipe in ipairs(list) do
            local source, price = Source(recipe, side)
            local open = t:Row(COLUMNS.sources, recipe, {
                a = recipe.learn and tostring(recipe.learn) or Color("?", "muted"),
                b = RecipeIcon(recipe) .. Color(RecipeName(recipe), Difficulty(recipe, skill) or "text"),
                c = source, d = price,
            }, index % 2 == 1, "src:" .. recipe.id)
            if open then
                SourceDetails(t, recipe, side)
            end
        end
    end
    Section(L["You can learn these now"], now)
    Section(L["Learnable later"], later, #now > 0 and 10 or 0)
    return { (L["%d not learned · %d learnable now"]):format(#now + #later, #now) },
        L["Click a row for where to get it; click the vendor line to mark it on the map"]
end

--------------------------------------------------------------------------------
-- 利润：按现在的价格，做哪个最赚
--------------------------------------------------------------------------------

local PROFIT_ROWS = 150
local TIER_ORDER = { high = 3, mid = 2, low = 1, none = 0 }
local PROFIT_DEFAULTS = { unlearned = false, sort = "profit", descending = true }

-- 一次制作的材料成本、卖出能拿到的钱（拍卖价扣手续费与卖店价取高）、利润、利润率（利润 ÷ 成本）、流通档；
-- 材料按 ReagentCost 计（本专业能做的中间材料，买与自己做取便宜的），crafted 为其中自己做的种数；
-- 材料或成品没价格时返回 nil
function Profit(recipe)
    local prices = Prices
    if not (prices and recipe.makes) then
        return nil
    end
    local unlearned = Settings("profit", PROFIT_DEFAULTS).unlearned
    local profession = ProfessionOf(recipe)
    local cost, crafted = 0, 0
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        local price, source = ReagentCost(profession, reagents[index], unlearned)
        if not price then
            return nil
        end
        if source == "craft" then
            crafted = crafted + 1
        end
        cost = cost + price * (reagents[index + 1] or 1)
    end
    local auction = prices.Auction(recipe.makes)
    local unit = math.max(VendorSell(recipe.makes) or 0, auction and auction * (1 - ns.LevelingPlan.AH_CUT) or 0)
    if unit <= 0 then
        return nil
    end
    local value = unit * (recipe.count or 1)
    return { recipe = recipe, cost = cost, value = value, profit = value - cost, crafted = crafted,
        margin = cost > 0 and (value - cost) / cost or 0, tier = (Tier(recipe.makes)) }
end
Recipes.Profit = Profit

local function SortProfit(list, key, descending)
    local function Value(entry)
        if key == "name" then
            return RecipeName(entry.recipe)
        elseif key == "tier" then
            return TIER_ORDER[entry.tier]
        end
        return entry[key]
    end
    table.sort(list, function(a, b)
        local va, vb = Value(a), Value(b)
        if va ~= vb then
            if descending then
                return va > vb
            end
            return va < vb
        end
        return a.recipe.id < b.recipe.id
    end)
end

local function RenderProfit(t, profession)
    local settings = Settings("profit", PROFIT_DEFAULTS)
    local list, unpriced = {}, 0
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.makes and recipe.skill and not recipe.nip and (settings.unlearned or KnownRecipe(recipe)) then
            local entry = Profit(recipe)
            if entry and entry.tier ~= "none" then
                tinsert(list, entry)
            elseif not entry then
                unpriced = unpriced + 1
            end
        end
    end
    SortProfit(list, settings.sort, settings.descending)
    -- 点表头排序：同一列再点一次反过来；换列时数字列从大到小、名字从小到大
    t:Header(COLUMNS.profit, { settings.sort, settings.descending }, function(key)
        if settings.sort == key then
            settings.descending = not settings.descending
        else
            settings.sort, settings.descending = key, key ~= "name"
        end
        Refresh()
    end)
    local gains = 0
    for index, entry in ipairs(list) do
        if entry.profit > 0 then
            gains = gains + 1
        end
        if index <= PROFIT_ROWS then
            local recipe = entry.recipe
            local label = TIER_LABEL[entry.tier]
            local color = entry.profit >= 0 and "green" or "red"
            local open = t:Row(COLUMNS.profit, recipe, {
                a = RecipeIcon(recipe) .. RecipeName(recipe)
                    .. (KnownRecipe(recipe) and "" or ("  " .. Color(L["not learned"], "muted"))),
                b = Money(entry.cost), c = Money(entry.value),
                d = Color((entry.profit >= 0 and "+" or "-") .. Money(math.abs(entry.profit)), color),
                e = Color(("%+d%%"):format(floor(entry.margin * 100 + 0.5)), color),
                f = Color(L[label[1]], label[2]),
            }, index % 2 == 1, "profit:" .. recipe.id)
            if open then
                ReagentDetails(t, recipe, 1, true, settings.unlearned)
                SaleDetails(t, recipe.makes)
            end
        end
    end
    if #list == 0 then
        t:Heading(Color(L["Scan the auction house or visit vendors first: material prices are needed"], "muted"), 6)
    end
    local hint = L["Per craft. Click a column to sort, a row for the cost breakdown"]
    if unpriced > 0 then
        hint = (L["%d recipes left out: a material has no price yet"]):format(unpriced) .. " · " .. hint
    end
    return { (L["%d recipes priced · %d make a profit"]):format(#list, gains) }, hint
end

local RENDER = { route = RenderRoute, sources = RenderSources, profit = RenderProfit }

--------------------------------------------------------------------------------
-- 工作台：跟随游戏专业窗口
--------------------------------------------------------------------------------

local BENCH_WIDTH = 760
local TILE_GAP = 8
local hooked = {}

local function OpenWindow()
    for _, window in ipairs(WINDOWS) do
        local frame = _G[window.frame]
        if frame and frame:IsVisible() then
            return frame
        end
    end
end

-- 专业窗口里打开的是哪个专业：新版接口按技能线 ID，旧版按名字
local function CurrentProfession(frame)
    local line, name
    if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
        local info = C_TradeSkillUI.GetBaseProfessionInfo()
        line, name = info and info.professionID, info and info.professionName
    end
    if not (line or name) then
        if frame == _G.CraftFrame and GetCraftDisplaySkillLine then
            name = GetCraftDisplaySkillLine()
        elseif GetTradeSkillLine then
            name = GetTradeSkillLine()
        end
    end
    for _, profession in ipairs(Professions()) do
        for _, id in ipairs(profession.skillLines or {}) do
            if line and id == line then
                return profession
            end
        end
        for _, localized in pairs(profession.name or {}) do
            if type(name) == "string" and localized:lower() == name:lower() then
                return profession
            end
        end
    end
end
Recipes.CurrentProfession = CurrentProfession


function Refresh()
    if not (bench and bench:IsVisible()) then
        return
    end
    local settings = Settings("panel", { view = "route" })
    local profession = CurrentProfession(OpenWindow())
    local view = RENDER[settings.view] and settings.view or "route"
    bench.views:Select(view)
    local picking = view == "route" and profession ~= nil and bench.picking and HasCommissions(profession)
    bench.picking = picking or nil
    bench.routeOptions:SetShown(view == "route" and profession ~= nil)
    bench.unlearned:SetShown(view == "profit" and profession ~= nil)
    bench.empty:SetShown(profession == nil)
    local t = Table()
    if not profession then
        bench.title:SetText(L["Profession workbench"])
        bench.summary:SetText("")
        bench.hint:SetText("")
        bench:ShowTotals(nil)
        t:Finish()
        return
    end
    local skill = LearnedSkills()[profession.slug]
    bench.title:SetText(Name(profession.name) or profession.slug)
    if view == "route" then
        local route = Settings("route", ROUTE_DEFAULTS)
        bench.target:SetValue(RouteTarget(route, skill and skill.rank or 1))
        local handbook = profession.route ~= nil
        if not handbook then
            route.mode = "live"
        end
        bench.mode:SetItems(handbook and bench.modeItems.all or bench.modeItems.calculated)
        local priority = ns.LevelingPlan.PRIORITY[route.priority or ""] and route.priority or "balanced"
        bench.mode:SetValue(route.mode == "handbook" and "handbook" or priority)
        bench.target:ClearAllPoints()
        bench.target:SetPoint("LEFT", bench.mode, "RIGHT", 8, 0)
        bench.buyRecipes:SetShown(route.mode ~= "handbook")
        bench.recovery:ClearAllPoints()
        bench.recovery:SetPoint("LEFT", bench.target, "RIGHT", 12, 0)
        bench.recovery:SetChecked(route.recovery)
        bench.buyRecipes:SetChecked(route.buyRecipes)
        bench.commission:SetShown(HasCommissions(profession))
        bench.commission:SetPoint("LEFT", route.mode == "handbook" and bench.recovery or bench.buyRecipes, "RIGHT", 14, 0)
        bench.commission:SetSelected(picking)
        bench.commission:SetLabel(picking and L["Back to the route"]
            or (L["Customer enchants: %d"]):format(#ChosenCommissions(profession)))
    elseif view == "profit" then
        bench.unlearned:SetChecked(Settings("profit", PROFIT_DEFAULTS).unlearned)
    end
    local parts, hint, plan = (picking and RenderPicker or RENDER[view])(t, profession, skill)
    t:Finish()
    bench:ShowTotals(plan)
    if skill then
        tinsert(parts, 1, (L["Your skill %d/%d"]):format(skill.rank, skill.max))
    end
    bench.summary:SetText(table.concat(parts, "  ·  "))
    bench.hint:SetText(Color(hint or "", "muted"))
end
Recipes.Refresh = Refresh

local Update

local function SetCollapsed(collapsed)
    Settings("panel").collapsed = collapsed
    Update()
end

local function CreateBench()
    local settings = Settings("panel", { view = "route" })
    bench = UI:Panel(UIParent, "panel", "line")
    bench:SetWidth(BENCH_WIDTH)
    bench:Hide()
    UI:Dockable(bench, settings, 2)
    bench.title = UI:Text(bench, "Heading", L["Profession workbench"])
    bench.title:SetPoint("TOPLEFT", 14, -12)
    bench.summary = UI:Text(bench, "Muted")
    bench.summary:SetPoint("TOPLEFT", bench.title, "BOTTOMLEFT", 0, -4)
    bench.summary:SetPoint("RIGHT", -14, 0)
    bench.summary:SetJustifyH("LEFT")
    bench.summary:SetWordWrap(false)
    bench.close = UI:CloseButton(bench, function()
        SetCollapsed(true)
    end)
    bench.close:SetPoint("TOPRIGHT", -8, -8)

    bench.views = UI:Segmented(bench, {
        { id = "route", label = L["Leveling route"] },
        { id = "sources", label = L["Recipe sources"] },
        { id = "profit", label = L["Profit"] },
    }, function(view)
        settings.view = view
        Refresh()
    end, 130)
    bench.views:SetPoint("TOPLEFT", 14, -54)

    -- 冲级路线的选项：目标技能、是否计入回收、是否买图纸；附魔专业另有按钮打开代工附魔的勾选表
    local route = Settings("route", ROUTE_DEFAULTS)
    local options = CreateFrame("Frame", nil, bench)
    options:SetPoint("TOPLEFT", 14, -86)
    options:SetPoint("RIGHT", -14, 0)
    options:SetHeight(24)
    bench.routeOptions = options
    local targets = {}
    for _, value in ipairs(TARGETS) do
        tinsert(targets, { id = value, label = (L["To skill %d"]):format(value) })
    end
    bench.target = UI:Dropdown(options, targets, function(value)
        route.target = value
        Refresh()
    end, 100)
    bench.target:SetItems(targets)
    bench.target:SetPoint("LEFT", 0, 0)
    -- 路线下拉框：三种计算取向（效率优先 / 均衡 / 省钱优先）与手册路线放在一起，切到手册路线后也能直接切回来。
    -- 有手册路线的专业才列出“手册路线”（Refresh 里按专业换列表）
    local modes = {
        { id = "speed", label = L["Fastest"], tip = L["Each craft counts as 30 silver, more at higher skill: fewer crafts usually win"] },
        { id = "balanced", label = L["Balanced"],
            tip = L["Each extra craft counts as a little money: a sure point is worth paying a bit for"] },
        { id = "saving", label = L["Cheapest"], tip = L["Money only: the cheapest way, even if it takes many more crafts"] },
        { id = "handbook", label = L["Handbook route"],
            tip = L["The fixed order from the wowhandbook.com guide, priced at today's prices"] },
    }
    bench.modeItems = { all = modes, calculated = { modes[1], modes[2], modes[3] } }
    bench.mode = UI:Dropdown(options, modes, function(value)
        if value == "handbook" then
            route.mode = "handbook"
        else
            route.mode, route.priority = "live", value
        end
        Refresh()
    end, 110)
    bench.mode:SetItems(modes)
    bench.mode:SetPoint("LEFT", 0, 0)
    bench.mode:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["How the route picks recipes"])
        for _, item in ipairs(self.items or modes) do
            GameTooltip:AddDoubleLine(item.label, item.tip, 0.88, 0.71, 0.35, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    bench.mode:HookScript("OnLeave", GameTooltip_Hide)
    local function Option(key, label, anchor)
        local check = UI:Checkbox(options, label, function(checked)
            route[key] = checked
            Refresh()
        end)
        check:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
        return check
    end
    bench.recovery = Option("recovery", L["Count resale"], bench.target)
    bench.buyRecipes = Option("buyRecipes", L["Buy recipe items"], bench.recovery)
    bench.commission = UI:Button(options, "", 150, 22)
    bench.commission:SetPoint("LEFT", bench.buyRecipes, "RIGHT", 14, 0)
    bench.commission:SetScript("OnClick", function()
        bench.picking = not bench.picking or nil
        Refresh()
    end)

    bench.unlearned = UI:Checkbox(bench, L["Include recipes not learned yet"], function(checked)
        Settings("profit").unlearned = checked
        Refresh()
    end)
    bench.unlearned:SetPoint("TOPLEFT", 14, -88)

    -- 冲级路线的四个数字：材料、图纸、成品回收、净花费（算不出路线或在勾选代工附魔时不显示）
    local totals = CreateFrame("Frame", nil, bench)
    totals:SetPoint("TOPLEFT", 10, -116)
    totals:SetPoint("RIGHT", -10, 0)
    totals:SetHeight(58)
    bench.totals, bench.tiles = totals, {}
    local tileWidth = (BENCH_WIDTH - 20 - 3 * TILE_GAP) / 4
    for index, key in ipairs({ "materials", "recipes", "resale", "net" }) do
        local tile = UI:StatTile(totals, "")
        tile:SetWidth(tileWidth)
        tile:SetPoint("TOPLEFT", (index - 1) * (tileWidth + TILE_GAP), 0)
        bench.tiles[key] = tile
    end

    local panel = UI:Panel(bench, "panel", "lineSoft")
    panel:SetPoint("BOTTOMRIGHT", -10, 30)
    function bench:ShowTotals(plan)
        totals:SetShown(plan ~= nil)
        panel:SetPoint("TOPLEFT", 10, plan and -(116 + 58 + TILE_GAP) or -116)
        if not plan then
            return
        end
        local tiles = self.tiles
        tiles.materials.title:SetText(L["Materials"])
        tiles.materials:Set(Brief(plan.materials))
        tiles.recipes.title:SetText(L["Recipe items"])
        tiles.recipes:Set(Brief(plan.recipeCost))
        tiles.resale.title:SetText(plan.recovery > 0
            and (L["Resale, at least %s"]):format(Brief(plan.safeRecovery)) or L["Resale value"])
        tiles.resale:Set(Brief(plan.recovery))
        -- 有断档或缺价的路线只是部分预算：标题说明只算了能算的部分，缺的区间写在底部提示里
        local partial = plan.missing and #plan.missing > 0
        tiles.net.title:SetText(plan.net >= 0 and (partial and L["Net cost, priced part"] or L["Net cost"])
            or (partial and L["Net profit, priced part"] or L["Net profit"]))
        tiles.net:Set(plan.net >= 0 and Brief(plan.net) or Color("+" .. Brief(-plan.net), "green"))
    end
    bench:ShowTotals(nil)
    bench.detail = UI:ScrollArea(panel)
    bench.detail:SetPoint("TOPLEFT", 6, -6)
    bench.detail:SetPoint("BOTTOMRIGHT", -14, 6)
    bench.rows, bench.expanded, bench.collapsed = {}, {}, {}
    bench.hint = UI:Text(bench, "Small")
    bench.hint:SetPoint("BOTTOMLEFT", 14, 10)
    bench.hint:SetPoint("RIGHT", -14, 0)
    bench.hint:SetJustifyH("LEFT")
    bench.hint:SetWordWrap(false)
    bench.empty = UI:Text(bench, "Muted", L["This profession levels by gathering; it has no recipes to craft."])
    bench.empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
    bench.empty:SetWidth(BENCH_WIDTH - 48)
    bench.empty:SetJustifyH("LEFT")

    -- 收起后在工作台左上角的位置留一个小按钮，点一下重新展开。按钮与工作台共用一个偏移（dockX / dockY，相对专业窗口右上角）：
    -- 拖动按钮后展开，工作台左上角就在按钮处；拖动工作台后收起，按钮就出现在工作台左上角。右键两者一起还原
    settings.tabX, settings.tabY = nil, nil -- 旧版按钮单独记的偏移，不再使用
    tab = UI:Button(UIParent, L["Workbench"], 80, 24, "primary")
    tab:Hide()
    tab:SetMovable(true)
    tab:SetClampedToScreen(true)
    tab:RegisterForDrag("LeftButton")
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tab:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    tab:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.draggedAt = GetTime()
        local window = OpenWindow()
        local left, top = self:GetLeft(), self:GetTop()
        if window and left and top and window:GetRight() and window:GetTop() then
            local ratio = window:GetEffectiveScale() / self:GetEffectiveScale()
            settings.dockX = math.floor(left - window:GetRight() * ratio + 0.5)
            settings.dockY = math.floor(top - window:GetTop() * ratio + 0.5)
        end
        Update()
    end)
    tab:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            settings.dockX, settings.dockY = nil, nil
            Update()
            return
        end
        -- 拖动松手时不当成点击
        if self.draggedAt and GetTime() - self.draggedAt < 0.3 then
            return
        end
        SetCollapsed(false)
    end)
    tab:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Workbench"])
        GameTooltip:AddLine(L["Click to open. Drag to move; right-click to put it back."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tab:HookScript("OnLeave", GameTooltip_Hide)
    Recipes.bench, Recipes.tab = bench, tab -- 供测试使用
end

function Update()
    local window = Module.enabled and OpenWindow()
    if not window then
        if bench then
            bench:Hide()
            tab:Hide()
        end
        return
    end
    if not bench then
        CreateBench()
    end
    bench:Dock(window)
    local x, y = bench:DockOffset()
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", window, "TOPRIGHT", x, y)
    -- 工作台永远在专业窗口之上：层级（strata）比专业窗口高一档，不受窗口被点击提到最前时层内等级变化的影响
    local strata = STRATA_ABOVE[window:GetFrameStrata()] or "DIALOG"
    for _, frame in ipairs({ bench, tab }) do
        frame:SetFrameStrata(strata)
        frame:SetFrameLevel(20)
    end
    local collapsed = Settings("panel").collapsed
    bench:SetShown(not collapsed)
    tab:SetShown(collapsed and true or false)
    Refresh()
end
Recipes.UpdatePanel = Update

-- 暴雪专业窗口按需加载：已加载就挂上，否则等它加载
local function Attach()
    for _, window in ipairs(WINDOWS) do
        local frame = _G[window.frame]
        if frame and not hooked[frame] then
            hooked[frame] = true
            frame:HookScript("OnShow", Update)
            frame:HookScript("OnHide", Update)
        end
    end
end

local function OnAddonLoaded(_, name)
    for _, window in ipairs(WINDOWS) do
        if name == window.addon then
            Attach()
        end
    end
end

-- 打开或切换专业、学会新配方、技能提升、价格变化：先读已学配方，再刷新（合并 0.5 秒内的多次变化；窗口没开时不做事）
local pending = false
local function OnChange()
    if pending or not (Module.enabled and OpenWindow()) then
        return
    end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        if Module.enabled and OpenWindow() then
            RecordKnownRecipes()
            Update()
        end
    end)
end

-- 战斗中不算路线（Refresh 里记下），脱战后补算一次
local function OnRegenEnabled()
    if deferred then
        deferred = false
        OnChange()
    end
end

local CHANGE_EVENTS = { "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED",
    "TRADE_SKILL_UPDATE", "CRAFT_SHOW", "CRAFT_UPDATE", "SKILL_LINES_CHANGED", "NEW_RECIPE_LEARNED",
    "GET_ITEM_INFO_RECEIVED" }
local listening = false

function Module:OnEnable()
    ns:RegisterEvent("ADDON_LOADED", OnAddonLoaded)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", OnRegenEnabled)
    for _, event in ipairs(CHANGE_EVENTS) do
        ns:RegisterEvent(event, OnChange)
    end
    if not listening and Prices and Prices.OnChange then
        listening = true
        Prices.OnChange(OnChange)
    end
    Attach()
    Update()
end

function Module:OnDisable()
    ns:UnregisterEvent("ADDON_LOADED", OnAddonLoaded)
    ns:UnregisterEvent("PLAYER_REGEN_ENABLED", OnRegenEnabled)
    for _, event in ipairs(CHANGE_EVENTS) do
        ns:UnregisterEvent(event, OnChange)
    end
    if bench then
        bench:Hide()
        tab:Hide()
    end
end
