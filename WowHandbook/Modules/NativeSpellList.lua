local ADDON_NAME, ns = ...
local L = ns.L

-- 暴雪技能书里的“按等级学习”页：用插件自己的一份分页列表（UI/NativeTemplates.xml），
-- 条目、分组标题、书页与翻页控件都是暴雪技能书的模板，看起来与原生技能书一样。
-- 暴雪自己的技能书列表不碰（不换它的模板与数据，不调用它的方法）：从技能书施法、拖技能都走暴雪原来的路径。
-- 我们的列表显示时把暴雪列表藏起来，收起时还原；条目都是我们自己创建的框架，按钮脚本可以放心替换。
-- 由 Modules/NativeTabs.lua 创建与切换。
local NativeSpellList = {}
ns.NativeSpellList = NativeSpellList

local ICON_PATH = "Interface\\Icons\\"

local function Icon(icon)
    if type(icon) == "string" and icon ~= "" and not icon:find("\\", 1, true) then
        return ICON_PATH .. icon
    end
    return icon or 134400
end

-- 暴雪技能书的说明文字（“%d级可学”“可训练”），客户端没有时用本地化表
local function AvailableAt(level)
    return (SPELLBOOK_AVAILABLE_AT or L["Level %d"]):format(level)
end

local function Trainable()
    return SPELLBOOK_TRAINABLE or L["Train now"]
end

--------------------------------------------------------------------------------
-- 条目：暴雪 SpellBookItemTemplate。它的方法都先检查 spellBookItemInfo，我们不给这个字段，
-- 所以暴雪的施法、拖动、动作条提示都不会对我们的条目生效；外观按暴雪“未学 / 可训练”的样子画
--------------------------------------------------------------------------------

local function ItemEnter(button)
    local frame = button:GetParent()
    local data = frame.wowHandbook
    if not data then
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if data.spellID and GameTooltip.SetSpellByID then
        GameTooltip:SetSpellByID(data.spellID)
    else
        GameTooltip:SetText(data.name or "", 1, 1, 1)
    end
    for _, line in ipairs(data.lines or {}) do
        GameTooltip:AddLine(line[1], line[2], line[3], line[4], true)
    end
    GameTooltip:Show()
    button.IconHighlight:Show()
    frame.Backplate:SetAlpha(frame.hoverBackplateAlpha or 1)
end

local function ItemLeave(button)
    local frame = button:GetParent()
    GameTooltip_Hide()
    button.IconHighlight:Hide()
    frame.Backplate:SetAlpha(frame.defaultBackplateAlpha or 0.25)
end

local function ItemClick(button, mouseButton)
    local data = button:GetParent().wowHandbook
    if data and data.onClick then
        data.onClick(mouseButton)
    end
end

local function ItemInit(frame, data)
    frame.wowHandbook = data
    local art = SpellBookItemMixin and SpellBookItemMixin.ArtSet and SpellBookItemMixin.ArtSet.Square
    local button = frame.Button
    local dim = not data.ready

    frame.Name:SetText(data.name or "")
    frame.SubName:SetText(data.sub or "")
    frame.RequiredLevel:SetText(data.note or "")
    frame.RequiredLevel:SetShown((data.note or "") ~= "")
    local alpha = dim and (frame.unlearnedTextAlpha or 0.6) or 1
    frame.Name:SetAlpha(alpha)
    frame.SubName:SetAlpha(alpha)
    frame.RequiredLevel:SetAlpha(alpha)

    button.Icon:SetTexture(Icon(data.icon))
    button.Icon:SetDesaturated(dim)
    if dim and SPELLBOOK_UNLEARNED_TINT_COLOR then
        button.Icon:SetVertexColor(SPELLBOOK_UNLEARNED_TINT_COLOR:GetRGB())
    else
        button.Icon:SetVertexColor(1, 1, 1)
    end
    button.Icon:SetAlpha(dim and (frame.unlearnedIconAlpha or 0.6) or 1)
    if art then
        frame.artSet = art
        if art.iconMask then
            button.IconMask:SetAtlas(art.iconMask, true)
            button.IconMask:Show()
        end
        button.IconHighlight:SetAtlas(art.iconHighlight, true)
        frame:ApplyBorderArt(dim and art.inactiveBorder or art.activeBorder,
            dim and art.inactiveBorderAnchors or art.activeBorderAnchors)
        -- 现在就能学的：暴雪“需要训练”的底板与阴影
        if data.trainable and art.trainableBackplate then
            button.TrainableBackplate:SetAtlas(art.trainableBackplate, true)
        end
    end
    button.TrainableShadow:SetShown(data.trainable and true or false)
    button.TrainableBackplate:SetShown(data.trainable and true or false)
    button.IconHighlight:Hide()
    frame.Backplate:SetAlpha(frame.defaultBackplateAlpha or 0.25)

    -- 鼠标交互全部换成我们的（这是我们自己的框架）
    button:SetScript("OnEnter", ItemEnter)
    button:SetScript("OnLeave", ItemLeave)
    button:SetScript("OnClick", ItemClick)
    button:SetScript("OnMouseDown", nil)
    button:SetScript("OnMouseUp", nil)
    button:SetScript("OnDragStart", nil)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:UpdateTextContainer()
end

local function ItemReset(_, frame)
    frame.wowHandbook = nil
    frame:Hide()
    frame:ClearAllPoints()
end

local function HeaderInit(frame, data)
    frame.Text:SetText(data.text or "")
end

local TEMPLATES = {
    HEADER = { template = "SpellBookHeaderTemplate", initFunc = HeaderInit },
    SPELL = { template = "SpellBookItemTemplate", initFunc = ItemInit, resetFunc = ItemReset },
}

--------------------------------------------------------------------------------
-- 数据
--------------------------------------------------------------------------------

