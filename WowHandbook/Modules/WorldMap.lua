local ADDON_NAME, ns = ...
local L = ns.L

-- 大地图增强，全部沿用暴雪地图自己的界面：
-- · F7 等级区间：鼠标指向区域时，地图顶部原生的区域名标签下方（标签的“描述”行）显示等级区间，
--   颜色沿用暴雪的任务难度色。客户端自己能给出等级时（C_Map.GetMapLevels）不重复显示。
-- · F9 飞行点：用继承暴雪飞行点模板的图钉（外观、悬停名称与“未发现的飞行点”说明都与原生一致），
--   只在暴雪自带图层不显示飞行点的地图上绘制；未开启的飞行点图标变灰（暴雪表示不可用的方式），
--   暴雪自带图层里的飞行点同样处理。对方阵营的飞行点不显示。
-- · F8 地图缩放：设置里可调大地图缩放比例（1.0 表示不改动）。
-- · 完整地图：补画尚未探索的区域（贴图来自客户端表导出的 Data/MapOverlays.lua），颜色略暗以区分已探索区域；
--   设置里可关闭。
-- · 副本入口：区域地图与大陆地图上标出副本与团队副本入口，悬停看等级区间，点击在手册里打开。
-- · 灵魂医者：默认死亡时显示（可改为始终或不显示），点击设为导航。
local Module = ns:NewModule("WorldMap", { levelLabel = true, flightPins = true, revealMap = true, mapScale = 1,
    dungeonPins = true, spiritHealers = "dead" })

local PIN_TEMPLATE = "WowHandbookFlightPinTemplate"
local BLIZZARD_PIN_TEMPLATE = "FlightPointPinTemplate"

local function Settings()
    return ns:GetModuleSettings(Module)
end

local function FactionEnum()
    return Enum and Enum.FlightPathFaction or { Neutral = 0, Horde = 1, Alliance = 2 }
end

local function NodeVisible(node)
    local faction, enum = UnitFactionGroup("player"), FactionEnum()
    if node.faction == enum.Horde then
        return faction == "Horde"
    elseif node.faction == enum.Alliance then
        return faction == "Alliance"
    end
    return true
end

local function NodesForMap(mapID)
    local nodes = {}
    for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(mapID) or {}) do
        if NodeVisible(node) then
            tinsert(nodes, node)
        end
    end
    return nodes
end

-- 与暴雪飞行点图层相同的说明文字（“未发现的飞行点”等）
local function Describe(node)
    if not node.isUndiscovered then
        return node
    end
    local enum = FactionEnum()
    if node.faction == enum.Horde and UNDISCOVERED_FACTION_FLIGHTPOINT then
        node.description = UNDISCOVERED_FACTION_FLIGHTPOINT:format(FACTION_HORDE)
    elseif node.faction == enum.Alliance and UNDISCOVERED_FACTION_FLIGHTPOINT then
        node.description = UNDISCOVERED_FACTION_FLIGHTPOINT:format(FACTION_ALLIANCE)
    else
        node.description = UNDISCOVERED_NEUTRAL_FLIGHTPOINT or L["Flight path not unlocked yet"]
    end
    return node
end

-- 未开启的飞行点图标变灰
local function StylePin(pin)
    local info = pin.poiInfo or pin.node
    if pin.Texture and info then
        pin.Texture:SetDesaturated(info.isUndiscovered and true or false)
    end
end

local function StyleAllPins(map)
    if not map.EnumeratePinsByTemplate then
        return
    end
    for _, template in ipairs({ BLIZZARD_PIN_TEMPLATE, PIN_TEMPLATE }) do
        for pin in map:EnumeratePinsByTemplate(template) do
            StylePin(pin)
        end
    end
end

--------------------------------------------------------------------------------
-- 飞行点数据提供者
--------------------------------------------------------------------------------

local provider

