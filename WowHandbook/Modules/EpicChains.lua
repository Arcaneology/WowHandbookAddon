local ADDON_NAME, ns = ...

-- 解谜助手的史诗任务线：五条跨地图的经典长任务链，与 wowhandbook.com 上“经典史诗长线任务”的攻略一致。
-- 步骤用任务 ID 判断进度，步骤名运行时取客户端的任务名，这里只写阶段、提示与地点。
-- 任务 ID 与前后顺序按 Questie 经典数据核对（QuestieDB 与 Forever 一致处沿用）。数据结构同 SecretChains.lua，另有：
--   quests     { 任务 ID }：这一步中间还有同一条线的其他任务（例如名字相同的一串跑腿任务），
--              其一在任务日志里即算这一步“进行中”；完成判断仍只看 quest（这一步的最后一个任务）
--   ownTitle   true 时步骤名用本地化的 title，不用客户端的任务名（一串同名任务合成一步时用）
--   optional   可选：不挡下一步，不计入进度
-- 同一阶段内按顺序做；parallel 的阶段内各步任意顺序。每一步“后面的步骤做完了，这一步也算完成”
-- 由 Chain() 按阶段顺序自动补上（after），可选步骤除外。
-- 奥妮克希亚开门任务两个阵营是两条完全不同的线，只放玩家所属阵营的那一条。

local function Chain(def)
    local ids = {}
    for _, group in ipairs(def.groups) do
        ids[group.id] = {}
    end
    for _, step in ipairs(def.steps) do
        if not step.optional then
            tinsert(ids[step.group], step.id)
        end
    end
    local order = {}
    for index, group in ipairs(def.groups) do
        order[group.id] = index
    end
    -- 后面还有必做步骤的第一个阶段
    local function NextGroupIDs(groupID)
        for index = order[groupID] + 1, #def.groups do
            local list = ids[def.groups[index].id]
            if #list > 0 then
                return list
            end
        end
        return {}
    end
    for _, step in ipairs(def.steps) do
        if not step.optional then
            local after = {}
            local group = def.groups[order[step.group]]
            local list = ids[step.group]
            local follow
            if not group.parallel then
                for position, id in ipairs(list) do
                    if id == step.id then
                        follow = list[position + 1]
                    end
                end
            end
            if follow then
                tinsert(after, follow)
            else
                for _, id in ipairs(NextGroupIDs(step.group)) do
                    tinsert(after, id)
                end
            end
            step.after = after
        end
    end
    return def
end

local function Quest(id, group, extra)
    local step = { id = "q" .. id, group = group, quest = id }
    for key, value in pairs(extra or {}) do
        step[key] = value
    end
    return step
end

local EPIC = {}

--------------------------------------------------------------------------------
-- 奥妮克希亚开门任务
--------------------------------------------------------------------------------

