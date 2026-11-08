local ADDON_NAME, ns = ...
local L = ns.L

-- BiS（最佳升级装备）：游戏角色窗口（CharacterFrame）右侧竖排模式标签的下面加一个“BiS”标签，
-- 点开后在角色窗口里显示原生角色信息样子的页面：左栏是种族背景上的角色模型（试穿推荐装备），
-- 两侧与底部是装备栏，装的是所选天赋在所选等级（1–60 逐级，或 60 级 PvP）的推荐装备；右栏列出每件装备从哪里拿。
-- 推荐来自网站 /bis/ 页的同一套算法逐级算出（Data/BisGear.lua 由 tools/dump_bis_gear.mjs 导出），插件只带物品 ID 与获取途径，
-- 物品名、图标、品质、鼠标提示、属性对比都在运行时向客户端取。
-- 与技能书、天赋窗口的嵌入方式一致：标签与页面都是插件自己的框架，标签用暴雪同一栏的
-- LargeSideTabButtonTemplate 但不继承角色窗口的 CharacterFrameModeSideTabTemplate（它的点击会调用暴雪的切换函数），
-- 不往暴雪的标签表里加标签、不改暴雪标签的状态；暴雪选中的标签用替身标签盖住来表现“未选中”，
-- 玩家切到暴雪的其他分页时用 hooksecurefunc 跟着收起。每次打开角色窗口都先回到暴雪自己的内容。
local Module = ns:NewModule("BisGear", { specs = {} })

local TAB_ICON = "Interface\\Icons\\INV_Chest_Plate16"
local VIEW_LEVEL = 600 -- 页面压过角色窗口的装备栏（100）、右栏切换按钮（510）与等级文字（520）
local SLOT_SIZE = 37
local SLOT_GAP = 6
local ROW_HEIGHT = 32 -- 右栏来源列表每行两行字：物品名、获取途径
local ALT_SIZE = 30 -- 按住 Alt 时装备格旁展开的备选格
local MAX_ALTS = 3

-- 装备栏布局与原生角色信息一致：左列、右列各 8 格，底部主手、副手、远程
local LEFT = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
local RIGHT = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
    "Trinket1Slot" }
local BOTTOM = { "MainHandSlot", "SecondaryHandSlot", "RangedSlot" }
-- 数据里的装备栏（网站的命名）依次填进哪些格子；戒指与饰品各两格
local FILLS = {
    Head = { "HeadSlot" }, Neck = { "NeckSlot" }, Shoulder = { "ShoulderSlot" }, Back = { "BackSlot" },
    Chest = { "ChestSlot" }, Wrist = { "WristSlot" }, Hands = { "HandsSlot" }, Waist = { "WaistSlot" },
    Legs = { "LegsSlot" }, Feet = { "FeetSlot" }, Finger = { "Finger0Slot", "Finger1Slot" },
    Trinket = { "Trinket0Slot", "Trinket1Slot" }, Weapon = { "MainHandSlot" }, ["Off Hand"] = { "SecondaryHandSlot" },
    Ranged = { "RangedSlot" }, Relic = { "RangedSlot" },
}

local host -- { frame, strip, tab, standIn, view, selected }
Module.host = function() -- 供测试使用
    return host
end
local MAX_LEVEL = 60
-- 本次登录里玩家在页面上选的等级（nil 时跟随角色等级）与是否看 60 级 PvP 组
local state = { level = nil, pvp = false }
-- 逐级推荐里的格子键（戒指、饰品按顺序编号），按这个顺序填格子
local KEY_ORDER = { "Weapon", "Off Hand", "Ranged", "Relic", "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist",
    "Hands", "Waist", "Legs", "Feet", "Finger1", "Finger2", "Trinket1", "Trinket2" }

--------------------------------------------------------------------------------
-- 数据
--------------------------------------------------------------------------------

local function ClassData()
    local data = ns.Data.bisGear
    return data and data.classes and data.classes[ns.PlayerClass() or ""]
end

-- 当前天赋：玩家在页面里选过的（按职业记在存档里），否则网站的默认升级天赋，再否则第一个
local function CurrentSpec()
    local data = ClassData()
    if not data then
        return nil
    end
    local wanted = ns:GetModuleSettings(Module).specs[ns.PlayerClass()] or data.default
    for _, spec in ipairs(data.specs) do
        if spec.tree == wanted then
            return spec
        end
    end
    return data.specs[1]
end

local function SelectedLevel()
    return math.max(1, math.min(MAX_LEVEL, state.level or ns.PlayerLevel()))
end

local function IsSiteSet(id)
    for _, siteID in ipairs(ns.Data.bisGear.siteSets or {}) do
        if siteID == id then
            return true
        end
    end
    return false
end

