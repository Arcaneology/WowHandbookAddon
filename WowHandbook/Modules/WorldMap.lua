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
-- · 灵魂医者：默认死亡时显示（可改为始终或不显示），点击设为导航；对方阵营专用的不显示。同时画出复活区域的
--   分界线（死在哪片区域就到哪个灵魂医者，Data/GraveyardAreas.lua），可单独关闭。
-- · 草药与矿点：区域地图上标出采集点（Data/GatheringNodes.lua），默认学了草药学 / 采矿才显示对应的点；
--   技能够采的正常显示，不够的变灰变淡；悬停列出这里可能刷出的几种与所需技能，点击设为导航。
--   小地图上同样显示（Modules/GatherMinimap.lua，可在设置里关闭）；自己采过的点另外记下并合并显示
--   （Modules/GatherLog.lua）。
-- · 职业训练师：显示你职业的训练师（本阵营与中立；猎人另有宠物训练师、法师另有传送门训练师），可关闭；
--   悬停看名字与现在可学的技能数，有可学技能时不透明、没有时半透明；点击设为导航。
-- · 幻化师：显示本阵营的幻化师（暴风城、奥格瑞玛、奥特兰克山脉的达拉然），可关闭；点击设为导航。
-- · 专业训练师：默认显示你学了的专业的训练师（本阵营与中立），可改为全部专业或不显示；下一步该找的那一档
--   不透明，其余半透明；悬停看名字、专业与能教到的等级，点击设为导航。
local Module = ns:NewModule("WorldMap", { levelLabel = true, flightPins = true, revealMap = true, mapScale = 1,
    dungeonPins = true, spiritHealers = "dead", graveyardAreas = true, herbPins = "auto", orePins = "auto", minimapGather = true,
    recordGather = true, minimapGatherStyle = "icon", trainerPins = "mine", classTrainerPins = true,
    transmogPins = true, transportPins = true, pathPins = true })

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

-- 贴图文件的实际边长：中间的格子是完整的 tileSize；最右一列 / 最下一行只剩 remaining 像素，
-- 文件边长是从 16 起不小于 remaining 的 2 的幂（与游戏自带地图探索图层的算法一致）。
local function TileFileSize(remaining, tileSize)
    if remaining >= tileSize then
        return tileSize
    end
    local size = 16
    while size < remaining do
        size = size * 2
    end
    return size
end
Module.TileFileSize = TileFileSize -- 供测试使用

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
                texture:SetTexCoord(0, pixelWidth / TileFileSize(pixelWidth, tileWidth),
                    0, pixelHeight / TileFileSize(pixelHeight, tileHeight))
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
-- 副本入口与灵魂医者图钉：模板（UI/MapPins.xml）创建时混入暴雪的基础图钉方法，图标与悬停提示在这里设置。
-- 图标优先用客户端自带的图集，没有时用通用贴图。
--------------------------------------------------------------------------------

