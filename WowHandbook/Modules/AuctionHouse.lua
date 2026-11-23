local ADDON_NAME, ns = ...
local L = ns.L

-- 拍卖行价格：
-- 1. 玩家在拍卖行搜索时（原生界面或 Auctionator 等插件发起的都算），把看到的结果（浏览列表的最低价、
--    商品与物品的逐条报价，含后续分页）记成每件物品的最低一口价单价；
-- 2. 拍卖行框体内部右下角（与左下角的金币显示同一行）放一个“扫描拍卖行”按钮，左边是扫描状态文字。
--    放在框体里面而不是下沿外侧：外侧那一行常被其他插件的按钮占用。查看单件物品（ItemBuyFrame）时
--    暴雪的“一口价”按钮在同一位置，这期间收起扫描按钮。
--    全量扫描用 C_AuctionHouse.ReplicateItems 取整个拍卖行，分批读取（每帧一批，不卡顿），读完一次性写入；
--    服务器限制全量扫描频率，冷却期间按钮不可点；关闭拍卖行即中止、不写入；
-- 3. 中立拍卖行（地精拍卖师，两个阵营共用）与阵营拍卖行分开记：打开拍卖行时看拍卖师（"npc" 单位）的阵营，
--    联盟或部落是阵营拍卖行，没有阵营是中立拍卖行；
-- 4. 自己记价（搜索与全量扫描）时滤掉诱饵低价（Prices.FilterBait）：少量货挂得远低于行情时不当作最低价；
-- 5. 物品鼠标提示加拍卖价格与记录了多久：本阵营拍卖行一行，中立拍卖行有记录时另加一行；
--    勾了“扫描交给 Auctionator”时只显示一行拍卖行价格（Auctionator 的数据不分中立与阵营）。
-- 价格存在 ns.Prices（Core/Prices.lua）。拍卖行界面是按需加载的 Blizzard_AuctionHouseUI，按钮是插件自己的框架
-- （UIPanelButtonTemplate），不改暴雪的标签与子页面。
local Module = ns:NewModule("AuctionHouse", { recordSearches = true, tooltip = true, auctionatorScan = false })
local RECORD = { filter = true }                   -- 搜索记价：滤掉诱饵低价
local RECORD_SCAN = { filter = true, fullScan = true } -- 全量扫描：另记下今天扫描过
local Prices = ns.Prices

local SCAN_COOLDOWN = 15 * 60 -- 服务器对全量扫描的限制：约 15 分钟一次
local SCAN_TIMEOUT = 300      -- 发出请求后这么久没收到数据就放弃（Forever 返回全量数据可能要几分钟）
local SCAN_CHUNK = 1000       -- 每帧读取的拍卖条数
local SEARCH_DELAY = 0.5      -- 浏览结果分批到达，合并后再读
local COMMODITY_ROWS = 40     -- 商品搜索结果里按价位累计的挂单条数（存成阶梯价）

local button, status, ticker
local scan = { state = "idle", generation = 0 }
local Refresh -- 按钮与状态文字刷新（拍卖行没打开时什么也不做）

--------------------------------------------------------------------------------
-- 读拍卖数据
--------------------------------------------------------------------------------

local function Plain(value)
    return type(value) == "number" and not ns.IsSecret(value)
end

-- batch[itemID] = { 最低单价, 看到的在售数量, 各价位的在售数量 }（Prices.RecordAuction 的格式）。
-- levels 为真时按价位累计数量（逐条读到挂单时才有意义；浏览列表只有最低价，不记价位）
local function Keep(batch, itemID, unitPrice, quantity, levels)
    if Plain(itemID) and Plain(unitPrice) and unitPrice > 0 then
        quantity = Plain(quantity) and quantity or 0
        local old = batch[itemID]
        if not old then
            old = { unitPrice, quantity }
            batch[itemID] = old
        else
            old[1] = math.min(old[1], unitPrice)
            old[2] = old[2] + quantity
        end
        if levels and quantity > 0 then
            local price = floor(unitPrice + 0.5)
            old[3] = old[3] or {}
            old[3][price] = (old[3][price] or 0) + quantity
        end
    end
