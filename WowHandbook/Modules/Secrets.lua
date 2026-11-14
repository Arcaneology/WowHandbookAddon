local ADDON_NAME, ns = ...
local K = ns.Theme.code -- 文字里内嵌的颜色（|c 前缀）；强调色随配色方案变化，用的时候再取
local L = ns.L

-- 解谜助手：长任务链（舒适的睡袋、黎明唤醒者）的独立小窗。步骤定义见 Modules/SecretChains.lua。
-- · 自动跟进：每一步按任务完成记录、任务日志、背包与银行里的物品、身上的装备判断完成与否；
--   客户端看不出来的步骤（打开宝库、和某人对话）由玩家在小窗里勾选，存角色存档。
-- · 下一步：按阶段顺序找第一个没完成的阶段；可按任意顺序做的阶段（parallel）里没完成的步骤都是下一步。
--   小窗上半部分是“现在做什么”：步骤名、按当前状态给的提示、缺的东西（标红）、任务目标进度、
--   可点击的地点（设地图标记，Shift 点击同时打开大地图）；下半部分是全部步骤，点一行看那一步，右键勾选手动步骤。
-- · 进度推进（自动判断到某一步完成）时在聊天框说一声完成了什么、下一步是什么（设置可关）。
-- · 接到某条链的任务时自动切到那条链。
-- · 主窗口“解谜”页另有“图书馆藏书”一项：每本书的获取状态、可能的位置（可追踪）、交书地点与阶段奖励。
-- 开关：设置项 shown（默认关）；/wh secrets 显示或隐藏。事件只在小窗或解谜页显示时订阅，刷新合并到 0.5 秒一次。
local Module = ns:NewModule("Secrets", { shown = false, announce = true, collapsed = false })

local WIDTH, PAD, ROW_HEIGHT = 270, 10, 18
local LIST_MAX_HEIGHT = 190
local READY_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"
local UI
local frame
local page -- 主窗口里的解谜页（第一次打开时创建）
local focus -- 玩家点选查看的步骤 id；nil 时看下一步
local lastDone = {} -- [链 id] = { [步骤 id] = true }：上次刷新时已完成的步骤，用来发现进度推进
local suppressAnnounce = false

local function Settings()
    return ns:GetModuleSettings(Module)
end

local function CharState()
    local state = ns.charDB.secrets
    if type(state) ~= "table" then
        state = {}
        ns.charDB.secrets = state
    end
    state.manual = state.manual or {}
    return state
end

local function Faction()
    return ns.PlayerFaction() or "A"
end

-- 按阵营取值：{ A = …, H = … } 取本阵营的，其他原样返回
local function ByFaction(value)
    if type(value) == "table" and (value.A or value.H) then
        return value[Faction()] or value.A or value.H
    end
    return value
end

local function ChainByID(id)
    for _, chain in ipairs(ns.SecretChains or {}) do
        if chain.id == id then
            return chain
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- 玩家状态
--------------------------------------------------------------------------------

local function ItemCount(itemID)
    local count = C_Item.GetItemCount and C_Item.GetItemCount(itemID, true)
    return count or 0
end

local function IsEquipped(itemID)
    return C_Item.IsEquippedItem and C_Item.IsEquippedItem(itemID) and true or false
end

local function QuestDone(questID)
    return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
end

local function OnQuest(questID)
    return C_QuestLog.GetLogIndexForQuestID(questID) ~= nil
end

-- 交给步骤 status 函数的查询
local ctx = {
    has = function(itemID, count) return ItemCount(itemID) >= (count or 1) end,
    equipped = IsEquipped,
    questDone = QuestDone,
    onQuest = OnQuest,
}
Module.ctx = ctx -- 供测试使用

local function ManualDone(chain, step)
    local manual = CharState().manual[chain.id]
    return manual and manual[step.id] == true
end

-- 这一步自己的完成判断（不含 after）
local function RawDone(chain, step)
    local questID = ByFaction(step.quest)
    if questID and QuestDone(questID) then
        return true
    end
    for _, item in ipairs(step.items or {}) do
        if ItemCount(item[1]) >= (item[2] or 1) then
            return true
        end
    end
    if step.equipped and IsEquipped(step.equipped) then
        return true
    end
    for _, id in ipairs(step.doneQuests or {}) do
        if QuestDone(id) then
            return true
        end
    end
    return step.manual and ManualDone(chain, step) or false
end

-- 整条链的状态：{ chain, rows = { { step, state, questID } }, byID, done, total, next = { [步骤 id] = true }, first }
-- state：done 已完成、ready 任务目标已完成待交、active 任务进行中、todo 还没做
local function Evaluate(chain)
    local rows, byID = {}, {}
    for index, step in ipairs(chain.steps) do
        local row = { step = step, index = index, questID = ByFaction(step.quest) }
        row.done = RawDone(chain, step)
        rows[index] = row
        byID[step.id] = row
    end
    -- after：后面的步骤完成了，这一步也算完成（链式推导，最多推导步骤数那么多轮）
    for _ = 1, #rows do
        local changed = false
        for _, row in ipairs(rows) do
            if not row.done then
                for _, id in ipairs(row.step.after or {}) do
                    if byID[id] and byID[id].done then
                        row.done, changed = true, true
                        break
                    end
                end
            end
        end
        if not changed then
            break
        end
    end
    local result = { chain = chain, rows = rows, byID = byID, done = 0, total = 0, next = {} }
    for _, row in ipairs(rows) do
        if row.done then
            row.state = "done"
        elseif row.questID and OnQuest(row.questID) then
            row.state = (C_QuestLog.IsComplete and C_QuestLog.IsComplete(row.questID)) and "ready" or "active"
        else
            row.state = "todo"
        end
        if not row.step.optional then
            result.total = result.total + 1
            if row.done then
                result.done = result.done + 1
            end
        end
    end
    -- 下一步：第一个还有必做步骤没完成的阶段
    for _, group in ipairs(chain.groups) do
        local pending = {}
        for _, row in ipairs(rows) do
            if row.step.group == group.id and not row.done and not row.step.optional then
                tinsert(pending, row)
            end
        end
        if #pending > 0 then
            if group.parallel then
                for _, row in ipairs(pending) do
                    result.next[row.step.id] = true
                end
            else
                result.next[pending[1].step.id] = true
            end
            result.first = pending[1]
            break
        end
    end
    -- 可选步骤：前一步完成后就能做，跟着列为下一步（不挡后面的步骤）
    for index, row in ipairs(rows) do
        if row.step.optional and not row.done and (index == 1 or rows[index - 1].done) then
            result.next[row.step.id] = true
        end
    end
    -- 进行中的任务优先当作“现在做什么”
    for _, row in ipairs(rows) do
        if row.state == "ready" or row.state == "active" then
            result.first = row
            break
        end
    end
    result.complete = result.done >= result.total
    return result
