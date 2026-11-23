local ADDON_NAME, ns = ...

-- 自绘控件：按钮、分段选择、搜索框、勾选框、细滚动条、滚动区域、虚拟列表、统计卡片、走势图。
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

--------------------------------------------------------------------------------
-- 确认框：屏幕中央一个小面板，一句说明、确认与取消两个按钮；Esc 或取消关闭。
-- 全插件共用一个（具名 WowHandbookConfirmDialog，放进 UISpecialFrames 让 Esc 关闭），再次调用时换掉内容。
-- 文字由调用方经本地化表传入。
--------------------------------------------------------------------------------

local confirmDialog

function UI:Confirm(text, acceptLabel, cancelLabel, onAccept)
    if not confirmDialog then
        local dialog = UI:Panel(UIParent, "panel", "goldDim")
        _G.WowHandbookConfirmDialog = dialog
        tinsert(UISpecialFrames, "WowHandbookConfirmDialog")
        dialog:SetSize(340, 120)
        dialog:SetPoint("CENTER", 0, 120)
        dialog:SetFrameStrata("DIALOG")
        dialog:SetClampedToScreen(true)
        dialog:EnableMouse(true)
        dialog.text = UI:Text(dialog, "Body")
        dialog.text:SetPoint("TOPLEFT", 18, -20)
        dialog.text:SetPoint("TOPRIGHT", -18, -20)
        dialog.text:SetJustifyH("CENTER")
        dialog.text:SetWordWrap(true)
        dialog.accept = UI:Button(dialog, "", 140, 26, "primary")
        dialog.accept:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -6, 16)
        dialog.cancel = UI:Button(dialog, "", 140, 26)
        dialog.cancel:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 6, 16)
        dialog.cancel:SetScript("OnClick", function() dialog:Hide() end)
        dialog.accept:SetScript("OnClick", function()
            dialog:Hide()
            if dialog.onAccept then
                dialog.onAccept()
            end
        end)
        confirmDialog = dialog
    end
    local dialog = confirmDialog
    dialog.text:SetText(text or "")
    dialog.accept:SetLabel(acceptLabel or "")
    dialog.cancel:SetLabel(cancelLabel or "")
    dialog.onAccept = onAccept
    dialog:SetHeight(math.max(110, (dialog.text:GetStringHeight() or 0) + 82))
    dialog:Show()
    dialog:Raise()
    return dialog
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
-- 弹出层的自动关闭：点弹出层和它的锚点以外的地方就关掉（下拉列表、快捷菜单、右键菜单、副本选择器共用）。
-- UI:AutoClose(popup, anchor)：anchor 可省略，也可以是返回当前锚点的函数（锚点会变的菜单）。
-- 点锚点本身交给锚点自己的点击处理，避免关了又开。全插件只订阅一次鼠标事件。
--------------------------------------------------------------------------------

local popups = {}

local function ClosePopups()
    for popup, anchor in pairs(popups) do
        if popup:IsShown() and not popup:IsMouseOver() then
            if type(anchor) == "function" then
                anchor = anchor()
            end
            if not (anchor and anchor:IsMouseOver()) then
                popup:Hide()
            end
        end
    end
end

function UI:AutoClose(popup, anchor)
    if not next(popups) then
        ns:RegisterEvent("GLOBAL_MOUSE_DOWN", ClosePopups)
    end
    popups[popup] = anchor or false
end

--------------------------------------------------------------------------------
-- 下拉选择：按钮显示当前项，点开后在按钮下方列出全部选项；点别处关闭
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
    menu:SetClampedToScreen(true)
    menu:Hide()
    UI:AutoClose(menu, dropdown)
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
-- 滑条：整数取值，细轨道加方形滑块；拖动、点轨道、滚轮都能改。
-- onChange(value) 只在玩家操作时调用，SetValue 不触发。SetMarks 在轨道上标出几个值（如洗天赋的等级）。
--------------------------------------------------------------------------------

