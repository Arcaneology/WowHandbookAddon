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
-- 客户端对单位身份有“秘密值”限制：选中目标的 GUID 是秘密值时拿不到实例编号，
-- 这时距上次击杀超过 RUN_EXPIRES 秒的记录视为旧进度清空。
local Module = ns:NewModule("InstanceTracker", { autoShow = true, collapsed = false })

local WIDTH = 280
local RUN_EXPIRES = 4 * 3600
local MAX_CONTENT_HEIGHT = 340
local UI
local frame
local current -- { instanceID, sections = { 副本序号… }, section = 当前分区在 sections 里的序号 }
local dismissed -- 玩家在这个副本实例里点了关闭
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
    local list = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID)
    return list or {}
end

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
    GameTooltip:SetText(ns.QuestTitle(questID), 1, 0.82, 0)
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

local ROW_HEIGHT = 20
local PAD = 12
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
    row.check:SetSize(14, 14)
    row.check:SetPoint("LEFT", 2, 0)
    row.check:SetTexture(READY_ICON)
    row.dot = row:CreateTexture(nil, "ARTWORK")
    row.dot:SetSize(6, 6)
    row.dot:SetPoint("CENTER", row.check, "CENTER")
    row.name = UI:Text(row, "Body")
    row.name:SetPoint("LEFT", 22, 0)
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
        row.dot:SetSize(state == "next" and 8 or 6, state == "next" and 8 or 6)
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

    f.title = UI:Text(f, "Heading")
    f.title:SetPoint("TOPLEFT", PAD, -12)
    f.title:SetPoint("RIGHT", -54, 0)
    f.title:SetWordWrap(false)
    f.subtitle = UI:Text(f, "Muted")
    f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)

    f.close = UI:CloseButton(f, function()
        dismissed = current and current.instanceID
        f:Hide()
    end, 22)
    f.close:SetPoint("TOPRIGHT", -4, -6)
    f.collapse = UI:Button(f, "-", 20, 18, "ghost")
    f.collapse:SetPoint("RIGHT", f.close, "LEFT", -2, 0)
    f.collapse:SetScript("OnClick", function()
        Settings().collapsed = not Settings().collapsed
        Refresh()
    end)

    -- 同一副本 ID 有多个分区时：手动切换分区
    f.section = UI:Dropdown(f, {}, function(position)
        Run().section = position
        Refresh()
    end, WIDTH - PAD * 2)

    -- 首领进度：大号计数 + 分段进度条（每个首领一段）
    f.progressLabel = UI:Text(f, "Muted", L["Boss progress"])
    f.progressCount = UI:Text(f, "Title")
    f.progressCount:SetJustifyH("RIGHT")
    f.segments = {}
    f.track = f:CreateTexture(nil, "ARTWORK")
    SetColor(f.track, "track")
    f.fill = f:CreateTexture(nil, "OVERLAY")
    SetColor(f.fill, "green")

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
        local gap = 3
        local segmentWidth = (width - gap * (total - 1)) / total
        for i = 1, total do
            local segment = frame.segments[i]
            if not segment then
                segment = frame:CreateTexture(nil, "ARTWORK")
                segment:SetHeight(6)
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
        frame.track:SetSize(width, 6)
        frame.fill:ClearAllPoints()
        frame.fill:SetPoint("TOPLEFT", PAD, -top)
        frame.fill:SetSize(math.max(1, width * (total > 0 and killed / total or 0)), 6)
    end
end

-- 任务行右侧：可交 / 目标完成数 / 副本内可接
local function QuestTag(row)
    if row.kind == "complete" then
        return GREEN .. L["Ready to turn in"] .. "|r"
    elseif row.kind == "inside" then
        return GOLD .. L["Pick up here"] .. "|r"
    end
    local done, total = 0, 0
    for _, objective in ipairs(Objectives(row.id)) do
        total = total + 1
        if objective.finished then
            done = done + 1
        end
    end
    return total > 0 and ("|cff6f95d6%d/%d|r"):format(done, total) or ("|cff6f95d6" .. L["In progress"] .. "|r")
end

