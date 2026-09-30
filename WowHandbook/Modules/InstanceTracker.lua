local ADDON_NAME, ns = ...
local L = ns.L

-- 副本进度小窗：进入副本时显示本副本的首领击杀状态与相关任务状态。
-- · 首领击杀：首领战结束（ENCOUNTER_END，带本场全部首领的 creatureID 与名字）按 NPC ID 或名字对应首领，
--   另听 BOSS_KILL，团队副本再读客户端的副本锁定记录。不订阅战斗记录：这个客户端把它列为受限事件，
--   插件订阅会被拦截并弹出“只有暴雪界面才能执行的操作”提示。没有首领战的稀有精英不会自动标记。
-- · 一次副本进度：生物 GUID 里带副本实例编号，遇到新的编号就是新进度，清空击杀记录；
--   死亡跑尸、下线重上回到同一个实例时记录保留（存角色存档）。
-- · 同一副本 ID 的多个分区（血色修道院各区等）：看到哪个分区的首领死亡就切到哪个区，也可在小窗里手动切换。
-- · 任务：本副本任务里已接的（进度、可交）与副本内可接的逐条列出，其余只给数量。
-- 只在副本里订阅这些事件；离开副本时注销并隐藏小窗。关闭按钮只隐藏到下次进入副本。
-- 布局尽量紧凑：一行标题（副本名 + 首领进度，悬停看等级与操作说明）加一条细进度条；已击杀的首领合并成一行
-- （悬停看是哪几个），只展开还没打的；任务标题行右侧给出已完成与副本外待接的数量。
-- /wh test：测试模式，用一套固定的虚构副本（首领、击杀进度、各种状态的任务）打开小窗，看版式用。
-- 客户端对单位身份有“秘密值”限制：选中目标的 GUID 是秘密值时拿不到实例编号，
-- 这时距上次击杀超过 RUN_EXPIRES 秒的记录视为旧进度清空。
local Module = ns:NewModule("InstanceTracker", { autoShow = true, collapsed = false })

local WIDTH = 240
local RUN_EXPIRES = 4 * 3600
local MAX_CONTENT_HEIGHT = 260
local UI
local frame
local current -- { instanceID, sections = { 副本序号… }, section = 当前分区在 sections 里的序号 }
local dismissed -- 玩家在这个副本实例里点了关闭
local test -- 测试模式的虚构数据（/wh test），非 nil 时小窗只显示它
local instanceEventsRegistered = false

local GREEN, GOLD, MUTED, TEXT = "|cff46bf72", "|cffe0b458", "|cff8a8374", "|cfff4e8cc"

local function Settings()
    return ns:GetModuleSettings(Module)
end

--------------------------------------------------------------------------------
-- 副本与首领
--------------------------------------------------------------------------------

-- 副本里返回副本 ID；不在副本（或在战场、竞技场）返回 nil
local function CurrentInstanceID()
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceType ~= "party" and instanceType ~= "raid" then
        return nil
    end
    return instanceID
end

local function SectionsFor(instanceID)
    local sections = {}
    for index, dungeon in ipairs(ns.Data.dungeons or {}) do
        if dungeon.instanceID == instanceID and not dungeon.aggregateOnly then
            tinsert(sections, index)
        end
    end
    return sections
end

local function Bosses(dungeon)
    local bosses = {}
    for _, boss in ipairs(dungeon.bosses or {}) do
        if not ns.IsLootGroup(boss) then
            tinsert(bosses, boss)
        end
    end
    return bosses
end

local function BossKey(boss)
    if boss.npcID then
        return "npc:" .. boss.npcID
    end
    return "name:" .. (ns.NormalizedName(boss.name and boss.name.enUS) or "?")
end

local function NameMatches(boss, name)
    local key = ns.NormalizedName(name)
    if not key then
        return false
    end
    for _, candidate in pairs(boss.name or {}) do
        if ns.NormalizedName(candidate) == key then
            return true
        end
    end
    return ns.NormalizedName(ns.BossName(boss)) == key
end

-- 在当前副本的各分区里找首领：先按 NPC ID，再按名字。返回分区在 sections 里的序号与首领键
local function MatchBoss(npcID, name)
    if not current then
        return nil
    end
    if ns.IsSecret(name) then
        name = nil
    end
    for pass = 1, 2 do
        for position, index in ipairs(current.sections) do
            for _, boss in ipairs(Bosses(ns.Data.dungeons[index])) do
                if (pass == 1 and npcID and boss.npcID == npcID) or (pass == 2 and name and NameMatches(boss, name)) then
                    return position, BossKey(boss)
                end
            end
        end
    end
    return nil
end