function UI:Slider(parent, width, onChange)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetSize(width or 200, 16)
    slider:SetOrientation("HORIZONTAL")
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouseWheel(true)
    slider.onChange = onChange -- 供测试使用

    local track = Theme:Fill(slider, "lineSoft", "BACKGROUND")
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    track:SetHeight(4)
    local fill = Theme:Fill(slider, "goldDim", "ARTWORK")
    fill:SetPoint("LEFT", track, "LEFT")
    fill:SetHeight(4)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(10, 16)
    SetColor(thumb, "gold")
    slider:SetThumbTexture(thumb)
    local marks = {}

    local quiet = false
    local function Update(self)
        local low, high = self:GetMinMaxValues()
        local span = high > low and (high - low) or 1
        local usable = self:GetWidth() - 10
        fill:SetWidth(math.max(1, usable * (self:GetValue() - low) / span + 5))
        for _, mark in ipairs(marks) do
            if mark.value then
                mark:ClearAllPoints()
                mark:SetPoint("CENTER", self, "LEFT", 5 + usable * (mark.value - low) / span, 0)
            end
        end
    end
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        Update(self)
        if not quiet and self.value ~= value then
            self.value = value
            onChange(value)
        end
        self.value = value
    end)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local low, high = self:GetMinMaxValues()
        local value = math.max(low, math.min(high, (self.value or low) + (delta > 0 and 1 or -1)))
        if value ~= self.value then
            self:SetValue(value)
        end
    end)
    slider:SetScript("OnSizeChanged", Update)

    function slider:SetRange(low, high)
        quiet = true
        self:SetMinMaxValues(low, math.max(low, high))
        quiet = false
        Update(self)
    end
    function slider:SetLevel(value)
        quiet = true
        self.value = value
        self:SetValue(value)
        quiet = false
        Update(self)
    end
    function slider:SetMarks(values, color)
        for index, value in ipairs(values or {}) do
            local mark = marks[index] or Theme:Fill(self, color or "text", "ARTWORK", 2)
            marks[index] = mark
            mark:SetSize(2, 10)
            mark.value = value
            mark:Show()
        end
        for index = #(values or {}) + 1, #marks do
            marks[index].value = nil
            marks[index]:Hide()
        end
        Update(self)
    end
    return slider
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
-- 表格用法：list:SetColumns({ { title = "名称列标题" }, { title = "列标题", width = 宽 }, ... }) 在顶部加一行表头，
-- 第一项是名字列（占剩下的宽度），后面各列靠右排、右对齐；条目用 columns = { "第 1 列", "第 2 列", ... } 代替 tags。
-- 列带 sort = "键" 时表头可点：点击调用 list.onSort(键)；list:SetSortIndicator(键, 是否升序) 在该列表头画箭头
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

    list.headerHeight = 0

    local function CreateRow(index)
        local row = CreateFrame("Button", nil, list)
        row:SetHeight(rowHeight)
        row:SetPoint("TOPLEFT", 0, -list.headerHeight - (index - 1) * rowHeight)
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
        return math.max(1, floor((self:GetHeight() - self.headerHeight) / rowHeight))
    end

    -- 各列的右边距：从右往左排，每列宽 width，列间 10
    local function ColumnOffsets(columns)
        local offsets, right = {}, -6
        for index = #columns, 2, -1 do
            offsets[index] = right
            right = right - columns[index].width - 10
        end
        return offsets, right
    end

    -- 行里的各列文字：按列定义建好，名字的右边界接到最左一列
    local function LayoutCells(row)
        local columns = list.columns
        if row.columnsLaidOut == columns then
            return
        end
        row.columnsLaidOut = columns
        row.cells = row.cells or {}
        local offsets, nameRight = ColumnOffsets(columns)
        for index = 2, #columns do
            local cell = row.cells[index] or UI:Text(row, "Small")
            row.cells[index] = cell
            cell:ClearAllPoints()
            cell:SetPoint("RIGHT", row, "RIGHT", offsets[index], 0)
            cell:SetWidth(columns[index].width)
            cell:SetJustifyH(columns[index].justify or "RIGHT")
            cell:SetWordWrap(false)
            cell:Show()
        end
        for index = #columns + 1, #row.cells do
            row.cells[index]:Hide()
        end
        row.label:SetPoint("RIGHT", row, "RIGHT", nameRight + 2, 0)
    end

    -- 当前排序的列：表头文字用强调色，旁边一个箭头（向下为从大到小，向上为从小到大）
    function list:SetSortIndicator(key, ascending)
        self.sortKey, self.sortAscending = key, ascending and true or false
        for _, cell in ipairs(self.header and self.header.cells or {}) do
            cell.active = key ~= nil and cell.sortKey == key
            cell.title:SetTextColor(unpack(C[cell.active and "gold" or "muted"]))
            cell.arrow:SetShown(cell.active)
            if cell.active then
                cell.arrow:SetVertexColor(unpack(C.gold))
                if ascending then
                    cell.arrow:SetTexCoord(0, 1, 1, 0)
                else
                    cell.arrow:SetTexCoord(0, 1, 0, 1)
                end
            end
        end
    end

    function list:SetColumns(columns)
        self.columns = columns
        if not self.header then
            self.header = CreateFrame("Frame", nil, self)
            self.header:SetPoint("TOPLEFT")
            self.header:SetPoint("RIGHT", bar, "LEFT", -4, 0)
            self.header.titles = {}
            local line = self.header:CreateTexture(nil, "ARTWORK")
            line:SetPoint("BOTTOMLEFT")
            line:SetPoint("BOTTOMRIGHT")
            line:SetHeight(1)
            SetColor(line, "lineSoft")
        end
        self.headerHeight = rowHeight
        self.header:SetHeight(rowHeight)
        self.header.cells = self.header.cells or {}
        local offsets, nameRight = ColumnOffsets(columns)
        for index, column in ipairs(columns) do
            -- 每个表头是一个按钮（可点的列悬停变亮），里面是标题文字与排序箭头
            local cell = self.header.cells[index]
            if not cell then
                cell = CreateFrame("Button", nil, self.header)
                cell.title = UI:Text(cell, "Muted")
                cell.arrow = cell:CreateTexture(nil, "OVERLAY")
                cell.arrow:SetSize(10, 10)
                cell.arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
                cell.arrow:Hide()
                cell:SetScript("OnEnter", function(own)
                    if own.sortKey then
                        own.title:SetTextColor(unpack(C.text))
                    end
                end)
                cell:SetScript("OnLeave", function(own)
                    own.title:SetTextColor(unpack(C[own.active and "gold" or "muted"]))
                end)
                cell:SetScript("OnClick", function(own)
                    if own.sortKey and list.onSort then
                        list.onSort(own.sortKey)
                    end
                end)
                self.header.cells[index] = cell
            end
            self.header.titles[index] = cell.title
            cell.sortKey = column.sort
            cell:EnableMouse(column.sort ~= nil)
            cell:ClearAllPoints()
            cell:SetHeight(rowHeight)
            cell.title:ClearAllPoints()
            cell.arrow:ClearAllPoints()
            if index == 1 then
                cell:SetPoint("LEFT", self.header, "LEFT", 0, 0)
                cell:SetPoint("RIGHT", self.header, "RIGHT", nameRight, 0)
                cell.title:SetPoint("LEFT", 10, 0)
                cell.title:SetJustifyH("LEFT")
                cell.arrow:SetPoint("LEFT", cell.title, "RIGHT", 3, 0)
            else
                cell:SetPoint("RIGHT", self.header, "RIGHT", offsets[index], 0)
                cell:SetWidth(column.width)
                cell.title:SetPoint("RIGHT", 0, 0)
                cell.title:SetJustifyH(column.justify or "RIGHT")
                cell.arrow:SetPoint("RIGHT", cell.title, "LEFT", -3, 0)
            end
            cell.title:SetText(column.title or "")
            cell:Show()
        end
        for index = #columns + 1, #self.header.cells do
            self.header.cells[index]:Hide()
        end
        self:SetSortIndicator(self.sortKey, self.sortAscending)
        for index, row in ipairs(self.rows) do
            row:SetPoint("TOPLEFT", 0, -self.headerHeight - (index - 1) * rowHeight)
        end
        self:Refresh()
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
                if self.columns then
                    LayoutCells(row)
                    for index = 2, #self.columns do
                        row.cells[index]:SetText(entry.columns and entry.columns[index - 1] or "")
                    end
                end
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
        -- 可选：list.onRefresh(list) 在每次重画后调用（比如按可见范围按需加载数据）
        if self.onRefresh then
            self.onRefresh(self)
        end
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

    -- 行底色每次刷新时现取颜色；配色方案变化时整表重刷（表头的排序高亮也重画）
    Theme:Track(list, function(self)
        self:Refresh()
        if self.header then
            self:SetSortIndicator(self.sortKey, self.sortAscending)
        end
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
-- 停靠面板：贴在某个游戏窗口右侧的面板（配方面板），可拖动，记住相对那个窗口右上角的偏移。
-- UI:Dockable(panel, settings, defaultX)：settings 为模块设置（偏移存在 dockX / dockY），defaultX 为默认的横向间距。
-- panel:Dock(outer) 按偏移贴到 outer 右侧（高度与 outer 一致；设了 panel.dockHeight 时顶部对齐、用这个高度），
-- panel:DockOffset() 返回当前偏移；
-- 左键拖动面板空白处移动，松手后记下偏移；右键面板弹出菜单，里面可以复位到默认位置（不再一点就复位，避免误触）。
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
        if self.dockHeight then
            self:SetHeight(self.dockHeight)
        else
            self:SetPoint("BOTTOMLEFT", outer, "BOTTOMRIGHT", x, y)
        end
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
    function panel:ResetDock()
        settings.dockX, settings.dockY = nil, nil
        if self.dockOuter then
            self:Dock(self.dockOuter)
        end
        if self.onDocked then
            self.onDocked()
        end
    end
    panel:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            UI:ContextMenu({
                { kind = "action", text = ns.L["Reset position"], onClick = function() self:ResetDock() end },
            })
        end
    end)
    return panel
