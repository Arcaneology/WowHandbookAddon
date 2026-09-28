-- 界面冒烟测试：用“万能”框架桩加载主插件与采集插件，实际执行界面创建与交互路径
-- （打开主窗口、切换页面、采集数据页的分类/搜索/筛选/选择/跳转、复制链接对话框），
-- 捕获空值等运行错误。看不到画面，布局与观感仍需游戏内确认。
-- 桩的边界：未知的框架方法仍返回空函数（结束时列出调用过的未知方法供核对），不能证明方法在客户端存在；
-- 定时器排队、由测试推进（runTimers）；战斗状态可切换；可见性考虑父框架，显示 / 隐藏会向子框架传递 OnShow / OnHide；
-- XML 只核对模板名是否与代码引用一致，不加载模板。
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
local now = 0
GetTime = function() return now end
local inCombat = false
InCombatLockdown = function() return inCombat end
local cursorItem
GetCursorInfo = function() return cursorItem end
IsControlKeyDown = function() return false end
GetCursorPosition = function() return 0, 50 end
GetInstanceInfo = function() return "Ragefire Chasm", "party", 1, "", 5, 0, false, 389 end
UnitGUID = function() return nil end
-- 模拟客户端的秘密值：不能转成文字、不能拼接、不能比较大小
local SECRET = setmetatable({}, {
    __tostring = function() error("attempt to perform string conversion on a secret string value") end,
    __concat = function() error("attempt to concatenate a secret string value") end,
    __lt = function() error("attempt to compare a secret string value") end,
    __index = function() error("attempt to index a secret string value") end,
})
issecretvalue = function(value) return rawequal(value, SECRET) end
UnitName = function() return nil end
C_AddOns = { GetAddOnMetadata = function() return "0.1.0-test" end }
-- 定时器排队，runTimers() 推进时间并按到期先后执行（执行中新排的定时器也会在本次推进内执行）
local timers = {}
C_Timer = { After = function(delay, fn) tinsert(timers, { at = now + (delay or 0), fn = fn }) end,
    NewTicker = function() return { Cancel = function() end } end }
local function runTimers(seconds)
    local target = now + (seconds or 60)
    while true do
        table.sort(timers, function(a, b) return a.at < b.at end)
        local timer = timers[1]
        if not timer or timer.at > target then break end
        table.remove(timers, 1)
        now = math.max(now, timer.at)
        timer.fn()
    end
    now = target
end
C_Item = {
    GetItemInfo = function() return nil end,
    RequestLoadItemDataByID = function() end,
    GetItemQualityColor = function() return 1, 1, 1, "ffa335ee" end,
    GetItemNameByID = function() return nil end,
}
local loadedItemRequests = {}
C_Item.RequestLoadItemDataByID = function(id) loadedItemRequests[id] = (loadedItemRequests[id] or 0) + 1 end
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
local questObjectives = {}
C_QuestLog.GetQuestObjectives = function(id) return questObjectives[id] end
local completeQuests = {}
C_QuestLog.IsComplete = function(id) return completeQuests[id] == true end
C_Map.CanSetUserWaypointOnMap = function() return true end
-- 客户端副本入口：哀嚎洞穴按名字对应（坐标与插件数据不同），淹没之城按名字、领主大厅按副本 ID 对应
local function vec(x, y) return { GetXY = function() return x, y end } end
local clientEntranceCalls = 0
C_EncounterJournal = { GetDungeonEntrancesForMap = function(mapID)
    clientEntranceCalls = clientEntranceCalls + 1
    if mapID == 1413 then
        return { { name = "Wailing Caverns", journalInstanceID = 240, position = vec(0.461, 0.359) } }
    elseif mapID == 1434 then
        return { { name = "The Drowned City", journalInstanceID = 9001, position = vec(0.21, 0.73) } }
    elseif mapID == 1453 then
        return { { name = "Dalaran Ruins", journalInstanceID = 9002, position = vec(0.62, 0.11) } }
    end
    return {}
end }
EJ_GetInstanceInfo = function(journalID)
    if journalID == 9002 then return "Dalaran", "", 0, 0, 0, 0, 0, "", false, 2959 end
    return nil
end
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
local placeFails = false
PlaceAction = function(slot) if not placeFails then actions[slot] = cursorSpell end end
PickupAction = function(slot) cursorSpell = actions[slot]; actions[slot] = nil end
ClearCursor = function() cursorSpell = nil end
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
local unknownMethods = {}
local function newObject(kind, name)
    local o = { kind = kind, name = name, shown = true, scripts = {}, text = "", checked = false, enabled = true,
        width = 100, height = 100, events = {}, children = {}, parent = false }
    return setmetatable(o, { __index = function(_, key)
        if frameMethods[key] then return frameMethods[key] end
        -- 小写开头的是插件自己的字段，没赋值时与客户端一样是 nil；大写开头的按框架方法处理
        if type(key) ~= "string" or not key:match("^%u") then return nil end
        unknownMethods[key] = true
        return function() return nil end
    end })
end
-- 显示状态变化时，向仍处于显示状态的子框架传递 OnShow / OnHide（与客户端一致）
local function fireTree(frame, script)
    if not frame.shown then return end
    if frame.scripts[script] then frame.scripts[script](frame) end
    for _, child in ipairs(frame.children) do fireTree(child, script) end
end
frameMethods.CreateTexture = function(self)
    local texture = newObject("Texture")
    texture.parent = self
    return texture
end
frameMethods.SetTexture = function(self, path) self.texture = path end
frameMethods.CreateFontString = function() return newObject("FontString") end
frameMethods.CreateMaskTexture = function(self)
    local mask = newObject("MaskTexture")
    mask.parent = self
    return mask
end
frameMethods.AddMaskTexture = function(self, mask)
    self.masks = rawget(self, "masks") or {}
    tinsert(self.masks, mask)
end
frameMethods.SetScript = function(self, name, fn) self.scripts[name] = fn end
frameMethods.HookScript = function(self, name, fn)
    local previous = self.scripts[name]
    self.scripts[name] = previous and function(...) previous(...) fn(...) end or fn
end
frameMethods.GetScript = function(self, name) return self.scripts[name] end
frameMethods.IsVisible = function(self)
    return self.shown and (not self.parent or self.parent:IsVisible())