local DUNGEON_PIN = "WowHandbookDungeonPinTemplate"
local GRAVEYARD_PIN = "WowHandbookGraveyardPinTemplate"
local GATHER_PIN = "WowHandbookGatherPinTemplate"
local TRAINER_PIN = "WowHandbookTrainerPinTemplate"
local CLASS_TRAINER_PIN = "WowHandbookClassTrainerPinTemplate"
local TRANSMOG_PIN = "WowHandbookTransmogPinTemplate"
local TRANSPORT_PIN = "WowHandbookTransportPinTemplate"
local PATH_PIN = "WowHandbookPathPinTemplate"
local TRANSMOG_ICON = "Interface\\Icons\\INV_Shirt_White_01" -- 小地图共用
local ICONS = {
    dungeon = { level = "PIN_FRAME_LEVEL_DUNGEON_ENTRANCE", atlas = "Dungeon",
        texture = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", size = 22 },
    raid = { level = "PIN_FRAME_LEVEL_DUNGEON_ENTRANCE", atlas = "Raid",
        texture = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", size = 24 },
    -- 灵魂医者：死亡后“返回墓地”按钮用的守护之魂图标，做成圆形徽章
    graveyard = { level = "PIN_FRAME_LEVEL_SELECTABLE_GRAVEYARD", texture = "Interface\\Icons\\spell_holy_guardianspirit",
        size = 24, round = true },
    -- 专业训练师：专业图标做成圆形徽章，贴图在放置时换成对应专业
    trainer = { level = "PIN_FRAME_LEVEL_AREA_POI", texture = "Interface\\Icons\\inv_misc_questionmark",
        size = 20, round = true },
    -- 幻化师：衬衫图标做成圆形徽章
    transmog = { level = "PIN_FRAME_LEVEL_AREA_POI", texture = TRANSMOG_ICON, size = 20, round = true },
    -- 飞艇与船：飞艇塔用飞艇、码头用船，颜色按阵营（Media/Transport*，tools/make_transport_icons.py 生成）；
    -- 实际贴图在放置时由 Transport.IconTexture 换成，提示里写去向
    transport = { level = "PIN_FRAME_LEVEL_AREA_POI", texture = "Interface\\AddOns\\WowHandbook\\Media\\TransportShipGold",
        size = 22 },
    -- 区域路口：金色小箭头（Media/PathArrow），按路口方向旋转，悬停写通往哪里
    path = { level = "PIN_FRAME_LEVEL_AREA_POI", texture = "Interface\\AddOns\\WowHandbook\\Media\\PathArrow", size = 18 },
    -- 采集点：小图标，贴图在放置时换成采到的物品图标；比任务等图标低一层，不挡住它们
    gather = { level = "PIN_FRAME_LEVEL_AREA_POI", texture = "Interface\\Icons\\inv_misc_questionmark", size = 7 },
}

local function HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

-- 圆形徽章：与小地图按钮同样的拼法——暗色圆底、裁掉边角的方形图标、暴雪金属圆环，悬停时小地图按钮的高亮。
-- 不用遮罩：这个客户端里用遮罩裁圆的图钉整个不显示（图钉在、悬停有提示，但看不到图标）。
-- 尺寸按小地图按钮（31 宽、圆底 24、圆环 53 左上对齐）等比缩放到图钉大小。
local BADGE_BASE = 31
local function MakeBadge(pin, size)
    local k = size / BADGE_BASE
    local background = pin:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24 * k, 24 * k)
    background:SetPoint("CENTER", pin, "CENTER")
    pin.whTexture:ClearAllPoints()
    pin.whTexture:SetSize(17 * k, 17 * k)
    pin.whTexture:SetPoint("CENTER", pin, "CENTER")
    pin.whTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = pin:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53 * k, 53 * k)
    border:SetPoint("TOPLEFT", pin, "TOPLEFT")
    pin.whHighlight:ClearAllPoints()
    pin.whHighlight:SetAllPoints(pin)
    pin.whHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    pin.whRing, pin.whBackground = border, background
end

local function SetupPin(pin, iconKey)
    local icon = ICONS[iconKey]
    if not rawget(pin, "whTexture") then
        pin.whTexture = pin:CreateTexture(nil, "OVERLAY")
        pin.whTexture:SetAllPoints()
        pin.whHighlight = pin:CreateTexture(nil, "HIGHLIGHT")
        pin.whHighlight:SetAllPoints()
        pin.whHighlight:SetBlendMode("ADD")
        if icon.round then
            MakeBadge(pin, icon.size) -- 每种图钉有自己的对象池，徽章只需在创建时做一次
        end
        if pin.SetScalingLimits then
            pin:SetScalingLimits(1, 1.0, 1.2)
        end
    end
    -- 图钉层级：不指定时落在最底的默认层级，会被“已探索区域”的地图贴图盖住——探索过的地方看不到图标，
    -- 但鼠标移上去仍有提示。与暴雪同类图标同层（层级名在这个客户端不存在时暴雪会回退到默认层级）。
    if pin.UseFrameLevelType then
        pin:UseFrameLevelType(icon.level)
    end
    pin:SetSize(icon.size, icon.size)
    -- 徽章的高亮是固定的小地图按钮高亮，只换中间的图标
    for _, texture in ipairs(icon.round and { pin.whTexture } or { pin.whTexture, pin.whHighlight }) do
        if icon.atlas and HasAtlas(icon.atlas) then
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
    -- 地图框架在创建图钉时就把当时的 OnMouseEnter / OnMouseLeave 绑成脚本，换了函数要重新绑定
    pin:SetScript("OnEnter", pin.OnMouseEnter)
    pin:SetScript("OnLeave", pin.OnMouseLeave)
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

