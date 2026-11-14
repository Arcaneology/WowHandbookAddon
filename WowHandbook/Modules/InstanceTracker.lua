local ADDON_NAME, ns = ...
local L = ns.L

-- 副本助手小窗：一个小窗两种模式。
-- 副本外（设置项 shown，默认开）：只显示任务。标题即副本选择器，适合当前等级的副本排最前（与副本手册推荐同一标准），
--   其余按等级；所选副本按角色记住，进入副本时自动换成这个副本。任务分“进本前先接”与“副本内接取”两段，
--   已是别的副本任务前置步骤的不单独成行，任务链显示进度、点 +/- 展开每一步。点击一行在地图上标记该找的人
--   （该接的一步标记接任务的人，可交的标记交任务的人，进行中的副本任务标记副本入口），右键在手册里打开。
-- 副本内（设置项 autoShow，默认开）：本副本的首领击杀进度加任务状态。
-- · 首领击杀：首领战结束（ENCOUNTER_END，带本场全部首领的 creatureID 与名字）按 NPC ID 或名字对应首领，
--   另听 BOSS_KILL，团队副本再读客户端的副本锁定记录。不订阅战斗记录：这个客户端把它列为受限事件，
--   插件订阅会被拦截并弹出“只有暴雪界面才能执行的操作”提示。没有首领战的稀有精英不会自动标记。
-- · 一次副本进度：生物 GUID 里带副本实例编号，遇到新的编号就是新进度，清空击杀记录；
--   死亡跑尸、下线重上回到同一个实例时记录保留（存角色存档）。
-- · 同一副本 ID 的多个分区（血色修道院各区等）：看到哪个分区的首领死亡就切到哪个区，也可在小窗里手动切换。
-- · 任务：本副本任务里已接的（进度、可交）与副本内可接的逐条列出，其余只给数量。
-- · 布局尽量紧凑：一行标题（副本名 + 首领进度）加一条细进度条；已击杀的首领合并成一行（悬停看是哪几个），
--   只展开还没打的；任务标题行右侧给出已完成与副本外待接的数量。
-- 关闭按钮：副本内只隐藏到下次进入副本；副本外记入设置（/wh quests 或设置里再打开）。
-- 首领相关事件只在副本里订阅；任务事件只在小窗显示时订阅，刷新节流 0.5 秒。
-- /wh test：测试模式，用一套固定的虚构副本（首领、击杀进度、各种状态的任务）打开小窗，看版式用。
-- 客户端对单位身份有“秘密值”限制：选中目标的 GUID 是秘密值时拿不到实例编号，
-- 这时距上次击杀超过 RUN_EXPIRES 秒的记录视为旧进度清空。
local Module = ns:NewModule("InstanceTracker", { autoShow = true, shown = true, collapsed = false })

local WIDTH = 240
local RUN_EXPIRES = 4 * 3600
local MAX_CONTENT_HEIGHT = 280
local UI
local frame, menu
local current -- 在副本里：{ instanceID, sections = { 副本序号… } }
local dismissed -- 玩家在这个副本实例里点了关闭
local test -- 测试模式的虚构数据（/wh test），非 nil 时小窗只显示它
local expanded = {} -- 副本外：展开了任务链的任务
local instanceEventsRegistered = false

-- 文字里内嵌的颜色取自主题；强调色随配色方案变化，用的时候再取（K.gold）
local K = ns.Theme.code
local GREEN, MUTED, TEXT, DIM, RED, BLUE = K.green, K.muted, K.text, K.textDim, K.red, K.blue

local function Settings()
    return ns:GetModuleSettings(Module)
end

local function CharState()
    ns.charDB.dungeonQuests = ns.charDB.dungeonQuests or {}
    return ns.charDB.dungeonQuests
end

local function Dungeons()
    return ns.modules.Dungeons
end

local Refresh
local ExitTest
local Evaluate

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
-- 副本外：副本列表（适合的在前）与所选副本
--------------------------------------------------------------------------------

local function FactionOK(dungeon)
    local faction = ns.PlayerFaction()
    return not dungeon.faction or dungeon.faction == "both" or not faction
        or (dungeon.faction == "alliance" and faction == "A") or (dungeon.faction == "horde" and faction == "H")
end

local function Listable(dungeon)
    return not dungeon.aggregateOnly and #(dungeon.quests or {}) > 0 and FactionOK(dungeon)
end

-- 返回 suitable, others：副本序号列表。适合的按离等级区间中点的距离，其余按最低等级
local function DungeonOrder()
    local level = ns.PlayerLevel()
    local suitable, others = {}, {}
    local Suitable = Dungeons().Suitable
    for index, dungeon in ipairs(ns.Data.dungeons or {}) do
        if Listable(dungeon) then
            tinsert(Suitable(dungeon) and suitable or others, index)
        end
    end
    local function Mid(index)
        local levels = ns.Data.dungeons[index].levels
        return levels and (levels[1] + levels[2]) / 2 or 999
    end
    table.sort(suitable, function(a, b)
        local da, db = math.abs(Mid(a) - level), math.abs(Mid(b) - level)
        if da ~= db then
            return da < db
        end
        return a < b
    end)
    table.sort(others, function(a, b)
        local la, lb = ns.Data.dungeons[a].levels, ns.Data.dungeons[b].levels
        la, lb = la and la[1] or 999, lb and lb[1] or 999
        if la ~= lb then
            return la < lb
        end
        return a < b
    end)
    return suitable, others
end
Module.DungeonOrder = DungeonOrder -- 供测试使用

local function IndexOfSlug(slug)
    for index, dungeon in ipairs(ns.Data.dungeons or {}) do
        if dungeon.slug == slug then
            return index
        end
    end
    return nil
