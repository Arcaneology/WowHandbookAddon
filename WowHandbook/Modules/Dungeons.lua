local ADDON_NAME, ns = ...
local L = ns.L

-- 副本手册（F1–F3），卡片式：
-- · 主页：上方“适合你的副本”（按玩家等级推荐 3 个大卡片），下方“全部副本”卡片网格（全部 / 副本 / 团队副本，可搜索）。
-- · 详情：返回按钮、副本名与等级、“在地图上显示入口”（设导航并打开游戏大地图）、网站攻略；三个标签——
--   任务（左侧按状态分组的任务列表，任务链可展开看每一步；右侧任务详情、接交地点与奖励）、
--   首领（按顺序，带各自掉落）、掉落（全部掉落按品质汇总）。
local Module = ns:NewModule("Dungeons")
local UI

local PAD = 20
local CONTENT_WIDTH = 762 - PAD * 2
local GAP = 12

local state = { kind = "all", search = "", selected = nil, tab = "quests" }
local Classify -- 任务分类，定义在“任务表”一节
local page

--------------------------------------------------------------------------------
-- 数据
--------------------------------------------------------------------------------

local function DungeonName(dungeon)
    local name = ns.Name(dungeon.name)
    if dungeon.aggregateOnly then
        return (L["Other quests for %s"]):format(name or L["Dungeon"])
    end
    return name
end

local function FactionOK(dungeon)
    local faction = ns.PlayerFaction()
    return not dungeon.faction or dungeon.faction == "both" or not faction
        or (dungeon.faction == "alliance" and faction == "A") or (dungeon.faction == "horde" and faction == "H")
end

-- 本阵营（或通用）的任务：总数、已完成数、现在可接或已接的数量。
-- 只来自其他插件、尚未在游戏里确认的任务（unverified）不计数，只在任务列表里列出。
local function QuestSummary(dungeon)
    local faction = ns.PlayerFaction()
    local total, done, available = 0, 0, 0
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = ns.Data.quests[questID]
        if quest and not quest.unverified and not (quest.faction and faction and quest.faction ~= faction) then
            total = total + 1
            local kind = Classify(questID)
            if kind == "done" then
                done = done + 1
            elseif kind == "ready" or kind == "active" then
                available = available + 1
            end
        end
    end
    return total, done, available
end

local function LootCount(dungeon)
    local n = 0
    for _, boss in ipairs(dungeon.bosses or {}) do
        n = n + #(boss.items or {})
    end
    return n
end

-- 推荐：等级区间覆盖玩家等级（前后各放宽 2 级）的副本，按离区间中点的距离排序，有可接任务的优先
-- 值得推荐：本阵营进得去、有掉落或任务数据（“数据待补”的新副本不推荐）；团本只在满级时推荐
local function Recommendable(dungeon)
    if dungeon.aggregateOnly or dungeon.dataPending or not FactionOK(dungeon) then
        return false
    end
    if LootCount(dungeon) == 0 and #(dungeon.quests or {}) == 0 then
        return false
    end
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 60
    return dungeon.kind ~= "raid" or ns.PlayerLevel() >= maxLevel
end

