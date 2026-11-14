local ADDON_NAME, ns = ...
local L = ns.L

-- 附魔批量制作：专业窗口里，附魔到装备（不可叠加的目标）时暴雪不给“全部制造”与数量框，只能一次次点“附魔”，
-- 每次还要在“替换附魔”的确认框点“是”。本模块在暴雪“全部制造”的位置补一个原生样子的按钮与数量框：
-- 填好次数后连续点按钮（或在按钮上滚动鼠标滚轮），每下附魔一次，按钮上显示剩余次数；
-- 替换已有附魔的确认框在专业窗口附魔时自动确认（可在设置里关）。
-- 为什么不能一次点完：游戏只允许每次附魔由玩家的一次点击（或按键、滚轮）触发，插件在附魔成功后自己发下一次会被拦下
-- （游戏内实测，2026-11-09）；一次交给客户端多次的写法，目标不可叠加时客户端只施一次。
-- 控件是插件自己的框架（暴雪 NumericInputSpinnerTemplate 与制作页同款 SharedButtonSmallTemplate），挂在暴雪制作页下面，
-- 位置与暴雪“全部制造”与数量框相同；跟随暴雪只用 hooksecurefunc 挂制作页的 ValidateControls 与表单的 Init
-- （暴雪按方法名调用），不改暴雪的按钮与表单。
local Module = ns:NewModule("Enchanting", { autoReplace = true })

local page, form, controls
local run -- 正在进行的连续附魔：{ recipeID, left, location, reagents, casting }

local function CurrentRecipe()
    local recipeInfo = form and form.GetRecipeInfo and form:GetRecipeInfo()
    if not recipeInfo then
        return nil
    end
    local transaction = form.GetTransaction and form:GetTransaction()
    local isEnchant = recipeInfo.isEnchantingRecipe
    if not isEnchant and transaction and transaction.IsRecipeType and Enum.TradeskillRecipeType then
        isEnchant = transaction:IsRecipeType(Enum.TradeskillRecipeType.Enchant)
    end
    return recipeInfo, transaction, isEnchant
end

local function Craftable(recipeID)
    local count = C_TradeSkillUI.GetCraftableCount and C_TradeSkillUI.GetCraftableCount(recipeID)
    return type(count) == "number" and count or 0
end

-- 按钮宽度随文字（与暴雪制作页按钮一样用 SetTextToFit）
local function SetButtonText(text)
    local button = controls.button
    if button.SetTextToFit then
        button:SetTextToFit(text)
    else
        button:SetText(text)
    end
    if button.GetWidth and (button:GetWidth() or 0) < 80 then
        button:SetWidth(80)
    end
end

local function Update()
    if not controls then
        return
    end
    local recipeInfo, transaction, isEnchant = CurrentRecipe()
    local blizzardAll = page.CreateAllButton
    local show = Module.enabled and recipeInfo and recipeInfo.learned and isEnchant
        and not (type(blizzardAll) == "table" and blizzardAll:IsShown())
    if not show then
        controls.button:Hide()
        controls.count:Hide()
        return
    end
    controls.button:Show()
    controls.count:Show()
    if run then
        SetButtonText((L["Next enchant (%d left)"]):format(run.left))
        controls.button:SetEnabled(not InCombatLockdown())
        controls.count:SetEnabled(false)
        return
    end
    controls.count:SetEnabled(true)
    local most = Craftable(recipeInfo.recipeID)
    local target = transaction and transaction.GetEnchantAllocation and transaction:GetEnchantAllocation()
    controls.count:SetMinMaxValues(math.min(1, most), most)
    local value = controls.count:GetValue() or 0
    if value < 1 or value > most then
        controls.count:SetValue(most)
    end
    SetButtonText((L["Enchant %d times"]):format(math.max(1, math.min(controls.count:GetValue() or 1, most))))
    controls.button:SetEnabled(most > 0 and target ~= nil and not InCombatLockdown())
    controls.button.reason = (most == 0 and L["You don't have the materials."])
        or (not target and L["Choose the item to enchant first."]) or nil
end

local function Stop(message)
    if not run then
        return
    end
    run = nil
    if message then
        ns:Print(message)
    end
    Update()
end

-- 附魔一次：只在玩家点击（或滚轮）的处理里调用；正在施法时忽略多余的点击
local function CastOnce()
    if not run or run.casting or (UnitCastingInfo and UnitCastingInfo("player")) then
        return
    end
    if InCombatLockdown() or Craftable(run.recipeID) == 0 then
        Stop(L["Enchanting stopped."])
        return
    end
    run.casting = true
    C_TradeSkillUI.CraftEnchant(run.recipeID, 1, run.reagents, run.location, false)
end

local function OnButton(_, mouseButton)
    if mouseButton == "RightButton" then
        Stop(L["Enchanting stopped."])
        return
    end
    if not run then
        local recipeInfo, transaction = CurrentRecipe()
        local target = transaction and transaction:GetEnchantAllocation()
        if not (recipeInfo and target and target.GetItemLocation) then
            return
        end
        local count = math.min(controls.count:GetValue() or 0, Craftable(recipeInfo.recipeID))
        if count < 1 then
            return
        end
        controls.count:ClearFocus()
        run = {
            recipeID = recipeInfo.recipeID,
            left = count,
            location = target:GetItemLocation(),
            reagents = transaction.GetCraftingReagentInfos and transaction:GetCraftingReagentInfos() or nil,
        }
    end
    CastOnce()
    Update()
end

