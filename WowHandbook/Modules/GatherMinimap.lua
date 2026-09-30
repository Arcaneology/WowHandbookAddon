local ADDON_NAME, ns = ...

-- 小地图上的草药与矿点（大地图模块 WorldMap 的一部分，显示哪些点与大地图同一套设置：herbPins / orePins；
-- minimapGather 关掉只关小地图）。只画玩家当前所在区域地图的点。
--
-- 位置换算：玩家与采集点在同一张区域地图上的坐标（0–1）相减，乘以这张地图的实际宽高（码，用
-- C_Map.GetWorldPosFromMapPos 取地图两角的世界坐标得出），再按小地图当前的可视半径（码）换成像素；
-- 小地图随视角旋转时按玩家朝向转过来。超出小地图圆形范围的点不画。
--
-- 更新：只有当前地图有要显示的点时，才每 0.2 秒检查一次；玩家位置、朝向、小地图缩放都没变就什么都不做。
-- 离开这张地图、关掉设置或没有要显示的点时停止。
--
-- 图层：小地图的地形与系统的采集追踪标记（寻找矿物 / 寻找草药的小点）由引擎一起绘制，插件框体只能在它们上面，
-- 所以图钉放在紧贴小地图的最低一层。样式 minimapGatherStyle：icon（物品图标，默认）或 circle（空心圆环，
-- 系统标记从中间露出来；草药绿、矿点金，技能不够的红）。
local Module = ns.modules.WorldMap

local UPDATE_INTERVAL = 0.2
local PIN_SIZE = 7
local RING_SIZE = 12
local RING_TEXTURE = "Interface\\AddOns\\WowHandbook\\Media\\GatherRing"
local RING_COLOR = { herb = "green", ore = "gold" }
-- 取不到 C_Minimap.GetViewRadius 时按缩放档位查小地图可视直径（码）：室外、室内各 6 档（0 为最远）
local VIEW_DIAMETER = {
    outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
    indoor = { [0] = 300, 240, 180, 120, 80, 50 },
}

local state = { spots = {}, pins = {} }
local ticker
Module.minimapGatherPins = state.pins -- 供测试使用

local function Settings()
    return ns:GetModuleSettings(Module)
end

-- 小地图可视半径（码）
local function ViewRadius()
    if C_Minimap and C_Minimap.GetViewRadius then
        local radius = C_Minimap.GetViewRadius()
        if radius and radius > 0 then
            return radius
        end
    end
    local zoom = Minimap:GetZoom() or 0
    local diameters = (IsIndoors and IsIndoors()) and VIEW_DIAMETER.indoor or VIEW_DIAMETER.outdoor
    return (diameters[zoom] or diameters[0]) / 2
end

-- 区域地图的实际宽、高（码），大地图模块提供（按地图缓存）
local function MapSize(mapID)
    return Module.MapSize(mapID)
end

local function Rotating()
    local getter = C_CVar and C_CVar.GetCVar or GetCVar
    return getter and getter("rotateMinimap") == "1"
end

local function ShowTooltip(pin)
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(pin.lines[1], 1, 0.82, 0)
    -- 最后一行是大地图上的“点击设为导航”，小地图上不能点，不显示
    for index = 2, #pin.lines - 1 do
        GameTooltip:AddLine(pin.lines[index], 1, 1, 1, true)
    end
    GameTooltip:Show()
end

local function AcquirePin(index)
    local pin = state.pins[index]
    if not pin then
        pin = CreateFrame("Frame", nil, Minimap)
        pin:SetFrameLevel(Minimap:GetFrameLevel() + 1)
        pin.icon = pin:CreateTexture(nil, "OVERLAY")
        pin.icon:SetAllPoints()
        -- 只响应鼠标指向（显示提示），点击穿透给小地图
        pin:EnableMouse(true)
        if pin.SetMouseClickEnabled then
            pin:SetMouseClickEnabled(false)
        end
        pin:SetScript("OnEnter", ShowTooltip)
        pin:SetScript("OnLeave", GameTooltip_Hide)
        state.pins[index] = pin
    end
    return pin
end

local function HidePins(from)
    for index = from or 1, #state.pins do
        state.pins[index]:Hide()
    end
