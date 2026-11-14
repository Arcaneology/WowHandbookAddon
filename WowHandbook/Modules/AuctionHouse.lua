local ADDON_NAME, ns = ...
local L = ns.L

-- 拍卖行价格：
-- 1. 玩家在拍卖行搜索时，把看到的结果（浏览列表的最低价、商品与物品的逐条报价）记成每件物品的最低一口价单价；
-- 2. 拍卖行框体下沿右端（与“购买 / 出售 / 拍卖”标签同一行）放一个“扫描拍卖行”按钮，左边是扫描状态文字。
--    全量扫描用 C_AuctionHouse.ReplicateItems 取整个拍卖行，分批读取（每帧一批，不卡顿），读完一次性写入；
--    服务器限制全量扫描频率，冷却期间按钮不可点；关闭拍卖行即中止、不写入；
-- 3. 物品鼠标提示加一行拍卖价格与记录了多久。
-- 价格存在 ns.Prices（Core/Prices.lua）。拍卖行界面是按需加载的 Blizzard_AuctionHouseUI，按钮是插件自己的框架
-- （UIPanelButtonTemplate），不改暴雪的标签与子页面。
local Module = ns:NewModule("AuctionHouse", { recordSearches = true, tooltip = true, useAuctionator = false })
local Prices = ns.Prices

local SCAN_COOLDOWN = 15 * 60 -- 服务器对全量扫描的限制：约 15 分钟一次
local SCAN_TIMEOUT = 90       -- 发出请求后这么久没收到数据就放弃
local SCAN_CHUNK = 1000       -- 每帧读取的拍卖条数
local SEARCH_DELAY = 0.5      -- 浏览结果分批到达，合并后再读

local button, status, ticker
local scan = { state = "idle", generation = 0 }
local Refresh -- 按钮与状态文字刷新（拍卖行没打开时什么也不做）

--------------------------------------------------------------------------------
-- 读拍卖数据
--------------------------------------------------------------------------------

local function Plain(value)
    return type(value) == "number" and not ns.IsSecret(value)
end

-- batch[itemID] = { 最低单价, 看到的在售数量 }（Prices.RecordAuction 的格式）
local function Keep(batch, itemID, unitPrice, quantity)
    if Plain(itemID) and Plain(unitPrice) and unitPrice > 0 then
        quantity = Plain(quantity) and quantity or 0
        local old = batch[itemID]
        if not old then
            batch[itemID] = { unitPrice, quantity }
        else
            old[1] = math.min(old[1], unitPrice)
            old[2] = old[2] + quantity
        end
    end
end

-- 浏览列表：每个物品的最低价（商品是单价；装备类每条一件）
local function ReadBrowseResults()
    local results = C_AuctionHouse.GetBrowseResults and C_AuctionHouse.GetBrowseResults()
    local batch = {}
    for _, result in ipairs(results or {}) do
        local key = result.itemKey
        if key and (key.battlePetSpeciesID or 0) == 0 then
            Keep(batch, key.itemID, result.minPrice, result.totalQuantity)
        end
    end
    Prices.RecordAuction(batch)
end

local browsePending = false
local function OnBrowseResults()
    if browsePending or not ns:GetModuleSettings(Module).recordSearches then
        return
    end
    browsePending = true
    C_Timer.After(SEARCH_DELAY, function()
        browsePending = false
        if Module.enabled then
            ReadBrowseResults()
        end
    end)
end

-- 商品（材料等可叠加物品）：结果按单价从低到高，第一条就是最低价
local function OnCommodityResults(_, itemID)
    if not (ns:GetModuleSettings(Module).recordSearches and Plain(itemID)) then
        return
    end
    local first = C_AuctionHouse.GetCommoditySearchResultInfo and C_AuctionHouse.GetCommoditySearchResultInfo(itemID, 1)
    if first then
        local batch = {}
        local quantity = C_AuctionHouse.GetCommoditySearchResultsQuantity
            and C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID) or first.quantity
        Keep(batch, itemID, first.unitPrice, quantity)
        Prices.RecordAuction(batch)
    end
end

-- 物品（装备等）：逐条比一口价单价
local function OnItemResults(_, itemKey)
    if not (ns:GetModuleSettings(Module).recordSearches and type(itemKey) == "table")
        or (itemKey.battlePetSpeciesID or 0) ~= 0 then
        return
    end
    local count = C_AuctionHouse.GetNumItemSearchResults and C_AuctionHouse.GetNumItemSearchResults(itemKey) or 0
    local batch = {}
    for index = 1, count do
        local info = C_AuctionHouse.GetItemSearchResultInfo(itemKey, index)
        if info and Plain(info.buyoutAmount) then
            Keep(batch, itemKey.itemID, info.buyoutAmount / math.max(1, info.quantity or 1), info.quantity or 1)
        end
    end
    Prices.RecordAuction(batch)