end

-- 副本外显示的副本：玩家选过的，否则最适合的那个
local function SelectedIndex()
    local index = CharState().dungeon and IndexOfSlug(CharState().dungeon)
    if index then
        return index
    end
    local suitable, others = DungeonOrder()
    return suitable[1] or others[1]
end
Module.SelectedIndex = SelectedIndex -- 供测试使用

local function Select(index)
    local dungeon = ns.Data.dungeons[index]
    if dungeon then
        CharState().dungeon = dungeon.slug
    end
    if menu then
        menu:Hide()
    end
    Refresh()
end
Module.Select = Select -- 供测试使用

--------------------------------------------------------------------------------
-- 任务
--------------------------------------------------------------------------------

local function QuestClassOK(quest)
    return not quest.classRestriction or quest.classRestriction:lower() == ns.PlayerClass()
end

-- 副本内：返回 { 已接或副本内可接的任务 }, 已完成数, 需在副本外接的数量
local function QuestRows(dungeon)
    local rows, done, outside = {}, 0, 0
    local faction = ns.PlayerFaction()
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = ns.Data.quests[questID]
        if quest and QuestClassOK(quest) and not (quest.faction and faction and quest.faction ~= faction) then
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

local GROUP_ORDER = { complete = 1, active = 2, ready = 3, chain = 4, low = 5 }

-- 副本外：返回 { outside = {条目}, inside = {条目} }, 已完成数。条目：{ id, kind, chain, nextStep, doneSteps }
-- kind：complete（可交）、active（进行中）、ready（现在可接）、chain（先做前置）、low（等级不够）
local function QuestGroups(dungeon)
    local faction = ns.PlayerFaction()
    local Classify = Dungeons().Classify
    local list, info = {}, {}
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = ns.Data.quests[questID]
        if quest and not info[questID] and QuestClassOK(quest)
            and not (quest.faction and faction and quest.faction ~= faction) then
            local kind, chain, nextStep, doneSteps = Classify(questID)
            -- 额外与外部关联任务只在已接时追踪
            if (not quest.extra and not quest.relatedExternal) or kind == "active" then
                if kind == "active" and C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) then
                    kind = "complete"
                end
                info[questID] = { id = questID, kind = kind, chain = chain, nextStep = nextStep, doneSteps = doneSteps }
                tinsert(list, questID)
            end
        end
    end
    local covered = {}
    for _, questID in ipairs(list) do
        for _, stepID in ipairs(info[questID].chain) do
            if stepID ~= questID and info[stepID] then
                covered[stepID] = true
            end
        end
    end
    local groups, done = { outside = {}, inside = {} }, 0
    for _, questID in ipairs(list) do
        local item = info[questID]
        if not covered[questID] then
            if item.kind == "done" then
                done = done + 1
            else
                -- 任务链上正在做的一步已接：整条链算进行中
                if item.kind == "chain" and item.nextStep and ns.QuestStatus(item.nextStep) == "active" then
                    local stepComplete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(item.nextStep)
                    item.kind = stepComplete and "complete" or "active"
                end
                -- 该做的一步在副本外接就归“进本前先接”，否则看副本任务本身
                local target = ns.Data.quests[item.nextStep or questID] or ns.Data.quests[questID]
                tinsert(target.inside and groups.inside or groups.outside, item)
            end
        end
    end
    local function Sort(a, b)
        if a.kind ~= b.kind then
            return GROUP_ORDER[a.kind] < GROUP_ORDER[b.kind]
        end
        local qa, qb = ns.Data.quests[a.id], ns.Data.quests[b.id]
        local la, lb = qa.min or qa.level or 0, qb.min or qb.level or 0
        if la ~= lb then
            return la < lb
        end
        return a.id < b.id
    end
    table.sort(groups.outside, Sort)
    table.sort(groups.inside, Sort)
    return groups, done
end
Module.QuestGroups = QuestGroups -- 供测试使用

-- 任务链上一步的状态：done / active / next / pending
local function StepState(stepID, nextStep)
    local status = ns.QuestStatus(stepID)
    if status == "done" then
        return "done"
    elseif status == "active" then
        return "active"
    elseif stepID == nextStep then
        return "next"
    end
    return "pending"
end

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
-- 地图标记：该去找谁
--------------------------------------------------------------------------------

-- 返回 source, role。已接且可交 -> 交任务的人；已接未完成的副本任务（给了副本序号时）-> 副本入口；其余 -> 接任务的人
local function TrackTarget(stepID, dungeonIndex)
    local quest = ns.Data.quests[stepID]
    if not quest then
        return nil
    end
    if ns.QuestStatus(stepID) == "active" then
        if C_QuestLog.IsComplete and C_QuestLog.IsComplete(stepID) then
            return quest.finish, "finish"
        end
        if quest.instances and dungeonIndex then
            local mapID, x, y = ns.DungeonEntrance(dungeonIndex)
            if mapID then
                return { map = mapID, x = x, y = y, name = ns.Data.dungeons[dungeonIndex].name }, "entrance"
            end
        end
        return quest.finish, "finish"
    end
    return quest.start, "start"
end
Module.TrackTarget = TrackTarget -- 供测试使用

local function SourceName(source)
    local name = source and ns.Name(source.name) or "?"
    if source and source.kind == "item" then
        name = (L["Item: %s"]):format(name)
    end
    return name
end

