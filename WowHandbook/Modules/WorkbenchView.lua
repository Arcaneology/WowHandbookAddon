local ADDON_NAME, ns = ...
local L = ns.L

-- 专业工作台（界面部分）：贴在游戏专业窗口右侧的两栏窗口。
--   顶栏：专业名、技能进度、配方数概要、收起按钮。
--   左栏：一张配方列表，三种视角共用搜索框（配方名、图纸名、材料名都能搜）——
--     练级：顶上一行“路线总览”，接着是训练师（下一档该找的那些，其余折成一行），再按步骤排（技能区间与次数）；
--       已走过的 1 到当前技能折成一行，点开才算；
--     图纸：按 已学 / 现在可学 / 以后可学 / 商人青睐的图纸 分组，行尾是学习技能与来源；
--     赚钱：按利润（或利润率、成本、卖价、好不好卖、名字）排序，行尾是每次利润。
--   右栏：选中配方的详情——标题区（图标、名字、是否已学、每次利润与回本率）、难度色条（学习、变黄、变绿、变灰，
--     标出当前技能），成本表（每种材料的来源并列可选，表尾合计），成品出售，在冲级路线里的那一步，
--     学习来源；底部按钮：拍卖行搜材料、在专业窗口打开、在地图上标出商人。
--     选中训练师时换成训练师详情：位置（点击在地图上标出）、能教到哪一档、学下一档的要求、在这里现在能学的配方。
--     选中“路线总览”时换成整条路线：四个数字、路线选项、代工附魔勾选、要自己做的材料、要买的图纸、购物清单、成品去向。
--   钓鱼没有配方，左栏换成 地区 / 渔获 / 我的渔获 / 训练师 四个视角，条目与右栏内容在 WorkbenchFishing.lua。
--   在游戏专业窗口里选中配方，右栏跟着切过去（hooksecurefunc 挂配方表单的 Init，与 CraftingCost 同一挂法）。
-- 计算全部在 Workbench.lua；这里只画界面。路线按专业与技能缓存，价格、已学配方或选项变化时作废重算；
-- 只换选中项时只重画右栏。

local R = ns.modules.Workbench
local Module = R
local UI, Theme = ns.UI, ns.Theme
local Prices = ns.Prices

local Color, Settings, Name, ItemLink = R.Color, R.Settings, R.Name, R.ItemLink
local LearnedSkills = R.LearnedSkills
local RecipeName, RecipeIcon, KnownRecipe, Difficulty = R.RecipeName, R.RecipeIcon, R.KnownRecipe, R.Difficulty
local ShowRecipeTooltip, AuctionOpen, SearchEnabled = R.ShowRecipeTooltip, R.AuctionOpen, R.SearchEnabled
local ShiftSearch, InsertChatLink = R.ShiftSearch, R.InsertChatLink
local Money, Brief, Count, Tier = R.Money, R.Brief, R.Count, R.Tier
local HasCommissions, CommissionPicks = R.HasCommissions, R.CommissionPicks
local RouteTarget, BuildRoute, Destination = R.RouteTarget, R.BuildRoute, R.Destination
local TIER_LABEL, TIER_REASON = R.TIER_LABEL, R.TIER_REASON
local PROFIT_DEFAULTS, ROUTE_DEFAULTS, TARGETS = R.PROFIT_DEFAULTS, R.ROUTE_DEFAULTS, R.TARGETS
local CastCost, ProfessionOf, ReagentCost, Profit = R.CastCost, R.ProfessionOf, R.ReagentCost, R.Profit
local Side, FavorPrice, Source, MapName = R.Side, R.FavorPrice, R.Source, R.MapName
local OpenWindow, CurrentProfession = R.OpenWindow, R.CurrentProfession

local BENCH_WIDTH = 1100 -- 与拍卖行工作台差不多大
local BENCH_HEIGHT = 680
local LEFT_WIDTH = 330
local TOP_HEIGHT = 44 -- 顶栏
local HEAD_HEIGHT = 56 -- 右栏标题区
local SKILLBAR_HEIGHT = 56 -- 难度色条：上方当前技能、中间色条、下方各档技能
local DIFFICULTY_BAR_TOP, DIFFICULTY_BAR_HEIGHT = 20, 10
local ACTION_HEIGHT = 36 -- 右栏底部按钮区
local STRIP_HEIGHT = 92 -- 路线总览的选项与四个数字
local ROW_HEIGHT = 20
local TOTAL_HEIGHT = 26 -- 成本表、卖出表的合计行
local RULE_HEIGHT = 9 -- 分隔线所在的行
local TILE_GAP = 8
local PICKER_ICON, PICKER_GAP, PICKER_GROUP_GAP = 24, 3, 9 -- 顶栏专业图标条：图标大小、间距、已学与没学之间的空
local STRATA_ABOVE = { BACKGROUND = "LOW", LOW = "MEDIUM", MEDIUM = "HIGH", HIGH = "DIALOG", DIALOG = "FULLSCREEN",
    FULLSCREEN = "FULLSCREEN_DIALOG", FULLSCREEN_DIALOG = "TOOLTIP" }
local DIFFICULTY_COLORS = { "skillOrange", "skillYellow", "skillGreen", "skillGray" }

local bench, tab, escape
local Refresh, RefreshList, RefreshDetail, Update, CloseStandalone

--------------------------------------------------------------------------------
-- 路线缓存：同一专业、同一技能、同样的选项只算一次
--------------------------------------------------------------------------------

local routeCache

local function Invalidate()
    routeCache = nil
end
R.Invalidate = Invalidate

-- 返回 { plan, from, to, earlier }；战斗中没有缓存时返回 nil 并记下脱战后补算
local function RoutePlan(profession, skill)
    if not (Prices and ns.LevelingPlan) then
        return nil
    end
    local key = profession.slug .. ":" .. (skill and skill.rank or 1)
    if routeCache and routeCache.key == key then
        return routeCache
    end
    if InCombatLockdown() then
        R.deferred = true
        return nil
    end
    local plan, from, to = BuildRoute(profession, skill)
    local handbook = Settings("route", ROUTE_DEFAULTS).mode == "handbook"
    plan.fixed = handbook and profession.route ~= nil
    plan.locked = not handbook and R.LockedRoute(profession) ~= nil
    routeCache = { key = key, plan = plan, from = from, to = to }
    return routeCache
end

-- 已经走过的 1 到当前技能：按现在的价格算一遍同样的路线，展开时才算
local function EarlierPlan(profession, skill, route)
    if not route.earlier and route.from > 1 and not InCombatLockdown() then
        route.earlier = BuildRoute(profession, skill, 1, route.from, true)
    end
    return route.earlier
end

--------------------------------------------------------------------------------
-- 右栏的行（表头、小标题、数据行、对齐明细行、比例条）
--------------------------------------------------------------------------------

local CELLS = { "a", "b", "c", "d", "e" }
local HEADING = { { key = "a" } }
local SECTION_VALUE = { { key = "a", width = 360 }, { key = "b" } }
local COLUMNS = {
    cost = {
        { key = "a", label = "Item", width = 400 },
        { key = "b", label = "Quantity", width = 70 },
        { key = "c", label = "Unit price", width = 130 },
        { key = "d", label = "Total" },
    },
    sale = {
        { key = "a", label = "Outlet", width = 400 },
        { key = "b", label = "Quantity", width = 70 },
        { key = "c", label = "Unit price", width = 130 },
        { key = "d", label = "Total" },
    },
    list = {
        { key = "a", label = "Item", width = 460 },
        { key = "b", label = "Count", width = 70 },
        { key = "c", label = "Cost" },
    },
    learn = {
        { key = "a", label = "Recipe", width = 460 },
        { key = "b", label = "Learn at" },
    },
    pick = {
        { key = "a", label = "Free at skill", width = 84 },
        { key = "b", label = "Enchant", width = 380 },
        { key = "c", label = "Materials per cast", width = 140 },
        { key = "d", label = "" },
    },
}

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.highlight = row:CreateTexture(nil, "BORDER")
    row.highlight:SetAllPoints()
    row.highlight:Hide()
    row.swatch = row:CreateTexture(nil, "ARTWORK")
    row.swatch:SetSize(8, 8)
    row.swatch:SetPoint("LEFT", 8, 0)
    row.bars = {}
    row.cells = {}
    for _, key in ipairs(CELLS) do
        local cell = UI:Text(row, "Small")
        cell:SetJustifyH("LEFT")
        cell:SetWordWrap(false)
        row.cells[key] = cell
    end
    row:SetScript("OnEnter", function(self)
        self.highlight:SetColorTexture(unpack(Theme.colors.raised))
        self.highlight:SetShown(self.recipe or self.item or self.spot or self.key or self.onClick)
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
        if (self.recipe or self.item) and GameTooltip:IsShown() and SearchEnabled() and AuctionOpen() then
            GameTooltip:AddLine(self.item and L["Shift-click to search the auction house"]
                or L["Shift-click to search the auction house for the product and materials"], 0.27, 0.75, 0.45)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        GameTooltip_Hide()
    end)
    -- Shift 点击：拍卖行开着时搜索（ShiftSearch），否则把物品（没有时成品）链接发到聊天框；
    -- 有商人位置的行点击在地图上标出；带 onClick 的行（分段标题、勾选行、操作行）调用它；其余可展开的行展开或收起
    row:SetScript("OnClick", function(self)
        local recipe = self.recipe
        if (self.item or recipe) and IsModifiedClick and IsModifiedClick("CHATLINK") then
            if not ShiftSearch(self) then
                InsertChatLink(self.item or recipe.makes)
            end
        elseif self.spot then
            ns.Waypoints:ShowOnMap(self.spot[1], self.spot[2], self.spot[3], self.spot.title)
        elseif self.onClick then
            self.onClick()
        elseif self.key then
            bench.expanded[self.key] = not bench.expanded[self.key] or nil
            RefreshDetail()
        end
    end)
    return row
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
    end
    Theme:Paint(row.box.mark, "gold")
    row.box:Show()
    row.box.mark:SetShown(row.check)
end

-- 按列宽摆放单元格；没有宽度的列占到行尾。行首有勾选框或色块时只让第一列右移，后面的列与表头对齐
local function LayoutRow(row, columns)
    for _, cell in pairs(row.cells) do
        cell:Hide()
    end
    RowCheck(row)
    local inset = 0
    if row.check ~= nil then
        inset = 22
    elseif row.swatch:IsShown() then
        inset = 14
    end
    local x = 8
    for index, column in ipairs(columns) do
        local cell = row.cells[column.key]
        local offset = index == 1 and inset or 0
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", x + offset, 0)
        if column.width and index < #columns then
            cell:SetWidth(column.width - 8 - offset)
            x = x + column.width
        else
            cell:SetPoint("RIGHT", -8, 0)
        end
        cell:Show()
    end
end