local function CreateProvider()
    provider = CreateFromMixins(MapCanvasDataProviderMixin)
    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(PIN_TEMPLATE)
    end
    function provider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not (mapID and Settings().flightPins) then
            return
        end
        -- 暴雪自带图层显示飞行点的地图上不重复绘制，只把未开启的变灰
        local blizzardShows = C_TaxiMap.ShouldMapShowTaxiNodes and C_TaxiMap.ShouldMapShowTaxiNodes(mapID)
        if not blizzardShows then
            for _, node in ipairs(NodesForMap(mapID)) do
                map:AcquirePin(PIN_TEMPLATE, Describe(node))
            end
        end
        -- 暴雪图层可能在本图层之后刷新，下一帧再统一处理颜色
        C_Timer.After(0, function()
            StyleAllPins(map)
        end)
    end
    return provider
end

--------------------------------------------------------------------------------
-- 完整地图：未探索区域的贴图
--------------------------------------------------------------------------------

local UNEXPLORED_SHADE = 0.7 -- 未探索区域的亮度，已探索区域保持原样
local reveal = { textures = {}, used = 0 }

local function RevealTexture()
    reveal.used = reveal.used + 1
    local texture = reveal.textures[reveal.used]
    if not texture then
        texture = reveal.frame:CreateTexture(nil, "ARTWORK")
        reveal.textures[reveal.used] = texture
    end
    return texture
end

local function ExploredKeys(mapID)
    local keys = {}
    local explored = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures(mapID)
    for _, info in ipairs(explored or {}) do
        keys[info.offsetX .. ":" .. info.offsetY] = true
    end
    return keys
end

-- 按贴图的宽高切成与地图图层相同大小的格子（通常 256），逐格放到地图画布的像素位置上
local function DrawOverlay(overlay, tileWidth, tileHeight)
    local width, height, left, top = overlay[1], overlay[2], overlay[3], overlay[4]
    local columns = math.ceil(width / tileWidth)
    local rows = math.ceil(height / tileHeight)
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local fileID = overlay[4 + row * columns + column + 1]
            if fileID then
                local pixelWidth = math.min(tileWidth, width - column * tileWidth)
                local pixelHeight = math.min(tileHeight, height - row * tileHeight)
                local texture = RevealTexture()
                texture:SetTexture(fileID)
                texture:SetSize(pixelWidth, pixelHeight)
                texture:SetTexCoord(0, pixelWidth / tileWidth, 0, pixelHeight / tileHeight)
                texture:ClearAllPoints()
                texture:SetPoint("TOPLEFT", left + column * tileWidth, -(top + row * tileHeight))
                texture:SetVertexColor(UNEXPLORED_SHADE, UNEXPLORED_SHADE, UNEXPLORED_SHADE)
                texture:Show()
            end
        end
    end
end

local function RefreshReveal(map)
    for index = 1, reveal.used do
        reveal.textures[index]:Hide()
    end
    reveal.used = 0
    local mapID = map:GetMapID()
    local overlays = mapID and ns.Data.mapOverlays and ns.Data.mapOverlays[mapID]
    if not (overlays and Settings().revealMap) then
        if reveal.frame then
            reveal.frame:Hide()
        end
        return
    end
    local canvas = map:GetCanvas()
    if not reveal.frame then
        reveal.frame = CreateFrame("Frame", nil, canvas)
    end
    local frame = reveal.frame
    frame:SetParent(canvas)
    -- 放在画布上一层：高于地图底图，低于各类图钉
    frame:SetFrameLevel(canvas:GetFrameLevel() + 1)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", canvas, "TOPLEFT")
    frame:SetSize(map:DenormalizeHorizontalSize(1), map:DenormalizeVerticalSize(1))
    local layer = C_Map.GetMapArtLayers and (C_Map.GetMapArtLayers(mapID) or {})[1]
    local tileWidth = layer and layer.tileWidth or 256
    local tileHeight = layer and layer.tileHeight or 256
    local explored = ExploredKeys(mapID)
    for _, overlay in ipairs(overlays) do
        if not explored[overlay[3] .. ":" .. overlay[4]] then
            DrawOverlay(overlay, tileWidth, tileHeight)
        end
    end
    frame:Show()
end

local revealProvider

local function CreateRevealProvider()
    revealProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function revealProvider:RemoveAllData()
        if reveal.frame then
            reveal.frame:Hide()
        end
    end
    function revealProvider:RefreshAllData()
        RefreshReveal(self:GetMap())
    end
    return revealProvider