-- 在地图上标记这一步该找的人；副本内不标副本入口（人已经在里面）
local function Track(stepID)
    if test then
        return -- 测试模式的虚构任务没有地点
    end
    local source, role = TrackTarget(stepID, not current and SelectedIndex() or nil)
    if not source then
        ns:Print(L["No map location recorded for this."])
        return
    end
    if not (source.map and source.x) then
        if source.kind == "item" then
            ns:Print(L["%s starts from an item: %s"], ns.QuestTitle(stepID), SourceName(source))
        elseif role == "start" and ns.Data.quests[stepID].inside then
            ns:Print(L["%s is picked up inside the dungeon."], ns.QuestTitle(stepID))
        else
            ns:Print(L["No map location recorded for this."])
        end
        return
    end
    ns.Waypoints:Set(source.map, source.x, source.y, ("%s (%s)"):format(SourceName(source), ns.QuestTitle(stepID)))
end
Module.Track = Track -- 供测试使用

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
    if not current then
        return SelectedIndex()
    end
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

-- 小窗大小按设置缩放（右键菜单里选）
local function ApplyScale()
    if frame then
        frame:SetScale(Settings().scale or 1)
    end
end

local function StartMoving()
    if frame and not Settings().locked then
        frame:StartMoving()
    end
end

local function SetColor(texture, name)
    texture:SetColorTexture(unpack(ns.Theme.colors[name]))
end

--------------------------------------------------------------------------------
-- 鼠标提示：首领掉落、任务目标、接交地点、任务链与奖励
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

local function PlaceLine(label, source)
    if not source then
        return
    end
    local place
    if source.map and source.x then
        place = ("%s %.1f, %.1f"):format(ns.MapName(source.map) or "?", source.x, source.y or 0)
    else
        place = L["inside the instance"]
    end
    GameTooltip:AddDoubleLine(label .. " " .. SourceName(source), place, 0.85, 0.8, 0.69, 0.54, 0.51, 0.45)
end

-- 任务提示：row.questID（本行的任务或任务链上的一步），row.item（副本外：所在的整条任务链）
local function QuestTooltip(row)
    local questID = row.questID
    local item = row.item
    local quest = ns.Data.quests[questID] or {}
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    GameTooltip:SetText(QuestName(questID), 1, 0.82, 0)
    local level = quest.min or quest.level
    if level then
        if ns.PlayerLevel() < level then
            GameTooltip:AddLine((L["Available from level %d"]):format(level), 0.85, 0.4, 0.29)
        else
            GameTooltip:AddLine((L["Available from level %d"]):format(level), 0.85, 0.8, 0.69)
        end
    end
    if row.kind == "inside" then
        GameTooltip:AddLine(L["Picked up inside the dungeon"], 0.88, 0.71, 0.35)
    end
    local objectives = Objectives(questID)
    for _, objective in ipairs(objectives) do
        if objective.text and objective.text ~= "" then
            if objective.finished then
                GameTooltip:AddLine(objective.text, 0.27, 0.75, 0.45, true)
            else
                GameTooltip:AddLine(objective.text, 1, 1, 1, true)
            end
        end
    end
    local summary = #objectives == 0 and quest.summary and ns.Name(quest.summary)
    if summary then
        GameTooltip:AddLine(summary, 1, 1, 1, true)
    end
    if not test then
        PlaceLine(L["Pick up:"], quest.start)
        PlaceLine(L["Turn in:"], quest.finish)
    end
    if item and not row.isStep and #item.chain > 1 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine((L["Quest chain (%d/%d)"]):format(item.doneSteps, #item.chain), 0.88, 0.71, 0.35)
        for index, id in ipairs(item.chain) do
            local state = StepState(id, item.nextStep)
            local color = state == "done" and GREEN or (state == "active" and K.gold or (state == "next" and BLUE or MUTED))
            GameTooltip:AddLine(("%s%d. %s|r"):format(color, index, ns.QuestTitle(id)), 1, 1, 1)
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
    if not test then
        GameTooltip:AddLine(" ")
        local _, role = TrackTarget(row.trackID or questID, not current and SelectedIndex() or nil)
        local hint = role == "finish" and L["Click: mark the turn-in NPC"]
            or (role == "entrance" and L["Click: mark the dungeon entrance"] or L["Click: mark the quest giver"])
        GameTooltip:AddLine(hint, 0.54, 0.51, 0.45)
        GameTooltip:AddLine(L["Right-click: menu"], 0.54, 0.51, 0.45)
    end
    GameTooltip:Show()
end

-- 物品数据到了，正在看的提示重新生成
ns.OnItemLoaded(function()
    if hoveredRow and hoveredRow:IsVisible() and hoveredRow.ShowTooltip then
        hoveredRow:ShowTooltip()
    end
end)

-- 打开手册里的这个副本（首领看掉落页，任务看任务页并选中）
local function OpenInHandbook(row)
    if test then
        return -- 测试模式的虚构副本在手册里没有
    end
    local module = Dungeons()
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
-- 行
--------------------------------------------------------------------------------

local ROW_HEIGHT = 16
local PAD = 10
local HEADER = 34 -- 副本内：标题行 + 进度条
local OUTSIDE_TOP = 28 -- 副本外：只有标题行
local READY_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"

-- 行的右键菜单：任务可以在地图上标记该找的人、在手册里打开；首领在手册里打开掉落页
local function RowMenu(row)
    local entries = {}
    if row.questID then
        tinsert(entries, { kind = "title", text = ns.QuestTitle(row.questID) })
        tinsert(entries, { kind = "action", text = L["Mark on the map"], onClick = function()
            Track(row.trackID or row.questID)
        end })
    end
    tinsert(entries, { kind = "action", text = L["Open in WoW Handbook"], onClick = function()
        OpenInHandbook(row)
    end })
    UI:ContextMenu(entries)
