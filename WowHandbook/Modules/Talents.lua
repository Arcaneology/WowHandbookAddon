local ADDON_NAME, ns = ...
local L = ns.L

-- 天赋加点的规则与状态（界面在游戏天赋窗口里：Modules/NativeTalentView.lua 的方案视图；
-- /wh 主窗口不再有天赋页）：三棵天赋树，左键加点、右键减点，规则与游戏一致
-- （10 级起每级 1 点、共 51 点；一棵树里每投 5 点开放下一层；前置天赋要点满）。
-- 只是模拟，不会改动角色的真实天赋。每个职业的加点记在账号存档里；
-- 加点可生成网站天赋模拟器的链接（分享码格式与网站一致）。
-- 推荐方案：网站的练级方案逐级导出（Data/TalentPlans.lua，每一级一个分享码），选中后拖动等级条
-- 查看每一级的完整点法和这一级点的是哪个天赋，洗天赋的等级在等级条上标出；改动任意一点就变回“我的加点”。
-- 数据 Data/Talents.lua 由网站的天赋数据生成（取自客户端天赋表）。
-- plans[职业] = 选中的方案 ID；"" 表示玩家选了“我的加点”，nil 表示没选过（有默认方案时用默认方案）。
local Module = ns:NewModule("Talents", { builds = {}, plans = {} })

local TOTAL_POINTS = 51
local POINTS_PER_ROW = 5
local FIRST_TALENT_LEVEL = 10

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

-- plan：选中的推荐方案（nil 为“我的加点”）；level：方案正在看的等级；picks[树][天赋] = 这一级加的点
local state = { class = nil, build = nil, plan = nil, level = nil, picks = {}, respec = false }

local function Classes()
    return ns.Data.talents or {}
end

local function Trees()
    local data = Classes()[state.class]
    return data and data.trees or {}
end

local function ClassPlans(class)
    local data = ns.Data.talentPlans and ns.Data.talentPlans[class or state.class]
    return data and data.plans or {}, data and data.default
end

local function FindPlan(id)
    for _, plan in ipairs(ClassPlans()) do
        if plan.id == id then
            return plan
        end
    end
end

local function PlanBuild(plan, level)
    if level < plan.first then
        return Rules.Empty(Trees())
    end
    return Rules.Decode(Trees(), plan.codes[math.min(level, plan.last) - plan.first + 1])
end

local function IsRespec(plan, level)
    for _, respec in ipairs(plan.respecs or {}) do
        if respec == level then
            return true
        end
    end
    return false
end

-- 方案默认看哪一级：看本职业时停在角色当前等级，其他职业看方案的最后一级
local function DefaultLevel(plan)
    if state.class == ns.PlayerClass() then
        return math.max(plan.first, math.min(plan.last, ns.PlayerLevel()))
    end
    return plan.last
end

-- 跳到方案的某一级：加点换成这一级的点法，并记下这一级比上一级多出的点
local function SetLevel(level)
    local plan = state.plan
    if not plan then
        return
    end
    level = math.max(plan.first, math.min(plan.last, level))
    state.level = level
    state.build = PlanBuild(plan, level)
    state.respec = IsRespec(plan, level)
    state.picks = {}
    local before = PlanBuild(plan, level - 1)
    for t, ranks in ipairs(state.build) do
        state.picks[t] = {}
        for i, rank in ipairs(ranks) do
            if rank > before[t][i] then
                state.picks[t][i] = true
            end
        end
    end
end

-- 选方案：plan 为 nil 时回到玩家自己存下的加点
local function UsePlan(plan)
    state.plan = plan
    state.picks, state.respec = {}, false
    ns:GetModuleSettings(Module).plans[state.class] = plan and plan.id or ""
    -- 游戏天赋窗口上的方案等级跟着换（本职业的方案才会画）
    local native = ns.modules.NativeTabs
    if native and native.enabled and native.RefreshBadges then
        native.RefreshBadges()
    end
    if plan then
        SetLevel(DefaultLevel(plan))
    else
        state.level = nil
        state.build = Rules.Decode(Trees(), ns:GetModuleSettings(Module).builds[state.class] or "")
    end
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
    -- 没选过方案、也没有自己的加点时，用网站给这个职业的默认方案
    local saved, plan = class and settings.plans[class]
    if saved == nil and (settings.builds[class or ""] or "") == "" then
        local _, default = ClassPlans(class)
        saved = default
    end
    if saved and saved ~= "" then
        plan = FindPlan(saved)
    end
    UsePlan(plan)
end

local function SaveBuild()
    local code = Rules.Encode(state.build)
    ns:GetModuleSettings(Module).builds[state.class] = code ~= "" and code or nil
end

local function Code()
    return Rules.Encode(state.build)
end

-- 在方案上改动：从这一级的点法出发，变成玩家自己的加点
local function Detach()
    if state.plan then
        state.plan, state.level, state.picks, state.respec = nil, nil, {}, false
        ns:GetModuleSettings(Module).plans[state.class] = ""
    end
end

-- 加点或减点；成功返回 true
local function Spend(t, index, delta)
    local trees = Trees()
    if delta > 0 and Rules.CanAdd(trees, state.build, t, index)
        or delta < 0 and Rules.CanRemove(trees, state.build, t, index) then
        Detach()
        state.build[t][index] = state.build[t][index] + delta
        SaveBuild()
        return true
    end
    return false
end

local function Reset(t)
    Detach()
    for index, ranks in ipairs(state.build) do
        if not t or t == index then
            for i in ipairs(ranks) do
                ranks[i] = 0
            end
        end
    end
    SaveBuild()
end

-- 方案视图与测试使用
Module.SelectClass = SelectClass
Module.Spend = Spend
Module.Reset = Reset
Module.Code = Code
Module.State = state
Module.UsePlan = UsePlan
Module.SetLevel = SetLevel
Module.FindPlan = FindPlan
Module.Trees = Trees
Module.ClassPlans = ClassPlans

--------------------------------------------------------------------------------
-- 天赋鼠标提示：游戏天赋窗口里的方案视图使用（按钮上带 treeIndex / talentIndex）
--------------------------------------------------------------------------------

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

Module.ShowTooltip = ShowTooltip

function Module:OnEnable()
    -- 升级时，正在看本职业方案的等级条跟到新等级（方案视图下次刷新时画出来）
    ns:RegisterEvent("PLAYER_LEVEL_UP", function(_, level)
        if state.plan and state.class == ns.PlayerClass() and level then
            SetLevel(level)
        end
    end)
end
