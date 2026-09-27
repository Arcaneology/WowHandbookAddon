local ADDON_NAME, ns = ...
local L = ns.L

-- 按等级的技能书（F4）：本职业全部可训练技能按学习等级展开，标出已学、现在可学、还没到等级；
-- 升级时在聊天框提示这一级可以学什么。技能数据来自网站（Forever 客户端导出），已学情况读玩家技能书。
local Module = ns:NewModule("Spellbook", { levelUpNotice = true })
local UI

local page

-- 网站数据的种族名 -> 客户端 raceFile
local RACE_TOKENS = { ["Night Elf"] = "NightElf", Undead = "Scourge" }

local function RaceAllowed(races)
    if not races then
        return true
    end
    local _, raceFile = UnitRace("player")
    for _, race in ipairs(races) do
        if (RACE_TOKENS[race] or race:gsub(" ", "")) == raceFile then
            return true
        end
    end
    return false
end

local function ClassSpells()
    return ns.Data.spells[ns.PlayerClass() or ""] or {}
end

-- 恶魔技能 ID -> { pet = 恶魔英文名, key = 技能英文名小写, rank = 等级数字 }（按需建一次）
local petSpellIndex
local function PetSpellIndex()
    if not petSpellIndex then
        petSpellIndex = {}
        for _, spell in ipairs(ns.Data.spells.warlock or {}) do
            if spell.pet then
                for _, rank in ipairs(spell.ranks) do
                    if rank.id then
                        petSpellIndex[rank.id] = { pet = spell.pet.enUS, key = (spell.name.enUS or ""):lower(),
                            rank = ns.RankNumber(rank.rank) }
                    end
                end
            end
        end
    end
    return petSpellIndex
end

-- 读取当前召唤出的恶魔学过的技能，按恶魔记进角色存档：
-- charDB.petSpells = { [恶魔英文名] = { [技能英文名小写] = 最高等级 } }。
-- 按技能 ID 识别恶魔与等级，不依赖技能名后的等级文字；这样换了恶魔、收起恶魔后仍然知道每只恶魔学过什么。
local function RecordPetSpells()
    if ns.PlayerClass() ~= "warlock" or not ns.charDB or not UnitExists("pet") or not C_SpellBook.HasPetSpells then
        return
    end
    local count = C_SpellBook.HasPetSpells()
    if not count or count == 0 then
        return
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1
    local index = PetSpellIndex()
    local learned, pet = {}, nil
    for slot = 1, count do
        local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
        local info = item and item.spellID and index[item.spellID]
        if info then
            pet = info.pet
            learned[info.key] = math.max(learned[info.key] or 0, info.rank)
        end
    end
    if pet then
        ns.charDB.petSpells = ns.charDB.petSpells or {}
        ns.charDB.petSpells[pet] = learned
    end
end
Module.RecordPetSpells = RecordPetSpells

-- 召唤或更换恶魔后记录它的技能：恶魔技能书就绪有延迟，统一 1 秒后读，期间重复事件合并。
-- 技能书页与未学技能面板共用这一个处理函数（同一函数重复注册只算一次）。
local petPending = false
function Module.OnPetChanged(_, unit)
    if unit and unit ~= "player" then
        return
    end
    if petPending then
        return
    end
    petPending = true
    C_Timer.After(1, function()
        petPending = false
        RecordPetSpells()
    end)
end

