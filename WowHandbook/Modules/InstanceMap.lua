local ADDON_NAME, ns = ...
local L = ns.L

-- 副本地图：无限版客户端没有副本的 UiMap，在副本里打开大地图只能退回世界地图。这里在暴雪大地图里
-- 补上副本地图（Data/InstanceMaps.lua，由 tools/export_instance_maps.py 生成）：
-- · 经典地下城与团队副本用客户端自带的副本地图贴图（按文件 ID 加载，不随插件分发）；
-- · 无限版新地下城用玩家自制地图（Media/InstanceMaps/，地图下方署名作者）。
-- 做法：地图数据提供者在“玩家在有地图的副本里、大地图正显示暴雪给的退回地图”时，把副本地图画在地图画布上，
-- 盖住底下的世界地图；地图原生的拖动与滚轮缩放照常可用。画布点击处理器吃掉这时的点击，免得点到世界地图上的
-- 大陆跳走；导航栏照常可用，换到别的地图时副本地图自动隐藏。多层副本在右上角选层，旁边的按钮在副本地图与
-- 世界地图之间切换。客户端给不出副本里的玩家坐标与各层范围，所以不画玩家位置，层也由玩家自己选。
local Module = ns:NewModule("InstanceMap", {})

local DROPDOWN_TEMPLATE = "WowStyle1DropdownTemplate"
local BUTTON_TEMPLATE = "UIPanelButtonTemplate"
local CLICK_PRIORITY = 1000 -- 先于暴雪的点击导航

local state = {
    floors = {},       -- 副本地图 ID → 这次会话最后看的层
    worldMap = false,  -- 玩家点了“世界地图”：本副本里暂时不盖副本地图
    instanceID = nil,  -- 正在显示的副本
}
local art          -- 画布上的副本地图框架
local controls     -- 右上角的选层下拉框与切换按钮
local provider

-- 玩家所在副本的地图数据；不在副本里或这个副本没有地图时返回空
local function CurrentInstance()
    if not GetInstanceInfo then
        return
    end
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    if not instanceID or instanceType == "none" then
        return
    end
    local entry = ns.Data.instanceMaps and ns.Data.instanceMaps[instanceID]
    if entry and entry.floors and entry.floors[1] then
        return instanceID, entry
    end
end
Module.CurrentInstance = CurrentInstance -- 供测试使用

-- 大地图正显示的是不是“玩家所在位置”的地图：客户端给得出玩家地图时说明这个副本有原生地图，不插手
local function ShowingPlayerFallback(map)
    if not (C_Map and C_Map.GetBestMapForUnit) or C_Map.GetBestMapForUnit("player") then
        return false
    end
    local mapID = map:GetMapID()
    local fallback = MapUtil and MapUtil.GetDisplayableMapForPlayer and MapUtil.GetDisplayableMapForPlayer()
        or (C_Map.GetFallbackWorldMapID and C_Map.GetFallbackWorldMapID())
    return mapID ~= nil and mapID == fallback
end

local function SelectedFloor(instanceID, entry)
    local floor = state.floors[instanceID] or 1
    if not entry.floors[floor] then
        floor = 1
    end
    return floor
end
Module.SelectedFloor = SelectedFloor

-- 层名：数据给了名字（如达拉然的“城区”“下水道”）用名字，否则“第 N 层”
function Module.FloorLabel(floor, index)
    if floor.label then
        return L[floor.label]
    end
    return L["Floor %d"]:format(index)
end

--------------------------------------------------------------------------------
-- 画布上的副本地图
--------------------------------------------------------------------------------

