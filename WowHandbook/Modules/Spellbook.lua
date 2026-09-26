local ADDON_NAME, ns = ...
local L = ns.L

-- 按等级的技能书（F4）：本职业全部可训练技能按学习等级展开，标出已学、现在可学、还没到等级；
-- 升级时在聊天框提示这一级可以学什么。技能数据来自网站（Forever 客户端导出），已学情况读玩家技能书。
local Module = ns:NewModule("Spellbook", { levelUpNotice = true })
local UI

local state = { filter = "upcoming" }
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

-- 当前召唤出的恶魔已学的技能：技能名（小写）-> 最高等级数字。没有宠物时返回 nil
local function KnownPetSpells()
    if not UnitExists("pet") or not C_SpellBook.HasPetSpells then
        return nil, nil
    end
    local count = C_SpellBook.HasPetSpells()
    if not count or count == 0 then
        return nil, nil
    end
    local known = {}
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1
    for slot = 1, count do
        local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
        if item and item.name then
            local key = item.name:lower()
            known[key] = math.max(known[key] or 0, ns.RankNumber(item.subName))
        end
    end
    return known, UnitCreatureFamily("pet")
end

-- 每个技能的每个等级展开成一行：{ spell, rank, rankNumber, level, status }
-- status：known（已学）、ready（现在可学）、later（还没到等级）；恶魔技能另有
-- innate（召唤恶魔时自带）、book（到等级了，可向商人买魔典）
local function Rows(petsOnly)
    local rows = {}
    local known = ns.KnownSpells()
    local petKnown, petFamily = KnownPetSpells()
    local level = ns.PlayerLevel()
    for _, spell in ipairs(ClassSpells()) do
        if spell.pet then
            if petsOnly then
                local petName = ns.Name(spell.pet)
                local learned = petKnown and petFamily == petName and petKnown[(ns.Name(spell.name) or ""):lower()]
                for _, rank in ipairs(spell.ranks) do
                    local rankNumber = ns.RankNumber(rank.rank)
                    local status
                    if rank.level > level then
                        status = "later"
                    elseif rank.innate then
                        status = "innate"
                    elseif learned and learned >= rankNumber then
                        status = "known"
                    else
                        status = "book"
                    end
                    tinsert(rows, { spell = spell, rank = rank.rank, rankNumber = rankNumber, level = rank.level,
                        status = status, book = rank.book, price = rank.price, pet = petName })
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
                tinsert(rows, { spell = spell, rank = rank.rank, rankNumber = rankNumber, level = rank.level, status = status })
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

local STATUS = {
    known = "|cff46bf72%s|r",
    innate = "|cff46bf72%s|r",
    ready = "|cffe0b458%s|r",
    book = "|cffe0b458%s|r",
    later = "|cff8a8374%s|r",
}
local STATUS_LABEL = { known = "Learned", innate = "Innate", ready = "Train now", book = "Buy the grimoire", later = "Not yet" }

local function Icon(spell)
    return spell.icon and ("|TInterface\\Icons\\%s:16:16:0:0:64:64:5:59:5:59|t "):format(spell.icon) or ""
end

local function RankText(row)
    if row.rank == "" then
        return ""
    end
    return " |cff8a8374(" .. (L["Rank %d"]):format(row.rankNumber) .. ")|r"
end

local function Refresh()
    if not (page and page:IsShown()) then
        return
    end
    local stack = page.stack
    stack:Reset()
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

    if #rows == 0 then
        stack:Text(L["No spell data for your class yet."], "Muted")
        page.detail:SetContentHeight(stack:Finish())
        return
    end

    local currentLevel
    for _, row in ipairs(rows) do
        local show = state.filter == "all"
            or (state.filter == "upcoming" and (row.status == "ready" or (row.status == "later" and row.level <= level + 10)))
        if show then
            if row.level ~= currentLevel then
                currentLevel = row.level
                local label = (L["Level %d"]):format(row.level)
                if row.level == level then
                    label = label .. "  |cffe0b458" .. L["your level"] .. "|r"
                end
                stack:Heading(label)
            end
            stack:Text(("%s%s%s   " .. STATUS[row.status]):format(Icon(row.spell), ns.Name(row.spell.name) or "?",
                RankText(row), L[STATUS_LABEL[row.status]]), "Body", 8, 5)
        end
    end

    -- 恶魔技能（术士）：按恶魔分组；每一级标出自带或对应的魔典
    local petRows = Rows(true)
    if #petRows > 0 then
        stack:Spacer(10)
        stack:Text(L["Demon abilities"], "Title", 0, 4)
        local note = "Rank 1 of some abilities comes with the demon; "
            .. "every other rank is learned from a grimoire sold by demon trainers."
        stack:Text(L[note], "Muted", 0, 6)
        local currentPet
        for _, row in ipairs(petRows) do
            local show = state.filter == "all" or row.status ~= "later" or row.level <= level + 10
            if show then
                if row.pet ~= currentPet then
                    currentPet = row.pet
                    stack:Heading(row.pet or "?")
                end
                local source = ""
                if row.book then
                    local price = ns.Money(row.price)
                    source = "   " .. ns.ItemLink(row.book) .. (price and ("  " .. price) or "")
                end
                stack:Text(("%s%s%s  |cff8a8374%s|r   " .. STATUS[row.status] .. "%s"):format(Icon(row.spell),
                    ns.Name(row.spell.name) or "?", RankText(row), (L["Level %d"]):format(row.level),
                    L[STATUS_LABEL[row.status]], source), "Body", 8, 5)
            end
        end
    end
    page.detail:SetContentHeight(stack:Finish())
end

local function CreatePage(parent)
    UI = ns.UI
    local p = CreateFrame("Frame", nil, parent)
    page = p
    local PAD = 20
    local _, className = UnitClass("player")

    local title = UI:Text(p, "Title", (L["Spells by level · %s"]):format(className or ""))
    title:SetPoint("TOPLEFT", PAD, -18)
    p.summary = UI:Text(p, "Muted")
    p.summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

    p.filter = UI:Segmented(p, {
        { id = "upcoming", label = L["Now and next 10 levels"] },
        { id = "all", label = L["Full spellbook"] },
    }, function(filter)
        state.filter = filter
        p.detail:ScrollToTop()
        Refresh()
    end, 150)
    p.filter:SetPoint("TOPLEFT", PAD, -64)
    p.filter:Select(state.filter)

    local siteButton = UI:Button(p, L["Full spellbook on the website"], 190, 24)
    siteButton:SetPoint("TOPRIGHT", -PAD, -64)
    siteButton:SetScript("OnClick", function()
        ns.Links:ShowCopyDialog(ns.Links:Build("spellbook", ns.PlayerClass()))
    end)

    local panel = UI:Panel(p, "panel", "lineSoft")
    panel:SetPoint("TOPLEFT", PAD, -100)
    panel:SetPoint("BOTTOMRIGHT", -PAD, 20)
    local detail = UI:ScrollArea(panel)
    detail:SetPoint("TOPLEFT", 16, -10)
    detail:SetPoint("BOTTOMRIGHT", -18, 10)
    detail.child:SetHyperlinksEnabled(true)
    detail.child:SetScript("OnHyperlinkEnter", function(self, link)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    detail.child:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
    p.detail = detail
    p.stack = UI:Stack(detail.child)

    p:SetScript("OnShow", Refresh)
    return p
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
    ns:RegisterEvent("SPELLS_CHANGED", function()
        ns.InvalidateKnownSpells()
        if page and page:IsShown() then
            C_Timer.After(0.3, Refresh)
        end
    end)
end
