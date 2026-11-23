local ADDON_NAME, ns = ...
local L = ns.L

-- 专业工作台（计算部分）：打开游戏专业窗口时，针对窗口里打开的那个专业算出——
--   冲级路线：按拍卖行与商人价格算出的最省路线（Core/LevelingPlan.lua），成品按流通性估回收；
--             有攻略的专业可以换成手册路线（wowhandbook.com 专业攻略的固定顺序，只按现在的价格计价）；
--   图纸：每个配方要多少技能、从哪来（训练师 / 商人 / 商人青睐 / 掉落 / 任务）、商人价与拍卖价、商人位置；
--   利润：一次制作的材料成本（本专业能做的中间材料买与做取便宜的）、成品卖价、利润、利润率、好不好卖。
-- 界面在 Modules/WorkbenchView.lua：左栏配方列表（冲级 / 图纸 / 赚钱三种视角），右栏选中配方的详情与路线总览。
-- 本文件还负责配方与物品鼠标提示里的成本利润行、Shift 点击搜拍卖行、跟随专业窗口的事件。
-- 两个文件之间的共用函数挂在模块表上（Recipes.xxx），界面文件加载时取成局部变量。
-- 数据：Data/Recipes.lua（tools/export_recipe_data.py 从网站导出）；配方名称、图标运行时向客户端取。
-- 已学配方：IsPlayerSpell，加上打开专业窗口时读到的（本次登录内有效，不存档）。
-- 设置存在模块设置里：panel（视角、收起、位置）、route（冲级路线选项）、profit（赚钱视角选项）、
-- fishing（钓鱼视角）、recordFishing（记录自己的渔获，钓鱼视角见 Modules/WorkbenchFishing.lua）、
-- fishingPopup（拿起鱼竿时显示渔获小窗，见 Modules/FishingPopup.lua）。
-- 关闭模块后不注册事件、不建界面；已挂在专业窗口上的 OnShow / OnHide 钩子取消不了，只在模块开启时做事。
local Module = ns:NewModule("Workbench", { auctionSearch = true, recordFishing = true, fishingPopup = true })
local Theme = ns.Theme
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
Recipes.Color = Color

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
Recipes.Settings = Settings

local function Name(names)
    if type(names) ~= "table" then
        return names
    end
    return names[ns.locale] or names.enUS
end
Recipes.Name = Name

local function ItemLink(itemID)
    local _, link = C_Item.GetItemInfo(itemID)
    if not link and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return link or ("#" .. itemID)
end
Recipes.ItemLink = ItemLink

local function Professions()
    return ns.Data.recipes or {}
end
Recipes.Professions = Professions

-- 玩家已学的专业：{ [slug] = { rank, max } }。按专业数据（12 个，含草药学、剥皮、钓鱼等采集类）与配方数据的
-- 技能线 ID、名字对照（ns.ProfessionSkills）。只看配方数据会漏掉采集类：它们没有配方，钓鱼会一直显示“未学”
local function LearnedSkills()
    return ns.ProfessionSkills(Professions())
end
Recipes.LearnedSkills = LearnedSkills

--------------------------------------------------------------------------------
-- 配方：名称、图标、已学、难度
--------------------------------------------------------------------------------

local function RecipeName(recipe)
    return C_Spell.GetSpellName(recipe.id) or ("#" .. recipe.id)
end
Recipes.RecipeName = RecipeName

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

local AddPriceLines -- 在利润计算之后定义：鼠标提示里追加成本、卖价与利润

-- 配方提示：游戏的技能提示（含材料），另加三档技能点、学习来源与成本利润；anchor 默认 ANCHOR_RIGHT
local function ShowRecipeTooltip(owner, recipe, anchor)
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
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
    AddPriceLines(recipe)
    GameTooltip:Show()
end
Recipes.ShowRecipeTooltip = ShowRecipeTooltip

