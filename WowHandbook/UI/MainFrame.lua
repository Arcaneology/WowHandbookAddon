local ADDON_NAME, ns = ...
local L = ns.L
local Theme, UI = ns.Theme, ns.UI

-- 主窗口：顶部标题栏，左侧导航，右侧内容页。功能模块和其他插件通过 RegisterTab 注册页面，
-- 页面在第一次切换到时才创建。窗口本身也在第一次打开时才创建。视觉与网站深色主题一致。
local MainFrame = {}
ns.MainFrame = MainFrame

local FRAME_WIDTH, FRAME_HEIGHT = 940, 600
local HEADER_HEIGHT, SIDEBAR_WIDTH = 44, 176

local frame
local tabs = {}       -- 已注册的页面定义，按 order 排序
local tabsByID = {}
local selectedID

--------------------------------------------------------------------------------
-- 页面注册
--------------------------------------------------------------------------------

-- definition = { id = "唯一 ID", title = "导航文字", order = 数字（小的在前），
--                create = function(parent) return 页面框架 end, onShow = function(page) end（可选） }
function MainFrame:RegisterTab(definition)
    assert(type(definition.id) == "string" and type(definition.create) == "function", "invalid tab definition")
    if tabsByID[definition.id] then
        return
    end
    definition.order = definition.order or 100
    tabsByID[definition.id] = definition
    tinsert(tabs, definition)
    table.sort(tabs, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.id < b.id
    end)
    if frame then
        self:LayoutNav()
    end
end

function MainFrame:HasTab(id)
    return tabsByID[id] ~= nil
end

--------------------------------------------------------------------------------
-- 概览页（内置）
--------------------------------------------------------------------------------

-- 概览页的功能卡片：tab 为打开的页面；hint 为没有页面时的说明
local FEATURES = {
    { "Dungeon guide", "Quests, quest chains and loot for every dungeon, with one-click NPC waypoints.", tab = "dungeons" },
    { "Spells by level", "Your full spellbook by level: what to learn now and where to train it.", tab = "spellbook" },
    { "World map", "Zone level ranges, flight paths you still need, and a larger map.", hint = "Open your world map" },
    { "Travel", "Boats, zeppelins and the fastest way to get where you are going.", hint = "Coming soon" },
}

