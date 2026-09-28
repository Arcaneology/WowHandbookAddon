local ADDON_NAME, ns = ...
local L = ns.L

-- 动作条（F5）：只在学会技能时，处理这次新学的技能所属的那一系（同名技能）：
-- · 等级提升：动作条上这一系的低等级技能换成已学的最高等级；玩家没学新等级的技能不会被动。
-- · 新技能：这一系还不在任何动作条上、且是主动技能时，放进主动作条第一个空位。
-- 同一批学会的多个等级按技能系合并，结果与事件顺序无关。登录、换地图时不扫描动作条；
-- 想把整条动作条一次升级到最高等级，在设置页手动执行，并可撤销最近一次改动。
-- 战斗中动作条不能改动，排队等脱战后执行；光标上正拿着东西时先不动，等放下再做。
-- 只处理技能，不动宏、物品和其他按钮。
local Module = ns:NewModule("ActionBars", { upgradeRanks = true, placeNewSpells = true })

local MAX_SLOTS = 120
local MAIN_BAR = { 1, 12 }  -- 主动作条第一页
local CURSOR_RETRY = 1
local pendingLearned = {}   -- [spellID] = true：这一批学会的技能
local lastChanges = {}      -- 最近一次改动：{ slot, before = 原技能 ID 或 nil, after = 新技能 ID }
Module.lastChanges = lastChanges -- 供测试使用

local function Settings()
    return ns:GetModuleSettings(Module)
end

local function CursorBusy()
    return GetCursorInfo and GetCursorInfo() ~= nil
end

local function SpellInSlot(slot)
    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" and id then
        return id
    end
    return nil
end

local function FamilyKey(spellID)
    local name = C_Spell.GetSpellName(spellID)
    return name and name:lower()
end

-- 调用前已确认光标是空的：放置后光标上是被换下来的旧按钮，清掉即可，不会丢掉玩家拿着的东西。
-- 放完核对槽位，失败时返回 false，不报告成功。
local function PlaceSpell(spellID, slot)
    C_Spell.PickupSpell(spellID)
    PlaceAction(slot)
    ClearCursor()
    return SpellInSlot(slot) == spellID
end

local function Record(changes, slot, before, after)
    tinsert(changes, { slot = slot, before = before, after = after })
end

-- 把动作条上 family（nil 表示全部技能系）里低于已学最高等级的技能换成最高等级
local function UpgradeSlots(families, changes)
    local known = ns.KnownSpells()
    local upgraded = 0
    for slot = 1, MAX_SLOTS do
        local id = SpellInSlot(slot)
        local key = id and FamilyKey(id)
        local entry = key and (not families or families[key]) and known[key]
        if entry and entry.best > 0 then
            local current = ns.RankNumber(C_Spell.GetSpellSubtext(id))
            local best = entry.ids[entry.best]
            if current > 0 and current < entry.best and best and best ~= id and PlaceSpell(best, slot) then
                Record(changes, slot, id, best)
                upgraded = upgraded + 1
            end
        end
    end
    return upgraded
end

local function OnBars(key)
    for slot = 1, MAX_SLOTS do
        local id = SpellInSlot(slot)
        if id and FamilyKey(id) == key then
            return true
        end
    end
    return false
end

local function PlaceNewSpell(key, spellID, changes)
    if C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID) then
        return
    end
    if OnBars(key) then
        return -- 已在动作条上（可能是游戏自己放的，或上面刚升级过）
    end
    for slot = MAIN_BAR[1], MAIN_BAR[2] do
        if not HasAction(slot) then
            if PlaceSpell(spellID, slot) then
                Record(changes, slot, nil, spellID)
                ns:Print(L["Placed %s on your action bar."], C_Spell.GetSpellName(spellID) or "?")
            end
            return
        end
    end
end

