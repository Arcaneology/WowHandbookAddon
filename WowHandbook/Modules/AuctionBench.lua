local ADDON_NAME, ns = ...
local L = ns.L

-- 拍卖行工作台：独立窗口（不嵌进 /wh 主窗口的内容区，免受主窗口尺寸与布局限制），
-- 从 /wh 导航的“拍卖行工作台”或 /wh auction 打开；打开拍卖行时默认自动打开（右键标题栏或设置里可关掉），
-- 拍卖行开着时点 × 收成一个小按钮（与专业工作台一样），下次打开拍卖行也只显示小按钮，点它再展开。
-- 只读价格库（Core/Prices.lua），自己只存窗口位置、大小与是否随拍卖行打开（模块设置）。
-- 价格库把中立拍卖行（地精拍卖行，两个阵营共用）与本阵营拍卖行分开记，并按天保留扫描到的价格；
-- 这一页把两边都有近期价格的物品放在一起比：
--   - 商机筛选：默认列中立比本阵营便宜的（在中立买、回本阵营拍卖行卖：阵营拍卖行人多，卖得快），
--     也可以切到本阵营更便宜的，或列出全部记过价格的物品；
--   - 每件物品的两边价格、扣掉卖出那边成交手续费后的每件利润与利润率（详情里另有两边的流通率估算）；
--   - 选中物品显示两边的价格走势图（按天，来自玩家自己的历史扫描）。
-- 手续费按阵营拍卖行 5%、中立拍卖行 15% 估算（游戏惯例），保证金不计。
-- 只用插件自己扫描的数据：Auctionator 的价格不分中立与阵营，不在这里出现。
local Module = ns:NewModule("AuctionBench", { autoOpen = true })
local Bench = Module
local UI, Theme, Prices = ns.UI, ns.Theme, ns.Prices

local FRESH_DAYS = 3          -- 两边的价格都在这么多天内才算有效，拿来比较
local FACTION_CUT = 0.05      -- 阵营拍卖行成交手续费
local NEUTRAL_CUT = 0.15      -- 中立拍卖行成交手续费
local LIQUIDITY_WINDOW = 14   -- 流通率看最近多少天的扫描
local NAME_LOOKAHEAD = 20     -- 除了看得见的行，再往下多请求多少行的物品名（滚动时少等一下）

-- 独立窗口
local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1240, 720
local MIN_WIDTH, MIN_HEIGHT = 1040, 560
local HEADER_HEIGHT, PAD, LIST_WIDTH = 40, 18, 580
local MONEY_WIDTH, MARGIN_WIDTH = 82, 54 -- 列表的金额列与利润率列宽度
local CHART_MARGIN = 78       -- 走势图纵轴刻度文字的宽度
local LAYOUT_VERSION = 2      -- 窗口布局版本：变了就不用旧的窗口大小
local CHART_SHARE = 0.5      -- 走势图占详情区高度的比例

local state = { lens = "neutral", sort = "profit", ascending = false, search = "", range = 30, selected = nil }
local page
local tab               -- 收起后的小按钮
local auctionOpen = false -- 拍卖行是否开着
local PlaceWindow, ShowTab

-- 文字颜色取主题的（强调色随配色方案变，用的时候再取）
local function C(name)
    return Theme.code[name]
end

-- 本阵营的名字（联盟 / 部落），用在列标题、筛选与详情里：写全称，不写“阵营”
local function FactionName()
    local group = UnitFactionGroup and UnitFactionGroup("player")
    if group == "Alliance" then
        return L["Alliance"], L["Alliance auction house"]
    elseif group == "Horde" then
        return L["Horde"], L["Horde auction house"]
    end
    return L["Faction"], L["Auction house"]
end

local function Money(copper)
    copper = floor((copper or 0) + 0.5)
    local sign = copper < 0 and "-" or ""
    copper = math.abs(copper)
    if GetMoneyString then
        return sign .. GetMoneyString(copper, true)
    end
    local gold, silver, rest = floor(copper / 10000), floor(copper / 100) % 100, copper % 100
    if gold > 0 then
        return ("%s%dg %ds %dc"):format(sign, gold, silver, rest)
    elseif silver > 0 then
        return ("%s%ds %dc"):format(sign, silver, rest)
    end
    return ("%s%dc"):format(sign, rest)