end

--------------------------------------------------------------------------------
-- 区域等级：写进地图原生区域名标签的描述行
--------------------------------------------------------------------------------

local function DifficultyColorCode(minLevel, maxLevel)
    local level = UnitLevel("player")
    if GetQuestDifficultyColor and RGBTableToColorCode then
        local color
        if level < minLevel then
            color = GetQuestDifficultyColor(minLevel)
        elseif level > maxLevel then
            color = GetQuestDifficultyColor(maxLevel - 2)
        else
            color = QuestDifficultyColors and QuestDifficultyColors.difficult or GetQuestDifficultyColor(level)
        end
        return RGBTableToColorCode(color)
    end
    return "|c" .. ns.LevelColor(minLevel, maxLevel)
end

local function ZoneDescription(zoneMapID)
    local zone = ns.Data.zones[zoneMapID]
    local parts = {}
    if zone and zone.levels then
        local nativeMin = C_Map.GetMapLevels and C_Map.GetMapLevels(zoneMapID)
        if not (nativeMin and nativeMin > 0) then
            local minLevel, maxLevel = zone.levels[1], zone.levels[2]
            tinsert(parts, DifficultyColorCode(minLevel, maxLevel) .. (L["Level %s"]):format(ns.LevelRange(zone.levels)) .. "|r")
        end
    end
    return #parts > 0 and table.concat(parts, "    ") or nil
end

local function HookAreaLabel(label)
    if label.wowHandbookHooked then
        return
    end
    label.wowHandbookHooked = true
    hooksecurefunc(label, "SetLabel", function(self, areaLabelType, name, description)
        local areaName = MAP_AREA_LABEL_TYPE and MAP_AREA_LABEL_TYPE.AREA_NAME
        if not (Settings().levelLabel and areaLabelType == areaName and name and description == nil) then
            return
        end
        local map = self.dataProvider and self.dataProvider:GetMap()
        if not map then
            return
        end
        local mapID = map:GetMapID()
        local x, y = map:GetNormalizedCursorPosition()
        local info = mapID and x and C_Map.GetMapInfoAtPosition(mapID, x, y)
        if not (info and info.mapID and info.mapID ~= mapID) then
            return
        end
        local text = ZoneDescription(info.mapID)
        local labelInfo = self.labelInfoByType and self.labelInfoByType[areaLabelType]
        if text and labelInfo then
            labelInfo.description = text
            labelInfo.descriptionColor = WHITE_FONT_COLOR -- 用文字自带的颜色
            self.dirty = true
        end
    end)
end

local function FindAreaLabel()
    for dataProvider in pairs(WorldMapFrame.dataProviders or {}) do
        local label = type(dataProvider) == "table" and dataProvider.Label
        if label and label.SetLabel and label.labelInfoByType then
            return label
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 地图缩放与挂载
--------------------------------------------------------------------------------
-- 副本入口与灵魂医者图钉：继承暴雪地图的基础图钉模板（MapCanvasPinTemplate），图标与悬停提示在这里设置。
-- 图标优先用客户端自带的图集，没有时用通用贴图。
--------------------------------------------------------------------------------

