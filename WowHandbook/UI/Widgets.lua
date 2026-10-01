local ADDON_NAME, ns = ...

-- 自绘控件：按钮、分段选择、搜索框、勾选框、细滚动条、滚动区域、虚拟列表、统计卡片。
-- 统一使用 ns.Theme 的颜色与字体；通过 WowHandbookAPI.UI 也提供给其他插件使用。
local Theme = ns.Theme
local C = Theme.colors
local UI = {}
ns.UI = UI

-- 贴图上纯色并登记，配色方案变化时自动重刷
local function SetColor(texture, name)
    Theme:Paint(texture, name)
end

--------------------------------------------------------------------------------
-- 面板
--------------------------------------------------------------------------------

function UI:Panel(parent, background, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Theme:Skin(frame, background or "panel", border or "lineSoft")
    return frame
end

function UI:Text(parent, font, text)
    local fontString = parent:CreateFontString(nil, "OVERLAY", Theme.fonts[font or "Body"]:GetName())
    fontString:SetJustifyH("LEFT")
    if text then
        fontString:SetText(text)
    end
    return fontString
end

--------------------------------------------------------------------------------
-- 按钮：variant = "default" | "primary" | "ghost"
--------------------------------------------------------------------------------

local function PaintButton(button)
    local hovered = button:IsMouseOver() and button:IsEnabled()
    local variant = button.variant
    local background, border, text
    if not button:IsEnabled() then
        background, border, text = "panel", "lineSoft", "muted"
    elseif button.selected then
        background, border, text = "selected", "goldDim", "gold"
    elseif variant == "primary" then
        background, border, text = hovered and "raised" or "panel", hovered and "gold" or "goldDim", "gold"
    elseif variant == "ghost" then
        background, border, text = hovered and "raised" or "none", hovered and "line" or "none", hovered and "text" or "textDim"
    else
        background, border, text = hovered and "raised" or "panel", hovered and "goldDim" or "line", "text"
    end
    button:SetBackdropColor(unpack(C[background]))
    button:SetBackdropBorderColor(unpack(C[border]))
    button.label:SetTextColor(unpack(C[text]))
end

function UI:Button(parent, text, width, height, variant)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 120, height or 24)
    Theme:Skin(button)
    button.variant = variant or "default"
    local label = button:CreateFontString(nil, "OVERLAY", Theme.fonts.Small:GetName())
    label:SetPoint("CENTER", 0, 0)
    button.label = label
    function button:SetLabel(value)
        label:SetText(value)
    end
    function button:SetSelected(selected)
        self.selected = selected
        PaintButton(self)
    end
    button:SetLabel(text or "")
    button:HookScript("OnEnter", PaintButton)
    button:HookScript("OnLeave", PaintButton)
    button:HookScript("OnEnable", PaintButton)
    button:HookScript("OnDisable", PaintButton)
    Theme:Track(button, PaintButton)
    button:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            label:SetPoint("CENTER", 0, -1)
        end
    end)
    button:SetScript("OnMouseUp", function()
        label:SetPoint("CENTER", 0, 0)
    end)
    PaintButton(button)
    return button
end

-- 两条交叉细线组成的“×”图标（不依赖字体字形）
function UI:CrossIcon(parent, size)
    local lines = {}
    for i, angle in ipairs({ 45, -45 }) do
        local line = parent:CreateTexture(nil, "OVERLAY")
        line:SetSize(size, 1.5)
        line:SetPoint("CENTER")
        line:SetColorTexture(1, 1, 1, 1)
        line:SetRotation(math.rad(angle))
        lines[i] = line
    end
    function lines.SetColor(_, color)
        for i = 1, 2 do
            lines[i]:SetVertexColor(unpack(C[color]))
        end
    end
    lines:SetColor("muted")
    return lines
end

-- 关闭或清除按钮：透明底，悬停时变亮
function UI:CloseButton(parent, onClick, size)
    local button = CreateFrame("Button", nil, parent)
    size = size or 24
    button:SetSize(size, size)
    local icon = UI:CrossIcon(button, size * 0.5)
    button:SetScript("OnEnter", function()
        icon:SetColor("gold")
    end)
    button:SetScript("OnLeave", function()
        icon:SetColor("muted")
    end)
    button:SetScript("OnClick", onClick)
    return button
end

--------------------------------------------------------------------------------
-- 分段选择：items = { { id = "a", label = "A" }, ... }
--------------------------------------------------------------------------------