end

-- 列表与刻度用的紧凑金额：不带金币图标，最多两级单位（12g 05s、75s 20c、35c），100 金以上只写金
local function ShortMoney(copper)
    copper = floor((copper or 0) + 0.5)
    local sign = copper < 0 and "-" or ""
    copper = math.abs(copper)
    local g = _G["GOLD_AMOUNT_SYMBOL"] or "g"
    local si = _G["SILVER_AMOUNT_SYMBOL"] or "s"
    local c = _G["COPPER_AMOUNT_SYMBOL"] or "c"
    local gold, silver, rest = floor(copper / 10000), floor(copper / 100) % 100, copper % 100
    if gold >= 100 then
        return ("%s%d%s"):format(sign, gold, g)
    elseif gold > 0 then
        return ("%s%d%s %02d%s"):format(sign, gold, g, silver, si)
    elseif silver > 0 then
        return ("%s%d%s %02d%s"):format(sign, silver, si, rest, c)
    end
    return ("%s%d%s"):format(sign, rest, c)
end

local function Percent(ratio)
    return ratio and ("%d%%"):format(floor(ratio * 100 + 0.5)) or "?"
end

-- 物品名：客户端物品缓存有上限，几千个物品一起请求时先到的名字会被挤掉，再取又是空的，
-- 列表里的名字就会在“物品 12345”和真名之间来回跳。所以优先用扫描与搜索拍卖行时长期存下的名字
-- （Prices.ItemName），再问客户端；见过一次的名字记在本次会话里
local nameCache = {}
local function ItemName(itemID)
    local name = nameCache[itemID]
    if name then
        return name
    end
    name = Prices.ItemName(itemID)
    if not name then
        name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    end
    if name and name ~= "" then
        nameCache[itemID] = name
        return name
    end
end

--------------------------------------------------------------------------------
-- 数据：与界面无关，便于在游戏外测试
--------------------------------------------------------------------------------

-- 一件物品两边的价格与比较结果；没有任何记录时返回 nil
function Bench.Compare(itemID)
    local P = Prices
    if not P then
        return nil
    end
    local faction, factionAge = P.Own(itemID, "faction")
    local neutral, neutralAge = P.Neutral(itemID)
    if not (faction or neutral) then
        return nil
    end
    local row = { id = itemID, faction = faction, factionAge = factionAge, neutral = neutral, neutralAge = neutralAge }
    row.fresh = faction and neutral and (factionAge or math.huge) <= FRESH_DAYS and (neutralAge or math.huge) <= FRESH_DAYS
        or false
    if faction and neutral then
        -- 中立买入、阵营卖出；阵营买入、中立卖出（每件，扣成交手续费）
        row.buyNeutral = faction * (1 - FACTION_CUT) - neutral
        row.buyFaction = neutral * (1 - NEUTRAL_CUT) - faction
        -- 利润率 = 扣掉卖出那边成交手续费后的每件利润 ÷ 买入价
        row.buyNeutralMargin = row.buyNeutral / neutral
        row.buyFactionMargin = row.buyFaction / faction
        row.spread = (faction - neutral) / math.min(faction, neutral) -- 正数：中立更便宜
    end
    row.factionTurnover, row.factionPresence = P.Liquidity(itemID, "faction", LIQUIDITY_WINDOW)
    row.neutralTurnover, row.neutralPresence = P.Liquidity(itemID, "neutral", LIQUIDITY_WINDOW)
    row.factionAvailable = P.Available(itemID, "faction")
    row.neutralAvailable = P.Available(itemID, "neutral")
    row.factionBait = P.BaitPrice(itemID, "faction")
    row.neutralBait = P.BaitPrice(itemID, "neutral")
    return row
end