-- 所选等级的装备组：{ level, pvp, id（网站上对应的组）, site, gear, alts }。
-- 逐级推荐取每个格子在这一级及以下最近的一次变化（物品 ID 为 0 表示这格空了）；备选取这一级所在的网站 10 级段
local function CurrentSet(spec)
    if not spec then
        return nil
    end
    if state.pvp then
        local pvp = spec.pvp
        return { level = MAX_LEVEL, pvp = true, id = MAX_LEVEL .. "-pvp", site = IsSiteSet(MAX_LEVEL .. "-pvp"),
            gear = pvp.gear, alts = pvp.alts }
    end
    local level, faction = SelectedLevel(), ns.PlayerFaction()
    local latest = {}
    for _, row in ipairs(spec.timeline) do
        if row[1] <= level and (row[3] == "" or row[3] == faction) then
            latest[row[2]] = row
        end
    end
    local gear = {}
    for _, key in ipairs(KEY_ORDER) do
        local row = latest[key]
        if row and row[4] ~= 0 then
            tinsert(gear, { row[4], (key:gsub("%d$", "")), row[3], row[5], row[6], row[7] })
        end
    end
    local band = spec.bands[#spec.bands]
    for _, item in ipairs(spec.bands) do
        if level <= item.range[2] then
            band = item
            break
        end
    end
    local id = tostring(band and band.range[2] or level)
    return { level = level, pvp = false, id = id, site = IsSiteSet(id), gear = gear, alts = band and band.alts or {} }
end
Module.CurrentSet = function() -- 供测试使用
    return CurrentSet(CurrentSpec())
end

-- 本阵营的条目：阵营标记为空（两边都有）或与玩家阵营相同
local function ForFaction(list)
    local faction, out = ns.PlayerFaction(), {}
    for _, entry in ipairs(list or {}) do
        if entry[3] == "" or entry[3] == faction then
            tinsert(out, entry)
        end
    end
    return out
end

-- 格子名 -> 首选条目
local function Assign(set)
    local filled = {}
    for _, entry in ipairs(ForFaction(set and set.gear)) do
        for _, slot in ipairs(FILLS[entry[2]] or {}) do
            if not filled[slot] then
                filled[slot] = entry
                break
            end
        end
    end
    return filled
end
Module.Assign = Assign

-- 一个装备栏的备选：网站这一段的备选里，除去已经是首选的，以及所选等级还穿不上的（需求等级向客户端取，
-- 还没缓存的先不列，数据到了刷新时补上）
local function Alternatives(set, gearSlot)
    local out, picked = {}, {}
    for _, entry in ipairs(set and set.gear or {}) do
        picked[entry[1]] = true
    end
    for _, entry in ipairs(ForFaction(set and set.alts)) do
        if entry[2] == gearSlot and not picked[entry[1]] then
            local _, _, _, _, minLevel = C_Item.GetItemInfo(entry[1])
            if minLevel == nil then
                ns.RequestItem(entry[1])
            elseif minLevel <= set.level then
                tinsert(out, entry)
            end
        end
    end
    return out
end

local function SpecName(spec)
    local trees = ns.Data.talents and ns.Data.talents[ns.PlayerClass() or ""]
    local tree = trees and trees.trees and trees.trees[spec.tree]
    return tree and ns.Name(tree.name) or spec.slug
end

local function SetName(set)
    if set.pvp then
        return (L["Level %d PvP"]):format(set.level)
    end
    return (L["Level %d"]):format(set.level)
end

--------------------------------------------------------------------------------
-- 获取途径：副本与首领名取插件副本数据（按客户端语言），任务名向客户端取
--------------------------------------------------------------------------------

local function FindDungeon(siteSlug, bossName)
    local first
    for _, dungeon in ipairs(ns.Data.dungeons or {}) do
        if dungeon.siteSlug == siteSlug then
            first = first or dungeon
            for _, boss in ipairs(dungeon.bosses or {}) do
                if boss.name and boss.name.enUS == bossName then
                    return dungeon, boss
                end
            end
        end
    end
    return first, nil
end

local function ProfessionName(slug)
    for _, profession in ipairs(ns.Data.professions or {}) do
        if profession.slug == slug then
            return ns.Name(profession.name)
        end
    end
    return slug
end

local function NpcName(npcID)
    local npcs = ns.Data.bisGear and ns.Data.bisGear.npcs
    return npcs and npcs[npcID] and ns.Name(npcs[npcID]) or tostring(npcID)
end

function Module.SourceText(entry)
    local kind, a, b = entry[4], entry[5], entry[6]
    if kind == "drop" then
        local dungeon, boss = FindDungeon(a, b)
        local bossName = ns.BossName(boss or { name = { enUS = b } })
        return (L["Drop: %s (%s)"]):format(bossName, dungeon and ns.Name(dungeon.name) or a)
    elseif kind == "trash" then
        local dungeon = FindDungeon(a)
        return (L["Drop: %s (%s)"]):format(L["Trash mobs"], dungeon and ns.Name(dungeon.name) or a)
    elseif kind == "quest" then
        return (L["Quest: %s"]):format(ns.QuestTitle(a))
    elseif kind == "vendor" then
        return (L["Vendor: %s"]):format(NpcName(a))
    elseif kind == "mob" then
        return (L["Drop: %s"]):format(NpcName(a))
    elseif kind == "crafted" then
        local recipe = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(b)
        local name = ProfessionName(a)
        return recipe and (L["Crafted: %s (%s)"]):format(recipe, name) or (L["Crafted: %s"]):format(name)
    end
    return ""
end

--------------------------------------------------------------------------------
-- 物品：图标、品质、是否已穿上、与身上装备的属性差
--------------------------------------------------------------------------------

local function ItemLinkOrNil(itemID)
    local _, link = C_Item.GetItemInfo(itemID)
    if not link then
        ns.RequestItem(itemID)
    end
    return link
end

-- 身上这一格（戒指、饰品看两格）有没有穿着这件
local function Wearing(entry)
    for _, slot in ipairs(FILLS[entry[2]] or {}) do
        local slotID = GetInventorySlotInfo(slot)
        if slotID and GetInventoryItemID("player", slotID) == entry[1] then
            return true
        end
    end
    return false
end
Module.Wearing = Wearing

-- 换上这件后属性的变化：{ {名字, 数值}… }；身上这格是空的时就是这件的全部属性
local function StatChanges(entry, slot)
    local link = ItemLinkOrNil(entry[1])
    if not (link and C_Item.GetItemStats) then
        return nil
    end
    local slotID = GetInventorySlotInfo(slot)
    local worn = slotID and GetInventoryItemLink("player", slotID)
    local ok, stats
    if worn and C_Item.GetItemStatDelta then
        ok, stats = pcall(C_Item.GetItemStatDelta, link, worn)
    else
        ok, stats = pcall(C_Item.GetItemStats, link)
    end
    if not (ok and type(stats) == "table") then
        return nil
    end
    local changes = {}
    for key, value in pairs(stats) do
        local name = _G[key]
        if type(name) == "string" and type(value) == "number" and value ~= 0 then
            tinsert(changes, { name, value })
        end
    end
    table.sort(changes, function(x, y)
        return x[1] < y[1]
    end)
    return changes
end

local function FormatChange(value)
    if value == math.floor(value) then
        return ("%+d"):format(value)
    end
    return ("%+.1f"):format(value)
end

local function ShowTooltip(owner, entry, slot, set, isAlternative)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(entry[1])
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Module.SourceText(entry), 1, 0.82, 0, true)
    if Wearing(entry) then
        GameTooltip:AddLine(L["You are wearing this."], 0.1, 1, 0.1)
    else
        local changes = StatChanges(entry, slot)
        if changes and #changes > 0 then
            GameTooltip:AddLine(L["If you replace what you wear:"], 1, 1, 1)
            for _, change in ipairs(changes) do
                local good = change[2] > 0
                GameTooltip:AddLine(FormatChange(change[2]) .. " " .. change[1], good and 0.1 or 1, good and 1 or 0.1,
                    0.1)
            end
        end
    end
    local alts = isAlternative and {} or Alternatives(set, entry[2])
    if #alts > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Alternatives:"], 1, 1, 1)
        for _, alt in ipairs(alts) do
            local name = C_Item.GetItemNameByID(alt[1])
            if not name then
                ns.RequestItem(alt[1])
            end
            GameTooltip:AddDoubleLine(name or L["Loading..."], Module.SourceText(alt), 0.8, 0.8, 0.8, 0.6, 0.6, 0.6)
        end
        if not owner.isRow then
            GameTooltip:AddLine(L["Hold Alt to show them next to this slot."], 0.5, 0.5, 0.5)
        end
    end
    GameTooltip:Show()
