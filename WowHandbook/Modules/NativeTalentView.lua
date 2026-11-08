local ADDON_NAME, ns = ...
local L = ns.L

-- 暴雪天赋窗口里的“天赋方案”页：原生天赋窗口的样子（同一张职业背景、内框、树标题、方形天赋节点与箭头连线，
-- 下拉框、带步进按钮的滑条、按钮都用暴雪模板），内容是插件的天赋模拟器：
-- 选网站推荐方案后拖动等级查看每一级的点法，这一级点的天赋带暴雪的“可学”加号；左键加点、右键减点。
-- 状态与规则都在 Modules/Talents.lua（与 /wh 天赋页共用同一份加点与方案），这里只负责画。
-- 只看本职业。全部是插件自己的框架，盖在暴雪天赋画布上面，暴雪的天赋按钮与应用天赋不受影响。
-- 由 Modules/NativeTabs.lua 创建与切换。
local NativeTalentView = {}
ns.NativeTalentView = NativeTalentView

local COLUMN_WIDTH = 404       -- 暴雪天赋画布 1212 宽，三棵树各占三分之一
-- 位置对齐暴雪天赋页（按游戏截图量出，2026-11-08）：暴雪的树标题在画布上沿下约 100、第一行天赋中心约 175，
-- 节点间距约 60；本页从同一个画布上沿开始，所以用同样的数，切换标签时天赋位置不跳
local NODE, PITCH = 40, 60     -- 节点大小、节点间距（行与列相同）
local GRID_TOP = 175           -- 第一行节点中心距视图顶部
local HEADER_TOP = 100         -- 树标题中心距视图顶部
local DIVIDER_TOP, DIVIDER_HEIGHT = 135, 420 -- 树之间竖分隔线：从标题下方到最后一行，不碰底部的文字
local NODE_ART = {
    maxed = "talents-node-square-yellow",
    open = "talents-node-square-green",
    locked = "talents-node-square-gray",
}

local atan2 = math.atan2 or math.atan -- 游戏是 Lua 5.1（math.atan2）；本地测试的 5.4 用 math.atan(y, x)

local function Talents()
    return ns.modules.Talents
end

-- 节点中心相对视图顶部中点的位置（x 向右，y 向下）
local function NodeCenter(t, talent)
    return (t - 2) * COLUMN_WIDTH + (talent.col - 2.5) * PITCH, GRID_TOP + (talent.row - 1) * PITCH
end

--------------------------------------------------------------------------------
-- 节点与连线
--------------------------------------------------------------------------------

local function OnNodeClick(button, mouseButton)
    local module = Talents()
    if module.Spend(button.treeIndex, button.talentIndex, mouseButton == "RightButton" and -1 or 1) then
        button.view:Refresh()
        module.Refresh()
        if button:IsMouseOver() then
            module.ShowTooltip(button)
        end
    end
end

