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
    { module = "Dungeons", category = "dungeons", title = "Dungeon guide", options = {} },
    { module = "ItemSource", category = "dungeons", title = "Item sources", options = {} },
    { module = "MinimapButton", category = "general", title = "Minimap button", options = {
        { key = "hidden", icon = "INV_Misc_Gear_01", label = "Minimap button", tip = "Show minimap button",
            inverted = true },
    } },
    { module = "Spellbook", category = "spells", title = "Spellbook", options = {
        { key = "levelUpNotice", quick = true, icon = "INV_Misc_Book_11", label = "Level-up reminder",
            tip = "Tell me which spells to train when I level up" },
    } },
    { module = "Professions", category = "professions", title = "Professions", options = {} },
    { module = "SpellbookPanel", category = "spells", title = "Unlearned spells", options = {
        { key = "collapsed", icon = "INV_Misc_Book_09", label = "Spell panel",
            tip = "Show the panel next to the game spellbook", inverted = true },
    } },
    { module = "Talents", category = "spells", title = "Talent simulator", options = {} },
    { module = "ActionBars", category = "spells", title = "Action bars", options = {
        { key = "upgradeRanks", quick = true, icon = "Spell_ChargePositive", label = "Upgrade ranks",
            tip = "When I learn a new rank, replace that spell's lower ranks on my bars" },
        { key = "placeNewSpells", quick = true, icon = "INV_Scroll_03", label = "Place new spells",
            tip = "Put newly learned spells on an empty main bar slot" },
        { key = "rangeTint", quick = true, icon = "Ability_Hunter_SniperShot", label = "Out of range in red",
            tip = "Tint the whole button red when the target is out of range" },
    } },
    { module = "InstanceTracker", category = "dungeons", title = "Instance tracker", options = {
        { key = "autoShow", quick = true, icon = "INV_Misc_Bone_HumanSkull_01", label = "Auto-show in instances",
            tip = "Show boss and quest progress when I enter an instance" },
    } },
    { module = "AutoQuest", category = "quests", title = "Quests", options = {
        { key = "autoAccept", quick = true, icon = "INV_Misc_Book_07", label = "Auto-accept",
            tip = "Accept quests automatically when I talk to an NPC (hold Shift to skip)" },
        { key = "autoTurnIn", quick = true, icon = "INV_Letter_03", label = "Auto turn-in",
            tip = "Turn in completed quests automatically when I talk to an NPC (hold Shift to skip)" },
        { key = "rewardMode", quick = true, icon = "INV_Misc_Bag_10", label = "Reward", choices = {
            { id = "manual", label = "Manual", tip = "I choose the reward myself" },
            { id = "usable", label = "Auto", tip = "Usable first, then the most valuable" },
        } },
    } },
    { module = "Vendor", category = "general", title = "Vendor", options = {
        { key = "sellJunk", quick = true, icon = "INV_Misc_Coin_01", label = "Sell gray items",
            tip = "Sell gray items automatically when I open a vendor" },
    } },
    { module = "WorldMap", category = "map", title = "World map", options = {
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

-- 设置页布局：左侧分类导航，右侧是这一类的设置列表。
-- 每个功能一段：标题行（功能名，右侧整体开关），下面每个选项一行（左侧图标与名称，右侧勾选框或下拉框），
-- 行与行之间细分隔线；不再是一格格小卡片。
local CATEGORIES = {
    { id = "general", title = "General" },
    { id = "dungeons", title = "Dungeons" },
    { id = "quests", title = "Quests" },
    { id = "spells", title = "Spells" },
    { id = "professions", title = "Professions" },
    { id = "map", title = "Map" },
    { id = "about", title = "About" },
}
local NAV_WIDTH, ROW_HEIGHT, HEADER_HEIGHT = 128, 30, 34
local LANGUAGE_NAMES = { enUS = "English", zhCN = "简体中文" } -- 语言名用各自的语言写，不翻译

-- 一行：左侧图标与名称（悬停看完整说明），底部细分隔线。返回行框架
local function OptionRow(list, y, width, labelText, option)
    local row = CreateFrame("Frame", nil, list)
    row:SetSize(width, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -y)
    local label = CreateFrame("Frame", nil, row)
    label:SetPoint("LEFT", 12, 0)
    label:SetSize(width - 200, ROW_HEIGHT)
    label:EnableMouse(true)
    local text = UI:Text(label, "Body", labelText)
    text:SetPoint("LEFT")
    if option then
        AddTip(label, option)
    end
    local line = row:CreateTexture(nil, "BORDER")
    line:SetPoint("BOTTOMLEFT", 12, 0)
    line:SetPoint("BOTTOMRIGHT", -12, 0)
    line:SetHeight(1)
    line:SetColorTexture(unpack(ns.Theme.colors.lineSoft))
    return row
end

-- 一段：功能名 + 整体开关，下面是它的选项。返回下一段的纵坐标
local function AddSection(list, y, width, section)
    local module = ns.modules[section.module]
    if not module then
        return y
    end
    local settings = ns:GetModuleSettings(module)
    local header = CreateFrame("Frame", nil, list)
    header:SetSize(width, HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, -y)
    local heading = UI:Text(header, "Heading", L[section.title])
    heading:SetPoint("BOTTOMLEFT", 12, 8)
    local enabled = UI:Checkbox(header, L["Enabled"], function(checked)
        settings.enabled = checked
    end)
    enabled:SetPoint("BOTTOMRIGHT", -12, 5)
    enabled:SetChecked(settings.enabled ~= false)
    y = y + HEADER_HEIGHT
    local function Changed()
        if module.Refresh then
            module:Refresh()
        end
    end
    for _, option in ipairs(section.options) do
        local row = OptionRow(list, y, width, ns.SettingIcon(option, 16) .. L[option.label], option)
        if option.choices then
            local items = {}
            for _, choice in ipairs(option.choices) do
                tinsert(items, { id = choice.id, label = ns.ChoiceText(choice, true) })
            end
            local dropdown = UI:Dropdown(row, items, function(id)
                settings[option.key] = id
                Changed()
            end, 160)
            dropdown:SetPoint("RIGHT", -12, 0)
            tinsert(controls, { dropdown = dropdown, settings = settings, option = option })
        else
            local check = UI:Checkbox(row, "", function(checked)
                if option.inverted then
                    settings[option.key] = not checked
                else
                    settings[option.key] = checked
                end
                Changed()
            end)
            check:SetPoint("RIGHT", -12, 0)
            tinsert(controls, { check = check, settings = settings, option = option })
        end
        y = y + ROW_HEIGHT
    end
    if section.module == "WorldMap" then
        local row = OptionRow(list, y, width, ns.SettingIcon({ icon = "INV_Misc_Spyglass_03" }, 16) .. L["World map scale"])
        local value = UI:Text(row, "Body")
        local function ShowScale()
            value:SetText(("%.1f"):format(settings.mapScale or 1))
        end
        local function Step(delta)
            settings.mapScale = math.min(1.6, math.max(0.6, floor(((settings.mapScale or 1) + delta) * 10 + 0.5) / 10))
            ShowScale()
            module:ApplyScale()
        end
        local plus = UI:Button(row, "+", 24, 20)
        plus:SetPoint("RIGHT", -12, 0)
        plus:SetScript("OnClick", function() Step(0.1) end)
        value:SetPoint("RIGHT", plus, "LEFT", -8, 0)
        local minus = UI:Button(row, "-", 24, 20)
        minus:SetPoint("RIGHT", value, "LEFT", -8, 0)
        minus:SetScript("OnClick", function() Step(-0.1) end)
        ShowScale()
        y = y + ROW_HEIGHT
    elseif section.module == "ActionBars" then
        -- 整条动作条一次升级到最高等级，以及撤销最近一次改动（自动或手动）
        local row = OptionRow(list, y, width, "")
        local undo = UI:Button(row, L["Undo last change"], 120, 22)
        undo:SetPoint("RIGHT", -12, 0)
        undo:SetScript("OnClick", function() module:Undo() end)
        local upgradeAll = UI:Button(row, L["Upgrade all now"], 140, 22)
        upgradeAll:SetPoint("RIGHT", undo, "LEFT", -6, 0)
        upgradeAll:SetScript("OnClick", function() module:UpgradeAll() end)
        y = y + ROW_HEIGHT + 4
    end
    return y + 14
end

-- 通用：界面语言（重载界面后生效）
local function AddLanguage(list, y, width)
    local header = CreateFrame("Frame", nil, list)
    header:SetSize(width, HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, -y)
    local heading = UI:Text(header, "Heading", L["Language"])
    heading:SetPoint("BOTTOMLEFT", 12, 8)
    y = y + HEADER_HEIGHT
    local option = { label = "Interface language",
        tip = "The language of WoW Handbook's own text. Game names such as items and zones follow the game client." }
    local row = OptionRow(list, y, width, ns.SettingIcon({ icon = "INV_Misc_Book_09" }, 16) .. L[option.label], option)
    local items = { { id = "auto", label = L["Game language"] } }
    for _, locale in ipairs(ns.LANGUAGES) do
        tinsert(items, { id = locale, label = LANGUAGE_NAMES[locale] })
    end
    local note = UI:Text(row, "Muted", "")
    local dropdown = UI:Dropdown(row, items, function(id)
        ns.db.language = id ~= "auto" and id or nil
        note:SetText(L["Reload the UI to apply"])
    end, 160)
    dropdown:SetPoint("RIGHT", -12, 0)
    dropdown:SetValue(ns.db.language or "auto")
    note:SetPoint("RIGHT", dropdown, "LEFT", -10, 0)
    list.languageDropdown = dropdown -- 供测试使用
    return y + ROW_HEIGHT + 14
end

-- 通用：外观——配色方案（跟随职业、网站金色或指定职业色）与主窗口背景不透明度，改动立即生效
local function AddAppearance(list, y, width)
    local Theme = ns.Theme
    local appearance = ns.db.appearance
    local header = CreateFrame("Frame", nil, list)
    header:SetSize(width, HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, -y)
    local heading = UI:Text(header, "Heading", L["Appearance"])
    heading:SetPoint("BOTTOMLEFT", 12, 8)
    y = y + HEADER_HEIGHT

    local schemeOption = { label = "Color scheme",
        tip = "The accent color of the WoW Handbook windows. It follows your class by default." }
    local row = OptionRow(list, y, width, ns.SettingIcon({ icon = "INV_Misc_Gem_Variety_02" }, 16) .. L[schemeOption.label],
        schemeOption)
    local items = {}
    for _, scheme in ipairs(Theme.SCHEMES) do
        local label
        if scheme == "class" then
            label = (L["My class (%s)"]):format(ns.ClassName(ns.PlayerClass()) or "")
        elseif scheme == "gold" then
            label = L["Handbook gold"]
        else
            label = ns.ClassName(scheme)
        end
        tinsert(items, { id = scheme, label = ("|cff%s%s|r"):format(Theme:AccentHex(scheme), label) })
    end
    local dropdown = UI:Dropdown(row, items, function(id)
        appearance.scheme = id
        ns:ApplyAppearance()
    end, 160)
    dropdown:SetPoint("RIGHT", -12, 0)
    dropdown:SetValue(appearance.scheme)
    list.schemeDropdown = dropdown -- 供测试使用
    y = y + ROW_HEIGHT

    local opacityOption = { label = "Background opacity",
        tip = "Lower it to see the game through the main window. Text, borders and menus stay solid." }
    row = OptionRow(list, y, width, ns.SettingIcon({ icon = "INV_Misc_Spyglass_03" }, 16) .. L[opacityOption.label],
        opacityOption)
    local value = UI:Text(row, "Body")
    local function ShowOpacity()
        value:SetText(("%d%%"):format(appearance.opacity))
    end
    local function Step(delta)
        appearance.opacity = math.min(Theme.MAX_OPACITY, math.max(Theme.MIN_OPACITY, appearance.opacity + delta))
        ShowOpacity()
        ns:ApplyAppearance()
    end
    local plus = UI:Button(row, "+", 24, 20)
    plus:SetPoint("RIGHT", -12, 0)
    plus:SetScript("OnClick", function() Step(10) end)
    value:SetPoint("RIGHT", plus, "LEFT", -8, 0)
    local minus = UI:Button(row, "-", 24, 20)
    minus:SetPoint("RIGHT", value, "LEFT", -8, 0)
    minus:SetScript("OnClick", function() Step(-10) end)
    ShowOpacity()
    list.opacityPlus, list.opacityMinus, list.opacityValue = plus, minus, value -- 供测试使用
    return y + ROW_HEIGHT + 14
end

-- 关于：网站与非官方声明
local function AddAbout(list, y, width)
    local about = UI:Panel(list, "raised", "lineSoft")
    about:SetPoint("TOPLEFT", 0, -y)
    about:SetSize(width, 96)
    local aboutTitle = UI:Text(about, "Heading", L["About"])
    aboutTitle:SetPoint("TOPLEFT", 14, -12)
    local version = UI:Text(about, "Muted", ns.version)
    version:SetPoint("LEFT", aboutTitle, "RIGHT", 8, 0)
    local disclaimer = "WoW Handbook is a free, unofficial fan-made addon. "
        .. "It is not affiliated with or endorsed by Blizzard Entertainment. Full guides: wowhandbook.com"
    local aboutText = UI:Text(about, "Small", L[disclaimer])
    aboutText:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -8)
    aboutText:SetPoint("RIGHT", -14, 0)
    local copy = UI:Button(about, L["Copy website link"], 150, 24, "primary")
    copy:SetPoint("BOTTOMLEFT", 14, 12)
    copy:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("home"))
    end)
    return y + 96, about
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

    -- 右侧：一个滚动区域，切换分类时重建里面的列表
    local scroll = UI:ScrollArea(p)
    scroll:SetPoint("TOPLEFT", PAD + NAV_WIDTH + 16, -64)
    scroll:SetPoint("BOTTOMRIGHT", -PAD - 10, 12)
    local width = CONTENT_WIDTH - PAD * 2 - NAV_WIDTH - 16 - 10
    local lists = {}
    local navButtons = {}

    local function Show(id)
        p.category = id
        for key, list in pairs(lists) do
            list:SetShown(key == id)
        end
        if not lists[id] then
            local list = CreateFrame("Frame", nil, scroll.child)
            list:SetPoint("TOPLEFT")
            list:SetWidth(width)
            local y = 0
            if id == "general" then
                y = AddLanguage(list, y, width)
                y = AddAppearance(list, y, width)
            end
            if id == "about" then
                local about
                y, about = AddAbout(list, y, width)
                p.about = about -- 供测试使用
            end
            for _, section in ipairs(SECTIONS) do
                if section.category == id then
                    y = AddSection(list, y, width, section)
                end
            end
            list:SetHeight(y)
            list.contentHeight = y
            lists[id] = list
            SyncControls()
        end
        scroll:SetContentHeight(lists[id].contentHeight)
        p.list, p.contentHeight = lists[id], lists[id].contentHeight -- 供测试使用
        for key, button in pairs(navButtons) do
            button:SetSelected(key == id)
        end
    end
    p.ShowCategory = Show -- 供测试使用

    -- 左侧：分类导航
    for index, category in ipairs(CATEGORIES) do
        local button = UI:Button(p, L[category.title], NAV_WIDTH, 26, "ghost")
        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT", 12, 0)
        button:SetPoint("TOPLEFT", PAD, -64 - (index - 1) * 30)
        button:SetScript("OnClick", function() Show(category.id) end)
        navButtons[category.id] = button
    end

    p.scroll = scroll
    Show("general")
    return p
end

ns.MainFrame:RegisterTab({ id = "settings", titleKey = "Settings", order = 800, create = CreatePage, onShow = SyncControls })
