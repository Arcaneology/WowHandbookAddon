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
Enum = { SpellBookSpellBank = { Player = 0 }, ItemQuality = { Poor = 0 } }
local completedQuests, activeQuests = { [5722] = true }, {}
C_QuestLog.IsQuestFlaggedCompleted = function(id) return completedQuests[id] == true end
C_QuestLog.GetLogIndexForQuestID = function(id) return activeQuests[id] and 1 or nil end
C_QuestLog.RequestLoadQuestByID = function() end
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
        local pin = { template = template, poiInfo = node, Texture = newObject("Texture") }
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
check("spellbook page renders both filters", function()
    main.MainFrame:SelectTab("spellbook")
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
    main.MainFrame:SelectTab("home")
    main.MainFrame:SelectTab("spellbook")
    fireAll("PLAYER_LEVEL_UP", 8)
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
