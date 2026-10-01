local ADDON_NAME, ns = ...
local L = ns.L

-- 天赋模拟器：九个职业的三棵天赋树，左键加点、右键减点，规则与游戏一致
-- （10 级起每级 1 点、共 51 点；一棵树里每投 5 点开放下一层；前置天赋要点满）。
-- 只是模拟，不会改动角色的真实天赋。每个职业的加点记在账号存档里；
-- 加点可生成网站天赋模拟器的链接（分享码格式与网站一致）。
-- 数据 Data/Talents.lua 由网站的天赋数据生成（取自客户端天赋表）。
local Module = ns:NewModule("Talents", { builds = {} })
local UI

local TOTAL_POINTS = 51
local POINTS_PER_ROW = 5
local FIRST_TALENT_LEVEL = 10

local page

local function Color(text, name)
    return ns.Theme:Color(text, name)
end

--------------------------------------------------------------------------------
-- 规则：build[树序号][天赋序号] = 已投点数
--------------------------------------------------------------------------------

local Rules = {}
Module.Rules = Rules -- 供测试使用

function Rules.Empty(trees)
    local build = {}
    for t, tree in ipairs(trees) do
        build[t] = {}
        for i in ipairs(tree.talents) do
            build[t][i] = 0
        end
    end
    return build
end

function Rules.TreeTotal(ranks)
    local total = 0
    for _, rank in ipairs(ranks) do
        total = total + rank
    end
    return total
end

function Rules.Total(build)
    local total = 0
    for _, ranks in ipairs(build) do
        total = total + Rules.TreeTotal(ranks)
    end
    return total
end

-- 投了这么多点至少要几级（第一点在 10 级）
function Rules.RequiredLevel(total)
    return total > 0 and FIRST_TALENT_LEVEL - 1 + total or 0
end

-- 某一级角色有多少天赋点
function Rules.PointsAtLevel(level)
    return math.min(TOTAL_POINTS, math.max(0, level - FIRST_TALENT_LEVEL + 1))
end

-- 开放第 row 层需要在这棵树里先投多少点
function Rules.RowRequirement(row)
    return (row - 1) * POINTS_PER_ROW
end

-- 第 row 层以上各层已投的点数
function Rules.PointsBelow(tree, ranks, row)
    local total = 0
    for i, talent in ipairs(tree.talents) do
        if talent.row < row then
            total = total + ranks[i]
        end
    end
    return total
end

function Rules.RowOpen(tree, ranks, row)
    return Rules.PointsBelow(tree, ranks, row) >= Rules.RowRequirement(row)
end

function Rules.PrereqMet(tree, ranks, index)
    local req = tree.talents[index].req
    return req == nil or ranks[req] >= tree.talents[req].max
end

-- 这个天赋现在能不能投点：所在层已开放，前置天赋已点满
function Rules.IsAvailable(tree, ranks, index)
    return Rules.RowOpen(tree, ranks, tree.talents[index].row) and Rules.PrereqMet(tree, ranks, index)
end

function Rules.IsValidTree(tree, ranks)
    for i, talent in ipairs(tree.talents) do
        if ranks[i] ~= 0 and (ranks[i] > talent.max or not Rules.IsAvailable(tree, ranks, i)) then
            return false
        end
    end
    return true
end

function Rules.CanAdd(trees, build, t, index)
    return Rules.Total(build) < TOTAL_POINTS and build[t][index] < trees[t].talents[index].max
        and Rules.IsAvailable(trees[t], build[t], index)
end

-- 减掉这一点后整棵树仍然合法才能减（下面的层、依赖它的天赋不能悬空）
function Rules.CanRemove(trees, build, t, index)
    if build[t][index] == 0 then
        return false
    end
    build[t][index] = build[t][index] - 1
    local valid = Rules.IsValidTree(trees[t], build[t])
    build[t][index] = build[t][index] + 1
    return valid
end

-- 分享码（与网站天赋模拟器一致）：每个天赋一位数字，去掉每棵树末尾的 0，三棵树用 "-" 连接
function Rules.Encode(build)
    local parts = {}
    for t, ranks in ipairs(build) do
        parts[t] = table.concat(ranks):gsub("0+$", "")
    end
    return (table.concat(parts, "-"):gsub("%-+$", ""))
end

-- 解析分享码；不是合法加点时返回空加点
function Rules.Decode(trees, code)
    local build = Rules.Empty(trees)
    if type(code) ~= "string" or code:find("[^%d%-]") then
        return build
    end
    local t = 0
    for part in (code .. "-"):gmatch("(%d*)%-") do
        t = t + 1
        if not trees[t] or #part > #trees[t].talents then
            return Rules.Empty(trees)
        end
        for i = 1, #part do
            build[t][i] = tonumber(part:sub(i, i))
        end
    end
    for index, tree in ipairs(trees) do
        if not Rules.IsValidTree(tree, build[index]) then
            return Rules.Empty(trees)
        end
    end
    if Rules.Total(build) > TOTAL_POINTS then
        return Rules.Empty(trees)
    end
    return build