end

-- 物品名（按品质着色）；还没缓存时先显示“加载中”，数据到了会刷新
local function ItemName(itemID)
    local name = C_Item.GetItemNameByID(itemID)
    if not name then
        ns.RequestItem(itemID)
        return L["Loading..."]
    end
    local quality = C_Item.GetItemQualityByID(itemID)
    local _, _, _, hex = C_Item.GetItemQualityColor(quality or 1)
    return hex and ("|c" .. hex .. name .. "|r") or name
end

-- 品质边框：品质未知（物品还没缓存）时先不画
local function PaintItem(icon, border, itemID)
    icon:SetTexture(C_Item.GetItemIconByID(itemID) or 134400)
    local quality = C_Item.GetItemQualityByID(itemID)
    if quality and quality > 1 then
        local r, g, b = C_Item.GetItemQualityColor(quality)
        border:SetVertexColor(r, g, b)
        border:Show()
    else
        border:Hide()
    end
    if not quality then
        ns.RequestItem(itemID)
    end
end

--------------------------------------------------------------------------------
-- 页面
--------------------------------------------------------------------------------

local function ModifiedClick(entry)
    if not (entry and IsModifiedClick and IsModifiedClick() and HandleModifiedItemClick) then
        return
    end
    local link = ItemLinkOrNil(entry[1])
    if link then
        HandleModifiedItemClick(link)
    end
end

local UpdateFlyout -- 下面定义：按住 Alt 时只展开鼠标所在装备格的备选

-- 鼠标离开装备格或备选格后，等这一帧结束再看鼠标是否移到了同一组的另一格上
local function LeaveFlyout(view)
    GameTooltip_Hide()
    C_Timer.After(0, function()
        UpdateFlyout(view)
    end)