-- 这一行在当前视角下的每件利润与利润率：中立更便宜看“中立买、阵营卖”（扣阵营 5%），
-- 阵营更便宜看“阵营买、中立卖”（扣中立 15%），全部物品取两种做法里利润高的那种
local function LensValues(row, lens)
    if lens == "faction" then
        return row.buyFaction, row.buyFactionMargin
    end
    if lens == "all" and row.buyNeutral and row.buyFaction and row.buyFaction > row.buyNeutral then
        return row.buyFaction, row.buyFactionMargin
    end
    return row.buyNeutral, row.buyNeutralMargin
end

local function Matches(itemID, search)
    if search == "" then
        return true
    end
    if tostring(itemID):find(search, 1, true) then
        return true
    end
    local name = ItemName(itemID)
    return name and name:lower():find(search, 1, true) ~= nil or false
end

-- 列表条目：lens 为 "neutral"（中立更便宜，默认）、"faction"（阵营更便宜）或 "all"；
-- sort 为表头的列："name"（物品名）、"neutral" / "faction"（两边价格）、"profit"（每件利润）、"margin"（利润率）；
-- ascending 为真时从小到大（名字按字母），否则从大到小；没有这一项的行排在最后
function Bench.BuildRows(lens, sort, search, ascending)
    local P = Prices
    local rows = {}
    if not P then
        return rows
    end
    search = (search or ""):lower()
    local seen = {}
    local ids = {}
    for _, kind in ipairs({ "faction", "neutral" }) do
        for _, itemID in ipairs(P.ItemIDs(kind)) do
            if not seen[itemID] then
                seen[itemID] = true
                tinsert(ids, itemID)
            end
        end
    end
    for _, itemID in ipairs(ids) do
        local row = Bench.Compare(itemID)
        local keep = row and Matches(itemID, search)
        if keep and lens == "neutral" then
            keep = row.fresh and row.neutral < row.faction
        elseif keep and lens == "faction" then
            keep = row.fresh and row.faction < row.neutral
        end
        if keep then
            row.profit, row.margin = LensValues(row, lens)
            tinsert(rows, row)
        end
    end
    local function Value(row)
        if sort == "name" then
            return (ItemName(row.id) or ""):lower()
        elseif sort == "neutral" or sort == "faction" or sort == "margin" then
            return row[sort]
        end
        return row.profit
    end
    table.sort(rows, function(a, b)
        local va, vb = Value(a), Value(b)
        if va == nil or vb == nil or va == vb then
            if (va == nil) ~= (vb == nil) then
                return vb == nil
            end
            return a.id < b.id
        end
        if ascending then
            return va < vb
        end
        return va > vb
    end)
    return rows
end

-- 两条走势序列（阵营金色、中立蓝色），只取最近 range 天（nil 为全部）
function Bench.Series(itemID, range)
    local P = Prices
    local series = {}
    if not P then
        return series
    end
    local from = range and (P.Today() - range + 1) or -math.huge
    for _, spec in ipairs({ { "faction", "gold" }, { "neutral", "blue" } }) do
        local points = {}
        for _, point in ipairs(P.History(itemID, spec[1])) do
            if point.day >= from then
                tinsert(points, { x = point.day, y = point.price })
            end
        end
        tinsert(series, { kind = spec[1], color = spec[2], points = points })
    end
    return series
end

--------------------------------------------------------------------------------
-- 界面
--------------------------------------------------------------------------------

-- 表格的四列：中立价、阵营价、每件利润、利润率（没有的写“—”）
local DASH = C("muted") .. "—|r"
local function Columns(row)
    return {
        row.neutral and (C("blue") .. ShortMoney(row.neutral) .. "|r") or DASH,
        row.faction and (C("gold") .. ShortMoney(row.faction) .. "|r") or DASH,
        row.profit and ((row.profit > 0 and C("green") or C("red")) .. ShortMoney(row.profit) .. "|r") or DASH,
        row.margin and ((row.margin > 0 and C("green") or C("red")) .. Percent(row.margin) .. "|r") or DASH,
    }
end