end

--------------------------------------------------------------------------------
-- 当前职业与加点
--------------------------------------------------------------------------------

local state = { class = nil, build = nil }

local function Classes()
    return ns.Data.talents or {}
end

local function Trees()
    local data = Classes()[state.class]
    return data and data.trees or {}
end

-- 选中职业：存档里上次看的，否则当前角色的职业，再否则第一个有数据的职业
local function SelectClass(class)
    local settings = ns:GetModuleSettings(Module)
    local classes = Classes()
    if not classes[class or ""] then
        class = classes[settings.class or ""] and settings.class or ns.PlayerClass()
    end
    if not classes[class or ""] then
        class = nil
        for _, candidate in ipairs(ns.Theme.CLASS_ORDER) do
            if classes[candidate] then
                class = candidate
                break
            end
        end
    end
    state.class = class
    settings.class = class
    state.build = Rules.Decode(Trees(), class and settings.builds[class] or "")
end

local function SaveBuild()
    local code = Rules.Encode(state.build)
    ns:GetModuleSettings(Module).builds[state.class] = code ~= "" and code or nil
end

local function Code()
    return Rules.Encode(state.build)
end

-- 加点或减点；成功返回 true
local function Spend(t, index, delta)
    local trees = Trees()
    if delta > 0 and Rules.CanAdd(trees, state.build, t, index)
        or delta < 0 and Rules.CanRemove(trees, state.build, t, index) then
        state.build[t][index] = state.build[t][index] + delta
        SaveBuild()
        return true
    end
    return false
end

local function Reset(t)
    for index, ranks in ipairs(state.build) do
        if not t or t == index then
            for i in ipairs(ranks) do
                ranks[i] = 0
            end
        end
    end
    SaveBuild()
end

-- 供测试与斜杠命令使用
Module.SelectClass = SelectClass
Module.Spend = Spend
Module.Reset = Reset
Module.Code = Code
Module.State = state

--------------------------------------------------------------------------------
-- 页面：顶部标题、点数、职业选择与按钮；下面并排三棵树
--------------------------------------------------------------------------------

local PAD = 20
local TREE_WIDTH, TREE_GAP = 234, 10
local TREE_HEADER = 34
local ICON, COL_PITCH, ROW_PITCH = 40, 54, 61
local LINE = 2

local Refresh

-- 天赋图标左上角在树面板里的位置
local function CellPosition(talent)
    local margin = (TREE_WIDTH - COL_PITCH * 4) / 2
    local x = margin + (talent.col - 1) * COL_PITCH + (COL_PITCH - ICON) / 2
    local y = TREE_HEADER + 6 + (talent.row - 1) * ROW_PITCH
    return x, y
end

local function ShowTooltip(button)
    local trees = Trees()
    local tree = trees[button.treeIndex]
    local talent = tree and tree.talents[button.talentIndex]
    if not talent then
        return
    end
    local ranks = state.build[button.treeIndex]
    local rank = ranks[button.talentIndex]
    local texts = ns.Name(talent.ranks) or {}
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.Name(talent.name) or "?", 1, 1, 1)
    GameTooltip:AddLine((L["Rank %d/%d"]):format(rank, talent.max), 1, 1, 1)
    if not Rules.RowOpen(tree, ranks, talent.row) then
        GameTooltip:AddLine((L["Requires %d points in %s"]):format(Rules.RowRequirement(talent.row),
            ns.Name(tree.name) or ""), 1, 0.25, 0.25)
    end
    if not Rules.PrereqMet(tree, ranks, button.talentIndex) then
        local req = tree.talents[talent.req]
        GameTooltip:AddLine((L["Requires %d points in %s"]):format(req.max, ns.Name(req.name) or ""), 1, 0.25, 0.25)
    end
    if talent.cost then
        GameTooltip:AddLine(ns.Name(talent.cost), 1, 1, 1, true)
    end
    if rank > 0 and texts[rank] then
        GameTooltip:AddLine(texts[rank], 1, 0.82, 0, true)
    end
    if rank < talent.max and texts[rank + 1] then
        if rank > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Next rank:"], 1, 1, 1)
        end
        GameTooltip:AddLine(texts[rank + 1], 1, 0.82, 0, true)
    end
    GameTooltip:AddLine(L["Left-click: add a point. Right-click: remove a point."], 0.54, 0.51, 0.45, true)
    GameTooltip:Show()
end