end

--------------------------------------------------------------------------------
-- 勾选菜单（小地图按钮右键的快捷设置、各处的右键菜单），紧凑排列：行首是图标加简短名称，控件靠右。条目按顺序：
--   { kind = "title", text, onClick }             强调色标题（有 onClick 才可点击）
--   { kind = "group", text, expanded, onClick }    可折叠的分组标题：行尾 + / -，点了以后菜单保持打开
--   条目带 indent = true 时缩进一格（分组里的条目）；带 keepOpen = true 的按钮行点了以后菜单保持打开
--   { kind = "check", text, checked, onClick, tip }  勾选项：行尾方框，点整行切换
--   { kind = "choice", text, choices = { {id, text, tip} }, value, onClick(id), tip }
--                                                  多选一：行尾横排选项（可以是图标贴图），当前项金色、其余淡色
--   { kind = "action", text, onClick }             普通按钮行
--   { kind = "separator" }                         分隔线
-- tip 为悬停提示。menu:Open(anchor, build)：build 是条目表或返回条目表的函数；点了勾选项或选项后重新调用 build 刷新，
-- 菜单保持打开。menu:OpenAtCursor(build) 在鼠标处弹出。点菜单以外的地方或按 Esc 关闭。
-- UI:ContextMenu(build) 用全插件共用的一个右键菜单在鼠标处弹出。
--------------------------------------------------------------------------------