end

local function CreateSlot(view, slot)
    local button = CreateFrame("Button", nil, view)
    button:SetSize(SLOT_SIZE, SLOT_SIZE)
    button.slot = slot
    local frame = button:CreateTexture(nil, "BACKGROUND")
    frame:SetAtlas("UI-Character-Info-GearSlot", true)
    frame:SetPoint("CENTER")
    button.icon = button:CreateTexture(nil, "BORDER")
    button.icon:SetAllPoints()
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\Common\\WhiteIconFrame")
    button.border:SetAllPoints()
    button.check = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    button.check:SetSize(14, 14)
    button.check:SetPoint("BOTTOMRIGHT", 2, -2)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local _, empty = GetInventorySlotInfo(slot)
    button.empty = empty
    button:SetScript("OnEnter", function(self)
        view.hovered = self
        UpdateFlyout(view)
        if self.entry then
            ShowTooltip(self, self.entry, self.slot, view.set)
        end
    end)
    button:SetScript("OnLeave", function()
        LeaveFlyout(view)
    end)
    button:SetScript("OnClick", function(self)
        ModifiedClick(self.entry)
    end)
    view.slots[slot] = button
    return button
end

-- 备选格：按住 Alt 时在鼠标所在的装备格旁边排开（左列向右、右列向左、底部向上），像原生换装备的弹出栏；
-- 格子挨得很近，鼠标从装备格移到备选格上不会让弹出栏收起
local function CreateAlternatives(view, button, direction)
    button.alts = {}
    for i = 1, MAX_ALTS do
        local alt = CreateFrame("Button", nil, view)
        alt:SetSize(ALT_SIZE, ALT_SIZE)
        alt:SetFrameLevel(button:GetFrameLevel() + 2)
        local frame = alt:CreateTexture(nil, "BACKGROUND")
        frame:SetAtlas("UI-Character-Info-GearSlotSmall", true)
        frame:SetPoint("CENTER")
        alt.icon = alt:CreateTexture(nil, "BORDER")
        alt.icon:SetAllPoints()
        alt.border = alt:CreateTexture(nil, "OVERLAY")
        alt.border:SetTexture("Interface\\Common\\WhiteIconFrame")
        alt.border:SetAllPoints()
        alt.check = alt:CreateTexture(nil, "OVERLAY", nil, 2)
        alt.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        alt.check:SetSize(12, 12)
        alt.check:SetPoint("BOTTOMRIGHT", 2, -2)
        alt:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        local previous = button.alts[i - 1] or button
        local gap = 2
        if direction == "right" then
            alt:SetPoint("LEFT", previous, "RIGHT", gap, 0)
        elseif direction == "left" then
            alt:SetPoint("RIGHT", previous, "LEFT", -gap, 0)
        else
            alt:SetPoint("BOTTOM", previous, "TOP", 0, gap)
        end
        alt:SetScript("OnEnter", function(self)
            if self.entry then
                ShowTooltip(self, self.entry, button.slot, view.set, true)
            end
        end)
        alt:SetScript("OnLeave", function()
            LeaveFlyout(view)
        end)
        alt:SetScript("OnClick", function(self)
            ModifiedClick(self.entry)
        end)
        alt:Hide()
        button.alts[i] = alt
    end
end

local function PlaceSlots(view, left)
    for i, slot in ipairs(LEFT) do
        local button = CreateSlot(view, slot)
        button:SetPoint("TOPLEFT", left, "TOPLEFT", 24, -60 - (i - 1) * (SLOT_SIZE + SLOT_GAP))
        button:SetFrameLevel(view:GetFrameLevel() + 5)
        CreateAlternatives(view, button, "right")
    end
    for i, slot in ipairs(RIGHT) do
        local button = CreateSlot(view, slot)
        button:SetPoint("TOPRIGHT", left, "TOPRIGHT", -20, -60 - (i - 1) * (SLOT_SIZE + SLOT_GAP))
        button:SetFrameLevel(view:GetFrameLevel() + 5)
        CreateAlternatives(view, button, "left")
    end
    local previous
    for _, slot in ipairs(BOTTOM) do
        local button = CreateSlot(view, slot)
        if previous then
            button:SetPoint("TOPLEFT", previous, "TOPRIGHT", SLOT_GAP, 0)
        else
            button:SetPoint("BOTTOM", left, "BOTTOM", -40, 30)
        end
        button:SetFrameLevel(view:GetFrameLevel() + 5)
        CreateAlternatives(view, button, "up")
        previous = button
    end
end

local function HideFlyout(view)
    for _, button in pairs(view.slots) do
        for _, alt in ipairs(button.alts) do
            alt.entry = nil
            alt:Hide()
        end
    end
    view.flyout = nil
end

