local ADDON_NAME, ns = ...
local L = ns.L

-- 地图标记：装了 TomTom 用它的箭头，否则用游戏自带的地图标记并设为追踪目标。
-- 坐标用 0–100（与网站数据一致）。
local Waypoints = {}
ns.Waypoints = Waypoints

function Waypoints:Set(uiMapID, x, y, title)
    if not (uiMapID and x and y) then
        ns:Print(L["No map location recorded for this."])
        return false
    end
    local tomtom = _G.TomTom
    if tomtom and tomtom.AddWaypoint then
        tomtom:AddWaypoint(uiMapID, x / 100, y / 100, { title = title, from = "WoW Handbook" })
    elseif C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(uiMapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(uiMapID, x / 100, y / 100))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    else
        ns:Print(L["This map does not support waypoints."])
        return false
    end
    ns:Print(L["Waypoint set: %s (%s %.1f, %.1f)"], title or "?", ns.MapName(uiMapID) or "?", x, y)
    return true
end

-- 打开游戏大地图并定位到该地图，同时收起插件窗口以免挡住地图
function Waypoints:OpenMap(uiMapID)
    ns.MainFrame:Hide()
    if OpenWorldMap then
        OpenWorldMap(uiMapID)
    elseif C_Map.OpenWorldMap then
        C_Map.OpenWorldMap(uiMapID)
    end
end

-- 设好标记后打开游戏大地图并定位到该地图
function Waypoints:ShowOnMap(uiMapID, x, y, title)
    if not self:Set(uiMapID, x, y, title) then
        return false
    end
    self:OpenMap(uiMapID)
    return true
end
