local ADDON_NAME, ns = ...
local L = ns.L

-- 嵌入游戏自带窗口：暴雪技能书顶部的分类标签栏末尾加“按等级学习”“专业”两个图标标签，
-- 暴雪天赋窗口顶部的双天赋标签旁加“天赋方案”标签，用的都是暴雪同一栏标签的模板。
-- 点我们的标签时显示原生样子的页面：技能书里是用暴雪技能书模板另建的一份分页列表（Modules/NativeSpellList.lua），
-- 天赋窗口里是原生天赋窗口样子的方案视图（Modules/NativeTalentView.lua）；/wh 主窗口仍是插件自己的深色页面。
-- 无限版的技能书与天赋是 PlayerSpellsFrame 里的两个子框架（按需加载的 Blizzard_PlayerSpells）。
-- 不往暴雪的标签栏里加标签、不改暴雪标签的状态、不调用暴雪的切换函数（避免污染技能书施法与天赋操作）：
-- 我们的标签挂在自己的容器上（容器提供标签模板需要的 SetTab 等方法），只锚定在暴雪标签栏右侧。
-- 暴雪选中的标签在我们的页面显示期间仍是选中样子且不可点，所以在它上面盖一个同样外观、未选中的“替身”标签，
-- 点替身回到暴雪内容；玩家点暴雪的其他标签时，用 hooksecurefunc 跟着收起我们的页面。
-- 每次打开暴雪窗口都回到暴雪自己的内容。
-- 天赋窗口里，暴雪天赋按钮上方另标出所选推荐方案在第几级点这个天赋（按客户端技能名对应到我们的天赋）。
local Module = ns:NewModule("NativeTabs")

local STAND_IN = 0 -- 替身标签的标签 ID；我们的页面标签从 1 起
-- 盖板至少比暴雪内容框架高出的层级：天赋窗口的顶部标签栏与树标题在 1010 层，天赋按钮的层级还会更高，
-- 实际层级按暴雪天赋按钮的最高层再往上算（TopLevel）
local HOST_LEVEL = 1100
local MAX_LEVEL = 9000

-- 两个宿主：暴雪框架、它的顶部标签栏与标签模板、我们的视图（创建、显示、收起）与页面
-- （module：页面依赖的功能模块，模块关闭时不加这个标签）。技能书的分类标签是图标标签（鼠标提示写名字），
-- 天赋窗口的是文字标签
local HOSTS = {
    {
        key = "spellbook",
        frame = function()
            return PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
        end,
        tabSystem = function(inner)
            return inner.CategoryTabSystem
        end,
        tabTemplate = "SpellBookCategoryTabTemplate",
        iconTabs = true,
        createView = function(inner)
            return ns.NativeSpellList.Create(inner)
        end,
        showView = function(view, page)
            view:ShowKind(page.id)
        end,
        hideView = function(view)
            view:Close()
        end,
        pages = {
            { id = "spells", module = "Spellbook", title = "Spells by level", icon = "Interface\\Icons\\INV_Misc_Book_11" },
        },
    },
    {
        key = "talents",
        frame = function()
            return PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
        end,
        tabSystem = function(inner)
            return inner.TabSystem
        end,
        tabTemplate = "ClassTalentsFrameTabTemplate",
        -- 双天赋标签挂在天赋画布边框的上沿，方案视图从边框上沿往下盖到窗口底
        coverTop = function(inner)
            local border = inner.BackgroundBorder
            local top, borderTop = inner:GetTop(), type(border) == "table" and border:GetTop()
            return top and borderTop and (top - borderTop) or 34
        end,
        createView = function(inner)
            return ns.NativeTalentView.Create(inner)
        end,
        showView = function(view)
            view:Show()
            view:Refresh()
        end,
        hideView = function(view)
            view:Hide()
        end,
        pages = {
            { id = "talents", module = "Talents", title = "Talent plans" },
        },
    },
}

local hosts = {} -- key -> { inner, system, view, strip, tabs, standIn, selected }
Module.hosts = hosts -- 供测试使用

local function Covering(host)
    return host and host.selected ~= nil and host.view ~= nil and host.view:IsVisible()
end

local function PageEnabled(page)
    local module = ns.modules[page.module]
    return module ~= nil and module.enabled
end

-- 暴雪标签栏里当前选中的标签（只读）
local function NativeSelectedTab(host)
    local system = host.system
    local id = system and system.selectedTabID
    return id and system.GetTabButton and system:GetTabButton(id)
end