local function CreateHomePage(parent)
    local page = CreateFrame("Frame", nil, parent)

    local eyebrow = UI:Text(page, "Accent", L["World of Warcraft: Forever"])
    eyebrow:SetPoint("TOPLEFT", 28, -28)

    local title = UI:Text(page, "Title", L["Your companion for World of Warcraft: Forever."])
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -8)

    local subtitle = UI:Text(page, "Small", L["Dungeon guide, spells by level and more are on the way."])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

    local heading = UI:Text(page, "Heading", L["Features"])
    heading:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -28)

    -- 2 x 2 功能卡片（内容区宽 762，左右各留 28）
    local CARD_WIDTH, CARD_HEIGHT, GAP = 347, 96, 12
    for index, item in ipairs(FEATURES) do
        local card = UI:Panel(page, "panel", "lineSoft")
        card:SetSize(CARD_WIDTH, CARD_HEIGHT)
        local column = (index - 1) % 2
        local rowIndex = floor((index - 1) / 2)
        card:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", column * (CARD_WIDTH + GAP), -12 - rowIndex * (CARD_HEIGHT + GAP))
        local accent = card:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("TOPLEFT", 1, -1)
        accent:SetPoint("BOTTOMLEFT", 1, 1)
        accent:SetWidth(2)
        accent:SetColorTexture(unpack(Theme.colors[item.tab and "gold" or "goldDim"]))
        local cardTitle = UI:Text(card, "Heading", L[item[1]])
        cardTitle:SetPoint("TOPLEFT", 16, -14)
        local cardBody = UI:Text(card, "Small", L[item[2]])
        cardBody:SetPoint("TOPLEFT", cardTitle, "BOTTOMLEFT", 0, -8)
        cardBody:SetWidth(CARD_WIDTH - 32)
        cardBody:SetJustifyV("TOP")
        if item.tab then
            local open = UI:Button(card, L["Open"], 70, 22, "primary")
            open:SetPoint("BOTTOMRIGHT", -12, 10)
            open:SetScript("OnClick", function()
                MainFrame:SelectTab(item.tab)
            end)
        else
            local hint = UI:Text(card, "Muted", L[item.hint])
            hint:SetPoint("BOTTOMRIGHT", -14, 12)
        end
    end

    local extrasKey = "Also on: spell ranks upgrade on your action bars, new spells go to an empty slot, "
        .. "and gray items sell at vendors. Change these in Settings."
    local extras = UI:Text(page, "Muted", L[extrasKey])
    extras:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -12 - 2 * (CARD_HEIGHT + GAP) - 4)
    extras:SetWidth(706)

    -- 网站区（链接规范见 docs/05-site-link-policy.md）
    local site = UI:Panel(page, "raised", "lineSoft")
    site:SetPoint("BOTTOMLEFT", 28, 24)
    site:SetPoint("BOTTOMRIGHT", -28, 24)
    site:SetHeight(64)
    local siteTitle = UI:Text(site, "Heading", "wowhandbook.com")
    siteTitle:SetPoint("TOPLEFT", 16, -14)
    local siteBody = UI:Text(site, "Small", L["Full guides, changes from Classic and planning tools on the website:"])
    siteBody:SetPoint("TOPLEFT", siteTitle, "BOTTOMLEFT", 0, -6)
    local copyButton = UI:Button(site, L["Copy website link"], 150, 26, "primary")
    copyButton:SetPoint("RIGHT", -16, 0)
    copyButton:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("home"))
    end)
    siteBody:SetPoint("RIGHT", copyButton, "LEFT", -16, 0)

    return page
end

MainFrame:RegisterTab({ id = "home", title = L["Home"], order = 0, create = CreateHomePage })

--------------------------------------------------------------------------------
-- 窗口、导航
--------------------------------------------------------------------------------

local function Create()
    local f = CreateFrame("Frame", "WowHandbookMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    Theme:Skin(f, "window", "line")
    f:Hide()
    tinsert(UISpecialFrames, f:GetName()) -- Esc 关闭

    -- 顶部金色细线
    local topLine = f:CreateTexture(nil, "OVERLAY")
    topLine:SetPoint("TOPLEFT", 1, -1)
    topLine:SetPoint("TOPRIGHT", -1, -1)
    topLine:SetHeight(2)
    topLine:SetColorTexture(unpack(Theme.colors.gold))

    -- 标题栏（拖动窗口）
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -3)
    header:SetPoint("TOPRIGHT", -1, -3)
    header:SetHeight(HEADER_HEIGHT - 3)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        f:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
    end)

    local mark = header:CreateTexture(nil, "ARTWORK")
    mark:SetSize(10, 10)
    mark:SetPoint("LEFT", 18, 0)
    mark:SetColorTexture(unpack(Theme.colors.gold))
    mark:SetRotation(math.rad(45))

    local title = UI:Text(header, "Title", L["WoW Handbook"])
    title:SetPoint("LEFT", mark, "RIGHT", 12, 0)
    local version = UI:Text(header, "Muted", ns.version)
    version:SetPoint("LEFT", title, "RIGHT", 8, -1)

    local close = UI:CloseButton(header, function()
        f:Hide()
    end)
    close:SetPoint("RIGHT", -10, 0)

    local headerLine = f:CreateTexture(nil, "ARTWORK")
    headerLine:SetPoint("TOPLEFT", 1, -HEADER_HEIGHT)
    headerLine:SetPoint("TOPRIGHT", -1, -HEADER_HEIGHT)
    headerLine:SetHeight(1)
    headerLine:SetColorTexture(unpack(Theme.colors.lineSoft))

    -- 左侧导航
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", 1, -HEADER_HEIGHT - 1)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    Theme:Fill(sidebar, "sidebar"):SetAllPoints()
    local sidebarLine = sidebar:CreateTexture(nil, "ARTWORK")
    sidebarLine:SetPoint("TOPRIGHT")
    sidebarLine:SetPoint("BOTTOMRIGHT")
    sidebarLine:SetWidth(1)
    sidebarLine:SetColorTexture(unpack(Theme.colors.lineSoft))
    f.sidebar = sidebar
    f.navButtons = {}

    local siteLabel = UI:Text(sidebar, "Muted", "wowhandbook.com")
    siteLabel:SetPoint("BOTTOMLEFT", 18, 16)

    -- 内容区
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", -1, 1)
    f.content = content
    f.pages = {}
    return f
