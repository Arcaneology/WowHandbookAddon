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

local state = { search = "", selected = nil, tab = "quests" }
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

local function QuestClassOK(quest)
    return not quest.classRestriction or quest.classRestriction:lower() == ns.PlayerClass()
end

local function QuestClassLabel(quest)
    if quest.classRestriction == "PALADIN" then
        return L["Paladin class quest"]
    end
end

-- 本阵营（或通用）的任务：总数、已完成数、现在可接（还没接）的数量、已接未交的数量，
-- 以及只属于对方阵营的任务数（如部落角色看死亡矿井、监狱：任务全是联盟的，卡片要说明而不是写“暂无”）。
-- 额外与外部关联任务不计普通副本统计，职业任务只展示给对应职业。
-- 只数最终的副本任务：已是别的副本任务的任务链前置步骤的不单独计数（与任务列表的合并规则一致）。
-- 一条链上：最终任务已完成算完成；链上正做着的一步（或最终任务本身）已接算进行中；链上下一步现在能接算可接。
local function QuestSummary(dungeon)
    local faction = ns.PlayerFaction()
    local total, done, ready, active, others = 0, 0, 0, 0, 0
    local own, info = {}, {}
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = ns.Data.quests[questID]
        local counted = quest and not quest.extra and not quest.relatedExternal and QuestClassOK(quest)
        if counted and quest.faction and faction and quest.faction ~= faction then
            others = others + 1
        elseif counted and not info[questID] then
            local kind, chain, nextStep = Classify(questID)
            info[questID] = { kind = kind, chain = chain, nextStep = nextStep }
            tinsert(own, questID)
        end
    end
    local covered = {}
    for _, questID in ipairs(own) do
        for _, stepID in ipairs(info[questID].chain) do
            if stepID ~= questID and info[stepID] then
                covered[stepID] = true
            end
        end
    end
    for _, questID in ipairs(own) do
        if not covered[questID] then
            total = total + 1
            local item = info[questID]
            local stepStatus = item.kind == "chain" and item.nextStep and ns.QuestStatus(item.nextStep)
            if item.kind == "done" then
                done = done + 1
            elseif item.kind == "active" or stepStatus == "active" then
                active = active + 1
            elseif item.kind == "ready" or stepStatus == "available" then
                ready = ready + 1
            end
        end
    end
    return total, done, ready, active, others
end
Module.QuestSummary = QuestSummary -- 供测试使用

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
            local _, _, ready, active = QuestSummary(dungeon)
            local available = ready + active -- 还有任务可接或在做，推荐时优先
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
    -- 等级超过全部副本时才推荐等级最高的几个；低于最低门槛或落在断档里时不推荐，
    -- 首页另有“接下来开放”的副本
    local highest = 0
    for _, dungeon in ipairs(ns.Data.dungeons) do
        if dungeon.levels and Recommendable(dungeon) then
            highest = math.max(highest, dungeon.levels[2])
        end
    end
    if #result == 0 and level > highest + 2 then
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

--------------------------------------------------------------------------------
-- 卡片
--------------------------------------------------------------------------------

local FACTION_EMBLEMS = {
    alliance = "Interface\\AddOns\\WowHandbook\\Media\\FactionAlliance",
    horde = "Interface\\AddOns\\WowHandbook\\Media\\FactionHorde",
}
local WATERMARK_ALPHA, WATERMARK_HOVER_ALPHA = 0.13, 0.24

-- 副本所在的阵营地盘（与网站一致）：副本本身只对一方开放时取该方，否则看入口所在区域；都不是时为争夺地区
local function Territory(index)
    local dungeon = ns.Data.dungeons[index]
    local faction = dungeon.faction and dungeon.faction:lower()
    if faction == "alliance" or faction == "horde" then
        return faction
    end
    local mapID = (dungeon.entrance and dungeon.entrance.map) or ns.DungeonEntrance(index)
    local zone = mapID and ns.Data.zones[mapID]
    if zone and (zone.faction == "alliance" or zone.faction == "horde") then
        return zone.faction
    end
    return "contested"
end
Module.Territory = Territory -- 供测试使用