-- 本角色在这个副本的进度：{ zoneUID = 副本实例编号, killed = { [首领键] = true }, section = 分区序号 }
local function Run()
    ns.charDB.instanceRuns = ns.charDB.instanceRuns or {}
    local runs = ns.charDB.instanceRuns
    local run = runs[current.instanceID]
    if not run then
        run = { killed = {} }
        runs[current.instanceID] = run
    end
    return run
end

-- "Creature-0-服务器-副本-实例编号-NPC ID-生成编号" -> 实例编号, NPC ID
local function ParseCreatureGUID(guid)
    if type(guid) ~= "string" or ns.IsSecret(guid) then
        return nil
    end
    local kind, _, _, _, zoneUID, npcID = strsplit("-", guid)
    if kind ~= "Creature" and kind ~= "Vehicle" then
        return nil
    end
    return zoneUID, tonumber(npcID)
end
Module.ParseCreatureGUID = ParseCreatureGUID -- 供测试使用

-- 看到的生物属于另一个副本实例时，说明是新的一次进度：清空击杀记录
local function CheckRun(zoneUID)
    if not (current and zoneUID) then
        return
    end
    local run = Run()
    if run.zoneUID ~= zoneUID then
        if run.zoneUID then
            wipe(run.killed)
        end
        run.zoneUID = zoneUID
    end
end

local Refresh
local ExitTest

local function MarkKilled(position, key)
    local run = Run()
    if run.killed[key] then
        return
    end
    run.killed[key] = true
    run.time = time()
    if #current.sections > 1 then
        run.section = position
    end
    Refresh()
end

-- 首领战结束：本场每个首领按 creatureID（再按名字）对应，没有首领列表时按首领战名字对应
local function OnEncounterEnd(_, _, encounterName, _, _, success, units)
    if not (success == 1 or success == true) then
        return
    end
    local matched = false
    for _, unit in ipairs(type(units) == "table" and units or {}) do
        local npcID = not ns.IsSecret(unit.creatureID) and unit.creatureID or nil
        local position, key = MatchBoss(npcID, unit.creatureName)
        if position then
            matched = true
            MarkKilled(position, key)
        end
    end
    if not matched then
        local position, key = MatchBoss(nil, encounterName)
        if position then
            MarkKilled(position, key)
        end
    end
end
Module.OnEncounterEnd = OnEncounterEnd -- 供测试使用

local function OnBossKill(_, _, encounterName)
    local position, key = MatchBoss(nil, encounterName)
    if position then
        MarkKilled(position, key)
    end
end

local function OnTargetChanged()
    CheckRun((ParseCreatureGUID(UnitGUID("target"))))
end

-- 团队副本：客户端的副本锁定记录里已击杀的首领
local function ApplyLockout()
    if not (current and GetNumSavedInstances and GetSavedInstanceInfo and GetSavedInstanceEncounterInfo) then
        return
    end
    for index = 1, GetNumSavedInstances() do
        local info = { GetSavedInstanceInfo(index) }
        local locked, numEncounters, instanceID = info[5], info[11], info[14]
        if locked and instanceID == current.instanceID then
            for encounter = 1, numEncounters or 0 do
                local bossName, _, isKilled = GetSavedInstanceEncounterInfo(index, encounter)
                if isKilled then
                    local position, key = MatchBoss(nil, bossName)
                    if position then
                        Run().killed[key] = true
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 任务
--------------------------------------------------------------------------------

-- 返回 { 已接或副本内可接的任务 }, 已完成数, 需在副本外接的数量
local function QuestRows(dungeon)
    local rows, done, outside = {}, 0, 0
    local faction = ns.PlayerFaction()
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = ns.Data.quests[questID]
        if quest and (not quest.classRestriction or quest.classRestriction:lower() == ns.PlayerClass())
            and not (quest.faction and faction and quest.faction ~= faction) then
            local status = ns.QuestStatus(questID)
            if status == "active" then
                local complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID)
                tinsert(rows, { id = questID, kind = complete and "complete" or "active" })
            elseif status == "done" and not quest.relatedExternal then
                done = done + 1
            elseif status == "available" and quest.inside and not quest.relatedExternal then
                tinsert(rows, { id = questID, kind = "inside" })
            elseif not quest.extra and not quest.relatedExternal then
                outside = outside + 1
            end
        end
    end
    local order = { complete = 1, active = 2, inside = 3 }
    table.sort(rows, function(a, b)
        if a.kind ~= b.kind then
            return order[a.kind] < order[b.kind]
        end
        return a.id < b.id
    end)
    return rows, done, outside
end
Module.QuestRows = QuestRows -- 供测试使用

local function Objectives(questID)
    if test then
        return test.objectives[questID] or {}
    end
    local list = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)
    return list or {}
end

-- 任务标题：测试模式用虚构标题
local function QuestName(questID)
    if test then
        return test.titles[questID] or "?"
    end
    return ns.QuestTitle(questID)
end

