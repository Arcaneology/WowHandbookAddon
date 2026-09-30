local ADDON_NAME, ns = ...
local L = ns.L

-- 设置页：各功能开关与选项、关于（网站与非官方声明）。
-- 功能模块的整体开关在重载界面后生效；模块内的选项立即生效。
local UI
local CONTENT_WIDTH = 762 -- 主窗口内容区宽度

-- 每个选项：icon 为 Interface\Icons 下的图标（设置页与快捷菜单行首显示），label 为简短名称，
-- tip 为鼠标悬停时的完整说明；多选一的选项可用 icon（完整贴图路径）代替文字，悬停看 tip。
local YES = "Interface\\RaidFrame\\ReadyCheck-Ready"
local NO = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local SECTIONS = {
    { module = "Dungeons", title = "Dungeon guide", options = {} },
    { module = "ItemSource", title = "Item sources", options = {} },
    { module = "MinimapButton", title = "Minimap button", options = {
        { key = "hidden", icon = "INV_Misc_Gear_01", label = "Minimap button", tip = "Show minimap button",
            inverted = true },
    } },
    { module = "Spellbook", title = "Spellbook", options = {
        { key = "levelUpNotice", quick = true, icon = "INV_Misc_Book_11", label = "Level-up reminder",
            tip = "Tell me which spells to train when I level up" },
    } },
    { module = "Professions", title = "Professions", options = {} },
    { module = "SpellbookPanel", title = "Unlearned spells", options = {
        { key = "collapsed", icon = "INV_Misc_Book_09", label = "Spell panel",
            tip = "Show the panel next to the game spellbook", inverted = true },
    } },
    { module = "ActionBars", title = "Action bars", options = {
        { key = "upgradeRanks", quick = true, icon = "Spell_ChargePositive", label = "Upgrade ranks",
            tip = "When I learn a new rank, replace that spell's lower ranks on my bars" },
        { key = "placeNewSpells", quick = true, icon = "INV_Scroll_03", label = "Place new spells",
            tip = "Put newly learned spells on an empty main bar slot" },
        { key = "rangeTint", quick = true, icon = "Ability_Hunter_SniperShot", label = "Out of range in red",
            tip = "Tint the whole button red when the target is out of range" },
    } },
    { module = "InstanceTracker", title = "Instance tracker", options = {
        { key = "autoShow", quick = true, icon = "INV_Misc_Bone_HumanSkull_01", label = "Auto-show in instances",
            tip = "Show boss and quest progress when I enter an instance" },
    } },
    { module = "AutoQuest", title = "Quests", options = {
        { key = "autoAccept", quick = true, icon = "INV_Misc_Book_07", label = "Auto-accept",
            tip = "Accept quests automatically when I talk to an NPC (hold Shift to skip)" },
        { key = "autoTurnIn", quick = true, icon = "INV_Letter_03", label = "Auto turn-in",
            tip = "Turn in completed quests automatically when I talk to an NPC (hold Shift to skip)" },
        { key = "rewardMode", quick = true, icon = "INV_Misc_Bag_10", label = "Reward", choices = {
            { id = "manual", label = "Manual", tip = "I choose the reward myself" },
            { id = "usable", label = "Auto", tip = "Usable first, then the most valuable" },
        } },
    } },
    { module = "Vendor", title = "Vendor", options = {
        { key = "sellJunk", quick = true, icon = "INV_Misc_Coin_01", label = "Sell gray items",
            tip = "Sell gray items automatically when I open a vendor" },
    } },
    { module = "WorldMap", title = "World map", options = {
        { key = "levelLabel", icon = "Ability_Hunter_Pathfinding", label = "Zone levels",
            tip = "Show zone level ranges under the zone name" },
        { key = "flightPins", quick = true, icon = "Ability_Mount_Wyvern_01", label = "Flight paths",
            tip = "Show flight paths; ones not unlocked yet are grayed out" },
        { key = "revealMap", icon = "INV_Misc_Map_01", label = "Full map",
            tip = "Show the full map, including areas not explored yet" },
        { key = "dungeonPins", quick = true, icon = "Spell_Arcane_PortalIronForge", label = "Dungeon entrances",
            tip = "Show dungeon and raid entrances" },
        { key = "spiritHealers", quick = true, icon = "Spell_Holy_GuardianSpirit", label = "Spirit healers", choices = {
            { id = "dead", label = "When dead", tip = "When I am dead" },
            { id = "always", icon = YES, tip = "Always" },
            { id = "off", icon = NO, tip = "Never" },
        } },
        { key = "classTrainerPins", quick = true, icon = "INV_Misc_Book_04", label = "Class trainers",
            tip = "Show my class trainers on the map, with how many spells I can train now" },
        { key = "trainerPins", quick = true, icon = "INV_Misc_Book_08", label = "Profession trainers", choices = {
            { id = "mine", label = "Mine", tip = "My professions" },
            { id = "all", label = "All", tip = "All professions" },
            { id = "off", icon = NO, tip = "Never" },
        } },
        { key = "herbPins", quick = true, icon = "Trade_Herbalism", label = "Herbs", choices = {
            { id = "auto", label = "Auto", tip = "When I know the profession" },
            { id = "always", icon = YES, tip = "Always" },
            { id = "off", icon = NO, tip = "Never" },
        } },
        { key = "orePins", quick = true, icon = "Trade_Mining", label = "Mining nodes", choices = {
            { id = "auto", label = "Auto", tip = "When I know the profession" },
            { id = "always", icon = YES, tip = "Always" },
            { id = "off", icon = NO, tip = "Never" },
        } },
        { key = "minimapGather", quick = true, icon = "INV_Misc_Spyglass_02", label = "On the minimap",
            tip = "Also show herbs and mining nodes on the minimap" },
        { key = "minimapGatherStyle", quick = true, icon = "INV_Ore_Copper_01", label = "Minimap style", choices = {
            { id = "icon", icon = "Interface\\Icons\\INV_Ore_Copper_01", tip = "Item icons" },
            { id = "circle", icon = "Interface\\AddOns\\WowHandbook\\Media\\GatherRing", tip = "Circles" },
        } },
        { key = "recordGather", quick = true, icon = "INV_Misc_Note_06", label = "Remember my nodes",
            tip = "Remember the herbs and mining nodes I gather and show them on the map" },
    } },
}

