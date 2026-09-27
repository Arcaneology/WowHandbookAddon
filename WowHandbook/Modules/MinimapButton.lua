local ADDON_NAME, ns = ...

local Module = ns:NewModule("MinimapButton", { hidden = false, angle = 225 })
local button
local atan2 = math.atan2 or function(y, x)
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    return y >= 0 and math.pi / 2 or -math.pi / 2
end

local function Position()
    local settings = ns:GetModuleSettings(Module)
    local radians = math.rad(settings.angle or 225)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * 80, math.sin(radians) * 80)
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