end
Module.Evaluate = Evaluate -- 供测试使用

-- 步骤名：任务用客户端的任务名，还没缓存时请求加载并先用本地化名
local requested = {}
local function QuestTitle(questID)
    local title = C_QuestLog.GetTitleForQuestID(questID)
    if title and title ~= "" then
        return title
    end
    if not requested[questID] and C_QuestLog.RequestLoadQuestByID then
        requested[questID] = true
        C_QuestLog.RequestLoadQuestByID(questID)
    end
    return nil
end

local function StepTitle(row)
    return row.questID and QuestTitle(row.questID) or L[row.step.title or "?"]
end

-- 当前状态下的提示
local function StepHint(row)
    local step = row.step
    local text = step.status and step.status(ctx)
    if not text then
        if (row.state == "active" or row.state == "ready") and step.active then
            text = ByFaction(step.active)
        else
            text = ByFaction(step.todo)
        end
    end
    return text and L[text] or nil
end

-- 缺的东西：{ 文字 }；已完成的步骤不提醒
local function MissingNeeds(row)
    local missing = {}
    if row.done then
        return missing
    end
    for _, need in ipairs(row.step.needs or {}) do
        if need.item and ItemCount(need.item) < 1 then
            tinsert(missing, L["Missing: %s"]:format(ns.ItemLink(need.item)))
        elseif need.equipped and not IsEquipped(need.equipped) then
            tinsert(missing, L["Not equipped: %s"]:format(ns.ItemLink(need.equipped)))
        end
    end
    return missing
end

-- 任务目标进度行
local function ObjectiveLines(row)
    local lines = {}
    if not (row.questID and (row.state == "active" or row.state == "ready")) then
        return lines
    end
    for _, objective in ipairs(C_QuestLog.GetQuestObjectives(row.questID) or {}) do
        if objective.text and objective.text ~= "" then
            tinsert(lines, (objective.finished and K.green or K.textDim) .. objective.text .. "|r")
        end
    end
    return lines
end

local function Spots(step)
    local spots = {}
    for _, spot in ipairs(step.spots or {}) do
        if not spot[5] or spot[5] == Faction() then
            tinsert(spots, spot)
        end
    end
    return spots
end

--------------------------------------------------------------------------------
-- 选链
--------------------------------------------------------------------------------

local function ChainQuests(chain)
    local ids = {}
    for _, step in ipairs(chain.steps) do
        local quest = step.quest
        if type(quest) == "table" then
            for _, id in pairs(quest) do
                ids[id] = true
            end
        elseif quest then
            ids[quest] = true
        end
        for _, id in ipairs(step.doneQuests or {}) do
            ids[id] = true
        end
    end
    return ids
end

-- 选中的链：存档里的；没有时选有进度但没做完的第一条，都没有就第一条
local function CurrentChain()
    local chain = ChainByID(CharState().chain)
    if chain then
        return chain
    end
    for _, candidate in ipairs(ns.SecretChains) do
        local result = Evaluate(candidate)
        if result.done > 0 and not result.complete then
            return candidate
        end
    end
    return ns.SecretChains[1]
end

local Refresh, RefreshPage, UpdateEvents

-- 小窗与主窗口页面一起刷新（各自不可见时直接跳过）
local function RefreshAll()
    Refresh()
    RefreshPage()
end

local LIBRARY = "library" -- 解谜页左侧列表里“图书馆藏书”一项的 id

local function SelectChain(id)
    local state = CharState()
    if state.chain == id and state.view ~= LIBRARY then
        return
    end
    state.view = nil
    state.chain = id
    focus = nil
    if frame then
        frame.listScroll:ScrollToTop()
    end
    RefreshAll()
end
Module.SelectChain = SelectChain -- 供测试使用

local function ToggleManual(chain, step)
    local manual = CharState().manual
    manual[chain.id] = manual[chain.id] or {}
    manual[chain.id][step.id] = not manual[chain.id][step.id] or nil
    -- 自己勾的不用再在聊天框里说一遍
    suppressAnnounce = true
    RefreshAll()
    suppressAnnounce = false
end
Module.ToggleManual = ToggleManual -- 供测试使用

--------------------------------------------------------------------------------
-- 进度推进提示
--------------------------------------------------------------------------------

local function Announce(result)
    local previous = lastDone[result.chain.id]
    local now = {}
    for _, row in ipairs(result.rows) do
        if row.done then
            now[row.step.id] = true
        end
    end
    lastDone[result.chain.id] = now
    if not previous or suppressAnnounce or not Settings().announce then
        return
    end
    for _, row in ipairs(result.rows) do
        if now[row.step.id] and not previous[row.step.id] then
            local chainName = L[result.chain.title]
            if result.complete then
                ns:Print(L["%s: all steps done!"], chainName)
            elseif result.first then
                ns:Print(L["%s: \"%s\" done. Next: %s"], chainName, StepTitle(row), StepTitle(result.first))
            end
            return
        end
    end
end

--------------------------------------------------------------------------------
-- 界面
--------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relativePoint, x, y = frame:GetPoint()
    Settings().position = { point, relativePoint, x, y }
end

local function RestorePosition()
    local position = Settings().position
    frame:ClearAllPoints()
    if position then
        frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -480)
    end
end

local function SetColor(texture, name)
    texture:SetColorTexture(unpack(ns.Theme.colors[name]))
end

-- 状态标记：done 绿勾，next 金色方块，active 蓝色方块，其余灰色小方块
local function SetMarker(holder, state)
    holder.check:SetShown(state == "done")
    holder.dot:SetShown(state ~= "done")
    if state ~= "done" then
        local color = (state == "next" and "gold") or (state == "active" and "blue") or "muted"
        SetColor(holder.dot, color)
        local size = state == "next" and 7 or 5
        holder.dot:SetSize(size, size)
    end
end