end

-- 名字是字符串且能读（不是保密值）才记
local function PlainName(name)
    return type(name) == "string" and name ~= "" and not ns.IsSecret(name)
end

-- 搜索记价时顺手记下物品名（客户端此时通常已拿到名字，没有就跳过），长期保存，下次搜到时刷新
local function RememberNames(batch)
    if not (C_Item and C_Item.GetItemNameByID) then
        return
    end
    local names = {}
    for itemID in pairs(batch) do
        local name = C_Item.GetItemNameByID(itemID)
        if PlainName(name) then
            names[itemID] = name
        end
    end
    Prices.RecordNames(names)
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
    Prices.RecordAuction(batch, RECORD)
    RememberNames(batch)
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
local function ReadCommodityResults(itemID)
    local first = C_AuctionHouse.GetCommoditySearchResultInfo and C_AuctionHouse.GetCommoditySearchResultInfo(itemID, 1)
    if first then
        local batch = {}
        local quantity = C_AuctionHouse.GetCommoditySearchResultsQuantity
            and C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID) or first.quantity
        Keep(batch, itemID, first.unitPrice, quantity)
        -- 前几十条挂单按价位累计，存成阶梯价（买得多时逐档往上吃）
        local rows = C_AuctionHouse.GetNumCommoditySearchResults and C_AuctionHouse.GetNumCommoditySearchResults(itemID) or 0
        local entry = batch[itemID]
        if entry and Plain(rows) then
            for index = 1, math.min(rows, COMMODITY_ROWS) do
                local info = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)
                if info and Plain(info.unitPrice) and Plain(info.quantity) and info.unitPrice > 0 and info.quantity > 0 then
                    local price = floor(info.unitPrice + 0.5)
                    entry[3] = entry[3] or {}
                    entry[3][price] = (entry[3][price] or 0) + info.quantity
                end
            end
        end
        Prices.RecordAuction(batch, RECORD)
        RememberNames(batch)
    end
end

-- 物品（装备、背包等）：逐条比一口价。ItemSearchResultInfo.buyoutAmount 是单件价，一条挂多件时不再除以件数
-- （暴雪拍卖行界面与 Auctionator 都按“单价 × 件数 = 总价”显示；之前除了件数，红色毛纺包一条 82 件被记成 24 铜）
local function ReadItemResults(itemKey)
    local count = C_AuctionHouse.GetNumItemSearchResults and C_AuctionHouse.GetNumItemSearchResults(itemKey) or 0
    local batch = {}
    for index = 1, count do
        local info = C_AuctionHouse.GetItemSearchResultInfo(itemKey, index)
        if info and Plain(info.buyoutAmount) then
            Keep(batch, itemKey.itemID, info.buyoutAmount, info.quantity or 1, true)
        end
    end
    Prices.RecordAuction(batch, RECORD)
    RememberNames(batch)
end

-- 单次搜索：原生拍卖行与 Auctionator 等插件都走同一套 C_AuctionHouse 接口，结果事件是全局的，
-- 谁发起的搜索都记。结果分页到达（_UPDATED 之后还有 _ADDED），同一件物品 SEARCH_DELAY 内的多次事件合并成一次读取
local pendingSearches = {}
local function QueueSearch(key, read, arg)
    if pendingSearches[key] then
        return
    end
    pendingSearches[key] = true
    C_Timer.After(SEARCH_DELAY, function()
        pendingSearches[key] = nil
        if Module.enabled and ns:GetModuleSettings(Module).recordSearches then
            read(arg)
        end
    end)
end

local function OnCommodityResults(_, itemID)
    if ns:GetModuleSettings(Module).recordSearches and Plain(itemID) then
        QueueSearch("c" .. itemID, ReadCommodityResults, itemID)
    end
end

