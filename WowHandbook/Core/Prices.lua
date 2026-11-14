local ADDON_NAME, ns = ...
local L = ns.L

-- 物品价格库：拍卖行价格（玩家搜索与全量扫描时记下的最低一口价单价）与商人售价。
-- 拍卖行价格的存档格式与 Auctionator 的价格库（AUCTIONATOR_PRICE_DATABASE，未序列化的第 6 版）一致：
--   ns.db.auctionPrices = { __dbversion = 6, ["服务器 阵营"] = { ["物品 ID"] = 价格记录 } }
--   价格记录 = { m = 最近一次看到的最低单价（铜）,
--                h = { ["天"] = 当天看到的最低单价里最高的一次 },
--                l = { ["天"] = 当天最低单价里最低的一次（与 h 相同时不存）},
--                a = { ["天"] = 当天看到的最多在售数量 } }
--   “天”是 2020-01-01 0 点（本地时间）起的天数，写成字符串；超过 21 天的按天记录删掉。
-- 拍卖行按“服务器 阵营”分开存（与 Auctionator 旧版拍卖行的键相同）。全量扫描时间另存在 ns.db.auctionScans。
-- 商人售价全账号共用：ns.db.vendorPrices[itemID] = 单价。
-- 勾选“使用 Auctionator 价格”且装了 Auctionator 时，还通过它的公开接口（Auctionator.API.v1）读它记下的价格，
-- 两边取更新的一份。
-- 价格在客户端里拿不到，只能由玩家看到时记下来；不联网、不上传。
local Prices = {}
ns.Prices = Prices

local DB_VERSION = 6        -- Auctionator 未序列化价格库的版本号，表结构与之相同
local HISTORY_DAYS = 21     -- 按天记录保留的天数（Auctionator 的默认值）
local dayZero -- 2020-01-01 0 点（本地时间），第一次用到时再算
local CALLER_ID = ADDON_NAME -- 调用 Auctionator 接口时报的名字

local listeners = {}

local function DayOf(when)
    dayZero = dayZero or time({ year = 2020, month = 1, day = 1, hour = 0 })
    return floor((when - dayZero) / 86400)
end

local function Today()
    return DayOf(time())
end

-- 当前角色所在的拍卖行。无限版没有传统服务器：同一地区按四个规则集（普通、PvP、角色扮演等）
-- 各有一个拍卖行，阵营分开；客户端报告的“服务器名”就是所在规则集共用的那个（同一规则集的角色都在它下面），
-- 所以按“服务器名 阵营”分存即按“规则集 阵营”分存。服务器名在登录后才取得到
local function MarketKey()
    local realm = (GetRealmName and GetRealmName()) or "?"
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return realm .. " " .. (faction or "Neutral")
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
    if db.auction then
        Migrate(db)
    end
    return db.auctionPrices
end

local function Market(create)
    local database = Database()
    if not database then
        return nil
    end
    local key = MarketKey()
    local market = database[key]
    if not market and create then
        market = {}
        database[key] = market
    end
    return market
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

local function Prune(days, cutoff)
    for day in pairs(days) do
        if tonumber(day) <= cutoff then
            days[day] = nil
        end
    end
end

-- 记一条价格（与 Auctionator 的 SetPrice 规则相同）
local function SetPrice(market, itemID, price, available, today)
    local key = tostring(itemID)
    local entry = market[key]
    if not entry then
        entry = { l = {}, h = {}, a = {}, m = 0 }
        market[key] = entry
    end
    entry.m = price
    local day = tostring(today)
    local highestLow = entry.h[day]
    if highestLow == nil or price > highestLow then
        entry.h[day] = price
        highestLow = price
    end
    local lowestLow = entry.l[day]
    if price < highestLow and (lowestLow == nil or price < lowestLow) then
        entry.l[day] = price
    end
    if available then
        entry.a = entry.a or {}
        entry.a[day] = math.max(entry.a[day] or 0, available)
    end
    local cutoff = today - HISTORY_DAYS
    Prune(entry.h, cutoff)
    Prune(entry.l, cutoff)
    if entry.a then
        Prune(entry.a, cutoff)
    end
end

-- 写入一批拍卖行价格：{ [itemID] = 单价 } 或 { [itemID] = { 单价, 在售数量 } }
function Prices.RecordAuction(batch)
    local market = Market(true)
    if not market then
        return 0
    end
    local today = Today()
    local count = 0
    for itemID, value in pairs(batch) do
        local price, available = value, nil
        if type(value) == "table" then
            price, available = value[1], value[2]
        end
        if type(itemID) == "number" and type(price) == "number" and price > 0 then
            SetPrice(market, itemID, floor(price + 0.5), available, today)
            count = count + 1
        end
    end
    if count > 0 then
        Notify(count)
    end
    return count
end

-- 自己记下的价格与距今天数（最近一次有记录的那天）
local function OwnPrice(itemID)
    local market = Market(false)
    local entry = market and market[tostring(itemID)]
    if not (entry and type(entry.m) == "number" and entry.m > 0) then
        return nil
    end
    local latest
    for key in pairs(entry.h or {}) do
        local day = tonumber(key)
        if day and (not latest or day > latest) then
            latest = day
        end
    end
    return entry.m, latest and math.max(0, Today() - latest) or nil
end

local function Plain(value)
    return type(value) == "number" and not (ns.IsSecret and ns.IsSecret(value))
end

-- Auctionator 记下的价格与距今天数（它只给 21 天内的天数，更久或没有时为 nil）
local function AuctionatorPrice(itemID)
    -- 开关在拍卖行模块的设置里（模块关掉时制作成本仍会用到价格，所以只看这个选项）
    local settings = ns.db and ns.db.modules and ns.db.modules.AuctionHouse
    if not (settings and settings.useAuctionator) then
        return nil
    end
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

-- 拍卖行单价、距今天数（0 = 今天，nil = 不知道）与来源（"own" / "auctionator"）；没有记录时返回 nil。
-- 两边都有时取天数更少的；一样新时用自己的
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

-- 价格来源变了（例如切换是否使用 Auctionator）时通知界面重算
function Prices.NotifyChanged()
    Notify(0)
end

-- Auctionator 是否在提供价格（设置页与鼠标提示用）
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

-- 全量扫描时间（每个拍卖行一份；服务器限制全量扫描的频率）
function Prices.LastScan()
    if not Database() then
        return nil
    end
    return ns.db.auctionScans[MarketKey()]
end

function Prices.SetLastScan(when)
    if Database() then
        ns.db.auctionScans[MarketKey()] = when
    end
end

function Prices.Count()
    local market = Market(false)
    local count = 0
    for _ in pairs(market or {}) do
        count = count + 1
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

-- 价格记录的新旧，给鼠标提示用：今天 / N 天前 / 不知道
function Prices.FormatDays(days)
    if not days then
        return L["date unknown"]
    elseif days == 0 then
        return L["today"]
    end
    return (L["%d days ago"]):format(days)
end

-- 给玩家看的拍卖行名字：规则集（客户端报告的服务器名）与阵营
function Prices.MarketLabel()
    local realm = (GetRealmName and GetRealmName()) or "?"
    local group, localized = UnitFactionGroup("player")
    return ("%s · %s"):format(realm, localized or group or "")
end