local MENU_ROW = 18
local MENU_PAD = 6
local MENU_GAP = 14 -- 名称与右侧控件之间至少留的空
local MENU_INDENT = 10 -- 分组里的条目缩进

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
        row.fold = UI:Text(row, "Accent")
        row.fold:SetPoint("RIGHT", -MENU_PAD - 1, 0)
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
            local keepOpen = entry.kind == "check" or entry.kind == "group" or entry.keepOpen
            if not keepOpen then
                menu:Hide()
            end
            entry.onClick(not entry.checked)
            if keepOpen then
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
        local entries = type(self.build) == "function" and self.build() or self.build or {}
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
            local indent = entry.indent and MENU_INDENT or 0
            row.text:SetPoint("LEFT", MENU_PAD + indent, 0)
            row.fold:SetShown(entry.kind == "group")
            row.fold:SetText(entry.expanded and "-" or "+")
            for _, option in ipairs(row.options) do
                option:Hide()
            end
            local rowWidth = MENU_PAD + indent + row.text:GetStringWidth() + MENU_PAD
            if entry.kind == "check" or entry.kind == "group" then
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

    -- 在鼠标处弹出（右键菜单）；菜单限制在屏幕内，靠近屏幕边缘时自动挪回来
    function menu:OpenAtCursor(build)
        self.build, self.anchor = build, nil
        local scale = UIParent:GetEffectiveScale()
        local x, y = GetCursorPosition()
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x or 0) / scale + 2, (y or 0) / scale - 2)
        self:Refresh()
        self:Show()
    end

    UI:AutoClose(menu, function()
        return menu.anchor
    end)
    return menu