-- 设置定义共享给小地图按钮右键的快捷菜单：标了 quick 的选项会出现在菜单里
ns.SettingsSections = SECTIONS

-- 设置页的控件：{ control, settings, option }，页面显示时按存档刷新（快捷菜单里改过的也能反映出来）
local controls = {}

-- 选项的显示：行首图标 + 简短名称；多选一的选项是图标 + 文字（没有文字就用说明）
function ns.SettingIcon(option, size)
    if not option.icon then
        return ""
    end
    local path = option.icon:find("\\") and option.icon or ("Interface\\Icons\\" .. option.icon)
    return ("|T%s:%d:%d:0:0:64:64:5:59:5:59|t "):format(path, size or 16, size or 16)
end

function ns.ChoiceText(choice, withTip)
    local icon = choice.icon and ("|T%s:14:14|t"):format(choice.icon) or ""
    local text = choice.label and L[choice.label] or (withTip and choice.tip and L[choice.tip]) or ""
    return icon .. ((icon ~= "" and text ~= "") and " " or "") .. text
end

-- 悬停时显示选项的完整说明
local function AddTip(frame, option)
    if not option.tip then
        return
    end
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L[option.label], 1, 0.82, 0)
        GameTooltip:AddLine(L[option.tip], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", GameTooltip_Hide)
end

-- 勾选框选项；inverted 表示存档里存的是相反的意思（如 hidden）。返回下一行的纵坐标
local function AddCheckbox(panel, settings, option, rowY, onChange)
    local check = UI:Checkbox(panel, ns.SettingIcon(option, 14) .. L[option.label], function(checked)
        if option.inverted then
            settings[option.key] = not checked
        else
            settings[option.key] = checked
        end
        onChange()
    end)
    check:SetPoint("TOPLEFT", 14, rowY)
    AddTip(check, option)
    tinsert(controls, { check = check, settings = settings, option = option })
    return rowY - 24
end

-- 多选一选项：左侧图标与名称，右侧下拉框（选项为图标 + 文字）。返回下一行的纵坐标
local function AddChoice(panel, settings, option, rowY, onChange)
    local label = CreateFrame("Frame", nil, panel)
    label:SetSize(140, 20)
    label:SetPoint("TOPLEFT", 14, rowY)
    label:EnableMouse(true)
    local text = UI:Text(label, "Small", ns.SettingIcon(option, 14) .. L[option.label])
    text:SetPoint("LEFT")
    AddTip(label, option)
    local items = {}
    for _, choice in ipairs(option.choices) do
        tinsert(items, { id = choice.id, label = ns.ChoiceText(choice, true) })
    end
    local dropdown = UI:Dropdown(panel, items, function(id)
        settings[option.key] = id
        onChange()
    end, 150)
    dropdown:SetPoint("TOPLEFT", 160, rowY)
    tinsert(controls, { dropdown = dropdown, settings = settings, option = option })
    return rowY - 28
end

-- 选项的当前值：勾选框为是否勾选（考虑 inverted），多选一为选中的 id
function ns.SettingValue(settings, option)
    if option.choices then
        return settings[option.key] or option.choices[1].id
    elseif option.inverted then
        return settings[option.key] ~= true
    end
    return settings[option.key] ~= false
end

-- 改一个选项并让模块立即生效（设置页与快捷菜单共用）
function ns.SetSetting(module, option, value)
    local settings = ns:GetModuleSettings(module)
    if option.choices then
        settings[option.key] = value
    elseif option.inverted then
        settings[option.key] = not value
    else
        settings[option.key] = value
    end
    if module.Refresh then
        module:Refresh()
    end
end

local function SyncControls()
    for _, item in ipairs(controls) do
        local value = ns.SettingValue(item.settings, item.option)
        if item.check then
            item.check:SetChecked(value)
        else
            item.dropdown:SetValue(value)
        end
    end
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
    SyncControls()
    return p
end

ns.MainFrame:RegisterTab({ id = "settings", title = L["Settings"], order = 800, create = CreatePage, onShow = SyncControls })
