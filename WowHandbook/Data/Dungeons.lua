-- 自动生成，请勿手工编辑。生成脚本：tools/export_site_data.py
-- 来源：wowhandbook src/data/generated（客户端 1.60.1.69913）
local ADDON_NAME, ns = ...
ns.Data = ns.Data or {}
ns.Data.dungeons = {
    {
        slug = "hall-of-thanes",
        kind = "dungeon",
        instanceID = 3065,
        levels = { 13, 13 },
        name = {
            enUS = "The Hall of Thanes",
            zhCN = "领主大厅",
        },
        bosses = {
            {
                name = {
                    enUS = "Faldrim Anvilmar",
                    zhCN = "法德林·安威玛尔",
                },
                items = { 270227, 271096, 271097 },
            },
            {
                name = {
                    enUS = "Infurnus",
                    zhCN = "茵弗努斯",
                },
            },
            {
                name = {
                    enUS = "Plunder",
                    zhCN = "劫掠者",
                },
                items = { 271098, 270228, 270229 },
            },
            {
                name = {
                    enUS = "Durgen Dirgehammer",
                    zhCN = "杜根·挽锤",
                },
                items = { 270256, 270260, 270261, 274286 },
            },
            {
                name = {
                    enUS = "Magmatus",
                },
                items = { 270230, 270231, 271095 },
            },
        },
        quests = { 96393, 96394, 96395, 96403, 98423 },
    },
    {
        slug = "ragefire-chasm",
        kind = "dungeon",
        instanceID = 389,
        levels = { 13, 13 },
        name = {
            enUS = "Ragefire Chasm",
            zhCN = "怒焰裂谷",
        },
        entrance = {
            map = 1454,
            x = 52.96,
            y = 48.87,
        },
        bosses = {
            {
                name = {
                    enUS = "Oggleflint",
                    zhCN = "奥格弗林特",
                },
                items = { 272996, 272998, 272999 },
            },
            {
                name = {
                    enUS = "Taragaman the Hungerer",
                    zhCN = "饥饿者塔拉加曼",
                },
                items = { 14149, 14148, 14145 },
            },
            {
                name = {
                    enUS = "Jergosh the Invoker",
                    zhCN = "祈求者耶戈什",
                },
                items = { 14150, 14147, 14151 },
            },
            {
                name = {
                    enUS = "Bazzalan",
                    zhCN = "巴扎兰",
                },
                items = { 273003, 273005, 273007 },
            },
        },
        quests = { 5722, 5723, 5724, 5725, 5726, 5727, 5728, 5729, 5730, 5761 },
    },
    {
        slug = "ruins-of-lordaeron",
        kind = "dungeon",
        instanceID = 2999,
        levels = { 15, 15 },
        name = {
            enUS = "Ruins of Lordaeron",
            zhCN = "洛丹伦废墟",
        },
        entrance = {
            map = 1420,
        },
        bosses = {
            {
                name = {
                    enUS = "Witherfang",
                    zhCN = "枯牙",
                },
                items = { 271201, 271202, 271203 },
            },
            {
                name = {
                    enUS = "The Abandoned",
                    zhCN = "被遗弃者",
                },
                items = { 271207, 271208, 271216 },
            },
            {
                name = {
                    enUS = "The Butcher",
                    zhCN = "屠夫",
                },
            },
            {
                name = {
                    enUS = "Rath'mael",
                    zhCN = "拉斯玛尔",
                },
                items = { 271213, 271214, 271215 },
            },
            {
                name = {
                    enUS = "Lordaeron Captain",
                    zhCN = "洛丹伦上尉",
                },
            },
            {
                name = {
                    enUS = "Viktor the Vile",
                    zhCN = "邪恶的维克多",
                },
                items = { 271211, 271218 },
            },
            {
                name = {
                    enUS = "Bjork",
                    zhCN = "比约克",
                },
                items = { 271217, 271209, 271210 },
            },
            {
                name = {
                    enUS = "The Baron",
                },
                items = { 271206, 271205, 271204, 280438 },
            },
        },
        quests = { 92401, 92415, 92421, 92422, 95189, 95195, 95204, 95216, 95250, 97288 },
    },
    {
        slug = "deadmines",
        kind = "dungeon",
        instanceID = 36,
        levels = { 16, 16 },
        name = {
            enUS = "The Deadmines",
            zhCN = "死亡矿井",
        },
        entrance = {
            map = 1436,
            x = 38.16,
            y = 77.48,
        },
        bosses = {
            {
                name = {
                    enUS = "Rhahk'Zor",
                    zhCN = "拉克佐",
                },
                items = { 872, 5187, 273289 },
            },
            {
                name = {
                    enUS = "Sneed",
                    zhCN = "斯尼德",
                },
                items = { 5194, 5195, 273293, 1937, 2169, 285292 },
            },
            {
                name = {
                    enUS = "Gilnid",
                    zhCN = "基尔尼格",
                },
                items = { 1156, 5199, 273297 },
            },
            {
                name = {
                    enUS = "Captain Greenskin",
                    zhCN = "绿皮船长",
                },
                items = { 5201, 10403, 5200 },
            },
            {
                name = {
                    enUS = "Mr. Smite",
                    zhCN = "重拳先生",
                },
                items = { 7230, 5192, 5196, 284715 },
            },
            {
                name = {
                    enUS = "Cookie",
                    zhCN = "曲奇",
                },
                items = { 5198, 5197, 8490, 273298 },
            },
            {
                name = {
                    enUS = "Edwin VanCleef",
                    zhCN = "艾德温·范克里夫",
                },
                items = { 5193, 5202, 10399, 5191, 2874 },
            },
        },
        quests = {
            65,
            132,
            135,
            141,
            142,
            155,
            166,
            167,
            168,
            214,
            373,
            2040,
            92753,
        },
    },
    {
        slug = "wailing-caverns",
        kind = "dungeon",
        instanceID = 43,
        levels = { 17, 17 },
        name = {
            enUS = "Wailing Caverns",
            zhCN = "哀嚎洞穴",
        },
        entrance = {
            map = 1413,
            x = 45.99,
            y = 36.27,
        },
        bosses = {
            {
                name = {
                    enUS = "Lady Anacondra",
                    zhCN = "安娜科德拉",
                },
                items = { 10412, 5404, 273088 },
            },
            {
                name = {
                    enUS = "Lord Cobrahn",
                    zhCN = "考布莱恩",
                },
                items = { 6460, 10410, 6465 },
            },
            {
                name = {
                    enUS = "Kresh",
                    zhCN = "克雷什",
                },
                items = { 13245, 6447 },
            },
            {
                name = {
                    enUS = "Lord Pythas",
                    zhCN = "皮萨斯",
                },
                items = { 6472, 6473, 273089 },
            },
            {
                name = {
                    enUS = "Skum",
                    zhCN = "斯卡姆",
                },
                items = { 6449, 6448, 273137 },
            },
            {
                name = {
                    enUS = "Lord Serpentis",
                    zhCN = "瑟芬迪斯",
                },
                items = { 6469, 5970, 10411, 6459 },
            },
            {
                name = {
                    enUS = "Verdan the Everliving",
                    zhCN = "永生者沃尔丹",
                },
                items = { 6630, 6631, 6629 },
            },
            {
                name = {
                    enUS = "Mutanus the Devourer",
                    zhCN = "吞噬者穆坦努斯",
                },
                items = { 6461, 6627, 6463, 10441 },
            },
        },
        quests = {
            865,
            870,
            877,
            880,
            886,
            914,
            959,
            962,
            1486,
            1487,
            1489,
            1490,
            1491,
            3366,
            3369,
            3370,
            6981,
        },
    },
    {
        slug = "shadowfang-keep",
        kind = "dungeon",
        instanceID = 33,
        levels = { 18, 18 },
        name = {
            enUS = "Shadowfang Keep",
            zhCN = "影牙城堡",
        },
        entrance = {
            map = 1421,
            x = 44.72,
            y = 67.77,
        },
        bosses = {
            {
                name = {
                    enUS = "Rethilgore",
                    zhCN = "雷希戈尔",
                },
                items = { 5254, 273456, 273457 },
            },
            {
                name = {
                    enUS = "Razorclaw the Butcher",
                    zhCN = "屠夫拉佐克劳",
                },
                items = { 1292, 6226, 6633 },
            },
            {
                name = {
                    enUS = "Baron Silverlaine",
                    zhCN = "席瓦莱恩男爵",
                },
                items = { 6321, 6323, 273637, 276631 },
            },
            {
                name = {
                    enUS = "Commander Springvale",
                    zhCN = "指挥官斯普林瓦尔",
                },
                items = { 6320, 3191 },
            },
            {
                name = {
                    enUS = "Odo the Blindwatcher",
                    zhCN = "盲眼守卫奥杜",
                },
                items = { 6318, 6319, 273645 },
            },
            {
                name = {
                    enUS = "Fenrus the Devourer",
                    zhCN = "吞噬者芬鲁斯",
                },
                items = { 6340, 3230, 273646 },
            },
            {
                name = {
                    enUS = "Wolf Master Nandos",
                    zhCN = "狼王南杜斯",
                },
                items = { 3748, 6314 },
            },
            {
                name = {
                    enUS = "Archmage Arugal",
                    zhCN = "大法师阿鲁高",
                },
                items = { 6324, 6392, 6220 },
            },
        },
        quests = { 1013, 1014, 1098, 1740 },
    },
    {
        slug = "blackfathom-deeps",
        kind = "dungeon",
        instanceID = 48,
        levels = { 22, 22 },
        name = {
            enUS = "Blackfathom Deeps",
            zhCN = "黑暗深渊",
        },
        entrance = {
            map = 1439,
            x = 33.49,
            y = 93.53,
        },
        bosses = {
            {
                name = {
                    enUS = "Ghamoo-ra",
                    zhCN = "加摩拉",
                },
                items = { 6907, 6908 },
            },
            {
                name = {
                    enUS = "Lady Sarevess",
                    zhCN = "萨利维丝",
                },
                items = { 888, 3078, 11121 },
            },
            {
                name = {
                    enUS = "Geilhast",
                    zhCN = "格里哈斯特",
                },
                items = { 6906, 6905, 1470 },
            },
            {
                name = {
                    enUS = "Lorgus Jett",
                    zhCN = "洛古斯·杰特",
                },
            },
            {
                name = {
                    enUS = "Old Serra'kis",
                    zhCN = "瑟拉吉斯",
                },
                items = { 6901, 6904, 6902 },
            },
            {
                name = {
                    enUS = "Twilight Lord Kelris",
                    zhCN = "暮光领主克尔里斯",
                },
                items = { 1155, 6903 },
            },
            {
                name = {
                    enUS = "Aku'mai",
                    zhCN = "阿库麦尔",
                },
                items = { 6911, 6910, 6909 },
            },
        },
        quests = {
            971,
            1198,
            1199,
            1200,
            1275,
            1740,
            3765,
            6561,
            6562,
            6563,
            6564,
            6565,
            6921,
            6922,
        },
    },
    {
        slug = "stockade",
        kind = "dungeon",
        instanceID = 34,
        levels = { 23, 23 },
        name = {
            enUS = "The Stockade",
            zhCN = "监狱",
        },
        entrance = {
            map = 1453,
            x = 50.35,
            y = 66.18,
        },
        bosses = {
            {
                name = {
                    enUS = "Targorr the Dread",
                    zhCN = "可怕的塔格尔",
                },
            },
            {
                name = {
                    enUS = "Kam Deepfury",
                    zhCN = "卡姆·深怒",
                },
                items = { 2280 },
            },
            {
                name = {
                    enUS = "Hamhock",
                    zhCN = "哈姆霍克",
                },
            },
            {
                name = {
                    enUS = "Dextren Ward",
                    zhCN = "迪克斯特·瓦德",
                },
            },
            {
                name = {
                    enUS = "Bazil Thredd",
                    zhCN = "巴吉尔·特雷德",
                },
            },
        },
        quests = { 377, 378, 386, 387, 388, 391 },
    },
    {
        slug = "razorfen-kraul",
        kind = "dungeon",
        instanceID = 47,
        levels = { 24, 24 },
        name = {
            enUS = "Razorfen Kraul",
            zhCN = "剃刀沼泽",
        },
        entrance = {
            map = 1413,
            x = 42.27,
            y = 89.87,
        },
        bosses = {
            {
                name = {
                    enUS = "Roogug",
                    zhCN = "鲁古格",
                },
            },
            {
                name = {
                    enUS = "Aggem Thorncurse",
                    zhCN = "阿格姆",
                },
                items = { 6681 },
            },
            {
                name = {
                    enUS = "Death Speaker Jargba",
                    zhCN = "亡语者贾格巴",
                },
                items = { 2816, 6685, 6682 },
            },
            {
                name = {
                    enUS = "Overlord Ramtusk",
                    zhCN = "主宰拉姆塔斯",
                },
                items = { 6687, 6686 },
            },
            {
                name = {
                    enUS = "Agathelos the Raging",
                    zhCN = "暴怒的阿迦赛罗斯",
                },
                items = { 6691, 6690 },
            },
            {
                name = {
                    enUS = "Charlga Razorflank",
                    zhCN = "卡尔加·刺肋",
                },
                items = { 6692, 17008 },
            },
        },
        quests = { 1100, 1101, 1102, 1109, 1142, 1144, 1221, 1701, 1838, 6521, 6522 },
    },
    {
        slug = "gnomeregan",
        kind = "dungeon",
        instanceID = 90,
        levels = { 25, 25 },
        name = {
            enUS = "Gnomeregan",
            zhCN = "诺莫瑞根",
        },
        entrance = {
            map = 1426,
            x = 17.67,
            y = 39.15,
        },
        bosses = {
            {
                name = {
                    enUS = "Grubbis",
                    zhCN = "格鲁比斯",
                },
                items = { 9445 },
            },
            {
                name = {
                    enUS = "Viscous Fallout",
                    zhCN = "粘性辐射尘",
                },
                items = { 9454, 9453, 9452 },
            },
            {
                name = {
                    enUS = "Electrocutioner 6000",
                    zhCN = "电刑器6000型",
                },
                items = { 9447, 9446, 9448, 6893 },
            },
            {
                name = {
                    enUS = "Crowd Pummeler 9-60",
                    zhCN = "群体打击者9-60",
                },
                items = { 9449, 9450 },
            },
            {
                name = {
                    enUS = "Mekgineer Thermaplugg",
                    zhCN = "机械师瑟玛普拉格",
                },
                items = { 9461, 9458, 4415, 4413, 4411, 7742, 11828 },
            },
        },
        quests = {
            2841,
            2842,
            2843,
            2904,
            2922,
            2923,
            2924,
            2926,
            2927,
            2928,
            2929,
            2930,
            2945,
            2947,
            2948,
            2949,
            2950,
            2962,
        },
    },
    {
        slug = "excavation-site-wetlands",
        kind = "dungeon",
        instanceID = 2998,
        levels = { 26, 26 },
        name = {
            enUS = "Excavation Site: Wetlands",
            zhCN = "挖掘场：湿地",
        },
        entrance = {
            map = 1437,
        },
        bosses = {
            {
                name = {
                    enUS = "Saltspine",
                    zhCN = "盐脊",
                },
            },
            {
                name = {
                    enUS = "Shadetooth",
                    zhCN = "暗齿",
                },
            },
            {
                name = {
                    enUS = "Highland Horror",
                },
            },
            {
                name = {
                    enUS = "Relic Guardian",
                    zhCN = "遗迹守卫者",
                },
            },
        },
    },
    {
        slug = "city-of-dalaran",
        kind = "dungeon",
        instanceID = 2959,
        levels = { 28, 28 },
        name = {
            enUS = "City of Dalaran",
            zhCN = "达拉然城",
        },
        bosses = {
            {
                name = {
                    enUS = "Arcane Anomaly",
                    zhCN = "奥术畸体",
                },
            },
            {
                name = {
                    enUS = "Fel Ancient",
                    zhCN = "邪能古树",
                },
            },
            {
                name = {
                    enUS = "Mana Devourer",
                    zhCN = "法力吞噬者",
                },
            },
            {
                name = {
                    enUS = "Mana Elemental",
                    zhCN = "法力元素",
                },
            },
            {
                name = {
                    enUS = "Unstable Sentinel",
                    zhCN = "不稳定的哨兵",
                },
            },
            {
                name = {
                    enUS = "Shade of the Archmage",
                    zhCN = "大法师之影",
                },
            },
            {
                name = {
                    enUS = "Lyn the Ignored",
                    zhCN = "被无视的琳恩",
                },
            },
            {
                name = {
                    enUS = "Atrexis the Grave Knight",
                    zhCN = "墓穴骑士阿特雷克斯",
                },
            },
            {
                name = {
                    enUS = "Mana Wraith",
                    zhCN = "法力怨魂",
                },
            },
        },
    },
    {
        slug = "scarlet-monastery",
        kind = "dungeon",
        instanceID = 189,
        levels = { 30, 30 },
        name = {
            enUS = "Scarlet Monastery",
            zhCN = "血色修道院",
        },
        entrance = {
            map = 1420,
            x = 85.08,
            y = 31.38,
        },
        bosses = {
            {
                name = {
                    enUS = "Interrogator Vishas",
                    zhCN = "审讯员韦沙斯",
                },
                items = { 7682 },
            },
            {
                name = {
                    enUS = "Bloodmage Thalnos",
                    zhCN = "血法师萨尔诺斯",
                },
                items = { 7685, 7684 },
            },
            {
                name = {
                    enUS = "Houndmaster Loksey",
                    zhCN = "驯犬者洛克希",
                },
                items = { 7710 },
            },
            {
                name = {
                    enUS = "Arcanist Doan",
                    zhCN = "奥法师杜安",
                },
                items = { 7714, 7713, 7711 },
            },
            {
                name = {
                    enUS = "Herod",
                    zhCN = "赫洛德",
                },
                items = { 7719, 10330, 7717 },
            },
            {
                name = {
                    enUS = "High Inquisitor Fairbanks",
                    zhCN = "大检察官法尔班克斯",
                },
                items = { 19507, 19508, 19509 },
            },
            {
                name = {
                    enUS = "High Inquisitor Whitemane",
                    zhCN = "大检察官怀特迈恩",
                },
                items = { 7721 },
            },
        },
        quests = { 261, 1048, 1049, 1050, 1051, 1052, 1053, 1113, 1160, 1951 },
    },
    {
        slug = "razorfen-downs",
        kind = "dungeon",
        instanceID = 129,
        levels = { 34, 34 },
        name = {
            enUS = "Razorfen Downs",
            zhCN = "剃刀高地",
        },
        entrance = {
            map = 1413,
            x = 50.91,
            y = 92.88,
        },
        bosses = {
            {
                name = {
                    enUS = "Tuten'kash",
                    zhCN = "图特卡什",
                },
                items = { 10775 },
            },
            {
                name = {
                    enUS = "Plaguemaw the Rotting",
                    zhCN = "腐烂的普雷莫尔",
                },
            },
            {
                name = {
                    enUS = "Mordresh Fire Eye",
                    zhCN = "火眼莫德雷斯",
                },
                items = { 10771 },
            },
            {
                name = {
                    enUS = "Ragglesnout",
                    zhCN = "拉戈斯诺特",
                },
            },
            {
                name = {
                    enUS = "Glutton",
                    zhCN = "暴食者",
                },
                items = { 10774, 10772 },
            },
            {
                name = {
                    enUS = "Amnennar the Coldbringer",
                    zhCN = "寒冰之王亚门纳尔",
                },
                items = { 10763, 10762, 10764, 10761, 10765 },
            },
        },
        quests = { 3341, 3523, 3525, 3636, 6626 },
    },
    {
        slug = "uldaman",
        kind = "dungeon",
        instanceID = 70,
        levels = { 35, 35 },
        name = {
            enUS = "Uldaman",
            zhCN = "奥达曼",
        },
        entrance = {
            map = 1418,
            x = 44.23,
            y = 12.21,
        },
        bosses = {
            {
                name = {
                    enUS = "Revelosh",
                    zhCN = "鲁维罗什",
                },
                items = { 9389, 9390, 7741 },
            },
            {
                name = {
                    enUS = "The Lost Dwarves",
                    zhCN = "失踪的矮人",
                },
            },
            {
                name = {
                    enUS = "Ironaya",
                    zhCN = "艾隆纳亚",
                },
                items = { 9407 },
            },
            {
                name = {
                    enUS = "Obsidian Sentinel",
                    zhCN = "黑曜石哨兵",
                },
                items = { 8053 },
            },
            {
                name = {
                    enUS = "Ancient Stone Keeper",
                    zhCN = "古代的石头看守者",
                },
                items = { 9411 },
            },
            {
                name = {
                    enUS = "Galgann Firehammer",
                    zhCN = "加加恩·火锤",
                },
            },
            {
                name = {
                    enUS = "Grimlok",
                    zhCN = "格瑞姆洛克",
                },
                items = { 9415, 9416, 9414, 7670 },
            },
            {
                name = {
                    enUS = "Archaedas",
                    zhCN = "阿扎达斯",
                },
            },
        },
        quests = {
            17,
            704,
            707,
            709,
            720,
            721,
            722,
            723,
            724,
            738,
            739,
            1139,
            1360,
            1956,
            2198,
            2199,
            2200,
            2201,
            2202,
            2240,
            2279,
            2280,
            2283,
            2284,
            2318,
            2338,
            2339,
            2342,
            2361,
            2398,
            2418,
            2439,
            2440,
        },
    },
    {
        slug = "maraudon",
        kind = "dungeon",
        instanceID = 349,
        levels = { 42, 42 },
        name = {
            enUS = "Maraudon",
            zhCN = "玛拉顿",
        },
        entrance = {
            map = 1443,
            x = 29.25,
            y = 62.53,
        },
        bosses = {
            {
                name = {
                    enUS = "Noxxion",
                    zhCN = "诺克赛恩",
                },
                items = { 17745 },
            },
            {
                name = {
                    enUS = "Razorlash",
                    zhCN = "锐刺鞭笞者",
                },
                items = { 17748 },
            },
            {
                name = {
                    enUS = "Tinkerer Gizlock",
                    zhCN = "工匠吉兹洛克",
                },
                items = { 17717, 17719 },
            },
            {
                name = {
                    enUS = "Lord Vyletongue",
                    zhCN = "维利塔恩",
                },
                items = { 17755 },
            },
            {
                name = {
                    enUS = "Celebras the Cursed",
                    zhCN = "被诅咒的塞雷布拉斯",
                },
                items = { 17740, 17739, 17738 },
            },
            {
                name = {
                    enUS = "Landslide",
                    zhCN = "兰斯利德",
                },
                items = { 17943 },
            },
            {
                name = {
                    enUS = "Rotgrip",
                    zhCN = "洛特格里普",
                },
                items = { 17732, 17728, 17730 },
            },
            {
                name = {
                    enUS = "Princess Theradras",
                    zhCN = "瑟莱德丝公主",
                },
                items = { 17715, 17714, 17713, 17710, 17766 },
            },
        },
        quests = { 7028, 7029, 7041, 7044, 7064, 7065, 7066, 7067, 7068, 7070 },
    },
    {
        slug = "zulfarrak",
        kind = "dungeon",
        instanceID = 209,
        levels = { 42, 42 },
        name = {
            enUS = "Zul'Farrak",
            zhCN = "祖尔法拉克",
        },
        entrance = {
            map = 1446,
            x = 38.73,
            y = 19.9,
        },
        bosses = {
            {
                name = {
                    enUS = "Hydromancer Velratha",
                    zhCN = "水占师维蕾萨",
                },
                items = { 9234, 10661 },
            },
            {
                name = {
                    enUS = "Gahz'rilla",
                    zhCN = "加兹瑞拉",
                },
                items = { 9469, 9467 },
            },
            {
                name = {
                    enUS = "Antu'sul",
                    zhCN = "安图苏尔",
                },
                items = { 9640, 9639, 9379 },
            },
            {
                name = {
                    enUS = "Theka the Martyr",
                    zhCN = "殉教者塞卡",
                },
                items = { 10660 },
            },
            {
                name = {
                    enUS = "Witch Doctor Zum'rah",
                    zhCN = "巫医祖穆拉恩",
                },
                items = { 18082 },
            },
            {
                name = {
                    enUS = "Nekrum Gutchewer",
                    zhCN = "耐克鲁姆",
                },
                items = { 9471 },
            },
            {
                name = {
                    enUS = "Shadowpriest Sezz'ziz",
                    zhCN = "暗影祭司塞瑟斯",
                },
                items = { 9470, 9474, 9475 },
            },
            {
                name = {
                    enUS = "Chief Ukorz Sandscalp",
                    zhCN = "乌克兹·沙顶",
                },
                items = { 9476, 9477, 11086 },
            },
        },
        quests = { 2768, 2770, 2846, 2865, 2936, 2991, 3042, 3527 },
    },
    {
        slug = "temple-of-atalhakkar",
        kind = "dungeon",
        instanceID = 109,
        levels = { 45, 45 },
        name = {
            enUS = "The Temple of Atal'Hakkar",
            zhCN = "阿塔哈卡神庙",
        },
        entrance = {
            map = 1435,
            x = 77.3,
            y = 35.92,
        },
        bosses = {
            {
                name = {
                    enUS = "Atal'alarion",
                    zhCN = "阿塔拉利恩",
                },
                items = { 10799 },
            },
            {
                name = {
                    enUS = "Avatar of Hakkar",
                    zhCN = "哈卡的化身",
                },
                items = { 10838, 10844 },
            },
            {
                name = {
                    enUS = "Shade of Eranikus",
                    zhCN = "伊兰尼库斯的阴影",
                },
                items = { 10833, 10454 },
            },
            {
                name = {
                    enUS = "Hazzas",
                    zhCN = "哈扎斯",
                },
                items = { 12465, 12466, 12243 },
            },
            {
                name = {
                    enUS = "Morphaz",
                    zhCN = "摩弗拉斯",
                },
                items = { 12465, 12466, 12243 },
            },
            {
                name = {
                    enUS = "Weaver",
                    zhCN = "德拉维沃尔",
                },
                items = { 12465, 12466, 12243 },
            },
            {
                name = {
                    enUS = "Dreamscythe",
                    zhCN = "德姆塞卡尔",
                },
                items = { 12465, 12466, 12243 },
            },
            {
                name = {
                    enUS = "Jammal'an the Prophet",
                    zhCN = "预言者迦玛兰",
                },
                items = { 10807 },
            },
        },
        quests = { 1445, 1446, 1475, 3373, 3374, 3446, 3447, 3528, 4143, 4146, 4787 },
    },
    {
        slug = "blackrock-depths",
        kind = "dungeon",
        instanceID = 230,
        levels = { 48, 48 },
        name = {
            enUS = "Blackrock Depths",
            zhCN = "黑石深渊",
        },
        entrance = {
            map = 1427,
            x = 27.15,
            y = 72.48,
        },
        bosses = {
            {
                name = {
                    enUS = "High Interrogator Gerstahn",
                    zhCN = "审讯官格斯塔恩",
                },
                items = { 22240, 11140 },
            },
            {
                name = {
                    enUS = "Lord Roccor",
                    zhCN = "洛考尔",
                },
                items = { 11632, 11631, 11630, 11813 },
            },
            {
                name = {
                    enUS = "Houndmaster Grebmar",
                    zhCN = "驯犬者格雷布玛尔",
                },
                items = { 11623, 11627, 11628 },
            },
            {
                name = {
                    enUS = "Ring of Law",
                    zhCN = "秩序竞技场",
                },
            },
            {
                name = {
                    enUS = "Pyromancer Loregrain",
                    zhCN = "控火师罗格雷恩",
                },
                items = { 11747, 11749, 11748, 11750, 11207 },
            },
            {
                name = {
                    enUS = "Lord Incendius",
                    zhCN = "伊森迪奥斯",
                },
                items = { 11764, 11765, 19268 },
            },
            {
                name = {
                    enUS = "Warder Stilgiss",
                    zhCN = "典狱官斯迪尔基斯",
                },
                items = { 22241 },
            },
            {
                name = {
                    enUS = "Fineous Darkvire",
                    zhCN = "弗诺斯·达克维尔",
                },
                items = { 11841, 11840 },
            },
            {
                name = {
                    enUS = "Bael'Gar",
                    zhCN = "贝尔加",
                },
            },
            {
                name = {
                    enUS = "General Angerforge",
                    zhCN = "安格弗将军",
                },
                items = { 11821, 11817, 11841 },
            },
            {
                name = {
                    enUS = "Golem Lord Argelmach",
                    zhCN = "傀儡统帅阿格曼奇",
                },
                items = { 11823, 11822 },
            },
            {
                name = {
                    enUS = "Hurley Blackbreath",
                    zhCN = "霍尔雷·黑须",
                },
            },
            {
                name = {
                    enUS = "Phalanx",
                    zhCN = "法拉克斯",
                },
                items = { 11745 },
            },
            {
                name = {
                    enUS = "Ribbly Screwspigot",
                    zhCN = "雷布里·斯库比格特",
                },
            },
            {
                name = {
                    enUS = "Plugger Spazzring",
                    zhCN = "普拉格",
                },
            },
            {
                name = {
                    enUS = "The Vault",
                    zhCN = "银行",
                },
            },
            {
                name = {
                    enUS = "Ambassador Flamelash",
                    zhCN = "弗莱拉斯大使",
                },
                items = { 23320 },
            },
            {
                name = {
                    enUS = "The Seven",
                    zhCN = "黑铁七贤",
                },
            },
            {
                name = {
                    enUS = "Magmus",
                    zhCN = "玛格姆斯",
                },
                items = { 11746 },
            },
            {
                name = {
                    enUS = "Princess Moira Bronzebeard",
                    zhCN = "铁炉堡公主茉艾拉·铜须",
                },
            },
            {
                name = {
                    enUS = "Emperor Dagran Thaurissan",
                    zhCN = "达格兰·索瑞森大帝",
                },
                items = { 12033 },
            },
        },
        quests = {
            3701,
            3702,
            3801,
            3802,
            3906,
            3907,
            3981,
            3982,
            4001,
            4003,
            4022,
            4023,
            4024,
            4061,
            4062,
            4063,
            4081,
            4082,
            4121,
            4122,
            4123,
            4126,
            4128,
            4132,
            4133,
            4134,
            4136,
            4182,
            4183,
            4184,
            4185,
            4186,
            4201,
            4223,
            4224,
            4241,
            4262,
            4263,
            4286,
            4324,
            4341,
            4342,
            4361,
            4362,
            7201,
            7848,
        },
    },
    {
        slug = "blackrock-spire",
        kind = "dungeon",
        instanceID = 229,
        levels = { 53, 53 },
        name = {
            enUS = "Blackrock Spire",
            zhCN = "黑石塔",
        },
        entrance = {
            map = 1428,
            x = 32.99,
            y = 25.17,
        },
        bosses = {
            {
                name = {
                    enUS = "Highlord Omokk",
                    zhCN = "欧莫克大王",
                },
                items = { 16670, 12336, 12534 },
            },
            {
                name = {
                    enUS = "Shadow Hunter Vosh'gajin",
                    zhCN = "暗影猎手沃什加斯",
                },
                items = { 16712, 12651 },
            },
            {
                name = {
                    enUS = "War Master Voone",
                    zhCN = "指挥官沃恩",
                },
                items = { 16676, 12335 },
            },
            {
                name = {
                    enUS = "Mother Smolderweb",
                    zhCN = "烟网蛛后",
                },
                items = { 16715 },
            },
            {
                name = {
                    enUS = "Urok Doomhowl",
                    zhCN = "乌洛克",
                },
                items = { 18784 },
            },
            {
                name = {
                    enUS = "Quartermaster Zigris",
                    zhCN = "军需官兹格雷斯",
                },
                items = { 13247, 12835 },
            },
            {
                name = {
                    enUS = "Halycon",
                    zhCN = "哈雷肯",
                },
            },
            {
                name = {
                    enUS = "Gizrul the Slavener",
                    zhCN = "奴役者基兹鲁尔",
                },
                items = { 16718 },
            },
            {
                name = {
                    enUS = "Overlord Wyrmthalak",
                    zhCN = "维姆萨拉克",
                },
                items = { 16679, 13164, 12337, 12780 },
            },
            {
                name = {
                    enUS = "Pyroguard Emberseer",
                    zhCN = "烈焰卫士艾博希尔",
                },
                items = { 16672, 23320 },
            },
            {
                name = {
                    enUS = "Warchief Rend Blackhand",
                    zhCN = "大酋长雷德·黑手",
                },
                items = { 16733 },
            },
            {
                name = {
                    enUS = "The Beast",
                    zhCN = "比斯巨兽",
                },
                items = { 16729, 24101, 19227 },
            },
            {
                name = {
                    enUS = "General Drakkisath",
                    zhCN = "达基萨斯将军",
                },
                items = {
                    13142,
                    12602,
                    15730,
                    13519,
                    16690,
                    16688,
                    16700,
                    16721,
                    16706,
                    16674,
                    16666,
                    16726,
                    16730,
                },
            },
            {
                name = {
                    enUS = "Lord Valthalak",
                    zhCN = "瓦塔拉克公爵",
                },
            },
        },
        quests = {
            4701,
            4724,
            4729,
            4742,
            4743,
            4764,
            4766,
            4768,
            4788,
            4862,
            4903,
            4974,
            4981,
            4982,
            5001,
            5002,
            5065,
            5081,
            5089,
            5102,
            5126,
            5127,
            5160,
            6804,
            6805,
            6821,
            7761,
        },
    },
    {
        slug = "dire-maul",
        kind = "dungeon",
        instanceID = 429,
        levels = { 54, 54 },
        name = {
            enUS = "Dire Maul",
            zhCN = "厄运之槌",
        },
        entrance = {
            map = 1444,
            x = 62.04,
            y = 33.27,
        },
        bosses = {
            {
                name = {
                    enUS = "Zevrim Thornhoof",
                    zhCN = "瑟雷姆·刺蹄",
                },
            },
            {
                name = {
                    enUS = "Hydrospawn",
                    zhCN = "海多斯博恩",
                },
                items = { 19268 },
            },
            {
                name = {
                    enUS = "Lethtendris",
                    zhCN = "蕾瑟塔蒂丝",
                },
            },
            {
                name = {
                    enUS = "Pusillin",
                    zhCN = "普希林",
                },
                items = { 18267, 18249 },
            },
            {
                name = {
                    enUS = "Alzzin the Wildshaper",
                    zhCN = "奥兹恩",
                },
            },
            {
                name = {
                    enUS = "Tendris Warpwood",
                    zhCN = "特迪斯·扭木",
                },
            },
            {
                name = {
                    enUS = "Illyanna Ravenoak",
                    zhCN = "伊琳娜·暗木",
                },
            },
            {
                name = {
                    enUS = "Magister Kalendris",
                    zhCN = "卡雷迪斯镇长",
                },
                items = { 22309 },
            },
            {
                name = {
                    enUS = "Immol'thar",
                    zhCN = "伊莫塔尔",
                },
            },
            {
                name = {
                    enUS = "Prince Tortheldrin",
                    zhCN = "托塞德林王子",
                },
            },
            {
                name = {
                    enUS = "Guard Mol'dar",
                    zhCN = "卫兵摩尔达",
                },
                items = { 18250, 18268 },
            },
            {
                name = {
                    enUS = "Stomper Kreeg",
                    zhCN = "践踏者克雷格",
                },
                items = { 18269, 18284, 18287, 18288, 9260 },
            },
            {
                name = {
                    enUS = "Guard Fengus",
                    zhCN = "卫兵芬古斯",
                },
                items = { 18250, 18266 },
            },
            {
                name = {
                    enUS = "Guard Slip'kik",
                    zhCN = "卫兵斯里基克",
                },
                items = { 18250 },
            },
            {
                name = {
                    enUS = "Captain Kromcrush",
                    zhCN = "克罗卡斯",
                },
            },
            {
                name = {
                    enUS = "Cho'Rush the Observer",
                    zhCN = "观察者克鲁什",
                },
            },
            {
                name = {
                    enUS = "King Gordok",
                    zhCN = "戈多克大王",
                },
                items = { 19258, 18780 },
            },
            {
                name = {
                    enUS = "Lord Hel'nurath",
                    zhCN = "赫尔努拉斯",
                },
            },
            {
                name = {
                    enUS = "Tsu'zee",
                    zhCN = "苏斯",
                },
            },
        },
        quests = {
            5518,
            5525,
            5526,
            5527,
            7441,
            7461,
            7462,
            7481,
            7482,
            7488,
            7489,
            7503,
            7631,
            7703,
            7877,
        },
    },
    {
        slug = "stratholme",
        kind = "dungeon",
        instanceID = 329,
        levels = { 55, 55 },
        name = {
            enUS = "Stratholme",
            zhCN = "斯坦索姆",
        },
        entrance = {
            map = 1423,
            x = 26.09,
            y = 10.44,
        },
        bosses = {
            {
                name = {
                    enUS = "Hearthsinger Forresten",
                    zhCN = "弗雷斯特恩",
                },
                items = { 16682 },
            },
            {
                name = {
                    enUS = "Timmy the Cruel",
                    zhCN = "残忍的提米",
                },
                items = { 16724, 13400, 13402 },
            },
            {
                name = {
                    enUS = "Malor the Zealous",
                    zhCN = "狂热的玛洛尔",
                },
                items = { 12845 },
            },
            {
                name = {
                    enUS = "Cannon Master Willey",
                    zhCN = "炮手威利",
                },
                items = { 16708, 12839 },
            },
            {
                name = {
                    enUS = "Archivist Galford",
                    zhCN = "档案管理员加尔福特",
                },
                items = { 16692, 13387, 12811, 22897 },
            },
            {
                name = {
                    enUS = "Balnazzar",
                    zhCN = "巴纳扎尔",
                },
                items = { 14512, 16725, 18720, 13520, 13250 },
            },
            {
                name = {
                    enUS = "The Unforgiven",
                    zhCN = "不可宽恕者",
                },
                items = { 16717, 13404, 13405 },
            },
            {
                name = {
                    enUS = "Baroness Anastari",
                    zhCN = "安娜丝塔丽男爵夫人",
                },
                items = { 16704 },
            },
            {
                name = {
                    enUS = "Nerub'enkan",
                    zhCN = "奈鲁布恩坎",
                },
                items = { 16675 },
            },
            {
                name = {
                    enUS = "Maleki the Pallid",
                    zhCN = "苍白的玛勒基",
                },
                items = { 16691, 13509, 12833 },
            },
            {
                name = {
                    enUS = "Magistrate Barthilas",
                    zhCN = "巴瑟拉斯镇长",
                },
                items = { 18722, 12382 },
            },
            {
                name = {
                    enUS = "Ramstein the Gorger",
                    zhCN = "吞咽者拉姆斯登",
                },
                items = { 16737 },
            },
            {
                name = {
                    enUS = "Baron Rivendare",
                    zhCN = "瑞文戴尔男爵",
                },
                items = { 13335, 13340, 16694, 16687, 16699, 16709, 16719, 16678, 16668, 16728, 16732 },
            },
            {
                name = {
                    enUS = "Black Guard Swordsmith",
                    zhCN = "黑衣守卫铸剑师",
                },
                items = { 18783 },
            },
            {
                name = {
                    enUS = "Crimson Hammersmith",
                    zhCN = "红衣铸锤师",
                },
                items = { 18781 },
            },
            {
                name = {
                    enUS = "Ezra Grimm",
                    zhCN = "艾兹拉·格里姆",
                },
            },
            {
                name = {
                    enUS = "Postmaster Malown",
                    zhCN = "邮差马龙",
                },
            },
            {
                name = {
                    enUS = "Skul",
                    zhCN = "斯库尔",
                },
            },
            {
                name = {
                    enUS = "Stonespine",
                    zhCN = "石脊",
                },
                items = { 13397 },
            },
        },
        quests = {
            4941,
            5125,
            5212,
            5213,
            5214,
            5243,
            5251,
            5262,
            5263,
            5281,
            5282,
            5542,
            5845,
        },
    },
    {
        slug = "scholomance",
        kind = "dungeon",
        instanceID = 289,
        levels = { 57, 57 },
        name = {
            enUS = "Scholomance",
            zhCN = "通灵学院",
        },
        entrance = {
            map = 1422,
            x = 69.68,
            y = 73.41,
        },
        bosses = {
            {
                name = {
                    enUS = "Kirtonos",
                    zhCN = "基尔图诺斯",
                },
                items = { 16734 },
            },
            {
                name = {
                    enUS = "Jandice Barov",
                    zhCN = "詹迪斯·巴罗夫",
                },
                items = { 16701, 13523 },
            },
            {
                name = {
                    enUS = "Rattlegore",
                    zhCN = "血骨傀儡",
                },
                items = { 16711, 18782, 13873 },
            },
            {
                name = {
                    enUS = "Marduk Blackpool",
                    zhCN = "马杜克·布莱克波尔",
                },
            },
            {
                name = {
                    enUS = "Vectus",
                    zhCN = "维克图斯",
                },
            },
            {
                name = {
                    enUS = "Kormok",
                    zhCN = "库尔莫克",
                },
            },
            {
                name = {
                    enUS = "Ras Frostwhisperer",
                    zhCN = "莱斯·霜语",
                },
                items = { 16689, 14525, 13521 },
            },
            {
                name = {
                    enUS = "Instructor Malicia",
                    zhCN = "讲师玛丽希亚",
                },
                items = { 16710, 14624, 14622, 14620, 14623, 14621 },
            },
            {
                name = {
                    enUS = "Doctor Theolen Krastinov",
                    zhCN = "瑟尔林·卡斯迪诺夫教授",
                },
                items = { 16684, 14617, 14624, 14622, 14620, 14623, 14621 },
            },
            {
                name = {
                    enUS = "Lorekeeper Polkelt",
                    zhCN = "博学者普克尔特",
                },
                items = { 16705, 14624, 14622, 14620, 14623, 14621 },
            },
            {
                name = {
                    enUS = "The Ravenian",
                    zhCN = "拉文尼亚",
                },
                items = { 16716, 14624, 14622, 14620, 14623, 14621 },
            },
            {
                name = {
                    enUS = "Lord Alexei Barov",
                    zhCN = "阿雷克斯·巴罗夫",
                },
                items = { 16722, 14624, 14622, 14620, 14623, 14621 },
            },
            {
                name = {
                    enUS = "Lady Illucia Barov",
                    zhCN = "伊露希亚·巴罗夫",
                },
                items = { 14624, 14622, 14620, 14623, 14621 },
            },
            {
                name = {
                    enUS = "Darkmaster Gandling",
                    zhCN = "黑暗院长加丁",
                },
                items = { 14514, 16693, 16686, 16698, 16707, 16720, 16677, 16667, 16727, 16731, 19276, 13501 },
            },
        },
        quests = { 4771, 5341, 5343, 5382, 5384, 5466, 5505, 5511, 8258 },
    },
    {
        slug = "blackwing-lair",
        kind = "raid",
        instanceID = 469,
        levels = { 60, 60 },
        name = {
            enUS = "Blackwing Lair",
            zhCN = "黑翼之巢",
        },
        entrance = {
            map = 1428,
            x = 32.5,
            y = 32.38,
        },
        bosses = {
            {
                name = {
                    enUS = "Razorgore the Untamed",
                    zhCN = "狂野的拉佐格尔",
                },
            },
            {
                name = {
                    enUS = "Vaelastrasz the Corrupt",
                    zhCN = "堕落的瓦拉斯塔兹",
                },
            },
            {
                name = {
                    enUS = "Broodlord Lashlayer",
                    zhCN = "勒什雷尔",
                },
            },
            {
                name = {
                    enUS = "Firemaw",
                    zhCN = "费尔默",
                },
            },
            {
                name = {
                    enUS = "Ebonroc",
                    zhCN = "埃博诺克",
                },
            },
            {
                name = {
                    enUS = "Flamegor",
                    zhCN = "弗莱格尔",
                },
            },
            {
                name = {
                    enUS = "Chromaggus",
                    zhCN = "克洛玛古斯",
                },
            },
            {
                name = {
                    enUS = "Nefarian",
                    zhCN = "奈法利安",
                },
            },
        },
    },
    {
        slug = "molten-core",
        kind = "raid",
        instanceID = 409,
        levels = { 60, 60 },
        name = {
            enUS = "Molten Core",
            zhCN = "熔火之心",
        },
        entrance = {
            map = 1428,
            x = 26.29,
            y = 24.55,
        },
        bosses = {
            {
                name = {
                    enUS = "Lucifron",
                    zhCN = "鲁西弗隆",
                },
            },
            {
                name = {
                    enUS = "Magmadar",
                    zhCN = "玛格曼达",
                },
            },
            {
                name = {
                    enUS = "Gehennas",
                    zhCN = "基赫纳斯",
                },
            },
            {
                name = {
                    enUS = "Garr",
                    zhCN = "加尔",
                },
            },
            {
                name = {
                    enUS = "Shazzrah",
                    zhCN = "沙斯拉尔",
                },
            },
            {
                name = {
                    enUS = "Baron Geddon",
                    zhCN = "迦顿男爵",
                },
            },
            {
                name = {
                    enUS = "Sulfuron Harbinger",
                    zhCN = "萨弗隆先驱者",
                },
            },
            {
                name = {
                    enUS = "Golemagg the Incinerator",
                    zhCN = "焚化者古雷曼格",
                },
            },
            {
                name = {
                    enUS = "Majordomo Executus",
                    zhCN = "管理者埃克索图斯",
                },
            },
            {
                name = {
                    enUS = "Ragnaros",
                    zhCN = "拉格纳罗斯",
                },
            },
        },
    },
    {
        slug = "naxxramas",
        kind = "raid",
        instanceID = 533,
        levels = { 60, 60 },
        name = {
            enUS = "Naxxramas",
            zhCN = "纳克萨玛斯",
        },
        bosses = {
            {
                name = {
                    enUS = "Anub'Rekhan",
                    zhCN = "阿努布雷坎",
                },
            },
            {
                name = {
                    enUS = "Grand Widow Faerlina",
                    zhCN = "黑女巫法琳娜",
                },
            },
            {
                name = {
                    enUS = "Maexxna",
                    zhCN = "迈克斯纳",
                },
            },
            {
                name = {
                    enUS = "Noth the Plaguebringer",
                    zhCN = "瘟疫使者诺斯",
                },
            },
            {
                name = {
                    enUS = "Heigan the Unclean",
                    zhCN = "肮脏的希尔盖",
                },
            },
            {
                name = {
                    enUS = "Loatheb",
                    zhCN = "洛欧塞布",
                },
            },
            {
                name = {
                    enUS = "Instructor Razuvious",
                    zhCN = "教官拉苏维奥斯",
                },
            },
            {
                name = {
                    enUS = "Gothik the Harvester",
                    zhCN = "收割者戈提克",
                },
            },
            {
                name = {
                    enUS = "The Four Horsemen",
                    zhCN = "天启四骑士",
                },
            },
            {
                name = {
                    enUS = "Patchwerk",
                    zhCN = "帕奇维克",
                },
            },
            {
                name = {
                    enUS = "Grobbulus",
                    zhCN = "格罗布鲁斯",
                },
            },
            {
                name = {
                    enUS = "Gluth",
                    zhCN = "格拉斯",
                },
            },
            {
                name = {
                    enUS = "Thaddius",
                    zhCN = "塔迪乌斯",
                },
            },
            {
                name = {
                    enUS = "Sapphiron",
                    zhCN = "萨菲隆",
                },
            },
            {
                name = {
                    enUS = "Kel'Thuzad",
                    zhCN = "克尔苏加德",
                },
            },
        },
    },
    {
        slug = "onyxias-lair",
        kind = "raid",
        instanceID = 249,
        levels = { 60, 60 },
        name = {
            enUS = "Onyxia's Lair",
            zhCN = "奥妮克希亚的巢穴",
        },
        entrance = {
            map = 1445,
            x = 52.3,
            y = 76.14,
        },
        bosses = {
            {
                name = {
                    enUS = "Onyxia",
                    zhCN = "奥妮克希亚",
                },
            },
        },
    },
    {
        slug = "ruins-of-ahnqiraj",
        kind = "raid",
        instanceID = 509,
        levels = { 60, 60 },
        name = {
            enUS = "Ruins of Ahn'Qiraj",
            zhCN = "安其拉废墟",
        },
        entrance = {
            map = 1451,
            x = 29.03,
            y = 92.82,
        },
        bosses = {
            {
                name = {
                    enUS = "Kurinnaxx",
                    zhCN = "库林纳克斯",
                },
            },
            {
                name = {
                    enUS = "General Rajaxx",
                    zhCN = "拉贾克斯将军",
                },
            },
            {
                name = {
                    enUS = "Moam",
                    zhCN = "莫阿姆",
                },
            },
            {
                name = {
                    enUS = "Buru the Gorger",
                    zhCN = "吞咽者布鲁",
                },
            },
            {
                name = {
                    enUS = "Ayamiss the Hunter",
                    zhCN = "狩猎者阿亚米斯",
                },
            },
            {
                name = {
                    enUS = "Ossirian the Unscarred",
                    zhCN = "无疤者奥斯里安",
                },
            },
        },
    },
    {
        slug = "temple-of-ahnqiraj",
        kind = "raid",
        instanceID = 531,
        levels = { 60, 60 },
        name = {
            enUS = "Temple of Ahn'Qiraj",
            zhCN = "安其拉神殿",
        },
        entrance = {
            map = 1451,
            x = 29.02,
            y = 92.7,
        },
        bosses = {
            {
                name = {
                    enUS = "The Prophet Skeram",
                    zhCN = "预言者斯克拉姆",
                },
            },
            {
                name = {
                    enUS = "Silithid Royalty",
                    zhCN = "安其拉三宝",
                },
            },
            {
                name = {
                    enUS = "Battleguard Sartura",
                    zhCN = "沙尔图拉",
                },
            },
            {
                name = {
                    enUS = "Fankriss the Unyielding",
                    zhCN = "顽强的范克瑞斯",
                },
            },
            {
                name = {
                    enUS = "Viscidus",
                    zhCN = "维希度斯",
                },
            },
            {
                name = {
                    enUS = "Princess Huhuran",
                    zhCN = "哈霍兰公主",
                },
            },
            {
                name = {
                    enUS = "Twin Emperors",
                    zhCN = "双子皇帝",
                },
            },
            {
                name = {
                    enUS = "Ouro",
                    zhCN = "奥罗",
                },
            },
            {
                name = {
                    enUS = "C'thun",
                    zhCN = "克苏恩",
                },
            },
        },
    },
    {
        slug = "zulgurub",
        kind = "raid",
        instanceID = 309,
        levels = { 60, 60 },
        name = {
            enUS = "Zul'Gurub",
            zhCN = "祖尔格拉布",
        },
        entrance = {
            map = 1434,
            x = 53.99,
            y = 17.57,
        },
        bosses = {
            {
                name = {
                    enUS = "High Priestess Jeklik",
                    zhCN = "高阶祭司耶克里克",
                },
            },
            {
                name = {
                    enUS = "High Priest Venoxis",
                    zhCN = "高阶祭司温诺希斯",
                },
            },
            {
                name = {
                    enUS = "High Priestess Mar'li",
                    zhCN = "高阶祭司玛尔里",
                },
            },
            {
                name = {
                    enUS = "Bloodlord Mandokir",
                    zhCN = "血领主曼多基尔",
                },
            },
            {
                name = {
                    enUS = "Edge of Madness",
                    zhCN = "疯狂之缘",
                },
            },
            {
                name = {
                    enUS = "High Priest Thekal",
                    zhCN = "高阶祭司塞卡尔",
                },
            },
            {
                name = {
                    enUS = "Gahz'ranka",
                    zhCN = "加兹兰卡",
                },
            },
            {
                name = {
                    enUS = "High Priestess Arlokk",
                    zhCN = "高阶祭司娅尔罗",
                },
            },
            {
                name = {
                    enUS = "Jin'do the Hexxer",
                    zhCN = "妖术师金度",
                },
            },
            {
                name = {
                    enUS = "Hakkar",
                    zhCN = "哈卡",
                },
            },
        },
    },
}