end

--------------------------------------------------------------------------------
-- 全量扫描
--------------------------------------------------------------------------------

local function CooldownLeft()
    local last = Prices.LastScan()
    return last and math.max(0, last + SCAN_COOLDOWN - time()) or 0
end

local function FinishScan(message)
    scan.state = "idle"
    scan.generation = scan.generation + 1
    scan.batch = nil
    if message then
        ns:Print(message)
    end
    Refresh()
end

-- 每帧读一批：GetReplicateItemInfo 的下标从 0 开始；第 3 个返回值是数量，第 10 个是整组一口价，第 17 个是物品 ID
local function ProcessChunk(generation)
    if scan.generation ~= generation or scan.state ~= "processing" then
        return
    end
    if InCombatLockdown() then
        C_Timer.After(1, function() ProcessChunk(generation) end)
        return
    end
    local last = math.min(scan.index + SCAN_CHUNK, scan.total)
    for index = scan.index, last - 1 do
        local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = C_AuctionHouse.GetReplicateItemInfo(index)
        if Plain(buyout) and buyout > 0 then
            Keep(scan.batch, itemID, buyout / math.max(1, count or 1), count or 1)
        end
    end
    scan.index = last
    Refresh()
    if last < scan.total then
        C_Timer.After(0, function() ProcessChunk(generation) end)
        return
    end
    local priced = Prices.RecordAuction(scan.batch)
    FinishScan((L["Auction house scanned: %d auctions, prices for %d items."]):format(scan.total, priced))
end

local function OnReplicateList()
    if scan.state ~= "waiting" then
        return
    end
    scan.state = "processing"
    scan.total = C_AuctionHouse.GetNumReplicateItems() or 0
    scan.index = 0
    scan.batch = {}
    local generation = scan.generation
    C_Timer.After(0, function() ProcessChunk(generation) end)
end

local function StartScan()
    if scan.state ~= "idle" or CooldownLeft() > 0 then
        return
    end
    if InCombatLockdown() then
        ns:Print(L["Available after combat."])
        return
    end
    if not (C_AuctionHouse and C_AuctionHouse.ReplicateItems) then
        return
    end
    scan.state = "waiting"
    scan.generation = scan.generation + 1
    local generation = scan.generation
    Prices.SetLastScan(time()) -- 请求发出就算一次，服务器从这时开始计冷却
    C_AuctionHouse.ReplicateItems()
    Refresh()
    C_Timer.After(SCAN_TIMEOUT, function()
        if scan.generation == generation and scan.state == "waiting" then
            FinishScan(L["The auction house did not answer. Try again later."])
        end
    end)
end

--------------------------------------------------------------------------------
-- 拍卖行右下角的扫描按钮与状态文字
--------------------------------------------------------------------------------

local function StatusText()
    if scan.state == "waiting" then
        return L["Asking the auction house..."]
    elseif scan.state == "processing" then
        return (L["Scanning... %d%%"]):format(floor(scan.index / math.max(1, scan.total) * 100))
    end
    local left = CooldownLeft()
    if left > 0 then
        return (L["Next full scan in %s"]):format(Prices.FormatAge(left))
    end
    local last = Prices.LastScan()
    return last and (L["Last scan %s ago"]):format(Prices.FormatAge(time() - last)) or L["Not scanned yet"]
end

Refresh = function()
    if not (button and button:IsVisible()) then
        return
    end
    status:SetText(StatusText())
    button:SetEnabled(scan.state == "idle" and CooldownLeft() == 0)
end

local function ShowScanTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L["Scan auction house"])
    GameTooltip:AddLine(L["Records the lowest buyout of every item for tooltips and crafting costs."], 1, 1, 1, true)
    GameTooltip:AddLine(L["The server allows one full scan every 15 minutes."], unpack(ns.Theme.colors.textDim))
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Prices.MarketLabel(), unpack(ns.Theme.colors.textDim))
    GameTooltip:AddLine((L["Prices recorded: %d"]):format(Prices.Count()), unpack(ns.Theme.colors.textDim))
    GameTooltip:Show()
end