-- 按技能系合并这一批学会的技能：{ [技能名小写] = 这一批里等级最高的 spellID }
local function Families(learned)
    local families = {}
    for spellID in pairs(learned) do
        local key = FamilyKey(spellID)
        if key then
            local current = families[key]
            if not current or ns.RankNumber(C_Spell.GetSpellSubtext(spellID))
                > ns.RankNumber(C_Spell.GetSpellSubtext(current)) then
                families[key] = spellID
            end
        end
    end
    return families
end

local function SaveChanges(changes)
    if #changes > 0 then
        wipe(lastChanges)
        for _, change in ipairs(changes) do
            tinsert(lastChanges, change)
        end
    end
end

local Schedule

local function Process()
    if not next(pendingLearned) then
        return
    end
    if InCombatLockdown() then
        return -- PLAYER_REGEN_ENABLED 时再来
    end
    if CursorBusy() then
        Schedule(CURSOR_RETRY)
        return
    end
    ns.InvalidateKnownSpells()
    local settings = Settings()
    local families = Families(pendingLearned)
    wipe(pendingLearned)
    local changes = {}
    if settings.upgradeRanks then
        local upgraded = UpgradeSlots(families, changes)
        if upgraded > 0 then
            ns:Print(L["Upgraded %d action bar buttons to the highest spell rank."], upgraded)
        end
    end
    if settings.placeNewSpells then
        local known = ns.KnownSpells()
        for key, spellID in pairs(families) do
            -- 开着等级提升时放已学的最高等级；关着时只放这一批学会的那个等级
            local entry = settings.upgradeRanks and known[key]
            local best = entry and entry.best > 0 and entry.ids[entry.best]
            PlaceNewSpell(key, best or spellID, changes)
        end
    end
    SaveChanges(changes)
end

function Schedule(delay)
    -- 学技能时会连续触发多次事件，合并到 1 秒后统一处理
    if not Module.scheduled then
        Module.scheduled = true
        C_Timer.After(delay or 1, function()
            Module.scheduled = false
            if Module.enabled then
                Process()
            end
        end)
    end
end

local function OnLearned(_, spellID)
    if spellID then
        pendingLearned[spellID] = true
        Schedule()
    end
end

-- 设置页：把整条动作条一次升级到最高等级。返回是否执行
function Module:UpgradeAll()
    if InCombatLockdown() then
        ns:Print(L["Action bars cannot be changed in combat. Try again after combat."])
        return false
    end
    if CursorBusy() then
        ns:Print(L["Put down what you are holding on the cursor first."])
        return false
    end
    ns.InvalidateKnownSpells()
    local changes = {}
    local upgraded = UpgradeSlots(nil, changes)
    SaveChanges(changes)
    if upgraded > 0 then
        ns:Print(L["Upgraded %d action bar buttons to the highest spell rank."], upgraded)
    else
        ns:Print(L["Every spell on your action bars is already at its highest rank."])
    end
    return true
end

-- 设置页：撤销最近一次改动。只还原仍是插件放上去的那个技能的按钮，玩家之后自己改过的不动
function Module:Undo()
    if #lastChanges == 0 then
        ns:Print(L["No action bar changes to undo."])
        return false
    end
    if InCombatLockdown() then
        ns:Print(L["Action bars cannot be changed in combat. Try again after combat."])
        return false
    end
    if CursorBusy() then
        ns:Print(L["Put down what you are holding on the cursor first."])
        return false
    end
    local restored = 0
    for index = #lastChanges, 1, -1 do
        local change = lastChanges[index]
        if SpellInSlot(change.slot) == change.after then
            if change.before then
                if PlaceSpell(change.before, change.slot) then
                    restored = restored + 1
                end
            else
                PickupAction(change.slot)
                ClearCursor()
                if not HasAction(change.slot) then
                    restored = restored + 1
                end
            end
        end
    end
    wipe(lastChanges)
    ns:Print(L["Restored %d action bar buttons."], restored)
    return true
end

function Module:OnEnable()
    ns:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE", OnLearned)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", Process)
end