function UI:Segmented(parent, items, onChange, buttonWidth)
    local group = CreateFrame("Frame", nil, parent)
    group.buttons = {}
    local previous
    for _, item in ipairs(items) do
        local button = UI:Button(group, item.label, buttonWidth or 88, 24)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", -1, 0)
        else
            button:SetPoint("LEFT", 0, 0)
        end
        button:SetScript("OnClick", function()
            group:Select(item.id)
            onChange(item.id)
        end)
        group.buttons[item.id] = button
        previous = button
    end
    group:SetSize((buttonWidth or 88) * #items, 24)
    function group:Select(id)
        for buttonID, button in pairs(self.buttons) do
            button:SetSelected(buttonID == id)
        end
    end
    function group:SetLabel(id, label)
        self.buttons[id]:SetLabel(label)
    end
    return group
end

--------------------------------------------------------------------------------
-- 下拉选择：按钮显示当前项，点开后在按钮下方列出全部选项
--------------------------------------------------------------------------------

function UI:Dropdown(parent, items, onChange, width)
    local dropdown = UI:Button(parent, "", width or 150, 24)
    dropdown.onChange = onChange -- 供测试使用
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", 10, 0)
    dropdown.label:SetPoint("RIGHT", -22, 0)
    dropdown.label:SetJustifyH("LEFT")
    local arrow = dropdown:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    arrow:SetVertexColor(unpack(C.muted))

    -- 菜单挂在 UIParent 上，放在滚动区域里的下拉框展开时不会被裁掉；下拉框隐藏时一起隐藏
    local menu = UI:Panel(UIParent, "menu", "line")
    menu:SetFrameStrata("DIALOG")
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(width or 150)
    menu:EnableMouse(true)
    menu:Hide()
    dropdown.menu = menu
    local buttons = {}

    function dropdown:SetItems(list)
        self.items = list
        for index, item in ipairs(list) do
            local button = buttons[index] or UI:Button(menu, "", (width or 150) - 8, 22, "ghost")
            buttons[index] = button
            button:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 22)
            button:SetLabel(item.label)
            button:SetScript("OnClick", function()
                menu:Hide()
                dropdown:SetValue(item.id)
                onChange(item.id)
            end)
            button:Show()
        end
        for index = #list + 1, #buttons do
            buttons[index]:Hide()
        end
        menu:SetHeight(#list * 22 + 8)
    end

    function dropdown:SetValue(id)
        self.value = id
        for index, item in ipairs(self.items or {}) do
            if item.id == id then
                self:SetLabel(item.label)
            end
            buttons[index]:SetSelected(item.id == id)
        end
    end

    dropdown:SetScript("OnClick", function()
        menu:SetScale(dropdown:GetEffectiveScale() / UIParent:GetEffectiveScale())
        menu:SetShown(not menu:IsShown())
    end)
    dropdown:HookScript("OnHide", function()
        menu:Hide()
    end)
    dropdown:SetItems(items)
    return dropdown
end

--------------------------------------------------------------------------------
-- 搜索框
--------------------------------------------------------------------------------

function UI:SearchBox(parent, width, placeholder, onChange)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width or 180, 24)
    Theme:Skin(box, "panel", "line")
    box:SetFontObject(Theme.fonts.Small)
    box:SetTextInsets(24, 22, 0, 0)
    box:SetAutoFocus(false)
    box:SetMaxLetters(60)

    local icon = box:CreateTexture(nil, "OVERLAY")
    icon:SetSize(12, 12)
    icon:SetPoint("LEFT", 7, 0)
    icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    icon:SetVertexColor(unpack(C.muted))

    local hint = UI:Text(box, "Muted", placeholder or "")
    hint:SetPoint("LEFT", 24, 0)

    local clear = UI:CloseButton(box, function()
        box:SetText("")
        box:ClearFocus()
    end, 18)
    clear:SetPoint("RIGHT", -3, 0)
    clear:Hide()

    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnEnterPressed", box.ClearFocus)
    box:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(unpack(C.goldDim))
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(unpack(C.line))
    end)
    box:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        hint:SetShown(text == "")
        clear:SetShown(text ~= "")
        onChange(text)
    end)
    return box
end

--------------------------------------------------------------------------------
-- 勾选框
--------------------------------------------------------------------------------

function UI:Checkbox(parent, label, onChange)
    local check = CreateFrame("Button", nil, parent)
    check:SetHeight(20)
    local box = CreateFrame("Frame", nil, check, "BackdropTemplate")
    box:SetSize(14, 14)
    box:SetPoint("LEFT", 0, 0)
    Theme:Skin(box, "panel", "line")
    local mark = box:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("TOPLEFT", 3, -3)
    mark:SetPoint("BOTTOMRIGHT", -3, 3)
    SetColor(mark, "gold")
    local text = UI:Text(check, "Small", label)
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)
    check:SetWidth(20 + text:GetStringWidth())

    function check:SetChecked(value)
        self.checked = value and true or false
        mark:SetShown(self.checked)
    end
    function check:GetChecked()
        return self.checked
    end
    check:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        onChange(self.checked)
    end)
    check:SetScript("OnEnter", function()
        box:SetBackdropBorderColor(unpack(C.goldDim))
    end)
    check:SetScript("OnLeave", function()
        box:SetBackdropBorderColor(unpack(C.line))
    end)
    check:SetChecked(false)
    return check
end

--------------------------------------------------------------------------------
-- 细滚动条：SetRange(总量, 可见量, 当前位置)；拖动或点击轨道时调用 onScroll(新位置)
--------------------------------------------------------------------------------