end

-- 右键菜单：全插件共用一个，在鼠标处弹出。build 是条目表或返回条目表的函数（见上面的条目说明）
local contextMenu

function UI:ContextMenu(build)
    contextMenu = contextMenu or UI:CheckMenu("WowHandbookContextMenu")
    GameTooltip_Hide()
    contextMenu:OpenAtCursor(build)
    return contextMenu
end

-- 浮动小窗（副本助手、解谜小窗）右键菜单里共用的两项：锁定位置、大小。
-- settings 为模块设置（locked、scale），apply() 在大小改变后调用，由小窗按 settings.scale 重新缩放
local WINDOW_SCALES = { 0.85, 1, 1.15, 1.3 }

function UI:WindowMenuEntries(settings, apply)
    local choices = {}
    for _, scale in ipairs(WINDOW_SCALES) do
        tinsert(choices, { id = scale, text = ("%d%%"):format(math.floor(scale * 100 + 0.5)) })
    end
    return {
        { kind = "check", text = ns.L["Lock position"], checked = settings.locked == true,
            tip = ns.L["Keep this window where it is; dragging no longer moves it"],
            onClick = function(checked) settings.locked = checked or nil end },
        { kind = "choice", text = ns.L["Size"], choices = choices, value = settings.scale or 1,
            onClick = function(id)
                settings.scale = id ~= 1 and id or nil
                apply()
            end },
    }
end

--------------------------------------------------------------------------------
-- 内容堆叠：在滚动区域里自上而下排列标题、文字、带按钮的行、物品图标行。
-- 每次刷新先 Reset() 再依次添加，最后 Finish() 返回总高度。控件放在对象池里复用。
--------------------------------------------------------------------------------

function UI:Stack(parent)
    -- inset / insetRight：BeginBox 与 EndBox 之间的内容整体内缩
    local stack = { parent = parent, y = 0, inset = 0, insetRight = 0,
        pools = { text = {}, button = {}, item = {}, texture = {} }, used = {} }

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
        self.inset, self.insetRight, self.box = 0, 0, nil
    end

    function stack:Width()
        local width = self.parent:GetWidth()
        -- 滚动区域首次显示时可能还没有宽度，用父滚动框或默认宽度兜底
        if not width or width < 100 then
            local scroll = self.parent:GetParent()
            width = scroll and scroll.GetWidth and scroll:GetWidth() or 0
        end
        width = width >= 100 and width or 640
        return width - self.inset - self.insetRight
    end

    local function Left(indent)
        return stack.inset + (indent or 0)
    end

    -- 纯色贴图（画在父框架的 BACKGROUND 层，文字与按钮都在它上面）
    local function Fill(color, sublevel)
        local texture = Take("texture", function()
            return stack.parent:CreateTexture(nil, "BACKGROUND")
        end)
        texture:SetDrawLayer("BACKGROUND", sublevel or 0)
        Theme:Paint(texture, color)
        return texture
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
        fontString:SetPoint("TOPLEFT", Left(indent), -self.y)
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

    -- 小标题：强调色小字，比 Heading 轻，用于分组
    function stack:Subheading(text, gap)
        self.y = self.y + 4
        self:Text(text, "Accent", 0, gap or 6)
    end

    -- 1 像素分隔线
    function stack:Divider(gap)
        local line = Fill("lineSoft", 1)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", Left(0), -self.y)
        line:SetWidth(self:Width())
        self.y = self.y + 1 + (gap or 8)
    end

    -- 进度条：fraction 0–1，color 为已完成部分的主题色
    function stack:Progress(fraction, color, height)
        height = height or 6
        local width = self:Width()
        local track = Fill("track", 1)
        track:SetPoint("TOPLEFT", Left(0), -self.y)
        track:SetSize(width, height)
        fraction = math.max(0, math.min(1, fraction or 0))
        if fraction > 0 then
            local bar = Fill(color or "gold", 2)
            bar:SetPoint("TOPLEFT", Left(0), -self.y)
            bar:SetSize(math.max(1, width * fraction), height)
        end
        self.y = self.y + height + 8
    end

    -- 背景框：BeginBox 之后添加的内容内缩，EndBox 在这段内容背后画底色、边框与左侧色条。不嵌套
    local BOX_PAD, BOX_LEFT = 10, 14
    function stack:BeginBox(accent, background)
        self.box = { top = self.y, accent = accent or "gold", background = background or "raised" }
        self.inset, self.insetRight = BOX_LEFT, BOX_PAD
        self.y = self.y + BOX_PAD
    end

    function stack:EndBox(gap)
        local box = self.box
        if not box then
            return
        end
        self.box = nil
        self.inset, self.insetRight = 0, 0
        self.y = self.y + BOX_PAD - 4
        local width, height = self:Width(), self.y - box.top
        local background = Fill(box.background, 0)
        background:SetPoint("TOPLEFT", 0, -box.top)
        background:SetSize(width, height)
        local edges = {
            { "TOPLEFT", 0, -box.top, width, 1 },
            { "TOPLEFT", 0, -(self.y - 1), width, 1 },
            { "TOPLEFT", 0, -box.top, 1, height },
            { "TOPLEFT", width - 1, -box.top, 1, height },
        }
        for _, edge in ipairs(edges) do
            local line = Fill("lineSoft", 1)
            line:SetPoint(edge[1], edge[2], edge[3])
            line:SetSize(edge[4], edge[5])
        end
        local accent = Fill(box.accent, 2)
        accent:SetPoint("TOPLEFT", 1, -(box.top + 1))
        accent:SetSize(3, height - 2)
        self.y = self.y + (gap or 8)
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
            button:SetPoint("TOPRIGHT", -(self.insetRight + rightEdge), -top)
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
        fontString:SetPoint("TOPLEFT", Left(indent), -top - 3)
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
            button:SetPoint("TOPLEFT", Left(indent), -self.y)
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

