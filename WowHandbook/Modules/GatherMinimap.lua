local ADDON_NAME, ns = ...

-- 小地图上的草药与矿点（大地图模块 WorldMap 的一部分，显示哪些点与大地图同一套设置：herbPins / orePins；
-- minimapGather 关掉只关小地图）。只画玩家当前所在区域地图的点。
-- 同一套图钉也画专业训练师、职业训练师与灵魂医者：显示与否完全跟随大地图的 trainerPins / classTrainerPins /
-- spiritHealers（大地图显示，小地图就显示，没有单独的开关）；比采集点大一号的方形图标，不带边框与圆形徽章。
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
local L = ns.L

local UPDATE_INTERVAL = 0.2
local PIN_SIZE = 7
local RING_SIZE = 12
local POI_SIZE = 13 -- 训练师、灵魂医者：比采集点醒目，但不遮住小地图
local SPIRIT_ICON = "Interface\\Icons\\spell_holy_guardianspirit"
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
    -- 采集点的最后一行是大地图上的“点击设为导航”，小地图上不能点，不显示
    for index = 2, #pin.lines - (pin.poi and 0 or 1) do
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
            pin.poi = spot.poi
            if spot.poi then
                pin:SetSize(POI_SIZE, POI_SIZE)
                pin.icon:SetTexture(spot.icon)
                pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                pin.icon:SetVertexColor(1, 1, 1)
            elseif ring then
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
            pin.style = spot.poi or (ring and "circle" or "icon") -- 供测试使用
            pin:SetAlpha(spot.alpha or Module.GATHER_ALPHA)
            -- 训练师、灵魂医者画在采集点上面
            pin:SetFrameLevel(Minimap:GetFrameLevel() + (spot.poi and 2 or 1))
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

-- 当前地图上要画的专业训练师、职业训练师与灵魂医者（与大地图同一套判断）
local function AddPoiSpots(mapID)
    for _, item in ipairs(Module.TrainersForMap(mapID)) do
        local trainer, profession = item.trainer, item.profession
        local lines = { ns.Name(trainer.name) or "?", ns.Name(profession.name) or profession.slug }
        if trainer.rank then
            lines[2] = lines[2] .. " · " .. ns.TrainerRankName(trainer.rank)
        end
        if item.next then
            tinsert(lines, ns.Theme:Color(L["The trainer you need next"], "gold"))
        end
        tinsert(state.spots, { x = trainer.x / 100, y = trainer.y / 100, poi = "trainer", lines = lines,
            icon = "Interface\\Icons\\" .. (profession.icon or "inv_misc_questionmark"), alpha = item.next and 1 or 0.6 })
    end
    local classTrainers = Module.ClassTrainersForMap(mapID)
    if #classTrainers > 0 then
        local ready = Module.ReadySpells()
        for _, trainer in ipairs(classTrainers) do
            local lines = { ns.Name(trainer.name) or "?" }
            local alpha = 1
            if trainer.kind then
                tinsert(lines, L[Module.CLASS_KIND_LABEL[trainer.kind]])
            else
                tinsert(lines, (L["%s trainer"]):format(ns.ClassName(ns.PlayerClass()) or "?"))
                tinsert(lines, ready > 0 and ns.Theme:Color((L["%d spells to train now"]):format(ready), "gold")
                    or ns.Theme:Color(L["Nothing new to train yet"], "muted"))
                alpha = ready > 0 and 1 or 0.6
            end
            tinsert(state.spots, { x = trainer.x / 100, y = trainer.y / 100, poi = "classTrainer", lines = lines,
                icon = Module.ClassTrainerIcon(trainer), alpha = alpha })
        end
    end
    if Module.SpiritHealersWanted() then
        for _, spot in ipairs(Module.GraveyardsForMap(mapID)) do
            local title = spot[3] and spot[3] ~= "" and spot[3] or L["Spirit Healer"]
            tinsert(state.spots, { x = spot[1] / 100, y = spot[2] / 100, poi = "graveyard", lines = { title },
                icon = SPIRIT_ICON, alpha = 1 })
        end
    end
end

-- 进入地图、技能或设置变化时：重新挑出当前地图要显示的点
local function Rebuild()
    wipe(state.spots)
    state.mapID = nil
    lastKey = nil
    local settings = Settings()
    local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local width, height
    if mapID then
        width, height = MapSize(mapID)
    end
    if not width then
        Stop()
        return
    end
    AddPoiSpots(mapID)
    local skills = ns.ProfessionSkills()
    for _, kind in ipairs(settings.minimapGather ~= false and ns.Data.gathering and { "herb", "ore" } or {}) do
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
    -- 换地图、专业变化（采集点与专业训练师）、死亡与复活（灵魂医者）、升级与学技能（职业训练师的可学数量）
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
        "SKILL_LINES_CHANGED", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_LEVEL_UP",
        "LEARNED_SPELL_IN_SKILL_LINE" }) do
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