local function AddMarker(parent)
    parent.check = parent:CreateTexture(nil, "ARTWORK")
    parent.check:SetSize(12, 12)
    parent.check:SetPoint("LEFT", 2, 0)
    parent.check:SetTexture(READY_ICON)
    parent.dot = parent:CreateTexture(nil, "ARTWORK")
    parent.dot:SetPoint("CENTER", parent.check, "CENTER")
end

local function MarkerState(result, row)
    if row.done then
        return "done"
    elseif row.state == "active" or row.state == "ready" then
        return "active"
    elseif result.next[row.step.id] then
        return "next"
    end
    return "todo"
end

local function StateLabel(result, row)
    if row.done then
        return K.green .. L["Done"] .. "|r"
    elseif row.state == "ready" then
        return K.blue .. L["Ready to turn in"] .. "|r"
    elseif row.state == "active" then
        return K.blue .. L["In progress"] .. "|r"
    elseif row.step.optional then
        return K.muted .. L["Optional"] .. "|r"
    elseif result.next[row.step.id] then
        return K.gold .. L["Next step"] .. "|r"
    end
    return K.muted .. L["Later"] .. "|r"
end

local function SpotTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L[self.spot[4]], 1, 0.82, 0)
    GameTooltip:AddLine(("%s %.1f, %.1f"):format(ns.MapName(self.spot[1]) or "?", self.spot[2], self.spot[3]), 1, 1, 1)
    GameTooltip:AddLine(L["Click: set a waypoint · Shift-click: also open the map"], 0.54, 0.51, 0.45)
    GameTooltip:Show()
end

local function SpotButton(index)
    local button = frame.spotButtons[index]
    if button then
        return button
    end
    button = CreateFrame("Button", nil, frame)
    button:SetHeight(ROW_HEIGHT)
    button.hover = button:CreateTexture(nil, "BACKGROUND")
    button.hover:SetAllPoints()
    SetColor(button.hover, "glassHover")
    button.hover:Hide()
    button.pin = button:CreateTexture(nil, "ARTWORK")
    button.pin:SetSize(12, 12)
    button.pin:SetPoint("LEFT", 2, 0)
    button.pin:SetTexture("Interface\\Minimap\\Tracking\\None")
    button.text = UI:Text(button, "Small")
    button.text:SetPoint("LEFT", 18, 0)
    button.text:SetPoint("RIGHT", -2, 0)
    button.text:SetWordWrap(false)
    button:SetScript("OnEnter", function(self)
        self.hover:Show()
        SpotTooltip(self)
    end)
    button:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip_Hide()
    end)
    button:SetScript("OnClick", function(self)
        local spot = self.spot
        if IsShiftKeyDown and IsShiftKeyDown() then
            ns.Waypoints:ShowOnMap(spot[1], spot[2], spot[3], L[spot[4]])
        else
            ns.Waypoints:Set(spot[1], spot[2], spot[3], L[spot[4]])
        end
    end)
    frame.spotButtons[index] = button
    return button
end

local function ListRow(index)
    local row = frame.listRows[index]
    if row then
        return row
    end
    row = CreateFrame("Button", nil, frame.listScroll.child)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.hover = row:CreateTexture(nil, "BACKGROUND")
    row.hover:SetAllPoints()
    SetColor(row.hover, "glassHover")
    row.hover:Hide()
    row.selected = row:CreateTexture(nil, "BACKGROUND")
    row.selected:SetAllPoints()
    SetColor(row.selected, "selected")
    row.selected:Hide()
    AddMarker(row)
    row.name = UI:Text(row, "Small")
    row.name:SetPoint("LEFT", 18, 0)
    row.name:SetPoint("RIGHT", -4, 0)
    row.name:SetWordWrap(false)
    row.heading = UI:Text(row, "Accent")
    row.heading:SetPoint("LEFT", 2, 0)
    row.heading:SetPoint("RIGHT", -4, 0)
    row.heading:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
        if not self.row then
            return
        end
        self.hover:Show()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(StepTitle(self.row), 1, 0.82, 0)
        local hint = StepHint(self.row)
        if hint then
            GameTooltip:AddLine(hint, 1, 1, 1, true)
        end
        GameTooltip:AddLine(L["Click: show this step · Right-click: menu"], 0.54, 0.51, 0.45)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip_Hide()
    end)
    row:SetScript("OnClick", function(self, button)
        if not self.row then
            return
        end
        local stepRow = self.row
        local function ShowStep()
            focus = stepRow.step.id
            Refresh()
        end
        if button == "RightButton" then
            -- 右键菜单：查看这一步；游戏判断不了的步骤可以手动标记完成或取消
            local entries = {
                { kind = "title", text = StepTitle(stepRow) },
                { kind = "action", text = L["Show this step"], onClick = ShowStep },
            }
            if stepRow.step.manual then
                tinsert(entries, { kind = "action", text = stepRow.done and L["Mark as not done"] or L["Mark as done"],
                    onClick = function()
                        ToggleManual(CurrentChain(), stepRow.step)
                    end })
            end
            UI:ContextMenu(entries)
            return
        end
        ShowStep()
    end)
    frame.listRows[index] = row
    return row
end

-- 小窗的右键菜单：锁定位置、大小；打开手册的解谜页；打开设置
local function WindowMenu()
    UI:ContextMenu(function()
        local entries = UI:WindowMenuEntries(Settings(), function()
            if frame then
                frame:SetScale(Settings().scale or 1)
            end
        end)
        tinsert(entries, { kind = "separator" })
        if ns.MainFrame:HasTab("secrets") then
            tinsert(entries, { kind = "action", text = L["Open in WoW Handbook"], onClick = function()
                ns.MainFrame:Open("secrets")
            end })
        end
        tinsert(entries, { kind = "action", text = L["Settings"], onClick = function()
            ns.MainFrame:Open("settings")
        end })
        return entries
    end)
end
Module.WindowMenu = WindowMenu -- 供测试使用

local function Toggle()
    Settings().shown = not (frame and frame:IsShown())
    Module:Refresh()
end
Module.Toggle = Toggle -- 供测试使用