local function AddDungeonPin(map, index, px, py)
    local dungeon = ns.Data.dungeons[index]
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
        -- 先画客户端给出的这张地图上的入口；客户端没给的副本再用插件数据的坐标（大陆图经世界坐标换算）
        local drawn = {}
        for _, spot in ipairs(ns.ClientDungeonEntrances(mapID)) do
            if not drawn[spot.index] and DungeonVisible(ns.Data.dungeons[spot.index]) then
                drawn[spot.index] = true
                AddDungeonPin(map, spot.index, spot.x, spot.y)
            end
        end
        for index, dungeon in ipairs(ns.Data.dungeons or {}) do
            local entrance = dungeon.entrance
            if not drawn[index] and entrance and entrance.x and DungeonVisible(dungeon) then
                local px, py = ToMapPosition(entrance.map, entrance.x, entrance.y, mapID)
                if px then
                    AddDungeonPin(map, index, px, py)
                end
            end
        end
    end
    return dungeonProvider
end

--------------------------------------------------------------------------------
-- 灵魂医者：显示时机可设为死亡时（默认）、始终或不显示。游戏给的墓地列表（C_DeathInfo.GetGraveyardsForMap）
-- 与插件自带的位置（Data/Graveyards.lua）合并，同一处只画一个。
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
Module.SpiritHealersWanted = SpiritHealersWanted -- 小地图共用

-- 玩家阵营在墓地数据里的写法："A" / "H"；数据里第三项是这两者之一时，只有该阵营会被送到那里
local function GraveyardFaction()
    return UnitFactionGroup("player") == "Alliance" and "A" or "H"
end

-- { {x, y, name} }，坐标 0–100。游戏给出的墓地在前；插件数据里游戏没给的点（相距 SAME_SPOT 格以内算同一个）补在后面，
-- 对方阵营专用的跳过。原来游戏一给列表就整份丢掉插件数据，游戏列表不全时（如湿地中部）那里就没有图钉。
local SAME_SPOT = 3
local function GraveyardsForMap(mapID)
    local spots = {}
    local fromGame = C_DeathInfo and C_DeathInfo.GetGraveyardsForMap and C_DeathInfo.GetGraveyardsForMap(mapID)
    for _, graveyard in ipairs(fromGame or {}) do
        if graveyard.position then
            local x, y = graveyard.position:GetXY()
            tinsert(spots, { x * 100, y * 100, graveyard.name })
        end
    end
    local faction = GraveyardFaction()
    for _, point in ipairs(ns.Data.graveyards and ns.Data.graveyards[mapID] or {}) do
        local known = point[3] ~= nil and point[3] ~= faction
        for _, spot in ipairs(spots) do
            if math.abs(spot[1] - point[1]) <= SAME_SPOT and math.abs(spot[2] - point[2]) <= SAME_SPOT then
                known = true
                break
            end
        end
        if not known then
            tinsert(spots, { point[1], point[2] })
        end
    end
    return spots
end
Module.GraveyardsForMap = GraveyardsForMap -- 供测试使用

-- 复活区域：服务器把死者送到“这片区域关联的、本阵营能用的墓地里最近的一个”。分界线由导出脚本按码算好
-- （每张地图联盟、部落各一份，两边相同时只有 both；每条 {x1, y1, x2, y2}，坐标 0–100），这里按玩家阵营
-- 画成细线，随灵魂医者图钉一起显示。线放在画布上的一个框架里，随地图缩放移动；粗细按画布缩放反向调整，
-- 放大地图时线不变粗。颜色是暴雪地图上的金色（固定含义色，不随插件配色变化）。
local AREA_LINE_WIDTH = 1.5
local AREA_LINE_COLOR = { 1, 0.82, 0, 0.8 }
local areaLines = { lines = {}, used = 0 }

local function AreaBordersForMap(mapID)
    local entry = ns.Data.graveyardAreas and ns.Data.graveyardAreas[mapID]
    return entry and (entry.both or entry[GraveyardFaction()]) or nil
end
Module.AreaBordersForMap = AreaBordersForMap -- 供测试使用

local function AreaLineThickness(map)
    local scale = map.GetCanvasScale and map:GetCanvasScale() or 1
    return AREA_LINE_WIDTH / ((scale and scale > 0) and scale or 1)
end

local function HideGraveyardAreas()
    for index = 1, areaLines.used do
        areaLines.lines[index]:Hide()
    end
    areaLines.used = 0
    if areaLines.frame then
        areaLines.frame:Hide()
    end
end

