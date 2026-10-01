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

-- 首领名：数据里的掉落分组（小怪、配方、书籍）用插件自己的本地化文字，其余按语言取名
-- 值是显示用的本地化键；网站数据里少数副本把小怪写成 "Trash"
local LOOT_GROUPS = {
    ["Trash mobs"] = "Trash mobs",
    ["Trash"] = "Trash mobs",
    ["Plans and patterns"] = "Plans and patterns",
    ["Books"] = "Books",
}
-- 客户端的“秘密值”：副本、战斗等场合加密的单位身份（GUID、名字）、战斗记录内容等。
-- 插件不能比较、拆分或转成文字，遇到就当作取不到
function ns.IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) or false
end

-- 掉落表里的行不是首领（副本卡片的首领数、副本进度小窗等只算真正的首领）：
-- 导出时标了 lootOnly 的（稀有精英、物品、杂兵等），以及小怪、配方、书籍这些掉落分组
function ns.IsLootGroup(boss)
    if boss and boss.lootOnly then
        return true
    end
    local english = boss and boss.name and boss.name.enUS
    return english and LOOT_GROUPS[english] ~= nil or false
end

function ns.BossCount(dungeon)
    local n = 0
    for _, boss in ipairs(dungeon and dungeon.bosses or {}) do
        if not ns.IsLootGroup(boss) then
            n = n + 1
        end
    end
    return n
end

function ns.BossName(boss)
    local english = boss and boss.name and boss.name.enUS
    if english and LOOT_GROUPS[english] then
        return ns.L[LOOT_GROUPS[english]]
    end
    return boss and ns.Name(boss.name)
end

-- 玩家已学的专业：{ [slug] = { rank = 当前技能, max = 当前上限 } }。
-- Forever 跑在正式服引擎上：用 GetProfessions / GetProfessionInfo，按技能线 ID 对照数据里的 skillLines
-- （主技能线与其下的子技能线），对不上再按名字（客户端语言）对照。经典旧世客户端没有这组接口，
-- 改读技能列表 GetSkillLineInfo（同样按名字对照）。
function ns.ProfessionSkills()
    local learned = {}
    local byLine, byName = {}, {}
    for _, profession in ipairs(ns.Data.professions or {}) do
        for _, line in ipairs(profession.skillLines or {}) do
            byLine[line] = profession.slug
        end
        for _, name in pairs(profession.name or {}) do
            byName[name:lower()] = profession.slug
        end
    end
    if GetProfessions and GetProfessionInfo then
        for _, index in pairs({ GetProfessions() }) do
            local name, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
            local slug = byLine[skillLine] or (type(name) == "string" and byName[name:lower()])
            if slug then
                learned[slug] = { rank = rank or 0, max = maxRank or 0 }
            end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        for index = 1, GetNumSkillLines() or 0 do
            local name, header, _, rank, _, _, maxRank = GetSkillLineInfo(index)
            local slug = not header and type(name) == "string" and byName[name:lower()]
            if slug and not learned[slug] then
                learned[slug] = { rank = rank or 0, max = maxRank or 0 }
            end
        end
    end
    return learned
end

-- 专业训练师的等级：数据里的等级取自训练师头衔，是它“最高能教到”的一档，
-- 高档训练师也教低档（中级训练师也能从零教起）。
ns.TRAINER_RANK_ORDER = { apprentice = 1, journeyman = 2, expert = 3, artisan = 4, specialization = 5 }

-- 训练师等级的名字：按英文头衔里的等级词（英文头衔统一）固定对应中文，与游戏里训练师头衔的写法一致：
-- Apprentice 见习、Journeyman 初级（“初级炼金师”）、Master / Artisan 大师级（“大师级××训练师”）；
-- Expert 的中文头衔不带等级词，用客户端专业技能的“高级”。其他语言走本地化表。
local RANK_KEYS = { apprentice = "Apprentice", journeyman = "Journeyman", expert = "Expert", artisan = "Artisan",
    specialization = "Specialization" }
function ns.TrainerRankName(rank)
    return L[RANK_KEYS[rank] or rank]
end

-- 下一步要学的一档：还没学是初级，技能上限 75 学中级、150 学高级、225 学专家级；满了返回 nil
function ns.NextTrainerRank(skill)
    if not skill then
        return "apprentice"
    elseif skill.max <= 75 then
        return "journeyman"
    elseif skill.max <= 150 then
        return "expert"
    elseif skill.max <= 225 then
        return "artisan"
    end