local function Recommended(count)
    local level = ns.PlayerLevel()
    local scored = {}
    for index, dungeon in ipairs(ns.Data.dungeons) do
        local levels = dungeon.levels
        if levels and Recommendable(dungeon)
            and level >= levels[1] - 2 and level <= levels[2] + 2 then
            local _, _, available = QuestSummary(dungeon)
            local distance = math.abs((levels[1] + levels[2]) / 2 - level)
            tinsert(scored, { index = index, score = distance - (available > 0 and 1 or 0) })
        end
    end
    table.sort(scored, function(a, b)
        return a.score < b.score
    end)
    local result = {}
    for i = 1, math.min(count, #scored) do
        tinsert(result, scored[i].index)
    end
    -- 等级超过全部副本时，推荐等级最高的几个
    if #result == 0 then
        for index = #ns.Data.dungeons, 1, -1 do
            if Recommendable(ns.Data.dungeons[index]) then
                tinsert(result, index)
            end
            if #result >= count then
                break
            end
        end
    end
    return result
end

local function CopyLink(kind, argument)
    ns.Links:ShowCopyDialog(ns.Links:Build(kind, argument))
end

--------------------------------------------------------------------------------
-- 卡片
--------------------------------------------------------------------------------

local function FillCard(card, index)
    local dungeon = ns.Data.dungeons[index]
    card.index = index
    local levels = dungeon.levels
    local color = levels and ns.LevelColor(levels[1], levels[2]) or "ff8a8374"
    card:SetAccentHex(color)
    card.name:SetText(DungeonName(dungeon))
    local meta = {}
    if levels then
        tinsert(meta, ("|c%s%s %s|r"):format(color, L["Level"], ns.LevelRange(levels)))
    end
    tinsert(meta, dungeon.kind == "raid" and L["Raid"] or L["Dungeon"])
    card.meta:SetText(table.concat(meta, "  ·  "))
    local total, done, available = QuestSummary(dungeon)
    local facts = {}
    if available > 0 then
        tinsert(facts, ("|cffe0b458%s|r"):format((L["%d to pick up"]):format(available)))
    end
    if total > 0 then
        tinsert(facts, (L["Quests %d/%d"]):format(done, total))
    end
    if dungeon.dataPending then
        tinsert(facts, L["Data coming soon"])
    elseif not dungeon.aggregateOnly then
        tinsert(facts, (L["%d bosses"]):format(#(dungeon.bosses or {})))
    end
    local loot = LootCount(dungeon)
    if loot > 0 then
        tinsert(facts, (L["%d items"]):format(loot))
    end
    card.facts:SetText("|cff8a8374" .. table.concat(facts, "  ·  ") .. "|r")
    if card.featured then
        local entrance = dungeon.entrance
        local where = entrance and entrance.map and (L["Entrance in %s"]):format(ns.MapName(entrance.map))
        card.where:SetText(where and ("|cff8a8374" .. where .. "|r") or "")
    end
    card:Show()
end

local function CreateCard(parent, featured)
    local card = UI:Card(parent)
    card.featured = featured and true or false
    card.name = UI:Text(card, featured and "Title" or "Heading")
    card.name:SetPoint("TOPLEFT", 14, -12)
    card.name:SetPoint("RIGHT", -10, 0)
    card.name:SetWordWrap(false)
    card.meta = UI:Text(card, "Small")
    card.meta:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -6)
    card.facts = UI:Text(card, "Small")
    card.facts:SetPoint("TOPLEFT", card.meta, "BOTTOMLEFT", 0, -6)
    card.facts:SetPoint("RIGHT", -10, 0)
    card.facts:SetWordWrap(false)
    if featured then
        card.where = UI:Text(card, "Small")
        card.where:SetPoint("BOTTOMLEFT", 14, 12)
        card.where:SetPoint("RIGHT", -10, 0)
        card.where:SetWordWrap(false)
    end
    card:SetScript("OnClick", function(self)
        Module:ShowDetail(self.index)
    end)
    return card
end

--------------------------------------------------------------------------------
-- 主页：推荐 + 全部
--------------------------------------------------------------------------------

local FEATURED, FEATURED_HEIGHT = 3, 112
local COLUMNS, CARD_HEIGHT = 3, 80

local function Matches(text, search)
    return search == "" or (text and text:lower():find(search, 1, true) ~= nil)
end

local function RefreshHome()
    local home = page.home
    local child = home.scroll.child
    local width = (CONTENT_WIDTH - GAP * (COLUMNS - 1)) / COLUMNS
    local y = 0

    home.featuredTitle:SetPoint("TOPLEFT", 0, -y)
    y = y + 26
    local featured = Recommended(FEATURED)
    for i = 1, FEATURED do
        local card = home.featured[i] or CreateCard(child, true)
        home.featured[i] = card
        if featured[i] then
            card:SetSize(width, FEATURED_HEIGHT)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", (i - 1) * (width + GAP), -y)
            FillCard(card, featured[i])
        else
            card:Hide()
        end
    end
    y = y + FEATURED_HEIGHT + 24

    home.allTitle:SetPoint("TOPLEFT", 0, -y)
    home.kinds:ClearAllPoints()
    home.kinds:SetPoint("TOPRIGHT", child, "TOPRIGHT", -170, -y + 3)
    home.search:ClearAllPoints()
    home.search:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y + 3)
    y = y + 34

    local search = state.search:lower()
    local shown = 0
    for index, dungeon in ipairs(ns.Data.dungeons) do
        local kindOK = state.kind == "all" or state.kind == dungeon.kind
        if kindOK and FactionOK(dungeon) and Matches(DungeonName(dungeon), search) then
            shown = shown + 1
            local card = home.cards[shown] or CreateCard(child, false)
            home.cards[shown] = card
            local column = (shown - 1) % COLUMNS
            local row = floor((shown - 1) / COLUMNS)
            card:SetSize(width, CARD_HEIGHT)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", column * (width + GAP), -(y + row * (CARD_HEIGHT + GAP)))
            FillCard(card, index)
        end
    end
    for i = shown + 1, #home.cards do
        home.cards[i]:Hide()
    end
    if shown == 0 then
        home.empty:SetPoint("TOPLEFT", 0, -y)
        home.empty:Show()
        y = y + 20
    else
        home.empty:Hide()
        y = y + math.ceil(shown / COLUMNS) * (CARD_HEIGHT + GAP)
    end
    home.scroll:SetContentHeight(y + 10)
end

local function CreateHome(parent)
    local home = CreateFrame("Frame", nil, parent)
    home:SetAllPoints()
    local title = UI:Text(home, "Title", L["Dungeon guide"])
    title:SetPoint("TOPLEFT", PAD, -18)
    local subtitle = UI:Text(home, "Muted", L["Level colors: gray too low, green easy, gold right for you, red too high."])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

    local scroll = UI:ScrollArea(home)
    scroll:SetPoint("TOPLEFT", PAD, -64)
    scroll:SetPoint("BOTTOMRIGHT", -PAD, 16)
    home.scroll = scroll
    local child = scroll.child
    home.featured, home.cards = {}, {}

    home.featuredTitle = UI:Text(child, "Heading", L["Best for your level"])
    home.allTitle = UI:Text(child, "Heading", L["All instances"])
    home.kinds = UI:Segmented(child, {
        { id = "all", label = L["All"] },
        { id = "dungeon", label = L["Dungeons"] },
        { id = "raid", label = L["Raids"] },
    }, function(kind)
        state.kind = kind
        RefreshHome()
    end, 80)
    home.kinds:Select(state.kind)
    home.search = UI:SearchBox(child, 150, L["Search"], function(text)
        state.search = text
        RefreshHome()
    end)
    home.empty = UI:Text(child, "Muted", L["No instances match."])
    return home
end

--------------------------------------------------------------------------------
-- 详情页
--------------------------------------------------------------------------------

local function PlaceText(source)
    if source.map then
        return ("%s %.1f, %.1f"):format(ns.MapName(source.map), source.x or 0, source.y or 0)
    end
    return L["inside the instance"]
end

--------------------------------------------------------------------------------
-- 任务表：每个副本任务归入一种情况，并给出去哪接 / 去哪交 / 任务链从哪继续
--------------------------------------------------------------------------------

-- 任务链：沿“前置”一路往上找，返回从最早一步到该任务的有序列表（不含重复，防止环）
local function ChainOf(questID)
    local order, seen = {}, {}
    local function Visit(id)
        if seen[id] then
            return
        end
        seen[id] = true
        local quest = ns.Data.quests[id]
        for _, before in ipairs(quest and quest.before or {}) do
            Visit(before)
        end
        tinsert(order, id)
    end
    Visit(questID)
    return order
end

-- 分类：active（已接）、ready（现在就能接）、chain（要先做任务链前面的步骤）、low（等级不够）、done（已完成）
-- 返回 类别, 任务链, 任务链上下一步（第一个没完成的步骤）, 任务链里已完成的步数
function Classify(questID)
    local status = ns.QuestStatus(questID)
    local chain = ChainOf(questID)
    local nextStep, doneSteps = nil, 0
    for _, id in ipairs(chain) do
        if ns.QuestStatus(id) == "done" then
            doneSteps = doneSteps + 1
        elseif not nextStep then
            nextStep = id
        end
    end
    if status == "done" then
        return "done", chain, nil, doneSteps
    elseif status == "active" then
        return "active", chain, questID, doneSteps
    elseif nextStep and nextStep ~= questID then
        return "chain", chain, nextStep, doneSteps
    elseif status == "low" then
        return "low", chain, questID, doneSteps
    end
    return "ready", chain, questID, doneSteps
end

-- tag：列表每行与详情页的状态标签
Module.Classify = Classify -- 供测试使用

local GROUPS = {
    { key = "active", tag = "Accepted", color = "ffe0b458" },
    { key = "ready", tag = "Ready to pick up", color = "fff4e8cc" },
    { key = "chain", tag = "Needs earlier quests", color = "ff6f95d6" },
    { key = "low", tag = "Level too low", color = "ffd8664a" },
    { key = "done", tag = "Completed", color = "ff46bf72" },
}

local function MarkButton(source, who, primary)
    if not (source and source.map and source.x) then
        return nil
    end
    return { label = L["Mark on map"], variant = primary and "primary" or nil, onClick = function()
        ns.Waypoints:Set(source.map, source.x, source.y, who)
    end }
end

-- 一行“去哪里做什么”：接任务或交任务
local function PlaceRow(stack, labelKey, source, primary)
    if not source then
        return
    end
    local who = ns.Name(source.name) or "?"
    if source.kind == "item" then
        who = (L["Item: %s"]):format(who)
    end
    stack:Row(("|cff8a8374%s|r %s  |cff8a8374%s|r"):format(L[labelKey], who, PlaceText(source)),
        { MarkButton(source, who, primary) }, "Small", 16)
end

local function IndexOf(list, value)
    for index, item in ipairs(list) do
        if item == value then
            return index
        end
    end
    return nil
end

local GROUP_BY_KEY = {}
for _, group in ipairs(GROUPS) do
    GROUP_BY_KEY[group.key] = group
end

-- 任务链上每一步的状态：done / active / next（下一步该做的）/ pending
local STEP_STYLE = {
    done = { "ff46bf72", "Completed" },
    active = { "ffe0b458", "Accepted" },
    next = { "ff6f95d6", "Next step" },
    pending = { "ff8a8374", "Not yet" },
}

local function StepState(id, nextStep)
    local status = ns.QuestStatus(id)
    if status == "done" then
        return "done"
    elseif status == "active" then
        return "active"
    elseif id == nextStep then
        return "next"
    end
    return "pending"
end

--------------------------------------------------------------------------------
-- 任务标签：左侧任务列表（按状态分组，任务链可展开），右侧任务详情与奖励
--------------------------------------------------------------------------------

local questState = { selected = nil, expanded = {} }
Module.questState = questState -- 供测试使用

-- 左侧列表的行：分组标题、任务、展开后的任务链步骤
-- 左侧列表：只列副本实际需要的任务（不分大类），按状态再按等级排序，每行带状态标签。
-- 分两段：副本外提前接的任务在上，分隔线下是进副本后才能接的任务。
-- 任务链只在最后一步（副本任务）上显示一次，点开展开整条链的每一步；
-- 作为别的副本任务前置步骤的副本任务不再单独成行，避免与展开的任务链重复。
local ORDER = {}
for index, group in ipairs(GROUPS) do
    ORDER[group.key] = index
end

local function QuestEntries(dungeon)
    local faction = ns.PlayerFaction()
    local list, others, info = {}, 0, {}
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = ns.Data.quests[questID]
        if quest and quest.faction and faction and quest.faction ~= faction then
            others = others + 1
        elseif quest and not info[questID] then
            local kind, chain, nextStep, doneSteps = Classify(questID)
            info[questID] = { kind = kind, chain = chain, nextStep = nextStep, doneSteps = doneSteps }
            tinsert(list, questID)
        end
    end
    -- 找出已包含在其他副本任务链里的前置步骤
    local covered = {}
    for _, questID in ipairs(list) do
        for _, stepID in ipairs(info[questID].chain) do
            if stepID ~= questID and info[stepID] then
                covered[stepID] = true
            end
        end
    end

    local rows = {}
    for _, questID in ipairs(list) do
        if not covered[questID] then
            tinsert(rows, questID)
        end
    end
    table.sort(rows, function(a, b)
        local ka, kb = ORDER[info[a].kind], ORDER[info[b].kind]
        if ka ~= kb then
            return ka < kb
        end
        -- 同一状态内按最低可接等级排序（没有时用任务等级）
        local qa, qb = ns.Data.quests[a], ns.Data.quests[b]
        local la, lb = qa.min or qa.level or 0, qb.min or qb.level or 0
        if la ~= lb then
            return la < lb
        end
        return a < b
    end)

    local entries = {}
    local function AddQuest(questID)
        local item = info[questID]
        local quest = ns.Data.quests[questID]
        local group = GROUP_BY_KEY[item.kind]
        local hasChain = #item.chain > 1
        local expanded = hasChain and questState.expanded[questID]
        local toggle = hasChain and (expanded and "|cffe0b458-|r " or "|cffe0b458+|r ") or "   "
        local tag = ("|c%s%s|r"):format(group.color, L[group.tag])
        if hasChain then
            tag = ("|cff8a8374%s %d/%d|r  "):format(L["Chain"], item.doneSteps, #item.chain) .. tag
        end
        tinsert(entries, {
            id = questID,
            text = ("%s|cff8a8374%s|r %s"):format(toggle, (quest.min or quest.level) and ("[" .. (quest.min or quest.level) .. "]") or "",
                ns.QuestTitle(questID)),
            tags = tag,
            chainOwner = hasChain and questID or nil,
        })
        if expanded then
            for index, stepID in ipairs(item.chain) do
                local style = STEP_STYLE[StepState(stepID, item.nextStep)]
                tinsert(entries, {
                    id = "step:" .. questID .. ":" .. stepID,
                    step = stepID,
                    text = ("      |cff8a8374%d.|r |c%s%s|r"):format(index, style[1], ns.QuestTitle(stepID)),
                    tags = ("|c%s%s|r"):format(style[1], L[style[2]]),
                })
            end
        end
    end

    -- 先列需要在副本外提前接好的任务，分隔线下面是进副本后才能接的（副本里的人给的、副本里拾取的物品开始的）
    local sections = {
        { key = "outside", title = L["Pick up before you go"] },
        { key = "inside", title = L["Picked up inside the dungeon"] },
    }
    for _, section in ipairs(sections) do
        local members = {}
        for _, questID in ipairs(rows) do
            local isInside = ns.Data.quests[questID].inside and "inside" or "outside"
            if isInside == section.key then
                tinsert(members, questID)
            end
        end
        if #members > 0 then
            tinsert(entries, { id = "section:" .. section.key, divider = true,
                text = ("|cffe0b458%s|r"):format(section.title), tags = ("|cff8a8374%d|r"):format(#members) })
            for _, questID in ipairs(members) do
                AddQuest(questID)
            end
        end
    end
    return entries, info, others
end
Module.QuestEntries = QuestEntries -- 供测试使用

local function RewardsSection(stack, rewards)
    if not rewards then
        stack:Text(L["No reward data yet."], "Muted", 0, 6)
        return
    end
    local line = {}
    if rewards.xp then
        tinsert(line, (L["%d XP"]):format(rewards.xp))
    end
    local money = ns.Money(rewards.money)
    if money then
        tinsert(line, money)
    end
    if #line > 0 then
        stack:Text(table.concat(line, "    "), "Body", 0, 6)
    end
    local function ItemIDs(list)
        local ids = {}
        for _, item in ipairs(list or {}) do
            tinsert(ids, item.id)
        end
        return ids
    end
    if rewards.items then
        stack:Text(L["You will receive:"], "Small", 0, 4)
        stack:Items(ItemIDs(rewards.items), 0, 34)
    end
    if rewards.choices then
        stack:Text(L["Choose one of:"], "Small", 0, 4)
        stack:Items(ItemIDs(rewards.choices), 0, 34)
    end
    -- 其他插件数据里多出来的奖励与后续任务的奖励（待核验的条目只进采集插件的清单，这里不标未验证）
    local possible, followUp = {}, {}
    for _, item in ipairs(rewards.referenceItems or {}) do
        tinsert(item.followUp and followUp or possible, item.id)
    end
    if #possible > 0 then
        stack:Text(L["Other possible rewards:"], "Small", 0, 4)
        stack:Items(possible, 0, 34)
    end
    if #followUp > 0 then
        stack:Text(L["Rewards from the follow-up quest:"], "Small", 0, 4)
        stack:Items(followUp, 0, 34)
    end
    for _, reputation in ipairs(rewards.reputation or {}) do
        stack:Text(("|cff8a8374%s|r %s +%d"):format(L["Reputation:"], ns.Name(reputation.name) or "?", reputation.value or 0),
            "Small", 0, 3)
    end
end

-- 右侧详情：questID 可以是副本任务，也可以是任务链上的步骤
local function RenderQuestDetail(view, questID, item)
    local stack = view.stack
    stack:Reset()
    local quest = questID and ns.Data.quests[questID]
    if not quest then
        stack:Text(L["Pick a quest on the left."], "Muted")
        view.scroll:SetContentHeight(stack:Finish())
        return
    end
    item = item or {}
    local kind = item.kind or Classify(questID)
    local group = GROUP_BY_KEY[kind]
    stack:Text(ns.QuestTitle(questID), "Title", 0, 4)

    -- 最低可接等级是给玩家的主要信息；任务等级（难度、经验）只作参考，放在后面并用暗色
    local meta = { ("|c%s%s|r"):format(group.color, L[group.tag]) }
    if quest.min then
        tinsert(meta, (L["Accept at level %d"]):format(quest.min))
    end
    if quest.level then
        tinsert(meta, "|cff8a8374" .. (L["Quest level %d"]):format(quest.level) .. "|r")
    end
    stack:Text(table.concat(meta, "  ·  "), "Small", 0, 8)

    -- 状态说明
    local chain = item.chain or select(2, Classify(questID))
    local nextStep = item.nextStep or select(3, Classify(questID))
    local doneSteps = item.doneSteps or select(4, Classify(questID))
    if kind == "chain" and nextStep then
        local stepIndex = IndexOf(chain, nextStep)
        local headline
        if ns.QuestStatus(nextStep) == "active" then
            headline = (L["You are on this chain: step %d, %s."]):format(stepIndex, ns.QuestTitle(nextStep))
        elseif doneSteps > 0 then
            headline = (L["Chain paused: continue with step %d, %s."]):format(stepIndex, ns.QuestTitle(nextStep))
        else
            headline = (L["Chain not started: begin with step 1, %s."]):format(ns.QuestTitle(nextStep))
        end
        stack:Text("|cff6f95d6" .. headline .. "|r", "Body", 0, 6)
        local step = ns.Data.quests[nextStep]
        if step and ns.QuestStatus(nextStep) == "active" then
            PlaceRow(stack, "Turn in:", step.finish or step.start, true)
        elseif step then
            PlaceRow(stack, "Pick up:", step.start, true)
        end
        stack:Spacer(4)
    elseif kind == "low" and quest.min then
        stack:Text(("|cffd8664a%s|r"):format((L["Available from level %d (you are %d)."]):format(quest.min, ns.PlayerLevel())),
            "Body", 0, 6)
    elseif kind == "done" then
        stack:Text("|cff46bf72" .. L["Done on this character."] .. "|r", "Body", 0, 6)
    end

    -- 目标
    local summary = quest.summary and ns.Name(quest.summary)
    if summary then
        stack:Heading(L["Objective"])
        stack:Text(summary, "Body", 0, 4)
        local objectives = quest.objectives and (quest.objectives[ns.locale] or quest.objectives.enUS)
        for _, objective in ipairs(objectives or {}) do
            stack:Text("- " .. objective, "Small", 8, 2)
        end
    end

    -- 接交任务
    stack:Heading(L["Where to go"])
    PlaceRow(stack, "Pick up:", quest.start, kind == "ready")
    if quest.finish and quest.finish.id ~= (quest.start and quest.start.id) then
        PlaceRow(stack, "Turn in:", quest.finish, kind == "active")
    end

    -- 任务链
    if #chain > 1 then
        stack:Heading((L["Quest chain (%d/%d)"]):format(doneSteps, #chain))
        for index, stepID in ipairs(chain) do
            local style = STEP_STYLE[StepState(stepID, nextStep)]
            local marker = stepID == questID and "  |cffe0b458<|r" or ""
            stack:Text(("|cff8a8374%d.|r |c%s%s|r  |c%s%s|r%s"):format(index, style[1], ns.QuestTitle(stepID),
                style[1], L[style[2]], marker), "Body", 0, 4)
        end
    end
    if #(quest.after or {}) > 0 then
        local names = {}
        for _, id in ipairs(quest.after) do
            tinsert(names, ns.QuestTitle(id))
        end
        stack:Text(("|cff8a8374%s|r %s"):format(L["Leads to:"], table.concat(names, ", ")), "Small", 0, 4)
    end

    -- 奖励
    stack:Heading(L["Rewards"])
    RewardsSection(stack, quest.rewards)

    view.scroll:SetContentHeight(stack:Finish())
end

local function RefreshQuestView(detail, dungeon)
    local view = detail.questView
    local entries, info, others = QuestEntries(dungeon)
    -- 默认选中第一个任务
    if not questState.selected or not (info[questState.selected] or ns.Data.quests[questState.selected]) then
        questState.selected = nil
        for _, entry in ipairs(entries) do
            if not entry.step and not entry.divider then
                questState.selected = entry.id
                break
            end
        end
    end
    local selectedRow = questState.selectedRow or questState.selected
    view.list:SetData(entries, selectedRow)
    local total = 0
    for _ in pairs(info) do
        total = total + 1
    end
    view.count:SetText(others > 0 and (L["%d quests · %d for the other faction"]):format(total, others)
        or (L["%d quests"]):format(total))
    view.info = info
    RenderQuestDetail(view, questState.selected, info[questState.selected])
end

local function CreateQuestView(parent)
    local view = CreateFrame("Frame", nil, parent)
    view:SetAllPoints()
    local listPanel = UI:Panel(view, "window", "lineSoft")
    listPanel:SetPoint("TOPLEFT", 8, -8)
    listPanel:SetPoint("BOTTOMLEFT", 8, 30)
    listPanel:SetWidth(330)
    view.list = UI:List(listPanel, 22, function(id)
        local entry
        for _, e in ipairs(view.list.data) do
            if e.id == id then
                entry = e
                break
            end
        end
        questState.selectedRow = id
        if entry and entry.step then
            questState.selected = entry.step
        else
            questState.selected = id
            -- 任务链：点一下展开 / 收起
            if entry and entry.chainOwner then
                questState.expanded[id] = not questState.expanded[id]
            end
        end
        view.scroll:ScrollToTop()
        RefreshQuestView(view.detail, view.dungeon)
    end)
    view.list:SetPoint("TOPLEFT", 1, -1)
    view.list:SetPoint("BOTTOMRIGHT", -1, 1)
    view.count = UI:Text(view, "Muted")
    view.count:SetPoint("TOPLEFT", listPanel, "BOTTOMLEFT", 2, -8)

    local scroll = UI:ScrollArea(view)
    scroll:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 18, -6)
    scroll:SetPoint("BOTTOMRIGHT", -18, 12)
    scroll.child:SetHyperlinksEnabled(true)
    scroll.child:SetScript("OnHyperlinkEnter", function(self, link)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    scroll.child:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    view.scroll = scroll
    view.stack = UI:Stack(scroll.child)
    view:Hide()
    return view
end

-- 掉落：首领与全部掉落合并为一页，按首领顺序分组，受上方筛选条控制（大类、护甲类型、职业）。
-- 职业默认是当前角色，只显示自己能用的物品。
local function LootFilter()
    if not state.loot then
        local _, classFile = UnitClass("player")
        state.loot = { class = classFile, category = "all", armor = "all" }
    end
    return state.loot
end

local function RenderLoot(detail, dungeon)
    local stack = detail.stack
    local bosses = dungeon.bosses or {}
    if LootCount(dungeon) == 0 then
        stack:Text(dungeon.dataPending and L["Data coming soon"] or L["No loot data yet."], "Muted")
        return
    end
    local filter = LootFilter()
    local shown = 0
    for order, boss in ipairs(bosses) do
        local items = {}
        for _, entry in ipairs(boss.items or {}) do
            local itemID = type(entry) == "table" and entry.id or entry
            if ns.ItemFilter.Matches(itemID, filter) then
                tinsert(items, entry)
            end
        end
        if #items > 0 then
            shown = shown + #items
            local level = boss.level and ("  |cff8a8374" .. (L["Level %s"]):format(tostring(boss.level)) .. "|r") or ""
            stack:Text(("|cff8a8374%d.|r  %s%s  |cff8a8374(%d)|r"):format(order, ns.BossName(boss) or "?", level, #items),
                "Heading", 0, 6)
            stack:Items(items, 18, 34)
            stack:Spacer(4)
        end
    end
    if shown == 0 then
        stack:Text(L["No items match these filters."], "Muted", 0, 8)
    end
    stack:Text(L["Hover an item for its stats; Shift-click to link it in chat."], "Muted")
end

-- 掉落页上方的筛选条
local function RefreshLootFilters(detail)
    local bar, filter = detail.lootFilters, LootFilter()
    bar.class:SetValue(filter.class or "all")
    bar.category:Select(filter.category)
    bar.armor:Select(filter.armor)
    bar.armor:SetShown(filter.category == "armor")
    bar:SetHeight(filter.category == "armor" and 62 or 32)
end

local function CreateLootFilters(panel, onChange)
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetPoint("TOPLEFT", 16, -12)
    bar:SetPoint("TOPRIGHT", -16, -12)
    bar:SetHeight(32)
    local filter = LootFilter()

    local classItems = { { id = "all", label = L["All classes"] } }
    for _, classFile in ipairs(ns.ItemFilter.CLASSES) do
        tinsert(classItems, { id = classFile, label = ns.ItemFilter.ClassName(classFile) })
    end
    bar.class = UI:Dropdown(bar, classItems, function(id)
        filter.class = id ~= "all" and id or nil
        onChange()
    end, 130)
    bar.class:SetPoint("TOPRIGHT", 0, 0)
    local classLabel = UI:Text(bar, "Small", L["Class"])
    classLabel:SetPoint("RIGHT", bar.class, "LEFT", -8, 0)

    bar.category = UI:Segmented(bar, ns.ItemFilter.CategoryItems(), function(id)
        filter.category = id
        onChange()
    end, 72)
    bar.category:SetPoint("TOPLEFT", 0, 0)

    bar.armor = UI:Segmented(bar, ns.ItemFilter.ArmorItems(), function(id)
        filter.armor = id
        onChange()
    end, 64)
    bar.armor:SetPoint("TOPLEFT", 0, -30)
    return bar
end

local RENDERERS = { loot = RenderLoot }

local function RefreshDetail()
    local detail = page.detail
    local dungeon = state.selected and ns.Data.dungeons[state.selected]
    if not dungeon then
        return
    end
    detail.title:SetText(DungeonName(dungeon))
    local meta = {}
    if dungeon.levels then
        tinsert(meta, ("|c%s%s %s|r"):format(ns.LevelColor(dungeon.levels[1], dungeon.levels[2]), L["Level"],
            ns.LevelRange(dungeon.levels)))
    end
    tinsert(meta, dungeon.kind == "raid" and L["Raid"] or L["Dungeon"])
    if dungeon.dataPending then
        tinsert(meta, L["Data coming soon"])
    end
    local total, done = QuestSummary(dungeon)
    if total > 0 then
        tinsert(meta, (L["Quests %d/%d"]):format(done, total))
    end
    local entrance = dungeon.entrance
    if entrance and entrance.map then
        tinsert(meta, (L["Entrance in %s"]):format(ns.MapName(entrance.map)))
    end
    detail.meta:SetText(table.concat(meta, "  ·  "))
    detail.markEntrance:SetShown(entrance and entrance.map and entrance.x and true or false)
    detail.tabs:SetLabel("quests", (L["Quests (%d)"]):format(total))
    detail.tabs:SetLabel("loot", (L["Loot (%d)"]):format(LootCount(dungeon)))
    detail.tabs:Select(state.tab)

    -- 任务标签用左右分栏视图，其他标签用滚动内容
    local questTab = state.tab == "quests"
    detail.questView:SetShown(questTab)
    detail.scroll:SetShown(not questTab)
    detail.lootFilters:SetShown(state.tab == "loot") -- 筛选条只属于掉落页
    if questTab then
        detail.questView.detail, detail.questView.dungeon = detail, dungeon
        RefreshQuestView(detail, dungeon)
        return
    end
    -- 掉落页顶部有筛选条，内容区从筛选条下方开始
    local lootTab = state.tab == "loot"
    detail.lootFilters:SetShown(lootTab)
    detail.scroll:ClearAllPoints()
    if lootTab then
        RefreshLootFilters(detail)
        detail.scroll:SetPoint("TOPLEFT", detail.lootFilters, "BOTTOMLEFT", 0, -10)
    else
        detail.scroll:SetPoint("TOPLEFT", 16, -14)
    end
    detail.scroll:SetPoint("BOTTOMRIGHT", -18, 14)
    detail.stack:Reset()
    RENDERERS[state.tab](detail, dungeon)
    detail.scroll:SetContentHeight(detail.stack:Finish())
end

local function CreateDetail(parent)
    local detail = CreateFrame("Frame", nil, parent)
    detail:SetAllPoints()

    local back = UI:Button(detail, "<  " .. L["All instances"], 130, 24, "ghost")
    back:SetPoint("TOPLEFT", PAD - 6, -14)
    back:SetScript("OnClick", function()
        Module:ShowHome()
    end)

    detail.title = UI:Text(detail, "Title")
    detail.title:SetPoint("TOPLEFT", PAD, -46)
    detail.meta = UI:Text(detail, "Small")
    detail.meta:SetPoint("TOPLEFT", detail.title, "BOTTOMLEFT", 0, -6)

    local guide = UI:Button(detail, L["Full guide on the website"], 170, 26)
    guide:SetPoint("TOPRIGHT", -PAD, -46)
    guide:SetScript("OnClick", function()
        local dungeon = ns.Data.dungeons[state.selected]
        CopyLink(dungeon.kind == "raid" and "raid" or "dungeon", dungeon.siteSlug or dungeon.slug)
    end)
    detail.markEntrance = UI:Button(detail, L["Show entrance on map"], 150, 26, "primary")
    detail.markEntrance:SetPoint("RIGHT", guide, "LEFT", -8, 0)
    detail.markEntrance:SetScript("OnClick", function()
        local dungeon = ns.Data.dungeons[state.selected]
        local entrance = dungeon.entrance
        ns.Waypoints:ShowOnMap(entrance.map, entrance.x, entrance.y, DungeonName(dungeon))
    end)

    detail.tabs = UI:Segmented(detail, {
        { id = "quests", label = L["Quests"] },
        { id = "loot", label = L["Loot"] },
    }, function(tab)
        state.tab = tab
        detail.scroll:ScrollToTop()
        RefreshDetail()
    end, 110)
    detail.tabs:SetPoint("TOPLEFT", PAD, -100)

    local panel = UI:Panel(detail, "panel", "lineSoft")
    panel:SetPoint("TOPLEFT", PAD, -134)
    panel:SetPoint("BOTTOMRIGHT", -PAD, 16)
    local scroll = UI:ScrollArea(panel)
    scroll:SetPoint("TOPLEFT", 16, -14)
    scroll:SetPoint("BOTTOMRIGHT", -18, 14)
    scroll.child:SetHyperlinksEnabled(true)
    scroll.child:SetScript("OnHyperlinkEnter", function(self, link)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    scroll.child:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    detail.scroll = scroll
    detail.stack = UI:Stack(scroll.child)
    detail.questView = CreateQuestView(panel)
    detail.lootFilters = CreateLootFilters(panel, function()
        detail.scroll:ScrollToTop()
        RefreshDetail()
    end)
    detail:Hide()
    return detail
end

--------------------------------------------------------------------------------
-- 页面
--------------------------------------------------------------------------------

local function Refresh()
    if not (page and page:IsShown()) then
        return
    end
    if page.detail:IsShown() then
        RefreshDetail()
    else
        RefreshHome()
    end
end

function Module:ShowHome()
    page.detail:Hide()
    page.home:Show()
    RefreshHome()
end

function Module:ShowDetail(index)
    state.selected = index
    page.home:Hide()
    page.detail:Show()
    page.detail.scroll:ScrollToTop()
    RefreshDetail()
end

local function CreatePage(parent)
    UI = ns.UI
    local p = CreateFrame("Frame", nil, parent)
    page = p
    Module.page = p -- 供测试使用
    p.home = CreateHome(p)
    p.detail = CreateDetail(p)
    p:SetScript("OnShow", Refresh)
    return p
end

-- 打开副本手册并显示指定副本（按 ns.Data.dungeons 的序号或 slug）；tab 可选 quests / loot（旧的 bosses 视同 loot）
function Module:Select(target, tab)
    for index, dungeon in ipairs(ns.Data.dungeons) do
        if index == target or dungeon.slug == target then
            ns.MainFrame:Open("dungeons")
            state.tab = (tab == "bosses" and "loot") or tab or state.tab
            self:ShowDetail(index)
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- 首页用的摘要
--------------------------------------------------------------------------------

local function DungeonIndexOf(slug)
    for index, dungeon in ipairs(ns.Data.dungeons) do
        if dungeon.slug == slug then
            return index
        end
    end
    return nil
end

-- 任务所属的副本：副本任务直接看 instances；任务链上的非副本步骤找包含它的副本任务链
local function DungeonOfQuest(questID)
    local quest = ns.Data.quests[questID]
    if quest and quest.instances then
        for _, parentSlug in ipairs(quest.instances) do
            for _, sectionSlug in ipairs(quest.sectionSlugs or {}) do
                local target = sectionSlug == "unassigned" and parentSlug or (parentSlug .. "-" .. sectionSlug)
                local index = DungeonIndexOf(target)
                if index then
                    return index
                end
            end
        end
        -- 老数据没有分区标记时，根据导出的任务归属寻找分区。
        for index, dungeon in ipairs(ns.Data.dungeons) do
            if IndexOf(dungeon.quests or {}, questID) then
                return index
            end
        end
        return DungeonIndexOf(quest.instances[1])
    end
    for index, dungeon in ipairs(ns.Data.dungeons) do
        for _, owner in ipairs(dungeon.quests or {}) do
            if IndexOf(ChainOf(owner), questID) then
                return index
            end
        end
    end
    return nil
end

-- 返回 {
--   recommended = { {index, name, levels, total, done, available} },
--   prep = { {quest = 任务ID, dungeon = 序号, step = 链上第几步或 nil, steps = 链长} }：推荐副本里现在就能在副本外接的任务
--          （任务链没开始或中断时给出该接的那一步），
--   active = { {quest, dungeon, complete} }：任务日志里的副本任务（含任务链步骤），
--   upcoming = { [等级] = { 副本名… } }：之后 levelsAhead 级以内开放的副本 }
function Module.Summary(recommendCount, levelsAhead)
    local summary = { recommended = {}, prep = {}, active = {}, upcoming = {} }
    local seen = {}
    for _, index in ipairs(Recommended(recommendCount or 3)) do
        local dungeon = ns.Data.dungeons[index]
        local total, done, available = QuestSummary(dungeon)
        local entry = { index = index, name = DungeonName(dungeon), levels = dungeon.levels,
            total = total, done = done, available = available, prep = 0 }
        tinsert(summary.recommended, entry)
        local faction = ns.PlayerFaction()
        for _, questID in ipairs(dungeon.quests or {}) do
            local quest = ns.Data.quests[questID]
            if quest and not quest.unverified and not (quest.faction and faction and quest.faction ~= faction) then
                local kind, chain, nextStep = Classify(questID)
                local target
                if kind == "ready" and not quest.inside then
                    target = questID
                elseif kind == "chain" and nextStep and ns.QuestStatus(nextStep) == "available" then
                    local step = ns.Data.quests[nextStep]
                    if step and not step.inside then
                        target = nextStep
                    end
                end
                if target and not seen[target] and not (ns.Data.quests[target] or {}).unverified then
                    seen[target] = true
                    entry.prep = entry.prep + 1
                    local stepIndex = #chain > 1 and IndexOf(chain, target) or nil
                    tinsert(summary.prep, { quest = target, dungeon = index, step = stepIndex, steps = #chain })
                end
            end
        end
    end
    for questID in pairs(ns.Data.quests) do
        if ns.QuestStatus(questID) == "active" then
            local index = DungeonOfQuest(questID)
            local complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) or false
            tinsert(summary.active, { quest = questID, dungeon = index, complete = complete and true or false })
        end
    end
    table.sort(summary.active, function(a, b)
        if a.complete ~= b.complete then
            return a.complete
        end
        return a.quest < b.quest
    end)
    local level = ns.PlayerLevel()
    for _, dungeon in ipairs(ns.Data.dungeons) do
        local first = dungeon.levels and dungeon.levels[1]
        if first and Recommendable(dungeon) and first > level and first <= level + (levelsAhead or 4) then
            summary.upcoming[first] = summary.upcoming[first] or {}
            tinsert(summary.upcoming[first], DungeonName(dungeon))
        end
    end
    return summary
end
Module.PlaceText = PlaceText

function Module:OnEnable()
    ns.MainFrame:RegisterTab({ id = "dungeons", title = L["Dungeon guide"], order = 10, create = CreatePage, onShow = Refresh })
    -- 任务进度、等级变化、物品与任务数据到达时刷新（节流 0.5 秒；页面没打开时不做任何事）
    local pending = false
    local function OnChange()
        if pending or not (page and page:IsShown()) then
            return
        end
        pending = true
        C_Timer.After(0.5, function()
            pending = false
            Refresh()
        end)
    end
    ns:RegisterEvent("QUEST_LOG_UPDATE", OnChange)
    ns:RegisterEvent("PLAYER_LEVEL_UP", OnChange)
    ns:RegisterEvent("QUEST_TURNED_IN", OnChange)
    ns:RegisterEvent("GET_ITEM_INFO_RECEIVED", OnChange)
    ns:RegisterEvent("QUEST_DATA_LOAD_RESULT", OnChange)
end
