-- 界面冒烟测试：用“万能”框架桩加载主插件与采集插件，实际执行界面创建与交互路径
-- （打开主窗口、切换页面、采集数据页的分类/搜索/筛选/选择/跳转、复制链接对话框），
-- 捕获调用了不存在的方法、空值等运行错误。看不到画面，布局与观感仍需游戏内确认。
-- 用法（仓库根目录）：lua tools/tests/ui_smoke.lua

unpack = unpack or table.unpack
tinsert = table.insert
floor = math.floor
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
strsplit = function(sep, s)
    local parts = {}
    for piece in (s .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do tinsert(parts, piece) end
    return unpack(parts)
end
time, date = os.time, os.date
SlashCmdList, UISpecialFrames = {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GetLocale = function() return "zhCN" end
GetBuildInfo = function() return "1.60.1", "70009", "Sep 23 2026", 16001 end
GetTime = function() return 0 end
InCombatLockdown = function() return false end
IsControlKeyDown = function() return false end
GetCursorPosition = function() return 0, 50 end
GetInstanceInfo = function() return "Ragefire Chasm", "party", 1, "", 5, 0, false, 389 end
UnitGUID = function() return nil end
UnitName = function() return nil end
C_AddOns = { GetAddOnMetadata = function() return "0.1.0-test" end }
C_Timer = { After = function(_, fn) fn() end, NewTicker = function() return { Cancel = function() end } end }
C_Item = {
    GetItemInfo = function() return nil end,
    RequestLoadItemDataByID = function() end,
    GetItemQualityColor = function() return 1, 1, 1, "ffa335ee" end,
    GetItemNameByID = function() return nil end,
}
local loadedItemRequests = {}
C_Item.RequestLoadItemDataByID = function(id) loadedItemRequests[id] = true end
local tooltipItemCallback
TooltipDataProcessor = { AddTooltipPostCall = function(_, callback) tooltipItemCallback = callback end }
C_TooltipInfo = { GetItemByID = function() return nil end }
C_Map = {
    GetBestMapForUnit = function() return 1411 end,
    GetPlayerMapPosition = function() return nil end,
    GetMapInfo = function() return { name = "Orgrimmar" } end,
}
C_QuestLog = {
    GetTitleForQuestID = function() return nil end,
    GetNumQuestLogEntries = function() return 0 end,
}
GetMoneyString = function(c) return tostring(c) end
C_CVar = { GetCVar = function() return "0" end, SetCVar = function() end }

-- 主插件功能模块用到的接口
UnitFactionGroup = function() return "Horde" end
local playerClass = { "Mage", "MAGE" }
UnitClass = function() return playerClass[1], playerClass[2] end
UnitCreatureFamily = function() return "Imp" end
UnitExists = function(unit) return unit == "pet" or unit == "player" end
UnitRace = function() return "Orc", "Orc" end
local playerLevel = 20
UnitLevel = function(unit) return unit == "player" and playerLevel or 10 end
UnitXP = function() return 1500 end
UnitXPMax = function() return 6000 end
GetXPExhaustion = function() return 900 end
GetMaxPlayerLevel = function() return 60 end
RAID_CLASS_COLORS = { MAGE = { colorStr = "ff3fc7eb" }, WARLOCK = { colorStr = "ff8788ee" } }
Enum = { SpellBookSpellBank = { Player = 0 }, ItemQuality = { Poor = 0 }, TooltipDataType = { Item = 0 } }
local completedQuests, activeQuests = { [5722] = true }, {}
C_QuestLog.IsQuestFlaggedCompleted = function(id) return completedQuests[id] == true end
C_QuestLog.GetLogIndexForQuestID = function(id) return activeQuests[id] and 1 or nil end
C_QuestLog.RequestLoadQuestByID = function() end
local completeQuests = {}
C_QuestLog.IsComplete = function(id) return completeQuests[id] == true end
C_Map.CanSetUserWaypointOnMap = function() return true end
local waypoint
C_Map.SetUserWaypoint = function(point) waypoint = point end
UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { map = map, x = x, y = y } end }
C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end }
C_Map.GetMapInfoAtPosition = function() return { mapID = 1411 } end
C_Item.GetItemIconByID = function() return 134400 end
C_Item.GetItemQualityByID = function() return 3 end
-- 技能书：奥术智慧 1 级与 2 级都已学会；动作条 1 号位放的是 1 级
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = 2, shouldHide = false } end,
    HasPetSpells = function() return 1, "DEMON" end,
    GetSpellBookItemInfo = function(slot, bank)
        if bank == 1 then return { spellID = 7799, name = "Firebolt", subName = "Rank 2" } end
        if slot == 1 then return { spellID = 1459, name = "Arcane Intellect", subName = "Rank 1", isPassive = false } end
        return { spellID = 1460, name = "Arcane Intellect", subName = "Rank 2", isPassive = false }
    end,
}
local spellNames = { [1459] = "Arcane Intellect", [1460] = "Arcane Intellect", [2136] = "Fire Blast" }
local spellRanks = { [1459] = "Rank 1", [1460] = "Rank 2", [2136] = "Rank 1" }
C_Spell = {
    GetSpellName = function(id) return spellNames[id] end,
    GetSpellSubtext = function(id) return spellRanks[id] end,
    PickupSpell = function(id) cursorSpell = id end,
    IsSpellPassive = function() return false end,
}
local actions = { [1] = 1459 }
GetActionInfo = function(slot) if actions[slot] then return "spell", actions[slot] end end
HasAction = function(slot) return actions[slot] ~= nil end
PlaceAction = function(slot) actions[slot] = cursorSpell end
ClearCursor = function() end
C_ActionBar = { FindSpellActionButtons = function(id) local r = {} for s, v in pairs(actions) do if v == id then r[#r + 1] = s end end return r end }
-- 商人
local soldJunk = false
C_Container = C_Container or {}
C_Container.GetContainerNumSlots = function(bag) return bag == 0 and 1 or 0 end
C_Container.GetContainerItemInfo = function() return { itemID = 3300, quality = 0, stackCount = 2, hasNoValue = false } end
C_Container.GetContainerItemID = function() return 3300 end
C_MerchantFrame = { SellAllJunkItems = function() soldJunk = true end, IsSellAllJunkEnabled = function() return true end }
-- 大地图：假的地图框架与数据提供者、图钉 mixin
local openedMap
OpenWorldMap = function(id) openedMap = id end
C_TaxiMap = { ShouldMapShowTaxiNodes = function() return false end, GetTaxiNodesForMap = function() return {
    { nodeID = 25, name = "Crossroads", faction = 1, isUndiscovered = false, atlasName = "TaxiNode_Horde", position = { GetXY = function() return 0.5, 0.3 end } },
    { nodeID = 26, name = "Stormwind", faction = 2, isUndiscovered = true, position = { GetXY = function() return 0.4, 0.6 end } },
    { nodeID = 27, name = "Ratchet", faction = 0, isUndiscovered = true, position = { GetXY = function() return 0.6, 0.4 end } },
} end }
CreateFromMixins = function(...) local t = {} for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do t[k] = v end end return t end
Mixin = function(object, ...) for i = 1, select("#", ...) do for k, v in pairs(select(i, ...)) do object[k] = v end end return object end
MapCanvasDataProviderMixin = {}
MapCanvasPinMixin = { OnLoad = function() end, UseFrameLevelType = function() end, SetScalingLimits = function() end, SetPosition = function() end }
local pins = {}

-- 万能框架桩：任何方法都存在；少数取值方法返回合理的数
local frameMethods = {}
local function newObject(kind, name)
    local o = { kind = kind, name = name, shown = true, scripts = {}, text = "", checked = false, enabled = true,
        width = 100, height = 100, events = {} }
    return setmetatable(o, { __index = function(_, key)
        return frameMethods[key] or function() return nil end
    end })
end
frameMethods.CreateTexture = function() return newObject("Texture") end
frameMethods.SetTexture = function(self, path) self.texture = path end
frameMethods.CreateFontString = function() return newObject("FontString") end
frameMethods.SetScript = function(self, name, fn) self.scripts[name] = fn end
frameMethods.HookScript = function(self, name, fn) self.scripts[name] = self.scripts[name] or fn end
frameMethods.GetScript = function(self, name) return self.scripts[name] end
frameMethods.Show = function(self) self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
frameMethods.Hide = function(self) self.shown = false end
frameMethods.SetShown = function(self, v) if v then self:Show() else self:Hide() end end
frameMethods.IsShown = function(self) return self.shown end
frameMethods.IsVisible = function(self) return self.shown end
frameMethods.SetText = function(self, t) self.text = t or "" end
frameMethods.GetText = function(self) return self.text end
frameMethods.SetWidth = function(self, w) self.width = w end
frameMethods.SetHeight = function(self, h) self.height = h end
frameMethods.SetSize = function(self, w, h) self.width, self.height = w, h end
frameMethods.GetWidth = function(self) return self.width end
frameMethods.GetHeight = function(self) return self.height end
frameMethods.GetStringHeight = function() return 12 end
frameMethods.GetStringWidth = function() return 40 end
frameMethods.GetTop = function() return 100 end
frameMethods.GetEffectiveScale = function() return 1 end
frameMethods.GetCenter = function() return 500, 500 end
frameMethods.GetFrameLevel = function() return 1 end
frameMethods.GetScale = function() return 1 end
frameMethods.GetVerticalScroll = function() return 0 end
frameMethods.GetName = function(self) return self.name end
frameMethods.IsEnabled = function(self) return self.enabled end
frameMethods.IsMouseOver = function() return false end
frameMethods.RegisterEvent = function(self, e) self.events[e] = true end
frameMethods.UnregisterEvent = function(self, e) self.events[e] = nil end
frameMethods.Click = function(self) if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end

local allFrames = {}
CreateFrame = function(kind, name, parent, template)
    local f = newObject(kind, name)
    f.parent, f.template = parent, template
    f.shown = true
    tinsert(allFrames, f)
    if name then _G[name] = f end
    return f
end
CreateFont = function(name)
    local f = newObject("Font", name)
    _G[name] = f
    return f
end
for _, name in ipairs({ "GameFontNormalLarge", "GameFontNormal", "GameFontHighlight", "GameFontHighlightSmall",
    "GameFontNormalSmall" }) do
    _G[name] = newObject("Font", name)
end
UIParent = newObject("Frame", "UIParent")
Minimap = newObject("Frame", "Minimap")
WorldMapFrame = newObject("Frame", "WorldMapFrame")
WorldMapFrame.ScrollContainer = newObject("Frame")
WorldMapFrame.GetMapID = function() return 1413 end
WorldMapFrame.GetNormalizedCursorPosition = function() return 0.5, 0.5 end
hooksecurefunc = function(target, method, hook)
    local original = target[method]
    target[method] = function(...)
        local a, b, c, d = original(...)
        hook(...)
        return a, b, c, d
    end
end
local areaLabel = { labelInfoByType = {} }
function areaLabel:SetLabel(kind, name, description)
    self.labelInfoByType[kind] = self.labelInfoByType[kind] or {}
    self.labelInfoByType[kind].name, self.labelInfoByType[kind].description = name, description
end
local fakeMap = {
    GetMapID = function() return 1413 end,
    GetNormalizedCursorPosition = function() return 0.5, 0.5 end,
    GetCanvas = function() return WorldMapFrame.ScrollContainer end,
    DenormalizeHorizontalSize = function() return 1002 end,
    DenormalizeVerticalSize = function() return 668 end,
    RemoveAllPinsByTemplate = function(_, template) for i = #pins, 1, -1 do if pins[i].template == template then table.remove(pins, i) end end end,
    AcquirePin = function(_, template, node)
        local pin = newObject("Frame")
        pin.template, pin.poiInfo, pin.Texture = template, node, newObject("Texture")
        pin.SetPosition = function(self, x, y) self.x, self.y = x, y end
        pins[#pins + 1] = pin
        return pin
    end,
    EnumeratePinsByTemplate = function(_, template)
        local i = 0
        return function()
            repeat i = i + 1 until not pins[i] or pins[i].template == template
            return pins[i]
        end
    end,
}
areaLabel.dataProvider = { GetMap = function() return fakeMap end }
MAP_AREA_LABEL_TYPE = { AREA_NAME = 3 }
WHITE_FONT_COLOR = {}
UNDISCOVERED_NEUTRAL_FLIGHTPOINT = "Undiscovered flight point"
WorldMapFrame.dataProviders = { [{ Label = areaLabel }] = true }
WorldMapFrame.AddDataProvider = function(self, provider)
    provider.GetMap = function() return fakeMap end
    -- 测试框架的通用对象对缺失字段返回函数，所以用 rawget
    self.providers = rawget(self, "providers") or {}
    table.insert(self.providers, provider)
    self.provider = rawget(self, "provider") or provider -- 第一个是飞行点图层
end
GameTooltip = newObject("GameTooltip", "GameTooltip")
GameTooltip.AddLine = function(self, line)
    self.lines = rawget(self, "lines") or {}
    tinsert(self.lines, line)
end
GameTooltip.SetSpellByID = function(self, id) self.spellID = id end
GameTooltip_Hide = function() end

local function fireAll(event, ...)
    for _, f in ipairs(allFrames) do
        if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
    end
end

local function loadAddon(folder)
    local ns = {}
    local toc = assert(io.open(folder .. "/" .. folder .. ".toc")):read("a")
    for line in toc:gmatch("[^\r\n]+") do
        if not line:match("^##") and line:match("%.lua$") then
            assert(loadfile(folder .. "/" .. line:gsub("\\", "/")))(folder, ns)
        end
    end
    return ns
end

local failures = 0
local function check(name, fn)
    local ok, err = pcall(fn)
    print((ok and "PASS " or "FAIL ") .. name .. (ok and "" or ("\n    " .. tostring(err))))
    if not ok then failures = failures + 1 end
end

-- 内部采集插件不在公开仓库中：没有时跳过相关检查
local hasCollector = io.open("WowHandbook_Collector/WowHandbook_Collector.toc") ~= nil
local function collectorCheck(name, fn)
    if hasCollector then
        check(name, fn)
    else
        print("SKIP " .. name .. "（没有 WowHandbook_Collector）")
    end
end

local main, collector
check("load main addon", function() main = loadAddon("WowHandbook") end)
collectorCheck("load collector addon", function() collector = loadAddon("WowHandbook_Collector") end)
check("addon loaded events", function()
    fireAll("ADDON_LOADED", "WowHandbook")
    fireAll("ADDON_LOADED", "WowHandbook_Collector")
    fireAll("PLAYER_LOGIN")
end)
check("item source index and tooltip callback", function()
    local sourceModule = main.modules.ItemSource
    local target, expected
    for _, dungeon in ipairs(main.Data.dungeons) do
        for _, boss in ipairs(dungeon.bosses or {}) do
            local entry = boss.items and boss.items[1]
            if entry then
                target = type(entry) == "table" and entry.id or entry
                expected = main.Name(dungeon.name)
                break
            end
        end
        if target then break end
    end
    assert(target and sourceModule.Lookup(target):find(expected, 1, true), "source index missing")
    assert(tooltipItemCallback, "tooltip callback not registered")
    tooltipItemCallback(GameTooltip, { id = target, dataInstanceID = 1 })
    assert(GameTooltip.lines and GameTooltip.lines[#GameTooltip.lines]:find(expected, 1, true), "source tooltip missing")
    local before = #GameTooltip.lines
    tooltipItemCallback(GameTooltip, { id = target, dataInstanceID = 1 })
    assert(#GameTooltip.lines == before, "duplicate tooltip source")
end)
check("minimap button opens window and can be hidden", function()
    local module = main.modules.MinimapButton
    assert(module.enabled, "button module not enabled")
    local button
    for _, f in ipairs(allFrames) do
        if f.parent == Minimap and f.scripts.OnDragStart then button = f; break end
    end
    assert(button and button.shown, "minimap button missing")
    assert(button.icon and tostring(button.icon.texture):find("Media\\MinimapIcon$"), "minimap icon is not the site emblem")
    local previous = WowHandbookMainFrame and WowHandbookMainFrame.shown
    button:Click()
    assert(WowHandbookMainFrame.shown ~= previous, "button did not toggle window")
    button:Click()
    assert(not WowHandbookMainFrame.shown, "button did not close window")
    button.scripts.OnDragStart(button)
    assert(button.scripts.OnUpdate, "drag not active")
    button.scripts.OnDragStop(button)
    assert(not button.scripts.OnUpdate, "drag not stopped")
    main.db.modules.MinimapButton.hidden = true
    module:Refresh()
    assert(not button.shown, "hidden setting ignored")
    main.db.modules.MinimapButton.hidden = false
    module:Refresh()
    local count = #allFrames
    main:DisableModule(module)
    assert(not button.shown, "disabled button still visible")
    main:EnableModule(module)
    assert(#allFrames == count and button.shown, "reenable should reuse button")
end)
check("unlocked item placeholder and drop rate row", function()
    assert(main.ItemLink(999999) == main.L["Item information not yet unlocked"])
    assert(loadedItemRequests[999999], "item load not requested")
    local host = newObject("Frame")
    local stack = main.UI:Stack(host)
    stack:Items({ { id = 999999, rate = 12.5, unverified = true } }, 0, 30)
    local row = stack.pools.text[1].text
    assert(row:find(main.L["Item information not yet unlocked"], 1, true), "placeholder missing")
    assert(row:find("12.5", 1, true), "drop rate missing")
    assert(row:find(main.L["Unverified"], 1, true), "unverified marker missing")
end)

-- 放一些采集数据，让详情与列表走完整路径
collectorCheck("seed collected data", function()
    local data = collector.localeData
    data.quests[5722] = { title = "Lost Satchel", detail = { text = "Find it.", objectives = "Bring it." },
        rewards = { xp = 850, money = 1250, items = { { id = 901, count = 1 } } }, progress = "?", completion = "Thanks",
        starters = { ["npc:3346"] = { kind = "npc", id = 3346, mapID = 1411, x = 45.6, y = 12.3 } },
        log = { text = "Log", objectiveList = { { text = "0/1" } } }, build = "1.60.1.70009" }
    data.items[901] = { name = "Cape", quality = 3, itemLevel = 20, lines = { { "Cape" }, { "+5 Stamina", color = "ff00ff00" } } }
    data.failedItems[902] = { reason = "server" }
    collector.db.npcs[3346] = { names = { zhCN = "卡加尔" }, positions = {} }
    collector.db.loot["npc:11520"] = { kind = "npc", id = 11520, opened = 2, items = { [901] = 1 }, instances = { [389] = "怒焰裂谷" } }
end)

check("/wh opens main window with nav", function()
    SlashCmdList.WOWHANDBOOK("")
    assert(WowHandbookMainFrame and WowHandbookMainFrame.shown, "main frame not shown")
end)
collectorCheck("open collected page via /whc show", function()
    SlashCmdList.WOWHANDBOOKCOLLECTOR("show")
end)
collectorCheck("switch categories and filters", function()
    local B = collector.Browser
    for _, category in ipairs({ "loot", "items", "quests" }) do
        B:Select(category, category == "loot" and "npc:11520" or (category == "items" and 901 or 5722))
    end
    B:Refresh()
    B:OnDataChanged()
end)
collectorCheck("hyperlink jump from detail", function()
    collector.Browser:Select("items", 902)
    collector.Browser:Select("quests", 5723)
end)
collectorCheck("pending tasks page: categories, map link marks the spot", function()
    SlashCmdList.WOWHANDBOOKCOLLECTOR("todo")
    local T = collector.Tasks
    local npcID, v = next(collector.targets.verify.npcs)
    assert(npcID, "no NPC in verify table")
    local detail = T.Detail("npcs", npcID)
    assert(detail:find("待确认坐标"), "detail not in Chinese")
    local link = detail:match("|H(whmap:[^|]+)|h")
    assert(link and T.OnMapLink(link), "no clickable coordinate")
    for _, category in ipairs({ "quests", "bosses", "loot", "npcs" }) do
        assert(#T.BuildEntries(category, false) > 0, "empty category " .. category)
    end
    T:Refresh()
    T:OnDataChanged()
    assert(v.map, "NPC has no website map")
end)
collectorCheck("no runtime errors recorded by the collector", function()
    assert(#collector.db.errors == 0, collector.db.errors[1] and collector.db.errors[1].message)
end)
collectorCheck("collector window shows, collapses, hides and refreshes", function()
    assert(WowHandbookCollectorHud and WowHandbookCollectorHud.shown, "hud not shown after login")
    collector.Hud:OnDataChanged()
    collector:Log("quests", "%d %s", 1, "test")
    SlashCmdList.WOWHANDBOOKCOLLECTOR("hud")
    assert(not WowHandbookCollectorHud.shown, "hud not hidden")
    SlashCmdList.WOWHANDBOOKCOLLECTOR("hud")
    assert(WowHandbookCollectorHud.shown, "hud not shown again")
end)
check("dungeon guide page opens and renders every dungeon", function()
    main.MainFrame:SelectTab("dungeons")
    for index = 1, #main.Data.dungeons do
        assert(main.modules.Dungeons:Select(index), "select failed " .. index)
    end
    assert(main.modules.Dungeons:Select("ragefire-chasm"), "select by slug failed")
end)
check("every dungeon renders on every tab", function()
    for _, tab in ipairs({ "quests", "loot" }) do
        for index = 1, #main.Data.dungeons do
            assert(main.modules.Dungeons:Select(index, tab), "select failed " .. index .. " " .. tab)
        end
    end
    main.modules.Dungeons:ShowHome()
end)
check("sections use their own range; unassigned quests stay visible outside recommendations", function()
    local dungeons = main.Data.dungeons
    local section = { slug = "test-parent-east", parentSlug = "test-parent", siteSlug = "test-parent",
        name = { enUS = "East Wing", zhCN = "东区" }, kind = "dungeon", levels = { 20, 25 },
        bosses = { { name = { enUS = "Test Boss", zhCN = "测试首领" }, items = { { id = 999999, rate = 12.5 } } } },
        quests = { 999998 } }
    local fallback = { slug = "test-parent", name = { enUS = "Test Parent", zhCN = "测试副本" },
        aggregateOnly = true, kind = "dungeon", levels = { 20, 25 }, quests = {}, bosses = {} }
    tinsert(dungeons, section)
    tinsert(dungeons, fallback)
    main.Data.quests[999998] = { name = { enUS = "Test Quest", zhCN = "测试任务" },
        instances = { "test-parent" }, sectionSlugs = { "east" } }
    activeQuests[999998] = true
    local ok, err = pcall(function()
        assert(main.LevelRange(section.levels) == "20-25", "range lost")
        assert(main.modules.Dungeons:Select(section.slug, "loot"), "section not selectable")
        assert(main.modules.Dungeons:Select(fallback.slug, "quests"), "fallback quests not selectable")
        for _, recommendation in ipairs(main.modules.Dungeons.Summary(100).recommended) do
            assert(recommendation.name ~= "测试副本的其他任务", "fallback entered recommendations")
        end
        local found
        for _, active in ipairs(main.modules.Dungeons.Summary(3).active) do
            if active.quest == 999998 then found = active.dungeon end
        end
        assert(found == #dungeons - 1, "quest did not map to section")
    end)
    activeQuests[999998] = nil
    main.Data.quests[999998] = nil
    table.remove(dungeons)
    table.remove(dungeons)
    assert(ok, err)
end)
check("quest table classifies chain states", function()
    local Classify = main.modules.Dungeons.Classify
    -- 找一个在副本里、前面至少有 2 步任务链、没有阵营限制和等级门槛高于 20 的任务
    local target, chain
    for _, dungeon in ipairs(main.Data.dungeons) do
        for _, id in ipairs(dungeon.quests or {}) do
            local _, c = Classify(id)
            local quest = main.Data.quests[id]
            if #c >= 3 and not quest.faction then
                target, chain = id, c
                break
            end
        end
        if target then break end
    end
    assert(target, "no quest with a 3-step chain found")
    completedQuests, activeQuests = {}, {}
    local kind, _, nextStep, doneSteps = Classify(target)
    assert(kind == "chain" and nextStep == chain[1] and doneSteps == 0, "not started: " .. kind)
    completedQuests[chain[1]] = true
    kind, _, nextStep, doneSteps = Classify(target)
    assert(kind == "chain" and nextStep == chain[2] and doneSteps == 1, "paused: " .. kind)
    activeQuests[chain[2]] = true
    kind, _, nextStep = Classify(target)
    assert(kind == "chain" and nextStep == chain[2], "on chain: " .. kind)
    for i = 1, #chain - 1 do completedQuests[chain[i]] = true end
    activeQuests = {}
    kind = Classify(target)
    local quest = main.Data.quests[target]
    assert(kind == ((quest.min and quest.min > 20) and "low" or "ready"), "ready/low: " .. kind)
    activeQuests[target] = true
    assert(Classify(target) == "active", "active")
    activeQuests = {}
    completedQuests[target] = true
    assert(Classify(target) == "done", "done")
    completedQuests = { [5722] = true }
end)
check("waypoint for a quest giver", function()
    main.Waypoints:Set(1411, 45.5, 12.3, "Kargal")
    assert(waypoint and waypoint.map == 1411 and math.abs(waypoint.x - 0.455) < 1e-6, "waypoint not set")
end)
check("unlearned spells panel follows the game spellbook", function()
    -- 模拟按需加载的暴雪技能书（无限版为 PlayerSpellsFrame.SpellBookFrame）
    PlayerSpellsFrame = CreateFrame("Frame", "PlayerSpellsFrame", UIParent)
    PlayerSpellsFrame.SpellBookFrame = CreateFrame("Frame", nil, PlayerSpellsFrame)
    local book = PlayerSpellsFrame.SpellBookFrame
    book.shown = false
    fireAll("ADDON_LOADED", "Blizzard_PlayerSpells")
    assert(book.scripts.OnShow and book.scripts.OnHide, "game spellbook not hooked")
    local module = main.modules.SpellbookPanel
    book.shown = true
    book.scripts.OnShow(book)
    assert(module.panel and module.panel.shown, "panel not shown with the spellbook")
    local entries = module.Entries()
    assert(#entries > 0, "no unlearned spells listed")
    local later = false
    for _, entry in ipairs(entries) do
        assert(entry.row.status ~= "known" and entry.row.status ~= "innate", "learned spell listed")
        if entry.row.status == "later" then
            later = true
        else
            assert(not later, "a spell to learn now is listed after later ones")
        end
    end
    local withID = 0
    for _, entry in ipairs(entries) do
        if entry.row.id then withID = withID + 1 end
    end
    assert(withID > 0, "no spell IDs for tooltips")
    module.panel.list.onEntryEnter(module.panel.list.rows[1], entries[1].id)
    main.db.modules.SpellbookPanel.collapsed = true
    module:Refresh()
    assert(not module.panel.shown and module.tab.shown, "collapse should leave the small button")
    module.tab.scripts.OnClick(module.tab)
    assert(module.panel.shown and not module.tab.shown, "button should expand the panel")
    book.shown = false
    book.scripts.OnHide(book)
    assert(not module.panel.shown and not module.tab.shown, "panel should hide with the spellbook")
end)
check("spellbook page renders", function()
    main.MainFrame:SelectTab("spellbook")
end)
check("spellbook is one full table; hovering a row shows the spell tooltip", function()
    main.MainFrame:SelectTab("home")
    main.MainFrame:SelectTab("spellbook")
    local page = main.modules.Spellbook.page
    assert(rawget(page, "filter") == nil, "the recent-levels filter should be gone")
    local header, spells, hovered = page.tableRows[1], 0, nil
    assert(header.cells.spell:GetText():find(main.L["Spell"], 1, true) and not header.entry, "no table header")
    for _, row in ipairs(page.tableRows) do
        if row:IsShown() and row.entry then
            spells = spells + 1
            if row.entry.id and not hovered then
                hovered = row
            end
        end
    end
    assert(spells == #main.modules.Spellbook.Rows(), ("table shows %d of %d spells"):format(spells, #main.modules.Spellbook.Rows()))
    assert(hovered, "no row with a spell ID")
    hovered.scripts.OnEnter(hovered)
    assert(GameTooltip.spellID == hovered.entry.id, "row hover did not show the spell tooltip")
    hovered.scripts.OnLeave(hovered)
end)
check("warlock spellbook shows demon abilities with grimoires and innate ranks", function()
    playerClass = { "Warlock", "WARLOCK" }
    local innate, books = 0, 0
    for _, spell in ipairs(main.Data.spells.warlock) do
        for _, rank in ipairs(spell.pet and spell.ranks or {}) do
            if rank.innate then innate = innate + 1 end
            if rank.book then books = books + 1 end
        end
    end
    assert(innate == 4 and books == 59, ("innate %d books %d"):format(innate, books))
    -- 召唤出的小鬼会火焰箭 2 级（技能 ID 7799）：按 ID 记进角色存档；没召唤过的恶魔不能报“购买魔典”
    main.charDB.petSpells = nil
    local rows = main.modules.Spellbook.Rows(true)
    local imp = main.charDB.petSpells and main.charDB.petSpells.Imp
    assert(imp and imp.firebolt == 2, "imp spells not recorded by spell ID")
    local unchecked = 0
    for _, row in ipairs(rows) do
        if row.spell.pet.enUS ~= "Imp" then
            assert(row.status ~= "book" and row.status ~= "known", "unsummoned demon judged: " .. row.spell.name.enUS)
            if row.status == "unchecked" then unchecked = unchecked + 1 end
        elseif row.spell.name.enUS == "Firebolt" and row.rankNumber == 2 then
            assert(row.status == "known", "imp Firebolt rank 2 should be known, got " .. row.status)
        end
    end
    assert(unchecked > 0, "no demon marked as unchecked")
    -- 事件：召唤或更换恶魔后 1 秒内合并读取
    main.modules.Spellbook.OnPetChanged("UNIT_PET", "player")
    main.modules.Spellbook.OnPetChanged("PET_BAR_UPDATE")
    main.MainFrame:SelectTab("home")
    main.MainFrame:SelectTab("spellbook")
    fireAll("PLAYER_LEVEL_UP", 8)
    -- 首页“现在可学”卡片：可买魔典的恶魔技能和普通技能一样逐行列出，带技能 ID（悬停显示技能提示）
    local summary = main.modules.Spellbook.Summary(4)
    assert(#summary.grimoires > 0, "no grimoire to buy in this test")
    main.Home.Refresh()
    local card = main.Home.page.cards.spells
    assert(card.count:GetText() == tostring(#summary.ready + #summary.grimoires), "grimoires not counted on the home card")
    local total = #summary.ready + #summary.grimoires
    if total <= #card.lines then
        local line = card.lines[#summary.ready + 1]
        assert(line:IsShown() and line.spellID == summary.grimoires[1].id and line.tooltip[2], "grimoire line missing")
    end
    playerClass = { "Mage", "MAGE" }
end)
check("settings page renders", function()
    main.MainFrame:SelectTab("settings")
end)
check("action bar upgrades lower rank after learning", function()
    fireAll("LEARNED_SPELL_IN_SKILL_LINE", 1460, 1, false)
    assert(actions[1] == 1460, "slot 1 not upgraded, got " .. tostring(actions[1]))
end)
check("new spell goes to an empty main bar slot", function()
    spellNames[2136] = "Fire Blast"
    fireAll("LEARNED_SPELL_IN_SKILL_LINE", 2136, 1, false)
    assert(actions[2] == 2136, "new spell not placed")
end)
check("vendor sells junk", function()
    fireAll("MERCHANT_SHOW")
    assert(soldJunk, "junk not sold")
end)
check("quest list leads with the level a quest can be accepted at", function()
    for _, dungeon in ipairs(main.Data.dungeons) do
        if dungeon.slug == "ruins-of-lordaeron" then
            local found = false
            for _, entry in ipairs(main.modules.Dungeons.QuestEntries(dungeon)) do
                if entry.id == 97288 then
                    found = true
                    assert(entry.text:find("[16]", 1, true), "row should show accept level 16: " .. entry.text)
                end
            end
            assert(found, "Unending Torment not listed")
        end
    end
end)
check("world map: dungeon entrances on zone maps, click opens the dungeon", function()
    local provider = WorldMapFrame.providers[3]
    assert(provider, "dungeon provider not added")
    provider:RefreshAllData()
    local found = 0
    for _, pin in ipairs(pins) do
        if pin.template == "WowHandbookDungeonPinTemplate" then
            found = found + 1
            assert(pin.x >= 0 and pin.x <= 1 and pin.y >= 0 and pin.y <= 1, "pin outside the map")
            assert(pin.whLines[1] and pin.whLines[1] ~= "?", "pin has no name")
        end
    end
    local expected = 0
    for _, dungeon in ipairs(main.Data.dungeons) do
        local faction = dungeon.faction
        if dungeon.entrance and dungeon.entrance.map == 1413 and dungeon.entrance.x
            and (not faction or faction == "both" or faction == "horde") then
            expected = expected + 1
        end
    end
    assert(expected > 0 and found == expected, ("%d dungeon pins, expected %d"):format(found, expected))
    for _, pin in ipairs(pins) do
        if pin.template == "WowHandbookDungeonPinTemplate" then
            pin:OnMouseEnter()
            pin:OnMouseClickAction("LeftButton")
            break
        end
    end
    assert(WowHandbookMainFrame.shown, "clicking a dungeon pin should open the handbook")
    main.db.modules.WorldMap.dungeonPins = false
    provider:RefreshAllData()
    for _, pin in ipairs(pins) do
        assert(pin.template ~= "WowHandbookDungeonPinTemplate", "dungeon pins shown while turned off")
    end
    main.db.modules.WorldMap.dungeonPins = true
    provider:RemoveAllData()
end)
check("world map: spirit healers when dead, always or never", function()
    local provider = WorldMapFrame.providers[4]
    assert(provider, "graveyard provider not added")
    local function count()
        provider:RefreshAllData()
        local n, first = 0, nil
        for _, pin in ipairs(pins) do
            if pin.template == "WowHandbookGraveyardPinTemplate" then
                n = n + 1
                first = first or pin
            end
        end
        return n, first
    end
    local expected = #(main.Data.graveyards[1413] or {})
    assert(expected > 0, "no spirit healers for the test map")
    local dead = false
    UnitIsDeadOrGhost = function() return dead end
    local settings = main.db.modules.WorldMap
    assert((settings.spiritHealers or "dead") == "dead", "default should be: when dead")
    assert(count() == 0, "shown while alive")
    dead = true
    local n, pin = count()
    assert(n == expected, ("%d spirit healers, expected %d"):format(n, expected))
    waypoint = nil
    pin:OnMouseClickAction("LeftButton")
    assert(waypoint, "clicking a spirit healer should set a waypoint")
    fireAll("PLAYER_ALIVE")
    dead = false
    settings.spiritHealers = "always"
    assert(count() == expected, "always: not shown while alive")
    settings.spiritHealers = "off"
    dead = true
    assert(count() == 0, "never: still shown")
    settings.spiritHealers = nil
    dead = false
    provider:RemoveAllData()
end)
check("world map: native-style flight pins", function()
    assert(WorldMapFrame.provider, "data provider not added")
    WorldMapFrame.provider:RefreshAllData()
    assert(#pins == 2, "expected 2 pins for a Horde player, got " .. #pins)
    assert(pins[1].template == "WowHandbookFlightPinTemplate" and pins[1].poiInfo.name == "Crossroads")
    assert(pins[2].poiInfo.isUndiscovered and pins[2].poiInfo.description == "Undiscovered flight point")
end)
check("world map: full map draws only unexplored areas", function()
    local overlays = main.Data.mapOverlays[1413]
    assert(overlays and #overlays > 1, "no overlay data for 1413")
    local first = overlays[1]
    C_MapExplorationInfo = { GetExploredMapTextures = function()
        return { { offsetX = first[3], offsetY = first[4] } }
    end }
    local revealProvider = WorldMapFrame.providers[2]
    assert(revealProvider, "reveal provider not added")
    local created = 0
    local canvas = WorldMapFrame.ScrollContainer
    local originalCreate = CreateFrame
    CreateFrame = function(...)
        local frame = originalCreate(...)
        local originalTexture = frame.CreateTexture
        frame.CreateTexture = function(...)
            created = created + 1
            return originalTexture(...)
        end
        return frame
    end
    local ok, err = pcall(function() revealProvider:RefreshAllData() end)
    CreateFrame = originalCreate
    assert(ok, err)
    local expected = 0
    for index = 2, #overlays do
        expected = expected + (#overlays[index] - 4)
    end
    assert(created == expected, ("expected %d unexplored tiles, drew %d"):format(expected, created))
    assert(canvas)
end)
check("world map: level range under the native zone name", function()
    main.Data.zones[1411] = main.Data.zones[1411] or { levels = { 1, 10 } }
    areaLabel:SetLabel(3, "Durotar", nil)
    local info = areaLabel.labelInfoByType[3]
    assert(info.description and info.description:find("1%-10"), "no level in description: " .. tostring(info.description))
end)
check("entrance button marks and opens the world map", function()
    main.Waypoints:ShowOnMap(1454, 52.9, 48.8, "Ragefire Chasm")
    assert(openedMap == 1454, "world map not opened")
end)
check("loot filter: categories, armor types and class usability", function()
    local F = main.ItemFilter
    local fake = {
        [901] = { "INVTYPE_CHEST", 4, 4 },   -- 板甲
        [902] = { "INVTYPE_2HWEAPON", 2, 10 }, -- 法杖
        [903] = { "INVTYPE_FINGER", 4, 0 },  -- 戒指
        [904] = { "", 12, 0 },               -- 任务物品
        [905] = { "INVTYPE_CLOAK", 4, 1 },   -- 披风
    }
    local original = C_Item.GetItemInfoInstant
    C_Item.GetItemInfoInstant = function(id)
        local f = fake[id]
        return id, "", "", f[1], 0, f[2], f[3]
    end
    local ok, err = pcall(function()
        local all = { category = "all", armor = "all" }
        assert(not F.Matches(901, { class = "WARLOCK", category = "all", armor = "all" }), "warlocks cannot wear plate")
        assert(F.Matches(901, { class = "WARRIOR", category = "all", armor = "all" }))
        assert(F.Matches(902, { class = "WARLOCK", category = "weapon", armor = "all" }))
        assert(not F.Matches(902, { class = "ROGUE", category = "all", armor = "all" }), "rogues cannot use staves")
        assert(F.Matches(903, all) and F.Matches(904, all))
        assert(not F.Matches(904, { category = "armor", armor = "all" }))
        assert(F.Matches(901, { category = "armor", armor = "plate" }))
        assert(not F.Matches(903, { category = "armor", armor = "plate" }))
        assert(F.Matches(905, { class = "WARRIOR", category = "armor", armor = "accessory" }), "cloaks count as accessories")
    end)
    C_Item.GetItemInfoInstant = original
    assert(ok, err)
end)
check("loot filters only show on the loot tab", function()
    local D = main.modules.Dungeons
    local shown = {}
    local bar
    assert(D:Select(1, "loot"))
    bar = D.page and D.page.detail and D.page.detail.lootFilters
    assert(bar, "detail page not created")
    shown.loot = bar:IsShown()
    assert(D:Select(1, "quests"))
    shown.quests = bar:IsShown()
    assert(shown.loot and not shown.quests, "filter bar visible on the quest tab")
end)
check("quest list: flat, no quest shown twice", function()
    local D = main.modules.Dungeons
    for _, dungeon in ipairs(main.Data.dungeons) do
        local entries, info = D.QuestEntries(dungeon)
        local top = {}
        for _, entry in ipairs(entries) do
            assert(not entry.header, "group header rows should be gone")
            if not entry.step and not entry.divider then
                assert(not top[entry.id], "quest listed twice: " .. entry.id)
                top[entry.id] = true
            end
        end
        for id in pairs(top) do
            for _, step in ipairs(info[id].chain) do
                assert(step == id or not top[step], ("quest %d also appears in chain of %d"):format(step, id))
            end
        end
    end
end)
check("quest list: outside quests above the divider, inside quests below", function()
    local D = main.modules.Dungeons
    local checked = 0
    for _, dungeon in ipairs(main.Data.dungeons) do
        local entries = D.QuestEntries(dungeon)
        local section
        for _, entry in ipairs(entries) do
            if entry.divider then
                section = entry.id
            elseif not entry.step then
                local want = main.Data.quests[entry.id].inside and "section:inside" or "section:outside"
                assert(section == want, ("quest %d under %s"):format(entry.id, tostring(section)))
                checked = checked + 1
            end
        end
    end
    assert(checked > 0)
end)
check("quest view: expand a chain and select a step", function()
    local D = main.modules.Dungeons
    for index, dungeon in ipairs(main.Data.dungeons) do
        for _, id in ipairs(dungeon.quests or {}) do
            local _, chain = D.Classify(id)
            if #chain > 1 then
                D.questState.expanded[id] = true
                D.questState.selected = chain[1]
                assert(D:Select(index, "quests"))
                D.questState.selected = id
                assert(D:Select(index, "quests"))
                return
            end
        end
    end
    error("no chained quest found")
end)
check("level-up notice lists spells", function()
    fireAll("PLAYER_LEVEL_UP", 14)
end)
check("no main addon errors in modules", function()
    main.MainFrame:SelectTab("home")
end)
check("home dashboard: status, cards and upcoming", function()
    local Home = main.Home
    main.MainFrame:SelectTab("home")
    local p = Home.page
    assert(p and p.cards, "home page not created")
    -- 部落 13 级：怒焰裂谷（13 级）应在推荐里，并有进本前先接的任务
    local savedLevel = playerLevel
    playerLevel = 13
    local rfc
    for index, dungeon in ipairs(main.Data.dungeons) do
        if dungeon.slug == "ragefire-chasm" then rfc = index end
    end
    local summary = main.modules.Dungeons.Summary(3, 4)
    local recommended = false
    for _, item in ipairs(summary.recommended) do
        if item.index == rfc then recommended = true end
    end
    assert(recommended, "Ragefire Chasm not recommended at level 13")
    assert(#summary.prep > 0, "nothing to prepare at level 13")
    for _, item in ipairs(summary.prep) do
        assert(not main.Data.quests[item.quest].inside, "prep lists an inside quest")
    end
    -- 任务日志里有一个已完成的副本任务
    local questID
    for _, id in ipairs(main.Data.dungeons[rfc].quests) do
        if not completedQuests[id] and main.Data.quests[id].faction ~= "A" then questID = id break end
    end
    activeQuests[questID], completeQuests[questID] = true, true
    Home.Refresh()
    local line = p.cards.quests.lines[1]
    assert(line:IsShown() and line.note:GetText():find(main.L["Ready to turn in"], 1, true), "turn-in not shown")
    assert(p.cards.quests.title:GetText() == main.L["Dungeon quests in your log"], "quest card should show the log")
    assert(p.character:GetText():find("13"), "level missing: " .. tostring(p.character:GetText()))
    assert(p.xpText:GetText():find("25"), "xp percent missing: " .. tostring(p.xpText:GetText()))
    activeQuests[questID], completeQuests[questID] = nil, nil
    Home.Refresh()
    assert(p.cards.quests.title:GetText() == main.L["Pick up before you go"], "quest card should fall back to prep")
    -- 练级区域：13 级有匹配区域，且不含主城与另一阵营的领地
    local zones = Home.RecommendedZones(4)
    assert(#zones > 0, "no zones recommended at level 13")
    for _, item in ipairs(zones) do
        assert(item.zone.kind == "zone", "city recommended")
        assert(item.zone.faction ~= "alliance", "enemy territory recommended: " .. item.zone.slug)
        assert(13 >= item.zone.levels[1] - 1 and 13 <= item.zone.levels[2], "zone level out of range")
    end
    assert(p.cards.zones.lines[1]:IsShown(), "zone card empty")
    -- 推荐副本：不推荐“数据待补”与没有数据的副本，满级前不推荐团本
    for _, testLevel in ipairs({ 37, 45, 59 }) do
        playerLevel = testLevel
        for _, item in ipairs(main.modules.Dungeons.Summary(4, 4).recommended) do
            local dungeon = main.Data.dungeons[item.index]
            assert(not dungeon.dataPending, "data-pending dungeon recommended: " .. dungeon.slug)
            assert(dungeon.kind ~= "raid", "raid recommended before max level: " .. dungeon.slug)
        end
    end
    -- 领主大厅只对联盟显示：部落角色的推荐里不应出现
    playerLevel = 14
    for _, item in ipairs(main.modules.Dungeons.Summary(4, 4).recommended) do
        assert(main.Data.dungeons[item.index].slug ~= "hall-of-thanes", "Hall of Thanes shown to Horde")
    end
    playerLevel = savedLevel
    Home.Refresh()
end)
check("switch back to home page", function()
    main.MainFrame:SelectTab("home")
    if hasCollector then
        main.MainFrame:SelectTab("collected")
    end
end)
collectorCheck("collected page is localized for zhCN", function()
    assert(collector.L["Collected data"] == "采集数据", "zhCN translation missing")
    assert(collector.Browser.Detail("quests", 5722):find("任务正文"), "detail not in Chinese")
end)
check("copy link dialog", function()
    SlashCmdList.WOWHANDBOOK("link")
    assert(WowHandbookLinkDialog and WowHandbookLinkDialog.shown, "dialog not shown")
end)
check("widgets: list scroll, checkbox, search, scrollbar drag", function()
    local UI = main.UI
    local parent = CreateFrame("Frame")
    local list = UI:List(parent, 22, function() end)
    local data = {}
    for i = 1, 50 do data[i] = { id = i, text = "row " .. i, tags = "t" } end
    list:SetData(data, 3)
    list.scripts.OnMouseWheel(list, -1)
    list:ScrollTo(40)
    local check = UI:Checkbox(parent, "x", function() end)
    check:Click()
    assert(check:GetChecked() == true)
    local box = UI:SearchBox(parent, 100, "search", function() end)
    box:SetText("abc")
    box.scripts.OnTextChanged(box)
    local area = UI:ScrollArea(parent)
    area:SetContentHeight(500)
    area.scripts.OnMouseWheel(area, -1)
    local tile = UI:StatTile(parent, "t")
    tile:Set("1/2", "note", 0.5)
    tile.scripts.OnSizeChanged(tile)
end)

if failures > 0 then
    print(failures .. " check(s) failed")
    os.exit(1)
end
print("all ui checks passed")
