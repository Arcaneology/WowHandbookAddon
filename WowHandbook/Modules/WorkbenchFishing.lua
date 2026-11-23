local ADDON_NAME, ns = ...
local L = ns.L

-- 专业工作台的钓鱼视角（专业工作台模块 Workbench 的一部分）。钓鱼没有配方，工作台换成四个视角：
--   地区：网站钓鱼数据里的地区按水域技能分组，选中后右栏列出每片水域（主水域与另算的子区域）的渔获几率，
--     与玩家自己在那里钓到的比例并排；鱼群另列。玩家所在的地区默认选中，所在的那片水域标出来。
--   渔获：每种渔获按类别（鱼、宝箱、药水、其他、垃圾）列出，右栏是它出在哪些地区的哪片水域、哪些鱼群，各自的几率。
--   我的渔获：所在地区（标准几率与玩家几率对照）、钓过的地区、钓到过的物品与件数。
--   训练师：与其他采集专业相同。
-- 记录：每次钓鱼上钩（拾取窗口来自钓鱼，IsFishingLoot；客户端没有这个接口时看拾取来源是不是鱼漂）记下所在地图、
--   子区域与水域（开阔水域或鱼群物件 ID），存角色存档 WowHandbookCharDB.fishing[地图] =
--   { areas = { [子区域名] = 记录 }, schools = { [鱼群物件 ID] = 记录 } }，记录 = { n 上钩次数, items = { [物品] = 出现次数 },
--   qty = { [物品] = 件数 }, last 时间 }。子区域名随客户端语言。同一来源 2 秒内重复打开拾取只算一次。
--   设置 recordFishing（默认开启）关掉后不再记录。只记游戏数据，不记角色名等个人信息。
-- 几率：网站数据是每次上钩得到该物品的几率；玩家几率是带回该物品的上钩次数占全部上钩次数的比例，两者可直接对照。
-- 数据：Data/Fishing.lua（tools/export_fishing_data.py 从网站导出）；物品名称、图标、品质运行时向客户端取。

-- luacheck: read globals IsFishingLoot
local R = ns.modules.Workbench
local Module = R
local Color, Settings, Name, ItemLink = R.Color, R.Settings, R.Name, R.ItemLink

local Fishing = {}
R.Fishing = Fishing

local BOBBER = 35591 -- 鱼漂（Fishing Bobber）的物件 ID
local REPEAT_SECONDS = 2
local FEW_CATCHES = 20 -- 上钩少于这么多次时，玩家几率只作参考（灰色）
local KIND_ORDER = { "fish", "treasure", "potion", "other", "junk" }
local KIND_LABEL = { fish = "Fish", treasure = "Treasure", potion = "Potions", other = "Other catches", junk = "Junk" }
local FLAG_LABEL = { quest = "only while on the quest", winter = "winter only", summer = "summer only" }
local SHARE_COLORS = { "gold", "blue", "green", "goldDim", "textDim", "muted" }
local VIEW_DEFAULTS = { view = "zones" }

local RATE_COLUMNS = {
    { key = "a", label = "Catch", width = 250 },
    { key = "b", label = "Chance", width = 76 },
    { key = "c", label = "Yours", width = 76 },
    { key = "d", label = "Caught" },
}
local OWN_COLUMNS = {
    { key = "a", label = "Catch", width = 326 },
    { key = "c", label = "Yours", width = 76 },
    { key = "d", label = "Caught" },
}
local WHERE_COLUMNS = {
    { key = "a", label = "Where", width = 326 },
    { key = "b", label = "Chance", width = 76 },
    { key = "c", label = "Yours" },
}

--------------------------------------------------------------------------------
-- 数据索引
--------------------------------------------------------------------------------

-- 导出时空表不写出：没有鱼群、没有子区域名的地方补成空表，后面不必逐处判断
local normalized
local function Data()
    local data = ns.Data.fishing or { zones = {}, kinds = {} }
    if not normalized then
        normalized = true
        data.zones, data.kinds = data.zones or {}, data.kinds or {}
        for _, zone in ipairs(data.zones) do
            zone.waters, zone.schools = zone.waters or {}, zone.schools or {}
            for _, water in ipairs(zone.waters) do
                water.areas, water.catch = water.areas or {}, water.catch or {}
            end
            for _, school in ipairs(zone.schools) do
                school.yields = school.yields or {}
            end
        end
    end
    return data