local function Create()
    UI = ns.UI
    local f = CreateFrame("Frame", "WowHandbookSecretsFrame", UIParent, "BackdropTemplate")
    ns.Theme:Skin(f, "glass", "glassLine")
    f:SetWidth(WIDTH)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScale(Settings().scale or 1)
    f:SetScript("OnDragStart", function(self)
        if not Settings().locked then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    -- 右键小窗空白处：锁定位置、大小、打开手册与设置
    f:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            WindowMenu()
        end
    end)
    f:SetScript("OnShow", function()
        UpdateEvents()
        Refresh()
    end)
    f:SetScript("OnHide", function()
        UpdateEvents()
        RefreshPage() -- 主窗口页面上“显示小窗”按钮的文字跟着变
    end)

    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", -1, -1)
    accent:SetHeight(2)
    ns.Theme:Paint(accent, "gold")

    f.close = UI:CloseButton(f, function()
        Settings().shown = false
        f:Hide()
        ns:Print(L["Secrets helper hidden. Type /wh secrets to show it again."])
    end, 18)
    f.close:SetPoint("TOPRIGHT", -3, -6)
    f.collapse = UI:Button(f, "-", 16, 16, "ghost")
    f.collapse:SetPoint("RIGHT", f.close, "LEFT", -1, 0)
    f.collapse:SetScript("OnClick", function()
        Settings().collapsed = not Settings().collapsed
        Refresh()
    end)

    -- 标题即选链下拉框
    local items = {}
    for _, chain in ipairs(ns.SecretChains) do
        tinsert(items, { id = chain.id, label = L[chain.title] })
    end
    f.chain = UI:Dropdown(f, items, SelectChain, WIDTH - PAD * 2 - 38)
    f.chain:SetHeight(20)
    f.chain:SetPoint("TOPLEFT", PAD, -7)

    f.progressText = UI:Text(f, "Small")
    f.progressText:SetPoint("TOPLEFT", PAD, -33)
    f.levelText = UI:Text(f, "Small")
    f.levelText:SetPoint("TOPRIGHT", -PAD, -33)
    f.levelText:SetJustifyH("RIGHT")
    f.track = f:CreateTexture(nil, "ARTWORK")
    f.track:SetPoint("TOPLEFT", PAD, -49)
    f.track:SetSize(WIDTH - PAD * 2, 3)
    SetColor(f.track, "track")
    f.fill = f:CreateTexture(nil, "OVERLAY")
    f.fill:SetPoint("TOPLEFT", f.track, "TOPLEFT")
    f.fill:SetHeight(3)
    SetColor(f.fill, "green")

    -- 现在做什么
    f.focus = CreateFrame("Frame", nil, f)
    f.focus:SetSize(WIDTH - PAD * 2, ROW_HEIGHT)
    AddMarker(f.focus)
    f.focusTitle = UI:Text(f.focus, "Heading")
    f.focusTitle:SetPoint("LEFT", 18, 0)
    f.focusTitle:SetPoint("RIGHT", -70, 0)
    f.focusTitle:SetWordWrap(false)
    f.focusState = UI:Text(f.focus, "Small")
    f.focusState:SetPoint("RIGHT", 0, 0)
    f.focusState:SetJustifyH("RIGHT")
    f.hint = UI:Text(f, "Body")
    f.hint:SetWidth(WIDTH - PAD * 2)
    f.hint:SetWordWrap(true)
    f.needs = UI:Text(f, "Small")
    f.needs:SetWidth(WIDTH - PAD * 2)
    f.needs:SetWordWrap(true)
    f.needs:SetTextColor(unpack(ns.Theme.colors.red))
    f.objectives = UI:Text(f, "Small")
    f.objectives:SetWidth(WIDTH - PAD * 2)
    f.objectives:SetWordWrap(true)
    f.spotButtons = {}
    f.manual = UI:Button(f, "", 120, 20)
    f.manual:SetScript("OnClick", function(self)
        if self.step then
            ToggleManual(CurrentChain(), self.step)
        end
    end)
    f.back = UI:Button(f, L["Back to next step"], 110, 20, "ghost")
    f.back:SetScript("OnClick", function()
        focus = nil
        Refresh()
    end)

    -- 全部步骤
    f.divider = f:CreateTexture(nil, "ARTWORK")
    f.divider:SetHeight(1)
    f.divider:SetWidth(WIDTH - PAD * 2)
    SetColor(f.divider, "lineSoft")
    f.listScroll = UI:ScrollArea(f)
    f.listRows = {}

    f.link = UI:Button(f, L["Full walkthrough"], 120, 20, "ghost")
    f.link:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("secret", CurrentChain().site))
    end)
    f.link:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Full walkthrough"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Copy the website link: the full walkthrough with maps for every step"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.link:HookScript("OnLeave", GameTooltip_Hide)

    f:Hide()
    return f
end

local function TextHeight(fontString)
    return math.max(fontString:GetStringHeight() or 0, 12)
end

-- 文字块：有内容就放在 y 处并返回下一行的 y，没有内容就隐藏
local function PlaceText(fontString, text, y)
    if not text or text == "" then
        fontString:Hide()
        return y
    end
    fontString:SetText(text)
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPLEFT", PAD, -y)
    fontString:Show()
    return y + TextHeight(fontString) + 4
end

local function FocusRow(result)
    if focus and result.byID[focus] then
        return result.byID[focus], true
    end
    focus = nil
    return result.first, false
end