--------------------------------------------------------------------------------
-- 测试模式：固定的虚构副本，每次打开都一样。名字全是虚构的，不对应游戏里的任何副本或首领
--------------------------------------------------------------------------------

local function TestTemplate()
    local function Boss(id, name, level)
        return { npcID = id, level = level, name = { enUS = name } }
    end
    local bosses = {
        Boss(-1, L["Gravekeeper Thane"], 26),
        Boss(-2, L["The Rotting Hound"], 27),
        Boss(-3, L["Mistress Venn"], 28),
        Boss(-4, L["Bonecaller Oryx"], 29),
        Boss(-5, L["Archivist Malgorn"], 30),
    }
    return {
        dungeon = { name = { enUS = L["Test Crypt"] }, kind = "dungeon", levels = { 24, 32 }, bosses = bosses },
        killed = { ["npc:-1"] = true, ["npc:-2"] = true },
        quests = { { id = -1, kind = "complete" }, { id = -2, kind = "active" }, { id = -3, kind = "inside" } },
        done = 1,
        outside = 2,
        titles = { [-1] = L["Relics of the Crypt"], [-2] = L["Silence the Bonecaller"], [-3] = L["A Plea from the Dark"] },
        objectives = {
            [-1] = { { text = L["Crypt relic: 6/6"], numFulfilled = 6, numRequired = 6, finished = true } },
            [-2] = { { text = L["Crypt shard: 3/8"], numFulfilled = 3, numRequired = 8, finished = false },
                { text = L["Bonecaller Oryx slain: 0/1"], numFulfilled = 0, numRequired = 1, finished = false } },
        },
    }
end
Module.TestTemplate = TestTemplate -- 供测试使用

--------------------------------------------------------------------------------
-- 小窗
--------------------------------------------------------------------------------

local function CurrentDungeon()
    if not current or #current.sections == 0 then
        return nil
    end
    local position = Run().section
    if not (position and current.sections[position]) then
        position = 1
    end
    return ns.Data.dungeons[current.sections[position]], position
end

local function DungeonIndex()
    local _, position = CurrentDungeon()
    return position and current.sections[position]
end

local function SavePosition()
    local point, _, relativePoint, x, y = frame:GetPoint()
    Settings().position = { point, relativePoint, x, y }
end

local function RestorePosition()
    local position = Settings().position
    frame:ClearAllPoints()
    if position then
        frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -220)
    end
end

local function SetColor(texture, name)
    texture:SetColorTexture(unpack(ns.Theme.colors[name]))
end

--------------------------------------------------------------------------------
-- 鼠标提示：首领掉落、任务目标与奖励
--------------------------------------------------------------------------------

local MAX_TOOLTIP_ITEMS = 14
local hoveredRow

-- 物品一行：图标 + 品质色名字；客户端还没有数据时请求并显示占位
local function ItemLine(itemID)
    local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
    if not name then
        ns.RequestItem(itemID)
        return MUTED .. L["Item information not yet unlocked"] .. "|r"
    end
    local color = "ffffffff"
    if quality and C_Item.GetItemQualityColor then
        color = select(4, C_Item.GetItemQualityColor(quality)) or color
    end
    return ("|T%s:14:14:0:0|t |c%s%s|r"):format(tostring(icon or 134400), color, name)
end

local function Usable(itemID)
    local _, classFile = UnitClass("player")
    return ns.ItemFilter.Matches(itemID, { class = classFile, category = "all", armor = "all" })
end

local function BossTooltip(row)
    local boss = row.boss
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText(ns.BossName(boss) or "?", 1, 0.82, 0)
    if boss.level then
        GameTooltip:AddLine((L["Level %s"]):format(tostring(boss.level)), 0.85, 0.8, 0.69)
    end
    GameTooltip:AddLine(row.killed and L["Killed"] or L["Not killed yet"], row.killed and 0.27 or 0.54,
        row.killed and 0.75 or 0.51, row.killed and 0.45 or 0.45)
    -- 本职业能用的排在前面
    local usable, others = {}, {}
    for _, entry in ipairs(boss.items or {}) do
        local itemID = type(entry) == "table" and entry.id or entry
        tinsert(Usable(itemID) and usable or others, entry)
    end
    local total = #usable + #others
    if total > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine((L["Loot (%d)"]):format(total), 0.88, 0.71, 0.35)
        local shown = 0
        for _, list in ipairs({ usable, others }) do
            for _, entry in ipairs(list) do
                if shown < MAX_TOOLTIP_ITEMS then
                    shown = shown + 1
                    local itemID = type(entry) == "table" and entry.id or entry
                    local rate = type(entry) == "table" and entry.rate
                    GameTooltip:AddDoubleLine(ItemLine(itemID), rate and ("%s%%"):format(tostring(rate)) or "",
                        1, 1, 1, 0.54, 0.51, 0.45)
                end
            end
        end
        if total > shown then
            GameTooltip:AddLine((L["and %d more"]):format(total - shown), 0.54, 0.51, 0.45)
        end
    else
        GameTooltip:AddLine(L["No loot data yet."], 0.54, 0.51, 0.45)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Click to see the full loot list in WoW Handbook."], 0.54, 0.51, 0.45)
    GameTooltip:Show()
