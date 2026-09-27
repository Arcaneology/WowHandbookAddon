local ADDON_NAME, ns = ...

-- 自绘控件：按钮、分段选择、搜索框、勾选框、细滚动条、滚动区域、虚拟列表、统计卡片。
-- 统一使用 ns.Theme 的颜色与字体；通过 WowHandbookAPI.UI 也提供给内部采集插件使用。
local Theme = ns.Theme
local C = Theme.colors
local UI = {}
ns.UI = UI

local function SetColor(texture, name)
    texture:SetColorTexture(unpack(C[name]))
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
        background, border, text = hovered and "raised" or "window", hovered and "line" or "window", hovered and "text" or "textDim"
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
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", 10, 0)
    dropdown.label:SetPoint("RIGHT", -22, 0)
    dropdown.label:SetJustifyH("LEFT")
    local arrow = dropdown:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    arrow:SetVertexColor(unpack(C.muted))

    local menu = UI:Panel(dropdown, "window", "line")
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
        thumbTexture:SetColorTexture(unpack(C.gold))
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
        row.label = UI:Text(row, "Small")
        row.label:SetPoint("LEFT", 10, 0)
        row.label:SetPoint("RIGHT", -110, 0)
        row.label:SetWordWrap(false)
        row.tags = UI:Text(row, "Muted")
        row.tags:SetPoint("RIGHT", -6, 0)
        row.tags:SetJustifyH("RIGHT")
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
                SetColor(self.background, "raised")
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
                    SetColor(row.background, "selected")
                elseif (self.offset + i) % 2 == 0 then
                    SetColor(row.background, "stripe")
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
    function button:SetItem(itemID)
        self.itemID = itemID
        self.icon:SetTexture(C_Item.GetItemIconByID(itemID) or 134400)
        local quality = C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(itemID)
        if quality and C_Item.GetItemQualityColor then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            self:SetBackdropBorderColor(r, g, b, 1)
        else
            self:SetBackdropBorderColor(unpack(C.line))
        end
    end
    return button
end

-- 小地图入口：与小地图上其他按钮一致，采用暴雪原生的圆形边框、圆形底和悬停高亮（主题规则的例外，
-- 用户指定）；图标为网站徽标。不依赖第三方库。
local MINIMAP_ICON = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\MinimapIcon"

function UI:MinimapButton(parent, onClick)
    local button = CreateFrame("Button", "WowHandbookMinimapButton", parent)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
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
    button:SetScript("OnClick", function()
        onClick()
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ns.L["WoW Handbook"])
        GameTooltip:AddLine(ns.L["Left-click: open or close. Drag: move."], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
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

    -- 物品行：可传 ID 或 {id, rate, unverified}；未解锁时显示可读占位。
    function stack:Items(itemIDs, indent, size)
        size = size or 30
        for _, entry in ipairs(itemIDs) do
            local itemID = type(entry) == "table" and entry.id or entry
            local name = C_Item.GetItemInfo(itemID)
            if not name and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemID)
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
            if type(entry) == "table" and entry.unverified then
                description = description .. " " .. ns.L["Unverified"]
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
    card:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(C.goldDim))
        self:SetBackdropColor(unpack(C.raised))
    end)
    card:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(C.lineSoft))
        self:SetBackdropColor(unpack(C.panel))
    end)
    -- 左侧色条颜色（十六进制 "ffe0b458"）
    function card:SetAccentHex(hex)
        local r = tonumber(hex:sub(3, 4), 16) / 255
        local g = tonumber(hex:sub(5, 6), 16) / 255
        local b = tonumber(hex:sub(7, 8), 16) / 255
        self.accent:SetColorTexture(r, g, b, 1)
    end
    return card
end