local function ShowFlyout(view, button)
    HideFlyout(view)
    local alts = button.entry and Alternatives(view.set, button.entry[2]) or {}
    for i, alt in ipairs(button.alts) do
        local entry = alts[i]
        alt.entry = entry
        if entry then
            PaintItem(alt.icon, alt.border, entry[1])
            alt.check:SetShown(Wearing(entry))
            alt:Show()
        end
    end
    view.flyout = button
end

local function OverGroup(button)
    if button:IsMouseOver() then
        return true
    end
    for _, alt in ipairs(button.alts) do
        if alt:IsShown() and alt:IsMouseOver() then
            return true
        end
    end
    return false
end

-- 鼠标在某个装备格（或它展开的备选格）上并按着 Alt 时展开这一格的备选，其余情况收起
function UpdateFlyout(view)
    local button = view.hovered
    if button and not OverGroup(button) then
        view.hovered, button = nil, nil
    end
    if button and IsAltKeyDown() then
        if view.flyout ~= button then
            ShowFlyout(view, button)
        end
    elseif view.flyout then
        HideFlyout(view)
    end
end
Module.UpdateFlyout = UpdateFlyout

-- 模型：与原生角色信息相同，用模型场景（ModelSceneMixinTemplate）与角色信息的场景 ID 595 放玩家自己的模型，
-- 脱下后试穿推荐装备；拖动旋转、滚轮缩放由暴雪的场景模板处理。
-- （旧式 DressUpModel 在无限版客户端里光照与遮挡不对，模型半透明并有一道黑影，2026-11-07 截图）
local CHARACTER_SHEET_SCENE = 595
local function CreateModel(view, left, top)
    local model = CreateFrame("ModelScene", nil, view, "ModelSceneMixinTemplate")
    model:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, 0)
    model:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", 0, 0)
    model:SetFrameLevel(view:GetFrameLevel() + 1)
    view.model = model

    -- 种族背景：与原生角色信息相同的四块贴图与遮罩
    local race = select(2, UnitRace("player"))
    local path = type(DressUpTexturePath) == "function" and race and DressUpTexturePath(race)
    local pieces = {
        { "TOPLEFT", 0.171875, 1, 0.0392156862745098, 1 },
        { "TOPRIGHT", 0, 0.296875, 0.0392156862745098, 1 },
        { "BOTTOMLEFT", 0.171875, 1, 0, 0.62 },
        { "BOTTOMRIGHT", 0, 0.296875, 0, 0.62 },
    }
    for i, piece in ipairs(pieces) do
        local texture = view:CreateTexture(nil, "BACKGROUND", nil, 1)
        if path then
            texture:SetTexture(path .. i)
        end
        texture:SetTexCoord(piece[2], piece[3], piece[4], piece[5])
        local isTop, isLeft = i <= 2, i % 2 == 1
        if isTop then
            texture:SetPoint("TOP", model, "TOP")
            texture:SetPoint("BOTTOM", model, "BOTTOM", 0, 129)
        else
            texture:SetPoint("BOTTOM", model, "BOTTOM")
            texture:SetHeight(130)
        end
        if isLeft then
            texture:SetPoint("LEFT", model, "LEFT")
            texture:SetPoint("RIGHT", model, "RIGHT", -79, 0)
        else
            texture:SetPoint("RIGHT", model, "RIGHT")
            texture:SetWidth(80)
        end
    end
    local overlay = view:CreateTexture(nil, "BORDER")
    overlay:SetAtlas("UI-Character-Info-RaceBG-Overlay")
    overlay:SetAllPoints(model)
end

local function DressActor(actor, view)
    actor:Undress()
    for _, entry in pairs(view.filled or {}) do
        actor:TryOn("item:" .. entry[1])
    end
end

local function Dress(view)
    local model = view.model
    if not (model and model:IsVisible() and model.TransitionToModelSceneID) then
        return
    end
    if not view.sceneReady then
        model:TransitionToModelSceneID(CHARACTER_SHEET_SCENE, CAMERA_TRANSITION_TYPE_IMMEDIATE or 1,
            CAMERA_MODIFICATION_TYPE_DISCARD or 1, true)
        view.sceneReady = true
    end
    local actor = model:GetPlayerActor()
    if not actor then
        return
    end
    -- 模型异步加载：加载完再脱衣试穿；已加载时直接换
    actor:SetOnModelLoadedCallback(function(self)
        DressActor(self, view)
    end)
    if not view.actorLoaded then
        actor:SetModelByUnit("player", false, false, false, true)
        view.actorLoaded = true
    elseif actor.IsLoaded and actor:IsLoaded() then
        DressActor(actor, view)
    end
end

