local ADDON_NAME, ns = ...
local L = ns.L

-- 制作成本：专业窗口（K 键打开的 ProfessionsFrame，按需加载的 Blizzard_Professions）里，
-- 选中配方的表单右下角显示“每次制作的利润”，按算式自上而下：成品卖价 − 拍卖行 5% 手续费 − 材料 = 利润，
-- 下面一句话说明结论（赚多少成、亏钱，或缺哪些价格、怎么补）。没有成品的配方（附魔等）只显示每次的材料花费。
-- 方案：材料能用本专业已学的配方自己做时（毛布卷用毛料做），每种这样的材料有“直接买”与“自己做”两种取法，
-- 组合起来是几个方案；面板显示利润最高（没有成品时花费最少）的方案，悬停列出全部方案与所选方案的逐项材料。
-- 自己做只往下看一层：做它的材料按买入价算；正在冷却的配方不算。
-- 成品按卖店价与拍卖价（扣 5% 手续费后）取高的：有些成品卖店比挂拍卖还值钱，这时按卖店算、不扣手续费。
-- 材料单价取商人售价与拍卖行价格的低者；商人售价在打开商人时记下（只记金币购买、不限量的物品）。
-- 成本面板是插件自己的框架，挂在暴雪配方表单下面随它显示；跟随暴雪只用 hooksecurefunc 挂表单的 Init
-- （暴雪按方法名调用），不改暴雪表单的数据与控件。
local Module = ns:NewModule("CraftingCost")
local Prices = ns.Prices

local AUCTION_CUT = 0.05
local MAX_COMBINED = 3 -- 能自己做的材料不超过 3 种时列出全部组合（最多 8 个方案），再多只列三种代表方案

local panel, form, hookedForm
local current -- 正在显示的配方 ID

local function ItemName(itemID)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if not name then
        ns.RequestItem(itemID)
    end
    return name or ("item:" .. itemID)
end

local function Schematic(recipeID)
    return C_TradeSkillUI.GetRecipeSchematic and C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
end

local function AverageYield(schematic)
    return ((schematic.quantityMin or 1) + (schematic.quantityMax or schematic.quantityMin or 1)) / 2
end

-- 本专业已学的配方能做出哪些物品：物品 ID → 配方 ID。专业窗口里配方列表变化时标记重建；
-- 战斗中不重建（沿用旧表），避免在战斗里遍历全部配方。
local makers, makersDirty = nil, true
local function Makers()
    if makers and (not makersDirty or InCombatLockdown()) then
        return makers
    end
    if InCombatLockdown() then
        return {}
    end
    makers, makersDirty = {}, false
    if not (C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo) then
        return makers
    end
    for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if info and info.learned then
            local schematic = Schematic(recipeID)
            local itemID = schematic and schematic.outputItemID
            if itemID and not makers[itemID] then
                makers[itemID] = recipeID
            end
        end
    end
    return makers
end

-- 一个材料槽里有价格的最便宜买法
local function CheapestBuy(slot)
    local best
    for _, reagent in ipairs(slot.reagents or {}) do
        if reagent.itemID then
            local price, source = Prices.BuyCost(reagent.itemID)
            if not best or (price and (not best.price or price < best.price)) then
                best = { itemID = reagent.itemID, price = price, source = source }
            end
        end
    end
    return best
end

local function RequiredSlots(schematic)
    local slots = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
        if slot.required and (slot.quantityRequired or 0) > 0 then
            tinsert(slots, slot)
        end
    end
    return slots
end

-- 自己做一个材料的单价：做它的配方的材料全按买入价，除以平均产出。有材料没价格时返回 nil
local function CraftUnit(makerID)
    local cooldown = C_TradeSkillUI.GetRecipeCooldown and C_TradeSkillUI.GetRecipeCooldown(makerID)
    if cooldown and cooldown > 0 then
        return nil
    end
    local schematic = Schematic(makerID)
    if not schematic then
        return nil
    end
    local parts, total = {}, 0
    for _, slot in ipairs(RequiredSlots(schematic)) do
        local buy = CheapestBuy(slot)
        if not (buy and buy.price) then
            return nil
        end
        buy.quantity = slot.quantityRequired
        tinsert(parts, buy)
        total = total + buy.price * buy.quantity
    end
    if #parts == 0 then
        return nil
    end
    local yield = AverageYield(schematic)
    return total / yield, parts, yield
