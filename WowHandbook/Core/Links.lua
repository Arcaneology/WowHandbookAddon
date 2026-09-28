local ADDON_NAME, ns = ...
local L = ns.L

-- 网站地址统一在这里生成，模块不得自行拼接。
local Links = {}
ns.Links = Links

local BASE_URL = "https://wowhandbook.com"

-- 网站路由：英文无前缀，中文在 /zh/ 下；网站路由变更时同步修改这里。
local ROUTES = {
    home = "/",
    dungeon = "/zones/dungeons/%s/", -- 副本 slug，如 "deadmines"
    raid = "/zones/raids/%s/",       -- 团队副本 slug，如 "molten-core"
    quest = "/quests/%d/",           -- 任务 ID，网站重定向到所属副本页
    spellbook = "/spellbook/%s/",    -- 职业 slug，如 "mage"
}

local function LocalePrefix()
    if ns:IsLocale("zhCN", "zhTW") then
        return "/zh"
    end
    return ""
end

local function ValidArgument(kind, argument)
    if kind == "quest" then
        return type(argument) == "number" and argument > 0
    end
    return type(argument) == "string" and argument:match("^[%w%-]+$") ~= nil
end

-- Links:Build("dungeon", "deadmines") -> https://wowhandbook.com/zh/zones/dungeons/deadmines/
function Links:Build(kind, argument)
    local route = ROUTES[kind]
    assert(route, "unknown link kind: " .. tostring(kind))
    local path = route
    if route:find("%%") then
        assert(ValidArgument(kind, argument), "invalid argument for link kind " .. kind)
        path = route:format(argument)
    end
    return BASE_URL .. LocalePrefix() .. path
end

--------------------------------------------------------------------------------
-- 复制链接对话框：游戏无法直接打开浏览器，只能让玩家复制地址。
--------------------------------------------------------------------------------

local dialog

local function CopyShortcut()
    if IsMacClient and IsMacClient() then
        return "Cmd+C"
    end
    return "Ctrl+C"
end

local function CreateDialog()
    local Theme, UI = ns.Theme, ns.UI
    local frame = CreateFrame("Frame", "WowHandbookLinkDialog", UIParent, "BackdropTemplate")
    frame:SetSize(480, 132)
    frame:SetPoint("CENTER", 0, 120)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    Theme:Skin(frame, "window", "line")
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName()) -- Esc 关闭

    local topLine = frame:CreateTexture(nil, "OVERLAY")
    topLine:SetPoint("TOPLEFT", 1, -1)
    topLine:SetPoint("TOPRIGHT", -1, -1)
    topLine:SetHeight(2)
    topLine:SetColorTexture(unpack(Theme.colors.gold))

    local title = UI:Text(frame, "Heading", L["Website link"])
    title:SetPoint("TOPLEFT", 18, -16)

    local close = UI:CloseButton(frame, function()
        frame:Hide()
    end)
    close:SetPoint("TOPRIGHT", -8, -8)

    local hint = UI:Text(frame, "Small")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    frame.hint = hint

    local editBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    editBox:SetHeight(30)
    editBox:SetPoint("BOTTOMLEFT", 18, 18)
    editBox:SetPoint("BOTTOMRIGHT", -18, 18)
    Theme:Skin(editBox, "panel", "goldDim")
    editBox:SetFontObject(Theme.fonts.Body)
    editBox:SetTextInsets(10, 10, 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    -- 只读：玩家误改内容时恢复原地址并重新全选。
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and frame.url then
            self:SetText(frame.url)
            self:HighlightText()
        end
    end)
    -- 复制后自动关闭。等下一帧再关，确保系统先完成复制。
    editBox:SetScript("OnKeyDown", function(_, key)
        local modifierDown = IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())
        if key == "C" and modifierDown then
            C_Timer.After(0, function()
                frame:Hide()
            end)
        end
    end)
    frame.editBox = editBox

    return frame
end

function Links:ShowCopyDialog(url)
    dialog = dialog or CreateDialog()
    dialog.url = url
    dialog.hint:SetText(L["Press %s to copy, then paste it into your browser."]:format(CopyShortcut()))
    dialog:Show()
    dialog.editBox:SetText(url)
    dialog.editBox:SetCursorPosition(0)
    dialog.editBox:SetFocus()
    dialog.editBox:HighlightText()
end