end

local function RewardItems(rewards)
    local lines = {}
    for _, key in ipairs({ "items", "choices", "extraItems" }) do
        for _, item in ipairs(rewards and rewards[key] or {}) do
            tinsert(lines, ItemLine(item.id))
        end
    end
    return lines
end

local function QuestTooltip(row)
    local questID = row.questID
    local quest = ns.Data.quests[questID] or {}
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText(QuestName(questID), 1, 0.82, 0)
    local level = quest.min or quest.level
    if level then
        GameTooltip:AddLine((L["Available from level %d"]):format(level), 0.85, 0.8, 0.69)
    end
    if row.kind == "inside" then
        GameTooltip:AddLine(L["Picked up inside the dungeon"], 0.88, 0.71, 0.35)
    end
    for _, objective in ipairs(Objectives(questID)) do
        if objective.text and objective.text ~= "" then
            if objective.finished then
                GameTooltip:AddLine(objective.text, 0.27, 0.75, 0.45, true)
            else
                GameTooltip:AddLine(objective.text, 1, 1, 1, true)
            end
        end
    end
    local rewards = quest.rewards
    local money = rewards and ns.Money(rewards.money)
    local items = RewardItems(rewards)
    if (rewards and rewards.xp) or money or #items > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Rewards"], 0.88, 0.71, 0.35)
        if rewards.xp then
            GameTooltip:AddLine((L["%d XP"]):format(rewards.xp), 1, 1, 1)
        end
        if money then
            GameTooltip:AddLine(money, 1, 1, 1)
        end
        for _, line in ipairs(items) do
            GameTooltip:AddLine(line, 1, 1, 1)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Click to see the quest in WoW Handbook."], 0.54, 0.51, 0.45)
    GameTooltip:Show()
end

-- 物品数据到了，正在看的提示重新生成
ns.OnItemLoaded(function()
    if hoveredRow and hoveredRow:IsVisible() and hoveredRow.ShowTooltip then
        hoveredRow:ShowTooltip()
    end
end)

-- 点击：打开手册里的这个副本（首领看掉落页，任务看任务页并选中）
local function OpenInHandbook(row)
    if test then
        return -- 测试模式的虚构副本在手册里没有
    end
    local module = ns.modules.Dungeons
    local index = DungeonIndex()
    if not (module and index) or ns:GetModuleSettings(module).enabled == false then
        ns:Print(L["%s is turned off in Settings."], L["Dungeon guide"])
        return
    end
    if row.questID then
        module.questState.selected, module.questState.selectedRow = row.questID, row.questID
        module:Select(index, "quests")
    else
        module:Select(index, "loot")
    end
end
Module.OpenInHandbook = OpenInHandbook -- 供测试使用

--------------------------------------------------------------------------------
-- 卡片
--------------------------------------------------------------------------------

local ROW_HEIGHT = 16
local PAD = 10
local HEADER = 34 -- 标题行 + 进度条
local READY_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"

-- 列表行：左侧状态标记，中间名字，右侧状态文字；悬停显示提示，点击打开手册
local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.hover = row:CreateTexture(nil, "BACKGROUND")
    row.hover:SetAllPoints()
    SetColor(row.hover, "glassHover")
    row.hover:Hide()
    row.check = row:CreateTexture(nil, "ARTWORK")
    row.check:SetSize(12, 12)
    row.check:SetPoint("LEFT", 2, 0)
    row.check:SetTexture(READY_ICON)
    row.dot = row:CreateTexture(nil, "ARTWORK")
    row.dot:SetSize(5, 5)
    row.dot:SetPoint("CENTER", row.check, "CENTER")
    row.name = UI:Text(row, "Small")
    row.name:SetPoint("LEFT", 18, 0)
    row.name:SetWordWrap(false)
    row.tag = UI:Text(row, "Small")
    row.tag:SetPoint("RIGHT", -4, 0)
    row.tag:SetJustifyH("RIGHT")
    row.name:SetPoint("RIGHT", row.tag, "LEFT", -6, 0)
    row:SetScript("OnEnter", function(self)
        hoveredRow = self
        self.hover:Show()
        self:ShowTooltip()
    end)
    row:SetScript("OnLeave", function(self)
        hoveredRow = nil
        self.hover:Hide()
        GameTooltip_Hide()
    end)
    row:SetScript("OnClick", OpenInHandbook)
    function row:ShowTooltip()
        if self.questID then
            QuestTooltip(self)
        elseif self.killedList then
            -- 合并起来的“已击杀”一行：列出是哪几个
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(L["Killed"], 0.27, 0.75, 0.45)
            for _, boss in ipairs(self.killedList) do
                GameTooltip:AddLine(ns.BossName(boss) or "?", 1, 1, 1)
            end
            GameTooltip:Show()
        else
            BossTooltip(self)
        end
    end
    return row
