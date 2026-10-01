local ADDON_NAME, ns = ...
local L = ns.L

-- 专业：左侧 12 个专业（已学的标出技能等级），右侧是这个专业本阵营可用的训练师：
-- 按可教到的等级分组，你下一步要找的那一档高亮；点一行在大地图上标出位置。
-- 训练师数据来自网站（QuestieDB Forever 版加游戏内实测坐标）；已学专业与技能等级读玩家的专业信息。
local Module = ns:NewModule("Professions", {})
local UI

local page

local RANK_ORDER = ns.TRAINER_RANK_ORDER

local function Color(text, name)
    return ns.Theme:Color(text, name)
end

local function Professions()
    return ns.Data.professions or {}
end

local function Find(slug)
    for _, profession in ipairs(Professions()) do
        if profession.slug == slug then
            return profession
        end
    end
end

-- 玩家已学的专业（公共工具，大地图的采集点也用）
local LearnedSkills = ns.ProfessionSkills
Module.LearnedSkills = LearnedSkills -- 供测试使用

-- 下一步要学的一档（见 Core/Util.lua）；要找哪一档训练师用 ns.TargetTrainerRank
local NextRank = ns.NextTrainerRank
Module.NextRank = NextRank

-- 本阵营能用的训练师（阵营未知的也列出），按等级、当前所在地图优先、地图名排序
local function Trainers(profession)
    local faction = ns.PlayerFaction()
    local here = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local rows = {}
    for _, trainer in ipairs(profession.trainers or {}) do
        if not trainer.faction or trainer.faction == "AH" or not faction or trainer.faction == faction then
            tinsert(rows, trainer)
        end
    end
    table.sort(rows, function(a, b)
        local ra, rb = RANK_ORDER[a.rank] or 0, RANK_ORDER[b.rank] or 0
        if ra ~= rb then
            return ra < rb
        end
        if (a.map == here) ~= (b.map == here) then
            return a.map == here
        end
        local ma, mb = ns.MapName(a.map) or "", ns.MapName(b.map) or ""
        if ma ~= mb then
            return ma < mb
        end
        return (ns.Name(a.name) or "") < (ns.Name(b.name) or "")
    end)
    return rows
end
Module.Trainers = Trainers -- 供测试使用

--------------------------------------------------------------------------------
-- 表格：表头、分组标题、数据行；隔行底色，重点行淡金底加金条
--------------------------------------------------------------------------------

local ROW_HEIGHT = 22
local CELLS = { "a", "b", "c" }
local COLUMNS = {
    trainers = {
        { key = "a", label = "Trainer", width = 220 },
        { key = "b", label = "Trainer rank", width = 110 },
        { key = "c", label = "Location" },
    },
}
local HEADING = { { key = "a" } }

local function TrainerTitle(trainer)
    return ns.Name(trainer.name) or "?"
end

local function ShowTrainerTooltip(row, trainer)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(TrainerTitle(trainer), 1, 0.82, 0)
    if trainer.rank then
        GameTooltip:AddLine((L["Trainer rank: %s"]):format(ns.TrainerRankName(trainer.rank)), 1, 1, 1)
    end
    GameTooltip:AddLine(ns.MapName(trainer.map) or "?", 0.85, 0.8, 0.69)
    if trainer.x then
        GameTooltip:AddLine(L["Click to mark it on the map."], 0.54, 0.51, 0.45)
    else
        GameTooltip:AddLine(L["Exact spot not recorded yet."], 0.54, 0.51, 0.45)
    end
    GameTooltip:Show()
end

local function OnRowEnter(row)
    row.highlight:Show()
    if row.trainer then
        ShowTrainerTooltip(row, row.trainer)
    end
end

local function OnRowClick(row)
    local trainer = row.trainer
    if trainer then
        ns.Waypoints:ShowOnMap(trainer.map, trainer.x, trainer.y, TrainerTitle(trainer))
    end
end

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetColorTexture(unpack(ns.Theme.colors.stripe))
    row.tint = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.tint:SetAllPoints()
    ns.Theme:Paint(row.tint, "goldTint")
    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetPoint("TOPLEFT")
    row.bar:SetPoint("BOTTOMLEFT")
    row.bar:SetWidth(3)
    ns.Theme:Paint(row.bar, "gold")
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
    row:SetScript("OnEnter", OnRowEnter)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        GameTooltip_Hide()
    end)
    row:SetScript("OnClick", OnRowClick)
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
end

local function Table()
    local child = page.detail.child
    local rows, used, y = page.rows, 0, 0
    local t = {}

    local function NextRow(data)
        used = used + 1
        local row = rows[used] or CreateRow(child)
        rows[used] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
        row:Show()
        row.trainer = data and data.trainer
        row:EnableMouse(data ~= nil)
        y = y + ROW_HEIGHT
        return row
    end

    local function Fill(row, columns, cells, striped, target)
        row.stripe:SetShown(striped and true or false)
        row.tint:SetShown(target and true or false)
        row.bar:SetShown(target and true or false)
        for _, column in ipairs(columns) do
            row.cells[column.key]:SetText(cells[column.key] or "")
        end
        LayoutRow(row, columns)
    end

    function t:Header(columns)
        local cells = {}
        for _, column in ipairs(columns) do
            cells[column.key] = Color(L[column.label], "gold")
        end
        Fill(NextRow(nil), columns, cells)
    end

    function t:Heading(text, gapBefore)
        y = y + (gapBefore or 0)
        Fill(NextRow(nil), HEADING, { a = text })
    end

    function t:Row(columns, data, cells, striped, target)
        Fill(NextRow(data), columns, cells, striped, target)
    end

    function t:Finish()
        for index = used + 1, #rows do
            rows[index]:Hide()
        end
        page.detail:SetContentHeight(y + 8)
        return used
    end
    return t