-- 每个技能的每个等级展开成一行：{ spell, rank, rankNumber, level, status }
-- status：known（已学）、ready（现在可学）、later（还没到等级）；恶魔技能另有
-- innate（召唤恶魔时自带）、book（到等级了，可向商人买魔典）、unchecked（这只恶魔还没召唤过，不知道学没学）
local function Rows(petsOnly)
    local rows = {}
    local known = ns.KnownSpells()
    if petsOnly then
        RecordPetSpells()
    end
    local petSpells = ns.charDB and ns.charDB.petSpells or {}
    local level = ns.PlayerLevel()
    for _, spell in ipairs(ClassSpells()) do
        if spell.pet then
            if petsOnly then
                local petName = ns.Name(spell.pet)
                local record = petSpells[spell.pet.enUS]
                local learned = record and record[(spell.name.enUS or ""):lower()]
                for _, rank in ipairs(spell.ranks) do
                    local rankNumber = ns.RankNumber(rank.rank)
                    local status
                    if rank.level > level then
                        status = "later"
                    elseif rank.innate then
                        status = "innate"
                    elseif not record then
                        status = "unchecked"
                    elseif learned and learned >= rankNumber then
                        status = "known"
                    else
                        status = "book"
                    end
                    tinsert(rows, { spell = spell, rank = rank.rank, rankNumber = rankNumber, level = rank.level,
                        status = status, book = rank.book, price = rank.price, pet = petName, id = rank.id })
                end
            end
        elseif not petsOnly and RaceAllowed(spell.races) then
            local entry = known[(ns.Name(spell.name) or ""):lower()]
            for _, rank in ipairs(spell.ranks) do
                local rankNumber = ns.RankNumber(rank.rank)
                local status
                if entry and entry.best >= rankNumber then
                    status = "known"
                elseif rank.level <= level then
                    status = "ready"
                else
                    status = "later"
                end
                tinsert(rows, { spell = spell, rank = rank.rank, rankNumber = rankNumber, level = rank.level, status = status,
                    id = rank.id })
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.pet ~= b.pet then
            return (a.pet or "") < (b.pet or "")
        end
        if a.level ~= b.level then
            return a.level < b.level
        end
        return (ns.Name(a.spell.name) or "") < (ns.Name(b.spell.name) or "")
    end)
    return rows
end

Module.Rows = Rows -- 未学技能面板共用

local STATUS = {
    known = "|cff46bf72%s|r",
    innate = "|cff46bf72%s|r",
    ready = "|cffe0b458%s|r",
    book = "|cffe0b458%s|r",
    unchecked = "|cff8a8374%s|r",
    later = "|cff8a8374%s|r",
}
local STATUS_LABEL = { known = "Learned", innate = "Innate", ready = "Train now", book = "Buy the grimoire",
    unchecked = "Summon this demon once to check", later = "Not yet" }

local function Icon(spell)
    return spell.icon and ("|TInterface\\Icons\\%s:16:16:0:0:64:64:5:59:5:59|t "):format(spell.icon) or ""
end

--------------------------------------------------------------------------------
-- 表格：职业技能一张（学习等级 | 技能 | 技能等级 | 状态），恶魔技能一张（另加恶魔、魔典两列）。
-- 同一学习等级只在第一行写等级，隔行底色；整行悬停显示游戏的技能提示，指向魔典一格显示物品提示。
--------------------------------------------------------------------------------

local ROW_HEIGHT = 22
local CELLS = { "level", "spell", "rank", "pet", "status", "book" }
local COLUMNS = {
    class = {
        { key = "level", label = "Learn at", width = 70 },
        { key = "spell", label = "Spell", width = 300 },
        { key = "rank", label = "Rank", width = 90 },
        { key = "status", label = "Status" },
    },
    pet = {
        { key = "level", label = "Learn at", width = 70 },
        { key = "spell", label = "Spell", width = 190 },
        { key = "rank", label = "Rank", width = 70 },
        { key = "pet", label = "Demon", width = 90 },
        { key = "status", label = "Status", width = 150 },
        { key = "book", label = "Grimoire" },
    },
}

local function ShowRowTooltip(row)
    row.highlight:Show()
    if not row.entry then
        return
    end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if row.entry.id then
        GameTooltip:SetSpellByID(row.entry.id)
    else
        GameTooltip:SetText(ns.Name(row.entry.spell.name) or "?", 1, 0.82, 0)
    end
    GameTooltip:AddLine((L["Learn at level %d"]):format(row.entry.level), 1, 1, 1)
    GameTooltip:Show()