-- 适合玩家现在去的副本：与推荐同一标准（等级区间前后放宽 2 级，本阵营进得去，有数据，团本满级才算）
local function Suitable(dungeon)
    local levels = dungeon.levels
    if not levels or dungeon.aggregateOnly or dungeon.dataPending or not Recommendable(dungeon) then
        return false
    end
    local level = ns.PlayerLevel()
    return level >= levels[1] - 2 and level <= levels[2] + 2
end
Module.Suitable = Suitable -- 供测试使用

-- 卡片上用图标代替文字：任务沿用游戏的任务标记，首领骷髅，掉落背包，入口地图；完整说明在悬停提示里
local function Icon(path, crop)
    return ("|T%s:13:13:0:0%s|t"):format(path, crop and ":64:64:5:59:5:59" or "")
end
local CARD_ICON = {
    ready = Icon("Interface\\GossipFrame\\AvailableQuestIcon"),
    active = Icon("Interface\\GossipFrame\\ActiveQuestIcon"),
    done = Icon("Interface\\RaidFrame\\ReadyCheck-Ready"),
    boss = Icon("Interface\\TargetingFrame\\UI-TargetingFrame-Skull"),
    loot = Icon("Interface\\Icons\\INV_Misc_Bag_08", true),
    entrance = Icon("Interface\\Icons\\INV_Misc_Map_01", true),
}
Module.CARD_ICON = CARD_ICON -- 供测试使用

-- 卡片上任务的状态符号：还有没接的任务用黄 !；都接了但没做完用黄 ?；全部完成才用绿勾
function Module.QuestBadge(total, done, active)
    if done >= total then
        return CARD_ICON.done
    elseif done + active >= total then
        return CARD_ICON.active
    end
    return CARD_ICON.ready
end

-- 悬停提示：卡片上省掉的文字都在这里
local function CardTooltip(card)
    local dungeon = ns.Data.dungeons[card.index]
    GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
    GameTooltip:SetText(DungeonName(dungeon), 1, 0.82, 0)
    local levels = dungeon.levels
    local kind = dungeon.kind == "raid" and L["Raid"] or L["Dungeon"]
    GameTooltip:AddLine(levels and ("%s %s  ·  %s"):format(L["Level"], ns.LevelRange(levels), kind) or kind, 0.85, 0.8, 0.69)
    local total, done, ready, active, others = QuestSummary(dungeon)
    if ready > 0 then
        GameTooltip:AddLine(CARD_ICON.ready .. " " .. (L["%d to pick up"]):format(ready), 1, 1, 1)
    end
    if active > 0 then
        GameTooltip:AddLine(CARD_ICON.active .. " " .. (L["%d in progress"]):format(active), 1, 1, 1)
    end
    if total > 0 then
        GameTooltip:AddLine(CARD_ICON.done .. " " .. (L["Quests %d/%d"]):format(done, total), 1, 1, 1)
    elseif others > 0 then
        GameTooltip:AddLine((L["%d quests for the other faction"]):format(others), 0.54, 0.51, 0.45)
    else
        GameTooltip:AddLine(L["No dungeon quests"], 0.54, 0.51, 0.45)
    end
    if dungeon.dataPending then
        GameTooltip:AddLine(L["Data coming soon"], 0.54, 0.51, 0.45)
    elseif not dungeon.aggregateOnly then
        GameTooltip:AddLine(CARD_ICON.boss .. " " .. (L["%d bosses"]):format(ns.BossCount(dungeon)), 1, 1, 1)
    end
    local loot = LootCount(dungeon)
    if loot > 0 then
        GameTooltip:AddLine(CARD_ICON.loot .. " " .. (L["%d items"]):format(loot), 1, 1, 1)
    end
    local mapID = ns.DungeonEntrance(card.index) or (dungeon.entrance and dungeon.entrance.map)
    if mapID then
        GameTooltip:AddLine(CARD_ICON.entrance .. " " .. (L["Entrance in %s"]):format(ns.MapName(mapID)), 1, 1, 1)
    end
    GameTooltip:Show()
end

