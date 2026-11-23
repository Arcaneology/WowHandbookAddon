local ADDON_NAME, ns = ...
local L = ns.L

-- 物品价格库：拍卖行价格（玩家搜索与全量扫描时记下的最低一口价单价）与商人售价。
-- 拍卖行价格的存档格式与 Auctionator 的价格库（AUCTIONATOR_PRICE_DATABASE，未序列化的第 6 版）一致：
--   ns.db.auctionPrices = { __dbversion = 6, ["服务器 阵营"] = { ["物品 ID"] = 价格记录 } }
--   价格记录 = { m = 最近一次看到的最低单价（铜）,
--                h = { ["天"] = 当天看到的最低单价里最高的一次 },
--                l = { ["天"] = 当天最低单价里最低的一次（与 h 相同时不存）},
--                a = { ["天"] = 当天看到的最多在售数量 },
--                r = { ["天"] = 当天看到的原始最低单价，只在它被当成诱饵低价滤掉时才存 } }（r 是本插件加的，Auctionator 不读）
--   “天”是 2020-01-01 0 点（本地时间）起的天数，写成字符串。
-- 拍卖行分开存：阵营拍卖行的键是“服务器 Alliance / Horde”（与 Auctionator 旧版拍卖行的键相同），
-- 中立拍卖行（藏宝海湾、加基森、永望镇等地精拍卖行，两个阵营共用）的键是“服务器 Neutral”。
-- 打开拍卖行时由拍卖行模块判断是哪一种（Prices.SetAuctionHouse），这期间记下的价格写进那个拍卖行；
-- 制作成本、冲级路线等读的 Prices.Auction 只用本阵营拍卖行，中立拍卖行另由 Prices.Neutral 读。
-- 按天记录保留多久由玩家设置（ns.db.auctionHistoryDays，默认 30 天），超过就滚动删掉；
-- 每件物品至少留最近有记录的一天，免得很久没在售的物品连最后一次价格都丢了。
-- 全量扫描时间另存在 ns.db.auctionScans；做过全量扫描的日子存在 ns.db.auctionScanDays[键] = { ["天"] = true }
-- （估算流通率时据此区分“这天没在售”与“这天没扫描”）。
-- 阶梯价（买得多时逐档往上吃，冲级路线算材料花费用）另存，不放进上面那张与 Auctionator 同构的表：
--   ns.db.auctionDepth = { ["服务器 阵营"] = { [物品 ID] = { 天, 单价 1, 数量 1, 单价 2, 数量 2, ... } } }
--   单价从低到高，最多 DEPTH_LEVELS 档；只有一档时不存（最低单价与在售数量已在价格记录里）。
-- 诱饵低价：有人把少量货挂得远低于行情（例如行情 5 银挂 1 银），引别人跟着低价挂单再捡漏。
-- 自己扫描与搜索记价时（RecordAuction 带 filter）用 Prices.FilterBait 识别并跳过这类挂单，
-- 记下的最低价是滤掉诱饵后的价格，原始最低价另存在 r 里；Auctionator 的价格原样使用，不做过滤。
-- 商人售价全账号共用：ns.db.vendorPrices[itemID] = 单价。
-- 物品名：全量扫描读到的挂单自带名字，搜索时客户端通常也已拿到名字，都顺手记下来长期保存，
-- 下次扫描或搜索到同一物品时用新名字覆盖：ns.db.auctionNames = { [客户端语言] = { [物品 ID] = 名字 } }。
-- 名字仍然来自客户端，只是存起来，不用每次都等客户端物品缓存（几千个物品时缓存会把先到的名字挤掉）。
-- 装了 Auctionator 时自动通过它的公开接口（Auctionator.API.v1）读它记下的价格，不用另开开关：
-- 自己没有记录的物品用它的，两边都有时取更新的一份。
-- 价格在客户端里拿不到，只能由玩家看到时记下来；不联网、不上传。
local Prices = {}
ns.Prices = Prices

