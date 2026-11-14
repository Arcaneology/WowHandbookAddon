local ADDON_NAME, ns = ...
local L = ns.L

-- 稀有宠物追踪：只对猎人启用。
-- 列出可驯服的稀有、精英稀有与重点宠物：现在能不能驯服、在哪里、这个角色驯服过没有。
-- · 已驯服：召出或驯服宠物时，宠物 GUID 里带着原来的生物 ID，是追踪表里的就记到本角色存档；
--   插件装上之前驯服、后来放弃的，右键一行手动标记或取消。
-- · 左侧按状态筛选（现在能驯服 / 等级不够 / 已驯服 / 全部）或按家族看；点一行在大地图上标出位置。
-- · 每只宠物的特点（用户 2026-11-08）：攻击间隔（攻速被动，只在比普通 2 秒快或慢时显示）、自带的宠物技能等级、
--   重点宠物的网站标签（独特外观、PvP 等）；都没有时显示家族专属技能。鼠标指向一行时展开：家族定位、
--   专属技能、网站的看点与驯服提示。技能名与图标运行时向客户端取。
-- · 鼠标指向追踪表里的野兽时，提示末尾加一行“稀有宠物 · 家族 · 已驯服 / 未驯服”（可在设置里关闭）。
-- 家族修正、食谱、技能等级与普通野兽只放网站（用户 2026-11-08）。野兽位置来自 QuestieDB；地图名运行时向客户端取。
local Module = ns:NewModule("HunterPets", { tooltip = true })
local UI

local page
local ROW_HEIGHT = 38
local RIGHT_WIDTH = 170
local NORMAL_ATTACK = 2.0 -- 秒：没有攻速被动的宠物的攻击间隔
local FILTERS = {
    { id = "now", label = "You can tame now" },
    { id = "later", label = "Level too low" },
    { id = "tamed", label = "Tamed" },
    { id = "all", label = "All rare pets" },
}
local TAGS = { look = "Unique look", pvp = "PvP", group = "Group buff", early = "Early pick", tank = "Tank" }
local RARE = { rare = true, rareelite = true }

local function Color(text, name)
    return ns.Theme:Color(text, name)
end

local function Data()
    return ns.Data.hunterPets or { families = {}, beasts = {} }
end

local function FamilyBySlug(slug)
    for _, family in ipairs(Data().families) do
        if family.slug == slug then
            return family
        end
    end
end

-- 本角色驯服过的追踪宠物：charDB.tamedPets[生物 ID] = 记下的时间（右键手动标记的同样记时间）
local function Tamed()
    ns.charDB.tamedPets = ns.charDB.tamedPets or {}
    return ns.charDB.tamedPets
end

local function IsTamed(id)
    return Tamed()[id] ~= nil
end
Module.IsTamed = IsTamed -- 供测试使用

local function Icon(icon, size)
    return icon and ("|TInterface\\Icons\\%s:%d:%d:0:0:64:64:5:59:5:59|t "):format(icon, size or 16, size or 16) or ""
end

local function SpellName(spellID)
    return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
end

local function SpellLabel(spellID, size)
    local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
    local icon = texture and ("|T%s:%d:%d:0:0:64:64:5:59:5:59|t "):format(texture, size or 14, size or 14) or ""
    return icon .. (SpellName(spellID) or "?")
end

-- 攻击间隔：比普通快几成（1.3 秒 → 快 54%）
local function AttackText(attack)
    local percent = floor((NORMAL_ATTACK / attack - 1) * 100 + 0.5)
    if percent > 0 then
        return (L["%.1f s swing (%d%% faster)"]):format(attack, percent)
    end
    return (L["%.1f s swing (%d%% slower)"]):format(attack, -percent)
end