function UI:ScrollBar(parent, onScroll)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetWidth(6)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    SetColor(track, "lineSoft")
    local thumb = CreateFrame("Frame", nil, bar)
    thumb:SetWidth(6)
    local thumbTexture = thumb:CreateTexture(nil, "ARTWORK")
    thumbTexture:SetAllPoints()
    SetColor(thumbTexture, "goldDim")
    thumb:EnableMouse(true)
    bar:EnableMouse(true)

    local total, visible, position = 0, 0, 0

    local function Layout()
        local height = bar:GetHeight()
        if total <= visible or height <= 0 then
            bar:Hide()
            return
        end
        bar:Show()
        local thumbHeight = math.max(24, height * visible / total)
        local top = (height - thumbHeight) * position / (total - visible)
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", bar, "TOP", 0, -top)
    end

    function bar:SetRange(newTotal, newVisible, newPosition)
        total, visible, position = newTotal, newVisible, newPosition
        Layout()
    end

    local function CursorY()
        local _, y = GetCursorPosition()
        return y / bar:GetEffectiveScale()
    end

    local function PositionFromCursor(grabOffset)
        local height = bar:GetHeight()
        local thumbHeight = thumb:GetHeight()
        local fromTop = bar:GetTop() - CursorY() - grabOffset
        local ratio = math.min(1, math.max(0, fromTop / math.max(1, height - thumbHeight)))
        return ratio * (total - visible)
    end

    thumb:SetScript("OnMouseDown", function()
        local grab = thumb:GetTop() - CursorY()
        SetColor(thumbTexture, "gold")
        thumb:SetScript("OnUpdate", function()
            onScroll(PositionFromCursor(grab))
        end)
    end)
    thumb:SetScript("OnMouseUp", function()
        thumb:SetScript("OnUpdate", nil)
        SetColor(thumbTexture, "goldDim")
    end)
    bar:SetScript("OnMouseDown", function()
        onScroll(PositionFromCursor(thumb:GetHeight() / 2))
    end)
    bar:SetScript("OnSizeChanged", Layout)
    return bar
end

--------------------------------------------------------------------------------
-- 滚动区域：scroll.child 放内容；内容高度变化后调用 scroll:SetContentHeight(h)
--------------------------------------------------------------------------------

function UI:ScrollArea(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    scroll.child = child

    local contentHeight = 0
    local bar = UI:ScrollBar(parent, function(value)
        scroll:SetVerticalScroll(value)
        scroll:UpdateBar()
    end)
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 4, 0)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 4, 0)
    scroll.bar = bar

    function scroll:MaxScroll()
        return math.max(0, contentHeight - self:GetHeight())
    end
    function scroll:UpdateBar()
        bar:SetRange(contentHeight, self:GetHeight(), self:GetVerticalScroll())
    end
    function scroll:SetContentHeight(height)
        contentHeight = height
        child:SetSize(self:GetWidth(), height)
        self:SetVerticalScroll(math.min(self:GetVerticalScroll(), self:MaxScroll()))
        self:UpdateBar()
    end
    function scroll:ScrollToTop()
        self:SetVerticalScroll(0)
        self:UpdateBar()
    end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local value = math.min(self:MaxScroll(), math.max(0, self:GetVerticalScroll() - delta * 40))
        self:SetVerticalScroll(value)
        self:UpdateBar()
    end)
    scroll:SetScript("OnSizeChanged", function(self)
        child:SetWidth(self:GetWidth())
        self:UpdateBar()
    end)
    return scroll
end

--------------------------------------------------------------------------------
-- 虚拟列表：只创建可见行。SetData({ { id, text, tags }, ... }, selectedID)
--------------------------------------------------------------------------------