end

-- 列表行：左侧状态标记（副本外是任务链的 +/-），中间名字，右侧状态；悬停显示提示。
-- 点击：首领打开手册掉落页；任务左键在地图上标记该找的人；右键弹出菜单
local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
    row.toggle = CreateFrame("Button", nil, row)
    row.toggle:SetSize(14, ROW_HEIGHT)
    row.toggle:SetPoint("LEFT", 0, 0)
    row.toggle.text = UI:Text(row.toggle, "Accent")
    row.toggle.text:SetPoint("CENTER")
    row.toggle:SetScript("OnClick", function()
        if row.item then
            expanded[row.item.id] = not expanded[row.item.id] or nil
            Refresh()
        end
    end)
    row.toggle:Hide()
    row.name = UI:Text(row, "Small")
    row.name:SetWordWrap(false)
    row.tag = UI:Text(row, "Small")
    row.tag:SetPoint("RIGHT", -4, 0)
    row.tag:SetJustifyH("RIGHT")
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
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            RowMenu(self)
        elseif self.questID then
            Track(self.trackID or self.questID)
        else
            OpenInHandbook(self)
        end
    end)
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

-- 行的字段清空，换成这一行要显示的内容；indent 为名字左侧缩进
local function ResetRow(row, indent)
    row.boss, row.questID, row.kind, row.killed, row.killedList = nil, nil, nil, nil, nil
    row.item, row.isStep, row.trackID = nil, nil, nil
    row.toggle:Hide()
    row.check:Hide()
    row.dot:Hide()
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", indent or 18, 0)
    row.name:SetPoint("RIGHT", row.tag, "LEFT", -6, 0)
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

--------------------------------------------------------------------------------
-- 副本选择器（副本外）
--------------------------------------------------------------------------------

local MENU_ROW = 18
local MENU_MAX_HEIGHT = 320

-- 任务状态符号：用游戏里 NPC 头顶的任务标记，玩家一眼能懂，比文字省地方。
-- 黄 ? 可交，灰 ? 进行中，黄 ! 可接（副本内可接），灰 ! 副本外待接，蓝 ! 先做前置，红 ! 等级不够，绿勾 已完成
local QUEST_ICON = {
    turnIn = "|TInterface\\GossipFrame\\ActiveQuestIcon:12:12|t",
    active = "|TInterface\\GossipFrame\\ActiveQuestIcon:12:12:0:0:16:16:0:16:0:16:140:131:116|t",
    inside = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12|t",
    outside = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12:0:0:16:16:0:16:0:16:140:131:116|t",
    done = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t",
}
Module.QUEST_ICON = QUEST_ICON -- 供测试使用
local CHAIN_ICON = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12:0:0:16:16:0:16:0:16:111:149:214|t"
local LOW_ICON = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12:0:0:16:16:0:16:0:16:216:102:74|t"
-- 副本外各类条目的符号
local KIND_ICON = {
    complete = QUEST_ICON.turnIn, active = QUEST_ICON.active, ready = QUEST_ICON.inside,
    chain = CHAIN_ICON, low = LOW_ICON,
}
Module.KIND_ICON = KIND_ICON -- 供测试使用

local function CreateMenu()
    local m = UI:Panel(UIParent, "menu", "line")
    m:SetFrameStrata("DIALOG")
    m:SetWidth(WIDTH)
    m:EnableMouse(true)
    m:SetClampedToScreen(true)
    m.scroll = UI:ScrollArea(m)
    m.scroll:SetPoint("TOPLEFT", 4, -4)
    m.scroll:SetPoint("BOTTOMRIGHT", -12, 4)
    m.rows = {}
    m.headings = {}
    m:Hide()
    -- 点别处或按 Esc 关闭（具名框架才能放进 UISpecialFrames）
    local name = "WowHandbookInstanceMenu"
    _G[name] = m
    tinsert(UISpecialFrames, name)
    UI:AutoClose(m, function()
        return frame and frame.titleHover
    end)
    return m
end

local function MenuButton(index)
    local button = menu.rows[index]
    if button then
        return button
    end
    button = CreateFrame("Button", nil, menu.scroll.child)
    button:SetHeight(MENU_ROW)
    button.hover = button:CreateTexture(nil, "BACKGROUND")
    button.hover:SetAllPoints()
    SetColor(button.hover, "glassHover")
    button.hover:Hide()
    button.tag = UI:Text(button, "Small")
    button.tag:SetPoint("RIGHT", -4, 0)
    button.tag:SetJustifyH("RIGHT")
    button.name = UI:Text(button, "Small")
    button.name:SetPoint("LEFT", 6, 0)
    button.name:SetPoint("RIGHT", button.tag, "LEFT", -4, 0)
    button.name:SetWordWrap(false)
    button:SetScript("OnEnter", function(self) self.hover:Show() end)
    button:SetScript("OnLeave", function(self) self.hover:Hide() end)
    button:SetScript("OnClick", function(self) Select(self.index) end)
    menu.rows[index] = button
    return button
end