--------------------------------------------------------------------------------
-- Shift 点击在拍卖行搜索（设置 auctionSearch，默认开）
--   拍卖行开着、没有在聊天框里打字时：
--   · 物品：Auctionator 的购物标签页开着时填进它的搜索栏并搜索（与它自己 Shift 点击物品的做法相同）；
--           游戏的“购买”页开着时用游戏的搜索栏；拍卖行停在别的页时，装了 Auctionator 用它的公开接口
--           （切到购物页搜这一件），没装就切到“购买”页再搜。
--   · 配方：装了 Auctionator 时像它的“搜索材料”一样一次搜成品与全部材料（材料带每次制作的数量；
--           没学的配方另加图纸），用公开接口 MultiSearchAdvanced；没装时用游戏的搜索栏搜成品
--           （没有成品的搜图纸）。
--   拍卖行没开时照旧把链接插进聊天框。物品名字没缓存时先请求，到齐了再搜。
--------------------------------------------------------------------------------

local function AuctionOpen()
    return AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown() or false
end
Recipes.AuctionOpen = AuctionOpen

local function UsesAuctionator()
    return type(Auctionator) == "table" and type(Auctionator.API) == "table"
        and type(Auctionator.API.v1) == "table" or false
end

local function SearchEnabled()
    return ns:GetModuleSettings(Module).auctionSearch ~= false
end
Recipes.SearchEnabled = SearchEnabled

-- 正在聊天框里打字（光标在一个不是拍卖行搜索栏的输入框里）时，Shift 点击还是插入链接
local function Typing()
    local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if not focus then
        return false
    end
    local bar = AuctionHouseFrame and AuctionHouseFrame.SearchBar
    return not (bar and focus == bar.SearchBox)
end

-- 物品名字都到了以后调用 done(名字表)；没缓存的先请求（每件最多等一次，没到的跳过）
local function WithNames(itemIDs, done)
    local missing = 0
    local function Finish()
        local names = {}
        for _, itemID in ipairs(itemIDs) do
            names[itemID] = C_Item.GetItemInfo(itemID)
        end
        done(names)
    end
    for _, itemID in ipairs(itemIDs) do
        if not C_Item.GetItemInfo(itemID) and Item and Item.CreateFromItemID then
            local item = Item:CreateFromItemID(itemID)
            if not item:IsItemEmpty() then
                missing = missing + 1
                item:ContinueOnItemLoad(function()
                    missing = missing - 1
                    if missing == 0 then
                        Finish()
                    end
                end)
            end
        end
    end
    if missing == 0 then
        Finish()
    end
end

-- 游戏拍卖行的搜索栏：不在“购买”页时先切过去
local function NativeSearch(name)
    local frame = AuctionHouseFrame
    local bar = frame and frame.SearchBar
    if not (bar and name) then
        return false
    end
    if not bar:IsVisible() then
        if frame.BuyTab and frame.BuyTab.Click then
            frame.BuyTab:Click()
        elseif frame.SetDisplayMode and AuctionHouseFrameDisplayMode and AuctionHouseFrameDisplayMode.Buy then
            frame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
        end
    end
    if bar.SetSearchText then
        bar:SetSearchText(name)
    elseif bar.SearchBox and bar.SearchBox.SetText then
        bar.SearchBox:SetText(name)
    else
        return false
    end
    if bar.StartSearch then
        bar:StartSearch()
    elseif bar.SearchButton and bar.SearchButton.Click then
        bar.SearchButton:Click()
    else
        return false
    end
    return true
end

-- Auctionator 的公开接口：拍卖行没开等情况会报错，接住后改用游戏的搜索栏
local function AuctionatorCall(method, terms)
    local api = Auctionator.API.v1
    if type(api[method]) ~= "function" then
        return false
    end
    return pcall(api[method], L["Profession workbench"], terms)
end

-- Auctionator 购物页开着时填进它的搜索栏（与它自己 Shift 点击物品的做法相同，精确匹配）
local function AuctionatorShoppingSearch(name)
    local frame = AuctionatorShoppingFrame
    if not (frame and frame.IsVisible and frame:IsVisible() and frame.DoSearch
        and frame.SearchOptions and frame.SearchOptions.SetSearchTerm) then
        return false
    end
    local term = "\"" .. name .. "\""
    frame:DoSearch({ term }, {})
    frame.SearchOptions:SetSearchTerm(term)
    local recents = Auctionator.Shopping and Auctionator.Shopping.Recents
    if recents and type(recents.Save) == "function" then
        recents.Save(term)
    end
    return true