local function FillCard(card, index)
    local dungeon = ns.Data.dungeons[index]
    card.index = index
    local levels = dungeon.levels
    local color = levels and ns.LevelColor(levels[1], levels[2]) or "ff8a8374"

    -- 阵营：左侧色条与右上角水印（网站同款徽章），争夺地区不画水印
    local territory = Territory(index)
    card.territory = territory
    card:SetAccentHex(territory == "alliance" and ns.Theme.hex.blue or (territory == "horde" and ns.Theme.hex.red
        or ns.Theme.hex.muted))
    local emblem = FACTION_EMBLEMS[territory]
    card.watermark:SetShown(emblem ~= nil)
    if emblem then
        card.watermark:SetTexture(emblem)
        card.watermark:SetAlpha(WATERMARK_ALPHA)
    end

    -- 三行布局：
    --   第一行  副本名 ........................ 等级区间（按等级着色）
    --   第二行  任务标记与数字 · 首领 · 掉落（全是图标加数字）
    --   底行    入口区域 ...................... “适合你”或“团本”
    -- 对方阵营的任务、没有任务等说明只在悬停提示里写，卡片上不占位置
    local suitable = Suitable(dungeon)
    card:SetHighlighted(suitable)
    card.name:SetText(DungeonName(dungeon))
    card.meta:SetText(levels and ("|c%s%s|r"):format(color, ns.LevelRange(levels)) or "")

    -- 任务：一个状态符号加“已完成/总数”。还有没接的任务用黄 !；都接了但没做完用黄 ?；全部完成才用绿勾
    local total, done, _, active = QuestSummary(dungeon)
    local stats = {}
    if total > 0 then
        tinsert(stats, Module.QuestBadge(total, done, active) .. ("|cffd9ccb0%d/%d|r"):format(done, total))
    end
    if dungeon.dataPending then
        tinsert(stats, "|cff8a8374" .. L["Data coming soon"] .. "|r")
    elseif not dungeon.aggregateOnly then
        tinsert(stats, CARD_ICON.boss .. "|cffd9ccb0" .. ns.BossCount(dungeon) .. "|r")
    end
    local loot = LootCount(dungeon)
    if loot > 0 then
        tinsert(stats, CARD_ICON.loot .. "|cffd9ccb0" .. loot .. "|r")
    end
    if #stats == 0 then
        tinsert(stats, "|cff8a8374" .. L["Data coming soon"] .. "|r")
    end
    card.quests:SetText(table.concat(stats, "    "))

    local mapID = ns.DungeonEntrance(index) or (dungeon.entrance and dungeon.entrance.map)
    card.where:SetText(mapID and (CARD_ICON.entrance .. " |cff8a8374" .. ns.MapName(mapID) .. "|r") or "")
    if suitable then
        card.badge:SetText(L["Right for you"])
    elseif dungeon.kind == "raid" then
        card.badge:SetText("|cff8a8374" .. L["Raid"] .. "|r")
    end
    card.badge:SetShown(suitable or dungeon.kind == "raid")
    card:Show()
end

local function CreateCard(parent)
    local card = UI:Card(parent)
    card.watermark = card:CreateTexture(nil, "BACKGROUND", nil, 1)
    card.watermark:SetSize(96, 96)
    card.watermark:SetPoint("TOPRIGHT", -8, -8)
    card.watermark:SetRotation(math.rad(-6))
    card.onHover = function(self, hovered)
        -- 悬停时水印更清楚、转正一点，与网站一致
        self.watermark:SetAlpha(hovered and WATERMARK_HOVER_ALPHA or WATERMARK_ALPHA)
        self.watermark:SetRotation(math.rad(hovered and -2 or -6))
        if hovered then
            CardTooltip(self)
        elseif GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end
    -- 第一行：副本名（左）与等级区间（右）
    card.meta = UI:Text(card, "Body")
    card.meta:SetPoint("TOPRIGHT", -12, -13)
    card.meta:SetJustifyH("RIGHT")
    card.name = UI:Text(card, "Heading")
    card.name:SetPoint("TOPLEFT", 16, -13)
    card.name:SetPoint("RIGHT", card.meta, "LEFT", -8, 0)
    card.name:SetWordWrap(false)
    -- 第二行：图标加数字
    card.quests = UI:Text(card, "Small")
    card.quests:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -9)
    card.quests:SetPoint("RIGHT", -12, 0)
    card.quests:SetWordWrap(false)
    -- 底行：入口区域（左）与“适合你”或“团本”（右）
    card.badge = UI:Text(card, "Accent")
    card.badge:SetPoint("BOTTOMRIGHT", -12, 11)
    card.badge:SetJustifyH("RIGHT")
    card.where = UI:Text(card, "Small")
    card.where:SetPoint("BOTTOMLEFT", 16, 11)
    card.where:SetPoint("RIGHT", card.badge, "LEFT", -8, 0)
    card.where:SetWordWrap(false)
    card:SetScript("OnClick", function(self)
        Module:ShowDetail(self.index)
    end)
    return card
