-- 界面冒烟测试：用“万能”框架桩加载主插件（以及存在时的本地扩展插件），实际执行界面创建与交互路径
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
    if type(a) == "number" then self.pointX, self.pointY = a, b else self.pointX, self.pointY = c, d end
    if type(a) == "table" then self.relativeTo = a end
    self.point = point
end
frameMethods.SetAllPoints = function(self, relative)
    if type(relative) == "table" then self.relativeTo = relative end
end
frameMethods.SetAlpha = function(self, alpha) self.alpha = alpha end
frameMethods.SetColorTexture = function(self, r, g, b, alpha) self.color = { r, g, b, alpha } end
frameMethods.SetBackdropColor = function(self, r, g, b, alpha) self.backdropColor = { r, g, b, alpha } end
frameMethods.SetBackdropBorderColor = function(self, r, g, b, alpha) self.borderColor = { r, g, b, alpha } end
frameMethods.SetTextColor = function(self, r, g, b, alpha) self.textColor = { r, g, b, alpha } end
frameMethods.SetDesaturated = function(self, desaturated) self.desaturated = desaturated and true or false end
frameMethods.SetVertexColor = function(self, r, g, b) self.vertexColor = { r, g, b } end
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
frameMethods.GetFrameLevel = function(self) return rawget(self, "frameLevel") or 1 end
frameMethods.SetFrameLevel = function(self, level) self.frameLevel = level end
frameMethods.GetScale = function() return 1 end
frameMethods.GetVerticalScroll = function() return 0 end
frameMethods.GetName = function(self) return self.name end
frameMethods.IsEnabled = function(self) return self.enabled end
frameMethods.IsMouseOver = function() return false end
-- Forever 客户端没有旧版专业窗口的这些事件：注册会报错（2026-09-29 专业模块因此没能启用）
local UNKNOWN_EVENTS = { TRADE_SKILL_UPDATE = true, CRAFT_SHOW = true, CRAFT_UPDATE = true }
C_EventUtils = { IsEventValid = function(e) return not UNKNOWN_EVENTS[e] end }
frameMethods.RegisterEvent = function(self, e)
    if UNKNOWN_EVENTS[e] then
        error(('Frame:RegisterEvent(): Attempt to register unknown event "%s"'):format(e))
    end
    self.events[e] = true
end
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
    if type(target) == "string" then -- 挂全局函数：hooksecurefunc("名字", hook)
        target, method, hook = _G, target, method
    end
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

