local ADDON_NAME, ns = ...
local L = ns.L

-- 渔获小窗（专业工作台模块 Workbench 的一部分，设置 fishingPopup，默认开启）：主手换上鱼竿时浮出，换下时收起；
-- /wh fishing 随时打开或收起。显示玩家自己的渔获，三个分页：
--   本次：当期钓鱼（分期规则见 WorkbenchFishing.lua 的“历次钓鱼”）的地点、开始时间、时长、上钩次数，
--     每种渔获的件数与本次几率，旁边是所在水域的标准几率；底部可以手动“开始新一期”或“结束本期”。
--   本地区：所在水域的标准几率表（系统数据）与你在这片水域的累计几率并排，表里有而你还没钓到的灰色列出。
--   历次：最近的历次钓鱼，点一期看它的明细。
-- 关闭按钮只收起到下次拿起鱼竿；可拖动、右键锁定位置与调大小，位置与分页存在模块设置 fishingPopupWindow。

local R = ns.modules.Workbench
local Module = R
local Theme = ns.Theme
local Color, Settings = R.Color, R.Settings

local WIDTH, PAD, ROW_HEIGHT, MAX_ROWS = 300, 10, 18, 14
local FEW_CATCHES = 20 -- 上钩少于这么多次时，你的几率灰色只作参考
local MAINHAND = 16 -- 主手栏位
local WEAPON_CLASS = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local FISHING_POLE = (Enum and Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole) or 20
local VIEWS = { "trip", "zone", "history" }
local NEXT_TRIP = "Your next catch starts a new trip. A trip ends by itself when you change zones or rest your rod "
    .. "for 15 minutes; start one yourself to keep it going until you end it."

local frame, dismissed, holding, forced, selected
local Popup = {}
R.FishingPopup = Popup -- 供测试使用

local function Window()
    return Settings("fishingPopupWindow", { view = "trip" })
end

local function Enabled()
    return Module.enabled and ns:GetModuleSettings(Module).fishingPopup ~= false
end

-- 主手是不是鱼竿
local function HoldingPole()
    local itemID = GetInventoryItemID and GetInventoryItemID("player", MAINHAND)
    if not itemID then
        return false
    end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    return classID == WEAPON_CLASS and subclassID == FISHING_POLE
end
Popup.HoldingPole = HoldingPole

--------------------------------------------------------------------------------
-- 数据
--------------------------------------------------------------------------------

local function Here()
    local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    return mapID, GetSubZoneText and GetSubZoneText() or ""
end

-- 某地某子区域的水域：返回地区数据、水域序号、标准几率 { [物品] = 几率 }（季节、任务限定的不算）、水域名
local function WaterHere(mapID, subzone)
    local zone = mapID and R.Fishing.ZoneOf(mapID)
    if not zone then
        return nil, nil, {}, nil
    end
    local index = R.Fishing.WaterOf(zone, subzone)
    local water = zone.waters[index]
    local rates = {}
    for _, row in ipairs(water and water.catch or {}) do
        if row[3] == "" then
            rates[row[1]] = row[2]
        end
    end
    local name
    if water and water.main then
        name = #zone.waters > 1 and L["Open water"] or nil
    elseif water then
        name = table.concat(ns.Name(water.areas) or {}, L[", "])
    end
    return zone, index, rates, name
end

local function Place(mapID, subzone, waterName)
    local parts = { ns.MapName(mapID) or L["Unknown zone"] }
    if subzone and subzone ~= "" then
        tinsert(parts, subzone)
    end
    if waterName and waterName ~= "" and waterName ~= subzone then
        tinsert(parts, waterName)
    end
    return table.concat(parts, " · ")
end

local function Minutes(trip)
    return math.floor(math.max(0, (trip.last or trip.start) - trip.start) / 60 + 0.5)
end

local function Kinds(record)
    local kinds = 0
    for _ in pairs(record.qty) do
        kinds = kinds + 1
    end
    return kinds
end

