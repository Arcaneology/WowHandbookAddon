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
local Module = ns:NewModule("WorldMap", { levelLabel = true, flightPins = true, revealMap = true, mapScale = 1 })

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

function Module:ApplyScale()
    if WorldMapFrame and not InCombatLockdown() then
        local scale = Settings().mapScale or 1
        if scale ~= 1 or WorldMapFrame:GetScale() ~= 1 then
            WorldMapFrame:SetScale(scale)
        end
    end
end

function Module:Refresh()
    for _, dataProvider in ipairs({ provider, revealProvider }) do
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
    -- 探索了新区域：该区域改由暴雪自带图层显示，这里不再补画
    ns:RegisterEvent("MAP_EXPLORATION_UPDATED", function()
        if WorldMapFrame and WorldMapFrame:IsShown() then
            Module:Refresh()
        end
    end)
end