local DUNGEON_PIN = "WowHandbookDungeonPinTemplate"
local GRAVEYARD_PIN = "WowHandbookGraveyardPinTemplate"
local ICONS = {
    dungeon = { atlas = "Dungeon", texture = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", size = 22 },
    raid = { atlas = "Raid", texture = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", size = 24 },
    graveyard = { atlas = "poi-graveyard-neutral", texture = "Interface\\Icons\\Spell_Holy_Resurrection", size = 18 },
}

local function HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

local function SetupPin(pin, iconKey)
    local icon = ICONS[iconKey]
    if not rawget(pin, "whTexture") then
        pin.whTexture = pin:CreateTexture(nil, "OVERLAY")
        pin.whTexture:SetAllPoints()
        pin.whHighlight = pin:CreateTexture(nil, "HIGHLIGHT")
        pin.whHighlight:SetAllPoints()
        pin.whHighlight:SetBlendMode("ADD")
        if pin.SetScalingLimits then
            pin:SetScalingLimits(1, 1.0, 1.2)
        end
    end
    pin:SetSize(icon.size, icon.size)
    for _, texture in ipairs({ pin.whTexture, pin.whHighlight }) do
        if HasAtlas(icon.atlas) then
            texture:SetAtlas(icon.atlas)
        else
            texture:SetTexture(icon.texture)
        end
    end
    pin.whHighlight:SetAlpha(0.35)
end

-- 图钉的悬停与点击：lines 为提示行（第一行是标题），onClick 为点击动作
local function SetPinBehavior(pin, lines, onClick)
    pin.whLines, pin.whClick = lines, onClick
    pin.OnMouseEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.whLines[1], 1, 0.82, 0)
        for index = 2, #self.whLines do
            GameTooltip:AddLine(self.whLines[index], 1, 1, 1, true)
        end
        GameTooltip:Show()
    end
    pin.OnMouseLeave = function()
        GameTooltip_Hide()
    end
    pin.OnMouseClickAction = function(self, button)
        if button == "LeftButton" and self.whClick then
            self.whClick()
        end
    end
end

-- 区域地图上的坐标（0–100）换到当前显示的地图（0–1）：同一张图直接换算；大陆图经世界坐标换算
local function ToMapPosition(fromMapID, x, y, toMapID)
    if fromMapID == toMapID then
        return x / 100, y / 100
    end
    local info = C_Map.GetMapInfo(toMapID)
    local continent = Enum and Enum.UIMapType and Enum.UIMapType.Continent
    if not (info and continent and info.mapType == continent and C_Map.GetWorldPosFromMapPos
        and C_Map.GetMapPosFromWorldPos and CreateVector2D) then
        return nil
    end
    local continentID, worldPos = C_Map.GetWorldPosFromMapPos(fromMapID, CreateVector2D(x / 100, y / 100))
    if not (continentID and worldPos) then
        return nil
    end
    local _, position = C_Map.GetMapPosFromWorldPos(continentID, worldPos, toMapID)
    if not position then
        return nil
    end
    local px, py = position:GetXY()
    if px < 0 or px > 1 or py < 0 or py > 1 then
        return nil
    end
    return px, py
end

local function DungeonVisible(dungeon)
    local faction = UnitFactionGroup("player")
    return not dungeon.faction or dungeon.faction == "both" or dungeon.faction:lower() == (faction or ""):lower()
end

local dungeonProvider

local function CreateDungeonProvider()
    dungeonProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function dungeonProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(DUNGEON_PIN)
    end
    function dungeonProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not (mapID and Settings().dungeonPins) then
            return
        end
        for index, dungeon in ipairs(ns.Data.dungeons or {}) do
            local entrance = dungeon.entrance
            if entrance and entrance.x and DungeonVisible(dungeon) then
                local px, py = ToMapPosition(entrance.map, entrance.x, entrance.y, mapID)
                if px then
                    local pin = map:AcquirePin(DUNGEON_PIN)
                    SetupPin(pin, dungeon.kind == "raid" and "raid" or "dungeon")
                    local levels = dungeon.levels
                    local color = levels and ns.LevelColor(levels[1], levels[2]) or "ffffffff"
                    SetPinBehavior(pin, {
                        ns.Name(dungeon.name) or "?",
                        levels and ("|c%s%s %s|r"):format(color, L["Level"], ns.LevelRange(levels)) or nil,
                        L["Click to open it in WoW Handbook."],
                    }, function()
                        local module = ns.modules.Dungeons
                        if module and ns:GetModuleSettings(module).enabled ~= false then
                            module:Select(index, "quests")
                        end
                    end)
                    pin:SetPosition(px, py)
                end
            end
        end
    end
    return dungeonProvider
end

--------------------------------------------------------------------------------
-- 灵魂医者：显示时机可设为死亡时（默认）、始终或不显示。先用游戏给的墓地列表
-- （C_DeathInfo.GetGraveyardsForMap），游戏不给时用插件自带的位置（Data/Graveyards.lua）。
--------------------------------------------------------------------------------

local function SpiritHealersWanted()
    local mode = Settings().spiritHealers or "dead"
    if mode == "always" then
        return true
    elseif mode == "dead" then
        return UnitIsDeadOrGhost("player") and true or false
    end
    return false
end

-- { {x, y, name} }，坐标 0–100
local function GraveyardsForMap(mapID)
    local spots = {}
    local fromGame = C_DeathInfo and C_DeathInfo.GetGraveyardsForMap and C_DeathInfo.GetGraveyardsForMap(mapID)
    for _, graveyard in ipairs(fromGame or {}) do
        if graveyard.position then
            local x, y = graveyard.position:GetXY()
            tinsert(spots, { x * 100, y * 100, graveyard.name })
        end
    end
    if #spots == 0 then
        for _, point in ipairs(ns.Data.graveyards and ns.Data.graveyards[mapID] or {}) do
            tinsert(spots, { point[1], point[2] })
        end
    end
    return spots
end
Module.GraveyardsForMap = GraveyardsForMap -- 供测试使用

local graveyardProvider

local function CreateGraveyardProvider()
    graveyardProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function graveyardProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(GRAVEYARD_PIN)
    end
    function graveyardProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not (mapID and SpiritHealersWanted()) then
            return
        end
        for _, spot in ipairs(GraveyardsForMap(mapID)) do
            local pin = map:AcquirePin(GRAVEYARD_PIN)
            SetupPin(pin, "graveyard")
            local title = spot[3] and spot[3] ~= "" and spot[3] or L["Spirit Healer"]
            SetPinBehavior(pin, { title, L["Click to set a waypoint here."] }, function()
                ns.Waypoints:Set(mapID, spot[1], spot[2], title)
            end)
            pin:SetPosition(spot[1] / 100, spot[2] / 100)
        end
    end
    return graveyardProvider
end

--------------------------------------------------------------------------------

function Module:ApplyScale()
    if WorldMapFrame and not InCombatLockdown() then
        local scale = Settings().mapScale or 1
        if scale ~= 1 or WorldMapFrame:GetScale() ~= 1 then
            WorldMapFrame:SetScale(scale)
        end
    end
end

function Module:Refresh()
    for _, dataProvider in ipairs({ provider, revealProvider, dungeonProvider, graveyardProvider }) do
        if dataProvider and dataProvider.GetMap and dataProvider:GetMap() then
            dataProvider:RefreshAllData()
        end
    end
end

local attached = false
local function Attach()
    if attached or not (WorldMapFrame and MapCanvasDataProviderMixin) then
        return
    end
    attached = true
    WorldMapFrame:AddDataProvider(CreateProvider())
    WorldMapFrame:AddDataProvider(CreateRevealProvider())
    WorldMapFrame:AddDataProvider(CreateDungeonProvider())
    WorldMapFrame:AddDataProvider(CreateGraveyardProvider())
    local label = FindAreaLabel()
    if label then
        HookAreaLabel(label)
    end
    WorldMapFrame:HookScript("OnShow", function()
        Module:ApplyScale()
    end)
end

function Module:OnEnable()
    Attach()
    ns:RegisterEvent("ADDON_LOADED", function(_, name)
        if name == "Blizzard_WorldMap" then
            Attach()
        end
    end)
    -- 开了新飞行点后刷新图钉
    ns:RegisterEvent("TAXIMAP_OPENED", function()
        Module:Refresh()
    end)
    -- 死亡、释放灵魂、复活：刷新灵魂医者（只在地图打开时）
    for _, event in ipairs({ "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do
        ns:RegisterEvent(event, function()
            if WorldMapFrame and WorldMapFrame:IsShown() and graveyardProvider and graveyardProvider:GetMap() then
                graveyardProvider:RefreshAllData()
            end
        end)
    end
    -- 探索了新区域：该区域改由暴雪自带图层显示，这里不再补画
    ns:RegisterEvent("MAP_EXPLORATION_UPDATED", function()
        if WorldMapFrame and WorldMapFrame:IsShown() then
            Module:Refresh()
        end
    end)
end