end

local function HideRowTooltip(row)
    row.highlight:Hide()
    GameTooltip_Hide()
end

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(unpack(ns.Theme.colors.stripe))
    row.highlight = row:CreateTexture(nil, "BORDER")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(unpack(ns.Theme.colors.raised))
    row.highlight:Hide()
    row.cells = {}
    for _, key in ipairs(CELLS) do
        local cell = UI:Text(row, "Small")
        cell:SetJustifyH("LEFT")
        cell:SetWordWrap(false)
        row.cells[key] = cell
    end
    -- 魔典一格：单独的悬停区域，显示魔典物品提示
    row.bookHover = CreateFrame("Button", nil, row)
    row.bookHover:SetHeight(ROW_HEIGHT)
    row.bookHover:SetScript("OnEnter", function(self)
        row.highlight:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(row.entry.book)
        GameTooltip:Show()
    end)
    row.bookHover:SetScript("OnLeave", function()
        HideRowTooltip(row)
    end)
    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)
    return row
end

-- 按列宽摆放单元格；没有宽度的列占到行尾
local function LayoutRow(row, columns)
    for _, cell in pairs(row.cells) do
        cell:Hide()
    end
    local x = 8
    for index, column in ipairs(columns) do
        local cell = row.cells[column.key]
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", x, 0)
        if column.width and index < #columns then
            cell:SetWidth(column.width - 8)
            x = x + column.width
        else
            cell:SetPoint("RIGHT", -8, 0)
        end
        cell:Show()
    end
    row.bookHover:Hide()
    if row.entry and row.entry.book and row.cells.book:IsShown() then
        row.bookHover:ClearAllPoints()
        row.bookHover:SetPoint("LEFT", x, 0)
        row.bookHover:SetPoint("RIGHT", 0, 0)
        row.bookHover:Show()
    end
end

local function Table(p)
    local rows, used, y = p.tableRows, 0, 0
    local child = p.detail.child
    local t = {}

    local function NextRow()
        used = used + 1
        local row = rows[used] or CreateRow(child)
        rows[used] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
        row:Show()
        y = y + ROW_HEIGHT
        return row
    end

    function t:Header(columns)
        local row = NextRow()
        row.entry = false
        row:EnableMouse(false)
        row.stripe:Hide()
        for _, column in ipairs(columns) do
            row.cells[column.key]:SetText(("|cffe0b458%s|r"):format(L[column.label]))
        end
        LayoutRow(row, columns)
    end

    function t:Row(columns, data, cells, striped)
        local row = NextRow()
        row.entry = data
        row:EnableMouse(true)
        row.stripe:SetShown(striped)
        for _, column in ipairs(columns) do
            row.cells[column.key]:SetText(cells[column.key] or "")
        end
        LayoutRow(row, columns)
    end

    function t:Text(fontString, gapBefore, gapAfter)
        y = y + (gapBefore or 0)
        fontString:ClearAllPoints()
        fontString:SetPoint("TOPLEFT", 4, -y)
        fontString:SetPoint("RIGHT", child, "RIGHT", -4, 0)
        fontString:Show()
        y = y + fontString:GetStringHeight() + (gapAfter or 0)
    end

    function t:Finish()
        for index = used + 1, #rows do
            rows[index]:Hide()
        end
        return y + 8
    end
    return t
end

-- 学习等级一格：同一等级只在第一行写，你当前的等级用金色
local function LevelCell(row, previous, playerLevel)
    if previous and previous.level == row.level and previous.pet == row.pet then
        return ""
    end
    local color = row.level == playerLevel and "e0b458" or "d9ccb0"
    return ("|cff%s%d|r"):format(color, row.level)
end

local function RankCell(row)
    return row.rank ~= "" and (L["Rank %d"]):format(row.rankNumber) or "-"