-- 每次附魔成功：剩余次数减一，做完就结束
local function OnSpellSucceeded(_, unit, _, spellID)
    if not (run and unit == "player" and spellID == run.recipeID) then
        return
    end
    run.casting = false
    run.left = run.left - 1
    if run.left <= 0 then
        Stop(L["Enchanting finished."])
        return
    end
    Update()
end

-- 打断或失败：这一次不算，玩家可以接着点
local function OnSpellStopped(_, unit, _, spellID)
    if run and unit == "player" and spellID == run.recipeID then
        run.casting = false
        Update()
    end
end

-- 替换已有附魔的确认：只在专业窗口开着、选的是附魔配方时自动点“是”
local function OnReplace(event)
    if not (ns:GetModuleSettings(Module).autoReplace and page and page:IsVisible()) then
        return
    end
    local _, _, isEnchant = CurrentRecipe()
    if not isEnchant then
        return
    end
    local confirm = event == "REPLACE_TRADESKILL_ENCHANT" and C_Item.ReplaceTradeskillEnchant or C_Item.ReplaceEnchant
    if not confirm then
        return
    end
    confirm()
    -- 暴雪的确认框可能在我们之后才弹出：下一帧再收起
    C_Timer.After(0, function()
        if StaticPopup_Hide then
            StaticPopup_Hide("REPLACE_ENCHANT")
            StaticPopup_Hide("REPLACE_TRADESKILL_ENCHANT")
        end
    end)
end

local function ShowButtonTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L["Enchant all"])
    local help = L["Click once per enchant, or turn the mouse wheel over this button. The game allows one enchant per click."]
    GameTooltip:AddLine(help, 1, 1, 1, true)
    GameTooltip:AddLine(L["Right-click to stop."], unpack(ns.Theme.colors.textDim))
    if self.reason and not run then
        GameTooltip:AddLine(self.reason, unpack(ns.Theme.colors.red))
    end
    GameTooltip:Show()
end

local function CreateControls()
    controls = {}
    -- 与暴雪“全部制造”与数量框同一模板、同一位置（Camelot 版制作页的 GetButtonTemplate 与 SetControlAnchors）；
    -- 暴雪显示自己的按钮时我们隐藏
    local count = CreateFrame("EditBox", nil, page, "NumericInputSpinnerTemplate")
    count:SetPoint("BOTTOMLEFT", page, "BOTTOMRIGHT", -185, 11)
    if count.SetOnValueChangedCallback then
        count:SetOnValueChangedCallback(function()
            if not run then
                Update()
            end
        end)
    end
    controls.count = count
    local button = CreateFrame("Button", nil, page, "SharedButtonSmallTemplate")
    button:SetWidth(80)
    button:SetPoint("BOTTOMLEFT", page, "BOTTOMRIGHT", -362, 7)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnClick", OnButton)
    -- 滚轮也算玩家操作：在按钮上滚一格附魔一次
    button:EnableMouseWheel(true)
    button:SetScript("OnMouseWheel", function(self)
        if run and self:IsEnabled() then
            OnButton(self, "LeftButton")
        end
    end)
    button:SetScript("OnEnter", ShowButtonTooltip)
    button:SetScript("OnLeave", GameTooltip_Hide)
    controls.button = button
    count:Hide()
    button:Hide()
end

-- 换了配方才停：暴雪每次附魔后也会刷新表单（同一配方再 Init 一次），那时不停
local function OnRecipeChanged(_, recipeInfo)
    if not Module.enabled then
        return
    end
    if run and not (recipeInfo and recipeInfo.recipeID == run.recipeID) then
        Stop(L["Enchanting stopped."])
    end
    Update()
end

local function Attach()
    local craftingPage = type(ProfessionsFrame) == "table" and ProfessionsFrame.CraftingPage
    if type(craftingPage) ~= "table" or page then
        return
    end
    page, form = craftingPage, craftingPage.SchematicForm
    CreateControls()
    hooksecurefunc(page, "ValidateControls", Update)
    if type(form) == "table" and form.Init then
        hooksecurefunc(form, "Init", OnRecipeChanged)
    end
    if page.HookScript then
        page:HookScript("OnHide", function()
            Stop(nil)
        end)
    end
    Update()
end

local function OnAddonLoaded(_, name)
    if name == "Blizzard_Professions" and Module.enabled then
        Attach()
    end
end

local EVENTS = {
    ADDON_LOADED = OnAddonLoaded,
    UNIT_SPELLCAST_SUCCEEDED = OnSpellSucceeded,
    UNIT_SPELLCAST_INTERRUPTED = OnSpellStopped,
    UNIT_SPELLCAST_FAILED = OnSpellStopped,
    REPLACE_ENCHANT = OnReplace,
    REPLACE_TRADESKILL_ENCHANT = OnReplace,
    BAG_UPDATE_DELAYED = Update,
    PLAYER_REGEN_DISABLED = function() Stop(L["Enchanting stopped."]) end,
}

function Module:OnEnable()
    if not (C_TradeSkillUI and C_TradeSkillUI.CraftEnchant) then
        return
    end
    for event, handler in pairs(EVENTS) do
        ns:RegisterEvent(event, handler)
    end
    Attach()
    Update()
end

function Module:OnDisable()
    for event, handler in pairs(EVENTS) do
        ns:UnregisterEvent(event, handler)
    end
    run = nil
    Update()
end

-- 测试用
Module.IsRunning = function()
    return run ~= nil and run.left or nil
end