local function DrawGraveyardAreas(map, mapID)
    HideGraveyardAreas()
    local borders = Settings().graveyardAreas ~= false and AreaBordersForMap(mapID)
    if not borders then
        return
    end
    local canvas = map:GetCanvas()
    if not areaLines.frame then
        areaLines.frame = CreateFrame("Frame", nil, canvas)
    end
    local frame = areaLines.frame
    frame:SetParent(canvas)
    -- 高于完整地图补画的贴图（画布 + 1），低于各类图钉
    frame:SetFrameLevel(canvas:GetFrameLevel() + 2)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", canvas, "TOPLEFT")
    local width, height = map:DenormalizeHorizontalSize(1), map:DenormalizeVerticalSize(1)
    frame:SetSize(width, height)
    local thickness = AreaLineThickness(map)
    for _, border in ipairs(borders) do
        areaLines.used = areaLines.used + 1
        local line = areaLines.lines[areaLines.used]
        if not line then
            line = frame:CreateLine(nil, "OVERLAY")
            line:SetColorTexture(unpack(AREA_LINE_COLOR))
            areaLines.lines[areaLines.used] = line
        end
        line:SetThickness(thickness)
        line:SetStartPoint("TOPLEFT", frame, border[1] / 100 * width, -border[2] / 100 * height)
        line:SetEndPoint("TOPLEFT", frame, border[3] / 100 * width, -border[4] / 100 * height)
        line:Show()
    end
    frame:Show()
end

local graveyardProvider

local function CreateGraveyardProvider()
    graveyardProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function graveyardProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(GRAVEYARD_PIN)
        HideGraveyardAreas()
    end
    function graveyardProvider:OnCanvasScaleChanged()
        local thickness = AreaLineThickness(self:GetMap())
        for index = 1, areaLines.used do
            areaLines.lines[index]:SetThickness(thickness)
        end
    end
    function graveyardProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not (mapID and SpiritHealersWanted()) then
            return
        end
        DrawGraveyardAreas(map, mapID)
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

--------------------------------------------------------------------------------
-- 草药与矿点：herbPins / orePins 为 auto（学了对应专业才显示，默认）、always 或 off。
-- 一处可能刷出几种（如锡、银、铁轮流），图标取你能采的里面所需技能最高的一种；一种都采不了时变灰变淡。
--------------------------------------------------------------------------------

-- 地图的实际宽、高（码），按地图缓存；取不到返回 nil（小地图换算与采集点误差共用）
local mapSizes = {}
function Module.MapSize(mapID)
    if mapSizes[mapID] then
        return mapSizes[mapID][1], mapSizes[mapID][2]
    end
    if not (mapID and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
        return nil
    end
    local _, topLeft = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
    local _, bottomRight = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(1, 1))
    if not (topLeft and bottomRight) then
        return nil
    end
    -- 世界坐标 x 向北、y 向西；地图 x 向东、y 向南。只取跨度
    local width, height = math.abs(topLeft.y - bottomRight.y), math.abs(topLeft.x - bottomRight.x)
    if width == 0 or height == 0 then
        return nil
    end
    mapSizes[mapID] = { width, height }
    return width, height
end

-- 采集点的误差：两个坐标（0–100）相距 SAME_SPOT_YARDS 码以内算同一个点。采集时人站在草药 / 矿旁边几码内，
-- 这个范围盖住站位偏差，又不会把相邻的两个刷新点合成一个。取不到地图尺寸时按很小的百分比判断（宁可多记一个点）
local SAME_SPOT_YARDS = 5
local SAME_SPOT_FALLBACK = 0.15
function Module.SameSpot(mapID, x1, y1, x2, y2)
    local width, height = Module.MapSize(mapID)
    if not width then
        return math.abs(x1 - x2) <= SAME_SPOT_FALLBACK and math.abs(y1 - y2) <= SAME_SPOT_FALLBACK
    end
    local dx, dy = (x1 - x2) * width / 100, (y1 - y2) * height / 100
    return dx * dx + dy * dy <= SAME_SPOT_YARDS * SAME_SPOT_YARDS
end

local GATHER_PROFESSION = { herb = "herbalism", ore = "mining" }
local GATHER_SETTING = { herb = "herbPins", ore = "orePins" }
local GATHER_TITLE = { herb = "Herb", ore = "Mining node" }
-- 采集点统一半透明，不抢地图上其他信息；技能不够的图标染红（小地图共用）
local GATHER_ALPHA = 0.5
Module.GATHER_ALPHA = GATHER_ALPHA
function Module.StyleGatherIcon(texture, ok)
    local red = ns.Theme.colors.red
    if ok then
        texture:SetVertexColor(1, 1, 1)
    else
        texture:SetVertexColor(1, red[2] + 0.1, red[3] + 0.1)
    end