local function OnTalentClick(button, mouseButton)
    if Spend(button.treeIndex, button.talentIndex, mouseButton == "RightButton" and -1 or 1) then
        Refresh()
        if button:IsMouseOver() then
            ShowTooltip(button)
        end
    end
end

local function TalentButton(panel, index)
    local button = panel.buttons[index]
    if not button then
        button = UI:IconButton(panel, ICON)
        button:SetScript("OnClick", OnTalentClick)
        button:SetScript("OnEnter", ShowTooltip)
        button:SetScript("OnLeave", GameTooltip_Hide)
        panel.buttons[index] = button
    end
    return button
end

local function Line(panel, index)
    local line = panel.lines[index]
    if not line then
        line = panel:CreateTexture(nil, "ARTWORK")
        panel.lines[index] = line
    end
    line:ClearAllPoints()
    line:Show()
    return line
end

-- 前置连线：同列画竖线，同层画横线，其余先横后竖；前置点满后线变成强调色
local function DrawLinks(panel, tree, ranks)
    local used = 0
    local function Segment(x, y, width, height, met)
        used = used + 1
        local line = Line(panel, used)
        line:SetPoint("TOPLEFT", x, -y)
        line:SetSize(math.max(LINE, width), math.max(LINE, height))
        line:SetColorTexture(unpack(ns.Theme.colors[met and "gold" or "line"]))
    end
    for index, talent in ipairs(tree.talents) do
        local req = talent.req and tree.talents[talent.req]
        if req then
            local met = Rules.PrereqMet(tree, ranks, index)
            local fromX, fromY = CellPosition(req)
            local toX, toY = CellPosition(talent)
            local half = (ICON - LINE) / 2
            if req.col == talent.col then
                Segment(fromX + half, fromY + ICON, LINE, toY - fromY - ICON, met)
            elseif req.row == talent.row then
                local left = math.min(fromX, toX) + ICON
                Segment(left, fromY + half, math.abs(toX - fromX) - ICON, LINE, met)
            else
                local left = toX > fromX and fromX + ICON or toX + half
                local right = toX > fromX and toX + half + LINE or fromX
                Segment(left, fromY + half, right - left, LINE, met)
                Segment(toX + half, fromY + half, LINE, toY - fromY - half, met)
            end
        end
    end
    for index = used + 1, #panel.lines do
        panel.lines[index]:Hide()
    end
end

local function RenderTree(panel, t, tree, ranks, pointsLeft)
    local spent = Rules.TreeTotal(ranks)
    panel.icon:SetTexture(tree.icon and ("Interface\\Icons\\" .. tree.icon) or nil)
    panel.title:SetText(ns.Name(tree.name) or "")
    panel.points:SetText(Color(tostring(spent), spent > 0 and "gold" or "muted"))
    panel.reset:SetEnabled(spent > 0)
    for index, talent in ipairs(tree.talents) do
        local button = TalentButton(panel, index)
        local rank = ranks[index]
        local available = Rules.IsAvailable(tree, ranks, index)
        button.treeIndex, button.talentIndex = t, index
        local x, y = CellPosition(talent)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", x, -y)
        button:SetIcon(talent.icon and ("Interface\\Icons\\" .. talent.icon) or 134400)
        local open = rank > 0 or (available and pointsLeft > 0)
        button:SetDimmed(not open)
        if rank >= talent.max then
            button:SetBorder("gold")
            button:SetCount(("%d/%d"):format(rank, talent.max), "gold")
        elseif rank > 0 then
            button:SetBorder("goldDim")
            button:SetCount(("%d/%d"):format(rank, talent.max), "green")
        else
            button:SetBorder(open and "line" or "lineSoft")
            button:SetCount(("%d/%d"):format(rank, talent.max), open and "textDim" or "muted")
        end
        button:Show()
    end
    for index = #tree.talents + 1, #panel.buttons do
        panel.buttons[index]:Hide()
    end
    DrawLinks(panel, tree, ranks)
end