end

-- 状态标记：done 绿色勾，next 金色方块，其余灰色方块
local function SetMarker(row, state)
    row.check:SetShown(state == "done")
    row.dot:SetShown(state ~= "done")
    if state ~= "done" then
        SetColor(row.dot, state == "next" and "gold" or (state == "active" and "blue" or "muted"))
        row.dot:SetSize(state == "next" and 7 or 5, state == "next" and 7 or 5)
    end
end

local function Create()
    UI = ns.UI
    local f = CreateFrame("Frame", "WowHandbookInstanceFrame", UIParent, "BackdropTemplate")
    ns.Theme:Skin(f, "glass", "glassLine")
    f:SetWidth(WIDTH)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    -- 顶部金色细线，与主窗口一致
    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetHeight(2)
    SetColor(accent, "gold")

    -- 标题行：副本名（悬停看等级、类型与操作说明）…… 首领进度 3/7，收起、关闭
    f.close = UI:CloseButton(f, function()
        if test then
            ExitTest()
            return
        end
        dismissed = current and current.instanceID
        f:Hide()
    end, 18)
    f.close:SetPoint("TOPRIGHT", -3, -5)
    f.collapse = UI:Button(f, "-", 16, 16, "ghost")
    f.collapse:SetPoint("RIGHT", f.close, "LEFT", -1, 0)
    f.progressCount = UI:Text(f, "Small")
    f.progressCount:SetPoint("RIGHT", f.collapse, "LEFT", -6, 0)
    f.progressCount:SetJustifyH("RIGHT")
    f.title = UI:Text(f, "Heading")
    f.title:SetPoint("TOPLEFT", PAD, -10)
    f.title:SetPoint("RIGHT", f.progressCount, "LEFT", -6, 0)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    f.titleHover = CreateFrame("Frame", nil, f)
    f.titleHover:SetPoint("TOPLEFT", f.title, "TOPLEFT", 0, 2)
    f.titleHover:SetPoint("BOTTOMRIGHT", f.title, "BOTTOMRIGHT", 0, -2)
    f.titleHover:EnableMouse(true)
    f.titleHover:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(f.title:GetText() or "", 1, 0.82, 0)
        if f.info then
            GameTooltip:AddLine(f.info, 1, 1, 1)
        end
        GameTooltip:AddLine(L["Hover: details · Click: open handbook"], 0.54, 0.51, 0.45)
        GameTooltip:Show()
    end)
    f.titleHover:SetScript("OnLeave", GameTooltip_Hide)
    -- 标题拖不动的话整个小窗就拖不动：把拖动转给小窗
    f.titleHover:RegisterForDrag("LeftButton")
    f.titleHover:SetScript("OnDragStart", function() f:StartMoving() end)
    f.titleHover:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SavePosition()
    end)
    f.collapse:SetScript("OnClick", function()
        Settings().collapsed = not Settings().collapsed
        Refresh()
    end)

    -- 同一副本 ID 有多个分区时：手动切换分区
    f.section = UI:Dropdown(f, {}, function(position)
        Run().section = position
        Refresh()
    end, WIDTH - PAD * 2)
    f.section:SetHeight(20)

    -- 首领进度条：标题下一条细线，首领不多时每个首领一段
    f.segments = {}
    f.track = f:CreateTexture(nil, "ARTWORK")
    SetColor(f.track, "track")
    f.fill = f:CreateTexture(nil, "OVERLAY")
    SetColor(f.fill, "green")

    -- 收起时在进度条下方只显示下一个要打的首领
    f.nextRow = CreateRow(f)
    f.nextRow:Hide()

    f.scroll = UI:ScrollArea(f)
    f.stack = UI:Stack(f.scroll.child)
    f.rows = {}
    f.divider = f.scroll.child:CreateTexture(nil, "ARTWORK")
    SetColor(f.divider, "lineSoft")
    f.divider:SetHeight(1)
    f:Hide()
    return f
end

