local ADDON_NAME, ns = ...

-- 自动任务：和 NPC 对话时自动接任务、自动交任务，两项可分别开关（默认都开）。
-- · 对话菜单（GOSSIP_SHOW）与任务问候（QUEST_GREETING）里：先交已完成的，再接可接的（灰色任务不自动接）。
-- · 任务说明（QUEST_DETAIL）：接受。进行中（QUEST_PROGRESS）：能交就继续。
-- · 奖励（QUEST_COMPLETE）：只有一个或没有可选奖励时直接交；有多个可选奖励时按 rewardMode：
--   manual（默认）留给玩家自己选；usable 先在能用的奖励里挑卖价最高的，都用不了就挑卖价最高的。
--   卖价要等物品信息到达，最多等 1.5 秒；仍取不到的按 0 算。
-- · 按住 Shift 和 NPC 对话时本次不自动；需要交钱的任务不自动交。
-- · 同一次对话里不重复：每个任务的每一步（对话里点开接 / 接受 / 对话里点开交 / 继续 / 领奖励）在一次对话里只自动
--   做一次，接不下（如任务日志满了）、交不了时不会反复点同一个任务，留给玩家手动处理。对话结束（对话菜单与
--   任务窗口都关了）后清掉记录，再去点这个 NPC 会重新自动处理一次（用户 2026-10-01 明确：不重复指的是短时间内
--   不反复交，不是整次登录只试一次）。游戏确认接下（QUEST_ACCEPTED）或交付（QUEST_TURNED_IN）后也清掉记录。
-- · 自动操作都推迟到下一帧：先让其他插件（任务助手、数据采集等）读完这次窗口的内容，再接受或交付；
--   执行前确认窗口还开着（期间玩家自己点过就不重复操作）。
local Module = ns:NewModule("AutoQuest", { autoAccept = true, autoTurnIn = true, rewardMode = "manual" })

local PRICE_WAIT, PRICE_TRIES = 0.5, 3

local function Settings()
    return ns:GetModuleSettings(Module)
end

-- 已经自动尝试过的步骤：tried[步骤][任务键] = true。任务键优先用任务 ID，取不到用标题
local tried = { pickAccept = {}, accept = {}, pickTurnIn = {}, progress = {}, reward = {} }
local ACCEPT_STEPS = { "pickAccept", "accept" }
local TURN_IN_STEPS = { "pickTurnIn", "progress", "reward" }

-- 这一步没试过就记下并返回 true；试过返回 false
local function Once(step, key)
    if key == nil or tried[step][key] then
        return false
    end
    tried[step][key] = true
    return true
end
Module.tried = tried -- 供测试使用

-- 成功后清掉这个任务在这些步骤上的记录（按 ID 与标题两种键）
local function Forget(steps, questID)
    local title = questID and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
    for _, step in ipairs(steps) do
        tried[step][questID or false] = nil
        if title then
            tried[step][title] = nil
        end
    end
end

-- 对话结束：对话菜单与任务窗口都关了。窗口在一次对话里会来回切换（点任务时对话菜单先关、任务窗口再开），
-- 所以关闭事件后等一会儿再看，两个窗口都不在才算结束，清掉全部记录
local END_DELAY = 1
local endPending = false
local function OnWindowClosed()
    if endPending then
        return
    end
    endPending = true
    C_Timer.After(END_DELAY, function()
        endPending = false
        if (GossipFrame and GossipFrame:IsShown()) or (QuestFrame and QuestFrame:IsShown()) then
            return
        end
        for _, steps in pairs(tried) do
            wipe(steps)
        end
    end)
end

-- 当前任务窗口里的任务键
local function WindowQuestKey()
    local questID = GetQuestID and GetQuestID()
    if questID and questID ~= 0 then
        return questID
    end
    return GetTitleText and GetTitleText() or nil
end

-- 按住 Shift：本次交给玩家自己操作
local function Paused()
    return IsShiftKeyDown and IsShiftKeyDown()
end

-- 对话菜单：先交已完成的任务，再接新任务。每次只点一个，游戏打开任务窗口后流程继续
local function OnGossip()
    local settings = Settings()
    if Paused() or not C_GossipInfo then
        return
    end
    if settings.autoTurnIn and C_GossipInfo.GetActiveQuests then
        for _, quest in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
            if quest.isComplete and quest.questID and Once("pickTurnIn", quest.questID) then
                C_GossipInfo.SelectActiveQuest(quest.questID)
                return
            end
        end
    end
    if settings.autoAccept and C_GossipInfo.GetAvailableQuests then
        for _, quest in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
            if not quest.isTrivial and quest.questID and Once("pickAccept", quest.questID) then
                C_GossipInfo.SelectAvailableQuest(quest.questID)
                return
            end
        end
    end
end