end

local function SearchItem(itemID)
    WithNames({ itemID }, function(names)
        local name = names[itemID]
        if not (name and AuctionOpen()) then
            return
        end
        if UsesAuctionator() then
            if AuctionatorShoppingSearch(name) then
                return
            end
            local bar = AuctionHouseFrame.SearchBar
            if not (bar and bar:IsVisible()) and AuctionatorCall("MultiSearchExact", { name }) then
                return
            end
        end
        NativeSearch(name)
    end)
end

-- 配方要搜的物品：没学的配方先放图纸，再放成品，再放材料（带每次制作的数量）
local function RecipeTerms(recipe)
    local ids, counts = {}, {}
    if recipe.learnedFrom and not KnownRecipe(recipe) then
        tinsert(ids, recipe.learnedFrom)
    end
    if recipe.makes then
        tinsert(ids, recipe.makes)
    end
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        tinsert(ids, reagents[index])
        counts[reagents[index]] = reagents[index + 1]
    end
    return ids, counts
end
Recipes.RecipeTerms = RecipeTerms

local function SearchRecipe(recipe)
    local ids, counts = RecipeTerms(recipe)
    if #ids == 0 then
        return
    end
    WithNames(ids, function(names)
        if not AuctionOpen() then
            return
        end
        if UsesAuctionator() then
            local terms, seen = {}, {}
            for _, itemID in ipairs(ids) do
                local name = names[itemID]
                if name and not seen[name] and not name:find("[;^\"]") then
                    seen[name] = true
                    tinsert(terms, { searchString = name, isExact = true, quantity = counts[itemID] })
                end
            end
            if #terms > 0 and AuctionatorCall("MultiSearchAdvanced", terms) then
                return
            end
        end
        NativeSearch(names[recipe.makes] or names[ids[1]])
    end)
end

-- 行的 Shift 点击：拍卖行开着就搜索，返回 true；否则返回 false，由调用方插入聊天链接
local function ShiftSearch(row)
    if not (SearchEnabled() and AuctionOpen()) or Typing() then
        return false
    end
    if row.item then
        SearchItem(row.item)
    elseif row.recipe then
        SearchRecipe(row.recipe)
    else
        return false
    end
    return true
end
Recipes.ShiftSearch = ShiftSearch

local function InsertChatLink(itemID)
    if not itemID then
        return
    end
    local _, link = C_Item.GetItemInfo(itemID)
    if link and ChatEdit_InsertLink then
        ChatEdit_InsertLink(link)
    end
end
Recipes.InsertChatLink = InsertChatLink

--------------------------------------------------------------------------------
-- 冲级路线：按价格算（LevelingPlan.lua）
--------------------------------------------------------------------------------

-- commissionPicks = { [附魔的配方 ID] = true }：勾选了接代工的附魔
-- mode = "live" 按价格算的最省路线 / "handbook" 手册路线（专业有 route 数据时才能选）
local PROFIT_DEFAULTS = { unlearned = false, sort = "profit", descending = true }
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
Recipes.Money = Money

-- 汇总数字用：一金以上不显示铜
local function Brief(copper)
    copper = copper or 0
    if copper >= 10000 then
        copper = floor(copper / 100 + 0.5) * 100
    end
    return Money(copper)
end
Recipes.Brief = Brief

local function Count(value)
    return tostring(math.ceil(value - 1e-6))
end
Recipes.Count = Count

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
Recipes.VendorSell = VendorSell

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
Recipes.HasCommissions = HasCommissions

local function CommissionPicks()
    local settings = Settings("route", ROUTE_DEFAULTS)
    settings.commissionPicks = settings.commissionPicks or {}
    return settings.commissionPicks
end
Recipes.CommissionPicks = CommissionPicks

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
Recipes.RouteTarget = RouteTarget

-- 锁定的练级路线：每个角色各自一份，存在角色存档 lockedRoutes[专业 slug] =
-- { steps = 固定路线格式的步骤（LevelingPlan 的 fixed）, from, to, priority 锁定时的取向, at 锁定时间 }。
-- 锁定后一直照这些配方、顺序与次数走（技能在一步中间时次数按剩下的点数折算），只按今天的价格计价，
-- 价格波动不会换配方；手工解锁才回到按价格算
local function Locks()
    local db = ns.charDB
    if not db then
        return {}
    end
    db.lockedRoutes = db.lockedRoutes or {}
    return db.lockedRoutes
