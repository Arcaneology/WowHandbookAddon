-- 自动生成的数据文件，请勿手工编辑。
-- Beast spawn locations from QuestieDB (https://github.com/Questie/QuestieDB), the Questie project, GPL-3.0.
local ADDON_NAME, ns = ...
ns.Data = ns.Data or {}
ns.Data.hunterPets = {
    families = {
        {
            slug = "wolf",
            name = {
                enUS = "Wolf",
                zhCN = "狼",
            },
            icon = "ability_hunter_pet_wolf",
            signature = 24604,
            role = {
                enUS = "Group support",
                zhCN = "团队辅助",
            },
        },
        {
            slug = "cat",
            name = {
                enUS = "Cat",
                zhCN = "豹",
            },
            icon = "ability_hunter_pet_cat",
            signature = 24450,
            role = {
                enUS = "Single-target damage",
                zhCN = "单体输出",
            },
        },
        {
            slug = "spider",
            name = {
                enUS = "Spider",
                zhCN = "蜘蛛",
            },
            icon = "ability_hunter_pet_spider",
            signature = 1265843,
            role = {
                enUS = "Control and damage",
                zhCN = "控制与输出",
            },
        },
        {
            slug = "bear",
            name = {
                enUS = "Bear",
                zhCN = "熊",
            },
            icon = "ability_hunter_pet_bear",
            signature = 1264494,
            role = {
                enUS = "Tanking several enemies",
                zhCN = "多目标承伤",
            },
        },
        {
            slug = "boar",
            name = {
                enUS = "Boar",
                zhCN = "野猪",
            },
            icon = "ability_hunter_pet_boar",
            signature = 7371,
            role = {
                enUS = "Tank with a gap closer",
                zhCN = "带冲锋的坦克",
            },
        },
        {
            slug = "crocolisk",
            name = {
                enUS = "Crocolisk",
                zhCN = "鳄鱼",
            },
            icon = "ability_hunter_pet_crocolisk",
            signature = 1264758,
            role = {
                enUS = "Anti-healing in PvP",
                zhCN = "PvP 降治疗",
            },
        },
        {
            slug = "carrion-bird",
            name = {
                enUS = "Carrion Bird",
                zhCN = "食腐鸟",
            },
            icon = "ability_hunter_pet_vulture",
            signature = 24423,
            role = {
                enUS = "Group defense",
                zhCN = "团队减伤",
            },
        },
        {
            slug = "gorilla",
            name = {
                enUS = "Gorilla",
                zhCN = "猩猩",
            },
            icon = "ability_hunter_pet_gorilla",
            signature = 26090,
            role = {
                enUS = "Area damage",
                zhCN = "范围伤害",
            },
        },
        {
            slug = "raptor",
            name = {
                enUS = "Raptor",
                zhCN = "迅猛龙",
            },
            icon = "ability_hunter_pet_raptor",
            signature = 1265065,
            role = {
                enUS = "Bleed damage",
                zhCN = "流血输出",
            },
        },
        {
            slug = "tallstrider",
            name = {
                enUS = "Tallstrider",
                zhCN = "陆行鸟",
            },
            icon = "ability_hunter_pet_tallstrider",
            signature = 1265899,
            role = {
                enUS = "Armor reduction",
                zhCN = "降低护甲",
            },
        },
        {
            slug = "scorpid",
            name = {
                enUS = "Scorpid",
                zhCN = "蝎子",
            },
            icon = "ability_hunter_pet_scorpid",
            signature = 24640,
            role = {
                enUS = "Stacking poison",
                zhCN = "叠加毒伤",
            },
        },
        {
            slug = "turtle",
            name = {
                enUS = "Turtle",
                zhCN = "海龟",
            },
            icon = "ability_hunter_pet_turtle",
            signature = 26064,
            role = {
                enUS = "Maximum survival",
                zhCN = "极限生存",
            },
        },
        {
            slug = "bat",
            name = {
                enUS = "Bat",
                zhCN = "蝙蝠",
            },
            icon = "ability_hunter_pet_bat",
            signature = 1264478,
            role = {
                enUS = "Caster disruption",
                zhCN = "干扰施法",
            },
        },
        {
            slug = "hyena",
            name = {
                enUS = "Hyena",
                zhCN = "土狼",
            },
            icon = "ability_hunter_pet_hyena",
            signature = 1265038,
            role = {
                enUS = "Slow and bleed",
                zhCN = "减速与流血",
            },
        },
        {
            slug = "bird-of-prey",
            name = {
                enUS = "Bird of Prey",
                zhCN = "猛禽",
            },
            icon = "ability_hunter_pet_owl",
            signature = 1265054,
            role = {
                enUS = "Disarm",
                zhCN = "缴械",
            },
        },
        {
            slug = "wind-serpent",
            name = {
                enUS = "Wind Serpent",
                zhCN = "风蛇",
            },
            icon = "ability_hunter_pet_windserpent",
            signature = 24844,
            role = {
                enUS = "Ranged damage",
                zhCN = "远程伤害",
            },
        },
        {
            slug = "fox",
            name = {
                enUS = "Fox",
                zhCN = "狐狸",
            },
            icon = "ability_hunter_aspectofthefox",
            signature = 1310612,
            role = {
                enUS = "New: dodge and speed",
                zhCN = "新家族：闪避与攻速",
            },
        },
    },
    beasts = {
        [255887] = {
            family = "fox",
            levels = { 6, 6 },
            rank = "rare",
            new = true,
            featured = true,
            name = {
                enUS = "Slydris",
                zhCN = "斯莱德里斯",
            },
            why = {
                enUS = "A rare fox and one of the first members of the new fox family. Trickster's Dance gives a burst of dodge and attack speed.",
                zhCN = "稀有狐狸，是最早能驯服的新狐狸家族成员之一。欺诈者之舞带来一段闪避与攻速爆发。",
            },
            tip = {
                enUS = "It is level 6, so you can tame it as soon as you reach 10 on Zephras Isle.",
                zhCN = "它只有 6 级，在泽风岛升到 10 级就能抓。",
            },
            tags = { "look", "early" },
            spots = {
                { 2521, 50.0, 53.0 },
                { 2521, 50.3, 50.3 },
                { 2521, 51.7, 51.6 },
            },
        },
        [471] = {
            family = "spider",
            levels = { 7, 10 },
            rank = "rare",
            name = {
                enUS = "Mother Fang",
                zhCN = "母蜘蛛",
            },
            spots = {
                { 1429, 62.1, 48.0 },
            },
        },
        [14430] = {
            family = "cat",
            levels = { 9, 9 },
            rank = "rare",
            featured = true,
            attack = 1.4,
            name = {
                enUS = "Duskstalker",
                zhCN = "暮色巡游者",
            },
            why = {
                enUS = "A level 9 night-elf cat with Faster Attack IV (1.4 s). Ready the moment you learn Tame Beast.",
                zhCN = "9 级的暗夜精灵豹，自带迅猛攻击 IV（1.4 秒），学会驯服野兽就能抓。",
            },
            tip = {
                enUS = "It appears in the south of Teldrassil; if it is missing, other hunters may have taken it, so check back later.",
                zhCN = "刷新在泰达希尔南部；找不到时多半被别的猎人抓走了，过一会儿再来。",
            },
            tags = { "early" },
            spots = {
                { 1438, 58.1, 76.7 },
            },
        },
        [3068] = {
            family = "tallstrider",
            levels = { 9, 9 },
            rank = "rare",
            name = {
                enUS = "Mazzranache",
                zhCN = "马兹拉纳其",
            },
            spots = {
                { 1412, 49.1, 48.7 },
            },
        },
        [276111] = {
            family = "cat",
            levels = { 10, 10 },
            rank = "rare",
            new = true,
            featured = true,
            name = {
                enUS = "Ghostfang",
                zhCN = "幽魂之牙",
            },
            why = {
                enUS = "A rare leopard that could not be tamed in Classic. One of the first rare cats an Alliance hunter can reach.",
                zhCN = "经典旧世不能驯服的稀有豹，是联盟猎人最早能抓到的稀有豹之一。",
            },
            tip = {
                enUS = "Look along the mountain road in eastern Dun Morogh, between Kharanos and the pass toward the Wetlands.",
                zhCN = "在丹莫罗东部的山道上找，大致在卡拉诺斯与通往湿地的山口之间。",
            },
            tags = { "look", "early" },
            spots = {
                { 1426, 74.2, 60.8 },
                { 1426, 74.6, 63.1 },
                { 1426, 79.0, 47.0 },
                { 1426, 79.4, 42.9 },
                { 1426, 80.5, 46.0 },
                { 1426, 81.4, 53.2 },
            },
        },
        [276101] = {
            family = "bird-of-prey",
            levels = { 10, 10 },
            rank = "rare",
            new = true,
            featured = true,
            name = {
                enUS = "Nightscreech",
                zhCN = "夜啸",
            },
            why = {
                enUS = "A rare bird of prey near the Oracle Glade. Mine! disarms melee attackers, which makes it a strong PvP pick later on.",
                zhCN = "先知林地附近的稀有猛禽。归我了！可以缴械近战敌人，之后打 PvP 很有用。",
            },
            tip = {
                enUS = "Search the western coast of Teldrassil around the Oracle Glade.",
                zhCN = "在泰达希尔西海岸的先知林地一带找。",
            },
            tags = { "pvp", "early" },
            spots = {
                { 1438, 37.4, 29.8 },
                { 1438, 37.7, 32.1 },
                { 1438, 38.0, 28.2 },
                { 1438, 38.0, 56.0 },
                { 1438, 38.4, 26.4 },
                { 1438, 39.2, 51.9 },
            },
        },
        [5807] = {
            family = "cat",
            levels = { 10, 10 },
            rank = "rare",
            featured = true,
            attack = 1.2,
            name = {
                enUS = "The Rake",
                zhCN = "扫荡者",
            },
            why = {
                enUS = "The rare cat of Mulgore with Faster Attack VI: a 1.2-second swing at level 10, the quickest early pet for Horde hunters.",
                zhCN = "莫高雷的稀有豹，自带迅猛攻击 VI，10 级就有 1.2 秒的攻击间隔，是部落猎人最快的早期宠物。",
            },
            tip = {
                enUS = "It sits in the hills north of Bloodhoof Village. Tame it right after you learn Tame Beast at 10.",
                zhCN = "在血蹄村以北的山丘上。10 级学会驯服野兽后马上就能去抓。",
            },
            tags = { "early", "pvp" },
            spots = {
                { 1412, 51.6, 27.4 },
            },
        },
        [1132] = {
            family = "wolf",
            levels = { 10, 10 },
            rank = "rare",
            name = {
                enUS = "Timber",
                zhCN = "狂暴的冬狼",
            },
            spots = {
                { 1426, 33.5, 43.8 },
                { 1426, 34.2, 41.8 },
            },
        },
        [5823] = {
            family = "scorpid",
            levels = { 11, 11 },
            rank = "rare",
            attack = 1.6,
            name = {
                enUS = "Death Flayer",
                zhCN = "死亡毒蝎",
            },
            spots = {
                { 1411, 36.5, 49.7 },
            },
        },
        [10357] = {
            family = "bat",
            levels = { 11, 11 },
            rank = "rare",
            name = {
                enUS = "Ressan the Needler",
                zhCN = "毒针雷萨恩",
            },
            spots = {
                { 1420, 42.9, 67.6 },
            },
        },
        [1130] = {
            family = "bear",
            levels = { 12, 12 },
            rank = "rare",
            name = {
                enUS = "Bjarn",
                zhCN = "游荡的冰爪熊",
            },
            spots = {
                { 1426, 52.8, 58.5 },
                { 1426, 55.6, 58.5 },
                { 1426, 59.5, 58.4 },
                { 1426, 62.6, 58.5 },
            },
        },
        [274300] = {
            family = "wolf",
            levels = { 12, 12 },
            rank = "rare",
            new = true,
            featured = true,
            attack = 1.5,
            teaches = {
                { 24604, 1 },
            },
            name = {
                enUS = "Coldrasp",
                zhCN = "寒啸",
            },
            why = {
                enUS = "A spectral blue wolf new in Forever. It comes with Furious Howl and swings at 1.5 seconds, so it is a group pet from level 12.",
                zhCN = "无限版新增的幽蓝幽灵狼，自带狂怒之嚎，攻击间隔 1.5 秒，12 级起就能当团队宠物。",
            },
            tip = {
                enUS = "It wanders the Whispering Forest on the western edge of Tirisfal; sweep between the marked spots.",
                zhCN = "它在提瑞斯法林地西缘的低语森林游荡，沿着标出的几处刷新点来回找。",
            },
            tags = { "look", "group", "early" },
            spots = {
                { 1420, 15.6, 69.8 },
                { 1420, 16.1, 66.6 },
                { 1420, 16.7, 65.2 },
                { 1420, 16.9, 68.0 },
                { 1420, 17.7, 70.0 },
                { 1420, 18.0, 66.4 },
            },
        },
        [5865] = {
            family = "cat",
            levels = { 13, 13 },
            rank = "rare",
            attack = 1.5,
            name = {
                enUS = "Dishu",
                zhCN = "迪舒",
            },
            spots = {
                { 1413, 49.6, 15.8 },
            },
        },
        [12431] = {
            family = "wolf",
            levels = { 13, 13 },
            rank = "rare",
            name = {
                enUS = "Gorefang",
                zhCN = "血牙狼人",
            },
            spots = {
                { 1421, 59.5, 7.6 },
            },
        },
        [259388] = {
            family = "bear",
            levels = { 13, 13 },
            rank = "rare",
            new = true,
            featured = true,
            attack = 1.6,
            name = {
                enUS = "Mystmane",
                zhCN = "秘鬃",
            },
            why = {
                enUS = "A rare bear on Zephras Isle, new in Forever, with Faster Attack II (1.6 s). A sturdy tank with Swipe for Skyborne hunters.",
                zhCN = "泽风岛上的稀有熊，无限版新增，自带迅猛攻击 II（1.6 秒）。带横扫的耐打坦克，适合天裔猎人。",
            },
            tip = {
                enUS = "It roams the hills around the marked spot; bears are slow, so it stays close to its path.",
                zhCN = "在标出位置附近的山坡上游荡，熊走得慢，不会离路线太远。",
            },
            tags = { "tank", "early" },
            spots = {
                { 2521, 56.2, 37.9 },
                { 2521, 57.8, 37.3 },
                { 2521, 58.1, 38.8 },
                { 2521, 60.1, 37.8 },
                { 2521, 60.5, 35.1 },
            },
        },
        [2175] = {
            family = "cat",
            levels = { 13, 13 },
            rank = "rare",
            attack = 1.5,
            name = {
                enUS = "Shadowclaw",
                zhCN = "影爪",
            },
            spots = {
                { 1439, 40.3, 40.5 },
            },
        },
        [10359] = {
            family = "spider",
            levels = { 13, 13 },
            rank = "rare",
            name = {
                enUS = "Sri'skulk",
                zhCN = "瑟斯库克",
            },
            spots = {
                { 1420, 88.2, 51.4 },
            },
        },
        [12432] = {
            family = "bear",
            levels = { 14, 14 },
            rank = "rare",
            name = {
                enUS = "Old Vicejaw",
                zhCN = "维斯迦尔",
            },
            spots = {
                { 1421, 53.9, 51.9 },
            },
        },
        [12433] = {
            family = "spider",
            levels = { 15, 15 },
            rank = "rare",
            name = {
                enUS = "Krethis Shadowspinner",
                zhCN = "克雷希斯",
            },
            spots = {
                { 1421, 35.7, 8.2 },
            },
        },
        [14268] = {
            family = "carrion-bird",
            levels = { 16, 16 },
            rank = "rare",
            name = {
                enUS = "Lord Condar",
                zhCN = "康达尔",
            },
            spots = {
                { 1432, 62.6, 78.5 },
                { 1432, 74.6, 70.8 },
                { 1432, 74.7, 66.9 },
                { 1432, 77.7, 74.9 },
            },
        },
        [5829] = {
            family = "hyena",
            levels = { 17, 17 },
            rank = "rare",
            name = {
                enUS = "Snort the Heckler",
                zhCN = "土狼斯诺特",
            },
            spots = {
                { 1413, 41.1, 22.2 },
            },
        },
        [14266] = {
            family = "spider",
            levels = { 19, 19 },
            rank = "rare",
            name = {
                enUS = "Shanda the Spinner",
                zhCN = "纺织者杉达",
            },
            spots = {
                { 1432, 78.1, 52.4 },
            },
        },
        [5842] = {
            family = "raptor",
            levels = { 19, 19 },
            rank = "rareelite",
            name = {
                enUS = "Takk the Leaper",
                zhCN = "“跳跃者”塔克",
            },
            spots = {
                { 1413, 59.6, 8.3 },
            },
        },
        [3653] = {
            family = "turtle",
            levels = { 20, 20 },
            rank = "elite",
            featured = true,
            teaches = {
                { 26064, 1 },
            },
            name = {
                enUS = "Kresh",
                zhCN = "克雷什",
            },
            why = {
                enUS = "The elite turtle inside the Wailing Caverns, the classic way to get an early Shell Shield turtle.",
                zhCN = "哀嚎洞穴里的精英海龟，经典的早期甲壳护盾海龟来源。",
            },
            tip = {
                enUS = "It swims in the caverns' water; bring a group to reach it, then tame it while your party keeps the area clear.",
                zhCN = "在洞穴的水域里，组队进去，让队友清好周围再驯服。",
            },
            tags = { "tank" },
            instances = { "wailing-caverns" },
        },
        [2172] = {
            family = "tallstrider",
            levels = { 20, 20 },
            rank = "rare",
            name = {
                enUS = "Strider Clutchmother",
                zhCN = "雌性森林陆行鸟",
            },
            spots = {
                { 1439, 34.8, 87.3 },
            },
        },
        [2476] = {
            family = "crocolisk",
            levels = { 22, 22 },
            rank = "rare",
            name = {
                enUS = "Large Loch Crocolisk",
                zhCN = "大型洛克鳄",
            },
            spots = {
                { 1432, 58.9, 31.1 },
                { 1432, 60.3, 39.6 },
            },
        },
        [10644] = {
            family = "wolf",
            levels = { 22, 22 },
            rank = "rare",
            featured = true,
            attack = 1.3,
            teaches = {
                { 24604, 1 },
            },
            name = {
                enUS = "Mist Howler",
                zhCN = "迷雾嚎叫者",
            },
            why = {
                enUS = "A misty grey wolf with Faster Attack V (1.3 s) and Furious Howl. Fast, good-looking and useful in groups.",
                zhCN = "迷雾色的灰狼，自带迅猛攻击 V（1.3 秒）与狂怒之嚎。快、好看，组队也有用。",
            },
            tip = {
                enUS = "It patrols western Ashenvale between the marked spots.",
                zhCN = "在灰谷西部几处标出的位置之间巡逻。",
            },
            tags = { "look", "group", "pvp" },
            spots = {
                { 1440, 20.9, 36.9 },
                { 1440, 26.8, 18.4 },
            },
        },
        [616] = {
            family = "spider",
            levels = { 23, 23 },
            rank = "rare",
            name = {
                enUS = "Chatter",
                zhCN = "查特",
            },
            spots = {
                { 1433, 43.1, 41.1 },
                { 1433, 45.2, 36.9 },
                { 1433, 45.5, 34.6 },
                { 1433, 46.3, 38.7 },
                { 1433, 47.0, 32.6 },
                { 1433, 47.0, 45.2 },
            },
        },
        [5828] = {
            family = "cat",
            levels = { 23, 23 },
            rank = "rareelite",
            featured = true,
            attack = 1.3,
            name = {
                enUS = "Humar the Pridelord",
                zhCN = "狮王休玛",
            },
            why = {
                enUS = "The black lion of the Barrens: a rare elite cat with Faster Attack V (1.3 s) and one of the most recognizable pets in the game.",
                zhCN = "贫瘠之地的黑狮：稀有精英豹，自带迅猛攻击 V（1.3 秒），是辨识度最高的宠物之一。",
            },
            tip = {
                enUS = "It patrols northeast of the Crossroads. It is elite, so lay a Freezing Trap before you start Tame Beast.",
                zhCN = "在十字路口东北巡逻。它是精英，开始驯服前先放冰冻陷阱。",
            },
            tags = { "look", "pvp" },
            spots = {
                { 1413, 62.0, 33.3 },
            },
        },
        [521] = {
            family = "wolf",
            levels = { 23, 23 },
            rank = "rare",
            name = {
                enUS = "Lupos",
                zhCN = "鲁伯斯",
            },
            spots = {
                { 1431, 20.0, 26.4 },
                { 1431, 21.5, 26.5 },
                { 1431, 23.6, 27.0 },
                { 1431, 24.9, 28.4 },
                { 1431, 27.1, 27.2 },
                { 1431, 29.6, 29.8 },
            },
        },
        [14279] = {
            family = "spider",
            levels = { 24, 24 },
            rank = "rare",
            name = {
                enUS = "Creepthess",
                zhCN = "克雷普塞斯",
            },
            spots = {
                { 1424, 38.6, 58.4 },
            },
        },
        [1112] = {
            family = "spider",
            levels = { 24, 24 },
            rank = "rare",
            name = {
                enUS = "Leech Widow",
                zhCN = "吸血寡妇",
            },
            spots = {
                { 1437, 47.3, 59.2 },
            },
        },
        [5834] = {
            family = "wind-serpent",
            levels = { 25, 25 },
            rank = "rare",
            name = {
                enUS = "Azzere the Skyblade",
                zhCN = "天空之刃艾泽里",
            },
            spots = {
                { 1413, 44.8, 64.1 },
            },
        },
        [462] = {
            family = "carrion-bird",
            levels = { 26, 26 },
            rank = "rare",
            name = {
                enUS = "Vultros",
                zhCN = "乌尔图斯",
            },
            spots = {
                { 1436, 36.8, 62.5 },
                { 1436, 40.6, 60.5 },
                { 1436, 44.1, 46.2 },
                { 1436, 45.4, 44.0 },
                { 1436, 45.7, 60.1 },
                { 1436, 46.1, 57.7 },
            },
        },
        [14280] = {
            family = "bear",
            levels = { 27, 27 },
            rank = "rare",
            name = {
                enUS = "Big Samras",
                zhCN = "萨姆拉斯",
            },
            spots = {
                { 1424, 86.0, 39.9 },
            },
        },
        [574] = {
            family = "spider",
            levels = { 27, 27 },
            rank = "rare",
            name = {
                enUS = "Naraxis",
                zhCN = "纳拉克西斯",
            },
            spots = {
                { 1431, 86.4, 47.6 },
            },
        },
        [1140] = {
            family = "raptor",
            levels = { 31, 31 },
            rank = "rare",
            name = {
                enUS = "Razormaw Matriarch",
                zhCN = "刺喉雌龙",
            },
            spots = {
                { 1437, 69.9, 29.2 },
            },
        },
        [12037] = {
            family = "bear",
            levels = { 31, 31 },
            rank = "rare",
            name = {
                enUS = "Ursol'lok",
                zhCN = "乌索洛克",
            },
            spots = {
                { 1440, 83.4, 48.5 },
            },
        },
        [4425] = {
            family = "bat",
            levels = { 32, 32 },
            rank = "rareelite",
            name = {
                enUS = "Blind Hunter",
                zhCN = "盲眼猎手",
            },
            instances = { "razorfen-kraul" },
        },
        [14223] = {
            family = "turtle",
            levels = { 32, 32 },
            rank = "rare",
            name = {
                enUS = "Cranky Benj",
                zhCN = "暴躁的本希",
            },
            spots = {
                { 1416, 37.3, 19.8 },
            },
        },
        [14228] = {
            family = "hyena",
            levels = { 34, 34 },
            rank = "rare",
            name = {
                enUS = "Giggler",
                zhCN = "基格勒尔",
            },
            spots = {
                { 1443, 61.3, 28.9 },
            },
        },
        [14222] = {
            family = "cat",
            levels = { 35, 35 },
            rank = "rare",
            attack = 1.4,
            name = {
                enUS = "Araga",
                zhCN = "阿拉加",
            },
            spots = {
                { 1416, 30.2, 72.1 },
            },
        },
        [5937] = {
            family = "scorpid",
            levels = { 35, 35 },
            rank = "rareelite",
            name = {
                enUS = "Vile Sting",
                zhCN = "邪刺恐蝎",
            },
            spots = {
                { 1441, 70.5, 72.9 },
            },
        },
        [2850] = {
            family = "cat",
            levels = { 37, 37 },
            rank = "rare",
            featured = true,
            attack = 1.0,
            name = {
                enUS = "Broken Tooth",
                zhCN = "断牙",
            },
            why = {
                enUS = "The famous Badlands cat with Faster Attack VII, the fastest passive in the game (a 1.0-second swing).",
                zhCN = "荒芜之地著名的豹，自带迅猛攻击 VII，游戏里最快的攻速被动（1.0 秒一击）。",
            },
            tip = {
                enUS = "It patrols the north of the Badlands; many hunters camp it, so be ready to tame the moment it appears.",
                zhCN = "在荒芜之地北部巡逻，很多猎人蹲守，刷出来就立刻驯服。",
            },
            tags = { "pvp", "look" },
            spots = {
                { 1418, 45.8, 36.5 },
                { 1418, 53.6, 15.5 },
                { 1418, 59.7, 26.9 },
                { 1418, 59.7, 29.4 },
            },
        },
        [2753] = {
            family = "wolf",
            levels = { 38, 38 },
            rank = "rare",
            attack = 1.6,
            name = {
                enUS = "Barnabus",
                zhCN = "巴纳布斯",
            },
            spots = {
                { 1418, 38.9, 68.0 },
                { 1418, 46.2, 74.3 },
                { 1418, 55.8, 67.8 },
            },
        },
        [14232] = {
            family = "raptor",
            levels = { 38, 38 },
            rank = "rare",
            name = {
                enUS = "Dart",
                zhCN = "达尔特",
            },
            spots = {
                { 1445, 47.3, 18.4 },
            },
        },
        [14233] = {
            family = "crocolisk",
            levels = { 39, 39 },
            rank = "rare",
            name = {
                enUS = "Ripscale",
                zhCN = "雷普斯凯尔",
            },
            spots = {
                { 1445, 37.8, 50.3 },
                { 1445, 42.4, 55.0 },
                { 1445, 44.1, 50.2 },
                { 1445, 47.3, 54.6 },
                { 1445, 49.1, 57.3 },
            },
        },
        [4380] = {
            family = "spider",
            levels = { 40, 40 },
            rank = "rare",
            name = {
                enUS = "Darkmist Widow",
                zhCN = "暗雾寡妇蛛",
            },
            spots = {
                { 1445, 31.1, 20.4 },
            },
        },
        [14234] = {
            family = "wind-serpent",
            levels = { 41, 41 },
            rank = "rare",
            name = {
                enUS = "Hayoc",
                zhCN = "哈尤克",
            },
            spots = {
                { 1445, 52.0, 62.9 },
            },
        },
        [14491] = {
            family = "gorilla",
            levels = { 42, 42 },
            rank = "rare",
            name = {
                enUS = "Kurmokk",
                zhCN = "科尔摩克",
            },
            spots = {
                { 1434, 38.1, 61.1 },
            },
        },
        [8211] = {
            family = "wolf",
            levels = { 42, 42 },
            rank = "rare",
            name = {
                enUS = "Old Cliff Jumper",
                zhCN = "海崖奔跳者",
            },
            spots = {
                { 1425, 11.9, 53.7 },
            },
        },
        [5356] = {
            family = "wolf",
            levels = { 42, 42 },
            rank = "rare",
            name = {
                enUS = "Snarler",
                zhCN = "咆哮者",
            },
            spots = {
                { 1444, 80.2, 39.6 },
            },
        },
        [8208] = {
            family = "hyena",
            levels = { 43, 43 },
            rank = "rare",
            name = {
                enUS = "Murderous Blisterpaw",
                zhCN = "残忍的疱爪土狼",
            },
            spots = {
                { 1446, 52.3, 33.3 },
            },
        },
        [5352] = {
            family = "bear",
            levels = { 43, 43 },
            rank = "rare",
            name = {
                enUS = "Old Grizzlegut",
                zhCN = "灰腹老熊",
            },
            spots = {
                { 1444, 59.5, 59.4 },
            },
        },
        [8207] = {
            family = "carrion-bird",
            levels = { 46, 46 },
            rank = "rare",
            name = {
                enUS = "Greater Firebird",
                zhCN = "巨型火鸟",
            },
            spots = {
                { 1446, 49.4, 36.0 },
            },
        },
        [8277] = {
            family = "spider",
            levels = { 48, 48 },
            rank = "rare",
            name = {
                enUS = "Rekk'tilac",
                zhCN = "雷克提拉克",
            },
            spots = {
                { 1427, 30.3, 73.0 },
                { 1427, 35.0, 28.0 },
                { 1427, 53.0, 70.9 },
                { 1427, 59.8, 29.3 },
                { 1427, 61.9, 73.2 },
            },
        },
        [5349] = {
            family = "wind-serpent",
            levels = { 49, 49 },
            rank = "rare",
            name = {
                enUS = "Arash-ethis",
                zhCN = "阿拉瑟希斯",
            },
            spots = {
                { 1444, 44.8, 25.0 },
            },
        },
        [14339] = {
            family = "wolf",
            levels = { 49, 49 },
            rank = "rare",
            name = {
                enUS = "Death Howl",
                zhCN = "死亡之嚎",
            },
            spots = {
                { 1448, 47.9, 74.8 },
                { 1448, 48.3, 78.2 },
                { 1448, 50.0, 77.1 },
                { 1448, 56.2, 89.3 },
            },
        },
        [8303] = {
            family = "boar",
            levels = { 50, 50 },
            rank = "rare",
            name = {
                enUS = "Grunter",
                zhCN = "格朗特",
            },
            spots = {
                { 1419, 52.3, 27.4 },
                { 1419, 54.1, 28.6 },
                { 1419, 54.9, 30.5 },
                { 1419, 55.6, 28.4 },
                { 1419, 56.0, 34.3 },
                { 1419, 57.1, 33.2 },
            },
        },
        [14344] = {
            family = "bear",
            levels = { 50, 50 },
            rank = "rare",
            name = {
                enUS = "Mongress",
                zhCN = "莫戈雷斯",
            },
            spots = {
                { 1448, 39.8, 80.3 },
                { 1448, 42.1, 75.2 },
                { 1448, 43.3, 76.6 },
                { 1448, 47.0, 84.0 },
            },
        },
        [3581] = {
            family = "crocolisk",
            levels = { 50, 50 },
            rank = "rare",
            name = {
                enUS = "Sewer Beast",
                zhCN = "下水道鳄鱼",
            },
            spots = {
                { 1453, 71.1, 68.0 },
                { 1453, 71.2, 48.8 },
            },
        },
        [8213] = {
            family = "turtle",
            levels = { 51, 51 },
            rank = "rare",
            name = {
                enUS = "Ironback",
                zhCN = "铁背龟",
            },
            spots = {
                { 1425, 81.5, 49.2 },
            },
        },
        [8300] = {
            family = "hyena",
            levels = { 51, 51 },
            rank = "rare",
            attack = 1.3,
            name = {
                enUS = "Ravage",
                zhCN = "毁灭",
            },
            spots = {
                { 1419, 45.5, 36.1 },
                { 1419, 46.4, 34.2 },
                { 1419, 47.1, 37.1 },
                { 1419, 48.6, 35.6 },
                { 1419, 50.2, 36.9 },
                { 1419, 58.6, 35.6 },
            },
        },
        [5708] = {
            family = "wind-serpent",
            levels = { 51, 51 },
            rank = "rareelite",
            name = {
                enUS = "Spawn of Hakkar",
                zhCN = "哈卡的后代",
            },
            instances = { "temple-of-atalhakkar" },
        },
        [14343] = {
            family = "bird-of-prey",
            levels = { 52, 52 },
            rank = "rare",
            name = {
                enUS = "Olm the Wise",
                zhCN = "智者奥尔姆",
            },
            spots = {
                { 1448, 50.2, 32.8 },
            },
        },
        [13896] = {
            family = "turtle",
            levels = { 52, 52 },
            rank = "rareelite",
            name = {
                enUS = "Scalebeard",
                zhCN = "鳞须海龟",
            },
            spots = {
                { 1447, 52.6, 47.4 },
            },
        },
        [8299] = {
            family = "carrion-bird",
            levels = { 52, 52 },
            rank = "rare",
            attack = 1.2,
            name = {
                enUS = "Spiteflayer",
                zhCN = "斯比弗雷尔",
            },
            spots = {
                { 1419, 57.5, 33.6 },
                { 1419, 57.8, 42.3 },
                { 1419, 58.4, 36.0 },
                { 1419, 60.2, 37.6 },
                { 1419, 60.4, 42.3 },
                { 1419, 60.7, 39.8 },
            },
        },
        [8301] = {
            family = "scorpid",
            levels = { 53, 53 },
            rank = "rare",
            name = {
                enUS = "Clack the Reaver",
                zhCN = "掠夺者科拉克",
            },
            spots = {
                { 1419, 47.6, 35.7 },
                { 1419, 48.3, 38.7 },
                { 1419, 49.8, 36.5 },
                { 1419, 51.6, 36.9 },
                { 1419, 52.8, 38.1 },
                { 1419, 54.0, 35.7 },
            },
        },
        [10077] = {
            family = "wolf",
            levels = { 53, 53 },
            rank = "rare",
            name = {
                enUS = "Deathmaw",
                zhCN = "死亡之喉",
            },
            spots = {
                { 1428, 75.5, 32.9 },
                { 1428, 81.5, 56.7 },
                { 1428, 82.7, 30.4 },
                { 1428, 87.4, 50.5 },
            },
        },
        [6585] = {
            family = "gorilla",
            levels = { 53, 53 },
            rank = "rare",
            name = {
                enUS = "Uhk'loc",
                zhCN = "乌卡洛克",
            },
            spots = {
                { 1449, 68.5, 12.7 },
            },
        },
        [2931] = {
            family = "carrion-bird",
            levels = { 55, 56 },
            rank = "rareelite",
            name = {
                enUS = "Zaricotl",
                zhCN = "扎里科特",
            },
            spots = {
                { 1418, 34.5, 53.7 },
                { 1418, 35.4, 66.5 },
                { 1418, 56.1, 61.7 },
            },
        },
        [9696] = {
            family = "wolf",
            levels = { 56, 57 },
            featured = true,
            attack = 1.5,
            teaches = {
                { 17261, 8 },
                { 24597, 4 },
            },
            name = {
                enUS = "Bloodaxe Worg",
                zhCN = "血斧座狼",
            },
            why = {
                enUS = "Worgs in Upper Blackrock Spire that come with Bite 8 and Furious Howl 4, the top ranks of both.",
                zhCN = "黑石塔上层的座狼，自带撕咬 8 级与狂怒之嚎 4 级，两个技能都是最高等级。",
            },
            tip = {
                enUS = "Tame one on a raid run through Upper Blackrock Spire, between pulls.",
                zhCN = "在黑石塔上层的团队里趁拉怪间隙驯服。",
            },
            tags = { "group" },
            instances = { "blackrock-spire" },
        },
        [14476] = {
            family = "scorpid",
            levels = { 56, 56 },
            rank = "rare",
            name = {
                enUS = "Krellack",
                zhCN = "克里拉克",
            },
            spots = {
                { 1451, 63.2, 16.7 },
            },
        },
        [14472] = {
            family = "spider",
            levels = { 57, 57 },
            rank = "rare",
            name = {
                enUS = "Gretheer",
                zhCN = "格雷瑟尔",
            },
            spots = {
                { 1451, 39.3, 55.4 },
            },
        },
        [10200] = {
            family = "cat",
            levels = { 57, 57 },
            rank = "rare",
            name = {
                enUS = "Rak'shiri",
                zhCN = "拉克西里",
            },
            spots = {
                { 1452, 51.1, 10.8 },
            },
        },
        [10741] = {
            family = "cat",
            levels = { 60, 60 },
            featured = true,
            name = {
                enUS = "Sian-Rotam",
                zhCN = "赛洛塔姆",
            },
            why = {
                enUS = "The white lion of northern Winterspring, a level 60 beast that only appears after a special summon. A collector's favorite.",
                zhCN = "冬泉谷北部的白狮，60 级，只有完成特殊召唤后才会出现。收藏型玩家的心头好。",
            },
            tip = {
                enUS = "Plan it for level 60. It appears at Frostsaber Rock in the far north of Winterspring, only after its summon.",
                zhCN = "按 60 级规划。它出现在冬泉谷最北端的霜刃石，只有召唤后才会现身。",
            },
            tags = { "look" },
            spots = {
                { 1452, 49.9, 9.8 },
            },
        },
    },
}
