local ADDON_NAME, ns = ...
local Theme, UI = ns.Theme, ns.UI

-- 主窗口：顶部标题栏，左侧导航，右侧内容页。功能模块和其他插件通过 RegisterTab 注册页面，
-- 页面在第一次切换到时才创建。窗口本身也在第一次打开时才创建。视觉与网站深色主题一致。
local MainFrame = {}
ns.MainFrame = MainFrame

local FRAME_WIDTH, FRAME_HEIGHT = 940, 600
local HEADER_HEIGHT, SIDEBAR_WIDTH = 44, 176
-- 标题字标：512×64 的贴图按 0.375 倍显示
local WORDMARK = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Wordmark"
local WORDMARK_WIDTH, WORDMARK_HEIGHT = 192, 24

local frame
local tabs = {}       -- 已注册的页面定义，按 order 排序
local tabsByID = {}
local selectedID

--------------------------------------------------------------------------------
-- 页面注册
--------------------------------------------------------------------------------

-- definition = { id = "唯一 ID", title = "导航文字"（或 titleKey = 本地化键，显示时按当前界面语言翻译），order = 数字（小的在前），
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

-- 首页（“今日面板”）在 UI/Home.lua

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
    Theme:Paint(topLine, "gold")

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
    Theme:Paint(mark, "gold")
    mark:SetRotation(math.rad(45))

    -- 标题用字标贴图：站名“WoW Handbook”以网站的标题字体渲染成图片（tools/make_wordmark.py），
    -- 插件不带字体文件。贴图是白字加透明通道，这里按正文色着色；各语言界面都显示这个站名。
    -- 版本号不放在标题栏，见设置页的“关于”
    local title = header:CreateTexture(nil, "ARTWORK")
    title:SetTexture(WORDMARK)
    title:SetSize(WORDMARK_WIDTH, WORDMARK_HEIGHT)
    title:SetPoint("LEFT", mark, "RIGHT", 10, 0)
    Theme:Track(title, function(texture)
        local color = Theme.colors.text
        texture:SetVertexColor(color[1], color[2], color[3])
    end)
    title:SetVertexColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3])
    f.title = title -- 供测试使用

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
            Theme:Paint(button.accent, "gold")
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
        button.label:SetText(definition.titleKey and ns.L[definition.titleKey] or definition.title)
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

-- 配色方案或背景透明度变化：登记过的框架与贴图由主题重刷，这里补上导航的选中态，
-- 并让当前页面重新生成内容（文字里内嵌的强调色跟着换）
Theme:OnChange(function()
    if not frame then
        return
    end
    for _, button in ipairs(frame.navButtons) do
        PaintNav(button)
    end
    local definition, page = tabsByID[selectedID], frame.pages[selectedID]
    if definition and page and page:IsVisible() and definition.onShow then
        definition.onShow(page)
    end
end)

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
-- 对其他插件公开的接口：注册页面、在地图上标记坐标、共用主题与控件
--------------------------------------------------------------------------------

WowHandbookAPI = {
    RegisterTab = function(definition)
        MainFrame:RegisterTab(definition)
    end,
    Open = function(id)
        MainFrame:Open(id)
    end,
    -- 在地图上标记一个坐标（0–100）并打开大地图，规则与插件自己的“地图标记”一致
    ShowOnMap = function(uiMapID, x, y, title)
        return ns.Waypoints:ShowOnMap(uiMapID, x, y, title)
    end,
    -- 共用的主题与控件，让其他页面与主窗口风格一致
    Theme = Theme,
    UI = UI,
}