end

local function Refresh()
    if not (page and page:IsShown()) then
        return
    end
    local rows = Rows()
    local level = ns.PlayerLevel()
    local ready, upcomingLevel = 0, nil
    for _, row in ipairs(rows) do
        if row.status == "ready" then
            ready = ready + 1
        elseif row.status == "later" and not upcomingLevel then
            upcomingLevel = row.level
        end
    end
    page.summary:SetText((L["Level %d · %d ready to train · next new spells at level %s"]):format(
        level, ready, upcomingLevel and tostring(upcomingLevel) or "-"))

    local t = Table(page)
    page.demonTitle:Hide()
    page.demonNote:Hide()
    if #rows == 0 then
        page.empty:SetText(L["No spell data for your class yet."])
        t:Text(page.empty, 4, 0)
        page.detail:SetContentHeight(t:Finish())
        return
    end
    page.empty:Hide()

    t:Header(COLUMNS.class)
    local previous, stripe = nil, false
    for _, row in ipairs(rows) do
        if not (previous and previous.level == row.level) then
            stripe = not stripe
        end
        t:Row(COLUMNS.class, row, {
            level = LevelCell(row, previous, level),
            spell = Icon(row.spell) .. (ns.Name(row.spell.name) or "?"),
            rank = RankCell(row),
            status = STATUS[row.status]:format(L[STATUS_LABEL[row.status]]),
        }, stripe)
        previous = row
    end

    -- 恶魔技能（术士）：按恶魔分组；每一级标出自带或对应的魔典
    local petRows = Rows(true)
    if #petRows > 0 then
        t:Text(page.demonTitle, 18, 4)
        t:Text(page.demonNote, 0, 8)
        t:Header(COLUMNS.pet)
        previous, stripe = nil, false
        for _, row in ipairs(petRows) do
            if not (previous and previous.level == row.level and previous.pet == row.pet) then
                stripe = not stripe
            end
            local book = ""
            if row.book then
                local price = ns.Money(row.price)
                book = ns.ItemLink(row.book) .. (price and ("  " .. price) or "")
            end
            t:Row(COLUMNS.pet, row, {
                level = LevelCell(row, previous, level),
                spell = Icon(row.spell) .. (ns.Name(row.spell.name) or "?"),
                rank = RankCell(row),
                pet = (previous and previous.pet == row.pet) and "" or (row.pet or "?"),
                status = STATUS[row.status]:format(L[STATUS_LABEL[row.status]]),
                book = book,
            }, stripe)
            previous = row
        end
    end
    page.detail:SetContentHeight(t:Finish())
end

local function CreatePage(parent)
    UI = ns.UI
    local p = CreateFrame("Frame", nil, parent)
    page = p
    Module.page = p -- 供测试使用
    local PAD = 20
    local _, className = UnitClass("player")

    local title = UI:Text(p, "Title", (L["Spells by level · %s"]):format(className or ""))
    title:SetPoint("TOPLEFT", PAD, -18)
    p.summary = UI:Text(p, "Muted")
    p.summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

    local siteButton = UI:Button(p, L["Full spellbook on the website"], 190, 24)
    siteButton:SetPoint("TOPRIGHT", -PAD, -20)
    siteButton:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("spellbook", ns.PlayerClass()))
    end)

    local panel = UI:Panel(p, "panel", "lineSoft")
    panel:SetPoint("TOPLEFT", PAD, -66)
    panel:SetPoint("BOTTOMRIGHT", -PAD, 20)
    local detail = UI:ScrollArea(panel)
    detail:SetPoint("TOPLEFT", 12, -10)
    detail:SetPoint("BOTTOMRIGHT", -18, 10)
    p.detail = detail
    p.tableRows = {}
    p.empty = UI:Text(detail.child, "Muted")
    p.demonTitle = UI:Text(detail.child, "Title", L["Demon abilities"])
    local note = "Rank 1 of some abilities comes with the demon; "
        .. "every other rank is learned from a grimoire sold by demon trainers."
    p.demonNote = UI:Text(detail.child, "Muted", L[note])
    p.demonNote:SetJustifyH("LEFT")

    p:SetScript("OnShow", Refresh)
    return p