end

-- 该类采集点显示与否，以及玩家该专业的技能（没学为 0）
local function GatherWanted(kind, skills)
    local mode = Settings()[GATHER_SETTING[kind]] or "auto"
    local skill = skills[GATHER_PROFESSION[kind]]
    if mode == "off" or (mode == "auto" and not skill) then
        return false, 0
    end
    return true, skill and skill.rank or 0
end
Module.GatherWanted = GatherWanted -- 供测试使用

local function ItemName(itemID)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if not name then
        ns.RequestItem(itemID)
    end
    return name or ("#" .. itemID)
end

Module.ItemName = ItemName -- 小地图共用

-- 一处采集点：返回图标物品、能不能采、提示行；mine 为自己在这里采过的次数。
-- 同一处可能轮流刷出几种（游戏的共享刷新点，如铜 / 锡 / 银）。数据只列可能刷出什么、没有频率，图标按区域等级挑主矿：
-- 去掉偶尔替换刷出的稀有变种（rare：银、金、真银、黑铁），按这张地图的最低等级 × 5 估一个“该区域适用的技能”，
-- 取所需技能不超过它的最高一种；都超过就取最低的。于是低级区是铜、荆棘谷是铁、燃烧平原是瑟银。
-- 提示按所需技能从低到高列出全部可能，稀有的标出来；图标染不染红按图标上那一种的所需技能判断。
local function DescribeSpot(kind, spot, skill, mine, mapID)
    local nodes = ns.Data.gathering.nodes
    local list = {}
    for index = 3, #spot do
        if nodes[spot[index]] then
            tinsert(list, nodes[spot[index]])
        end
    end
    table.sort(list, function(a, b)
        return a.skill < b.skill
    end)
    local zone = mapID and ns.Data.zones[mapID]
    local target = zone and zone.levels and zone.levels[1] * 5 or 0
    local icon, lowest
    for _, node in ipairs(list) do
        if not node.rare then
            lowest = lowest or node
            if node.skill <= target then
                icon = node
            end
        end
    end
    icon = icon or lowest or list[1]
    -- 能不能采按图标上的那一种判断：图标是锡矿就看锡矿要的技能，不因为这里也可能刷铜矿就当作能采
    local ok, lines = icon ~= nil and skill >= icon.skill, { L[GATHER_TITLE[kind]] }
    for _, node in ipairs(list) do
        local can = skill >= node.skill
        local text = ("%s  (%s)"):format(ItemName(node.item), (L["skill %d"]):format(node.skill))
        if node.rare then
            text = text .. "  " .. L["rare"]
        end
        tinsert(lines, ns.Theme:Color(text, can and "green" or "red"))
    end
    if mine and mine > 0 then
        tinsert(lines, ns.Theme:Color((L["You gathered here %d times"]):format(mine), "gold"))
    end
    tinsert(lines, L["Click to set a waypoint here."])
    return icon, ok, lines
end
Module.DescribeSpot = DescribeSpot -- 供测试使用

local gatherProvider

local function CreateGatherProvider()
    gatherProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function gatherProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(GATHER_PIN)
    end
    function gatherProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not (mapID and ns.Data.gathering) then
            return
        end
        local skills = ns.ProfessionSkills()
        for _, kind in ipairs({ "herb", "ore" }) do
            local wanted, skill = GatherWanted(kind, skills)
            local spots, mine = {}, {}
            if wanted then
                spots, mine = Module.GatherSpots(mapID, kind)
            end
            for _, spot in ipairs(spots) do
                local node, ok, lines = DescribeSpot(kind, spot, skill, mine[spot], mapID)
                local pin = map:AcquirePin(GATHER_PIN)
                SetupPin(pin, "gather")
                pin.whTexture:SetTexture(node and C_Item.GetItemIconByID(node.item) or ICONS.gather.texture)
                Module.StyleGatherIcon(pin.whTexture, ok)
                pin.whOk = ok -- 供测试使用
                pin:SetAlpha(GATHER_ALPHA)
                SetPinBehavior(pin, lines, function()
                    ns.Waypoints:Set(mapID, spot[1], spot[2], node and ItemName(node.item) or lines[1])
                end)
                pin:SetPosition(spot[1] / 100, spot[2] / 100)
            end
        end
    end
    return gatherProvider
end

--------------------------------------------------------------------------------
-- 专业训练师：trainerPins 为 mine（学了的专业，默认）、all（全部专业）或 off
--------------------------------------------------------------------------------