end

-- 这些训练师里该去找的那一档：能教到下一档的训练师中，最高可教等级最低的一档（最常见、离新手区最近）。
-- 例：还没学采矿的玩家要学初级，但多数训练师头衔是“中级”，就高亮中级训练师。没有合适的返回 nil
function ns.TargetTrainerRank(trainers, skill)
    local need = ns.NextTrainerRank(skill)
    local needOrder = need and ns.TRAINER_RANK_ORDER[need]
    local best
    for _, trainer in ipairs(needOrder and trainers or {}) do
        local order = trainer.rank and ns.TRAINER_RANK_ORDER[trainer.rank]
        if order and order >= needOrder and order ~= ns.TRAINER_RANK_ORDER.specialization
            and (not best or order < ns.TRAINER_RANK_ORDER[best]) then
            best = trainer.rank
        end
    end
    return best
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

-- 职业名：取客户端的（按客户端语言）；取不到时用天赋数据里的名字。slug 为数据里的职业键
function ns.ClassName(slug)
    local names = LOCALIZED_CLASS_NAMES_MALE
    local name = names and slug and names[slug:upper()]
    if name then
        return name
    end
    local data = ns.Data and ns.Data.talents and ns.Data.talents[slug]
    return data and ns.Name(data.name) or slug
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

-- 副本入口：优先用客户端的副本入口接口（C_EncounterJournal.GetDungeonEntrancesForMap），
-- 按副本 ID 或名字对应到插件的副本；客户端没给的副本才用插件数据里的坐标。
-- 客户端入口是静态数据，按地图缓存，整个会话只查一次。
-- 名字比较用的键：小写、去掉开头的 The、空白与标点（客户端名与数据名写法略有不同时也能对上）
local function NormalizedName(name)
    if not name then
        return nil
    end
    local key = name:lower():gsub("^the ", "")
    key = key:gsub("[%s%p]", "")
    return key ~= "" and key or nil
end
ns.NormalizedName = NormalizedName

-- 客户端入口的副本 ID：EJ_GetInstanceInfo 第 10 个返回值是副本（instance）ID
local function EntranceInstanceID(entrance)
    if EJ_GetInstanceInfo and entrance.journalInstanceID then
        return select(10, EJ_GetInstanceInfo(entrance.journalInstanceID))
    end
    return nil
end

-- 副本 ID 与各语言名字 -> 副本序号列表。分区副本的父条目（aggregateOnly）对应到它的各个分区，
-- 客户端只给一个入口（如“血色修道院”）时，各分区都用这个入口。
local dungeonIndex
local function DungeonIndex()
    if dungeonIndex then
        return dungeonIndex
    end
    local byInstance, byName, children = {}, {}, {}
    local dungeons = ns.Data.dungeons or {}
    for index, dungeon in ipairs(dungeons) do
        if dungeon.parentSlug then
            children[dungeon.parentSlug] = children[dungeon.parentSlug] or {}
            tinsert(children[dungeon.parentSlug], index)
        end
    end
    for index, dungeon in ipairs(dungeons) do
        local targets = dungeon.aggregateOnly and children[dungeon.slug] or { index }
        if dungeon.instanceID then
            byInstance[dungeon.instanceID] = targets
        end
        for _, name in pairs(dungeon.name or {}) do
            local key = NormalizedName(name)
            if key then
                byName[key] = targets
            end
        end
    end
    dungeonIndex = { byInstance = byInstance, byName = byName }
    return dungeonIndex
end

local clientEntrances = {} -- [uiMapID] = { { index = 副本序号, x, y（0–1） } }
function ns.ClientDungeonEntrances(uiMapID)
    if not uiMapID then
        return {}
    end
    if clientEntrances[uiMapID] then
        return clientEntrances[uiMapID]
    end
    local found = {}
    local api = C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap
    local entrances = api and api(uiMapID)
    if entrances and #entrances > 0 then
        local index = DungeonIndex()
        for _, entrance in ipairs(entrances) do
            local targets = index.byInstance[EntranceInstanceID(entrance) or false]
                or index.byName[NormalizedName(entrance.name) or false]
            if targets and entrance.position then
                local x, y = entrance.position:GetXY()
                for _, target in ipairs(targets) do
                    tinsert(found, { index = target, x = x, y = y })
                end
            end
        end
    end
    clientEntrances[uiMapID] = found
    return found