end

function Recipes.LockedRoute(profession)
    return profession and Locks()[profession.slug] or nil
end

-- 把算好的路线存成固定路线：备料（stock）步骤保留到用它的下一步做完为止
function Recipes.LockRoute(profession, plan, from, to)
    local steps, list = {}, plan.steps or {}
    for index, step in ipairs(list) do
        if not step.gap and step.recipe and (step.stock or step.to > step.from) then
            local entry = { recipe = step.recipe.id, from = step.from, to = step.to, crafts = step.crafts,
                stock = step.stock or nil, forced = step.forced or nil }
            if step.stock then
                for later = index + 1, #list do
                    local following = list[later]
                    if not following.gap and not following.stock then
                        entry.keepBelow = following.to
                        break
                    end
                end
                entry.keepBelow = entry.keepBelow or to
            end
            tinsert(steps, entry)
        end
    end
    Locks()[profession.slug] = { steps = steps, from = from, to = to,
        priority = Settings("route", ROUTE_DEFAULTS).priority, at = time() }
end

function Recipes.UnlockRoute(profession)
    Locks()[profession.slug] = nil
end

-- from / to 不给时按玩家技能与设置的目标；给了就算这一段（工作台用它算玩家已经走过的 1 到当前技能）。
-- 按价格算的模式下这个专业锁定了路线时，照锁定的步骤计价、目标是锁定时的目标；live 为真时不管锁定
local function BuildRoute(profession, skill, from, to, live)
    local settings = Settings("route", ROUTE_DEFAULTS)
    local lock = not live and settings.mode ~= "handbook" and Recipes.LockedRoute(profession) or nil
    from = from or (skill and skill.rank or 1)
    to = to or (lock and math.max(from, lock.to)) or RouteTarget(settings, from)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return ns.LevelingPlan.Build({
        recipes = profession.recipes or {}, from = from, to = to, faction = faction == "Horde" and "H" or "A",
        known = KnownRecipe, hasTool = HasTool, market = Market(),
        fixed = settings.mode == "handbook" and profession.route or (lock and lock.steps) or nil,
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
Recipes.Destination = Destination

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
Recipes.TIER_LABEL, Recipes.TIER_REASON = TIER_LABEL, TIER_REASON
Recipes.PROFIT_DEFAULTS, Recipes.ROUTE_DEFAULTS, Recipes.TARGETS = PROFIT_DEFAULTS, ROUTE_DEFAULTS, TARGETS

-- 明细：每种材料的数量、单价与来源、小计（crafts 为制作次数）。
-- deep 为真时（利润页）材料按 ReagentCost 计：本专业自己做更便宜的，写出自己做的单价、用到的下一层材料与买入价
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
Recipes.CastCost = CastCost

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

-- 中立拍卖行买一件：商人价与中立拍卖行价取低；都没有时为 nil
local function NeutralBuy(itemID)
    local vendor, neutral = Prices.Vendor(itemID), (Prices.Neutral(itemID))
    if vendor and (not neutral or vendor <= neutral) then
        return vendor
    end
    return neutral
end

-- 用某个配方自己做一件材料：做它的材料在本阵营（market = "faction"，商人与拍卖行取低）或中立拍卖行
-- （"neutral"，商人与中立拍卖行取低）买。parts = { { item, each = 做一件要几个, unit = 单价或 nil }, ... }
local function CraftWay(maker, market)
    local per = maker.count or 1
    local parts, total = {}, 0
    local reagents = maker.reagents or {}
    for index = 1, #reagents, 2 do
        local item, count = reagents[index], reagents[index + 1] or 1
        local unit
        if market == "neutral" then
            unit = NeutralBuy(item)
        else
            unit = Prices.BuyCost(item)
        end
        tinsert(parts, { item = item, each = count / per, unit = unit })
        total = unit and total and total + unit * count or nil
    end
    return { key = "craft:" .. maker.id .. ":" .. market, kind = "craft", market = market, recipe = maker,
        parts = parts, price = total and total / per }
end

-- 按单价从低到高排（没价格的在最后，同价按原来的顺序）
local function ByPrice(list, field)
    for index, entry in ipairs(list) do
        entry.order = index
    end
    table.sort(list, function(a, b)
        local x, y = a[field], b[field]
        if (x ~= nil) ~= (y ~= nil) then
            return x ~= nil
        end
        if x and x ~= y then
            return x < y
        end
        return a.order < b.order
    end)
    return list
end

-- 一件材料的全部来源，工作台的成本表里并列列出、玩家点选：商人、本阵营拍卖行、做它的配方（材料在本阵营买），
-- 再是中立拍卖行与做它的配方（材料在中立拍卖行买）——中立的只在有中立拍卖行记录时列出。
-- 按单价从低到高排。每项 { key, kind = "vendor" / "auction" / "neutral" / "craft", market, price = 单价或 nil, recipe, parts }
local function Ways(profession, itemID)
    local list = {}
    local vendor, auction = Prices.Vendor(itemID), (Prices.Auction(itemID))
    if vendor then
        tinsert(list, { key = "vendor", kind = "vendor", price = vendor })
    end
    if auction or not vendor then
        tinsert(list, { key = "auction", kind = "auction", price = auction })
    end
    local makers = profession and MakersOf(profession, itemID) or {}
    for _, maker in ipairs(makers) do
        tinsert(list, CraftWay(maker, "faction"))
    end
    local neutral = Prices.Neutral(itemID)
    if neutral then
        tinsert(list, { key = "neutral", kind = "neutral", price = neutral })
    end
    for _, maker in ipairs(makers) do
        local reagents, recorded = maker.reagents or {}, false
        for index = 1, #reagents, 2 do
            recorded = recorded or Prices.Neutral(reagents[index]) ~= nil
        end
        if recorded then
            tinsert(list, CraftWay(maker, "neutral"))
        end
    end
    return ByPrice(list, "price")
end
Recipes.Ways = Ways

-- 玩家的选择，所有配方共用：sources = { [材料物品 ID] = Ways 里的 key }（没选时按最省的算），
-- sales = { [成品物品 ID] = Outlets 里的 key }（没选时本阵营拍卖行与商人取高）
local function Picks(kind)
    local store = ns:GetModuleSettings(Module)
    store[kind] = store[kind] or {}
    return store[kind]
end

-- 选一项；再点已选的那项取消选择，回到默认。价格、成本与利润随之全部重算
local function Toggle(kind, itemID, key)
    local picks = Picks(kind)
    if picks[itemID] == key then
        picks[itemID] = nil
    else
        picks[itemID] = key
    end
end

function Recipes.PickedSource(itemID)
    return Picks("sources")[itemID]
end

function Recipes.PickSource(itemID, key)
    Toggle("sources", itemID, key)
end

function Recipes.PickedSale(itemID)
    return Picks("sales")[itemID]
end

function Recipes.PickSale(itemID, key)
    Toggle("sales", itemID, key)
end

-- 成品的全部卖法，按到手单价从低到高：本阵营拍卖行（扣 5% 手续费）、商人、中立拍卖行（有记录时，扣 15%）。
-- 每项 { key = "auction" / "vendor" / "neutral", unit = 到手单价, cut = 手续费比例 }
local function Outlets(itemID)
    local plan = ns.LevelingPlan
    local list = {}
    local auction, vendor, neutral = Prices.Auction(itemID), VendorSell(itemID), Prices.Neutral(itemID)
    if auction then
        tinsert(list, { key = "auction", unit = auction * (1 - plan.AH_CUT), cut = plan.AH_CUT })
    end
    if vendor and vendor > 0 then
        tinsert(list, { key = "vendor", unit = vendor })
    end
    if neutral then
        tinsert(list, { key = "neutral", unit = neutral * (1 - plan.NEUTRAL_CUT), cut = plan.NEUTRAL_CUT })
    end
    return ByPrice(list, "unit")
end
Recipes.Outlets = Outlets

-- 计入利润的卖法：玩家选过且现在有价格时按它，否则本阵营拍卖行与商人取高。返回这一项与全部卖法；都没价格时为 nil
local function SaleOutlet(itemID)
    local list = Outlets(itemID)
    local picked, best = Picks("sales")[itemID], nil
    for _, outlet in ipairs(list) do
        if outlet.key == picked then
            return outlet, list
        end
        if outlet.key ~= "neutral" and (not best or outlet.unit > best.unit) then
            best = outlet
        end
    end
    return best, list
end
Recipes.SaleOutlet = SaleOutlet

-- 一件材料的单价：玩家选了来源（且这个来源现在有价格）时按它；否则买（商人价与拍卖价取低）与用本专业的配方
-- 自己做取便宜的。自己做只往下看一层：做它的材料按买入价算，不再找更下一层；只用已学的配方（unlearned 为真时
-- 没学的也算），有冷却的配方（月布等）不算。返回 单价, 来源（"vendor" / "auction" / "neutral" / "craft"）,
-- 自己做时用的配方, 买入单价, 用的来源 key；买不到也做不了时单价为 nil
function ReagentCost(profession, itemID, unlearned)
    local buy, source = Prices.BuyCost(itemID)
    local picked = Picks("sources")[itemID]
    if picked then
        for _, way in ipairs(Ways(profession, itemID)) do
            if way.key == picked and way.price then
                return way.price, way.kind, way.recipe, buy, way.key
            end
        end
    end
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
    return best, from, via, buy, via and ("craft:" .. via.id .. ":faction") or from
end
Recipes.ReagentCost = ReagentCost
Recipes.ProfessionOf = ProfessionOf
Recipes.MakersOf = MakersOf
--------------------------------------------------------------------------------
-- 图纸：还没学的配方要多少技能、从哪来、多少钱
--------------------------------------------------------------------------------

local VIA_LABEL = { vendor = "Vendor", drop = "Drop", quest = "Quest" }

local function Side()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return faction == "Horde" and "H" or "A"
end
Recipes.Side = Side

-- 商人青睐：数量与所需声望。声望档名与商会名取自客户端（没有时用英文档名）
local FAVOR_STANDING = { friendly = 5, honored = 6, revered = 7, exalted = 8 }
local FAVOR_FACTION = { A = 2586, H = 2587 }

local function FavorStanding(favor, side)
    local rank = favor.standing and FAVOR_STANDING[favor.standing]
    if not rank then
        return nil
    end
    local label = _G["FACTION_STANDING_LABEL" .. rank] or favor.standing:gsub("^%l", string.upper)
    local id = FAVOR_FACTION[favor.side or side]
    local name
    if id and C_Reputation and C_Reputation.GetFactionDataByID then
        local data = C_Reputation.GetFactionDataByID(id)
        name = data and data.name
    end
    return name and ("%s (%s)"):format(label, name) or label
end

-- “45 商人青睐 · 尊敬”：数量与所需声望（不限声望时只有数量）
local function FavorPrice(favor, side)
    local text = ("%s %s"):format(favor.cost or "?", L["Merchant's Favor"])
    local standing = FavorStanding(favor, side)
    if favor.gold then
        text = text .. " + " .. Money(favor.gold)
    end
    return standing and (text .. " · " .. standing) or text
end
Recipes.FavorPrice = FavorPrice

-- 来源文字、价格文字、商人位置
local function Source(recipe, side)
    if recipe.auto then
        return Color(L["Comes with the rank"], "muted"), ""
    elseif not recipe.learnedFrom then
        return L["Trainer"], ""
    elseif recipe.favor then
        return Color(L["Merchant's Favor"], "gold"), FavorPrice(recipe.favor, side)
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
        or (auction and L["Auction"] or Color(L["World drop"], "muted"))
    return source, table.concat(prices, " · "), recipe.spot and recipe.spot[side]
end
Recipes.Source = Source

local function MapName(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return info and info.name or ("#" .. mapID)
end
Recipes.MapName = MapName

--------------------------------------------------------------------------------
-- 利润：按现在的价格，做哪个最赚
--------------------------------------------------------------------------------


-- 一次制作的材料成本、卖出能拿到的钱（按 SaleOutlet：玩家选的卖法，没选时拍卖价扣手续费与卖店价取高）、利润、利润率（利润 ÷ 成本）、流通档；
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
    local outlet = SaleOutlet(recipe.makes)
    if not (outlet and outlet.unit > 0) then
        return nil
    end
    local value = outlet.unit * (recipe.count or 1)
    return { recipe = recipe, cost = cost, value = value, profit = value - cost, crafted = crafted,
        margin = cost > 0 and (value - cost) / cost or 0, tier = (Tier(recipe.makes)) }
end
Recipes.Profit = Profit

-- 配方鼠标提示里的价格：材料成本、成品卖价、利润与回本率；成品没价格时只给能算出的成本
function AddPriceLines(recipe, tooltip)
    if not Prices then
        return
    end
    tooltip = tooltip or GameTooltip
    local entry = Profit(recipe)
    local cost = entry and entry.cost or CastCost(recipe)
    if not cost or not recipe.reagents or #recipe.reagents == 0 then
        return
    end
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L["Cost"], Money(cost), 0.88, 0.71, 0.35, 1, 1, 1)
    if not entry then
        return
    end
    tooltip:AddDoubleLine(L["Sells for"], Money(entry.value), 0.88, 0.71, 0.35, 1, 1, 1)
    local gain = entry.profit >= 0
    tooltip:AddDoubleLine(L["Profit"], (gain and "+" or "-") .. Money(math.abs(entry.profit)), 0.88, 0.71, 0.35,
        gain and 0.27 or 0.9, gain and 0.75 or 0.3, gain and 0.45 or 0.3)
    if entry.cost > 0 then
        local rate = entry.value / entry.cost
        tooltip:AddLine((L["Payback %d%%"]):format(floor(rate * 100 + 0.5)), 0.7, 0.7, 0.7)
    end
end

-- 物品鼠标提示（背包、拍卖行、聊天链接等）：能用专业配方做出的物品追加制作成本与利润。
-- 同一物品有多个配方时取成本最低的；物品到配方的索引第一次悬停时建好。战斗中不算。
local makerByItem, itemHooked
local itemShown = setmetatable({}, { __mode = "k" })

local function MakerOfItem(itemID)
    if not makerByItem then
        makerByItem = {}
        for _, profession in ipairs(Professions()) do
            for _, recipe in ipairs(profession.recipes or {}) do
                if recipe.makes and recipe.skill and not recipe.cooldown and not recipe.nip
                    and recipe.reagents and #recipe.reagents > 0 then
                    makerByItem[recipe.makes] = makerByItem[recipe.makes] or {}
                    tinsert(makerByItem[recipe.makes], recipe)
                end
            end
        end
    end
    local list = makerByItem[itemID]
    if not list then
        return nil
    end
    local best, bestCost
    for _, recipe in ipairs(list) do
        local entry = Profit(recipe)
        local cost = entry and entry.cost or CastCost(recipe)
        if cost and (not bestCost or cost < bestCost) then
            best, bestCost = recipe, cost
        end
    end
    return best
end

local function OnItemTooltip(tooltip, data)
    if not Module.enabled or not tooltip or not tooltip.AddLine or InCombatLockdown() then
        return
    end
    local itemID = data and data.id
    if ns.IsSecret(itemID) then
        return
    end
    if not itemID and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        itemID = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    end
    if not itemID then
        return
    end
    local token = data and data.dataInstanceID or itemID
    if itemShown[tooltip] == token then
        return
    end
    local recipe = MakerOfItem(itemID)
    if not recipe then
        return
    end
    itemShown[tooltip] = token
    AddPriceLines(recipe, tooltip)
    if tooltip.Show then
        tooltip:Show()
    end
end

local function HookItemTooltips()
    if itemHooked then
        return
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
        itemHooked = true
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetItem", OnItemTooltip)
        itemHooked = true
    end
    if itemHooked and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
            itemShown[tooltip] = nil
        end)
    end
end
--------------------------------------------------------------------------------
-- 工作台：跟随游戏专业窗口
--------------------------------------------------------------------------------

local hooked = {}
-- 界面（WorkbenchView.lua）提供：UpdatePanel 跟随专业窗口显示或隐藏工作台；HidePanel 关闭模块时收起；
-- Invalidate 价格或已学配方变了，下次刷新重算路线与列表；AttachForm 挂上专业窗口的配方表单（选中配方时跟着切）
local function Update()
    if Recipes.UpdatePanel then
        Recipes.UpdatePanel()
    end
end

local function OpenWindow()
    for _, window in ipairs(WINDOWS) do
        local frame = _G[window.frame]
        if frame and frame:IsVisible() then
            return frame
        end
    end
end
Recipes.OpenWindow = OpenWindow

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

-- 专业窗口每次打开：工作台展开（不沿用上次收起的状态），并跟着窗口里的专业
local function OnWindowShown()
    if Module.enabled and Recipes.WindowShown then
        Recipes.WindowShown()
    end
    Update()
end

-- 暴雪专业窗口按需加载：已加载就挂上，否则等它加载
local function Attach()
    for _, window in ipairs(WINDOWS) do
        local frame = _G[window.frame]
        if frame and not hooked[frame] then
            hooked[frame] = true
            frame:HookScript("OnShow", OnWindowShown)
            frame:HookScript("OnHide", Update)
        end
    end
    if Recipes.AttachForm then
        Recipes.AttachForm()
    end
end

local function OnAddonLoaded(_, name)
    for _, window in ipairs(WINDOWS) do
        if name == window.addon then
            Attach()
        end
    end
end

-- 打开或切换专业、学会新配方、技能提升、价格变化：先读已学配方（专业窗口开着时），再刷新
-- （合并 0.5 秒内的多次变化；专业窗口没开、工作台也没单独开着时不做事）
local pending = false
local function Showing()
    return OpenWindow() or (Recipes.PanelShown and Recipes.PanelShown())
end

local function OnChange()
    if pending or not (Module.enabled and Showing()) then
        return
    end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        if Module.enabled and Showing() then
            if OpenWindow() then
                RecordKnownRecipes()
            end
            if Recipes.Invalidate then
                Recipes.Invalidate()
            end
            Update()
        end
    end)