-- 表格行：{ id, qty, mine（带回它的上钩次数）, standard }。钓到的在前（件数多的在前），
-- withStandard 时标准表里有而没钓到的按几率排在后面
local function Rows(record, rates, withStandard)
    local rows, seen = {}, {}
    for itemID, qty in pairs(record and record.qty or {}) do
        seen[itemID] = true
        tinsert(rows, { id = itemID, qty = qty, mine = record.items[itemID] or 0, standard = rates[itemID] })
    end
    if withStandard then
        for itemID, pct in pairs(rates) do
            if not seen[itemID] then
                tinsert(rows, { id = itemID, qty = 0, mine = 0, standard = pct })
            end
        end
    end
    table.sort(rows, function(a, b)
        if (a.qty > 0) ~= (b.qty > 0) then
            return a.qty > 0
        end
        if a.qty ~= b.qty then
            return a.qty > b.qty
        end
        if (a.standard or 0) ~= (b.standard or 0) then
            return (a.standard or 0) > (b.standard or 0)
        end
        return a.id < b.id
    end)
    return rows
end
Popup.Rows = Rows -- 供测试使用

--------------------------------------------------------------------------------
-- 框架
--------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relativePoint, x, y = frame:GetPoint()
    Window().position = { point, relativePoint, x, y }
end

local function RestorePosition()
    local position = Window().position
    frame:ClearAllPoints()
    if position then
        frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else
        frame:SetPoint("RIGHT", UIParent, "RIGHT", -260, 60)
    end
end

local function ApplyScale()
    if frame then
        frame:SetScale(Window().scale or 1)
    end
end

local function StartMoving()
    if frame and not Window().locked then
        frame:StartMoving()
    end
end

local function StopMoving()
    frame:StopMovingOrSizing()
    SavePosition()
end

local function OpenWorkbench()
    if R.SetFishingLens and R.OpenStandalone then
        R.SetFishingLens("mine")
        R.OpenStandalone("fishing")
    end
end

local function WindowMenu()
    ns.UI:ContextMenu(function()
        local entries = ns.UI:WindowMenuEntries(Window(), ApplyScale)
        tinsert(entries, { kind = "separator" })
        tinsert(entries, { kind = "action", text = L["Open the fishing workbench"], onClick = OpenWorkbench })
        tinsert(entries, { kind = "action", text = L["Settings"], onClick = function()
            ns.MainFrame:Open("settings")
        end })
        return entries
    end)
end

local function Draggable(widget)
    widget:RegisterForDrag("LeftButton")
    widget:SetScript("OnDragStart", StartMoving)
    widget:SetScript("OnDragStop", StopMoving)
end

local Refresh

-- 一行四列：a 名字（左），b、c、d 数字（右对齐）
local function CreateRow(parent)
    local UI = ns.UI
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.hover = row:CreateTexture(nil, "BACKGROUND")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(unpack(Theme.colors.glassHover))
    row.hover:Hide()
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 0, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.d = UI:Text(row, "Small")
    row.d:SetPoint("RIGHT", 0, 0)
    row.d:SetWidth(46)
    row.d:SetJustifyH("RIGHT")
    row.c = UI:Text(row, "Small")
    row.c:SetPoint("RIGHT", row.d, "LEFT", -2, 0)
    row.c:SetWidth(46)
    row.c:SetJustifyH("RIGHT")
    row.b = UI:Text(row, "Small")
    row.b:SetPoint("RIGHT", row.c, "LEFT", -2, 0)
    row.b:SetWidth(40)
    row.b:SetJustifyH("RIGHT")
    row.a = UI:Text(row, "Small")
    row.a:SetPoint("RIGHT", row.b, "LEFT", -4, 0)
    row.a:SetJustifyH("LEFT")
    row.a:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
        if self.item or self.onClick then
            self.hover:Show()
        end
        if self.item then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetItemByID(self.item)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip_Hide()
    end)
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            WindowMenu()
        elseif self.onClick then
            self.onClick()
        end
    end)
    Draggable(row)
    return row