local faction = UnitFactionGroup and ns.PlayerFaction() or nil
if faction == "H" then
    tinsert(EPIC, Chain({
        id = "onyxia",
        title = "Onyxia's Lair Attunement",
        site = "onyxia-attunement-guide",
        minLevel = 55,
        reward = 16309,
        groups = {
            { id = "kargath", title = "Kargath and Orgrimmar" },
            { id = "rexxar", title = "Rexxar and Emberstrife" },
            { id = "dragons", title = "The four dragons", parallel = true },
            { id = "finale", title = "Rexxar's reward" },
        },
        steps = {
            Quest(4903, "kargath", {
                todo = "Start with Warlord Goretooth at Kargath in the Badlands, then clear Lower Blackrock Spire.",
                spots = { { 1418, 5.8, 47.6, "Warlord Goretooth" } },
            }),
            Quest(4941, "kargath"),
            Quest(4974, "kargath", {
                todo = "Defeat Warchief Rend Blackhand in Upper Blackrock Spire and take his head to Thrall in Orgrimmar.",
            }),
            Quest(6566, "kargath"),
            Quest(6567, "kargath"),
            Quest(6568, "rexxar", {
                todo = "Rexxar patrols the main road of Desolace with his bear Misha.",
            }),
            Quest(6569, "rexxar", {
                todo = "Bring 20 Black Dragonspawn Eyes from Upper Blackrock Spire to Myranda the Hag in the Western Plaguelands.",
            }),
            Quest(6570, "rexxar", {
                todo = "Equip the Amulet of Draconic Subversion before you step into Emberstrife's cave in Dustwallow Marsh.",
            }),
            Quest(6583, "dragons", {
                todo = "Elite dragon in the Swamp of Sorrows. Bring a group.",
            }),
            Quest(6584, "dragons", {
                todo = "Elite dragon outside the Caverns of Time in Tanaris. Bring a group.",
            }),
            Quest(6585, "dragons", {
                todo = "Elite dragon in the Wetlands. Bring a group.",
            }),
            Quest(6582, "dragons", {
                todo = "Elite dragon inside the Mazthoril cave in Winterspring. Bring a group.",
            }),
            Quest(6601, "finale"),
            Quest(6602, "finale", {
                todo = "Defeat General Drakkisath in Upper Blackrock Spire, loot the blood and bring it to Rexxar in Desolace.",
            }),
        },
        ending = "Done! Keep the Drakefire Amulet in your bags or bank for good: it is your key to Onyxia's Lair.",
    }))
else
    tinsert(EPIC, Chain({
        id = "onyxia",
        title = "Onyxia's Lair Attunement",
        site = "onyxia-attunement-guide",
        minLevel = 48,
        reward = 16309,
        groups = {
            { id = "steppes", title = "Morgan's Vigil" },
            { id = "depths", title = "Blackrock Depths" },
            { id = "city", title = "Stormwind and Winterspring" },
        },
        steps = {
            Quest(4182, "steppes", {
                todo = "Start with Helendis Riverhorn at Morgan's Vigil in the Burning Steppes.",
                spots = { { 1428, 85.8, 68.9, "Helendis Riverhorn" } },
            }),
            Quest(4224, "steppes", { quests = { 4183, 4184, 4185, 4186, 4223 } }),
            Quest(4241, "steppes"),
            Quest(4242, "depths", {
                todo = "Windsor is held in the Detention Block of Blackrock Depths.",
            }),
            Quest(4264, "depths", {
                todo = "Kill monsters anywhere inside Blackrock Depths until A Crumpled Up Note drops.",
            }),
            Quest(4282, "depths", {
                todo = "Defeat General Angerforge and Golem Lord Argelmach for Windsor's two tablets.",
            }),
            Quest(4322, "depths", {
                todo = "Clear the prison wing first, then talk to Windsor and stay with him all the way out.",
            }),
            Quest(6402, "city"),
            Quest(6403, "city", {
                todo = "Follow Windsor into Stormwind Keep and help Bolvar Fordragon.",
            }),
            Quest(6501, "city", {
                todo = "Take the cave teleport rune in Mazthoril, Winterspring, up to Haleh.",
            }),
            Quest(6502, "city", {
                todo = "Defeat General Drakkisath in Upper Blackrock Spire, loot the blood and return to Haleh.",
            }),
        },
        ending = "Done! Keep the Drakefire Amulet in your bags or bank for good: it is your key to Onyxia's Lair.",
    }))
end

--------------------------------------------------------------------------------
-- 爱与家庭：提里奥·弗丁
--------------------------------------------------------------------------------

