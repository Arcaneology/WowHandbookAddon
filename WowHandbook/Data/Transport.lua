-- 自动生成的数据文件，请勿手工编辑。
-- Zeppelin tower locations from QuestieDB (https://github.com/Questie/QuestieDB), the Questie project, GPL-3.0.
local ADDON_NAME, ns = ...
ns.Data = ns.Data or {}
ns.Data.transport = {
    hubs = {
        orgrimmar = {
            kind = "zeppelin",
            area = 1637,
            map = 1411,
            x = 50.8,
            y = 13.2,
            name = {
                enUS = "Orgrimmar",
                zhCN = "奥格瑞玛",
            },
        },
        undercity = {
            kind = "zeppelin",
            area = 1497,
            map = 1420,
            x = 61.3,
            y = 59.0,
            name = {
                enUS = "Undercity",
                zhCN = "幽暗城",
            },
        },
        gromgol = {
            kind = "zeppelin",
            area = 117,
            map = 1434,
            x = 31.5,
            y = 29.6,
            name = {
                enUS = "Grom'gol Base Camp",
                zhCN = "格罗姆高营地",
            },
        },
        ratchet = {
            kind = "dock",
            area = 392,
            map = 1413,
            x = 63.7,
            y = 38.6,
            taxiNodes = { 80 },
            name = {
                enUS = "Ratchet",
                zhCN = "棘齿城",
            },
        },
        bootybay = {
            kind = "dock",
            area = 35,
            map = 1434,
            x = 25.9,
            y = 73.1,
            taxiNodes = { 9, 18, 19 },
            name = {
                enUS = "Booty Bay",
                zhCN = "藏宝海湾",
            },
        },
        menethil = {
            kind = "dock",
            area = 150,
            map = 1437,
            berths = {
                theramore = {
                    x = 5.0,
                    y = 63.5,
                },
                southshore = {
                    x = 4.6,
                    y = 57.1,
                },
            },
            taxiNodes = { 7 },
            name = {
                enUS = "Menethil Harbor",
                zhCN = "米奈希尔港",
            },
        },
        southshore = {
            kind = "dock",
            area = 271,
            map = 1424,
            x = 50.6,
            y = 69.8,
            taxiNodes = { 14, 46 },
            name = {
                enUS = "Southshore",
                zhCN = "南海镇",
            },
        },
        auberdine = {
            kind = "dock",
            area = 442,
            map = 1439,
            berths = {
                menethil = {
                    x = 32.4,
                    y = 43.8,
                },
                rutheran = {
                    x = 33.2,
                    y = 40.1,
                },
                stormwind = {
                    x = 30.7,
                    y = 41.0,
                },
            },
            taxiNodes = { 26 },
            name = {
                enUS = "Auberdine",
                zhCN = "奥伯丁",
            },
        },
        rutheran = {
            kind = "dock",
            area = 702,
            map = 1438,
            x = 54.9,
            y = 96.8,
            taxiNodes = { 27 },
            name = {
                enUS = "Rut'theran Village",
                zhCN = "鲁瑟兰村",
            },
        },
        theramore = {
            kind = "dock",
            area = 513,
            map = 1445,
            x = 71.6,
            y = 56.5,
            taxiNodes = { 32 },
            name = {
                enUS = "Theramore Isle",
                zhCN = "塞拉摩岛",
            },
        },
        stormwind = {
            kind = "dock",
            area = 1519,
            map = 1453,
            x = 22.4,
            y = 56.2,
            taxiNodes = { 2 },
            name = {
                enUS = "Stormwind City",
                zhCN = "暴风城",
            },
        },
    },
    routes = {
        {
            id = "Z1",
            kind = "zeppelin",
            stops = { "orgrimmar", "undercity" },
            faction = "H",
        },
        {
            id = "Z2",
            kind = "zeppelin",
            stops = { "orgrimmar", "gromgol" },
            faction = "H",
        },
        {
            id = "Z3",
            kind = "zeppelin",
            stops = { "undercity", "gromgol" },
            faction = "H",
        },
        {
            id = "B1",
            kind = "boat",
            stops = { "ratchet", "bootybay" },
        },
        {
            id = "B3",
            kind = "boat",
            stops = { "menethil", "theramore" },
            faction = "A",
        },
        {
            id = "B4",
            kind = "boat",
            stops = { "auberdine", "rutheran" },
            faction = "A",
        },
        {
            id = "L1",
            kind = "boat",
            stops = { "menethil", "southshore", "auberdine" },
            loop = true,
            faction = "A",
        },
        {
            id = "B6",
            kind = "boat",
            stops = { "auberdine", "stormwind" },
            faction = "A",
        },
    },
}
