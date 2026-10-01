local ADDON_NAME, ns = ...

-- 界面主题：与网站 wowhandbook.com 的深色主题一致（金属深色底、强调色、奶油色文字）。
-- 颜色用 0–1 的 RGBA；字体沿用游戏字体（保留多语言字形回退），只改颜色和大小层级。
-- 强调色（gold 等几个键）与背景透明度可由玩家在设置里调整，见下方“配色方案与背景透明度”：
-- 颜色表原地改写，键名不变（gold 仍叫 gold，值可能是职业色）。
local Theme = {}
ns.Theme = Theme

local function Hex(hex, alpha)
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    return { r, g, b, alpha or 1 }
end

Theme.colors = {
    window = Hex("0e1014", 0.97),  -- 窗口底
    menu = Hex("0e1014", 0.97),    -- 下拉菜单、快捷菜单、对话框（不随背景透明度变化，保证可读）
    none = Hex("000000", 0),       -- 透明（幽灵按钮未悬停时）
    sidebar = Hex("121418", 1),    -- 侧栏
    panel = Hex("15181d", 1),      -- 卡片、输入框
    raised = Hex("1e2229", 1),     -- 悬停、按下
    stripe = Hex("ffffff", 0.025), -- 列表斑马纹
    selected = Hex("e0b458", 0.12),
    line = Hex("3a3d42", 1),       -- 边框、分隔线
    lineSoft = Hex("2a2d33", 1),
    gold = Hex("e0b458", 1),       -- 强调色
    goldDim = Hex("b8862c", 1),
    text = Hex("f4e8cc", 1),       -- 正文
    textDim = Hex("d9ccb0", 1),
    muted = Hex("8a8374", 1),      -- 次要文字
    green = Hex("46bf72", 1),
    red = Hex("d8664a", 1),
    blue = Hex("6f95d6", 1),
    -- 半透明卡片（副本进度小窗等浮在游戏画面上的界面）
    glass = Hex("0b0d11", 0.78),    -- 卡片底
    glassLine = Hex("e0b458", 0.28), -- 卡片边框
    glassHover = Hex("ffffff", 0.07), -- 行悬停
    track = Hex("ffffff", 0.09),    -- 进度条底
    greenDim = Hex("46bf72", 0.55), -- 已完成的进度段
    -- 表格整行高亮底色（技能书：现在可学）
    goldTint = Hex("e0b458", 0.14),
    -- 动作条按钮图标的染色：超出距离染红；恢复时沿用游戏的可用性颜色（可用原色、缺法力偏蓝、不能用变灰）
    actionOutOfRange = Hex("ff3a3a", 1),
    actionUsable = Hex("ffffff", 1),
    actionNoMana = Hex("8080ff", 1),
    actionUnusable = Hex("666666", 1),
}

-- 文字里内嵌颜色用的十六进制（|cffXXXXXX）
Theme.hex = {
    gold = "ffe0b458",
    text = "fff4e8cc",
    textDim = "ffd9ccb0",
    muted = "ff8a8374",
    green = "ff46bf72",
    red = "ffd8664a",
    blue = "ff6f95d6",
    -- 专业配方难度，沿用游戏的约定：橙色必涨技能、黄色多半涨、绿色偶尔涨、灰色不涨
    skillOrange = "ffff8040",
    skillYellow = "ffffd100",
    skillGreen = "ff40bf40",
    skillGray = "ff808080",
}

function Theme:Color(text, name)
    return "|c" .. (self.hex[name] or name) .. tostring(text) .. "|r"
end

Theme.WHITE = "Interface\\Buttons\\WHITE8X8"

-- 字体层级：继承游戏字体对象，再统一设置颜色
local FONT_SPECS = {
    Title = { "GameFontNormalLarge", "text" },
    Heading = { "GameFontNormal", "gold" },
    Body = { "GameFontHighlight", "text" },
    Small = { "GameFontHighlightSmall", "textDim" },
    Muted = { "GameFontHighlightSmall", "muted" },
    Accent = { "GameFontNormalSmall", "gold" },
}

Theme.fonts = {}
for name, spec in pairs(FONT_SPECS) do
    local font = CreateFont("WowHandbookFont" .. name)
    font:SetFontObject(spec[1])
    font:SetTextColor(unpack(Theme.colors[spec[2]]))
    Theme.fonts[name] = font
end

--------------------------------------------------------------------------------
-- 上色与登记：用主题上过色的框架、贴图都记下来，配色方案或透明度变化时原样重刷，不用重载界面。
-- 状态会变的控件（按钮的选中 / 悬停等）用 Theme:Track(对象, 重画函数) 登记自己的重画函数。
--------------------------------------------------------------------------------

local tracked = setmetatable({}, { __mode = "k" }) -- [框架或贴图] = 重画函数

function Theme:Track(object, painter)
    tracked[object] = painter