-- 任务问候（有多个任务、没有对话选项的 NPC）：同样先交后接
local function OnGreeting()
    local settings = Settings()
    if Paused() then
        return
    end
    if settings.autoTurnIn and GetNumActiveQuests then
        for index = 1, GetNumActiveQuests() do
            local title, isComplete = GetActiveTitle(index)
            local key = GetActiveQuestID and GetActiveQuestID(index) or title
            if isComplete and Once("pickTurnIn", key) then
                SelectActiveQuest(index)
                return
            end
        end
    end
    if settings.autoAccept and GetNumAvailableQuests then
        for index = 1, GetNumAvailableQuests() do
            local info = GetAvailableQuestInfo and { GetAvailableQuestInfo(index) } or {}
            local isTrivial, questID = info[1], info[5]
            local key = questID or (GetAvailableTitle and GetAvailableTitle(index))
            if not isTrivial and Once("pickAccept", key) then
                SelectAvailableQuest(index)
                return
            end
        end
    end
end

local function OnDetail()
    if not Settings().autoAccept or Paused() then
        return
    end
    -- 进入区域自动接的任务游戏已经接了，只需确认
    if not Once("accept", WindowQuestKey()) then
        return
    end
    if QuestGetAutoAccept and QuestGetAutoAccept() then
        if AcknowledgeAutoAcceptQuest then
            AcknowledgeAutoAcceptQuest()
        end
        return
    end
    AcceptQuest()
end

local function OnProgress()
    if Settings().autoTurnIn and not Paused() and IsQuestCompletable() and Once("progress", WindowQuestKey()) then
        CompleteQuest()
    end
end

-- 可选奖励里挑一个：能用的优先，其中卖价最高的；都不能用就挑卖价最高的。
-- 返回序号与是否所有卖价都已取到
local function PickReward()
    local best, bestUsable, bestPrice, complete = nil, false, -1, true
    for index = 1, GetNumQuestChoices() do
        local _, _, _, _, isUsable = GetQuestItemInfo("choice", index)
        local link = GetQuestItemLink("choice", index)
        local price = link and select(11, C_Item.GetItemInfo(link))
        if price == nil then
            complete = false
            price = 0
        end
        local usable = isUsable and true or false
        if not best or (usable and not bestUsable) or (usable == bestUsable and price > bestPrice) then
            best, bestUsable, bestPrice = index, usable, price
        end
    end
    return best, complete
end
Module.PickReward = PickReward -- 供测试使用

local function OnComplete()
    local settings = Settings()
    if not settings.autoTurnIn or Paused() then
        return
    end
    if GetQuestMoneyToGet and GetQuestMoneyToGet() > 0 then
        return
    end
    local choices = GetNumQuestChoices()
    if choices > 1 and settings.rewardMode ~= "usable" then
        return -- 手动：留给玩家自己选
    end
    if not Once("reward", WindowQuestKey()) then
        return
    end
    if choices <= 1 then
        GetQuestReward(choices == 1 and 1 or nil)
        return
    end
    -- 卖价要等物品信息到达：最多等 PRICE_TRIES 次，每次 PRICE_WAIT 秒；窗口关了就不再选
    local tries = 0
    local function Try()
        if not (QuestFrame and QuestFrame:IsShown()) or GetNumQuestChoices() ~= choices then
            return
        end
        local index, complete = PickReward()
        tries = tries + 1
        if complete or tries >= PRICE_TRIES then
            GetQuestReward(index)
        else
            C_Timer.After(PRICE_WAIT, Try)
        end
    end
    Try()
end

-- 推迟到下一帧，且窗口仍开着才执行（对话菜单看 GossipFrame，任务窗口看 QuestFrame）
local function NextFrame(handler, frameName)
    return function()
        C_Timer.After(0, function()
            local frame = _G[frameName]
            if frame and not frame:IsShown() then
                return
            end
            handler()
        end)
    end
end

function Module:OnEnable()
    -- 游戏确认成功后清掉记录，同一个任务以后（如可重复任务）还能再自动处理
    ns:RegisterEvent("QUEST_ACCEPTED", function(_, questID)
        Forget(ACCEPT_STEPS, questID)
    end)
    ns:RegisterEvent("QUEST_TURNED_IN", function(_, questID)
        Forget(TURN_IN_STEPS, questID)
    end)
    ns:RegisterEvent("GOSSIP_CLOSED", OnWindowClosed)
    ns:RegisterEvent("QUEST_FINISHED", OnWindowClosed)
    ns:RegisterEvent("GOSSIP_SHOW", NextFrame(OnGossip, "GossipFrame"))
    ns:RegisterEvent("QUEST_GREETING", NextFrame(OnGreeting, "QuestFrame"))
    ns:RegisterEvent("QUEST_DETAIL", NextFrame(OnDetail, "QuestFrame"))
    ns:RegisterEvent("QUEST_PROGRESS", NextFrame(OnProgress, "QuestFrame"))
    ns:RegisterEvent("QUEST_COMPLETE", NextFrame(OnComplete, "QuestFrame"))
end
