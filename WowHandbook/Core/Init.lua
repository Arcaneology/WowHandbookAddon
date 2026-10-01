local ADDON_NAME, ns = ...
local L = ns.L

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
ns.version = GetMetadata(ADDON_NAME, "Version") or "dev"

--------------------------------------------------------------------------------
-- 输出
--------------------------------------------------------------------------------

function ns:Print(message, ...)
    if select("#", ...) > 0 then
        message = message:format(...)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff46bf72" .. L["WoW Handbook"] .. "|r: " .. tostring(message))
end

--------------------------------------------------------------------------------
-- 事件：全插件共用一个事件框架，模块通过 ns:RegisterEvent 订阅
--------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local handlers = {} -- [event] = { handler, ... }

-- 客户端认不认识这个事件：各版本客户端的事件不完全相同（Forever 没有 TRADE_SKILL_UPDATE），
-- 注册未知事件会报错，所以先查；没有查询接口时照常注册
function ns.IsEventValid(event)
    if C_EventUtils and C_EventUtils.IsEventValid then
        return C_EventUtils.IsEventValid(event) and true or false
    end
    return true
end

-- 订阅事件；客户端不认识的事件跳过并返回 false，不影响模块其余部分
function ns:RegisterEvent(event, handler)
    local list = handlers[event]
    if not list then
        if not ns.IsEventValid(event) or not pcall(eventFrame.RegisterEvent, eventFrame, event) then
            return false
        end
        list = {}
        handlers[event] = list
    end
    for _, existing in ipairs(list) do
        if existing == handler then
            return true
        end
    end
    tinsert(list, handler)
    return true
end

function ns:UnregisterEvent(event, handler)
    local list = handlers[event]
    if not list then
        return
    end
    for i = #list, 1, -1 do
        if list[i] == handler then
            table.remove(list, i)
        end
    end
    if #list == 0 then
        handlers[event] = nil
        eventFrame:UnregisterEvent(event)
    end
end

-- 一个处理函数出错不影响同一事件的其他处理函数：错误交给游戏的错误处理（开了 scriptErrors 会弹出），
-- 同一条错误每个会话只报告一次，避免高频事件刷屏。
local reportedErrors = {}
local function ReportHandlerError(event, err)
    local message = ("WoW Handbook %s: %s"):format(event, tostring(err))
    if reportedErrors[message] then
        return
    end
    reportedErrors[message] = true
    local handler = geterrorhandler and geterrorhandler()
    if handler then
        handler(message)
    else
        ns:Print(message)
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then
        return
    end
    -- 复制一份再遍历：处理函数里注册或注销事件不会打乱本轮分发。
    local snapshot = { unpack(list) }
    for _, handler in ipairs(snapshot) do
        local ok, err = pcall(handler, event, ...)
        if not ok then
            ReportHandlerError(event, err)
        end
    end
end)

--------------------------------------------------------------------------------
-- 存档
--------------------------------------------------------------------------------

local DB_SCHEMA = 1
local CHAR_DB_SCHEMA = 1

local DB_DEFAULTS = {
    modules = {},
    -- 外观：配色方案（class 跟随当前角色的职业）与主窗口背景不透明度（百分数）
    appearance = { scheme = "class", opacity = 100 },
}

local CHAR_DB_DEFAULTS = {}

-- 只补缺失的键，不覆盖玩家已有设置。
local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

-- 存档结构变化时，在这里按版本号逐级迁移。
local function Migrate(db, currentSchema)
    db.schemaVersion = db.schemaVersion or currentSchema
end

local function InitSavedVariables()
    WowHandbookDB = WowHandbookDB or {}
    WowHandbookCharDB = WowHandbookCharDB or {}
    Migrate(WowHandbookDB, DB_SCHEMA)
    Migrate(WowHandbookCharDB, CHAR_DB_SCHEMA)
    ApplyDefaults(WowHandbookDB, DB_DEFAULTS)
    ApplyDefaults(WowHandbookCharDB, CHAR_DB_DEFAULTS)
    ns.db = WowHandbookDB
    ns.charDB = WowHandbookCharDB
    -- 界面语言：设置里选的（默认跟随客户端），在任何模块启用、界面创建之前生效
    ns:ApplyLanguage(ns.db.language)
    ns:ApplyAppearance()
end

