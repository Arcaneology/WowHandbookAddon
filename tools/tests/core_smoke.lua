-- 在游戏外用最小 WoW API 桩运行核心文件，验证加载顺序、本地化回退、链接生成、事件与模块启用。
-- 用法（仓库根目录）：lua tools/tests/core_smoke.lua
-- 这不能代替游戏内验证：界面模板、真实事件与客户端行为只能在 Forever 客户端里确认。

local locale = arg[1] or "enUS"

unpack = unpack or table.unpack
tinsert = table.insert
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
UISpecialFrames = {}
SlashCmdList = {}
local printed = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) table.insert(printed, msg) end }
GetLocale = function() return locale end
C_AddOns = { GetAddOnMetadata = function() return "0.1.0-test" end }

-- 主题字体：只需能创建并设置
CreateFont = function(name)
    local font = {}
    function font.SetFontObject() end
    function font.SetTextColor() end
    function font.GetName() return name end
    return font
end

local eventFrame
CreateFrame = function()
    local f = { events = {}, scripts = {} }
    function f:RegisterEvent(e) self.events[e] = true end
    function f:UnregisterEvent(e) self.events[e] = nil end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    eventFrame = eventFrame or f
    return f
end

local function fire(event, ...)
    if eventFrame.events[event] then
        eventFrame.scripts.OnEvent(eventFrame, event, ...)
    end
end

-- 按 TOC 顺序加载
local ns = {}
local root = "WowHandbook/"
local toc = assert(io.open(root .. "WowHandbook.toc")):read("a")
for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^##") and line:match("%.lua$") then
        local chunk = assert(loadfile(root .. line:gsub("\\", "/")))
        chunk("WowHandbook", ns)
    end
end

local failures = 0
local function check(name, ok)
    print((ok and "PASS " or "FAIL ") .. name)
    if not ok then failures = failures + 1 end
end

-- 本地化
local L = ns.L
check("missing key falls back to key", L["__missing__"] == "__missing__")
if locale == "zhCN" then
    check("zhCN translation loaded", L["Copy website link"] == "复制网站链接")
else
    check("enUS key maps to itself", L["Copy website link"] == "Copy website link")
end

-- 链接
local prefix = (locale == "zhCN" or locale == "zhTW") and "/zh" or ""
check("home link", ns.Links:Build("home") == "https://wowhandbook.com" .. prefix .. "/")
check("dungeon link", ns.Links:Build("dungeon", "deadmines")
    == "https://wowhandbook.com" .. prefix .. "/zones/dungeons/deadmines/")
check("quest link", ns.Links:Build("quest", 17) == "https://wowhandbook.com" .. prefix .. "/quests/17/")
check("invalid slug rejected", not pcall(ns.Links.Build, ns.Links, "dungeon", "../x"))
check("unknown kind rejected", not pcall(ns.Links.Build, ns.Links, "nope"))

-- 模块与存档
local enabledCount = 0
local mod = ns:NewModule("Test", { size = 3 })
function mod:OnEnable() enabledCount = enabledCount + 1 end
local off = ns:NewModule("Off")
function off:OnEnable() error("disabled module must not enable") end

WowHandbookDB = { modules = { Off = { enabled = false } } }
fire("ADDON_LOADED", "SomethingElse")
check("db untouched before own ADDON_LOADED", ns.db == nil)
fire("ADDON_LOADED", "WowHandbook")
check("db initialised", ns.db == WowHandbookDB and ns.db.schemaVersion == 1)
fire("PLAYER_LOGIN")
check("module enabled once", enabledCount == 1 and mod.enabled)
check("module defaults applied", ns.db.modules.Test.size == 3 and ns.db.modules.Test.enabled == true)
check("player-disabled module stays off", not off.enabled)
check("login handler unregistered", eventFrame.events.PLAYER_LOGIN == nil)

-- 主窗口标签页接口
check("public API exposed", type(WowHandbookAPI) == "table" and type(WowHandbookAPI.RegisterTab) == "function")
check("home tab registered", ns.MainFrame:HasTab("home"))
check("no collected-data tab without the collector", not ns.MainFrame:HasTab("collected"))
WowHandbookAPI.RegisterTab({ id = "extra", title = "Extra", create = function() end })
check("external tab registered", ns.MainFrame:HasTab("extra"))

-- 事件：一个处理函数出错不影响同一事件的其他处理函数，同一条错误只报告一次（R09）
local reported, secondRan = {}, 0
geterrorhandler = function() return function(message) table.insert(reported, message) end end
ns:RegisterEvent("TEST_EVENT", function() error("boom") end)
ns:RegisterEvent("TEST_EVENT", function() secondRan = secondRan + 1 end)
fire("TEST_EVENT")
fire("TEST_EVENT")
check("failing handler does not stop the next one", secondRan == 2)
check("handler error reported once with the event name", #reported == 1 and reported[1]:find("TEST_EVENT", 1, true) ~= nil)
geterrorhandler = nil

-- 斜杠命令
SlashCmdList.WOWHANDBOOK("bogus")
check("unknown command prints help", #printed >= 2)

if failures > 0 then
    print(failures .. " check(s) failed")
    os.exit(1)
end
print("all checks passed (" .. locale .. ")")