local function Table()
    local child = bench.body.child
    local rows, used, y = bench.rows, 0, 0
    local t = {}

    local function NextRow(recipe, key, spot, item, height)
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
        row:SetHeight(height or ROW_HEIGHT)
        row.swatch:Hide()
        if row.rule then
            row.rule:Hide()
        end
        for _, bar in ipairs(row.bars) do
            bar:Hide()
        end
        for _, cell in pairs(row.cells) do
            cell:SetJustifyH("LEFT")
            cell:SetFontObject(Theme.fonts.Small)
        end
        y = y + (height or ROW_HEIGHT)
        return row
    end

    local function Fill(row, columns, cells, striped)
        row.stripe:SetColorTexture(unpack(Theme.colors.stripe))
        row.stripe:SetShown(striped and true or false)
        for _, column in ipairs(columns) do
            row.cells[column.key]:SetText(cells[column.key] or "")
        end
        LayoutRow(row, columns)
    end

    function t:Gap(height)
        y = y + height
    end

    function t:Header(columns)
        local cells = {}
        for _, column in ipairs(columns) do
            cells[column.key] = Color(L[column.label], "muted")
        end
        Fill(NextRow(nil), columns, cells)
    end

    -- 小标题（强调色）；gapBefore 为上方留白
    function t:Heading(text, gapBefore)
        y = y + (gapBefore or 0)
        Fill(NextRow(nil), HEADING, { a = Color(text, "gold") })
    end

    -- 一整行说明文字（已上色的文字原样显示）；spot = { 地图, x, y, title = 名字 } 时点击在地图上标出
    function t:Detail(text, spot)
        Fill(NextRow(nil, nil, spot), HEADING, { a = text })
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

    -- 对齐的明细行：b 及以后的列右对齐（数量、单价、总价）；swatch 为色块的颜色名。
    -- key 不为空时可点击展开，第一列前面带 + / -；highlight 为真时背景高亮（选中的一项）；返回是否已展开
    function t:Line(columns, cells, swatch, item, key, highlight)
        local open = key and bench.expanded[key] or false
        if key then
            local first = columns[1].key
            cells[first] = Color(open and "- " or "+ ", "muted") .. (cells[first] or "")
        end
        local row = NextRow(nil, key, nil, item)
        if swatch then
            row.swatch:SetColorTexture(unpack(Theme.colors[swatch]))
            row.swatch:Show()
        end
        for index = 2, #columns do
            row.cells[columns[index].key]:SetJustifyH("RIGHT")
        end
        Fill(row, columns, cells)
        if highlight then
            row.stripe:SetColorTexture(unpack(Theme.colors.selected))
            row.stripe:Show()
        end
        return open
    end

    -- 比例条：segments = { { 数值, 颜色名 }, ... }，按数值占比分宽度
    function t:Bar(segments)
        local row = NextRow(nil, nil, nil, nil, 14)
        Fill(row, HEADING, {})
        local total = 0
        for _, segment in ipairs(segments) do
            total = total + segment[1]
        end
        if total <= 0 then
            return
        end
        local width = math.max(100, (bench.body:GetWidth() or 0) - 16)
        local x = 8
        for index, segment in ipairs(segments) do
            local bar = row.bars[index]
            if not bar then
                bar = row:CreateTexture(nil, "ARTWORK")
                row.bars[index] = bar
            end
            local w = math.max(1, width * segment[1] / total)
            bar:ClearAllPoints()
            bar:SetPoint("LEFT", x, 0)
            bar:SetSize(w, 8)
            bar:SetColorTexture(unpack(Theme.colors[segment[2]]))
            bar:Show()
            x = x + w
        end
    end

    -- 分段标题：点击收起或展开这一段（默认展开，closed 为真时默认收起）；返回是否展开。
    -- bench.collapsed[key]：true 收起、false 展开、nil 按默认。value 为标题行右端的数字（已上色的文字）
    function t:Section(title, key, gapBefore, closed, value)
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
            RefreshDetail()
        end
        row:EnableMouse(true)
        local text = Color(open and "- " or "+ ", "muted") .. Color(title, "gold")
        if value then
            row.cells.b:SetJustifyH("RIGHT")
            Fill(row, SECTION_VALUE, { a = text, b = value })
        else
            Fill(row, HEADING, { a = text })
        end
        return open
    end

    -- 带勾选框的行：点击调用 onClick
    function t:Check(columns, recipe, cells, striped, checked, onClick)
        local row = NextRow(recipe)
        row.onClick, row.check = onClick, checked and true or false
        row:EnableMouse(true)
        Fill(row, columns, cells, striped)
    end

    -- 可点选的明细行（成本表里材料的一个来源、卖出表里的一种卖法）：行首勾选框，checked 为是否选中（选中的行
    -- 背景高亮）；b 及以后的列右对齐。onClick 为 nil 时不能点（现在没价格）
    function t:Option(columns, cells, checked, onClick, item)
        local row = NextRow(nil, nil, nil, item)
        row.onClick, row.check = onClick, checked and true or false
        row:EnableMouse((onClick or item) and true or false)
        for index = 2, #columns do
            row.cells[columns[index].key]:SetJustifyH("RIGHT")
        end
        Fill(row, columns, cells)
        if checked then
            row.stripe:SetColorTexture(unpack(Theme.colors.selected))
            row.stripe:Show()
        end
    end

    -- 分隔线：一条横贯表格的细线（材料之间、合计行上方）
    function t:Rule()
        local row = NextRow(nil, nil, nil, nil, RULE_HEIGHT)
        Fill(row, HEADING, {})
        if not row.rule then
            row.rule = row:CreateTexture(nil, "ARTWORK")
            row.rule:SetHeight(1)
            row.rule:SetPoint("LEFT", 8, 0)
            row.rule:SetPoint("RIGHT", -8, 0)
        end
        row.rule:SetColorTexture(unpack(Theme.colors.line))
        row.rule:Show()
    end

    -- 合计行（材料成本、卖价、利润、利润率）：比明细行高，字大一号，b 及以后的列右对齐
    function t:Total(columns, cells)
        local row = NextRow(nil, nil, nil, nil, TOTAL_HEIGHT)
        for index, column in ipairs(columns) do
            local cell = row.cells[column.key]
            cell:SetFontObject(Theme.fonts.Body)
            if index > 1 then
                cell:SetJustifyH("RIGHT")
            end
        end
        Fill(row, columns, cells)
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
        bench.body:SetContentHeight(y + 8)
        return used
    end
    return t
end

--------------------------------------------------------------------------------
-- 右栏的内容块
--------------------------------------------------------------------------------

local function Origin(source)
    return source == "vendor" and L["from a vendor"] or L["on the auction house"]
end

-- 一次制作的材料，每种按玩家选的来源，没选的按最省的做法（见 ReagentCost）：
-- 返回 { { item, count, price, source, via, buy, key }, ... }、材料合计（有材料没价格时为 nil）、自己做的种数
local function CheapestWay(recipe)
    local unlearned = Settings("profit", PROFIT_DEFAULTS).unlearned
    local profession = ProfessionOf(recipe)
    local lines, total, crafted = {}, 0, 0
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        local item, count = reagents[index], reagents[index + 1] or 1
        local price, source, via, buy, key = ReagentCost(profession, item, unlearned)
        tinsert(lines, { item = item, count = count, price = price, source = source, via = via, buy = buy, key = key })
        if price and total then
            total = total + price * count
        else
            total = nil
        end
        if source == "craft" then
            crafted = crafted + 1
        end
    end
    return lines, total, crafted
end
R.CheapestWay = CheapestWay -- 供测试使用

-- 来源与卖法的名字：本阵营拍卖行写“联盟拍卖行 / 部落拍卖行”，中立拍卖行写“中立拍卖行”，商人写“商人”
local function SourceLabel(kind)
    if kind == "vendor" then
        return L["Vendor"]
    elseif kind == "neutral" then
        return L["Neutral auction house"]
    end
    local group = UnitFactionGroup("player")
    if group == "Alliance" then
        return L["Alliance auction house"]
    elseif group == "Horde" then
        return L["Horde auction house"]
    end
    return L["Auction house"]
end

-- 自己做时一种下层材料是在哪买的：本阵营按商人与拍卖行取低，中立按商人与中立拍卖行取低
local function PartTag(part, market)
    local kind
    if market == "neutral" then
        kind = part.unit and part.unit == Prices.Vendor(part.item) and "vendor" or "neutral"
    else
        kind = select(2, Prices.BuyCost(part.item)) or "auction"
    end
    return Color(SourceLabel(kind), "muted")
end

-- 成本表里一种材料的一个来源：直接买的写这件材料，自己做的写做它用的下层材料（多种时用 + 连起来，只写合计）
local function WayCells(way, count)
    local none = Color(L["no price yet"], "muted")
    local cells
    if way.kind ~= "craft" then
        cells = { b = tostring(count) }
        cells.c = way.price and Money(way.price) or none
    elseif #way.parts == 1 then
        local part = way.parts[1]
        cells = { a = ItemLink(part.item) .. "  " .. PartTag(part, way.market), b = Count(part.each * count),
            c = part.unit and Money(part.unit) or none }
    else
        local names = {}
        for _, part in ipairs(way.parts) do
            tinsert(names, ItemLink(part.item) .. " x" .. Count(part.each * count))
        end
        cells = { a = table.concat(names, " + ") .. (way.market == "neutral"
            and "  " .. Color(L["Neutral auction house"], "muted") or ""), c = way.price and "" or none }
    end
    cells.d = way.price and Money(way.price * count) or ""
    if way.kind == "craft" and not KnownRecipe(way.recipe) then
        cells.a = cells.a .. "  " .. Color(L["not learned"], "muted")
    end
    return cells
end