local function OnItemResults(_, itemKey)
    if not (ns:GetModuleSettings(Module).recordSearches and type(itemKey) == "table" and Plain(itemKey.itemID))
        or (itemKey.battlePetSpeciesID or 0) ~= 0 then
        return
    end
    local key = ("i%d:%s:%s"):format(itemKey.itemID, tostring(itemKey.itemLevel or 0), tostring(itemKey.itemSuffix or 0))
    QueueSearch(key, ReadItemResults, itemKey)
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
    scan.external = nil
    scan.generation = scan.generation + 1
    scan.batch = nil
    scan.names = nil
    if message then
        ns:Print(message)
    end
    Refresh()
end

-- 每帧读一批：GetReplicateItemInfo 的下标从 0 开始；第 3 个返回值是数量，第 10 个是整条挂单的一口价（除以数量得单价，
-- 与 Auctionator 的全量扫描一致；物品搜索的 buyoutAmount 才是单价），第 17 个是物品 ID
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
        local name, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = C_AuctionHouse.GetReplicateItemInfo(index)
        if Plain(buyout) and buyout > 0 then
            Keep(scan.batch, itemID, buyout / math.max(1, count or 1), count or 1, true)
        end
        -- 第 1 个返回值是物品名：扫描完一起存下来（物品 ID 与名字的对应长期保存，下次扫描刷新）
        if Plain(itemID) and PlainName(name) then
            scan.names[itemID] = name
        end
    end
    scan.index = last
    Refresh()
    if last < scan.total then
        C_Timer.After(0, function() ProcessChunk(generation) end)
        return
    end
    -- 收到数据才算服务器受理了这次全量扫描，冷却从请求发出时算起
    Prices.SetLastScan(scan.requestedAt or time())
    local priced, baited = Prices.RecordAuction(scan.batch, RECORD_SCAN)
    Prices.RecordNames(scan.names)
    local message = (L["Auction house scanned: %d auctions, prices for %d items."]):format(scan.total, priced)
    if baited > 0 then
        message = message .. " " .. (L["Skipped bait listings on %d items."]):format(baited)
    end
    FinishScan(message)
end

local function OnReplicateList()
    if scan.state ~= "waiting" then
        return
    end
    scan.state = "processing"
    scan.total = C_AuctionHouse.GetNumReplicateItems() or 0
    scan.index = 0
    scan.batch = {}
    scan.names = {}
    local generation = scan.generation
    C_Timer.After(0, function() ProcessChunk(generation) end)
end

-- 等全量数据。external 为真时是别的插件（Auctionator、GUGU 等）发的请求：全量数据是整个游戏会话共用的，
-- 服务器 15 分钟只受理一次，别人的请求回来的数据我们照样读，不再自己重复请求。
-- 冷却只在真的收到数据时才记（ProcessChunk 结束时）；超时没有数据就不计冷却，可以再试
local function BeginWaiting(external)
    scan.state = "waiting"
    scan.external = external and true or nil
    scan.requestedAt = time()
    scan.generation = scan.generation + 1
    local generation = scan.generation
    Refresh()
    C_Timer.After(SCAN_TIMEOUT, function()
        if scan.generation == generation and scan.state == "waiting" then
            local noData = L["The auction house sent no data within 5 minutes, so no cooldown is counted. "
                .. "It allows one full scan every 15 minutes per account, other addons' scans included; try again later."]
            FinishScan(external and L["The scan another addon asked for did not come back."] or noData)
        end
    end)
end

local ownRequest = false

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
    -- 拍卖行的请求通道忙时（刚搜索过很多次等），请求会被丢掉：先不发
    if C_AuctionHouse.IsThrottledMessageSystemReady then
        local ok, ready = pcall(C_AuctionHouse.IsThrottledMessageSystemReady)
        if ok and ready == false then
            ns:Print(L["The auction house is busy. Try again in a moment."])
            return
        end
    end
    BeginWaiting(false)
    ownRequest = true
    local ok = pcall(C_AuctionHouse.ReplicateItems)
    ownRequest = false
    if not ok then
        FinishScan(L["The auction house did not accept the scan request."])
    end
end

