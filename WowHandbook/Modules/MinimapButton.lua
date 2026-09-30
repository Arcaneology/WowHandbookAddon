local ADDON_NAME, ns = ...

local L = ns.L

-- 小地图按钮：左键开关主窗口，右键弹出快捷设置菜单，拖动沿小地图边缘移动。
-- 快捷菜单的内容来自设置页的定义（ns.SettingsSections 里标了 quick 的选项），改动与设置页完全一样、立即生效。
local Module = ns:NewModule("MinimapButton", { hidden = false, angle = 225 })
local button, menu
local atan2 = math.atan2 or function(y, x)
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    return y >= 0 and math.pi / 2 or -math.pi / 2
end

-- 按钮中心放在小地图边框的圆上：半径取小地图实际半宽再向外一点，不写死尺寸
-- （Forever 客户端的小地图是 198 宽，经典旧世是 140；玩家或其他插件也可能改小地图大小）
local EDGE_OFFSET = 5
local DEFAULT_WIDTH = 198

local function Radius()
    local width = Minimap:GetWidth()
    if not width or width <= 0 then
        width = DEFAULT_WIDTH
    end
    return width / 2 + EDGE_OFFSET
end
Module.Radius = Radius -- 供测试使用

local function Position()
    if not button then
        return
    end
    local settings = ns:GetModuleSettings(Module)
    local radians = math.rad(settings.angle or 225)
    local radius = Radius()
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

local function OnDragStart(self)
    self:SetScript("OnUpdate", function()
        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local centerX, centerY = Minimap:GetCenter()
        if x and y and centerX and centerY then
            local angle = math.deg(atan2(y / scale - centerY, x / scale - centerX))
            ns:GetModuleSettings(Module).angle = angle
            Position()
        end
    end)
end

local function OnDragStop(self)
    self:SetScript("OnUpdate", nil)
end

-- 快捷菜单条目：标题（点击打开主窗口）；常用选项按模块用分隔线分组（只列已启用的模块），
-- 每行是图标加简短名称，悬停看完整说明；最后是“设置”（打开设置页）
local function MenuEntries()
    local entries = {
        { kind = "title", text = L["WoW Handbook"], tip = L["Open WoW Handbook"],
            onClick = function() ns.MainFrame:Open("home") end },
    }
    for _, section in ipairs(ns.SettingsSections or {}) do
        local module = ns.modules[section.module]
        if module and module.enabled then
            local settings = ns:GetModuleSettings(module)
            local first = true
            for _, option in ipairs(section.options) do
                if option.quick then
                    if first then
                        tinsert(entries, { kind = "separator" })
                        first = false
                    end
                    local value = ns.SettingValue(settings, option)
                    local text = ns.SettingIcon(option, 14) .. L[option.label]
                    local tip = option.tip and L[option.tip]
                    if option.choices then
                        local choices = {}
                        for _, choice in ipairs(option.choices) do
                            tinsert(choices, { id = choice.id, text = ns.ChoiceText(choice),
                                tip = L[choice.tip or choice.label] })
                        end
                        tinsert(entries, { kind = "choice", text = text, tip = tip, choices = choices, value = value,
                            onClick = function(id) ns.SetSetting(module, option, id) end })
                    else
                        tinsert(entries, { kind = "check", text = text, tip = tip, checked = value,
                            onClick = function(checked) ns.SetSetting(module, option, checked) end })
                    end
                end
            end
        end
    end
    tinsert(entries, { kind = "separator" })
    tinsert(entries, { kind = "action", text = ns.SettingIcon({ icon = "INV_Misc_Gear_01" }, 14) .. L["Settings"],
        onClick = function() ns.MainFrame:Open("settings") end })
    return entries
end
Module.MenuEntries = MenuEntries -- 供测试使用

local function OnClick(mouseButton)
    if mouseButton == "RightButton" then
        menu = menu or ns.UI:CheckMenu("WowHandbookQuickMenu")
        Module.menu = menu -- 供测试使用
        menu:Toggle(button, MenuEntries)
    else
        if menu then
            menu:Hide()
        end
        ns.MainFrame:Toggle()
    end
end

function Module:Refresh()
    if button then
        button:SetShown(self.enabled and not ns:GetModuleSettings(self).hidden)
    end
end

function Module:OnEnable()
    if not Minimap then
        return
    end
    if not button then
        button = ns.UI:MinimapButton(Minimap, OnClick)
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", OnDragStart)
        button:SetScript("OnDragStop", OnDragStop)
        -- 小地图改变大小（界面编辑模式、其他插件）时跟着重新定位
        Minimap:HookScript("OnSizeChanged", Position)
    end
    Position()
    self:Refresh()
end

function Module:OnDisable()
    if button then
        button:SetScript("OnUpdate", nil)
        button:Hide()
    end
end