end

-- 战斗中不算路线（界面刷新时记下 Recipes.deferred），脱战后补算一次
local function OnRegenEnabled()
    if Recipes.deferred then
        Recipes.deferred = false
        OnChange()
    end
end

-- 背包变化（BAG_UPDATE_DELAYED 已是一批一次）：0.3 秒内合并，只让界面重画购物清单
local bagsPending = false
local function OnBags()
    if bagsPending or not (Module.enabled and Recipes.PanelShown and Recipes.PanelShown()) then
        return
    end
    bagsPending = true
    C_Timer.After(0.3, function()
        bagsPending = false
        if Module.enabled and Recipes.BagsChanged then
            Recipes.BagsChanged()
        end
    end)
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
    ns:RegisterEvent("BAG_UPDATE_DELAYED", OnBags)
    if not listening and Prices and Prices.OnChange then
        listening = true
        Prices.OnChange(OnChange)
    end
    HookItemTooltips()
    if Recipes.StartFishingLog then
        Recipes.StartFishingLog()
    end
    if Recipes.StartFishingPopup then
        Recipes.StartFishingPopup()
    end
    Attach()
    -- 主窗口导航里的“专业”：直接单独打开专业工作台（可以看任意专业）
    ns.MainFrame:RegisterTab({ id = "professions", title = L["Professions"], order = 30, action = function()
        if Module.enabled and Recipes.OpenStandalone then
            ns.MainFrame:Hide()
            Recipes.OpenStandalone()
        end
    end })
    Update()
end

function Module:OnDisable()
    ns:UnregisterEvent("ADDON_LOADED", OnAddonLoaded)
    ns:UnregisterEvent("PLAYER_REGEN_ENABLED", OnRegenEnabled)
    for _, event in ipairs(CHANGE_EVENTS) do
        ns:UnregisterEvent(event, OnChange)
    end
    ns:UnregisterEvent("BAG_UPDATE_DELAYED", OnBags)
    if Recipes.StopFishingLog then
        Recipes.StopFishingLog()
    end
    if Recipes.StopFishingPopup then
        Recipes.StopFishingPopup()
    end
    if Recipes.HidePanel then
        Recipes.HidePanel()
    end
end
