local ADDON_NAME, ns = ...

-- 记录玩家自己采过的草药与矿点（大地图模块 WorldMap 的一部分，设置 recordGather，默认开启）。
-- 打开拾取窗口时，拾取来源是采集物件（按 Data/GatheringNodes.lua 的物件 ID 认；数据里没有的物件，
-- 拾取里有草药 / 矿石物品也算，Forever 新增的采集点由此补上）就记下玩家当前的地图与坐标——
-- 采集时玩家就站在采集点旁边。拾取里有任务物品（任务要求去挖的矿、采的草，物品类别是任务物品，不是普通草药或矿石）
-- 的不记：那是任务物件，不是常驻的采集点。存在账号存档 WowHandbookDB.gathered[地图] = { {x, y, 种类序号, 次数, 时间} }。
-- 误差：离已有的点（自带数据或自己记过的，同一类）5 码以内（Module.SameSpot，按地图实际尺寸换算）就记在
-- 那个点的坐标上，同一种累加次数，不另记一个点。只记游戏数据，不记角色名等个人信息。
--
-- 显示：Module.GatherSpots 把自带数据与自己的记录合并。记录落在已有的点上，该点提示多一行“你在这里采过 N 次”；
-- 自带数据没有的位置单独画一个点。
local Module = ns.modules.WorldMap


local function Settings()
    return ns:GetModuleSettings(Module)
end

-- 物件 ID -> 种类序号，物品 ID -> 种类序号（按需建一次；同一物品取所需技能最低的一种）
local byObject, byItem
local function Index()
    if not byObject then
        byObject, byItem = {}, {}
        for index, node in ipairs(ns.Data.gathering and ns.Data.gathering.nodes or {}) do
            for _, objectID in ipairs(node.objects or {}) do
                byObject[objectID] = index
            end
            local known = byItem[node.item]
            if not known or ns.Data.gathering.nodes[known].skill > node.skill then
                byItem[node.item] = index
            end
        end
    end
    return byObject, byItem
end

local function Records(mapID)
    ns.db.gathered = ns.db.gathered or {}
    ns.db.gathered[mapID] = ns.db.gathered[mapID] or {}
    return ns.db.gathered[mapID]
end

-- 误差范围内已有的点：先看自带数据里同一类（草药 / 矿）的点，再看自己记过的同一类的点；返回它的坐标
local function Anchor(mapID, x, y, kind)
    local nodes = ns.Data.gathering and ns.Data.gathering.nodes or {}
    local data = ns.Data.gathering and ns.Data.gathering.maps[mapID]
    for _, spot in ipairs(data and data[kind] or {}) do
        if Module.SameSpot(mapID, spot[1], spot[2], x, y) then
            return spot[1], spot[2]
        end
    end
    for _, record in ipairs(Records(mapID)) do
        local node = nodes[record[3]]
        if node and node.kind == kind and Module.SameSpot(mapID, record[1], record[2], x, y) then
            return record[1], record[2]
        end
    end
end

-- 记一次采集；返回是否记下。玩家站的位置和采集点有几码误差：离已有的点（自带数据或自己记过的，同一类）
-- 在 5 码以内就记在那个点上，不另记一个点；同一种再采只累加次数
local function Record(mapID, x, y, node)
    local records = Records(mapID)
    local info = ns.Data.gathering and ns.Data.gathering.nodes[node]
    local ax, ay = Anchor(mapID, x, y, info and info.kind)
    if ax then
        x, y = ax, ay
    else
        x, y = math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10
    end
    for _, record in ipairs(records) do
        if record[3] == node and record[1] == x and record[2] == y then
            record[4] = (record[4] or 1) + 1
            record[5] = time()
            return true
        end
    end
    tinsert(records, { x, y, node, 1, time() })
    return true
end
Module.RecordGather = Record -- 供测试使用