end

local function FindOnMap(uiMapID, index)
    for _, spot in ipairs(ns.ClientDungeonEntrances(uiMapID)) do
        if spot.index == index then
            return uiMapID, spot.x * 100, spot.y * 100
        end
    end
    return nil
end

-- 副本入口的地图与坐标（0–100）：先在入口所在地图向客户端查，数据没写地图时查所有区域地图；
-- 客户端没有时用插件数据；都没有时返回 nil
function ns.DungeonEntrance(index)
    local dungeon = ns.Data.dungeons[index]
    if not dungeon then
        return nil
    end
    local entrance = dungeon.entrance
    local mapID, x, y = FindOnMap(entrance and entrance.map, index)
    if mapID then
        return mapID, x, y
    end
    if not (entrance and entrance.map) then
        for zoneMap in pairs(ns.Data.zones or {}) do
            mapID, x, y = FindOnMap(zoneMap, index)
            if mapID then
                return mapID, x, y
            end
        end
    end
    if entrance and entrance.map and entrance.x then
        return entrance.map, entrance.x, entrance.y
    end
    return nil
end

-- 地图所在的大陆名（卡利姆多、东部王国……）：沿父地图往上找到大陆，名字取客户端的（按客户端语言）。
-- 取不到时返回 nil。取到的结果按地图缓存（取不到的不缓存，下次再问客户端）。
local continentNames = {}
function ns.ContinentName(uiMapID)
    if continentNames[uiMapID] then
        return continentNames[uiMapID]
    end
    local continentType = Enum and Enum.UIMapType and Enum.UIMapType.Continent
    local info = uiMapID and C_Map.GetMapInfo(uiMapID)
    local steps = 0
    while info and continentType and info.mapType ~= continentType and info.parentMapID and info.parentMapID > 0 and steps < 6 do
        info = C_Map.GetMapInfo(info.parentMapID)
        steps = steps + 1
    end
    local name = info and continentType and info.mapType == continentType and info.name or nil
    if uiMapID then
        continentNames[uiMapID] = name
    end
    return name
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

-- 物品数据请求：同一物品等待中不重复请求；失败后按 5 秒起、每次翻倍、最长 5 分钟的间隔才再试，
-- 不会永久放弃（服务器可能只是暂时没给）。只有本插件请求的物品成功到达时才通知页面刷新。
local ITEM_PENDING_TIMEOUT, ITEM_RETRY_BASE, ITEM_RETRY_MAX = 30, 5, 300
local itemRequests = {} -- [itemID] = { pending = 是否等待中, requestedAt, retryAt, tries }
local itemListeners = {}

function ns.RequestItem(itemID)
    if not (itemID and C_Item.RequestLoadItemDataByID) then
        return
    end
    local now = GetTime()
    local request = itemRequests[itemID]
    if request then
        if request.pending and now - request.requestedAt < ITEM_PENDING_TIMEOUT then
            return
        end
        if not request.pending and now < request.retryAt then
            return
        end
    else
        request = { tries = 0 }
        itemRequests[itemID] = request
    end
    request.pending, request.requestedAt = true, now
    request.tries = request.tries + 1
    C_Item.RequestLoadItemDataByID(itemID)
end

-- listener(event, itemID)：本插件请求的物品数据到达时调用
function ns.OnItemLoaded(listener)
    tinsert(itemListeners, listener)
end

ns:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(event, itemID, success)
    local request = itemRequests[itemID]
    if not (request and request.pending) then
        return
    end
    if success == false then
        request.pending = false
        request.retryAt = GetTime() + math.min(ITEM_RETRY_MAX, ITEM_RETRY_BASE * 2 ^ (request.tries - 1))
        return
    end
    itemRequests[itemID] = nil
    for _, listener in ipairs(itemListeners) do
        listener(event, itemID)
    end
end)

-- 物品链接（客户端还没缓存时显示占位文字，数据到了会在下一次刷新时补上）
function ns.ItemLink(itemID)
    local _, link = C_Item.GetItemInfo(itemID)
    if not link then
        ns.RequestItem(itemID)
    end
    return link or L["Item information not yet unlocked"]
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