function UI:List(parent, rowHeight, onSelect)
    local list = CreateFrame("Frame", nil, parent)
    list.rows = {}
    list.data = {}
    list.offset = 0
    rowHeight = rowHeight or 22

    local bar = UI:ScrollBar(list, function(value)
        list.offset = floor(value + 0.5)
        list:Refresh()
    end)
    bar:SetPoint("TOPRIGHT", -2, -2)
    bar:SetPoint("BOTTOMRIGHT", -2, 2)

    local function CreateRow(index)
        local row = CreateFrame("Button", nil, list)
        row:SetHeight(rowHeight)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
        row:SetPoint("RIGHT", bar, "LEFT", -4, 0)
        row.background = row:CreateTexture(nil, "BACKGROUND")
        row.background:SetAllPoints()
        row.accent = row:CreateTexture(nil, "ARTWORK")
        row.accent:SetPoint("TOPLEFT")
        row.accent:SetPoint("BOTTOMLEFT")
        row.accent:SetWidth(2)
        SetColor(row.accent, "gold")
        row.tags = UI:Text(row, "Muted")
        row.tags:SetPoint("RIGHT", -6, 0)
        row.tags:SetJustifyH("RIGHT")
        row.tags:SetWordWrap(false)
        -- 名字的右边界跟随右侧标签：标签多宽就让多少，名字放不下时截断，不与标签叠字
        row.label = UI:Text(row, "Small")
        row.label:SetPoint("LEFT", 10, 0)
        row.label:SetPoint("RIGHT", row.tags, "LEFT", -8, 0)
        row.label:SetWordWrap(false)
        -- 分隔行（entry.divider）：上方一条细线 + 小标题，不可点选
        row.line = row:CreateTexture(nil, "ARTWORK")
        row.line:SetPoint("TOPLEFT", 6, -3)
        row.line:SetPoint("TOPRIGHT", -6, -3)
        row.line:SetHeight(1)
        SetColor(row.line, "line")
        row:SetScript("OnClick", function(self)
            list.selectedID = self.entryID
            list:Refresh()
            onSelect(self.entryID)
        end)
        row:SetScript("OnEnter", function(self)
            if self:IsEnabled() and self.entryID ~= list.selectedID then
                self.background:SetColorTexture(unpack(C.raised))
            end
            -- 可选：list.onEntryEnter(行, 条目ID) 用来显示鼠标提示
            if list.onEntryEnter and self.entryID then
                list.onEntryEnter(self, self.entryID)
            end
        end)
        row:SetScript("OnLeave", function()
            if list.onEntryEnter then
                GameTooltip_Hide()
            end
            list:Refresh()
        end)
        return row
    end

    function list:VisibleRows()
        return math.max(1, floor(self:GetHeight() / rowHeight))
    end

    function list:Refresh()
        local visibleRows = self:VisibleRows()
        local maxOffset = math.max(0, #self.data - visibleRows)
        self.offset = math.min(math.max(0, self.offset), maxOffset)
        for i = 1, visibleRows do
            local row = self.rows[i] or CreateRow(i)
            self.rows[i] = row
            local entry = self.data[self.offset + i]
            if entry then
                row.entryID = entry.id
                row.label:SetText(entry.text)
                row.tags:SetText(entry.tags or "")
                row.line:SetShown(entry.divider and true or false)
                row:SetEnabled(not entry.divider)
                local selected = not entry.divider and entry.id == self.selectedID
                if entry.divider then
                    row.background:SetColorTexture(0, 0, 0, 0)
                elseif selected then
                    row.background:SetColorTexture(unpack(C.selected))
                elseif (self.offset + i) % 2 == 0 then
                    row.background:SetColorTexture(unpack(C.stripe))
                else
                    row.background:SetColorTexture(0, 0, 0, 0)
                end
                row.accent:SetShown(selected)
                row:Show()
            else
                row:Hide()
            end
        end
        for i = visibleRows + 1, #self.rows do
            self.rows[i]:Hide()
        end
        bar:SetRange(#self.data, visibleRows, self.offset)
    end

    function list:SetData(data, selectedID)
        self.data = data
        self.selectedID = selectedID
        self:Refresh()
    end

    -- 让指定条目进入可见范围
    function list:ScrollTo(id)
        for index, entry in ipairs(self.data) do
            if entry.id == id then
                local visibleRows = self:VisibleRows()
                if index <= self.offset or index > self.offset + visibleRows then
                    self.offset = index - floor(visibleRows / 2)
                end
                self:Refresh()
                return
            end
        end
    end

    function list:ResetScroll()
        self.offset = 0
    end

    -- 行底色每次刷新时现取颜色；配色方案变化时整表重刷
    Theme:Track(list, function(self)
        self:Refresh()
    end)

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        self.offset = self.offset - delta * 3
        self:Refresh()
    end)
    list:SetScript("OnSizeChanged", function(self)
        self:Refresh()
    end)
    return list
end

--------------------------------------------------------------------------------
-- 统计卡片：标题、数值、可选进度条
--------------------------------------------------------------------------------

function UI:StatTile(parent, title)
    local tile = UI:Panel(parent, "panel", "lineSoft")
    tile:SetHeight(58)
    tile.title = UI:Text(tile, "Muted", title)
    tile.title:SetPoint("TOPLEFT", 10, -8)
    tile.value = UI:Text(tile, "Title")
    tile.value:SetPoint("TOPLEFT", 10, -24)
    tile.note = UI:Text(tile, "Muted")
    tile.note:SetPoint("LEFT", tile.value, "RIGHT", 6, -1)

    local track = tile:CreateTexture(nil, "ARTWORK")
    track:SetPoint("BOTTOMLEFT", 10, 8)
    track:SetPoint("BOTTOMRIGHT", -10, 8)
    track:SetHeight(3)
    SetColor(track, "lineSoft")
    local fill = tile:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", track)
    fill:SetPoint("BOTTOMLEFT", track)
    SetColor(fill, "gold")

    function tile:Set(value, note, ratio)
        self.value:SetText(value)
        self.note:SetText(note or "")
        self.ratio = ratio
        if ratio then
            track:Show()
            fill:SetShown(ratio > 0)
            fill:SetWidth(math.max(1, track:GetWidth() * math.min(1, ratio)))
        else
            track:Hide()
            fill:Hide()
        end
    end
    -- 宽度确定后重新计算进度条
    tile:SetScript("OnSizeChanged", function(self)
        if self.ratio then
            fill:SetWidth(math.max(1, track:GetWidth() * math.min(1, self.ratio)))
        end
    end)
    return tile
end

--------------------------------------------------------------------------------
-- 物品图标按钮：悬停显示物品提示，Shift+点击在聊天框链接物品
--------------------------------------------------------------------------------

local function ItemButtonOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local name = C_Item.GetItemInfo(self.itemID)
    if name then
        GameTooltip:SetItemByID(self.itemID)
    else
        GameTooltip:AddLine(ns.L["Item information not yet unlocked"])
    end
    GameTooltip:Show()
end

local function ItemButtonOnClick(self)
    local _, link = C_Item.GetItemInfo(self.itemID)
    if link and HandleModifiedItemClick then
        HandleModifiedItemClick(link)
    end
end

function UI:ItemButton(parent, size)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size or 30, size or 30)
    Theme:Skin(button, "panel", "line")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button:SetScript("OnEnter", ItemButtonOnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", ItemButtonOnClick)
    local function PaintBorder(self)
        local quality = self.itemID and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(self.itemID)
        self:SetBackdropColor(unpack(C.panel))
        if quality and C_Item.GetItemQualityColor then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            self:SetBackdropBorderColor(r, g, b, 1)
        else
            self:SetBackdropBorderColor(unpack(C.line))
        end
    end
    function button:SetItem(itemID)
        self.itemID = itemID
        self.icon:SetTexture(C_Item.GetItemIconByID(itemID) or 134400)
        PaintBorder(self)
    end
    Theme:Track(button, PaintBorder)
    return button
end

-- 图标按钮：带边框的方形图标，右下角可显示一小段文字（如天赋的“2/5”）。左右键点击都触发 OnClick。
-- SetIcon(贴图路径)、SetCount(文字, 颜色名)、SetBorder(颜色名)、SetDimmed(是否变灰变淡)
function UI:IconButton(parent, size)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(size or 36, size or 36)
    Theme:Skin(button, "panel", "line")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.border = "line"
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.count = UI:Text(button, "Small")
    button.count:SetPoint("BOTTOMRIGHT", 3, -5)
    button.count:SetJustifyH("RIGHT")
    -- 文字底衬：压在图标右下角上，数字在任何图标上都看得清
    local badge = button:CreateTexture(nil, "ARTWORK", nil, 2)
    badge:SetPoint("TOPLEFT", button.count, "TOPLEFT", -3, 2)
    badge:SetPoint("BOTTOMRIGHT", button.count, "BOTTOMRIGHT", 2, -2)
    SetColor(badge, "menu")
    button.badge = badge
    badge:Hide()

    local function Paint(self)
        self:SetBackdropColor(unpack(C.panel))
        self:SetBackdropBorderColor(unpack(C[self.border]))
        if self.countColor then
            self.count:SetTextColor(unpack(C[self.countColor]))
        end
    end
    function button:SetIcon(path)
        self.icon:SetTexture(path)
    end
    function button:SetCount(text, color)
        self.count:SetText(text or "")
        self.countColor = color or "text"
        badge:SetShown(text ~= nil and text ~= "")
        Paint(self)
    end
    function button:SetBorder(color)
        self.border = color or "line"
        Paint(self)
    end
    function button:SetDimmed(dimmed)
        self.icon:SetDesaturated(dimmed and true or false)
        self.icon:SetAlpha(dimmed and 0.45 or 1)
    end
    Theme:Track(button, Paint)
    return button
end

-- 小地图入口：与小地图上其他按钮一致，采用暴雪原生的圆形边框、圆形底和悬停高亮（主题规则的例外）；
-- 图标为网站徽标。不依赖第三方库。
local MINIMAP_ICON = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\MinimapIcon"

function UI:MinimapButton(parent, onClick)
    local button = CreateFrame("Button", "WowHandbookMinimapButton", parent)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24, 24)
    background:SetPoint("CENTER", 0, 0)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(MINIMAP_ICON)
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 0)
    button.icon = icon

    -- 边框贴图的圆环在贴图左上部，按暴雪小地图按钮的惯例左上对齐
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)

    -- 按下时图标略向右下移，松开复位
    button:SetScript("OnMouseDown", function()
        icon:SetPoint("CENTER", 1, -1)
    end)
    button:SetScript("OnMouseUp", function()
        icon:SetPoint("CENTER", 0, 0)
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        onClick(mouseButton)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ns.L["WoW Handbook"])
        GameTooltip:AddLine(ns.L["Left-click: open or close. Right-click: quick settings. Drag: move."], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

--------------------------------------------------------------------------------
-- 停靠面板：贴在某个游戏窗口右侧的面板（未学技能面板、配方面板），可拖动，记住相对那个窗口右上角的偏移。
-- UI:Dockable(panel, settings, defaultX)：settings 为模块设置（偏移存在 dockX / dockY），defaultX 为默认的横向间距。
-- panel:Dock(outer) 按偏移贴到 outer 右侧（高度与 outer 一致），panel:DockOffset() 返回当前偏移；
-- 左键拖动面板空白处移动，松手后记下偏移；右键面板复位到默认位置。
--------------------------------------------------------------------------------

function UI:Dockable(panel, settings, defaultX)
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")

    function panel:DockOffset()
        return settings.dockX or defaultX, settings.dockY or 0
    end

    function panel:Dock(outer)
        self.dockOuter = outer
        local x, y = self:DockOffset()
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", outer, "TOPRIGHT", x, y)
        self:SetPoint("BOTTOMLEFT", outer, "BOTTOMRIGHT", x, y)
    end

    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local outer = self.dockOuter
        local left, top = self:GetLeft(), self:GetTop()
        local right, outerTop = outer and outer:GetRight(), outer and outer:GetTop()
        if left and top and right and outerTop then
            -- 两者可能缩放不同：统一换算到面板自己的坐标
            local ratio = outer:GetEffectiveScale() / self:GetEffectiveScale()
            settings.dockX = math.floor(left - right * ratio + 0.5)
            settings.dockY = math.floor(top - outerTop * ratio + 0.5)
        end
        if outer then
            self:Dock(outer)
        end
        if self.onDocked then
            self.onDocked()
        end
    end)
    panel:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            settings.dockX, settings.dockY = nil, nil
            if self.dockOuter then
                self:Dock(self.dockOuter)
            end
            if self.onDocked then
                self.onDocked()
            end
        end
    end)
    return panel