-- 顶部条：左边选天赋（菜单里另有 60 级 PvP 开关），右边拖动选等级（原生角色信息这里是等级文字）
local function CreateControls(view, top)
    local spec = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
    spec:SetWidth(150)
    spec:SetPoint("LEFT", top, "LEFT", 12, -2)
    spec:SetupMenu(function(_, root)
        local data = ClassData()
        local function IsSelected(tree)
            local current = CurrentSpec()
            return current ~= nil and current.tree == tree
        end
        local function SetSelected(tree)
            ns:GetModuleSettings(Module).specs[ns.PlayerClass()] = tree
            view:Refresh()
        end
        for _, item in ipairs(data and data.specs or {}) do
            root:CreateRadio(SpecName(item), IsSelected, SetSelected, item.tree)
        end
        root:CreateDivider()
        root:CreateCheckbox(L["Level 60 PvP gear"], function()
            return state.pvp
        end, function()
            state.pvp = not state.pvp
            view:Refresh()
        end)
    end)
    view.specDropdown = spec

    local slider = CreateFrame("Frame", nil, view, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(200)
    slider:SetPoint("RIGHT", top, "RIGHT", -40, -2)
    view.formatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
            return (L["Level %d"]):format(math.floor(value + 0.5))
        end,
    }
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        local level = math.floor(value + 0.5)
        if view.syncing or (level == SelectedLevel() and not state.pvp) then
            return
        end
        -- 拖动等级条就离开 PvP 组；选回角色当前等级时恢复跟随升级
        state.level = level ~= ns.PlayerLevel() and level or nil
        state.pvp = false
        view:Refresh()
    end, view)
    view.levelSlider = slider
end

-- 右栏：所选组的标题、已穿上几件、每件从哪里拿、网站 BiS 页链接
local function CreateRightPane(view, left)
    local pane = CreateFrame("Frame", nil, view)
    pane:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
    pane:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 0, 0)
    pane:SetWidth(233)
    local background = pane:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Character-Info-Stat-BG", true)
    background:SetPoint("TOPLEFT")
    local stone = pane:CreateTexture(nil, "ARTWORK")
    stone:SetAtlas("UI-Character-Info-Stat-StoneBG3", true)
    stone:SetPoint("TOPLEFT")
    local divider = pane:CreateTexture(nil, "OVERLAY")
    divider:SetAtlas("common-framedivider", true)
    divider:SetPoint("TOPLEFT", -6, -1)
    divider:SetPoint("BOTTOMLEFT", -6, 0)

    view.title = pane:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    view.title:SetPoint("TOP", stone, "TOP", 0, -14)
    view.title:SetWidth(210)
    view.summary = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    view.summary:SetPoint("TOP", view.title, "BOTTOM", 0, -6)

    local header = CreateFrame("Frame", nil, pane, "CharacterStatFrameCategoryTemplate")
    header:SetPoint("TOP", stone, "BOTTOM", 0, -2)
    if header.Title then
        header.Title:SetText(L["Where to get it"])
    end
    -- 来源列表放在可滚动区域里（原生属性栏同款细滚动条），装备多时不会盖过底部按钮
    local scroll = CreateFrame("ScrollFrame", nil, pane)
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 6, -2)
    scroll:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -22, 44)
    local list = CreateFrame("Frame", nil, scroll)
    list:SetSize(195, ROW_HEIGHT)
    scroll:SetScrollChild(list)
    local bar = CreateFrame("EventFrame", nil, pane, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
        ScrollUtil.InitScrollFrameWithScrollBar(scroll, bar)
    end
    view.scroll, view.list = scroll, list
    view.rows = {}
    for i = 1, #LEFT + #RIGHT + #BOTTOM do
        local row = CreateFrame("Button", nil, list)
        row.isRow = true
        row:SetSize(195, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(24, 24)
        row.icon:SetPoint("LEFT", 2, 0)
        row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 0)
        row.name:SetPoint("RIGHT", -2, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.text:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 0)
        row.text:SetPoint("RIGHT", -2, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row:SetScript("OnEnter", function(self)
            if self.entry then
                ShowTooltip(self, self.entry, self.slot, view.set)
            end
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnClick", function(self)
            ModifiedClick(self.entry)
        end)
        view.rows[i] = row
    end

    local link = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    link:SetSize(190, 22)
    link:SetPoint("BOTTOM", 0, 12)
    link:SetText(L["Copy BiS page link"])
    link:SetScript("OnClick", function()
        local spec = CurrentSpec()
        local set = CurrentSet(spec)
        if spec and set then
            -- 网站 BiS 页没有的组（10 级）只链接到天赋页本身
            ns.Links:ShowCopyDialog(ns.Links:Build("bis", ns.PlayerClass() .. "/" .. spec.slug,
                set.site and ("lv-" .. set.id) or nil))
        end
    end)
    link:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["Copy BiS page link"], 1, 1, 1)
        GameTooltip:AddLine(L["See every slot's runner-ups, enchants and stat weights for this set on wowhandbook.com."],
            nil, nil, nil, true)
        GameTooltip:Show()
    end)
    link:SetScript("OnLeave", GameTooltip_Hide)
    view.pane = pane
end