end

-- 给框架加上纯色底和 1 像素边框；框架必须用 "BackdropTemplate" 创建
function Theme:Skin(frame, background, border)
    background, border = background or "panel", border or "line"
    frame:SetBackdrop({ bgFile = self.WHITE, edgeFile = self.WHITE, edgeSize = 1 })
    local function Paint(target)
        target:SetBackdropColor(unpack(self.colors[background]))
        target:SetBackdropBorderColor(unpack(self.colors[border]))
    end
    Paint(frame)
    tracked[frame] = Paint
end

-- 给已有贴图上纯色（跟随配色变化）
function Theme:Paint(texture, color)
    local function Paint(target)
        target:SetColorTexture(unpack(self.colors[color]))
    end
    Paint(texture)
    tracked[texture] = Paint
    return texture
end

-- 纯色贴图
function Theme:Fill(frame, color, layer, sublevel)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
    return self:Paint(texture, color)
end

--------------------------------------------------------------------------------
-- 配色方案与背景透明度
-- 方案只换强调色：class 跟随当前角色的职业，gold 是与网站一致的金色，其余为指定某个职业的颜色。
-- 透明度只作用于大面积底色（窗口、侧栏、卡片），文字、边框与菜单保持不透明。
--------------------------------------------------------------------------------

-- 职业色（游戏的职业代表色）；键为数据里的职业键
local CLASS_ACCENTS = {
    warrior = "c69b6d",
    paladin = "f48cba",
    hunter = "aad372",
    rogue = "fff468",
    priest = "ffffff",
    shaman = "0070dd",
    mage = "3fc7eb",
    warlock = "8788ee",
    druid = "ff7c0a",
}
local DEFAULT_ACCENT = "e0b458"

Theme.CLASS_ORDER = { "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }
Theme.MIN_OPACITY, Theme.MAX_OPACITY = 30, 100

-- 可选的方案：class（跟随职业）、gold（网站金色）、各职业
Theme.SCHEMES = { "class", "gold" }
for _, class in ipairs(Theme.CLASS_ORDER) do
    tinsert(Theme.SCHEMES, class)
end

-- 方案对应的强调色（六位十六进制）；class 按当前角色的职业，取不到职业时用金色
function Theme:AccentHex(scheme)
    if scheme == "class" then
        local _, classFile
        if UnitClass then
            _, classFile = UnitClass("player")
        end
        scheme = classFile and classFile:lower() or "gold"
    end
    return CLASS_ACCENTS[scheme] or DEFAULT_ACCENT
end

-- 强调色派生出的各个键：{ 键, 亮度系数, 透明度 }
local ACCENT_KEYS = {
    { "gold", 1, 1 },
    { "goldDim", 0.74, 1 },
    { "selected", 1, 0.12 },
    { "goldTint", 1, 0.14 },
    { "glassLine", 1, 0.28 },
}
-- 随背景透明度变化的底色及其原始透明度
local BACKGROUND_ALPHA = { window = 0.97, sidebar = 1, panel = 1 }

local listeners = {}

-- 配色或透明度变化后调用 listener()（页面用它重画自己动态上色的部分）
function Theme:OnChange(listener)
    tinsert(listeners, listener)
end

-- 应用配色方案与背景透明度（百分数）；省略时保持当前值。原地改写颜色表，再重刷登记过的框架、贴图与字体
function Theme:Apply(scheme, opacity)
    self.scheme = scheme or self.scheme or "gold"
    opacity = tonumber(opacity) or self.opacity or self.MAX_OPACITY
    self.opacity = math.min(self.MAX_OPACITY, math.max(self.MIN_OPACITY, opacity))

    local accent = Hex(self:AccentHex(self.scheme))
    for _, spec in ipairs(ACCENT_KEYS) do
        local color = self.colors[spec[1]]
        color[1], color[2], color[3], color[4] = accent[1] * spec[2], accent[2] * spec[2], accent[3] * spec[2], spec[3]
    end
    self.hex.gold = ("ff%02x%02x%02x"):format(math.floor(accent[1] * 255 + 0.5), math.floor(accent[2] * 255 + 0.5),
        math.floor(accent[3] * 255 + 0.5))
    for name, alpha in pairs(BACKGROUND_ALPHA) do
        self.colors[name][4] = alpha * self.opacity / 100
    end

    for name, spec in pairs(FONT_SPECS) do
        self.fonts[name]:SetTextColor(unpack(self.colors[spec[2]]))
    end
    -- 先抄一份再重刷：重画函数里可能新建并登记控件（列表补行），不能边遍历边改登记表
    local snapshot = {}
    for object, painter in pairs(tracked) do
        tinsert(snapshot, { object, painter })
    end
    for _, entry in ipairs(snapshot) do
        entry[2](entry[1])
    end
    for _, listener in ipairs(listeners) do
        listener()
    end
end