-- 替身标签：盖在暴雪选中的标签上，外观与它相同但未选中；只在我们的页面显示时出现
local function PlaceStandIn(host)
    local standIn, native = host.standIn, NativeSelectedTab(host)
    if not (host.selected and native and native:IsShown()) then
        standIn:Hide()
        return
    end
    if host.definition.iconTabs then
        standIn:Init(STAND_IN, nil, native.tabIcon)
        standIn:SetTooltipText(native.tooltipText)
    else
        standIn:Init(STAND_IN, native.Text and native.Text:GetText() or "")
    end
    standIn:ClearAllPoints()
    standIn:SetAllPoints(native)
    standIn:Show()
end

local function PaintTabs(host)
    for _, tab in ipairs(host.tabs) do
        tab:SetTabSelected(tab.page.id == host.selected)
    end
    PlaceStandIn(host)
end

local FitView

-- 切换标签：pageID 为 nil 时露出暴雪原来的内容
local function Select(host, pageID)
    local entry
    for _, page in ipairs(host.definition.pages) do
        if page.id == pageID and PageEnabled(page) then
            entry = page
        end
    end
    if entry and not host.view then
        if InCombatLockdown() then
            -- 视图第一次创建要建不少框架，战斗中不做
            ns:Print(L["Available after combat."])
            entry = nil
        else
            host.view = host.definition.createView(host.inner)
            FitView(host)
        end
    end
    -- 记下打开我们页面时暴雪选中的是哪个标签：之后暴雪选中别的标签才算玩家切走了
    if entry and not host.selected then
        host.nativeTabID = host.system.selectedTabID
    end
    host.selected = entry and entry.id or nil
    if host.badges then
        host.badges:SetShown(entry == nil)
    end
    if entry then
        host.definition.showView(host.view, entry)
    elseif host.view then
        host.definition.hideView(host.view)
    end
    PaintTabs(host)
end
Module.Select = function(key, pageID) -- 供测试使用
    Select(hosts[key], pageID)
end

-- 暴雪内容框架里最高的层级：天赋窗口按 nodeIDToButton 里各天赋按钮的层级算
local function TopLevel(inner)
    local peak = inner:GetFrameLevel() + HOST_LEVEL
    local buttons = rawget(inner, "nodeIDToButton")
    if type(buttons) == "table" then
        for _, button in pairs(buttons) do
            local level = button.GetFrameLevel and button:GetFrameLevel()
            if level and level + 10 > peak then
                peak = level + 10
            end
        end
    end
    return math.min(peak, MAX_LEVEL)
end

-- 天赋窗口：方案视图盖住天赋画布（从双天赋标签下沿到窗口底），层级压过最高的天赋按钮；
-- 技能书的列表自己定位（与暴雪列表同一位置）。标签容器压过暴雪标签栏（替身要盖住暴雪选中的标签）
function FitView(host)
    local inner = host.inner
    local level = TopLevel(inner)
    if host.badges then
        host.badges:SetFrameLevel(level)
    end
    local view = host.view
    if view and host.definition.coverTop then
        view:ClearAllPoints()
        view:SetPoint("BOTTOMRIGHT")
        view:SetPoint("TOPLEFT", inner, "TOPLEFT", 0, -host.definition.coverTop(inner, host.system))
        view:SetFrameLevel(level + 20)
    end
    host.strip:SetFrameLevel(math.max(level + 30, (host.system:GetFrameLevel() or 0) + 10))
end

--------------------------------------------------------------------------------
-- 暴雪天赋按钮上的方案等级：所选方案（天赋页里本职业选的方案，没选过时用默认方案）在第几级点这个天赋，
-- 已到等级的段落绿色。方案洗天赋前，按角色当前等级所在的那一段显示。
--------------------------------------------------------------------------------

-- 本职业正在用的方案；选了“我的加点”或天赋模块关闭时为 nil
local function PlayerPlan()
    local class = ns.PlayerClass()
    local data = ns.Data.talentPlans and ns.Data.talentPlans[class or ""]
    local talents = ns.modules.Talents
    if not (data and talents and talents.enabled) then
        return nil
    end
    local settings = ns:GetModuleSettings(talents)
    local id = settings.plans[class]
    if id == nil and (settings.builds[class] or "") == "" then
        id = data.default
    end
    for _, plan in ipairs(data.plans) do
        if plan.id == id then
            return plan
        end
    end
end

