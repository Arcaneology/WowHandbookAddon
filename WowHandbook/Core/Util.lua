local ADDON_NAME, ns = ...
local L = ns.L

-- 通用工具：按客户端语言取名字、玩家阵营 / 职业 / 等级、等级配色、地图名、钱币格式。

-- 数据里的名字表 { enUS = "...", zhCN = "..." }：取当前语言，没有就取英文
function ns.Name(names)
    if type(names) ~= "table" then
        return names
    end
    return names[ns.locale] or names.enUS or select(2, next(names))
end

-- "A" / "H"
function ns.PlayerFaction()
    local faction = UnitFactionGroup("player")
    return faction == "Alliance" and "A" or (faction == "Horde" and "H" or nil)
end

-- 数据里的职业键：warrior、mage ……
function ns.PlayerClass()
    local _, classFile = UnitClass("player")
    return classFile and classFile:lower()
end

function ns.PlayerLevel()
    return UnitLevel("player") or 1
end

-- 等级区间相对玩家等级的颜色：灰（太低）、绿、黄（合适）、橙、红（太高）
function ns.LevelColor(minLevel, maxLevel)
    local level = ns.PlayerLevel()
    minLevel = minLevel or maxLevel or level
    maxLevel = maxLevel or minLevel
    if level > maxLevel + 5 then
        return "ff9d9d9d"
    elseif level > maxLevel then
        return "ff46bf72"
    elseif level >= minLevel then
        return "ffe0b458"
    elseif level >= minLevel - 3 then
        return "ffff9933"
    end
    return "ffd8664a"
end

function ns.LevelRange(levels)
    if not levels then
        return nil
    end
    if levels[1] == levels[2] then
        return tostring(levels[1])
    end
    return ("%d-%d"):format(levels[1], levels[2])
end

function ns.MapName(uiMapID)
    if not uiMapID then
        return nil
    end
    local info = C_Map.GetMapInfo(uiMapID)
    if info and info.name then
        return info.name
    end
    local zone = ns.Data.zones[uiMapID]
    return zone and ns.Name(zone.name) or tostring(uiMapID)
end

function ns.Money(copper)
    if not copper or copper <= 0 then
        return nil
    end
    if GetMoneyString then
        return GetMoneyString(copper)
    end
    return ("%dg %ds %dc"):format(floor(copper / 10000), floor(copper / 100) % 100, copper % 100)
end

-- 物品链接（客户端还没缓存时显示“物品 ID”，数据到了会在下一次刷新时补上）
function ns.ItemLink(itemID)
    local _, link = C_Item.GetItemInfo(itemID)
    return link or ("|cff9d9d9d[" .. L["Item"] .. " " .. itemID .. "]|r")
end

-- 任务标题：优先用客户端（按客户端语言），没有就请求加载并先用数据里的名字
local requestedQuests = {}
function ns.QuestTitle(questID)
    local title = C_QuestLog.GetTitleForQuestID(questID)
    if title and title ~= "" then
        return title
    end
    if not requestedQuests[questID] and C_QuestLog.RequestLoadQuestByID then
        requestedQuests[questID] = true
        C_QuestLog.RequestLoadQuestByID(questID)
    end
    local quest = ns.Data.quests[questID]
    return quest and ns.Name(quest.name) or (L["Quest"] .. " " .. questID)
end

-- 任务状态：done（已完成）、active（在任务日志里）、available（可接）、low（等级不够）、faction（对方阵营）
function ns.QuestStatus(questID)
    local quest = ns.Data.quests[questID]
    if C_QuestLog.IsQuestFlaggedCompleted(questID) then
        return "done"
    end
    if C_QuestLog.GetLogIndexForQuestID(questID) then
        return "active"
    end
    if quest then
        local faction = ns.PlayerFaction()
        if quest.faction and faction and quest.faction ~= faction then
            return "faction"
        end
        if quest.min and ns.PlayerLevel() < quest.min then
            return "low"
        end
    end
    return "available"
end