end

--------------------------------------------------------------------------------
-- 勾选菜单（小地图按钮右键的快捷设置），紧凑排列：行首是图标加简短名称，控件靠右。条目按顺序：
--   { kind = "title", text, onClick }             金色标题（可点击）
--   { kind = "check", text, checked, onClick, tip }  勾选项：行尾方框，点整行切换
--   { kind = "choice", text, choices = { {id, text, tip} }, value, onClick(id), tip }
--                                                  多选一：行尾横排选项（可以是图标贴图），当前项金色、其余淡色
--   { kind = "action", text, onClick }             普通按钮行
--   { kind = "separator" }                         分隔线
-- tip 为悬停提示。menu:Open(anchor, build)：build() 返回条目表；点了勾选项或选项后重新调用 build 刷新，
-- 菜单保持打开。点菜单以外的地方或按 Esc 关闭。
--------------------------------------------------------------------------------

local MENU_ROW = 18
local MENU_PAD = 6
local MENU_GAP = 14 -- 名称与右侧控件之间至少留的空

local function MenuTip(owner, title, tip)
    if not tip then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title or "", 1, 0.82, 0)
    GameTooltip:AddLine(tip, 1, 1, 1, true)
    GameTooltip:Show()
end

function UI:CheckMenu(name)
    local menu = UI:Panel(UIParent, "menu", "line")
    if name then
        _G[name] = menu -- 具名框架才能放进 UISpecialFrames 让 Esc 关闭（名字以 WowHandbook 开头）
        tinsert(UISpecialFrames, name)
    end
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:Hide()
    local rows = {}

    local function Clickable(entry)
        return entry and entry.onClick and entry.kind ~= "choice"
    end

    local function Row(index)
        local row = rows[index]
        if row then
            return row
        end
        row = CreateFrame("Button", nil, menu)
        row:SetHeight(MENU_ROW)
        row.hover = row:CreateTexture(nil, "BACKGROUND")
        row.hover:SetAllPoints()
        SetColor(row.hover, "raised")
        row.hover:Hide()
        row.box = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.box:SetSize(11, 11)
        row.box:SetPoint("RIGHT", -MENU_PAD, 0)
        Theme:Skin(row.box, "panel", "line")
        row.mark = row.box:CreateTexture(nil, "OVERLAY")
        row.mark:SetPoint("TOPLEFT", 2, -2)
        row.mark:SetPoint("BOTTOMRIGHT", -2, 2)
        SetColor(row.mark, "gold")
        row.text = UI:Text(row, "Small")
        row.text:SetJustifyH("LEFT")
        row.text:SetPoint("LEFT", MENU_PAD, 0)
        row.line = row:CreateTexture(nil, "ARTWORK")
        row.line:SetPoint("LEFT", MENU_PAD, 0)
        row.line:SetPoint("RIGHT", -MENU_PAD, 0)
        row.line:SetHeight(1)
        SetColor(row.line, "lineSoft")
        row.options = {}
        row:SetScript("OnEnter", function(self)
            self.hover:SetShown(Clickable(self.entry) and true or false)
            if self.entry then
                MenuTip(self, self.entry.text, self.entry.tip)
            end
        end)
        row:SetScript("OnLeave", function(self)
            self.hover:Hide()
            GameTooltip_Hide()
        end)
        row:SetScript("OnClick", function(self)
            local entry = self.entry
            if not Clickable(entry) then
                return
            end
            if entry.kind ~= "check" then
                menu:Hide()
            end
            entry.onClick(not entry.checked)
            if entry.kind == "check" then
                menu:Refresh()
            end
        end)
        rows[index] = row
        return row
    end

    -- 多选一的选项：小号文字或图标按钮
    local function Option(row, index)
        local option = row.options[index]
        if not option then
            option = CreateFrame("Button", nil, row)
            option:SetHeight(MENU_ROW)
            option.text = UI:Text(option, "Small")
            option.text:SetPoint("CENTER")
            option.dot = option:CreateTexture(nil, "ARTWORK")
            option.dot:SetHeight(2)
            option.dot:SetPoint("BOTTOMLEFT", 3, 1)
            option.dot:SetPoint("BOTTOMRIGHT", -3, 1)
            SetColor(option.dot, "gold")
            option:SetScript("OnClick", function(self)
                self.entry.onClick(self.id)
                menu:Refresh()
            end)
            option:SetScript("OnEnter", function(self)
                self.text:SetAlpha(1)
                MenuTip(self, self.entry.text, self.tip)
            end)
            option:SetScript("OnLeave", function(self)
                self.text:SetAlpha(self.id == self.entry.value and 1 or 0.45)
                GameTooltip_Hide()
            end)
            row.options[index] = option
        end
        return option
    end

    function menu:Refresh()
        local entries = self.build and self.build() or {}
        local width, y = 150, MENU_PAD
        for index, entry in ipairs(entries) do
            local row = Row(index)
            row.entry = entry
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 1, -y)
            row:SetPoint("RIGHT", -1, 0)
            row.box:SetShown(entry.kind == "check")
            row.mark:SetShown(entry.kind == "check" and entry.checked and true or false)
            row.line:SetShown(entry.kind == "separator")
            row.text:SetShown(entry.kind ~= "separator")
            row.text:SetText(entry.text or "")
            row.text:SetTextColor(unpack(entry.kind == "title" and C.gold or C.text))
            for _, option in ipairs(row.options) do
                option:Hide()
            end
            local rowWidth = MENU_PAD + row.text:GetStringWidth() + MENU_PAD
            if entry.kind == "check" then
                rowWidth = rowWidth + MENU_GAP + 11
            elseif entry.kind == "choice" then
                -- 选项从右往左排
                local x, total = -MENU_PAD, 0
                for optionIndex = #entry.choices, 1, -1 do
                    local choice = entry.choices[optionIndex]
                    local option = Option(row, optionIndex)
                    option.entry, option.id, option.tip = entry, choice.id, choice.tip
                    option.text:SetText(choice.text)
                    local selected = choice.id == entry.value
                    option.text:SetTextColor(unpack(selected and C.gold or C.text))
                    option.text:SetAlpha(selected and 1 or 0.45)
                    option.dot:SetShown(selected)
                    local optionWidth = math.max(18, option.text:GetStringWidth() + 8)
                    option:SetWidth(optionWidth)
                    option:ClearAllPoints()
                    option:SetPoint("RIGHT", row, "RIGHT", x, 0)
                    option:Show()
                    x = x - optionWidth
                    total = total + optionWidth
                end
                rowWidth = rowWidth + MENU_GAP + total
            end
            local height = entry.kind == "separator" and 7 or MENU_ROW
            row:SetHeight(height)
            row:Show()
            width = math.max(width, rowWidth)
            y = y + height
        end
        for index = #entries + 1, #rows do
            rows[index]:Hide()
        end
        self:SetSize(width + 2, y + MENU_PAD)
        self.rows = rows -- 供测试使用
    end

    function menu:Open(anchor, build)
        self.build, self.anchor = build, anchor
        self:ClearAllPoints()
        self:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, 0)
        self:Refresh()
        self:Show()
    end

    function menu:Toggle(anchor, build)
        if self:IsShown() then
            self:Hide()
        else
            self:Open(anchor, build)
        end
    end

    -- 点菜单以外的地方关闭（点锚点本身交给锚点的点击处理，避免关了又开）
    ns:RegisterEvent("GLOBAL_MOUSE_DOWN", function()
        if menu:IsShown() and not menu:IsMouseOver() and not (menu.anchor and menu.anchor:IsMouseOver()) then
            menu:Hide()
        end
    end)
    return menu