end

local byMap, bySlug
local function Index()
    if not byMap then
        byMap, bySlug = {}, {}
        for _, zone in ipairs(Data().zones) do
            byMap[zone.map] = zone
            bySlug[zone.slug] = zone
        end
    end
    return byMap, bySlug
end

function Fishing.ZoneOf(mapID)
    return mapID and Index()[mapID]
end

-- 水域技能：可钓 max(1, level)，不脱钩 level + 95（与网站相同）
local function Band(level)
    level = level or 330
    return math.max(1, level), level + 95
end
Fishing.Band = Band

local function ClientLocale()
    return (GetLocale and GetLocale() == "zhCN") and "zhCN" or "enUS"
end

-- 子区域属于哪片水域：子区域名（客户端语言）在某片非主水域的 areas 里就是它，否则是主水域
local function WaterOf(zone, subzone)
    local main
    local locale = ClientLocale()
    for index, water in ipairs(zone.waters) do
        if water.main then
            main = main or index
        elseif subzone and subzone ~= "" then
            for _, area in ipairs(water.areas[locale] or water.areas.enUS or {}) do
                if area == subzone then
                    return index
                end
            end
        end
    end
    return main or 1
end
Fishing.WaterOf = WaterOf

local function AreaText(water)
    local areas = Name(water.areas) or {}
    return table.concat(areas, L[", "])
end

local function WaterTitle(zone, water)
    if water.main then
        return #zone.waters > 1 and L["Open water"] or ns.MapName(zone.map) or zone.slug
    end
    return AreaText(water)
end

-- 1 以上留一位小数，以下留两位，去掉末尾的 0（58.8%、40%、0.07%）
local function Rate(pct)
    local text = (pct >= 1 and "%.1f" or "%.2f"):format(pct)
    text = text:gsub("(%.%d-)0+$", "%1"):gsub("%.$", "")
    return text .. "%"
end
Fishing.Rate = Rate

local function ItemName(itemID)
    local name, _, quality = C_Item.GetItemInfo(itemID)
    if not name then
        ns.RequestItem(itemID)
        return "#" .. itemID
    end
    local hex = quality and C_Item.GetItemQualityColor and select(4, C_Item.GetItemQualityColor(quality))
    return hex and ("|c" .. hex .. name .. "|r") or name
end

--------------------------------------------------------------------------------
-- 玩家的渔获记录
--------------------------------------------------------------------------------

local function Store()
    ns.charDB.fishing = ns.charDB.fishing or {}
    return ns.charDB.fishing
end

local function NewRecord()
    return { n = 0, items = {}, qty = {} }
end

--------------------------------------------------------------------------------
-- 历次钓鱼（一期一期的记录）：存角色存档 WowHandbookCharDB.fishingTrips（新的在后，最多 TRIP_LIMIT 期），
-- 每期 = { start 开始时间, last 最后上钩时间, map 开始时的地图, subzone 开始时的子区域, n, items, qty（同记录），
--   manual 玩家手动开的, ended 已结束 }。
-- 自动分期：上钩时如果没有进行中的一期，或进行中的是自动的一期而换了地图、距上一杆超过 TRIP_GAP 秒，就自动开新的一期。
-- 手动分期：玩家点“开始新一期”立刻开一期，跨地图、隔多久都算同一期，直到玩家点“结束本期”或再开新的一期。
--------------------------------------------------------------------------------

local TRIP_GAP = 15 * 60
local TRIP_LIMIT = 50
Fishing.TRIP_GAP = TRIP_GAP

local function Trips()
    ns.charDB.fishingTrips = ns.charDB.fishingTrips or {}
    return ns.charDB.fishingTrips
end
Fishing.Trips = Trips

