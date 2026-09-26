local ADDON_NAME, ns = ...

-- 界面主题：与网站 wowhandbook.com 的深色主题一致（金属深色底、金色强调、奶油色文字）。
-- 颜色用 0–1 的 RGBA；字体沿用游戏字体（保留多语言字形回退），只改颜色和大小层级。
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

-- 给框架加上纯色底和 1 像素边框；框架必须用 "BackdropTemplate" 创建
function Theme:Skin(frame, background, border)
    frame:SetBackdrop({ bgFile = self.WHITE, edgeFile = self.WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(self.colors[background or "panel"]))
    frame:SetBackdropBorderColor(unpack(self.colors[border or "line"]))
end

-- 纯色贴图
function Theme:Fill(frame, color, layer, sublevel)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
    texture:SetColorTexture(unpack(self.colors[color]))
    return texture
end
