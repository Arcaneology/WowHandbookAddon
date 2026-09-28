local ADDON_NAME, ns = ...
local L = ns.L
local Theme, UI = ns.Theme, ns.UI

-- 首页：面向升级玩家的“今日面板”，打开就知道现在该去哪、回城该做什么。
-- · 顶部一行：职业、等级与经验进度
-- · 第一行“现在去哪”：适合练级的区域、适合你等级的副本（带进本前可先接的任务数）
-- · 第二行“回城要做”：可以训练的技能；副本任务（日志里有副本任务时列出，可交的在前；没有时列出进本前先接）
-- · 底部网站区：推荐副本在网站上的完整攻略（条目级复制链接）
-- 数据来自各功能模块的 Summary() 与区域数据；模块被关闭时对应卡片提示去设置里打开。
local MainFrame = ns.MainFrame

local PAD = 28
local CARD_WIDTH, CARD_HEIGHT, GAP = 347, 204, 12
local CARDS_TOP = -50
local LINE_HEIGHT, MAX_LINES = 22, 6
local LEVELS_AHEAD = 4

local page
local Refresh
local Home = {}
ns.Home = Home -- 供测试使用

local function EnabledModule(name)
    local module = ns.modules[name]
    if module and ns:GetModuleSettings(module).enabled ~= false and module.Summary then
        return module
    end
    return nil
end

local function OpenDungeon(index, questID)
    local dungeons = ns.modules.Dungeons
    if questID then
        dungeons.questState.selected = questID
        dungeons.questState.selectedRow = questID
    end
    dungeons:Select(index, "quests")
end

--------------------------------------------------------------------------------
-- 卡片
--------------------------------------------------------------------------------

local function ShowLineTooltip(line)
    if not (line.tooltip or line.spellID) then
        return
    end
    GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
    -- 技能行先显示游戏自己的技能提示，tooltip 里的行接在后面
    local first = true
    if line.spellID then
        GameTooltip:SetSpellByID(line.spellID)
        first = false
    end
    -- 提示行可能有空位（例如区域没有阵营），跳过空位继续输出
    for index = 1, table.maxn(line.tooltip or {}) do
        local text = line.tooltip[index]
        if text then
            if first then
                GameTooltip:SetText(text, 1, 0.82, 0)
                first = false
            else
                GameTooltip:AddLine(text, 1, 1, 1, true)
            end
        end
    end
    GameTooltip:Show()
end

local function CreateLine(card, index)
    local line = CreateFrame("Button", nil, card)
    line:SetHeight(LINE_HEIGHT)
    line:SetPoint("TOPLEFT", 10, -38 - (index - 1) * LINE_HEIGHT)
    line:SetPoint("TOPRIGHT", -10, -38 - (index - 1) * LINE_HEIGHT)
    line.highlight = line:CreateTexture(nil, "BACKGROUND")
    line.highlight:SetAllPoints()
    line.highlight:SetColorTexture(unpack(Theme.colors.raised))
    line.highlight:Hide()
    line.action = UI:Button(line, "", 64, 18, "ghost")
    line.action:SetPoint("RIGHT", -2, 0)
    line.note = UI:Text(line, "Muted")
    line.note:SetPoint("RIGHT", -6, 0)
    line.note:SetJustifyH("RIGHT")
    line.text = UI:Text(line, "Small")
    line.text:SetPoint("LEFT", 6, 0)
    line.text:SetPoint("RIGHT", line.note, "LEFT", -8, 0)
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    line:SetScript("OnEnter", function(self)
        self.highlight:Show()
        ShowLineTooltip(self)
    end)
    line:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        GameTooltip_Hide()
    end)
    line:SetScript("OnClick", function(self)
        if self.onClick then
            self.onClick()
        end
    end)
    return line
end

local function CreateCard(parent, titleKey)
    local card = UI:Panel(parent, "panel", "lineSoft")
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    local accent = card:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("BOTTOMLEFT", 1, 1)
    accent:SetWidth(2)
    accent:SetColorTexture(unpack(Theme.colors.gold))
    card.title = UI:Text(card, "Heading", L[titleKey])
    card.title:SetPoint("TOPLEFT", 16, -13)
    card.count = UI:Text(card, "Accent")
    card.count:SetPoint("LEFT", card.title, "RIGHT", 8, 0)
    card.lines = {}
    for index = 1, MAX_LINES do
        card.lines[index] = CreateLine(card, index)
    end
    card.empty = UI:Text(card, "Muted")
    card.empty:SetPoint("TOPLEFT", 16, -42)
    card.empty:SetWidth(CARD_WIDTH - 32)
    card.empty:SetJustifyH("LEFT")
    card.empty:SetJustifyV("TOP")
    card.open = UI:Button(card, "", 120, 22, "primary")
    card.open:SetPoint("BOTTOMRIGHT", -12, 10)
    card.footer = UI:Text(card, "Muted")
    card.footer:SetPoint("BOTTOMLEFT", 16, 15)
    card.footer:SetPoint("RIGHT", card.open, "LEFT", -8, 0)
    card.footer:SetJustifyH("LEFT")
    card.footer:SetWordWrap(false)
    return card