-- 按存档应用配色方案与背景透明度（主题在 UI/Theme.lua，界面创建之前与设置改动时调用）
function ns:ApplyAppearance()
    if self.Theme and self.Theme.Apply then
        local appearance = self.db.appearance
        self.Theme:Apply(appearance.scheme, appearance.opacity)
    end
end

--------------------------------------------------------------------------------
-- 模块：每个功能一个模块，可在设置中单独开关
--------------------------------------------------------------------------------

ns.modules = {}
local moduleOrder = {}

function ns:NewModule(name, defaults)
    assert(not self.modules[name], "module already exists: " .. name)
    local module = {
        name = name,
        defaults = defaults or {},
        enabled = false,
    }
    self.modules[name] = module
    tinsert(moduleOrder, name)
    return module
end

-- 模块设置：ns.db.modules[name]，其中 enabled 为 false 表示玩家关闭了该模块。
function ns:GetModuleSettings(module)
    return self.db.modules[module.name]
end

function ns:EnableModule(module)
    if module.enabled then
        return
    end
    module.enabled = true
    self:GetModuleSettings(module).enabled = true
    if module.OnEnable then
        -- 一个模块出错不影响其他模块：报告错误（走游戏的错误处理，开了 scriptErrors 会弹出）后继续
        local ok, err = pcall(module.OnEnable, module)
        if not ok then
            module.enabled = false
            local handler = geterrorhandler and geterrorhandler()
            if handler then
                handler(("WoW Handbook module %s: %s"):format(module.name, tostring(err)))
            else
                self:Print("module %s failed: %s", module.name, tostring(err))
            end
        end
    end
end

function ns:DisableModule(module)
    if not module.enabled then
        return
    end
    module.enabled = false
    self:GetModuleSettings(module).enabled = false
    if module.OnDisable then
        module:OnDisable()
    end
end

local function EnableModules()
    for _, name in ipairs(moduleOrder) do
        local module = ns.modules[name]
        local settings = ns.db.modules[name]
        if type(settings) ~= "table" then
            settings = {}
            ns.db.modules[name] = settings
        end
        ApplyDefaults(settings, module.defaults)
        if settings.enabled == nil then
            settings.enabled = true
        end
        if settings.enabled then
            ns:EnableModule(module)
        end
    end
end

--------------------------------------------------------------------------------
-- 启动
--------------------------------------------------------------------------------

local function OnAddonLoaded(event, loadedName)
    if loadedName ~= ADDON_NAME then
        return
    end
    ns:UnregisterEvent(event, OnAddonLoaded)
    InitSavedVariables()
end

local function OnPlayerLogin(event)
    ns:UnregisterEvent(event, OnPlayerLogin)
    ns:ApplyAppearance() -- 登录时职业一定取得到：跟随职业的配色在这里定下来
    EnableModules()
end

ns:RegisterEvent("ADDON_LOADED", OnAddonLoaded)
ns:RegisterEvent("PLAYER_LOGIN", OnPlayerLogin)

--------------------------------------------------------------------------------
-- 斜杠命令：/wowhandbook 与 /wh
--------------------------------------------------------------------------------

local moduleCommands = {} -- 模块注册的子命令：{ name, help }，按注册顺序列在帮助里

local function PrintHelp()
    ns:Print(L["Commands:"])
    ns:Print("/wh - %s", L["open or close the main window"])
    ns:Print("/wh link - %s", L["copy the website link"])
    for _, command in ipairs(moduleCommands) do
        ns:Print("/wh %s - %s", command.name, command.help)
    end
    ns:Print("/wh help - %s", L["show this help"])
end

local COMMANDS = {
    [""] = function()
        ns.MainFrame:Toggle()
    end,
    link = function()
        ns.Links:ShowCopyDialog(ns.Links:Build("home"))
    end,
    help = PrintHelp,
}

-- 功能模块注册 /wh 子命令（help 为已本地化的说明）
function ns:AddCommand(name, help, run)
    if COMMANDS[name] then
        return
    end
    COMMANDS[name] = run
    tinsert(moduleCommands, { name = name, help = help })
end

SLASH_WOWHANDBOOK1 = "/wowhandbook"
SLASH_WOWHANDBOOK2 = "/wh"
SlashCmdList.WOWHANDBOOK = function(input)
    local command = strtrim(input or ""):lower()
    local run = COMMANDS[command]
    if run then
        run()
    else
        ns:Print(L["Unknown command: %s"], command)
        PrintHelp()
    end
end