-- 这张地图上要画的训练师：{ {trainer, profession, next} }
local function TrainersForMap(mapID)
    local mode = Settings().trainerPins or "mine"
    local list = {}
    if mode == "off" then
        return list
    end
    local skills = ns.ProfessionSkills()
    local faction = ns.PlayerFaction()
    for _, profession in ipairs(ns.Data.professions or {}) do
        local skill = skills[profession.slug]
        if mode == "all" or skill then
            -- 该找的一档与专业页一致（Core/Util.lua 的 ns.TargetTrainerRank），按本阵营能用的训练师算
            local usable = {}
            for _, trainer in ipairs(profession.trainers or {}) do
                if not trainer.faction or trainer.faction == "AH" or not faction or trainer.faction == faction then
                    tinsert(usable, trainer)
                end
            end
            local nextRank = ns.TargetTrainerRank(usable, skill)
            for _, trainer in ipairs(profession.trainers or {}) do
                if trainer.map == mapID and trainer.x
                    and (not trainer.faction or trainer.faction == "AH" or not faction or trainer.faction == faction) then
                    tinsert(list, { trainer = trainer, profession = profession,
                        next = trainer.rank ~= nil and trainer.rank == nextRank })
                end
            end
        end
    end
    return list
end
Module.TrainersForMap = TrainersForMap -- 供测试使用

local trainerProvider

local function CreateTrainerProvider()
    trainerProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function trainerProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(TRAINER_PIN)
    end
    function trainerProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not mapID then
            return
        end
        for _, item in ipairs(TrainersForMap(mapID)) do
            local trainer, profession = item.trainer, item.profession
            local pin = map:AcquirePin(TRAINER_PIN)
            SetupPin(pin, "trainer")
            pin.whTexture:SetTexture("Interface\\Icons\\" .. (profession.icon or "inv_misc_questionmark"))
            pin:SetAlpha(item.next and 1 or 0.6)
            local name = ns.Name(trainer.name) or "?"
            local lines = { name, ns.Name(profession.name) or profession.slug }
            if trainer.rank then
                lines[2] = lines[2] .. " · " .. ns.TrainerRankName(trainer.rank)
            end
            if item.next then
                tinsert(lines, ns.Theme:Color(L["The trainer you need next"], "gold"))
            end
            tinsert(lines, L["Click to set a waypoint here."])
            SetPinBehavior(pin, lines, function()
                ns.Waypoints:Set(mapID, trainer.x, trainer.y, name)
            end)
            pin:SetPosition(trainer.x / 100, trainer.y / 100)
        end
    end
    return trainerProvider
end

--------------------------------------------------------------------------------
-- 职业训练师：classTrainerPins 开关（默认开）；只画自己职业的
--------------------------------------------------------------------------------

local CLASS_ICON = { pet = "Ability_Hunter_BeastTraining", portal = "Spell_Arcane_PortalIronForge" }
local CLASS_KIND_LABEL = { pet = "Pet trainer", portal = "Portal trainer" }

-- 现在可以去训练师那里学的职业技能数（技能书模块的判断：已到等级、还没学）
local function ReadySpells()
    local spellbook = ns.modules.Spellbook
    if not (spellbook and spellbook.Rows) then
        return 0
    end
    local ready = 0
    for _, row in ipairs(spellbook.Rows(false)) do
        if row.status == "ready" then
            ready = ready + 1
        end
    end
    return ready
end
Module.ReadySpells = ReadySpells -- 小地图共用

-- 职业训练师的图标：宠物 / 传送门训练师用各自的技能图标，其余用职业图标（小地图共用）
function Module.ClassTrainerIcon(trainer)
    local _, classFile = UnitClass("player")
    classFile = classFile or ""
    return "Interface\\Icons\\" .. (CLASS_ICON[trainer.kind] or ("ClassIcon_" .. classFile:sub(1, 1) .. classFile:sub(2):lower()))
end
Module.CLASS_KIND_LABEL = CLASS_KIND_LABEL

-- 这张地图上要画的本职业训练师：{ trainer, … }
local function ClassTrainersForMap(mapID)
    if Settings().classTrainerPins == false then
        return {}
    end
    local faction = ns.PlayerFaction()
    local list = {}
    for _, trainer in ipairs(ns.Data.classTrainers and ns.Data.classTrainers[ns.PlayerClass() or ""] or {}) do
        if trainer.map == mapID and trainer.x
            and (not trainer.faction or trainer.faction == "AH" or not faction or trainer.faction == faction) then
            tinsert(list, trainer)
        end
    end
    return list