-- 副本选择器：适合你的在前，其余按等级；每项右侧是现在可接（或进行中）的任务数与等级区间
local function FillMenu()
    local suitable, others = DungeonOrder()
    local selected = SelectedIndex()
    local y, used = 0, 0
    for _, heading in ipairs(menu.headings) do
        heading:Hide()
    end
    local width = WIDTH - 16
    local function Section(headingIndex, title, list)
        if #list == 0 then
            return
        end
        local heading = menu.headings[headingIndex] or UI:Text(menu.scroll.child, "Accent")
        menu.headings[headingIndex] = heading
        heading:SetText(title)
        heading:ClearAllPoints()
        heading:SetPoint("TOPLEFT", 4, -y - 3)
        heading:Show()
        y = y + MENU_ROW
        for _, index in ipairs(list) do
            used = used + 1
            local dungeon = ns.Data.dungeons[index]
            local button = MenuButton(used)
            button.index = index
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", 0, -y)
            button:SetWidth(width)
            button.name:SetText((index == selected and K.gold or TEXT) .. (ns.Name(dungeon.name) or "?") .. "|r")
            local levels = dungeon.levels
            local levelText = levels and ("|c%s%s|r"):format(ns.LevelColor(levels[1], levels[2]), ns.LevelRange(levels)) or ""
            local _, _, ready, active = Dungeons().QuestSummary(dungeon)
            local badge = ""
            if ready > 0 then
                badge = QUEST_ICON.inside .. MUTED .. ready .. "|r "
            elseif active > 0 then
                badge = QUEST_ICON.turnIn .. MUTED .. active .. "|r "
            end
            button.tag:SetText(badge .. levelText)
            button:Show()
            y = y + MENU_ROW
        end
        y = y + 4
    end
    Section(1, L["Suitable for you"], suitable)
    Section(2, L["All dungeons"], others)
    for index = used + 1, #menu.rows do
        menu.rows[index]:Hide()
    end
    menu:SetHeight(math.min(y + 8, MENU_MAX_HEIGHT))
    menu.scroll:SetContentHeight(y)
    menu.scroll.bar:SetShown(y + 8 > MENU_MAX_HEIGHT)
end

local function ToggleMenu()
    if current or test then
        return -- 副本里看的就是当前副本；分区用小窗里的分区下拉框切换
    end
    menu = menu or CreateMenu()
    if menu:IsShown() then
        menu:Hide()
        return
    end
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
    menu:SetScale(frame:GetEffectiveScale() / UIParent:GetEffectiveScale())
    menu:Show()
    FillMenu()
    menu.scroll:ScrollToTop()
end
Module.ToggleMenu = ToggleMenu -- 供测试使用

-- 小窗的右键菜单：锁定位置、大小；打开手册里的这个副本；打开设置
local function WindowMenu()
    if menu then
        menu:Hide()
    end
    UI:ContextMenu(function()
        local entries = UI:WindowMenuEntries(Settings(), ApplyScale)
        tinsert(entries, { kind = "separator" })
        if not test then
            tinsert(entries, { kind = "action", text = L["Open in WoW Handbook"], onClick = function()
                OpenInHandbook({})
            end })
        end
        tinsert(entries, { kind = "action", text = L["Settings"], onClick = function()
            ns.MainFrame:Open("settings")
        end })
        return entries
    end)
end
Module.WindowMenu = WindowMenu -- 供测试使用
Module.MenuRow = function(index) return menu and menu.rows[index] end -- 供测试使用

--------------------------------------------------------------------------------
-- 框架
--------------------------------------------------------------------------------

local SetQuestEvents

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
    f:SetScript("OnDragStart", StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    -- 右键小窗空白处或标题：锁定位置、大小、打开手册与设置
    f:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            WindowMenu()
        end
    end)
    -- 任务事件只在小窗显示时订阅
    f:SetScript("OnShow", function()
        SetQuestEvents(true)
    end)
    f:SetScript("OnHide", function()
        SetQuestEvents(false)
        if menu then
            menu:Hide()
        end
    end)

    -- 顶部金色细线，与主窗口一致
    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetHeight(2)
    SetColor(accent, "gold")

    -- 标题行：（副本外有下拉箭头）副本名 …… 进度，收起、关闭
    f.close = UI:CloseButton(f, function()
        if test then
            ExitTest()
        elseif current then
            dismissed = current.instanceID
            f:Hide()
        else
            Settings().shown = false
            f:Hide()
            ns:Print(L["Dungeon helper hidden. Type /wh quests to show it again."])
        end
    end, 18)
    f.close:SetPoint("TOPRIGHT", -3, -5)
    f.collapse = UI:Button(f, "-", 16, 16, "ghost")
    f.collapse:SetPoint("RIGHT", f.close, "LEFT", -1, 0)
    f.progressCount = UI:Text(f, "Small")
    f.progressCount:SetPoint("RIGHT", f.collapse, "LEFT", -6, 0)
    f.progressCount:SetJustifyH("RIGHT")
    f.progress = f.progressCount -- 供测试使用
    f.arrow = f:CreateTexture(nil, "OVERLAY")
    f.arrow:SetSize(10, 10)
    f.arrow:SetPoint("TOPLEFT", PAD, -12)
    f.arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    f.arrow:SetVertexColor(unpack(ns.Theme.colors.gold))
    f.title = UI:Text(f, "Heading")
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    -- 标题悬停看等级与操作说明；副本外点击打开副本选择器
    f.titleHover = CreateFrame("Button", nil, f)
    f.titleHover:SetPoint("TOPLEFT", PAD - 2, -6)
    f.titleHover:SetPoint("RIGHT", f.progressCount, "LEFT", -2, 0)
    f.titleHover:SetHeight(20)
    f.titleHover.hover = f.titleHover:CreateTexture(nil, "BACKGROUND")
    f.titleHover.hover:SetAllPoints()
    SetColor(f.titleHover.hover, "glassHover")
    f.titleHover.hover:Hide()
    f.titleHover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f.titleHover:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            WindowMenu()
        else
            ToggleMenu()
        end
    end)
    f.titleHover:SetScript("OnEnter", function(self)
        if not (current or test) then
            self.hover:Show()
        end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(f.title:GetText() or "", 1, 0.82, 0)
        if f.info then
            GameTooltip:AddLine(f.info, 1, 1, 1)
        end
        GameTooltip:AddLine((current or test) and L["Drag: move"] or L["Click: choose a dungeon · Drag: move"],
            0.54, 0.51, 0.45)
        GameTooltip:AddLine(L["Right-click: lock, size and more"], 0.54, 0.51, 0.45)
        GameTooltip:Show()
    end)
    f.titleHover:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip_Hide()
    end)
    -- 标题拖不动的话整个小窗就拖不动：把拖动转给小窗
    f.titleHover:RegisterForDrag("LeftButton")
    f.titleHover:SetScript("OnDragStart", StartMoving)
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
    f.headings = {}
    f.divider = f.scroll.child:CreateTexture(nil, "ARTWORK")
    SetColor(f.divider, "lineSoft")
    f.divider:SetHeight(1)
    f.empty = UI:Text(f.scroll.child, "Muted")
    f.empty:SetWidth(WIDTH - PAD * 2 - 8)
    f.empty:SetWordWrap(true)
    f:SetScale(Settings().scale or 1)
    f:Hide()
    return f