local function Group(groups, text)
    local group = { header = { templateKey = "HEADER", text = text }, elements = {} }
    tinsert(groups, group)
    return group
end

local function LinkSpell(spellID, mouseButton)
    if mouseButton == "LeftButton" and IsModifiedClick and IsModifiedClick("CHATLINK") and spellID then
        local link = C_Spell and C_Spell.GetSpellLink and C_Spell.GetSpellLink(spellID)
        if link and ChatEdit_InsertLink then
            ChatEdit_InsertLink(link)
        end
    end
end

local function SpellElement(row)
    local level = row.level
    -- 没召唤过的恶魔：到了等级就当作可买魔典来画，提示里请玩家召唤一次确认
    local reached = level <= ns.PlayerLevel()
    local unchecked = row.status == "unchecked"
    local ready = row.status == "ready" or row.status == "book" or (unchecked and reached)
    local note
    if row.status == "ready" then
        note = Trainable()
    elseif row.status == "book" or (unchecked and reached) then
        note = L["Grimoire"]
    else
        note = AvailableAt(level)
    end
    local sub = row.rank ~= "" and (L["Rank %d"]):format(row.rankNumber) or ""
    local lines = {}
    if row.pet and row.status ~= "later" and not (unchecked and not reached) then
        tinsert(lines, { L["Learned from a grimoire sold by demon trainers."], 1, 0.82, 0 })
    end
    if unchecked then
        tinsert(lines, { L["Summon this demon once to check"], 0.54, 0.51, 0.45 })
    end
    return {
        templateKey = "SPELL",
        name = ns.Name(row.spell.name) or "?",
        sub = sub,
        note = note,
        icon = row.spell.icon,
        spellID = row.id,
        ready = ready,
        trainable = row.status == "ready",
        lines = lines,
        onClick = function(mouseButton)
            LinkSpell(row.id, mouseButton)
        end,
    }
end

-- 按等级学习：现在可学的一组，之后按学习等级分组；术士另列恶魔技能
function NativeSpellList.SpellGroups()
    local spellbook = ns.modules.Spellbook
    local groups = {}
    if not spellbook then
        return groups
    end
    local ready, byLevel, levels = nil, {}, {}
    for _, row in ipairs(spellbook.Rows(false)) do
        if row.status == "ready" then
            ready = ready or Group(groups, Trainable())
            tinsert(ready.elements, SpellElement(row))
        elseif row.status == "later" then
            if not byLevel[row.level] then
                byLevel[row.level] = { header = { templateKey = "HEADER", text = (L["Level %d"]):format(row.level) },
                    elements = {} }
                tinsert(levels, row.level)
            end
            tinsert(byLevel[row.level].elements, SpellElement(row))
        end
    end
    table.sort(levels)
    for _, level in ipairs(levels) do
        tinsert(groups, byLevel[level])
    end
    -- 恶魔技能：每只恶魔一组（Rows 已按恶魔、等级排好）。还没学的都列出：到等级可买魔典的、没到等级的，
    -- 以及这只恶魔还没召唤过、不知道学没学的（按到没到等级显示，鼠标提示请玩家召唤一次）
    local demonGroups = {}
    for _, row in ipairs(spellbook.Rows(true)) do
        if row.status == "book" or row.status == "later" or row.status == "unchecked" then
            local key = row.pet or "?"
            if not demonGroups[key] then
                demonGroups[key] = Group(groups, (L["Demon abilities: %s"]):format(key))
            end
            tinsert(demonGroups[key].elements, SpellElement(row))
        end
    end
    return groups
end

--------------------------------------------------------------------------------
-- 列表框架
--------------------------------------------------------------------------------

-- 跟随暴雪技能书的单页 / 双页（收起时一页）
local function SyncMinimized(list)
    local minimized = list.book.isMinimized and true or false
    if list.minimized ~= minimized then
        list.minimized = minimized
        list:SetViewsPerPage(minimized and 1 or 2, true)
        list.View2:SetShown(not minimized)
    end
end

-- book：暴雪技能书框架（PlayerSpellsFrame.SpellBookFrame）
function NativeSpellList.Create(book)
    local list = CreateFrame("Frame", nil, book, "WowHandbookSpellListTemplate")
    list.book = book
    list:SetPoint("TOPLEFT", 0, -50)
    list:SetPoint("BOTTOMRIGHT")
    list:SetElementTemplateData(TEMPLATES)
    list:EnableMouse(true)
    list:Hide()
    if type(book.SetMinimized) == "function" then
        hooksecurefunc(book, "SetMinimized", function()
            if list:IsShown() then
                SyncMinimized(list)
            end
        end)
    end

    -- kind = "spells"（目前只有这一页）
    function list:ShowKind(kind)
        self.kind = kind
        local native = self.book.PagedSpellsFrame
        self:SetFrameLevel((native and native:GetFrameLevel() or self.book:GetFrameLevel()) + 5)
        self:Show()
        if native then
            native:Hide()
        end
        SyncMinimized(self)
        self:Refresh()
    end

    function list:Refresh()
        if not (self.kind and self:IsShown()) then
            return
        end
        local groups = NativeSpellList.SpellGroups()
        if #groups == 0 then
            groups = { { header = { templateKey = "HEADER", text = L["Nothing left to learn. Well done!"] }, elements = {} } }
        end
        self:SetDataProvider(CreateDataProvider(groups), self.shownKind == self.kind)
        self.shownKind = self.kind
    end

    -- 收起：还原暴雪自己的列表
    function list:Close()
        self.kind = nil
        if self:IsShown() then
            self:Hide()
        end
        local native = self.book.PagedSpellsFrame
        if native and not native:IsShown() then
            native:Show()
        end
    end
    return list
end