local function CreateNode(view)
    local button = CreateFrame("Button", nil, view.grid)
    button:SetSize(NODE, NODE)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.view = view
    button.shadow = button:CreateTexture(nil, "BACKGROUND")
    button.shadow:SetAtlas("talents-node-square-shadow")
    button.shadow:SetSize(78, 78)
    button.shadow:SetPoint("CENTER")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(34, 34)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.ring = button:CreateTexture(nil, "OVERLAY")
    button.ring:SetSize(NODE, NODE)
    button.ring:SetPoint("CENTER")
    button.plus = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.plus:SetAtlas("talents-icon-learnableplus")
    button.plus:SetSize(19, 18)
    button.plus:SetPoint("BOTTOMLEFT", -3, -3)
    button.rank = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.rank:SetPoint("BOTTOMRIGHT", 6, -4)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAtlas("talents-node-square-yellow")
    highlight:SetAllPoints(button.ring)
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.35)
    button:SetScript("OnClick", OnNodeClick)
    button:SetScript("OnEnter", function(self)
        Talents().ShowTooltip(self)
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

local function Edge(view, index)
    local edge = view.edges[index]
    if not edge then
        edge = {}
        edge.line = view.grid:CreateLine(nil, "ARTWORK")
        edge.line:SetThickness(6)
        edge.arrow = view.grid:CreateTexture(nil, "ARTWORK", nil, 2)
        edge.arrow:SetSize(12, 12)
        view.edges[index] = edge
    end
    return edge
end

-- 前置连线：从前置天赋指向这个天赋，前置点满后变成金色
local function DrawEdges(view, t, tree, ranks, used)
    local Rules = Talents().Rules
    for index, talent in ipairs(tree.talents) do
        local req = talent.req and tree.talents[talent.req]
        if req then
            used = used + 1
            local edge = Edge(view, used)
            local fromX, fromY = NodeCenter(t, req)
            local toX, toY = NodeCenter(t, talent)
            -- 屏幕坐标 y 向上
            local angle = atan2(toY - fromY, fromX - toX)
            local dx, dy = math.cos(angle) * NODE / 2, math.sin(angle) * NODE / 2
            edge.line:SetStartPoint("TOP", view.grid, fromX - dx, -fromY - dy)
            edge.line:SetEndPoint("TOP", view.grid, toX + dx, -toY + dy)
            edge.arrow:ClearAllPoints()
            edge.arrow:SetPoint("CENTER", view.grid, "TOP", toX + dx, -toY + dy)
            edge.arrow:SetRotation(angle - math.pi / 2)
            local met = Rules.PrereqMet(tree, ranks, index)
            edge.line:SetAtlas(met and "talents-arrow-line-yellow" or "talents-arrow-line-gray", true)
            edge.arrow:SetAtlas(met and "talents-arrow-head-yellow" or "talents-arrow-head-gray")
            edge.line:Show()
            edge.arrow:Show()
        end
    end
    return used
end

--------------------------------------------------------------------------------
-- 刷新
--------------------------------------------------------------------------------

local function RefreshControls(view)
    local module = Talents()
    local state = module.State
    local plan = state.plan
    view.planDropdown:GenerateMenu()
    view.slider:SetShown(plan ~= nil)
    if plan then
        view.slider:Init(state.level, plan.first, plan.last, plan.last - plan.first, view.formatters)
        local picked = {}
        for t, tree in ipairs(module.Trees()) do
            for i in pairs(state.picks[t] or {}) do
                tinsert(picked, ("%s %d/%d"):format(ns.Name(tree.talents[i].name) or "?", state.build[t][i],
                    tree.talents[i].max))
            end
        end
        if state.respec then
            local text = L["Respec at this level: reset every point and spend %d on the new plan."]
            view.pick:SetText(RED_FONT_COLOR:WrapTextInColorCode(text:format(module.Rules.Total(state.build))))
        elseif #picked > 0 then
            view.pick:SetText((L["This level: %s"]):format(GREEN_FONT_COLOR:WrapTextInColorCode(table.concat(picked, ", "))))
        else
            view.pick:SetText("")
        end
    else
        view.pick:SetText(L["Pick a leveling plan from wowhandbook.com, then drag the level bar to see what to spend at each level."])
    end
    local total = module.Rules.Total(state.build)
    view.summary:SetText((L["Points: %s"]):format(("%d/%d"):format(total, 51)))
    view.reset:SetEnabled(total > 0)
end

function NativeTalentView.Refresh(view)
    local module = Talents()
    if not (module and view:IsVisible()) then
        return
    end
    local state = module.State
    -- 只看本职业：在 /wh 里切到别的职业后回到这里时换回来
    local class = ns.PlayerClass()
    if state.class ~= class then
        module.SelectClass(class)
    end
    local trees = module.Trees()
    local Rules = module.Rules
    local total = Rules.Total(state.build)
    local pointsLeft = 51 - total
    local used, edges = 0, 0

    -- 背景：照搬暴雪天赋窗口当前用的职业背景
    local source = view.inner.ClassBackground
    local atlas = type(source) == "table" and source.GetAtlas and source:GetAtlas()
    if atlas then
        view.background:SetAtlas(atlas)
    else
        view.background:SetAtlas("Talents-Background-c60")
    end

    for t, tree in ipairs(trees) do
        local header = view.headers[t]
        header.Icon:SetTexture(tree.icon and ("Interface\\Icons\\" .. tree.icon) or nil)
        header.Name:SetText(ns.Name(tree.name) or "")
        header.Text:SetText(Rules.TreeTotal(state.build[t]))
        header:Show()
        local ranks = state.build[t]
        local picks = state.plan and state.picks[t] or {}
        for index, talent in ipairs(tree.talents) do
            used = used + 1
            local button = view.nodes[used] or CreateNode(view)
            view.nodes[used] = button
            button.treeIndex, button.talentIndex = t, index
            local x, y = NodeCenter(t, talent)
            button:ClearAllPoints()
            button:SetPoint("CENTER", view.grid, "TOP", x, -y)
            button.icon:SetTexture(talent.icon and ("Interface\\Icons\\" .. talent.icon) or 134400)
            local rank = ranks[index]
            local open = Rules.IsAvailable(tree, ranks, index) and (rank > 0 or pointsLeft > 0)
            local art = rank >= talent.max and NODE_ART.maxed or ((rank > 0 or open) and NODE_ART.open or NODE_ART.locked)
            button.ring:SetAtlas(art)
            button.icon:SetDesaturated(rank == 0 and not open)
            button.rank:SetText(rank > 0 and ("%d/%d"):format(rank, talent.max) or "")
            button.rank:SetTextColor((rank >= talent.max and NORMAL_FONT_COLOR or GREEN_FONT_COLOR):GetRGB())
            button.plus:SetShown(picks[index] and not state.respec or false)
            button:Show()
        end
        edges = DrawEdges(view, t, tree, ranks, edges)
    end
    for index = used + 1, #view.nodes do
        view.nodes[index]:Hide()
    end
    for index = edges + 1, #view.edges do
        view.edges[index].line:Hide()
        view.edges[index].arrow:Hide()
    end
    for t = #trees + 1, #view.headers do
        view.headers[t]:Hide()
    end
    RefreshControls(view)
end

--------------------------------------------------------------------------------
-- 创建
--------------------------------------------------------------------------------

local function CreateHeader(view, t)
    local header = CreateFrame("Frame", nil, view.grid, "ClassTalentTreeHeaderTemplate")
    header:SetFrameLevel(view.grid:GetFrameLevel() + 5) -- 模板自带固定层级，压到网格之上
    header:SetPoint("CENTER", view.grid, "TOP", (t - 2) * COLUMN_WIDTH - 60, -HEADER_TOP)
    return header
end

local function CreateControls(view)
    local module = Talents()
    -- 方案下拉框：我的加点 + 本职业的推荐方案
    local dropdown = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(220)
    dropdown:SetPoint("BOTTOMLEFT", 30, 14)
    dropdown:SetupMenu(function(_, root)
        local state = module.State
        local function IsSelected(id)
            return (state.plan and state.plan.id or "") == id
        end
        local function SetSelected(id)
            module.UsePlan(module.FindPlan(id))
            view:Refresh()
            module.Refresh()
        end
        root:CreateRadio(L["My build"], IsSelected, SetSelected, "")
        for _, plan in ipairs((module.ClassPlans())) do
            root:CreateRadio(ns.Name(plan.name) or plan.id, IsSelected, SetSelected, plan.id)
        end
    end)
    view.planDropdown = dropdown

    -- 等级滑条：拖动或点两侧步进按钮
    local slider = CreateFrame("Frame", nil, view, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(240)
    slider:SetPoint("LEFT", dropdown, "RIGHT", 24, 0)
    view.formatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
            return (L["Level %d"]):format(math.floor(value + 0.5))
        end,
    }
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        local level = math.floor(value + 0.5)
        if module.State.plan and level ~= module.State.level then
            module.SetLevel(level)
            view:Refresh()
            module.Refresh()
        end
    end, view)
    view.slider = slider

    view.reset = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
    view.reset:SetSize(100, 22)
    view.reset:SetPoint("BOTTOMRIGHT", -30, 16)
    view.reset:SetText(L["Reset"])
    view.reset:SetScript("OnClick", function()
        module.Reset()
        view:Refresh()
        module.Refresh()
    end)
    view.link = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
    view.link:SetSize(150, 22)
    view.link:SetPoint("RIGHT", view.reset, "LEFT", -8, 0)
    view.link:SetText(L["Copy build link"])
    view.link:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("talents", module.State.class, module.Code()))
    end)
    view.link:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["Copy build link"], 1, 1, 1)
        GameTooltip:AddLine(L["Open this build in the talent calculator on wowhandbook.com to share it or keep editing."],
            NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        GameTooltip:Show()
    end)
    view.link:SetScript("OnLeave", GameTooltip_Hide)

    view.pick = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.pick:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 2, 10)
    view.pick:SetPoint("RIGHT", -30, 0)
    view.pick:SetJustifyH("LEFT")
    view.summary = view:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.summary:SetPoint("BOTTOMRIGHT", view.reset, "TOPRIGHT", 0, 10)
