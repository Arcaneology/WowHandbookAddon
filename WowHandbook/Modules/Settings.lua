local ADDON_NAME, ns = ...
local L = ns.L

-- 设置页：各功能开关与选项、关于（网站与非官方声明）。
-- 功能模块的整体开关在重载界面后生效；模块内的选项立即生效。
local UI
local CONTENT_WIDTH = 762 -- 主窗口内容区宽度

local SECTIONS = {
    { module = "Dungeons", title = "Dungeon guide", options = {} },
    { module = "ItemSource", title = "Item sources", options = {} },
    { module = "MinimapButton", title = "Minimap button", options = {
        { key = "hidden", label = "Show minimap button", inverted = true },
    } },
    { module = "Spellbook", title = "Spellbook", options = {
        { key = "levelUpNotice", label = "Tell me which spells to train when I level up" },
    } },
    { module = "SpellbookPanel", title = "Unlearned spells", options = {
        { key = "collapsed", label = "Show the panel next to the game spellbook", inverted = true },
    } },
    { module = "ActionBars", title = "Action bars", options = {
        { key = "upgradeRanks", label = "When I learn a new rank, replace that spell's lower ranks on my bars" },
        { key = "placeNewSpells", label = "Put newly learned spells on an empty main bar slot" },
    } },
    { module = "InstanceTracker", title = "Instance tracker", options = {
        { key = "autoShow", label = "Show boss and quest progress when I enter an instance" },
    } },
    { module = "Vendor", title = "Vendor", options = {
        { key = "sellJunk", label = "Sell gray items automatically when I open a vendor" },
    } },
    { module = "WorldMap", title = "World map", options = {
        { key = "levelLabel", label = "Show zone level ranges under the zone name" },
        { key = "flightPins", label = "Show flight paths; ones not unlocked yet are grayed out" },
        { key = "revealMap", label = "Show the full map, including areas not explored yet" },
        { key = "dungeonPins", label = "Show dungeon and raid entrances" },
        { key = "spiritHealers", label = "Spirit healers", choices = {
            { id = "dead", label = "When I am dead" },
            { id = "always", label = "Always" },
            { id = "off", label = "Never" },
        } },
    } },
}

-- 勾选框选项；inverted 表示存档里存的是相反的意思（如 hidden）。返回下一行的纵坐标
local function AddCheckbox(panel, settings, option, rowY, onChange)
    local check = UI:Checkbox(panel, L[option.label], function(checked)
        if option.inverted then
            settings[option.key] = not checked
        else
            settings[option.key] = checked
        end
        onChange()
    end)
    check:SetPoint("TOPLEFT", 14, rowY)
    if option.inverted then
        check:SetChecked(settings[option.key] ~= true)
    else
        check:SetChecked(settings[option.key] ~= false)
    end
    return rowY - 24
end

-- 多选一选项：左侧标签，右侧下拉框。返回下一行的纵坐标
local function AddChoice(panel, settings, option, rowY, onChange)
    local label = UI:Text(panel, "Small", L[option.label])
    label:SetPoint("TOPLEFT", 14, rowY - 4)
    local items = {}
    for _, choice in ipairs(option.choices) do
        tinsert(items, { id = choice.id, label = L[choice.label] })
    end
    local dropdown = UI:Dropdown(panel, items, function(id)
        settings[option.key] = id
        onChange()
    end, 150)
    dropdown:SetPoint("TOPLEFT", 160, rowY)
    dropdown:SetValue(settings[option.key] or option.choices[1].id)
    return rowY - 28
end

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

    -- 设置主体放在滚动区域里：模块和选项再多也不会越出窗口或与“关于”重叠
    local scroll = UI:ScrollArea(p)
    scroll:SetPoint("TOPLEFT", PAD, -60)
    scroll:SetPoint("BOTTOMRIGHT", -PAD - 10, 12)
    local body = scroll.child
    local GAP = 16
    local columnWidth = (CONTENT_WIDTH - PAD * 2 - 10 - GAP) / 2
    local column = 0
    local columnY = { 0, 0 }
    for _, section in ipairs(SECTIONS) do
        local module = ns.modules[section.module]
        if module then
            local settings = ns:GetModuleSettings(module)
            local x = column * (columnWidth + GAP)
            local top = columnY[column + 1]
            local panel = UI:Panel(body, "panel", "lineSoft")
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
            local function Changed()
                if module.Refresh then
                    module:Refresh()
                end
            end
            for _, option in ipairs(section.options) do
                if option.choices then
                    rowY = AddChoice(panel, settings, option, rowY, Changed)
                else
                    rowY = AddCheckbox(panel, settings, option, rowY, Changed)
                end
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
            elseif section.module == "ActionBars" then
                -- 整条动作条一次升级到最高等级，以及撤销最近一次改动（自动或手动）
                local upgradeAll = UI:Button(panel, L["Upgrade all now"], 140, 22)
                upgradeAll:SetPoint("TOPLEFT", 14, rowY - 2)
                upgradeAll:SetScript("OnClick", function() module:UpgradeAll() end)
                local undo = UI:Button(panel, L["Undo last change"], 120, 22, "ghost")
                undo:SetPoint("LEFT", upgradeAll, "RIGHT", 6, 0)
                undo:SetScript("OnClick", function() module:Undo() end)
                rowY = rowY - 30
            end
            local height = -rowY + 8
            panel:SetHeight(height)
            columnY[column + 1] = top - height - 12
            column = 1 - column
        end
    end

    -- 关于：网站与非官方声明，接在两列设置之后
    local aboutTop = math.min(columnY[1], columnY[2])
    local about = UI:Panel(body, "raised", "lineSoft")
    about:SetPoint("TOPLEFT", 0, aboutTop)
    about:SetWidth(columnWidth * 2 + GAP)
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
    p.contentHeight = -aboutTop + 76 + 8 -- 供测试使用
    scroll:SetContentHeight(p.contentHeight)
    p.scroll, p.about = scroll, about
    return p
end

ns.MainFrame:RegisterTab({ id = "settings", title = L["Settings"], order = 800, create = CreatePage })