end

local function Create()
    local UI = ns.UI
    frame = CreateFrame("Frame", "WowHandbookFishingFrame", UIParent, "BackdropTemplate")
    Theme:Skin(frame, "glass", "glassLine")
    frame:SetWidth(WIDTH)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    Draggable(frame)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            WindowMenu()
        end
    end)
    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetHeight(2)
    accent:SetColorTexture(unpack(Theme.colors.gold))

    frame.close = UI:CloseButton(frame, function()
        dismissed = true
        forced = false
        frame:Hide()
    end, 18)
    frame.close:SetPoint("TOPRIGHT", -3, -5)
    frame.title = UI:Text(frame, "Heading")
    frame.title:SetPoint("TOPLEFT", PAD, -9)
    frame.title:SetPoint("RIGHT", frame.close, "LEFT", -4, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetWordWrap(false)
    frame.title:SetText(L["My catches"])

    local labels = { trip = L["This trip"], zone = L["These waters"], history = L["Past trips"] }
    local items = {}
    for _, id in ipairs(VIEWS) do
        tinsert(items, { id = id, label = labels[id] })
    end
    frame.views = UI:Segmented(frame, items, function(view)
        Window().view = view
        selected = nil
        Refresh()
    end, math.floor((WIDTH - PAD * 2) / #VIEWS))
    frame.views:SetPoint("TOPLEFT", PAD, -32)
    frame.views:SetHeight(20)
    for _, button in pairs(frame.views.buttons) do
        button:SetHeight(20)
    end

    frame.place = UI:Text(frame, "Body")
    frame.place:SetJustifyH("LEFT")
    frame.place:SetWordWrap(false)
    frame.summary = UI:Text(frame, "Small")
    frame.summary:SetJustifyH("LEFT")
    frame.summary:SetWordWrap(true)

    local half = math.floor((WIDTH - PAD * 2 - 6) / 2)
    frame.start = UI:Button(frame, L["Start a new trip"], half, 20)
    frame.start:SetScript("OnClick", function()
        R.Fishing.StartTrip()
        Window().view = "trip"
        selected = nil
        Refresh()
    end)
    frame.stop = UI:Button(frame, L["End this trip"], half, 20)
    frame.stop:SetPoint("LEFT", frame.start, "RIGHT", 6, 0)
    frame.stop:SetScript("OnClick", function()
        R.Fishing.EndTrip()
        Refresh()
    end)
    frame.back = UI:Button(frame, L["Back to past trips"], half, 20)
    frame.back:SetScript("OnClick", function()
        selected = nil
        Refresh()
    end)

    frame.header = CreateRow(frame)
    frame.header:EnableMouse(false)
    frame.rows = {}
    frame.note = UI:Text(frame, "Small")
    frame.note:SetJustifyH("LEFT")
    frame.note:SetWordWrap(true)
    ApplyScale()
    RestorePosition()
    frame:Hide()
    Popup.frame = frame -- 供测试使用
end

--------------------------------------------------------------------------------
-- 排版：自上而下，y 为当前位置（负数）
--------------------------------------------------------------------------------

local function Line(widget, y, gap)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", PAD, y)
    widget:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    widget:Show()
    local height = widget.GetStringHeight and math.ceil(widget:GetStringHeight()) or widget:GetHeight()
    return y - height - (gap or 4)
end

local function Header(y, a, b, c, d)
    local row = frame.header
    row.icon:Hide()
    row.a:SetText(Color(a, "muted"))
    row.b:SetText(Color(b or "", "muted"))
    row.c:SetText(Color(c or "", "muted"))
    row.d:SetText(Color(d or "", "muted"))
    return Line(row, y, 0)
end

local function Row(index, y)
    local row = frame.rows[index]
    if not row then
        row = CreateRow(frame)
        frame.rows[index] = row
    end
    row.item, row.onClick = nil, nil
    row.icon:Hide()
    return row, Line(row, y, 0)
end

local function Pct(count, n)
    return n > 0 and R.Fishing.Rate(count / n * 100) or ""
end

-- 渔获表：件数、你的几率（本次或累计）、标准几率；返回新的 y、总行数、画出的行数
local function CatchTable(y, record, rates, withStandard, yoursLabel)
    local rows = Rows(record, rates, withStandard)
    if #rows == 0 then
        return y, 0, 0
    end
    local showStandard = next(rates) ~= nil
    y = Header(y, L["Catch"], L["Caught"], yoursLabel, showStandard and L["Chance"] or "")
    local few = record.n < FEW_CATCHES
    local shown = math.min(#rows, MAX_ROWS)
    for index = 1, shown do
        local data = rows[index]
        local row
        row, y = Row(index, y)
        row.item = data.id
        row.icon:SetTexture(C_Item.GetItemIconByID(data.id))
        row.icon:Show()
        local name = R.Fishing.ItemName(data.id)
        local mine = data.qty > 0 and Pct(data.mine, record.n) or (record.n > 0 and "0%" or "")
        row.a:SetText(data.qty > 0 and name or Color(name, "muted"))
        row.b:SetText(data.qty > 0 and ("x" .. data.qty) or Color("-", "muted"))
        row.c:SetText((few or data.qty == 0) and Color(mine, "muted") or mine)
        row.d:SetText(showStandard and Color(data.standard and R.Fishing.Rate(data.standard) or "-", "muted") or "")
    end
    return y, #rows, shown
end

local function TripSummary(trip)
    local text = (L["Started %s · %d min · %d catches · %d kinds"]):format(date("%H:%M", trip.start), Minutes(trip),
        trip.n, Kinds(trip))
    if trip.manual then
        text = text .. " · " .. Color(L["started by you"], "gold")
    end
    return text
end

-- 本次（或历次里选中的一期）
local function DrawTrip(y, trip, past)
    local mapID, subzone = Here()
    if not trip then
        frame.place:SetText(Place(mapID, subzone, select(4, WaterHere(mapID, subzone))))
        y = Line(frame.place, y)
        frame.summary:SetText(Color(L[NEXT_TRIP], "muted"))
        return Line(frame.summary, y, 8), 0, 0
    end
    local here = not past and trip.map == mapID
    local where = here and subzone or trip.subzone
    local _, _, rates, waterName = WaterHere(trip.map, where)
    frame.place:SetText(Place(trip.map, where, waterName))
    y = Line(frame.place, y)
    frame.summary:SetText((past and date("%m-%d ", trip.start) or "") .. TripSummary(trip))
    y = Line(frame.summary, y, 6)
    if trip.n == 0 then
        frame.note:SetText(Color(L["Cast your line: every catch on this trip is counted here."], "muted"))
        return Line(frame.note, y, 6), 0, 0
    end
    return CatchTable(y, trip, rates, false, L["This trip"])
end

-- 本地区：所在水域的标准几率与你在这片水域的累计几率
local function DrawZone(y)
    local F = R.Fishing
    local mapID, subzone = Here()
    local zone, index, rates, waterName = WaterHere(mapID, subzone)
    frame.place:SetText(Place(mapID, subzone, waterName))
    y = Line(frame.place, y)
    local record
    if zone then
        record = F.OwnWaters(mapID, zone)[index] or F.NewRecord()
    else
        record = mapID and F.OwnTotal(mapID) or F.NewRecord()
    end
    local text = record.n > 0 and (L["You have caught %d times in these waters"]):format(record.n)
        or L["You have not fished these waters yet"]
    if not zone then
        text = text .. " · " .. L["No standard chances for this zone yet"]
    end
    frame.summary:SetText(Color(text, "muted"))
    y = Line(frame.summary, y, 6)
    return CatchTable(y, record, rates, true, L["Yours"])
end

local function DrawHistory(y)
    local trips = R.Fishing.Trips()
    if #trips == 0 then
        frame.summary:SetText(Color(L["No trips yet: every time you go fishing, the trip is kept here."], "muted"))
        return Line(frame.summary, y, 6), 0, 0
    end
    local active = R.Fishing.ActiveTrip()
    y = Header(y, L["Trip"], "", L["Hooked"], L["Minutes"])
    local shown = math.min(#trips, MAX_ROWS)
    for index = 1, shown do
        local trip = trips[#trips - index + 1]
        local row
        row, y = Row(index, y)
        local text = date("%m-%d %H:%M  ", trip.start) .. (ns.MapName(trip.map) or L["Unknown zone"])
        row.a:SetText(trip == active and Color(text, "gold") or text)
        row.b:SetText(trip.manual and Color(L["Manual"], "muted") or "")
        row.c:SetText(tostring(trip.n))
        row.d:SetText(tostring(Minutes(trip)))
        row.onClick = function()
            selected = trip
            Refresh()
        end
    end
    return y, #trips, shown
end

function Refresh()
    if not (frame and frame:IsShown()) then
        return
    end
    local view = Window().view
    if view ~= "zone" and view ~= "history" then
        view = "trip"
    end
    frame.views:Select(view)
    for _, widget in ipairs({ frame.place, frame.summary, frame.note, frame.header, frame.start, frame.stop,
        frame.back }) do
        widget:Hide()
    end
    local active = R.Fishing.ActiveTrip((Here()))
    local y, count, shown = -60
    local button
    if view == "trip" then
        y, count, shown = DrawTrip(y, active)
        button = frame.start
        frame.stop:SetShown(active ~= nil)
    elseif view == "zone" then
        y, count, shown = DrawZone(y)
    elseif selected then
        y, count, shown = DrawTrip(y, selected, true)
        button = frame.back
    else
        y, count, shown = DrawHistory(y)
    end
    for index = shown + 1, #frame.rows do
        frame.rows[index]:Hide()
    end
    if count > shown then
        frame.note:SetText(Color((L["%d more: see the fishing workbench"]):format(count - shown), "muted"))
        y = Line(frame.note, y - 2, 4)
    end
    if button then
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", PAD, y - 4)
        button:Show()
        y = y - 4 - button:GetHeight()
    end
    frame:SetHeight(-y + PAD)
end
Popup.Refresh = Refresh

--------------------------------------------------------------------------------
-- 显示时机
--------------------------------------------------------------------------------

-- 拿起鱼竿时打开，放下时收起（/wh fishing 打开的不随鱼竿收起）；关掉后到下次拿起鱼竿前不再自动弹出
local function Update()
    local hold = Enabled() and HoldingPole()
    if hold and not holding then
        dismissed = false
    end
    holding = hold
    if not (Enabled() and (forced or (hold and not dismissed))) then
        if frame then
            frame:Hide()
        end
        return
    end
    if not frame then
        Create()
    end
    frame:Show()
    Refresh()
end
Popup.Update = Update
R.UpdateFishingPopup = Update

local function Toggle()
    if not Enabled() then
        ns:Print(L["Turn on the catch window in the Workbench settings first."])
        return
    end
    if frame and frame:IsShown() then
        forced, dismissed = false, true
    else
        forced = true
    end
    Update()
end
Popup.Toggle = Toggle

local function OnEquipment(_, slot)
    if slot == nil or slot == MAINHAND then
        Update()
    end
end

local ZONE_EVENTS = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" }

function R.FishingPopupChanged()
    Refresh()
end

function R.StartFishingPopup()
    ns:AddCommand("fishing", L["show or hide your catch window"], Toggle)
    ns:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", OnEquipment)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
    for _, event in ipairs(ZONE_EVENTS) do
        ns:RegisterEvent(event, Refresh)
    end
    Update()
end

function R.StopFishingPopup()
    ns:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED", OnEquipment)
    ns:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
    for _, event in ipairs(ZONE_EVENTS) do
        ns:UnregisterEvent(event, Refresh)
    end
    holding, forced = false, false
    if frame then
        frame:Hide()
    end
end