end

-- 一个槽里自己做最便宜的一种
local function CheapestCraft(slot, recipeID)
    local index, best = Makers()
    for _, reagent in ipairs(slot.reagents or {}) do
        local makerID = reagent.itemID and index[reagent.itemID]
        if makerID and makerID ~= recipeID then
            local unit, parts, yield = CraftUnit(makerID)
            if unit and (not best or unit < best.price) then
                best = { itemID = reagent.itemID, price = unit, source = "craft", parts = parts, yield = yield }
            end
        end
    end
    return best
end

-- 按每槽的取法（true 为自己做）算一个方案
local function BuildPlan(slots, crafting, net)
    local plan = { reagents = {}, cost = 0, missing = 0, crafted = {} }
    for index, slot in ipairs(slots) do
        local choice = crafting[index] and slot.craft or slot.buy
        local reagent = {}
        for key, field in pairs(choice) do
            reagent[key] = field
        end
        reagent.quantity = slot.quantity
        reagent.buyPrice = slot.buy.price
        tinsert(plan.reagents, reagent)
        if choice.price then
            plan.cost = plan.cost + choice.price * slot.quantity
        else
            plan.missing = plan.missing + 1
        end
        if crafting[index] then
            tinsert(plan.crafted, choice.itemID)
        end
    end
    if net and plan.missing == 0 then
        plan.profit = floor(net - plan.cost + 0.5)
    end
    return plan
end

-- 方案排序：价格齐全的在前；有成品按利润从高到低，没有成品按花费从低到高；缺价格的按缺得少、花费低
local function BetterPlan(a, b)
    if (a.missing == 0) ~= (b.missing == 0) then
        return a.missing == 0
    end
    if a.profit and b.profit and a.profit ~= b.profit then
        return a.profit > b.profit
    end
    if a.missing ~= b.missing then
        return a.missing < b.missing
    end
    if a.cost ~= b.cost then
        return a.cost < b.cost
    end
    return #a.crafted < #b.crafted
end