end

--------------------------------------------------------------------------------
-- 主页：一张网格列出全部副本，适合你等级的高亮
--------------------------------------------------------------------------------

local COLUMNS, CARD_HEIGHT = 3, 84

local function Matches(text, search)
    return search == "" or (text and text:lower():find(search, 1, true) ~= nil)
end

local function RefreshHome()
    local home = page.home
    local child = home.scroll.child
    local width = (CONTENT_WIDTH - GAP * (COLUMNS - 1)) / COLUMNS

    local search = state.search:lower()
    local shown, firstSuitableRow = 0, nil
    for index, dungeon in ipairs(ns.Data.dungeons) do
        -- 副本手册列出全部副本（对方阵营的也列出，卡片上有阵营色条与水印）；只有推荐才按阵营筛选
        if Matches(DungeonName(dungeon), search) then
            shown = shown + 1
            local card = home.cards[shown] or CreateCard(child)
            home.cards[shown] = card
            local column = (shown - 1) % COLUMNS
            local row = floor((shown - 1) / COLUMNS)
            card:SetSize(width, CARD_HEIGHT)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", column * (width + GAP), -(row * (CARD_HEIGHT + GAP)))
            FillCard(card, index)
            if not firstSuitableRow and Suitable(dungeon) then
                firstSuitableRow = row
            end
        end
    end
    for i = shown + 1, #home.cards do
        home.cards[i]:Hide()
    end
    local height
    if shown == 0 then
        home.empty:SetPoint("TOPLEFT", 0, 0)
        home.empty:Show()
        height = 20
    else
        home.empty:Hide()
        height = math.ceil(shown / COLUMNS) * (CARD_HEIGHT + GAP)
    end
    home.scroll:SetContentHeight(height + 10)
    -- 第一次打开时滚到第一张“适合你”的卡片，不用自己往下找
    if not state.homeScrolled and firstSuitableRow then
        state.homeScrolled = true
        home.scroll:SetVerticalScroll(math.min(firstSuitableRow * (CARD_HEIGHT + GAP), home.scroll:MaxScroll()))
        home.scroll:UpdateBar()
    end
    Module.homeFirstSuitableRow = firstSuitableRow -- 供测试使用
end

local function CreateHome(parent)
    local home = CreateFrame("Frame", nil, parent)
    home:SetAllPoints()
    local title = UI:Text(home, "Title", L["Dungeon guide"])
    title:SetPoint("TOPLEFT", PAD, -18)
    local subtitle = UI:Text(home, "Muted", L["Gold cards are right for your level. Hover a card for details."])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

    home.search = UI:SearchBox(home, 150, L["Search"], function(text)
        state.search = text
        RefreshHome()
    end)
    home.search:SetPoint("TOPRIGHT", -PAD, -18)

    local scroll = UI:ScrollArea(home)
    scroll:SetPoint("TOPLEFT", PAD, -70)
    scroll:SetPoint("BOTTOMRIGHT", -PAD, 16)
    home.scroll = scroll
    home.cards = {}
    home.empty = UI:Text(scroll.child, "Muted", L["No instances match."])
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
-- 列表里的状态符号：游戏自带的任务标记，玩家一眼能懂，比文字省地方（任务名长时不再和右侧叠字）。
-- 黄色 ! 可接，? 已接，红色 ! 等级不够，绿勾 已完成；需要先做前置的直接显示任务链进度。
local STATUS_ICON = {
    ready = "|TInterface\\GossipFrame\\AvailableQuestIcon:14:14|t",
    active = "|TInterface\\GossipFrame\\ActiveQuestIcon:14:14|t",
    low = "|TInterface\\GossipFrame\\AvailableQuestIcon:14:14:0:0:16:16:0:16:0:16:216:102:74|t",
    done = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t",
}
Module.STATUS_ICON = STATUS_ICON -- 供测试使用