-- 别的插件发全量请求（hooksecurefunc 只是跟在后面看，不改它的调用）：拍卖行开着、本模块开着且允许记价时，
-- 跟着等同一份数据并记下价格
local function OnAnyReplicateRequest()
    if ownRequest or not Module.enabled or not ns:GetModuleSettings(Module).recordSearches then
        return
    end
    if not (AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown()) then
        return
    end
    if scan.state == "idle" then
        BeginWaiting(true)
    end
end

--------------------------------------------------------------------------------
-- 拍卖行框体内右下角的扫描按钮与状态文字
--------------------------------------------------------------------------------

local function StatusText()
    if scan.state == "waiting" then
        if scan.external then
            return L["Waiting for another addon's full scan..."]
        end
        return (L["Waiting for the auction house... %s"]):format(Prices.FormatSeconds(time() - (scan.requestedAt or time())))
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
    local text = StatusText()
    if Prices.AuctionHouseKind() == "neutral" then
        text = L["Neutral auction house"] .. " · " .. text
    end
    status:SetText(text)
    button:SetEnabled(scan.state == "idle" and CooldownLeft() == 0)
end

local function ShowScanTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L["Scan auction house"])
    GameTooltip:AddLine(L["Records the lowest buyout of every item for tooltips and crafting costs."], 1, 1, 1, true)
    GameTooltip:AddLine(L["Listings priced far below the rest, a few at a time, are treated as bait and skipped."],
        unpack(ns.Theme.colors.textDim))
    GameTooltip:AddLine(L["The server allows one full scan every 15 minutes."], unpack(ns.Theme.colors.textDim))
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Prices.MarketLabel(), unpack(ns.Theme.colors.textDim))
    GameTooltip:AddLine((L["Prices recorded: %d"]):format(Prices.Count()), unpack(ns.Theme.colors.textDim))
    GameTooltip:Show()
end

-- 查看单件物品时暴雪的“一口价”按钮占着框体右下角（ItemBuyFrame.BuyoutFrame 锚在右下），这期间收起扫描按钮
local function BuyoutCovered()
    local itemBuy = AuctionHouseFrame and AuctionHouseFrame.ItemBuyFrame
    return type(itemBuy) == "table" and itemBuy.IsShown and itemBuy:IsShown() or false
end

local function UsesAuctionatorScan()
    return ns:GetModuleSettings(Module).auctionatorScan and Prices.AuctionatorLoaded()
end

-- covered 由 ItemBuyFrame 的显示 / 隐藏钩子直接传入（隐藏钩子里不依赖 IsShown 的时机）
local function UpdateButtonShown(covered)
    if covered == nil then
        covered = BuyoutCovered()
    end
    if button then
        button:SetShown(Module.enabled and not UsesAuctionatorScan() and not covered)
    end
end

-- 按钮在拍卖行框体内部右下角，与左下角的金币显示（MoneyFrameBorder，距底 6）同一行；状态文字在按钮左边。
-- 这一行在浏览、出售、拍卖各页都空着；层级比框体高一些，压在背景上，但低于暴雪的对话框遮罩（1000）
local function Attach()
    local host = AuctionHouseFrame
    if button or type(host) ~= "table" then
        return
    end
    button = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    button:SetSize(120, 22)
    button:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -8, 5)
    if host.GetFrameLevel then
        button:SetFrameLevel(host:GetFrameLevel() + 20)
    end
    button:SetText(L["Scan auction house"])
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnClick", StartScan)
    button:SetScript("OnEnter", ShowScanTooltip)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnShow", function() Refresh() end)
    status = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("RIGHT", button, "LEFT", -8, 0)
    status:SetJustifyH("RIGHT")
    local itemBuy = host.ItemBuyFrame
    if type(itemBuy) == "table" and itemBuy.HookScript then
        itemBuy:HookScript("OnShow", function() UpdateButtonShown(true) end)
        itemBuy:HookScript("OnHide", function() UpdateButtonShown(false) end)
    end
end

-- 这次打开的是中立还是阵营拍卖行：拍卖师（"npc" 单位）是联盟或部落的就是阵营拍卖行，
-- 地精拍卖师没有阵营，是中立拍卖行；取不到拍卖师时按阵营拍卖行算
local function DetectAuctionHouse()
    if UnitExists and UnitExists("npc") then
        local faction = UnitFactionGroup("npc")
        if faction == "Alliance" or faction == "Horde" then
            return "faction"
        end
        return "neutral"
    end
    return "faction"