-- 一行里的特点摘要；没有任何特点时给家族专属技能（灰色）
local function Specials(beast)
    local parts = {}
    if beast.attack then
        tinsert(parts, Color(AttackText(beast.attack), beast.attack < NORMAL_ATTACK and "green" or "red"))
    end
    for _, taught in ipairs(beast.teaches or {}) do
        tinsert(parts, Color((L["%s rank %d"]):format(SpellLabel(taught[1], 12), taught[2]), "gold"))
    end
    for _, tag in ipairs(beast.tags or {}) do
        tinsert(parts, Color(L[TAGS[tag] or tag], "text"))
    end
    if #parts == 0 then
        local family = FamilyBySlug(beast.family)
        if family and family.signature then
            return Color((L["Family ability: %s"]):format(SpellLabel(family.signature, 12)), "muted")
        end
        return ""
    end
    return table.concat(parts, Color("  ·  ", "muted"))
end
Module.Specials = Specials -- 供测试使用

-- 宠物名以客户端为准（网站的中文名有几只无限版新增宠物是自译的，与游戏不一致）；客户端还没缓存时用数据兜底，
-- 记下来让页面稍后再刷新一次
local missingNames = false
local nameRetries = 0
local NAME_RETRIES = 3 -- 每次打开页面最多再刷新几次（每次隔 1 秒）
local function BeastName(id, beast)
    local name = ns.NpcName(id)
    if name then
        return name
    end
    missingNames = true
    return ns.Name(beast.name) or "?"
end

local function LevelText(beast)
    return beast.levels and ns.LevelRange(beast.levels) or "?"
end

local function CanTame(beast, level)
    return beast.levels and beast.levels[1] <= level
end

local function InstanceName(slug)
    for _, dungeon in ipairs(ns.Data.dungeons or {}) do
        if dungeon.slug == slug then
            return ns.Name(dungeon.name) or slug
        end
    end
    return slug
end

local function Location(beast)
    local spot = beast.spots and beast.spots[1]
    if spot then
        local where = ns.MapName(spot[1]) or "?"
        return ("%s  %s"):format(where, Color(("%.0f, %.0f"):format(spot[2], spot[3]), "muted"))
    end
    if beast.instances then
        return InstanceName(beast.instances[1])
    end
    return Color("?", "muted")
end

-- 状态：已驯服 > 现在能驯服 > 等级不够
local function State(id, beast, level)
    if IsTamed(id) then
        return "tamed"
    end
    return CanTame(beast, level) and "now" or "later"
end

-- 按筛选（状态或家族 slug）取宠物，按等级升序
local function Pets(filter, level)
    local rows = {}
    for id, beast in pairs(Data().beasts) do
        local state = State(id, beast, level)
        if filter == "all" or filter == state or filter == beast.family then
            tinsert(rows, { id = id, beast = beast, state = state })
        end
    end
    local function lo(row)
        return row.beast.levels and row.beast.levels[1] or 0
    end
    table.sort(rows, function(a, b)
        if lo(a) ~= lo(b) then
            return lo(a) < lo(b)
        end
        return BeastName(a.id, a.beast) < BeastName(b.id, b.beast)
    end)
    return rows
end
Module.Pets = Pets -- 供测试使用

local function Counts(level)
    local counts = { now = 0, later = 0, tamed = 0, all = 0 }
    for id, beast in pairs(Data().beasts) do
        local state = State(id, beast, level)
        counts[state] = counts[state] + 1
        counts.all = counts.all + 1
    end
    return counts
end

local function StatusText(row)
    if row.state == "tamed" then
        return Color(L["Tamed"], "green")
    elseif row.state == "now" then
        return Color(L["Can tame"], "gold")
    end
    return Color((L["Level %d"]):format(row.beast.levels and row.beast.levels[1] or 0), "muted")
end

--------------------------------------------------------------------------------
-- 表格（与专业页相同的行样式：隔行底色，可驯服的行淡金底加金条）
--------------------------------------------------------------------------------

local Refresh