end
Module.ClassTrainersForMap = ClassTrainersForMap -- 供测试使用

local classTrainerProvider

local function CreateClassTrainerProvider()
    classTrainerProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function classTrainerProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(CLASS_TRAINER_PIN)
    end
    function classTrainerProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        local trainers = mapID and ClassTrainersForMap(mapID) or {}
        if #trainers == 0 then
            return
        end
        local ready = ReadySpells()
        local _, classFile = UnitClass("player")
        local className = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile or ""] or classFile or "?"
        for _, trainer in ipairs(trainers) do
            local pin = map:AcquirePin(CLASS_TRAINER_PIN)
            SetupPin(pin, "trainer")
            pin.whTexture:SetTexture(Module.ClassTrainerIcon(trainer))
            local name = ns.Name(trainer.name) or "?"
            local lines = { name }
            if trainer.kind then
                tinsert(lines, L[CLASS_KIND_LABEL[trainer.kind]])
                pin:SetAlpha(1)
            else
                tinsert(lines, (L["%s trainer"]):format(className))
                tinsert(lines, ready > 0 and ns.Theme:Color((L["%d spells to train now"]):format(ready), "gold")
                    or ns.Theme:Color(L["Nothing new to train yet"], "muted"))
                pin:SetAlpha(ready > 0 and 1 or 0.6)
            end
            tinsert(lines, L["Click to set a waypoint here."])
            SetPinBehavior(pin, lines, function()
                ns.Waypoints:Set(mapID, trainer.x, trainer.y, name)
            end)
            pin:SetPosition(trainer.x / 100, trainer.y / 100)
        end
    end
    return classTrainerProvider
end

--------------------------------------------------------------------------------
-- 幻化师：transmogPins 开关（默认开）；本阵营与中立的
--------------------------------------------------------------------------------

Module.TRANSMOG_ICON = TRANSMOG_ICON

local function TransmogrifiersForMap(mapID)
    if Settings().transmogPins == false then
        return {}
    end
    local faction = ns.PlayerFaction()
    local list = {}
    for _, npc in ipairs(ns.Data.transmogrifiers or {}) do
        if npc.map == mapID and npc.x and (not npc.faction or not faction or npc.faction == faction) then
            tinsert(list, npc)
        end
    end
    return list
end
Module.TransmogrifiersForMap = TransmogrifiersForMap -- 小地图共用

local transmogProvider

local function CreateTransmogProvider()
    transmogProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function transmogProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(TRANSMOG_PIN)
    end
    function transmogProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        for _, npc in ipairs(mapID and TransmogrifiersForMap(mapID) or {}) do
            local pin = map:AcquirePin(TRANSMOG_PIN)
            SetupPin(pin, "transmog")
            local name = ns.Name(npc.name) or "?"
            SetPinBehavior(pin, { name, L["Transmogrifier"], L["Click to set a waypoint here."] }, function()
                ns.Waypoints:Set(mapID, npc.x, npc.y, name)
            end)
            pin:SetPosition(npc.x / 100, npc.y / 100)
        end
    end
    return transmogProvider
end

--------------------------------------------------------------------------------
-- 飞艇与船：transportPins 开关（默认开）。双向航线只提示下一站，环线提示接下来的两站。
--------------------------------------------------------------------------------

local transportProvider

-- 图钉提示：每条航线一行“本站 → 下一站（船）”（环线“本站 → 下一站 → 再下一站（船）”），首行作标题；
-- 自带交通图标不分船与飞艇，所以括号里注明。小地图共用。
function Module.TransportPinLines(entry)
    local here = ns.Transport.HubName(entry.id)
    local lines = {}
    for _, line in ipairs(entry.lines) do
        local names = { here }
        for _, hubID in ipairs(line.to) do
            tinsert(names, ns.Transport.HubName(hubID))
        end
        tinsert(lines, (L[line.kind == "zeppelin" and "%s (zeppelin)" or "%s (boat)"]):format(table.concat(names, " → ")))
    end
    if entry.spot.approximate then
        tinsert(lines, L["Position is approximate."])
    end
    return lines
end