local DB_VERSION = 6        -- Auctionator 未序列化价格库的版本号，表结构与之相同
local DEFAULT_HISTORY_DAYS = 30
local MIN_HISTORY_DAYS, MAX_HISTORY_DAYS = 1, 365
local DEPTH_LEVELS = 6      -- 阶梯价最多存几档（最便宜的几档）
local DEPTH_DAYS = 3        -- 阶梯价超过这么多天就不再使用（挂单变化快）
local FULL_SCAN_SIZE = 1000 -- 一批写入超过这么多件物品视为全量扫描，顺带清掉过期的阶梯价
local PRUNE_CHUNK = 2000    -- 滚动清理时每帧处理的物品数
local PRUNE_DELAY = 20      -- 登录后多久做一次滚动清理

-- 诱饵低价的判断（Prices.FilterBait）
local BAIT_SHARE = 0.15     -- 最便宜的这一截数量占全部在售的比例不超过它才可能是诱饵
local BAIT_GAP = 0.6        -- 诱饵价低于紧接着的正常价的这个比例（1 银对 5 银是 0.2）才算断档
local HISTORY_OK = 0.75     -- 低价不低于近几天行情的这个比例时，认为是正常降价，不滤
local SUSPICIOUS = 0.4      -- 只看到一个价位时，低于近几天行情的这个比例就当诱饵
local REFERENCE_DAYS = 7    -- 行情取之前这么多天的每日价格的中位数

local dayZero -- 2020-01-01 0 点（本地时间），第一次用到时再算
local CALLER_ID = ADDON_NAME -- 调用 Auctionator 接口时报的名字

local listeners = {}
local currentKind -- "neutral"：当前打开的是中立拍卖行；nil：阵营拍卖行或没打开

local function DayOf(when)
    dayZero = dayZero or time({ year = 2020, month = 1, day = 1, hour = 0 })
    return floor((when - dayZero) / 86400)
end

local function Today()
    return DayOf(time())
end

-- 某一天 0 点的时间（给走势图标日期）
function Prices.DayTime(day)
    dayZero = dayZero or time({ year = 2020, month = 1, day = 1, hour = 0 })
    return dayZero + day * 86400
end

function Prices.Today()
    return Today()
end

-- 拍卖行的键。无限版没有传统服务器：同一地区按四个规则集（普通、PvP、角色扮演等）
-- 各有一个拍卖行，阵营分开；客户端报告的“服务器名”就是所在规则集共用的那个（同一规则集的角色都在它下面），
-- 所以按“服务器名 阵营”分存即按“规则集 阵营”分存。中立拍卖行两个阵营共用，键是“服务器名 Neutral”。
-- 服务器名在登录后才取得到
local function Realm()
    return (GetRealmName and GetRealmName()) or "?"
end

local function FactionKey()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return Realm() .. " " .. (faction or "Neutral")
end

local function NeutralKey()
    return Realm() .. " Neutral"
end

local function KeyFor(kind)
    return kind == "neutral" and NeutralKey() or FactionKey()
end

-- 当前打开的拍卖行：kind 为 "neutral" 或 "faction"（关闭拍卖行时传 nil，回到阵营拍卖行）
function Prices.SetAuctionHouse(kind)
    currentKind = kind == "neutral" and "neutral" or nil
end

function Prices.AuctionHouseKind()
    return currentKind or "faction"
end

-- 旧格式（{ [服务器-阵营] = { prices = { [itemID] = { 单价, 时间 } }, lastScan } }）只在测试客户端出现过，
-- 第一次用到时转成新格式再删掉
local function Migrate(db)
    local old = db.auction
    db.auction = nil
    if type(old) ~= "table" then
        return
    end
    for oldKey, market in pairs(old) do
        if type(market) == "table" then
            local key = tostring(oldKey):gsub("%-([^%-]+)$", " %1")
            local prices = db.auctionPrices[key] or {}
            db.auctionPrices[key] = prices
            for itemID, entry in pairs(market.prices or {}) do
                if type(entry) == "table" and type(entry[1]) == "number" then
                    local day = tostring(DayOf(entry[2] or time()))
                    prices[tostring(itemID)] = prices[tostring(itemID)]
                        or { m = entry[1], h = { [day] = entry[1] }, l = {}, a = {} }
                end
            end
            if market.lastScan and not db.auctionScans[key] then
                db.auctionScans[key] = market.lastScan
            end
        end
    end