local function RefreshView(view)
    local spec = CurrentSpec()
    local set = CurrentSet(spec)
    view.set = set
    view.filled = Assign(set)
    if view.specDropdown.GenerateMenu then
        view.specDropdown:GenerateMenu()
    end
    view.syncing = true
    view.levelSlider:Init(set and set.level or SelectedLevel(), 1, MAX_LEVEL, MAX_LEVEL - 1, view.formatters)
    view.syncing = false

    local total, worn = 0, 0
    for slot, button in pairs(view.slots) do
        local entry = view.filled[slot]
        button.entry = entry
        if entry then
            PaintItem(button.icon, button.border, entry[1])
            local wearing = Wearing(entry)
            button.check:SetShown(wearing)
            total = total + 1
            worn = worn + (wearing and 1 or 0)
        else
            button.icon:SetTexture(button.empty)
            button.border:Hide()
            button.check:Hide()
        end
    end

    view.title:SetText(spec and set and (SpecName(spec) .. " · " .. SetName(set)) or L["No BiS data for your class yet."])
    view.summary:SetText(total > 0 and (L["You wear %d of %d pieces"]):format(worn, total) or "")
    local n = 0
    for _, list in ipairs({ LEFT, RIGHT, BOTTOM }) do
        for _, slot in ipairs(list) do
            local entry = view.filled[slot]
            if entry then
                n = n + 1
                local row = view.rows[n]
                row.entry, row.slot = entry, slot
                row.icon:SetTexture(C_Item.GetItemIconByID(entry[1]) or 134400)
                row.name:SetText(ItemName(entry[1]))
                local text = Module.SourceText(entry)
                row.text:SetText(Wearing(entry) and ns.Theme:Color(text, "green") or text)
                row:Show()
            end
        end
    end
    for i = n + 1, #view.rows do
        view.rows[i].entry = nil
        view.rows[i]:Hide()
    end
    view.list:SetHeight(math.max(1, n) * ROW_HEIGHT)
    if view.flyout then
        ShowFlyout(view, view.flyout)
    end
    Dress(view)
end

local function CreateView(frame)
    local left = frame.LeftPaneHost or frame
    local view = CreateFrame("Frame", nil, frame)
    view:SetPoint("TOPLEFT", left, "TOPLEFT", 0, 0)
    view:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    -- 原生等级文字在 HIGH 层，页面放到同一层并压过它；整页接住鼠标，点不到下面原生的装备格
    view:SetFrameStrata("HIGH")
    view:SetFrameLevel(VIEW_LEVEL)
    view:EnableMouse(true)
    view.slots = {}
    -- 不透明底：原生角色模型、属性栏不会从页面的透明处透出来
    local base = view:CreateTexture(nil, "BACKGROUND", nil, -8)
    base:SetColorTexture(0, 0, 0, 1)
    base:SetAllPoints()

    local leftArea = CreateFrame("Frame", nil, view)
    leftArea:SetPoint("TOPLEFT")
    leftArea:SetPoint("BOTTOMLEFT")
    leftArea:SetWidth(left == frame and 398 or (left:GetWidth() or 398))
    local background = view:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Character-Info-General-BG", true)
    background:SetPoint("TOPLEFT")

    -- 顶部石纹条，与原生角色信息相同
    local top = CreateFrame("Frame", nil, view)
    top:SetPoint("TOPLEFT", leftArea, "TOPLEFT")
    top:SetPoint("TOPRIGHT", leftArea, "TOPRIGHT")
    top:SetHeight(36)
    top:SetFrameLevel(view:GetFrameLevel() + 2)
    local rock = top:CreateTexture(nil, "ARTWORK")
    rock:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
    rock:SetHorizTile(true)
    rock:SetVertTile(true)
    rock:SetAllPoints()
    local edge = top:CreateTexture(nil, "ARTWORK", nil, 1)
    edge:SetAtlas("_UI-Frame-InnerTopTile", true)
    edge:SetHorizTile(true)
    edge:SetPoint("BOTTOMLEFT")
    edge:SetPoint("BOTTOMRIGHT")

    CreateModel(view, leftArea, top)
    PlaceSlots(view, leftArea)
    CreateControls(view, top)
    view.specDropdown:SetFrameLevel(top:GetFrameLevel() + 2)
    view.levelSlider:SetFrameLevel(top:GetFrameLevel() + 2)
    CreateRightPane(view, leftArea)

    -- 角色窗口收起右栏时（宽度只剩左栏）右栏跟着隐藏
    local function FitPane()
        local width = frame:GetWidth()
        view.pane:SetShown(not width or width > 420)
    end
    frame:HookScript("OnSizeChanged", FitPane)
    FitPane()

    -- 按住 Alt 展开鼠标所在格的备选：只在页面显示时订阅按键变化
    local function OnModifier()
        UpdateFlyout(view)
    end
    view:SetScript("OnShow", function()
        ns:RegisterEvent("MODIFIER_STATE_CHANGED", OnModifier)
    end)
    view:SetScript("OnHide", function()
        ns:UnregisterEvent("MODIFIER_STATE_CHANGED", OnModifier)
        view.hovered = nil
        HideFlyout(view)
    end)

    view.Refresh = RefreshView
    view:Hide()
    return view
end

--------------------------------------------------------------------------------
-- 标签：接在暴雪最后一个显示中的模式标签下面；替身盖住暴雪选中的标签
--------------------------------------------------------------------------------

local function NativeTabs()
    local tabs = host.frame.ModeTabs and host.frame.ModeTabs.Tabs
    return type(tabs) == "table" and tabs or {}
