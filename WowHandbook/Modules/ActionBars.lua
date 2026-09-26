local ADDON_NAME, ns = ...
local L = ns.L

-- 动作条（F5）：
-- · 等级提升：学会某技能的更高等级后，动作条上所有低等级的同名技能换成最高等级。
-- · 新技能：学会新的主动技能且它不在任何动作条上时，放进主动作条第一个空位。
-- 战斗中动作条不能改动，排队等脱战后执行。只处理技能，不动宏、物品和其他按钮。
local Module = ns:NewModule("ActionBars", { upgradeRanks = true, placeNewSpells = true })

local MAX_SLOTS = 120
local MAIN_BAR = { 1, 12 }  -- 主动作条第一页
local pendingUpgrade = false
local pendingNew = {}

local function Settings()
    return ns:GetModuleSettings(Module)
end

local function PlaceSpell(spellID, slot)
    ClearCursor()
    C_Spell.PickupSpell(spellID)
    PlaceAction(slot)
    ClearCursor()
end

local function UpgradeRanks()
    local known = ns.KnownSpells()
    local upgraded = 0
    for slot = 1, MAX_SLOTS do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id then
            local name = C_Spell.GetSpellName(id)
            local entry = name and known[name:lower()]
            if entry and entry.best > 0 then
                local current = ns.RankNumber(C_Spell.GetSpellSubtext(id))
                local best = entry.ids[entry.best]
                if current > 0 and current < entry.best and best and best ~= id then
                    PlaceSpell(best, slot)
                    upgraded = upgraded + 1
                end
            end
        end
    end
    if upgraded > 0 then
        ns:Print(L["Upgraded %d action bar buttons to the highest spell rank."], upgraded)
    end
end

local function PlaceNewSpell(spellID)
    if C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID) then
        return
    end
    local buttons = C_ActionBar.FindSpellActionButtons(spellID)
    if buttons and #buttons > 0 then
        return -- 已在动作条上（可能是游戏自己放的）
    end
    -- 同名低等级已在动作条上时交给等级提升处理
    local name = C_Spell.GetSpellName(spellID)
    for slot = 1, MAX_SLOTS do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id and C_Spell.GetSpellName(id) == name then
            return
        end
    end
    for slot = MAIN_BAR[1], MAIN_BAR[2] do
        if not HasAction(slot) then
            PlaceSpell(spellID, slot)
            ns:Print(L["Placed %s on your action bar."], name or "?")
            return
        end
    end
end

local function Process()
    if InCombatLockdown() then
        return -- PLAYER_REGEN_ENABLED 时再来
    end
    local settings = Settings()
    if pendingUpgrade and settings.upgradeRanks then
        ns.InvalidateKnownSpells()
        UpgradeRanks()
    end
    pendingUpgrade = false
    if settings.placeNewSpells then
        for spellID in pairs(pendingNew) do
            PlaceNewSpell(spellID)
        end
    end
    wipe(pendingNew)
end

local function Schedule()
    -- 学技能时会连续触发多次事件，合并到 1 秒后统一处理
    if not Module.scheduled then
        Module.scheduled = true
        C_Timer.After(1, function()
            Module.scheduled = false
            Process()
        end)
    end
end

local function OnLearned(_, spellID)
    pendingUpgrade = true
    if spellID then
        pendingNew[spellID] = true
    end
    Schedule()
end

function Module:OnEnable()
    ns:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE", OnLearned)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if pendingUpgrade or next(pendingNew) then
            Process()
        end
    end)
    -- 登录时也检查一次：离线期间在训练师学的高等级技能
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        pendingUpgrade = true
        C_Timer.After(3, Process)
    end)
end