function Refresh()
    if not (page and page:IsVisible()) then
        return
    end
    if not state.class then
        SelectClass()
    end
    local trees = Trees()
    local total = Rules.Total(state.build or {})
    local parts = {
        (L["Points: %s"]):format(Color(("%d/%d"):format(total, TOTAL_POINTS), total > 0 and "gold" or "textDim")),
    }
    if total > 0 then
        tinsert(parts, (L["Requires level %d"]):format(Rules.RequiredLevel(total)))
    end
    local spent = {}
    for t in ipairs(trees) do
        spent[t] = Rules.TreeTotal(state.build[t])
    end
    tinsert(parts, table.concat(spent, " / "))
    if state.class == ns.PlayerClass() then
        tinsert(parts, (L["You have %d points at level %d"]):format(Rules.PointsAtLevel(ns.PlayerLevel()), ns.PlayerLevel()))
    end
    page.summary:SetText(table.concat(parts, "  ·  "))
    page.classDropdown:SetValue(state.class)
    page.resetAll:SetEnabled(total > 0)
    for t, panel in ipairs(page.trees) do
        local tree = trees[t]
        panel:SetShown(tree ~= nil)
        if tree then
            RenderTree(panel, t, tree, state.build[t], TOTAL_POINTS - total)
        end
    end
    page.empty:SetShown(#trees == 0)
end
Module.Refresh = function() Refresh() end -- 供测试使用

local function CreateTreePanel(parent, t)
    local panel = UI:Panel(parent, "panel", "lineSoft")
    panel:SetWidth(TREE_WIDTH)
    panel.buttons, panel.lines = {}, {}
    panel.icon = panel:CreateTexture(nil, "ARTWORK")
    panel.icon:SetSize(20, 20)
    panel.icon:SetPoint("TOPLEFT", 10, -7)
    panel.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    panel.title = UI:Text(panel, "Heading")
    panel.title:SetPoint("LEFT", panel.icon, "RIGHT", 8, 0)
    panel.reset = UI:CloseButton(panel, function()
        Reset(t)
        Refresh()
    end, 20)
    panel.reset:SetPoint("TOPRIGHT", -6, -7)
    panel.reset:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Reset this tree"], 1, 1, 1)
        GameTooltip:Show()
    end)
    panel.reset:HookScript("OnLeave", GameTooltip_Hide)
    panel.points = UI:Text(panel, "Body")
    panel.points:SetPoint("RIGHT", panel.reset, "LEFT", -4, 0)
    local line = ns.Theme:Fill(panel, "lineSoft", "ARTWORK")
    line:SetPoint("TOPLEFT", 1, -TREE_HEADER)
    line:SetPoint("TOPRIGHT", -1, -TREE_HEADER)
    line:SetHeight(1)
    return panel
end

local function CreatePage(parent)
    UI = ns.UI
    local p = CreateFrame("Frame", nil, parent)
    page = p
    Module.page = p -- 供测试使用

    local title = UI:Text(p, "Title", L["Talent simulator"])
    title:SetPoint("TOPLEFT", PAD, -18)
    p.summary = UI:Text(p, "Muted")
    p.summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

    -- 职业选择：名字用客户端的职业名，按职业色显示
    local items = {}
    for _, class in ipairs(ns.Theme.CLASS_ORDER) do
        if Classes()[class] then
            tinsert(items, { id = class, label = ("|cff%s%s|r"):format(ns.Theme:AccentHex(class), ns.ClassName(class)) })
        end
    end
    p.classDropdown = UI:Dropdown(p, items, function(class)
        SelectClass(class)
        Refresh()
    end, 130)
    p.classDropdown:SetPoint("TOPRIGHT", -PAD, -18)

    p.resetAll = UI:Button(p, L["Reset"], 70, 24)
    p.resetAll:SetPoint("RIGHT", p.classDropdown, "LEFT", -6, 0)
    p.resetAll:SetScript("OnClick", function()
        Reset()
        Refresh()
    end)

    -- 网站链接：在网站天赋模拟器里打开这套加点（分享给别人，或在浏览器里继续调整）
    p.link = UI:Button(p, L["Copy build link"], 130, 24, "primary")
    p.link:SetPoint("RIGHT", p.resetAll, "LEFT", -6, 0)
    p.link:SetScript("OnClick", function()
        if state.class then
            ns.Links:ShowCopyDialog(ns.Links:Build("talents", state.class, Code()))
        end
    end)
    p.link:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(L["Copy build link"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Open this build in the talent calculator on wowhandbook.com to share it or keep editing."],
            1, 1, 1, true)
        GameTooltip:Show()
    end)
    p.link:HookScript("OnLeave", GameTooltip_Hide)

    p.trees = {}
    for t = 1, 3 do
        local panel = CreateTreePanel(p, t)
        panel:SetPoint("TOPLEFT", PAD + (t - 1) * (TREE_WIDTH + TREE_GAP), -64)
        panel:SetPoint("BOTTOMLEFT", PAD + (t - 1) * (TREE_WIDTH + TREE_GAP), 14)
        p.trees[t] = panel
    end
    p.empty = UI:Text(p, "Muted", L["No talent data for this class yet."])
    p.empty:SetPoint("TOPLEFT", PAD, -70)
    p.empty:Hide()

    p:SetScript("OnShow", Refresh)
    return p
end

function Module:OnEnable()
    ns.MainFrame:RegisterTab({ id = "talents", title = L["Talents"], order = 22, create = CreatePage, onShow = Refresh })
    ns:AddCommand("talents", L["open the talent simulator"], function()
        ns.MainFrame:Open("talents")
    end)
end