tinsert(EPIC, Chain({
    id = "inDreams",
    title = "In Dreams: Tirion Fordring",
    site = "in-dreams-fordring-quest-chain",
    minLevel = 52,
    groups = {
        { id = "cleanup", title = "Tirion's three tasks", parallel = true },
        { id = "relics", title = "Relics of the past" },
        { id = "strat", title = "Stratholme" },
        { id = "hearth", title = "Hearthglen" },
    },
    steps = {
        Quest(5542, "cleanup", { spots = { { 1423, 7.6, 43.7, "Tirion Fordring" } } }),
        Quest(5543, "cleanup"),
        Quest(5544, "cleanup"),
        Quest(5742, "relics"),
        Quest(5781, "relics", {
            todo = "Click the Loose Dirt Mound at Blackwood Lake. Mercutio Filthgorger appears at once.",
            spots = { { 1423, 28.2, 86.2, "Taelan's Hammer" } },
        }),
        Quest(5845, "relics", {
            todo = "Dive into the pool in Northdale for the lost banner.",
            spots = { { 1423, 71.2, 34.0, "The lost banner" } },
        }),
        Quest(5846, "strat", {
            todo = "Bring a group into the Scarlet side of Stratholme and take the painting from the wall of the Scarlet Bastion.",
        }),
        Quest(5848, "strat"),
        Quest(5861, "hearth"),
        Quest(5862, "hearth", {
            todo = "Wear the Scarlet disguise and find Taelan in the keep of Hearthglen.",
            spots = { { 1422, 45.8, 18.2, "Taelan Fordring" } },
        }),
        Quest(5944, "hearth", {
            todo = "Bring a full group: escort Taelan out of Hearthglen and hold against the ambush at the tower.",
        }),
    },
    ending = "Done! Choose your reward from the four upgraded items.",
}))

--------------------------------------------------------------------------------
-- 达隆郡之战
--------------------------------------------------------------------------------

tinsert(EPIC, Chain({
    id = "darrowshire",
    title = "The Battle of Darrowshire",
    site = "battle-of-darrowshire-quest-chain",
    minLevel = 50,
    reward = 15856,
    groups = {
        { id = "pamela", title = "Pamela and Chromie" },
        { id = "carlin", title = "Carlin Redpath" },
        { id = "heroes", title = "Heroes and villains", parallel = true },
        { id = "battle", title = "The battle" },
    },
    steps = {
        Quest(5149, "pamela", {
            quests = { 5142, 5601 },
            todo = "Find Pamela Redpath in the ruins of Darrowshire and search the three ruined houses for the doll.",
            spots = { { 1423, 36.4, 90.8, "Pamela Redpath" } },
        }),
        Quest(5152, "pamela", { spots = { { 1422, 49.2, 78.4, "Marlene Redpath" } } }),
        Quest(5153, "pamela", {
            todo = "Clear the undead outside the inn at Andorhal first, then go upstairs to Chromie.",
            spots = { { 1422, 39.5, 66.8, "Chromie" } },
        }),
        Quest(5154, "pamela", {
            todo = "Find the one intact book among the decoys in the Andorhal town hall.",
        }),
        Quest(5241, "carlin", {
            optional = true,
            todo = "Optional: free 15 Darrowshire Spirits by clicking the spirit that rises from each ghoul.",
            spots = { { 1423, 81.5, 59.8, "Carlin Redpath" } },
        }),
        Quest(5211, "carlin", { optional = true }),
        Quest(5210, "carlin", { spots = { { 1423, 81.5, 59.8, "Carlin Redpath" } } }),
        Quest(5168, "heroes"),
        Quest(5181, "heroes"),
        Quest(5206, "battle", {
            todo = "Bring Redpath's Shield, Davil's Libram, the Shattered Sword of Marduk and Horgus' Skull to Carlin.",
        }),
        Quest(5941, "battle"),
        Quest(5721, "battle", {
            todo = "Bring three to five players: hold Darrowshire Square and keep Joseph Redpath alive.",
            spots = { { 1423, 38.6, 91.2, "Darrowshire Square" } },
        }),
        Quest(5942, "battle"),
    },
    ending = "Done! Choose one of the three rewards.",
}))

--------------------------------------------------------------------------------
-- 林克的冒险
--------------------------------------------------------------------------------