function Refresh()
    if not (frame and frame:IsShown()) then
        return
    end
    local chain = CurrentChain()
    local result = Evaluate(chain)
    Announce(result)
    local collapsed = Settings().collapsed
    frame.collapse:SetLabel(collapsed and "+" or "-")
    frame.chain:SetValue(chain.id)

    -- 进度
    frame.progressText:SetText(L["%d of %d steps"]:format(result.done, result.total))
    if chain.minLevel and ns.PlayerLevel() < chain.minLevel then
        frame.levelText:SetText(K.red .. L["From level %d"]:format(chain.minLevel) .. "|r")
    elseif chain.minLevel then
        frame.levelText:SetText(K.muted .. L["From level %d"]:format(chain.minLevel) .. "|r")
    else
        frame.levelText:SetText("")
    end
    local share = result.total > 0 and result.done / result.total or 0
    frame.fill:SetWidth(math.max(1, (WIDTH - PAD * 2) * share))
    frame.fill:SetShown(share > 0)

    -- 现在做什么
    local y = 58
    local row, picked = FocusRow(result)
    frame.focus:ClearAllPoints()
    frame.focus:SetPoint("TOPLEFT", PAD, -y)
    frame.focus:Show()
    local spots = {}
    if row then
        SetMarker(frame.focus, MarkerState(result, row))
        frame.focusTitle:SetText(StepTitle(row))
        frame.focusState:SetText(StateLabel(result, row))
        y = y + ROW_HEIGHT + 2
        y = PlaceText(frame.hint, StepHint(row), y)
        y = PlaceText(frame.needs, table.concat(MissingNeeds(row), "\n"), y)
        y = PlaceText(frame.objectives, table.concat(ObjectiveLines(row), "\n"), y)
        if not collapsed then
            spots = Spots(row.step)
        end
    else
        -- 全部完成
        SetMarker(frame.focus, "done")
        frame.focusTitle:SetText(L["All steps done"])
        frame.focusState:SetText("")
        y = y + ROW_HEIGHT + 2
        y = PlaceText(frame.hint, chain.ending and L[chain.ending], y)
        frame.needs:Hide()
        frame.objectives:Hide()
    end
    for index, spot in ipairs(spots) do
        local button = SpotButton(index)
        button.spot = spot
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", PAD - 2, -y)
        button:SetWidth(WIDTH - PAD * 2 + 4)
        button.text:SetText(("%s  " .. K.muted .. "%s %.1f, %.1f|r"):format(L[spot[4]], ns.MapName(spot[1]) or "?", spot[2], spot[3]))
        button:Show()
        y = y + ROW_HEIGHT
    end
    for index = #spots + 1, #frame.spotButtons do
        frame.spotButtons[index]:Hide()
    end
    -- 手动步骤的勾选按钮、看别的步骤时回到下一步
    local buttons = false
    frame.manual:Hide()
    frame.back:Hide()
    if not collapsed and row and row.step.manual then
        frame.manual.step = row.step
        frame.manual:SetLabel(ManualDone(chain, row.step) and L["Mark as not done"] or L["Mark as done"])
        frame.manual:ClearAllPoints()
        frame.manual:SetPoint("TOPLEFT", PAD, -(y + 4))
        frame.manual:Show()
        buttons = true
    end
    if not collapsed and picked then
        frame.back:ClearAllPoints()
        frame.back:SetPoint("TOPRIGHT", -PAD, -(y + 4))
        frame.back:Show()
        buttons = true
    end
    if buttons then
        y = y + 28
    end

    if collapsed then
        frame.divider:Hide()
        frame.listScroll:Hide()
        frame.listScroll.bar:Hide()
        frame.link:Hide()
        frame:SetHeight(y + 6)
        return
    end

    -- 全部步骤：阶段标题 + 步骤行
    y = y + 4
    frame.divider:ClearAllPoints()
    frame.divider:SetPoint("TOPLEFT", PAD, -y)
    frame.divider:Show()
    y = y + 6
    local used, listHeight = 0, 0
    local multiGroup = #chain.groups > 1
    for _, group in ipairs(chain.groups) do
        if multiGroup then
            used = used + 1
            local heading = ListRow(used)
            heading.row = nil
            heading.check:Hide()
            heading.dot:Hide()
            heading.name:Hide()
            heading.selected:Hide()
            heading.heading:SetText(L[group.title] .. (group.parallel and ("  " .. K.muted .. L["any order"] .. "|r") or ""))
            heading.heading:Show()
            heading:ClearAllPoints()
            heading:SetPoint("TOPLEFT", 0, -listHeight)
            heading:SetWidth(WIDTH - PAD * 2 - 4)
            heading:Show()
            listHeight = listHeight + ROW_HEIGHT
        end
        for _, stepRow in ipairs(result.rows) do
            if stepRow.step.group == group.id then
                used = used + 1
                local line = ListRow(used)
                line.row = stepRow
                line.heading:Hide()
                line.name:Show()
                SetMarker(line, MarkerState(result, stepRow))
                local color = stepRow.done and K.muted or K.text
                line.name:SetText(color .. StepTitle(stepRow) .. "|r")
                line.selected:SetShown(row == stepRow)
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", 0, -listHeight)
                line:SetWidth(WIDTH - PAD * 2 - 4)
                line:Show()
                listHeight = listHeight + ROW_HEIGHT
            end
        end
    end
    for index = used + 1, #frame.listRows do
        frame.listRows[index]:Hide()
    end
    local visible = math.min(listHeight, LIST_MAX_HEIGHT)
    frame.listScroll:ClearAllPoints()
    frame.listScroll:SetPoint("TOPLEFT", PAD - 2, -y)
    frame.listScroll:SetSize(WIDTH - PAD * 2 - 4, visible)
    frame.listScroll:Show()
    frame.listScroll:SetContentHeight(listHeight)
    frame.listScroll.bar:SetShown(listHeight > LIST_MAX_HEIGHT)
    y = y + visible + 6

    frame.link:ClearAllPoints()
    frame.link:SetPoint("TOPRIGHT", -PAD, -y)
    frame.link:Show()
    frame:SetHeight(y + 26)
end

--------------------------------------------------------------------------------
-- 事件：只在小窗或主窗口解谜页显示时订阅，合并刷新
--------------------------------------------------------------------------------

local pending = false
local function QueueRefresh()
    if pending or not ((frame and frame:IsVisible()) or (page and page:IsVisible())) then
        return
    end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        RefreshAll()
    end)
end

-- 接到某条链的任务：切到那条链
local function OnQuestAccepted(_, questID)
    for _, chain in ipairs(ns.SecretChains) do
        if ChainQuests(chain)[questID] then
            CharState().chain = chain.id
            focus = nil
            break
        end
    end
    QueueRefresh()
end

local EVENTS = {
    "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "QUEST_DATA_LOAD_RESULT", "BAG_UPDATE_DELAYED",
    "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP",
}
local eventsRegistered = false
local function SetEvents(active)
    if active == eventsRegistered then
        return
    end
    eventsRegistered = active
    local method = active and "RegisterEvent" or "UnregisterEvent"
    for _, event in ipairs(EVENTS) do
        ns[method](ns, event, QueueRefresh)
    end
    ns[method](ns, "QUEST_ACCEPTED", OnQuestAccepted)
end

function UpdateEvents()
    SetEvents(Module.enabled and ((frame and frame:IsShown()) or (page and page:IsVisible())) and true or false)
end