-- {树序号 = {天赋序号 = {等级…}}}：角色当前等级所在阶段的加点顺序，第 n 点在 first + n - 1 级
local function PlanLevels(plan, level)
    local order = plan.orders[#plan.orders]
    for _, phase in ipairs(plan.orders) do
        if phase.respecAt and level < phase.respecAt then
            order = phase
            break
        end
    end
    local levels = {}
    for n, step in ipairs(order.steps) do
        local t, i = math.floor(step / 100), step % 100
        levels[t] = levels[t] or {}
        levels[t][i] = levels[t][i] or {}
        tinsert(levels[t][i], plan.first + n - 1)
    end
    return levels
end

-- 等级列表写成“11-13, 20”，已到等级的段落绿色
local function LevelText(list, level)
    local parts, first = {}, 1
    while first <= #list do
        local last = first
        while list[last + 1] == list[last] + 1 do
            last = last + 1
        end
        local text = first == last and tostring(list[first]) or (list[first] .. "-" .. list[last])
        tinsert(parts, ns.Theme:Color(text, list[last] <= level and "green" or "text"))
        first = last + 1
    end
    return table.concat(parts, ",")
end

local function SpellName(button)
    local ok, spellID = pcall(button.GetSpellID, button)
    if ok and spellID and C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
end

local function Badge(host, button)
    local badge = host.badgeByButton[button]
    if not badge then
        badge = {}
        badge.background = ns.Theme:Fill(host.badges, "menu", "OVERLAY")
        badge.text = ns.UI:Text(host.badges, "Small")
        badge.text:SetPoint("BOTTOM", button, "TOP", 0, 3)
        badge.background:SetPoint("TOPLEFT", badge.text, "TOPLEFT", -3, 2)
        badge.background:SetPoint("BOTTOMRIGHT", badge.text, "BOTTOMRIGHT", 3, -2)
        host.badgeByButton[button] = badge
    end
    return badge
end

local function RefreshBadges()
    local host = hosts.talents
    if not (host and host.inner:IsVisible()) then
        return
    end
    local buttons = rawget(host.inner, "nodeIDToButton")
    local plan = Module.enabled and PlayerPlan()
    local trees = ns.Data.talents and ns.Data.talents[ns.PlayerClass() or ""]
    local level = ns.PlayerLevel()
    local levels, byName = plan and trees and PlanLevels(plan, level), {}
    if levels then
        for t, tree in ipairs(trees.trees) do
            for i, talent in ipairs(tree.talents) do
                local name = ns.Name(talent.name)
                if name then
                    byName[name] = levels[t] and levels[t][i]
                end
            end
        end
    end
    FitView(host)
    for _, badge in pairs(host.badgeByButton) do
        badge.text:Hide()
        badge.background:Hide()
    end
    host.badges:SetShown(Module.enabled and host.selected == nil)
    for _, button in pairs(type(buttons) == "table" and buttons or {}) do
        local list = levels and byName[SpellName(button) or ""]
        if list then
            local badge = Badge(host, button)
            badge.text:SetText(LevelText(list, level))
            badge.text:Show()
            badge.background:Show()
        end
    end
end
Module.RefreshBadges = RefreshBadges

-- 标签容器：暴雪标签模板点击时调用父框架的 SetTab(标签 ID)，宽度取父框架的 GetTabWidthConstraints；
-- 这里由插件自己实现，不经过暴雪的标签系统
local function CreateStrip(host)
    local strip = CreateFrame("Frame", nil, host.inner)
    strip:SetAllPoints(host.system)
    function strip.GetTabWidthConstraints()
        return host.system.minTabWidth, host.system.maxTabWidth
    end
    function strip.SetTab(_, tabID)
        local tab = host.tabs[tabID]
        Select(host, tab and tab.page.id or nil)
    end
    function strip.PlayTabSelectSound()
        local sound = host.system.tabSelectSound
        if sound and PlaySound then
            PlaySound(sound)
        end
    end
    host.strip = strip
    return strip
end

local function CreateTab(host, tabID, page)
    local tab = CreateFrame("Button", nil, host.strip, host.definition.tabTemplate)
    if host.definition.iconTabs then
        tab:Init(tabID, nil, page.icon)
        tab:SetTooltipText(L[page.title])
    else
        tab:Init(tabID, L[page.title])
    end
    tab.page = page
    -- 接在暴雪标签栏右侧（它的宽度随标签多少变化，锚点跟着走）
    tab:SetPoint("TOPLEFT", host.tabs[tabID - 1] or host.system, "TOPRIGHT", tabID == 1 and 2 or 0, 0)
    host.tabs[tabID] = tab
    return tab
end

local function Build(definition, inner)
    local system = definition.tabSystem(inner)
    if type(system) ~= "table" then
        return
    end
    local host = { definition = definition, inner = inner, system = system, tabs = {} }
    hosts[definition.key] = host
    CreateStrip(host)

    inner:HookScript("OnSizeChanged", function()
        FitView(host)
    end)
    if definition.key == "talents" then
        -- 方案等级标在暴雪天赋按钮上方的一层上；暴雪天赋按钮在窗口显示后才排好，稍后再刷一次
        host.badges = CreateFrame("Frame", nil, inner)
        host.badges:SetAllPoints(inner)
        host.badgeByButton = {}
        inner:HookScript("OnShow", function()
            C_Timer.After(0, RefreshBadges)
            C_Timer.After(0.5, RefreshBadges)
        end)
    end

    for _, page in ipairs(definition.pages) do
        if PageEnabled(page) then
            CreateTab(host, #host.tabs + 1, page)
        end
    end
    host.standIn = CreateFrame("Button", nil, host.strip, definition.tabTemplate)
    host.standIn:Hide()
    FitView(host)

    -- 玩家点暴雪自己的标签（换分类、换天赋组）时收起我们的页面。暴雪标签栏点击时调用的是加载时记下的
    -- 切换函数（GenerateClosure(self.SetTab, self)），挂在内容框架的 SetTab 上不会触发；
    -- 标签栏每次切换都会按方法名调用 SetTabVisuallySelected，所以挂在这里。暴雪刷新技能数据时也会重新选中
    -- 当前标签，那时标签没变，不收起，只把替身重新盖上
    if type(system.SetTabVisuallySelected) == "function" then
        hooksecurefunc(system, "SetTabVisuallySelected", function(_, tabID)
            if not host.selected then
                return
            end
            if tabID ~= host.nativeTabID then
                Select(host, nil)
            else
                PlaceStandIn(host)
            end
        end)
    end
    -- 用技能书搜索时也收起
    for _, method in ipairs({ "DisplayFullSearchResults", "EnableSearchResultsMode" }) do
        if type(inner[method]) == "function" then
            hooksecurefunc(inner, method, function()
                if host.selected then
                    Select(host, nil)
                end
            end)
        end
    end
    -- 技能书的搜索框接在分类标签栏右侧，暴雪按标签栏右沿算它的宽度；我们的标签接在标签栏后面，
    -- 所以在暴雪算完之后把搜索框再收窄我们标签的宽度
    if definition.iconTabs and type(inner.ResizeSearchBox) == "function" and inner.SearchBox then
        hooksecurefunc(inner, "ResizeSearchBox", function()
            if not (Module.enabled and host.strip:IsShown()) then
                return
            end
            local used = 0
            for _, tab in ipairs(host.tabs) do
                used = used + (tab:GetWidth() or 0)
            end
            local width = inner.SearchBox:GetWidth()
            if width and used > 0 then
                inner.SearchBox:SetWidth(math.max(60, width - used - 4))
            end
        end)
    end

    -- 每次打开暴雪窗口都先显示它自己的内容
    inner:HookScript("OnShow", function()
        if Module.enabled then
            FitView(host)
            Select(host, nil)
        end
    end)
    host.strip:SetShown(Module.enabled)
    Select(host, nil)
end

-- 暴雪窗口按需加载：已加载就直接挂上，否则等它加载
local function Attach()
    for _, definition in ipairs(HOSTS) do
        local inner = definition.frame()
        if type(inner) == "table" and not hosts[definition.key] then
            Build(definition, inner)
        end
    end
end

function Module:OnEnable()
    Attach()
    for _, host in pairs(hosts) do
        host.strip:Show()
    end
    if not self.listening then
        self.listening = true
        ns:RegisterEvent("ADDON_LOADED", function(_, name)
            if name == "Blizzard_PlayerSpells" and Module.enabled then
                Attach()
            end
        end)
        -- 天赋变化、升级时重画方案等级（天赋窗口没开时 RefreshBadges 直接返回）
        local function Later()
            C_Timer.After(0.2, RefreshBadges)
        end
        ns:RegisterEvent("TRAIT_CONFIG_UPDATED", Later)
        ns:RegisterEvent("PLAYER_LEVEL_UP", Later)
        -- 学会技能、升级、专业变化时重画正在显示的页面（节流 0.3 秒，页面没显示时不做任何事）
        local pending = false
        local function RefreshViews()
            if pending then
                return
            end
            local shown = false
            for _, host in pairs(hosts) do
                shown = shown or Covering(host)
            end
            if not shown then
                return
            end
            pending = true
            C_Timer.After(0.3, function()
                pending = false
                for _, host in pairs(hosts) do
                    if Covering(host) then
                        host.view:Refresh()
                    end
                end
            end)
        end
        for _, event in ipairs({ "SPELLS_CHANGED", "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED" }) do
            ns:RegisterEvent(event, RefreshViews)
        end
    end
    RefreshBadges()
end

function Module:OnDisable()
    for _, host in pairs(hosts) do
        Select(host, nil)
        host.strip:Hide()
        if host.badges then
            host.badges:Hide()
        end
    end
end