end

-- 进度条：首领不多时每个首领一段，太多时画成一整条；total 为 0 时全部隐藏
local MAX_SEGMENTS = 20
local function DrawProgress(top, killed, total)
    local width = WIDTH - PAD * 2
    local segmented = total > 0 and total <= MAX_SEGMENTS
    for _, segment in ipairs(frame.segments) do
        segment:Hide()
    end
    frame.track:SetShown(total > MAX_SEGMENTS)
    frame.fill:SetShown(total > MAX_SEGMENTS and killed > 0)
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
    elseif total > 0 then
        frame.track:ClearAllPoints()
        frame.track:SetPoint("TOPLEFT", PAD, -top)
        frame.track:SetSize(width, 3)
        frame.fill:ClearAllPoints()
        frame.fill:SetPoint("TOPLEFT", PAD, -top)
        frame.fill:SetSize(math.max(1, width * killed / total), 3)
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

-- 副本内任务行右侧：可交 / 副本内可接只放符号；进行中列出每个目标的数量（如 3/8  0/1），已完成的目标换成绿勾
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
            tinsert(parts, (BLUE .. "%d/%d|r"):format(have, need))
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
    if current or test then
        GameTooltip:AddLine(QUEST_ICON.inside .. " " .. L["Picked up inside the dungeon"], 1, 1, 1)
        GameTooltip:AddLine(QUEST_ICON.outside .. " " .. L["To pick up outside the dungeon"], 1, 1, 1)
    else
        GameTooltip:AddLine(QUEST_ICON.inside .. " " .. L["Ready to pick up"], 1, 1, 1)
        GameTooltip:AddLine(CHAIN_ICON .. " " .. L["Needs earlier quests"], 1, 1, 1)
        GameTooltip:AddLine(LOW_ICON .. " " .. L["Level too low"], 1, 1, 1)
    end
    GameTooltip:AddLine(QUEST_ICON.done .. " " .. L["Completed"], 1, 1, 1)
    GameTooltip:Show()
end

-- 副本外的段标题（悬停说明符号）
local function Heading(index, text, count)
    local heading = frame.headings[index]
    if not heading then
        heading = CreateFrame("Frame", nil, frame.scroll.child)
        heading:SetHeight(ROW_HEIGHT)
        heading:EnableMouse(true)
        heading:SetScript("OnEnter", QuestLegend)
        heading:SetScript("OnLeave", GameTooltip_Hide)
        heading.text = UI:Text(heading, "Small")
        heading.text:SetPoint("LEFT", 2, 0)
        frame.headings[index] = heading
    end
    heading.text:SetText(K.gold .. text .. "|r" .. MUTED .. "  " .. count .. "|r")
    return heading
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

-- 行池：rows[1..used] 显示，其余隐藏
local function RowPool()
    local used, y = 0, 0
    local width = WIDTH - PAD * 2 - 4
    for _, row in ipairs(frame.rows) do
        row:Hide()
    end
    local pool = {}
    function pool.Row(indent)
        used = used + 1
        local row = frame.rows[used] or CreateRow(frame.scroll.child)
        frame.rows[used] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetWidth(width)
        ResetRow(row, indent)
        row:Show()
        y = y + ROW_HEIGHT
        return row
    end
    function pool.Y(value)
        if value then
            y = value
        end
        return y
    end
    function pool.Used()
        return used
    end
    pool.width = width
    return pool
end

local function SetTitle(text, withArrow)
    frame.arrow:SetShown(withArrow)
    frame.title:ClearAllPoints()
    frame.title:SetPoint("TOPLEFT", PAD + (withArrow and 14 or 0), -10)
    frame.title:SetPoint("RIGHT", frame.progressCount, "LEFT", -6, 0)
    frame.title:SetText(text)
end

local function LevelInfo(dungeon)
    local levels = dungeon.levels
    return table.concat({
        levels and ("|c%s%s %s|r"):format(ns.LevelColor(levels[1], levels[2]), L["Level"], ns.LevelRange(levels)) or nil,
        dungeon.kind == "raid" and L["Raid"] or L["Dungeon"],
    }, "  ·  ")
end

local function PlaceScroll(top)
    frame.scroll:Show()
    frame.scroll:ClearAllPoints()
    frame.scroll:SetPoint("TOPLEFT", PAD - 4, -top)
    frame.scroll:SetPoint("BOTTOMRIGHT", -PAD, 6)
end