local function ShowBeastTooltip(row, data)
    local beast = data.beast
    local family = FamilyBySlug(beast.family)
    local muted, body, hint = { 0.85, 0.8, 0.69 }, { 1, 1, 1 }, { 0.54, 0.51, 0.45 }
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(BeastName(data.id, beast), 1, 0.82, 0)
    if family then
        local role = family.role and ns.Name(family.role)
        GameTooltip:AddLine(Icon(family.icon) .. ns.Name(family.name) .. (role and ("  ·  " .. role) or ""), unpack(body))
    end
    GameTooltip:AddLine((L["Level %s"]):format(LevelText(beast)), unpack(muted))
    if beast.attack then
        GameTooltip:AddLine(AttackText(beast.attack), unpack(beast.attack < NORMAL_ATTACK and { 0.4, 0.85, 0.45 } or muted))
    end
    for _, taught in ipairs(beast.teaches or {}) do
        GameTooltip:AddLine((L["Comes with %s rank %d"]):format(SpellLabel(taught[1]), taught[2]), 1, 0.82, 0)
    end
    if family and family.signature then
        GameTooltip:AddLine((L["Family ability: %s"]):format(SpellLabel(family.signature)), unpack(muted))
    end
    local why, tip = beast.why and ns.Name(beast.why), beast.tip and ns.Name(beast.tip)
    if why then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(why, 1, 1, 1, true)
    end
    if tip then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine((L["How to tame: %s"]):format(tip), 0.85, 0.8, 0.69, true)
    end
    GameTooltip:AddLine(" ")
    if beast.spots and #beast.spots > 1 then
        GameTooltip:AddLine((L["Spawns in %d places."]):format(#beast.spots), unpack(muted))
    end
    if beast.spots then
        GameTooltip:AddLine(L["Click to mark it on the map."], unpack(hint))
    end
    GameTooltip:AddLine(L["Right-click: menu"],
        unpack(hint))
    GameTooltip:Show()
end

local function CreateRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
    -- 左边两行：名字、等级与标记 / 特点；右边两行：状态 / 位置
    local function Cell(font, justify)
        local cell = UI:Text(row, font)
        cell:SetJustifyH(justify)
        cell:SetWordWrap(false)
        return cell
    end
    row.name = Cell("Body", "LEFT")
    row.name:SetPoint("TOPLEFT", 8, -4)
    row.name:SetPoint("RIGHT", -RIGHT_WIDTH, 0)
    row.specials = Cell("Small", "LEFT")
    row.specials:SetPoint("BOTTOMLEFT", 8, 5)
    row.specials:SetPoint("RIGHT", -RIGHT_WIDTH, 0)
    row.status = Cell("Small", "RIGHT")
    row.status:SetPoint("TOPRIGHT", -8, -5)
    row.status:SetWidth(RIGHT_WIDTH - 16)
    row.location = Cell("Small", "RIGHT")
    row.location:SetPoint("BOTTOMRIGHT", -8, 5)
    row.location:SetWidth(RIGHT_WIDTH - 16)
    row.heading = Cell("Small", "LEFT")
    row.heading:SetPoint("LEFT", 8, 0)
    row.heading:SetPoint("RIGHT", -8, 0)
    row:SetScript("OnEnter", function(self)
        self.highlight:Show()
        if self.data then
            ShowBeastTooltip(self, self.data)
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        GameTooltip_Hide()
    end)
    row:SetScript("OnClick", function(self, button)
        local data = self.data
        if not data then
            return
        end
        local spot = data.beast.spots and data.beast.spots[1]
        local function ShowOnMap()
            ns.Waypoints:ShowOnMap(spot[1], spot[2], spot[3], BeastName(data.id, data.beast))
        end
        if button == "RightButton" then
            -- 右键菜单：在地图上标出、手动标记已驯服或取消
            local entries = { { kind = "title", text = BeastName(data.id, data.beast) } }
            if spot then
                tinsert(entries, { kind = "action", text = L["Mark on the map"], onClick = ShowOnMap })
            end
            tinsert(entries, { kind = "action", text = IsTamed(data.id) and L["Mark as not tamed"] or L["Mark as tamed"],
                onClick = function()
                    Tamed()[data.id] = not IsTamed(data.id) and time() or nil
                    Refresh()
                end })
            UI:ContextMenu(entries)
            return
        end
        if spot then
            ShowOnMap()
        end
    end)
    return row
end

local function Table()
    local child = page.detail.child
    local rows, used, y = page.rows, 0, 0
    local t = {}

    local function NextRow(data, height)
        used = used + 1
        local row = rows[used] or CreateRow(child)
        rows[used] = row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
        row:SetHeight(height)
        row:Show()
        row.data = data
        row:EnableMouse(data ~= nil)
        y = y + height
        return row
    end

    function t:Heading(text, gapBefore)
        y = y + (gapBefore or 0)
        local row = NextRow(nil, 24)
        row.stripe:Hide()
        row.tint:Hide()
        row.bar:Hide()
        for _, cell in ipairs({ row.name, row.specials, row.status, row.location }) do
            cell:Hide()
        end
        row.heading:SetText(text)
        row.heading:Show()
    end

    function t:Pet(data, cells, striped, target)
        local row = NextRow(data, ROW_HEIGHT)
        row.stripe:SetShown(striped and true or false)
        row.tint:SetShown(target and true or false)
        row.bar:SetShown(target and true or false)
        row.heading:Hide()
        row.name:SetText(cells.name)
        row.specials:SetText(cells.specials)
        row.status:SetText(cells.status)
        row.location:SetText(cells.location)
        for _, cell in ipairs({ row.name, row.specials, row.status, row.location }) do
            cell:Show()
        end
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
-- 内容
--------------------------------------------------------------------------------

local function PetCell(row)
    local beast = row.beast
    local family = FamilyBySlug(beast.family)
    local name = BeastName(row.id, beast)
    if row.state == "tamed" then
        name = Color(name, "green")
    elseif RARE[beast.rank or ""] then
        name = Color(name, "gold")
    end
    local text = Icon(family and family.icon) .. name
    if beast.rank == "rareelite" or beast.rank == "elite" then
        text = text .. "  " .. Color(L["Elite"], "muted")
    end
    if beast.new then
        text = text .. "  " .. Color(L["New"], "green")
    end
    local levels = beast.levels
    return ("%s  |c%s%s|r"):format(text, ns.LevelColor(levels and levels[1], levels and levels[2]),
        (L["Lv %s"]):format(LevelText(beast)))
end

local function FilterTitle(filter)
    for _, f in ipairs(FILTERS) do
        if f.id == filter then
            return L[f.label]
        end
    end
    local family = FamilyBySlug(filter)
    return family and (Icon(family.icon, 20) .. (ns.Name(family.name) or family.slug)) or ""
end

function Refresh()
    if not (page and page:IsVisible()) then
        return
    end
    missingNames = false
    local settings = ns:GetModuleSettings(Module)
    local level = ns.PlayerLevel()
    local counts = Counts(level)
    local selected = settings.selected
    if not (selected and (FamilyBySlug(selected) or counts[selected])) then
        selected = "now"
    end

    local items = {}
    for _, f in ipairs(FILTERS) do
        local tone = f.id == "now" and "gold" or (f.id == "tamed" and "green" or "muted")
        tinsert(items, { id = f.id, text = L[f.label], tags = Color(tostring(counts[f.id]), tone) })
    end
    tinsert(items, { id = "divider:families", divider = true, text = Color(L["Families"], "muted") })
    for _, family in ipairs(Data().families) do
        local total, tamed = 0, 0
        for id, beast in pairs(Data().beasts) do
            if beast.family == family.slug then
                total = total + 1
                tamed = tamed + (IsTamed(id) and 1 or 0)
            end
        end
        tinsert(items, { id = family.slug, text = Icon(family.icon) .. (ns.Name(family.name) or family.slug),
            tags = Color(("%d/%d"):format(tamed, total), tamed == total and "green" or "muted") })
    end
    page.list:SetData(items, selected)

    page.title:SetText(FilterTitle(selected))
    page.summary:SetText((L["Tamed %d of %d rare pets  ·  %d you can tame now"]):format(counts.tamed, counts.all,
        counts.now))

    local t = Table()
    local rows = Pets(selected, level)
    if #rows > 0 then
        for index, row in ipairs(rows) do
            t:Pet(row, {
                name = PetCell(row),
                specials = Specials(row.beast),
                status = StatusText(row),
                location = Location(row.beast),
            }, index % 2 == 1, row.state == "now")
        end
    elseif selected == "now" then
        t:Heading(Color(L["No untamed rare pet at your level right now. Check Level too low for the next ones."],
            "muted"), 4)
    elseif selected == "tamed" then
        t:Heading(Color(L["Summon a rare pet you tamed and it is checked off here."], "muted"), 4)
    else
        t:Heading(Color(L["Nothing here yet."], "muted"), 4)
    end
    t:Finish()
    if missingNames and nameRetries < NAME_RETRIES then
        nameRetries = nameRetries + 1
        C_Timer.After(1, Refresh)
    end
    page.hint:SetText(Color(L["Click: mark on the map  ·  Right-click: menu. Summoned pets are checked off automatically."],
        "muted"))
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
    p.list = UI:List(listPanel, 24, function(id)
        settings.selected = id
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

    p:SetScript("OnShow", function()
        nameRetries = 0
        Refresh()
    end)
    return p
end

--------------------------------------------------------------------------------
-- 自动记下已驯服：宠物 GUID "Pet-0-1234-0-5678-5828-0100ABCDEF" 里的 5828 是原来的生物 ID
--------------------------------------------------------------------------------

local function CreatureIDFromGUID(guid, unitType)
    if type(guid) ~= "string" or ns.IsSecret(guid) then
        return nil
    end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= unitType then
        return nil
    end
    return tonumber(id)
end

local function CheckPet()
    local id = UnitExists("pet") and CreatureIDFromGUID(UnitGUID("pet"), "Pet")
    if id and Data().beasts[id] and not IsTamed(id) then
        Tamed()[id] = time()
        Refresh()
    end
end
Module.CheckPet = CheckPet -- 供测试使用

--------------------------------------------------------------------------------
-- 鼠标提示：追踪表里的野兽加一行“稀有宠物 · 家族 · 已驯服 / 未驯服”
--------------------------------------------------------------------------------

local seenTooltips = setmetatable({}, { __mode = "k" })
local hooked = false

local function TooltipLine(npcID)
    local beast = npcID and Data().beasts[npcID]
    if not beast then
        return nil
    end
    local parts = { RARE[beast.rank or ""] and L["Rare pet"] or L["Tameable"] }
    local family = FamilyBySlug(beast.family)
    if family then
        tinsert(parts, ns.Name(family.name))
    end
    tinsert(parts, IsTamed(npcID) and L["Tamed"] or L["Not tamed yet"])
    return table.concat(parts, "  ·  ")
end
Module.TooltipLine = TooltipLine -- 供测试使用

local function AddTooltip(tooltip, data)
    if not (Module.enabled and ns:GetModuleSettings(Module).tooltip) or not tooltip or not tooltip.AddLine then
        return
    end
    local guid = data and data.guid
    if ns.IsSecret(guid) then
        return
    end
    local line = TooltipLine(CreatureIDFromGUID(guid, "Creature"))
    if not line or seenTooltips[tooltip] == guid then
        return
    end
    seenTooltips[tooltip] = guid
    tooltip:AddLine(line, unpack(ns.Theme.colors.gold))
    if tooltip.Show then
        tooltip:Show()
    end
end

function Module:OnEnable()
    -- 只对猎人启用：其他职业不注册页面、不挂提示、不订阅事件
    if ns.PlayerClass() ~= "hunter" then
        return
    end
    ns.MainFrame:RegisterTab({ id = "hunterPets", title = L["Rare pets"], order = 23, create = CreatePage,
        onShow = Refresh })
    if not hooked and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, AddTooltip)
        hooked = true
        if GameTooltip and GameTooltip.HookScript then
            GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
                seenTooltips[tooltip] = nil
            end)
        end
    end
    -- 宠物出现（召出、驯服、登录）时记下；只读 GUID，开销很小，合并 1 秒内的多次事件
    local pending = false
    local function Schedule()
        if pending then
            return
        end
        pending = true
        C_Timer.After(1, function()
            pending = false
            CheckPet()
        end)
    end
    ns:RegisterEvent("UNIT_PET", function(_, unit)
        if unit == "player" then
            Schedule()
        end
    end)
    -- 升级后“现在能驯服”会变；等客户端更新等级后再刷新（页面没打开时 Refresh 直接返回）
    ns:RegisterEvent("PLAYER_LEVEL_UP", function()
        C_Timer.After(0.5, Refresh)
    end)
    Schedule()
end