-- 进度条：首领不多时每个首领一段，太多时画成一整条
local MAX_SEGMENTS = 20
local function DrawProgress(top, killed, total)
    local width = WIDTH - PAD * 2
    local segmented = total > 0 and total <= MAX_SEGMENTS
    for _, segment in ipairs(frame.segments) do
        segment:Hide()
    end
    frame.track:SetShown(not segmented)
    frame.fill:SetShown(not segmented and killed > 0)
    if segmented then
        local gap = 2
        local segmentWidth = (width - gap * (total - 1)) / total
        for i = 1, total do
            local segment = frame.segments[i]
            if not segment then
                segment = frame:CreateTexture(nil, "ARTWORK")
                segment:SetHeight(3)
                frame.segments[i] = segment
            end
            segment:ClearAllPoints()
            segment:SetPoint("TOPLEFT", PAD + (i - 1) * (segmentWidth + gap), -top)
            segment:SetWidth(segmentWidth)
            SetColor(segment, i <= killed and "green" or "track")
            segment:Show()
        end
    else
        frame.track:ClearAllPoints()
        frame.track:SetPoint("TOPLEFT", PAD, -top)
        frame.track:SetSize(width, 3)
        frame.fill:ClearAllPoints()
        frame.fill:SetPoint("TOPLEFT", PAD, -top)
        frame.fill:SetSize(math.max(1, width * (total > 0 and killed / total or 0)), 3)
    end
end

-- 一个任务目标的数量进度（物品、击杀等）：优先用接口给的数量，没有就从目标文字末尾的 "3/8" 取
local function ObjectiveCount(objective)
    local have, need = objective.numFulfilled, objective.numRequired
    if not (have and need and need > 0) then
        have, need = tostring(objective.text or ""):match("(%d+)%s*/%s*(%d+)%s*$")
        have, need = tonumber(have), tonumber(need)
    end
    if not (have and need and need > 0) then
        have, need = objective.finished and 1 or 0, 1
    end
    return math.min(have, need), need
end

-- 任务状态符号：用游戏里 NPC 头顶的任务标记，玩家一眼能懂，比文字省地方。
-- 黄 ? 可交，灰 ? 进行中，黄 ! 副本内可接，灰 ! 副本外待接，绿勾 已完成（整个任务或单个目标）
local QUEST_ICON = {
    turnIn = "|TInterface\\GossipFrame\\ActiveQuestIcon:12:12|t",
    active = "|TInterface\\GossipFrame\\ActiveQuestIcon:12:12:0:0:16:16:0:16:0:16:140:131:116|t",
    inside = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12|t",
    outside = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12:0:0:16:16:0:16:0:16:140:131:116|t",
    done = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t",
}
Module.QUEST_ICON = QUEST_ICON -- 供测试使用

-- 任务行右侧：可交 / 副本内可接只放符号；进行中列出每个目标的数量（如 3/8  0/1），已完成的目标换成绿勾
local function QuestTag(row)
    if row.kind == "complete" then
        return QUEST_ICON.turnIn
    elseif row.kind == "inside" then
        return QUEST_ICON.inside
    end
    local parts = {}
    for _, objective in ipairs(Objectives(row.id)) do
        local have, need = ObjectiveCount(objective)
        if objective.finished or have >= need then
            tinsert(parts, QUEST_ICON.done)
        else
            tinsert(parts, ("|cff6f95d6%d/%d|r"):format(have, need))
        end
    end
    return #parts > 0 and table.concat(parts, " ") or QUEST_ICON.active
end

