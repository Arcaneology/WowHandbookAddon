local ADDON_NAME, ns = ...
local L = ns.L

-- 未学技能面板：打开游戏自带的技能书时，在它右侧贴一块面板，列出本职业还没学的技能
-- （现在可学的在前，其余按学习等级排列；术士另列可买的魔典）。
-- 面板是插件自己的框架，只用 HookScript 跟随暴雪技能书显示和隐藏：不改暴雪框架、不往暴雪列表里加条目，
-- 所以不会污染技能书的施法与拖放。
local Module = ns:NewModule("SpellbookPanel", { collapsed = false })
local UI

local PANEL_WIDTH, ROW_HEIGHT = 270, 26
local ORDER = { ready = 1, book = 2, unchecked = 3, later = 4 }

local panel, tab
local target -- 暴雪技能书框架（无限版为 PlayerSpellsFrame.SpellBookFrame）
local attached = false

-- 技能书所在的整个窗口：面板贴在它的右边
local function Outer()
    if PlayerSpellsFrame and target == PlayerSpellsFrame.SpellBookFrame then
        return PlayerSpellsFrame
    end
    return target
end

-- 行首图标；还没到等级的技能图标调暗，与暴雪技能书里未学技能的灰色图标一致
local function IconText(icon, dim)
    if not icon then
        return ""
    end
    return ("|TInterface\\Icons\\%s:18:18:0:0:64:64:5:59:5:59%s|t "):format(icon, dim and ":110:110:110" or "")
end

local function Entries()
    local spellbook = ns.modules.Spellbook
    local rows = {}
    for _, petsOnly in ipairs({ false, true }) do
        for _, row in ipairs(spellbook.Rows(petsOnly)) do
            if ORDER[row.status] then
                tinsert(rows, row)
            end
        end
    end
    table.sort(rows, function(a, b)
        if ORDER[a.status] ~= ORDER[b.status] then
            return ORDER[a.status] < ORDER[b.status]
        end
        if a.level ~= b.level then
            return a.level < b.level
        end
        return (ns.Name(a.spell.name) or "") < (ns.Name(b.spell.name) or "")
    end)
    local entries, now = {}, 0
    for index, row in ipairs(rows) do
        local name = ns.Name(row.spell.name) or "?"
        if row.rank ~= "" then
            name = name .. " |cff8a8374" .. (L["Rank %d"]):format(row.rankNumber) .. "|r"
        end
        if row.pet then
            name = name .. " |cff8a8374(" .. row.pet .. ")|r"
        end
        local tags
        if row.status == "later" then
            tags = "|cff8a8374" .. (L["Learn at level %d"]):format(row.level) .. "|r"
        elseif row.status == "unchecked" then
            tags = "|cff8a8374" .. L["Summon to check"] .. "|r"
        else
            now = now + 1
            tags = "|cffe0b458" .. L[row.status == "book" and "Buy the grimoire" or "Train now"] .. "|r"
        end
        local dim = row.status == "later" or row.status == "unchecked"
        tinsert(entries, { id = index, text = IconText(row.spell.icon, dim) .. name, tags = tags,
            row = row })
    end
    return entries, now
end

-- 鼠标提示：有技能 ID 时显示客户端的技能说明（未学的技能也能取到），魔典显示物品提示
local function ShowTooltip(button, entryID)
    local entry = panel.entries[entryID]
    if not entry then
        return
    end
    local row = entry.row
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if row.status == "book" and row.book then
        GameTooltip:SetItemByID(row.book)
    elseif row.id then
        GameTooltip:SetSpellByID(row.id)
    else
        GameTooltip:SetText(ns.Name(row.spell.name) or "?", 1, 0.82, 0)
    end
    if row.status == "later" then
        GameTooltip:AddLine((L["Learn at level %d"]):format(row.level), 1, 1, 1)
    elseif row.status == "ready" then
        GameTooltip:AddLine(L["Visit your class trainer to learn it."], 0.88, 0.71, 0.35)
    elseif row.status == "unchecked" then
        GameTooltip:AddLine(L["Summon this demon once to check"], 1, 1, 1, true)
    end
    GameTooltip:Show()
end