local function CreateTransportProvider()
    transportProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function transportProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(TRANSPORT_PIN)
    end
    function transportProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not (mapID and Settings().transportPins ~= false) then
            return
        end
        for _, entry in ipairs(ns.Transport.HubsForMap(mapID, ns.PlayerFaction())) do
            local pin = map:AcquirePin(TRANSPORT_PIN)
            SetupPin(pin, "transport")
            ns.Transport.ApplyIcon(pin.whTexture, entry)
            ns.Transport.ApplyIcon(pin.whHighlight, entry)
            SetPinBehavior(pin, Module.TransportPinLines(entry))
            pin:SetPosition(entry.spot.x / 100, entry.spot.y / 100)
        end
    end
    return transportProvider
end

--------------------------------------------------------------------------------
-- 区域路口：pathPins 开关（默认开）。区域之间、区域与首都之间的通道，箭头指向通往的方向，悬停写去向。
-- 数据 Data/ZonePaths.lua 按地图记录位置、方向（逆时针角度，箭头贴图朝右为 0）与通往的地图。
--------------------------------------------------------------------------------

local pathProvider

local PATH_TITLE = { path = "Path to %s", entrance = "Entrance to %s", exit = "Exit to %s" }

local function MapName(mapID)
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    return info and info.name or (L["Map %d"]):format(mapID)
end

function Module.PathLines(spot)
    local lines = { (L[PATH_TITLE[spot.kind] or PATH_TITLE.path]):format(MapName(spot.to)) }
    if spot.to2 then
        tinsert(lines, (L["Also leads to %s"]):format(MapName(spot.to2)))
    end
    return lines
end

local function CreatePathProvider()
    pathProvider = CreateFromMixins(MapCanvasDataProviderMixin)
    function pathProvider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(PATH_PIN)
    end
    function pathProvider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        local spots = mapID and Settings().pathPins ~= false and ns.Data.zonePaths and ns.Data.zonePaths[mapID]
        if not spots then
            return
        end
        for _, spot in ipairs(spots) do
            local pin = map:AcquirePin(PATH_PIN)
            SetupPin(pin, "path")
            local rotation = math.rad(spot.angle)
            pin.whTexture:SetRotation(rotation)
            pin.whHighlight:SetRotation(rotation)
            pin.whAngle = spot.angle -- 供测试使用
            SetPinBehavior(pin, Module.PathLines(spot))
            pin:SetPosition(spot.x / 100, spot.y / 100)
        end
    end
    return pathProvider
end

function Module:ApplyScale()
    if WorldMapFrame and not InCombatLockdown() then
        local scale = Settings().mapScale or 1
        if scale ~= 1 or WorldMapFrame:GetScale() ~= 1 then
            WorldMapFrame:SetScale(scale)
        end
    end
end

function Module:Refresh()
    for _, dataProvider in ipairs({ provider, revealProvider, dungeonProvider, graveyardProvider, gatherProvider,
        trainerProvider, classTrainerProvider, transmogProvider, transportProvider, pathProvider }) do
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
    WorldMapFrame:AddDataProvider(CreateGatherProvider())
    WorldMapFrame:AddDataProvider(CreateTrainerProvider())
    WorldMapFrame:AddDataProvider(CreateClassTrainerProvider())
    WorldMapFrame:AddDataProvider(CreateTransmogProvider())
    WorldMapFrame:AddDataProvider(CreateTransportProvider())
    WorldMapFrame:AddDataProvider(CreatePathProvider())
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
    if Module.StartMinimapGather then
        Module.StartMinimapGather()
    end
    Module.StartGatherLog()
    -- 学了或提升了专业：刷新采集点与训练师（只在地图打开时，合并 1 秒内的多次变化）
    local skillPending = false
    ns:RegisterEvent("SKILL_LINES_CHANGED", function()
        if skillPending or not (WorldMapFrame and WorldMapFrame:IsShown() and gatherProvider and gatherProvider:GetMap()) then
            return
        end
        skillPending = true
        C_Timer.After(1, function()
            skillPending = false
            if WorldMapFrame:IsShown() then
                gatherProvider:RefreshAllData()
                trainerProvider:RefreshAllData()
            end
        end)
    end)
    -- 升级、学了新技能：职业训练师的“可学技能数”跟着变（只在地图打开时）
    for _, event in ipairs({ "PLAYER_LEVEL_UP", "LEARNED_SPELL_IN_SKILL_LINE" }) do
        ns:RegisterEvent(event, function()
            if WorldMapFrame and WorldMapFrame:IsShown() and classTrainerProvider and classTrainerProvider:GetMap() then
                classTrainerProvider:RefreshAllData()
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