tinsert(EPIC, Chain({
    id = "linken",
    title = "Linken's Adventure",
    site = "linkens-adventure-quest-chain",
    minLevel = 47,
    reward = 11905,
    groups = {
        { id = "one", title = "Part one" },
        { id = "two", title = "Part two" },
        { id = "three", title = "Part three" },
    },
    steps = {
        Quest(3844, "one", {
            quests = { 3845 },
            todo = "Swim out to the raft in the lake and click the Small Pack.",
            spots = { { 1449, 63.1, 68.5, "Small Pack" }, { 1449, 44.7, 8.1, "Linken" } },
        }),
        Quest(3908, "one", {
            todo = "Show the photograph to Donova Snowden in Winterspring.",
            spots = { { 1452, 61.6, 38.6, "Donova Snowden" } },
        }),
        Quest(3909, "two"),
        Quest(3912, "two"),
        Quest(3913, "two"),
        Quest(3914, "two"),
        Quest(3941, "three"),
        Quest(3942, "three"),
        Quest(4084, "three"),
        Quest(4005, "three", { spots = { { 1446, 70.3, 49.9, "Aquementas" } } }),
        Quest(3961, "three"),
        Quest(3962, "three", {
            todo = "Use the Silver Totem to strip Blazerunner's shield. Bring a friend if you are below level 55.",
            spots = { { 1449, 49.7, 45.7, "Blazerunner" } },
        }),
    },
    ending = "Done! Linken's Boomerang is yours, along with your choice of an upgraded rare weapon.",
}))

--------------------------------------------------------------------------------
-- 失踪的使节（联盟）
--------------------------------------------------------------------------------

if faction ~= "H" then
    tinsert(EPIC, Chain({
        id = "diplomat",
        title = "The Missing Diplomat",
        site = "the-missing-diplomat-quest-chain",
        minLevel = 28,
        reward = 6757,
        groups = {
            { id = "stormwind", title = "Stormwind and Duskwood" },
            { id = "menethil", title = "Menethil Harbor" },
            { id = "theramore", title = "Theramore" },
        },
        steps = {
            Quest(1243, "stormwind", {
                ownTitle = true, title = "Follow the Defias trail in Stormwind", quests = { 1274, 1241, 1242 },
                todo = "Pick up the chain from Thomas in Cathedral Square.",
                spots = { { 1453, 51.4, 45.8, "Thomas" } },
            }),
            Quest(1245, "stormwind", { ownTitle = true, title = "Duskwood: the Defias lead", quests = { 1244 } }),
            Quest(1247, "stormwind", { ownTitle = true, title = "Back in Stormwind: the next lead", quests = { 1246, 1447 } }),
            Quest(1250, "menethil", {
                ownTitle = true, title = "Subdue the brawler at the inn", quests = { 1248, 1249 },
                todo = "Ask the barkeep about the local bruiser, then beat him until he talks. He does not need to die.",
                spots = { { 1437, 10.6, 60.8, "Mikhail" } },
            }),
            Quest(1264, "theramore", { ownTitle = true, title = "Sail to Theramore" }),
            Quest(1266, "theramore", {
                ownTitle = true, title = "Confront Private Hendel", quests = { 1265 },
                todo = "Defeat Private Hendel at the ruined tower in the marsh.",
                spots = { { 1445, 45.1, 24.6, "Private Hendel" } },
            }),
            Quest(1267, "theramore", {
                ownTitle = true, title = "Report to Jaina Proudmoore", quests = { 1324 },
                todo = "Stay for the interrogation, then return to the tower in Theramore.",
                spots = { { 1445, 66.3, 49.0, "Jaina Proudmoore" } },
            }),
        },
        ending = "Done! Jaina's Signet Ring is yours.",
    }))
end

for _, chain in ipairs(EPIC) do
    tinsert(ns.SecretChains, chain)
end