local function CreateArt(canvas)
    art = CreateFrame("Frame", nil, canvas)
    -- 只接管鼠标移动（地图不再显示世界地图的悬停高亮与区域名），点击仍交给地图，拖动与缩放照常
    if art.SetMouseMotionEnabled then
        art:SetMouseMotionEnabled(true)
        art:SetMouseClickEnabled(false)
    end
    art.background = art:CreateTexture(nil, "BACKGROUND")
    art.background:SetAllPoints()
    art.background:SetColorTexture(0, 0, 0, 1)
    art.content = CreateFrame("Frame", nil, art)
    art.tiles = {}
    art.credit = art:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    art.credit:SetPoint("BOTTOMRIGHT", art.content, "BOTTOMRIGHT", -12, 8)
    art.credit:SetTextColor(1, 0.82, 0)
    return art
end

-- 按格子把一层贴图铺进 content：每格文件是 tile × tile，最右一列、最下一行只取有图的部分
local function DrawFloor(floor)
    local content = art.content
    local scale = content:GetWidth() / floor.width
    local columns = floor.columns
    local rows = math.ceil(#floor.textures / columns)
    local used = 0
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local file = floor.textures[row * columns + column + 1]
            if file then
                used = used + 1
                local texture = art.tiles[used]
                if not texture then
                    texture = content:CreateTexture(nil, "ARTWORK")
                    art.tiles[used] = texture
                end
                local pixelWidth = math.min(floor.tile, floor.width - column * floor.tile)
                local pixelHeight = math.min(floor.tile, floor.height - row * floor.tile)
                texture:SetTexture(file)
                texture:SetTexCoord(0, pixelWidth / floor.tile, 0, pixelHeight / floor.tile)
                texture:SetSize(pixelWidth * scale, pixelHeight * scale)
                texture:ClearAllPoints()
                texture:SetPoint("TOPLEFT", column * floor.tile * scale, -row * floor.tile * scale)
                texture:Show()
            end
        end
    end
    for index = used + 1, #art.tiles do
        art.tiles[index]:Hide()
    end
end

-- 比画布中所有图钉都高一层，盖住世界地图上的图钉
local function TopPinLevel(map, canvas)
    local level = canvas:GetFrameLevel() + 1
    if map.EnumerateAllPins then
        for pin in map:EnumerateAllPins() do
            level = math.max(level, pin:GetFrameLevel() + 1)
        end
    end
    return level
end

local function HideArt()
    if art then
        art:Hide()
    end
    state.instanceID = nil
end

local function ShowArt(map, instanceID, entry)
    local canvas = map:GetCanvas()
    if not art then
        CreateArt(canvas)
    end
    art:SetParent(canvas)
    art:SetFrameLevel(TopPinLevel(map, canvas))
    local width, height = map:DenormalizeHorizontalSize(1), map:DenormalizeVerticalSize(1)
    art:ClearAllPoints()
    art:SetPoint("TOPLEFT", canvas, "TOPLEFT")
    art:SetSize(width, height)
    -- 等比放进画布中间，多出来的边留黑
    local floor = entry.floors[SelectedFloor(instanceID, entry)]
    local scale = math.min(width / floor.width, height / floor.height)
    art.content:ClearAllPoints()
    art.content:SetPoint("CENTER")
    art.content:SetSize(floor.width * scale, floor.height * scale)
    DrawFloor(floor)
    if entry.artist then
        art.credit:SetText(L["Map by %s"]:format(entry.artist))
        art.credit:Show()
    else
        art.credit:Hide()
    end
    art:Show()
    state.instanceID = instanceID
end

--------------------------------------------------------------------------------
-- 右上角：选层与切换按钮（暴雪原生控件）
--------------------------------------------------------------------------------

local function Refresh()
    if provider and provider:GetMap() then
        provider:RefreshAllData()
    end
end

local function CreateControls(map)
    local container = map:GetCanvasContainer()
    controls = CreateFrame("Frame", nil, map)
    controls:SetSize(1, 1)
    controls:SetPoint("TOPRIGHT", container, "TOPRIGHT", -6, -6)

    local toggle = CreateFrame("Button", nil, controls, BUTTON_TEMPLATE)
    toggle:SetSize(110, 22)
    toggle:SetPoint("TOPRIGHT")
    toggle:SetScript("OnClick", function()
        state.worldMap = not state.worldMap
        Refresh()
    end)
    controls.toggle = toggle

    local dropdown = CreateFrame("DropdownButton", nil, controls, DROPDOWN_TEMPLATE)
    dropdown:SetWidth(150)
    dropdown:SetPoint("RIGHT", toggle, "LEFT", -6, 0)
    dropdown:SetupMenu(function(_, root)
        local instanceID, entry = CurrentInstance()
        if not entry then
            return
        end
        local function IsSelected(index)
            return SelectedFloor(instanceID, entry) == index
        end
        local function SetSelected(index)
            state.floors[instanceID] = index
            Refresh()
        end
        for index, floor in ipairs(entry.floors) do
            root:CreateRadio(Module.FloorLabel(floor, index), IsSelected, SetSelected, index)
        end
    end)
    controls.dropdown = dropdown
    return controls
end

local function UpdateControls(map, entry, showingArt)
    if not entry then
        if controls then
            controls:Hide()
        end
        return
    end
    if not controls then
        CreateControls(map)
    end
    -- 放在副本地图之上
    controls:SetFrameLevel((art and art:IsShown() and art:GetFrameLevel() or map:GetCanvas():GetFrameLevel()) + 10)
    controls.toggle:SetText(showingArt and L["Show world map"] or L["Show dungeon map"])
    local multiFloor = showingArt and #entry.floors > 1
    controls.dropdown:SetShown(multiFloor)
    if multiFloor then
        controls.dropdown:GenerateMenu()
    end
    controls:Show()
end

--------------------------------------------------------------------------------
-- 数据提供者
--------------------------------------------------------------------------------

local function CreateProvider()
    provider = CreateFromMixins(MapCanvasDataProviderMixin)

    -- 副本地图显示时吃掉画布点击：不跳到点中的大陆，右键也不退回上一级（导航栏照常可用）
    local function OnCanvasClick()
        return art ~= nil and art:IsShown()
    end

    function provider:OnAdded(map)
        MapCanvasDataProviderMixin.OnAdded(self, map)
        if map.AddCanvasClickHandler then
            map:AddCanvasClickHandler(OnCanvasClick, CLICK_PRIORITY)
        end
    end

    function provider:OnRemoved(map)
        if map.RemoveCanvasClickHandler then
            map:RemoveCanvasClickHandler(OnCanvasClick, CLICK_PRIORITY)
        end
        MapCanvasDataProviderMixin.OnRemoved(self, map)
    end

    function provider:RemoveAllData()
        HideArt()
    end

    function provider:RefreshAllData()
        local map = self:GetMap()
        local instanceID, entry = CurrentInstance()
        if instanceID ~= state.lastInstance then
            -- 进了另一个副本：回到副本地图
            state.lastInstance = instanceID
            state.worldMap = false
        end
        local host = entry and ShowingPlayerFallback(map)
        if host and not state.worldMap then
            ShowArt(map, instanceID, entry)
        else
            HideArt()
        end
        UpdateControls(map, host and entry, art ~= nil and art:IsShown())
    end

    function provider:OnMapChanged()
        self:RefreshAllData()
    end

    function provider:OnCanvasSizeChanged()
        self:RefreshAllData()
    end

    return provider
end

local attached = false
local function Attach()
    if attached or not (WorldMapFrame and MapCanvasDataProviderMixin) then
        return
    end
    attached = true
    WorldMapFrame:AddDataProvider(CreateProvider())
end

function Module:Refresh()
    Refresh()
end

function Module:OnEnable()
    Attach()
    ns:RegisterEvent("ADDON_LOADED", function(_, name)
        if name == "Blizzard_WorldMap" then
            Attach()
        end
    end)
    -- 地图开着时进出副本
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA" }) do
        ns:RegisterEvent(event, function()
            if WorldMapFrame and WorldMapFrame:IsShown() then
                Refresh()
            end
        end)
    end
end