end

-- lines：{ {text, note, tooltip = {…}, spellID, onClick, action = {label, onClick}} }；emptyText 为没有内容时的说明
local function FillCard(card, lines, emptyText, footer)
    card.count:SetText(#lines > 0 and tostring(#lines) or "")
    for index, line in ipairs(card.lines) do
        local item = lines[index]
        if item then
            line.text:SetText(item.text)
            line.note:SetText(item.note or "")
            line.tooltip, line.spellID, line.onClick = item.tooltip, item.spellID, item.onClick
            if item.action then
                line.action:SetLabel(item.action.label)
                line.action:SetScript("OnClick", item.action.onClick)
                line.action:Show()
                line.note:SetPoint("RIGHT", line.action, "LEFT", -6, 0)
            else
                line.action:Hide()
                line.note:SetPoint("RIGHT", -6, 0)
            end
            line:Show()
        else
            line:Hide()
        end
    end
    card.empty:SetText(#lines == 0 and emptyText or "")
    local parts = {}
    if #lines > MAX_LINES then
        tinsert(parts, (L["+%d more"]):format(#lines - MAX_LINES))
    end
    if footer then
        tinsert(parts, footer)
    end
    card.footer:SetText(table.concat(parts, "  ·  "))
end

local function SetOpen(card, label, onClick)
    card.open:SetLabel(label)
    card.open:SetScript("OnClick", onClick)
    card.open:Show()
end

local function ShowDisabled(card, featureKey)
    FillCard(card, {}, (L["%s is turned off in Settings."]):format(L[featureKey]))
    if MainFrame:HasTab("settings") then
        SetOpen(card, L["Settings"], function()
            MainFrame:SelectTab("settings")
        end)
    else
        card.open:Hide()
    end
end

--------------------------------------------------------------------------------
-- 各卡片内容
--------------------------------------------------------------------------------

local function SpellIcon(icon)
    return icon and ("|TInterface\\Icons\\%s:14:14:0:0:64:64:5:59:5:59|t "):format(icon) or ""
end

local function NextTrainingLevel(upcoming)
    local first
    for level in pairs(upcoming) do
        if not first or level < first then
            first = level
        end
    end
    return first
end

local function FillSpells(card, spells)
    if not spells then
        ShowDisabled(card, "Spellbook")
        return
    end
    local lines = {}
    local function OpenSpellbook()
        MainFrame:SelectTab("spellbook")
    end
    for _, spell in ipairs(spells.ready) do
        tinsert(lines, { text = SpellIcon(spell.icon) .. spell.name,
            note = spell.rank ~= "" and spell.rank or nil, spellID = spell.id, onClick = OpenSpellbook })
    end
    -- 恶魔技能（术士）：到等级、可向恶魔训练师买魔典的，和普通技能同样列出，右侧注明恶魔与等级
    for _, spell in ipairs(spells.grimoires) do
        local price = ns.Money(spell.price)
        local grimoire = ns.ItemLink(spell.book)
        tinsert(lines, { text = SpellIcon(spell.icon) .. spell.name,
            note = ("%s · %s"):format(spell.pet or "?", (L["Rank %d"]):format(spell.rank)), spellID = spell.id,
            tooltip = { [2] = (L["Grimoire: %s"]):format(grimoire) .. (price and ("  " .. price) or ""),
                [3] = L["Buy it from a demon trainer."] },
            onClick = OpenSpellbook })
    end
    local empty
    local nextLevel = NextTrainingLevel(spells.upcoming)
    if nextLevel then
        empty = (L["Nothing to train right now. Next new spells at level %d."]):format(nextLevel)
    else
        empty = L["Nothing to train right now."]
    end
    FillCard(card, lines, empty)
    SetOpen(card, L["Spellbook"], OpenSpellbook)
end

local function DungeonLevels(levels)
    if not levels then
        return ""
    end
    return ("|c%s%s|r"):format(ns.LevelColor(levels[1], levels[2]), ns.LevelRange(levels))
end

-- 适合练级的区域：本阵营或争夺地区里，等级区间覆盖当前等级的野外区域（主城不算）
local TERRITORY = { alliance = "Alliance territory", horde = "Horde territory",
    contested = "Contested territory", neutral = "Neutral territory" }

local function RecommendedZones(count)
    local level = ns.PlayerLevel()
    local faction = ({ A = "alliance", H = "horde" })[ns.PlayerFaction() or ""]
    local scored = {}
    for uiMapID, zone in pairs(ns.Data.zones or {}) do
        local levels = zone.levels
        local reachable = not faction or (zone.faction ~= "alliance" and zone.faction ~= "horde") or zone.faction == faction
        if zone.kind == "zone" and levels and levels[1] and levels[2] and reachable
            and level >= levels[1] - 1 and level <= levels[2] then
            -- 越接近区间中段越合适；刚够等级的区域稍微靠后，本阵营地区略优先
            local score = math.abs((levels[1] + levels[2]) / 2 - level)
            if level < levels[1] then
                score = score + 2
            end
            if zone.faction == faction then
                score = score - 1
            end
            tinsert(scored, { id = uiMapID, zone = zone, score = score })
        end
    end
    table.sort(scored, function(a, b)
        if a.score ~= b.score then
            return a.score < b.score
        end
        return a.id < b.id
    end)
    local result = {}
    for index = 1, math.min(count, #scored) do
        tinsert(result, scored[index])
    end
    -- 挑出最合适的几个后按等级从低到高列出
    table.sort(result, function(a, b)
        local la, lb = a.zone.levels, b.zone.levels
        if la[1] ~= lb[1] then
            return la[1] < lb[1]
        end
        if la[2] ~= lb[2] then
            return la[2] < lb[2]
        end
        return a.id < b.id
    end)
    return result
end

local function FillZones(card)
    local lines = {}
    for _, item in ipairs(RecommendedZones(MAX_LINES)) do
        local zone, levels = item.zone, item.zone.levels
        local range = ("|c%s%s|r"):format(ns.LevelColor(levels[1], levels[2]), ns.LevelRange(levels))
        local territory = TERRITORY[zone.faction or ""]
        local continent = ns.ContinentName(item.id)
        tinsert(lines, {
            text = ns.Name(zone.name) or "?",
            note = continent and ("|cff8a8374%s|r  %s"):format(continent, range) or range,
            tooltip = { ns.Name(zone.name) or "?", continent, (L["Level %s"]):format(ns.LevelRange(levels)),
                territory and L[territory] or nil, L["Click to open it on the world map."] },
            onClick = function()
                ns.Waypoints:OpenMap(item.id)
            end,
        })
    end
    FillCard(card, lines, L["No zone fits your level right now."])
    card.open:Hide()
end

local function FillDungeons(card, summary)
    if not summary then
        ShowDisabled(card, "Dungeon guide")
        return
    end
    local lines = {}
    for _, item in ipairs(summary.recommended) do
        local note = DungeonLevels(item.levels)
        if item.prep > 0 then
            note = ("|cff46bf72%s|r  %s"):format((L["%d to pick up"]):format(item.prep), note)
        end
        local tooltip = { item.name, (L["Level %s"]):format(ns.LevelRange(item.levels) or "?") }
        if item.total > 0 then
            tinsert(tooltip, (L["Dungeon quests done: %d/%d"]):format(item.done, item.total))
        end
        if item.prep > 0 then
            tinsert(tooltip, (L["Pick up %d quests before you go in."]):format(item.prep))
        end
        tinsert(lines, { text = item.name, note = note, tooltip = tooltip, onClick = function()
            OpenDungeon(item.index)
        end })
    end
    FillCard(card, lines, L["No dungeon fits your level right now."])
    SetOpen(card, L["All dungeons"], function()
        MainFrame:SelectTab("dungeons")
        ns.modules.Dungeons:ShowHome()
    end)
end

local function MarkAction(source, who)
    if not (source and source.map and source.x) then
        return nil
    end
    return { label = L["Mark"], onClick = function()
        ns.Waypoints:Set(source.map, source.x, source.y, who)
    end }
end

local function SourceTooltip(labelKey, source)
    if not source then
        return nil
    end
    local who = ns.Name(source.name) or "?"
    if source.kind == "item" then
        who = (L["Item: %s"]):format(who)
    end
    return ("%s %s  |cff8a8374%s|r"):format(L[labelKey], who, ns.modules.Dungeons.PlaceText(source))
end

-- 副本任务卡：日志里有副本任务时列出这些（可交的在前）；没有时列出推荐副本进本前可先接的任务
local function FillQuests(card, summary)
    if not summary then
        card.title:SetText(L["Dungeon quests"])
        ShowDisabled(card, "Dungeon guide")
        return
    end
    local lines = {}
    if #summary.active > 0 then
        card.title:SetText(L["Dungeon quests in your log"])
        for _, item in ipairs(summary.active) do
            local quest = ns.Data.quests[item.quest]
            local dungeon = item.dungeon and ns.Data.dungeons[item.dungeon]
            local note = item.complete and ("|cff46bf72%s|r"):format(L["Ready to turn in"])
                or (dungeon and ns.Name(dungeon.name) or nil)
            local who = quest.finish and ns.Name(quest.finish.name)
            tinsert(lines, {
                text = ns.QuestTitle(item.quest),
                note = note,
                tooltip = { ns.QuestTitle(item.quest), dungeon and ns.Name(dungeon.name) or nil,
                    SourceTooltip("Turn in:", quest.finish) },
                action = item.complete and MarkAction(quest.finish, who) or nil,
                onClick = item.dungeon and function()
                    OpenDungeon(item.dungeon, item.quest)
                end or nil,
            })
        end
        FillCard(card, lines, "")
        card.open:Hide()
        return
    end
    card.title:SetText(L["Pick up before you go"])
    for _, item in ipairs(summary.prep) do
        local quest = ns.Data.quests[item.quest]
        local dungeon = ns.Data.dungeons[item.dungeon]
        local text = ns.QuestTitle(item.quest)
        if item.step then
            text = text .. (" |cff8a8374(%s %d/%d)|r"):format(L["Chain"], item.step, item.steps)
        end
        local who = quest.start and ns.Name(quest.start.name)
        tinsert(lines, {
            text = text,
            note = ns.Name(dungeon.name),
            tooltip = { ns.QuestTitle(item.quest), ns.Name(dungeon.name), SourceTooltip("Pick up:", quest.start) },
            action = MarkAction(quest.start, who),
            onClick = function()
                OpenDungeon(item.dungeon, item.quest)
            end,
        })
    end
    FillCard(card, lines, L["You have every quest you can pick up for these dungeons."])
    local first = summary.recommended[1]
    if first then
        SetOpen(card, L["Quest list"], function()
            OpenDungeon(first.index)
        end)
    else
        card.open:Hide()
    end
end

--------------------------------------------------------------------------------
-- 顶部状态、接下来几级、网站区
--------------------------------------------------------------------------------

local function ClassColorCode(classFile)
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    return color and color.colorStr or "fff4e8cc"
end

local function MaxLevel()
    return GetMaxPlayerLevel and GetMaxPlayerLevel() or 60
end

local function RefreshStatus()
    local className, classFile = UnitClass("player")
    local level = ns.PlayerLevel()
    page.character:SetText(("|c%s%s|r  ·  %s"):format(ClassColorCode(classFile), className or "?",
        (L["Level %d"]):format(level)))
    if level >= MaxLevel() then
        page.xpBar:Hide()
        page.xpText:SetText(L["Max level"])
        return
    end
    local current, maximum = UnitXP("player") or 0, UnitXPMax("player") or 1
    maximum = math.max(maximum, 1)
    local share = math.min(1, current / maximum)
    page.xpBar:Show()
    page.xpBar.fill:SetWidth(math.max(1, page.xpBar:GetWidth() * share))
    local rested = GetXPExhaustion and GetXPExhaustion()
    local text = (L["%d%% through level %d · %d XP to level %d"]):format(floor(share * 100), level, maximum - current,
        level + 1)
    if rested and rested > 0 then
        text = text .. "  ·  " .. (L["Rested %d XP"]):format(rested)
    end
    page.xpText:SetText(text)
end

local function RefreshSite(dungeons)
    local first = dungeons and dungeons.recommended[1]
    local dungeon = first and ns.Data.dungeons[first.index]
    if dungeon then
        page.siteBody:SetText((L["Full guide for %s on the website: every boss, loot table and quest walkthrough."])
            :format(ns.Name(dungeon.name)))
        page.siteButton:SetScript("OnClick", function()
            ns.Links:ShowCopyDialog(ns.Links:Build(dungeon.kind == "raid" and "raid" or "dungeon",
                dungeon.siteSlug or dungeon.slug))
        end)
    else
        page.siteBody:SetText(L["Full guides, changes from Classic and planning tools on the website:"])
        page.siteButton:SetScript("OnClick", function()
            ns.Links:ShowCopyDialog(ns.Links:Build("home"))
        end)
    end
end

function Refresh()
    if not (page and page:IsVisible()) then
        return
    end
    local spellbook, dungeonGuide = EnabledModule("Spellbook"), EnabledModule("Dungeons")
    local spells = spellbook and spellbook.Summary(LEVELS_AHEAD)
    local dungeons = dungeonGuide and dungeonGuide.Summary(MAX_LINES, LEVELS_AHEAD)
    RefreshStatus()
    FillZones(page.cards.zones)
    FillDungeons(page.cards.dungeons, dungeons)
    FillSpells(page.cards.spells, spells)
    FillQuests(page.cards.quests, dungeons)
    RefreshSite(dungeons)
end

--------------------------------------------------------------------------------
-- 页面
--------------------------------------------------------------------------------

-- 顶部一行：左边职业与等级，右边细经验条与进度文字
local function CreateStatus(p)
    p.character = UI:Text(p, "Heading")
    p.character:SetPoint("TOPLEFT", PAD, -18)
    p.xpText = UI:Text(p, "Muted")
    p.xpText:SetPoint("TOPRIGHT", -PAD, -20)
    local bar = CreateFrame("Frame", nil, p)
    bar:SetSize(140, 6)
    bar:SetPoint("RIGHT", p.xpText, "LEFT", -10, 0)
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(unpack(Theme.colors.lineSoft))
    bar.fill = bar:CreateTexture(nil, "ARTWORK")
    bar.fill:SetPoint("TOPLEFT")
    bar.fill:SetPoint("BOTTOMLEFT")
    bar.fill:SetColorTexture(unpack(Theme.colors.gold))
    p.xpBar = bar
end

local function CreateHomePage(parent)
    local p = CreateFrame("Frame", nil, parent)
    page = p
    Home.page = p
    CreateStatus(p)

    p.cards = {
        zones = CreateCard(p, "Where to level"),
        dungeons = CreateCard(p, "Dungeons for your level"),
        spells = CreateCard(p, "Train now"),
        quests = CreateCard(p, "Pick up before you go"),
    }
    -- 第一行“现在去哪”，第二行“回城要做”
    local order = { "zones", "dungeons", "spells", "quests" }
    for index, key in ipairs(order) do
        local column, row = (index - 1) % 2, floor((index - 1) / 2)
        p.cards[key]:SetPoint("TOPLEFT", PAD + column * (CARD_WIDTH + GAP), CARDS_TOP - row * (CARD_HEIGHT + GAP))
    end

    -- 网站区
    local site = UI:Panel(p, "raised", "lineSoft")
    site:SetPoint("BOTTOMLEFT", PAD, 16)
    site:SetPoint("BOTTOMRIGHT", -PAD, 16)
    site:SetHeight(52)
    local siteTitle = UI:Text(site, "Heading", "wowhandbook.com")
    siteTitle:SetPoint("TOPLEFT", 16, -10)
    p.siteButton = UI:Button(site, L["Copy website link"], 150, 26, "primary")
    p.siteButton:SetPoint("RIGHT", -14, 0)
    p.siteBody = UI:Text(site, "Small")
    p.siteBody:SetPoint("TOPLEFT", siteTitle, "BOTTOMLEFT", 0, -5)
    p.siteBody:SetPoint("RIGHT", p.siteButton, "LEFT", -16, 0)
    p.siteBody:SetJustifyH("LEFT")
    p.siteBody:SetWordWrap(false)

    -- 页面打开期间，任务、经验、等级、技能变化时刷新（节流 0.5 秒）
    local pending = false
    local function OnChange()
        if pending or not p:IsVisible() then
            return
        end
        pending = true
        C_Timer.After(0.5, function()
            pending = false
            Refresh()
        end)
    end
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "SPELLS_CHANGED",
        "ZONE_CHANGED_NEW_AREA" }) do
        ns:RegisterEvent(event, OnChange)
    end
    p:SetScript("OnShow", Refresh)
    return p
end

function Home.Refresh()
    Refresh()
end

Home.RecommendedZones = RecommendedZones -- 供测试使用

MainFrame:RegisterTab({ id = "home", title = L["Home"], order = 0, create = CreateHomePage, onShow = function()
    Refresh()
end })
