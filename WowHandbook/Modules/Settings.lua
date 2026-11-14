local ADDON_NAME, ns = ...
local L = ns.L

-- 设置页：各功能开关与选项、关于（网站与非官方声明）。
-- 功能模块的整体开关在重载界面后生效；模块内的选项立即生效。
local UI
local CONTENT_WIDTH = 762 -- 主窗口内容区宽度

-- 每个功能（模块）一段：title 为功能名，note 为一句说明（设置页“功能”列表里显示）。
-- 选项带 group 时，在它前面画一个小标题，把一长串选项分成几组。
-- 每个选项：icon 为 Interface\Icons 下的图标（设置页与快捷菜单行首显示），label 为简短名称，
-- tip 为鼠标悬停时的完整说明；多选一的选项可用 icon（完整贴图路径）代替文字，悬停看 tip。
local YES = "Interface\\RaidFrame\\ReadyCheck-Ready"
local NO = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local SECTIONS = {
    { module = "Dungeons", category = "dungeons", title = "Dungeon guide",
        note = "Bosses, loot and quests for every dungeon and raid", options = {} },
    { module = "ItemSource", category = "dungeons", title = "Item sources",
        note = "Item tooltips say which dungeon boss drops the item", options = {} },
    { module = "BisGear", category = "dungeons", title = "BiS gear",
        note = "A BiS tab in the character window: the best gear for your spec at every level and where to get it", options = {} },
    { module = "MinimapButton", category = "general", title = "Minimap button",
        note = "The button on the minimap that opens WoW Handbook", options = {
        { key = "hidden", icon = "INV_Misc_Gear_01", label = "Minimap button", tip = "Show minimap button",
            inverted = true },
    } },
    { module = "Spellbook", category = "spells", title = "Spellbook",
        note = "Every spell of your class by the level you can train it", options = {
        { key = "levelUpNotice", quick = true, icon = "INV_Misc_Book_11", label = "Level-up reminder",
            tip = "Tell me which spells to train when I level up" },
    } },
    { module = "Professions", category = "professions", title = "Professions",
        note = "Profession trainers for your faction, one click to mark them on the map", options = {} },
    { module = "Talents", category = "spells", title = "Talent simulator",
        note = "Plan talent builds and follow the recommended leveling builds level by level", options = {} },
    { module = "HunterPets", category = "spells", title = "Rare pets",
        note = "Rare pets you can tame, where they are and which ones you already have", options = {
        { key = "tooltip", icon = "Ability_Hunter_BeastTaming", label = "Rare pets in tooltips",
            tip = "Show rare pets and whether you tamed them in their tooltips" },
    } },
    { module = "NativeTabs", category = "spells", title = "In the game windows",
        note = "Extra tabs in the game's own spellbook and talent windows: spells by level, professions, talent builds", options = {} },
    { module = "ActionBars", category = "spells", title = "Action bars",
        note = "Keeps your action bars up to date as you train spells", options = {
        { key = "upgradeRanks", quick = true, icon = "Spell_ChargePositive", label = "Upgrade ranks",
            tip = "When I learn a new rank, replace that spell's lower ranks on my bars" },
        { key = "placeNewSpells", quick = true, icon = "INV_Scroll_03", label = "Place new spells",
            tip = "Put newly learned spells on an empty main bar slot" },
        { key = "rangeTint", quick = true, icon = "Ability_Hunter_SniperShot", label = "Out of range in red",
            tip = "Tint the whole button red when the target is out of range" },
    } },
    { module = "InstanceTracker", category = "dungeons", title = "Dungeon helper",
        note = "A small window with dungeon quests outside instances and boss progress inside", options = {
        { key = "shown", quick = "top", icon = "INV_Misc_Note_01", label = "Quest window outside instances",
            tip = "Outside instances, show the quests for a dungeon I pick and mark where to pick them up" },
        { key = "autoShow", quick = true, icon = "INV_Misc_Bone_HumanSkull_01", label = "Auto-show in instances",
            tip = "Show boss and quest progress when I enter an instance" },
    } },
    { module = "Secrets", category = "quests", title = "Secrets helper",
        note = "Step-by-step help for long secret quest chains", options = {
        { key = "shown", quick = "top", icon = "INV_Misc_Bag_BigBagofEnchantments", label = "Secrets window",
            tip = "Show a small window that follows long secret quest chains (Cozy Sleeping Bag, Dawn Waker) and tells me the next step" },
        { key = "announce", icon = "INV_Letter_15", label = "Progress messages",
            tip = "Say in chat when a step of the chain is done and what comes next" },
    } },
    { module = "AutoQuest", category = "quests", title = "Quests",
        note = "Accept and turn in quests for you", options = {
        { key = "autoAccept", quick = "top", icon = "INV_Misc_Book_07", label = "Auto-accept",
            tip = "Accept quests automatically when I talk to an NPC (hold Shift to skip)" },
        { key = "autoTurnIn", quick = "top", icon = "INV_Letter_03", label = "Auto turn-in",
            tip = "Turn in completed quests automatically when I talk to an NPC (hold Shift to skip)" },
        { key = "rewardMode", quick = true, icon = "INV_Misc_Bag_10", label = "Reward", choices = {
            { id = "manual", label = "Manual", tip = "I choose the reward myself" },
            { id = "usable", label = "Auto", tip = "Usable first, then the most valuable" },
        } },
        -- 不存设置：直接读写客户端变量（get / set），显示玩家实际的状态
        { key = "questItemGlow", quick = true, icon = "Spell_Holy_MindVision", label = "Quest item glow",
            tip = "Make quest items and the monsters that drop them glow (takes effect after /reload)",
            get = function() return ns.modules.AutoQuest.QuestItemGlow() end,
            set = function(on) ns.modules.AutoQuest.SetQuestItemGlow(on) end },
    } },
    { module = "Vendor", category = "general", title = "Vendor",
        note = "Vendor chores done for you", options = {
        { key = "sellJunk", quick = "top", icon = "INV_Misc_Coin_01", label = "Sell gray items",
            tip = "Sell gray items automatically when I open a vendor" },
    } },
    { module = "AuctionHouse", category = "general", title = "Auction house",
        note = "Remembers auction prices and adds a scan tab to the auction house", options = {
        { key = "recordSearches", quick = true, icon = "INV_Misc_Coin_02", label = "Record searches",
            tip = "Remember the prices I see when I search the auction house" },
        { key = "tooltip", quick = true, icon = "INV_Misc_Coin_03", label = "Prices in tooltips",
            tip = "Show the recorded auction price in item tooltips" },
        { key = "useAuctionator", quick = true, icon = "INV_Misc_Coin_04", label = "Use Auctionator prices",
            tip = "Use Auctionator's prices when newer and let it do the scanning (hides my scan button)",
            set = function(on) ns.modules.AuctionHouse.SetUseAuctionator(on) end },
    } },
    { module = "MerchantCrates", category = "professions", title = "Waylaid crates",
        note = "Shows what each waylaid crate takes and what it costs to fill at auction prices", options = {} },
    { module = "CraftingCost", category = "professions", title = "Crafting cost",
        note = "Material cost, auction price, profit and margin for the recipe selected in the professions window", options = {} },
    { module = "Enchanting", category = "professions", title = "Enchant all",
        note = "Enchant several times in a row from the professions window", options = {
        { key = "autoReplace", quick = true, icon = "Trade_Engraving", label = "Replace enchants without asking",
            tip = "When enchanting from the professions window, confirm replacing an existing enchant automatically" },
    } },
    { module = "InstanceMap", category = "map", title = "Dungeon maps",
        note = "Dungeon maps on the world map while you are inside an instance", options = {} },
    { module = "WorldMap", category = "map", title = "World map",
        note = "Zone levels, flight paths, trainers, gathering nodes and more on the world map", options = {
        { key = "flightPins", group = "Pins", quick = true, icon = "Ability_Mount_Wyvern_01", label = "Flight paths",
            tip = "Show flight paths; ones not unlocked yet are grayed out" },
        { key = "dungeonPins", quick = true, icon = "Spell_Arcane_PortalIronForge", label = "Dungeon entrances",
            tip = "Show dungeon and raid entrances" },
        { key = "spiritHealers", quick = true, icon = "Spell_Holy_GuardianSpirit", label = "Spirit healers", choices = {
            { id = "dead", label = "When dead", tip = "When I am dead" },
            { id = "always", icon = YES, tip = "Always" },
            { id = "off", icon = NO, tip = "Never" },
        } },
        { key = "graveyardAreas", icon = "Spell_Holy_Resurrection", label = "Resurrection areas",
            tip = "Along with spirit healers, show the borders between their areas: die inside one and you return to its healer" },
        { key = "classTrainerPins", quick = true, icon = "INV_Misc_Book_04", label = "Class trainers",
            tip = "Show my class trainers on the map, with how many spells I can train now" },
        { key = "trainerPins", quick = true, icon = "INV_Misc_Book_08", label = "Profession trainers", choices = {
            { id = "mine", label = "Mine", tip = "My professions" },
            { id = "all", label = "All", tip = "All professions" },
            { id = "off", icon = NO, tip = "Never" },
        } },
        { key = "transmogPins", quick = true, icon = "INV_Shirt_White_01", label = "Transmogrifiers",
            tip = "Show transmogrifiers on the map" },
        { key = "transportPins", quick = true, icon = "INV_Misc_Map02", label = "Zeppelins and boats",
            tip = "Show zeppelin towers and boat landings on the map, with where they go" },
        { key = "pathPins", quick = true, icon = "INV_Misc_Map_01", label = "Zone paths",
            tip = "Show the paths between zones, and the entrances to capitals, as arrows on the map" },
        { key = "herbPins", group = "Gathering", quick = "top", icon = "Trade_Herbalism", label = "Herbs", choices = {
            { id = "auto", label = "Auto", tip = "When I know the profession" },
            { id = "always", icon = YES, tip = "Always" },
            { id = "off", icon = NO, tip = "Never" },
        } },
        { key = "orePins", quick = "top", icon = "Trade_Mining", label = "Mining nodes", choices = {
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
        { key = "levelLabel", group = "Display", icon = "Ability_Hunter_Pathfinding", label = "Zone levels",
            tip = "Show zone level ranges under the zone name" },
        { key = "revealMap", icon = "INV_Misc_Map_01", label = "Full map",
            tip = "Show the full map, including areas not explored yet" },
    } },
}

-- 设置定义共享给小地图按钮右键的快捷菜单：标了 quick 的选项会出现在菜单里。
-- quick = "top" 的直接列在菜单顶部（最常切换的几项），quick = true 的收在所属分类的折叠分组里
ns.SettingsSections = SECTIONS

-- 设置页的控件：{ check / dropdown, settings, option }，页面显示时按存档刷新（快捷菜单里改过的也能反映出来）
local controls = {}
-- 功能的整体开关重载界面后才生效：记下登录时各功能是否启用，开关与它不一致的标出“重载后生效”
local loginEnabled = {}
local featureRows = {} -- [模块名] = { check, pending, settings }
local blocks = {}      -- [模块名] = 这个功能的选项段（功能关掉后变淡）
local reloadButton

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
-- 带 get 的选项不存在设置里，取它自己报告的实际状态
function ns.SettingValue(settings, option)
    if option.get then
        return option.get()
    elseif option.choices then
        return settings[option.key] or option.choices[1].id
    elseif option.inverted then
        return settings[option.key] ~= true
    end
    return settings[option.key] ~= false
end

-- 改一个选项并让模块立即生效（设置页与快捷菜单共用）
function ns.SetSetting(module, option, value)
    if option.set then
        option.set(value)
        return
    end
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

-- 功能列表：勾选状态、“重载后生效”标记、关掉的功能的选项段变淡；有开关在等重载时突出“重载界面”按钮
local function SyncFeatures()
    local anyPending = false
    for name, row in pairs(featureRows) do
        local enabled = row.settings.enabled ~= false
        local pending = loginEnabled[name] ~= nil and enabled ~= loginEnabled[name]
        anyPending = anyPending or pending
        row.check:SetChecked(enabled)
        row.pending:SetShown(pending)
        if blocks[name] then
            blocks[name]:SetAlpha(enabled and 1 or 0.45)
        end
    end
    if reloadButton then
        reloadButton:SetSelected(anyPending)
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
    SyncFeatures()
end

-- 设置页布局：左侧分类导航，右侧是这一类的设置列表。
-- 每一类先是“功能”列表：这一类的每个功能一行（名称、一句说明、整体开关），开关集中在一处；
-- 下面是有选项的功能各一段：标题行（功能名），每个选项一行（左侧图标与名称，右侧勾选框、下拉框或滑条），
-- 行与行之间细分隔线。
local CATEGORIES = {
    { id = "general", title = "General" },
    { id = "dungeons", title = "Dungeons" },
    { id = "quests", title = "Quests" },
    { id = "spells", title = "Spells" },
    { id = "professions", title = "Professions" },
    { id = "map", title = "Map" },
    { id = "about", title = "About" },
}
ns.SettingsCategories = CATEGORIES -- 快捷菜单按同样的分类折叠
local NAV_WIDTH, ROW_HEIGHT, HEADER_HEIGHT = 128, 30, 34
local SUBHEADING_HEIGHT, SLIDER_WIDTH = 26, 140
local LANGUAGE_NAMES = { enUS = "English", zhCN = "简体中文" } -- 语言名用各自的语言写，不翻译
local WINDOW_SIZES = { 80, 90, 100, 110, 120, 130 } -- 主窗口大小（百分数）

-- 一行：左侧图标与名称（悬停看完整说明），底部细分隔线。返回行框架与名称文字
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
    local line = ns.Theme:Fill(row, "lineSoft", "BORDER")
    line:SetPoint("BOTTOMLEFT", 12, 0)
    line:SetPoint("BOTTOMRIGHT", -12, 0)
    line:SetHeight(1)
    return row, text
end

local function Heading(parent, y, width, text)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(width, HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, -y)
    local heading = UI:Text(header, "Heading", text)
    heading:SetPoint("BOTTOMLEFT", 12, 8)
    return header
end

-- “功能”列表：这一类的每个功能一行，名称后面是一句说明，右侧是整体开关。返回下一段的纵坐标
local function AddFeatures(list, y, width, category)
    local sections = {}
    for _, section in ipairs(SECTIONS) do
        if section.category == category and ns.modules[section.module] then
            tinsert(sections, section)
        end
    end
    if #sections == 0 then
        return y
    end
    Heading(list, y, width, L["Features"])
    y = y + HEADER_HEIGHT
    for _, section in ipairs(sections) do
        local module = ns.modules[section.module]
        local settings = ns:GetModuleSettings(module)
        local row, text = OptionRow(list, y, width, L[section.title], { label = section.title, tip = section.note })
        local check = UI:Checkbox(row, "", function(checked)
            settings.enabled = checked
            SyncFeatures()
        end)
        check:SetPoint("RIGHT", -12, 0)
        local pending = UI:Text(row, "Accent", L["Reload the UI to apply"])
        pending:SetPoint("RIGHT", check, "LEFT", -10, 0)
        pending:Hide()
        local note = UI:Text(row, "Muted", L[section.note])
        note:SetPoint("LEFT", text, "RIGHT", 10, 0)
        note:SetPoint("RIGHT", row, "RIGHT", -48, 0)
        note:SetJustifyH("LEFT")
        note:SetWordWrap(false)
        featureRows[section.module] = { check = check, pending = pending, settings = settings }
        y = y + ROW_HEIGHT
    end
    return y + 14
end

-- 一个功能的选项段：功能名，下面是它的选项（没有选项的功能只在“功能”列表里）。返回下一段的纵坐标
local function AddSection(list, y, width, section)
    local module = ns.modules[section.module]
    if not module or #section.options == 0 then
        return y
    end
    local settings = ns:GetModuleSettings(module)
    local block = CreateFrame("Frame", nil, list)
    block:SetPoint("TOPLEFT", 0, -y)
    block:SetWidth(width)
    blocks[section.module] = block
    Heading(block, 0, width, L[section.title])
    local top = y
    y = HEADER_HEIGHT -- 段内的纵坐标
    local function Changed()
        if module.Refresh then
            module:Refresh()
        end
    end
    for _, option in ipairs(section.options) do
        if option.group then
            local sub = UI:Text(block, "Accent", L[option.group])
            sub:SetPoint("TOPLEFT", 12, -y - 9)
            y = y + SUBHEADING_HEIGHT
        end
        local row = OptionRow(block, y, width, ns.SettingIcon(option, 16) .. L[option.label], option)
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
                if option.set then
                    option.set(checked)
                    return
                end
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
        -- 大地图缩放：0.6–1.6，每格 0.1
        local row = OptionRow(block, y, width, ns.SettingIcon({ icon = "INV_Misc_Spyglass_03" }, 16) .. L["World map scale"])
        local value = UI:Text(row, "Body")
        local function ShowScale()
            value:SetText(("%.1f"):format(settings.mapScale or 1))
        end
        local slider = UI:Slider(row, SLIDER_WIDTH, function(step)
            settings.mapScale = step / 10
            ShowScale()
            module:ApplyScale()
        end)
        slider:SetRange(6, 16)
        slider:SetLevel(floor((settings.mapScale or 1) * 10 + 0.5))
        slider:SetPoint("RIGHT", -12, 0)
        value:SetPoint("RIGHT", slider, "LEFT", -10, 0)
        ShowScale()
        block.mapScaleSlider = slider -- 供测试使用
        y = y + ROW_HEIGHT
    elseif section.module == "ActionBars" then
        -- 整条动作条一次升级到最高等级，以及撤销最近一次改动（自动或手动）
        local row = OptionRow(block, y, width, "")
        local undo = UI:Button(row, L["Undo last change"], 120, 22)
        undo:SetPoint("RIGHT", -12, 0)
        undo:SetScript("OnClick", function() module:Undo() end)
        local upgradeAll = UI:Button(row, L["Upgrade all now"], 140, 22)
        upgradeAll:SetPoint("RIGHT", undo, "LEFT", -6, 0)
        upgradeAll:SetScript("OnClick", function() module:UpgradeAll() end)
        y = y + ROW_HEIGHT + 4
    end
    block:SetHeight(y)
    return top + y + 14
end

-- 通用：界面语言（重载界面后生效）
local function AddLanguage(list, y, width)
    Heading(list, y, width, L["Language"])
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
    Heading(list, y, width, L["Appearance"])
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

    -- 背景不透明度：30%–100%，每格 10%
    local opacityOption = { label = "Background opacity",
        tip = "Lower it to see the game through the main window. Text, borders and menus stay solid." }
    row = OptionRow(list, y, width, ns.SettingIcon({ icon = "INV_Misc_Spyglass_03" }, 16) .. L[opacityOption.label],
        opacityOption)
    local value = UI:Text(row, "Body")
    local function ShowOpacity()
        value:SetText(("%d%%"):format(appearance.opacity))
    end
    local slider = UI:Slider(row, SLIDER_WIDTH, function(step)
        appearance.opacity = math.min(Theme.MAX_OPACITY, math.max(Theme.MIN_OPACITY, step * 10))
        ShowOpacity()
        ns:ApplyAppearance()
    end)
    slider:SetRange(Theme.MIN_OPACITY / 10, Theme.MAX_OPACITY / 10)
    slider:SetLevel(floor(appearance.opacity / 10 + 0.5))
    slider:SetPoint("RIGHT", -12, 0)
    value:SetPoint("RIGHT", slider, "LEFT", -10, 0)
    ShowOpacity()
    list.opacitySlider, list.opacityValue = slider, value -- 供测试使用
    y = y + ROW_HEIGHT

    -- 窗口大小：用下拉框而不是滑条（窗口一缩放，正在拖的滑条会跟着跑）
    local sizeOption = { label = "Window size", tip = "Make the main window larger or smaller." }
    row = OptionRow(list, y, width, ns.SettingIcon({ icon = "INV_Misc_Spyglass_02" }, 16) .. L[sizeOption.label], sizeOption)
    local sizes = {}
    for _, percent in ipairs(WINDOW_SIZES) do
        tinsert(sizes, { id = percent, label = percent .. "%" })
    end
    local size = UI:Dropdown(row, sizes, function(id)
        appearance.scale = id
        ns:ApplyAppearance()
    end, 160)
    size:SetPoint("RIGHT", -12, 0)
    size:SetValue(appearance.scale or 100)
    list.sizeDropdown = size -- 供测试使用
    y = y + ROW_HEIGHT

    -- 窗口位置：拖动标题栏后会记住，这里可以放回屏幕中央
    local positionOption = { label = "Window position",
        tip = "The main window stays where you drag it. Reset it to move it back to the center of the screen." }
    row = OptionRow(list, y, width, ns.SettingIcon({ icon = "INV_Misc_Map_01" }, 16) .. L[positionOption.label],
        positionOption)
    local reset = UI:Button(row, L["Reset position"], 160, 22)
    reset:SetPoint("RIGHT", -12, 0)
    reset:SetScript("OnClick", function()
        ns.MainFrame:ResetPosition()
    end)
    list.resetPosition = reset -- 供测试使用
    return y + ROW_HEIGHT + 14
end

-- 关于：插件与作者信息（版本号只在这里显示，不放主窗口标题栏）、非官方声明与网站链接
local ABOUT_ROW = 22
local function AddAbout(list, y, width)
    local about = UI:Panel(list, "raised", "lineSoft")
    about:SetPoint("TOPLEFT", 0, -y)
    local aboutTitle = UI:Text(about, "Title", L["WoW Handbook"])
    aboutTitle:SetPoint("TOPLEFT", 14, -14)
    local intro = UI:Text(about, "Small",
        L["A free companion for World of Warcraft: Forever: dungeons, quests, talents, spells and trainers, all inside the game."])
    intro:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -8)
    intro:SetPoint("RIGHT", -14, 0)

    -- 信息行：左侧名称，右侧内容
    local rows = {
        { "Version", ns.version },
        { "Author", ns.author },
        { "Organization", ns.organization },
        { "Game", L["World of Warcraft: Forever"] .. " 1.60.x" },
        { "Website", "wowhandbook.com" },
        { "License", "GPL-3.0" },
    }
    local top = 74
    about.rows = {} -- 供测试使用
    for index, row in ipairs(rows) do
        local label = UI:Text(about, "Muted", L[row[1]])
        label:SetPoint("TOPLEFT", 14, -top - (index - 1) * ABOUT_ROW)
        local value = UI:Text(about, "Body", row[2])
        value:SetPoint("TOPLEFT", 130, -top - (index - 1) * ABOUT_ROW)
        about.rows[row[1]] = value
    end
    local bottom = top + #rows * ABOUT_ROW

    local line = ns.Theme:Fill(about, "lineSoft", "ARTWORK")
    line:SetPoint("TOPLEFT", 14, -bottom - 6)
    line:SetPoint("TOPRIGHT", -14, -bottom - 6)
    line:SetHeight(1)
    local disclaimer = "WoW Handbook is a free, unofficial fan-made addon. "
        .. "It is not affiliated with or endorsed by Blizzard Entertainment. Full guides: wowhandbook.com"
    local aboutText = UI:Text(about, "Small", L[disclaimer])
    aboutText:SetPoint("TOPLEFT", 14, -bottom - 18)
    aboutText:SetPoint("RIGHT", -14, 0)
    local copy = UI:Button(about, L["Copy website link"], 150, 24, "primary")
    copy:SetPoint("BOTTOMLEFT", 14, 14)
    copy:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("home"))
    end)
    local height = bottom + 18 + 40 + 24 + 22
    about:SetSize(width, height)
    return y + height, about
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
    reloadButton = reload
    for _, section in ipairs(SECTIONS) do
        local module = ns.modules[section.module]
        if module and loginEnabled[section.module] == nil then
            loginEnabled[section.module] = ns:GetModuleSettings(module).enabled ~= false
        end
    end

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
            y = AddFeatures(list, y, width, id)
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
    p.featureRows, p.blocks = featureRows, blocks -- 供测试使用

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

ns.MainFrame:RegisterTab({ id = "settings", titleKey = "Settings", order = 800, bottom = true, create = CreatePage,
    onShow = SyncControls })