end

--------------------------------------------------------------------------------
-- 内容堆叠：在滚动区域里自上而下排列标题、文字、带按钮的行、物品图标行。
-- 每次刷新先 Reset() 再依次添加，最后 Finish() 返回总高度。控件放在对象池里复用。
--------------------------------------------------------------------------------

function UI:Stack(parent)
    local stack = { parent = parent, y = 0, pools = { text = {}, button = {}, item = {} }, used = {} }

    local function Take(kind, create)
        local pool = stack.pools[kind]
        local used = stack.used[kind] or 0
        used = used + 1
        stack.used[kind] = used
        local widget = pool[used]
        if not widget then
            widget = create()
            pool[used] = widget
        end
        widget:ClearAllPoints()
        widget:Show()
        return widget
    end

    function stack:Reset()
        for _, pool in pairs(self.pools) do
            for _, widget in ipairs(pool) do
                widget:Hide()
            end
        end
        wipe(self.used)
        self.y = 0
    end

    function stack:Width()
        local width = self.parent:GetWidth()
        -- 滚动区域首次显示时可能还没有宽度，用父滚动框或默认宽度兜底
        if not width or width < 100 then
            local scroll = self.parent:GetParent()
            width = scroll and scroll.GetWidth and scroll:GetWidth() or 0
        end
        return width >= 100 and width or 640
    end

    -- font: Theme 字体名（Title / Heading / Body / Small / Muted / Accent）；indent: 左缩进
    function stack:Text(text, font, indent, gap)
        local fontString = Take("text", function()
            local fs = self.parent:CreateFontString(nil, "OVERLAY")
            fs:SetJustifyH("LEFT")
            fs:SetJustifyV("TOP")
            fs:SetSpacing(2)
            return fs
        end)
        fontString:SetFontObject(Theme.fonts[font or "Body"])
        fontString:SetWidth(math.max(40, self:Width() - (indent or 0)))
        fontString:SetPoint("TOPLEFT", indent or 0, -self.y)
        fontString:SetText(text or "")
        self.y = self.y + fontString:GetStringHeight() + (gap or 6)
        return fontString
    end

    function stack:Heading(text)
        self.y = self.y + 6
        self:Text(text, "Heading", 0, 8)
    end

    function stack:Spacer(height)
        self.y = self.y + (height or 8)
    end

    -- 一行文字，右侧若干按钮：buttons = { { label = "...", onClick = fn, variant = "primary" }, ... }
    function stack:Row(text, buttons, font, indent)
        local top = self.y
        local rightEdge = 0
        for index = #(buttons or {}), 1, -1 do
            local definition = buttons[index]
            local button = Take("button", function()
                return UI:Button(self.parent, "", 60, 20)
            end)
            button.variant = definition.variant or "default"
            button:SetLabel(definition.label)
            button:SetWidth(math.max(44, button.label:GetStringWidth() + 18))
            button:SetPoint("TOPRIGHT", -rightEdge, -top)
            button:SetScript("OnClick", definition.onClick)
            button:SetSelected(false)
            rightEdge = rightEdge + button:GetWidth() + 6
        end
        local fontString = Take("text", function()
            local fs = self.parent:CreateFontString(nil, "OVERLAY")
            fs:SetJustifyH("LEFT")
            fs:SetJustifyV("TOP")
            fs:SetSpacing(2)
            return fs
        end)
        fontString:SetFontObject(Theme.fonts[font or "Body"])
        fontString:SetWidth(math.max(40, self:Width() - (indent or 0) - rightEdge - 6))
        fontString:SetPoint("TOPLEFT", indent or 0, -top - 3)
        fontString:SetText(text or "")
        self.y = top + math.max(22, fontString:GetStringHeight() + 6) + 2
        return fontString
    end

    -- 物品行：可传 ID 或 {id, rate}；未解锁时显示可读占位。
    function stack:Items(itemIDs, indent, size)
        size = size or 30
        for _, entry in ipairs(itemIDs) do
            local itemID = type(entry) == "table" and entry.id or entry
            local name = C_Item.GetItemInfo(itemID)
            if not name then
                ns.RequestItem(itemID)
            end
            local button = Take("item", function()
                return UI:ItemButton(self.parent, size)
            end)
            button:SetPoint("TOPLEFT", indent or 0, -self.y)
            button:SetItem(itemID)
            local label = Take("text", function()
                return self.parent:CreateFontString(nil, "OVERLAY")
            end)
            label:SetFontObject(Theme.fonts.Small)
            label:SetPoint("LEFT", button, "RIGHT", 8, 0)
            label:SetWidth(math.max(40, self:Width() - (indent or 0) - size - 12))
            label:SetJustifyH("LEFT")
            local description = name or ns.L["Item information not yet unlocked"]
            if type(entry) == "table" and entry.rate then
                description = description .. "  " .. (ns.L["Drop rate: %s%%"]):format(tostring(entry.rate))
            end
            label:SetText(description)
            self.y = self.y + math.max(size, label:GetStringHeight()) + 4
        end
        if #itemIDs > 0 then
            self.y = self.y + 4
        end
    end

    function stack:Finish()
        return self.y + 8
    end

    return stack