-- 进行中的一期（自动的一期在玩家换了地图或停了太久后视为已结束），没有返回 nil
local function ActiveTrip(mapID)
    local trips = Trips()
    local trip = trips[#trips]
    if not trip or trip.ended then
        return nil
    end
    if not trip.manual then
        if (trip.last or trip.start) + TRIP_GAP < time() then
            return nil
        end
        if mapID and trip.map ~= mapID then
            return nil
        end
    end
    return trip
end
Fishing.ActiveTrip = ActiveTrip

local function StartTrip(manual)
    local trips = Trips()
    local last = trips[#trips]
    if last then
        last.ended = true
        if last.n == 0 then
            table.remove(trips) -- 一杆没钓就结束的不留
        end
    end
    local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local trip = { start = time(), map = mapID, subzone = GetSubZoneText and GetSubZoneText() or "",
        manual = manual or nil, n = 0, items = {}, qty = {} }
    tinsert(trips, trip)
    while #trips > TRIP_LIMIT do
        table.remove(trips, 1)
    end
    return trip
end

-- 玩家手动开一期 / 结束本期
function Fishing.StartTrip()
    local trip = StartTrip(true)
    if R.FishingChanged then
        R.FishingChanged()
    end
    return trip
end

function Fishing.EndTrip()
    local trips = Trips()
    local trip = trips[#trips]
    if trip and not trip.ended then
        trip.ended = true
        if trip.n == 0 then
            table.remove(trips)
        end
        if R.FishingChanged then
            R.FishingChanged()
        end
    end
end

function Fishing.TripForCatch(mapID)
    local trip = ActiveTrip(mapID)
    if not trip then
        trip = StartTrip(false)
        trip.map = mapID
    end
    return trip
end

local function AddRecord(total, record)
    total.n = total.n + (record.n or 0)
    for itemID, count in pairs(record.items or {}) do
        total.items[itemID] = (total.items[itemID] or 0) + count
    end
    for itemID, count in pairs(record.qty or {}) do
        total.qty[itemID] = (total.qty[itemID] or 0) + count
    end
end

local function LootSource()
    local guid = GetLootSourceInfo and GetLootSourceInfo(1)
    if type(guid) ~= "string" or ns.IsSecret(guid) then
        return nil, nil
    end
    return tonumber(guid:match("^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")), guid
end

local lastSource, lastTime
local function OnLootOpened()
    if ns:GetModuleSettings(Module).recordFishing == false or not (GetNumLootItems and GetLootSlotLink) then
        return
    end
    local objectID, guid = LootSource()
    local fishing
    if IsFishingLoot then
        fishing = IsFishingLoot() and true or false
    else
        fishing = objectID == BOBBER
    end
    if not fishing then
        return
    end
    local now = GetTime()
    if guid and guid == lastSource and lastTime and now - lastTime < REPEAT_SECONDS then
        return
    end
    lastSource, lastTime = guid, now
    local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not mapID then
        return
    end
    local store = Store()
    local place = store[mapID] or { areas = {}, schools = {} }
    store[mapID] = place
    local record
    if objectID and objectID ~= BOBBER then
        place.schools[objectID] = place.schools[objectID] or NewRecord()
        record = place.schools[objectID]
    else
        local subzone = GetSubZoneText and GetSubZoneText() or ""
        place.areas[subzone] = place.areas[subzone] or NewRecord()
        record = place.areas[subzone]
    end
    record.n = record.n + 1
    record.last = time()
    -- 当期钓鱼的统计，与地区记录同样计数
    local session = Fishing.TripForCatch(mapID)
    session.n = session.n + 1
    session.last = record.last
    local seen = {}
    for slot = 1, GetNumLootItems() do
        local link = GetLootSlotLink(slot)
        local itemID = type(link) == "string" and not ns.IsSecret(link) and tonumber(link:match("item:(%d+)"))
        if itemID then
            local quantity = GetLootSlotInfo and tonumber((select(3, GetLootSlotInfo(slot)))) or 1
            record.qty[itemID] = (record.qty[itemID] or 0) + math.max(1, quantity)
            session.qty[itemID] = (session.qty[itemID] or 0) + math.max(1, quantity)
            if not seen[itemID] then
                seen[itemID] = true
                record.items[itemID] = (record.items[itemID] or 0) + 1
                session.items[itemID] = (session.items[itemID] or 0) + 1
            end
        end
    end
    if R.FishingChanged then
        R.FishingChanged()
    end
end
Fishing.OnLootOpened = OnLootOpened -- 供测试使用

function R.StartFishingLog()
    ns:RegisterEvent("LOOT_OPENED", OnLootOpened)
end

function R.StopFishingLog()
    ns:UnregisterEvent("LOOT_OPENED", OnLootOpened)
end

-- 某张地图上玩家的开阔水域渔获，按水域汇总：{ [水域序号] = 记录 }，另返回全图合计与各子区域的上钩次数
local function OwnWaters(mapID, zone)
    local place = Store()[mapID]
    local waters, total, subzones = {}, NewRecord(), {}
    for subzone, record in pairs(place and place.areas or {}) do
        local index = zone and WaterOf(zone, subzone) or 1
        waters[index] = waters[index] or NewRecord()
        AddRecord(waters[index], record)
        AddRecord(total, record)
        subzones[subzone] = (subzones[subzone] or 0) + record.n
    end
    return waters, total, subzones
end

Fishing.OwnWaters = OwnWaters
Fishing.NewRecord = NewRecord
Fishing.ItemName = ItemName

-- 玩家钓过的鱼群对上该地区的哪个鱼群：按鱼群的普通渔获几率给玩家带回的物品打分，取最高的；对不上的记为 0
local function OwnSchools(mapID, zone)
    local place = Store()[mapID]
    local matched = {}
    for _, record in pairs(place and place.schools or {}) do
        local best, bestScore = 0, 0
        for index, school in ipairs(zone and zone.schools or {}) do
            local score = 0
            for _, row in ipairs(school.yields) do
                score = score + (record.items[row[1]] or 0) * row[2]
            end
            if score > bestScore then
                best, bestScore = index, score
            end
        end
        matched[best] = matched[best] or NewRecord()
        AddRecord(matched[best], record)
    end
    return matched
end

-- 一张地图上玩家的全部渔获（开阔水域加鱼群）
local function OwnTotal(mapID)
    local place = Store()[mapID]
    local total = NewRecord()
    for _, record in pairs(place and place.areas or {}) do
        AddRecord(total, record)
    end
    for _, record in pairs(place and place.schools or {}) do
        AddRecord(total, record)
    end
    return total
end
Fishing.OwnTotal = OwnTotal

-- 玩家所有地图的合计：返回合计记录与 { [地图] = 上钩次数 }
local function OwnAll()
    local total, maps = NewRecord(), {}
    for mapID in pairs(Store()) do
        local record = OwnTotal(mapID)
        if record.n > 0 then
            AddRecord(total, record)
            maps[mapID] = record.n
        end
    end
    return total, maps
end
Fishing.OwnAll = OwnAll

local function OwnRate(record, itemID)
    if not (record and record.n > 0) then
        return ""
    end
    local text = Rate((record.items[itemID] or 0) / record.n * 100)
    return record.n < FEW_CATCHES and Color(text, "muted") or text
end

local function Caught(record, itemID)
    local count = record and record.qty[itemID]
    return count and count > 0 and ("x" .. count) or ""
end

--------------------------------------------------------------------------------
-- 左栏条目
--------------------------------------------------------------------------------

local function Here()
    local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    return mapID, GetSubZoneText and GetSubZoneText() or ""
end

local function ZoneName(zone, mapID)
    return ns.MapName(zone and zone.map or mapID) or (zone and zone.slug) or "?"
end

local function Matches(text, q)
    return q == "" or (text and text:lower():find(q, 1, true) ~= nil)
end

local function ZoneMatches(zone, q)
    if Matches(ZoneName(zone), q) then
        return true
    end
    for _, water in ipairs(zone.waters) do
        if Matches(AreaText(water), q) then
            return true
        end
    end
    return false
end

local function BandText(level)
    local low, high = Band(level)
    return (L["Skill %d-%d"]):format(low, high)
end

local function ZoneEntries(entries, q)
    local here = Here()
    local zones = {}
    for _, zone in ipairs(Data().zones) do
        if ZoneMatches(zone, q) then
            tinsert(zones, zone)
        end
    end
    table.sort(zones, function(a, b)
        if (a.level or 330) ~= (b.level or 330) then
            return (a.level or 330) < (b.level or 330)
        end
        return ZoneName(a) < ZoneName(b)
    end)
    local band, default
    for _, zone in ipairs(zones) do
        if zone.level ~= band then
            band = zone.level
            tinsert(entries, { id = "band:" .. tostring(band), divider = true, text = BandText(band) })
        end
        local caught = OwnTotal(zone.map).n
        local isHere = zone.map == here
        local id = "fz:" .. zone.slug
        default = isHere and id or default
        tinsert(entries, { id = id, fishing = "zone", zone = zone, map = zone.map,
            text = Color(ZoneName(zone), isHere and "gold" or "text"),
            tags = isHere and Color(L["You are here"], "green")
                or (caught > 0 and Color((L["%d catches"]):format(caught), "muted") or nil) })
    end
    if #zones == 0 then
        tinsert(entries, { id = "noZones", divider = true, text = Color(L["No match"], "muted") })
    end
    return (L["%d fishing zones"]):format(#zones), default
end

-- 每种渔获：类别、可钓的最低水域等级、最高几率（只算普通的，不算任务 / 季节）
local fishList
local function FishList()
    if fishList then
        return fishList
    end
    local info = {}
    local function Note(itemID, pct, flag, level)
        local entry = info[itemID]
        if not entry then
            entry = { id = itemID, kind = Data().kinds[itemID] or "other", best = 0, level = 999 }
            info[itemID] = entry
        end
        if flag == "" then
            entry.best = math.max(entry.best, pct)
        end
        entry.level = math.min(entry.level, level or 330)
    end
    for _, zone in ipairs(Data().zones) do
        for _, water in ipairs(zone.waters) do
            for _, row in ipairs(water.catch) do
                Note(row[1], row[2], row[3], water.level)
            end
        end
        for _, school in ipairs(zone.schools) do
            for _, row in ipairs(school.yields) do
                Note(row[1], row[2], row[3], zone.level)
            end
        end
    end
    local order = {}
    for index, kind in ipairs(KIND_ORDER) do
        order[kind] = index
    end
    fishList = {}
    for _, entry in pairs(info) do
        tinsert(fishList, entry)
    end
    table.sort(fishList, function(a, b)
        if a.kind ~= b.kind then
            return (order[a.kind] or 9) < (order[b.kind] or 9)
        end
        if a.level ~= b.level then
            return a.level < b.level
        end
        if a.best ~= b.best then
            return a.best > b.best
        end
        return a.id < b.id
    end)
    return fishList
end

local function FishEntries(entries, q)
    local own = OwnAll()
    local kind, count = nil, 0
    for _, fish in ipairs(FishList()) do
        local name = ItemName(fish.id)
        if Matches(name, q) then
            if fish.kind ~= kind then
                kind = fish.kind
                tinsert(entries, { id = "kind:" .. kind, divider = true, text = L[KIND_LABEL[kind] or "Other catches"] })
            end
            count = count + 1
            local caught = own.qty[fish.id]
            tinsert(entries, { id = "ff:" .. fish.id, fishing = "item", item = fish.id, text = name,
                tags = caught and Color("x" .. caught, "green") or (fish.best > 0 and Color(Rate(fish.best), "muted") or nil) })
        end
    end
    if count == 0 then
        tinsert(entries, { id = "noFish", divider = true, text = Color(L["No match"], "muted") })
    end
    return (L["%d kinds of catch"]):format(count)
end

local function MineEntries(entries, q)
    local here, subzone = Here()
    local total, maps = OwnAll()
    local default
    if here then
        local zone = Fishing.ZoneOf(here)
        tinsert(entries, { id = "where", divider = true, text = L["Where you are"] })
        local text = ZoneName(zone, here) .. (subzone ~= "" and (" · " .. subzone) or "")
        tinsert(entries, { id = "fm:here", fishing = "zone", zone = zone, map = here, text = Color(text, "gold"),
            tags = maps[here] and Color((L["%d catches"]):format(maps[here]), "green") or nil })
        default = "fm:here"
    end
    local list = {}
    for mapID in pairs(maps) do
        if mapID ~= here and Matches(ZoneName(Fishing.ZoneOf(mapID), mapID), q) then
            tinsert(list, mapID)
        end
    end
    table.sort(list, function(a, b)
        if maps[a] ~= maps[b] then
            return maps[a] > maps[b]
        end
        return a < b
    end)
    if #list > 0 then
        tinsert(entries, { id = "fished", divider = true, text = L["Zones you have fished"] })
        for _, mapID in ipairs(list) do
            tinsert(entries, { id = "fm:" .. mapID, fishing = "zone", zone = Fishing.ZoneOf(mapID), map = mapID,
                text = ZoneName(Fishing.ZoneOf(mapID), mapID), tags = Color((L["%d catches"]):format(maps[mapID]), "muted") })
        end
    end
    local items = {}
    for itemID in pairs(total.qty) do
        if Matches(ItemName(itemID), q) then
            tinsert(items, itemID)
        end
    end
    table.sort(items, function(a, b)
        if total.qty[a] ~= total.qty[b] then
            return total.qty[a] > total.qty[b]
        end
        return a < b
    end)
    if #items > 0 then
        tinsert(entries, { id = "caught", divider = true, text = (L["Your catches (%d kinds)"]):format(#items) })
        for _, itemID in ipairs(items) do
            tinsert(entries, { id = "fi:" .. itemID, fishing = "item", item = itemID, text = ItemName(itemID),
                tags = Color("x" .. total.qty[itemID], "green") })
        end
    elseif total.n == 0 then
        tinsert(entries, { id = "noCatches", divider = true,
            text = Color(L["No catches yet: go fishing and every catch is counted here"], "muted") })
    end
    return (L["%d catches · %d kinds"]):format(total.n, #items), default
end

-- 左栏：按视角填条目；返回顶栏概要与默认选中的条目
function R.FishingEntries(lens, entries, query)
    local q = (query or ""):lower()
    if lens == "fzones" then
        return ZoneEntries(entries, q)
    elseif lens == "ffish" then
        return FishEntries(entries, q)
    end
    return MineEntries(entries, q)
end

function R.FishingLens()
    local view = Settings("fishing", VIEW_DEFAULTS).view
    return (view == "fish" or view == "mine" or view == "trainers") and ("f" .. view) or "fzones"
end

function R.SetFishingLens(view)
    Settings("fishing", VIEW_DEFAULTS).view = view
end

--------------------------------------------------------------------------------
-- 右栏
--------------------------------------------------------------------------------

local function CatchLabel(row)
    local text = ItemName(row[1])
    if row[5] and row[5] > 1 then
        text = text .. Color((" x%d-%d"):format(row[4] or 1, row[5]), "muted")
    end
    if row[3] ~= "" and FLAG_LABEL[row[3]] then
        text = text .. "  " .. Color(L[FLAG_LABEL[row[3]]], "muted")
    end
    return text
end

-- 一张渔获几率表：标准几率、玩家几率、件数；玩家钓到过、表里没有的物品追加在后面
local function RateTable(t, rows, own)
    local segments = {}
    for index, row in ipairs(rows) do
        if row[3] == "" and index <= #SHARE_COLORS then
            tinsert(segments, { row[2], SHARE_COLORS[index] })
        end
    end
    if #segments > 1 then
        t:Bar(segments)
    end
    t:Header(RATE_COLUMNS)
    local listed = {}
    for index, row in ipairs(rows) do
        listed[row[1]] = true
        local swatch = row[3] == "" and SHARE_COLORS[index] or nil
        t:Line(RATE_COLUMNS, { a = CatchLabel(row), b = Rate(row[2]), c = OwnRate(own, row[1]), d = Caught(own, row[1]) },
            swatch, row[1])
    end
    local extra = {}
    for itemID in pairs(own and own.items or {}) do
        if not listed[itemID] then
            tinsert(extra, itemID)
        end
    end
    table.sort(extra, function(a, b)
        return own.items[a] > own.items[b]
    end)
    for _, itemID in ipairs(extra) do
        t:Line(RATE_COLUMNS, { a = ItemName(itemID), b = Color("-", "muted"), c = OwnRate(own, itemID),
            d = Caught(own, itemID) }, nil, itemID)
    end
end

local function OwnOnly(t, own)
    local items = {}
    for itemID in pairs(own.items) do
        tinsert(items, itemID)
    end
    table.sort(items, function(a, b)
        return own.items[a] > own.items[b]
    end)
    t:Header(OWN_COLUMNS)
    for _, itemID in ipairs(items) do
        t:Line(OWN_COLUMNS, { a = ItemName(itemID), c = OwnRate(own, itemID), d = Caught(own, itemID) }, nil, itemID)
    end
end

local function ZoneDetail(t, entry, skill)
    local zone, mapID = entry.zone, entry.map
    local here, subzone = Here()
    local isHere = mapID == here
    local total = OwnTotal(mapID)
    local sub = {}
    if zone then
        local low, high = Band(zone.level)
        tinsert(sub, (L["Fishable at %d, no lost catches at %d"]):format(low, high))
        local rank = skill and skill.rank
        if rank and rank < low then
            sub[1] = Color(sub[1], "red")
        elseif rank and rank < high then
            sub[1] = Color(sub[1], "skillYellow")
        end
    else
        tinsert(sub, Color(L["No standard fishing table for this zone"], "muted"))
    end
    if isHere then
        tinsert(sub, Color(L["You are here"], "green"))
    end
    R.SetHead("Interface\\Icons\\trade_fishing", ZoneName(zone, mapID), table.concat(sub, "  ·  "),
        total.n > 0 and tostring(total.n) or "", total.n > 0 and L["Your catches here"] or "")
    local waters, _, subzones = OwnWaters(mapID, zone)
    if not zone then
        if total.n > 0 then
            t:Heading(L["Your catches here"])
            OwnOnly(t, total)
        end
        return
    end
    local current = isHere and WaterOf(zone, subzone)
    for index, water in ipairs(zone.waters) do
        local title = WaterTitle(zone, water)
        if index == current then
            title = title .. "  ·  " .. L["You are here"]
        end
        if t:Section(title, "water:" .. zone.slug .. ":" .. index, index > 1 and 8 or 0) then
            if water.main and #zone.waters > 1 then
                t:Detail(Color(L["Everywhere in the zone except the waters listed below"], "muted"))
            end
            if water.level ~= zone.level then
                local low, high = Band(water.level)
                t:Detail(Color((L["Fishable at %d, no lost catches at %d"]):format(low, high), "muted"))
            end
            local own = waters[index]
            if own then
                t:Detail(Color((L["You: %d catches in these waters"]):format(own.n), "green"))
            end
            RateTable(t, water.catch, own)
        end
    end
    if #zone.schools > 0 then
        local schools = OwnSchools(mapID, zone)
        if t:Section(L["Fish schools"], "schools:" .. zone.slug, 12) then
            t:Detail(Color(L["Cast into a school's ripples for its own catch table"], "muted"))
            for index, school in ipairs(zone.schools) do
                local own = schools[index]
                t:Heading(Name(school.name) .. (own and Color(("  ·  " .. L["%d catches"]):format(own.n), "green") or ""), 6)
                RateTable(t, school.yields, own)
            end
            if schools[0] then
                t:Heading(L["Other schools you fished"], 6)
                OwnOnly(t, schools[0])
            end
        end
    end
    local names = {}
    for name in pairs(subzones) do
        tinsert(names, name)
    end
    if #names > 0 then
        table.sort(names, function(a, b)
            return subzones[a] > subzones[b]
        end)
        if t:Section(L["Where you fished in this zone"], "subzones:" .. zone.slug, 12) then
            for _, name in ipairs(names) do
                local water = zone.waters[WaterOf(zone, name)]
                t:Detail(("%s  %s  %s"):format(name ~= "" and name or ZoneName(zone),
                    Color((L["%d catches"]):format(subzones[name]), "green"), Color(WaterTitle(zone, water), "muted")))
            end
        end
    end
    t:Gap(8)
    t:Detail(Color(L["Chance: how often one catch brings the item, from the Classic fishing tables. "
        .. "Yours: the share of your own catches that brought it."], "muted"))
end

local function ItemDetail(t, entry)
    local itemID = entry.item
    local kind = Data().kinds[itemID]
    local own, maps = OwnAll()
    local best = 0
    local waters, schools = {}, {}
    for _, zone in ipairs(Data().zones) do
        for index, water in ipairs(zone.waters) do
            for _, row in ipairs(water.catch) do
                if row[1] == itemID then
                    tinsert(waters, { zone = zone, water = water, index = index, row = row })
                    best = row[3] == "" and math.max(best, row[2]) or best
                end
            end
        end
        for index, school in ipairs(zone.schools) do
            for _, row in ipairs(school.yields) do
                if row[1] == itemID then
                    tinsert(schools, { zone = zone, school = school, index = index, row = row })
                    best = row[3] == "" and math.max(best, row[2]) or best
                end
            end
        end
    end
    local sub = { kind and L[KIND_LABEL[kind]] or L["Catch"] }
    if own.qty[itemID] then
        tinsert(sub, Color((L["You caught %d"]):format(own.qty[itemID]), "green"))
    end
    R.SetHead(C_Item.GetItemIconByID(itemID), ItemLink(itemID), table.concat(sub, "  ·  "),
        best > 0 and Rate(best) or "", best > 0 and L["Best chance per catch"] or "")
    local function Sorter(a, b)
        if (a.row[3] == "") ~= (b.row[3] == "") then
            return a.row[3] == ""
        end
        if a.row[2] ~= b.row[2] then
            return a.row[2] > b.row[2]
        end
        return ZoneName(a.zone) < ZoneName(b.zone)
    end
    table.sort(waters, Sorter)
    table.sort(schools, Sorter)
    if #waters > 0 then
        t:Heading(L["Open water"])
        t:Header(WHERE_COLUMNS)
        for _, found in ipairs(waters) do
            local where = ZoneName(found.zone)
            if not found.water.main then
                where = where .. Color("  " .. AreaText(found.water), "muted")
            end
            local mine = (OwnWaters(found.zone.map, found.zone))[found.index]
            t:Line(WHERE_COLUMNS, { a = where .. (found.row[3] ~= "" and ("  " .. Color(L[FLAG_LABEL[found.row[3]]], "muted")) or ""),
                b = Rate(found.row[2]), c = OwnRate(mine, itemID) })
        end
    end
    if #schools > 0 then
        t:Heading(L["Fish schools"], 8)
        t:Header(WHERE_COLUMNS)
        for _, found in ipairs(schools) do
            local mine = (OwnSchools(found.zone.map, found.zone))[found.index]
            t:Line(WHERE_COLUMNS, { a = Name(found.school.name) .. Color("  " .. ZoneName(found.zone), "muted"),
                b = Rate(found.row[2]), c = OwnRate(mine, itemID) })
        end
    end
    if own.qty[itemID] then
        local list = {}
        for mapID in pairs(maps) do
            local record = OwnTotal(mapID)
            if record.qty[itemID] then
                tinsert(list, { map = mapID, record = record })
            end
        end
        table.sort(list, function(a, b)
            return a.record.qty[itemID] > b.record.qty[itemID]
        end)
        t:Heading(L["Where you caught it"], 8)
        t:Header(OWN_COLUMNS)
        for _, found in ipairs(list) do
            t:Line(OWN_COLUMNS, { a = ZoneName(Fishing.ZoneOf(found.map), found.map), c = OwnRate(found.record, itemID),
                d = Caught(found.record, itemID) })
        end
    end
    if #waters == 0 and #schools == 0 then
        t:Detail(Color(L["Not in the standard fishing tables"], "muted"))
    end
end

function R.FishingDetail(t, entry, skill)
    if entry.fishing == "item" then
        ItemDetail(t, entry)
    else
        ZoneDetail(t, entry, skill)
    end
end

-- 记下一次上钩后：渔获小窗立即刷新；工作台开着且在看钓鱼时，节流刷新
function R.FishingChanged()
    if R.FishingPopupChanged then
        R.FishingPopupChanged()
    end
    if R.bench and R.bench:IsVisible() and R.bench.slug == "fishing" and R.Refresh then
        if not Fishing.pending then
            Fishing.pending = true
            C_Timer.After(0.5, function()
                Fishing.pending = false
                if Module.enabled and R.bench:IsVisible() then
                    R.Refresh()
                end
            end)
        end
    end
end