end

local function PlaceTab()
    local last
    for _, tab in ipairs(NativeTabs()) do
        if tab:IsShown() then
            last = tab
        end
    end
    host.tab:ClearAllPoints()
    if last then
        host.tab:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -2)
    else
        host.tab:SetPoint("TOPLEFT", host.frame, "TOPRIGHT", 0, -30)
    end
end

local function NativeSelectedTab()
    local id = host.frame.selectedTab
    return id and NativeTabs()[id]
end

local function PlaceStandIn()
    local standIn, native = host.standIn, NativeSelectedTab()
    if not (host.selected and native and native:IsShown()) then
        standIn:Hide()
        return
    end
    if native == (host.frame.ModeTabs and host.frame.ModeTabs.CharacterTab) and SetPortraitTexture then
        SetPortraitTexture(standIn.Icon, "player")
    else
        standIn.Icon:SetTexture(native.Icon and native.Icon:GetTexture())
    end
    standIn.tooltipText = native.tooltipText
    standIn:SetFillToInterior(true)
    standIn:SetChecked(false)
    standIn:ClearAllPoints()
    standIn:SetAllPoints(native)
    standIn:Show()
end

local function Select(open)
    if open and not host.view then
        if InCombatLockdown() then
            ns:Print(L["Available after combat."])
            open = false
        else
            host.view = CreateView(host.frame)
        end
    end
    host.selected = open and true or nil
    host.tab:SetChecked(host.selected == true)
    if host.view then
        host.view:SetShown(host.selected == true)
        if host.selected then
            host.view:Refresh()
        end
    end
    PlaceStandIn()
end
Module.Select = function(open) -- 供测试使用
    Select(open)
end

local function CreateSideTab(parent)
    local tab = CreateFrame("Frame", nil, parent, "LargeSideTabButtonTemplate")
    tab:SetFrameLevel((host.frame.ModeTabs and host.frame.ModeTabs:GetFrameLevel() or 0) + 5)
    return tab
end

local function Build(frame)
    host = { frame = frame }
    local strip = CreateFrame("Frame", nil, frame)
    strip:SetAllPoints(frame)
    host.strip = strip

    local tab = CreateSideTab(strip)
    tab.Icon:SetTexture(TAB_ICON)
    tab.tooltipText = L["BiS gear"]
    tab:SetFillToInterior(true)
    tab:SetCustomOnMouseUpHandler(function(_, mouse, inside)
        if mouse == "LeftButton" and inside then
            Select(true)
        end
    end)
    host.tab = tab

    host.standIn = CreateSideTab(strip)
    host.standIn:SetFrameLevel(tab:GetFrameLevel() + 5)
    host.standIn:SetCustomOnMouseUpHandler(function(_, mouse, inside)
        if mouse == "LeftButton" and inside then
            Select(false)
        end
    end)
    host.standIn:Hide()

    -- 暴雪切换分页（点它的标签或按快捷键）都会按方法名调用 ShowSubFrame；点没有分页的标签只调用 OnModeTabClicked
    local function Leave()
        if host.selected then
            Select(false)
        end
    end
    for _, method in ipairs({ "ShowSubFrame", "OnModeTabClicked" }) do
        if type(frame[method]) == "function" then
            hooksecurefunc(frame, method, Leave)
        end
    end
    -- 暴雪重排、重选标签后重新接上我们的标签与替身
    for _, method in ipairs({ "UpdateTabLayout", "RefreshDisplay" }) do
        if type(frame[method]) == "function" then
            hooksecurefunc(frame, method, function()
                if Module.enabled then
                    PlaceTab()
                    PlaceStandIn()
                end
            end)
        end
    end
    frame:HookScript("OnShow", function()
        if Module.enabled then
            PlaceTab()
            Select(false)
        end
    end)
    PlaceTab()
    Select(false)
end

--------------------------------------------------------------------------------
-- 事件：页面显示时才刷新（换装备、升级、物品数据到达），节流 0.3 秒
--------------------------------------------------------------------------------

local pending = false
local function RefreshLater()
    if pending or not (host and host.view and host.view:IsVisible()) then
        return
    end
    pending = true
    C_Timer.After(0.3, function()
        pending = false
        if host.view:IsVisible() then
            host.view:Refresh()
        end
    end)
end
Module.RefreshLater = RefreshLater

local EVENTS = { "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP" }

function Module:OnEnable()
    if not (CharacterFrame and ClassData()) then
        return
    end
    if not host then
        Build(CharacterFrame)
        ns.OnItemLoaded(function()
            if Module.enabled then
                RefreshLater()
            end
        end)
    end
    host.strip:Show()
    PlaceTab()
    for _, event in ipairs(EVENTS) do
        ns:RegisterEvent(event, RefreshLater)
    end
end

function Module:OnDisable()
    for _, event in ipairs(EVENTS) do
        ns:UnregisterEvent(event, RefreshLater)
    end
    if host then
        Select(false)
        host.strip:Hide()
    end
end
