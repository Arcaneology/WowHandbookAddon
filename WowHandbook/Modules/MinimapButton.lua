local ADDON_NAME, ns = ...

local Module = ns:NewModule("MinimapButton", { hidden = false, angle = 225 })
local button
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
        button = ns.UI:MinimapButton(Minimap, function()
            ns.MainFrame:Toggle()
        end)
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