function Refresh()
    if not (frame and frame:IsShown() and current) then
        return
    end
    local dungeon, position = CurrentDungeon()
    if not dungeon then
        return
    end
    local run = Run()
    local bosses = Bosses(dungeon)
    local killed = 0
    for _, boss in ipairs(bosses) do
        if run.killed[BossKey(boss)] then
            killed = killed + 1
        end
    end
    frame.title:SetText(ns.Name(dungeon.name) or "?")
    local levels = dungeon.levels
    frame.subtitle:SetText(table.concat({
        levels and ("|c%s%s %s|r"):format(ns.LevelColor(levels[1], levels[2]), L["Level"], ns.LevelRange(levels)) or nil,
        dungeon.kind == "raid" and L["Raid"] or L["Dungeon"],
    }, "  ·  "))

    local collapsed = Settings().collapsed
    frame.collapse:SetLabel(collapsed and "+" or "-")
    local top = 50
    if #current.sections > 1 and not collapsed then
        local items = {}
        for i, index in ipairs(current.sections) do
            tinsert(items, { id = i, label = ns.Name(ns.Data.dungeons[index].name) })
        end
        frame.section:ClearAllPoints()
        frame.section:SetPoint("TOPLEFT", PAD, -top)
        frame.section:SetItems(items)
        frame.section:SetValue(position)
        frame.section:Show()
        top = top + 32
    else
        frame.section:Hide()
    end

    -- 进度：收起时也显示，一眼看到打到哪了
    frame.progressLabel:ClearAllPoints()
    frame.progressLabel:SetPoint("TOPLEFT", PAD, -top - 4)
    frame.progressCount:ClearAllPoints()
    frame.progressCount:SetPoint("TOPRIGHT", -PAD, -top)
    frame.progressCount:SetText(("%s%d|r %s/ %d|r"):format(killed == #bosses and #bosses > 0 and GREEN or TEXT,
        killed, MUTED, #bosses))
    frame.progress = frame.progressCount -- 供测试使用
    DrawProgress(top + 24, killed, #bosses)
    top = top + 38

    if collapsed then
        frame.scroll:Hide()
        frame.scroll.bar:Hide()
        frame:SetHeight(top + 4)
        return
    end
    frame.scroll:Show()
    frame.scroll:ClearAllPoints()
    frame.scroll:SetPoint("TOPLEFT", PAD - 4, -top)
    frame.scroll:SetPoint("BOTTOMRIGHT", -PAD, PAD)

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
        y = y + ROW_HEIGHT
        return row
    end

    -- 首领：已击杀打勾变暗，下一个没打的金色标记
    if #bosses == 0 then
        stack.y = y
        stack:Text(L["No boss data for this instance yet."], "Muted", 0, 4)
        y = stack.y
    end
    local nextShown = false
    for _, boss in ipairs(bosses) do
        local row = Row()
        row.boss, row.questID, row.kind = boss, nil, nil
        row.killed = run.killed[BossKey(boss)] and true or false
        local name = ns.BossName(boss) or "?"
        if row.killed then
            SetMarker(row, "done")
            row.name:SetText(MUTED .. name .. "|r")
            row.tag:SetText(GREEN .. L["Killed"] .. "|r")
        elseif not nextShown then
            nextShown = true
            SetMarker(row, "next")
            row.name:SetText(TEXT .. name .. "|r")
            row.tag:SetText(GOLD .. L["Next"] .. "|r")
        else
            SetMarker(row, "open")
            row.name:SetText("|cffd9ccb0" .. name .. "|r")
            row.tag:SetText("")
        end
    end

    -- 任务
    y = y + 8
    frame.divider:ClearAllPoints()
    frame.divider:SetPoint("TOPLEFT", 0, -y)
    frame.divider:SetWidth(width)
    y = y + 8
    local questRows, done, outside = QuestRows(dungeon)
    stack.y = y
    stack:Text(GOLD .. L["Quests for this instance"] .. "|r" .. (#questRows > 0 and (MUTED .. "  " .. #questRows .. "|r") or ""),
        "Small", 0, 0)
    y = stack.y
    if #questRows == 0 then
        stack:Text(MUTED .. L["No quests in your log for this instance."] .. "|r", "Small", 0, 0)
        y = stack.y
    end
    for _, item in ipairs(questRows) do
        local row = Row()
        row.questID, row.kind, row.boss, row.killed = item.id, item.kind, nil, nil
        SetMarker(row, item.kind == "complete" and "done" or (item.kind == "inside" and "next" or "active"))
        row.name:SetText(TEXT .. ns.QuestTitle(item.id) .. "|r")
        row.tag:SetText(QuestTag(item))
    end
    stack.y = y + 4
    if done > 0 or outside > 0 then
        stack:Text(MUTED .. (L["%d done · %d not picked up (pick up outside)"]):format(done, outside) .. "|r", "Small", 0, 0)
    end
    stack:Text(MUTED .. L["Hover for loot and rewards; click to open WoW Handbook."] .. "|r", "Small", 0, 0)
    local height = stack:Finish()
    frame.scroll:SetContentHeight(height)
    frame:SetHeight(top + math.min(height, MAX_CONTENT_HEIGHT) + PAD)
end
Module.Refresh = function() Refresh() end -- 供测试使用

local function Show()
    frame = frame or Create()
    RestorePosition()
    frame:Show()
    Refresh()
end

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
    UpdateInstance()
end