-- 本地扩展插件不在公开仓库中：没有时跳过相关检查
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
check("minimap button right-click opens a quick settings menu that changes settings in place", function()
    local module = main.modules.MinimapButton
    -- 改大地图选项会刷新整张地图；这里只验证设置值，刷新换成记次数（后面的大地图测试依赖图层还没画过）
    local worldMap = main.modules.WorldMap
    local savedRefresh, refreshed = worldMap.Refresh, 0
    worldMap.Refresh = function() refreshed = refreshed + 1 end
    local button
    for _, f in ipairs(allFrames) do
        if f.parent == Minimap and f.scripts.OnDragStart then button = f; break end
    end
    button.scripts.OnClick(button, "RightButton")
    local menu = module.menu
    assert(menu and menu.shown, "right-click did not open the menu")
    assert(not (WowHandbookMainFrame and WowHandbookMainFrame.shown), "right-click opened the main window")
    local function find(kind, text)
        for _, row in ipairs(menu.rows) do
            local entryText = row.shown and row.entry and row.entry.text
            if entryText and row.entry.kind == kind and entryText:sub(-#text) == text then return row end
        end
    end
    local L = main.L
    assert(find("title", L["WoW Handbook"]), "menu has no title")
    -- 紧凑：行首是图标，名称是短名，完整说明在悬停提示里
    local sell = find("check", L["Sell gray items"])
    assert(sell and sell.entry.checked, "sell junk option missing or not checked")
    assert(sell.entry.text:find("^|T") and sell.entry.tip == L["Sell gray items automatically when I open a vendor"],
        "menu row has no icon or no full description in its tip")
    assert(menu.width < 260, ("menu is too wide: %d"):format(menu.width))
    -- 勾选项：点一下关掉，菜单保持打开，勾选状态跟着变
    sell.scripts.OnClick(sell)
    assert(main.db.modules.Vendor.sellJunk == false and menu.shown, "check did not change the setting in place")
    assert(not find("check", L["Sell gray items"]).entry.checked, "menu not refreshed")
    find("check", L["Sell gray items"]).scripts.OnClick(find("check", L["Sell gray items"]))
    assert(main.db.modules.Vendor.sellJunk == true, "check did not turn it back on")
    -- 多选一：矿点改为始终显示（绿勾图标），悬停看含义
    local ore = find("choice", L["Mining nodes"])
    assert(ore and ore.entry.value == "auto", "mining nodes choice missing")
    for _, option in ipairs(ore.options) do
        if option.shown and option.id == "always" then
            assert(option.text:GetText():find("ReadyCheck%-Ready") and option.tip == L["Always"], "always is not a check mark")
            option.scripts.OnClick(option)
        end
    end
    assert(main.db.modules.WorldMap.orePins == "always" and find("choice", L["Mining nodes"]).entry.value == "always",
        "choice did not change the setting")
    assert(refreshed == 1, "changing a world map option did not refresh the map")
    main.db.modules.WorldMap.orePins = nil
    worldMap.Refresh = savedRefresh
    -- 设置页显示时同步快捷菜单里改过的值
    main.db.modules.Vendor.sellJunk = false
    main.MainFrame:Open("settings")
    main.MainFrame:SelectTab("home")
    main.MainFrame:SelectTab("settings")
    main.db.modules.Vendor.sellJunk = true
    main.MainFrame:Hide()
    -- 点菜单外面关闭；Esc 可关闭
    fireAll("GLOBAL_MOUSE_DOWN", "LeftButton")
    assert(not menu.shown, "clicking elsewhere did not close the menu")
    local escape = false
    for _, name in ipairs(UISpecialFrames) do escape = escape or name == "WowHandbookQuickMenu" end
    assert(escape, "menu does not close with Esc")
    -- 左键仍然开关主窗口
    button.scripts.OnClick(button, "LeftButton")
    assert(WowHandbookMainFrame.shown, "left-click no longer opens the window")
    main.MainFrame:Hide()
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
    local all = #main.modules.Spellbook.Rows(false, true)
    assert(spells == all, ("table shows %d of %d spells"):format(spells, all))
    assert(hovered, "no row with a spell ID")
    hovered.scripts.OnEnter(hovered)
    assert(GameTooltip.spellID == hovered.entry.id, "row hover did not show the spell tooltip")
    hovered.scripts.OnLeave(hovered)
end)
check("race spells: the side panel lists only your race, the big spellbook lists all with race tags", function()
    local Spellbook = main.modules.Spellbook
    local savedClass, savedRace, savedInfo = playerClass, UnitRace, C_CreatureInfo
    playerClass = { "Priest", "PRIEST" }
    UnitRace = function() return "Troll", "Troll" end
    -- 客户端给得出的种族名用客户端的；给不出的用本地化表
    C_CreatureInfo = { GetRaceInfo = function(id) return id == 8 and { raceName = "CLIENT-TROLL" } or nil end }
    -- 每个牧师种族两个专属技能
    local perRace = {}
    for _, spell in ipairs(main.Data.spells.priest) do
        if spell.races then
            assert(#spell.races == 1, "priest race spell shared by several races: " .. spell.name.enUS)
            perRace[spell.races[1]] = (perRace[spell.races[1]] or 0) + 1
        end
    end
    for _, race in ipairs({ "Human", "Dwarf", "Night Elf", "Gnome", "Undead", "Troll" }) do
        assert(perRace[race] == 2, ("%s priests should have 2 race spells, data has %s"):format(race, tostring(perRace[race])))
    end
    -- 默认行（未学技能面板、首页、训练师提示用）：只有本种族的
    local own = 0
    for _, row in ipairs(Spellbook.Rows()) do
        assert(row.status ~= "other" and (not row.races or row.mine), "another race's spell in the default rows")
        if row.races then
            assert(row.races[1] == "Troll", "wrong race spell for a troll: " .. row.spell.name.enUS)
            own = own + 1
        end
    end
    assert(own > 0, "troll race spells missing from the default rows")
    -- 两个技能在当前语言下重名时（网站中文数据曾把 Smite 与矮人的 Chastise 都写成“惩击”）：
    -- 学了一个不能把另一个也算成已学，重名的按技能 ID 判断。这里临时把两者改成同名来测
    local smite, chastise
    for _, spell in ipairs(main.Data.spells.priest) do
        if spell.name.enUS == "Smite" then smite = spell elseif spell.name.enUS == "Chastise" then chastise = spell end
    end
    local savedChastiseName = chastise.name
    chastise.name = smite.name
    UnitRace = function() return "Dwarf", "Dwarf" end
    local savedKnownSpells, savedIsPlayerSpell, savedLevel = main.KnownSpells, IsPlayerSpell, playerLevel
    playerLevel = 20
    main.KnownSpells = function() return { [main.Name(smite.name):lower()] = { best = 3, ids = {} } } end
    IsPlayerSpell = function(id) return id == smite.ranks[2].id end
    for _, row in ipairs(Spellbook.Rows()) do
        if row.spell == chastise then
            assert(row.status ~= "known", "Chastise counted as learned because Smite shares its name")
        elseif row.spell == smite and row.rankNumber <= 2 then
            assert(row.status == "known", "Smite rank " .. row.rankNumber .. " not recognized by its spell ID")
        end
    end
    main.KnownSpells, IsPlayerSpell, playerLevel = savedKnownSpells, savedIsPlayerSpell, savedLevel
    chastise.name = savedChastiseName
    UnitRace = function() return "Troll", "Troll" end
    -- 技能书页：全部列出；本种族的带绿色标签、照常显示状态，其他种族的灰色标签、状态写“其他种族”
    main.MainFrame:SelectTab("home")
    main.MainFrame:SelectTab("spellbook")
    local page = Spellbook.page
    local mine, others, tagged = 0, 0, {}
    for _, row in ipairs(page.tableRows) do
        if row.shown and row.entry and row.entry.races then
            local text = row.cells.spell:GetText()
            local race = row.entry.races[1]
            tagged[race] = true
            if row.entry.mine then
                mine = mine + 1
                assert(text:find("|c" .. main.Theme.hex.green .. "[CLIENT-TROLL]|r", 1, true), "own race tag wrong: " .. text)
                assert(row.group ~= "other" and row.cells.status:GetText():find(main.L["Other race"], 1, true) == nil,
                    "own race spell marked as another race's")
            else
                others = others + 1
                assert(text:find("|c" .. main.Theme.hex.muted .. "[" .. main.L[race] .. "]|r", 1, true),
                    "other race tag wrong: " .. text)
                assert(row.group == "other" and row.alpha < 0.55, "other race row not dimmed")
                assert(row.cells.status:GetText():find(main.L["Other race"], 1, true), "other race row has no status")
            end
            row.scripts.OnEnter(row)
            row.scripts.OnLeave(row)
        end
    end
    assert(mine == own and others > mine, ("race rows: %d mine, %d others"):format(mine, others))
    for _, race in ipairs({ "Human", "Dwarf", "Night Elf", "Gnome", "Undead", "Troll" }) do
        assert(tagged[race], "no tagged spell for " .. race)
    end
    -- 整个阵营都能学的技能（法师传送）标阵营，不列五个种族
    assert(Spellbook.RaceLabel({ "Dwarf", "Gnome", "Human", "Night Elf", "Skyborne" }) == main.L["Alliance"], "no faction label")
    assert(Spellbook.RaceLabel({ "Orc", "Skyborne", "Tauren", "Troll", "Undead" }) == main.L["Horde"], "no faction label")
    assert(Spellbook.RaceLabel({ "Dwarf", "Human" }) == main.L["Dwarf"] .. " / " .. main.L["Human"], "race list label wrong")
    playerClass, UnitRace, C_CreatureInfo = savedClass, savedRace, savedInfo
    main.MainFrame:SelectTab("home")
    main.MainFrame:SelectTab("spellbook")
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
check("unknown events are skipped and the professions module still loads", function()
    assert(main.modules.Professions.enabled, "professions module failed to enable")
    assert(main:RegisterEvent("TRADE_SKILL_UPDATE", function() end) == false, "unknown event was not skipped")
    assert(main:RegisterEvent("TRADE_SKILL_SHOW", function() end) == true, "known event was not registered")
    C_EventUtils = nil -- 没有查询接口时靠 pcall 兜底
    assert(main:RegisterEvent("CRAFT_UPDATE", function() end) == false, "failed registration was not caught")
    C_EventUtils = { IsEventValid = function(e) return not UNKNOWN_EVENTS[e] end }
end)
check("professions page: a profession whose trainers have no rank opens without an error", function()
    -- 采矿训练师头衔不写等级：还没学采矿时，“下一步”没有目标，不能报错（bug.txt 2026-10-01）
    GetNumSkillLines = function() return 0 end
    main.db.modules.Professions.selected = "mining"
    main.MainFrame:SelectTab("professions")
    main.modules.Professions.Refresh()
    local page = main.modules.Professions.page
    assert(page.summary:GetText() and not page.summary:GetText():find("nil", 1, true), "summary broken")
    main.db.modules.Professions.selected = nil
end)
check("professions page lists trainers for your faction and highlights the next rank", function()
    -- 已学炼金术 120/150（部落）：默认选中炼金术，只列部落与中立训练师，高级训练师一档高亮
    GetNumSkillLines = function() return 2 end
    GetSkillLineInfo = function(index)
        if index == 1 then return "Professions", true end
        return "Alchemy", false, false, 120, 0, 0, 150
    end
    main.db.modules.Professions.selected = nil
    main.MainFrame:SelectTab("professions")
    local module = main.modules.Professions
    local page = module.page
    assert(module.NextRank({ rank = 120, max = 150 }) == "expert", "next rank after journeyman should be expert")
    -- 训练师头衔是最高可教的一档：还没学的专业要学初级，但只有中级以上的训练师时高亮中级（中级也从零教起）
    local sample = { { rank = "expert" }, { rank = "journeyman" }, { rank = "artisan" }, { rank = "specialization" }, {} }
    assert(main.TargetTrainerRank(sample, nil) == "journeyman", "a beginner is not sent to journeyman trainers")
    assert(main.TargetTrainerRank(sample, { rank = 70, max = 75 }) == "journeyman", "75 cap should find journeyman")
    assert(main.TargetTrainerRank(sample, { rank = 140, max = 150 }) == "expert", "150 cap should find expert")
    assert(main.TargetTrainerRank(sample, { rank = 300, max = 300 }) == nil, "maxed skill still has a target")
    assert(main.TargetTrainerRank({ { rank = "apprentice" }, { rank = "journeyman" } }, nil) == "apprentice",
        "an apprentice trainer is not preferred for a beginner")
    -- 等级名按英文头衔的等级词走本地化表（中文里 Journeyman 对应训练师头衔“初级炼金师”的“初级”）
    assert(main.TrainerRankName("journeyman") == main.L["Journeyman"], "rank name does not use the locale table")
    local alchemy
    for _, profession in ipairs(main.Data.professions) do
        if profession.slug == "alchemy" then alchemy = profession end
    end
    assert(page.title:GetText() == main.Name(alchemy.name), "learned profession is not selected by default")
    local expected = module.Trainers(alchemy)
    local shown, highlighted, clickable = 0, 0, nil
    for _, row in ipairs(page.rows) do
        if row:IsShown() and row.trainer then
            shown = shown + 1
            assert(row.trainer.faction ~= "A", "alliance trainer listed for a horde player")
            if row.tint.shown then
                highlighted = highlighted + 1
                assert(row.trainer.rank == "expert", "highlighted row is not an expert trainer")
            end
            if row.trainer.x and not clickable then clickable = row end
        end
    end
    assert(shown == #expected and shown > 0, ("table shows %d of %d trainers"):format(shown, #expected))
    assert(highlighted > 0, "no expert trainer highlighted")
    assert(page.summary:GetText():find("120/150", 1, true), "summary has no skill level")
    waypoint = nil
    clickable.scripts.OnClick(clickable)
    assert(waypoint and waypoint.map == clickable.trainer.map, "clicking a trainer did not set a waypoint")
    -- 切换专业
    main.MainFrame:Open("professions") -- 标记地图时收起了主窗口
    page.list.rows[1].scripts.OnClick(page.list.rows[1])
    GetNumSkillLines, GetSkillLineInfo = nil, nil
end)
check("every profession's trainer list renders, learned or not", function()
    local module = main.modules.Professions
    local settings = main.db.modules.Professions
    main.MainFrame:Open("professions")
    for _, skill in ipairs({ false, true }) do
        GetNumSkillLines = function() return skill and #main.Data.professions or 0 end
        GetSkillLineInfo = function(index)
            local profession = main.Data.professions[index]
            return profession.name.enUS, false, false, 290, 0, 0, 300
        end
        for _, profession in ipairs(main.Data.professions) do
            settings.selected = profession.slug
            module.Refresh()
            for _, row in ipairs(module.page.rows) do
                if row:IsShown() and row.trainer then
                    row.scripts.OnEnter(row)
                    row.scripts.OnLeave(row)
                end
            end
        end
    end
    settings.selected = nil
    GetNumSkillLines, GetSkillLineInfo = nil, nil
end)
check("side panels clear the spellbook tabs, can be dragged, remember their offset and reset on right-click", function()
    local book = PlayerSpellsFrame.SpellBookFrame
    local module = main.modules.SpellbookPanel
    local settings = main.db.modules.SpellbookPanel
    settings.collapsed, settings.dockX, settings.dockY = false, nil, nil
    book.shown = true
    book.scripts.OnShow(book)
    local panel = module.panel
    assert(panel.pointX == 40 and panel.relativeTo == PlayerSpellsFrame, "spell panel does not clear the spellbook tabs")
    -- 拖到技能书右上角往右 120、往下 30 的地方
    PlayerSpellsFrame.GetRight = function() return 500 end
    PlayerSpellsFrame.GetTop = function() return 700 end
    panel.GetLeft = function() return 620 end
    panel.GetTop = function() return 670 end
    panel.scripts.OnDragStart(panel)
    panel.scripts.OnDragStop(panel)
    assert(settings.dockX == 120 and settings.dockY == -30, "drag offset not remembered")
    book.shown = false
    book.scripts.OnHide(book)
    book.shown = true
    book.scripts.OnShow(book)
    assert(panel.pointX == 120 and panel.pointY == -30, "remembered offset not used when reopening")
    panel.scripts.OnMouseUp(panel, "RightButton")
    assert(settings.dockX == nil and panel.pointX == 40, "right-click did not reset the position")
    book.shown = false
    book.scripts.OnHide(book)
end)
collectorCheck("collector recipes page: recipes and leveling guide for your profession", function()
    local R = collector.Recipes
    local alchemy
    for _, profession in ipairs(collector.recipeData) do
        if profession.slug == "alchemy" then alchemy = profession end
    end
    assert(alchemy and #alchemy.recipes > 0 and #alchemy.guide > 0, "no alchemy recipe data in the collector")
    GetProfessions = function() return 1 end
    GetProfessionInfo = function() return "Alchemy", nil, 120, 150, 0, 0, 171 end
    -- 打开专业窗口时读到的已学配方：旧版按名字、新版按配方 ID
    local first, second = alchemy.recipes[1], alchemy.recipes[2]
    spellNames[first.id] = "Elixir of Minor Force"
    GetNumTradeSkills = function() return 2 end
    GetTradeSkillInfo = function(index)
        if index == 1 then return "Elixirs", "header" end
        return "Elixir of Minor Force", "trivial"
    end
    C_TradeSkillUI = {
        GetAllRecipeIDs = function() return { first.id, second.id } end,
        GetRecipeInfo = function(id) return { learned = id == second.id } end,
    }
    R.RecordKnownRecipes()
    C_TradeSkillUI, GetNumTradeSkills, GetTradeSkillInfo = nil, nil, nil
    assert(R.KnownRecipe(first) and R.KnownRecipe(second), "recipes seen in the profession window are not known")
    -- “配方”页挂在主窗口
    main.MainFrame:Open("recipes")
    local page = R.page
    assert(page and page:IsVisible(), "recipes page not registered in the main window")
    assert(page.title:GetText() == main.Name(alchemy.name), "learned profession is not selected by default")
    local recipeRows = 0
    for _, row in ipairs(page.rows) do
        if row:IsShown() and row.recipe then recipeRows = recipeRows + 1 end
    end
    assert(recipeRows == #alchemy.recipes, ("recipes view shows %d of %d"):format(recipeRows, #alchemy.recipes))
    local orange
    for _, recipe in ipairs(alchemy.recipes) do
        if recipe.skill and recipe.skill[1] > 120 then orange = recipe break end
    end
    assert(R.Difficulty(orange, { rank = 120, max = 150 }) == "skillOrange", "recipe above your skill is not orange")
    assert(R.Difficulty(first, { rank = 120, max = 150 }) == "skillGray", "low recipe is not gray")
    -- 图标：有成品的用成品物品图标，没有成品的用技能图标
    local savedIcon, savedTexture = C_Item.GetItemIconByID, C_Spell.GetSpellTexture
    C_Item.GetItemIconByID = function(id) return id == first.makes and 999001 or 134400 end
    C_Spell.GetSpellTexture = function() return 999002 end
    assert(R.RecipeIcon(first):find("999001", 1, true), "recipe with a product does not use the item icon")
    assert(R.RecipeIcon({ id = 1 }):find("999002", 1, true), "enchant does not use the spell icon")
    C_Item.GetItemIconByID, C_Spell.GetSpellTexture = savedIcon, savedTexture
    page.hideLearned.scripts.OnClick(page.hideLearned)
    local afterHide = 0
    for _, row in ipairs(page.rows) do
        if row:IsShown() and row.recipe then afterHide = afterHide + 1 end
    end
    assert(afterHide == recipeRows - 2, "hiding learned recipes did not remove the two learned rows")
    collector.db.settings.recipes.hideLearned = false
    -- 冲级指南：每段的推荐配方，技能 120 所在的 75-150 段高亮
    page.views.buttons.guide.scripts.OnClick(page.views.buttons.guide)
    local picks, highlightedPicks = 0, 0
    for _, row in ipairs(page.rows) do
        if row:IsShown() and row.recipe then
            picks = picks + 1
            if row.tint.shown then highlightedPicks = highlightedPicks + 1 end
        end
    end
    local expectedPicks, bracketPicks = 0, 0
    for _, bracket in ipairs(alchemy.guide) do
        expectedPicks = expectedPicks + #bracket.picks
        if bracket.from == 75 then bracketPicks = #bracket.picks end
    end
    assert(picks == expectedPicks and picks > 0, ("guide shows %d of %d picks"):format(picks, expectedPicks))
    assert(highlightedPicks == bracketPicks, "the bracket you are in is not highlighted")
    -- 每个专业两个视图都能画出来，悬停不报错
    for _, profession in ipairs(collector.recipeData) do
        for _, view in ipairs({ "recipes", "guide" }) do
            collector.db.settings.recipes.selected, collector.db.settings.recipes.view = profession.slug, view
            R.Refresh()
            for _, row in ipairs(page.rows) do
                if row:IsShown() and row.recipe then
                    row.scripts.OnEnter(row)
                    row.scripts.OnLeave(row)
                end
            end
        end
    end
    collector.db.settings.recipes.selected, collector.db.settings.recipes.view = nil, "recipes"
    main.MainFrame:Hide()
    GetProfessions, GetProfessionInfo = nil, nil
end)
collectorCheck("collector recipe panel follows the game profession window", function()
    -- 模拟按需加载的暴雪专业窗口（Forever 为 ProfessionsFrame）
    ProfessionsFrame = CreateFrame("Frame", "ProfessionsFrame", UIParent)
    local window = ProfessionsFrame
    window.shown = false
    fireAll("ADDON_LOADED", "Blizzard_Professions")
    assert(window.scripts.OnShow and window.scripts.OnHide, "game profession window not hooked")
    local R = collector.Recipes
    local alchemy
    for _, profession in ipairs(collector.recipeData) do
        if profession.slug == "alchemy" then alchemy = profession end
    end
    -- 窗口里打开的是炼金术（子技能线 2937），技能 60/75
    C_TradeSkillUI = { GetBaseProfessionInfo = function() return { professionID = 2937, professionName = "?" } end }
    GetProfessions = function() return 1 end
    GetProfessionInfo = function() return "Alchemy", nil, 60, 75, 0, 0, 171 end
    window.shown = true
    window.scripts.OnShow(window)
    assert(R.panel and R.panel.shown, "panel not shown with the profession window")
    assert(R.panel.title:GetText() == main.Name(alchemy.name), "panel does not name the open profession")
    local entries = R.Entries(alchemy)
    assert(#entries == #alchemy.recipes, ("panel lists %d of %d recipes"):format(#entries, #alchemy.recipes))
    assert(not entries[1].row.known and entries[#entries].row.known, "unlearned recipes should come first, learned last")
    GameTooltip.spellID = nil
    R.panel.list.onEntryEnter(R.panel, entries[1].id)
    assert(GameTooltip.spellID == entries[1].row.recipe.id, "hover does not show the recipe tooltip")
    -- 旧版窗口按名字认专业
    C_TradeSkillUI = nil
    GetTradeSkillLine = function() return "Alchemy", 60, 75 end
    assert(R.CurrentProfession(window) == alchemy, "profession not recognized by name")
    GetTradeSkillLine = nil
    -- 收起留小按钮；窗口关了面板一起隐藏
    R.panel.close.scripts.OnClick(R.panel.close)
    assert(not R.panel.shown and R.tab.shown, "collapse should leave the small button")
    R.tab.scripts.OnClick(R.tab)
    assert(R.panel.shown, "button should expand the panel")
    -- 可拖动并记住相对专业窗口的偏移
    window.GetRight = function() return 800 end
    window.GetTop = function() return 600 end
    R.panel.GetLeft = function() return 850 end
    R.panel.GetTop = function() return 600 end
    R.panel.scripts.OnDragStart(R.panel)
    R.panel.scripts.OnDragStop(R.panel)
    assert(collector.db.settings.recipePanel.dockX == 50 and collector.db.settings.recipePanel.dockY == 0,
        "recipe panel offset not remembered")
    collector.db.settings.recipePanel.dockX = nil
    window.shown = false
    window.scripts.OnHide(window)
    assert(not R.panel.shown and not R.tab.shown, "panel should hide with the profession window")
    GetProfessions, GetProfessionInfo = nil, nil
end)
check("auto quest: accepts and turns in on its own, rewards by the chosen rule, Shift skips, never retries", function()
    local W = main.modules.AutoQuest
    local settings = main.db.modules.AutoQuest
    assert(settings.autoAccept == true and settings.autoTurnIn == true and settings.rewardMode == "manual",
        "defaults should be auto-accept, auto turn-in, manual reward")
    local log = {}
    local shift = false
    IsShiftKeyDown = function() return shift end
    local active, available = {}, {}
    local windowQuest = 0
    GetQuestID = function() return windowQuest end
    C_GossipInfo = C_GossipInfo or {}
    local savedGossip = { C_GossipInfo.GetActiveQuests, C_GossipInfo.GetAvailableQuests,
        C_GossipInfo.SelectActiveQuest, C_GossipInfo.SelectAvailableQuest }
    C_GossipInfo.GetActiveQuests = function() return active end
    C_GossipInfo.GetAvailableQuests = function() return available end
    C_GossipInfo.SelectActiveQuest = function(id) tinsert(log, "turnin:" .. id) end
    C_GossipInfo.SelectAvailableQuest = function(id) tinsert(log, "pick:" .. id) end
    -- 对话菜单：先交已完成的，再接可接的；灰色任务不接；推迟到下一帧
    active = { { questID = 11, isComplete = false }, { questID = 12, isComplete = true } }
    available = { { questID = 21, isTrivial = true }, { questID = 22, isTrivial = false } }
    fireAll("GOSSIP_SHOW")
    assert(#log == 0, "acted in the same frame; other addons need to read the window first")
    runTimers()
    assert(log[#log] == "turnin:12", "completed quest was not turned in first")
    active = {}
    fireAll("GOSSIP_SHOW"); runTimers()
    assert(log[#log] == "pick:22", "the non-gray quest was not picked")
    -- 失败不重试：接不下（对话菜单又弹出同一个任务）时不再点它
    local count = #log
    fireAll("GOSSIP_SHOW"); runTimers()
    assert(#log == count, "retried a quest that was already tried")
    -- 对话结束（两个窗口都关了）后再点这个 NPC：重新自动处理一次；窗口还开着时的关闭事件不算结束
    local savedGossipFrame, savedQuestFrame = GossipFrame, QuestFrame
    local gossipOpen = true
    GossipFrame = { IsShown = function() return gossipOpen end }
    QuestFrame = { IsShown = function() return false end }
    fireAll("QUEST_FINISHED"); runTimers(2)
    fireAll("GOSSIP_SHOW"); runTimers()
    assert(#log == count, "retried while the conversation was still open")
    gossipOpen = false
    fireAll("GOSSIP_CLOSED"); runTimers(2)
    gossipOpen = true
    fireAll("GOSSIP_SHOW"); runTimers()
    assert(#log == count + 1 and log[#log] == "pick:22", "did not try again after the conversation ended")
    count = #log
    fireAll("GOSSIP_SHOW"); runTimers()
    assert(#log == count, "retried twice in the same conversation")
    GossipFrame, QuestFrame = savedGossipFrame, savedQuestFrame
    -- 按住 Shift、关掉开关：不动
    available = { { questID = 23, isTrivial = false } }
    shift = true
    fireAll("GOSSIP_SHOW"); runTimers()
    shift = false
    settings.autoAccept = false
    fireAll("GOSSIP_SHOW"); runTimers()
    assert(#log == count, "acted while Shift was held or auto-accept was off")
    settings.autoAccept = true
    -- 任务说明：接受一次；同一任务再弹出不再接；游戏确认接下后可以再自动处理
    AcceptQuest = function() tinsert(log, "accept") end
    QuestGetAutoAccept = function() return false end
    windowQuest = 22
    fireAll("QUEST_DETAIL"); runTimers()
    assert(log[#log] == "accept", "quest detail was not accepted")
    count = #log
    fireAll("QUEST_DETAIL"); runTimers()
    assert(#log == count, "accepted the same quest twice after a failure")
    fireAll("QUEST_ACCEPTED", 22)
    fireAll("QUEST_DETAIL"); runTimers()
    assert(#log == count + 1, "after a successful accept the quest can be handled again")
    -- 进行中：能交就继续
    IsQuestCompletable = function() return true end
    CompleteQuest = function() tinsert(log, "complete") end
    windowQuest = 12
    fireAll("QUEST_PROGRESS"); runTimers()
    assert(log[#log] == "complete", "quest progress was not continued")
    -- 奖励：只有一个就交；多个且手动就不动；自动时按规则挑
    local choices = {}
    GetNumQuestChoices = function() return #choices end
    GetQuestItemInfo = function(_, index) return "x", nil, 1, 1, choices[index].usable end
    GetQuestItemLink = function(_, index) return "item:" .. index end
    GetQuestMoneyToGet = function() return 0 end
    GetQuestReward = function(index) tinsert(log, "reward:" .. tostring(index)) end
    QuestFrame = QuestFrame or CreateFrame("Frame", "QuestFrame", UIParent)
    QuestFrame.shown = true
    local savedInfo = C_Item.GetItemInfo
    C_Item.GetItemInfo = function(link)
        local index = tonumber(link:match("item:(%d+)"))
        return "x", link, 1, 1, 1, "", "", 1, "", 1, choices[index] and choices[index].price
    end
    local function complete(questID)
        windowQuest = questID
        fireAll("QUEST_COMPLETE"); runTimers()
    end
    choices = { { usable = true, price = 10 } }
    complete(101)
    assert(log[#log] == "reward:1", "single reward was not taken")
    count = #log
    complete(101)
    assert(#log == count, "took the reward of the same quest twice")
    choices = { { usable = true, price = 10 }, { usable = false, price = 500 }, { usable = true, price = 90 } }
    complete(102)
    assert(#log == count, "manual mode picked a reward")
    settings.rewardMode = "usable"
    complete(103)
    assert(log[#log] == "reward:3", "should take the most valuable of the usable rewards")
    choices = { { usable = false, price = 500 }, { usable = true, price = 5 }, { usable = false, price = 900 } }
    complete(104)
    assert(log[#log] == "reward:2", "the only usable reward should win even if cheaper")
    choices = { { usable = false, price = 10 }, { usable = false, price = 500 } }
    complete(105)
    assert(log[#log] == "reward:2", "with nothing usable it should take the most valuable")
    -- 需要交钱的任务不自动交
    GetQuestMoneyToGet = function() return 100 end
    count = #log
    complete(106)
    assert(#log == count, "a quest that costs money was turned in")
    settings.rewardMode = "manual"
    for _, steps in pairs(W.tried) do for key in pairs(steps) do steps[key] = nil end end
    C_Item.GetItemInfo = savedInfo
    QuestFrame.shown = false
    C_GossipInfo.GetActiveQuests, C_GossipInfo.GetAvailableQuests, C_GossipInfo.SelectActiveQuest,
        C_GossipInfo.SelectAvailableQuest = unpack(savedGossip, 1, 4)
    IsShiftKeyDown, GetQuestID = nil, nil
end)
check("instance tracker test mode: /wh test opens the same compact sample every time", function()
    local T = main.modules.InstanceTracker
    local function open()
        SlashCmdList.WOWHANDBOOK("test")
        local f = WowHandbookInstanceFrame
        assert(f and f.shown, "/wh test did not open the tracker")
        return f
    end
    local function snapshot(f)
        local parts = { f.title:GetText(), f.progress:GetText() }
        for _, row in ipairs(f.rows) do
            if row.shown then tinsert(parts, (row.name:GetText() or "") .. "|" .. (row.tag:GetText() or "")) end
        end
        return table.concat(parts, "\n")
    end
    main.db.modules.InstanceTracker.collapsed = false
    local f = open()
    assert(f.width == 240, "tracker is not the compact width")
    assert(f.title:GetText() == main.L["Test Crypt"], "sample dungeon name missing")
    assert(f.progress:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") == "2/5", "sample progress should be 2/5")
    -- 已击杀的合并成一行，悬停列出是哪几个；还没打的逐行列出，第一个是“下一个”
    local killedRow, bossRows, questRows = nil, 0, 0
    for _, row in ipairs(f.rows) do
        if row.shown then
            if rawget(row, "killedList") then killedRow = row
            elseif rawget(row, "boss") then bossRows = bossRows + 1
            elseif rawget(row, "questID") then questRows = questRows + 1 end
        end
    end
    assert(killedRow and #killedRow.killedList == 2, "killed bosses are not merged into one row")
    GameTooltip.lines = {}
    killedRow.scripts.OnEnter(killedRow)
    local listed = 0
    for _, line in ipairs(GameTooltip.lines) do
        if line == main.L["Gravekeeper Thane"] or line == main.L["The Rotting Hound"] then listed = listed + 1 end
    end
    killedRow.scripts.OnLeave(killedRow)
    assert(listed == 2, "merged killed row does not list the killed bosses")
    assert(bossRows == 3 and questRows == 3, ("sample shows %d bosses and %d quests"):format(bossRows, questRows))
    local found = false
    for _, row in ipairs(f.rows) do
        if row.shown and rawget(row, "questID") == -2 then
            found = row.tag:GetText():find("3/8", 1, true) and row.tag:GetText():find("0/1", 1, true)
        end
    end
    assert(found, "sample quest in progress does not show its counts")
    -- 任务区用符号：可交是黄 ?，副本内可接是黄 !，不写文字；标题行悬停说明符号
    for _, row in ipairs(f.rows) do
        if row.shown and rawget(row, "questID") == -1 then
            assert(row.tag:GetText() == T.QUEST_ICON.turnIn, "ready quest is not the turn-in icon")
        elseif row.shown and rawget(row, "questID") == -3 then
            assert(row.tag:GetText() == T.QUEST_ICON.inside, "inside quest is not the pick-up icon")
        end
    end
    GameTooltip.lines = {}
    f.questHover.scripts.OnEnter(f.questHover)
    local legend = 0
    for _, line in ipairs(GameTooltip.lines) do
        for _, icon in pairs(T.QUEST_ICON) do
            if line:find(icon, 1, true) then legend = legend + 1 break end
        end
    end
    f.questHover.scripts.OnLeave(f.questHover)
    assert(legend == 5, ("quest legend explains %d of 5 icons"):format(legend))
    -- 测试模式下点击不跳到手册
    main.MainFrame:Hide()
    killedRow.scripts.OnClick(killedRow)
    assert(not (WowHandbookMainFrame and WowHandbookMainFrame.shown), "clicking in test mode opened the handbook")
    -- 每次打开都一样
    local first = snapshot(f)
    SlashCmdList.WOWHANDBOOK("test")
    -- 测试环境此时在怒焰裂谷里：退出测试回到真实副本的小窗
    assert(f.title:GetText() ~= main.L["Test Crypt"], "/wh test again did not leave the sample")
    f = open()
    assert(snapshot(f) == first, "test mode is not the same every time")
    -- 关闭按钮同样退出测试模式
    f.close.scripts.OnClick(f.close)
    assert(f.title:GetText() ~= main.L["Test Crypt"], "close did not leave the sample")
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
check("action bars: an out-of-range button turns red, and back to the game's colors in range", function()
    local module = main.modules.ActionBars
    local colors = main.Theme.colors
    local inRange, usable, noMana = {}, true, false
    IsActionInRange = function(slot) return inRange[slot] end
    IsUsableAction = function() return usable, noMana end
    -- 游戏按钮：可用性变化时自己把图标设回原色
    local button = newObject("Frame", "ActionButton1")
    _G.ActionButton1 = button
    button.action, button.icon = 5, newObject("Texture")
    button.UpdateUsable = function(self) self.icon:SetVertexColor(1, 1, 1) end
    local other = newObject("Frame", "ActionButton2")
    _G.ActionButton2 = other
    other.action, other.icon = 6, newObject("Texture")
    module.StartRangeTint()
    local function color(b) return b.icon.vertexColor and table.concat(b.icon.vertexColor, ",") end
    local red = table.concat({ colors.actionOutOfRange[1], colors.actionOutOfRange[2], colors.actionOutOfRange[3] }, ",")
    -- 超出距离：整个图标染红，别的格子不动
    inRange[5] = false
    fireAll("ACTION_RANGE_CHECK_UPDATE", 5, false, true)
    assert(color(button) == red, "out-of-range button is not red")
    assert(other.icon.vertexColor == nil, "a button in another slot was tinted")
    -- 游戏重设可用性颜色后仍保持红色
    button:UpdateUsable()
    assert(color(button) == red, "red tint lost after the game updated usability")
    -- 回到距离内：按可用性恢复（缺法力偏蓝）
    inRange[5], usable, noMana = true, false, true
    fireAll("ACTION_RANGE_CHECK_UPDATE", 5, true, true)
    local blue = table.concat({ colors.actionNoMana[1], colors.actionNoMana[2], colors.actionNoMana[3] }, ",")
    assert(color(button) == blue, "in-range button did not get the game's no-mana color back")
    -- 没有目标（取不到距离）不染红；关掉设置时恢复
    inRange[5], usable, noMana = nil, true, false
    fireAll("PLAYER_TARGET_CHANGED")
    assert(color(button) ~= red, "tinted without a target")
    inRange[5] = false
    fireAll("PLAYER_TARGET_CHANGED")
    assert(color(button) == red, "not tinted after target change")
    main.db.modules.ActionBars.rangeTint = false
    module:Refresh()
    local c = button.icon.vertexColor
    assert(c[1] == 1 and c[2] == 1 and c[3] == 1, "turning the option off did not restore the color")
    main.db.modules.ActionBars.rangeTint = true
    _G.ActionButton1, _G.ActionButton2, IsActionInRange, IsUsableAction = nil, nil, nil, nil
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
check("world map: herb and mining nodes follow your professions and skill", function()
    local provider = WorldMapFrame.providers[5]
    assert(provider, "gathering provider not added")
    local spots = main.Data.gathering.maps[1413]
    assert(spots and #spots.herb > 0 and #spots.ore > 0, "no gathering data for the test map")
    local function pinsOf()
        provider:RefreshAllData()
        local list = {}
        for _, pin in ipairs(pins) do
            if pin.template == "WowHandbookGatherPinTemplate" then tinsert(list, pin) end
        end
        return list
    end
    local settings = main.db.modules.WorldMap
    local herbalism
    GetNumSkillLines = function() return herbalism and 1 or 0 end
    GetSkillLineInfo = function() return "Herbalism", false, false, herbalism, 0, 0, 150 end
    -- 默认：没学草药学、采矿，不显示
    assert(#pinsOf() == 0, "nodes shown without the professions")
    -- 草药学 60：只显示草药；够不着的变灰变淡
    herbalism = 60
    local list = pinsOf()
    assert(#list == #spots.herb, ("%d herb pins, expected %d"):format(#list, #spots.herb))
    local low, high
    for _, pin in ipairs(list) do
        if pin.whOk then low = low or pin else high = high or pin end
    end
    assert(low and high, "expected both gatherable and too-high herbs at skill 60")
    -- 小而半透明（统一 0.5）；能采的原色，够不着的染红
    assert(low.width == 7 and low.alpha == 0.5 and high.alpha == 0.5, "gathering pins are not small and half transparent")
    local lc, hc = low.whTexture.vertexColor, high.whTexture.vertexColor
    assert(lc[1] == 1 and lc[2] == 1 and lc[3] == 1, "gatherable herb is tinted")
    assert(hc[1] == 1 and hc[2] < 0.7 and hc[3] < 0.7, "too-high herb is not tinted red")
    assert(#low.whLines >= 3 and low.whLines[1] == main.L["Herb"], "herb tooltip has no node lines")
    waypoint = nil
    low:OnMouseClickAction("LeftButton")
    assert(waypoint, "clicking a node should set a waypoint")
    -- 矿点设为始终显示：没学采矿也显示，全部够不着
    settings.orePins = "always"
    assert(#pinsOf() == #spots.herb + #spots.ore, "always: mining nodes not shown")
    settings.herbPins, settings.orePins = "off", "off"
    assert(#pinsOf() == 0, "never: nodes still shown")
    settings.herbPins, settings.orePins = nil, nil
    GetNumSkillLines, GetSkillLineInfo = nil, nil
    provider:RemoveAllData()
end)
check("professions are recognized by skill line on the retail-style API, by name as a fallback", function()
    GetProfessions = function() return 1, 2 end
    GetProfessionInfo = function(index)
        if index == 1 then return "Kraeuterkunde", nil, 100, 150, 0, 0, 2944 end -- 名字对不上，按子技能线认出
        return "Mining", nil, 40, 75, 0, 0, 999999                                -- 技能线未知，按名字认出
    end
    local skills = main.ProfessionSkills()
    GetProfessions, GetProfessionInfo = nil, nil
    assert(skills.herbalism and skills.herbalism.rank == 100 and skills.herbalism.max == 150, "herbalism not found by skill line")
    assert(skills.mining and skills.mining.rank == 40, "mining not found by name")
end)
check("minimap: gathering nodes placed by distance, rotated with the minimap, only inside its circle", function()
    local W = main.modules.WorldMap
    local spot = main.Data.gathering.maps[1411].herb[1]
    local px, py = spot[1] / 100, spot[2] / 100
    local saved = { C_Map.GetWorldPosFromMapPos, C_Map.GetPlayerMapPosition, CreateVector2D, C_Minimap, C_CVar }
    -- 1411 按 1000×1000 码算；世界坐标 x 向北、y 向西
    C_Map.GetWorldPosFromMapPos = function(_, v) return 1, { x = 1000 - v.y * 1000, y = 1000 - v.x * 1000 } end
    C_Map.GetPlayerMapPosition = function() return { GetXY = function() return px, py end } end
    CreateVector2D = function(x, y) return { x = x, y = y } end
    C_Minimap = { GetViewRadius = function() return 100 end }
    Minimap:SetWidth(140)
    Minimap:Show()
    GetProfessions = function() return 1 end
    GetProfessionInfo = function() return "Herbalism", nil, 150, 150, 0, 0, 182 end
    W.RebuildMinimapGather()
    local shown = {}
    for _, pin in ipairs(W.minimapGatherPins) do
        if pin.shown then tinsert(shown, pin) end
    end
    assert(#shown > 0, "no minimap pins next to the player")
    local here
    for _, pin in ipairs(shown) do
        local dx, dy = pin.pointX, pin.pointY
        assert(dx * dx + dy * dy <= 70 * 70, "a pin is drawn outside the minimap circle")
        if math.abs(dx) < 1e-6 and math.abs(dy) < 1e-6 then here = pin end
    end
    assert(here and here.lines[1] == main.L["Herb"], "the node under the player is not at the center")
    -- 往东 5% = 50 码 = 35 像素（半径 100 码对应半宽 70 像素）；小地图旋转、面朝西时，东边的点在正下方
    px = px - 0.05
    W.UpdateMinimapGather(true)
    assert(math.abs(here.pointX - 35) < 1e-6 and math.abs(here.pointY) < 1e-6, "east offset is wrong")
    C_CVar = { GetCVar = function(name) return name == "rotateMinimap" and "1" or nil end }
    GetPlayerFacing = function() return math.pi / 2 end
    W.UpdateMinimapGather(true)
    assert(math.abs(here.pointX) < 1e-6 and math.abs(here.pointY + 35) < 1e-6, "rotation is wrong")
    -- 图层紧贴小地图（系统的采集追踪标记由引擎和地形一起画，插件只能在上面，尽量低）
    assert(here.frameLevel == Minimap:GetFrameLevel() + 1, "minimap pin is not on the lowest layer")
    -- 圆圈样式：空心圆环，能采的草药绿色，50% 半透明
    main.db.modules.WorldMap.minimapGatherStyle = "circle"
    W.UpdateMinimapGather(true)
    local green = main.Theme.colors.green
    assert(here.style == "circle" and tostring(here.icon.texture):find("GatherRing$") and here.width == 12,
        "circle style does not use the ring")
    assert(here.icon.vertexColor[1] == green[1] and here.icon.vertexColor[2] == green[2] and here.alpha == 0.5,
        "gatherable herb ring is not green and half transparent")
    main.db.modules.WorldMap.minimapGatherStyle = nil
    W.UpdateMinimapGather(true)
    assert(here.style == "icon" and here.width == 7, "icon style not restored")
    -- 关掉小地图显示
    main.db.modules.WorldMap.minimapGather = false
    W.RebuildMinimapGather()
    for _, pin in ipairs(W.minimapGatherPins) do assert(not pin.shown, "pins remain after turning it off") end
    main.db.modules.WorldMap.minimapGather = nil
    C_Map.GetWorldPosFromMapPos, C_Map.GetPlayerMapPosition, CreateVector2D, C_Minimap, C_CVar = unpack(saved, 1, 5)
    GetProfessions, GetProfessionInfo, GetPlayerFacing = nil, nil, nil
end)
check("minimap: trainers and spirit healers follow the world map settings, plain icons without a border", function()
    local W = main.modules.WorldMap
    local settings = main.db.modules.WorldMap
    local saved = { C_Map.GetWorldPosFromMapPos, C_Map.GetPlayerMapPosition, CreateVector2D, C_Minimap, C_Map.GetBestMapForUnit,
        UnitIsDeadOrGhost }
    -- 找一个本阵营的法师训练师，站在他身上
    local trainer
    for _, candidate in ipairs(main.Data.classTrainers.mage) do
        if candidate.x and not candidate.kind and (candidate.faction == "H" or candidate.faction == "AH") then
            trainer = candidate
            break
        end
    end
    assert(trainer, "no horde mage trainer in the data")
    local px, py = trainer.x / 100, trainer.y / 100
    C_Map.GetBestMapForUnit = function() return trainer.map end
    C_Map.GetWorldPosFromMapPos = function(_, v) return 1, { x = 1000 - v.y * 1000, y = 1000 - v.x * 1000 } end
    C_Map.GetPlayerMapPosition = function() return { GetXY = function() return px, py end } end
    CreateVector2D = function(x, y) return { x = x, y = y } end
    C_Minimap = { GetViewRadius = function() return 100 end }
    UnitIsDeadOrGhost = function() return false end
    Minimap:SetWidth(140)
    Minimap:Show()
    settings.herbPins, settings.orePins = "off", "off"
    local function shown(style)
        local list = {}
        for _, pin in ipairs(W.minimapGatherPins) do
            if pin.shown and (not style or pin.style == style) then tinsert(list, pin) end
        end
        return list
    end
    W.RebuildMinimapGather()
    local pins = shown("classTrainer")
    assert(#pins > 0, "class trainer missing from the minimap")
    local here
    for _, pin in ipairs(pins) do
        if math.abs(pin.pointX) < 1e-6 and math.abs(pin.pointY) < 1e-6 then here = pin end
    end
    assert(here and here.lines[1] == main.Name(trainer.name), "the trainer under the player is not at the center")
    -- 大小合适、不带边框：13 像素的方形图标，没有边框模板与圆形遮罩，盖在采集点上面
    assert(here.width == 13 and here.height == 13, "trainer pin size is " .. tostring(here.width))
    assert(here.template == nil and rawget(here, "masks") == nil and rawget(here.icon, "masks") == nil, "minimap pin has a border or mask")
    assert(here.icon.texture == "Interface\\Icons\\ClassIcon_Mage", "wrong class trainer icon: " .. tostring(here.icon.texture))
    assert(here.frameLevel == Minimap:GetFrameLevel() + 2, "trainer pin is not above the gathering pins")
    here.scripts.OnEnter(here)
    -- 大地图关掉职业训练师，小地图也没有
    settings.classTrainerPins = false
    W.RebuildMinimapGather()
    assert(#shown("classTrainer") == 0, "class trainer still on the minimap after turning it off")
    settings.classTrainerPins = nil
    -- 专业训练师：全部专业时显示这张地图上的；不显示时没有
    settings.trainerPins = "all"
    local professionTrainer = W.TrainersForMap(trainer.map)[1]
    if professionTrainer then
        px, py = professionTrainer.trainer.x / 100, professionTrainer.trainer.y / 100
        W.RebuildMinimapGather()
        local found
        for _, pin in ipairs(shown("trainer")) do
            if pin.lines[1] == main.Name(professionTrainer.trainer.name) then found = pin end
        end
        assert(found and found.width == 13 and found.icon.texture:find("^Interface\\Icons\\"), "profession trainer missing or wrong")
    end
    settings.trainerPins = "off"
    W.RebuildMinimapGather()
    assert(#shown("trainer") == 0, "profession trainers on the minimap while turned off")
    settings.trainerPins = nil
    -- 灵魂医者：默认只在死亡时；始终显示时活着也有
    local yard
    for mapID, points in pairs(main.Data.graveyards) do
        if points[1] then yard = { map = mapID, x = points[1][1], y = points[1][2] } break end
    end
    C_Map.GetBestMapForUnit = function() return yard.map end
    px, py = yard.x / 100, yard.y / 100
    W.RebuildMinimapGather()
    assert(#shown("graveyard") == 0, "spirit healer shown while alive with the default setting")
    UnitIsDeadOrGhost = function() return true end
    fireAll("PLAYER_DEAD")
    runTimers(2)
    assert(#shown("graveyard") > 0, "spirit healer not shown after dying")
    UnitIsDeadOrGhost = function() return false end
    fireAll("PLAYER_UNGHOST")
    runTimers(2)
    assert(#shown("graveyard") == 0, "spirit healer still shown after coming back to life")
    settings.spiritHealers = "always"
    W.RebuildMinimapGather()
    local healer = shown("graveyard")[1]
    assert(healer and healer.width == 13 and healer.icon.texture == "Interface\\Icons\\spell_holy_guardianspirit"
        and healer.alpha == 1, "spirit healer pin wrong")
    -- 没有单独的小地图开关：大地图设置关掉，小地图就没有；“小地图显示采集点”那个开关不影响训练师与灵魂医者
    settings.minimapGather = false
    W.RebuildMinimapGather()
    assert(#shown("graveyard") > 0, "the gathering switch must not hide spirit healers")
    settings.spiritHealers, settings.classTrainerPins, settings.trainerPins = "off", false, "off"
    W.RebuildMinimapGather()
    assert(#shown() == 0, "pins remain after turning everything off on the world map")
    for _, section in ipairs(main.SettingsSections) do
        for _, option in ipairs(section.options) do
            assert(option.key ~= "minimapPoi", "there should be no separate minimap switch for trainers")
        end
    end
    settings.minimapGather, settings.classTrainerPins, settings.trainerPins = nil, nil, nil
    settings.spiritHealers, settings.herbPins, settings.orePins = nil, nil, nil
    C_Map.GetWorldPosFromMapPos, C_Map.GetPlayerMapPosition, CreateVector2D, C_Minimap, C_Map.GetBestMapForUnit,
        UnitIsDeadOrGhost = unpack(saved, 1, 6)
    W.RebuildMinimapGather()
end)
check("gathering icons pick the zone's main ore by level, never a rare variant", function()
    local W = main.modules.WorldMap
    local nodes = main.Data.gathering.nodes
    local ORE = { [2770] = "copper", [2771] = "tin", [2772] = "iron", [3858] = "mithril", [10620] = "thorium" }
    -- 每张地图上混合刷新的点：图标不是稀有变种
    for mapID in pairs(main.Data.gathering.maps) do
        local spots, mine = W.GatherSpots(mapID, "ore")
        for _, spot in ipairs(spots) do
            local node = W.DescribeSpot("ore", spot, 0, mine[spot], mapID)
            local hasCommon = false
            for index = 3, #spot do hasCommon = hasCommon or not nodes[spot[index]].rare end
            assert(not (hasCommon and node.rare), ("map %d: a rare ore is used as the icon"):format(mapID))
        end
    end
    -- 各区域的主矿：最多的那种图标
    local function main_ore(mapID)
        local spots, mine = W.GatherSpots(mapID, "ore")
        local count = {}
        for _, spot in ipairs(spots) do
            local item = W.DescribeSpot("ore", spot, 0, mine[spot], mapID).item
            count[item] = (count[item] or 0) + 1
        end
        local best, n = nil, 0
        for item, c in pairs(count) do if c > n then best, n = item, c end end
        return ORE[best]
    end
    assert(main_ore(1411) == "copper", "Durotar should show copper")
    assert(main_ore(1434) == "iron", "Stranglethorn should show iron, got " .. tostring(main_ore(1434)))
    assert(main_ore(1428) == "thorium", "Burning Steppes should show thorium, got " .. tostring(main_ore(1428)))
    -- 颜色跟着图标：赤脊山（15 级起，按技能 75 挑主矿）的铜 / 锡混合点图标是锡矿；技能 50 能采铜但采不了锡，要染红
    local redridge
    for _, s in ipairs(main.Data.gathering.maps[1433].ore) do
        local hasCopper, hasTin = false, false
        for index = 3, #s do
            hasCopper = hasCopper or nodes[s[index]].item == 2770
            hasTin = hasTin or nodes[s[index]].item == 2771
        end
        if hasCopper and hasTin then redridge = redridge or s end
    end
    assert(redridge, "no copper and tin spot in Redridge")
    local tinNode, ok = W.DescribeSpot("ore", redridge, 50, nil, 1433)
    assert(tinNode.item == 2771 and tinNode.skill == 65, "Redridge mixed spot should show tin (skill 65)")
    assert(not ok, "tin icon is not tinted red at mining 50 although copper there is gatherable")
    local _, ok65 = W.DescribeSpot("ore", redridge, 65, nil, 1433)
    assert(ok65, "tin icon still red at mining 65")
    -- 提示：按技能从低到高，稀有的标出来
    local spot
    for _, s in ipairs(main.Data.gathering.maps[1413].ore) do
        for index = 3, #s do if nodes[s[index]].rare then spot = spot or s end end
    end
    assert(spot, "no spot with a rare ore in the Barrens")
    local _, _, lines = W.DescribeSpot("ore", spot, 0, nil, 1413)
    local rareLine = false
    for _, line in ipairs(lines) do rareLine = rareLine or line:find(main.L["rare"], 1, true) ~= nil end
    assert(rareLine, "rare ore is not marked in the tooltip")
end)
check("gathering log: records nodes you gather and merges them into the map", function()
    local W = main.modules.WorldMap
    local nodes = main.Data.gathering.nodes
    local copper
    for index, node in ipairs(nodes) do
        if node.item == 2770 then copper = copper or index end -- 铜矿石
    end
    local spot = main.Data.gathering.maps[1411].ore[1]
    local px, py = spot[1] / 100, spot[2] / 100
    local saved = { C_Map.GetPlayerMapPosition, IsInInstance, issecretvalue, WorldMapFrame.shown,
        C_Map.GetWorldPosFromMapPos, CreateVector2D }
    C_Map.GetPlayerMapPosition = function() return { GetXY = function() return px, py end } end
    -- 地图按 1000×1000 码算：1 个百分点 = 10 码，误差 5 码 = 0.5 个百分点的直线距离
    C_Map.GetWorldPosFromMapPos = function(_, v) return 1, { x = 1000 - v.y * 1000, y = 1000 - v.x * 1000 } end
    CreateVector2D = function(x, y) return { x = x, y = y } end
    WorldMapFrame.shown = false -- 地图关着：采集后只更新小地图，不重画大地图上的其他图钉
    local guid, loot = nil, {}
    GetLootSourceInfo = function() return guid end
    GetNumLootItems = function() return #loot end
    GetLootSlotLink = function(slot) return loot[slot] end
    main.db.gathered = nil
    -- 采了数据里已有的铜矿脉：记在已有的点上，提示多一行采过几次
    local objectID = nodes[copper].objects[1]
    guid = ("GameObject-0-1-2-3-%d-00000ABC"):format(objectID)
    W.OnGatherLoot()
    W.OnGatherLoot()
    local records = main.db.gathered[1411]
    assert(#records == 1 and records[1][3] == copper and records[1][4] == 2, "gathering the same vein twice is not one record with count 2")
    assert(records[1][1] == spot[1] and records[1][2] == spot[2], "record is not snapped to the known spot")
    -- 误差：离已知点约 4 码（各偏 3 码）采，仍记在那个点上；约 8.5 码（各偏 6 码）就另记一个点
    px, py = (spot[1] + 0.3) / 100, (spot[2] - 0.3) / 100
    W.OnGatherLoot()
    assert(#records == 1 and records[1][4] == 3, "a gather within 5 yards made a second spot")
    px, py = (spot[1] + 0.6) / 100, (spot[2] - 0.6) / 100
    W.OnGatherLoot()
    assert(#records == 2, "a gather 8 yards away was merged into the known spot")
    table.remove(records)
    px, py = spot[1] / 100, spot[2] / 100
    local spots, mine = W.GatherSpots(1411, "ore")
    assert(#spots == #main.Data.gathering.maps[1411].ore, "a record on a known spot added a new spot")
    local merged
    for _, s in ipairs(spots) do if mine[s] then merged = s end end
    assert(merged and mine[merged] == 3, "known spot does not carry your count")
    local _, _, lines = W.DescribeSpot("ore", merged, 0, mine[merged])
    local found = false
    for _, line in ipairs(lines) do found = found or line:find("3", 1, true) and line:find(main.L["You gathered here %d times"]:sub(1, 6), 1, true) end
    assert(found, "tooltip has no gathered count")
    -- 数据里没有的物件，拾取里有铜矿石：按物品认出，记成新的一处
    px, py = 0.9, 0.9
    guid, loot = "GameObject-0-1-2-3-999999-00000ABD", { "|cffffffff|Hitem:2770::::|h[Copper Ore]|h|r" }
    W.OnGatherLoot()
    spots, mine = W.GatherSpots(1411, "ore")
    assert(#spots == #main.Data.gathering.maps[1411].ore + 1, "new node was not added as its own spot")
    assert(spots[#spots][3] == copper and mine[spots[#spots]] == 1, "new spot does not list copper")
    -- 采完不用开大地图，小地图上马上出现这个新点（玩家就站在它旁边，在小地图正中）
    do
        local saved = { C_Map.GetWorldPosFromMapPos, CreateVector2D, C_Minimap, GetProfessions, GetProfessionInfo }
        C_Map.GetWorldPosFromMapPos = function(_, v) return 1, { x = 1000 - v.y * 1000, y = 1000 - v.x * 1000 } end
        CreateVector2D = function(x, y) return { x = x, y = y } end
        C_Minimap = { GetViewRadius = function() return 100 end }
        GetProfessions = function() return 1 end
        GetProfessionInfo = function() return "Mining", nil, 50, 75, 0, 0, 186 end
        Minimap:SetWidth(140)
        Minimap:Show()
        px, py = 0.35, 0.95
        guid, loot = "GameObject-0-1-2-3-999998-00000AC0", { "|cffffffff|Hitem:2770::::|h[Copper Ore]|h|r" }
        W.OnGatherLoot()
        local atPlayer = false
        for _, pin in ipairs(W.minimapGatherPins) do
            if pin.shown and math.abs(pin.pointX) < 1e-6 and math.abs(pin.pointY) < 1e-6 then atPlayer = true end
        end
        assert(atPlayer, "the node just gathered does not show on the minimap right away")
        C_Map.GetWorldPosFromMapPos, CreateVector2D, C_Minimap, GetProfessions, GetProfessionInfo = unpack(saved, 1, 5)
        local records = main.db.gathered[1411]
        table.remove(records) -- 这个点只为验证小地图，不影响下面的计数
        px, py = 0.9, 0.9
        guid, loot = "GameObject-0-1-2-3-999999-00000ABD", { "|cffffffff|Hitem:2770::::|h[Copper Ore]|h|r" }
    end
    -- 自己记过的新点同样有误差范围：在它旁边约 3 码处再采一次，不另记
    px, py = 0.902, 0.898
    W.OnGatherLoot()
    spots, mine = W.GatherSpots(1411, "ore")
    assert(#spots == #main.Data.gathering.maps[1411].ore + 1 and mine[spots[#spots]] == 2,
        "a gather next to your own recorded spot made another spot")
    -- 不记：来源不是物件、在副本里、来源是秘密值、关掉了设置
    local count = #main.db.gathered[1411]
    guid, loot = "Creature-0-1-2-3-500-00000ABE", {}
    W.OnGatherLoot()
    guid = ("GameObject-0-1-2-3-%d-00000ABF"):format(objectID)
    px, py = 0.1, 0.1
    IsInInstance = function() return true end
    W.OnGatherLoot()
    IsInInstance = saved[2]
    issecretvalue = function() return true end
    W.OnGatherLoot()
    issecretvalue = saved[3]
    main.db.modules.WorldMap.recordGather = false
    W.OnGatherLoot()
    main.db.modules.WorldMap.recordGather = nil
    -- 任务物件：拾取格子标了任务物品，或物品类别是任务物品（12），都不记
    px, py = 0.5, 0.2
    guid, loot = "GameObject-0-1-2-3-999997-00000AC1", { "|cffffffff|Hitem:2770::::|h[Copper Ore]|h|r" }
    GetLootSlotInfo = function() return nil, "Ore", 1, nil, 1, false, true end
    W.OnGatherLoot()
    GetLootSlotInfo = nil
    local savedItem = C_Item
    C_Item = setmetatable({ GetItemInfoInstant = function() return 2770, nil, nil, nil, nil, 12, 0 end },
        { __index = savedItem })
    W.OnGatherLoot()
    C_Item = savedItem
    assert(#main.db.gathered[1411] == count, "recorded something it should not")
    main.db.gathered = nil
    C_Map.GetPlayerMapPosition, WorldMapFrame.shown = saved[1], saved[4]
    C_Map.GetWorldPosFromMapPos, CreateVector2D = saved[5], saved[6]
    GetLootSourceInfo, GetNumLootItems, GetLootSlotLink = nil, nil, nil
end)
check("world map: profession trainers for your professions, the next rank stands out", function()
    local provider = WorldMapFrame.providers[6]
    assert(provider, "trainer provider not added")
    local alchemy
    for _, profession in ipairs(main.Data.professions) do
        if profession.slug == "alchemy" then alchemy = profession end
    end
    -- 部落玩家：找一张有中级炼金训练师（部落或中立、有坐标）的地图
    local mapID
    for _, trainer in ipairs(alchemy.trainers) do
        if trainer.rank == "journeyman" and trainer.x and trainer.faction ~= "A" then mapID = mapID or trainer.map end
    end
    assert(mapID, "no horde journeyman alchemy trainer in the data")
    local map = provider:GetMap()
    local savedMap = map.GetMapID
    map.GetMapID = function() return mapID end
    local function pinsOf()
        provider:RefreshAllData()
        local list = {}
        for _, pin in ipairs(pins) do
            if pin.template == "WowHandbookTrainerPinTemplate" then tinsert(list, pin) end
        end
        return list
    end
    GetProfessions = function() return 1 end
    local learned = false
    GetProfessionInfo = function() if learned then return "Alchemy", nil, 60, 75, 0, 0, 171 end end
    assert(#pinsOf() == 0, "trainers shown without any profession")
    learned = true
    local list = pinsOf()
    assert(#list > 0, "no alchemy trainer pins")
    local nextPin
    for _, pin in ipairs(list) do
        assert(pin.whLines[2]:find(main.Name(alchemy.name), 1, true), "a non-alchemy trainer is shown")
        assert(tostring(pin.whTexture.texture):find("trade_alchemy$"), "trainer pin does not use the profession icon")
        if pin.alpha == 1 then nextPin = pin end
    end
    assert(nextPin, "the journeyman trainer (next rank) is not highlighted")
    waypoint = nil
    nextPin:OnMouseClickAction("LeftButton")
    assert(waypoint, "clicking a trainer should set a waypoint")
    main.db.modules.WorldMap.trainerPins = "all"
    assert(#pinsOf() >= #list, "all professions shows fewer trainers")
    main.db.modules.WorldMap.trainerPins = "off"
    assert(#pinsOf() == 0, "trainers shown while turned off")
    main.db.modules.WorldMap.trainerPins = nil
    provider:RemoveAllData()
    map.GetMapID = savedMap
    GetProfessions, GetProfessionInfo = nil, nil
end)
check("world map: class trainers of your class, spells to train now in the tooltip", function()
    local W = main.modules.WorldMap
    local provider = WorldMapFrame.providers[7]
    assert(provider, "class trainer provider not added")
    -- 法师（部落）：找一张有本阵营或中立、带坐标的法师训练师与传送门训练师的地图
    local mapID
    local count = {}
    for _, trainer in ipairs(main.Data.classTrainers.mage) do
        if trainer.x and trainer.faction ~= "A" then
            count[trainer.map] = count[trainer.map] or { plain = 0, portal = 0 }
            if trainer.kind == "portal" then count[trainer.map].portal = count[trainer.map].portal + 1
            else count[trainer.map].plain = count[trainer.map].plain + 1 end
        end
    end
    for id, c in pairs(count) do if c.plain > 0 and c.portal > 0 then mapID = id end end
    assert(mapID, "no horde map with both mage and portal trainers")
    local map = provider:GetMap()
    local savedMap = map.GetMapID
    map.GetMapID = function() return mapID end
    local function pinsOf()
        provider:RefreshAllData()
        local list = {}
        for _, pin in ipairs(pins) do
            if pin.template == "WowHandbookClassTrainerPinTemplate" then tinsert(list, pin) end
        end
        return list
    end
    local list = pinsOf()
    assert(#list == #W.ClassTrainersForMap(mapID) and #list == count[mapID].plain + count[mapID].portal,
        ("%d class trainer pins on the map"):format(#list))
    local plain, portal
    for _, pin in ipairs(list) do
        local texture = tostring(pin.whTexture.texture)
        if texture:find("ClassIcon_Mage$") then plain = plain or pin end
        if texture:find("Spell_Arcane_PortalIronForge$") then portal = portal or pin end
        for _, trainer in ipairs(main.Data.classTrainers.warrior) do
            assert(pin.whLines[1] ~= main.Name(trainer.name), "a warrior trainer is shown to a mage")
        end
    end
    assert(plain and portal, "mage trainer or portal trainer icon is wrong")
    local spellsLine = plain.whLines[3]
    assert(spellsLine:find(main.L["Nothing new to train yet"], 1, true) or spellsLine:find("%d"),
        "mage trainer tooltip has no spells-to-train line")
    waypoint = nil
    plain:OnMouseClickAction("LeftButton")
    assert(waypoint, "clicking a class trainer should set a waypoint")
    main.db.modules.WorldMap.classTrainerPins = false
    assert(#pinsOf() == 0, "class trainers shown while turned off")
    main.db.modules.WorldMap.classTrainerPins = true
    provider:RemoveAllData()
    map.GetMapID = savedMap
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
    -- 湿地中部的灵魂医者（坐标随实测数据微调，按大致位置判断）
    assert(math.abs(spots[2][1] - 49.3) < 1 and math.abs(spots[2][2] - 41.8) < 1, "central Wetlands spirit healer missing")
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
    -- 领主大厅不推荐给部落角色，但副本手册里照样列出（怒焰裂谷对联盟同理）
    playerLevel = 14
    for _, item in ipairs(main.modules.Dungeons.Summary(4, 4).recommended) do
        assert(main.Data.dungeons[item.index].slug ~= "hall-of-thanes", "Hall of Thanes recommended to Horde")
    end
    do
        local D = main.modules.Dungeons
        D:ShowHome()
        local listed = {}
        for _, card in ipairs(D.page.home.cards) do
            if card.shown ~= false and card.index then listed[main.Data.dungeons[card.index].slug] = true end
        end
        assert(listed["hall-of-thanes"] and listed["ragefire-chasm"], "the dungeon guide does not list both factions' dungeons")
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
check("settings: category nav with one list of rows, About on its own page, language switch", function()
    main.MainFrame:SelectTab("settings")
    local page
    for _, f in ipairs(allFrames) do
        if rawget(f, "ShowCategory") then page = f end
    end
    assert(page and page.scroll and page.list.parent == page.scroll.scrollChild, "settings body not in a scroll area")
    -- 每个分类都能打开，列表高度覆盖全部内容
    for _, id in ipairs({ "general", "dungeons", "quests", "spells", "professions", "map", "about" }) do
        page.ShowCategory(id)
        assert(page.category == id and page.list.shown ~= false, "category did not open: " .. id)
        assert(page.contentHeight > 0, "empty category: " .. id)
    end
    assert(page.about and page.about.parent == page.list, "About is not on the About page")
    -- 语言：选了中文存进存档，重载前不改当前界面
    page.ShowCategory("general")
    local before = main.locale
    local dropdown = page.list.languageDropdown
    assert(dropdown, "no language setting")
    dropdown.onChange("zhCN")
    assert(main.db.language == "zhCN" and main.locale == before, "language choice not saved, or applied before reload")
    main:ApplyLanguage(main.db.language)
    assert(main.L["Copy website link"] == "复制网站链接", "Chinese not applied after choosing it")
    main:ApplyLanguage("enUS")
    assert(main.L["Copy website link"] == "Copy website link", "English not applied")
    dropdown.onChange("auto")
    assert(main.db.language == nil, "game language not stored as the default")
    main:ApplyLanguage(nil)
    assert(main.locale == before, "auto does not follow the client")
end)
check("appearance: accent follows the class by default, schemes and background opacity apply at once", function()
    local Theme = main.Theme
    local function near(color, r, g, b) return math.abs(color[1] - r) + math.abs(color[2] - g) + math.abs(color[3] - b) < 0.01 end
    -- 测试角色是法师：默认配色跟随职业
    assert(main.db.appearance.scheme == "class" and main.db.appearance.opacity == 100, "wrong appearance defaults")
    assert(near(Theme.colors.gold, 0x3f / 255, 0xc7 / 255, 0xeb / 255), "accent does not follow the mage class color")
    assert(Theme.hex.gold == "ff3fc7eb", "inline accent hex not updated: " .. Theme.hex.gold)
    assert(Theme:Color("x", "gold") == "|cff3fc7ebx|r", "Theme:Color does not use the scheme accent")
    main.MainFrame:Open("settings")
    local page
    for _, f in ipairs(allFrames) do
        if rawget(f, "ShowCategory") then page = f end
    end
    page.ShowCategory("general")
    local list = page.list
    assert(list.schemeDropdown and #list.schemeDropdown.items == 11, "scheme list should be: my class, gold and 9 classes")
    -- 换成金色：颜色表原地改写，已创建的窗口、导航立即重刷
    local frame = WowHandbookMainFrame
    list.schemeDropdown.onChange("gold")
    assert(main.db.appearance.scheme == "gold" and near(Theme.colors.gold, 0xe0 / 255, 0xb4 / 255, 0x58 / 255),
        "gold scheme not applied")
    assert(Theme.hex.gold == "ffe0b458", "gold hex not restored")
    assert(near(WowHandbookFontHeading.textColor, 0xe0 / 255, 0xb4 / 255, 0x58 / 255), "heading font did not follow the scheme")
    local selectedNav
    for _, button in ipairs(frame.navButtons) do
        if button.tabID == "settings" then selectedNav = button end
    end
    assert(near(selectedNav.label.textColor, 0xe0 / 255, 0xb4 / 255, 0x58 / 255), "selected nav label not repainted")
    assert(near(selectedNav.accent.color, 0xe0 / 255, 0xb4 / 255, 0x58 / 255), "nav accent bar not repainted")
    list.schemeDropdown.onChange("druid")
    assert(Theme.hex.gold == "ffff7c0a" and near(selectedNav.accent.color, 1, 0x7c / 255, 0x0a / 255), "class scheme not applied")
    assert(Theme.colors.goldDim[1] < Theme.colors.gold[1] and Theme.colors.selected[4] < 0.2, "derived accent colors wrong")
    -- 背景不透明度：每次 10%，不低于 30%；只影响大面积底色，菜单与文字不变
    assert(math.abs(frame.backdropColor[4] - 0.97) < 0.001, "window should start solid")
    list.opacityMinus:Click()
    assert(main.db.appearance.opacity == 90 and list.opacityValue:GetText() == "90%", "opacity step not saved or shown")
    assert(math.abs(frame.backdropColor[4] - 0.97 * 0.9) < 0.001, "window background did not become translucent")
    assert(math.abs(Theme.colors.sidebar[4] - 0.9) < 0.001 and math.abs(Theme.colors.panel[4] - 0.9) < 0.001,
        "sidebar and cards did not follow the opacity")
    assert(Theme.colors.menu[4] == 0.97 and Theme.colors.text[4] == 1 and Theme.colors.line[4] == 1,
        "menus, text and borders must stay solid")
    for _ = 1, 12 do list.opacityMinus:Click() end
    assert(main.db.appearance.opacity == 30, "opacity went below the minimum")
    for _ = 1, 12 do list.opacityPlus:Click() end
    assert(main.db.appearance.opacity == 100 and math.abs(frame.backdropColor[4] - 0.97) < 0.001, "opacity did not return to solid")
    -- 幽灵按钮未悬停时是透明的，不会在半透明窗口上叠出深色块
    assert(Theme.colors.none[4] == 0, "no transparent color for ghost buttons")
    list.schemeDropdown.onChange("class")
    assert(Theme.hex.gold == "ff3fc7eb", "did not return to the class scheme")
end)
check("talent simulator: every class renders, points follow the game rules, builds are saved and shareable", function()
    local Module = main.modules.Talents
    assert(Module and Module.enabled, "talent module not enabled")
    local Rules = Module.Rules
    main.MainFrame:Open("talents")
    local page = Module.page
    assert(page and page:IsVisible(), "talent page did not open")
    -- 默认是当前角色的职业（法师），三棵树都画出来
    assert(Module.State.class == "mage", "should start on the player's class: " .. tostring(Module.State.class))
    local classes = main.Data.talents
    for _, class in ipairs(main.Theme.CLASS_ORDER) do
        assert(classes[class] and #classes[class].trees == 3, "no talent data for " .. class)
        page.classDropdown.onChange(class)
        assert(Module.State.class == class, "class did not switch")
        for t, tree in ipairs(classes[class].trees) do
            local panel = page.trees[t]
            assert(panel.shown and panel.title:GetText() == main.Name(tree.name), "tree header wrong for " .. class)
            local shown = 0
            for _, button in ipairs(panel.buttons) do
                if button.shown then shown = shown + 1 end
            end
            assert(shown == #tree.talents, ("%s tree %d: %d buttons for %d talents"):format(class, t, shown, #tree.talents))
            for index, talent in ipairs(tree.talents) do
                assert(talent.max >= 1 and talent.max <= 5 and #talent.ranks.enUS == talent.max and #talent.ranks.zhCN == talent.max,
                    "rank texts missing: " .. talent.name.enUS)
                assert(talent.row >= 1 and talent.row <= 7 and talent.col >= 1 and talent.col <= 4, "talent off the grid")
                assert(not talent.req or (tree.talents[talent.req] and tree.talents[talent.req].row <= talent.row),
                    "bad prerequisite: " .. talent.name.enUS)
                panel.buttons[index].scripts.OnEnter(panel.buttons[index]) -- 鼠标提示不报错
            end
        end
    end
    -- 战士武器系：第一层可点，第二层要先投 5 点
    page.classDropdown.onChange("warrior")
    Module.Reset()
    Module.Refresh()
    local trees = classes.warrior.trees
    local arms, panel = trees[1], page.trees[1]
    local first, second
    for index, talent in ipairs(arms.talents) do
        if talent.row == 1 and not first then first = index end
        if talent.row == 2 and not talent.req and not second then second = index end
    end
    assert(panel.buttons[second].icon.desaturated == true, "a locked talent should look dimmed")
    panel.buttons[second]:Click()
    assert(Module.State.build[1][second] == 0, "row 2 took a point before 5 points in the tree")
    for _ = 1, arms.talents[first].max + 2 do panel.buttons[first]:Click() end
    assert(Module.State.build[1][first] == arms.talents[first].max, "left-click did not fill the talent to its maximum")
    assert(panel.buttons[first].count:GetText() == ("%d/%d"):format(arms.talents[first].max, arms.talents[first].max),
        "rank label not updated")
    -- 第一层凑满 5 点后第二层开放
    for index, talent in ipairs(arms.talents) do
        if talent.row == 1 then
            while Rules.PointsBelow(arms, Module.State.build[1], 2) < 5 and Module.Spend(1, index, 1) do end
        end
    end
    Module.Refresh()
    assert(Rules.PointsBelow(arms, Module.State.build[1], 2) == 5, "could not put 5 points in row 1")
    assert(panel.buttons[second].icon.desaturated == false, "row 2 did not open after 5 points")
    panel.buttons[second]:Click()
    assert(Module.State.build[1][second] == 1, "row 2 did not take a point after 5 points")
    -- 第二层有点时，第一层不能减到 5 点以下
    panel.buttons[first].scripts.OnClick(panel.buttons[first], "RightButton")
    assert(Rules.PointsBelow(arms, Module.State.build[1], 2) == 5, "right-click removed a point the next row depends on")
    panel.buttons[second].scripts.OnClick(panel.buttons[second], "RightButton")
    assert(Module.State.build[1][second] == 0, "right-click did not remove a point")
    -- 前置天赋：没点满前置不能点
    local dependent
    for index, talent in ipairs(arms.talents) do
        if talent.req then dependent = index break end
    end
    local req = arms.talents[dependent].req
    local ranks = Rules.Empty(trees)[1]
    for index, talent in ipairs(arms.talents) do
        if talent.row < arms.talents[dependent].row and index ~= req then ranks[index] = talent.max end
    end
    assert(Rules.RowOpen(arms, ranks, arms.talents[dependent].row) and not Rules.IsAvailable(arms, ranks, dependent),
        "a talent opened without its prerequisite")
    ranks[req] = arms.talents[req].max
    assert(Rules.IsAvailable(arms, ranks, dependent), "a talent stayed locked with its prerequisite maxed")
    -- 总共 51 点
    Module.Reset()
    local spent = true
    while spent do
        spent = false
        for t, tree in ipairs(trees) do
            for index in ipairs(tree.talents) do
                if Module.Spend(t, index, 1) then spent = true end
            end
        end
    end
    assert(Rules.Total(Module.State.build) == 51 and Rules.RequiredLevel(51) == 60, "the build should stop at 51 points")
    assert(Rules.PointsAtLevel(9) == 0 and Rules.PointsAtLevel(10) == 1 and Rules.PointsAtLevel(60) == 51, "points per level wrong")
    -- 分享码与网站格式一致：每个天赋一位数字，末尾的 0 去掉；存档按职业保存，换职业再回来还在
    local code = Module.Code()
    assert(code:match("^[%d%-]+$") and Rules.Encode(Rules.Decode(trees, code)) == code, "share code does not round-trip")
    assert(main.db.modules.Talents.builds.warrior == code, "build not saved")
    page.classDropdown.onChange("mage")
    page.classDropdown.onChange("warrior")
    assert(Module.Code() == code, "build lost after switching class")
    assert(Rules.Encode(Rules.Decode(trees, "9")) == "" and Rules.Encode(Rules.Decode(trees, "abc")) == "",
        "an illegal code should decode to an empty build")
    assert(Rules.Encode({ { 3, 0, 2, 0 }, { 0, 0 }, { 0, 1 } }) == "302--01", "share code format differs from the website")
    -- 网站链接：职业页加分享码；空加点不带 #
    page.link:Click()
    local expected = main.Links:Build("talents", "warrior") .. "#" .. code
    assert(WowHandbookLinkDialog.shown and WowHandbookLinkDialog.url == expected, "wrong build link: " .. tostring(WowHandbookLinkDialog.url))
    assert(expected:find("/talents/warrior/#", 1, true), "talent link has the wrong route")
    WowHandbookLinkDialog:Hide()
    panel.reset:Click()
    assert(Rules.TreeTotal(Module.State.build[1]) == 0 and Rules.Total(Module.State.build) > 0, "tree reset should clear one tree only")
    page.resetAll:Click()
    assert(Module.Code() == "" and main.db.modules.Talents.builds.warrior == nil, "reset did not clear the build")
    assert(main.Links:Build("talents", "warrior"):sub(-1) == "/", "an empty build should link to the plain class page")
    assert(not pcall(main.Links.Build, main.Links, "talents", "warrior", "x<y"), "unsafe link fragment accepted")
    -- /wh talents 打开模拟器
    main.MainFrame:SelectTab("home")
    SlashCmdList.WOWHANDBOOK("talents")
    assert(page:IsVisible(), "/wh talents did not open the simulator")
    page.classDropdown.onChange("mage")
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
            assert(card.quests:GetText() ~= "", "card stats row empty")
            assert(not card.meta:GetText():find(main.L["Level"], 1, true), "card still spells out the level label")
        end
    end
    -- 卡片用图标代替文字，完整说明在悬停提示里
    local rfcCard
    for _, card in ipairs(cards) do
        if card.shown and main.Data.dungeons[card.index].slug == "ragefire-chasm" then rfcCard = card end
    end
    assert(rfcCard.quests:GetText():find(D.CARD_ICON.boss, 1, true), "card has no boss icon")
    assert(not rfcCard.where:GetText():find(main.L["Entrance in %s"]:gsub("%%s", ""), 1, true), "card still says entrance in")
    GameTooltip.lines = {}
    rfcCard:onHover(true)
    local tip = table.concat(GameTooltip.lines, "\n")
    assert(tip:find((main.L["%d bosses"]):format(main.BossCount(main.Data.dungeons[rfcCard.index])), 1, true),
        "card tooltip has no boss count")
    assert(tip:find(main.L["Entrance in %s"]:gsub("%%s", ""), 1, true), "card tooltip has no entrance")
    rfcCard:onHover(false)
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
check("dungeon card: a dungeon whose quests are all for the other faction says so", function()
    local D = main.modules.Dungeons
    local savedFaction = UnitFactionGroup
    local savedQuests = { main.Data.quests[-101], main.Data.quests[-102] }
    main.Data.quests[-101], main.Data.quests[-102] = { faction = "A", min = 10 }, { faction = "A", min = 12 }
    local dungeon = { quests = { -101, -102 } }
    UnitFactionGroup = function() return "Horde" end
    local total, _, _, _, others = D.QuestSummary(dungeon)
    assert(total == 0 and others == 2, ("horde sees total %d others %d"):format(total, others))
    UnitFactionGroup = function() return "Alliance" end
    total, _, _, _, others = D.QuestSummary(dungeon)
    assert(total == 2 and others == 0, "alliance does not see its own quests")
    main.Data.quests[-101], main.Data.quests[-102] = savedQuests[1], savedQuests[2]
    UnitFactionGroup = savedFaction
end)
check("dungeon card: only final dungeon quests count, and the badge follows accepted and done", function()
    local D = main.modules.Dungeons
    local saved = { main.Data.quests[-201], main.Data.quests[-202], main.Data.quests[-203] }
    local savedCompleted, savedActive = completedQuests, activeQuests
    -- -201 是 -202 的任务链前置步骤：副本任务只有 -202 与 -203 两个
    main.Data.quests[-201] = { min = 10 }
    main.Data.quests[-202] = { min = 12, before = { -201 } }
    main.Data.quests[-203] = { min = 12 }
    local dungeon = { quests = { -201, -202, -203 } }
    completedQuests, activeQuests = {}, {}
    local total, done, _, active = D.QuestSummary(dungeon)
    assert(total == 2, ("chain step counted as a dungeon quest: total %d"):format(total))
    assert(D.QuestBadge(total, done, active) == D.CARD_ICON.ready, "untaken quests are not shown with !")
    -- 前置正在做、另一个也接了：都接了没做完，用 ?
    activeQuests = { [-201] = true, [-203] = true }
    total, done, _, active = D.QuestSummary(dungeon)
    assert(active == 2 and D.QuestBadge(total, done, active) == D.CARD_ICON.active, "all taken but unfinished is not ?")
    -- 全部完成：绿勾
    completedQuests, activeQuests = { [-201] = true, [-202] = true, [-203] = true }, {}
    total, done, _, active = D.QuestSummary(dungeon)
    assert(done == 2 and D.QuestBadge(total, done, active) == D.CARD_ICON.done, "all done is not a check")
    completedQuests, activeQuests = savedCompleted, savedActive
    main.Data.quests[-201], main.Data.quests[-202], main.Data.quests[-203] = saved[1], saved[2], saved[3]
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
        return (f.progress:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("(%d)/(%d)", "%1 / %2"))
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
    assert(questRow and questRow.tag:GetText():find("3/8", 1, true), "quest row does not show the objective count")
    -- 多个目标：各自显示数量，接口给的数量优先于文字
    questObjectives[questID] = { { text = "Ragefire Trogg slain: 3/8", finished = false },
        { text = "Hide", numFulfilled = 5, numRequired = 5, finished = true } }
    T.Refresh()
    -- 已完成的目标换成绿勾，不再写 5/5
    assert(questRow.tag:GetText():find("3/8", 1, true) and questRow.tag:GetText():find(T.QUEST_ICON.done, 1, true)
        and not questRow.tag:GetText():find("5/5", 1, true), "quest row does not show every objective count")
    questObjectives[questID] = { { text = "Ragefire Trogg slain: 3/8", finished = false } }
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
    assert(f.nextRow.shown and f.nextRow.boss and not f.nextRow.killed, "collapsed card does not show the next boss")
    assert(f.nextRow.name:GetText():find(main.BossName(f.nextRow.boss), 1, true), "collapsed next boss has the wrong name")
    main.db.modules.InstanceTracker.collapsed = false
    T.Refresh()
    assert(not f.nextRow.shown, "next boss row stays when expanded")
    main.db.modules.InstanceTracker.collapsed = true
    T.Refresh()
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
