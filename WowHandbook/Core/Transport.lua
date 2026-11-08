local ADDON_NAME, ns = ...

-- 公共交通（飞艇、船）：枢纽与航线来自 Data/Transport.lua，在大地图与小地图上提示；一个泊位一个图钉。
-- 航线 stops 是按顺序的停靠点：两站是双向往返，三站以上且 loop 为真是单向环线。
local Transport = {}
ns.Transport = Transport

-- 近似位置的偏移（地图百分比）：码头没有记录坐标时用就近飞行点的位置，错开一点以免盖住飞行点图钉
local APPROX_OFFSET = 1.2
-- 环线只提示接下来的两站
local LOOP_LOOKAHEAD = 2

local function Data()
    return ns.Data.transport or { hubs = {}, routes = {} }
end

-- 地名：优先向客户端取（按游戏区域表的区域编号，与客户端语言一致），取不到才用数据里自带的中英文名
function Transport.HubName(id)
    local hub = Data().hubs[id]
    if not hub then
        return tostring(id)
    end
    local getAreaInfo = hub.area and C_Map and C_Map.GetAreaInfo
    local name = getAreaInfo and getAreaInfo(hub.area)
    if type(name) == "string" and name ~= "" then
        return name
    end
    return ns.Name(hub.name)
end

local function Usable(route, faction)
    return not route.faction or not faction or route.faction == faction
end

-- 这个枢纽的提示：每条经过这里的航线给出 { kind, to = { 下一站, ... } }。
-- 双向航线只给另一端（下一站）；环线给环上接下来的两站，沿固定方向走。
function Transport.Lines(hubID, faction)
    local lines = {}
    for _, route in ipairs(Data().routes) do
        if Usable(route, faction) then
            for index, stop in ipairs(route.stops) do
                if stop == hubID then
                    local to = {}
                    if route.loop then
                        for step = 1, math.min(LOOP_LOOKAHEAD, #route.stops - 1) do
                            tinsert(to, route.stops[(index - 1 + step) % #route.stops + 1])
                        end
                    else
                        -- 两站往返：另一端；多站线路取相邻的两侧
                        if route.stops[index - 1] then
                            tinsert(to, route.stops[index - 1])
                        end
                        if route.stops[index + 1] then
                            tinsert(to, route.stops[index + 1])
                        end
                    end
                    tinsert(lines, { kind = route.kind, to = to, loop = route.loop and true or nil, faction = route.faction })
                end
            end
        end
    end
    return lines
end

-- 枢纽在地图上的位置：{ x, y, approximate }。有记录坐标直接用；否则取就近飞行点的位置；都没有返回 nil
local function HubSpot(hub)
    if hub.x and hub.y then
        return { x = hub.x, y = hub.y }
    end
    if hub.taxiNodes and C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap then
        for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(hub.map) or {}) do
            for _, wanted in ipairs(hub.taxiNodes) do
                if node.nodeID == wanted and node.position then
                    local x, y = node.position:GetXY()
                    return { x = x * 100 + APPROX_OFFSET, y = y * 100 - APPROX_OFFSET, approximate = true }
                end
            end
        end
    end
    return nil
end

-- 一条航线在这个枢纽的泊位位置：枢纽的 berths 按下一站记录各泊位的坐标；没有记录就用枢纽自己的位置
local function BerthSpot(hub, line)
    local berth = hub.berths and line.to[1] and hub.berths[line.to[1]]
    if berth then
        return { x = berth.x, y = berth.y }
    end
    return HubSpot(hub)
end

-- 这个图钉上的航线都只有一个阵营能坐就返回该阵营（"A" / "H"），否则 nil（中立）
local function PinFaction(entry)
    local faction
    for index, line in ipairs(entry.lines) do
        if not line.faction or (index > 1 and line.faction ~= faction) then
            return nil
        end
        faction = line.faction
    end
    return faction
end

-- 图钉图标：优先用客户端自带的交通图标（正式服地图上码头、飞艇塔、传送门共用的 TaxiNode_Continent_*），
-- 联盟蓝、部落红、两个阵营都能坐的中立金；客户端没有这个图集时退回插件自绘的飞艇与船（Media/Transport*）。
local NATIVE_ATLAS = { A = "TaxiNode_Continent_Alliance", H = "TaxiNode_Continent_Horde" }
local NEUTRAL_ATLAS = "TaxiNode_Continent_Neutral"

function Transport.IconAtlas(entry)
    local atlas = NATIVE_ATLAS[PinFaction(entry) or ""] or NEUTRAL_ATLAS
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        return atlas
    end
    return nil
end

local ICON_PATH = "Interface\\AddOns\\WowHandbook\\Media\\Transport"
function Transport.IconTexture(entry)
    local faction = PinFaction(entry)
    return ICON_PATH .. (entry.kind == "zeppelin" and "Zeppelin" or "Ship")
        .. (faction == "A" and "Blue" or faction == "H" and "Red" or "Gold")
end

-- 把图钉图标画到一张贴图上：有自带图集用图集，否则用自绘贴图（整张，不裁边）
function Transport.ApplyIcon(texture, entry)
    local atlas = Transport.IconAtlas(entry)
    if atlas then
        texture:SetAtlas(atlas)
    else
        texture:SetTexture(Transport.IconTexture(entry))
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

-- 这张地图上要画的图钉：一个泊位（或飞艇塔）一个，本阵营有航线可坐且能确定位置才有。
-- 同一个位置上的几条航线合成一个图钉：{ id = 枢纽, kind, spot, lines }
function Transport.HubsForMap(mapID, faction)
    local list = {}
    for id, hub in pairs(Data().hubs) do
        if hub.map == mapID then
            local pins = {}
            for _, line in ipairs(Transport.Lines(id, faction)) do
                local spot = BerthSpot(hub, line)
                if spot then
                    local key = ("%.2f:%.2f"):format(spot.x, spot.y)
                    if not pins[key] then
                        pins[key] = { id = id, kind = hub.kind, spot = spot, lines = {} }
                        tinsert(list, pins[key])
                    end
                    tinsert(pins[key].lines, line)
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.id ~= b.id then
            return a.id < b.id
        end
        return a.spot.y < b.spot.y
    end)
    return list
end