end

local function Database()
    local db = ns.db
    if not db then
        return nil
    end
    -- 价格库可能已按同一格式建好（同格式的数据可以直接放进来），旧存档照样转换
    db.auctionPrices = db.auctionPrices or { __dbversion = DB_VERSION }
    db.auctionScans = db.auctionScans or {}
    db.auctionScanDays = db.auctionScanDays or {}
    if db.auction then
        Migrate(db)
    end
    return db.auctionPrices
end

local function MarketByKey(key, create)
    local database = Database()
    if not database then
        return nil
    end
    local market = database[key]
    if not market and create then
        market = {}
        database[key] = market
    end
    return market
end

local function Market(create)
    return MarketByKey(KeyFor(currentKind), create)
end

-- 价格有变化时通知（鼠标提示、制作页刷新）；batch 为本次写入的物品数
function Prices.OnChange(listener)
    tinsert(listeners, listener)
end

local function Notify(count)
    for _, listener in ipairs(listeners) do
        listener(count)
    end
end

--------------------------------------------------------------------------------
-- 保留期与滚动清理
--------------------------------------------------------------------------------

-- 按天记录保留的天数（玩家在设置里选 7 / 30 / 180 天或自定义）
function Prices.HistoryDays()
    local days = ns.db and tonumber(ns.db.auctionHistoryDays)
    if not days then
        return DEFAULT_HISTORY_DAYS
    end
    return math.min(MAX_HISTORY_DAYS, math.max(MIN_HISTORY_DAYS, floor(days)))
end

function Prices.HistoryLimits()
    return MIN_HISTORY_DAYS, MAX_HISTORY_DAYS, DEFAULT_HISTORY_DAYS
end

local function Prune(days, cutoff, keep)
    if type(days) ~= "table" then
        return
    end
    for key in pairs(days) do
        local day = tonumber(key)
        if not day or (day <= cutoff and key ~= keep) then
            days[key] = nil
        end
    end
end

local function LatestDayKey(entry)
    local latest, latestKey
    for key in pairs(entry.h or {}) do
        local day = tonumber(key)
        if day and (not latest or day > latest) then
            latest, latestKey = day, key
        end
    end
    return latestKey, latest
end

-- 删掉超过保留期的按天记录，留下最近有记录的一天
local function PruneEntry(entry, cutoff)
    local keep = LatestDayKey(entry)
    Prune(entry.h, cutoff, keep)
    Prune(entry.l, cutoff, keep)
    Prune(entry.a, cutoff, keep)
    Prune(entry.r, cutoff, keep)
    if entry.r and not next(entry.r) then
        entry.r = nil
    end
end

local pruning, pruneAgain = false, false