local itemListenerAdded = false
local function AddItemListener()
    if itemListenerAdded then
        return
    end
    itemListenerAdded = true
    ns.OnItemLoaded(function()
        if Module.enabled then
            QueueRefresh()
        end
    end)
end

--------------------------------------------------------------------------------
-- 主窗口页面（/wh → 解谜）：左侧选链，右侧整条链的每一步都展开：状态、提示、缺的东西、任务目标、地点
-- （“地图”按钮设标记并打开大地图）、手动步骤的勾选按钮。选中的链与手动勾选和小窗共用。
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 图书馆藏书（解谜页左侧列表的一项）：数据见 Data/LibraryBooks.lua。
-- 每本书一个捐书任务：任务完成 = 已捐；没捐但在背包或银行里 = 待交；其余 = 还没拿到，列出可能出现的位置
-- （“追踪”设地图标记，“地图”另打开大地图）。顶部是本阵营图书管理员的位置，接着是三个阶段奖励的进度。
--------------------------------------------------------------------------------

local function LibraryData()
    return ns.Data and ns.Data.libraryBooks
end

-- { books = { { book, state = "donated" / "bags" / "missing" } }, donated, bags, total }
local function EvaluateLibrary()
    local data = LibraryData()
    local result = { books = {}, donated = 0, bags = 0, total = 0 }
    for _, book in ipairs(data and data.books or {}) do
        local state = "missing"
        if QuestDone(book.quest) then
            state = "donated"
            result.donated = result.donated + 1
        elseif ItemCount(book.id) > 0 then
            state = "bags"
            result.bags = result.bags + 1
        end
        result.total = result.total + 1
        tinsert(result.books, { book = book, state = state })
    end
    return result
end
Module.EvaluateLibrary = EvaluateLibrary -- 供测试使用

local function Librarian()
    local data = LibraryData()
    local librarians = data and data.librarians or {}
    return librarians[Faction()] or librarians.A
end

local function SpotPlace(spot)
    if spot.map then
        return ("%s %.1f, %.1f"):format(ns.MapName(spot.map) or "?", spot.x, spot.y)
    end
    return ns.Name(spot.zone) or "?"
end

-- 地点行：有坐标的带“追踪”“地图”两个按钮
local function SpotRow(stack, text, spot, title, indent)
    local buttons
    if spot.map then
        buttons = {
            { label = L["Track"], variant = "primary", onClick = function()
                ns.Waypoints:Set(spot.map, spot.x, spot.y, title)
            end },
            { label = L["Map"], variant = "ghost", onClick = function()
                ns.Waypoints:ShowOnMap(spot.map, spot.x, spot.y, title)
            end },
        }
    end
    stack:Row(text, buttons, "Small", indent)
end

local function BookName(book)
    return ns.ItemLink(book.id)
end

-- 书的第一个地点所在区域名，用于分组与排序
local function BookZone(book)
    local spot = book.spots and book.spots[1]
    if not spot then
        return "?"
    end
    return spot.map and (ns.MapName(spot.map) or "?") or (ns.Name(spot.zone) or "?")
end

local function MilestoneLine(milestone, result)
    local title = QuestTitle(milestone.quest) or L["%d books"]:format(milestone.books)
    local status
    if QuestDone(milestone.quest) then
        status = ns.Theme:Color(L["Claimed"], "green")
    elseif result.donated >= milestone.books and ns.PlayerLevel() >= (milestone.minLevel or 1) then
        status = ns.Theme:Color(L["Ready to claim"], "gold")
    else
        status = ns.Theme:Color(L["%d/%d books"]:format(math.min(result.donated, milestone.books), milestone.books), "muted")
        if milestone.minLevel and milestone.minLevel > 1 then
            local level = L["From level %d"]:format(milestone.minLevel)
            status = status .. "  " .. (ns.PlayerLevel() < milestone.minLevel and ns.Theme:Color(level, "red")
                or ns.Theme:Color(level, "muted"))
        end
    end
    return title .. "  " .. status
end