-- 任务标题行悬停：说明各个符号
local function QuestLegend(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(L["Quests"], 1, 0.82, 0)
    GameTooltip:AddLine(QUEST_ICON.turnIn .. " " .. L["Ready to turn in"], 1, 1, 1)
    GameTooltip:AddLine(QUEST_ICON.active .. " " .. L["In progress"], 1, 1, 1)
    GameTooltip:AddLine(QUEST_ICON.inside .. " " .. L["Picked up inside the dungeon"], 1, 1, 1)
    GameTooltip:AddLine(QUEST_ICON.outside .. " " .. L["To pick up outside the dungeon"], 1, 1, 1)
    GameTooltip:AddLine(QUEST_ICON.done .. " " .. L["Completed"], 1, 1, 1)
    GameTooltip:Show()
end

-- 小窗要显示的数据：真实副本或测试模板。返回 dungeon, 分区序号, 首领列表, 已击杀表, 任务行, 已完成数, 副本外待接数
local function ViewData()
    if test then
        return test.dungeon, nil, test.dungeon.bosses, test.killed, test.quests, test.done, test.outside
    end
    local dungeon, position = CurrentDungeon()
    if not dungeon then
        return nil
    end
    local rows, done, outside = QuestRows(dungeon)
    return dungeon, position, Bosses(dungeon), Run().killed, rows, done, outside
end

function Refresh()
    if not (frame and frame:IsShown() and (current or test)) then
        return
    end
    local dungeon, position, bosses, killedSet, questRows, done, outside = ViewData()
    if not dungeon then
        return
    end
    local killedList, remaining = {}, {}
    for _, boss in ipairs(bosses) do
        tinsert(killedSet[BossKey(boss)] and killedList or remaining, boss)
    end
    local killed = #killedList

    -- 标题行：副本名；进度 3/7（打完变绿）；等级与类型放进标题的悬停提示
    frame.title:SetText(ns.Name(dungeon.name) or "?")
    local levels = dungeon.levels
    frame.info = table.concat({
        levels and ("|c%s%s %s|r"):format(ns.LevelColor(levels[1], levels[2]), L["Level"], ns.LevelRange(levels)) or nil,
        dungeon.kind == "raid" and L["Raid"] or L["Dungeon"],
    }, "  ·  ")
    frame.progressCount:SetText(("%s%d|r%s/%d|r"):format(killed == #bosses and #bosses > 0 and GREEN or TEXT,
        killed, MUTED, #bosses))
    frame.progress = frame.progressCount -- 供测试使用
    DrawProgress(28, killed, #bosses)

    local collapsed = Settings().collapsed
    frame.collapse:SetLabel(collapsed and "+" or "-")
    local top = HEADER
    if not test and #current.sections > 1 and not collapsed then
        local items = {}
        for i, index in ipairs(current.sections) do
            tinsert(items, { id = i, label = ns.Name(ns.Data.dungeons[index].name) })
        end
        frame.section:ClearAllPoints()
        frame.section:SetPoint("TOPLEFT", PAD, -top)
        frame.section:SetItems(items)
        frame.section:SetValue(position)
        frame.section:Show()
        top = top + 24
    else
        frame.section:Hide()
    end

    frame.nextRow:Hide()
    if collapsed then
        -- 收起：进度条下只留下一个要打的首领
        frame.scroll:Hide()
        frame.scroll.bar:Hide()
        local boss = remaining[1]
        if boss then
            local row = frame.nextRow
            row.boss, row.questID, row.kind, row.killed, row.killedList = boss, nil, nil, false, nil
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", PAD - 4, -top)
            row:SetPoint("RIGHT", -PAD, 0)
            SetMarker(row, "next")
            row.name:SetText(TEXT .. (ns.BossName(boss) or "?") .. "|r")
            row.tag:SetText(GOLD .. L["Next"] .. "|r")
            row:Show()
            top = top + ROW_HEIGHT
        end
        frame:SetHeight(top + 6)
        return
    end
    frame.scroll:Show()
    frame.scroll:ClearAllPoints()
    frame.scroll:SetPoint("TOPLEFT", PAD - 4, -top)
    frame.scroll:SetPoint("BOTTOMRIGHT", -PAD, 6)

    local stack, rows = frame.stack, frame.rows
    stack:Reset()
    for _, row in ipairs(rows) do
        row:Hide()
    end
    local used, y = 0, 0
    local width = WIDTH - PAD * 2 - 4
    local function Row()
        used = used + 1
        local row = rows[used] or CreateRow(frame.scroll.child)
        rows[used] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetWidth(width)
        row:Show()
        row.killedList = nil
        y = y + ROW_HEIGHT
        return row
    end

    -- 首领：已击杀的合并成一行（悬停看是哪几个），还没打的逐行列出，第一个标“下一个”
    if #bosses == 0 then
        stack.y = y
        stack:Text(L["No boss data for this instance yet."], "Muted", 0, 4)
        y = stack.y
    end
    if killed > 0 then
        local row = Row()
        row.boss, row.questID, row.kind, row.killed, row.killedList = nil, nil, nil, true, killedList
        SetMarker(row, "done")
        row.name:SetText(MUTED .. (L["Killed %d"]):format(killed) .. "|r")
        row.tag:SetText("")
    end
    for order, boss in ipairs(remaining) do
        local row = Row()
        row.boss, row.questID, row.kind, row.killed = boss, nil, nil, false
        local name = ns.BossName(boss) or "?"
        if order == 1 then
            SetMarker(row, "next")
            row.name:SetText(TEXT .. name .. "|r")
            row.tag:SetText(GOLD .. L["Next"] .. "|r")
        else
            SetMarker(row, "open")
            row.name:SetText("|cffd9ccb0" .. name .. "|r")
            row.tag:SetText("")
        end
    end

    -- 任务：标题行右侧写已完成与副本外待接的数量；没有已接任务时只有这一行
    y = y + 4
    frame.divider:ClearAllPoints()
    frame.divider:SetPoint("TOPLEFT", 0, -y)
    frame.divider:SetWidth(width)
    y = y + 4
    -- 标题行：任务 N，后面是已完成（绿勾）与副本外待接（灰 !）的数量；悬停说明符号
    local header = GOLD .. L["Quests"] .. "|r" .. (#questRows > 0 and (MUTED .. " " .. #questRows .. "|r") or "")
    if done > 0 then
        header = header .. "   " .. QUEST_ICON.done .. MUTED .. done .. "|r"
    end
    if outside > 0 then
        header = header .. "   " .. QUEST_ICON.outside .. MUTED .. outside .. "|r"
    end
    stack.y = y
    local headerText = stack:Text(header, "Small", 0, 0)
    if not frame.questHover then
        frame.questHover = CreateFrame("Frame", nil, frame.scroll.child)
        frame.questHover:EnableMouse(true)
        frame.questHover:SetScript("OnEnter", QuestLegend)
        frame.questHover:SetScript("OnLeave", GameTooltip_Hide)
    end
    frame.questHover:ClearAllPoints()
    frame.questHover:SetPoint("TOPLEFT", headerText, "TOPLEFT", 0, 2)
    frame.questHover:SetPoint("BOTTOMRIGHT", headerText, "BOTTOMRIGHT", 0, -2)
    frame.questHover:Show()
    y = stack.y
    for _, item in ipairs(questRows) do
        local row = Row()
        row.questID, row.kind, row.boss, row.killed = item.id, item.kind, nil, nil
        SetMarker(row, item.kind == "complete" and "done" or (item.kind == "inside" and "next" or "active"))
        row.name:SetText(TEXT .. QuestName(item.id) .. "|r")
        row.tag:SetText(QuestTag(item))
    end
    stack.y = y + 2
    local height = stack:Finish()
    frame.scroll:SetContentHeight(height)
    frame:SetHeight(top + math.min(height, MAX_CONTENT_HEIGHT) + 6)
end
Module.Refresh = function() Refresh() end -- 供测试使用

local function Show()
    frame = frame or Create()
    RestorePosition()
    frame:Show()
    Refresh()
end

-- 退出测试模式：人在副本里且没关过这个副本的小窗，就回到真实数据；否则关掉小窗
function ExitTest()
    test = nil
    if current and dismissed ~= current.instanceID and Settings().autoShow then
        Refresh()
    elseif frame then
        frame:Hide()
    end
end

-- /wh test：用固定的虚构副本打开小窗（再输一次退出）；进入真实副本时自动回到真实数据
local function ToggleTest()
    if test and frame and frame:IsShown() then
        ExitTest()
        return
    end
    test = TestTemplate()
    Show()
end
Module.ToggleTest = ToggleTest -- 供测试使用

--------------------------------------------------------------------------------
-- 进出副本
--------------------------------------------------------------------------------

local pendingRefresh = false
local function OnQuestChange()
    if pendingRefresh or not (frame and frame:IsVisible()) then
        return
    end
    pendingRefresh = true
    C_Timer.After(0.5, function()
        pendingRefresh = false
        Refresh()
    end)
end

local function OnInstanceInfo()
    ApplyLockout()
    Refresh()
end

local function SetInstanceEvents(active)
    if active == instanceEventsRegistered then
        return
    end
    instanceEventsRegistered = active
    local method = active and "RegisterEvent" or "UnregisterEvent"
    ns[method](ns, "ENCOUNTER_END", OnEncounterEnd)
    ns[method](ns, "BOSS_KILL", OnBossKill)
    ns[method](ns, "PLAYER_TARGET_CHANGED", OnTargetChanged)
    ns[method](ns, "QUEST_LOG_UPDATE", OnQuestChange)
    ns[method](ns, "UPDATE_INSTANCE_INFO", OnInstanceInfo)
end

local function UpdateInstance()
    local instanceID = CurrentInstanceID()
    local sections = instanceID and SectionsFor(instanceID) or {}
    if #sections == 0 then
        current, dismissed = nil, nil
        SetInstanceEvents(false)
        if frame then
            frame:Hide()
        end
        return
    end
    if current and current.instanceID == instanceID then
        return
    end
    current = { instanceID = instanceID, sections = sections }
    test = nil
    local run = Run()
    if run.time and time() - run.time > RUN_EXPIRES then
        wipe(run.killed)
        run.zoneUID = nil
    end
    SetInstanceEvents(true)
    ApplyLockout()
    if RequestRaidInfo then
        RequestRaidInfo()
    end
    if Settings().autoShow and dismissed ~= instanceID then
        Show()
    end
end
Module.UpdateInstance = UpdateInstance -- 供测试使用

-- /wh instance：手动显示或隐藏（不在副本里时提示）
local function Toggle()
    if not current then
        ns:Print(L["You are not in an instance the handbook knows."])
        return
    end
    if frame and frame:IsShown() then
        dismissed = current.instanceID
        frame:Hide()
    else
        dismissed = nil
        Show()
    end
end

function Module:Refresh()
    if frame and frame:IsShown() then
        Refresh()
    end
end

function Module:OnEnable()
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateInstance)
    ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", UpdateInstance)
    ns:AddCommand("instance", L["show or hide the instance tracker"], Toggle)
    ns:AddCommand("test", L["preview the instance tracker with a sample dungeon"], ToggleTest)
    UpdateInstance()
end