-- 全部拍卖行一起滚动清理：分帧处理，战斗中暂停。done 在清理完后调用（可省略）。
-- 清理进行中又被要求清理（例如在设置里连续拖短保留期）时，这一轮结束后按新的保留期再清一轮
function Prices.PruneAll(done)
    local database = Database()
    if not database then
        return
    end
    if pruning then
        pruneAgain = true
        return
    end
    pruning = true
    local cutoff = Today() - Prices.HistoryDays()
    local queue = {}
    for key, market in pairs(database) do
        if type(market) == "table" then
            for _, entry in pairs(market) do
                if type(entry) == "table" then
                    tinsert(queue, entry)
                end
            end
            local scanDays = ns.db.auctionScanDays[key]
            if type(scanDays) == "table" then
                Prune(scanDays, cutoff)
            end
        end
    end
    local index = 1
    local function Step()
        if InCombatLockdown and InCombatLockdown() then
            C_Timer.After(1, Step)
            return
        end
        local last = math.min(index + PRUNE_CHUNK - 1, #queue)
        for i = index, last do
            PruneEntry(queue[i], cutoff)
        end
        index = last + 1
        if index <= #queue then
            C_Timer.After(0, Step)
            return
        end
        pruning = false
        if pruneAgain then
            pruneAgain = false
            Prices.PruneAll(done)
        elseif done then
            done()
        end
    end
    Step()
end

-- 改保留期（设置页）；缩短时立即滚动清理一次
function Prices.SetHistoryDays(days)
    if not ns.db then
        return
    end
    local old = Prices.HistoryDays()
    ns.db.auctionHistoryDays = math.min(MAX_HISTORY_DAYS, math.max(MIN_HISTORY_DAYS, floor(tonumber(days) or DEFAULT_HISTORY_DAYS)))
    if Prices.HistoryDays() < old then
        Prices.PruneAll()
    end
end

--------------------------------------------------------------------------------
-- 诱饵低价
--------------------------------------------------------------------------------

-- 近几天（不含今天）的行情：每日价格（h）的中位数；不足一天的记录时为 nil
local function Reference(entry, today)
    local values = {}
    for key, price in pairs(entry and entry.h or {}) do
        local day = tonumber(key)
        if day and day < today and day >= today - REFERENCE_DAYS and type(price) == "number" and price > 0 then
            tinsert(values, price)
        end
    end
    if #values == 0 then
        return nil
    end
    table.sort(values)
    local middle = (#values + 1) / 2
    return (values[floor(middle)] + values[math.ceil(middle)]) / 2
end

-- 识别诱饵低价。buckets = { [单价] = 数量 }（可省略，只知道最低价 lowest 时传 nil），reference 为近几天行情（可省略）。
-- 规则：
--   1. 按单价从低到高看，最便宜的一截数量合计不超过在售的 BAIT_SHARE（至少允许 1 件），
--      且这一截里最贵的一档也低于下一档的 BAIT_GAP，就认为这一截是诱饵，跳过；
--   2. 有近几天行情时，这一截不低于行情的 HISTORY_OK 就当作正常降价，不跳过；
--   3. 只有一个价位（或只知道最低价）时没法比挂单，只和行情比：低于行情的 SUSPICIOUS 就当诱饵。
-- 返回：可信最低价（整个都可疑时为 nil）、原始最低价、被跳过的数量
function Prices.FilterBait(buckets, lowest, reference)
    local levels = {}
    for price, quantity in pairs(buckets or {}) do
        if type(price) == "number" and price > 0 and type(quantity) == "number" and quantity > 0 then
            tinsert(levels, { price, quantity })
        end
    end
    table.sort(levels, function(a, b) return a[1] < b[1] end)
    if #levels == 0 and type(lowest) == "number" and lowest > 0 then
        levels[1] = { lowest, 1 }
    end
    if #levels == 0 then
        return nil
    end
    local raw = levels[1][1]
    if #levels == 1 then
        if reference and raw < SUSPICIOUS * reference then
            return nil, raw, levels[1][2]
        end
        return raw, raw, 0
    end
    local total = 0
    for _, level in ipairs(levels) do
        total = total + level[2]
    end
    local limit = math.max(1, total * BAIT_SHARE)
    local cut, cumulative = 0, 0
    for index = 1, #levels - 1 do
        cumulative = cumulative + levels[index][2]
        if cumulative > limit then
            break
        end
        if levels[index][1] < BAIT_GAP * levels[index + 1][1] then
            cut = index
        end
    end
    if cut > 0 and reference and levels[cut][1] >= HISTORY_OK * reference then
        cut = 0
    end
    local skipped = 0
    for index = 1, cut do
        skipped = skipped + levels[index][2]
    end
    return levels[cut + 1][1], raw, skipped
end

--------------------------------------------------------------------------------
-- 写入
--------------------------------------------------------------------------------

local function NewEntry(market, key)
    local entry = { l = {}, h = {}, a = {}, m = 0 }
    market[key] = entry
    return entry
end

-- 记一条价格（与 Auctionator 的 SetPrice 规则相同）；raw 为滤掉诱饵前的原始最低价（比 price 低时另存）
local function SetPrice(market, itemID, price, available, today, raw)
    local key = tostring(itemID)
    local entry = market[key] or NewEntry(market, key)
    entry.h, entry.l = entry.h or {}, entry.l or {}
    local day = tostring(today)
    if price then
        entry.m = price
        local highestLow = entry.h[day]
        if highestLow == nil or price > highestLow then
            entry.h[day] = price
            highestLow = price
        end
        local lowestLow = entry.l[day]
        if price < highestLow and (lowestLow == nil or price < lowestLow) then
            entry.l[day] = price
        end
    end
    if raw and (not price or raw < price) then
        entry.r = entry.r or {}
        entry.r[day] = math.min(entry.r[day] or raw, raw)
    end
    if available then
        entry.a = entry.a or {}
        entry.a[day] = math.max(entry.a[day] or 0, available)
    end
    PruneEntry(entry, today - Prices.HistoryDays())
end

local function DepthMarket(create, kind)
    if not Database() then
        return nil
    end
    local db = ns.db
    db.auctionDepth = db.auctionDepth or {}
    local key = KeyFor(kind)
    local market = db.auctionDepth[key]
    if not market and create then
        market = {}
        db.auctionDepth[key] = market
    end
    return market
end

-- 把 { [单价] = 数量 } 整理成 { 天, 单价, 数量, ... }（单价从低到高，最多 DEPTH_LEVELS 档）；不足两档时返回 nil
local function DepthRecord(buckets, today)
    local prices = {}
    for price, quantity in pairs(buckets) do
        if type(price) == "number" and price > 0 and type(quantity) == "number" and quantity > 0 then
            tinsert(prices, price)
        end
    end
    if #prices < 2 then
        return nil
    end
    table.sort(prices)
    local record = { today }
    for index = 1, math.min(#prices, DEPTH_LEVELS) do
        tinsert(record, floor(prices[index] + 0.5))
        tinsert(record, buckets[prices[index]])
    end
    return record
end

-- 写入一批拍卖行价格（写进当前打开的拍卖行：中立或本阵营）：{ [itemID] = 单价 }、{ [itemID] = { 单价, 在售数量 } }
-- 或 { [itemID] = { 单价, 在售数量, { [单价] = 数量 } } }（第三项是各价位的在售数量，存成阶梯价）。
-- options.filter 为真时滤掉诱饵低价（自己扫描与搜索记价时用）；options.fullScan 为真时记下今天做过全量扫描。
-- 返回写入的物品数与滤掉诱饵的物品数
function Prices.RecordAuction(batch, options)
    local market = Market(true)
    if not market then
        return 0, 0
    end
    options = options or {}
    local today = Today()
    local count, baited = 0, 0
    local depth
    for itemID, value in pairs(batch) do
        local price, available, buckets = value, nil, nil
        if type(value) == "table" then
            price, available, buckets = value[1], value[2], value[3]
        end
        if type(itemID) == "number" and type(price) == "number" and price > 0 then
            price = floor(price + 0.5)
            local trusted, raw = price, nil
            if options.filter then
                local effective, lowest, skipped = Prices.FilterBait(buckets, price,
                    Reference(market[tostring(itemID)], today))
                if skipped and skipped > 0 then
                    trusted, raw = effective and floor(effective + 0.5), lowest and floor(lowest + 0.5)
                    baited = baited + 1
                end
            end
            SetPrice(market, itemID, trusted, available, today, raw)
            count = count + 1
            if type(buckets) == "table" then
                depth = depth or DepthMarket(true, currentKind)
                depth[itemID] = DepthRecord(buckets, today)
            end
        end
    end
    if depth and count > FULL_SCAN_SIZE then
        for itemID, record in pairs(depth) do
            if type(record) ~= "table" or (record[1] or 0) < today - DEPTH_DAYS then
                depth[itemID] = nil
            end
        end
    end
    if options.fullScan and count > 0 then
        local key = KeyFor(currentKind)
        ns.db.auctionScanDays[key] = ns.db.auctionScanDays[key] or {}
        ns.db.auctionScanDays[key][tostring(today)] = true
    end
    if count > 0 then
        Notify(count)
    end
    return count, baited
end

--------------------------------------------------------------------------------
-- 读取
--------------------------------------------------------------------------------

local function EntryOf(itemID, kind)
    local market = MarketByKey(KeyFor(kind), false)
    return market and market[tostring(itemID)]
end

-- 自己记下的价格与距今天数（最近一次有记录的那天）
local function OwnPrice(itemID, kind)
    local entry = EntryOf(itemID, kind)
    if not (entry and type(entry.m) == "number" and entry.m > 0) then
        return nil
    end
    local _, latest = LatestDayKey(entry)
    return entry.m, latest and math.max(0, Today() - latest) or nil
end

-- 自己记下的价格（不含 Auctionator）：kind 为 "faction"（默认）或 "neutral"
function Prices.Own(itemID, kind)
    if type(itemID) ~= "number" then
        return nil
    end
    return OwnPrice(itemID, kind)
end

-- 中立拍卖行的价格与距今天数；没有记录时返回 nil
function Prices.Neutral(itemID)
    return Prices.Own(itemID, "neutral")
end

local function Plain(value)
    return type(value) == "number" and not (ns.IsSecret and ns.IsSecret(value))
end

-- Auctionator 记下的价格与距今天数（它只给 21 天内的天数，更久或没有时为 nil）
local function AuctionatorPrice(itemID)
    local api = type(Auctionator) == "table" and type(Auctionator.API) == "table" and Auctionator.API.v1
    if type(api) ~= "table" or type(api.GetAuctionPriceByItemID) ~= "function" then
        return nil
    end
    local ok, price = pcall(api.GetAuctionPriceByItemID, CALLER_ID, itemID)
    if not (ok and Plain(price) and price > 0) then
        return nil
    end
    local age
    if type(api.GetAuctionAgeByItemID) == "function" then
        local okAge, days = pcall(api.GetAuctionAgeByItemID, CALLER_ID, itemID)
        if okAge and Plain(days) then
            age = days
        end
    end
    return floor(price + 0.5), age
end

-- 本阵营拍卖行单价、距今天数（0 = 今天，nil = 不知道）与来源（"own" / "auctionator"）；没有记录时返回 nil。
-- 自己没有记录时用 Auctionator 的；两边都有时取天数更少的，一样新时用自己的
function Prices.Auction(itemID)
    if type(itemID) ~= "number" then
        return nil
    end
    local own, ownAge = OwnPrice(itemID)
    local other, otherAge = AuctionatorPrice(itemID)
    if other and (not own or (otherAge or math.huge) < (ownAge or math.huge)) then
        return other, otherAge, "auctionator"
    end
    if own then
        return own, ownAge, "own"
    end
    return nil
end

-- 只读 Auctionator 的价格（“扫描交给 Auctionator”时鼠标提示用）
function Prices.Auctionator(itemID)
    if type(itemID) ~= "number" then
        return nil
    end
    return AuctionatorPrice(itemID)
end

-- 自己记下的在售数量（最近一次有记录的那天看到的最多数量）；没有记录时返回 nil
function Prices.Available(itemID, kind)
    local entry = EntryOf(itemID, kind)
    local latest, quantity
    for key, value in pairs(entry and entry.a or {}) do
        local day = tonumber(key)
        if day and (not latest or day > latest) then
            latest, quantity = day, value
        end
    end
    return quantity
end

-- 最近一天有没有滤掉诱饵低价：返回那天的原始最低价（没有滤掉时为 nil）
function Prices.BaitPrice(itemID, kind)
    local entry = EntryOf(itemID, kind)
    if not (entry and entry.r) then
        return nil
    end
    local latestKey = LatestDayKey(entry)
    local raw = latestKey and entry.r[latestKey]
    if raw then
        return raw
    end
    -- 当天整个都可疑时没有 h，只有 r：取 r 里最近的一天，且要比 h 的最近一天新
    local _, latest = LatestDayKey(entry)
    local rawDay, rawPrice
    for key, value in pairs(entry.r) do
        local day = tonumber(key)
        if day and (not rawDay or day > rawDay) then
            rawDay, rawPrice = day, value
        end
    end
    if rawDay and (not latest or rawDay > latest) then
        return rawPrice
    end
    return nil
end

-- 走势：{ { day = 天, price = 当天价格（h）, low = 当天最低（l，没有时同 price）, raw = 诱饵价, quantity = 在售数量 }, ... }，
-- 按天从早到晚；kind 为 "faction" 或 "neutral"
function Prices.History(itemID, kind)
    local entry = EntryOf(itemID, kind)
    local points = {}
    if not entry then
        return points
    end
    for key, price in pairs(entry.h or {}) do
        local day = tonumber(key)
        if day and type(price) == "number" then
            tinsert(points, { day = day, price = price, low = (entry.l and entry.l[key]) or price,
                raw = entry.r and entry.r[key], quantity = entry.a and entry.a[key] })
        end
    end
    table.sort(points, function(a, b) return a.day < b.day end)
    return points
end

-- 某个拍卖行记过价格的全部物品 ID
function Prices.ItemIDs(kind)
    local market = MarketByKey(KeyFor(kind), false)
    local ids = {}
    for key, entry in pairs(market or {}) do
        local itemID = tonumber(key)
        if itemID and type(entry) == "table" then
            tinsert(ids, itemID)
        end
    end
    return ids
end

-- 做过全量扫描的日子（从早到晚）
function Prices.ScanDays(kind)
    if not Database() then
        return {}
    end
    local days = {}
    for key in pairs(ns.db.auctionScanDays[KeyFor(kind)] or {}) do
        local day = tonumber(key)
        if day then
            tinsert(days, day)
        end
    end
    table.sort(days)
    return days
end

-- 流通率（估算）：只看最近 window 天里做过全量扫描的日子。
--   turnover = 相邻两次扫描之间在售数量的变化占较多一方的比例的平均（卖掉与新挂上的都算，越高说明换手越快）；
--   presence = 这些日子里有在售的比例。
-- 拍卖数据里看不到成交，这是从在售数量的变化推出来的；扫描不足两天时 turnover 为 nil。
-- 返回 turnover、presence、有在售的天数、扫描的天数
function Prices.Liquidity(itemID, kind, window)
    local entry = EntryOf(itemID, kind)
    local today = Today()
    window = window or 14
    local days = {}
    for _, day in ipairs(Prices.ScanDays(kind)) do
        if day > today - window then
            tinsert(days, day)
        end
    end
    if #days == 0 then
        return nil, nil, 0, 0
    end
    local quantities, listed = {}, 0
    for index, day in ipairs(days) do
        local key = tostring(day)
        local quantity = 0
        if entry and entry.h and entry.h[key] then
            quantity = (entry.a and entry.a[key]) or 1
        elseif entry and entry.r and entry.r[key] then
            quantity = (entry.a and entry.a[key]) or 1
        end
        quantities[index] = quantity
        if quantity > 0 then
            listed = listed + 1
        end
    end
    local sum, pairsCount = 0, 0
    for index = 2, #quantities do
        local before, after = quantities[index - 1], quantities[index]
        local larger = math.max(before, after)
        if larger > 0 then
            sum = sum + math.abs(after - before) / larger
            pairsCount = pairsCount + 1
        end
    end
    local turnover = pairsCount > 0 and sum / pairsCount or nil
    return turnover, listed / #days, listed, #days
end

-- 阶梯价：{ { 单价, 数量 }, ... }（单价从低到高）。没有近 DEPTH_DAYS 天内的阶梯记录时，
-- 退回“最低单价 × 在售数量”这一档；连在售数量也没有时返回 nil（只知道最低价）
function Prices.Depth(itemID)
    local depth = DepthMarket(false)
    local record = depth and depth[itemID]
    if type(record) == "table" and (record[1] or 0) >= Today() - DEPTH_DAYS then
        local levels = {}
        for index = 2, #record - 1, 2 do
            tinsert(levels, { record[index], record[index + 1] })
        end
        if #levels > 0 then
            return levels
        end
    end
    local own = OwnPrice(itemID)
    local available = own and Prices.Available(itemID)
    if available and available > 0 then
        return { { own, available } }
    end
    return nil
end

-- 价格来源变了时通知界面重算
function Prices.NotifyChanged()
    Notify(0)
end

-- 是否装了 Auctionator（拍卖行模块据此决定扫描交给谁）
function Prices.AuctionatorLoaded()
    return type(Auctionator) == "table" and type(Auctionator.API) == "table"
        and type(Auctionator.API.v1) == "table" or false
end

function Prices.RecordVendor(itemID, price)
    if not (ns.db and itemID and price and price > 0) then
        return
    end
    ns.db.vendorPrices = ns.db.vendorPrices or {}
    ns.db.vendorPrices[itemID] = price
end

-- 记下物品名：names[itemID] = 名字；返回新记或改了的个数
local function NameTable(create)
    if not ns.db then
        return nil
    end
    local locale = ns.clientLocale or "enUS"
    if create then
        ns.db.auctionNames = ns.db.auctionNames or {}
        ns.db.auctionNames[locale] = ns.db.auctionNames[locale] or {}
    end
    return ns.db.auctionNames and ns.db.auctionNames[locale]
end

function Prices.RecordNames(names)
    local store = NameTable(true)
    local changed = 0
    if not store then
        return changed
    end
    for itemID, name in pairs(names or {}) do
        if Plain(itemID) and type(name) == "string" and name ~= "" and store[itemID] ~= name then
            store[itemID] = name
            changed = changed + 1
        end
    end
    return changed
end

-- 拍卖行扫描或搜索时记下的物品名（当前客户端语言），没记过返回 nil
function Prices.ItemName(itemID)
    local store = NameTable(false)
    return store and itemID and store[itemID] or nil
end

function Prices.Vendor(itemID)
    local vendor = ns.db and ns.db.vendorPrices
    return vendor and itemID and vendor[itemID] or nil
end

-- 买一个这件物品最少要多少钱：商人售价与拍卖行单价取低者。返回单价与来源（"vendor" / "auction"）
function Prices.BuyCost(itemID)
    local vendor = Prices.Vendor(itemID)
    local auction = Prices.Auction(itemID)
    if vendor and (not auction or vendor <= auction) then
        return vendor, "vendor"
    end
    if auction then
        return auction, "auction"
    end
    return nil
end

-- 全量扫描时间（每个拍卖行一份，按当前打开的拍卖行；服务器限制全量扫描的频率）
function Prices.LastScan(kind)
    if not Database() then
        return nil
    end
    return ns.db.auctionScans[KeyFor(kind or currentKind)]
end

function Prices.SetLastScan(when)
    if Database() then
        ns.db.auctionScans[KeyFor(currentKind)] = when
    end
end

-- 记过价格的物品数（当前拍卖行，或指定 kind）
function Prices.Count(kind)
    local market = MarketByKey(KeyFor(kind or currentKind), false)
    local count = 0
    for key in pairs(market or {}) do
        if key ~= "__dbversion" then
            count = count + 1
        end
    end
    return count
end

-- 多久以前：不足 1 小时按分钟，不足 2 天按小时，再久按天
function Prices.FormatAge(seconds)
    seconds = math.max(0, seconds or 0)
    if seconds < 3600 then
        return (L["%d min"]):format(math.max(1, floor(seconds / 60)))
    elseif seconds < 2 * 86400 then
        return (L["%d hr"]):format(floor(seconds / 3600))
    end
    return (L["%d days"]):format(floor(seconds / 86400))
end

-- 等了多久：不足 1 分钟按秒，否则按分秒
function Prices.FormatSeconds(seconds)
    seconds = math.max(0, floor(seconds or 0))
    if seconds < 60 then
        return (L["%d s"]):format(seconds)
    end
    return (L["%d min %d s"]):format(floor(seconds / 60), seconds % 60)
end

-- 价格记录的新旧，给鼠标提示用：今天 / N 天前 / 不知道
function Prices.FormatDays(days)
    if not days then
        return L["date unknown"]
    elseif days == 0 then
        return L["today"]
    end
    return (L["%d days ago"]):format(days)
end

-- 给玩家看的拍卖行名字：规则集（客户端报告的服务器名）与阵营（中立拍卖行写“中立”）
function Prices.MarketLabel(kind)
    kind = kind or Prices.AuctionHouseKind()
    if kind == "neutral" then
        return ("%s · %s"):format(Realm(), L["Neutral auction house"])
    end
    local group, localized = UnitFactionGroup("player")
    return ("%s · %s"):format(Realm(), localized or group or "")
end

-- 登录后做一次滚动清理（保留期外的按天记录）
local function OnLogin(event)
    ns:UnregisterEvent(event, OnLogin)
    C_Timer.After(PRUNE_DELAY, function()
        Prices.PruneAll()
    end)
end
ns:RegisterEvent("PLAYER_LOGIN", OnLogin)