end
Module.DetectAuctionHouse = DetectAuctionHouse

-- 勾选“扫描交给 Auctionator”且装了 Auctionator 时，不显示自己的扫描按钮（它的价格本来就会自动补上）；
-- 没装 Auctionator 时照常显示，免得没有地方扫描
local function OnAuctionHouseShow()
    Prices.SetAuctionHouse(DetectAuctionHouse())
    if not UsesAuctionatorScan() then
        Attach()
    end
    UpdateButtonShown()
    Refresh()
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
    Prices.SetAuctionHouse(nil)
end

--------------------------------------------------------------------------------
-- 鼠标提示
--------------------------------------------------------------------------------

local replicateHooked = false
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
    if type(itemID) ~= "number" then
        return
    end
    -- 勾了“扫描交给 Auctionator”：只显示一行拍卖行价格（Auctionator 的数据不分中立与阵营）；
    -- 否则本阵营一行（自己没有时用 Auctionator 的补上），中立拍卖行有自己的记录时另加一行
    local lines = {}
    local price, days, source = Prices.Auction(itemID)
    if price then
        local label = (source == "auctionator" and L["Auctionator (%s)"] or L["Auction (%s)"])
        tinsert(lines, { label:format(Prices.FormatDays(days)), price })
    end
    if not UsesAuctionatorScan() then
        local neutral, neutralDays = Prices.Neutral(itemID)
        if neutral then
            tinsert(lines, { (L["Auction, neutral (%s)"]):format(Prices.FormatDays(neutralDays)), neutral })
        end
    end
    if #lines == 0 then
        return
    end
    local token = data and data.dataInstanceID or itemID
    if seenTooltips[tooltip] == token then
        return
    end
    seenTooltips[tooltip] = token
    local dim, text = ns.Theme.colors.textDim, ns.Theme.colors.text
    for _, line in ipairs(lines) do
        tooltip:AddDoubleLine(line[1], ns.Money(line[2]), dim[1], dim[2], dim[3], text[1], text[2], text[3])
    end
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
    COMMODITY_SEARCH_RESULTS_ADDED = OnCommodityResults,
    ITEM_SEARCH_RESULTS_UPDATED = OnItemResults,
    ITEM_SEARCH_RESULTS_ADDED = OnItemResults,
    REPLICATE_ITEM_LIST_UPDATE = OnReplicateList,
}

function Module:OnEnable()
    -- 0.9.x 的“使用 Auctionator 价格”同时管读价格与隐藏扫描按钮；读价格改为自动后，只留下隐藏按钮这一半
    local settings = ns:GetModuleSettings(Module)
    if settings.useAuctionator ~= nil then
        settings.auctionatorScan = settings.useAuctionator and true or false
        settings.useAuctionator = nil
    end
    if not C_AuctionHouse then
        return
    end
    for event, handler in pairs(EVENTS) do
        ns:RegisterEvent(event, handler)
    end
    HookTooltips()
    if not replicateHooked and hooksecurefunc and C_AuctionHouse.ReplicateItems then
        hooksecurefunc(C_AuctionHouse, "ReplicateItems", OnAnyReplicateRequest)
        replicateHooked = true
    end
    if AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown() then
        OnAuctionHouseShow()
    end
end

function Module:OnDisable()
    for event, handler in pairs(EVENTS) do
        ns:UnregisterEvent(event, handler)
    end
    OnAuctionHouseClosed()
    UpdateButtonShown()
end

-- 设置页的“扫描交给 Auctionator”：改完立即显示或隐藏扫描按钮
function Module.SetAuctionatorScan(on)
    ns:GetModuleSettings(Module).auctionatorScan = on and true or false
    if Module.enabled and AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown() then
        OnAuctionHouseShow()
    end
end

-- 测试用：当前扫描状态、扫描按钮与状态文字
Module.ScanState = function()
    return scan.state
end
Module.Button = function()
    return button, status
end