end

local function PaintNav(button)
    local selected = button.tabID == selectedID
    local hovered = button:IsMouseOver()
    if selected then
        button.background:SetColorTexture(unpack(Theme.colors.selected))
        button.label:SetTextColor(unpack(Theme.colors.gold))
    elseif hovered then
        button.background:SetColorTexture(unpack(Theme.colors.raised))
        button.label:SetTextColor(unpack(Theme.colors.text))
    else
        button.background:SetColorTexture(0, 0, 0, 0)
        button.label:SetTextColor(unpack(Theme.colors.textDim))
    end
    button.accent:SetShown(selected)
end

function MainFrame:LayoutNav()
    for index, definition in ipairs(tabs) do
        local button = frame.navButtons[index]
        if not button then
            button = CreateFrame("Button", nil, frame.sidebar)
            button:SetHeight(34)
            button.background = button:CreateTexture(nil, "BACKGROUND")
            button.background:SetAllPoints()
            button.accent = button:CreateTexture(nil, "ARTWORK")
            button.accent:SetPoint("TOPLEFT")
            button.accent:SetPoint("BOTTOMLEFT")
            button.accent:SetWidth(3)
            button.accent:SetColorTexture(unpack(Theme.colors.gold))
            button.label = UI:Text(button, "Body")
            button.label:SetPoint("LEFT", 18, 0)
            button:SetScript("OnClick", function(navButton)
                MainFrame:SelectTab(navButton.tabID)
            end)
            button:SetScript("OnEnter", PaintNav)
            button:SetScript("OnLeave", PaintNav)
            frame.navButtons[index] = button
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", 0, -12 - (index - 1) * 36)
        button:SetPoint("RIGHT", -1, 0)
        button.tabID = definition.id
        button.label:SetText(definition.title)
        button:Show()
        PaintNav(button)
    end
end

function MainFrame:SelectTab(id)
    local definition = tabsByID[id] or tabs[1]
    selectedID = definition.id
    for _, button in ipairs(frame.navButtons) do
        PaintNav(button)
    end
    for pageID, page in pairs(frame.pages) do
        page:SetShown(pageID == selectedID)
    end
    local page = frame.pages[selectedID]
    if not page then
        page = definition.create(frame.content)
        page:SetAllPoints(frame.content)
        frame.pages[selectedID] = page
    end
    page:Show()
    if definition.onShow then
        definition.onShow(page)
    end
end

local function Ensure()
    if not frame then
        frame = Create()
        MainFrame:LayoutNav()
        MainFrame:SelectTab(selectedID or "home")
    end
    return frame
end

function MainFrame:Toggle()
    Ensure()
    frame:SetShown(not frame:IsShown())
end

function MainFrame:Hide()
    if frame then
        frame:Hide()
    end
end

-- 打开窗口并切到指定页面
function MainFrame:Open(id)
    Ensure()
    frame:Show()
    self:SelectTab(id)
end

--------------------------------------------------------------------------------
-- 对其他插件公开的接口（如内部采集插件注册“采集数据”页）
--------------------------------------------------------------------------------

WowHandbookAPI = {
    RegisterTab = function(definition)
        MainFrame:RegisterTab(definition)
    end,
    Open = function(id)
        MainFrame:Open(id)
    end,
    -- 共用的主题与控件，让其他页面与主窗口风格一致
    Theme = Theme,
    UI = UI,
}