-- 按钮在拍卖行框体下沿外侧的右端，与左边的“购买 / 出售 / 拍卖”标签同一行；状态文字在按钮左边
local function Attach()
    local host = AuctionHouseFrame
    if button or type(host) ~= "table" then
        return
    end
    button = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    button:SetSize(120, 22)
    button:SetPoint("TOPRIGHT", host, "BOTTOMRIGHT", -6, -2)
    button:SetText(L["Scan auction house"])
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnClick", StartScan)
    button:SetScript("OnEnter", ShowScanTooltip)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnShow", function() Refresh() end)
    status = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", button, "LEFT", -8, 0)
    status:SetJustifyH("RIGHT")
end

-- 勾选“使用 Auctionator 价格”且装了 Auctionator 时，扫描交给 Auctionator，不显示自己的扫描按钮；
-- 没装 Auctionator 时照常显示，免得没有地方扫描
local function UsesAuctionatorScan()
    return ns:GetModuleSettings(Module).useAuctionator and Prices.AuctionatorLoaded()
end

local function OnAuctionHouseShow()
    if UsesAuctionatorScan() then
        if button then
            button:Hide()
        end
    else
        Attach()
        if button then
            button:Show()
            Refresh()
        end
    end
    if not ticker then
        ticker = C_Timer.NewTicker(5, function() Refresh() end) -- 冷却与“多久以前”
    end
end

local function OnAuctionHouseClosed()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    if scan.state ~= "idle" then
        FinishScan(L["Scan stopped: the auction house was closed."])
    end
end

--------------------------------------------------------------------------------
-- 鼠标提示
--------------------------------------------------------------------------------

local seenTooltips = setmetatable({}, { __mode = "k" })
local hooked = false

local function ItemID(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)"))
end

local function AddTooltip(tooltip, data)
    if not (Module.enabled and ns:GetModuleSettings(Module).tooltip and tooltip and tooltip.AddDoubleLine) then
        return
    end
    local itemID = data and data.id
    if ns.IsSecret(itemID) then
        return
    end
    if not itemID and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        itemID = ItemID(link)
    end
    local price, days, source = Prices.Auction(itemID)
    if not price then
        return
    end
    local token = data and data.dataInstanceID or itemID
    if seenTooltips[tooltip] == token then
        return
    end
    seenTooltips[tooltip] = token
    local label = (source == "auctionator" and L["Auctionator (%s)"] or L["Auction (%s)"]):format(Prices.FormatDays(days))
    local dim, text = ns.Theme.colors.textDim, ns.Theme.colors.text
    tooltip:AddDoubleLine(label, ns.Money(price), dim[1], dim[2], dim[3], text[1], text[2], text[3])
    if tooltip.Show then
        tooltip:Show()
    end
end

local function HookTooltips()
    if hooked then
        return
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddTooltip)
        hooked = true
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetItem", AddTooltip)
        hooked = true
    end
    if hooked and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
            seenTooltips[tooltip] = nil
        end)
    end
end

--------------------------------------------------------------------------------
-- 启用与关闭
--------------------------------------------------------------------------------

local EVENTS = {
    AUCTION_HOUSE_SHOW = OnAuctionHouseShow,
    AUCTION_HOUSE_CLOSED = OnAuctionHouseClosed,
    AUCTION_HOUSE_BROWSE_RESULTS_UPDATED = OnBrowseResults,
    AUCTION_HOUSE_BROWSE_RESULTS_ADDED = OnBrowseResults,
    COMMODITY_SEARCH_RESULTS_UPDATED = OnCommodityResults,
    ITEM_SEARCH_RESULTS_UPDATED = OnItemResults,
    REPLICATE_ITEM_LIST_UPDATE = OnReplicateList,
}

function Module:OnEnable()
    if not C_AuctionHouse then
        return
    end
    for event, handler in pairs(EVENTS) do
        ns:RegisterEvent(event, handler)
    end
    HookTooltips()
    if AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown() then
        OnAuctionHouseShow()
    end
end

function Module:OnDisable()
    for event, handler in pairs(EVENTS) do
        ns:UnregisterEvent(event, handler)
    end
    OnAuctionHouseClosed()
    if button then
        button:Hide()
    end
end

-- 设置页的“使用 Auctionator 价格”：改完立即显示或隐藏扫描按钮、刷新用到价格的界面
function Module.SetUseAuctionator(on)
    ns:GetModuleSettings(Module).useAuctionator = on and true or false
    if Module.enabled and AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown() then
        OnAuctionHouseShow()
    end
    Prices.NotifyChanged()
end

-- 测试用：当前扫描状态、扫描按钮与状态文字
Module.ScanState = function()
    return scan.state
end
Module.Button = function()
    return button, status
end