local function Refresh()
    if not (panel and panel:IsShown()) then
        return
    end
    local entries, now = Entries()
    panel.entries = entries
    panel.list:SetData(entries)
    panel.count:SetText((L["%d to learn now · %d later"]):format(now, #entries - now))
    panel.empty:SetShown(#entries == 0)
end

local Update

local function SetCollapsed(collapsed)
    ns:GetModuleSettings(Module).collapsed = collapsed
    Update()
end

local function Create()
    UI = ns.UI
    panel = UI:Panel(UIParent, "panel", "line")
    panel:SetWidth(PANEL_WIDTH)
    panel:EnableMouse(true)
    panel:Hide()
    panel.title = UI:Text(panel, "Heading", L["Unlearned spells"])
    panel.title:SetPoint("TOPLEFT", 14, -12)
    panel.count = UI:Text(panel, "Muted")
    panel.count:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4)
    panel.close = UI:CloseButton(panel, function()
        SetCollapsed(true)
    end)
    panel.close:SetPoint("TOPRIGHT", -8, -8)
    panel.list = UI:List(panel, ROW_HEIGHT, function() end)
    panel.list:SetPoint("TOPLEFT", 6, -54)
    panel.list:SetPoint("BOTTOMRIGHT", -4, 8)
    panel.list.onEntryEnter = ShowTooltip
    panel.empty = UI:Text(panel, "Muted", L["You know every spell your class can learn right now."])
    panel.empty:SetPoint("TOPLEFT", 14, -60)
    panel.empty:SetWidth(PANEL_WIDTH - 28)
    panel.empty:SetJustifyH("LEFT")

    -- 收起后在技能书右上角留一个小按钮，点一下重新展开
    tab = UI:Button(UIParent, L["Unlearned spells"], 104, 24, "primary")
    tab:Hide()
    tab:SetScript("OnClick", function()
        SetCollapsed(false)
    end)
    Module.panel, Module.tab = panel, tab -- 供测试使用
end

local function Place()
    local outer = Outer()
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", outer, "TOPRIGHT", 2, 0)
    panel:SetPoint("BOTTOMLEFT", outer, "BOTTOMRIGHT", 2, 0)
    tab:ClearAllPoints()
    tab:SetPoint("TOPLEFT", outer, "TOPRIGHT", 2, -36)
    for _, frame in ipairs({ panel, tab }) do
        frame:SetFrameStrata(outer:GetFrameStrata())
        frame:SetFrameLevel(outer:GetFrameLevel() + 20)
    end
end

function Update()
    if not (Module.enabled and target and target:IsVisible()) then
        if panel then
            panel:Hide()
            tab:Hide()
        end
        return
    end
    if not panel then
        Create()
    end
    Place()
    local collapsed = ns:GetModuleSettings(Module).collapsed
    panel:SetShown(not collapsed)
    tab:SetShown(collapsed)
    Refresh()
end

-- 暴雪技能书按需加载：已加载就直接挂上，否则等它加载
local function Attach()
    if attached then
        return
    end
    local book = (PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame) or SpellBookFrame
    if not book then
        return
    end
    attached, target = true, book
    book:HookScript("OnShow", function()
        Update()
    end)
    book:HookScript("OnHide", function()
        Update()
    end)
    Update()
end

function Module:OnEnable()
    Attach()
    if not attached then
        ns:RegisterEvent("ADDON_LOADED", function(_, name)
            if name == "Blizzard_PlayerSpells" then
                Attach()
            end
        end)
    end
    -- 学会新技能、升级时刷新（节流 0.3 秒；面板没打开时不做任何事）
    local pending = false
    local function OnChange()
        if pending or not (panel and panel:IsShown()) then
            return
        end
        pending = true
        C_Timer.After(0.3, function()
            pending = false
            Refresh()
        end)
    end
    ns:RegisterEvent("SPELLS_CHANGED", OnChange)
    ns:RegisterEvent("PLAYER_LEVEL_UP", OnChange)
    -- 召唤、更换恶魔时记录它学过的技能（与技能书页共用处理函数）
    ns:RegisterEvent("UNIT_PET", ns.modules.Spellbook.OnPetChanged)
    ns:RegisterEvent("PET_BAR_UPDATE", ns.modules.Spellbook.OnPetChanged)
    Update()
end

function Module:OnDisable()
    Update()
end

-- 设置页改动选项后调用
function Module:Refresh()
    Update()
end

Module.Entries = Entries -- 供测试使用
