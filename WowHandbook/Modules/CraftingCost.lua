local ADDON_NAME, ns = ...
local L = ns.L

-- 制作成本：专业窗口（K 键打开的 ProfessionsFrame，按需加载的 Blizzard_Professions）里，
-- 选中配方的表单右下角显示材料成本、成品拍卖价、利润（扣除拍卖行 5% 手续费）与利润率（利润 ÷ 材料成本），
-- 悬停看每种材料的单价与来源。
-- 材料单价取商人售价与拍卖行价格的低者；商人售价在打开商人时记下（只记金币购买、不限量的物品）。
-- 成本面板是插件自己的框架，挂在暴雪配方表单下面随它显示；跟随暴雪只用 hooksecurefunc 挂表单的 Init
-- （暴雪按方法名调用），不改暴雪表单的数据与控件。
local Module = ns:NewModule("CraftingCost")
local Prices = ns.Prices

local AUCTION_CUT = 0.05

local panel, form, hookedForm
local current -- 正在显示的配方 ID

local function ItemName(itemID)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if not name then
        ns.RequestItem(itemID)
    end
    return name or ("item:" .. itemID)
end

-- 算一个配方：材料（必需的材料槽，每槽取有价格的最便宜一种）、成本、成品价值
local function Evaluate(recipeID)
    local schematic = C_TradeSkillUI.GetRecipeSchematic and C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    if not schematic then
        return nil
    end
    local result = { reagents = {}, cost = 0, missing = 0 }
    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
        if slot.required and (slot.quantityRequired or 0) > 0 then
            local best
            for _, reagent in ipairs(slot.reagents or {}) do
                if reagent.itemID then
                    local price, source = Prices.BuyCost(reagent.itemID)
                    if not best or (price and (not best.price or price < best.price)) then
                        best = { itemID = reagent.itemID, price = price, source = source }
                    end
                end
            end
            if best then
                best.quantity = slot.quantityRequired
                tinsert(result.reagents, best)
                if best.price then
                    result.cost = result.cost + best.price * best.quantity
                else
                    result.missing = result.missing + 1
                end
            end
        end
    end
    local itemID = schematic.outputItemID
    if itemID then
        local price = Prices.Auction(itemID)
        local quantity = ((schematic.quantityMin or 1) + (schematic.quantityMax or schematic.quantityMin or 1)) / 2
        result.outputItemID, result.quantity = itemID, quantity
        if price then
            result.value = price * quantity
        end
    end
    return result
end

local function ShowBreakdown(self)
    local result = self.result
    if not result then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(L["Crafting cost"])
    local dim, text = ns.Theme.colors.textDim, ns.Theme.colors.text
    for _, reagent in ipairs(result.reagents) do
        local left = ("%s x%d"):format(ItemName(reagent.itemID), reagent.quantity)
        local right
        if reagent.price then
            local where = reagent.source == "vendor" and L["vendor"] or L["auction"]
            right = ("%s (%s)"):format(ns.Money(floor(reagent.price * reagent.quantity + 0.5)) or "0", where)
        else
            right = L["no price yet"]
        end
        GameTooltip:AddDoubleLine(left, right, dim[1], dim[2], dim[3], text[1], text[2], text[3])
    end
    if result.missing > 0 then
        GameTooltip:AddLine(L["Search for these at the auction house, or scan it, to fill in the missing prices."],
            1, 1, 1, true)
    end
    if result.value then
        GameTooltip:AddLine(L["Profit is after the auction house's 5% cut."], unpack(dim))
        GameTooltip:AddLine(L["Margin is profit divided by material cost."], unpack(dim))
    end
    GameTooltip:Show()
end

local function Row(parent, index, label)
    local name = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("TOPLEFT", 0, -(index - 1) * 14)
    name:SetText(label)
    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("TOPRIGHT", 0, -(index - 1) * 14)
    value:SetJustifyH("RIGHT")
    return value
end

local function CreatePanel(host)
    panel = CreateFrame("Frame", nil, host)
    panel:SetSize(210, 56)
    -- Camelot 版把“追踪配方”勾选框移到表单右下角（距底 11），面板放在它上面
    panel:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -28, 42)
    panel.cost = Row(panel, 1, L["Material cost"])
    panel.value = Row(panel, 2, L["Auction price"])
    panel.profit = Row(panel, 3, L["Profit"])
    panel.margin = Row(panel, 4, L["Margin"])
    panel:EnableMouse(true)
    panel:SetScript("OnEnter", ShowBreakdown)
    panel:SetScript("OnLeave", GameTooltip_Hide)
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
    local cost = ns.Money(floor(result.cost + 0.5)) or "0"
    if result.missing > 0 then
        cost = (L["%s (%d without price)"]):format(cost, result.missing)
    end
    panel.cost:SetText(cost)
    panel.value:SetText(result.value and ns.Money(floor(result.value + 0.5)) or (result.outputItemID and L["no price yet"] or "-"))
    if result.value and result.missing == 0 then
        local profit = floor(result.value * (1 - AUCTION_CUT) - result.cost + 0.5)
        local money = ns.Money(math.abs(profit)) or "0"
        panel.profit:SetText(profit >= 0 and ns.Theme:Color("+" .. money, "green") or ns.Theme:Color("-" .. money, "red"))
        if result.cost > 0 then
            local margin = floor(profit / result.cost * 100 + 0.5)
            local text = ("%+d%%"):format(margin)
            panel.margin:SetText(ns.Theme:Color(text, margin >= 0 and "green" or "red"))
        else
            panel.margin:SetText("-")
        end
    else
        panel.profit:SetText("-")
        panel.margin:SetText("-")
    end
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
    current = nil
    if panel then
        panel:Hide()
    end
end

-- 测试用：按当前价格算一个配方
Module.Evaluate = Evaluate