-- 只请求看得见的行（再往下多 NAME_LOOKAHEAD 行）里还没有名字的物品，每个物品本次会话只请求一次；
-- 列表每次刷新（滚动、换筛选）时调用
local requestedNames = {}
local function RequestVisibleNames(list)
    if not (C_Item and C_Item.RequestLoadItemDataByID) then
        return
    end
    local last = math.min(#list.data, list.offset + list:VisibleRows() + NAME_LOOKAHEAD)
    for index = list.offset + 1, last do
        local entry = list.data[index]
        if entry.nameless and not requestedNames[entry.id] and not ItemName(entry.id) then
            requestedNames[entry.id] = true
            C_Item.RequestLoadItemDataByID(entry.id)
        end
    end
end

local function SideLine(label, price, age, available, turnover, presence, bait)
    if not price then
        return (L["%s: %s"]):format(label, C("muted") .. L["no price recorded"] .. "|r")
    end
    local P = Prices
    local text = (L["%s: %s"]):format(label, Money(price) .. "  " .. C("muted") .. P.FormatDays(age) .. "|r")
    if available then
        text = text .. "  " .. (L["%d listed"]):format(available)
    end
    if turnover then
        text = text .. "  " .. (L["turnover %s"]):format(Percent(turnover))
    end
    if presence then
        text = text .. C("muted") .. "  " .. (L["listed on %s of scan days"]):format(Percent(presence)) .. "|r"
    end
    if bait then
        text = text .. "\n    " .. C("red") .. (L["Bait listing skipped: %s"]):format(Money(bait)) .. "|r"
    end
    return text
end

local function RefreshDetail()
    if not page then
        return
    end
    local itemID = state.selected
    local row = itemID and Bench.Compare(itemID)
    if not row then
        page.detailText:SetText(C("muted") .. L["Pick an item on the left to see both auction houses and the price trend."] .. "|r")
        page.chart:SetSeries({})
        return
    end
    local name = ItemName(itemID) or (L["Item %d"]):format(itemID)
    local factionName, factionHouse = FactionName()
    local lines = { ("|cffffffff|Hitem:%d|h[%s]|h|r"):format(itemID, name) }
    tinsert(lines, SideLine(C("gold") .. factionHouse .. "|r", row.faction, row.factionAge,
        row.factionAvailable, row.factionTurnover, row.factionPresence, row.factionBait))
    tinsert(lines, SideLine(C("blue") .. L["Neutral auction house"] .. "|r", row.neutral, row.neutralAge,
        row.neutralAvailable, row.neutralTurnover, row.neutralPresence, row.neutralBait))
    if row.buyNeutral then
        local function Profit(value)
            return (value > 0 and C("green") or C("red")) .. Money(value) .. "|r"
        end
        tinsert(lines, (L["Buy neutral, sell %s: %s each, margin %s (5%% cut)"]):format(factionName,
            Profit(row.buyNeutral), Percent(row.buyNeutralMargin)))
        tinsert(lines, (L["Buy %s, sell neutral: %s each, margin %s (15%% cut)"]):format(factionName,
            Profit(row.buyFaction), Percent(row.buyFactionMargin)))
        if not row.fresh then
            tinsert(lines, C("muted") .. (L["One side is older than %d days; scan both again before trading."]):format(FRESH_DAYS) .. "|r")
        end
    end
    page.detailText:SetText(table.concat(lines, "\n"))
    local P = Prices
    page.chart:SetSeries(Bench.Series(itemID, state.range), {
        x = function(day)
            return date("%m-%d", P.DayTime(day))
        end,
        y = function(value)
            return ShortMoney(value)
        end,
    })
end

local function RefreshList()
    if not (page and page:IsVisible()) then
        return
    end
    local rows = Bench.BuildRows(state.lens, state.sort, state.search, state.ascending)
    local entries = {}
    for _, row in ipairs(rows) do
        local name = ItemName(row.id)
        tinsert(entries, { id = row.id, text = name or (L["Item %d"]):format(row.id), nameless = not name,
            columns = Columns(row) })
    end
    page.list:SetData(entries, state.selected)
    page.countText:SetText((L["%d items"]):format(#entries))
    local P = Prices
    if P then
        page.status:SetText((L["%s: %d items, %d scan days · Neutral: %d items, %d scan days · history kept %d days"]):format(
            (FactionName()), #P.ItemIDs("faction"), #P.ScanDays("faction"), #P.ItemIDs("neutral"), #P.ScanDays("neutral"), P.HistoryDays()))
    end
    RefreshDetail()
end

function Bench:Refresh()
    RefreshList()
end

-- 物品名陆续到达：先记进名字缓存，攒半秒后只把列表里对应行的文字换掉再重画，
-- 不重新计算整张表（几千个物品的比价与流通率每次都算一遍太重）
local namePending = false
local function ApplyNames()
    namePending = false
    if not (page and page:IsVisible()) then
        return
    end
    local changed = false
    for _, entry in ipairs(page.list.data) do
        if entry.nameless then
            local name = ItemName(entry.id)
            if name then
                entry.text, entry.nameless, changed = name, nil, true
            end
        end
    end
    if changed then
        page.list:Refresh()
        if state.selected then
            RefreshDetail()
        end
    end
end

local function OnItemInfo(_, itemID)
    if itemID then
        ItemName(itemID)
    end
    if namePending or not (page and page:IsVisible()) then
        return
    end
    namePending = true
    C_Timer.After(0.5, ApplyNames)
end

-- 窗口设置：位置、大小、缩放、锁定、是否随拍卖行打开、是否收起（存在模块设置里）
local function WindowSettings()
    return ns:GetModuleSettings(Module)
end

local function SaveGeometry(f)
    local settings = WindowSettings()
    local point, _, relativePoint, x, y = f:GetPoint()
    settings.position = point and { point, relativePoint, x, y } or nil
    settings.width, settings.height = f:GetWidth(), f:GetHeight()
end

-- 右下角的拖拽调整大小把手：三条斜线（纯色线段拼成）
local function ResizeGrip(f)
    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip.lines = {}
    for index = 1, 3 do
        local line = grip:CreateLine(nil, "OVERLAY")
        line:SetThickness(1)
        local offset = index * 4
        line:SetStartPoint("BOTTOMRIGHT", grip, -offset, 2)
        line:SetEndPoint("BOTTOMRIGHT", grip, -2, offset)
        grip.lines[index] = line
    end
    local function Paint(hovered)
        local color = Theme.colors[hovered and "gold" or "muted"]
        for _, line in ipairs(grip.lines) do
            line:SetColorTexture(color[1], color[2], color[3], 1)
        end
    end
    Paint(false)
    grip:SetScript("OnEnter", function() Paint(true) end)
    grip:SetScript("OnLeave", function() Paint(false) end)
    grip:SetScript("OnMouseDown", function()
        if not WindowSettings().locked then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        SaveGeometry(f)
    end)
    Theme:Track(grip, function() Paint(false) end)
    return grip
end

-- 窗口位置：记过就用记下的；没记过时，拍卖行开着就贴在拍卖行右边，否则放在屏幕中间
PlaceWindow = function(f)
    local position = WindowSettings().position
    f:ClearAllPoints()
    if position then
        f:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    elseif auctionOpen and AuctionHouseFrame then
        f:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 8, 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    end
end

-- 收起后的小按钮（与专业工作台收起后的按钮一样）：只在拍卖行开着时出现，点一下展开；
-- 可拖动，位置单独记下；右键回到默认位置（拍卖行右上角外侧）
local function PlaceTab()
    local position = WindowSettings().tabPosition
    tab:ClearAllPoints()
    if position then
        tab:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    elseif AuctionHouseFrame then
        tab:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 6, -28)
    else
        tab:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function CreateTab()
    tab = UI:Button(UIParent, L["Auction workbench"], 120, 24, "primary")
    tab:Hide()
    tab:SetFrameStrata("HIGH")
    tab:SetMovable(true)
    tab:SetClampedToScreen(true)
    tab:RegisterForDrag("LeftButton")
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tab:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    tab:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.draggedAt = GetTime()
        local point, _, relativePoint, x, y = self:GetPoint()
        WindowSettings().tabPosition = point and { point, relativePoint, x, y } or nil
    end)
    tab:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            WindowSettings().tabPosition = nil
            PlaceTab()
            return
        end
        -- 拖动松手时不当成点击
        if self.draggedAt and GetTime() - self.draggedAt < 0.3 then
            return
        end
        Bench:Expand()
    end)
    tab:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Auction workbench"])
        GameTooltip:AddLine(L["Click to open. Drag to move; right-click to put it back."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tab:HookScript("OnLeave", GameTooltip_Hide)
end

ShowTab = function()
    if not tab then
        CreateTab()
    end
    PlaceTab()
    tab:Show()
end

-- 独立窗口：不放进 /wh 主窗口的内容区，自己的标题栏可拖动、右下角可调大小、Esc 或 × 关闭、右键标题栏锁定位置与缩放。
-- 左侧列表固定宽度，右侧详情与走势图随窗口变大
local function CreateWindow()
    local settings = WindowSettings()
    -- 布局改过（表格列表更宽）：旧版本记下的大小作废，回到新的默认大小
    if settings.layout ~= LAYOUT_VERSION then
        settings.layout, settings.width, settings.height = LAYOUT_VERSION, nil, nil
    end
    local f = CreateFrame("Frame", "WowHandbookAuctionBenchFrame", UIParent, "BackdropTemplate")
    page = f
    Theme:Skin(f, "window", "line")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetResizable(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
    end
    f:EnableMouse(true)
    f:SetSize(math.max(MIN_WIDTH, settings.width or DEFAULT_WIDTH), math.max(MIN_HEIGHT, settings.height or DEFAULT_HEIGHT))
    f:SetScale(settings.scale or 1)
    f:Hide()
    PlaceWindow(f)
    tinsert(UISpecialFrames, "WowHandbookAuctionBenchFrame") -- Esc 关闭

    -- 标题栏：拖动移动，右键菜单
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER_HEIGHT)
    Theme:Fill(header, "sidebar")
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not WindowSettings().locked then
            f:StartMoving()
        end
    end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SaveGeometry(f)
    end)
    header:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton == "RightButton" then
            local entries = UI:WindowMenuEntries(WindowSettings(), function()
                f:SetScale(WindowSettings().scale or 1)
            end)
            tinsert(entries, 1, { kind = "check", text = L["Open with the auction house"],
                checked = WindowSettings().autoOpen ~= false,
                tip = L["Open this window when I open the auction house (or its small button, if I collapsed it)"],
                onClick = function(checked) WindowSettings().autoOpen = checked and true or false end })
            UI:ContextMenu(entries)
        end
    end)
    local headerLine = Theme:Fill(header, "line", "ARTWORK")
    headerLine:SetPoint("BOTTOMLEFT")
    headerLine:SetPoint("BOTTOMRIGHT")
    headerLine:SetHeight(1)

    local title = UI:Text(header, "Title", L["Auction workbench"])
    title:SetPoint("LEFT", PAD, 0)
    -- 拍卖行开着时 × 收成小按钮（像专业工作台贴在专业窗口旁时那样），否则直接关掉
    f.close = UI:CloseButton(header, function()
        if auctionOpen then
            Bench:Collapse()
        else
            f:Hide()
        end
    end)
    f.close:SetPoint("RIGHT", -10, 0)
    f.status = UI:Text(header, "Muted")
    f.status:SetPoint("LEFT", title, "RIGHT", 16, -1)
    f.status:SetPoint("RIGHT", f.close, "LEFT", -12, 0)
    f.status:SetJustifyH("RIGHT")
    f.status:SetWordWrap(false)

    -- 工具行：商机筛选（中立更便宜默认 / 阵营更便宜 / 全部）、排序、搜索
    local top = -(HEADER_HEIGHT + 14)
    f.lens = UI:Segmented(f, {
        { id = "neutral", label = L["Neutral cheaper"] },
        { id = "faction", label = (L["%s cheaper"]):format((FactionName())) },
        { id = "all", label = L["All items"] },
    }, function(lens)
        state.lens = lens
        f.list:ResetScroll()
        RefreshList()
    end, 104)
    f.lens:SetPoint("TOPLEFT", PAD, top - 12)
    f.lens:Select(state.lens)

    f.searchBox = UI:SearchBox(f, 180, L["Search name or ID"], function(text)
        state.search = text
        f.list:ResetScroll()
        RefreshList()
    end)
    f.searchBox:SetPoint("LEFT", f.lens, "RIGHT", 12, 0)

    local listPanel = UI:Panel(f, "panel", "lineSoft")
    listPanel:SetPoint("TOPLEFT", PAD, top - 40)
    listPanel:SetPoint("BOTTOMLEFT", PAD, 36)
    listPanel:SetWidth(LIST_WIDTH)
    f.list = UI:List(listPanel, 22, function(itemID)
        state.selected = itemID
        RefreshDetail()
    end)
    f.list:SetPoint("TOPLEFT", 1, -1)
    f.list:SetPoint("BOTTOMRIGHT", -1, 1)
    f.list.onRefresh = RequestVisibleNames
    -- 点表头排序：再点同一列反过来；换一列时数字从大到小、名字按字母
    f.list:SetColumns({
        { title = L["Item"], sort = "name" },
        { title = L["Neutral"], width = MONEY_WIDTH, sort = "neutral" },
        { title = (FactionName()), width = MONEY_WIDTH, sort = "faction" },
        { title = L["Profit each"], width = MONEY_WIDTH, sort = "profit" },
        { title = L["Margin"], width = MARGIN_WIDTH, sort = "margin" },
    })
    f.list.onSort = function(key)
        if state.sort == key then
            state.ascending = not state.ascending
        else
            state.sort, state.ascending = key, key == "name"
        end
        f.list:SetSortIndicator(state.sort, state.ascending)
        f.list:ResetScroll()
        RefreshList()
    end
    f.list:SetSortIndicator(state.sort, state.ascending)
    f.list.onEntryEnter = function(row, itemID)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()
    end
    f.countText = UI:Text(f, "Muted")
    f.countText:SetPoint("TOPLEFT", listPanel, "BOTTOMLEFT", 2, -8)

    local detailPanel = UI:Panel(f, "panel", "lineSoft")
    detailPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 12, 0)
    detailPanel:SetPoint("BOTTOMRIGHT", -PAD, 36)
    f.detailText = UI:Text(detailPanel, "Small")
    f.detailText:SetPoint("TOPLEFT", 14, -12)
    f.detailText:SetPoint("RIGHT", -14, 0)
    f.detailText:SetJustifyH("LEFT")
    f.detailText:SetJustifyV("TOP")
    f.detailText:SetSpacing(3)

    -- 走势图占详情区下半部分（随窗口变高），上方是时间范围 7 / 30 / 180 天或全部
    f.chart = UI:TrendChart(detailPanel, CHART_MARGIN)
    f.chart:SetPoint("BOTTOMLEFT", 10, 10)
    f.chart:SetPoint("BOTTOMRIGHT", -10, 10)
    f.chart:SetHeight(220)
    f.chart:SetEmptyText(L["No history yet: scan the auction house on different days to build a trend."])
    f.range = UI:Segmented(detailPanel, {
        { id = 7, label = (L["%d days"]):format(7) },
        { id = 30, label = (L["%d days"]):format(30) },
        { id = 180, label = (L["%d days"]):format(180) },
        { id = 0, label = L["All"] },
    }, function(range)
        state.range = range > 0 and range or nil
        RefreshDetail()
    end, 64)
    f.range:SetPoint("BOTTOMLEFT", f.chart, "TOPLEFT", 4, 8)
    f.range:Select(state.range or 0)
    local trendTitle = UI:Text(detailPanel, "Muted", C("gold") .. (FactionName()) .. "|r / " .. C("blue") .. L["Neutral"] .. "|r  "
        .. L["daily lowest buyout from your scans"])
    trendTitle:SetPoint("LEFT", f.range, "RIGHT", 10, 0)
    detailPanel:SetScript("OnSizeChanged", function(_, _, height)
        f.chart:SetHeight(math.max(180, floor((height or 0) * CHART_SHARE)))
    end)

    f.grip = ResizeGrip(f)
    f:SetScript("OnShow", function()
        if tab then
            tab:Hide()
        end
        RefreshList()
    end)
    -- 拍卖行开着时窗口被关掉（Esc 等），留下小按钮，随时点开
    f:SetScript("OnHide", function()
        if auctionOpen then
            ShowTab()
        end
    end)
    return f
end

-- 打开或收起独立窗口；从 /wh 主窗口导航打开时先关掉主窗口。
-- 战斗中不打开（几千件物品的比价是重计算）
function Bench:Toggle(forceShow)
    if not Module.enabled then
        return
    end
    if not (page and page:IsShown() and not forceShow) and InCombatLockdown() then
        ns:Print(L["Available after combat."])
        return
    end
    if not page then
        CreateWindow()
    end
    if page:IsShown() and not forceShow then
        page:Hide()
    else
        page:Show()
        page:Raise()
        RefreshList()
    end
end

-- 收成小按钮（拍卖行开着时）；下次打开拍卖行也先只显示小按钮
function Bench:Collapse()
    WindowSettings().collapsed = true
    if page then
        page:Hide()
    end
    if auctionOpen then
        ShowTab()
    end
end

-- 从小按钮展开
function Bench:Expand()
    WindowSettings().collapsed = nil
    if tab then
        tab:Hide()
    end
    self:Toggle(true)
    if page and auctionOpen then
        page.openedWithAuction = true
    end
end

-- 打开拍卖行：默认自动打开工作台；上次收起了就只显示小按钮。关掉“随拍卖行打开”时什么也不做
local function OnAuctionHouseShow()
    auctionOpen = true
    if WindowSettings().autoOpen == false then
        return
    end
    if page and page:IsShown() then
        return
    end
    if WindowSettings().collapsed then
        ShowTab()
        return
    end
    Bench:Toggle(true)
    if page then
        PlaceWindow(page)
        page.openedWithAuction = true
    end
end

-- 关闭拍卖行：小按钮收起；随拍卖行自动打开的工作台一起关掉（自己另外打开的留着）
local function OnAuctionHouseClosed()
    auctionOpen = false
    if tab then
        tab:Hide()
    end
    if page and page.openedWithAuction then
        page.openedWithAuction = nil
        page:Hide()
    end
end

local EVENTS = {
    GET_ITEM_INFO_RECEIVED = OnItemInfo,
    AUCTION_HOUSE_SHOW = OnAuctionHouseShow,
    AUCTION_HOUSE_CLOSED = OnAuctionHouseClosed,
}

function Module:OnEnable()
    for event, handler in pairs(EVENTS) do
        ns:RegisterEvent(event, handler)
    end
    -- 导航里的“拍卖行工作台”不切换主窗口的页面，而是关掉主窗口、打开独立窗口
    ns.MainFrame:RegisterTab({ id = "auctionbench", title = L["Auction workbench"], order = 35, action = function()
        if Module.enabled then
            ns.MainFrame:Hide()
            Bench:Toggle(true)
        end
    end })
    ns:AddCommand("auction", L["open or close the auction workbench window"], function()
        Bench:Toggle()
    end)
    if AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown() then
        OnAuctionHouseShow()
    end
end

function Module:OnDisable()
    for event, handler in pairs(EVENTS) do
        ns:UnregisterEvent(event, handler)
    end
    auctionOpen = false
    if tab then
        tab:Hide()
    end
    if page then
        page:Hide()
    end
end

-- 测试用
Bench.Page = function()
    return page
end
Bench.Tab = function()
    return tab
end
Bench.State = state