local function FinishScroll(top, height)
    frame.scroll:SetContentHeight(height)
    frame.scroll.bar:SetShown(height > MAX_CONTENT_HEIGHT)
    frame:SetHeight(top + math.min(height, MAX_CONTENT_HEIGHT) + 6)
end

local function HideScroll(height)
    frame.scroll:Hide()
    frame.scroll.bar:Hide()
    frame:SetHeight(height)
end

-- 副本内：首领进度 + 任务状态
local function RefreshInside()
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
    SetTitle(ns.Name(dungeon.name) or "?", false)
    frame.info = LevelInfo(dungeon)
    frame.progressCount:SetText(("%s%d|r%s/%d|r"):format(killed == #bosses and #bosses > 0 and GREEN or TEXT,
        killed, MUTED, #bosses))
    DrawProgress(28, killed, #bosses)

    local collapsed = Settings().collapsed
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
        local boss = remaining[1]
        if boss then
            local row = frame.nextRow
            ResetRow(row)
            row.boss, row.killed = boss, false
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", PAD - 4, -top)
            row:SetPoint("RIGHT", -PAD, 0)
            SetMarker(row, "next")
            row.name:SetText(TEXT .. (ns.BossName(boss) or "?") .. "|r")
            row.tag:SetText(K.gold .. L["Next"] .. "|r")
            row:Show()
            top = top + ROW_HEIGHT
        end
        HideScroll(top + 6)
        return
    end
    PlaceScroll(top)

    local stack = frame.stack
    stack:Reset()
    local pool = RowPool()

    -- 首领：已击杀的合并成一行（悬停看是哪几个），还没打的逐行列出，第一个标“下一个”
    if #bosses == 0 then
        stack.y = pool.Y()
        stack:Text(L["No boss data for this instance yet."], "Muted", 0, 4)
        pool.Y(stack.y)
    end
    if killed > 0 then
        local row = pool.Row()
        row.killed, row.killedList = true, killedList
        SetMarker(row, "done")
        row.name:SetText(MUTED .. (L["Killed %d"]):format(killed) .. "|r")
        row.tag:SetText("")
    end
    for order, boss in ipairs(remaining) do
        local row = pool.Row()
        row.boss, row.killed = boss, false
        local name = ns.BossName(boss) or "?"
        if order == 1 then
            SetMarker(row, "next")
            row.name:SetText(TEXT .. name .. "|r")
            row.tag:SetText(K.gold .. L["Next"] .. "|r")
        else
            SetMarker(row, "open")
            row.name:SetText(DIM .. name .. "|r")
            row.tag:SetText("")
        end
    end

    -- 任务：标题行右侧写已完成与副本外待接的数量；没有已接任务时只有这一行
    local y = pool.Y() + 4
    frame.divider:ClearAllPoints()
    frame.divider:SetPoint("TOPLEFT", 0, -y)
    frame.divider:SetWidth(pool.width)
    frame.divider:Show()
    y = y + 4
    local header = K.gold .. L["Quests"] .. "|r" .. (#questRows > 0 and (MUTED .. " " .. #questRows .. "|r") or "")
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
    pool.Y(stack.y)
    for _, item in ipairs(questRows) do
        local row = pool.Row()
        row.questID, row.kind = item.id, item.kind
        SetMarker(row, item.kind == "complete" and "done" or (item.kind == "inside" and "next" or "active"))
        row.name:SetText(TEXT .. QuestName(item.id) .. "|r")
        row.tag:SetText(QuestTag(item))
    end
    stack.y = pool.Y() + 2
    FinishScroll(top, stack:Finish())
end

-- 副本外条目右侧：等级不够写等级；任务链写进度；再加状态符号
local function EntryTag(item)
    local tag = KIND_ICON[item.kind] or ""
    if item.kind == "low" then
        local quest = ns.Data.quests[item.nextStep or item.id] or {}
        tag = RED .. (L["Lv %d"]):format(quest.min or quest.level or 0) .. "|r " .. tag
    end
    if #item.chain > 1 then
        tag = (item.kind == "chain" and BLUE or MUTED) .. item.doneSteps .. "/" .. #item.chain .. "|r " .. tag
    end
    return tag
end

local STEP_ICON = { done = QUEST_ICON.done, active = QUEST_ICON.active, next = QUEST_ICON.inside, pending = MUTED .. "-|r" }
local STEP_COLOR = { done = "muted", active = "gold", next = "text", pending = "muted" }

-- 副本外：所选副本的任务（进本前先接 / 副本内接取），任务链可展开
local function RefreshOutside()
    DrawProgress(0, 0, 0)
    frame.section:Hide()
    frame.nextRow:Hide()
    frame.divider:Hide()
    if frame.questHover then
        frame.questHover:Hide()
    end
    local index = SelectedIndex()
    local dungeon = index and ns.Data.dungeons[index]
    if not dungeon then
        SetTitle(L["Dungeon quests"], false)
        frame.info = nil
        frame.progressCount:SetText("")
        HideScroll(OUTSIDE_TOP + 4)
        return
    end
    SetTitle(ns.Name(dungeon.name) or "?", true)
    frame.info = LevelInfo(dungeon)
    local groups, done = QuestGroups(dungeon)
    local open = #groups.outside + #groups.inside
    frame.progressCount:SetText((done > 0 and QUEST_ICON.done or "") .. MUTED .. done .. "/" .. (done + open) .. "|r")
    if menu and menu:IsShown() then
        FillMenu()
    end
    if Settings().collapsed then
        HideScroll(OUTSIDE_TOP + 4)
        return
    end
    PlaceScroll(OUTSIDE_TOP)
    frame.stack:Reset()
    local pool = RowPool()
    local sections = {
        { key = "outside", title = L["Pick up before you go"] },
        { key = "inside", title = L["Picked up inside the dungeon"] },
    }
    for headingIndex, section in ipairs(sections) do
        local items = groups[section.key]
        if #items > 0 then
            local heading = Heading(headingIndex, section.title, #items)
            heading:ClearAllPoints()
            heading:SetPoint("TOPLEFT", 0, -pool.Y())
            heading:SetWidth(pool.width)
            heading:Show()
            pool.Y(pool.Y() + ROW_HEIGHT)
            for _, item in ipairs(items) do
                local hasChain = #item.chain > 1
                local row = pool.Row(16)
                row.questID, row.item, row.trackID = item.id, item, item.nextStep or item.id
                row.toggle:SetShown(hasChain)
                row.toggle.text:SetText(expanded[item.id] and "-" or "+")
                local color = (item.kind == "low" or item.kind == "chain") and DIM or TEXT
                row.name:SetText(color .. ns.QuestTitle(item.id) .. "|r")
                row.tag:SetText(EntryTag(item))
                if hasChain and expanded[item.id] then
                    for stepIndex, stepID in ipairs(item.chain) do
                        local state = StepState(stepID, item.nextStep)
                        local step = pool.Row(26)
                        step.questID, step.item, step.isStep = stepID, item, true
                        step.name:SetText(("%s%d. %s|r"):format(K[STEP_COLOR[state]], stepIndex, ns.QuestTitle(stepID)))
                        step.tag:SetText(STEP_ICON[state])
                    end
                end
            end
            pool.Y(pool.Y() + 4)
        end
    end
    frame.empty:Hide()
    if pool.Used() == 0 then
        frame.empty:ClearAllPoints()
        frame.empty:SetPoint("TOPLEFT", 2, -2)
        frame.empty:SetText(done > 0 and L["All quests for this dungeon are done."]
            or L["No quests for your character in this dungeon."])
        frame.empty:Show()
        pool.Y(frame.empty:GetStringHeight() + 6)
    end
    FinishScroll(OUTSIDE_TOP, pool.Y())
end

function Refresh()
    if not (frame and frame:IsShown()) then
        return
    end
    frame.collapse:SetLabel(Settings().collapsed and "+" or "-")
    for _, heading in ipairs(frame.headings) do
        heading:Hide()
    end
    frame.empty:Hide()
    if current or test then
        if menu then
            menu:Hide()
        end
        RefreshInside()
    else
        RefreshOutside()
    end
end

local function Show()
    frame = frame or Create()
    RestorePosition()
    frame:Show()
    Refresh()
end

-- 按当前情况决定小窗显示与否：测试模式照常；副本里看“进本显示首领进度”与是否关过；副本外看“副本外显示任务小窗”
function Evaluate()
    if test then
        Show()
        return
    end
    local want
    if current then
        want = Settings().autoShow and dismissed ~= current.instanceID
    else
        want = Settings().shown
    end
    if want then
        Show()
    elseif frame then
        frame:Hide()
    end
end

-- 退出测试模式：回到真实的副本内或副本外小窗（各自设置允许时）
function ExitTest()
    test = nil
    Evaluate()
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
-- 事件
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

local QUEST_EVENTS = { "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "QUEST_DATA_LOAD_RESULT", "PLAYER_LEVEL_UP" }
local questEventsRegistered = false
function SetQuestEvents(active)
    if active == questEventsRegistered then
        return
    end
    questEventsRegistered = active
    for _, event in ipairs(QUEST_EVENTS) do
        if active then
            ns:RegisterEvent(event, OnQuestChange)
        else
            ns:UnregisterEvent(event, OnQuestChange)
        end
    end
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
    ns[method](ns, "UPDATE_INSTANCE_INFO", OnInstanceInfo)
end

local function UpdateInstance()
    local instanceID = CurrentInstanceID()
    local sections = instanceID and SectionsFor(instanceID) or {}
    if #sections == 0 then
        local wasInside = current ~= nil
        current, dismissed = nil, nil
        SetInstanceEvents(false)
        if wasInside or not (frame and frame:IsShown()) then
            Evaluate()
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
    -- 出本后副本外的小窗接着显示这个副本
    local dungeon = CurrentDungeon()
    if dungeon and Listable(dungeon) then
        CharState().dungeon = dungeon.slug
    end
    SetInstanceEvents(true)
    ApplyLockout()
    if RequestRaidInfo then
        RequestRaidInfo()
    end
    Evaluate()
end
Module.UpdateInstance = UpdateInstance -- 供测试使用

-- /wh quests、/wh instance：显示或隐藏。副本里只管这次副本；副本外改“副本外显示任务小窗”设置
local function Toggle()
    local visible = frame and frame:IsShown()
    if test then
        ExitTest()
        return
    end
    if current then
        dismissed = visible and current.instanceID or nil
    else
        Settings().shown = not visible
    end
    Evaluate()
end
Module.Toggle = Toggle -- 供测试使用

-- 设置里改了选项：立即按新设置显示或隐藏；测试直接调用 Module.Refresh() 时只刷新
function Module:Refresh()
    if self == Module then
        Evaluate()
    elseif frame and frame:IsShown() then
        Refresh()
    end
end

function Module:OnEnable()
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateInstance)
    ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", UpdateInstance)
    ns:AddCommand("quests", L["show or hide the dungeon helper"], Toggle)
    ns:AddCommand("instance", nil, Toggle) -- 旧命令名，保留为别名
    ns:AddCommand("test", L["preview the instance tracker with a sample dungeon"], ToggleTest)
    UpdateInstance()
end
