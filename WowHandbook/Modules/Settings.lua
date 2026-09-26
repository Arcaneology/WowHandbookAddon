local ADDON_NAME, ns = ...
local L = ns.L

-- 设置页：各功能开关与选项、关于（网站与非官方声明）。
-- 功能模块的整体开关在重载界面后生效；模块内的选项立即生效。
local UI

local SECTIONS = {
    { module = "Dungeons", title = "Dungeon guide", options = {} },
    { module = "Spellbook", title = "Spellbook", options = {
        { key = "levelUpNotice", label = "Tell me which spells to train when I level up" },
    } },
    { module = "ActionBars", title = "Action bars", options = {
        { key = "upgradeRanks", label = "Replace lower spell ranks on my bars with the highest rank" },
        { key = "placeNewSpells", label = "Put newly learned spells on an empty main bar slot" },
    } },
    { module = "Vendor", title = "Vendor", options = {
        { key = "sellJunk", label = "Sell gray items automatically when I open a vendor" },
    } },
    { module = "WorldMap", title = "World map", options = {
        { key = "levelLabel", label = "Show zone level ranges under the zone name" },
        { key = "flightPins", label = "Show flight paths; ones not unlocked yet are grayed out" },
        { key = "revealMap", label = "Show the full map, including areas not explored yet" },
    } },
}

local function CreatePage(parent)
    UI = ns.UI
    local p = CreateFrame("Frame", nil, parent)
    local PAD = 20

    local title = UI:Text(p, "Title", L["Settings"])
    title:SetPoint("TOPLEFT", PAD, -18)
    local note = UI:Text(p, "Muted", L["Turning a whole feature on or off takes effect after reloading the UI."])
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

    local reload = UI:Button(p, L["Reload UI"], 110, 24)
    reload:SetPoint("TOPRIGHT", -PAD, -20)
    reload:SetScript("OnClick", function()
        C_UI.Reload()
    end)

    local y = -64
    local column = 0
    local columnWidth = (762 - PAD * 2 - 20) / 2
    local columnY = { y, y }
    for _, section in ipairs(SECTIONS) do
        local module = ns.modules[section.module]
        if module then
            local settings = ns:GetModuleSettings(module)
            local x = PAD + column * (columnWidth + 20)
            local top = columnY[column + 1]
            local panel = UI:Panel(p, "panel", "lineSoft")
            panel:SetPoint("TOPLEFT", x, top)
            panel:SetWidth(columnWidth)
            local heading = UI:Text(panel, "Heading", L[section.title])
            heading:SetPoint("TOPLEFT", 14, -12)
            local enabled = UI:Checkbox(panel, L["Enabled"], function(checked)
                settings.enabled = checked
            end)
            enabled:SetPoint("TOPRIGHT", -14, -9)
            enabled:SetChecked(settings.enabled ~= false)
            local rowY = -38
            for _, option in ipairs(section.options) do
                local check = UI:Checkbox(panel, L[option.label], function(checked)
                    settings[option.key] = checked
                    if module.Refresh then
                        module:Refresh()
                    end
                end)
                check:SetPoint("TOPLEFT", 14, rowY)
                check:SetChecked(settings[option.key] ~= false)
                rowY = rowY - 24
            end
            if section.module == "WorldMap" then
                local scaleLabel = UI:Text(panel, "Small")
                scaleLabel:SetPoint("TOPLEFT", 14, rowY - 4)
                local function ShowScale()
                    scaleLabel:SetText((L["World map scale: %.1f"]):format(settings.mapScale or 1))
                end
                local function Step(delta)
                    settings.mapScale = math.min(1.6, math.max(0.6, floor(((settings.mapScale or 1) + delta) * 10 + 0.5) / 10))
                    ShowScale()
                    module:ApplyScale()
                end
                local minus = UI:Button(panel, "-", 24, 20)
                minus:SetPoint("TOPLEFT", 160, rowY - 1)
                minus:SetScript("OnClick", function() Step(-0.1) end)
                local plus = UI:Button(panel, "+", 24, 20)
                plus:SetPoint("LEFT", minus, "RIGHT", 4, 0)
                plus:SetScript("OnClick", function() Step(0.1) end)
                ShowScale()
                rowY = rowY - 28
            end
            local height = -rowY + 8
            panel:SetHeight(height)
            columnY[column + 1] = top - height - 12
            column = 1 - column
        end
    end

    -- 关于：网站与非官方声明（见 docs/05-site-link-policy.md）
    local about = UI:Panel(p, "raised", "lineSoft")
    about:SetPoint("BOTTOMLEFT", PAD, 20)
    about:SetPoint("BOTTOMRIGHT", -PAD, 20)
    about:SetHeight(76)
    local aboutTitle = UI:Text(about, "Heading", L["About"])
    aboutTitle:SetPoint("TOPLEFT", 14, -12)
    local disclaimer = "WoW Handbook is a free, unofficial fan-made addon. "
        .. "It is not affiliated with or endorsed by Blizzard Entertainment. Full guides: wowhandbook.com"
    local aboutText = UI:Text(about, "Small", L[disclaimer])
    aboutText:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -6)
    aboutText:SetPoint("RIGHT", -180, 0)
    local copy = UI:Button(about, L["Copy website link"], 150, 24, "primary")
    copy:SetPoint("RIGHT", -14, 0)
    copy:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("home"))
    end)
    return p
end

ns.MainFrame:RegisterTab({ id = "settings", title = L["Settings"], order = 800, create = CreatePage })