end

-- inner：暴雪天赋框架（PlayerSpellsFrame.TalentsFrame）；视图的位置由调用方锚定
function NativeTalentView.Create(inner)
    local view = CreateFrame("Frame", nil, inner)
    view.inner = inner
    view:EnableMouse(true)
    view:EnableMouseWheel(true)
    view:SetScript("OnMouseWheel", function() end) -- 不让滚轮穿到下面的天赋画布
    view:Hide()

    -- 底：纯黑垫底，再铺暴雪当前的职业背景与内框
    local base = view:CreateTexture(nil, "BACKGROUND", nil, -8)
    base:SetAllPoints()
    base:SetColorTexture(0, 0, 0, 1)
    view.background = view:CreateTexture(nil, "BACKGROUND", nil, -7)
    view.background:SetAllPoints()
    local border = view:CreateTexture(nil, "BORDER")
    border:SetAtlas("Talents-inner-frame-c60")
    border:SetAllPoints()

    view.grid = CreateFrame("Frame", nil, view)
    view.grid:SetAllPoints()
    view.nodes, view.edges, view.headers = {}, {}, {}
    for t = 1, 3 do
        view.headers[t] = CreateHeader(view, t)
        if t > 1 then
            local divider = view.grid:CreateTexture(nil, "BORDER")
            divider:SetAtlas("Talents-divider-vertical-c60")
            divider:SetSize(2, DIVIDER_HEIGHT)
            divider:SetPoint("TOP", view.grid, "TOP", (t - 2.5) * COLUMN_WIDTH, -DIVIDER_TOP)
        end
    end
    CreateControls(view)
    view.Refresh = NativeTalentView.Refresh
    view:SetScript("OnShow", function(self)
        self:Refresh()
    end)
    return view
end