end
frameMethods.Show = function(self)
    local was = self:IsVisible()
    self.shown = true
    if not was and self:IsVisible() then fireTree(self, "OnShow") end
end
frameMethods.Hide = function(self)
    local was = self:IsVisible()
    if was then fireTree(self, "OnHide") end
    self.shown = false
end
frameMethods.SetShown = function(self, v) if v then self:Show() else self:Hide() end end
frameMethods.IsShown = function(self) return self.shown end
frameMethods.GetParent = function(self) return self.parent end
frameMethods.SetParent = function(self, parent)
    if self.parent then
        for i, child in ipairs(self.parent.children) do
            if child == self then table.remove(self.parent.children, i) break end
        end
    end
    self.parent = parent or false
    if parent then tinsert(parent.children, self) end
end
frameMethods.SetPoint = function(self, point, a, b, c, d)
    -- 记录锚点偏移：SetPoint(point, x, y) 或 SetPoint(point, relative, relativePoint, x, y)
    if type(a) == "number" then self.pointY = b else self.pointY = d end
    if type(a) == "table" then self.relativeTo = a end
    self.point = point
end
frameMethods.SetAllPoints = function(self, relative)
    if type(relative) == "table" then self.relativeTo = relative end
end
frameMethods.SetAlpha = function(self, alpha) self.alpha = alpha end
frameMethods.SetTexCoord = function(self, left, right, top, bottom) self.texCoord = { left, right, top, bottom } end
frameMethods.SetScrollChild = function(self, child) self.scrollChild = child end
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
    f.template = template
    f:SetParent(parent)
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
        pin.UseFrameLevelType = function(self, levelType) self.frameLevelType = levelType end
        -- 与客户端一致：创建时就把当时的 OnMouseEnter / OnMouseLeave 绑成脚本
        pin:SetScript("OnEnter", rawget(pin, "OnMouseEnter"))
        pin:SetScript("OnLeave", rawget(pin, "OnMouseLeave"))
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
check("minimap button sits on the minimap edge for its actual size", function()
    local module = main.modules.MinimapButton
    local button
    for _, f in ipairs(allFrames) do
        if f.parent == Minimap and f.scripts.OnDragStart then button = f; break end
    end
    local angle = math.rad(main.db.modules.MinimapButton.angle or 225)
    for _, width in ipairs({ 198, 140 }) do
        Minimap.width = width
        assert(Minimap.scripts.OnSizeChanged, "minimap size changes not followed")
        Minimap.scripts.OnSizeChanged(Minimap)
        assert(module.Radius() == width / 2 + 5, "radius ignores the minimap size")
        assert(math.abs(button.pointY - math.sin(angle) * (width / 2 + 5)) < 1e-6,
            ("button not on the edge of a %d minimap"):format(width))
    end
end)
check("unlocked item placeholder and drop rate row", function()
    assert(main.ItemLink(999999) == main.L["Item information not yet unlocked"])
    assert(loadedItemRequests[999999], "item load not requested")
    local host = newObject("Frame")
    local stack = main.UI:Stack(host)
    stack:Items({ { id = 999999, rate = 12.5 } }, 0, 30)
    local row = stack.pools.text[1].text
    assert(row:find(main.L["Item information not yet unlocked"], 1, true), "placeholder missing")
    assert(row:find("12.5", 1, true), "drop rate missing")
    assert(not row:find("nverified", 1, true) and not row:find("未验证", 1, true), "item rows must not show an unverified marker")
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
    for _, category in ipairs({ "quests", "bosses", "loot", "npcs", "entrances" }) do
        assert(#T.BuildEntries(category, false) > 0, "empty category " .. category)
    end
    local slug = next(collector.targets.verify.entrances)
    assert(T.Detail("entrances", slug):find("副本入口", 1, true) or T.Detail("entrances", slug) ~= "", "no entrance detail")
    local page
    for _, f in ipairs(allFrames) do
        if rawget(f, "recordButton") then page = f end
    end
    assert(page and page.recordButton, "no record button on the tasks page")
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
check("spellbook page has no website link", function()
    main.MainFrame:Open("spellbook")
    local page = main.modules.Spellbook.page
    for _, f in ipairs(allFrames) do
        if f.parent == page and rawget(f, "label") then
            local text = tostring(f.label.text)
            assert(not text:find("网站", 1, true) and not text:lower():find("website", 1, true), "spellbook page has a website button: " .. text)
        end
    end
end)
check("spellbook rows: learned, trainable and locked look different", function()
    -- 测试客户端是中文，桩里的已学技能是英文名：临时把第一个法师技能的 1 级标为已学
    local first = main.Data.spells.mage[1]
    local savedKnown = main.KnownSpells
    main.KnownSpells = function()
        return { [main.Name(first.name):lower()] = { best = 1, ids = { [1] = 1 } } }
    end
    main.MainFrame:Open("spellbook")
    local page = main.modules.Spellbook.page
    local seen = {}
    for _, row in ipairs(page.tableRows) do
        if row.shown and row.entry then
            local group = row.group
            seen[group] = true
            if group == "ready" then
                assert(row.tint.shown and row.bar.shown and (row.alpha or 1) == 1, "trainable row not highlighted")
            elseif group == "learned" then
                assert(not row.tint.shown and not row.bar.shown and (row.alpha or 1) == 1, "learned row not plain")
            else
                assert(not row.tint.shown and not row.bar.shown, "locked row is tinted")
                assert(row.alpha and row.alpha < 1, "locked row not dimmed")
                assert(row.cells.spell:GetText():find(":110:110:110|t", 1, true), "locked spell icon not dimmed")
            end
        end
    end
    main.KnownSpells = savedKnown
    assert(seen.learned and seen.ready and seen.locked, ("groups seen: learned %s ready %s locked %s"):format(tostring(seen.learned), tostring(seen.ready), tostring(seen.locked)))
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
local function learn(...)
    for i = 1, select("#", ...) do
        fireAll("LEARNED_SPELL_IN_SKILL_LINE", (select(i, ...)), 1, false)
    end
end
check("action bar upgrades lower rank after learning", function()
    learn(1460)
    assert(actions[1] == 1459, "changed before the batch delay")
    runTimers(2)
    assert(actions[1] == 1460, "slot 1 not upgraded, got " .. tostring(actions[1]))
end)
check("new spell goes to an empty main bar slot", function()
    spellNames[2136] = "Fire Blast"
    learn(2136)
    runTimers(2)
    assert(actions[2] == 2136, "new spell not placed")
end)
check("action bars: same-batch ranks give the highest rank in either order (R01)", function()
    for _, order in ipairs({ { 1459, 1460 }, { 1460, 1459 } }) do
        actions = { [2] = 2136 }
        learn(order[1], order[2])
        runTimers(2)
        local slots = C_ActionBar.FindSpellActionButtons(1460)
        assert(#slots == 1 and #C_ActionBar.FindSpellActionButtons(1459) == 0,
            ("order %d,%d left the wrong rank"):format(order[1], order[2]))
    end
    -- 关掉等级提升：只放这一批学会的等级，不悄悄升级
    local settings = main.db.modules.ActionBars
    settings.upgradeRanks = false
    actions = { [2] = 2136 }
    learn(1459)
    runTimers(2)
    assert(#C_ActionBar.FindSpellActionButtons(1459) == 1 and #C_ActionBar.FindSpellActionButtons(1460) == 0,
        "placed a rank that was not learned in this batch")
    settings.upgradeRanks = true
end)
check("action bars: no scan on entering the world; only the learned family changes (R01)", function()
    actions = { [1] = 1459, [2] = 2136 }
    fireAll("PLAYER_ENTERING_WORLD", false, true)
    runTimers(5)
    assert(actions[1] == 1459, "entering the world replaced a rank the player kept")
    learn(2136)
    runTimers(2)
    assert(actions[1] == 1459, "learning another spell touched an unrelated family")
end)
check("action bars: wait while the cursor holds something or in combat (R01)", function()
    actions = { [1] = 1459 }
    cursorItem = "item"
    learn(1460)
    runTimers(3)
    assert(actions[1] == 1459 and cursorItem == "item", "changed bars or cursor while the player was dragging")
    cursorItem = nil
    runTimers(2)
    assert(actions[1] == 1460, "not applied after the cursor was freed")
    actions = { [1] = 1459 }
    inCombat = true
    learn(1460)
    runTimers(2)
    assert(actions[1] == 1459, "changed bars in combat")
    inCombat = false
    fireAll("PLAYER_REGEN_ENABLED")
    assert(actions[1] == 1460, "not applied after combat")
end)
check("action bars: a failed placement is not reported or recorded (R01)", function()
    local module = main.modules.ActionBars
    actions = { [1] = 1459 }
    wipe(module.lastChanges)
    placeFails = true
    learn(1460)
    runTimers(2)
    placeFails = false
    assert(actions[1] == 1459 and #module.lastChanges == 0, "failed placement recorded as a change")
end)
check("action bars: upgrade all from settings, then undo (R01)", function()
    local module = main.modules.ActionBars
    actions = { [1] = 1459, [5] = 1459, [2] = 2136 }
    assert(module:UpgradeAll())
    assert(actions[1] == 1460 and actions[5] == 1460 and actions[2] == 2136, "upgrade all failed")
    actions[5] = 2136 -- 玩家之后自己改过的按钮不还原
    assert(module:Undo())
    assert(actions[1] == 1459 and actions[5] == 2136, "undo restored the wrong buttons")
    inCombat = true
    assert(not module:UpgradeAll(), "upgrade all ran in combat")
    inCombat = false
    actions = { [1] = 1460, [2] = 2136 }
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
            assert(pin.frameLevelType == "PIN_FRAME_LEVEL_DUNGEON_ENTRANCE", "dungeon pin has no frame level type")
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
            GameTooltip.text = ""
            assert(pin.scripts.OnEnter, "hover script not bound")
            pin.scripts.OnEnter(pin)
            assert(GameTooltip.text == pin.whLines[1], "hovering the pin shows no tooltip")
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
check("dungeon entrances come from the client first, plugin data as fallback", function()
    local D = main.Data.dungeons
    local function indexOf(slug) for i, d in ipairs(D) do if d.slug == slug then return i end end end
    -- 数据有坐标的副本：客户端给了就用客户端的
    local map, x, y = main.DungeonEntrance(indexOf("wailing-caverns"))
    assert(map == 1413 and math.abs(x - 46.1) < 1e-6 and math.abs(y - 35.9) < 1e-6, "client entrance not preferred")
    -- 数据只有地图的新副本：按名字（忽略 The 与标点）对应
    map, x, y = main.DungeonEntrance(indexOf("drowned-city"))
    assert(map == 1434 and math.abs(x - 21) < 1e-6, "new dungeon entrance not taken from the client")
    -- 数据连地图都没有：扫描区域地图，按副本 ID 对应（客户端名字不同也能对上）
    map, x, y = main.DungeonEntrance(indexOf("city-of-dalaran"))
    assert(map == 1453 and math.abs(y - 11) < 1e-6, "entrance without a map not found by instance ID")
    -- 游戏里记录、导入网站的入口：客户端没给时用数据
    map, x, y = main.DungeonEntrance(indexOf("hall-of-thanes"))
    assert(map == 1455 and x == 27.8 and y == 47.9, "recorded hall of thanes entrance not used")
    -- 客户端没有、数据有：用数据
    map = main.DungeonEntrance(indexOf("ragefire-chasm"))
    assert(map == 1454, "data fallback lost")
    -- 按地图缓存：再查不再调用客户端
    local calls = clientEntranceCalls
    main.DungeonEntrance(indexOf("city-of-dalaran"))
    main.DungeonEntrance(indexOf("drowned-city"))
    assert(clientEntranceCalls == calls, "client entrances not cached")
    -- 大地图：哀嚎洞穴只画一次，位置是客户端的
    local provider = WorldMapFrame.providers[3]
    provider:RefreshAllData()
    local wc = 0
    for _, pin in ipairs(pins) do
        if pin.template == "WowHandbookDungeonPinTemplate" and pin.whLines[1] == main.Name(D[indexOf("wailing-caverns")].name) then
            wc = wc + 1
            assert(math.abs(pin.x - 0.461) < 1e-6, "map pin not at the client position")
        end
    end
    provider:RemoveAllData()
    assert(wc == 1, "wailing caverns drawn " .. wc .. " times")
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
    assert(tostring(pin.whTexture.texture):find("spell_holy_guardianspirit$"), "spirit healer icon is not the guardian spirit")
    -- 图钉层级必须高于“已探索区域”的地图贴图，否则探索过的地方看不到图标（悬停仍有提示）
    assert(pin.frameLevelType == "PIN_FRAME_LEVEL_SELECTABLE_GRAVEYARD", "spirit healer pin has no frame level type")
    -- 圆形徽章不用遮罩（这个客户端里用遮罩裁圆的图钉整个不显示），用小地图按钮的圆底与圆环
    assert(tostring(pin.whRing.texture):find("MiniMap%-TrackingBorder$") and tostring(pin.whBackground.texture):find("UI%-Minimap%-Background$"),
        "spirit healer badge is not built like the minimap button")
    for _, texture in ipairs({ pin.whRing, pin.whBackground, pin.whTexture, pin.whHighlight }) do
        assert(not rawget(texture, "masks"), "a pin texture uses a mask")
        local relative = rawget(texture, "relativeTo")
        assert(not (relative and relative.kind == "MaskTexture"), "a pin texture is anchored to a mask texture")
    end
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
check("spirit healers: game list and plugin data are merged, same spot drawn once", function()
    local W = main.modules.WorldMap
    local saved = C_DeathInfo
    -- 游戏只给湿地米奈希尔港附近的一个墓地（坐标与插件数据略有出入）
    C_DeathInfo = { GetGraveyardsForMap = function(mapID)
        if mapID == 1437 then
            return { { name = "Menethil Harbor", position = { GetXY = function() return 0.112, 0.436 end } } }
        end
        return {}
    end }
    local spots = W.GraveyardsForMap(1437)
    C_DeathInfo = saved
    assert(#spots == 2, ("expected 2 spirit healers in the Wetlands, got %d"):format(#spots))
    assert(spots[1][3] == "Menethil Harbor", "game graveyard not first")
    assert(math.abs(spots[2][1] - 49.3) < 1e-6 and math.abs(spots[2][2] - 41.8) < 1e-6, "central Wetlands spirit healer missing")
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
check("quest list: compact status icons and chain progress, names never run under the tags", function()
    local D = main.modules.Dungeons
    local deadmines
    for _, d in ipairs(main.Data.dungeons) do if d.slug == "deadmines" then deadmines = d end end
    local savedFaction = UnitFactionGroup
    UnitFactionGroup = function() return "Alliance" end
    local entries = D.QuestEntries(deadmines)
    UnitFactionGroup = savedFaction
    local chainRow
    for _, entry in ipairs(entries) do
        if entry.id == 92753 then chainRow = entry end
        if entry.tags and not entry.divider then
            assert(not entry.tags:find(main.L["Chain"], 1, true), "chain word still in the tags: " .. entry.tags)
            for _, word in ipairs({ "Ready to pick up", "Needs earlier quests", "Level too low", "Accepted", "Completed" }) do
                assert(not entry.tags:find(main.L[word], 1, true), "status word still in the tags: " .. entry.tags)
            end
        end
    end
    assert(chainRow and chainRow.tags:find("%d+/10"), "chain progress not compact: " .. tostring(chainRow and chainRow.tags))
    -- 列表行：名字的右边界是右侧标签，不是写死的宽度
    local list = main.UI:List(CreateFrame("Frame"), 22, function() end)
    list:SetData({ { id = 1, text = "A very long quest name that would run under the tags", tags = "4/10" } })
    local row
    for _, f in ipairs(allFrames) do
        if rawget(f, "label") and rawget(f, "tags") and f.label.text == "A very long quest name that would run under the tags" then row = f end
    end
    assert(row and row.label.relativeTo == row.tags, "list label is not bounded by the tags")
end)
check("quest list: an expanded chain keeps the dungeon quest on top and lists it again as the last step", function()
    local D = main.modules.Dungeons
    local deadmines
    for _, d in ipairs(main.Data.dungeons) do if d.slug == "deadmines" then deadmines = d end end
    local savedFaction = UnitFactionGroup
    UnitFactionGroup = function() return "Alliance" end
    D.questState.expanded[92753] = true
    local entries = D.QuestEntries(deadmines)
    D.questState.expanded[92753] = nil
    local collapsed = D.QuestEntries(deadmines)
    UnitFactionGroup = savedFaction
    local _, chain = D.Classify(92753)
    local owner
    for i, entry in ipairs(entries) do
        if entry.id == 92753 then owner = i end
    end
    assert(owner and entries[owner].chainOwner == 92753, "dungeon quest header row missing")
    for i, stepID in ipairs(chain) do
        assert(entries[owner + i].step == stepID, "chain step out of order at " .. i)
    end
    assert(entries[owner + #chain].step == 92753, "dungeon quest is not the last step")
    for _, entry in ipairs(collapsed) do
        assert(not (entry.step and tostring(entry.id):find(":92753:", 1, true)), "collapsed chain still shows steps")
    end
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
check("home dashboard: status and cards, no coming-up timeline", function()
    assert(main.Home.page == nil or rawget(main.Home.page, "timeline") == nil, "coming-up timeline still on the home page")
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
check("home: zones to level in ascending level order, with their continent", function()
    local Home = main.Home
    local savedInfo, savedLevel = C_Map.GetMapInfo, playerLevel
    Enum.UIMapType = { Continent = 2, Zone = 3 }
    local kalimdor = { [1411] = true, [1412] = true, [1413] = true, [1438] = true, [1439] = true, [1440] = true, [1441] = true, [1442] = true }
    C_Map.GetMapInfo = function(id)
        if id == 1414 then return { name = "Kalimdor", mapType = 2 } end
        if id == 1415 then return { name = "Eastern Kingdoms", mapType = 2 } end
        return { name = "Zone " .. id, mapType = 3, parentMapID = kalimdor[id] and 1414 or 1415 }
    end
    playerLevel = 20
    local zones = Home.RecommendedZones(4)
    assert(#zones >= 2, "not enough zones at level 20")
    for i = 2, #zones do
        local a, b = zones[i - 1].zone.levels, zones[i].zone.levels
        assert(a[1] < b[1] or (a[1] == b[1] and a[2] <= b[2]), "zones not in ascending level order")
    end
    main.MainFrame:Open("home")
    Home.Refresh()
    local note = Home.page.cards.zones.lines[1].note:GetText()
    local expected = main.ContinentName(zones[1].id)
    C_Map.GetMapInfo, playerLevel = savedInfo, savedLevel
    Enum.UIMapType = nil
    assert(expected == "Kalimdor" or expected == "Eastern Kingdoms", "continent not found: " .. tostring(expected))
    assert(note:find(expected, 1, true), "zone line has no continent: " .. note)
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

check("quest view stays inside the selected dungeon (R02)", function()
    local D = main.modules.Dungeons
    local withQuests = {}
    for index, dungeon in ipairs(main.Data.dungeons) do
        local entries, info = D.QuestEntries(dungeon)
        local first
        for _, entry in ipairs(entries) do
            if not entry.step and not entry.divider then first = entry.id break end
        end
        if first then tinsert(withQuests, { index = index, first = first, info = info }) end
        if #withQuests == 2 then break end
    end
    local a, b = withQuests[1], withQuests[2]
    assert(a and b, "need two dungeons with quests")
    assert(not b.info[a.first], "test dungeons share a quest")
    D.questState.selected, D.questState.selectedRow = nil, nil
    assert(D:Select(a.index, "quests"))
    D.questState.selected, D.questState.selectedRow = a.first, a.first
    assert(D:Select(b.index, "quests"))
    assert(D.questState.selected == b.first and D.questState.selectedRow == nil,
        "dungeon B still shows quest " .. tostring(D.questState.selected) .. " from dungeon A")
    -- 首页跳转预先指定的任务属于本副本时保留
    local target
    for id in pairs(a.info) do if id ~= a.first then target = id break end end
    if target then
        D.questState.selected, D.questState.selectedRow = target, target
        assert(D:Select(a.index, "quests"))
        assert(D.questState.selected == target, ("preselected quest %s from the home page was dropped, got %s"):format(target, tostring(D.questState.selected)))
    end
end)
check("dungeon recommendations: none below every dungeon, highest above them (R05)", function()
    local saved = playerLevel
    playerLevel = 1
    local low = main.modules.Dungeons.Summary(3).recommended
    playerLevel = 70
    local high = main.modules.Dungeons.Summary(3).recommended
    playerLevel = saved
    assert(#low == 0, "level 1 was recommended " .. tostring(low[1] and low[1].name))
    assert(#high > 0, "no fallback above every dungeon")
end)
check("full map edge tiles sample the whole edge texture (R03)", function()
    local size = main.modules.WorldMap.TileFileSize
    assert(size(256, 256) == 256 and size(128, 256) == 128 and size(25, 256) == 32)
    assert(size(100, 256) == 128 and size(1, 256) == 16 and size(16, 256) == 16 and size(17, 256) == 32)
    -- 实际绘制：最右一列只剩 128 像素时，横向应取满贴图（1），而不是 128/256
    local revealProvider = WorldMapFrame.providers[2]
    local originalData = main.Data.mapOverlays[1413]
    main.Data.mapOverlays[1413] = { originalData[1], { 384, 256, 0, 0, 11, 12 } }
    C_MapExplorationInfo = { GetExploredMapTextures = function() return {} end }
    local coords = {}
    local originalSet = frameMethods.SetTexCoord
    frameMethods.SetTexCoord = function(self, l, r, t, b) tinsert(coords, { r, b }) originalSet(self, l, r, t, b) end
    local ok, err = pcall(function() revealProvider:RefreshAllData() end)
    frameMethods.SetTexCoord = originalSet
    main.Data.mapOverlays[1413] = originalData
    assert(ok, err)
    local found = false
    for _, c in ipairs(coords) do
        assert(c[1] <= 1 and c[2] <= 1, "texture coordinate above 1")
        if c[1] == 1 and c[2] == 1 then found = true end
    end
    assert(#coords >= 2 and found, "edge tile coordinates wrong")
end)
check("known spell cache refreshes without the spellbook modules (R04)", function()
    local before = main.KnownSpells()
    assert(not before["frost nova"], "test spell already known")
    local original = C_SpellBook.GetSpellBookSkillLineInfo
    local originalItem = C_SpellBook.GetSpellBookItemInfo
    C_SpellBook.GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = 3, shouldHide = false } end
    C_SpellBook.GetSpellBookItemInfo = function(slot, bank)
        if slot == 3 and bank ~= 1 then return { spellID = 122, name = "Frost Nova", subName = "Rank 1" } end
        return originalItem(slot, bank)
    end
    fireAll("SPELLS_CHANGED")
    local after = main.KnownSpells()
    C_SpellBook.GetSpellBookSkillLineInfo, C_SpellBook.GetSpellBookItemInfo = original, originalItem
    fireAll("SPELLS_CHANGED")
    assert(after["frost nova"], "cache not invalidated by the core")
end)
check("settings: body scrolls and About sits below every panel (R06)", function()
    main.MainFrame:SelectTab("settings")
    local page
    for _, f in ipairs(allFrames) do
        if rawget(f, "about") then page = f end
    end
    assert(page and page.scroll and page.about.parent == page.scroll.scrollChild, "settings body not in a scroll area")
    local lowest = 0
    for _, child in ipairs(page.scroll.scrollChild.children) do
        if child ~= page.about and child.pointY then
            lowest = math.min(lowest, child.pointY - child.height)
        end
    end
    assert(page.about.pointY <= lowest, ("About at %s overlaps a panel ending at %s"):format(page.about.pointY, lowest))
    assert(page.contentHeight >= -page.about.pointY + page.about.height, "content height too small")
end)
check("hidden pages stop refreshing; item requests are deduplicated with backoff (R07)", function()
    local D = main.modules.Dungeons
    assert(D:Select(1, "loot"))
    local title = D.page.detail.title
    local renders = 0
    local originalSetText = frameMethods.SetText
    title.SetText = function(self, t) renders = renders + 1 originalSetText(self, t) end
    fireAll("QUEST_LOG_UPDATE")
    runTimers(1)
    local visibleRenders = renders
    main.MainFrame:Hide()
    renders = 0
    fireAll("QUEST_LOG_UPDATE")
    runTimers(1)
    title.SetText = nil
    assert(visibleRenders > 0, "visible page did not refresh")
    assert(renders == 0, "hidden page refreshed " .. renders .. " times")
    -- 物品请求：等待中不重复；失败后退避，到时间再试；不是本插件请求的物品不触发刷新
    local id = 888888
    loadedItemRequests[id] = nil
    main.ItemLink(id)
    main.ItemLink(id)
    assert(loadedItemRequests[id] == 1, "duplicate request while pending")
    fireAll("GET_ITEM_INFO_RECEIVED", id, false)
    main.ItemLink(id)
    assert(loadedItemRequests[id] == 1, "retried without backoff")
    runTimers(6)
    main.ItemLink(id)
    assert(loadedItemRequests[id] == 2, "never retried after backoff")
    local notified = 0
    main.OnItemLoaded(function() notified = notified + 1 end)
    fireAll("GET_ITEM_INFO_RECEIVED", 777777, true)
    fireAll("GET_ITEM_INFO_RECEIVED", id, true)
    assert(notified == 1, "listeners notified " .. notified .. " times")
    main.MainFrame:Open("home")
end)
check("dungeon home: one grid, suitable dungeons highlighted, faction watermarks, no site link on the dungeon page", function()
    local D = main.modules.Dungeons
    local function indexOf(slug) for i, d in ipairs(main.Data.dungeons) do if d.slug == slug then return i end end end
    assert(D.Territory(indexOf("hall-of-thanes")) == "alliance", "hall of thanes not alliance territory")
    assert(D.Territory(indexOf("ragefire-chasm")) == "horde", "ragefire chasm not horde territory")
    assert(D.Territory(indexOf("gnomeregan")) == "alliance" and D.Territory(indexOf("zulfarrak")) == "contested")
    local saved = playerLevel
    playerLevel = 16
    main.MainFrame:Open("dungeons")
    D:ShowHome()
    local cards = D.page.home.cards
    local highlighted, watermarks = 0, 0
    for _, card in ipairs(cards) do
        if card.shown then
            local dungeon = main.Data.dungeons[card.index]
            assert(card.highlighted == D.Suitable(dungeon), "highlight does not match suitability: " .. dungeon.slug)
            if card.highlighted then
                highlighted = highlighted + 1
                assert(card.badge.shown, "suitable card has no badge")
            end
            if card.watermark.shown then
                watermarks = watermarks + 1
                assert(tostring(card.watermark.texture):find("Media\\Faction"), "watermark is not the site emblem")
            end
            assert(card.facts:GetText() ~= "" and card.quests:GetText() ~= "", "card rows empty")
        end
    end
    assert(highlighted > 0 and watermarks > 0, ("highlighted %d watermarks %d"):format(highlighted, watermarks))
    assert(D.homeFirstSuitableRow ~= nil, "no suitable row found at level 16")
    playerLevel = saved
    D:ShowHome()
    -- 副本详情页：没有网站链接按钮，右上角是入口标记
    assert(D:Select(indexOf("ragefire-chasm"), "quests"))
    local detail = D.page.detail
    for _, f in ipairs(allFrames) do
        if f.parent == detail and f.label and tostring(f.label.text):find(main.L["Copy website link"], 1, true) then
            error("dungeon page still has a website link")
        end
    end
    assert(detail.markEntrance.shown, "no entrance button on the dungeon page")
    main.MainFrame:Hide()
end)
check("Toxic Soil is outside; expanded chain lists the owner once more as its last step", function()
    local D = main.modules.Dungeons
    local savedFaction = main.PlayerFaction
    main.PlayerFaction = function() return "A" end
    local saved = D.questState.expanded[92753]
    D.questState.expanded[92753] = true
    local ok, err = pcall(function()
        local rows = D.QuestEntries({ quests = { 92753 } })
        assert(rows[1].id == "section:outside", "explosives incorrectly start inside")
        local owners, steps = 0, 0
        for _, row in ipairs(rows) do
            if row.id == 92753 then owners = owners + 1 end
            if row.step then steps = steps + 1 end
        end
        -- 用户 2026-09-29：展开时副本任务行仍在最上面，链的最后一步再列出副本任务本身
        assert(owners == 1 and steps == 10 and rows[#rows].step == 92753, "wrong main/step row counts")
    end)
    D.questState.expanded[92753] = saved
    main.PlayerFaction = savedFaction
    assert(ok, err)
end)
check("external class quests have their own section and do not inflate dungeon recommendations", function()
    local D = main.modules.Dungeons
    local savedQuest, savedClass = main.Data.quests[1654], playerClass
    local savedFaction = UnitFactionGroup
    UnitFactionGroup = function() return "Alliance" end
    main.Data.quests[1654] = { min = 20, relatedExternal = true, classRestriction = "PALADIN" }
    local dungeon = { quests = { 1654 } }
    playerClass = { "Paladin", "PALADIN" }
    local entries = D.QuestEntries(dungeon)
    assert(#entries == 2 and entries[1].id == "section:external", "external quest missing its section")
    assert(entries[2].id == 1654 and entries[2].tags:find(main.L["Paladin class quest"], 1, true),
        "external quest missing class label")
    local total, done, ready, active = D.QuestSummary(dungeon)
    assert(total == 0 and done == 0 and ready == 0 and active == 0, "external quest counted as ordinary dungeon quest")
    for _, entry in ipairs(D.Summary(100).prep) do
        assert(entry.quest ~= 1654, "external quest recommended as dungeon preparation")
    end
    playerClass = { "Warrior", "WARRIOR" }
    assert(#D.QuestEntries(dungeon) == 0, "paladin quest offered to another class")
    main.Data.quests[1654], playerClass = savedQuest, savedClass
    UnitFactionGroup = savedFaction
end)
check("dungeon card: quests in the log are not counted as to pick up", function()
    local D = main.modules.Dungeons
    local dungeon
    for _, d in ipairs(main.Data.dungeons) do if d.slug == "hall-of-thanes" then dungeon = d end end
    local savedFaction = UnitFactionGroup
    UnitFactionGroup = function() return "Alliance" end
    local savedCompleted, savedActive = completedQuests, activeQuests
    completedQuests, activeQuests = {}, {}
    local total = D.QuestSummary(dungeon)
    -- 全部接了、除了一个都交了
    local all = {}
    for _, id in ipairs(dungeon.quests) do
        local q = main.Data.quests[id]
        if not q.extra and (not q.faction or q.faction == "A") then tinsert(all, id) end
    end
    for i, id in ipairs(all) do
        if i == 1 then activeQuests[id] = true else completedQuests[id] = true end
        for _, step in ipairs(select(2, D.Classify(id)) or {}) do
            if step ~= id then completedQuests[step] = true end
        end
    end
    local _, done, ready, active = D.QuestSummary(dungeon)
    completedQuests, activeQuests = savedCompleted, savedActive
    UnitFactionGroup = savedFaction
    assert(total == #all and done == #all - 1 and ready == 0 and active == 1,
        ("total %d done %d ready %d active %d"):format(total, done, ready, active))
end)
check("instance tracker: external class quests only track accepted quests for their class", function()
    local savedClass, savedStatus, savedFaction = main.PlayerClass, main.QuestStatus, main.PlayerFaction
    main.PlayerClass = function() return "paladin" end
    main.QuestStatus = function() return "available" end
    main.PlayerFaction = function() return "A" end
    local dungeon = { quests = { 1654 } }
    local rows, done, outside = main.modules.InstanceTracker.QuestRows(dungeon)
    assert(#rows == 0 and done == 0 and outside == 0, "external quest counted as preparation")
    main.QuestStatus = function() return "active" end
    rows = main.modules.InstanceTracker.QuestRows(dungeon)
    assert(#rows == 1, "accepted class quest not tracked")
    main.PlayerClass = function() return "warrior" end
    rows = main.modules.InstanceTracker.QuestRows(dungeon)
    assert(#rows == 0, "wrong class quest tracked")
    main.PlayerClass, main.QuestStatus, main.PlayerFaction = savedClass, savedStatus, savedFaction
end)
check("instance tracker: shows in an instance, tracks kills per instance copy, quests and sections", function()
    local T = main.modules.InstanceTracker
    local f = WowHandbookInstanceFrame
    assert(T.enabled and f and f.shown, "tracker not shown inside Ragefire Chasm")
    local runs = main.charDB.instanceRuns
    local function killed(encounterName, units)
        fireAll("ENCOUNTER_END", 1, encounterName, 1, 5, 1, units or {})
    end
    local function targetGUID(guid)
        local saved = UnitGUID
        UnitGUID = function(unit) if unit == "target" then return guid end return saved(unit) end
        fireAll("PLAYER_TARGET_CHANGED")
        UnitGUID = saved
    end
    local function progress()
        return (f.progress:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
    end
    assert(progress() == "0 / 4", "progress: " .. progress())
    -- 首领战结束：按本场首领的 creatureID 对应
    targetGUID("Creature-0-1-389-100-9999-0000AAAA")
    killed("Bazzalan", { { creatureID = 11519, creatureName = "Bazzalan", remainingHealthPercent = 0 } })
    assert(runs[389].killed["npc:11519"] and progress() == "1 / 4", "kill by creature ID not tracked")
    killed("Some Trogg", { { creatureID = 9999, creatureName = "Some Trogg", remainingHealthPercent = 0 } })
    assert(progress() == "1 / 4", "trash counted as a boss")
    fireAll("ENCOUNTER_END", 1, "Oggleflint", 1, 5, 0, { { creatureID = 11517, creatureName = "Oggleflint" } })
    assert(not runs[389].killed["npc:11517"], "a wipe counted as a kill")
    -- 同一实例里死亡跑尸、重进：保留；选中另一个实例编号的怪：新进度，清空
    fireAll("PLAYER_ENTERING_WORLD")
    assert(runs[389].killed["npc:11519"], "kills lost on re-entering the same instance")
    targetGUID("Creature-0-1-389-200-9999-0000BBBB")
    assert(not runs[389].killed["npc:11519"], "new instance copy did not reset kills")
    killed("Oggleflint", { { creatureID = 11517, creatureName = "Oggleflint" } })
    assert(runs[389].killed["npc:11517"], "kill after reset not tracked")
    -- 秘密值：creatureID、名字都加密时跳过不报错；creatureID 加密时按名字对应
    targetGUID(SECRET)
    killed(SECRET, { { creatureID = SECRET, creatureName = SECRET } })
    assert(not runs[389].killed["npc:11518"], "secret values counted as a kill")
    killed("Jergosh", { { creatureID = SECRET, creatureName = "Jergosh the Invoker" } })
    assert(runs[389].killed["npc:11518"], "kill with a secret creature ID not matched by name")
    -- 没有首领列表时按首领战名字对应
    killed("Taragaman the Hungerer")
    assert(runs[389].killed["npc:11520"], "encounter end not matched by name")
    -- 战斗记录是受限事件：任何时候都不订阅
    for _, frame in ipairs(allFrames) do
        assert(not frame.events.COMBAT_LOG_EVENT_UNFILTERED, "combat log subscribed (blocked by the client)")
    end
    -- 任务：已接的列出进度，未接的只给数量
    local rfc
    for index, dungeon in ipairs(main.Data.dungeons) do if dungeon.slug == "ragefire-chasm" then rfc = index end end
    local questID
    for _, id in ipairs(main.Data.dungeons[rfc].quests) do
        local q = main.Data.quests[id]
        if q.faction ~= "A" and not completedQuests[id] then questID = id break end
    end
    activeQuests[questID] = true
    questObjectives[questID] = { { text = "Ragefire Trogg slain: 3/8", finished = false } }
    local rows = T.QuestRows(main.Data.dungeons[rfc])
    assert(rows[1] and rows[1].id == questID and rows[1].kind == "active", "active quest not listed")
    T.Refresh()
    completeQuests[questID] = true
    rows = T.QuestRows(main.Data.dungeons[rfc])
    assert(rows[1].kind == "complete", "complete quest not marked")
    activeQuests[questID], completeQuests[questID], questObjectives[questID] = nil, nil, nil
    -- 卡片：首领行悬停显示掉落，点击打开手册掉落页；任务行悬停显示目标与奖励，点击打开任务页并选中
    T.Refresh()
    local bossRow, questRow
    for _, row in ipairs(f.rows) do
        if row.shown and rawget(row, "boss") and not bossRow then bossRow = row end
        if row.shown and rawget(row, "questID") and not questRow then questRow = row end
    end
    assert(bossRow and bossRow.scripts.OnEnter, "no hoverable boss row")
    GameTooltip.lines, GameTooltip.doubleLines = {}, {}
    GameTooltip.AddDoubleLine = function(self, left) tinsert(self.doubleLines, left) end
    bossRow.scripts.OnEnter(bossRow)
    local lootCount = 0
    for _, entry in ipairs(bossRow.boss.items or {}) do lootCount = lootCount + 1 end
    assert(#GameTooltip.doubleLines == math.min(lootCount, 14), ("boss tooltip lists %d of %d items"):format(#GameTooltip.doubleLines, lootCount))
    bossRow.scripts.OnLeave(bossRow)
    bossRow.scripts.OnClick(bossRow)
    assert(WowHandbookMainFrame.shown and main.modules.Dungeons.page.detail.shown, "boss click did not open the loot page")
    main.MainFrame:Hide()
    activeQuests[questID] = true
    questObjectives[questID] = { { text = "Ragefire Trogg slain: 3/8", finished = false } }
    T.Refresh()
    for _, row in ipairs(f.rows) do
        if row.shown and rawget(row, "questID") == questID then questRow = row end
    end
    assert(questRow and questRow.tag:GetText():find("0/1", 1, true), "quest row has no objective progress")
    GameTooltip.lines = {}
    questRow.scripts.OnEnter(questRow)
    local found = false
    for _, line in ipairs(GameTooltip.lines) do if line == "Ragefire Trogg slain: 3/8" then found = true end end
    assert(found, "quest tooltip has no objectives")
    questRow.scripts.OnClick(questRow)
    assert(main.modules.Dungeons.questState.selected == questID, "quest click did not select the quest")
    main.MainFrame:Hide()
    activeQuests[questID], questObjectives[questID] = nil, nil
    GameTooltip.AddDoubleLine = nil
    -- 收起、关闭：关闭后同一次副本内不再自动弹出，/wh instance 可以再打开
    local tall = f.height
    main.db.modules.InstanceTracker.collapsed = true
    T.Refresh()
    assert(f.height < tall, "collapse did not shrink the window")
    main.db.modules.InstanceTracker.collapsed = false
    f.close.scripts.OnClick(f.close)
    assert(not f.shown, "close did not hide")
    fireAll("ZONE_CHANGED_NEW_AREA")
    assert(not f.shown, "reopened after closing")
    SlashCmdList.WOWHANDBOOK("instance")
    assert(f.shown, "/wh instance did not reopen")
    -- 共用副本 ID 的分区：哪个分区的首领死了就切到哪个区
    local savedInstance = GetInstanceInfo
    GetInstanceInfo = function() return "Scarlet Monastery", "party", 1, "", 5, 0, false, 189 end
    fireAll("PLAYER_ENTERING_WORLD")
    assert(f.section.shown, "no section selector for a shared instance")
    local library, libraryBoss
    for index, dungeon in ipairs(main.Data.dungeons) do
        if dungeon.slug == "scarlet-monastery-library" then
            library = dungeon
            for _, boss in ipairs(dungeon.bosses) do if boss.npcID then libraryBoss = boss break end end
        end
    end
    killed(libraryBoss.name.enUS, { { creatureID = libraryBoss.npcID, creatureName = libraryBoss.name.enUS } })
    assert(f.title:GetText() == main.Name(library.name), "did not switch to the library: " .. tostring(f.title:GetText()))
    -- 离开副本：隐藏并注销战斗记录
    GetInstanceInfo = function() return "Durotar", "none", 0, "", 0, 0, false, 1 end
    fireAll("PLAYER_ENTERING_WORLD")
    assert(not f.shown, "still shown outside an instance")
    for _, frame in ipairs(allFrames) do
        assert(not frame.events.ENCOUNTER_END, "encounter events still registered outside instances")
    end
    GetInstanceInfo = savedInstance
end)
check("XML pin templates match the names used in code and only inherit templates the client has", function()
    local xml = assert(io.open("WowHandbook/UI/MapPins.xml")):read("a")
    -- 已对照 1.60.1 客户端界面源码确认存在的暴雪模板；新增继承前先核对源码再加进来
    local CLIENT_TEMPLATES = { FlightPointPinTemplate = true }
    for parents in xml:gmatch('inherits="([^"]+)"') do
        for parent in parents:gmatch("[%w_]+") do
            assert(CLIENT_TEMPLATES[parent], "inherits a template not confirmed in the client: " .. parent)
        end
    end
    -- 不继承模板的图钉必须在创建时混入基础图钉方法，否则地图放置图钉时会调用空值
    for tag in xml:gmatch("<Frame[^>]-/?>") do
        if not tag:find("inherits=") and not tag:find("/>$") then
            local name = tag:match('name="([^"]+)"')
            local body = xml:match('name="' .. name .. '".-</Frame>')
            assert(body and body:find("Mixin%(self, MapCanvasPinMixin%)"), name .. " has no pin methods")
        end
    end
    local defined = {}
    for name in xml:gmatch('name="(WowHandbook[%w_]+)"') do defined[name] = true end
    local lua = assert(io.open("WowHandbook/Modules/WorldMap.lua")):read("a")
    local used = 0
    for name in lua:gmatch('"(WowHandbook[%w_]+Template)"') do
        used = used + 1
        assert(defined[name], "template not defined in MapPins.xml: " .. name)
    end
    assert(used > 0, "no templates referenced")
end)

local unknown = {}
for name in pairs(unknownMethods) do tinsert(unknown, name) end
table.sort(unknown)
print("NOTE 桩未实现、按空函数处理的方法（需对照客户端 API 核对）: " .. table.concat(unknown, ", "))

if failures > 0 then
    print(failures .. " check(s) failed")
    os.exit(1)
end
print("all ui checks passed")