--------------------------------------------------------------------------------
-- 走势图：按天（或任意数值横轴）的折线，几条序列共用一根纵轴。
-- chart:SetSeries({ { color = "gold", points = { { x = 横轴值, y = 纵轴值 }, ... } }, ... }, format)
--   format.x(值) / format.y(值) 返回刻度文字（可省略）；点按 x 从小到大传入。
-- 线与点每次重画都现取 Theme.colors，配色方案变化时整张图重画；只有一个点的序列只画点。
-- 横轴刻度取整数（如天），画在各自的真实位置，不重复；跨度不超过 6 时每个整数一格。
-- leftMargin 为纵轴刻度文字留的宽度（默认 64）。
-- chart:SetEmptyText(文字)：没有数据时居中显示
--------------------------------------------------------------------------------

function UI:TrendChart(parent, leftMargin)
    local chart = UI:Panel(parent, "panel", "lineSoft")
    local plot = CreateFrame("Frame", nil, chart)
    plot:SetPoint("TOPLEFT", leftMargin or 64, -12)
    plot:SetPoint("BOTTOMRIGHT", -14, 24)
    chart.plot = plot
    local GRID = 4
    local grid, yLabels, xLabels = {}, {}, {}
    for index = 0, GRID do
        grid[index] = Theme:Fill(plot, "lineSoft", "BACKGROUND")
        grid[index]:SetHeight(1)
        yLabels[index] = UI:Text(chart, "Muted")
        yLabels[index]:SetJustifyH("RIGHT")
    end
    chart.empty = UI:Text(chart, "Muted")
    chart.empty:SetPoint("CENTER", plot, "CENTER")
    local lines, dots = {}, {}
    chart.lines, chart.dots = lines, dots -- 供测试使用

    function chart:SetEmptyText(text)
        self.emptyText = text
        self:Redraw()
    end

    function chart:SetSeries(series, format)
        self.series = series or {}
        self.format = format or {}
        self:Redraw()
    end

    function chart:Redraw()
        local usedLines, usedDots = 0, 0
        local minX, maxX, minY, maxY
        for _, serie in ipairs(self.series or {}) do
            for _, point in ipairs(serie.points or {}) do
                minX, maxX = math.min(minX or point.x, point.x), math.max(maxX or point.x, point.x)
                minY, maxY = math.min(minY or point.y, point.y), math.max(maxY or point.y, point.y)
            end
        end
        local width, height = plot:GetWidth() or 0, plot:GetHeight() or 0
        local hasData = minX ~= nil and width > 0 and height > 0
        self.empty:SetText(minX == nil and (self.emptyText or "") or "")
        if hasData then
            if maxX == minX then
                minX, maxX = minX - 1, maxX + 1
            end
            local pad = (maxY - minY) * 0.08
            if pad == 0 then
                pad = math.max(1, maxY * 0.1)
            end
            minY, maxY = math.max(0, minY - pad), maxY + pad
        end
        local formatX, formatY = self.format and self.format.x, self.format and self.format.y
        for index = 0, GRID do
            local ratio = index / GRID
            grid[index]:ClearAllPoints()
            grid[index]:SetPoint("BOTTOMLEFT", plot, "BOTTOMLEFT", 0, height * ratio)
            grid[index]:SetPoint("BOTTOMRIGHT", plot, "BOTTOMRIGHT", 0, height * ratio)
            yLabels[index]:ClearAllPoints()
            yLabels[index]:SetPoint("RIGHT", plot, "BOTTOMLEFT", -6, height * ratio)
            if hasData then
                local yValue = minY + (maxY - minY) * ratio
                yLabels[index]:SetText(formatY and formatY(yValue) or tostring(floor(yValue + 0.5)))
            else
                yLabels[index]:SetText("")
            end
        end
        -- 横轴刻度：整数值，跨度小时逐个，跨度大时约 5 格；同一个值只标一次
        local ticks = {}
        if hasData then
            local first, last = math.ceil(minX), floor(maxX)
            local step = math.max(1, math.ceil((last - first) / GRID))
            for value = first, last, step do
                tinsert(ticks, value)
            end
            if ticks[#ticks] ~= last then
                ticks[#ticks] = last
            end
        end
        for index = 1, math.max(#ticks, #xLabels) do
            local label = xLabels[index]
            if not label and ticks[index] then
                label = UI:Text(chart, "Muted")
                xLabels[index] = label
            end
            if label then
                local value = ticks[index]
                if value then
                    label:ClearAllPoints()
                    label:SetPoint("TOP", plot, "BOTTOMLEFT", (value - minX) / (maxX - minX) * width, -6)
                    label:SetText(formatX and formatX(value) or tostring(value))
                    label:Show()
                else
                    label:Hide()
                end
            end
        end
        self.xTicks = ticks -- 供测试使用
        if hasData then
            local function Position(point)
                return (point.x - minX) / (maxX - minX) * width, (point.y - minY) / (maxY - minY) * height
            end
            for _, serie in ipairs(self.series) do
                local color = C[serie.color or "gold"] or C.gold
                local previousX, previousY
                for _, point in ipairs(serie.points or {}) do
                    local x, y = Position(point)
                    if previousX then
                        usedLines = usedLines + 1
                        local line = lines[usedLines] or plot:CreateLine(nil, "ARTWORK")
                        lines[usedLines] = line
                        line:SetThickness(2)
                        line:SetColorTexture(color[1], color[2], color[3], 1)
                        line:SetStartPoint("BOTTOMLEFT", plot, previousX, previousY)
                        line:SetEndPoint("BOTTOMLEFT", plot, x, y)
                        line:Show()
                    end
                    usedDots = usedDots + 1
                    local dot = dots[usedDots] or plot:CreateTexture(nil, "OVERLAY")
                    dots[usedDots] = dot
                    dot:SetSize(5, 5)
                    dot:ClearAllPoints()
                    dot:SetPoint("CENTER", plot, "BOTTOMLEFT", x, y)
                    dot:SetColorTexture(color[1], color[2], color[3], 1)
                    dot:Show()
                    previousX, previousY = x, y
                end
            end
        end
        for index = usedLines + 1, #lines do
            lines[index]:Hide()
        end
        for index = usedDots + 1, #dots do
            dots[index]:Hide()
        end
        self.drawnLines, self.drawnDots = usedLines, usedDots
    end

    plot:SetScript("OnSizeChanged", function()
        chart:Redraw()
    end)
    -- 面板本身的底色已由 UI:Panel 登记在 chart 上，重画函数登记在绘图区上，免得互相覆盖
    Theme:Track(plot, function()
        chart:Redraw()
    end)
    return chart
end