-- 算一个配方：每个必需材料槽的买法与自己做法、全部方案（最好的在前）、成品价值。
-- result.reagents / cost / missing 是最好方案的
local function Evaluate(recipeID)
    local schematic = Schematic(recipeID)
    if not schematic then
        return nil
    end
    local result = { slots = {}, reagents = {}, cost = 0, missing = 0, plans = {} }
    local itemID = schematic.outputItemID
    if itemID then
        local price = Prices.Auction(itemID)
        local quantity = AverageYield(schematic)
        result.outputItemID, result.quantity = itemID, quantity
        local vendor = select(11, C_Item.GetItemInfo(itemID))
        if vendor == nil then
            ns.RequestItem(itemID)
        end
        result.unitValue = price
        result.vendorUnit = vendor and vendor > 0 and vendor or nil
        if result.vendorUnit and (not price or result.vendorUnit > price * (1 - AUCTION_CUT)) then
            -- 卖店更值钱（或拍卖行还没价格）：卖价是卖店价，不扣手续费
            result.toVendor = true
            result.value = result.vendorUnit * quantity
            result.net = result.value
        elseif price then
            result.value = price * quantity
            result.net = result.value * (1 - AUCTION_CUT)
        end
    end

    local craftable = {}
    for _, slotSchematic in ipairs(RequiredSlots(schematic)) do
        local buy = CheapestBuy(slotSchematic)
        if buy then
            local slot = { quantity = slotSchematic.quantityRequired, buy = buy, craft = CheapestCraft(slotSchematic, recipeID) }
            tinsert(result.slots, slot)
            if slot.craft then
                tinsert(craftable, #result.slots)
            end
        end
    end
    if #result.slots == 0 then
        return result
    end

    local choices = {}
    if #craftable <= MAX_COMBINED then
        for mask = 0, 2 ^ #craftable - 1 do
            local crafting, bits = {}, mask
            for _, index in ipairs(craftable) do
                crafting[index] = bits % 2 == 1
                bits = floor(bits / 2)
            end
            tinsert(choices, crafting)
        end
    else
        -- 种类太多：全部买、全部自己做、每种取便宜的
        local all, cheaper = {}, {}
        for _, index in ipairs(craftable) do
            local slot = result.slots[index]
            all[index] = true
            cheaper[index] = not slot.buy.price or slot.craft.price < slot.buy.price
        end
        choices = { {}, all, cheaper }
    end
    for _, crafting in ipairs(choices) do
        tinsert(result.plans, BuildPlan(result.slots, crafting, result.net))
    end
    table.sort(result.plans, BetterPlan)
    local best = result.plans[1]
    result.best, result.reagents, result.cost, result.missing = best, best.reagents, best.cost, best.missing
    return result
end

local function MoneyText(copper)
    return ns.Money(floor(copper + 0.5)) or "0"
end

local function SignedMoney(copper)
    local money = ns.Money(math.abs(copper)) or "0"
    return copper >= 0 and ns.Theme:Color("+" .. money, "green") or ns.Theme:Color("-" .. money, "red")
end

local function PlanName(plan)
    if #plan.crafted == 0 then
        return L["Buy every material"]
    end
    local names = {}
    for _, itemID in ipairs(plan.crafted) do
        tinsert(names, ItemName(itemID))
    end
    return (L["Craft %s yourself"]):format(table.concat(names, L[", "]))
end

local function Amount(quantity)
    return ("%g"):format(floor(quantity * 100 + 0.5) / 100)
end

-- 鼠标提示：全部方案的利润（或花费），所选方案每种材料的数量、单价与来源（自己做的再列下一层材料），成品单价与价格口径
local function ShowBreakdown(self)
    local result = self.result
    if not result then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    local dim, text, gold = ns.Theme.colors.textDim, ns.Theme.colors.text, ns.Theme.colors.gold
    if #result.plans > 1 then
        GameTooltip:SetText((L["All %d plans"]):format(#result.plans))
        for index, plan in ipairs(result.plans) do
            local right
            if result.outputItemID then
                right = plan.profit and SignedMoney(plan.profit) or ns.Theme:Color("?", "muted")
            else
                right = MoneyText(plan.cost) .. (plan.missing > 0 and ns.Theme:Color(" ?", "muted") or "")
            end
            local left = PlanName(plan)
            if index == 1 then
                GameTooltip:AddDoubleLine(left .. "  " .. ns.Theme:Color(L["(shown)"], "gold"), right,
                    gold[1], gold[2], gold[3], text[1], text[2], text[3])
            else
                GameTooltip:AddDoubleLine(left, right, dim[1], dim[2], dim[3], text[1], text[2], text[3])
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Materials for the plan shown"], gold[1], gold[2], gold[3])
    else
        GameTooltip:SetText(L["Where the numbers come from"])
    end
    for _, reagent in ipairs(result.reagents) do
        local left = ("%s x%d"):format(ItemName(reagent.itemID), reagent.quantity)
        local right
        if reagent.source == "craft" then
            local buy = reagent.buyPrice and MoneyText(reagent.buyPrice) or L["no price yet"]
            right = (L["%s (craft %s each, buy %s)"]):format(MoneyText(reagent.price * reagent.quantity),
                MoneyText(reagent.price), buy)
        elseif reagent.price then
            local where = reagent.source == "vendor" and L["vendor"] or L["auction"]
            right = (L["%s (%s each, %s)"]):format(MoneyText(reagent.price * reagent.quantity),
                MoneyText(reagent.price), where)
        else
            right = L["no price yet"]
        end
        GameTooltip:AddDoubleLine(left, right, dim[1], dim[2], dim[3], text[1], text[2], text[3])
        if reagent.source == "craft" then
            for _, part in ipairs(reagent.parts) do
                local used = part.quantity * reagent.quantity / reagent.yield
                local where = part.source == "vendor" and L["vendor"] or L["auction"]
                GameTooltip:AddDoubleLine(("    %s x%s"):format(ItemName(part.itemID), Amount(used)),
                    (L["%s (%s each, %s)"]):format(MoneyText(part.price * used), MoneyText(part.price), where),
                    dim[1], dim[2], dim[3], dim[1], dim[2], dim[3])
            end
        end
    end
    if result.outputItemID then
        local right = result.unitValue and (L["%s each, auction"]):format(MoneyText(result.unitValue)) or L["no price yet"]
        GameTooltip:AddDoubleLine((L["Makes: %s"]):format(ItemName(result.outputItemID)), right,
            dim[1], dim[2], dim[3], text[1], text[2], text[3])
        if result.vendorUnit then
            GameTooltip:AddDoubleLine("    " .. L["Vendor price"], (L["%s each"]):format(MoneyText(result.vendorUnit)),
                dim[1], dim[2], dim[3], text[1], text[2], text[3])
        end
        if result.toVendor and result.unitValue then
            GameTooltip:AddLine(L["A vendor pays more than the auction house after its cut, so the profit uses the vendor price."],
                gold[1], gold[2], gold[3], true)
        end
    end
    if result.missing > 0 or (result.outputItemID and not result.value) then
        GameTooltip:AddLine(L["Search for these at the auction house, or scan it, to fill in the missing prices."],
            1, 1, 1, true)
    end
    GameTooltip:AddLine(L["Prices are the lowest buyouts recorded. A material uses the vendor price when that is cheaper."],
        dim[1], dim[2], dim[3], true)
    if #result.plans > 1 then
        GameTooltip:AddLine(L["Crafted materials use your learned recipes and count their own materials at the buying price."],
            dim[1], dim[2], dim[3], true)
    end
    GameTooltip:Show()
end

local WIDTH, ROW = 220, 14

local function Line(parent, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetJustifyH("LEFT")
    local value = parent:CreateFontString(nil, "OVERLAY", font)
    value:SetJustifyH("RIGHT")
    return { label = label, value = value }
end

local function Wrapped(parent)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetJustifyH("LEFT")
    text:SetWidth(WIDTH)
    return text
end

local function CreatePanel(host)
    panel = CreateFrame("Frame", nil, host)
    panel:SetSize(WIDTH, 100)
    -- Camelot 版把“追踪配方”勾选框移到表单右下角（距底 11），面板放在它上面，向上长
    panel:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -28, 42)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetJustifyH("LEFT")
    panel.plan = Wrapped(panel)
    panel.sells = Line(panel, "GameFontHighlightSmall")
    panel.cut = Line(panel, "GameFontHighlightSmall")
    panel.materials = Line(panel, "GameFontHighlightSmall")
    panel.cut.label:SetText(L["Auction house cut (5%)"])
    panel.materials.label:SetText(L["Materials"])
    panel.divider = panel:CreateTexture(nil, "ARTWORK")
    panel.divider:SetHeight(1)
    ns.Theme:Paint(panel.divider, "goldDim")
    panel.profit = Line(panel, "GameFontNormal")
    panel.profit.label:SetText(L["Profit"])
    panel.note = Wrapped(panel)
    panel:EnableMouse(true)
    panel:SetScript("OnEnter", ShowBreakdown)
    panel:SetScript("OnLeave", GameTooltip_Hide)
end

-- 自上而下排版：只排显示的行，最后按内容定高（面板底边固定，向上长）
local function Layout(lines)
    local y = 0
    panel.title:ClearAllPoints()
    panel.title:SetPoint("TOPLEFT", 0, 0)
    y = y - 18
    for _, entry in ipairs({ panel.plan, panel.sells, panel.cut, panel.materials, panel.divider, panel.profit, panel.note }) do
        local shown = lines[entry] and true or false
        if entry.label then
            entry.label:SetShown(shown)
            entry.value:SetShown(shown)
            if shown then
                entry.label:ClearAllPoints()
                entry.label:SetPoint("TOPLEFT", 0, y)
                entry.value:ClearAllPoints()
                entry.value:SetPoint("TOPRIGHT", 0, y)
                y = y - (entry == panel.profit and 18 or ROW)
            end
        else
            entry:SetShown(shown)
            if shown then
                entry:ClearAllPoints()
                if entry == panel.divider then
                    y = y - 2
                    entry:SetPoint("TOPLEFT", 0, y)
                    entry:SetPoint("TOPRIGHT", 0, y)
                    y = y - 5
                elseif entry == panel.plan then
                    entry:SetPoint("TOPLEFT", 0, y)
                    y = y - math.max(ROW, entry:GetStringHeight() or ROW) - 3
                else
                    entry:SetPoint("TOPLEFT", 0, y - 2)
                    y = y - 2 - math.max(ROW, entry:GetStringHeight() or ROW)
                end
            end
        end
    end
    panel:SetHeight(-y)
end

local function Render(recipeID)
    current = recipeID
    if not panel then
        return
    end
    local result = recipeID and Evaluate(recipeID)
    panel.result = result
    if not (result and #result.reagents > 0) then
        panel:Hide()
        return
    end
    local lines = { [panel.materials] = true }
    -- 有几个方案时，标题下写出显示的是哪个
    if #result.plans > 1 then
        local key = result.outputItemID and L["Most profitable of %d plans: %s"] or L["Cheapest of %d plans: %s"]
        panel.plan:SetText(ns.Theme:Color(key:format(#result.plans, PlanName(result.best)), "gold"))
        lines[panel.plan] = true
    end
    local materials = MoneyText(result.cost)
    if result.missing > 0 then
        materials = (L["%s + %d unpriced"]):format(materials, result.missing)
    end

    -- 没有成品的配方（附魔等）：只看每次的材料花费
    if not result.outputItemID then
        panel.title:SetText(L["Material cost per craft"])
        panel.materials.value:SetText(materials)
        if result.missing > 0 then
            panel.note:SetText(ns.Theme:Color(
                L["Some materials have no price yet. Search them at the auction house, or scan it."], "muted"))
            lines[panel.note] = true
        end
        Layout(lines)
        panel:Show()
        return
    end

    panel.title:SetText(L["Profit per craft"])
    panel.materials.value:SetText("-" .. materials)
    lines[panel.sells], lines[panel.divider], lines[panel.profit], lines[panel.note] = true, true, true, true
    local quantity = result.quantity or 1
    local amount = ("%g"):format(quantity)
    if result.toVendor then
        panel.sells.label:SetText(quantity == 1 and L["Sells to a vendor for"] or (L["Sells to a vendor for (x%s)"]):format(amount))
    else
        panel.sells.label:SetText(quantity == 1 and L["Sells for"] or (L["Sells for (x%s)"]):format(amount))
    end
    if result.toVendor then
        panel.sells.value:SetText(MoneyText(result.value))
    elseif result.value then
        panel.sells.value:SetText(MoneyText(result.value))
        panel.cut.value:SetText("-" .. MoneyText(result.value * AUCTION_CUT))
        lines[panel.cut] = true
    else
        panel.sells.value:SetText(ns.Theme:Color(L["no price yet"], "muted"))
    end

    local note
    local profit = result.best.profit
    if profit then
        panel.profit.value:SetText(SignedMoney(profit))
        if profit > 0 and result.cost > 0 then
            local margin = floor(profit / result.cost * 100 + 0.5)
            note = ns.Theme:Color((L["Earns %d%% on top of what the materials cost."]):format(margin), "green")
        elseif profit > 0 then
            note = ns.Theme:Color(L["Worth crafting to sell."], "green")
        elseif profit == 0 then
            note = ns.Theme:Color(L["Breaks even at current prices."], "muted")
        else
            note = ns.Theme:Color(L["Crafting to sell loses money at current prices."], "red")
        end
    else
        panel.profit.value:SetText(ns.Theme:Color("?", "muted"))
        if not result.value then
            note = L["Search for this item at the auction house to see the profit."]
        else
            note = L["Some materials have no price yet. Search them at the auction house, or scan it."]
        end
        note = ns.Theme:Color(note, "muted")
    end
    panel.note:SetText(note)
    Layout(lines)
    panel:Show()
end

local function OnFormInit(_, recipeInfo)
    if not Module.enabled then
        return
    end
    Render(recipeInfo and recipeInfo.recipeID)
end

local function Attach()
    local page = type(ProfessionsFrame) == "table" and ProfessionsFrame.CraftingPage
    local schematicForm = type(page) == "table" and page.SchematicForm
    if type(schematicForm) ~= "table" or hookedForm then
        return
    end
    hookedForm, form = true, schematicForm
    CreatePanel(form)
    hooksecurefunc(form, "Init", OnFormInit)
    local recipeInfo = form.GetRecipeInfo and form:GetRecipeInfo()
    Render(recipeInfo and recipeInfo.recipeID)
end

-- 价格变化（搜索、扫描、商人）时重算正在显示的配方；合并 0.5 秒内的多次变化
local refreshPending = false
local function OnPricesChanged()
    if refreshPending or not (Module.enabled and panel and current and form:IsVisible()) then
        return
    end
    refreshPending = true
    C_Timer.After(0.5, function()
        refreshPending = false
        if Module.enabled and current then
            Render(current)
        end
    end)
end

-- 记下商人的金币售价（每件），只记不限量、不要求其他货币的物品
local function RecordMerchant()
    local count = GetMerchantNumItems and GetMerchantNumItems() or 0
    for index = 1, count do
        local itemID = GetMerchantItemID and GetMerchantItemID(index)
        local info = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(index)
        if itemID and info and not info.hasExtendedCost and info.numAvailable == -1 and (info.price or 0) > 0 then
            Prices.RecordVendor(itemID, info.price / math.max(1, info.stackCount or 1))
        end
    end
end

local merchantPending = false
local function OnMerchant()
    if merchantPending then
        return
    end
    merchantPending = true
    C_Timer.After(0.5, function()
        merchantPending = false
        if Module.enabled then
            RecordMerchant()
        end
    end)
end

-- 配方列表变化（打开或切换专业、学会新配方）时，“能自己做的材料”表下次用时重建
local function OnRecipesChanged()
    makersDirty = true
end

local function OnAddonLoaded(_, name)
    if name == "Blizzard_Professions" and Module.enabled then
        Attach()
    end
end

local listening = false
function Module:OnEnable()
    if not C_TradeSkillUI then
        return
    end
    ns:RegisterEvent("ADDON_LOADED", OnAddonLoaded)
    ns:RegisterEvent("MERCHANT_SHOW", OnMerchant)
    ns:RegisterEvent("MERCHANT_UPDATE", OnMerchant)
    ns:RegisterEvent("TRADE_SKILL_SHOW", OnRecipesChanged)
    ns:RegisterEvent("TRADE_SKILL_LIST_UPDATE", OnRecipesChanged)
    ns:RegisterEvent("NEW_RECIPE_LEARNED", OnRecipesChanged)
    makersDirty = true
    if not listening then
        listening = true
        Prices.OnChange(OnPricesChanged)
    end
    Attach()
    if form then
        local recipeInfo = form.GetRecipeInfo and form:GetRecipeInfo()
        Render(recipeInfo and recipeInfo.recipeID)
    end
end

function Module:OnDisable()
    ns:UnregisterEvent("ADDON_LOADED", OnAddonLoaded)
    ns:UnregisterEvent("MERCHANT_SHOW", OnMerchant)
    ns:UnregisterEvent("MERCHANT_UPDATE", OnMerchant)
    ns:UnregisterEvent("TRADE_SKILL_SHOW", OnRecipesChanged)
    ns:UnregisterEvent("TRADE_SKILL_LIST_UPDATE", OnRecipesChanged)
    ns:UnregisterEvent("NEW_RECIPE_LEARNED", OnRecipesChanged)
    current, makers = nil, nil
    if panel then
        panel:Hide()
    end
end

-- 测试用：按当前价格算一个配方
Module.Evaluate = Evaluate