local function RenderLibrary(stack, result)
    local data = LibraryData()
    local librarian = Librarian()
    local librarianName = librarian and ns.Name(librarian.name) or "?"

    stack:Progress(result.total > 0 and result.donated / result.total or 0,
        result.donated >= result.total and "green" or "gold")
    stack:Spacer(4)

    -- 交书地点
    stack:Heading(L["Where to turn in"])
    if librarian then
        SpotRow(stack, ("%s  %s"):format(librarianName, ns.Theme:Color(SpotPlace(librarian), "muted")),
            librarian, librarianName, 0)
    end
    if data.charm then
        stack:Text(ns.Theme:Color(L["Each donation pays a %s (Mages only). Each title counts once."]:format(
            ns.ItemLink(data.charm)), "muted"), "Small", 0, 4)
    end

    -- 阶段奖励
    stack:Heading(L["Rewards"])
    for _, milestone in ipairs(data.milestones or {}) do
        local claimed = QuestDone(milestone.quest)
        local ready = not claimed and result.donated >= milestone.books
            and ns.PlayerLevel() >= (milestone.minLevel or 1)
        stack:BeginBox(claimed and "green" or (ready and "gold" or "lineSoft"), "panel")
        stack:Text(MilestoneLine(milestone, result), "Body", 0, 4)
        local choices = {}
        for _, itemID in ipairs(milestone.choice or {}) do
            tinsert(choices, ns.ItemLink(itemID))
        end
        if #choices > 0 then
            stack:Text(L["Choose one: %s"]:format(table.concat(choices, " / ")), "Small", 0, 4)
        end
        stack:EndBox(6)
    end

    -- 在包里待交
    local inBags, missing, donated = {}, {}, {}
    for _, entry in ipairs(result.books) do
        local list = (entry.state == "bags" and inBags) or (entry.state == "missing" and missing) or donated
        tinsert(list, entry)
    end
    if #inBags > 0 then
        stack:Heading(L["In your bags"] .. "  " .. ns.Theme:Color(("%d"):format(#inBags), "muted"))
        stack:BeginBox("blue")
        for _, entry in ipairs(inBags) do
            stack:Text(BookName(entry.book) .. "  " .. ns.Theme:Color(L["Bring it to %s."]:format(librarianName), "blue"),
                "Body", 0, 4)
        end
        stack:EndBox(6)
    end

    -- 还没拿到：按区域分组
    if #missing > 0 then
        for _, entry in ipairs(missing) do
            entry.zone = BookZone(entry.book)
        end
        table.sort(missing, function(a, b)
            if a.zone ~= b.zone then
                return a.zone < b.zone
            end
            return a.book.id < b.book.id
        end)
        stack:Heading(L["Still to find"] .. "  " .. ns.Theme:Color(("%d"):format(#missing), "muted"))
        local lastZone
        for _, entry in ipairs(missing) do
            local book = entry.book
            if entry.zone ~= lastZone then
                if lastZone then
                    stack:Divider(2)
                end
                lastZone = entry.zone
                stack:Subheading(entry.zone, 4)
            end
            local name = BookName(book)
            stack:Text(name, "Body", 12, 3)
            local plainName = C_Item.GetItemNameByID and C_Item.GetItemNameByID(book.id) or L["Library books"]
            for _, spot in ipairs(book.spots or {}) do
                SpotRow(stack, ns.Theme:Color(SpotPlace(spot), "muted"), spot, plainName, 24)
            end
            if #(book.spots or {}) > 1 then
                stack:Text(ns.Theme:Color(L["It can be in any of these places; one copy is enough."], "muted"), "Small", 24, 2)
            end
            local directions = book.directions and ns.Name(book.directions)
            if directions then
                stack:Text(directions, "Small", 24, 2)
            end
            stack:Spacer(4)
        end
    end

    -- 已捐
    if #donated > 0 then
        stack:Heading(L["Donated"] .. "  " .. ns.Theme:Color(("%d"):format(#donated), "muted"))
        for _, entry in ipairs(donated) do
            stack:Text("|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t " .. BookName(entry.book), "Small", 0, 2)
        end
    end
end

local function RefreshLibraryPage()
    local result = EvaluateLibrary()
    page.title:SetText(L["Library books"])
    local summary = { L["%d of %d donated"]:format(result.donated, result.total) }
    if result.bags > 0 then
        tinsert(summary, ns.Theme:Color(L["%d in your bags"]:format(result.bags), "blue"))
    end
    page.summary:SetText(table.concat(summary, "  ·  "))
    page.hint:SetText(ns.Theme:Color(L["Donated books and books in your bags are tracked automatically. "
        .. "Track a spot to set a map waypoint."], "muted"))
    local stack = page.stack
    stack:Reset()
    RenderLibrary(stack, result)
    page.detail:SetContentHeight(stack:Finish())
end

local function SelectLibrary()
    CharState().view = LIBRARY
    RefreshPage()
end

local function OnPageSelect(id)
    if id == LIBRARY then
        SelectLibrary()
    else
        SelectChain(id)
        RefreshPage()
    end
end
Module.SelectLibrary = SelectLibrary -- 供测试使用

local function RewardLine(chain)
    if not chain.reward then
        return nil
    end
    return L["Reward: %s"]:format(ns.ItemLink(chain.reward))
end

-- 行首的状态标记（贴图转义）：完成是绿勾，其余是彩色小方块
local function MarkerIcon(state)
    if state == "done" then
        return "|T" .. READY_ICON .. ":14:14|t"
    end
    local color = ns.Theme.colors[(state == "next" and "gold") or (state == "active" and "blue") or "muted"]
    local size = state == "todo" and 6 or 8
    return ("|T%s:%d:%d:4:0:8:8:0:8:0:8:%d:%d:%d|t"):format(ns.Theme.WHITE, size, size,
        math.floor(color[1] * 255 + 0.5), math.floor(color[2] * 255 + 0.5), math.floor(color[3] * 255 + 0.5))
end

-- 需要玩家自己勾选的步骤：行右侧的勾选按钮
local function ManualButtons(chain, row)
    local step = row.step
    if not step.manual then
        return nil
    end
    return { { label = ManualDone(chain, step) and L["Mark as not done"] or L["Mark as done"],
        variant = row.done and "default" or "primary",
        onClick = function() ToggleManual(chain, step) end } }
end

-- “现在做什么”里的一张步骤卡片
local function RenderCurrentStep(stack, chain, result, row)
    local accent = (row.state == "active" or row.state == "ready") and "blue" or "gold"
    stack:BeginBox(accent)
    stack:Row(StepTitle(row) .. "   " .. StateLabel(result, row), ManualButtons(chain, row), "Heading")
    local hint = StepHint(row)
    if hint then
        stack:Text(hint, "Body", 0, 6)
    end
    for _, line in ipairs(MissingNeeds(row)) do
        stack:Text(ns.Theme:Color(line, "red"), "Body", 0, 4)
    end
    local objectives = ObjectiveLines(row)
    if #objectives > 0 then
        stack:Text(table.concat(objectives, "\n"), "Small", 0, 6)
    end
    local spots = Spots(row.step)
    if #spots > 0 then
        stack:Spacer(2)
        for _, spot in ipairs(spots) do
            local name = L[spot[4]]
            stack:Row(("|TInterface\\Minimap\\Tracking\\None:14:14|t %s  %s"):format(name,
                ns.Theme:Color(("%s %.1f, %.1f"):format(ns.MapName(spot[1]) or "?", spot[2], spot[3]), "muted")),
                { { label = L["Track"], variant = "primary", onClick = function()
                    ns.Waypoints:Set(spot[1], spot[2], spot[3], name)
                end }, { label = L["Map"], variant = "ghost", onClick = function()
                    ns.Waypoints:ShowOnMap(spot[1], spot[2], spot[3], name)
                end } }, "Small")
        end
    end
    stack:EndBox(8)
end

function RefreshPage()
    if not (page and page:IsVisible()) then
        return
    end
    local current = CurrentChain()
    local items = {}
    for _, chain in ipairs(ns.SecretChains) do
        local result = Evaluate(chain)
        local tone = result.complete and "green" or (result.done > 0 and "gold" or "muted")
        tinsert(items, { id = chain.id, text = L[chain.title],
            tags = ns.Theme:Color(("%d/%d"):format(result.done, result.total), tone) })
    end
    local library = LibraryData() and EvaluateLibrary()
    if library then
        local tone = library.donated >= library.total and "green" or (library.donated > 0 and "gold" or "muted")
        tinsert(items, { id = LIBRARY, text = L["Library books"],
            tags = ns.Theme:Color(("%d/%d"):format(library.donated, library.total), tone) })
    end
    local showLibrary = library and CharState().view == LIBRARY
    page.list:SetData(items, showLibrary and LIBRARY or current.id)
    page.windowButton:SetLabel((frame and frame:IsShown()) and L["Hide the small window"] or L["Show the small window"])
    page.windowButton:SetWidth(math.max(120, page.windowButton.label:GetStringWidth() + 24))
    if showLibrary then
        RefreshLibraryPage()
        return
    end
    page.hint:SetText(ns.Theme:Color(L["Steps the game can see are checked off automatically. Mark the rest yourself; "
        .. "the small window and this page share the same progress."], "muted"))

    local result = Evaluate(current)
    Announce(result)
    page.title:SetText(L[current.title])
    local summary = { L["%d of %d steps"]:format(result.done, result.total) }
    if current.minLevel then
        local level = L["From level %d"]:format(current.minLevel)
        tinsert(summary, ns.PlayerLevel() < current.minLevel and ns.Theme:Color(level, "red") or level)
    end
    tinsert(summary, RewardLine(current))
    page.summary:SetText(table.concat(summary, "  ·  "))

    local stack = page.stack
    stack:Reset()
    stack:Progress(result.total > 0 and result.done / result.total or 0, result.complete and "green" or "gold")
    stack:Spacer(4)

    -- 上半部分：现在要做的步骤，每步一张卡片，带完整提示、缺的东西、任务目标与地点
    if result.complete then
        if current.ending then
            stack:BeginBox("green", "panel")
            stack:Text(ns.Theme:Color(L[current.ending], "green"), "Body", 0, 4)
            stack:EndBox(14)
        end
    else
        stack:Heading(L["What to do now"])
        for _, row in ipairs(result.rows) do
            local active = row.state == "active" or row.state == "ready"
            if not row.done and (active or result.next[row.step.id]) then
                RenderCurrentStep(stack, current, result, row)
            end
        end
        stack:Spacer(6)
    end

    -- 下半部分：全部步骤，每步一行；还没轮到的步骤附一行灰色提示
    stack:Heading(L["All steps"])
    for index, group in ipairs(current.groups) do
        if #current.groups > 1 then
            if index > 1 then
                stack:Divider(4)
            end
            stack:Subheading(L[group.title] .. (group.parallel and ("  " .. ns.Theme:Color(L["any order"], "muted")) or ""))
        end
        for _, row in ipairs(result.rows) do
            if row.step.group == group.id then
                local state = MarkerState(result, row)
                local title = StepTitle(row)
                if state == "done" then
                    title = ns.Theme:Color(title, "muted")
                elseif state == "todo" then
                    title = ns.Theme:Color(title, "textDim")
                end
                stack:Row(MarkerIcon(state) .. "  " .. title .. "   " .. StateLabel(result, row),
                    ManualButtons(current, row), "Body", 4)
                if state == "todo" then
                    local hint = StepHint(row)
                    if hint then
                        stack:Text(ns.Theme:Color(hint, "muted"), "Small", 24, 6)
                    end
                end
            end
        end
    end
    page.detail:SetContentHeight(stack:Finish())
end
Module.RefreshPage = function() RefreshPage() end -- 供测试使用

local function CreatePage(parent)
    UI = ns.UI
    local p = CreateFrame("Frame", nil, parent)
    page = p
    Module.page = p -- 供测试使用
    local MARGIN = 20

    local listPanel = UI:Panel(p, "panel", "lineSoft")
    listPanel:SetPoint("TOPLEFT", MARGIN, -18)
    listPanel:SetPoint("BOTTOMLEFT", MARGIN, 20)
    listPanel:SetWidth(180)
    p.list = UI:List(listPanel, 24, OnPageSelect)
    p.list:SetPoint("TOPLEFT", 4, -4)
    p.list:SetPoint("BOTTOMRIGHT", -4, 4)

    p.title = UI:Text(p, "Title")
    p.title:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 16, 0)
    p.summary = UI:Text(p, "Muted")
    p.summary:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -5)
    p.summary:SetPoint("RIGHT", -260, 0)
    p.summary:SetWordWrap(false)

    p.link = UI:Button(p, L["Full walkthrough"], 110, 22)
    p.link:SetPoint("TOPRIGHT", -MARGIN, -18)
    p.link:SetScript("OnClick", function()
        if CharState().view == LIBRARY then
            ns.Links:ShowCopyDialog(ns.Links:Build("library"))
        else
            ns.Links:ShowCopyDialog(ns.Links:Build("secret", CurrentChain().site))
        end
    end)
    p.windowButton = UI:Button(p, "", 120, 22, "primary")
    p.windowButton:SetPoint("RIGHT", p.link, "LEFT", -6, 0)
    p.windowButton:SetScript("OnClick", function()
        ns.SetSetting(Module, { key = "shown" }, not (frame and frame:IsShown()))
        RefreshPage()
    end)

    local panel = UI:Panel(p, "panel", "lineSoft")
    panel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 16, -48)
    panel:SetPoint("BOTTOMRIGHT", -MARGIN, 38)
    p.detail = UI:ScrollArea(panel)
    p.detail:SetPoint("TOPLEFT", 12, -10)
    p.detail:SetPoint("BOTTOMRIGHT", -18, 10)
    p.stack = UI:Stack(p.detail.child)
    p.hint = UI:Text(p, "Small")
    p.hint:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 2, -6) -- 往下排：英文两行时也不压到面板边框
    p.hint:SetPoint("RIGHT", -MARGIN, 0)

    p:SetScript("OnShow", function()
        UpdateEvents()
        RefreshPage()
    end)
    p:SetScript("OnHide", function()
        UpdateEvents()
    end)
    return p
end


-- 按设置显示或隐藏
function Module:Refresh()
    if not self.enabled then
        return
    end
    if Settings().shown then
        frame = frame or Create()
        AddItemListener()
        RestorePosition()
        frame:Show()
        Refresh()
    elseif frame then
        frame:Hide()
    end
end

function Module:OnEnable()
    ns:AddCommand("secrets", L["show or hide the secrets helper"], Toggle)
    if not ns.MainFrame:HasTab("secrets") then
        ns.MainFrame:RegisterTab({ id = "secrets", titleKey = "Secrets", order = 12, create = function(parent)
            AddItemListener()
            return CreatePage(parent)
        end, onShow = function() RefreshPage() end })
    end
    self:Refresh()
end

function Module:OnDisable()
    if frame then
        frame:Hide()
    end
    SetEvents(false)
end