end

local lastKey
local function Update(force)
    local mapID = state.mapID
    local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not (position and Minimap:IsVisible()) then
        lastKey = nil
        HidePins()
        return
    end
    local px, py = position:GetXY()
    local rotating = Rotating()
    local facing = rotating and GetPlayerFacing and GetPlayerFacing() or 0
    local radius = ViewRadius()
    local key = ("%.5f:%.5f:%.3f:%.1f"):format(px, py, facing, radius)
    if key == lastKey and not force then
        return
    end
    lastKey = key

    local scale = (Minimap:GetWidth() / 2) / radius
    local ring = Settings().minimapGatherStyle == "circle"
    local cos, sin = math.cos(facing), math.sin(facing)
    local used = 0
    for _, spot in ipairs(state.spots) do
        local east = (spot.x - px) * state.width
        local north = (py - spot.y) * state.height
        if rotating then
            east, north = east * cos + north * sin, north * cos - east * sin
        end
        if east * east + north * north <= radius * radius * 0.92 then
            used = used + 1
            local pin = AcquirePin(used)
            pin.lines = spot.lines
            if ring then
                pin:SetSize(RING_SIZE, RING_SIZE)
                pin.icon:SetTexture(RING_TEXTURE)
                pin.icon:SetTexCoord(0, 1, 0, 1)
                local color = ns.Theme.colors[spot.ok and RING_COLOR[spot.kind] or "red"]
                pin.icon:SetVertexColor(color[1], color[2], color[3])
            else
                pin:SetSize(PIN_SIZE, PIN_SIZE)
                pin.icon:SetTexture(spot.icon)
                pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                Module.StyleGatherIcon(pin.icon, spot.ok)
            end
            pin.style = ring and "circle" or "icon" -- 供测试使用
            pin:SetAlpha(Module.GATHER_ALPHA)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", Minimap, "CENTER", east * scale, north * scale)
            pin:Show()
        end
    end
    HidePins(used + 1)
end
Module.UpdateMinimapGather = Update -- 供测试使用

local function Stop()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    HidePins()
end

-- 进入地图、技能或设置变化时：重新挑出当前地图要显示的点
local function Rebuild()
    wipe(state.spots)
    state.mapID = nil
    lastKey = nil
    local mapID = Settings().minimapGather ~= false and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local width, height
    if mapID and ns.Data.gathering then
        width, height = MapSize(mapID)
    end
    if not width then
        Stop()
        return
    end
    local skills = ns.ProfessionSkills()
    for _, kind in ipairs({ "herb", "ore" }) do
        local wanted, skill = Module.GatherWanted(kind, skills)
        local spots, mine = {}, {}
        if wanted then
            spots, mine = Module.GatherSpots(mapID, kind)
        end
        for _, spot in ipairs(spots) do
            local node, ok, lines = Module.DescribeSpot(kind, spot, skill, mine[spot], mapID)
            tinsert(state.spots, { x = spot[1] / 100, y = spot[2] / 100, ok = ok, lines = lines, kind = kind,
                icon = node and C_Item.GetItemIconByID(node.item) or 134400 })
        end
    end
    if #state.spots == 0 then
        Stop()
        return
    end
    state.mapID, state.width, state.height = mapID, width, height
    Update(true)
    if not ticker then
        ticker = C_Timer.NewTicker(UPDATE_INTERVAL, function()
            Update()
        end)
    end
end
Module.RebuildMinimapGather = Rebuild -- 供测试使用

function Module.StartMinimapGather()
    if not Minimap then
        return
    end
    local pending = false
    local function Later()
        if pending then
            return
        end
        pending = true
        C_Timer.After(1, function()
            pending = false
            Rebuild()
        end)
    end
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
        "SKILL_LINES_CHANGED" }) do
        ns:RegisterEvent(event, Later)
    end
    -- 小地图缩放变了：下一次检查时重画
    ns:RegisterEvent("MINIMAP_UPDATE_ZOOM", function()
        lastKey = nil
    end)
    -- 设置页改了大地图选项会调用 Module:Refresh：小地图一起更新
    local refresh = Module.Refresh
    function Module:Refresh()
        refresh(self)
        Rebuild()
    end
    Later()
end