-- 拾取来源的物件 ID；来源不是物件或取不到（加密的秘密值等）返回 nil
local function LootObjectID()
    local guid = GetLootSourceInfo and GetLootSourceInfo(1)
    if type(guid) ~= "string" or ns.IsSecret(guid) then
        return nil
    end
    return tonumber(guid:match("^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
end

-- 按拾取里的物品认种类（数据里没有这个物件时用）
local function NodeFromLoot()
    local _, itemIndex = Index()
    for slot = 1, (GetNumLootItems and GetNumLootItems() or 0) do
        local link = GetLootSlotLink(slot)
        local itemID = type(link) == "string" and not ns.IsSecret(link) and tonumber(link:match("item:(%d+)"))
        if itemID and itemIndex[itemID] then
            return itemIndex[itemID]
        end
    end
end

-- 拾取里有没有任务物品：拾取格子标了任务物品，或物品类别是任务物品（classID 12）
local QUEST_ITEM_CLASS = 12
local function HasQuestItem()
    for slot = 1, (GetNumLootItems and GetNumLootItems() or 0) do
        local isQuestItem = GetLootSlotInfo and select(7, GetLootSlotInfo(slot))
        if isQuestItem and not ns.IsSecret(isQuestItem) then
            return true
        end
        local link = GetLootSlotLink(slot)
        local itemID = type(link) == "string" and not ns.IsSecret(link) and tonumber(link:match("item:(%d+)"))
        local classID = itemID and C_Item and C_Item.GetItemInfoInstant and select(6, C_Item.GetItemInfoInstant(itemID))
        if classID == QUEST_ITEM_CLASS then
            return true
        end
    end
    return false
end

local function OnLootOpened()
    if Settings().recordGather == false or (IsInInstance and IsInInstance()) then
        return
    end
    local objectID = LootObjectID()
    if not objectID or HasQuestItem() then
        return
    end
    local objectIndex = Index()
    local node = objectIndex[objectID] or NodeFromLoot()
    local mapID = node and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        return
    end
    local x, y = position:GetXY()
    Record(mapID, x * 100, y * 100, node)
    -- 地图开着就刷新（Module:Refresh 同时更新小地图），否则只更新小地图
    if WorldMapFrame and WorldMapFrame:IsShown() then
        Module:Refresh()
    elseif Module.RebuildMinimapGather then
        Module.RebuildMinimapGather()
    end
end
Module.OnGatherLoot = OnLootOpened -- 供测试使用

-- 某张地图某一类（herb / ore）要画的点：自带数据的点在前，自己记录里不在已有点上的追加在后。
-- 返回 spots（每个是 {x, y, 种类序号…}）与 mine（点 -> 自己采过的次数）
function Module.GatherSpots(mapID, kind)
    local nodes = ns.Data.gathering and ns.Data.gathering.nodes or {}
    local data = ns.Data.gathering and ns.Data.gathering.maps[mapID]
    local spots, mine = {}, {}
    for _, spot in ipairs(data and data[kind] or {}) do
        tinsert(spots, spot)
    end
    local own = {} -- 只因自己的记录才画的点：记录里的种类可以补进去
    for _, record in ipairs(ns.db.gathered and ns.db.gathered[mapID] or {}) do
        local node = nodes[record[3]]
        if node and node.kind == kind then
            local found
            for _, spot in ipairs(spots) do
                if Module.SameSpot(mapID, spot[1], spot[2], record[1], record[2]) then
                    found = spot
                    break
                end
            end
            if not found then
                found = { record[1], record[2] }
                own[found] = true
                tinsert(spots, found)
            end
            if own[found] then
                local listed = false
                for index = 3, #found do
                    listed = listed or found[index] == record[3]
                end
                if not listed then
                    tinsert(found, record[3])
                end
            end
            mine[found] = (mine[found] or 0) + (record[4] or 1)
        end
    end
    return spots, mine
end

function Module.StartGatherLog()
    ns:RegisterEvent("LOOT_OPENED", OnLootOpened)
end