end

--------------------------------------------------------------------------------
-- 训练师表格
--------------------------------------------------------------------------------

local function Location(trainer)
    local map = ns.MapName(trainer.map) or "?"
    if trainer.x then
        return ("%s  %s"):format(map, Color(("%.1f, %.1f"):format(trainer.x, trainer.y), "muted"))
    end
    return ("%s  %s"):format(map, Color(L["spot not recorded yet"], "muted"))
end

local function RenderTrainers(t, profession, skill)
    local trainers = Trainers(profession)
    local nextRank = ns.TargetTrainerRank(trainers, skill)
    t:Header(COLUMNS.trainers)
    for index, trainer in ipairs(trainers) do
        local target = trainer.rank ~= nil and trainer.rank == nextRank
        t:Row(COLUMNS.trainers, { trainer = trainer }, {
            a = Color(TrainerTitle(trainer), target and "gold" or "text"),
            b = trainer.rank and ns.TrainerRankName(trainer.rank) or Color("-", "muted"),
            c = Location(trainer),
        }, index % 2 == 1, target)
    end
    if #trainers == 0 then
        t:Heading(Color(L["No trainer data for your faction yet."], "muted"), 4)
    end

    local parts = { (L["%d trainers for your faction"]):format(#trainers) }
    if skill then
        tinsert(parts, (L["Your skill %d/%d"]):format(skill.rank, skill.max))
    end
    -- 没有带等级的训练师时（如采矿训练师头衔不写等级）不写“下一步”
    if nextRank then
        tinsert(parts, Color((L["Next: %s trainer"]):format(ns.TrainerRankName(nextRank)), "gold"))
    end
    return parts, L["Click: mark on map"]
end

local function Refresh()
    if not (page and page:IsVisible()) then
        return
    end
    local settings = ns:GetModuleSettings(Module)
    local learned = LearnedSkills()
    local professions = Professions()
    local selected = Find(settings.selected or "")
    if not selected then
        -- 默认选第一个已学的专业，没有就选第一个
        for _, profession in ipairs(professions) do
            if learned[profession.slug] then
                selected = profession
                break
            end
        end
        selected = selected or professions[1]
    end
    if not selected then
        return
    end

    local data, kind = {}, nil
    for _, profession in ipairs(professions) do
        if profession.kind ~= kind then
            kind = profession.kind
            tinsert(data, { id = "divider:" .. tostring(kind), divider = true,
                text = Color(L[kind == "secondary" and "Secondary professions" or "Primary professions"], "muted") })
        end
        local skill = learned[profession.slug]
        local icon = profession.icon and ("|TInterface\\Icons\\%s:16:16:0:0:64:64:5:59:5:59|t "):format(profession.icon) or ""
        tinsert(data, { id = profession.slug, text = icon .. (ns.Name(profession.name) or profession.slug),
            tags = skill and Color(("%d/%d"):format(skill.rank, skill.max), "green") or nil })
    end
    page.list:SetData(data, selected.slug)

    page.title:SetText(ns.Name(selected.name) or selected.slug)
    local t = Table()
    local parts, hint = RenderTrainers(t, selected, learned[selected.slug])
    t:Finish()
    page.summary:SetText(table.concat(parts, "  ·  "))
    page.hint:SetText(Color(hint, "muted"))
end
Module.Refresh = function() Refresh() end -- 供测试使用

local function CreatePage(parent)
    UI = ns.UI
    local p = CreateFrame("Frame", nil, parent)
    page = p
    Module.page = p -- 供测试使用
    local PAD = 20
    local settings = ns:GetModuleSettings(Module)

    local listPanel = UI:Panel(p, "panel", "lineSoft")
    listPanel:SetPoint("TOPLEFT", PAD, -18)
    listPanel:SetPoint("BOTTOMLEFT", PAD, 20)
    listPanel:SetWidth(180)
    p.list = UI:List(listPanel, 24, function(slug)
        settings.selected = slug
        Refresh()
    end)
    p.list:SetPoint("TOPLEFT", 4, -4)
    p.list:SetPoint("BOTTOMRIGHT", -4, 4)

    p.title = UI:Text(p, "Title")
    p.title:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 16, 0)
    p.summary = UI:Text(p, "Muted")
    p.summary:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -5)
    p.summary:SetPoint("RIGHT", -PAD, 0)
    p.summary:SetJustifyH("LEFT")
    p.summary:SetWordWrap(false)

    local panel = UI:Panel(p, "panel", "lineSoft")
    panel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 16, -48)
    panel:SetPoint("BOTTOMRIGHT", -PAD, 38)
    local detail = UI:ScrollArea(panel)
    detail:SetPoint("TOPLEFT", 12, -10)
    detail:SetPoint("BOTTOMRIGHT", -18, 10)
    p.detail = detail
    p.rows = {}
    p.hint = UI:Text(p, "Small")
    p.hint:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 2, -16)
    p.hint:SetPoint("RIGHT", -PAD, 0)
    p.hint:SetJustifyH("LEFT")

    p:SetScript("OnShow", Refresh)
    return p
end

function Module:OnEnable()
    ns.MainFrame:RegisterTab({ id = "professions", title = L["Professions"], order = 25, create = CreatePage,
        onShow = Refresh })
    -- 页面打开期间，技能等级变化时刷新（节流 0.5 秒，期间重复事件合并）
    local pending = false
    ns:RegisterEvent("SKILL_LINES_CHANGED", function()
        if pending or not (page and page:IsVisible()) then
            return
        end
        pending = true
        C_Timer.After(0.5, function()
            pending = false
            Refresh()
        end)
    end)
end
