local ADDON_NAME, ns = ...

-- 超出距离染红（动作条模块 ActionBars 的一部分，设置 rangeTint，默认开启）：
-- 游戏自带的规则只把按钮右上角的快捷键数字变红；这里把整个按钮图标染红，一眼看出够不够得着。
-- · 距离变化由游戏通知：ACTION_RANGE_CHECK_UPDATE（新版动作条），以及游戏更新距离提示的函数
--   ActionButton_UpdateRangeIndicator（旧版每隔一段时间检查一次，同样会调用它）。不自己轮询。
-- · 游戏在可用性变化（没蓝、不能用）时会重设图标颜色，挂在按钮的 UpdateUsable 之后重新染一次。
-- · 不在距离里就染红；在距离内、没有目标或这个技能不看距离时，按游戏原本的规则恢复：
--   可用原色，缺法力偏蓝，不能用变灰。
-- · 只改图标颜色（不受战斗锁定限制），不动按钮的动作、属性和点击，不会污染安全按钮。
local Module = ns.modules.ActionBars

local BAR_PREFIXES = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
    "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
}
local BUTTONS_PER_BAR = 12

local buttons = {} -- 已接管的按钮
local hooked = {}  -- [按钮] = true：已挂上 UpdateUsable
local started = false

local function Settings()
    return ns:GetModuleSettings(Module)
end

local function Icon(button)
    return button.icon or button.Icon or (button.GetName and button:GetName() and _G[button:GetName() .. "Icon"])
end

-- 这个按钮的技能现在是否超出距离：只有明确“不在距离内”才算；没有目标、不看距离、取不到时都不算
local function OutOfRange(button)
    local slot = button.action
    if not (slot and IsActionInRange) then
        return false
    end
    local inRange = IsActionInRange(slot)
    if ns.IsSecret(inRange) then
        return false
    end
    return inRange == false
end

-- 染色：超出距离染红，否则按游戏原本的可用性颜色恢复
local function Tint(button)
    local icon = Icon(button)
    if not icon or not button.action then
        return
    end
    local colors = ns.Theme.colors
    local color
    if Settings().rangeTint ~= false and Module.enabled and OutOfRange(button) then
        color = colors.actionOutOfRange
        button.whRangeTinted = true
    elseif button.whRangeTinted then
        -- 只恢复自己染过的，其他时候不碰游戏设的颜色
        button.whRangeTinted = nil
        local usable, noMana = true, false
        if IsUsableAction then
            usable, noMana = IsUsableAction(button.action)
        end
        if ns.IsSecret(usable) or usable then
            color = colors.actionUsable
        elseif noMana then
            color = colors.actionNoMana
        else
            color = colors.actionUnusable
        end
    end
    if color then
        icon:SetVertexColor(color[1], color[2], color[3])
    end
end
Module.RangeTint = Tint -- 供测试使用

-- 找到动作条按钮并挂上可用性更新；可以重复调用，只处理新出现的按钮
local function CollectButtons()
    for _, prefix in ipairs(BAR_PREFIXES) do
        for index = 1, BUTTONS_PER_BAR do
            local button = _G[prefix .. index]
            if button and not hooked[button] then
                hooked[button] = true
                tinsert(buttons, button)
                if type(button.UpdateUsable) == "function" then
                    hooksecurefunc(button, "UpdateUsable", Tint)
                end
            end
        end
    end
end

local function TintAll()
    for _, button in ipairs(buttons) do
        Tint(button)
    end
end
Module.RangeTintAll = TintAll -- 供测试使用

-- 某个动作条格子的距离或内容变了：只重染放着这个格子的按钮（格子号 0 表示全部）
local function OnRangeUpdate(_, slot)
    if not slot or slot == 0 then
        TintAll()
        return
    end
    for _, button in ipairs(buttons) do
        if button.action == slot then
            Tint(button)
        end
    end
end

function Module.StartRangeTint()
    CollectButtons()
    if started then
        TintAll()
        return
    end
    started = true
    if type(ActionButton_UpdateRangeIndicator) == "function" then
        hooksecurefunc("ActionButton_UpdateRangeIndicator", Tint)
    end
    if type(ActionButton_UpdateUsable) == "function" then
        hooksecurefunc("ActionButton_UpdateUsable", Tint)
    end
    ns:RegisterEvent("ACTION_RANGE_CHECK_UPDATE", OnRangeUpdate)
    -- 换目标、换动作条页时距离都会变，全部重染一次
    ns:RegisterEvent("PLAYER_TARGET_CHANGED", TintAll)
    ns:RegisterEvent("ACTIONBAR_PAGE_CHANGED", TintAll)
    ns:RegisterEvent("ACTIONBAR_SLOT_CHANGED", OnRangeUpdate)
    TintAll()
end

-- 设置里开关 rangeTint：马上重染（关掉时恢复原色）
function Module:Refresh()
    if started then
        TintAll()
    end
end