-- 制作：一段可收起的成本表（合计只写在表尾，标题行不重复）。比例条，物品 / 数量 / 单价 / 总价四列；
-- 每种材料把全部来源按单价从低到高并列成几行（直接买这件材料，或买做它的下层材料自己做；有中立拍卖行记录时
-- 再列中立的），勾选并高亮的那行计入成本（没选过的勾最省的），点另一行改用它，成本、利润与列表随之重算。
-- 末尾是字大一号的材料合计
local function CostSection(t, recipe)
    local reagents = recipe.reagents
    if not (Prices and reagents and #reagents > 0) then
        return
    end
    local none = Color(L["no price yet"], "red")
    local profession = ProfessionOf(recipe)
    local lines, cost = CheapestWay(recipe)
    if not t:Section(L["Making it"], "make", 0, false) then
        return
    end
    t:Header(COLUMNS.cost)
    for index, line in ipairs(lines) do
        local item, count = line.item, line.count
        if index > 1 then
            t:Rule()
        end
        for _, way in ipairs(R.Ways(profession, item)) do
            local cells = WayCells(way, count)
            if way.kind ~= "craft" then
                cells.a = ItemLink(item) .. "  " .. Color(SourceLabel(way.kind), "muted")
            end
            local checked = way.key == line.key
            if not checked then
                for _, key in ipairs({ "b", "c", "d" }) do
                    cells[key] = cells[key] ~= "" and Color(cells[key], "muted") or ""
                end
            end
            local onClick = way.price and function()
                R.PickSource(item, way.key)
                Refresh()
            end or nil
            t:Option(COLUMNS.cost, cells, checked, onClick,
                way.kind == "craft" and #way.parts == 1 and way.parts[1].item or item)
        end
    end
    t:Rule()
    t:Total(COLUMNS.cost, { a = Color(L["Material cost"], "gold"), d = cost and Money(cost) or none })
end

-- 卖出：一段可收起的去向表（卖价、利润只写在表尾，标题行不重复）。去向 / 数量 / 单价 / 总价，单价是扣手续费后
-- 到手的钱；与成本表一样，全部卖法按单价从低到高并列、可点选，勾选并高亮的那行计入卖价与利润
-- （没选过的勾本阵营拍卖行与商人里高的）。分隔线下是字大一号的卖价、利润与利润率，再一条分隔线后是好不好卖
-- 与在售数量
local function SaleSection(t, recipe)
    local itemID, count = recipe.makes, recipe.count or 1
    local chosen, outlets = R.SaleOutlet(itemID)
    if not t:Section(L["Selling it"], "sell", 10, false) then
        return
    end
    if #outlets > 0 then
        t:Header(COLUMNS.sale)
        for _, outlet in ipairs(outlets) do
            local checked = outlet == chosen
            local cells = {
                a = SourceLabel(outlet.key) .. (outlet.cut
                    and Color(("  " .. L["%d%% fee"]):format(floor(outlet.cut * 100 + 0.5)), "muted") or ""),
                b = tostring(count), c = Money(outlet.unit), d = Money(outlet.unit * count),
            }
            if not checked then
                for _, key in ipairs({ "b", "c", "d" }) do
                    cells[key] = Color(cells[key], "muted")
                end
            end
            t:Option(COLUMNS.sale, cells, checked, function()
                R.PickSale(itemID, outlet.key)
                Refresh()
            end, itemID)
        end
        t:Rule()
        t:Total(COLUMNS.sale, { a = Color(L["Sale price"], "gold"), d = chosen and Money(chosen.unit * count) or "" })
        -- 利润与利润率（利润 ÷ 材料成本），与右上角一致；材料缺价时没有
        local result = Profit(recipe)
        if result then
            local color = result.profit >= 0 and "green" or "red"
            t:Total(COLUMNS.sale, { a = Color(L["Profit"], "gold"),
                d = Color((result.profit >= 0 and "+" or "-") .. Money(math.abs(result.profit)), color) })
            if result.cost > 0 then
                t:Total(COLUMNS.sale, { a = Color(L["Margin"], "gold"),
                    d = Color(("%+d%%"):format(floor(result.margin * 100 + 0.5)), color) })
            end
        end
        t:Rule()
    end
    local label = TIER_LABEL[(Tier(itemID))]
    local listed = Prices.Auction(itemID) and Prices.Available and Prices.Available(itemID)
    t:Line(COLUMNS.sale, { a = Color(L[label[1]], label[2]),
        d = listed and Color((L["%d listed"]):format(listed), "muted") or "" })
end

-- 一步里买了什么（数量、均价、来源、小计）、用了前面做的什么、先自己做了什么
local function StepDetails(t, step, byRecipe)
    for _, entry in ipairs(step.bought or {}) do
        local item, count, cost = entry[1], entry[2], entry[3]
        local _, source = Prices.BuyCost(item)
        t:Detail(("%s x%s  ·  %s %s  =  %s"):format(ItemLink(item), Count(count), Money(cost / count),
            Color(Origin(source), "muted"), Money(cost)))
    end
    for _, entry in ipairs(step.used or {}) do
        t:Detail(("%s x%s  ·  %s"):format(ItemLink(entry[1]), Count(entry[2]),
            Color(L["made in an earlier step"], "green")))
    end
    for _, entry in ipairs(step.prepared or {}) do
        local recipe = byRecipe[entry[1]]
        if recipe then
            t:Detail((L["Make it yourself first: %s x%s"]):format(RecipeIcon(recipe) .. RecipeName(recipe),
                Count(entry[2])))
        end
    end
end

-- 材料明细：每种材料的数量、单价与来源、小计（crafts 为制作次数）；用于缺价的步骤与“要自己做的材料”
local function ReagentDetails(t, recipe, crafts)
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        local item, each = reagents[index], reagents[index + 1] or 1
        local total = each * crafts
        local price, source = Prices.BuyCost(item)
        if price then
            t:Detail(("%s x%s  ·  %s %s  =  %s"):format(ItemLink(item), Count(total), Money(price),
                Color(Origin(source), "muted"), Money(price * total)))
        else
            t:Detail(("%s x%s  ·  %s"):format(ItemLink(item), Count(total), Color(L["no price yet"], "red")))
        end
    end
end

-- 在冲级路线里：第几步、区间、次数、涨点几率、这一步的花费与买的材料，可替换的配方。
-- 可收起：冲级视角里默认展开，其他视角默认收起（closed）
local function RouteSection(t, step, index, byRecipe, closed)
    local recipe = step.recipe
    if not t:Section(L["On the leveling route"], closed and "route:other" or "route", 10, closed,
        (L["Step %d"]):format(index)) then
        return
    end
    if step.forced or step.stock then
        t:Detail((L["Step %d · %s x%s"]):format(index, step.forced and L["Tool"] or L["Stock up"], Count(step.crafts)))
        t:Detail(Color(step.forced and L["Later recipes need this in your bags: make one and keep it"]
            or L["Makes materials for the steps after it; it gives no skill"], "muted"))
    else
        t:Detail((L["Step %d · skill %d-%d · about %s crafts"]):format(index, step.from, step.to, Count(step.crafts)))
        local first = ns.LevelingPlan.Chance(recipe, step.from)
        local last = ns.LevelingPlan.Chance(recipe, step.to - 1)
        t:Detail(Color((L["Skill-up chance %d%% to %d%%, about %s crafts for %d points"]):format(
            floor(first * 100 + 0.5), floor(last * 100 + 0.5), Count(step.crafts), step.to - step.from), "muted"))
    end
    if step.commission then
        t:Detail(Color(L["Enchant other players' gear with their materials: no cost to you"], "green"))
    elseif step.unpriced then
        t:Detail(Color(L["no price yet"], "red"))
        ReagentDetails(t, recipe, step.crafts)
    else
        t:Detail((L["Materials for this step: %s"]):format(Money(step.cash)))
        StepDetails(t, step, byRecipe)
    end
    for _, other in ipairs(step.alternatives or {}) do
        t:Detail(Color(L["or"], "muted") .. " " .. RecipeIcon(other.recipe) .. Color(RecipeName(other.recipe), "muted"))
    end
end

-- 学习来源：学习技能、训练师 / 商人（点一行在地图上标出）/ 商人青睐 / 掉落 / 任务，图纸的拍卖价。
-- 可收起：已学的配方默认收起
local function LearnSection(t, recipe, side)
    if not t:Section(L["Where to learn it"], KnownRecipe(recipe) and "learn:known" or "learn", 10, KnownRecipe(recipe)) then
        return
    end
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
    if recipe.favor then
        t:Detail(("%s  ·  %s"):format(ItemLink(item), FavorPrice(recipe.favor, side)))
        t:Detail(Color(L["Bought from the Merchant's Favor vendors: trade the currency for it"], "muted"))
    elseif vendor then
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
        t:Detail(Color(L["World drop"], "muted"))
    end
end

-- 代工附魔的勾选表：当前技能到目标技能之间还能按代工算的附魔（学得到、还没变绿），点一行勾选或取消
local function PickerSection(t, profession, from, to)
    local settings = Settings("route", ROUTE_DEFAULTS)
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
    local chosen = 0
    for _, recipe in ipairs(list) do
        chosen = chosen + (picks[recipe.id] and 1 or 0)
    end
    if not t:Section((L["Customer enchants: %d of %d ticked"]):format(chosen, #list), "picker", 10, true) then
        return
    end
    local function Changed()
        Invalidate()
        Refresh()
    end
    t:Detail(Color(L["Tick only the enchants people actually bring you materials for."], "muted"))
    t:Detail(Color(onRoute and L["On the handbook route a ticked enchant is free for all its casts."]
        or L["They count as free skill-ups while orange or yellow; every other enchant uses your own materials."],
        "muted"))
    t:Action(L["Tick all"], function()
        for _, recipe in ipairs(list) do
            picks[recipe.id] = true
        end
        Changed()
    end)
    t:Action(L["Clear all"], function()
        for _, recipe in ipairs(list) do
            picks[recipe.id] = nil
        end
        Changed()
    end)
    t:Header(COLUMNS.pick)
    for index, recipe in ipairs(list) do
        local checked = picks[recipe.id] and true or false
        local cost = Prices and CastCost(recipe)
        t:Check(COLUMNS.pick, recipe, {
            a = ("%d-%d"):format(math.max(from, recipe.learn or recipe.skill[1]), recipe.skill[2]),
            b = RecipeIcon(recipe) .. Color(RecipeName(recipe), Difficulty(recipe, { rank = from }) or "text"),
            c = cost and Money(cost) or Color(L["no price yet"], "muted"),
            d = KnownRecipe(recipe) and "" or Color(L["not learned"], "muted"),
        }, index % 2 == 1, checked, function()
            picks[recipe.id] = not checked or nil
            Changed()
        end)
    end
end

-- 路线总览的正文：提示、代工附魔、要自己做的材料、要买的图纸、购物清单、成品去向
-- 训练师详情：位置、能教到哪一档（与你下一档的关系、学习要求）、在这里现在能学的配方
local RANK_CAP = { apprentice = 75, journeyman = 150, expert = 225, artisan = 300 }
-- 学下一档的要求（技能、角色等级）：中级、高级是游戏内训练师窗口实测，大师级按原版默认值
local RANK_NEEDS = { journeyman = { 50, 10 }, expert = { 125, 20 }, artisan = { 200, 35 } }
R.RANK_NEEDS = RANK_NEEDS -- 供测试使用
-- 副专业（烹饪、急救、钓鱼）的大师级是任务，要技能 225（无限副本手册与网站钓鱼攻略一致）
local SECONDARY_NEEDS = { artisan = { 225, 35 } }
local SECONDARY = { cooking = true, ["first-aid"] = true, fishing = true }
local function RankNeeds(profession, rank)
    return SECONDARY[profession.slug] and SECONDARY_NEEDS[rank] or RANK_NEEDS[rank]
end

-- 训练师名字：按 NPC ID 取客户端的（当前客户端语言），客户端还没缓存时用数据里的名字
local function TrainerName(trainer)
    return ns.NpcName(trainer.id) or Name(trainer.name) or "?"
end

-- 训练师分组的标题：卖技能书、给晋级任务的 NPC 单独写明，不叫“训练师”
local KIND_HEADING = { book = "%s: skill book", quest = "%s: quest" }
local function RankHeading(rank, kind)
    if rank == "none" then
        return L["Trainers"]
    end
    return (L[KIND_HEADING[kind] or "%s trainers"]):format(ns.TrainerRankName(rank))
end

local function FactionName(faction)
    if faction == "A" then
        return FACTION_ALLIANCE or L["Alliance"]
    elseif faction == "H" then
        return FACTION_HORDE or L["Horde"]
    elseif faction == "AH" then
        return L["Both factions"]
    end
end

local function TrainerSpotText(trainer)
    local map = ns.MapName(trainer.map) or "?"
    if trainer.x then
        return ("%s  %s"):format(map, Color(("%.1f, %.1f"):format(trainer.x, trainer.y), "muted"))
    end
    return ("%s  %s"):format(map, Color(L["spot not recorded yet"], "muted"))
end

-- 这位训练师教的配方里你还没学的：不是随档位自带、也不是图纸学的；有等级的训练师只算他那一档以内的
local function TrainerRecipes(profession, trainer)
    local cap = trainer.rank and RANK_CAP[trainer.rank]
    local rows = {}
    for _, recipe in ipairs(profession.recipes or {}) do
        if not recipe.auto and not recipe.learnedFrom and not KnownRecipe(recipe)
            and (not cap or (recipe.learn or 1) <= cap) then
            tinsert(rows, recipe)
        end
    end
    table.sort(rows, function(a, b)
        if (a.learn or 1) ~= (b.learn or 1) then
            return (a.learn or 1) < (b.learn or 1)
        end
        return RecipeName(a) < RecipeName(b)
    end)
    return rows
end

local function TrainerBody(t, profession, skill, trainer, here)
    t:Heading(L["Location"])
    local where = TrainerSpotText(trainer)
    if trainer.map == here then
        where = where .. "  " .. Color(L["You are in this zone"], "green")
    end
    t:Detail(where, trainer.x and { trainer.map, trainer.x, trainer.y, title = TrainerName(trainer) } or nil)
    t:Detail(Color(trainer.x and L["Click to mark it on the map."] or L["Exact spot not recorded yet."], "muted"))

    t:Heading(L["What they teach"], 8)
    local order = ns.TRAINER_RANK_ORDER
    local cap = trainer.rank and RANK_CAP[trainer.rank]
    if trainer.kind == "book" and cap then
        t:Detail((L["Sells the %s skill book: read it to raise the cap to %d"]):format(ns.TrainerRankName(trainer.rank), cap))
    elseif trainer.kind == "quest" and cap then
        t:Detail((L["Gives the %s quest: finish it to raise the cap to %d"]):format(ns.TrainerRankName(trainer.rank), cap))
    elseif cap then
        t:Detail((L["Teaches up to %s: skill cap %d"]):format(ns.TrainerRankName(trainer.rank), cap))
    elseif trainer.rank then
        t:Detail((L["Trainer rank: %s"]):format(ns.TrainerRankName(trainer.rank)))
    else
        t:Detail(Color(L["Rank not recorded: talk to the trainer to see what they teach"], "muted"))
    end
    local need = ns.NextTrainerRank(skill)
    if not need then
        t:Detail(Color(L["You have reached the highest rank"], "muted"))
    elseif trainer.rank and order[trainer.rank] and order[trainer.rank] < order[need] then
        t:Detail(Color((L["Your next rank is %s: this trainer only teaches up to %s"]):format(
            ns.TrainerRankName(need), ns.TrainerRankName(trainer.rank)), "red"))
    elseif not skill then
        t:Detail(Color(L["You have not learned this profession yet: this trainer can start you off"], "green"))
    else
        local needs = RankNeeds(profession, need)
        t:Detail(Color((L["Can teach your next rank: %s"]):format(ns.TrainerRankName(need)), "green"))
        if needs then
            local ready = skill.rank >= needs[1]
            t:Detail((L["Needs skill %d and level %d"]):format(needs[1], needs[2]) .. "  "
                .. Color(ready and L["Your skill is high enough"]
                    or (L["%d more skill to go"]):format(needs[1] - skill.rank), ready and "green" or "muted"))
        end
    end
    if not trainer.kind then
        t:Detail(Color(L["Higher-rank trainers also teach the lower ranks"], "muted"))
    end
    local faction = FactionName(trainer.faction)
    if faction then
        t:Detail((L["Faction: %s"]):format(faction))
    end

    local rank = skill and skill.rank or 0
    local now, later = {}, nil
    for _, recipe in ipairs(TrainerRecipes(profession, trainer)) do
        if (recipe.learn or 1) <= rank then
            tinsert(now, recipe)
        elseif not later then
            later = recipe
        end
    end
    if t:Section((L["Recipes to learn here now (%d)"]):format(#now), "trainerRecipes", 8) then
        if #now > 0 then
            t:Header(COLUMNS.learn)
            for index, recipe in ipairs(now) do
                t:Row(COLUMNS.learn, recipe, { a = RecipeIcon(recipe) .. Color(RecipeName(recipe), Difficulty(recipe, skill) or "text"),
                    b = tostring(recipe.learn or 1) },
                    index % 2 == 1)
            end
        elseif skill then
            t:Detail(Color(L["Nothing new to learn here right now"], "muted"))
        end
        if later then
            t:Detail(Color((L["Next new recipe at skill %d: %s"]):format(later.learn or 1, RecipeName(later)), "muted"))
        end
    end
end

-- 购物清单的一件物品在哪买：商人、本阵营拍卖行、中立拍卖行取单价最低的（拍卖行用最低一口价，与鼠标提示一致）。
-- 返回 "vendor" / "auction" / "neutral" 与单价；三处都没价格时按路线算的均价、归本阵营拍卖行
local function ShoppingMarket(entry)
    local market, unit
    for _, kind in ipairs({ "vendor", "auction", "neutral" }) do
        local price
        if kind == "vendor" then
            price = Prices.Vendor(entry.item)
        elseif kind == "auction" then
            price = Prices.Auction(entry.item)
        else
            price = Prices.Neutral(entry.item)
        end
        if price and (not unit or price < unit) then
            market, unit = kind, price
        end
    end
    if not unit then
        return "auction", entry.cost / math.max(1, entry.count)
    end
    return market, unit
end
R.ShoppingMarket = ShoppingMarket -- 供测试使用

-- 背包里有几个（不含银行）
local function InBags(itemID)
    return C_Item.GetItemCount and C_Item.GetItemCount(itemID) or 0
end

-- 购物清单：路线从当前技能算到目标要买的材料，减去背包里已有的，剩下的按 商人 / 本阵营拍卖行 / 中立拍卖行 分组
-- （组标题写件数与小计，组之间细线分隔），物品 / 数量 / 单价 / 总价；背包里已经够的放在最后一组。
-- 点开一件物品，三处各一行：单价与买齐的总价、拍卖行的在售数量，选中的那处背景高亮，没有记录的写“暂无价格”
local function ShoppingList(t, shopping)
    local groups = { vendor = {}, auction = {}, neutral = {}, bags = {} }
    for _, entry in ipairs(shopping) do
        local have = InBags(entry.item)
        local buy = math.max(0, math.ceil(entry.count - have - 1e-9))
        local market, unit = ShoppingMarket(entry)
        tinsert(groups[buy > 0 and market or "bags"], { entry = entry, have = have, buy = buy, market = market, unit = unit })
    end
    local none = Color(L["no price yet"], "muted")
    t:Header(COLUMNS.cost)
    local first = true
    for _, group in ipairs({ "vendor", "auction", "neutral", "bags" }) do
        local list = groups[group]
        if #list > 0 then
            if not first then
                t:Rule()
            end
            first = false
            local subtotal = 0
            for _, line in ipairs(list) do
                subtotal = subtotal + line.unit * line.buy
            end
            local title = group == "bags" and L["Already in your bags"] or SourceLabel(group)
            t:Line(COLUMNS.cost, { a = Color(title, "gold") .. Color(("  (%d)"):format(#list), "muted"),
                d = group ~= "bags" and Color(Money(subtotal), "gold") or "" })
            for _, line in ipairs(list) do
                local entry, buy, market = line.entry, line.buy, line.market
                local notes = {}
                if line.have > 0 then
                    tinsert(notes, Color((L["need %s, %d in bags"]):format(Count(entry.count), line.have), "muted"))
                end
                local listed = market == "auction" and Prices.Available(entry.item)
                if buy > 0 and listed and buy > listed then
                    tinsert(notes, Color((L["%s short on the auction house"]):format(Count(buy - listed)), "red"))
                end
                local cells = { a = ItemLink(entry.item) .. (#notes > 0 and "  " .. table.concat(notes, "  ") or "") }
                if buy > 0 then
                    cells.b, cells.c, cells.d = Count(buy), Money(line.unit), Money(line.unit * buy)
                end
                local open = t:Line(COLUMNS.cost, cells, nil, entry.item, buy > 0 and ("shop:" .. entry.item) or nil)
                if open then
                    local function Row(kind, unit, count)
                        t:Line(COLUMNS.cost, {
                            a = "      " .. SourceLabel(kind)
                                .. (count and Color("  " .. (L["%d listed"]):format(count), "muted") or ""),
                            b = unit and Count(buy) or "", c = unit and Money(unit) or none,
                            d = unit and Money(unit * buy) or "",
                        }, nil, entry.item, nil, kind == market)
                    end
                    Row("vendor", Prices.Vendor(entry.item))
                    local auction = Prices.Auction(entry.item)
                    Row("auction", auction, auction and Prices.Available(entry.item))
                    local neutral = Prices.Neutral(entry.item)
                    Row("neutral", neutral, neutral and Prices.Available(entry.item, "neutral"))
                end
            end
        end
    end
end

local function OverviewBody(t, profession, route)
    local plan = route.plan
    local notes = {}
    if plan.missing and #plan.missing > 0 then
        local ranges = {}
        for index = 1, math.min(3, #plan.missing) do
            ranges[index] = ("%d-%d"):format(plan.missing[index][1], plan.missing[index][2])
        end
        local text = (L["Not counted, no prices: skill %s"]):format(table.concat(ranges, ", "))
        if #plan.missing > 3 then
            text = text .. (L[" and %d more"]):format(#plan.missing - 3)
        end
        tinsert(notes, Color(text, "red"))
    end
    if plan.unpriced > 0 then
        tinsert(notes, Color((L["%d recipes left out: a material has no price yet"]):format(plan.unpriced), "muted"))
    end
    if plan.fixed then
        tinsert(notes, Color(L["Handbook route: the guide's fixed order at today's prices"], "muted"))
    end
    if plan.locked then
        tinsert(notes, Color(L["Locked route: same recipes and crafts as when you locked it, at today's prices"], "muted"))
        if route.from >= route.to then
            tinsert(notes, Color(L["The locked route is finished: unlock it to work out a new one"], "gold"))
        end
    end
    local crafted = false
    for _, step in ipairs(plan.steps) do
        crafted = crafted or not step.gap
    end
    if not crafted then
        tinsert(notes, Color(L["Scan the auction house or visit vendors first: material prices are needed"], "muted"))
    end
    for _, note in ipairs(notes) do
        t:Detail(note)
    end
    if #notes > 0 then
        t:Gap(6)
    end
    if HasCommissions(profession) then
        PickerSection(t, profession, route.from, route.to)
    end
    local makers = {} -- 成品是路线里哪个配方做的（成品去向里算回本率用）
    for _, step in ipairs(plan.steps) do
        if step.recipe and step.recipe.makes then
            makers[step.recipe.makes] = makers[step.recipe.makes] or step.recipe
        end
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
            }, index % 2 == 1, nil, entry.recipe.learnedFrom)
        end
    end
    if #plan.shopping > 0 and t:Section((L["Shopping list (%d)"]):format(#plan.shopping), "shopping", 10) then
        ShoppingList(t, plan.shopping)
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
                local maker = makers[product.item]
                local entry = maker and Profit(maker)
                if entry and entry.cost > 0 then
                    t:Detail("    " .. Color((L["Payback %d%%"]):format(floor(entry.value / entry.cost * 100 + 0.5)),
                        entry.value >= entry.cost and "green" or "gold"))
                end
                local tier, reason = Tier(product.item)
                local label = TIER_LABEL[tier]
                t:Detail("    " .. Color(L[label[1]], label[2]) .. Color("  ·  " .. L[TIER_REASON[reason]], "muted"))
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 左栏：三种视角的条目
--------------------------------------------------------------------------------

local MODE_ITEMS -- 路线下拉框的选项（建台时填）
local query = "" -- 搜索词（只在本次登录内记着，不存盘）
local opened = { earlier = false } -- 折叠行是否展开：已走过的步骤

local function Matches(text, q)
    return q == "" or (text and text:lower():find(q, 1, true) ~= nil)
end

local function ItemNameOf(itemID)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if not name then
        ns.RequestItem(itemID)
    end
    return name
end

-- 配方名、图纸名、成品名、材料名里有搜索词
local function RecipeMatches(recipe, q)
    if q == "" or Matches(RecipeName(recipe), q) then
        return true
    end
    if recipe.learnedFrom and Matches(ItemNameOf(recipe.learnedFrom), q) then
        return true
    end
    if recipe.makes and Matches(ItemNameOf(recipe.makes), q) then
        return true
    end
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        if Matches(ItemNameOf(reagents[index]), q) then
            return true
        end
    end
    return false
end

local function RecipeText(recipe, skill)
    return RecipeIcon(recipe) .. Color(RecipeName(recipe), Difficulty(recipe, skill) or "text")
end

local function StepEntry(id, step, index)
    local recipe = step.recipe
    if step.gap then
        return { id = id, divider = true, text = Color(("%d-%d  "):format(step.from, step.to)
            .. L["No recipe with known prices pays here"], "muted") }
    end
    local tags
    if step.forced or step.stock then
        tags = Color(step.forced and L["Tool"] or L["Stock up"], "gold") .. "  x" .. Count(step.crafts)
    else
        tags = ("%d-%d  x%s"):format(step.from, step.to, Count(step.crafts))
    end
    if step.commission then
        tags = Color(L["Customer's materials"], "green") .. "  " .. tags
    elseif step.unpriced then
        tags = Color(L["no price yet"], "red") .. "  " .. tags
    end
    return { id = id, recipe = recipe, step = step, index = index, text = RecipeText(recipe, { rank = step.from }),
        tags = tags }
end

-- 训练师：本阵营能用的（阵营未知、双方都能用的也算），所在地图是当前地图的排前，再按地图名、名字。
-- 训练师数据来自网站（QuestieDB Forever 版加游戏内实测坐标），与大地图用的是同一份
-- 配方数据（Data/Recipes.lua）里的专业不带训练师，按 slug 到专业数据（Data/Professions.lua）里找
local function TrainerList(profession)
    if profession.trainers then
        return profession.trainers
    end
    for _, other in ipairs(ns.Data.professions or {}) do
        if other.slug == profession.slug then
            return other.trainers or {}
        end
    end
    return {}
end

local function Trainers(profession)
    local faction = ns.PlayerFaction()
    local here = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local rows = {}
    for _, trainer in ipairs(TrainerList(profession)) do
        if not trainer.faction or trainer.faction == "AH" or not faction or trainer.faction == faction then
            tinsert(rows, trainer)
        end
    end
    table.sort(rows, function(a, b)
        if (a.map == here) ~= (b.map == here) then
            return a.map == here
        end
        local ma, mb = ns.MapName(a.map) or "", ns.MapName(b.map) or ""
        if ma ~= mb then
            return ma < mb
        end
        return TrainerName(a) < TrainerName(b)
    end)
    return rows, here
end
R.Trainers = Trainers -- 供测试使用

local function TrainerMatches(trainer, q)
    return Matches(TrainerName(trainer), q) or Matches(ns.MapName(trainer.map), q)
end

-- “训练师”视角：本阵营的训练师按可教到的等级分组，下一档该找的那一组排最前、标金色，
-- 其余按等级从低到高，头衔不写等级的（如采矿）放最后；组内当前所在地区的在前。搜索按名字或地区名筛选
local function TrainerEntries(profession, skill, entries)
    local trainers, here = Trainers(profession)
    local target = ns.TargetTrainerRank(trainers, skill)
    local order = ns.TRAINER_RANK_ORDER
    local q = query:lower()
    local groups, keys = {}, {}
    for _, trainer in ipairs(trainers) do
        if q == "" or TrainerMatches(trainer, q) then
            local key = (trainer.rank or "none") .. (trainer.kind and (":" .. trainer.kind) or "")
            if not groups[key] then
                groups[key] = {}
                tinsert(keys, key)
            end
            tinsert(groups[key], trainer)
        end
    end
    local function RankOf(key)
        return key:match("^[^:]+")
    end
    table.sort(keys, function(a, b)
        local ra, rb = RankOf(a), RankOf(b)
        if (ra == target) ~= (rb == target) then
            return ra == target
        end
        if ra ~= rb then
            return (order[ra] or 99) < (order[rb] or 99)
        end
        return a < b
    end)
    for _, key in ipairs(keys) do
        local rank = RankOf(key)
        local heading = RankHeading(rank, key:match(":(.+)$"))
        if rank == target then
            heading = Color(heading .. "  ·  " .. L["your next rank"], "gold")
        end
        tinsert(entries, { id = "rank:" .. key, divider = true, text = heading })
        for _, trainer in ipairs(groups[key]) do
            tinsert(entries, { id = "t:" .. tostring(trainer.id), trainer = trainer, target = rank == target,
                text = Color(TrainerName(trainer), rank == target and "gold" or "text"),
                tags = Color(ns.MapName(trainer.map) or "?", trainer.map == here and "green" or "muted") })
        end
    end
    if #keys == 0 then
        tinsert(entries, { id = "noTrainers", divider = true, text = Color(q ~= "" and L["No match"]
            or L["No trainer data for your faction yet."], "muted") })
    end
    return #trainers, target
end

local function RouteEntries(profession, skill, entries)
    local route = RoutePlan(profession, skill)
    if not route then
        local text = (Prices and ns.LevelingPlan) and L["The route is worked out after you leave combat"]
            or L["Price data is not available"]
        tinsert(entries, { id = "none", divider = true, text = Color(text, "muted") })
        return nil, text
    end
    local plan = route.plan
    tinsert(entries, { id = "overview", overview = true, text = Color(L["Route overview"], "gold"),
        tags = plan.net >= 0 and Brief(plan.net) or Color("+" .. Brief(-plan.net), "green") })
    local q = query:lower()
    if route.from > 1 then
        tinsert(entries, { id = "earlier", toggle = "earlier", text = Color((opened.earlier and "- " or "+ ")
            .. (L["Earlier steps, skill %d-%d"]):format(1, route.from), "muted") })
        local earlier = opened.earlier and EarlierPlan(profession, skill, route)
        for index, step in ipairs(earlier and earlier.steps or {}) do
            if step.gap or RecipeMatches(step.recipe, q) then
                tinsert(entries, StepEntry("e:" .. index, step, index))
            end
        end
    end
    tinsert(entries, { id = "steps", divider = true, text = (L["Steps, skill %d-%d"]):format(route.from, route.to) })
    for index, step in ipairs(plan.steps) do
        if (step.gap and q == "") or (not step.gap and RecipeMatches(step.recipe, q)) then
            tinsert(entries, StepEntry("s:" .. index, step, index))
        end
    end
    return route
end

local function SourceEntries(profession, skill, entries)
    local rank = skill and skill.rank or 0
    local side = Side()
    local q = query:lower()
    local known, now, later = {}, {}, {}
    local counts = { total = 0, known = 0, now = 0 }
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.skill and not recipe.nip then
            local isKnown = KnownRecipe(recipe)
            local learn = recipe.auto and 1 or recipe.learn
            local canNow = not isKnown and learn and learn <= rank
            counts.total = counts.total + 1
            counts.known = counts.known + (isKnown and 1 or 0)
            counts.now = counts.now + (canNow and 1 or 0)
            if RecipeMatches(recipe, q) then
                tinsert(isKnown and known or (canNow and now or later), recipe)
            end
        end
    end
    local function Order(a, b)
        local la, lb = a.learn or a.skill[1] or 999, b.learn or b.skill[1] or 999
        if la ~= lb then
            return la < lb
        end
        return a.id < b.id
    end
    local function Group(title, list, learned)
        if #list == 0 then
            return
        end
        table.sort(list, Order)
        tinsert(entries, { id = "g:" .. title, divider = true, text = ("%s (%d)"):format(title, #list) })
        for _, recipe in ipairs(list) do
            local tags
            if learned then
                tags = Color(L["Learned"], "green")
            else
                local source = Source(recipe, side)
                tags = (recipe.learn and (tostring(recipe.learn) .. "  ") or "") .. source
            end
            tinsert(entries, { id = "r:" .. recipe.id, recipe = recipe, text = RecipeText(recipe, skill), tags = tags })
        end
    end
    Group(L["Learned"], known, true)
    Group(L["You can learn these now"], now)
    Group(L["Learnable later"], later)
    -- 商人青睐卖的图纸，网站还没有对应配方的：只列图纸物品
    local formulas = {}
    for _, formula in ipairs(profession.formulas or {}) do
        if q == "" or Matches(ItemNameOf(formula.item), q) then
            tinsert(formulas, formula)
        end
    end
    if #formulas > 0 then
        tinsert(entries, { id = "g:formulas", divider = true,
            text = ("%s (%d)"):format(L["Formulas sold for Merchant's Favor"], #formulas) })
        for _, formula in ipairs(formulas) do
            tinsert(entries, { id = "f:" .. formula.item, formula = formula, item = formula.item,
                text = ItemLink(formula.item),
                tags = (formula.skill and (tostring(formula.skill) .. "  ") or "") .. Color(L["Merchant's Favor"], "gold") })
        end
    end
    if #known + #now + #later + #formulas == 0 then
        tinsert(entries, { id = "none", divider = true, text = Color(L["No recipe matches the search"], "muted") })
    end
    return counts
end

local TIER_ORDER = { high = 3, mid = 2, low = 1, none = 0 }

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

local function ProfitEntries(profession, skill, entries)
    local settings = Settings("profit", PROFIT_DEFAULTS)
    local q = query:lower()
    local list, unpriced, gains = {}, 0, 0
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.makes and recipe.skill and not recipe.nip and (settings.unlearned or KnownRecipe(recipe))
            and RecipeMatches(recipe, q) then
            local entry = Profit(recipe)
            if entry and entry.tier ~= "none" then
                tinsert(list, entry)
                gains = gains + (entry.profit > 0 and 1 or 0)
            elseif not entry then
                unpriced = unpriced + 1
            end
        end
    end
    SortProfit(list, settings.sort, settings.descending)
    for _, entry in ipairs(list) do
        local recipe = entry.recipe
        local color = entry.profit >= 0 and "green" or "red"
        local tags = Color((entry.profit >= 0 and "+" or "-") .. Money(math.abs(entry.profit)), color)
        if settings.sort == "margin" then
            tags = Color(("%+d%%"):format(floor(entry.margin * 100 + 0.5)), color)
        elseif settings.sort == "cost" then
            tags = Money(entry.cost)
        elseif settings.sort == "value" then
            tags = Money(entry.value)
        elseif settings.sort == "tier" then
            local label = TIER_LABEL[entry.tier]
            tags = Color(L[label[1]], label[2])
        end
        local name = RecipeText(recipe, skill)
        if not KnownRecipe(recipe) then
            name = name .. "  " .. Color(L["not learned"], "muted")
        end
        tinsert(entries, { id = "r:" .. recipe.id, recipe = recipe, text = name, tags = tags })
    end
    if #list == 0 then
        tinsert(entries, { id = "none", divider = true,
            text = Color(L["Scan the auction house or visit vendors first: material prices are needed"], "muted") })
    end
    if unpriced > 0 then
        tinsert(entries, { id = "unpriced", divider = true,
            text = Color((L["%d recipes left out: a material has no price yet"]):format(unpriced), "muted") })
    end
    return { priced = #list, gains = gains }
end

--------------------------------------------------------------------------------
-- 刷新：左栏列表与顶栏（RefreshList），右栏详情（RefreshDetail）
--------------------------------------------------------------------------------

local function IsFishing(profession)
    local slug = profession and profession.slug or (bench and bench.slug)
    return slug == "fishing" and R.FishingLens ~= nil
end

-- 当前视角：钓鱼有自己的四个视角（fzones / ffish / fmine / ftrainers，见 WorkbenchFishing.lua）
local function Lens(profession)
    if IsFishing(profession) then
        return R.FishingLens()
    end
    local view = Settings("panel", { view = "route" }).view
    return (view == "sources" or view == "profit" or view == "trainers") and view or "route"
end

-- 全部专业：按专业数据（Data/Professions.lua，12 个）的顺序；能制作的用配方数据里的那一份（带配方），
-- 采集类（草药学、剥皮、钓鱼）没有配方，用专业数据（只有训练师）
local allProfessions
local function AllProfessions()
    if not allProfessions then
        local crafting = {}
        for _, profession in ipairs(R.Professions()) do
            crafting[profession.slug] = profession
        end
        allProfessions = {}
        for _, profession in ipairs(ns.Data.professions or {}) do
            tinsert(allProfessions, crafting[profession.slug] or profession)
            crafting[profession.slug] = nil
        end
        for _, profession in ipairs(R.Professions()) do
            if crafting[profession.slug] then
                tinsert(allProfessions, profession)
            end
        end
    end
    return allProfessions
end

local function ProfessionBySlug(slug)
    for _, profession in ipairs(AllProfessions()) do
        if profession.slug == slug then
            return profession
        end
    end
end

local function Craftable(profession)
    return profession.recipes ~= nil and #profession.recipes > 0
end

-- 专业窗口里打开的专业（窗口没开、在总览页或不认识时为 nil）
local function NativeProfession()
    local window = OpenWindow()
    return window and CurrentProfession(window)
end

-- 当前看的专业与技能：玩家在下拉框里选的优先；没选时跟着专业窗口里的专业；窗口没开或在总览页时用上次看的，
-- 再没有就取第一个已学的专业、第一个专业。专业窗口换了专业（或重新打开）时放弃玩家的选择，跟着窗口走
local function Current()
    local native = NativeProfession()
    if native and native.slug ~= bench.followed then
        bench.followed = native.slug
        bench.chosen = nil
    end
    local panel = Settings("panel")
    local learned = LearnedSkills()
    local profession = (bench.chosen and ProfessionBySlug(bench.chosen)) or native
        or (panel.profession and ProfessionBySlug(panel.profession))
    if not profession then
        for _, candidate in ipairs(AllProfessions()) do
            if learned[candidate.slug] then
                profession = candidate
                break
            end
        end
        profession = profession or AllProfessions()[1]
    end
    if profession then
        panel.profession = profession.slug
    end
    return profession, profession and learned[profession.slug]
end

local function FindRecipe(profession, id)
    for _, recipe in ipairs(profession.recipes or {}) do
        if recipe.id == id then
            return recipe
        end
    end
end

-- 选中的条目：本视角记住的那一个；不在列表里的配方（专业窗口里选中的）也能显示；都没有时取第一个
local function Selected(profession)
    local lens = Lens()
    local id = bench.pick[lens]
    local entry = id and bench.byID[id]
    if not entry and type(id) == "string" and id:sub(1, 2) == "r:" then
        local recipe = FindRecipe(profession, tonumber(id:sub(3)))
        entry = recipe and { id = id, recipe = recipe }
    end
    if not entry then
        for _, candidate in ipairs(bench.entries) do
            if not candidate.divider and not candidate.toggle then
                entry = candidate
                break
            end
        end
        bench.pick[lens] = entry and entry.id
    end
    return entry
end

-- 路线里做这个配方的那一步（冲级视角选中步骤时就是它；其他视角在已算好的路线里找）
local function StepOf(entry)
    if entry.step then
        return entry.step, entry.index
    end
    local plan = routeCache and routeCache.plan
    for index, step in ipairs(plan and plan.steps or {}) do
        if step.recipe == entry.recipe and not step.gap then
            return step, index
        end
    end
end

local function SetSkillBar(bar, ratio)
    bar.fill:SetWidth(math.max(1, bar:GetWidth() * math.min(1, math.max(0, ratio))))
    bar.fill:SetShown(ratio > 0)
end

-- 顶栏的专业图标条：已学的在前，其余按数据顺序
local function ProfessionItems()
    local learned = LearnedSkills()
    local known, others = {}, {}
    for _, profession in ipairs(AllProfessions()) do
        local skill = learned[profession.slug]
        local item = { id = profession.slug, icon = profession.icon, name = Name(profession.name) or profession.slug,
            skill = skill, gathering = not Craftable(profession) }
        tinsert(skill and known or others, item)
    end
    for _, item in ipairs(others) do
        tinsert(known, item)
    end
    return known
end

-- 左栏上部：能制作的专业有三种视角与各自的选项；钓鱼有自己的视角；其余采集类专业只有搜索框与训练师
local function LayoutLeft(craftable, lens, fishing)
    bench.views:SetShown(craftable)
    bench.fishViews:SetShown(fishing)
    if fishing then
        bench.fishViews:Select(lens:sub(2))
        bench.search:ClearAllPoints()
        bench.search:SetPoint("TOPLEFT", 10, -38)
        bench.list:ClearAllPoints()
        bench.list:SetPoint("TOPLEFT", 4, -68)
        bench.list:SetPoint("BOTTOMRIGHT", -4, 6)
        bench.routeOptions:Hide()
        bench.profitOptions:Hide()
        return
    end
    bench.routeOptions:SetShown(craftable and lens == "route")
    bench.profitOptions:SetShown(craftable and lens == "profit")
    bench.search:ClearAllPoints()
    bench.search:SetPoint("TOPLEFT", 10, craftable and -38 or -8)
    bench.list:ClearAllPoints()
    local options = craftable and (lens == "route" or lens == "profit")
    bench.list:SetPoint("TOPLEFT", 4, options and -98 or (craftable and -68 or -38))
    bench.list:SetPoint("BOTTOMRIGHT", -4, 6)
end

function RefreshList()
    if not (bench and bench:IsVisible()) then
        return
    end
    local profession, skill = Current()
    local lens = Lens(profession)
    bench.views:Select(lens)
    bench.left:SetShown(profession ~= nil)
    bench.right:SetShown(profession ~= nil)
    bench.entries, bench.byID = {}, {}
    bench.picker:SetItems(ProfessionItems())
    if not profession then
        bench.summary:SetText("")
        bench.skill:Hide()
        bench.skillText:SetText("")
        return
    end
    -- 换了专业：上一个专业的选中项、展开状态不再适用
    if bench.slug ~= profession.slug then
        bench.slug = profession.slug
        wipe(bench.pick)
        wipe(bench.expanded)
        opened.earlier = false
    end
    bench.picker:SetValue(profession.slug)
    bench.professionName:SetText(Name(profession.name) or profession.slug)
    bench.skill:SetShown(skill ~= nil)
    bench.skillText:SetText(skill and ("%d / %d"):format(skill.rank, skill.max) or Color(L["not learned"], "muted"))
    if skill then
        SetSkillBar(bench.skill, skill.max > 0 and skill.rank / skill.max or 0)
    end
    local craftable = Craftable(profession)
    local fishing = IsFishing(profession)
    LayoutLeft(craftable, lens, fishing)
    local summary
    if fishing and lens ~= "ftrainers" then
        local default
        summary, default = R.FishingEntries(lens, bench.entries, query)
        if default and not bench.pick[lens] then
            bench.pick[lens] = default
        end
    elseif fishing then
        summary = (L["%d trainers for your faction"]):format((TrainerEntries(profession, skill, bench.entries)))
    elseif not craftable then
        tinsert(bench.entries, { id = "gathering", divider = true,
            text = Color(L["Levels by gathering: no recipes to craft"], "muted") })
        summary = (L["%d trainers for your faction"]):format((TrainerEntries(profession, skill, bench.entries)))
    elseif lens == "trainers" then
        summary = (L["%d trainers for your faction"]):format((TrainerEntries(profession, skill, bench.entries)))
    elseif lens == "route" then
        local settings = Settings("route", ROUTE_DEFAULTS)
        local handbook = profession.route ~= nil
        if not handbook then
            settings.mode = "live"
        end
        bench.mode:SetItems(handbook and MODE_ITEMS.all or MODE_ITEMS.calculated)
        local priority = ns.LevelingPlan.PRIORITY[settings.priority or ""] and settings.priority or "balanced"
        bench.mode:SetValue(settings.mode == "handbook" and "handbook" or priority)
        local lock = settings.mode ~= "handbook" and R.LockedRoute(profession)
        bench.target:SetValue(lock and lock.to or RouteTarget(settings, skill and skill.rank or 1))
        local route, message = RouteEntries(profession, skill, bench.entries)
        summary = message or (L["Skill %d-%d"]):format(route.from, route.to)
        -- 锁定按钮：按价格算的路线才有；锁定中写“解锁路线”并保持选中样式
        local locked = settings.mode ~= "handbook" and R.LockedRoute(profession) ~= nil
        bench.lockButton:SetShown(settings.mode ~= "handbook")
        bench.lockButton:SetLabel(locked and L["Unlock route"] or L["Lock route"])
        bench.lockButton:SetSelected(locked)
    elseif lens == "sources" then
        local counts = SourceEntries(profession, skill, bench.entries)
        summary = (L["%d recipes · %d learned · %d learnable now"]):format(counts.total, counts.known, counts.now)
    else
        local settings = Settings("profit", PROFIT_DEFAULTS)
        bench.sort:SetValue(settings.sort)
        bench.unlearned:SetChecked(settings.unlearned)
        local counts = ProfitEntries(profession, skill, bench.entries)
        summary = (L["%d recipes priced · %d make a profit"]):format(counts.priced, counts.gains)
    end
    bench.summary:SetText(summary)
    for _, entry in ipairs(bench.entries) do
        bench.byID[entry.id] = entry
    end
    local selected = Selected(profession)
    bench.list:SetData(bench.entries, selected and selected.id)
end

local function IconTexture(recipe)
    return recipe.makes and C_Item.GetItemIconByID(recipe.makes)
        or (C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(recipe.id))
end

-- 右栏标题区：图标、名字、一行说明，右侧一到三栏数字。stats = { { 大字, 说明 }, ... }，从左到右，
-- 最后一栏贴着右边；名字与说明让到数字栏左边
local STAT_GAP = 18
local function SetHeadStats(icon, name, sub, stats)
    bench.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    bench.name:SetText(name or "")
    bench.sub:SetText(sub or "")
    local x, shown = 14, #stats
    for index = 3, 1, -1 do
        local column = bench.stats[index]
        local stat = stats[shown - (3 - index)]
        column.value:SetShown(stat ~= nil)
        column.label:SetShown(stat ~= nil)
        if stat then
            column.value:SetText(stat[1] or "")
            column.label:SetText(stat[2] or "")
            column.value:ClearAllPoints()
            column.value:SetPoint("TOPRIGHT", bench.right, "TOPRIGHT", -x, -10)
            local width = math.max(column.value:GetStringWidth() or 0, column.label:GetStringWidth() or 0)
            x = x + width + STAT_GAP
        else
            column.value:SetText("")
            column.label:SetText("")
        end
    end
    bench.name:ClearAllPoints()
    bench.name:SetPoint("TOPLEFT", bench.headIcon, "TOPRIGHT", 10, -2)
    bench.name:SetPoint("TOPRIGHT", bench.right, "TOPRIGHT", -(x - STAT_GAP + 12), -12)
end

local function SetHead(icon, name, sub, big, caption)
    SetHeadStats(icon, name, sub, { { big, caption } })
end
R.SetHead = SetHead

-- 难度色条：学习 → 变黄 → 变绿 → 变灰，再留一段灰色；白色竖线是当前技能
local function ShowDifficulty(recipe, skill)
    local bar = bench.difficulty
    local points = recipe and recipe.skill
    bar:SetShown(points ~= nil)
    if not points then
        return
    end
    -- 色条的范围：从能学（没有学习技能时从变黄前 10 点）到变灰后再留一截；当前技能在范围外时把范围扩到它，
    -- 标记永远画在真实位置上
    local learn = recipe.learn
    local start = math.max(1, math.min(learn or (points[1] - 10), points[1]))
    local rank = skill and skill.rank
    local low = start
    local high = points[3] + math.max(5, floor((points[3] - start) * 0.2 + 0.5))
    if rank and rank < low then
        low = math.max(0, rank - 3)
    end
    if rank and rank > high - 2 then
        high = rank + 3
    end
    local marks = { low, start, points[1], points[2], points[3], high }
    local width = math.max(100, bar:GetWidth() or 0)
    local span = math.max(1, high - low)
    local function X(value)
        return width * (value - low) / span
    end
    for index, segment in ipairs(bar.segments) do
        local x, w = X(marks[index]), X(marks[index + 1]) - X(marks[index])
        segment:ClearAllPoints()
        segment:SetPoint("TOPLEFT", x, -DIFFICULTY_BAR_TOP)
        segment:SetSize(math.max(1, w), DIFFICULTY_BAR_HEIGHT)
        segment:SetShown(w > 0)
    end
    -- 文字按中心摆在 x 处，不超出色条两端；返回左右边界
    local function Place(text, x, y, anchor)
        local w = text:GetStringWidth() or 0
        local center = math.min(math.max(x, w / 2), width - w / 2)
        text:ClearAllPoints()
        text:SetPoint(anchor, bar, "TOPLEFT", center, y)
        return center - w / 2, center + w / 2
    end
    -- 当前技能：粗竖线（带深色描边）穿过色条，上方写“当前 217”，颜色是现在这个配方的难度色
    bar.marker:SetShown(rank ~= nil)
    bar.markerEdge:SetShown(rank ~= nil)
    bar.now:SetShown(rank ~= nil)
    if rank then
        local x = X(rank)
        bar.marker:ClearAllPoints()
        bar.marker:SetPoint("TOP", bar, "TOPLEFT", x, -(DIFFICULTY_BAR_TOP - 4))
        bar.markerEdge:ClearAllPoints()
        bar.markerEdge:SetPoint("CENTER", bar.marker, "CENTER")
        local tone = learn and rank < learn and "muted" or Difficulty(recipe, skill) or "text"
        bar.now:SetText(Color((L["Now %d"]):format(rank), tone))
        Place(bar.now, x, -(DIFFICULTY_BAR_TOP - 5), "BOTTOM")
    end
    -- 色条下方：学习与变黄、变绿、变灰的技能写在各自的位置上，挤在一起时后面的不写
    local ticks = {}
    if learn then
        tinsert(ticks, { learn, Color((L["Learn at %d"]):format(learn), "muted") })
    end
    tinsert(ticks, { points[1], Color(tostring(points[1]), "skillYellow") })
    tinsert(ticks, { points[2], Color(tostring(points[2]), "skillGreen") })
    tinsert(ticks, { points[3], Color(tostring(points[3]), "skillGray") })
    table.sort(ticks, function(a, b) return a[1] < b[1] end)
    local right = -math.huge
    for index, label in ipairs(bar.ticks) do
        local tick = ticks[index]
        label:SetShown(tick ~= nil)
        if tick then
            label:SetText(tick[2])
            local left, edge = Place(label, X(tick[1]), -(DIFFICULTY_BAR_TOP + DIFFICULTY_BAR_HEIGHT + 6), "TOP")
            if left < right + 6 then
                label:Hide()
            else
                right = edge
            end
        end
    end
end
R.ShowDifficulty = ShowDifficulty -- 供测试使用

-- 底部按钮：只摆出现在能用的；一个都没有时显示提示。trainer 不为空时只有“在地图上标出训练师”
local function ShowActions(recipe, side, trainer)
    local shown = {}
    if trainer then
        bench.mapButton:SetLabel(L["Mark the trainer on the map"])
        bench.mapButton.spot = trainer.x and { trainer.map, trainer.x, trainer.y, title = TrainerName(trainer) } or nil
    else
        bench.mapButton:SetLabel(L["Mark the vendor on the map"])
    end
    local search = recipe and SearchEnabled() and AuctionOpen()
    bench.searchButton:SetShown(search and true or false)
    if search then
        tinsert(shown, bench.searchButton)
    end
    -- “在专业窗口打开”：专业窗口开着、里面正是这个专业时才有
    local native = recipe and NativeProfession()
    local open = native and native.slug == bench.slug and C_TradeSkillUI and C_TradeSkillUI.OpenRecipe and KnownRecipe(recipe)
    bench.openButton:SetShown(open and true or false)
    if open then
        tinsert(shown, bench.openButton)
    end
    local spot = recipe and recipe.spot and recipe.spot[side]
    if not trainer then
        bench.mapButton.spot = spot and { spot[1], spot[2], spot[3], title = RecipeName(recipe) } or nil
    end
    bench.mapButton:SetShown(bench.mapButton.spot ~= nil)
    if bench.mapButton.spot then
        tinsert(shown, bench.mapButton)
    end
    bench.current = recipe
    local previous
    for _, button in ipairs(shown) do
        button:ClearAllPoints()
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
        else
            button:SetPoint("BOTTOMLEFT", bench.right, "BOTTOMLEFT", 12, 8)
        end
        previous = button
    end
    bench.hint:ClearAllPoints()
    if previous then
        bench.hint:SetPoint("LEFT", previous, "RIGHT", 10, 0)
    else
        bench.hint:SetPoint("BOTTOMLEFT", bench.right, "BOTTOMLEFT", 12, 14)
    end
    bench.hint:SetPoint("RIGHT", bench.right, "RIGHT", -12, 0)
    local hint = ""
    if recipe and SearchEnabled() and not AuctionOpen() then
        hint = L["Open the auction house to search for the materials"]
    end
    bench.hint:SetText(Color(hint, "muted"))
end

-- 路线总览上方的选项与四个数字
local function ShowStrip(route)
    bench.strip:SetShown(route ~= nil)
    if not route then
        return
    end
    local settings = Settings("route", ROUTE_DEFAULTS)
    local plan = route.plan
    bench.recovery:SetChecked(settings.recovery)
    bench.buyRecipes:SetChecked(settings.buyRecipes)
    bench.buyRecipes:SetShown(settings.mode ~= "handbook" and not plan.locked)
    local tiles = bench.tiles
    tiles.materials.title:SetText(L["Materials"])
    tiles.materials:Set(Brief(plan.materials))
    tiles.recipes.title:SetText(L["Recipe items"])
    tiles.recipes:Set(Brief(plan.recipeCost))
    tiles.resale.title:SetText(plan.recovery > 0
        and (L["Resale, at least %s"]):format(Brief(plan.safeRecovery)) or L["Resale value"])
    tiles.resale:Set(Brief(plan.recovery))
    -- 有断档或缺价的路线只是部分预算：标题说明只算了能算的部分
    local partial = plan.missing and #plan.missing > 0
    tiles.net.title:SetText(plan.net >= 0 and (partial and L["Net cost, priced part"] or L["Net cost"])
        or (partial and L["Net profit, priced part"] or L["Net profit"]))
    tiles.net:Set(plan.net >= 0 and Brief(plan.net) or Color("+" .. Brief(-plan.net), "green"))
end

-- 正文区的上边：标题区之下，有难度色条或路线选项时再往下
local function PlaceBody(top)
    bench.body:ClearAllPoints()
    bench.body:SetPoint("TOPLEFT", bench.right, "TOPLEFT", 6, -top)
    bench.body:SetPoint("BOTTOMRIGHT", bench.right, "BOTTOMRIGHT", -14, ACTION_HEIGHT + 4)
end

local function ModeLabel()
    local settings = Settings("route", ROUTE_DEFAULTS)
    if routeCache and routeCache.plan.locked then
        return L["Locked route"]
    end
    local id = settings.mode == "handbook" and "handbook" or settings.priority
    for _, item in ipairs(MODE_ITEMS.all) do
        if item.id == id then
            return item.label
        end
    end
    return ""
end

function RefreshDetail()
    if not (bench and bench:IsVisible()) then
        return
    end
    local profession, skill = Current()
    local t = Table()
    if not profession then
        t:Finish()
        return
    end
    local entry = Selected(profession)
    local side = Side()
    local top = HEAD_HEIGHT
    bench.detailEntry = entry
    if not entry then
        SetHead(nil, "", "", "", "")
        bench.difficulty:Hide()
        ShowStrip(nil)
        ShowActions(nil, side)
    elseif entry.overview and not routeCache then
        -- 路线刚作废（选项改了）还没重算：先重画左栏，它会重算路线并再画右栏
        RefreshList()
        if routeCache then
            RefreshDetail()
        end
        return
    elseif entry.overview then
        local route = routeCache
        local plan = route.plan
        SetHead("Interface\\Icons\\" .. (profession.icon or "INV_Misc_QuestionMark"), L["Route overview"],
            (L["Skill %d-%d"]):format(route.from, route.to) .. "  ·  " .. ModeLabel(),
            plan.net >= 0 and Brief(plan.net) or Color("+" .. Brief(-plan.net), "green"),
            plan.net >= 0 and L["Net cost"] or L["Net profit"])
        bench.difficulty:Hide()
        ShowStrip(route)
        top = top + STRIP_HEIGHT
        -- 下一档要找训练师：一行链接，点了切到“训练师”视角
        local target = ns.TargetTrainerRank((Trainers(profession)), skill)
        if target then
            t:Action((L["Next rank: find a %s trainer (Trainers tab)"]):format(ns.TrainerRankName(target)), function()
                Settings("panel").view = "trainers"
                Refresh()
            end)
            t:Gap(4)
        end
        OverviewBody(t, profession, route)
        ShowActions(nil, side)
    elseif entry.trainer then
        local trainer = entry.trainer
        local here = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        local sub = { trainer.rank and (L["Trainer rank: %s"]):format(ns.TrainerRankName(trainer.rank)) or L["Trainer"] }
        local faction = FactionName(trainer.faction)
        if faction then
            tinsert(sub, faction)
        end
        SetHead("Interface\\Icons\\" .. (profession.icon or "INV_Misc_QuestionMark"),
            Color(TrainerName(trainer), entry.target and "gold" or "text"), table.concat(sub, "  ·  "),
            ns.MapName(trainer.map) or "?",
            trainer.x and ("%.1f, %.1f"):format(trainer.x, trainer.y) or L["spot not recorded yet"])
        bench.difficulty:Hide()
        ShowStrip(nil)
        TrainerBody(t, profession, skill, trainer, here)
        ShowActions(nil, side, trainer)
    elseif entry.fishing then
        bench.difficulty:Hide()
        ShowStrip(nil)
        R.FishingDetail(t, entry, skill)
        ShowActions(nil, side)
    elseif entry.formula then
        local formula = entry.formula
        SetHead(C_Item.GetItemIconByID(formula.item), ItemLink(formula.item), Color(L["Merchant's Favor"], "gold"), "", "")
        bench.difficulty:Hide()
        ShowStrip(nil)
        t:Heading(L["Where to learn it"])
        if formula.skill then
            t:Detail((L["Needs skill %d to learn"]):format(formula.skill))
        end
        t:Detail(FavorPrice({ cost = formula.favor, standing = formula.standing, side = formula.side }, side))
        t:Detail(Color(L["Bought from the Merchant's Favor vendors: trade the currency for it"], "muted"))
        ShowActions(nil, side)
    else
        local recipe = entry.recipe
        local known = KnownRecipe(recipe)
        local sub = {}
        tinsert(sub, known and Color(L["Learned"], "green")
            or Color(recipe.learn and (L["Needs skill %d to learn"]):format(recipe.learn) or L["not learned"], "muted"))
        if recipe.makes then
            local label = TIER_LABEL[(Tier(recipe.makes))]
            tinsert(sub, Color(L[label[1]], label[2]))
        end
        -- 右上角：有成品的配方是 成本 / 卖价 / 利润 三栏（利润带利润率），附魔等没有成品的只有每次的材料
        local result = Prices and Profit(recipe)
        local cost = Prices and recipe.reagents and #recipe.reagents > 0 and select(2, CheapestWay(recipe))
        local dash = Color("—", "muted")
        local stats
        if result then
            local gain = result.profit >= 0
            local color = gain and "green" or "red"
            stats = {
                { Brief(result.cost), L["Cost"] },
                { Brief(result.value), L["Sale price"] },
                { Color((gain and "+" or "-") .. Brief(math.abs(result.profit)), color), L["Profit"]
                    .. (result.cost > 0 and ("  " .. Color(("%+d%%"):format(floor(result.margin * 100 + 0.5)), color)) or "") },
            }
        elseif recipe.makes and Prices then
            stats = { { cost and Brief(cost) or dash, L["Cost"] }, { dash, L["Sale price"] }, { dash, L["Profit"] } }
        elseif cost then
            stats = { { Brief(cost), L["Materials per cast"] } }
        else
            stats = { { Color(L["no price yet"], "muted"), "" } }
        end
        SetHeadStats(IconTexture(recipe), Color(RecipeName(recipe), Difficulty(recipe, skill) or "text"),
            table.concat(sub, "  ·  "), stats)
        ShowDifficulty(recipe, skill)
        ShowStrip(nil)
        top = top + SKILLBAR_HEIGHT
        CostSection(t, recipe)
        if recipe.makes then
            SaleSection(t, recipe)
        end
        local step, index = StepOf(entry)
        if step then
            local byRecipe = {}
            for _, other in ipairs(profession.recipes or {}) do
                byRecipe[other.id] = other
            end
            RouteSection(t, step, index, byRecipe, not entry.step)
        end
        LearnSection(t, recipe, side)
        ShowActions(recipe, side)
    end
    PlaceBody(top)
    t:Finish()
end

function Refresh()
    RefreshList()
    RefreshDetail()
end
R.Refresh = Refresh

-- 背包变了：路线总览开着时只重画右栏（购物清单按背包里的数量重算，路线本身不重算）
function R.BagsChanged()
    if bench and bench:IsVisible() and bench.detailEntry and bench.detailEntry.overview then
        RefreshDetail()
    end
end

-- 选中一个条目（左栏点击、专业窗口里选中配方）；只重画右栏
local function Pick(id)
    bench.pick[Lens()] = id
    bench.list:SetData(bench.entries, id)
    bench.body:ScrollToTop()
    RefreshDetail()
end

-- 专业窗口里选中了某个配方：冲级视角里有这一步就选中那一步，否则按配方显示
local function FocusRecipe(recipeID)
    local profession = Current()
    if not (profession and FindRecipe(profession, recipeID)) then
        return
    end
    local id = "r:" .. recipeID
    if Lens() == "route" then
        for _, entry in ipairs(bench.entries) do
            if entry.recipe and entry.recipe.id == recipeID and entry.id:sub(1, 2) == "s:" then
                id = entry.id
                break
            end
        end
    end
    Pick(id)
    bench.list:ScrollTo(id)
end
R.FocusRecipe = FocusRecipe

-- 左栏点击：“已走过的步骤”切换展开；Shift 点击配方或物品时搜拍卖行或插入链接，并照常选中
local function OnListSelect(id)
    local entry = bench.byID[id]
    if not entry then
        return
    end
    if entry.toggle then
        opened[entry.toggle] = not opened[entry.toggle]
        bench.list.selectedID = bench.pick[Lens()]
        RefreshList()
        return
    end
    if (entry.recipe or entry.item) and IsModifiedClick and IsModifiedClick("CHATLINK") then
        if not ShiftSearch(entry) then
            InsertChatLink(entry.item or entry.recipe.makes)
        end
    end
    Pick(id)
end

R.Select = OnListSelect -- 供测试使用

local function OnListEnter(row, id)
    local entry = bench.byID[id]
    if not entry then
        return
    end
    if entry.trainer then
        local trainer = entry.trainer
        GameTooltip:SetOwner(row, "ANCHOR_LEFT")
        GameTooltip:SetText(TrainerName(trainer), 1, 0.82, 0)
        if trainer.rank then
            GameTooltip:AddLine((L["Trainer rank: %s"]):format(ns.TrainerRankName(trainer.rank)), 1, 1, 1)
        end
        GameTooltip:AddLine(ns.MapName(trainer.map) or "?", 0.85, 0.8, 0.69)
        GameTooltip:Show()
        return
    elseif entry.recipe then
        ShowRecipeTooltip(row, entry.recipe, "ANCHOR_LEFT")
    elseif entry.item then
        GameTooltip:SetOwner(row, "ANCHOR_LEFT")
        GameTooltip:SetItemByID(entry.item)
        GameTooltip:Show()
    else
        return
    end
    if SearchEnabled() and AuctionOpen() and GameTooltip:IsShown() then
        GameTooltip:AddLine(entry.item and L["Shift-click to search the auction house"]
            or L["Shift-click to search the auction house for the product and materials"], 0.27, 0.75, 0.45)
        GameTooltip:Show()
    end
end

R.ListEnter = OnListEnter -- 供测试使用

--------------------------------------------------------------------------------
-- 建台
--------------------------------------------------------------------------------

local function SetCollapsed(collapsed)
    Settings("panel").collapsed = collapsed
    Update()
end

local function Line(parent, horizontal)
    local line = Theme:Fill(parent, "lineSoft", "ARTWORK")
    if horizontal then
        line:SetHeight(1)
    else
        line:SetWidth(1)
    end
    return line
end

-- 选项改了：路线作废，左右两栏都重画
local function Changed()
    Invalidate()
    Refresh()
end

-- 专业图标条：每个专业一个图标，点一下换过去。已学的在前，与没学的之间留一段空；没学的图标变灰变淡，
-- 选中的金边。鼠标提示写专业名与技能。接口与下拉框相同（items、value、onChange、SetItems、SetValue）
local function CreatePicker(onChange)
    local strip = CreateFrame("Frame", nil, bench)
    strip:SetHeight(PICKER_ICON)
    strip.buttons = {}
    strip.onChange = onChange
    local function OnEnter(button)
        local item = button.item
        GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
        GameTooltip:SetText(item.name, 1, 0.82, 0)
        if item.skill then
            GameTooltip:AddLine(("%d / %d"):format(item.skill.rank, item.skill.max), 1, 1, 1)
        else
            GameTooltip:AddLine(L["not learned"], 0.54, 0.51, 0.45)
        end
        if item.gathering then
            GameTooltip:AddLine(L["Levels by gathering: no recipes to craft"], 0.54, 0.51, 0.45)
        end
        GameTooltip:Show()
    end
    function strip:SetItems(list)
        self.items = list
        local x, previousLearned = 0, nil
        for index, item in ipairs(list) do
            local button = self.buttons[index]
            if not button then
                button = UI:IconButton(self, PICKER_ICON)
                button:HookScript("OnEnter", OnEnter)
                button:HookScript("OnLeave", GameTooltip_Hide)
                button:SetScript("OnClick", function(clicked)
                    strip:SetValue(clicked.item.id)
                    strip.onChange(clicked.item.id)
                end)
                self.buttons[index] = button
            end
            local learned = item.skill ~= nil
            if previousLearned and not learned then
                x = x + PICKER_GROUP_GAP
            end
            previousLearned = learned
            button.item = item
            button:SetIcon("Interface\\Icons\\" .. (item.icon or "INV_Misc_QuestionMark"))
            button:ClearAllPoints()
            button:SetPoint("LEFT", x, 0)
            button:Show()
            x = x + PICKER_ICON + PICKER_GAP
        end
        for index = #list + 1, #self.buttons do
            self.buttons[index]:Hide()
        end
        self:SetWidth(math.max(1, x - PICKER_GAP))
        self:SetValue(self.value)
    end
    function strip:SetValue(id)
        self.value = id
        for _, button in ipairs(self.buttons) do
            local item = button.item
            if item and button:IsShown() then
                local selected = item.id == id
                button:SetBorder(selected and "gold" or "line")
                button:SetDimmed(not selected and item.skill == nil)
            end
        end
    end
    return strip
end

local function CreateTop()
    -- 专业图标条：可以看任意专业，不必先在专业窗口里打开它
    bench.picker = CreatePicker(function(slug)
        bench.chosen = slug
        Refresh()
    end)
    bench.picker:SetPoint("LEFT", bench, "TOPLEFT", 10, -TOP_HEIGHT / 2)
    bench.professionName = UI:Text(bench, "Heading")
    bench.professionName:SetPoint("LEFT", bench.picker, "RIGHT", 14, 0)
    local skill = CreateFrame("Frame", nil, bench)
    skill:SetSize(100, 6)
    skill:SetPoint("LEFT", bench.professionName, "RIGHT", 10, 0)
    Theme:Fill(skill, "track")
    skill.fill = Theme:Fill(skill, "gold", "ARTWORK")
    skill.fill:SetPoint("TOPLEFT")
    skill.fill:SetPoint("BOTTOMLEFT")
    bench.skill = skill
    bench.skillText = UI:Text(bench, "Muted")
    bench.skillText:SetPoint("LEFT", skill, "RIGHT", 8, 0)
    -- 贴在专业窗口旁时收起成小按钮；单独打开时直接关掉
    bench.close = UI:CloseButton(bench, function()
        if bench.standalone then
            CloseStandalone()
        else
            SetCollapsed(true)
        end
    end)
    bench.close:SetPoint("TOPRIGHT", -8, -10)
    bench.summary = UI:Text(bench, "Muted")
    bench.summary:SetPoint("RIGHT", bench.close, "LEFT", -10, 0)
    bench.summary:SetPoint("LEFT", bench.skillText, "RIGHT", 16, 0)
    bench.summary:SetJustifyH("RIGHT")
    bench.summary:SetWordWrap(false)
    local line = Line(bench, true)
    line:SetPoint("TOPLEFT", 1, -TOP_HEIGHT)
    line:SetPoint("TOPRIGHT", -1, -TOP_HEIGHT)
end

local function CreateLeft()
    local left = CreateFrame("Frame", nil, bench)
    left:SetPoint("TOPLEFT", 0, -TOP_HEIGHT - 1)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(LEFT_WIDTH)
    bench.left = left
    local divider = Line(bench)
    divider:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 0, 1)

    local settings = Settings("panel", { view = "route" })
    bench.views = UI:Segmented(left, {
        { id = "route", label = L["Leveling"] },
        { id = "sources", label = L["Recipes"] },
        { id = "profit", label = L["Make money"] },
        { id = "trainers", label = L["Trainers"] },
    }, function(view)
        settings.view = view
        Refresh()
    end, floor((LEFT_WIDTH - 20) / 4))
    bench.views:SetPoint("TOPLEFT", 10, -8)

    -- 钓鱼：地区 / 渔获 / 我的渔获 / 训练师
    bench.fishViews = UI:Segmented(left, {
        { id = "zones", label = L["Zones"] },
        { id = "fish", label = L["Catches"] },
        { id = "mine", label = L["Mine"] },
        { id = "trainers", label = L["Trainers"] },
    }, function(view)
        R.SetFishingLens(view)
        Refresh()
    end, floor((LEFT_WIDTH - 20) / 4))
    bench.fishViews:SetPoint("TOPLEFT", 10, -8)
    bench.fishViews:Hide()

    local searchToken = 0
    bench.search = UI:SearchBox(left, LEFT_WIDTH - 20, L["Search recipes or materials"], function(text)
        query = text or ""
        searchToken = searchToken + 1
        local token = searchToken
        C_Timer.After(0.25, function()
            if token == searchToken then
                Refresh()
            end
        end)
    end)
    bench.search:SetPoint("TOPLEFT", 10, -38)

    -- 冲级视角：路线取向（效率优先 / 均衡 / 省钱优先 / 手册路线）与目标技能
    local route = Settings("route", ROUTE_DEFAULTS)
    local options = CreateFrame("Frame", nil, left)
    options:SetPoint("TOPLEFT", 10, -68)
    options:SetSize(LEFT_WIDTH - 20, 24)
    bench.routeOptions = options
    local modes = {
        { id = "speed", label = L["Fastest"], tip = L["Each craft counts as 30 silver, more at higher skill: fewer crafts usually win"] },
        { id = "balanced", label = L["Balanced"],
            tip = L["Each extra craft counts as a little money: a sure point is worth paying a bit for"] },
        { id = "saving", label = L["Cheapest"], tip = L["Money only: the cheapest way, even if it takes many more crafts"] },
        { id = "handbook", label = L["Handbook route"],
            tip = L["The fixed order from the wowhandbook.com guide, priced at today's prices"] },
    }
    MODE_ITEMS = { all = modes, calculated = { modes[1], modes[2], modes[3] } }
    -- 一行三样：路线取向、目标技能两个下拉框，右端是锁定按钮
    local LOCK_WIDTH = 72
    local half = floor((LEFT_WIDTH - 20 - LOCK_WIDTH - 16) / 2)
    bench.mode = UI:Dropdown(options, modes, function(value)
        if value == "handbook" then
            route.mode = "handbook"
        else
            route.mode, route.priority = "live", value
        end
        Changed()
    end, half)
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
    local targets = {}
    for _, value in ipairs(TARGETS) do
        tinsert(targets, { id = value, label = (L["To skill %d"]):format(value) })
    end
    bench.target = UI:Dropdown(options, targets, function(value)
        route.target = value
        Changed()
    end, half)
    bench.target:SetPoint("LEFT", bench.mode, "RIGHT", 8, 0)
    -- 锁定 / 解锁当前路线（本角色长期有效）：锁定后价格波动不再换配方与次数，买的东西不会每次刷新都变
    bench.lockButton = UI:Button(options, L["Lock route"], LOCK_WIDTH, 22, "primary")
    bench.lockButton:SetPoint("RIGHT", 0, 0)
    bench.lockButton:SetScript("OnClick", function()
        local profession = Current()
        if not (profession and routeCache) then
            return
        end
        if routeCache.plan.locked then
            R.UnlockRoute(profession)
        elseif #routeCache.plan.steps > 0 then
            R.LockRoute(profession, routeCache.plan, routeCache.from, routeCache.to)
        end
        Changed()
    end)
    bench.lockButton:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(self.label and self.label:GetText() or "")
        GameTooltip:AddLine(L["Keeps these recipes and crafts for this character until you unlock it, whatever prices do"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    bench.lockButton:HookScript("OnLeave", GameTooltip_Hide)

    -- 赚钱视角：排序与“还没学的也算”
    local profit = Settings("profit", PROFIT_DEFAULTS)
    local profitOptions = CreateFrame("Frame", nil, left)
    profitOptions:SetPoint("TOPLEFT", 10, -68)
    profitOptions:SetSize(LEFT_WIDTH - 20, 24)
    bench.profitOptions = profitOptions
    local sorts = {
        { id = "profit", label = L["Profit"] }, { id = "margin", label = L["Margin"] },
        { id = "cost", label = L["Cost"] }, { id = "value", label = L["Sells for"] },
        { id = "tier", label = L["Sells"] }, { id = "name", label = L["Recipe"] },
    }
    bench.sort = UI:Dropdown(profitOptions, sorts, function(value)
        profit.sort, profit.descending = value, value ~= "name"
        RefreshList()
        RefreshDetail()
    end, half)
    bench.sort:SetPoint("LEFT", 0, 0)
    bench.sort:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["Sort by"])
        GameTooltip:Show()
    end)
    bench.sort:HookScript("OnLeave", GameTooltip_Hide)
    bench.unlearned = UI:Checkbox(profitOptions, L["Not learned too"], function(checked)
        profit.unlearned = checked
        Changed()
    end)
    bench.unlearned:SetPoint("LEFT", bench.sort, "RIGHT", 10, 0)

    bench.list = UI:List(left, 22, OnListSelect)
    bench.list.onEntryEnter = OnListEnter
    bench.list:SetPoint("TOPLEFT", 4, -98)
    bench.list:SetPoint("BOTTOMRIGHT", -4, 6)
end

local function CreateRight()
    local right = CreateFrame("Frame", nil, bench)
    right:SetPoint("TOPLEFT", LEFT_WIDTH + 1, -TOP_HEIGHT - 1)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    bench.right = right

    -- 标题区
    local frame = CreateFrame("Frame", nil, right, "BackdropTemplate")
    frame:SetSize(38, 38)
    frame:SetPoint("TOPLEFT", 14, -10)
    Theme:Skin(frame, "panel", "goldDim")
    bench.icon = frame:CreateTexture(nil, "ARTWORK")
    bench.icon:SetPoint("TOPLEFT", 1, -1)
    bench.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    bench.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    -- 右侧最多三栏数字（配方：成本、卖价、利润；其他条目只用最右一栏），每栏大字下面一行说明，右对齐
    bench.headIcon = frame
    bench.stats = {}
    for index = 1, 3 do
        local value = UI:Text(right, "Title")
        value:SetJustifyH("RIGHT")
        local label = UI:Text(right, "Muted")
        label:SetJustifyH("RIGHT")
        label:SetPoint("TOPRIGHT", value, "BOTTOMRIGHT", 0, -4)
        bench.stats[index] = { value = value, label = label }
    end
    bench.big, bench.caption = bench.stats[3].value, bench.stats[3].label
    bench.name = UI:Text(right, "Heading")
    bench.name:SetWordWrap(false)
    bench.sub = UI:Text(right, "Muted")
    bench.sub:SetPoint("TOPLEFT", bench.name, "BOTTOMLEFT", 0, -5)
    bench.sub:SetPoint("TOPRIGHT", bench.name, "BOTTOMRIGHT", 0, -5)
    bench.sub:SetWordWrap(false)

    -- 难度色条
    local difficulty = CreateFrame("Frame", nil, right)
    difficulty:SetPoint("TOPLEFT", 14, -HEAD_HEIGHT - 2)
    difficulty:SetPoint("TOPRIGHT", -14, -HEAD_HEIGHT - 2)
    difficulty:SetHeight(SKILLBAR_HEIGHT - 4)
    -- 五段：还不能学（淡色，当前技能低于学习技能时才有宽度）、橙、黄、绿、灰
    difficulty.segments = { Theme:Fill(difficulty, "line", "ARTWORK") }
    for _, color in ipairs(DIFFICULTY_COLORS) do
        tinsert(difficulty.segments, Theme:Fill(difficulty, color, "ARTWORK"))
    end
    difficulty.markerEdge = Theme:Fill(difficulty, "panel", "OVERLAY", 1)
    difficulty.markerEdge:SetSize(7, DIFFICULTY_BAR_HEIGHT + 10)
    difficulty.marker = Theme:Fill(difficulty, "text", "OVERLAY", 2)
    difficulty.marker:SetSize(3, DIFFICULTY_BAR_HEIGHT + 8)
    difficulty.now = UI:Text(difficulty, "Body")
    difficulty.ticks = {}
    for index = 1, 4 do
        difficulty.ticks[index] = UI:Text(difficulty, "Small")
    end
    bench.difficulty = difficulty
    -- 宽度第一次确定（或改变）时按新宽度重画色条与比例条
    difficulty:SetScript("OnSizeChanged", function()
        if bench:IsVisible() then
            RefreshDetail()
        end
    end)

    -- 路线总览：选项与四个数字（材料、图纸、成品回收、净花费）
    local strip = CreateFrame("Frame", nil, right)
    strip:SetPoint("TOPLEFT", 12, -HEAD_HEIGHT)
    strip:SetPoint("TOPRIGHT", -12, -HEAD_HEIGHT)
    strip:SetHeight(STRIP_HEIGHT)
    bench.strip = strip
    local route = Settings("route", ROUTE_DEFAULTS)
    local function Option(key, label)
        return UI:Checkbox(strip, label, function(checked)
            route[key] = checked
            Changed()
        end)
    end
    bench.recovery = Option("recovery", L["Count resale"])
    bench.recovery:SetPoint("TOPLEFT", 2, -2)
    bench.buyRecipes = Option("buyRecipes", L["Buy recipe items"])
    bench.buyRecipes:SetPoint("LEFT", bench.recovery, "RIGHT", 16, 0)
    bench.tiles = {}
    local tileWidth = (BENCH_WIDTH - LEFT_WIDTH - 1 - 24 - 3 * TILE_GAP) / 4
    for index, key in ipairs({ "materials", "recipes", "resale", "net" }) do
        local tile = UI:StatTile(strip, "")
        tile:SetWidth(tileWidth)
        tile:SetPoint("TOPLEFT", (index - 1) * (tileWidth + TILE_GAP), -28)
        bench.tiles[key] = tile
    end
    strip:Hide()

    bench.body = UI:ScrollArea(right)
    bench.rows, bench.expanded, bench.collapsed, bench.pick = {}, {}, {}, {}
    bench.entries, bench.byID = {}, {}

    -- 底部按钮
    local line = Line(right, true)
    line:SetPoint("BOTTOMLEFT", 1, ACTION_HEIGHT)
    line:SetPoint("BOTTOMRIGHT", -1, ACTION_HEIGHT)
    bench.searchButton = UI:Button(right, L["Search the auction house"], 150, 22, "primary")
    bench.searchButton:SetScript("OnClick", function()
        if bench.current then
            ShiftSearch({ recipe = bench.current })
        end
    end)
    bench.openButton = UI:Button(right, L["Show in the professions window"], 170, 22)
    bench.openButton:SetScript("OnClick", function()
        if bench.current and C_TradeSkillUI and C_TradeSkillUI.OpenRecipe then
            C_TradeSkillUI.OpenRecipe(bench.current.id)
        end
    end)
    bench.mapButton = UI:Button(right, L["Mark the vendor on the map"], 150, 22)
    bench.mapButton:SetScript("OnClick", function(self)
        local spot = self.spot
        if spot then
            ns.Waypoints:ShowOnMap(spot[1], spot[2], spot[3], spot.title)
        end
    end)
    bench.hint = UI:Text(right, "Small")
    bench.hint:SetJustifyH("LEFT")
    bench.hint:SetWordWrap(false)
end

local function CreateTab(settings)
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
end

local function CreateBench()
    local settings = Settings("panel", { view = "route" })
    bench = UI:Panel(UIParent, "panel", "line")
    bench:SetSize(BENCH_WIDTH, BENCH_HEIGHT)
    bench:Hide()
    UI:Dockable(bench, settings, 2)
    bench.dockHeight = BENCH_HEIGHT
    CreateTop()
    CreateLeft()
    CreateRight()
    CreateTab(settings)
    -- Esc 关闭单独打开的工作台：UISpecialFrames 只收具名框架，用一个只在单独打开时显示的具名小框架代为接收，
    -- 贴在专业窗口旁时不受 Esc 影响（跟着专业窗口关）
    escape = CreateFrame("Frame", "WowHandbookWorkbenchEscape", UIParent)
    escape:Hide()
    escape:SetScript("OnHide", function()
        if bench.standalone then
            bench.standalone = false
            bench:Hide()
        end
    end)
    tinsert(UISpecialFrames, "WowHandbookWorkbenchEscape")
    -- 配色方案变化：列表行与比例条的颜色每次刷新时现取，整台重画一次
    Theme:OnChange(function()
        if bench:IsVisible() then
            Refresh()
        end
    end)
    R.bench, R.tab = bench, tab -- 供测试使用
end

-- 单独打开（主窗口导航的“专业”、或专业窗口没开时）：不贴专业窗口，放在屏幕中间，Esc 或关闭按钮关掉
function CloseStandalone()
    bench.standalone = false
    escape:Hide()
    bench:Hide()
end

local function OpenStandalone(slug)
    if not Module.enabled then
        return
    end
    if not bench then
        CreateBench()
    end
    if slug then
        bench.chosen = slug
    end
    if OpenWindow() then
        -- 专业窗口开着：工作台本来就贴在旁边，展开即可
        SetCollapsed(false)
        return
    end
    bench.standalone = true
    bench.dockOuter = nil
    bench:ClearAllPoints()
    bench:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    bench:SetHeight(BENCH_HEIGHT)
    bench:SetFrameStrata("HIGH")
    bench:SetFrameLevel(20)
    tab:Hide()
    escape:Show()
    bench:Show()
    Refresh()
end
R.OpenStandalone = OpenStandalone

-- 专业窗口打开：工作台总是展开，跟着窗口里的专业
function R.WindowShown()
    Settings("panel").collapsed = false
    if bench then
        bench.chosen, bench.followed = nil, nil
    end
end

function R.PanelShown()
    return bench ~= nil and bench:IsShown()
end

function Update()
    local window = Module.enabled and OpenWindow()
    if not window then
        if bench and Module.enabled and bench.standalone then
            tab:Hide()
            if bench:IsShown() then
                Refresh()
            end
        elseif bench then
            bench.standalone = false
            escape:Hide()
            bench:Hide()
            tab:Hide()
        end
        return
    end
    if not bench then
        CreateBench()
    end
    bench.standalone = false
    escape:Hide()
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
R.UpdatePanel = Update

function R.HidePanel()
    if bench then
        bench.standalone = false
        escape:Hide()
        bench:Hide()
        tab:Hide()
    end
end

-- 专业窗口的配方表单：选中配方时暴雪调用它的 Init（按方法名调用，hooksecurefunc 挂得上）。
-- 只读传入的配方 ID，不改表单的数据与控件
local hookedForm = false
local function OnFormInit(_, recipeInfo)
    if not (Module.enabled and bench and bench:IsVisible()) then
        return
    end
    local id = recipeInfo and recipeInfo.recipeID
    if not id or id == bench.native then
        return
    end
    bench.native = id
    -- 玩家在下拉框里换到了别的专业：专业窗口里点了配方，就切回窗口里的专业
    if bench.chosen then
        bench.chosen = nil
        RefreshList()
    end
    FocusRecipe(id)
end

function R.AttachForm()
    local page = type(ProfessionsFrame) == "table" and ProfessionsFrame.CraftingPage
    local form = type(page) == "table" and page.SchematicForm
    if hookedForm or type(form) ~= "table" or type(form.Init) ~= "function" then
        return
    end
    hookedForm = true
    hooksecurefunc(form, "Init", OnFormInit)
end