local STEP_STYLE = {
    done = { "ff46bf72", "Completed", STATUS_ICON.done },
    active = { "ffe0b458", "Accepted", STATUS_ICON.active },
    next = { "ff6f95d6", "Next step", STATUS_ICON.ready },
    pending = { "ff8a8374", "Not yet", "|cff8a8374-|r" },
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
        elseif quest and QuestClassOK(quest) and not info[questID] then
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
        -- 右侧：任务链进度（4/10）与状态符号；需要先做前置时只显示进度（蓝色）
        local tag = STATUS_ICON[item.kind] or ""
        if hasChain then
            local color = item.kind == "chain" and "ff6f95d6" or "ff8a8374"
            tag = ("|c%s%d/%d|r"):format(color, item.doneSteps, #item.chain) .. (tag ~= "" and (" " .. tag) or "")
        end
        local classLabel = QuestClassLabel(quest)
        if classLabel then
            tag = classLabel .. "  " .. tag
        end
        local levelText = (quest.min or quest.level) and ("[" .. (quest.min or quest.level) .. "]") or ""
        local ownerEntry = {
            id = questID,
            text = ("%s|cff8a8374%s|r %s"):format(toggle, levelText, ns.QuestTitle(questID)),
            tags = tag,
            status = group.key,
            chainOwner = hasChain and questID or nil,
        }
        tinsert(entries, ownerEntry)
        if not expanded then
            return
        end
        -- 展开：副本任务这一行仍在最上面作标题，下面按顺序列出整条任务链，最后一步就是副本任务本身
        for index, stepID in ipairs(item.chain) do
            local style = STEP_STYLE[StepState(stepID, item.nextStep)]
            tinsert(entries, {
                id = "step:" .. questID .. ":" .. stepID,
                step = stepID,
                text = ("      |cff8a8374%d.|r |c%s%s|r"):format(index, style[1], ns.QuestTitle(stepID)),
                tags = style[3],
            })
        end
    end

    -- 先列需要在副本外提前接好的任务，分隔线下面是进副本后才能接的（副本里的人给的、副本里拾取的物品开始的）
    local sections = {
        { key = "outside", title = L["Pick up before you go"] },
        { key = "inside", title = L["Picked up inside the dungeon"] },
        { key = "external", title = L["Related external quests"] },
    }
    for _, section in ipairs(sections) do
        local members = {}
        for _, questID in ipairs(rows) do
            local quest = ns.Data.quests[questID]
            local isInside = quest.relatedExternal and "external" or (quest.inside and "inside" or "outside")
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
    -- 其他可能的奖励与后续任务的奖励
    local possible, followUp = {}, {}
    for _, item in ipairs(rewards.extraItems or {}) do
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
    local classLabel = QuestClassLabel(quest)
    if classLabel then tinsert(meta, classLabel) end
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
        if quest.newInForeverChain then
            for _, id in ipairs(quest.after) do
                local followup = ns.Data.quests[id]
                if followup then
                    local note = ns.Name(followup.summary)
                    if note and note ~= "" then stack:Text(note, "Body", 0, 4) end
                    if followup.start then PlaceRow(stack, "Pick up:", followup.start, false) end
                end
            end
        end
    end

    -- 奖励
    stack:Heading(L["Rewards"])
    RewardsSection(stack, quest.rewards)

    view.scroll:SetContentHeight(stack:Finish())
end

local function InScope(info, questID)
    if info[questID] then
        return true
    end
    for _, item in pairs(info) do
        if IndexOf(item.chain, questID) then
            return true
        end
    end
    return false
end

local function RefreshQuestView(detail, dungeon)
    local view = detail.questView
    local entries, info, others = QuestEntries(dungeon)
    -- 选中的任务必须属于当前副本（副本任务或其任务链上的步骤），否则选中第一个任务；
    -- 首页跳转时预先指定的任务只要属于本副本就保留
    if not (questState.selected and InScope(info, questState.selected)) then
        questState.selected = nil
        questState.selectedRow = nil
        for _, entry in ipairs(entries) do
            if not entry.step and not entry.divider then
                questState.selected = entry.id
                break
            end
        end
    end
    local selectedRow = questState.selectedRow or questState.selected
    local rowFound = false
    for _, entry in ipairs(entries) do
        if entry.id == selectedRow then
            rowFound = true
            break
        end
    end
    if not rowFound then
        selectedRow = questState.selected
        questState.selectedRow = nil
    end
    view.list:SetData(entries, selectedRow)
    -- 只数列表里的任务行（最终的副本任务），任务链前置步骤与展开的步骤不算
    local total = 0
    for _, entry in ipairs(entries) do
        if type(entry.id) == "number" and not entry.step and not entry.divider then
            total = total + 1
        end
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
    listPanel:SetPoint("BOTTOMLEFT", 8, 46)
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
    -- 图例：列表右侧的状态符号
    view.legend = UI:Text(view, "Muted", ("%s %s   %s %s   %s %s   %s %s   |cff6f95d63/10|r %s"):format(
        STATUS_ICON.ready, L["Can pick up"], STATUS_ICON.active, L["Accepted"], STATUS_ICON.low, L["Too low"],
        STATUS_ICON.done, L["Done"], L["Chain"]))
    view.legend:SetPoint("TOPLEFT", view.count, "BOTTOMLEFT", 0, -4)

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
    stack:Text(L["Hover: stats · Shift-click: link"], "Muted")
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
    local entranceMap = ns.DungeonEntrance(state.selected) or (dungeon.entrance and dungeon.entrance.map)
    if entranceMap then
        tinsert(meta, (L["Entrance in %s"]):format(ns.MapName(entranceMap)))
    end
    detail.meta:SetText(table.concat(meta, "  ·  "))
    detail.markEntrance:SetShown(ns.DungeonEntrance(state.selected) and true or false)
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

    -- 返回按钮用有边框的普通样式（ghost 没有边框，看不出是按钮）
    local back = UI:Button(detail, "<  " .. L["All instances"], 130, 24)
    back:SetPoint("TOPLEFT", PAD - 6, -14)
    back:SetScript("OnClick", function()
        Module:ShowHome()
    end)

    detail.title = UI:Text(detail, "Title")
    detail.title:SetPoint("TOPLEFT", PAD, -46)
    detail.meta = UI:Text(detail, "Small")
    detail.meta:SetPoint("TOPLEFT", detail.title, "BOTTOMLEFT", 0, -6)

    -- 副本页不放网站链接，右上角是入口标记
    detail.markEntrance = UI:Button(detail, L["Show entrance on map"], 170, 26, "primary")
    detail.markEntrance:SetPoint("TOPRIGHT", -PAD, -46)
    detail.markEntrance:SetScript("OnClick", function()
        local mapID, x, y = ns.DungeonEntrance(state.selected)
        if mapID then
            ns.Waypoints:ShowOnMap(mapID, x, y, DungeonName(ns.Data.dungeons[state.selected]))
        end
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
    if not (page and page:IsVisible()) then
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
            -- 先记下目标副本再打开窗口：打开时页面的 OnShow 刷新就已属于目标副本，
            -- 不会先按上一个副本刷新而丢掉首页预先指定的任务
            state.selected = index
            state.tab = (tab == "bosses" and "loot") or tab or state.tab
            ns.MainFrame:Open("dungeons")
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
        local total, done, ready, active = QuestSummary(dungeon)
        local available = ready + active
        local entry = { index = index, name = DungeonName(dungeon), levels = dungeon.levels,
            total = total, done = done, available = available, prep = 0 }
        tinsert(summary.recommended, entry)
        local faction = ns.PlayerFaction()
        for _, questID in ipairs(dungeon.quests or {}) do
            local quest = ns.Data.quests[questID]
            if quest and not quest.extra and not quest.relatedExternal and QuestClassOK(quest)
            and not (quest.faction and faction and quest.faction ~= faction) then
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
                if target and not seen[target] and not (ns.Data.quests[target] or {}).extra then
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
        if pending or not (page and page:IsVisible()) then
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
    ns.OnItemLoaded(OnChange)
    ns:RegisterEvent("QUEST_DATA_LOAD_RESULT", OnChange)
end