end

-- 首页用的摘要：现在可学的技能、可买的魔典、接下来几级新开放的技能
-- 返回 { ready = { {name, icon, rank, id} }, grimoires = { {name, icon, pet, book, price, rank, id} },
--        upcoming = { [等级] = { 技能名… } } }（upcoming 只含之后 levelsAhead 级以内）
function Module.Summary(levelsAhead)
    local level = ns.PlayerLevel()
    local summary = { ready = {}, grimoires = {}, upcoming = {} }
    for _, row in ipairs(Rows(false)) do
        local name = ns.Name(row.spell.name) or "?"
        if row.status == "ready" then
            tinsert(summary.ready, { name = name, icon = row.spell.icon, rank = row.rank, id = row.id })
        elseif row.status == "later" and row.level <= level + (levelsAhead or 4) then
            summary.upcoming[row.level] = summary.upcoming[row.level] or {}
            tinsert(summary.upcoming[row.level], name .. (row.rank ~= "" and (" " .. row.rankNumber) or ""))
        end
    end
    for _, row in ipairs(Rows(true)) do
        if row.status == "book" and row.book then
            tinsert(summary.grimoires, { name = ns.Name(row.spell.name) or "?", icon = row.spell.icon, pet = row.pet,
                book = row.book, price = row.price, rank = row.rankNumber, id = row.id })
        end
    end
    return summary
end

-- 升级提示：列出这一级新开放的技能
local function OnLevelUp(_, newLevel)
    local settings = ns:GetModuleSettings(Module)
    if not settings.levelUpNotice then
        return
    end
    local names = {}
    local grimoires = {}
    for _, spell in ipairs(ClassSpells()) do
        if spell.pet or RaceAllowed(spell.races) then
            for _, rank in ipairs(spell.ranks) do
                if rank.level == newLevel then
                    local text = (ns.Name(spell.name) or "?") .. (rank.rank ~= "" and (" " .. ns.RankNumber(rank.rank)) or "")
                    if spell.pet then
                        if rank.book then
                            tinsert(grimoires, ("%s (%s)"):format(text, ns.Name(spell.pet) or "?"))
                        end
                    else
                        tinsert(names, text)
                    end
                end
            end
        end
    end
    if #grimoires > 0 then
        ns:Print(L["New demon grimoires available: %s."], table.concat(grimoires, ", "))
    end
    if #names > 0 then
        ns:Print(L["Level %d: new spells to train — %s. Open /wh for your spellbook."], newLevel, table.concat(names, ", "))
    end
end

function Module:OnEnable()
    ns.MainFrame:RegisterTab({ id = "spellbook", title = L["Spellbook"], order = 20, create = CreatePage, onShow = Refresh })
    ns:RegisterEvent("PLAYER_LEVEL_UP", OnLevelUp)
    -- 页面打开期间，技能变化、魔典物品信息到达时刷新（节流 0.3 秒，期间重复事件合并）
    local pending = false
    local function OnChange()
        if pending or not (page and page:IsShown()) then
            return
        end
        pending = true
        C_Timer.After(0.3, function()
            pending = false
            Refresh()
        end)
    end
    ns:RegisterEvent("SPELLS_CHANGED", function()
        ns.InvalidateKnownSpells()
        OnChange()
    end)
    ns:RegisterEvent("GET_ITEM_INFO_RECEIVED", OnChange)
    ns:RegisterEvent("UNIT_PET", Module.OnPetChanged)
    ns:RegisterEvent("PET_BAR_UPDATE", Module.OnPetChanged)
end