end

--------------------------------------------------------------------------------
-- 可点击卡片：面板底、左侧色条，悬停边框变金
--------------------------------------------------------------------------------

function UI:Card(parent)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    Theme:Skin(card, "panel", "lineSoft")
    card.accent = card:CreateTexture(nil, "ARTWORK")
    card.accent:SetPoint("TOPLEFT", 1, -1)
    card.accent:SetPoint("BOTTOMLEFT", 1, 1)
    card.accent:SetWidth(3)
    SetColor(card.accent, "goldDim")
    -- 高亮卡片（如“适合你”的副本）：浅金底、金色边框；悬停时再亮一级。onHover(self, hovered) 供页面加额外效果
    local function Paint(self, hovered)
        if self.highlighted then
            self:SetBackdropBorderColor(unpack(hovered and C.gold or C.goldDim))
            self:SetBackdropColor(unpack(C.selected))
        else
            self:SetBackdropBorderColor(unpack(hovered and C.goldDim or C.lineSoft))
            self:SetBackdropColor(unpack(hovered and C.raised or C.panel))
        end
        if self.onHover then
            self:onHover(hovered)
        end
    end
    card:SetScript("OnEnter", function(self)
        Paint(self, true)
    end)
    card:SetScript("OnLeave", function(self)
        Paint(self, false)
    end)
    function card:SetHighlighted(highlighted)
        self.highlighted = highlighted and true or false
        Paint(self, false)
    end
    Theme:Track(card, function(self)
        Paint(self, false)
    end)
    -- 左侧色条颜色（十六进制 "ffe0b458"）；指定后不再跟随配色方案
    function card:SetAccentHex(hex)
        local r = tonumber(hex:sub(3, 4), 16) / 255
        local g = tonumber(hex:sub(5, 6), 16) / 255
        local b = tonumber(hex:sub(7, 8), 16) / 255
        Theme:Track(self.accent, nil)
        self.accent:SetColorTexture(r, g, b, 1)
    end
    return card
end
