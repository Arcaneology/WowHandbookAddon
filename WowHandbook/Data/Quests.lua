-- 自动生成，请勿手工编辑。生成脚本：tools/export_site_data.py
-- 来源：wowhandbook src/data/generated（客户端 1.60.1.69913）
local ADDON_NAME, ns = ...
ns.Data = ns.Data or {}
ns.Data.quests = {
    [6564] = {
        name = {
            enUS = "Allegiance to the Old Gods",
            zhCN = "上古之神的仆从",
        },
        level = 22,
        min = 17,
        faction = "H",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "item",
            id = 16790,
            name = {
                enUS = "Damp Note",
                zhCN = "潮湿的便笺",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        after = { 6565 },
        summary = {
            enUS = "Bring the Damp Note to Je'neu Sancrea in Ashenvale.",
            zhCN = "把潮湿的便笺交给灰谷的耶努萨克雷。",
        },
        objectives = {
            enUS = { "Damp Note" },
            zhCN = { "潮湿的便笺" },
        },
        rewards = {
            xp = 1300,
            money = 1100,
            reputation = {
                {
                    name = {
                        enUS = "Darkspear Trolls",
                        zhCN = "暗矛巨魔",
                    },
                    value = 75,
                },
            },
        },
    },
    [6563] = {
        name = {
            enUS = "The Essence of Aku'Mai",
            zhCN = "阿库麦尔水晶",
        },
        level = 22,
        min = 17,
        faction = "H",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        finish = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        before = { 6562 },
        summary = {
            enUS = "Bring 20 Sapphires of Aku'Mai to Je'neu Sancrea in Ashenvale.",
            zhCN = "收集20颗阿库麦尔蓝宝石，把它们交给灰谷的耶努萨克雷。",
        },
        objectives = {
            enUS = { "Sapphire of Aku'Mai ×20" },
            zhCN = { "阿库麦尔蓝宝石 ×20" },
        },
        rewards = {
            xp = 1750,
            money = 1400,
            reputation = {
                {
                    name = {
                        enUS = "Darkspear Trolls",
                        zhCN = "暗矛巨魔",
                    },
                    value = 100,
                },
                {
                    name = {
                        enUS = "Earthen Ring",
                        zhCN = "大地之环",
                    },
                    value = 150,
                },
            },
        },
    },
    [6562] = {
        name = {
            enUS = "Trouble in the Deeps",
            zhCN = "帮助耶努萨克雷",
        },
        level = 22,
        min = 17,
        faction = "H",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            name = {
                enUS = "Tsunaman",
                zhCN = "苏纳曼",
            },
            map = 1442,
            x = 47.2,
            y = 64.2,
            unverified = true,
        },
        finish = {
            kind = "npc",
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
        },
        after = { 6563 },
        summary = {
            enUS = "Speak to Je'neu Sancrea in Ashenvale.",
            zhCN = "与灰谷的耶努萨克雷谈一谈。",
        },
        rewards = {
            xp = 440,
            reputation = {
                {
                    name = {
                        enUS = "Darkspear Trolls",
                        zhCN = "暗矛巨魔",
                    },
                    value = 25,
                },
                {
                    name = {
                        enUS = "Earthen Ring",
                        zhCN = "大地之环",
                    },
                    value = 100,
                },
            },
        },
    },
    [971] = {
        name = {
            enUS = "Knowledge in the Deeps",
            zhCN = "深渊中的知识",
        },
        level = 23,
        min = 10,
        faction = "A",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 2786,
            name = {
                enUS = "Gerrig Bonegrip",
                zhCN = "葛利·硬骨",
            },
            map = 1455,
            x = 50.83,
            y = 5.62,
        },
        finish = {
            kind = "npc",
            id = 2786,
            name = {
                enUS = "Gerrig Bonegrip",
                zhCN = "葛利·硬骨",
            },
            map = 1455,
            x = 50.83,
            y = 5.62,
        },
        summary = {
            enUS = "Bring the Lorgalis Manuscript to Gerrig Bonegrip in the Forlorn Cavern in Ironforge.",
            zhCN = "把洛迦里斯手稿带给铁炉堡的葛利·硬骨。",
        },
        objectives = {
            enUS = { "Lorgalis Manuscript" },
            zhCN = { "洛迦里斯手稿" },
        },
        rewards = {
            xp = 10300,
            items = {
                {
                    id = 6743,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Ironforge",
                        zhCN = "铁炉堡",
                    },
                    value = 50,
                },
            },
        },
    },
    [1198] = {
        name = {
            enUS = "In Search of Thaelrid",
            zhCN = "寻找塞尔瑞德",
        },
        level = 24,
        min = 18,
        faction = "A",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 4786,
            name = {
                enUS = "Dawnwatcher Shaedlass",
                zhCN = "哨兵山德拉斯",
            },
            map = 1457,
            x = 55.36,
            y = 25.03,
        },
        finish = {
            kind = "npc",
            id = 4787,
            name = {
                enUS = "Argent Guard Thaelrid",
                zhCN = "银月守卫塞尔瑞德",
            },
        },
        after = { 1200 },
        summary = {
            enUS = "Seek out Argent Guard Thaelrid in Blackfathom Deeps.",
            zhCN = "到黑色深渊去找到银月守卫塞尔瑞德。",
        },
        rewards = {
            xp = 9000,
            reputation = {
                {
                    name = {
                        enUS = "Argent Dawn",
                        zhCN = "银色黎明",
                    },
                    value = 150,
                },
                {
                    name = {
                        enUS = "Darnassus",
                        zhCN = "达纳苏斯",
                    },
                    value = 150,
                },
            },
        },
    },
    [1275] = {
        name = {
            enUS = "Researching the Corruption",
            zhCN = "研究堕落",
        },
        level = 24,
        min = 18,
        faction = "A",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 8997,
            name = {
                enUS = "Gershala Nightwhisper",
                zhCN = "戈沙拉·夜语",
            },
            map = 1439,
            x = 38.33,
            y = 43.04,
        },
        finish = {
            kind = "npc",
            id = 8997,
            name = {
                enUS = "Gershala Nightwhisper",
                zhCN = "戈沙拉·夜语",
            },
            map = 1439,
            x = 38.33,
            y = 43.04,
        },
        before = { 3765 },
        summary = {
            enUS = "Gershala Nightwhisper in Auberdine wants 8 Corrupt Brain stems.",
            zhCN = "奥伯丁的戈沙拉·夜语需要8块堕落者的脑干。",
        },
        objectives = {
            enUS = { "Corrupted Brain Stem ×8" },
            zhCN = { "堕落者的脑干 ×8" },
        },
        rewards = {
            xp = 2400,
            money = 3500,
            choices = {
                {
                    id = 7003,
                    count = 1,
                },
                {
                    id = 7004,
                    count = 1,
                },
                {
                    id = 270021,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Darnassus",
                        zhCN = "达纳苏斯",
                    },
                    value = 150,
                },
            },
        },
    },
    [3765] = {
        name = {
            enUS = "The Corruption Abroad",
            zhCN = "遥远的旅途",
        },
        level = 24,
        min = 18,
        faction = "A",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 4984,
            name = {
                enUS = "Argos Nightwhisper",
                zhCN = "阿古斯·夜语",
            },
            map = 1453,
            x = 36.2,
            y = 67.6,
        },
        finish = {
            kind = "npc",
            id = 8997,
            name = {
                enUS = "Gershala Nightwhisper",
                zhCN = "戈沙拉·夜语",
            },
            map = 1439,
            x = 38.33,
            y = 43.04,
        },
        after = { 1275 },
        summary = {
            enUS = "Travel to Gershala Nightwhisper in Auberdine.",
            zhCN = "到奥伯丁的戈沙拉·夜语那儿去。",
        },
    },
    [1199] = {
        name = {
            enUS = "Twilight Falls",
            zhCN = "暮光之锤的末日",
        },
        level = 25,
        min = 20,
        faction = "A",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 4784,
            name = {
                enUS = "Argent Guard Manados",
                zhCN = "银月守卫玛纳杜斯",
            },
            map = 1457,
            x = 55.24,
            y = 23.99,
        },
        finish = {
            kind = "npc",
            id = 4784,
            name = {
                enUS = "Argent Guard Manados",
                zhCN = "银月守卫玛纳杜斯",
            },
            map = 1457,
            x = 55.24,
            y = 23.99,
        },
        summary = {
            enUS = "Bring 10 Twilight Pendants to Argent Guard Manados in Darnassus.",
            zhCN = "收集10个暮光坠饰，把它们交给达纳苏斯的银月守卫玛纳杜斯。",
        },
        objectives = {
            enUS = { "Twilight Pendant ×10" },
            zhCN = { "暮光坠饰 ×10" },
        },
        rewards = {
            xp = 9550,
            items = {
                {
                    id = 6998,
                    count = 1,
                },
                {
                    id = 7000,
                    count = 1,
                },
                {
                    id = 270025,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Argent Dawn",
                        zhCN = "银色黎明",
                    },
                    value = 150,
                },
                {
                    name = {
                        enUS = "Darnassus",
                        zhCN = "达纳苏斯",
                    },
                    value = 150,
                },
            },
        },
    },
    [6565] = {
        name = {
            enUS = "Allegiance to the Old Gods",
            zhCN = "上古之神的仆从",
        },
        level = 26,
        min = 17,
        faction = "H",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        finish = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        before = { 6564 },
        summary = {
            enUS = "Kill Lorgus Jett in Blackfathom Deeps and then return to Je'neu Sancrea in Ashenvale.",
            zhCN = "杀掉黑暗深渊里的洛古斯·杰特，然后向灰谷的耶努萨克雷复命。",
        },
        objectives = {
            enUS = { "Lorgus Jett" },
            zhCN = { "洛古斯·杰特" },
        },
        rewards = {
            xp = 9950,
            money = 4000,
            choices = {
                {
                    id = 17694,
                    count = 1,
                },
                {
                    id = 17695,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Darkspear Trolls",
                        zhCN = "暗矛巨魔",
                    },
                    value = 150,
                },
                {
                    name = {
                        enUS = "Earthen Ring",
                        zhCN = "大地之环",
                    },
                    value = 150,
                },
            },
        },
    },
    [6921] = {
        name = {
            enUS = "Amongst the Ruins",
            zhCN = "废墟之间",
        },
        level = 27,
        min = 21,
        faction = "H",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        finish = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        summary = {
            enUS = "Bring the Fathom Core to Je'neu Sancrea at Zoram'gar Outpost, Ashenvale.",
            zhCN = "把深渊之核交给灰谷佐拉姆加前哨站里的耶努萨克雷。",
        },
        rewards = {
            xp = 10313,
            money = 4500,
        },
    },
    [1200] = {
        name = {
            enUS = "Blackfathom Villainy",
            zhCN = "黑暗深渊中的恶魔",
        },
        level = 27,
        min = 18,
        faction = "A",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 4787,
            name = {
                enUS = "Argent Guard Thaelrid",
                zhCN = "银月守卫塞尔瑞德",
            },
            map = 719,
            x = 20.1,
            y = 52.3,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 4783,
            name = {
                enUS = "Dawnwatcher Selgorm",
                zhCN = "哨兵塞尔高姆",
            },
            map = 1457,
            x = 56.16,
            y = 24.39,
        },
        before = { 1198 },
        summary = {
            enUS = "Bring the head of Twilight Lord Kelris to Dawnwatcher Selgorm in Darnassus.",
            zhCN = "把梦游者克尔里斯的头颅交给达纳苏斯的哨兵塞尔高姆。",
        },
        objectives = {
            enUS = { "Head of Kelris" },
            zhCN = { "克尔里斯的头颅" },
        },
        rewards = {
            xp = 12400,
            money = 6500,
            choices = {
                {
                    id = 7001,
                    count = 1,
                },
                {
                    id = 7002,
                    count = 1,
                },
                {
                    id = 270031,
                    count = 1,
                },
                {
                    id = 270032,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Argent Dawn",
                        zhCN = "银色黎明",
                    },
                    value = 200,
                },
                {
                    name = {
                        enUS = "Darnassus",
                        zhCN = "达纳苏斯",
                    },
                    value = 200,
                },
            },
        },
    },
    [6561] = {
        name = {
            enUS = "Blackfathom Villainy",
            zhCN = "黑暗深渊中的邪恶",
        },
        level = 27,
        min = 18,
        faction = "H",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 4787,
            name = {
                enUS = "Argent Guard Thaelrid",
                zhCN = "银月守卫塞尔瑞德",
            },
            map = 719,
            x = 20.1,
            y = 52.3,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 9087,
            name = {
                enUS = "Bashana Runetotem",
                zhCN = "巴珊娜·符文图腾",
            },
            map = 1456,
            x = 71.06,
            y = 34.19,
        },
        summary = {
            enUS = "Bring the head of Twilight Lord Kelris to Bashana Runetotem in Thunder Bluff.",
            zhCN = "把梦游者克尔里斯的头颅交给雷霆崖的巴珊娜·符文图腾。",
        },
        objectives = {
            enUS = { "Head of Kelris" },
            zhCN = { "克尔里斯的头颅" },
        },
        rewards = {
            xp = 12400,
            money = 6500,
            choices = {
                {
                    id = 7001,
                    count = 1,
                },
                {
                    id = 7002,
                    count = 1,
                },
                {
                    id = 270031,
                    count = 1,
                },
                {
                    id = 270032,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Argent Dawn",
                        zhCN = "银色黎明",
                    },
                    value = 200,
                },
                {
                    name = {
                        enUS = "Thunder Bluff",
                        zhCN = "雷霆崖",
                    },
                    value = 200,
                },
            },
        },
    },
    [6922] = {
        name = {
            enUS = "Baron Aquanis",
            zhCN = "阿奎尼斯男爵",
        },
        level = 30,
        min = 21,
        faction = "H",
        instances = { "blackfathom-deeps" },
        start = {
            kind = "item",
            id = 16782,
            name = {
                enUS = "Strange Water Globe",
                zhCN = "奇怪的水球",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 12736,
            name = {
                enUS = "Je'neu Sancrea",
                zhCN = "耶努萨克雷",
            },
            map = 1440,
            x = 11.56,
            y = 34.29,
        },
        summary = {
            enUS = "Bring the Strange Water Globe to Je'neu Sancrea at Zoram'gar Outpost, Ashenvale.",
            zhCN = "把奇怪的水球交给灰谷佐拉姆加前哨站的耶努萨克雷。",
        },
    },
    [3981] = {
        name = {
            enUS = "Commander Gor'shak",
            zhCN = "指挥官哥沙克",
        },
        level = 52,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9081,
            name = {
                enUS = "Galamav the Marksman",
                zhCN = "神射手贾拉玛弗",
            },
            map = 1418,
            x = 5.96,
            y = 47.73,
        },
        finish = {
            kind = "npc",
            id = 9020,
            name = {
                enUS = "Commander Gor'shak",
                zhCN = "指挥官哥沙克",
            },
        },
        before = { 3906 },
        after = { 3982, 4002, 4003, 4001 },
        summary = {
            enUS = "Find Commander Gor'shak in Blackrock Depths. You recall that the crudely drawn picture of the orc included bars drawn over the portrait....",
            zhCN = "在黑石深渊里找到指挥官哥沙克。 在那幅草图上画着的是一个铁栏后面的兽人，也许你应该到某个类似监狱的地方去找找看。",
        },
    },
    [3801] = {
        name = {
            enUS = "Dark Iron Legacy (3801)",
            zhCN = "黑铁的遗产",
        },
        level = 52,
        min = 48,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 8888,
            name = {
                enUS = "Franclorn Forgewright",
                zhCN = "弗兰克罗恩·铸铁",
            },
        },
        finish = {
            kind = "npc",
            id = 8888,
            name = {
                enUS = "Franclorn Forgewright",
                zhCN = "弗兰克罗恩·铸铁",
            },
        },
        summary = {
            enUS = "Speak with Franclorn Forgewright if you are interested in obtaining a key to the city major.",
            zhCN = "如果你想要得到进入这座城市主城区的钥匙，就去和弗兰克罗恩·铸铁谈一谈。",
        },
    },
    [3802] = {
        name = {
            enUS = "Dark Iron Legacy (3802)",
            zhCN = "黑铁的遗产",
        },
        level = 52,
        min = 48,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 8888,
            name = {
                enUS = "Franclorn Forgewright",
                zhCN = "弗兰克罗恩·铸铁",
            },
            map = 1415,
            x = 48.6,
            y = 64.2,
            unverified = true,
        },
        finish = {
            kind = "object",
            id = 164689,
            name = {
                enUS = "Monument of Franclorn Forgewright",
                zhCN = "弗兰克罗恩·铸铁的雕像",
            },
        },
        summary = {
            enUS = "Slay Fineous Darkvire and recover the great hammer, Ironfel. Take Ironfel to the Shrine of Thaurissan and place it on the statue of...",
            zhCN = "杀掉弗诺斯·达克维尔并拿回战锤铁胆。把铁胆之锤拿到索瑞森神殿去，将其放在弗兰克罗恩·铸铁的雕像上。",
        },
        rewards = {
            xp = 5100,
            money = 23000,
            referenceItems = {
                {
                    id = 11000,
                },
            },
        },
    },
    [3906] = {
        name = {
            enUS = "Disharmony of Flame",
            zhCN = "不和谐的烈焰",
        },
        level = 52,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9084,
            name = {
                enUS = "Thunderheart",
                zhCN = "桑德哈特",
            },
            map = 1418,
            x = 3.33,
            y = 48.26,
        },
        finish = {
            kind = "npc",
            id = 9084,
            name = {
                enUS = "Thunderheart",
                zhCN = "桑德哈特",
            },
            map = 1418,
            x = 3.33,
            y = 48.26,
        },
        after = { 3907, 3981, 7201, 3982, 4001, 4003 },
        summary = {
            enUS = "Travel to the quarry in Blackrock Mountain and slay Overmaster Pyron. Return to Thunderheart when you have completed this assignment.",
            zhCN = "到黑石山脉的采石场去干掉征服者派隆，然后向桑德哈特回报。",
        },
    },
    [4081] = {
        name = {
            enUS = "KILL ON SIGHT: Dark Iron Dwarves",
            zhCN = "格杀勿论：黑铁矮人",
        },
        level = 52,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "object",
            id = 164867,
            name = {
                enUS = "WANTED",
                zhCN = "通缉",
            },
            map = 1418,
            x = 3.74,
            y = 47.43,
        },
        finish = {
            kind = "npc",
            id = 9077,
            name = {
                enUS = "Warlord Goretooth",
                zhCN = "军官高图斯",
            },
            map = 1418,
            x = 5.81,
            y = 47.52,
        },
        after = { 4082 },
        summary = {
            enUS = "Venture to Blackrock Depths and destroy the vile aggressors! Warlord Goretooth wants you to kill 15 Anvilrage Guardsmen, 10...",
            zhCN = "到黑石深渊去消灭那些邪恶的侵略者！ 军官高图斯要你去杀死15个铁怒卫士、10个铁怒狱卒和5个铁怒步兵。完成任务之后回去向他复命。",
        },
        rewards = {
            xp = 5100,
            money = 15500,
        },
    },
    [4262] = {
        name = {
            enUS = "Overmaster Pyron",
            zhCN = "征服者派隆",
        },
        level = 52,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9561,
            name = {
                enUS = "Jalinda Sprig",
                zhCN = "加琳达",
            },
            map = 1428,
            x = 85.41,
            y = 70.06,
        },
        finish = {
            kind = "npc",
            id = 9561,
            name = {
                enUS = "Jalinda Sprig",
                zhCN = "加琳达",
            },
            map = 1428,
            x = 85.41,
            y = 70.06,
        },
        after = { 4263 },
        summary = {
            enUS = "Slay Overmaster Pyron and return to Jalinda Sprig. You recall Jalinda talking about Pyron guarding the quarry. Perhaps you should search there?",
            zhCN = "杀掉征服者派隆，然后向加琳达复命。 加琳达告诉过你，派隆守在采矿场中，也许你应该去那里找找。",
        },
    },
    [4136] = {
        name = {
            enUS = "Ribbly Screwspigot",
            zhCN = "雷布里·斯库比格特",
        },
        level = 53,
        min = 48,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9544,
            name = {
                enUS = "Yuka Screwspigot",
                zhCN = "尤卡·斯库比格特",
            },
            map = 1428,
            x = 66.06,
            y = 21.95,
        },
        finish = {
            kind = "npc",
            id = 9544,
            name = {
                enUS = "Yuka Screwspigot",
                zhCN = "尤卡·斯库比格特",
            },
            map = 1428,
            x = 66.06,
            y = 21.95,
        },
        before = { 4324 },
        summary = {
            enUS = "Bring Ribbly's Head to Yuka Screwspigot in the Burning Steppes.",
            zhCN = "把雷布里的头颅交给燃烧平原的尤卡·斯库比格特。",
        },
        rewards = {
            xp = 2650,
            money = 6000,
            referenceItems = {
                {
                    id = 11865,
                },
                {
                    id = 11963,
                },
                {
                    id = 12049,
                },
            },
        },
    },
    [4324] = {
        name = {
            enUS = "Yuka Screwspigot",
            zhCN = "尤卡·斯库比格特",
        },
        level = 53,
        min = 48,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9706,
            name = {
                enUS = "Yorba Screwspigot",
                zhCN = "尤尔巴·斯库比格特",
            },
            map = 1446,
            x = 67.04,
            y = 24.01,
        },
        finish = {
            kind = "npc",
            id = 9544,
            name = {
                enUS = "Yuka Screwspigot",
                zhCN = "尤卡·斯库比格特",
            },
            map = 1428,
            x = 66.06,
            y = 21.95,
        },
        after = { 4136 },
        summary = {
            enUS = "Speak with Yuka Screwspigot in the Burning Steppes.",
            zhCN = "与燃烧平原的尤卡·斯库比格特谈一谈。",
        },
    },
    [4022] = {
        name = {
            enUS = "A Taste of Flame (4022)",
            zhCN = "烈焰精华",
        },
        level = 54,
        min = 52,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9459,
            name = {
                enUS = "Cyrus Therepentous",
                zhCN = "塞勒斯·萨雷芬图斯",
            },
            map = 1428,
            x = 95.09,
            y = 31.56,
        },
        finish = {
            kind = "npc",
            id = 9459,
            name = {
                enUS = "Cyrus Therepentous",
                zhCN = "塞勒斯·萨雷芬图斯",
            },
            map = 1428,
            x = 95.09,
            y = 31.56,
        },
        summary = {
            enUS = "Show Cyrus Therepentous the Black Dragonflight Molt you received from Kalaran Windblade.",
            zhCN = "向塞勒斯·萨雷芬图斯展示你从卡拉然·温布雷那里得到的黑龙皮。",
        },
    },
    [4023] = {
        name = {
            enUS = "A Taste of Flame (4023)",
            zhCN = "烈焰精华",
        },
        level = 54,
        min = 52,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9459,
            name = {
                enUS = "Cyrus Therepentous",
                zhCN = "塞勒斯·萨雷芬图斯",
            },
            map = 1428,
            x = 95.09,
            y = 31.56,
        },
        finish = {
            kind = "npc",
            id = 9459,
            name = {
                enUS = "Cyrus Therepentous",
                zhCN = "塞勒斯·萨雷芬图斯",
            },
            map = 1428,
            x = 95.09,
            y = 31.56,
        },
        summary = {
            enUS = "Show Cyrus Therepentous proof of your worth. You have a feeling that Cyrus already knows that you are unworthy.",
            zhCN = "向塞勒斯·萨雷芬图斯证明你的价值。 你感觉到塞勒斯似乎对你不屑一顾。",
        },
    },
    [4182] = {
        name = {
            enUS = "Dragonkin Menace",
            zhCN = "黑龙的威胁",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9562,
            name = {
                enUS = "Helendis Riverhorn",
                zhCN = "赫林迪斯·河角",
            },
            map = 1428,
            x = 85.82,
            y = 68.95,
        },
        finish = {
            kind = "npc",
            id = 9562,
            name = {
                enUS = "Helendis Riverhorn",
                zhCN = "赫林迪斯·河角",
            },
            map = 1428,
            x = 85.82,
            y = 68.95,
        },
        after = { 4241 },
        summary = {
            enUS = "Slay 15 Black Broodlings, 10 Black Dragonspawn, 4 Black Wyrmkin and 1 Black Drake. Return to Helendis Riverhorn when the task is complete.",
            zhCN = "杀掉15条黑色小龙、10条黑色龙人和1条黑色幼龙。当你完成任务之后就向赫林迪斯·河角回报。",
        },
    },
    [4082] = {
        name = {
            enUS = "KILL ON SIGHT: High Ranking Dark Iron Officials",
            zhCN = "格杀勿论：高阶黑铁军官",
        },
        level = 54,
        min = 50,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "object",
            id = 164868,
            name = {
                enUS = "KILL ON SIGHT",
                zhCN = "格杀勿论",
            },
            map = 1418,
            x = 3.94,
            y = 46.73,
        },
        finish = {
            kind = "npc",
            id = 9077,
            name = {
                enUS = "Warlord Goretooth",
                zhCN = "军官高图斯",
            },
            map = 1418,
            x = 5.81,
            y = 47.52,
        },
        before = { 4081 },
        summary = {
            enUS = "Venture to Blackrock Depths and destroy the vile aggressors! Warlord Goretooth wants you to kill 10 Anvilrage...",
            zhCN = "到黑石深渊去消灭那些邪恶的侵略者！ 高图斯军阀要你杀死10个铁怒医师,、10个铁怒士兵和10个铁怒军官。完成任务之后回去向他复命。",
        },
        rewards = {
            xp = 5450,
            money = 16500,
        },
    },
    [4241] = {
        name = {
            enUS = "Marshal Windsor",
            zhCN = "温德索尔元帅",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        finish = {
            kind = "npc",
            id = 9023,
            name = {
                enUS = "Marshal Windsor",
                zhCN = "温德索尔元帅",
            },
        },
        before = { 4182, 4183, 4184, 4185, 4223, 4224 },
        after = { 4242, 4264, 4282, 4322 },
        summary = {
            enUS = "Travel to Blackrock Mountain in the northwest and enter Blackrock Depths. Find out what became of Marshal Windsor. You recall Ragged John...",
            zhCN = "到西北部的黑石山脉去，在黑石深渊中找到温德索尔元帅的下落。 狼狈不堪的约翰曾告诉你说温德索尔被关进了一个监狱。",
        },
    },
    [7201] = {
        name = {
            enUS = "The Last Element",
            zhCN = "最后的元素",
        },
        level = 54,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9078,
            name = {
                enUS = "Shadowmage Vivian Lagrave",
                zhCN = "暗法师薇薇安·拉格雷",
            },
            map = 1418,
            x = 2.9,
            y = 47.76,
        },
        finish = {
            kind = "npc",
            id = 9078,
            name = {
                enUS = "Shadowmage Vivian Lagrave",
                zhCN = "暗法师薇薇安·拉格雷",
            },
            map = 1418,
            x = 2.9,
            y = 47.76,
        },
        before = { 3906 },
        summary = {
            enUS = "Travel to Blackrock Depths and recover 10 Essence of the Elements. Your first inclination is to search the golems and golem makers. You...",
            zhCN = "到黑石深渊去取得10份元素精华。你应该在那些作战傀儡和傀儡制造者身上找找，另外，薇薇安·拉格雷也提到了一些有关元素生物的话题……",
        },
        rewards = {
            xp = 5450,
            money = 24500,
            referenceItems = {
                {
                    id = 12038,
                },
            },
        },
    },
    [4201] = {
        name = {
            enUS = "The Love Potion",
            zhCN = "爱情药水",
        },
        level = 54,
        min = 50,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9500,
            name = {
                enUS = "Mistress Nagmara",
                zhCN = "娜玛拉小姐",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 9500,
            name = {
                enUS = "Mistress Nagmara",
                zhCN = "娜玛拉小姐",
            },
        },
        summary = {
            enUS = "Bring 4 Gromsblood, 10 Giant Silver Veins and Nagmara's Filled Vial to Mistress Nagmara in Blackrock Depths.",
            zhCN = "将4份格罗姆之血、10块巨型银矿和装满水的娜玛拉之瓶交给黑石深渊的娜玛拉小姐。",
        },
        rewards = {
            xp = 5450,
            money = 8000,
            referenceItems = {
                {
                    id = 11962,
                },
                {
                    id = 11866,
                },
            },
        },
    },
    [4061] = {
        name = {
            enUS = "The Rise of the Machines (4061)",
            zhCN = "机器的崛起",
        },
        level = 54,
        min = 52,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9079,
            name = {
                enUS = "Hierophant Theodora Mulvadania",
                zhCN = "塞朵拉·穆瓦丹尼",
            },
            map = 1418,
            x = 3.02,
            y = 47.81,
        },
        finish = {
            kind = "npc",
            id = 9079,
            name = {
                enUS = "Hierophant Theodora Mulvadania",
                zhCN = "塞朵拉·穆瓦丹尼",
            },
            map = 1418,
            x = 3.02,
            y = 47.81,
        },
        after = { 4063 },
        summary = {
            enUS = "Venture to the Burning Steppes and recover 10 Fractured Elemental Shards for Hierophant Theodora Mulvadania. You recall Theodora...",
            zhCN = "到燃烧平原去为塞朵拉·穆瓦丹尼收集10块断裂的元素碎片。 塞朵拉曾经说过，那里的机械傀儡和元素生物是这种碎片的主要来源。",
        },
    },
    [4062] = {
        name = {
            enUS = "The Rise of the Machines (4062)",
            zhCN = "机器的崛起",
        },
        level = 54,
        min = 52,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9079,
            name = {
                enUS = "Hierophant Theodora Mulvadania",
                zhCN = "塞朵拉·穆瓦丹尼",
            },
            map = 1418,
            x = 3.02,
            y = 47.81,
        },
        finish = {
            kind = "npc",
            id = 2921,
            name = {
                enUS = "Lotwil Veriatus",
                zhCN = "鲁特维尔·沃拉图斯",
            },
            map = 1418,
            x = 25.95,
            y = 44.87,
        },
        summary = {
            enUS = "Take the Elemental Shard Sample to Lotwil Veriatus. You recall Theodora saying that Lotwil was stationed in a camp to the east.",
            zhCN = "将元素碎片样本交给鲁特维尔·沃拉图斯。 塞朵拉说鲁特维尔就在东边的一处营地里。",
        },
    },
    [3701] = {
        name = {
            enUS = "The Smoldering Ruins of Thaurissan (3701)",
            zhCN = "索瑞森废墟",
        },
        level = 54,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 8879,
            name = {
                enUS = "Royal Historian Archesonus",
                zhCN = "皇家历史学家阿克瑟努斯",
            },
            map = 1455,
            x = 38.37,
            y = 55.31,
        },
        finish = {
            kind = "npc",
            id = 8879,
            name = {
                enUS = "Royal Historian Archesonus",
                zhCN = "皇家历史学家阿克瑟努斯",
            },
            map = 1455,
            x = 38.37,
            y = 55.31,
        },
        summary = {
            enUS = "Venture to the Ruins of Thaurissan in the Burning Steppes and recover information from the Thaurissan Relics. Return...",
            zhCN = "到燃烧平原的索瑞森废墟中去，从索瑞森遗物上搜集信息。当你收集到足够的信息之后，就回到皇家历史学家阿克瑟努斯那里。",
        },
    },
    [3702] = {
        name = {
            enUS = "The Smoldering Ruins of Thaurissan (3702)",
            zhCN = "索瑞森废墟",
        },
        level = 54,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 8879,
            name = {
                enUS = "Royal Historian Archesonus",
                zhCN = "皇家历史学家阿克瑟努斯",
            },
            map = 1455,
            x = 38.37,
            y = 55.31,
        },
        finish = {
            kind = "npc",
            id = 8879,
            name = {
                enUS = "Royal Historian Archesonus",
                zhCN = "皇家历史学家阿克瑟努斯",
            },
            map = 1455,
            x = 38.37,
            y = 55.31,
        },
        after = { 4341, 4361, 4362 },
        summary = {
            enUS = "Listen to Royal Historian Archesonus recant the history of Thaurissan.",
            zhCN = "听皇家历史学家阿克瑟努斯讲述索瑞森的历史。",
        },
    },
    [4183] = {
        name = {
            enUS = "The True Masters (4183)",
            zhCN = "真正的主人",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9562,
            name = {
                enUS = "Helendis Riverhorn",
                zhCN = "赫林迪斯·河角",
            },
            map = 1428,
            x = 85.82,
            y = 68.95,
        },
        finish = {
            kind = "npc",
            id = 344,
            name = {
                enUS = "Magistrate Solomon",
                zhCN = "所罗门镇长",
            },
            map = 1433,
            x = 24.9,
            y = 44.3,
        },
        after = { 4241 },
        summary = {
            enUS = "Travel to Lakeshire and deliver Helendis Riverhorn's Letter to Magistrate Solomon.",
            zhCN = "把赫林迪斯·河角的信交给湖畔镇的所罗门镇长。",
        },
    },
    [4184] = {
        name = {
            enUS = "The True Masters (4184)",
            zhCN = "真正的主人",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 344,
            name = {
                enUS = "Magistrate Solomon",
                zhCN = "所罗门镇长",
            },
            map = 1433,
            x = 24.9,
            y = 44.3,
        },
        finish = {
            kind = "npc",
            id = 1748,
            name = {
                enUS = "Highlord Bolvar Fordragon",
                zhCN = "伯瓦尔·弗塔根公爵",
            },
            map = 1453,
            x = 79.6,
            y = 38.3,
        },
        after = { 4241 },
        summary = {
            enUS = "Travel to Stormwind and deliver Solomon's Plea to Highlord Bolvar Fordragon. Bolvar resides in Stormwind Keep.",
            zhCN = "到暴风城去把所罗门的求援信交给伯瓦尔·弗塔根公爵。 伯瓦尔在暴风要塞里。",
        },
    },
    [4185] = {
        name = {
            enUS = "The True Masters (4185)",
            zhCN = "真正的主人",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 1748,
            name = {
                enUS = "Highlord Bolvar Fordragon",
                zhCN = "伯瓦尔·弗塔根公爵",
            },
            map = 1453,
            x = 79.6,
            y = 38.3,
        },
        finish = {
            kind = "npc",
            id = 1748,
            name = {
                enUS = "Highlord Bolvar Fordragon",
                zhCN = "伯瓦尔·弗塔根公爵",
            },
            map = 1453,
            x = 79.6,
            y = 38.3,
        },
        after = { 4241 },
        summary = {
            enUS = "Speak with Highlord Bolvar Fordragon after speaking with Lady Katrana Prestor.",
            zhCN = "与女伯爵卡特拉娜·普瑞斯托谈话，然后再与伯瓦尔·弗塔根公爵谈话。",
        },
    },
    [4186] = {
        name = {
            enUS = "The True Masters (4186)",
            zhCN = "真正的主人",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 1748,
            name = {
                enUS = "Highlord Bolvar Fordragon",
                zhCN = "伯瓦尔·弗塔根公爵",
            },
            map = 1453,
            x = 79.6,
            y = 38.3,
        },
        finish = {
            kind = "npc",
            id = 344,
            name = {
                enUS = "Magistrate Solomon",
                zhCN = "所罗门镇长",
            },
            map = 1433,
            x = 24.9,
            y = 44.3,
        },
        summary = {
            enUS = "Take Bolvar's Decree to Magistrate Solomon in Lakeshire.",
            zhCN = "把伯瓦尔的命令交给湖畔镇的所罗门镇长。",
        },
    },
    [4223] = {
        name = {
            enUS = "The True Masters (4223)",
            zhCN = "真正的主人",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 344,
            name = {
                enUS = "Magistrate Solomon",
                zhCN = "所罗门镇长",
            },
            map = 1433,
            x = 24.9,
            y = 44.3,
        },
        finish = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        after = { 4241 },
        summary = {
            enUS = "Speak with Marshal Maxwell in the Burning Steppes.",
            zhCN = "和燃烧平原的麦克斯韦尔元帅谈一谈。",
        },
    },
    [4224] = {
        name = {
            enUS = "The True Masters (4224)",
            zhCN = "真正的主人",
        },
        level = 54,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        finish = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        after = { 4241 },
        summary = {
            enUS = "Speak with Ragged John to learn of Marshal Windsor's fate and return to Marshal Maxwell when you have completed this task. You recall...",
            zhCN = "和狼狈不堪的约翰谈谈来了解温德索尔元帅的命运，然后回到麦克斯韦尔元帅那里。 你想起麦克斯韦尔元帅说过他在一个北面的洞穴那里。",
        },
    },
    [3982] = {
        name = {
            enUS = "What Is Going On? (3982)",
            zhCN = "出了什么事？",
        },
        level = 54,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9020,
            name = {
                enUS = "Commander Gor'shak",
                zhCN = "指挥官哥沙克",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 9020,
            name = {
                enUS = "Commander Gor'shak",
                zhCN = "指挥官哥沙克",
            },
        },
        before = { 3906, 3981 },
        after = { 4002, 4003, 4004 },
        summary = {
            enUS = "Defend Gor'shak.",
            zhCN = "保护哥沙克。",
        },
    },
    [4001] = {
        name = {
            enUS = "What Is Going On? (4001)",
            zhCN = "出了什么事？",
        },
        level = 54,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9020,
            name = {
                enUS = "Commander Gor'shak",
                zhCN = "指挥官哥沙克",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        before = { 3906, 3981 },
        after = { 4002, 4003, 4004 },
        summary = {
            enUS = "Speak with Kharan Mighthammer and gather information about Princess Moira Bronzebeard's kidnapping. Take that information to Thrall in...",
            zhCN = "与卡兰·巨锤谈一谈，收集关于绑架公主铁炉堡公主茉艾拉·铜须这一事件的情报。将情报反馈给奥格瑞玛城里的萨尔。 哥沙克提到过卡兰被关在附近的某个牢房中。",
        },
    },
    [4126] = {
        name = {
            enUS = "Hurley Blackbreath",
            zhCN = "霍尔雷·黑须",
        },
        level = 55,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 1267,
            name = {
                enUS = "Ragnar Thunderbrew",
                zhCN = "拉格纳·雷酒",
            },
            map = 1426,
            x = 46.83,
            y = 52.36,
        },
        finish = {
            kind = "npc",
            id = 1267,
            name = {
                enUS = "Ragnar Thunderbrew",
                zhCN = "拉格纳·雷酒",
            },
            map = 1426,
            x = 46.83,
            y = 52.36,
        },
        before = { 4128 },
        summary = {
            enUS = "Bring the Lost Thunderbrew Recipe to Ragnar Thunderbrew in Kharanos.",
            zhCN = "把遗失的雷酒秘方带给卡拉诺斯的拉格纳·雷酒。",
        },
        rewards = {
            xp = 7050,
            money = 16500,
            referenceItems = {
                {
                    id = 11964,
                },
                {
                    id = 12000,
                },
                {
                    id = 12003,
                },
            },
        },
    },
    [4134] = {
        name = {
            enUS = "Lost Thunderbrew Recipe",
            zhCN = "遗失的雷酒秘方",
        },
        level = 55,
        min = 50,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9078,
            name = {
                enUS = "Shadowmage Vivian Lagrave",
                zhCN = "暗法师薇薇安·拉格雷",
            },
            map = 1418,
            x = 2.9,
            y = 47.76,
        },
        finish = {
            kind = "npc",
            id = 9078,
            name = {
                enUS = "Shadowmage Vivian Lagrave",
                zhCN = "暗法师薇薇安·拉格雷",
            },
            map = 1418,
            x = 2.9,
            y = 47.76,
        },
        before = { 4133 },
        summary = {
            enUS = "Bring the Lost Thunderbrew Recipe to Vivian Lagrave in Kargath.",
            zhCN = "把遗失的雷酒秘方交给卡加斯的薇薇安·拉格雷。",
        },
        rewards = {
            xp = 5650,
            money = 8500,
            referenceItems = {
                {
                    id = 11964,
                },
                {
                    id = 12000,
                },
                {
                    id = 3928,
                },
                {
                    id = 6149,
                },
            },
        },
    },
    [4128] = {
        name = {
            enUS = "Ragnar Thunderbrew",
            zhCN = "拉格纳·雷酒",
        },
        level = 55,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9540,
            name = {
                enUS = "Enohar Thunderbrew",
                zhCN = "恩诺哈尔·雷酒",
            },
            map = 1419,
            x = 63.63,
            y = 20.63,
        },
        finish = {
            kind = "npc",
            id = 1267,
            name = {
                enUS = "Ragnar Thunderbrew",
                zhCN = "拉格纳·雷酒",
            },
            map = 1426,
            x = 46.83,
            y = 52.36,
        },
        after = { 4126 },
        summary = {
            enUS = "Speak with Ragnar Thunderbrew.",
            zhCN = "和拉格纳·雷酒谈一谈。",
        },
    },
    [4123] = {
        name = {
            enUS = "The Heart of the Mountain",
            zhCN = "山脉之心",
        },
        level = 55,
        min = 50,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9536,
            name = {
                enUS = "Maxwort Uberglint",
                zhCN = "麦克斯沃特·尤博格林",
            },
            map = 1428,
            x = 65.15,
            y = 23.91,
        },
        finish = {
            kind = "npc",
            id = 9536,
            name = {
                enUS = "Maxwort Uberglint",
                zhCN = "麦克斯沃特·尤博格林",
            },
            map = 1428,
            x = 65.15,
            y = 23.91,
        },
        summary = {
            enUS = "Bring the Heart of the Mountain to Maxwort Uberglint in the Burning Steppes.",
            zhCN = "把山脉之心交给燃烧平原的麦克斯沃特·尤博格林。",
        },
        rewards = {
            xp = 5650,
            money = 8500,
        },
    },
    [4133] = {
        name = {
            enUS = "Vivian Lagrave",
            zhCN = "薇薇安·拉格雷",
        },
        level = 55,
        min = 50,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 5204,
            name = {
                enUS = "Apothecary Zinge",
                zhCN = "药剂师金格",
            },
            map = 1458,
            x = 50.14,
            y = 67.97,
        },
        finish = {
            kind = "npc",
            id = 9078,
            name = {
                enUS = "Shadowmage Vivian Lagrave",
                zhCN = "暗法师薇薇安·拉格雷",
            },
            map = 1418,
            x = 2.9,
            y = 47.76,
        },
        after = { 4134 },
        summary = {
            enUS = "Speak with Shadowmaster Vivian Lagrave in Kargath.",
            zhCN = "与卡加斯的暗法师薇薇安·拉格雷谈一谈。",
        },
    },
    [3907] = {
        name = {
            enUS = "Disharmony of Fire",
            zhCN = "不和谐的火焰",
        },
        level = 56,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9084,
            name = {
                enUS = "Thunderheart",
                zhCN = "桑德哈特",
            },
            map = 1418,
            x = 3.33,
            y = 48.26,
        },
        finish = {
            kind = "npc",
            id = 9084,
            name = {
                enUS = "Thunderheart",
                zhCN = "桑德哈特",
            },
            map = 1418,
            x = 3.33,
            y = 48.26,
        },
        before = { 3906 },
        summary = {
            enUS = "Enter Blackrock Depths and track down Lord Incendius. Slay him and return any source of information you may find to Thunderheart.",
            zhCN = "进入黑石深渊并找到伊森迪奥斯。杀掉它，然后把你找到的信息汇报给桑德哈特。",
        },
        rewards = {
            xp = 7300,
            money = 25500,
            referenceItems = {
                {
                    id = 12113,
                },
                {
                    id = 12114,
                },
                {
                    id = 12112,
                },
                {
                    id = 12115,
                },
            },
        },
    },
    [4263] = {
        name = {
            enUS = "Incendius!",
            zhCN = "伊森迪奥斯！",
        },
        level = 56,
        min = 48,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9561,
            name = {
                enUS = "Jalinda Sprig",
                zhCN = "加琳达",
            },
            map = 1428,
            x = 85.41,
            y = 70.06,
        },
        finish = {
            kind = "npc",
            id = 9561,
            name = {
                enUS = "Jalinda Sprig",
                zhCN = "加琳达",
            },
            map = 1428,
            x = 85.41,
            y = 70.06,
        },
        before = { 4262 },
        summary = {
            enUS = "Find Lord Incendius in Blackrock Depths and destroy him!",
            zhCN = "在黑石深渊里找到伊森迪奥斯，然后把他干掉！",
        },
        rewards = {
            xp = 5800,
            money = 8500,
            referenceItems = {
                {
                    id = 12113,
                },
                {
                    id = 12114,
                },
                {
                    id = 12112,
                },
                {
                    id = 12115,
                },
            },
        },
    },
    [4286] = {
        name = {
            enUS = "The Good Stuff",
            zhCN = "好东西",
        },
        level = 56,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9177,
            name = {
                enUS = "Oralius",
                zhCN = "奥拉留斯",
            },
            map = 1428,
            x = 84.56,
            y = 68.68,
        },
        finish = {
            kind = "npc",
            id = 9177,
            name = {
                enUS = "Oralius",
                zhCN = "奥拉留斯",
            },
            map = 1428,
            x = 84.56,
            y = 68.68,
        },
        summary = {
            enUS = "Travel to Blackrock Depths and recover 20 Dark Iron Fanny Packs. Return to Oralius when you have completed this task. You assume that the Dark...",
            zhCN = "到黑石深渊去找到20个黑铁挎包。当你完成任务之后，回到奥拉留斯那里复命。你认为黑石深渊里的黑铁矮人应该会有这些黑铁挎包。",
        },
        rewards = {
            xp = 5800,
            money = 8500,
            referenceItems = {
                {
                    id = 11883,
                },
            },
        },
    },
    [4024] = {
        name = {
            enUS = "A Taste of Flame (4024)",
            zhCN = "烈焰精华",
        },
        level = 58,
        min = 52,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9459,
            name = {
                enUS = "Cyrus Therepentous",
                zhCN = "塞勒斯·萨雷芬图斯",
            },
            map = 1428,
            x = 95.09,
            y = 31.56,
        },
        finish = {
            kind = "npc",
            id = 9459,
            name = {
                enUS = "Cyrus Therepentous",
                zhCN = "塞勒斯·萨雷芬图斯",
            },
            map = 1428,
            x = 95.09,
            y = 31.56,
        },
        before = { 3441, 3442, 3443, 3452, 3453, 3462, 3463, 3481 },
        summary = {
            enUS = "Travel to Blackrock Depths and slay Bael'Gar. You only know that the giant resides inside Blackrock Depths. Remember to use the Altered...",
            zhCN = "到黑石深渊去杀掉贝尔加。 你只知道这个巨型怪物住在黑石深渊的最深处。记住你要使用特殊的黑龙皮从贝尔加的尸体上采集烈焰精华。 将你采集到的烈焰精华交给塞勒斯·萨雷芬图斯。",
        },
        rewards = {
            xp = 6200,
            money = 26500,
            referenceItems = {
                {
                    id = 12066,
                },
                {
                    id = 12082,
                },
                {
                    id = 12083,
                },
            },
        },
    },
    [4122] = {
        name = {
            enUS = "Grark Lorkrub",
            zhCN = "格拉克·洛克鲁布",
        },
        level = 58,
        min = 52,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9080,
            name = {
                enUS = "Lexlort",
                zhCN = "雷克斯洛特",
            },
            map = 1418,
            x = 5.88,
            y = 47.63,
        },
        finish = {
            kind = "npc",
            id = 9520,
            name = {
                enUS = "Grark Lorkrub",
                zhCN = "格拉克·洛克鲁布",
            },
            map = 1428,
            x = 33.4,
            y = 50.8,
        },
        after = { 4121, 4132 },
        summary = {
            enUS = "Travel to the Burning Steppes and find Grark Lorkrub. You recall Lexlort mentioning that he was last seen in a massive Blackrock fortress. When...",
            zhCN = "到燃烧平原去找到格拉克·洛克鲁布。你回忆起雷克斯洛特曾经提起过，格拉克应该是在一座大型的黑石要塞中。 当你找到格拉克·洛克鲁布之后，用瑟银镣铐把他铐起来，然后将其带回灼热峡谷。雷克斯洛特会让他的部下等在那里接应你。",
        },
    },
    [4132] = {
        name = {
            enUS = "Operation: Death to Angerforge",
            zhCN = "行动：杀死安格弗将军",
        },
        level = 58,
        min = 52,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9077,
            name = {
                enUS = "Warlord Goretooth",
                zhCN = "军官高图斯",
            },
            map = 1418,
            x = 5.81,
            y = 47.52,
        },
        finish = {
            kind = "npc",
            id = 9077,
            name = {
                enUS = "Warlord Goretooth",
                zhCN = "军官高图斯",
            },
            map = 1418,
            x = 5.81,
            y = 47.52,
        },
        before = { 4122, 4121 },
        summary = {
            enUS = "Travel to Blackrock Depths and slay General Angerforge! Return to Warlord Goretooth when the task is complete.",
            zhCN = "到黑石深渊去杀掉安格弗将军！当任务完成之后向军官高图斯复命。",
        },
        rewards = {
            xp = 7750,
            money = 26500,
            referenceItems = {
                {
                    id = 12059,
                },
            },
        },
    },
    [4121] = {
        name = {
            enUS = "Precarious Predicament",
            zhCN = "押送囚徒",
        },
        level = 58,
        min = 52,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9520,
            name = {
                enUS = "Grark Lorkrub",
                zhCN = "格拉克·洛克鲁布",
            },
            map = 1428,
            x = 33.4,
            y = 50.8,
        },
        finish = {
            kind = "npc",
            id = 9080,
            name = {
                enUS = "Lexlort",
                zhCN = "雷克斯洛特",
            },
            map = 1418,
            x = 5.88,
            y = 47.63,
        },
        before = { 4122 },
        after = { 4132 },
        summary = {
            enUS = "Escort your prisoner, Grark Lorkrub, through Burning Steppes and through Blackrock Mountain to the Searing Gorge. You recall Lexlort...",
            zhCN = "押送你的囚犯格拉克·洛克鲁布。穿过燃烧平原和黑石山脉，一直走到灼热峡谷。 雷克斯洛特曾经告诉过你，他会让他的人等在黑石山脉的另外一边准备接收格拉克。 另外，你还要把瑟银镣铐一并还给雷克斯洛特。",
        },
        rewards = {
            xp = 7750,
            money = 26500,
        },
    },
    [4063] = {
        name = {
            enUS = "The Rise of the Machines (4063)",
            zhCN = "机器的崛起",
        },
        level = 58,
        min = 52,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 2921,
            name = {
                enUS = "Lotwil Veriatus",
                zhCN = "鲁特维尔·沃拉图斯",
            },
            map = 1418,
            x = 25.95,
            y = 44.87,
        },
        finish = {
            kind = "npc",
            id = 2921,
            name = {
                enUS = "Lotwil Veriatus",
                zhCN = "鲁特维尔·沃拉图斯",
            },
            map = 1418,
            x = 25.95,
            y = 44.87,
        },
        before = { 4061 },
        summary = {
            enUS = "Find and slay Golem Lord Argelmach. Return his head to Lotwil. You will also need to collect 10 Intact Elemental Cores from the...",
            zhCN = "找到并杀掉傀儡统帅阿格曼奇，将他的头交给鲁特维尔。你还需要从守卫着阿格曼奇的狂怒傀儡和战斗傀儡身上收集10块完整的元素核心。",
        },
        rewards = {
            xp = 6200,
            money = 26500,
            referenceItems = {
                {
                    id = 12109,
                },
                {
                    id = 12110,
                },
                {
                    id = 12108,
                },
                {
                    id = 12111,
                },
            },
        },
    },
    [4341] = {
        name = {
            enUS = "Kharan Mighthammer",
            zhCN = "卡兰·巨锤",
        },
        level = 59,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 2784,
            name = {
                enUS = "King Magni Bronzebeard",
                zhCN = "国王麦格尼·铜须",
            },
            map = 1455,
            x = 39.09,
            y = 56.2,
        },
        finish = {
            kind = "npc",
            id = 9021,
            name = {
                enUS = "Kharan Mighthammer",
                zhCN = "卡兰·巨锤",
            },
        },
        before = { 3702 },
        after = { 4361, 4362, 4363 },
        summary = {
            enUS = "Travel to Blackrock Depths and find Kharan Mighthammer. The King mentioned that Kharan was being held prisoner there - perhaps you should try...",
            zhCN = "去黑石深渊找到卡兰·巨锤。 国王提到卡兰在那里负责看守囚犯——也许你应该在监狱附近寻找他。",
        },
    },
    [4342] = {
        name = {
            enUS = "Kharan's Tale",
            zhCN = "卡兰的故事",
        },
        level = 59,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9021,
            name = {
                enUS = "Kharan Mighthammer",
                zhCN = "卡兰·巨锤",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 9021,
            name = {
                enUS = "Kharan Mighthammer",
                zhCN = "卡兰·巨锤",
            },
        },
        after = { 4361, 4362, 4363 },
        summary = {
            enUS = "Listen as Kharan Mighthammer tells his story.",
            zhCN = "听卡兰·巨锤说他的故事。",
        },
    },
    [4361] = {
        name = {
            enUS = "The Bearer of Bad News",
            zhCN = "糟糕的消息",
        },
        level = 59,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 9021,
            name = {
                enUS = "Kharan Mighthammer",
                zhCN = "卡兰·巨锤",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 2784,
            name = {
                enUS = "King Magni Bronzebeard",
                zhCN = "国王麦格尼·铜须",
            },
            map = 1455,
            x = 39.09,
            y = 56.2,
        },
        before = { 3702, 4341 },
        after = { 4362, 4363 },
        summary = {
            enUS = "Return to Ironforge and deliver the bad news to King Magni Bronzebeard.",
            zhCN = "回到铁炉堡，把这个坏消息带给国王麦格尼·铜须。",
        },
    },
    [4362] = {
        name = {
            enUS = "The Fate of the Kingdom",
            zhCN = "王国的命运",
        },
        level = 59,
        min = 50,
        faction = "A",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 2784,
            name = {
                enUS = "King Magni Bronzebeard",
                zhCN = "国王麦格尼·铜须",
            },
            map = 1455,
            x = 39.09,
            y = 56.2,
        },
        finish = {
            kind = "npc",
            id = 8929,
            name = {
                enUS = "Princess Moira Bronzebeard",
                zhCN = "铁炉堡公主茉艾拉·铜须",
            },
        },
        before = { 3702, 4341, 4361 },
        after = { 4363 },
        summary = {
            enUS = "Return to Blackrock Depths and rescue Princess Moira Bronzebeard from the evil clutches of Emperor Dagran Thaurissan.",
            zhCN = "回到黑石深渊，从达格兰·索瑞森大帝的魔掌中救出铁炉堡公主茉艾拉·铜须。",
        },
        rewards = {
            xp = 8050,
        },
    },
    [4003] = {
        name = {
            enUS = "The Royal Rescue",
            zhCN = "拯救公主",
        },
        level = 59,
        min = 48,
        faction = "H",
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        finish = {
            kind = "npc",
            id = 8929,
            name = {
                enUS = "Princess Moira Bronzebeard",
                zhCN = "铁炉堡公主茉艾拉·铜须",
            },
        },
        before = { 3906, 3981, 3982, 4002 },
        after = { 4004 },
        summary = {
            enUS = "Slay Emperor Dagran Thaurissan and free Princess Moira Bronzebeard from his evil spell.",
            zhCN = "杀掉达格兰·索瑞森大帝，然后将铁炉堡公主茉艾拉·铜须从他的邪恶诅咒中拯救出来。",
        },
        rewards = {
            xp = 8050,
        },
    },
    [7848] = {
        name = {
            enUS = "Attunement to the Core",
            zhCN = "熔火之心的传送门",
        },
        level = 60,
        min = 55,
        instances = { "blackrock-depths" },
        start = {
            kind = "npc",
            id = 14387,
            name = {
                enUS = "Lothos Riftwaker",
                zhCN = "洛索斯·天痕",
            },
            map = 1415,
            x = 48.4,
            y = 63.8,
            unverified = true,
        },
        finish = {
            kind = "npc",
            id = 14387,
            name = {
                enUS = "Lothos Riftwaker",
                zhCN = "洛索斯·天痕",
            },
        },
        summary = {
            enUS = "Venture to the Molten Core entry portal in Blackrock Depths and recover a Core Fragment. Return to Lothos Riftwaker in Blackrock Mountain...",
            zhCN = "进入黑石深渊，在通往熔火之心的传送门附近找到一块熔火碎片，然后回到黑石山脉的洛索斯·天痕那里。",
        },
    },
    [6804] = {
        name = {
            enUS = "Poisoned Water",
            zhCN = "被囚禁的水元素",
        },
        level = 56,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 13278,
            name = {
                enUS = "Duke Hydraxis",
                zhCN = "海达克西斯公爵",
            },
            map = 1447,
            x = 79.28,
            y = 73.7,
        },
        finish = {
            kind = "npc",
            id = 13278,
            name = {
                enUS = "Duke Hydraxis",
                zhCN = "海达克西斯公爵",
            },
            map = 1447,
            x = 79.28,
            y = 73.7,
        },
        summary = {
            enUS = "Use the Aspect of Neptulon on poisoned elementals of Eastern Plaguelands. Bring 12 Discordant Bracers and the Aspect of Neptulon to Duke Hydraxis...",
            zhCN = "对东瘟疫之地的被感染的水元素使用海神之水。把12副不谐护腕和海神之水交给艾萨拉的海达克西斯公爵。",
        },
    },
    [6805] = {
        name = {
            enUS = "Stormers and Rumblers",
            zhCN = "雷暴和磐石",
        },
        level = 57,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 13278,
            name = {
                enUS = "Duke Hydraxis",
                zhCN = "海达克西斯公爵",
            },
            map = 1447,
            x = 79.28,
            y = 73.7,
        },
        finish = {
            kind = "npc",
            id = 13278,
            name = {
                enUS = "Duke Hydraxis",
                zhCN = "海达克西斯公爵",
            },
            map = 1447,
            x = 79.28,
            y = 73.7,
        },
        summary = {
            enUS = "Kill 15 Dust Stormers and 15 Desert Rumblers and then return to Duke Hydraxis in Azshara.",
            zhCN = "杀死15个灰尘风暴和15个沙漠奔行者，然后回到艾萨拉的海达克西斯公爵那儿。",
        },
    },
    [4788] = {
        name = {
            enUS = "The Final Tablets",
            zhCN = "最后的石板",
        },
        level = 58,
        min = 40,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10460,
            name = {
                enUS = "Prospector Ironboot",
                zhCN = "勘查员詹斯·铁靴",
            },
            map = 1446,
            x = 66.89,
            y = 24.03,
        },
        finish = {
            kind = "npc",
            id = 10460,
            name = {
                enUS = "Prospector Ironboot",
                zhCN = "勘查员詹斯·铁靴",
            },
            map = 1446,
            x = 66.89,
            y = 24.03,
        },
        before = { 3520, 3527, 4787, 3528, 5065 },
        after = { 8181, 8182 },
        summary = {
            enUS = "Bring the Fifth and Sixth Mosh'aru Tablets to Prospector Ironboot in Tanaris.",
            zhCN = "将第五块和第六块摩沙鲁石板交给塔纳利斯的勘查员詹斯·铁靴。",
        },
        rewards = {
            xp = 7750,
        },
    },
    [5065] = {
        name = {
            enUS = "The Lost Tablets of Mosh'aru",
            zhCN = "失落的摩沙鲁石板",
        },
        level = 58,
        min = 40,
        instances = { "blackrock-spire" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 10460,
            name = {
                enUS = "Prospector Ironboot",
                zhCN = "勘查员詹斯·铁靴",
            },
            map = 1446,
            x = 66.89,
            y = 24.03,
        },
        finish = {
            kind = "npc",
            id = 10460,
            name = {
                enUS = "Prospector Ironboot",
                zhCN = "勘查员詹斯·铁靴",
            },
            map = 1446,
            x = 66.89,
            y = 24.03,
        },
        after = { 4788 },
        summary = {
            enUS = "Bring the Third and Fourth Mosh'aru Tablets to Prospector Ironboot in Tanaris.",
            zhCN = "把第三块和第四块摩沙鲁石板交给塔纳利斯的勘查员詹斯·铁靴。",
        },
    },
    [4982] = {
        name = {
            enUS = "Bijou's Belongings (4982)",
            zhCN = "比修的装置",
        },
        level = 59,
        min = 55,
        faction = "H",
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10257,
            name = {
                enUS = "Bijou",
                zhCN = "比修",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 10257,
            name = {
                enUS = "Bijou",
                zhCN = "比修",
            },
        },
        before = { 4981 },
        after = { 4983 },
        summary = {
            enUS = "Find Bijou's Belongings and return them to her. You recall her mentioning that she stashed them on the bottom floor of the city.",
            zhCN = "找到比修的装置并把它们还给她。你记得她说过她把装置藏在城市的最底层。",
        },
        rewards = {
            xp = 6400,
        },
    },
    [5001] = {
        name = {
            enUS = "Bijou's Belongings (5001)",
            zhCN = "比修的装置",
        },
        level = 59,
        min = 55,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10257,
            name = {
                enUS = "Bijou",
                zhCN = "比修",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 10257,
            name = {
                enUS = "Bijou",
                zhCN = "比修",
            },
        },
        after = { 5002, 5081 },
        summary = {
            enUS = "Find Bijou's Belongings and return them to her. Good luck!",
            zhCN = "找到比修的装置并把它们还给她。祝你好运！",
        },
        rewards = {
            xp = 6400,
        },
    },
    [4862] = {
        name = {
            enUS = "En-Ay-Es-Tee-Why",
            zhCN = "蜘蛛卵",
        },
        level = 59,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10260,
            name = {
                enUS = "Kibler",
                zhCN = "基布雷尔",
            },
            map = 1428,
            x = 65.89,
            y = 21.92,
        },
        finish = {
            kind = "npc",
            id = 10260,
            name = {
                enUS = "Kibler",
                zhCN = "基布雷尔",
            },
            map = 1428,
            x = 65.89,
            y = 21.92,
        },
        summary = {
            enUS = "Travel to Blackrock Spire and collect 15 Spire Spider Eggs for Kibler. By the sound of it, these eggs could be found near spiders.",
            zhCN = "到黑石塔去为基布雷尔收集15枚尖塔蜘蛛卵。 听说那些蜘蛛周围有许多这样的卵。",
        },
        rewards = {
            xp = 6400,
            money = 9000,
            referenceItems = {
                {
                    id = 12529,
                },
            },
        },
    },
    [4729] = {
        name = {
            enUS = "Kibler's Exotic Pets",
            zhCN = "基布雷尔的特殊宠物",
        },
        level = 59,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10260,
            name = {
                enUS = "Kibler",
                zhCN = "基布雷尔",
            },
            map = 1428,
            x = 65.89,
            y = 21.92,
        },
        finish = {
            kind = "npc",
            id = 10260,
            name = {
                enUS = "Kibler",
                zhCN = "基布雷尔",
            },
            map = 1428,
            x = 65.89,
            y = 21.92,
        },
        summary = {
            enUS = "Travel to Blackrock Spire and find Bloodaxe Worg Pups. Use the cage to carry the ferocious little beasts. Bring back a Caged Worg Pup to...",
            zhCN = "到黑石塔去找到血斧座狼幼崽。使用笼子来捕捉这些凶猛的小野兽，然后把笼中的座狼幼崽交给基布雷尔。",
        },
        rewards = {
            xp = 6400,
            money = 9000,
            referenceItems = {
                {
                    id = 12264,
                },
            },
        },
    },
    [5002] = {
        name = {
            enUS = "Message to Maxwell",
            zhCN = "给麦克斯韦尔的消息",
        },
        level = 59,
        min = 55,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10257,
            name = {
                enUS = "Bijou",
                zhCN = "比修",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        before = { 5001 },
        after = { 5081 },
        summary = {
            enUS = "Travel to the Burning Steppes and give Bijou's Information to Marshal Maxwell.",
            zhCN = "到燃烧平原去，把比修的情报交给麦克斯韦尔元帅。",
        },
        rewards = {
            xp = 6400,
            money = 18000,
        },
    },
    [4981] = {
        name = {
            enUS = "Operative Bijou",
            zhCN = "狡猾的比修",
        },
        level = 59,
        min = 55,
        faction = "H",
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
        start = {
            kind = "npc",
            id = 9080,
            name = {
                enUS = "Lexlort",
                zhCN = "雷克斯洛特",
            },
            map = 1418,
            x = 5.88,
            y = 47.63,
        },
        finish = {
            kind = "npc",
            id = 10257,
            name = {
                enUS = "Bijou",
                zhCN = "比修",
            },
        },
        after = { 4982, 4983 },
        summary = {
            enUS = "Travel to Blackrock Spire and find out what happened to Bijou.",
            zhCN = "到黑石塔去查明比修的下落。",
        },
    },
    [4701] = {
        name = {
            enUS = "Put Her Down",
            zhCN = "座狼之源",
        },
        level = 59,
        min = 55,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
        start = {
            kind = "npc",
            id = 9562,
            name = {
                enUS = "Helendis Riverhorn",
                zhCN = "赫林迪斯·河角",
            },
            map = 1428,
            x = 85.82,
            y = 68.95,
        },
        finish = {
            kind = "npc",
            id = 9562,
            name = {
                enUS = "Helendis Riverhorn",
                zhCN = "赫林迪斯·河角",
            },
            map = 1428,
            x = 85.82,
            y = 68.95,
        },
        summary = {
            enUS = "Travel to Blackrock Spire and destroy the source of the worg menace. As you left Helendis, he shouted a name: Halycon. It is what the orcs refer to...",
            zhCN = "到黑石塔去摧毁那里的座狼源头。当你离开的时候，赫林迪斯喊出了一个名字：哈雷肯。这个词就是兽人语中“座狼”的意思。",
        },
        rewards = {
            xp = 6400,
            money = 18000,
            referenceItems = {
                {
                    id = 15824,
                },
                {
                    id = 15825,
                },
                {
                    id = 15827,
                },
            },
        },
    },
    [4724] = {
        name = {
            enUS = "The Pack Mistress",
            zhCN = "座狼的首领",
        },
        level = 59,
        min = 55,
        faction = "H",
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
        start = {
            kind = "npc",
            id = 9081,
            name = {
                enUS = "Galamav the Marksman",
                zhCN = "神射手贾拉玛弗",
            },
            map = 1418,
            x = 5.96,
            y = 47.73,
        },
        finish = {
            kind = "npc",
            id = 9081,
            name = {
                enUS = "Galamav the Marksman",
                zhCN = "神射手贾拉玛弗",
            },
            map = 1418,
            x = 5.96,
            y = 47.73,
        },
        summary = {
            enUS = "Slay Halycon, pack mistress of the Bloodaxe worg.",
            zhCN = "杀死血斧座狼的领袖，哈雷肯。",
        },
        rewards = {
            xp = 6400,
            money = 18000,
            referenceItems = {
                {
                    id = 15824,
                },
                {
                    id = 15825,
                },
                {
                    id = 15827,
                },
            },
        },
    },
    [7761] = {
        name = {
            enUS = "Blackhand's Command",
            zhCN = "黑手的命令",
        },
        level = 60,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
        start = {
            kind = "item",
            id = 18987,
            name = {
                enUS = "Blackhand's Command",
                zhCN = "黑手的命令",
            },
        },
        inside = true,
        finish = {
            kind = "object",
            id = 179880,
            name = {
                enUS = "Drakkisath's Brand",
                zhCN = "达基萨斯的烙印",
            },
        },
        summary = {
            enUS = "That is one stupid orc. It would appear as if you need to find this brand and gain the Mark of Drakkisath in order to access the Orb of...",
            zhCN = "真是个愚蠢的兽人。看来你需要找到那枚烙印并获得达基萨斯徽记才可以使用命令宝珠。 你从信中获知，达基萨斯将军守卫着烙印。也许你应该就此进行更深入的调查。",
        },
    },
    [4764] = {
        name = {
            enUS = "Doomrigger's Clasp",
            zhCN = "末日扣环",
        },
        level = 60,
        min = 57,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 9565,
            name = {
                enUS = "Mayara Brightwing",
                zhCN = "玛亚拉·布莱特文",
            },
            map = 1428,
            x = 84.84,
            y = 69.12,
        },
        finish = {
            kind = "npc",
            id = 9565,
            name = {
                enUS = "Mayara Brightwing",
                zhCN = "玛亚拉·布莱特文",
            },
            map = 1428,
            x = 84.84,
            y = 69.12,
        },
        after = { 4765 },
        summary = {
            enUS = "Bring Doomrigger's Clasp to Mayara Brightwing in the Burning Steppes.",
            zhCN = "将末日扣环交给燃烧平原的玛亚拉·布莱特文。",
        },
        rewards = {
            xp = 1650,
        },
    },
    [6821] = {
        name = {
            enUS = "Eye of the Emberseer",
            zhCN = "艾博希尔之眼",
        },
        level = 60,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
        start = {
            kind = "npc",
            id = 13278,
            name = {
                enUS = "Duke Hydraxis",
                zhCN = "海达克西斯公爵",
            },
            map = 1447,
            x = 79.28,
            y = 73.7,
        },
        finish = {
            kind = "npc",
            id = 13278,
            name = {
                enUS = "Duke Hydraxis",
                zhCN = "海达克西斯公爵",
            },
            map = 1447,
            x = 79.28,
            y = 73.7,
        },
        summary = {
            enUS = "Bring the Eye of the Emberseer to Duke Hydraxis in Azshara.",
            zhCN = "将艾博希尔之眼交给艾萨拉的海达克西斯公爵。",
        },
    },
    [4974] = {
        name = {
            enUS = "For The Horde!",
            zhCN = "为部落而战！",
        },
        level = 60,
        min = 55,
        faction = "H",
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        finish = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        summary = {
            enUS = "Travel to Blackrock Spire and slay Warchief Rend Blackhand. Take his head and return to Orgrimmar.",
            zhCN = "去黑石塔杀死大酋长雷德·黑手，带着他的头颅返回奥格瑞玛。",
        },
        rewards = {
            xp = 9950,
            money = 27000,
            referenceItems = {
                {
                    id = 13966,
                },
                {
                    id = 13968,
                },
                {
                    id = 13965,
                },
            },
        },
    },
    [5089] = {
        name = {
            enUS = "General Drakkisath's Command",
            zhCN = "达基萨斯将军的命令",
        },
        level = 60,
        min = 55,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
        start = {
            kind = "item",
            id = 12780,
            name = {
                enUS = "General Drakkisath's Command",
                zhCN = "达基萨斯将军的命令",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        after = { 5102 },
        summary = {
            enUS = "Take General Drakkisath's Command to Marshal Maxwell in Burning Steppes.",
            zhCN = "把达基萨斯将军的命令交给燃烧平原的麦克斯韦尔元帅。",
        },
        rewards = {
            xp = 6600,
        },
    },
    [5102] = {
        name = {
            enUS = "General Drakkisath's Demise",
            zhCN = "达基萨斯将军之死",
        },
        level = 60,
        min = 55,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
        start = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        finish = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        summary = {
            enUS = "Travel to Blackrock Spire and destroy General Drakkisath. Return to Marshal Maxwell when the job is done.",
            zhCN = "到黑石塔去杀掉达基萨斯将军，完成任务之后就回到麦克斯韦尔元帅那里复命。",
        },
        rewards = {
            xp = 9950,
            money = 27000,
            referenceItems = {
                {
                    id = 13966,
                },
                {
                    id = 13968,
                },
                {
                    id = 13965,
                },
            },
        },
    },
    [5126] = {
        name = {
            enUS = "Lorax's Tale",
            zhCN = "罗拉克斯的故事",
        },
        level = 60,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 10918,
            name = {
                enUS = "Lorax",
                zhCN = "罗拉克斯",
            },
            map = 1452,
            x = 63.79,
            y = 73.76,
        },
        finish = {
            kind = "npc",
            id = 10918,
            name = {
                enUS = "Lorax",
                zhCN = "罗拉克斯",
            },
            map = 1452,
            x = 63.79,
            y = 73.76,
        },
        after = { 5127 },
        summary = {
            enUS = "Speak with Lorax. Listen to what he has to say.",
            zhCN = "与罗拉克斯谈一谈，听听他要说什么。",
        },
    },
    [5081] = {
        name = {
            enUS = "Maxwell's Mission",
            zhCN = "麦克斯韦尔的任务",
        },
        level = 60,
        min = 55,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
        start = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        finish = {
            kind = "npc",
            id = 9560,
            name = {
                enUS = "Marshal Maxwell",
                zhCN = "麦克斯韦尔元帅",
            },
            map = 1428,
            x = 84.74,
            y = 69.02,
        },
        before = { 5001, 5002 },
        summary = {
            enUS = "Travel to Blackrock Spire and destroy War Master Voone, Highlord Omokk, and Overlord Wyrmthalak. Return to Marshal Maxwell when the job is done.",
            zhCN = "到黑石塔去消灭指挥官沃恩、欧莫克大王和维姆萨拉克。完成任务之后回到麦克斯韦尔元帅处复命。",
        },
        rewards = {
            xp = 8300,
            money = 18000,
            referenceItems = {
                {
                    id = 13958,
                },
                {
                    id = 13959,
                },
                {
                    id = 13961,
                },
                {
                    id = 13962,
                },
                {
                    id = 13963,
                },
            },
        },
    },
    [4766] = {
        name = {
            enUS = "Mayara Brightwing",
            zhCN = "玛亚拉·布莱特文",
        },
        level = 60,
        min = 57,
        faction = "A",
        instances = { "blackrock-spire" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 2285,
            name = {
                enUS = "Count Remington Ridgewell",
                zhCN = "雷明顿·瑞治维尔伯爵",
            },
            map = 1453,
            x = 76.9,
            y = 47.8,
        },
        finish = {
            kind = "npc",
            id = 9565,
            name = {
                enUS = "Mayara Brightwing",
                zhCN = "玛亚拉·布莱特文",
            },
            map = 1428,
            x = 84.84,
            y = 69.12,
        },
        summary = {
            enUS = "Speak with Mayara Brightwing in the Burning Steppes.",
            zhCN = "与燃烧平原的玛亚拉·布莱特文谈一谈。",
        },
    },
    [4742] = {
        name = {
            enUS = "Seal of Ascension (4742)",
            zhCN = "晋升印章",
        },
        level = 60,
        min = 57,
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
        start = {
            kind = "npc",
            id = 10296,
            name = {
                enUS = "Vaelan",
                zhCN = "维埃兰",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 10296,
            name = {
                enUS = "Vaelan",
                zhCN = "维埃兰",
            },
        },
        summary = {
            enUS = "Find the three gemstones of command: The Gemstone of Smolderthorn, Gemstone of Spirestone, and Gemstone of Bloodaxe. Return them, along...",
            zhCN = "找到三块命令宝石：燃棘宝钻、尖石宝钻和血斧宝钻。把它们和原始晋升印章一起交给维埃兰。 可能携带者三块宝石的将军是：燃棘氏族的指挥官沃恩、尖石氏族的欧莫克大王，以及血斧氏族的维姆萨拉克。",
        },
        rewards = {
            xp = 8300,
        },
    },
    [4743] = {
        name = {
            enUS = "Seal of Ascension (4743)",
            zhCN = "晋升印章",
        },
        level = 60,
        min = 57,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10296,
            name = {
                enUS = "Vaelan",
                zhCN = "维埃兰",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 10296,
            name = {
                enUS = "Vaelan",
                zhCN = "维埃兰",
            },
        },
        summary = {
            enUS = "Travel to the Wyrmbog in Dustwallow Marsh. Find the ancient drake, Emberstrife and beat him without mercy until his will is broken. It...",
            zhCN = "到尘泥沼泽中的巨龙沼泽去。找到上古老龙埃博斯塔夫，对他发起无情的攻击，直到他的意志被摧毁。 此时，你必须尽快将未铸造的晋升印章放在这条龙面前，并使用龙力宝珠控制他的躯体，强迫他将黑龙的烈焰喷向未铸造的晋升印章！",
        },
        rewards = {
            xp = 9950,
            referenceItems = {
                {
                    id = 12344,
                },
            },
        },
    },
    [4768] = {
        name = {
            enUS = "The Darkstone Tablet",
            zhCN = "黑暗石板",
        },
        level = 60,
        min = 57,
        faction = "H",
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
        start = {
            kind = "npc",
            id = 9078,
            name = {
                enUS = "Shadowmage Vivian Lagrave",
                zhCN = "暗法师薇薇安·拉格雷",
            },
            map = 1418,
            x = 2.9,
            y = 47.76,
        },
        finish = {
            kind = "npc",
            id = 9078,
            name = {
                enUS = "Shadowmage Vivian Lagrave",
                zhCN = "暗法师薇薇安·拉格雷",
            },
            map = 1418,
            x = 2.9,
            y = 47.76,
        },
        summary = {
            enUS = "Bring the Darkstone Tablet to Shadow Mage Vivian Lagrave in Kargath.",
            zhCN = "将黑暗石板交给卡加斯的暗法师薇薇安·拉格雷。",
        },
        rewards = {
            xp = 8300,
            money = 27000,
            referenceItems = {
                {
                    id = 15861,
                },
                {
                    id = 15860,
                },
            },
        },
    },
    [5127] = {
        name = {
            enUS = "The Demon Forge",
            zhCN = "恶魔熔炉",
        },
        level = 60,
        min = 55,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10918,
            name = {
                enUS = "Lorax",
                zhCN = "罗拉克斯",
            },
            map = 1452,
            x = 63.79,
            y = 73.76,
        },
        finish = {
            kind = "npc",
            id = 10918,
            name = {
                enUS = "Lorax",
                zhCN = "罗拉克斯",
            },
            map = 1452,
            x = 63.79,
            y = 73.76,
        },
        before = { 5126 },
        summary = {
            enUS = "Travel to Blackrock Spire and find Goraluk Anvilcrack. Slay him and then use the Blood Stained Pike upon his corpse. After his soul has been...",
            zhCN = "到黑石塔去找到古拉鲁克。杀死他，然后用血污长矛刺入他的尸体。当他的灵魂被吸干后，这支矛就会成为穿魂长矛。 你还必须找到未铸造的符文覆饰胸甲。 将穿魂长矛和未铸造的符文覆饰胸甲都交给冬泉谷的罗拉克斯。",
        },
        rewards = {
            xp = 8300,
            referenceItems = {
                {
                    id = 12696,
                },
                {
                    id = 9224,
                },
                {
                    id = 12849,
                },
            },
        },
    },
    [5160] = {
        name = {
            enUS = "The Matron Protectorate",
            zhCN = "监护者",
        },
        level = 60,
        min = 57,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper", "lower" },
        start = {
            kind = "npc",
            id = 10740,
            name = {
                enUS = "Awbee",
                zhCN = "奥比",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 10929,
            name = {
                enUS = "Haleh",
                zhCN = "哈尔琳",
            },
            map = 1452,
            x = 54.55,
            y = 51.2,
        },
        after = { 5161, 5164, 5166, 5167 },
        summary = {
            enUS = "Travel to Winterspring and find Haleh. Give her Awbee's scale.",
            zhCN = "到冬泉谷去找到哈尔琳，把奥比的鳞片交给她。",
        },
        rewards = {
            xp = 6600,
        },
    },
    [4903] = {
        name = {
            enUS = "Warlord's Command",
            zhCN = "高图斯的命令",
        },
        level = 60,
        min = 55,
        faction = "H",
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
        start = {
            kind = "npc",
            id = 9077,
            name = {
                enUS = "Warlord Goretooth",
                zhCN = "军官高图斯",
            },
            map = 1418,
            x = 5.81,
            y = 47.52,
        },
        finish = {
            kind = "npc",
            id = 9077,
            name = {
                enUS = "Warlord Goretooth",
                zhCN = "军官高图斯",
            },
            map = 1418,
            x = 5.81,
            y = 47.52,
        },
        after = { 4941, 4974, 6566, 6567 },
        summary = {
            enUS = "Slay Highlord Omokk, War Master Voone, and Overlord Wyrmthalak. Recover Important Blackrock Documents. Return to Warlord Goretooth in Kargath...",
            zhCN = "杀死欧莫克大王、指挥官沃恩和维姆萨拉克。找到重要的黑石文件，然后向卡加斯的军官高图斯汇报。",
        },
        rewards = {
            xp = 8300,
            money = 18000,
            referenceItems = {
                {
                    id = 13958,
                },
                {
                    id = 13959,
                },
                {
                    id = 13961,
                },
                {
                    id = 13962,
                },
                {
                    id = 13963,
                },
            },
        },
    },
    [214] = {
        name = {
            enUS = "Red Silk Bandanas",
            zhCN = "红色丝质面罩",
        },
        level = 17,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 820,
            name = {
                enUS = "Scout Riell",
                zhCN = "哨兵瑞尔",
            },
            map = 1436,
            x = 56.7,
            y = 47.3,
        },
        finish = {
            kind = "npc",
            id = 820,
            name = {
                enUS = "Scout Riell",
                zhCN = "哨兵瑞尔",
            },
            x = 56.7,
            y = 47.3,
        },
        before = { 65, 132, 135, 141, 142, 155 },
        summary = {
            enUS = "Scout Riell at the Sentinel Hill Tower wants you to bring her 10 Red Silk Bandanas.",
            zhCN = "给哨兵岭哨塔的哨兵瑞尔带回10条红色丝质面罩。",
        },
        objectives = {
            enUS = { "Red Silk Bandana ×10" },
            zhCN = { "红色丝质面罩 ×10" },
        },
        rewards = {
            xp = 4700,
            choices = {
                {
                    id = 2074,
                    count = 1,
                },
                {
                    id = 2089,
                    count = 1,
                },
                {
                    id = 6094,
                    count = 1,
                },
                {
                    id = 270005,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 100,
                },
            },
        },
    },
    [168] = {
        name = {
            enUS = "Collecting Memories",
            zhCN = "收集记忆",
        },
        level = 18,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 656,
            name = {
                enUS = "Wilder Thistlenettle",
                zhCN = "维尔德·蓟草",
            },
            map = 1453,
            x = 70.2,
            y = 40.8,
        },
        finish = {
            kind = "npc",
            id = 656,
            name = {
                enUS = "Wilder Thistlenettle",
                zhCN = "维尔德·蓟草",
            },
            map = 1453,
            x = 70.2,
            y = 40.8,
        },
        summary = {
            enUS = "Retrieve 4 Miners' Union Cards and return them to Wilder Thistlenettle in Stormwind.",
            zhCN = "给暴风城的维尔德·蓟草带回4张矿业工会会员卡。",
        },
        objectives = {
            enUS = { "Miners' Union Card ×4" },
            zhCN = { "矿业工会会员卡 ×4" },
        },
        rewards = {
            xp = 1350,
            choices = {
                {
                    id = 2037,
                    count = 1,
                },
                {
                    id = 2036,
                    count = 1,
                },
                {
                    id = 270007,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Ironforge",
                        zhCN = "铁炉堡",
                    },
                    value = 100,
                },
            },
        },
    },
    [92753] = {
        name = {
            enUS = "Destruction in Deadmines",
            zhCN = "死亡矿井中的爆破",
        },
        level = 18,
        min = 9,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "item",
            id = 254553,
            name = {
                enUS = "Extra-Destructive Explosives",
                zhCN = "强效炸药",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            name = {
                enUS = "Alba Fairmoon",
                zhCN = "阿尔芭·皎月",
            },
        },
        before = { 92742, 92744, 92745, 92747, 92748, 92749, 92750, 92751, 92752 },
        summary = {
            enUS = "Find the forge hidden in the Deadmines, and plant the Extra-Destructive Explosives nearby. Then, meet up with Alba Fairmoon at the Deadmines exit.",
            zhCN = "找到死亡矿井深处的熔炉，在附近安放强效炸药，然后在死亡矿井出口与阿尔芭·皎月会合。",
        },
        objectives = {
            enUS = { "Explosives placed", "Extra-Destructive Explosives" },
            zhCN = { "已安放炸药", "强效炸药" },
        },
        rewards = {
            xp = 4050,
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 50,
                },
            },
        },
    },
    [132] = {
        name = {
            enUS = "The Defias Brotherhood (132)",
            zhCN = "迪菲亚兄弟会",
        },
        level = 18,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 266,
            name = {
                enUS = "Wiley the Black",
                zhCN = "黑衣威利",
            },
            map = 1433,
            x = 21.5,
            y = 45.3,
        },
        finish = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.33,
            y = 47.52,
        },
        after = { 214, 166 },
        summary = {
            enUS = "Take Wiley's Note to Gryan Stoutmantle in Westfall.",
            zhCN = "将威利的便笺交给西部荒野的格里安·斯托曼。",
        },
        rewards = {
            xp = 675,
        },
    },
    [135] = {
        name = {
            enUS = "The Defias Brotherhood (135)",
            zhCN = "迪菲亚兄弟会",
        },
        level = 18,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.33,
            y = 47.52,
        },
        finish = {
            kind = "npc",
            id = 332,
            name = {
                enUS = "Master Mathias Shaw",
                zhCN = "马迪亚斯·肖尔",
            },
            map = 1453,
            x = 78.4,
            y = 70.7,
        },
        after = { 214, 166 },
        summary = {
            enUS = "Take Wiley's Note to Mathias Shaw in Stormwind.",
            zhCN = "将威利的便笺交给暴风城的马迪亚斯·肖尔。",
        },
        rewards = {
            xp = 675,
        },
    },
    [141] = {
        name = {
            enUS = "The Defias Brotherhood (141)",
            zhCN = "迪菲亚兄弟会",
        },
        level = 18,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 332,
            name = {
                enUS = "Master Mathias Shaw",
                zhCN = "马迪亚斯·肖尔",
            },
            map = 1453,
            x = 78.4,
            y = 70.7,
        },
        finish = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.33,
            y = 47.52,
        },
        after = { 214, 166 },
        summary = {
            enUS = "Take Shaw's report to Gryan Stoutmantle in Westfall.",
            zhCN = "将肖尔的报告交给西部荒野的格里安·斯托曼。",
        },
        rewards = {
            xp = 340,
        },
    },
    [142] = {
        name = {
            enUS = "The Defias Brotherhood (142)",
            zhCN = "迪菲亚兄弟会",
        },
        level = 18,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.33,
            y = 47.52,
        },
        finish = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.33,
            y = 47.52,
        },
        after = { 214, 166 },
        summary = {
            enUS = "Track down the Defias Messenger in Westfall and bring his message to Stoutmantle.",
            zhCN = "追捕西部荒野的迪菲亚信使，并将他身上携带着的信件交给斯托曼。",
        },
    },
    [155] = {
        name = {
            enUS = "The Defias Brotherhood (155)",
            zhCN = "迪菲亚兄弟会",
        },
        level = 18,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 467,
            name = {
                enUS = "The Defias Traitor",
                zhCN = "迪菲亚叛徒",
            },
            map = 1436,
            x = 43.8,
            y = 69.6,
        },
        finish = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.33,
            y = 47.52,
        },
        after = { 214, 166 },
        summary = {
            enUS = "Escort the Defias Traitor to the secret hideout of the Defias Brotherhood. Once the Defias Traitor shows you where VanCleef and his...",
            zhCN = "护送迪菲亚叛徒前往迪菲亚兄弟会的秘密藏身处。迪菲亚叛徒把你带到范克里夫和他的手下的巢穴之后，尽快回去向格里安·斯托曼汇报相关信息。",
        },
    },
    [65] = {
        name = {
            enUS = "The Defias Brotherhood (65)",
            zhCN = "迪菲亚兄弟会",
        },
        level = 18,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.33,
            y = 47.52,
        },
        finish = {
            kind = "npc",
            id = 266,
            name = {
                enUS = "Wiley the Black",
                zhCN = "黑衣威利",
            },
            map = 1433,
            x = 21.5,
            y = 45.3,
        },
        after = { 214, 166 },
        summary = {
            enUS = "Gryan Stoutmantle wants you to talk to Wiley in Lakeshire.",
            zhCN = "格里安·斯托曼要求你去和湖畔镇的威利谈一谈。",
        },
        rewards = {
            xp = 1350,
        },
    },
    [167] = {
        name = {
            enUS = "Oh Brother...",
            zhCN = "我的兄弟……",
        },
        level = 20,
        min = 15,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 656,
            name = {
                enUS = "Wilder Thistlenettle",
                zhCN = "维尔德·蓟草",
            },
            map = 1453,
            x = 70.2,
            y = 40.8,
        },
        finish = {
            kind = "npc",
            id = 656,
            name = {
                enUS = "Wilder Thistlenettle",
                zhCN = "维尔德·蓟草",
            },
            map = 1453,
            x = 70.2,
            y = 40.8,
        },
        summary = {
            enUS = "Bring Foreman Thistlenettle's Explorers' League Badge to Wilder Thistlenettle in Stormwind.",
            zhCN = "将工头希斯耐特的探险者协会徽章交给暴风城的维尔德·蓟草。",
        },
        objectives = {
            enUS = { "Thistlenettle's Badge" },
            zhCN = { "希斯耐特的徽章" },
        },
        rewards = {
            xp = 1550,
            money = 500,
            choices = {
                {
                    id = 1893,
                    count = 1,
                },
                {
                    id = 270012,
                    count = 1,
                },
                {
                    id = 270013,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Ironforge",
                        zhCN = "铁炉堡",
                    },
                    value = 100,
                },
            },
        },
    },
    [2040] = {
        name = {
            enUS = "Underground Assault",
            zhCN = "地底突袭",
        },
        level = 20,
        min = 15,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 6579,
            name = {
                enUS = "Shoni the Shilent",
                zhCN = "沉默的舒尼",
            },
            map = 1453,
            x = 62.7,
            y = 34.2,
        },
        finish = {
            kind = "npc",
            id = 6579,
            name = {
                enUS = "Shoni the Shilent",
                zhCN = "沉默的舒尼",
            },
            map = 1453,
            x = 62.7,
            y = 34.2,
        },
        before = { 2041 },
        summary = {
            enUS = "Retrieve the Gnoam Sprecklesprocket from the Deadmines and return it to Shoni the Shilent in Stormwind.",
            zhCN = "从死亡矿井中带回小型高能发动机，将其带给暴风城矮人区中的沉默的舒尼。",
        },
        objectives = {
            enUS = { "Gnoam Sprecklesprocket" },
            zhCN = { "小型高能发动机" },
        },
        rewards = {
            xp = 5800,
            choices = {
                {
                    id = 7606,
                    count = 1,
                },
                {
                    id = 7607,
                    count = 1,
                },
                {
                    id = 270015,
                    count = 1,
                },
                {
                    id = 270016,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 100,
                },
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 100,
                },
            },
        },
    },
    [166] = {
        name = {
            enUS = "The Defias Brotherhood",
            zhCN = "迪菲亚兄弟会",
        },
        level = 22,
        min = 14,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            map = 1436,
            x = 56.4,
            y = 47.5,
        },
        finish = {
            kind = "npc",
            id = 234,
            name = {
                enUS = "Gryan Stoutmantle",
                zhCN = "格里安·斯托曼",
            },
            x = 56.4,
            y = 47.5,
        },
        before = { 65, 132, 135, 141, 142, 155 },
        summary = {
            enUS = "Kill Edwin VanCleef and bring his head to Gryan Stoutmantle.",
            zhCN = "杀死艾德温·范克里夫，把他的头交给格里安·斯托曼。",
        },
        objectives = {
            enUS = { "Head of VanCleef" },
            zhCN = { "范克里夫的头颅" },
        },
        rewards = {
            xp = 9750,
            choices = {
                {
                    id = 6087,
                    count = 1,
                },
                {
                    id = 2041,
                    count = 1,
                },
                {
                    id = 2042,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 200,
                },
            },
        },
    },
    [373] = {
        name = {
            enUS = "The Unsent Letter",
            zhCN = "未寄出的信",
        },
        level = 22,
        min = 16,
        faction = "A",
        instances = { "deadmines" },
        start = {
            kind = "item",
            id = 2874,
            name = {
                enUS = "An Unsent Letter",
                zhCN = "未寄出的信",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 1646,
            name = {
                enUS = "Baros Alexston",
                zhCN = "巴隆斯·阿历克斯顿",
            },
            map = 1453,
            x = 57.7,
            y = 47.9,
        },
        after = { 391 },
        summary = {
            enUS = "Deliver the Letter to the City Architect to Baros Alexston in Stormwind.",
            zhCN = "将艾德温·范克里夫的信交给巴隆斯·阿历克斯顿。",
        },
        objectives = {
            enUS = { "An Unsent Letter" },
            zhCN = { "未寄出的信" },
        },
        rewards = {
            xp = 3250,
            money = 700,
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 50,
                },
            },
        },
    },
    [7488] = {
        name = {
            enUS = "Lethtendris's Web (7488)",
            zhCN = "蕾瑟塔蒂丝的网",
        },
        level = 57,
        min = 54,
        faction = "A",
        instances = { "dire-maul" },
        sectionSlugs = { "east" },
        start = {
            kind = "npc",
            id = 7877,
            name = {
                enUS = "Latronicus Moonspear",
                zhCN = "拉托尼库斯·月矛",
            },
            map = 1444,
            x = 30.38,
            y = 46.17,
        },
        finish = {
            kind = "npc",
            id = 7877,
            name = {
                enUS = "Latronicus Moonspear",
                zhCN = "拉托尼库斯·月矛",
            },
            map = 1444,
            x = 30.38,
            y = 46.17,
        },
        before = { 7494 },
        summary = {
            enUS = "Bring Lethtendris' Web to Latronicus Moonspear at the Feathermoon Stronghold in Feralas.",
            zhCN = "把蕾瑟塔蒂丝的网交给菲拉斯羽月要塞的拉托尼库斯·月矛。",
        },
        rewards = {
            xp = 7550,
            money = 17000,
            referenceItems = {
                {
                    id = 18491,
                },
            },
        },
    },
    [7489] = {
        name = {
            enUS = "Lethtendris's Web (7489)",
            zhCN = "蕾瑟塔蒂丝的网",
        },
        level = 57,
        min = 54,
        faction = "H",
        instances = { "dire-maul" },
        sectionSlugs = { "east" },
        start = {
            kind = "npc",
            id = 7776,
            name = {
                enUS = "Talo Thornhoof",
                zhCN = "塔罗·刺蹄",
            },
            map = 1444,
            x = 76.18,
            y = 43.83,
        },
        finish = {
            kind = "npc",
            id = 7776,
            name = {
                enUS = "Talo Thornhoof",
                zhCN = "塔罗·刺蹄",
            },
            map = 1444,
            x = 76.18,
            y = 43.83,
        },
        before = { 7492 },
        summary = {
            enUS = "Bring Lethtendris's Web to Talo Thornhoof at Camp Mojache in Feralas.",
            zhCN = "把蕾瑟塔蒂丝的网交给非拉斯莫沙彻营地的塔罗·刺蹄。",
        },
        rewards = {
            xp = 7550,
            money = 17000,
            referenceItems = {
                {
                    id = 18491,
                },
            },
        },
    },
    [7441] = {
        name = {
            enUS = "Pusillin and the Elder Azj'Tordin",
            zhCN = "普希林和埃斯托尔迪",
        },
        level = 58,
        min = 54,
        instances = { "dire-maul" },
        sectionSlugs = { "east" },
        start = {
            kind = "npc",
            id = 14355,
            name = {
                enUS = "Azj'Tordin",
                zhCN = "埃斯托尔迪",
            },
            map = 1444,
            x = 76.91,
            y = 37.35,
        },
        finish = {
            kind = "npc",
            id = 14355,
            name = {
                enUS = "Azj'Tordin",
                zhCN = "埃斯托尔迪",
            },
            map = 1444,
            x = 76.91,
            y = 37.35,
        },
        summary = {
            enUS = "Travel to Dire Maul and locate the Imp, Pusillin. Convince Pusillin to give you Azj'Tordin's Book of Incantations through any...",
            zhCN = "到厄运之槌去找到小鬼普希林。你可以使用任何手段从小鬼那里得到埃斯托尔迪的咒术之书。 找到咒术之书后，回到拉瑞斯小亭的埃斯托尔迪那里。",
        },
        rewards = {
            xp = 7750,
            money = 17500,
            referenceItems = {
                {
                    id = 18411,
                },
                {
                    id = 18410,
                },
            },
        },
    },
    [5527] = {
        name = {
            enUS = "A Reliquary of Purity",
            zhCN = "净化之匣",
        },
        level = 60,
        min = 56,
        instances = { "dire-maul" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 11801,
            name = {
                enUS = "Rabine Saturna",
                zhCN = "拉比恩·萨图纳",
            },
            map = 1450,
            x = 51.69,
            y = 45.1,
        },
        finish = {
            kind = "npc",
            id = 11801,
            name = {
                enUS = "Rabine Saturna",
                zhCN = "拉比恩·萨图纳",
            },
            map = 1450,
            x = 51.69,
            y = 45.1,
        },
        after = { 5526 },
        summary = {
            enUS = "Travel to Silithus and search for a Reliquary of Purity within the ruins of Southwind Village. If you are able to find it, return with it...",
            zhCN = "到希利苏斯的南风村去寻找净化之匣。然后将其交给月光林地永夜港的拉比恩·萨图纳。",
        },
    },
    [7631] = {
        name = {
            enUS = "Dreadsteed of Xoroth",
            zhCN = "克索诺斯恐惧战马",
        },
        level = 60,
        min = 60,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
        start = {
            kind = "npc",
            id = 14436,
            name = {
                enUS = "Mor'zul Bloodbringer",
                zhCN = "莫苏尔·召血者",
            },
            map = 1428,
            x = 12.69,
            y = 31.64,
        },
        finish = {
            kind = "npc",
            id = 14504,
            name = {
                enUS = "Dreadsteed Spirit",
                zhCN = "恐惧战马的灵魂",
            },
        },
        before = { 7562, 7563, 7564, 7623, 7624, 7625, 7629, 7626, 7627, 7628, 7630 },
        summary = {
            enUS = "Read Mor'zul's Instructions. Summon a Xorothian Dreadsteed, defeat it, then bind its spirit to you.",
            zhCN = "阅读莫苏尔的指南，并召唤出一匹克索诺斯恐惧战马，击败它，然后控制它的灵魂。",
        },
    },
    [7481] = {
        name = {
            enUS = "Elven Legends (7481)",
            zhCN = "精灵的传说",
        },
        level = 60,
        min = 54,
        faction = "H",
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
        start = {
            kind = "npc",
            id = 14373,
            name = {
                enUS = "Sage Korolusk",
                zhCN = "先知科鲁拉克",
            },
            map = 1444,
            x = 75.24,
            y = 43.76,
        },
        finish = {
            kind = "npc",
            id = 14373,
            name = {
                enUS = "Sage Korolusk",
                zhCN = "先知科鲁拉克",
            },
            map = 1444,
            x = 75.24,
            y = 43.76,
        },
        summary = {
            enUS = "Search Dire Maul for Kariel Winthalus. Report back to Sage Korolusk at Camp Mojache with whatever information that you may find.",
            zhCN = "到厄运之槌去寻找泰尔米乌斯·探梦者。向莫沙彻营地的先知科鲁拉克报告你所找到的信息。",
        },
    },
    [7482] = {
        name = {
            enUS = "Elven Legends (7482)",
            zhCN = "精灵的传说",
        },
        level = 60,
        min = 54,
        faction = "A",
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
        start = {
            kind = "npc",
            id = 14374,
            name = {
                enUS = "Scholar Runethorn",
                zhCN = "学者卢索恩·纹角",
            },
            map = 1444,
            x = 31.65,
            y = 43.45,
        },
        finish = {
            kind = "npc",
            id = 14374,
            name = {
                enUS = "Scholar Runethorn",
                zhCN = "学者卢索恩·纹角",
            },
            map = 1444,
            x = 31.65,
            y = 43.45,
        },
        after = { 7483, 7484, 7485 },
        summary = {
            enUS = "Search Dire Maul for Kariel Winthalus. Report back to Scholar Runethorn at Feathermoon with whatever information that you may find.",
            zhCN = "到厄运之槌去寻找泰尔米乌斯·探梦者。向羽月要塞的学者卢索恩·纹角报告你所找到的信息。",
        },
    },
    [5525] = {
        name = {
            enUS = "Free Knot! (5525)",
            zhCN = "逃出生天！",
        },
        level = 60,
        min = 57,
        instances = { "dire-maul" },
        sectionSlugs = { "north" },
        start = {
            kind = "npc",
            id = 14338,
            name = {
                enUS = "Knot Thimblejack",
                zhCN = "诺特·希姆加克",
            },
            map = 2557,
            x = 24.7,
            y = 31.7,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 14338,
            name = {
                enUS = "Knot Thimblejack",
                zhCN = "诺特·希姆加克",
            },
        },
        summary = {
            enUS = "Dire Maul Level 60. View quest details and related records.",
            zhCN = "找到戈多克镣铐钥匙，释放诺特·希姆加克。",
        },
        rewards = {
            xp = 6600,
        },
    },
    [5526] = {
        name = {
            enUS = "Shards of the Felvine",
            zhCN = "魔藤碎片",
        },
        level = 60,
        min = 56,
        instances = { "dire-maul" },
        sectionSlugs = { "east" },
        start = {
            kind = "npc",
            id = 11801,
            name = {
                enUS = "Rabine Saturna",
                zhCN = "拉比恩·萨图纳",
            },
            map = 1450,
            x = 51.69,
            y = 45.1,
        },
        finish = {
            kind = "npc",
            id = 11801,
            name = {
                enUS = "Rabine Saturna",
                zhCN = "拉比恩·萨图纳",
            },
            map = 1450,
            x = 51.69,
            y = 45.1,
        },
        before = { 5527 },
        summary = {
            enUS = "Find the Felvine in Dire Maul and acquire a shard from it. Chances are you'll only be able to procure one with the demise of Alzzin the...",
            zhCN = "在厄运之槌中找到魔藤，然后从它上面采集一块碎片。只有干掉了奥兹恩之后，你才能进行采集工作。使用净化之匣安全地封印碎片，然后将其交给月光林地永夜港的拉比恩·萨图纳。",
        },
    },
    [5518] = {
        name = {
            enUS = "The Gordok Ogre Suit (5518)",
            zhCN = "戈多克食人魔装",
        },
        level = 60,
        min = 56,
        instances = { "dire-maul" },
        sectionSlugs = { "north" },
        start = {
            kind = "npc",
            id = 14338,
            name = {
                enUS = "Knot Thimblejack",
                zhCN = "诺特·希姆加克",
            },
            map = 2557,
            x = 24.7,
            y = 31.7,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 14338,
            name = {
                enUS = "Knot Thimblejack",
                zhCN = "诺特·希姆加克",
            },
        },
        summary = {
            enUS = "Bring 4 Bolts of Runecloth, 8 Rugged Leather, 2 Rune Threads, and Ogre Tannin to Knot Thimblejack. He is currently chained inside...",
            zhCN = "把4份符文布卷、8块硬甲皮、2卷符文线和一份食人魔鞣酸交给诺特·希姆加克。他现在被拴在厄运之槌的戈多克食人魔那边。",
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18258,
                },
            },
        },
    },
    [7461] = {
        name = {
            enUS = "The Madness Within",
            zhCN = "伊莫塔尔的疯狂",
        },
        level = 60,
        min = 56,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
        start = {
            kind = "npc",
            id = 14358,
            name = {
                enUS = "Shen'dralar Ancient",
                zhCN = "辛德拉古灵",
            },
            map = 2557,
            x = 31.4,
            y = 76.8,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 14358,
            name = {
                enUS = "Shen'dralar Ancient",
                zhCN = "辛德拉古灵",
            },
        },
        after = { 7462, 7877 },
        summary = {
            enUS = "You must destroy the guardians surrounding the 5 Pylons that power the Prison of Immol'thar. Once the Pylons have powered down, the force...",
            zhCN = "你必须干掉5座水晶塔周围的守卫，那5座水晶塔维持着关押伊莫塔尔的监狱。一旦水晶塔的能量被削弱，伊莫塔尔周围的能量力场就会消散。 进入伊莫塔尔的监狱，干掉站在中间的那个恶魔。最后，在图书馆挑战托塞德林王子。 当任务完成之后，到庭院中去找辛德拉古灵。",
        },
        rewards = {
            xp = 9950,
        },
    },
    [7462] = {
        name = {
            enUS = "The Treasure of the Shen'dralar (7462)",
            zhCN = "辛德拉的宝藏",
        },
        level = 60,
        min = 56,
        faction = "A",
        instances = { "dire-maul" },
        sectionSlugs = { "east", "west", "north" },
        start = {
            kind = "npc",
            id = 14358,
            name = {
                enUS = "Shen'dralar Ancient",
                zhCN = "辛德拉古灵",
            },
            map = 2557,
            x = 31.4,
            y = 76.8,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "object",
            id = 179517,
            name = {
                enUS = "Treasure of the Shen'dralar",
                zhCN = "辛德拉的宝藏",
            },
        },
        before = { 7461 },
        summary = {
            enUS = "Return to the Athenaeum and find the Treasure of the Shen'dralar. Claim your reward!",
            zhCN = "返回图书馆去找到辛德拉的宝藏。拿取你的奖励吧！",
        },
        rewards = {
            xp = 660,
            money = 27000,
            referenceItems = {
                {
                    id = 18420,
                },
                {
                    id = 18421,
                },
                {
                    id = 18424,
                },
            },
        },
    },
    [7877] = {
        name = {
            enUS = "The Treasure of the Shen'dralar (7877)",
            zhCN = "辛德拉的宝藏",
        },
        level = 60,
        min = 56,
        faction = "H",
        instances = { "dire-maul" },
        sectionSlugs = { "east", "west", "north" },
        start = {
            kind = "npc",
            id = 14358,
            name = {
                enUS = "Shen'dralar Ancient",
                zhCN = "辛德拉古灵",
            },
            map = 2557,
            x = 31.4,
            y = 76.8,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "object",
            id = 179517,
            name = {
                enUS = "Treasure of the Shen'dralar",
                zhCN = "辛德拉的宝藏",
            },
        },
        before = { 7461 },
        summary = {
            enUS = "Return to the Athenaeum and find the Treasure of the Shen'dralar. Claim your reward!",
            zhCN = "返回图书馆去找到辛德拉的宝藏。拿取你的奖励吧！",
        },
        rewards = {
            xp = 660,
            money = 27000,
            referenceItems = {
                {
                    id = 18420,
                },
                {
                    id = 18421,
                },
                {
                    id = 18424,
                },
            },
        },
    },
    [7703] = {
        name = {
            enUS = "Unfinished Gordok Business (7703)",
            zhCN = "戈多克食人魔的事务",
        },
        level = 60,
        min = 56,
        instances = { "dire-maul" },
        sectionSlugs = { "north" },
        start = {
            kind = "npc",
            id = 14325,
            name = {
                enUS = "Captain Kromcrush",
                zhCN = "克罗卡斯",
            },
            map = 2557,
            x = 26.9,
            y = 28,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 14325,
            name = {
                enUS = "Captain Kromcrush",
                zhCN = "克罗卡斯",
            },
        },
        summary = {
            enUS = "Find the Gauntlet of Gordok Might and return it to Captain Kromcrush in Dire Maul. According to Kromcrush, the \"old timey...",
            zhCN = "找到戈多克力量护手，并将它交给厄运之槌的克罗卡斯。 根据克罗卡斯所说的，“传说”自称是王子的精灵托塞德林从一名戈多克食人魔手中偷走了那件神器。",
        },
    },
    [7503] = {
        name = {
            enUS = "The Greatest Race of Hunters",
            zhCN = "最伟大的猎手",
        },
        level = 60,
        min = 54,
        instances = { "dire-maul" },
        sectionSlugs = { "east", "west", "north" },
        start = {
            kind = "item",
            id = 18361,
            name = {
                enUS = "The Greatest Race of Hunters",
                zhCN = "最伟大的猎手",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 14382,
            name = {
                enUS = "Lorekeeper Mykos",
                zhCN = "博学者麦库斯",
            },
        },
        summary = {
            enUS = "Return the book to its rightful owners.",
            zhCN = "将这本典籍交给它的主人。",
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18473,
                },
            },
        },
    },
    [2922] = {
        name = {
            enUS = "Save Techbot's Brain!",
            zhCN = "拯救尖端机器人！",
        },
        level = 26,
        min = 20,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 7944,
            name = {
                enUS = "Tinkmaster Overspark",
                zhCN = "工匠大师欧沃斯巴克",
            },
            map = 1455,
            x = 69.55,
            y = 50.33,
        },
        finish = {
            kind = "npc",
            id = 7944,
            name = {
                enUS = "Tinkmaster Overspark",
                zhCN = "工匠大师欧沃斯巴克",
            },
            map = 1455,
            x = 69.55,
            y = 50.33,
        },
        before = { 2923 },
        summary = {
            enUS = "Bring Techbot's Memory Core to Tinkmaster Overspark in Ironforge.",
            zhCN = "将尖端机器人的存储器核心交给铁炉堡的工匠大师欧沃斯巴克。",
        },
        objectives = {
            enUS = { "Techbot's Memory Core" },
            zhCN = { "尖端机器人的存储器核心" },
        },
        rewards = {
            xp = 6900,
            money = 2000,
            reputation = {
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 150,
                },
            },
        },
    },
    [2923] = {
        name = {
            enUS = "Tinkmaster Overspark",
            zhCN = "工匠大师欧沃斯巴克",
        },
        level = 26,
        min = 20,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            name = {
                enUS = "Brother Sarno",
                zhCN = "萨尔努修士",
            },
            map = 1453,
        },
        finish = {
            kind = "npc",
            name = {
                enUS = "Tinkmaster Overspark",
                zhCN = "工匠大师欧沃斯巴克",
            },
        },
        after = { 2922 },
        summary = {
            enUS = "Speak with Tinkmaster Overspark in Ironforge.",
            zhCN = "与铁炉堡的工匠大师欧沃斯巴克谈一谈。",
        },
        rewards = {
            xp = 210,
            reputation = {
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 25,
                },
            },
        },
    },
    [2926] = {
        name = {
            enUS = "Gnogaine",
            zhCN = "诺恩",
        },
        level = 27,
        min = 20,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 1268,
            name = {
                enUS = "Ozzie Togglevolt",
                zhCN = "奥齐·电环",
            },
            map = 1426,
            x = 45.89,
            y = 49.39,
        },
        finish = {
            kind = "npc",
            id = 1268,
            name = {
                enUS = "Ozzie Togglevolt",
                zhCN = "奥齐·电环",
            },
            map = 1426,
            x = 45.89,
            y = 49.39,
        },
        before = { 2927 },
        after = { 2962 },
        summary = {
            enUS = "Use the Empty Leaden Collection Phial on Irradiated Invaders or Irradiated Pillagers to collect radioactive fallout. Once it is full, take it back to Ozzie Togglevolt in Kharanos.",
            zhCN = "用空铅瓶对着辐射入侵者或者辐射抢劫者，从它们身上收集放射尘。瓶子装满之后，把它交给卡拉诺斯的奥齐·电环。",
        },
        objectives = {
            enUS = { "Full Leaden Collection Phial" },
            zhCN = { "装满的铅瓶" },
        },
        rewards = {
            xp = 5700,
            money = 2200,
            reputation = {
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 100,
                },
            },
        },
    },
    [2927] = {
        name = {
            enUS = "The Day After",
            zhCN = "灾难之后",
        },
        level = 27,
        min = 20,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 6569,
            name = {
                enUS = "Gnoarn",
                zhCN = "诺恩",
            },
            map = 1426,
            x = 69.18,
            y = 50.55,
        },
        finish = {
            kind = "npc",
            id = 1268,
            name = {
                enUS = "Ozzie Togglevolt",
                zhCN = "奥齐·电环",
            },
            map = 1426,
            x = 45.89,
            y = 49.39,
        },
        after = { 2926, 2962 },
        summary = {
            enUS = "Speak with Ozzie Togglevolt in Kharanos.",
            zhCN = "与卡拉诺斯的奥齐·电环谈一谈。",
        },
        rewards = {
            xp = 220,
            reputation = {
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 10,
                },
            },
        },
    },
    [2904] = {
        name = {
            enUS = "A Fine Mess",
            zhCN = "一团混乱",
        },
        level = 30,
        min = 24,
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 7850,
            name = {
                enUS = "Kernobee",
                zhCN = "克努比",
            },
            map = 721,
            x = 71.5,
            y = 58.8,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 7853,
            name = {
                enUS = "Scooty",
                zhCN = "斯库提",
            },
            map = 1434,
            x = 27.6,
            y = 77.48,
        },
        summary = {
            enUS = "Escort Kernobee to the Clockwerk Run exit and then report to Scooty in Booty Bay.",
            zhCN = "将克努比护送到出口，然后向藏宝海湾的斯库提汇报。",
        },
        rewards = {
            xp = 9200,
            choices = {
                {
                    id = 9535,
                    count = 1,
                },
                {
                    id = 9536,
                    count = 1,
                },
                {
                    id = 270042,
                    count = 1,
                },
            },
        },
    },
    [2930] = {
        name = {
            enUS = "Data Rescue",
            zhCN = "抢救数据",
        },
        level = 30,
        min = 25,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 7950,
            name = {
                enUS = "Master Mechanic Castpipe",
                zhCN = "大机械师卡斯派普",
            },
            map = 1455,
            x = 69.83,
            y = 48.1,
        },
        finish = {
            kind = "npc",
            id = 7950,
            name = {
                enUS = "Master Mechanic Castpipe",
                zhCN = "大机械师卡斯派普",
            },
            map = 1455,
            x = 69.83,
            y = 48.1,
        },
        before = { 2931 },
        summary = {
            enUS = "Bring a Prismatic Punch Card to Master Mechanic Castpipe in Ironforge.",
            zhCN = "将彩色穿孔卡片交给铁炉堡的大机械师卡斯派普。",
        },
        rewards = {
            xp = 3650,
            money = 2500,
            referenceItems = {
                {
                    id = 9605,
                },
                {
                    id = 9604,
                },
            },
        },
    },
    [2924] = {
        name = {
            enUS = "Essential Artificials",
            zhCN = "基础模组",
        },
        level = 30,
        min = 24,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 6169,
            name = {
                enUS = "Klockmort Spannerspan",
                zhCN = "科罗莫特·钢尺",
            },
            map = 1455,
            x = 67.92,
            y = 46.1,
        },
        finish = {
            kind = "npc",
            id = 6169,
            name = {
                enUS = "Klockmort Spannerspan",
                zhCN = "科罗莫特·钢尺",
            },
            map = 1455,
            x = 67.92,
            y = 46.1,
        },
        before = { 2925 },
        summary = {
            enUS = "Bring 12 Essential Artificials to Klockmort Spannerspan in Ironforge.",
            zhCN = "收集12个基础模组，把它们交给铁炉堡的科劳莫特·钢尺。",
        },
        rewards = {
            xp = 3050,
            money = 5500,
        },
    },
    [2928] = {
        name = {
            enUS = "Gyrodrillmatic Excavationators",
            zhCN = "陀螺式挖掘机",
        },
        level = 30,
        min = 20,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 6579,
            name = {
                enUS = "Shoni the Shilent",
                zhCN = "沉默的舒尼",
            },
            map = 1453,
            x = 62.7,
            y = 34.2,
        },
        finish = {
            kind = "npc",
            id = 6579,
            name = {
                enUS = "Shoni the Shilent",
                zhCN = "沉默的舒尼",
            },
            map = 1453,
            x = 62.7,
            y = 34.2,
        },
        summary = {
            enUS = "Bring twenty-four Robo-mechanical Guts to Shoni in Stormwind.",
            zhCN = "收集24副机械内胆，把它们交给暴风城的舒尼。",
        },
        objectives = {
            enUS = { "Robo-mechanical Guts ×24" },
            zhCN = { "机械内胆 ×24" },
        },
        rewards = {
            xp = 6350,
            choices = {
                {
                    id = 9608,
                    count = 1,
                },
                {
                    id = 9609,
                    count = 1,
                },
                {
                    id = 270045,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 100,
                },
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 100,
                },
            },
        },
    },
    [2962] = {
        name = {
            enUS = "The Only Cure is More Green Glow",
            zhCN = "更多的辐射尘！",
        },
        level = 30,
        min = 20,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 1268,
            name = {
                enUS = "Ozzie Togglevolt",
                zhCN = "奥齐·电环",
            },
            map = 1426,
            x = 45.89,
            y = 49.39,
        },
        finish = {
            kind = "npc",
            id = 1268,
            name = {
                enUS = "Ozzie Togglevolt",
                zhCN = "奥齐·电环",
            },
            map = 1426,
            x = 45.89,
            y = 49.39,
        },
        before = { 2927, 2926 },
        summary = {
            enUS = "Travel to Gnomeregan and bring back High Potency Radioactive Fallout. Be warned, the fallout is unstable and will collapse...",
            zhCN = "到诺莫瑞根去收集高强度辐射尘。要多加小心，这种辐射尘非常不稳定，很快就会分解。 奥齐要求你把沉重的铅瓶也交给他。",
        },
        rewards = {
            xp = 2450,
            money = 2500,
        },
    },
    [2945] = {
        name = {
            enUS = "Grime-Encrusted Ring",
            zhCN = "脏兮兮的戒指",
        },
        level = 34,
        min = 28,
        instances = { "gnomeregan" },
        start = {
            kind = "item",
            id = 9326,
            name = {
                enUS = "Grime-Encrusted Ring",
                zhCN = "脏兮兮的戒指",
            },
        },
        inside = true,
        finish = {
            kind = "object",
            id = 142487,
            name = {
                enUS = "The Sparklematic 5200",
                zhCN = "超级清洁器5200型",
            },
        },
        after = { 2947, 2949 },
        summary = {
            enUS = "Figure out a way to remove the grime from the Grime-Encrusted Ring.",
            zhCN = "想方法把脏兮兮的戒指弄干净。",
        },
        rewards = {
            xp = 2700,
            money = 300,
        },
    },
    [2947] = {
        name = {
            enUS = "Return of the Ring (2947)",
            zhCN = "戒指归来",
        },
        level = 34,
        min = 28,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "object",
            id = 142487,
            name = {
                enUS = "The Sparklematic 5200",
                zhCN = "超级清洁器5200型",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        before = { 2945 },
        after = { 2948 },
        summary = {
            enUS = "You may either keep the ring, or you may find the person responsible for the imprint and engravings on the inside of the band.",
            zhCN = "你要么自己留着这枚戒指，要么就按照戒指内侧刻着的名字找到它的主人。",
        },
        rewards = {
            xp = 2700,
        },
    },
    [2949] = {
        name = {
            enUS = "Return of the Ring (2949)",
            zhCN = "戒指归来",
        },
        level = 34,
        min = 28,
        faction = "H",
        instances = { "gnomeregan" },
        start = {
            kind = "object",
            id = 142487,
            name = {
                enUS = "The Sparklematic 5200",
                zhCN = "超级清洁器5200型",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 3412,
            name = {
                enUS = "Nogg",
                zhCN = "诺格",
            },
            map = 1454,
            x = 75.99,
            y = 25.41,
        },
        before = { 2945 },
        after = { 2950 },
        summary = {
            enUS = "You may either keep the ring, or you may find the person responsible for the imprint and engravings on the inside of the band.",
            zhCN = "你要么自己留着这枚戒指，要么就按照戒指内侧刻着的名字找到它的主人。",
        },
        rewards = {
            xp = 2700,
        },
    },
    [2842] = {
        name = {
            enUS = "Chief Engineer Scooty",
            zhCN = "主工程师斯库提",
        },
        level = 35,
        min = 20,
        faction = "H",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            name = {
                enUS = "Sovik",
                zhCN = "索维克",
            },
            map = 1454,
        },
        finish = {
            kind = "npc",
            name = {
                enUS = "Scooty",
                zhCN = "斯库提",
            },
        },
        after = { 2843 },
        summary = {
            enUS = "Speak with Scooty in Booty Bay.",
            zhCN = "和藏宝海湾的斯库提谈一谈。",
        },
        rewards = {
            xp = 280,
        },
    },
    [2948] = {
        name = {
            enUS = "Gnome Improvement",
            zhCN = "侏儒的手艺",
        },
        level = 35,
        min = 28,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        finish = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        summary = {
            enUS = "Bring the Brilliant Gold Ring, a Silver Bar, a Moss Agate, and 30 silver coins to Talvash del Kissel in Ironforge.",
            zhCN = "将闪亮的金戒指、1块银锭、1块绿玛瑙和30个银币交给铁炉堡的塔瓦斯德·基瑟尔。",
        },
    },
    [2843] = {
        name = {
            enUS = "Gnomer-gooooone!",
            zhCN = "出发！诺莫瑞根！",
        },
        level = 35,
        min = 20,
        faction = "H",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 7853,
            name = {
                enUS = "Scooty",
                zhCN = "斯库提",
            },
            map = 1434,
            x = 27.6,
            y = 77.48,
        },
        finish = {
            kind = "npc",
            id = 7853,
            name = {
                enUS = "Scooty",
                zhCN = "斯库提",
            },
            map = 1434,
            x = 27.6,
            y = 77.48,
        },
        before = { 2842 },
        summary = {
            enUS = "Wait for Scooty to calibrate the Goblin Transponder.",
            zhCN = "等斯库提调整好地精传送器。",
        },
        rewards = {
            items = {
                {
                    id = 9173,
                    count = 1,
                },
            },
        },
    },
    [2950] = {
        name = {
            enUS = "Nogg's Ring Redo",
            zhCN = "诺格的手艺",
        },
        level = 35,
        min = 28,
        faction = "H",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 3412,
            name = {
                enUS = "Nogg",
                zhCN = "诺格",
            },
            map = 1454,
            x = 75.99,
            y = 25.41,
        },
        finish = {
            kind = "npc",
            id = 3412,
            name = {
                enUS = "Nogg",
                zhCN = "诺格",
            },
            map = 1454,
            x = 75.99,
            y = 25.41,
        },
        summary = {
            enUS = "Bring the Brilliant Gold Ring, a Silver Bar, a Moss Agate, and 30 silver coins to Nogg in Orgrimmar.",
            zhCN = "将闪亮的金戒指、1块银锭、1块绿玛瑙和30个银币交给奥格瑞玛的诺格。",
        },
    },
    [2841] = {
        name = {
            enUS = "Rig Wars",
            zhCN = "设备之战",
        },
        level = 35,
        min = 25,
        faction = "H",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 3412,
            name = {
                enUS = "Nogg",
                zhCN = "诺格",
            },
            map = 1454,
            x = 75.99,
            y = 25.41,
        },
        finish = {
            kind = "npc",
            id = 3412,
            name = {
                enUS = "Nogg",
                zhCN = "诺格",
            },
            map = 1454,
            x = 75.99,
            y = 25.41,
        },
        summary = {
            enUS = "Retrieve the Rig Blueprints and Thermaplugg's Safe Combination from Gnomeregan and bring them to Nogg in Orgrimmar.",
            zhCN = "从诺莫瑞根拿到钻探设备蓝图和麦克尼尔的保险箱密码，把它们交给奥格瑞玛的诺格。",
        },
        rewards = {
            xp = 2750,
            referenceItems = {
                {
                    id = 9623,
                },
                {
                    id = 9624,
                },
                {
                    id = 9625,
                },
            },
        },
    },
    [2929] = {
        name = {
            enUS = "The Grand Betrayal",
            zhCN = "大叛徒",
        },
        level = 35,
        min = 25,
        faction = "A",
        instances = { "gnomeregan" },
        start = {
            kind = "npc",
            id = 7937,
            name = {
                enUS = "High Tinker Mekkatorque",
                zhCN = "大工匠梅卡托克",
            },
            map = 1455,
            x = 68.75,
            y = 48.97,
        },
        finish = {
            kind = "npc",
            id = 7937,
            name = {
                enUS = "High Tinker Mekkatorque",
                zhCN = "大工匠梅卡托克",
            },
            map = 1455,
            x = 68.75,
            y = 48.97,
        },
        summary = {
            enUS = "Venture to Gnomeregan and kill Mekgineer Thermaplugg. Return to High Tinker Mekkatorque when the task is complete.",
            zhCN = "到诺莫瑞根去杀掉麦克尼尔·瑟玛普拉格。完成任务之后向大工匠梅卡托克报告。",
        },
        rewards = {
            xp = 2750,
            money = 3500,
            referenceItems = {
                {
                    id = 9623,
                },
                {
                    id = 9624,
                },
                {
                    id = 9625,
                },
            },
        },
    },
    [96395] = {
        name = {
            enUS = "An Ancient Grudge",
            zhCN = "远古宿怨",
        },
        level = 15,
        min = 10,
        instances = { "hall-of-thanes" },
        start = {
            kind = "npc",
            name = {
                enUS = "Ghostly Attendant",
                zhCN = "幽灵侍从",
            },
        },
        inside = true,
        summary = {
            enUS = "Put the spirit of Faldrim Anvilmar to rest in the Hall of Thanes.",
            zhCN = "让领主大厅中的法德林·安威玛尔之魂安息。",
        },
        objectives = {
            enUS = { "Faldrim Anvilmar" },
            zhCN = { "法德林·安威玛尔" },
        },
        rewards = {
            xp = 3550,
            choices = {
                {
                    id = 279899,
                    count = 1,
                },
                {
                    id = 279900,
                    count = 1,
                },
            },
        },
    },
    [96403] = {
        name = {
            enUS = "Important Heirlooms",
            zhCN = "重要的传家宝",
        },
        level = 15,
        min = 10,
        instances = { "hall-of-thanes" },
        start = {
            kind = "npc",
            id = 265003,
            name = {
                enUS = "Thom Filch",
                zhCN = "托姆·菲尔奇",
            },
            map = 1455,
            x = 32.4,
            y = 44.8,
        },
        finish = {
            kind = "npc",
            id = 265003,
            name = {
                enUS = "Thom Filch",
                zhCN = "托姆·菲尔奇",
            },
            x = 32.4,
            y = 44.8,
        },
        summary = {
            enUS = "Collect 8 Dwarven Heirlooms from the Hall of Thanes.",
            zhCN = "在领主大厅收集8件矮人传家宝。",
        },
        objectives = {
            enUS = { "Dwarven Heirloom ×8" },
            zhCN = { "矮人传家宝 ×8" },
        },
        rewards = {
            xp = 4600,
            money = 700,
            choices = {
                {
                    id = 279898,
                    count = 1,
                },
                {
                    id = 280096,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Gadgetzan",
                        zhCN = "加基森",
                    },
                    value = 100,
                },
            },
        },
    },
    [96394] = {
        name = {
            enUS = "The Restless Dead",
            zhCN = "不安的亡者",
        },
        level = 15,
        min = 10,
        faction = "A",
        instances = { "hall-of-thanes" },
        start = {
            kind = "npc",
            id = 264943,
            name = {
                enUS = "Afadra Dunwall",
                zhCN = "阿法德拉·邓沃尔",
            },
            map = 1455,
            x = 33.2,
            y = 47.6,
        },
        finish = {
            kind = "npc",
            id = 264943,
            name = {
                enUS = "Afadra Dunwall",
                zhCN = "阿法德拉·邓沃尔",
            },
            x = 33.2,
            y = 47.6,
        },
        summary = {
            enUS = "Kill 15 Enraged Apparitions, 10 Tormented Souls and put the spirit of Anvilmar to rest.",
            zhCN = "消灭15个狂怒的幽灵和10个受折磨的灵魂，并让安威玛尔之魂安息。",
        },
        objectives = {
            enUS = { "Enraged Apparition ×15", "Tormented Soul ×10" },
            zhCN = { "狂怒的幽灵 ×15", "受折磨的灵魂 ×10" },
        },
        rewards = {
            xp = 3550,
            money = 700,
            choices = {
                {
                    id = 279897,
                    count = 1,
                },
                {
                    id = 280095,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Ironforge",
                        zhCN = "铁炉堡",
                    },
                    value = 100,
                },
            },
        },
    },
    [96393] = {
        name = {
            enUS = "Old Ironforge Incursion",
            zhCN = "突袭旧铁炉堡",
        },
        level = 16,
        min = 9,
        faction = "A",
        instances = { "hall-of-thanes" },
        start = {
            kind = "npc",
            id = 264936,
            name = {
                enUS = "Earthseer Farsen",
                zhCN = "大地先知法森",
            },
            map = 1426,
            x = 64.8,
            y = 58.5,
        },
        finish = {
            kind = "npc",
            id = 2784,
            name = {
                enUS = "King Magni Bronzebeard",
                zhCN = "国王麦格尼·铜须",
            },
            map = 1455,
            x = 39.09,
            y = 56.2,
        },
        before = { 96391 },
        summary = {
            enUS = "Enter the Hall of Thanes beneath Old Ironforge and claim the Head of Durgen Dirgehammer.",
            zhCN = "进入旧铁炉堡下方的领主大厅，夺取杜根·挽锤的头颅。",
        },
        objectives = {
            enUS = { "Durgen Dirgehammer's Head" },
            zhCN = { "杜根·挽锤的头颅" },
        },
        rewards = {
            xp = 4950,
            money = 800,
            choices = {
                {
                    id = 279894,
                    count = 1,
                },
                {
                    id = 279895,
                    count = 1,
                },
                {
                    id = 279896,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Ironforge",
                        zhCN = "铁炉堡",
                    },
                    value = 100,
                },
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 100,
                },
            },
        },
    },
    [98423] = {
        name = {
            enUS = "The Treaty of Understanding",
            zhCN = "谅解条约",
        },
        level = 16,
        min = 9,
        faction = "A",
        instances = { "hall-of-thanes" },
        start = {
            kind = "item",
            id = 281030,
            name = {
                enUS = "Treaty of Understanding",
                zhCN = "谅解条约",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 2784,
            name = {
                enUS = "King Magni Bronzebeard",
                zhCN = "国王麦格尼·铜须",
            },
            map = 1455,
            x = 39.09,
            y = 56.2,
        },
        summary = {
            enUS = "Bring the Treaty of Understanding to King Magni Bronzebeard in Ironforge.",
            zhCN = "把谅解条约交给铁炉堡的国王麦格尼·铜须。",
        },
        rewards = {
            xp = 3900,
            money = 1600,
            reputation = {
                {
                    name = {
                        enUS = "Ironforge",
                        zhCN = "铁炉堡",
                    },
                    value = 100,
                },
                {
                    name = {
                        enUS = "Gnomeregan Exiles",
                        zhCN = "诺莫瑞根流亡者",
                    },
                    value = 100,
                },
            },
        },
    },
    [7068] = {
        name = {
            enUS = "Shadowshard Fragments (7068)",
            zhCN = "暗影残片",
        },
        level = 42,
        min = 38,
        faction = "H",
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 7311,
            name = {
                enUS = "Uthel'nay",
                zhCN = "尤塞尔奈",
            },
            map = 1454,
            x = 39.16,
            y = 86.27,
        },
        finish = {
            kind = "npc",
            id = 7311,
            name = {
                enUS = "Uthel'nay",
                zhCN = "尤塞尔奈",
            },
            map = 1454,
            x = 39.16,
            y = 86.27,
        },
        summary = {
            enUS = "Collect 10 Shadowshard Fragments from Maraudon and return them to Uthel'nay in Orgrimmar.",
            zhCN = "从玛拉顿收集10块暗影残片，然后把它们交给奥格瑞玛的尤塞尔奈。",
        },
        rewards = {
            xp = 3450,
            referenceItems = {
                {
                    id = 17772,
                },
                {
                    id = 17773,
                },
            },
        },
    },
    [7070] = {
        name = {
            enUS = "Shadowshard Fragments (7070)",
            zhCN = "暗影残片",
        },
        level = 42,
        min = 38,
        faction = "A",
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 4967,
            name = {
                enUS = "Archmage Tervosh",
                zhCN = "大法师特沃什",
            },
            map = 1445,
            x = 45.2,
            y = 24.4,
        },
        finish = {
            kind = "npc",
            id = 4967,
            name = {
                enUS = "Archmage Tervosh",
                zhCN = "大法师特沃什",
            },
            map = 1445,
            x = 45.2,
            y = 24.4,
        },
        summary = {
            enUS = "Collect 10 Shadowshard Fragments from Maraudon and return them to Archmage Tervosh in Theramore on the coast of Dustwallow Marsh.",
            zhCN = "从玛拉顿收集10块暗影残片，然后把它们交给尘泥沼泽塞拉摩岛上的大法师特沃什。",
        },
        rewards = {
            xp = 3450,
            referenceItems = {
                {
                    id = 17772,
                },
                {
                    id = 17773,
                },
            },
        },
    },
    [7028] = {
        name = {
            enUS = "Twisted Evils",
            zhCN = "扭曲的邪恶",
        },
        level = 47,
        min = 41,
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 13656,
            name = {
                enUS = "Willow",
                zhCN = "维洛",
            },
            map = 1443,
            x = 62.2,
            y = 39.63,
        },
        finish = {
            kind = "npc",
            id = 13656,
            name = {
                enUS = "Willow",
                zhCN = "维洛",
            },
            map = 1443,
            x = 62.2,
            y = 39.63,
        },
        summary = {
            enUS = "Collect 15 Theradric Crystal Carvings for Willow in Desolace.",
            zhCN = "为凄凉之地的维洛收集25个瑟莱德丝水晶雕像。",
        },
        rewards = {
            xp = 5250,
            referenceItems = {
                {
                    id = 17775,
                },
                {
                    id = 17776,
                },
                {
                    id = 17777,
                },
                {
                    id = 17779,
                },
            },
        },
    },
    [7029] = {
        name = {
            enUS = "Vyletongue Corruption (7029)",
            zhCN = "维利塔恩的污染",
        },
        level = 47,
        min = 41,
        faction = "H",
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 11823,
            name = {
                enUS = "Vark Battlescar",
                zhCN = "瓦克·战痕",
            },
            map = 1443,
            x = 23.22,
            y = 70.33,
        },
        finish = {
            kind = "npc",
            id = 11823,
            name = {
                enUS = "Vark Battlescar",
                zhCN = "瓦克·战痕",
            },
            map = 1443,
            x = 23.22,
            y = 70.33,
        },
        summary = {
            enUS = "Fill the Coated Cerulean Vial at the orange crystal pool in Maraudon. Use the Filled Cerulean Vial on the Vylestem Vines to force...",
            zhCN = "在玛拉顿里用天蓝水瓶在橙色水晶池中装满水。 在维利斯塔姆藤蔓上使用装满水的天蓝水瓶，使堕落的诺克赛恩幼体出现。 治疗8株植物并杀死那些诺克赛恩幼体，然后向葬影村的瓦克·战痕复命。",
        },
        rewards = {
            xp = 5250,
            referenceItems = {
                {
                    id = 17768,
                },
                {
                    id = 17778,
                },
                {
                    id = 17770,
                },
            },
        },
    },
    [7041] = {
        name = {
            enUS = "Vyletongue Corruption (7041)",
            zhCN = "维利塔恩的污染",
        },
        level = 47,
        min = 41,
        faction = "A",
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 11715,
            name = {
                enUS = "Talendria",
                zhCN = "塔琳德莉亚",
            },
            map = 1443,
            x = 68.5,
            y = 8.88,
        },
        finish = {
            kind = "npc",
            id = 11715,
            name = {
                enUS = "Talendria",
                zhCN = "塔琳德莉亚",
            },
            map = 1443,
            x = 68.5,
            y = 8.88,
        },
        summary = {
            enUS = "Fill the Coated Cerulean Vial at the orange crystal pool in Maraudon. Use the Filled Cerulean Vial on the Vylestem Vines to force...",
            zhCN = "在玛拉顿里用天蓝水瓶在橙色水晶池中装满水。 在维利斯塔姆藤蔓上使用装满水的天蓝水瓶，使堕落的诺克赛恩幼体出现。 治疗8株植物并杀死那些诺克赛恩幼体，然后向尼耶尔前哨站的塔琳德莉亚复命。",
        },
        rewards = {
            xp = 5250,
            referenceItems = {
                {
                    id = 17768,
                },
                {
                    id = 17778,
                },
                {
                    id = 17770,
                },
            },
        },
    },
    [7067] = {
        name = {
            enUS = "The Pariah's Instructions",
            zhCN = "贱民的指引",
        },
        level = 48,
        min = 39,
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 13717,
            name = {
                enUS = "Centaur Pariah",
                zhCN = "半人马贱民",
            },
            map = 1443,
            x = 43.4,
            y = 84.8,
        },
        finish = {
            kind = "npc",
            id = 13717,
            name = {
                enUS = "Centaur Pariah",
                zhCN = "半人马贱民",
            },
            map = 1443,
            x = 43.4,
            y = 84.8,
        },
        summary = {
            enUS = "Read the Pariah's Instructions. Afterwards, obtain the Amulet of Union from Maraudon and return it to the Centaur Pariah in southern...",
            zhCN = "阅读贱民的指引，然后从玛拉顿得到联合坠饰，将其交给凄凉之地南部的半人马贱民。",
        },
        rewards = {
            xp = 5450,
            money = 14000,
            referenceItems = {
                {
                    id = 17774,
                },
            },
        },
    },
    [7044] = {
        name = {
            enUS = "Legends of Maraudon",
            zhCN = "玛拉顿的传说",
        },
        level = 49,
        min = 41,
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 13697,
            name = {
                enUS = "Cavindra",
                zhCN = "凯雯德拉",
            },
            map = 1443,
            x = 32.1,
            y = 63.96,
        },
        finish = {
            kind = "npc",
            id = 13716,
            name = {
                enUS = "Celebras the Redeemed",
                zhCN = "赎罪的塞雷布拉斯",
            },
        },
        after = { 7046 },
        summary = {
            enUS = "Recover the two parts of the Scepter of Celebras: the Celebrian Rod and the Celebrian Diamond. Find a way to speak with Celebras.",
            zhCN = "找回塞雷布拉斯节杖的两个部分：塞雷布拉斯魔棒和塞雷布拉斯钻石。 然后设法和塞雷布拉斯对话。",
        },
        rewards = {
            xp = 3400,
        },
    },
    [7064] = {
        name = {
            enUS = "Corruption of Earth and Seed (7064)",
            zhCN = "大地的污染",
        },
        level = 51,
        min = 45,
        faction = "H",
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 13699,
            name = {
                enUS = "Selendra",
                zhCN = "瑟琳德拉",
            },
            map = 1443,
            x = 26.87,
            y = 77.67,
        },
        finish = {
            kind = "npc",
            id = 13699,
            name = {
                enUS = "Selendra",
                zhCN = "瑟琳德拉",
            },
            map = 1443,
            x = 26.87,
            y = 77.67,
        },
        summary = {
            enUS = "Slay Princess Theradras and return to Selendra near Shadowprey Village in Desolace.",
            zhCN = "杀死瑟莱德丝公主，然后回到凄凉之地葬影村附近的瑟琳德拉那里复命。",
        },
        rewards = {
            xp = 6100,
            referenceItems = {
                {
                    id = 17705,
                },
                {
                    id = 17743,
                },
                {
                    id = 17753,
                },
            },
        },
    },
    [7065] = {
        name = {
            enUS = "Corruption of Earth and Seed (7065)",
            zhCN = "大地的污染",
        },
        level = 51,
        min = 45,
        faction = "A",
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 13698,
            name = {
                enUS = "Keeper Marandis",
                zhCN = "守护者玛兰迪斯",
            },
            map = 1443,
            x = 63.83,
            y = 10.67,
        },
        finish = {
            kind = "npc",
            id = 13698,
            name = {
                enUS = "Keeper Marandis",
                zhCN = "守护者玛兰迪斯",
            },
            map = 1443,
            x = 63.83,
            y = 10.67,
        },
        summary = {
            enUS = "Slay Princess Theradras and return to Keeper Marandis at Nijel's Point in Desolace.",
            zhCN = "杀死瑟莱德丝公主，然后回到凄凉之地尼耶尔前哨站的守护者玛兰迪斯那里复命。",
        },
        rewards = {
            xp = 6100,
            referenceItems = {
                {
                    id = 17705,
                },
                {
                    id = 17743,
                },
                {
                    id = 17753,
                },
            },
        },
    },
    [7066] = {
        name = {
            enUS = "Seed of Life",
            zhCN = "生命之种",
        },
        level = 51,
        min = 45,
        instances = { "maraudon" },
        start = {
            kind = "npc",
            id = 12238,
            name = {
                enUS = "Zaetar's Spirit",
                zhCN = "扎尔塔的灵魂",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 11832,
            name = {
                enUS = "Keeper Remulos",
                zhCN = "守护者雷姆洛斯",
            },
            map = 1450,
            x = 36.18,
            y = 41.79,
        },
        summary = {
            enUS = "Seek out Remulos in Moonglade and give him the Seed of Life.",
            zhCN = "到月光林地去找到雷姆洛斯，将生命之种交给他。",
        },
        rewards = {
            xp = 6100,
            money = 15000,
        },
    },
    [5726] = {
        name = {
            enUS = "Hidden Enemies (5726)",
            zhCN = "隐藏的敌人",
        },
        level = 12,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        finish = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        after = { 5728 },
        summary = {
            enUS = "Bring a Lieutenant's Insignia to Thrall in Orgrimmar.",
            zhCN = "将军官的徽章交给奥格瑞玛的萨尔。",
        },
    },
    [5727] = {
        name = {
            enUS = "Hidden Enemies (5727)",
            zhCN = "隐藏的敌人",
        },
        level = 12,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        finish = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        summary = {
            enUS = "Take the Lieutenant's Insignia to Neeru Fireblade and speak to him. Gauge if he believes you are a member of the Burning Blade and then...",
            zhCN = "将军官的徽章交给尼尔鲁·火刃并与他谈一谈，看看他是否相信你是火刃氏族中的一员，然后回到奥格瑞玛的萨尔那里。",
        },
    },
    [5729] = {
        name = {
            enUS = "Hidden Enemies (5729)",
            zhCN = "隐藏的敌人",
        },
        level = 15,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        finish = {
            kind = "npc",
            id = 3216,
            name = {
                enUS = "Neeru Fireblade",
                zhCN = "尼尔鲁·火刃",
            },
            map = 1454,
            x = 49.47,
            y = 50.59,
        },
        summary = {
            enUS = "Speak to Neeru Fireblade in Orgrimmar.",
            zhCN = "与奥格瑞玛的尼尔鲁·火刃谈一谈。",
        },
    },
    [5723] = {
        name = {
            enUS = "Testing an Enemy's Strength",
            zhCN = "试探敌人",
        },
        level = 15,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 11833,
            name = {
                enUS = "Rahauro",
                zhCN = "拉哈罗",
            },
            map = 1456,
            x = 70.14,
            y = 29.52,
        },
        finish = {
            kind = "npc",
            id = 11833,
            name = {
                enUS = "Rahauro",
                zhCN = "拉哈罗",
            },
            map = 1456,
            x = 70.14,
            y = 29.52,
        },
        summary = {
            enUS = "Search Orgrimmar for Ragefire Chasm, then kill 8 Ragefire Troggs and 8 Ragefire Shaman before returning to Rahauro in Thunder Bluff.",
            zhCN = "在奥格瑞玛找到怒焰裂谷，杀掉8个怒焰穴居人和8个怒焰萨满祭司，然后向雷霆崖的拉哈罗复命。",
        },
        objectives = {
            enUS = { "Ragefire Trogg ×8", "Ragefire Shaman ×8" },
            zhCN = { "怒焰穴居人 ×8", "怒焰萨满祭司 ×8" },
        },
        rewards = {
            xp = 3200,
            money = 700,
            reputation = {
                {
                    name = {
                        enUS = "Thunder Bluff",
                        zhCN = "雷霆崖",
                    },
                    value = 100,
                },
            },
        },
    },
    [5728] = {
        name = {
            enUS = "Hidden Enemies",
            zhCN = "隐藏的敌人",
        },
        level = 16,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        finish = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        before = { 5726 },
        after = { 5730 },
        summary = {
            enUS = "Kill Bazzalan and Jergosh the Invoker before returning to Thrall in Orgrimmar.",
            zhCN = "杀死巴扎兰和祈求者耶戈什，然后回到奥格瑞玛的萨尔那里。",
        },
        objectives = {
            enUS = { "Bazzalan", "Jergosh the Invoker" },
            zhCN = { "巴扎兰", "祈求者耶戈什" },
        },
        rewards = {
            xp = 3500,
            money = 800,
            reputation = {
                {
                    name = {
                        enUS = "Orgrimmar",
                        zhCN = "奥格瑞玛",
                    },
                    value = 100,
                },
            },
            referenceItems = {
                {
                    id = 15443,
                    followUp = true,
                },
                {
                    id = 15445,
                    followUp = true,
                },
                {
                    id = 15424,
                    followUp = true,
                },
                {
                    id = 15444,
                    followUp = true,
                },
            },
        },
    },
    [5730] = {
        name = {
            enUS = "Hidden Enemies (5730)",
            zhCN = "隐藏的敌人",
        },
        level = 16,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 3216,
            name = {
                enUS = "Neeru Fireblade",
                zhCN = "尼尔鲁·火刃",
            },
            map = 1454,
            x = 49.47,
            y = 50.59,
        },
        finish = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        summary = {
            enUS = "Speak to Thrall in Orgrimmar and tell him what you've learned.",
            zhCN = "与奥格瑞玛的萨尔谈一谈，告诉他你了解到的东西。",
        },
    },
    [5724] = {
        name = {
            enUS = "Returning the Lost Satchel",
            zhCN = "归还背包",
        },
        level = 16,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 11834,
            name = {
                enUS = "Maur Grimtotem",
                zhCN = "玛尔·恐怖图腾",
            },
            map = 2437,
            x = 58.6,
            y = 39.8,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 11833,
            name = {
                enUS = "Rahauro",
                zhCN = "拉哈罗",
            },
            map = 1456,
            x = 70.14,
            y = 29.52,
        },
        before = { 5722 },
        summary = {
            enUS = "Take the Grimtotem Satchel to Rahauro in Thunder Bluff.",
            zhCN = "将恐怖图腾背包交给雷霆崖的拉哈罗。",
        },
        objectives = {
            enUS = { "Grimtotem Satchel" },
            zhCN = { "恐怖图腾背包" },
        },
        rewards = {
            xp = 4400,
            choices = {
                {
                    id = 15452,
                    count = 1,
                },
                {
                    id = 15453,
                    count = 1,
                },
                {
                    id = 270003,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Thunder Bluff",
                        zhCN = "雷霆崖",
                    },
                    value = 150,
                },
            },
        },
    },
    [5722] = {
        name = {
            enUS = "Searching for the Lost Satchel",
            zhCN = "寻找背包",
        },
        level = 16,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 11833,
            name = {
                enUS = "Rahauro",
                zhCN = "拉哈罗",
            },
            map = 1456,
            x = 70.14,
            y = 29.52,
        },
        finish = {
            kind = "npc",
            id = 11834,
            name = {
                enUS = "Maur Grimtotem",
                zhCN = "玛尔·恐怖图腾",
            },
        },
        after = { 5724 },
        summary = {
            enUS = "Search Ragefire Chasm for Maur Grimtotem's corpse and search it for any items of interest.",
            zhCN = "在怒焰裂谷搜寻玛尔·恐怖图腾的尸体以及他留下的东西。",
        },
        rewards = {
            xp = 2700,
        },
    },
    [5761] = {
        name = {
            enUS = "Slaying the Beast",
            zhCN = "饥饿者塔拉加曼",
        },
        level = 16,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 3216,
            name = {
                enUS = "Neeru Fireblade",
                zhCN = "尼尔鲁·火刃",
            },
            map = 1454,
            x = 49.47,
            y = 50.59,
        },
        finish = {
            kind = "npc",
            id = 3216,
            name = {
                enUS = "Neeru Fireblade",
                zhCN = "尼尔鲁·火刃",
            },
            map = 1454,
            x = 49.47,
            y = 50.59,
        },
        summary = {
            enUS = "Enter Ragefire Chasm and slay Taragaman the Hungerer, then bring his heart back to Neeru Fireblade in Orgrimmar.",
            zhCN = "进入怒焰裂谷，杀死饥饿者塔拉加曼，然后把他的心脏交给奥格瑞玛的尼尔鲁·火刃。",
        },
        objectives = {
            enUS = { "Taragaman the Hungerer's Heart" },
            zhCN = { "塔拉加曼的心脏" },
        },
        rewards = {
            xp = 3500,
            money = 800,
        },
    },
    [5725] = {
        name = {
            enUS = "The Power to Destroy...",
            zhCN = "毁灭之力",
        },
        level = 16,
        min = 9,
        faction = "H",
        instances = { "ragefire-chasm" },
        start = {
            kind = "npc",
            id = 2425,
            name = {
                enUS = "Varimathras",
                zhCN = "瓦里玛萨斯",
            },
            map = 1458,
            x = 56.25,
            y = 92.2,
        },
        finish = {
            kind = "npc",
            id = 2425,
            name = {
                enUS = "Varimathras",
                zhCN = "瓦里玛萨斯",
            },
            map = 1458,
            x = 56.25,
            y = 92.2,
        },
        summary = {
            enUS = "Bring the books Spells of Shadow and Incantations from the Nether to Varimathras in Undercity.",
            zhCN = "将《暗影法术研究》和《扭曲虚空的魔法》这两本书交给幽暗城的瓦里玛萨斯。",
        },
        objectives = {
            enUS = { "Spells of Shadow", "Incantations from the Nether" },
            zhCN = { "暗影法术研究", "扭曲虚空的魔法" },
        },
        rewards = {
            xp = 4400,
            choices = {
                {
                    id = 15449,
                    count = 1,
                },
                {
                    id = 15450,
                    count = 1,
                },
                {
                    id = 15451,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 150,
                },
            },
        },
    },
    [6626] = {
        name = {
            enUS = "A Host of Evil",
            zhCN = "邪恶之地",
        },
        level = 35,
        min = 28,
        instances = { "razorfen-downs" },
        start = {
            kind = "npc",
            id = 12866,
            name = {
                enUS = "Myriam Moonsinger",
                zhCN = "麦雷姆·月歌",
            },
            map = 1413,
            x = 49.01,
            y = 94.94,
        },
        finish = {
            kind = "npc",
            id = 12866,
            name = {
                enUS = "Myriam Moonsinger",
                zhCN = "麦雷姆·月歌",
            },
            map = 1413,
            x = 49.01,
            y = 94.94,
        },
        summary = {
            enUS = "Kill 8 Razorfen Battleguard, 8 Razorfen Thornweavers, and 8 Death's Head Cultists and return to Myriam Moonsinger near the entrance to Razorfen...",
            zhCN = "杀掉8个剃刀沼泽护卫者、8个剃刀沼泽织棘者和8个亡首教徒，然后向剃刀高地入口处的麦雷姆·月歌复命。",
        },
        rewards = {
            xp = 3450,
            money = 7500,
        },
    },
    [3525] = {
        name = {
            enUS = "Extinguishing the Idol",
            zhCN = "封印神像",
        },
        level = 37,
        min = 32,
        instances = { "razorfen-downs" },
        start = {
            kind = "npc",
            id = 8516,
            name = {
                enUS = "Belnistrasz",
                zhCN = "奔尼斯特拉兹",
            },
            map = 722,
            x = 75.4,
            y = 8.7,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 8516,
            name = {
                enUS = "Belnistrasz",
                zhCN = "奔尼斯特拉兹",
            },
        },
        before = { 3523 },
        summary = {
            enUS = "Escort Belnistrasz to the Quilboar's idol in Razorfen Downs. Protect Belnistrasz while he performs the ritual to shut down the idol.",
            zhCN = "保护奔尼斯特拉兹来到剃刀高地的野猪人神像处。 当他在进行仪式封印神像时保护他。",
        },
        rewards = {
            xp = 4250,
            referenceItems = {
                {
                    id = 10710,
                },
            },
        },
    },
    [3523] = {
        name = {
            enUS = "Scourge of the Downs",
            zhCN = "剃刀高地的亡灵天灾",
        },
        level = 37,
        min = 32,
        instances = { "razorfen-downs" },
        start = {
            kind = "npc",
            id = 8516,
            name = {
                enUS = "Belnistrasz",
                zhCN = "奔尼斯特拉兹",
            },
            map = 722,
            x = 75.4,
            y = 8.7,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 8516,
            name = {
                enUS = "Belnistrasz",
                zhCN = "奔尼斯特拉兹",
            },
        },
        after = { 3525 },
        summary = {
            enUS = "If you agree to aid Belnistrasz, speak with him again and hand the Oathstone he gave you back to him.",
            zhCN = "如果你同意帮助奔尼斯特拉兹，就再跟他谈谈，并将誓言石还给他。",
        },
        rewards = {
            xp = 285,
        },
    },
    [3341] = {
        name = {
            enUS = "Bring the End",
            zhCN = "寒冰之王",
        },
        level = 42,
        min = 37,
        faction = "H",
        instances = { "razorfen-downs" },
        start = {
            kind = "npc",
            id = 2308,
            name = {
                enUS = "Andrew Brownell",
                zhCN = "安德鲁·布隆奈尔",
            },
            map = 1458,
            x = 74.05,
            y = 33.31,
        },
        finish = {
            kind = "npc",
            id = 2308,
            name = {
                enUS = "Andrew Brownell",
                zhCN = "安德鲁·布隆奈尔",
            },
            map = 1458,
            x = 74.05,
            y = 33.31,
        },
        summary = {
            enUS = "Andrew Brownell wants you to kill Amnennar the Coldbringer and return his skull.",
            zhCN = "安德鲁·布隆奈尔要你杀了寒冰之王亚门纳尔并将其头骨带回来。",
        },
        rewards = {
            xp = 4300,
            referenceItems = {
                {
                    id = 10823,
                },
                {
                    id = 10824,
                },
            },
        },
    },
    [3636] = {
        name = {
            enUS = "Bring the Light",
            zhCN = "与圣光同在",
        },
        level = 42,
        min = 39,
        faction = "A",
        instances = { "razorfen-downs" },
        start = {
            kind = "npc",
            id = 1284,
            name = {
                enUS = "Archbishop Benedictus",
                zhCN = "大主教本尼迪塔斯",
            },
            map = 1453,
            x = 50.0,
            y = 45.9,
        },
        finish = {
            kind = "npc",
            id = 1284,
            name = {
                enUS = "Archbishop Benedictus",
                zhCN = "大主教本尼迪塔斯",
            },
            map = 1453,
            x = 50.0,
            y = 45.9,
        },
        summary = {
            enUS = "Archbishop Bendictus wants you to slay Amnennar the Coldbringer in Razorfen Downs.",
            zhCN = "大主教本尼迪塔斯要你去杀死剃刀高地的寒冰之王亚门纳尔。",
        },
        rewards = {
            xp = 4300,
            referenceItems = {
                {
                    id = 10823,
                },
                {
                    id = 10824,
                },
            },
        },
    },
    [1221] = {
        name = {
            enUS = "Blueleaf Tubers",
            zhCN = "蓝叶薯",
        },
        level = 26,
        min = 20,
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 3446,
            name = {
                enUS = "Mebok Mizzyrix",
                zhCN = "麦伯克·米希瑞克斯",
            },
            map = 1413,
            x = 62.37,
            y = 37.62,
        },
        finish = {
            kind = "npc",
            id = 3446,
            name = {
                enUS = "Mebok Mizzyrix",
                zhCN = "麦伯克·米希瑞克斯",
            },
            map = 1413,
            x = 62.37,
            y = 37.62,
        },
        summary = {
            enUS = "Grab a Crate with Holes. Grab a Snufflenose Command Stick. Grab and read the Snufflenose Owner's Manual. In Razorfen Kraul, use the Crate with Holes to summon a Snufflenose Gopher, and use the Command Stick on the gopher to make it search for Tubers. Bring 6 Blueleaf Tubers, the Snufflenose Command Stick and the Crate with Holes to Mebok Mizzyrix in Ratchet.",
            zhCN = "找到一个开孔的箱子。 找到一根地鼠指挥棒。 找到并阅读《地鼠指挥手册》。 在剃刀沼泽里用开孔的箱子召唤一只地鼠，然后用指挥棒驱使它去搜寻蓝叶薯。 把地鼠指挥棒、开孔的箱子和6块蓝叶薯交给棘齿城的麦伯克·米希瑞克斯。",
        },
        objectives = {
            enUS = { "Blueleaf Tuber ×6", "Crate With Holes", "Snufflenose Owner's Manual", "Snufflenose Command Stick" },
            zhCN = { "蓝叶薯 ×6", "开孔的箱子", "地鼠训练手册", "地鼠指挥棒" },
        },
        rewards = {
            xp = 7900,
            items = {
                {
                    id = 6755,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Ratchet",
                        zhCN = "棘齿城",
                    },
                    value = 100,
                },
            },
        },
    },
    [1701] = {
        name = {
            enUS = "Fire Hardened Mail",
            zhCN = "弗伦的铠甲",
        },
        level = 28,
        min = 20,
        faction = "A",
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 5413,
            name = {
                enUS = "Furen Longbeard",
                zhCN = "弗伦·长须",
            },
            map = 1453,
            x = 64.7,
            y = 37.3,
        },
        finish = {
            kind = "npc",
            id = 5413,
            name = {
                enUS = "Furen Longbeard",
                zhCN = "弗伦·长须",
            },
            map = 1453,
            x = 64.7,
            y = 37.3,
        },
        summary = {
            enUS = "Gather the materials Furen Longbeard requires, and bring them to him in Stormwind.",
            zhCN = "收集必需的材料，将它们交给暴风城的弗伦·长须。",
        },
    },
    [1838] = {
        name = {
            enUS = "Brutal Armor",
            zhCN = "野蛮护甲",
        },
        level = 30,
        min = 20,
        faction = "H",
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 5878,
            name = {
                enUS = "Thun'grim Firegaze",
                zhCN = "索恩格瑞姆·火眼",
            },
            map = 1413,
            x = 57.23,
            y = 30.34,
        },
        finish = {
            kind = "npc",
            id = 5878,
            name = {
                enUS = "Thun'grim Firegaze",
                zhCN = "索恩格瑞姆·火眼",
            },
            map = 1413,
            x = 57.23,
            y = 30.34,
        },
        summary = {
            enUS = "Bring to Thun'grim Firegaze 15 Smoky Iron Ingots, 10 Powdered Azurite, 10 Iron Bars and a Vial of Phlogiston.",
            zhCN = "为索恩格瑞姆收集15根烟雾铁锭、10份蓝铜粉、10块铁锭和1瓶燃素。",
        },
    },
    [1142] = {
        name = {
            enUS = "Mortality Wanes",
            zhCN = "临终遗言",
        },
        level = 30,
        min = 25,
        faction = "A",
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 4510,
            name = {
                enUS = "Heralath Fallowbrook",
                zhCN = "赫尔拉斯·静水",
            },
            map = 491,
            x = 37.8,
            y = 32.6,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 4521,
            name = {
                enUS = "Treshala Fallowbrook",
                zhCN = "塔莎拉·静水",
            },
            map = 1457,
            x = 69.54,
            y = 67.75,
        },
        summary = {
            enUS = "Find and return Treshala's Pendant to Treshala Fallowbrook in Darnassus.",
            zhCN = "将塔莎拉的坠饰带给达纳苏斯的塔莎拉·静水。",
        },
        rewards = {
            xp = 3050,
            referenceItems = {
                {
                    id = 6751,
                },
                {
                    id = 6752,
                },
            },
        },
    },
    [1144] = {
        name = {
            enUS = "Willix the Importer",
            zhCN = "进口商威利克斯",
        },
        level = 30,
        min = 23,
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 4508,
            name = {
                enUS = "Willix the Importer",
                zhCN = "进口商威利克斯",
            },
            map = 491,
            x = 37.5,
            y = 31.1,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 4508,
            name = {
                enUS = "Willix the Importer",
                zhCN = "进口商威利克斯",
            },
        },
        summary = {
            enUS = "Escort Willix the Importer out of Razorfen Kraul.",
            zhCN = "护送进口商威利克斯逃出剃刀沼泽。",
        },
        rewards = {
            xp = 11450,
            choices = {
                {
                    id = 6748,
                    count = 1,
                },
                {
                    id = 6750,
                    count = 1,
                },
                {
                    id = 6749,
                    count = 1,
                },
                {
                    id = 274078,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Ratchet",
                        zhCN = "棘齿城",
                    },
                    value = 150,
                },
            },
        },
    },
    [1109] = {
        name = {
            enUS = "Going, Going, Guano!",
            zhCN = "蝙蝠的粪便",
        },
        level = 33,
        min = 30,
        faction = "H",
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 2055,
            name = {
                enUS = "Master Apothecary Faranell",
                zhCN = "大药剂师法拉尼尔",
            },
            map = 1458,
            x = 48.82,
            y = 69.28,
        },
        finish = {
            kind = "npc",
            id = 2055,
            name = {
                enUS = "Master Apothecary Faranell",
                zhCN = "大药剂师法拉尼尔",
            },
            map = 1458,
            x = 48.82,
            y = 69.28,
        },
        after = { 1113 },
        summary = {
            enUS = "Bring 1 pile of Kraul Guano to Master Apothecary Faranell in the Undercity.",
            zhCN = "帮幽暗城的大药剂师法拉尼尔带回一堆沼泽蝙蝠的粪便。",
        },
        rewards = {
            xp = 3300,
        },
    },
    [1102] = {
        name = {
            enUS = "A Vengeful Fate",
            zhCN = "奥尔德的报复",
        },
        level = 34,
        min = 29,
        faction = "H",
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 4451,
            name = {
                enUS = "Auld Stonespire",
                zhCN = "奥尔德·石塔",
            },
            map = 1456,
            x = 35.97,
            y = 59.92,
        },
        finish = {
            kind = "npc",
            id = 4451,
            name = {
                enUS = "Auld Stonespire",
                zhCN = "奥尔德·石塔",
            },
            map = 1456,
            x = 35.97,
            y = 59.92,
        },
        summary = {
            enUS = "Bring Razorflank's Heart to Auld Stonespire in Thunder Bluff.",
            zhCN = "把卡尔加·刺肋的心脏交给雷霆崖的奥尔德·石塔。",
        },
        rewards = {
            xp = 4050,
            referenceItems = {
                {
                    id = 4197,
                },
                {
                    id = 6742,
                },
                {
                    id = 6725,
                },
            },
        },
    },
    [1100] = {
        name = {
            enUS = "Lonebrow's Journal",
            zhCN = "亨里格的日记",
        },
        level = 34,
        min = 29,
        faction = "A",
        instances = { "razorfen-kraul" },
        start = {
            kind = "item",
            id = 5791,
            name = {
                enUS = "Henrig Lonebrow's Journal",
                zhCN = "亨里格·独眉的日记",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 4048,
            name = {
                enUS = "Falfindel Waywarder",
                zhCN = "法芬德尔",
            },
            map = 1444,
            x = 89.64,
            y = 46.57,
        },
        after = { 1101 },
        summary = {
            enUS = "Read Henrig Lonebrow's Journal.",
            zhCN = "阅读亨里格·独眉的日记。",
        },
    },
    [1101] = {
        name = {
            enUS = "The Crone of the Kraul",
            zhCN = "卡尔加·刺肋",
        },
        level = 34,
        min = 29,
        faction = "A",
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 4048,
            name = {
                enUS = "Falfindel Waywarder",
                zhCN = "法芬德尔",
            },
            map = 1444,
            x = 89.64,
            y = 46.57,
        },
        finish = {
            kind = "npc",
            id = 4048,
            name = {
                enUS = "Falfindel Waywarder",
                zhCN = "法芬德尔",
            },
            map = 1444,
            x = 89.64,
            y = 46.57,
        },
        before = { 1100 },
        summary = {
            enUS = "Bring Razorflank's Medallion to Falfindel Waywarder in Thalanaar.",
            zhCN = "把卡尔加·刺肋的徽章交给萨兰纳尔的法芬德尔。",
        },
        rewards = {
            xp = 3350,
            referenceItems = {
                {
                    id = 4197,
                },
                {
                    id = 6742,
                },
                {
                    id = 6725,
                },
            },
        },
    },
    [6521] = {
        name = {
            enUS = "An Unholy Alliance (6521)",
            zhCN = "邪恶的盟友",
        },
        level = 36,
        min = 28,
        faction = "H",
        instances = { "razorfen-kraul" },
        start = {
            kind = "npc",
            id = 2425,
            name = {
                enUS = "Varimathras",
                zhCN = "瓦里玛萨斯",
            },
            map = 1458,
            x = 56.25,
            y = 92.2,
        },
        finish = {
            kind = "npc",
            id = 2425,
            name = {
                enUS = "Varimathras",
                zhCN = "瓦里玛萨斯",
            },
            map = 1458,
            x = 56.25,
            y = 92.2,
        },
        before = { 6522 },
        summary = {
            enUS = "Bring Ambassador Malcin's Head to Varimathras in the Undercity.",
            zhCN = "把玛克林大使的头颅交给幽暗城的瓦里玛萨斯。",
        },
        rewards = {
            xp = 3500,
            money = 2000,
            referenceItems = {
                {
                    id = 17039,
                },
                {
                    id = 17042,
                },
                {
                    id = 17043,
                },
            },
        },
    },
    [6522] = {
        name = {
            enUS = "An Unholy Alliance (6522)",
            zhCN = "邪恶的盟友",
        },
        level = 36,
        min = 28,
        faction = "H",
        instances = { "razorfen-kraul" },
        start = {
            kind = "item",
            id = 17008,
            name = {
                enUS = "Small Scroll",
                zhCN = "小卷轴",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 2425,
            name = {
                enUS = "Varimathras",
                zhCN = "瓦里玛萨斯",
            },
            map = 1458,
            x = 56.25,
            y = 92.2,
        },
        after = { 6521 },
        summary = {
            enUS = "Take the Small Scroll to Varimathras in the Undercity.",
            zhCN = "把小卷轴交给幽暗城的瓦里玛萨斯。",
        },
        rewards = {
            xp = 2800,
            money = 4000,
        },
    },
    [95250] = {
        name = {
            enUS = "Abominable Creatures",
            zhCN = "可憎的生物",
        },
        level = 21,
        min = 16,
        faction = "A",
        instances = { "ruins-of-lordaeron" },
        finish = {
            kind = "npc",
            name = {
                enUS = "Captain Truman",
                zhCN = "杜鲁门队长",
            },
        },
        summary = {
            enUS = "Collect the Head of the Baron in the Ruins of Lordaeron and bring it back to Captain Truman.",
            zhCN = "在洛丹伦废墟取得男爵的头颅，并将其交给杜鲁门队长。",
        },
        objectives = {
            enUS = { "Head of the Baron" },
            zhCN = { "男爵的头颅" },
        },
        rewards = {
            xp = 6200,
            choices = {
                {
                    id = 279864,
                    count = 1,
                },
                {
                    id = 279865,
                    count = 1,
                },
                {
                    id = 279867,
                    count = 1,
                },
            },
        },
    },
    [97288] = {
        name = {
            enUS = "Unending Torment",
            zhCN = "无尽折磨",
        },
        level = 21,
        min = 16,
        faction = "H",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "item",
            id = 280438,
            name = {
                enUS = "Abominable Head",
                zhCN = "憎恶头颅",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 2055,
            name = {
                enUS = "Master Apothecary Faranell",
                zhCN = "大药剂师法拉尼尔",
            },
            map = 1458,
            x = 48.82,
            y = 69.28,
        },
        before = { 97292 },
        after = { 97289 },
        summary = {
            enUS = "Deliver the Abominable Head to Master Apothecary Faranell in the Undercity.",
            zhCN = "把憎恶头颅交给幽暗城的大药剂师法拉尼尔。",
        },
        objectives = {
            enUS = { "Abominable Head" },
            zhCN = { "憎恶头颅" },
        },
        rewards = {
            xp = 5300,
            money = 1300,
            referenceItems = {
                {
                    id = 279864,
                },
                {
                    id = 279865,
                },
                {
                    id = 279867,
                },
            },
        },
    },
    [92401] = {
        name = {
            enUS = "A Frightened Request",
            zhCN = "惊恐的请求",
        },
        level = 22,
        min = 15,
        faction = "H",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "npc",
            id = 250686,
            name = {
                enUS = "Tabitha Heartweaver",
                zhCN = "塔比瑟·织心",
            },
            map = 1421,
            x = 44.5,
            y = 43.0,
        },
        finish = {
            kind = "npc",
            id = 250686,
            name = {
                enUS = "Tabitha Heartweaver",
                zhCN = "塔比瑟·织心",
            },
            map = 1421,
            x = 44.5,
            y = 43.0,
        },
        summary = {
            enUS = "Investigate the disappearance of Edward Heartweaver in the Ruins of Lordaeron.",
            zhCN = "调查爱德华·织心在洛丹伦废墟失踪一事。",
        },
        objectives = {
            enUS = { "Investigate the disappearance of Edward Heartweaver in the Ruins of Lordaeron." },
            zhCN = { "调查爱德华·织心在洛丹伦废墟失踪一事。" },
        },
        rewards = {
            xp = 7050,
            choices = {
                {
                    id = 251485,
                    count = 1,
                },
                {
                    id = 251486,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 150,
                },
            },
        },
    },
    [95195] = {
        name = {
            enUS = "Bloodied Insignia",
            zhCN = "血污徽章",
        },
        level = 22,
        min = 16,
        faction = "A",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "item",
            id = 268540,
            name = {
                enUS = "Bloodied Insignia",
                zhCN = "血污徽章",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 466,
            name = {
                enUS = "General Marcus Jonathan",
                zhCN = "马库斯·乔纳森将军",
            },
            map = 1453,
            x = 63.97,
            y = 75.32,
        },
        summary = {
            enUS = "Collect 10 Bloodied Insignias and take them to General Marcus Jonathan in Stormwind City.",
            zhCN = "收集10枚血污徽章，并将它们交给暴风城的马库斯·乔纳森将军。",
        },
        objectives = {
            enUS = { "Bloodied Insignia ×10" },
            zhCN = { "血污徽章 ×10" },
        },
        rewards = {
            xp = 9750,
            money = 4500,
            choices = {
                {
                    id = 279868,
                    count = 1,
                },
                {
                    id = 279869,
                    count = 1,
                },
            },
        },
    },
    [95189] = {
        name = {
            enUS = "Crest of Lordaeron",
            zhCN = "洛丹伦纹章",
        },
        level = 22,
        min = 16,
        faction = "A",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "item",
            id = 268579,
            name = {
                enUS = "Crest of Lordaeron",
                zhCN = "洛丹伦纹章",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 15991,
            name = {
                enUS = "Lady Dena Kennedy",
                zhCN = "黛娜·肯尼迪女士",
            },
            map = 1453,
        },
        summary = {
            enUS = "Return the Crest of Lordaeron to Lady Dena Kennedy in Stormwind City.",
            zhCN = "把洛丹伦纹章交给暴风城的黛娜·肯尼迪女士。",
        },
        objectives = {
            enUS = { "Crest of Lordaeron" },
            zhCN = { "洛丹伦纹章" },
        },
        rewards = {
            xp = 9750,
            choices = {
                {
                    id = 280567,
                    count = 1,
                },
            },
            referenceItems = {
                {
                    id = 279864,
                },
                {
                    id = 279865,
                },
            },
        },
    },
    [95204] = {
        name = {
            enUS = "Crest of Lordaeron",
            zhCN = "洛丹伦纹章",
        },
        level = 22,
        min = 16,
        faction = "H",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "item",
            id = 275521,
            name = {
                enUS = "Crest of Lordaeron",
                zhCN = "洛丹伦纹章",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 7825,
            name = {
                enUS = "Oran Snakewrithe",
                zhCN = "奥兰·斯内克威瑟",
            },
            map = 1458,
            x = 73.06,
            y = 32.85,
        },
        summary = {
            enUS = "Bring the Crest of Lordaeron to Oran Snakewrithe in Undercity.",
            zhCN = "把洛丹伦纹章交给幽暗城的奥兰·斯内克威瑟。",
        },
        objectives = {
            enUS = { "Crest of Lordaeron" },
            zhCN = { "洛丹伦纹章" },
        },
        rewards = {
            xp = 8300,
            choices = {
                {
                    id = 280567,
                    count = 1,
                },
            },
        },
    },
    [92421] = {
        name = {
            enUS = "Light's Justice",
            zhCN = "圣光的正义",
        },
        level = 22,
        min = 15,
        faction = "H",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "npc",
            id = 266484,
            name = {
                enUS = "Morbin Lightbane",
                zhCN = "莫宾·光祸",
            },
            map = 1458,
            x = 57.4,
            y = 88.8,
            unverified = true,
        },
        finish = {
            kind = "npc",
            id = 266484,
            name = {
                enUS = "Morbin Lightbane",
                zhCN = "莫宾·光祸",
            },
            map = 1458,
        },
        summary = {
            enUS = "Collect 25 Intact Limbs within The Ruins of Lordaeron for Morbin Lightbane in the Undercity.",
            zhCN = "在洛丹伦废墟收集25条完好的肢体，交给幽暗城的莫宾·光祸。",
        },
        objectives = {
            enUS = { "Intact Limbs ×25" },
            zhCN = { "完好的肢体 ×25" },
        },
        rewards = {
            xp = 7050,
            money = 4500,
            choices = {
                {
                    id = 279874,
                    count = 1,
                },
                {
                    id = 279875,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 150,
                },
            },
            referenceItems = {
                {
                    id = 279864,
                },
                {
                    id = 279865,
                },
            },
        },
    },
    [92415] = {
        name = {
            enUS = "Remember That I Love You",
            zhCN = "记住我爱你",
        },
        level = 22,
        min = 15,
        faction = "A",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "item",
            id = 251522,
            name = {
                enUS = "Blood-Stained Letter",
                zhCN = "染血的信",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 14450,
            name = {
                enUS = "Orphan Matron Nightingale",
                zhCN = "孤儿监护员奈丁加尔",
            },
            map = 1453,
            x = 56.3,
            y = 54.0,
        },
        summary = {
            enUS = "Bring the Blood-Stained Letter to Orphan Matron Nightingale in Stormwind City.",
            zhCN = "把染血的信交给暴风城的孤儿监护员奈丁加尔。",
        },
        objectives = {
            enUS = { "Blood-Stained Letter" },
            zhCN = { "染血的信" },
        },
        rewards = {
            xp = 9750,
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 150,
                },
            },
            referenceItems = {
                {
                    id = 279870,
                },
                {
                    id = 279864,
                },
                {
                    id = 279865,
                },
            },
        },
    },
    [95216] = {
        name = {
            enUS = "The New Plague",
            zhCN = "新的瘟疫",
        },
        level = 22,
        min = 16,
        faction = "H",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "npc",
            id = 11835,
            name = {
                enUS = "Theodore Griffs",
                zhCN = "西奥多·格里夫斯",
            },
            map = 1458,
            x = 46.31,
            y = 71.91,
        },
        finish = {
            kind = "npc",
            id = 11835,
            name = {
                enUS = "Theodore Griffs",
                zhCN = "西奥多·格里夫斯",
            },
            map = 1458,
            x = 46.31,
            y = 71.91,
        },
        summary = {
            enUS = "Collect the Highly Toxic Strain from Witherfang in Ruins of Lordaeron for Theodore Griffs in Undercity.",
            zhCN = "从洛丹伦废墟的枯牙身上取得剧毒的毒株，交给幽暗城的西奥多·格里夫斯。",
        },
        objectives = {
            enUS = { "Highly Toxic Strain" },
            zhCN = { "剧毒的毒株" },
        },
        rewards = {
            xp = 8300,
            money = 125,
            choices = {
                {
                    id = 279876,
                    count = 1,
                },
                {
                    id = 279877,
                    count = 1,
                },
            },
            referenceItems = {
                {
                    id = 279864,
                },
                {
                    id = 279865,
                },
            },
        },
    },
    [92422] = {
        name = {
            enUS = "The Wrath of Rath'mael",
            zhCN = "拉斯玛尔之怒",
        },
        level = 22,
        min = 15,
        faction = "H",
        instances = { "ruins-of-lordaeron" },
        start = {
            kind = "npc",
            id = 251001,
            name = {
                enUS = "Deathguard Kristof",
                zhCN = "死亡卫士克里斯托夫",
            },
            map = 1420,
            x = 65.2,
            y = 60.2,
            unverified = true,
        },
        finish = {
            kind = "npc",
            id = 251001,
            name = {
                enUS = "Deathguard Kristof",
                zhCN = "死亡卫士克里斯托夫",
            },
            map = 1420,
        },
        summary = {
            enUS = "Kill Rath'mael in the Ruins of Lordaeron for Deathguard Kristof in Brill.",
            zhCN = "为布瑞尔的死亡卫士克里斯托夫消灭洛丹伦废墟中的拉斯玛尔。",
        },
        objectives = {
            enUS = { "Rath'mael" },
            zhCN = { "拉斯玛尔" },
        },
        rewards = {
            choices = {
                {
                    id = 251533,
                    count = 1,
                },
                {
                    id = 251534,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 150,
                },
            },
            referenceItems = {
                {
                    id = 279864,
                },
                {
                    id = 279865,
                },
            },
        },
    },
    [1113] = {
        name = {
            enUS = "Hearts of Zeal",
            zhCN = "狂热之心",
        },
        level = 33,
        min = 30,
        faction = "H",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "armory", "library", "cathedral", "graveyard" },
        start = {
            kind = "npc",
            id = 2055,
            name = {
                enUS = "Master Apothecary Faranell",
                zhCN = "大药剂师法拉尼尔",
            },
            map = 1458,
            x = 48.82,
            y = 69.28,
        },
        finish = {
            kind = "npc",
            id = 2055,
            name = {
                enUS = "Master Apothecary Faranell",
                zhCN = "大药剂师法拉尼尔",
            },
            map = 1458,
            x = 48.82,
            y = 69.28,
        },
        summary = {
            enUS = "Master Apothecary Faranell in the Undercity wants 20 Hearts of Zeal.",
            zhCN = "幽暗城的大药剂师法拉尼尔需要20颗狂热之心。",
        },
        rewards = {
            xp = 3300,
        },
    },
    [1051] = {
        name = {
            enUS = "Vorrel's Revenge",
            zhCN = "沃瑞尔的复仇",
        },
        level = 33,
        min = 25,
        faction = "H",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "armory", "library", "cathedral", "graveyard" },
        start = {
            kind = "npc",
            id = 3981,
            name = {
                enUS = "Vorrel Sengutz",
                zhCN = "沃瑞尔·森加斯",
            },
            map = 796,
            x = 37.1,
            y = 21.5,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 3982,
            name = {
                enUS = "Monika Sengutz",
                zhCN = "莫尼卡·森古特斯",
            },
            map = 1424,
            x = 62.67,
            y = 18.88,
        },
        summary = {
            enUS = "Return Vorrel Sengutz's wedding ring to Monika Sengutz in Tarren Mill.",
            zhCN = "把沃瑞尔·森加斯的结婚戒指还给塔伦米尔的莫尼卡·森古特斯。",
        },
        rewards = {
            xp = 3300,
            referenceItems = {
                {
                    id = 7750,
                },
                {
                    id = 4643,
                },
                {
                    id = 7751,
                },
            },
        },
    },
    [1160] = {
        name = {
            enUS = "Test of Lore (1160)",
            zhCN = "知识试炼",
        },
        level = 36,
        min = 25,
        faction = "H",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "armory", "library", "cathedral", "graveyard" },
        start = {
            kind = "npc",
            id = 4488,
            name = {
                enUS = "Parqual Fintallas",
                zhCN = "帕科瓦·芬塔拉斯",
            },
            map = 1458,
            x = 57.8,
            y = 65.42,
        },
        finish = {
            kind = "npc",
            id = 4488,
            name = {
                enUS = "Parqual Fintallas",
                zhCN = "帕科瓦·芬塔拉斯",
            },
            map = 1458,
            x = 57.8,
            y = 65.42,
        },
        before = { 1149, 1150, 1151, 1152, 1154 },
        after = { 1394 },
        summary = {
            enUS = "Find The Beginnings of the Undead Threat, and return it to Parqual Fintallas in Undercity.",
            zhCN = "找到《亡灵的起源》，把它交给幽暗城的帕科瓦·芬塔拉斯。",
        },
        rewards = {
            xp = 2100,
        },
    },
    [1049] = {
        name = {
            enUS = "Compendium of the Fallen",
            zhCN = "堕落者纲要",
        },
        level = 38,
        min = 28,
        faction = "H",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "armory", "library", "cathedral", "graveyard" },
        start = {
            kind = "npc",
            id = 3978,
            name = {
                enUS = "Sage Truthseeker",
                zhCN = "圣者图希克",
            },
            map = 1456,
            x = 34.4,
            y = 46.87,
        },
        finish = {
            kind = "npc",
            id = 3978,
            name = {
                enUS = "Sage Truthseeker",
                zhCN = "圣者图希克",
            },
            map = 1456,
            x = 34.4,
            y = 46.87,
        },
        summary = {
            enUS = "Retrieve the Compendium of the Fallen from the Monastery in Tirisfal Glades and return to Sage Truthseeker in Thunder Bluff.",
            zhCN = "从血色修道院里找到《堕落者纲要》，把它交给雷霆崖的圣者图希克。",
        },
        rewards = {
            xp = 3550,
            referenceItems = {
                {
                    id = 7747,
                },
                {
                    id = 17508,
                },
                {
                    id = 7749,
                },
            },
        },
    },
    [1050] = {
        name = {
            enUS = "Mythology of the Titans",
            zhCN = "泰坦神话",
        },
        level = 38,
        min = 28,
        faction = "A",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "armory", "library", "cathedral", "graveyard" },
        start = {
            kind = "npc",
            id = 3979,
            name = {
                enUS = "Librarian Mae Paledust",
                zhCN = "图书馆员麦伊·苍尘",
            },
            map = 1455,
            x = 74.97,
            y = 12.48,
        },
        finish = {
            kind = "npc",
            id = 3979,
            name = {
                enUS = "Librarian Mae Paledust",
                zhCN = "图书馆员麦伊·苍尘",
            },
            map = 1455,
            x = 74.97,
            y = 12.48,
        },
        summary = {
            enUS = "Retrieve Mythology of the Titans from the Monastery and bring it to Librarian Mae Paledust in Ironforge.",
            zhCN = "从修道院拿回《泰坦神话》，把它交给铁炉堡的图书馆员麦伊·苍尘。",
        },
        rewards = {
            xp = 3550,
            referenceItems = {
                {
                    id = 7746,
                },
            },
        },
    },
    [261] = {
        name = {
            enUS = "Down the Scarlet Path (261)",
            zhCN = "血色之路",
        },
        level = 39,
        min = 34,
        faction = "A",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 1182,
            name = {
                enUS = "Brother Anton",
                zhCN = "安东修士",
            },
            map = 1443,
            x = 66.52,
            y = 7.91,
        },
        finish = {
            kind = "npc",
            id = 1182,
            name = {
                enUS = "Brother Anton",
                zhCN = "安东修士",
            },
            map = 1443,
            x = 66.52,
            y = 7.91,
        },
        after = { 1053 },
        summary = {
            enUS = "Destroy 30 Undead Ravagers, then return to Brother Anton at Nijel's Point.",
            zhCN = "杀掉30个亡灵劫掠者，然后向尼耶尔前哨站的安东修士复命。",
        },
    },
    [1052] = {
        name = {
            enUS = "Down the Scarlet Path (1052)",
            zhCN = "血色之路",
        },
        level = 40,
        min = 34,
        faction = "A",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 1182,
            name = {
                enUS = "Brother Anton",
                zhCN = "安东修士",
            },
            map = 1443,
            x = 66.52,
            y = 7.91,
        },
        finish = {
            kind = "npc",
            id = 3980,
            name = {
                enUS = "Raleigh the Devout",
                zhCN = "虔诚的莱雷恩",
            },
            map = 1424,
            x = 51.47,
            y = 58.35,
        },
        summary = {
            enUS = "Take Brother Anton's Letter of Commendation to Raleigh the Devout in Southshore.",
            zhCN = "将安东修士的表彰信带给南海镇的虔诚的莱雷恩。",
        },
    },
    [1053] = {
        name = {
            enUS = "In the Name of the Light",
            zhCN = "以圣光之名",
        },
        level = 40,
        min = 34,
        faction = "A",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "armory", "library", "cathedral" },
        start = {
            kind = "npc",
            id = 3980,
            name = {
                enUS = "Raleigh the Devout",
                zhCN = "虔诚的莱雷恩",
            },
            map = 1424,
            x = 51.47,
            y = 58.35,
        },
        finish = {
            kind = "npc",
            id = 3980,
            name = {
                enUS = "Raleigh the Devout",
                zhCN = "虔诚的莱雷恩",
            },
            map = 1424,
            x = 51.47,
            y = 58.35,
        },
        before = { 261 },
        summary = {
            enUS = "Kill High Inquisitor Whitemane, Scarlet Commander Mograine, Herod, the Scarlet Champion and Houndmaster Loksey and then report back to...",
            zhCN = "杀死大检察官怀特迈恩，血色十字军指挥官莫格莱尼，十字军的勇士赫洛德和驯犬者洛克希并向南海镇的莱雷恩复命。",
        },
        rewards = {
            xp = 4700,
            referenceItems = {
                {
                    id = 6829,
                },
                {
                    id = 6830,
                },
                {
                    id = 6831,
                },
                {
                    id = 11262,
                },
            },
        },
    },
    [1951] = {
        name = {
            enUS = "Rituals of Power",
            zhCN = "能量仪祭",
        },
        level = 40,
        min = 30,
        instances = { "scarlet-monastery" },
        sectionSlugs = { "library" },
        start = {
            kind = "npc",
            id = 6548,
            name = {
                enUS = "Magus Tirth",
                zhCN = "大法师提尔斯",
            },
            map = 1441,
            x = 78.29,
            y = 75.7,
        },
        finish = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        before = { 1947, 1949, 1950 },
        after = { 1952 },
        summary = {
            enUS = "Bring the book Rituals of Power to Tabetha in Dustwallow Marsh.",
            zhCN = "将《能量仪祭》交给尘泥沼泽的塔贝萨。",
        },
    },
    [1048] = {
        name = {
            enUS = "Into The Scarlet Monastery",
            zhCN = "深入血色修道院",
        },
        level = 42,
        min = 33,
        faction = "H",
        instances = { "scarlet-monastery" },
        sectionSlugs = { "armory", "library", "cathedral" },
        start = {
            kind = "npc",
            id = 2425,
            name = {
                enUS = "Varimathras",
                zhCN = "瓦里玛萨斯",
            },
            map = 1458,
            x = 56.25,
            y = 92.2,
        },
        finish = {
            kind = "npc",
            id = 2425,
            name = {
                enUS = "Varimathras",
                zhCN = "瓦里玛萨斯",
            },
            map = 1458,
            x = 56.25,
            y = 92.2,
        },
        summary = {
            enUS = "Kill High Inquisitor Whitemane, Scarlet Commander Mograine, Herod, the Scarlet Champion and Houndmaster Loksey and then report back...",
            zhCN = "杀掉大检察官怀特迈恩、血色十字军指挥官莫格莱尼、血色十字军勇士赫洛德和驯犬者洛克希，然后向幽暗城的瓦里玛萨斯回报。",
        },
        rewards = {
            xp = 5150,
            referenceItems = {
                {
                    id = 6802,
                },
                {
                    id = 6803,
                },
                {
                    id = 10711,
                },
            },
        },
    },
    [5341] = {
        name = {
            enUS = "Barov Family Fortune (5341)",
            zhCN = "巴罗夫家族的宝藏",
        },
        level = 60,
        min = 52,
        faction = "H",
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 11022,
            name = {
                enUS = "Alexi Barov",
                zhCN = "阿莱克斯·巴罗夫",
            },
            map = 1420,
            x = 83.06,
            y = 71.6,
        },
        finish = {
            kind = "npc",
            id = 11022,
            name = {
                enUS = "Alexi Barov",
                zhCN = "阿莱克斯·巴罗夫",
            },
            map = 1420,
            x = 83.06,
            y = 71.6,
        },
        after = { 5342 },
        summary = {
            enUS = "Venture to the Scholomance and recover the Barov family fortune. Four deeds make up this fortune: The Deed to Caer Darrow; The Deed...",
            zhCN = "到通灵学院中去取得巴罗夫家族的宝藏。这份宝藏包括四份地契：凯尔达隆地契、布瑞尔地契、塔伦米尔地契，还有南海镇地契。完成任务之后就回到阿莱克斯·巴罗夫那儿去。",
        },
        rewards = {
            xp = 6600,
            money = 18000,
        },
    },
    [5343] = {
        name = {
            enUS = "Barov Family Fortune (5343)",
            zhCN = "巴罗夫家族的宝藏",
        },
        level = 60,
        min = 52,
        faction = "A",
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 11023,
            name = {
                enUS = "Weldon Barov",
                zhCN = "维尔顿·巴罗夫",
            },
            map = 1422,
            x = 43.45,
            y = 83.73,
        },
        finish = {
            kind = "npc",
            id = 11023,
            name = {
                enUS = "Weldon Barov",
                zhCN = "维尔顿·巴罗夫",
            },
            map = 1422,
            x = 43.45,
            y = 83.73,
        },
        after = { 5344 },
        summary = {
            enUS = "Venture to the Scholomance and recover the Barov family fortune. Four deeds make up this fortune: The Deed to Caer Darrow; The Deed...",
            zhCN = "到通灵学院中去取得巴罗夫家族的宝藏。这份宝藏包括四份地契：凯尔达隆地契、布瑞尔地契、塔伦米尔地契，还有南海镇地契。完成任务之后就回到维尔顿·巴罗夫那儿去。",
        },
        rewards = {
            xp = 6600,
            money = 18000,
        },
    },
    [4771] = {
        name = {
            enUS = "Dawn's Gambit",
            zhCN = "黎明先锋",
        },
        level = 60,
        min = 57,
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 11035,
            name = {
                enUS = "Betina Bigglezink",
                zhCN = "贝蒂娜·比格辛克",
            },
            map = 1423,
            x = 81.47,
            y = 59.66,
        },
        finish = {
            kind = "npc",
            id = 11035,
            name = {
                enUS = "Betina Bigglezink",
                zhCN = "贝蒂娜·比格辛克",
            },
            map = 1423,
            x = 81.47,
            y = 59.66,
        },
        before = { 4726, 4808, 4809, 4810, 4734, 4735, 5522, 5531 },
        summary = {
            enUS = "Place Dawn's Gambit in the Viewing Room of the Scholomance. Defeat Vectus, then return to Betina Bigglezink.",
            zhCN = "将黎明先锋放在通灵学院的观察室里。打败维克图斯，然后回到贝蒂娜·比格辛克那里去。",
        },
        rewards = {
            xp = 9950,
            money = 27000,
            referenceItems = {
                {
                    id = 15853,
                },
                {
                    id = 15854,
                },
            },
        },
    },
    [5382] = {
        name = {
            enUS = "Doctor Theolen Krastinov, the Butcher",
            zhCN = "瑟尔林·卡斯迪诺夫教授",
        },
        level = 60,
        min = 55,
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 11216,
            name = {
                enUS = "Eva Sarkhoff",
                zhCN = "艾瓦·萨克霍夫",
            },
            map = 1422,
            x = 70.22,
            y = 73.71,
        },
        finish = {
            kind = "npc",
            id = 11216,
            name = {
                enUS = "Eva Sarkhoff",
                zhCN = "艾瓦·萨克霍夫",
            },
            map = 1422,
            x = 70.22,
            y = 73.71,
        },
        after = { 5515, 5384, 5461, 5462, 5466 },
        summary = {
            enUS = "Find Doctor Theolen Krastinov inside the Scholomance. Destroy him, then burn the Remains of Eva Sarkhoff and the Remains...",
            zhCN = "在通灵学院中找到瑟尔林·卡斯迪诺夫教授。杀死他，并烧毁艾瓦·萨克霍夫和卢森·萨克霍夫的遗体。任务完成后就回到艾瓦·萨克霍夫那儿。",
        },
        rewards = {
            xp = 6600,
        },
    },
    [5384] = {
        name = {
            enUS = "Kirtonos the Herald",
            zhCN = "传令官基尔图诺斯",
        },
        level = 60,
        min = 55,
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 11216,
            name = {
                enUS = "Eva Sarkhoff",
                zhCN = "艾瓦·萨克霍夫",
            },
            map = 1422,
            x = 70.22,
            y = 73.71,
        },
        finish = {
            kind = "npc",
            id = 11216,
            name = {
                enUS = "Eva Sarkhoff",
                zhCN = "艾瓦·萨克霍夫",
            },
            map = 1422,
            x = 70.22,
            y = 73.71,
        },
        before = { 5382, 5515 },
        after = { 5461, 5462, 5463, 5464, 5466 },
        summary = {
            enUS = "Return to the Scholomance with the Blood of Innocents. Find the porch and place the Blood of Innocents in the brazier. Kirtonos will come to...",
            zhCN = "带着无辜者之血回到通灵学院，将它放在门廊的火盆下面，基尔图诺斯会前来吞噬你的灵魂。 勇敢地战斗吧，不要退缩！杀死基尔图诺斯，然后回到艾瓦·萨克霍夫那儿。",
        },
        rewards = {
            xp = 8300,
            referenceItems = {
                {
                    id = 15805,
                },
                {
                    id = 15806,
                },
                {
                    id = 13544,
                },
            },
        },
    },
    [8258] = {
        name = {
            enUS = "The Darkreaver Menace",
            zhCN = "达克雷尔的威胁",
        },
        level = 60,
        min = 58,
        faction = "H",
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 13417,
            name = {
                enUS = "Sagorne Creststrider",
                zhCN = "萨格尼",
            },
            map = 1454,
            x = 38.66,
            y = 35.92,
        },
        finish = {
            kind = "npc",
            id = 13417,
            name = {
                enUS = "Sagorne Creststrider",
                zhCN = "萨格尼",
            },
            map = 1454,
            x = 38.66,
            y = 35.92,
        },
        before = { 7667 },
        summary = {
            enUS = "Use the Divination Scryer in the heart of the Great Ossuary's basement in the Scholomance. Doing so will bring forth spirits you must...",
            zhCN = "在斯坦索姆地下室的尸骨储藏所的中心使用预言水晶球。然后你必须与被召唤出来的幽灵作战。击败这些幽灵之后，死亡骑士达克雷尔才会出现，你的任务就是击败他。 把死亡骑士达克雷尔的头颅交给奥格瑞玛智慧谷的萨格尼。",
        },
    },
    [5505] = {
        name = {
            enUS = "The Key to Scholomance (5505)",
            zhCN = "通灵学院的钥匙",
        },
        level = 60,
        min = 55,
        faction = "A",
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 11056,
            name = {
                enUS = "Alchemist Arbington",
                zhCN = "化学家阿尔比顿",
            },
            map = 1422,
            x = 42.66,
            y = 83.77,
        },
        finish = {
            kind = "npc",
            id = 11056,
            name = {
                enUS = "Alchemist Arbington",
                zhCN = "化学家阿尔比顿",
            },
            map = 1422,
            x = 42.66,
            y = 83.77,
        },
        summary = {
            enUS = "Western Plaguelands Level 60. View quest details and related records.",
            zhCN = "完成骷髅钥匙的锻造，领取通灵学院钥匙。",
        },
    },
    [5511] = {
        name = {
            enUS = "The Key to Scholomance (5511)",
            zhCN = "通灵学院的钥匙",
        },
        level = 60,
        min = 55,
        faction = "H",
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 10837,
            name = {
                enUS = "High Executor Derrington",
                zhCN = "高级执行官德灵顿",
            },
            map = 1420,
            x = 83.13,
            y = 68.94,
        },
        finish = {
            kind = "npc",
            id = 10837,
            name = {
                enUS = "High Executor Derrington",
                zhCN = "高级执行官德灵顿",
            },
            map = 1420,
            x = 83.13,
            y = 68.94,
        },
        summary = {
            enUS = "Western Plaguelands Level 60. View quest details and related records.",
            zhCN = "完成骷髅钥匙的锻造，领取通灵学院钥匙。",
        },
    },
    [5466] = {
        name = {
            enUS = "The Lich, Ras Frostwhisper",
            zhCN = "巫妖莱斯·霜语",
        },
        level = 60,
        min = 57,
        instances = { "scholomance" },
        start = {
            kind = "npc",
            id = 11286,
            name = {
                enUS = "Magistrate Marduke",
                zhCN = "马杜克镇长",
            },
            map = 1422,
            x = 70.57,
            y = 74.11,
        },
        finish = {
            kind = "npc",
            id = 11286,
            name = {
                enUS = "Magistrate Marduke",
                zhCN = "马杜克镇长",
            },
            map = 1422,
            x = 70.57,
            y = 74.11,
        },
        before = { 5382, 5515, 5384, 5461, 5462, 5463, 5464, 5465 },
        summary = {
            enUS = "Find Ras Frostwhisper in the Scholomance. When you have found him, use the Soulbound Keepsake on his undead visage. Should you...",
            zhCN = "在通灵学院里找到莱斯·霜语。当你找到他之后，使用禁锢灵魂的遗物破除其亡灵的外壳。如果你成功地破除了他的不死之身，就杀掉他并拿到莱斯·霜语的头颅。把那个头颅交给马杜克镇长。",
        },
        rewards = {
            xp = 9950,
            referenceItems = {
                {
                    id = 13982,
                },
                {
                    id = 13986,
                },
                {
                    id = 13984,
                },
                {
                    id = 14002,
                },
            },
        },
    },
    [1098] = {
        name = {
            enUS = "Deathstalkers in Shadowfang",
            zhCN = "影牙城堡里的亡灵哨兵",
        },
        level = 25,
        min = 18,
        faction = "H",
        instances = { "shadowfang-keep" },
        start = {
            kind = "npc",
            id = 1952,
            name = {
                enUS = "High Executor Hadrec",
                zhCN = "高级执行官哈德瑞克",
            },
            map = 1421,
            x = 43.42,
            y = 40.86,
        },
        finish = {
            kind = "npc",
            id = 4444,
            name = {
                enUS = "Deathstalker Vincent",
                zhCN = "亡灵哨兵文森特",
            },
        },
        summary = {
            enUS = "Find the Deathstalker Adamant and Deathstalker Vincent.",
            zhCN = "找到亡灵哨兵阿达曼特和亡灵哨兵文森特。",
        },
        rewards = {
            xp = 8700,
            money = 1800,
            items = {
                {
                    id = 3324,
                    count = 1,
                },
                {
                    id = 270023,
                    count = 1,
                },
                {
                    id = 270024,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 100,
                },
            },
        },
    },
    [1740] = {
        name = {
            enUS = "The Orb of Soran'ruk",
            zhCN = "索兰鲁克宝珠",
        },
        level = 25,
        min = 20,
        instances = { "shadowfang-keep", "blackfathom-deeps" },
        start = {
            kind = "npc",
            id = 6247,
            name = {
                enUS = "Doan Karhan",
                zhCN = "杜安·卡汉",
            },
            map = 1413,
            x = 49.31,
            y = 57.21,
        },
        finish = {
            kind = "npc",
            id = 6247,
            name = {
                enUS = "Doan Karhan",
                zhCN = "杜安·卡汉",
            },
            map = 1413,
            x = 49.31,
            y = 57.21,
        },
        summary = {
            enUS = "Find 3 Soran'ruk Fragments and 1 Large Soran'ruk Fragment and return them to Doan Karhan in the Barrens.",
            zhCN = "找到3块索兰鲁克宝珠的碎片和1块索兰鲁克宝珠的大碎片，把它们交给贫瘠之地的杜安·卡汉。",
        },
        objectives = {
            enUS = { "Soran'ruk Fragment ×3", "Large Soran'ruk Fragment" },
            zhCN = { "索兰鲁克宝珠的碎片 ×3", "索兰鲁克宝珠的大碎片" },
        },
        rewards = {
            xp = 7650,
            choices = {
                {
                    id = 6898,
                    count = 1,
                },
                {
                    id = 15109,
                    count = 1,
                },
            },
        },
    },
    [1013] = {
        name = {
            enUS = "The Book of Ur",
            zhCN = "乌尔之书",
        },
        level = 26,
        min = 16,
        faction = "H",
        instances = { "shadowfang-keep" },
        start = {
            kind = "npc",
            id = 2934,
            name = {
                enUS = "Keeper Bel'dugur",
                zhCN = "看守者贝尔杜加",
            },
            map = 1458,
            x = 53.74,
            y = 54.46,
        },
        finish = {
            kind = "npc",
            id = 2934,
            name = {
                enUS = "Keeper Bel'dugur",
                zhCN = "看守者贝尔杜加",
            },
            map = 1458,
            x = 53.74,
            y = 54.46,
        },
        summary = {
            enUS = "Bring the Book of Ur to Keeper Bel'dugur at the Apothecarium in the Undercity.",
            zhCN = "把乌尔之书交给幽暗城炼金区里的看守者贝尔杜加。",
        },
        objectives = {
            enUS = { "The Book of Ur" },
            zhCN = { "乌尔之书" },
        },
        rewards = {
            xp = 9150,
            money = 1400,
            choices = {
                {
                    id = 6335,
                    count = 1,
                },
                {
                    id = 4534,
                    count = 1,
                },
                {
                    id = 270030,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 100,
                },
            },
        },
    },
    [1014] = {
        name = {
            enUS = "Arugal Must Die",
            zhCN = "除掉阿鲁高",
        },
        level = 27,
        min = 18,
        faction = "H",
        instances = { "shadowfang-keep" },
        start = {
            kind = "npc",
            id = 1938,
            name = {
                enUS = "Dalar Dawnweaver",
                zhCN = "达拉尔·道恩维沃尔",
            },
            map = 1421,
            x = 44.2,
            y = 39.81,
        },
        finish = {
            kind = "npc",
            id = 1938,
            name = {
                enUS = "Dalar Dawnweaver",
                zhCN = "达拉尔·道恩维沃尔",
            },
            map = 1421,
            x = 44.2,
            y = 39.81,
        },
        summary = {
            enUS = "Kill Arugal and bring his head to Dalar Dawnweaver at the Sepulcher.",
            zhCN = "杀死阿鲁高，把他的头带给瑟伯切尔的达拉尔·道恩维沃尔。",
        },
        objectives = {
            enUS = { "Head of Arugal" },
            zhCN = { "阿鲁高的头颅" },
        },
        rewards = {
            xp = 14350,
            items = {
                {
                    id = 6414,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 200,
                },
            },
        },
    },
    [386] = {
        name = {
            enUS = "What Comes Around...",
            zhCN = "伸张正义",
        },
        level = 25,
        min = 22,
        faction = "A",
        instances = { "stockade" },
        start = {
            kind = "npc",
            id = 859,
            name = {
                enUS = "Guard Berton",
                zhCN = "卫兵伯尔顿",
            },
            map = 1433,
            x = 26.26,
            y = 46.58,
        },
        finish = {
            kind = "npc",
            id = 859,
            name = {
                enUS = "Guard Berton",
                zhCN = "卫兵伯尔顿",
            },
            map = 1433,
            x = 26.26,
            y = 46.58,
        },
        summary = {
            enUS = "Bring the head of Targorr the Dread to Guard Berton in Lakeshire.",
            zhCN = "把塔格尔的头颅带给湖畔镇的卫兵伯尔顿。",
        },
        objectives = {
            enUS = { "Head of Targorr" },
            zhCN = { "塔格尔的头颅" },
        },
        rewards = {
            xp = 6400,
            choices = {
                {
                    id = 3400,
                    count = 1,
                },
                {
                    id = 1317,
                    count = 1,
                },
                {
                    id = 270027,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 100,
                },
            },
        },
    },
    [377] = {
        name = {
            enUS = "Crime and Punishment",
            zhCN = "罪与罚",
        },
        level = 26,
        min = 22,
        faction = "A",
        instances = { "stockade" },
        start = {
            kind = "npc",
            id = 270,
            name = {
                enUS = "Councilman Millstipe",
                zhCN = "议员米尔斯迪普",
            },
            map = 1431,
            x = 71.92,
            y = 47.79,
        },
        finish = {
            kind = "npc",
            id = 270,
            name = {
                enUS = "Councilman Millstipe",
                zhCN = "议员米尔斯迪普",
            },
            map = 1431,
            x = 71.92,
            y = 47.79,
        },
        summary = {
            enUS = "Councilman Millstipe of Darkshire wants you to bring him the hand of Dextren Ward.",
            zhCN = "夜色镇的米尔斯迪普议员要你杀死迪克斯特·瓦德，并把他的手带回来作为证明。",
        },
        objectives = {
            enUS = { "Hand of Dextren Ward" },
            zhCN = { "迪克斯特·瓦德的手掌" },
        },
        rewards = {
            xp = 6700,
            choices = {
                {
                    id = 2033,
                    count = 1,
                },
                {
                    id = 2906,
                    count = 1,
                },
                {
                    id = 270029,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 100,
                },
            },
        },
    },
    [387] = {
        name = {
            enUS = "Quell the Uprising",
            zhCN = "镇压暴动",
        },
        level = 26,
        min = 22,
        faction = "A",
        instances = { "stockade" },
        start = {
            kind = "npc",
            id = 1719,
            name = {
                enUS = "Warden Thelwater",
                zhCN = "典狱官塞尔沃特",
            },
            map = 1453,
            x = 51.8,
            y = 69.3,
        },
        finish = {
            kind = "npc",
            id = 1719,
            name = {
                enUS = "Warden Thelwater",
                zhCN = "典狱官塞尔沃特",
            },
            map = 1453,
            x = 51.8,
            y = 69.3,
        },
        summary = {
            enUS = "Warden Thelwater of Stormwind wants you to kill 10 Defias Prisoners, 8 Defias Convicts, and 8 Defias Insurgents in The Stockade.",
            zhCN = "暴风城的典狱官塞尔沃特要求你杀死监狱中的10名迪菲亚囚徒、8名迪菲亚罪犯和8名迪菲亚叛军。",
        },
        objectives = {
            enUS = { "Defias Prisoner ×10", "Defias Convict ×8", "Defias Insurgent ×8" },
            zhCN = { "迪菲亚囚徒 ×10", "迪菲亚罪犯 ×8", "迪菲亚叛军 ×8" },
        },
        rewards = {
            xp = 8500,
            money = 4000,
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 150,
                },
            },
        },
    },
    [388] = {
        name = {
            enUS = "The Color of Blood",
            zhCN = "鲜血的颜色",
        },
        level = 26,
        min = 22,
        faction = "A",
        instances = { "stockade" },
        start = {
            kind = "npc",
            id = 1721,
            name = {
                enUS = "Nikova Raskol",
                zhCN = "尼科瓦·拉斯克",
            },
            map = 1453,
            x = 72.6,
            y = 55.5,
        },
        finish = {
            kind = "npc",
            id = 1721,
            name = {
                enUS = "Nikova Raskol",
                zhCN = "尼科瓦·拉斯克",
            },
            map = 1453,
            x = 72.6,
            y = 55.5,
        },
        summary = {
            enUS = "Nikova Raskol of Stormwind wants you to collect 10 Red Wool Bandanas.",
            zhCN = "暴风城的尼科瓦·拉斯克要你取得10条红色毛纺面罩。",
        },
        objectives = {
            enUS = { "Red Wool Bandana ×10" },
            zhCN = { "红色毛纺面罩 ×10" },
        },
        rewards = {
            xp = 8500,
            money = 4000,
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 150,
                },
            },
        },
    },
    [378] = {
        name = {
            enUS = "The Fury Runs Deep",
            zhCN = "卡姆·深怒",
        },
        level = 27,
        min = 22,
        faction = "A",
        instances = { "stockade" },
        start = {
            kind = "npc",
            id = 1074,
            name = {
                enUS = "Motley Garmason",
                zhCN = "莫特雷·加玛森",
            },
            map = 1437,
            x = 49.67,
            y = 18.23,
        },
        finish = {
            kind = "npc",
            id = 1074,
            name = {
                enUS = "Motley Garmason",
                zhCN = "莫特雷·加玛森",
            },
            map = 1437,
            x = 49.67,
            y = 18.23,
        },
        before = { 303 },
        summary = {
            enUS = "Motley Garmason wants Kam Deepfury's head brought to him at Dun Modr.",
            zhCN = "丹莫德的莫特雷·加玛森要求你把卡姆·深怒的头颅交给他。",
        },
        rewards = {
            xp = 2750,
            referenceItems = {
                {
                    id = 3562,
                },
                {
                    id = 1264,
                },
            },
        },
    },
    [391] = {
        name = {
            enUS = "The Stockade Riots",
            zhCN = "监狱暴动",
        },
        level = 29,
        min = 16,
        faction = "A",
        instances = { "stockade" },
        start = {
            kind = "npc",
            id = 1719,
            name = {
                enUS = "Warden Thelwater",
                zhCN = "典狱官塞尔沃特",
            },
            map = 1453,
            x = 51.8,
            y = 69.3,
        },
        finish = {
            kind = "npc",
            id = 1719,
            name = {
                enUS = "Warden Thelwater",
                zhCN = "典狱官塞尔沃特",
            },
            map = 1453,
            x = 51.8,
            y = 69.3,
        },
        before = { 373, 389 },
        after = { 392, 393, 350, 2745 },
        summary = {
            enUS = "Kill Bazil Thredd and bring his head back to Warden Thelwater at the Stockade.",
            zhCN = "杀死巴基尔·斯瑞德，把他的头带给监狱的典狱官塞尔沃特。",
        },
        objectives = {
            enUS = { "Head of Bazil Thredd" },
            zhCN = { "巴基尔·斯瑞德的头颅" },
        },
        rewards = {
            xp = 7500,
            money = 2500,
            reputation = {
                {
                    name = {
                        enUS = "Stormwind",
                        zhCN = "暴风城",
                    },
                    value = 100,
                },
            },
        },
    },
    [5542] = {
        name = {
            enUS = "Demon Dogs",
            zhCN = "恶魔之犬",
        },
        level = 56,
        min = 52,
        instances = { "stratholme" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 1855,
            name = {
                enUS = "Tirion Fordring",
                zhCN = "提里奥·弗丁",
            },
            map = 1423,
            x = 7.57,
            y = 43.7,
        },
        finish = {
            kind = "npc",
            id = 1855,
            name = {
                enUS = "Tirion Fordring",
                zhCN = "提里奥·弗丁",
            },
            map = 1423,
            x = 7.57,
            y = 43.7,
        },
        after = { 5742 },
        summary = {
            enUS = "Slay 20 Plaguehound Runts, 5 Plaguehounds and 5 Frenzied Plaguehounds. Return to Tirion Fordring when the task is complete.",
            zhCN = "杀掉20条瘟疫幼犬、5条瘟疫犬和5条狂怒的瘟疫犬。任务完成之后向提里奥·弗丁复命。",
        },
    },
    [5845] = {
        name = {
            enUS = "Of Lost Honor",
            zhCN = "失落的荣耀",
        },
        level = 58,
        min = 52,
        instances = { "stratholme" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 1855,
            name = {
                enUS = "Tirion Fordring",
                zhCN = "提里奥·弗丁",
            },
            map = 1423,
            x = 7.57,
            y = 43.7,
        },
        finish = {
            kind = "npc",
            id = 1855,
            name = {
                enUS = "Tirion Fordring",
                zhCN = "提里奥·弗丁",
            },
            map = 1423,
            x = 7.57,
            y = 43.7,
        },
        after = { 5846 },
        summary = {
            enUS = "Travel to Northdale, in the northeastern region of the Eastern Plaguelands, and recover the Symbol of Lost Honor. Return to Tirion Fordring upon...",
            zhCN = "到东瘟疫之地东北部的北谷去，找到失落荣耀的象征。完成目标之后向提里奥·弗丁复命。",
        },
    },
    [5263] = {
        name = {
            enUS = "Above and Beyond",
            zhCN = "超越",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 11039,
            name = {
                enUS = "Duke Nicholas Zverenhoff",
                zhCN = "尼古拉斯·瑟伦霍夫公爵",
            },
            map = 1423,
            x = 81.44,
            y = 59.82,
        },
        finish = {
            kind = "npc",
            id = 11039,
            name = {
                enUS = "Duke Nicholas Zverenhoff",
                zhCN = "尼古拉斯·瑟伦霍夫公爵",
            },
            map = 1423,
            x = 81.44,
            y = 59.82,
        },
        before = { 5251, 5262 },
        after = { 5264, 5265 },
        summary = {
            enUS = "Venture to Stratholme and destroy Baron Rivendare. Take his head and return to Duke Nicholas Zverenhoff.",
            zhCN = "到斯坦索姆去杀掉瑞文戴尔男爵，把他的头颅交给尼古拉斯·瑟伦霍夫公爵。",
        },
        rewards = {
            xp = 8300,
        },
    },
    [5125] = {
        name = {
            enUS = "Aurius' Reckoning",
            zhCN = "奥里克斯的清算",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 10917,
            name = {
                enUS = "Aurius",
                zhCN = "奥里克斯",
            },
            map = 2017,
            x = 72.9,
            y = 61.7,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 10917,
            name = {
                enUS = "Aurius",
                zhCN = "奥里克斯",
            },
        },
        before = { 5122 },
        summary = {
            enUS = "Stratholme Level 60. View quest details and related records.",
            zhCN = "消灭瑞文戴尔男爵，完成奥里克斯的清算。",
        },
        rewards = {
            xp = 9950,
            referenceItems = {
                {
                    id = 17044,
                },
                {
                    id = 17045,
                },
            },
        },
    },
    [4941] = {
        name = {
            enUS = "Eitrigg's Wisdom",
            zhCN = "伊崔格的智慧",
        },
        level = 60,
        min = 55,
        faction = "H",
        instances = { "stratholme" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 9077,
            name = {
                enUS = "Warlord Goretooth",
                zhCN = "军官高图斯",
            },
            map = 1418,
            x = 5.81,
            y = 47.52,
        },
        finish = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        summary = {
            enUS = "Speak with Eitrigg in Orgrimmar. When you have discussed matters with Eitrigg, seek council from Thrall. You recall having seen Eitrigg in...",
            zhCN = "和奥格瑞玛的伊崔格谈一谈。讨论完毕后，咨询萨尔的意见。 你回忆起曾在萨尔的大厅中见过伊崔格。",
        },
    },
    [5243] = {
        name = {
            enUS = "Houses of the Holy",
            zhCN = "神圣之屋",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 11036,
            name = {
                enUS = "Leonid Barthalomew the Revered",
                zhCN = "莱尼德·巴萨罗梅",
            },
            map = 1423,
            x = 81.73,
            y = 57.83,
        },
        finish = {
            kind = "npc",
            id = 11036,
            name = {
                enUS = "Leonid Barthalomew the Revered",
                zhCN = "莱尼德·巴萨罗梅",
            },
            map = 1423,
            x = 81.73,
            y = 57.83,
        },
        summary = {
            enUS = "Travel to Stratholme, in the north. Search the supply crates that litter the city and recover 5 Stratholme Holy Water. Return to Leonid...",
            zhCN = "到北方的斯坦索姆去，寻找散落在城市中的补给箱，并收集5瓶斯坦索姆圣水。当你找到足够的圣水之后就回去向莱尼德·巴萨罗梅复命。",
        },
        rewards = {
            xp = 6600,
            money = 18000,
            referenceItems = {
                {
                    id = 13216,
                },
                {
                    id = 13217,
                },
                {
                    id = 3928,
                },
                {
                    id = 6149,
                },
            },
        },
    },
    [5213] = {
        name = {
            enUS = "The Active Agent",
            zhCN = "活跃的探子",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 11035,
            name = {
                enUS = "Betina Bigglezink",
                zhCN = "贝蒂娜·比格辛克",
            },
            map = 1423,
            x = 81.47,
            y = 59.66,
        },
        finish = {
            kind = "npc",
            id = 11035,
            name = {
                enUS = "Betina Bigglezink",
                zhCN = "贝蒂娜·比格辛克",
            },
            map = 1423,
            x = 81.47,
            y = 59.66,
        },
        before = { 5212 },
        summary = {
            enUS = "Travel to Stratholme and search the ziggurats. Find and return new Scourge Data to Betina Bigglezink.",
            zhCN = "到斯坦索姆去探索那里的通灵塔。找到新的天灾军团档案，把它交给贝蒂娜·比格辛克。",
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 13209,
                },
                {
                    id = 19812,
                },
            },
        },
    },
    [5251] = {
        name = {
            enUS = "The Archivist",
            zhCN = "档案管理员",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 11039,
            name = {
                enUS = "Duke Nicholas Zverenhoff",
                zhCN = "尼古拉斯·瑟伦霍夫公爵",
            },
            map = 1423,
            x = 81.44,
            y = 59.82,
        },
        finish = {
            kind = "npc",
            id = 11039,
            name = {
                enUS = "Duke Nicholas Zverenhoff",
                zhCN = "尼古拉斯·瑟伦霍夫公爵",
            },
            map = 1423,
            x = 81.44,
            y = 59.82,
        },
        after = { 5262, 5263, 5264, 5265 },
        summary = {
            enUS = "Travel to Stratholme and find Archivist Galford of the Scarlet Crusade. Destroy him and burn down the Scarlet Archive.",
            zhCN = "在斯坦索姆城中找到血色十字军的档案管理员加尔福特，杀掉他，然后烧毁血色十字军档案。",
        },
        rewards = {
            xp = 8300,
            money = 18000,
        },
    },
    [5212] = {
        name = {
            enUS = "The Flesh Does Not Lie",
            zhCN = "血肉不会撒谎",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 11035,
            name = {
                enUS = "Betina Bigglezink",
                zhCN = "贝蒂娜·比格辛克",
            },
            map = 1423,
            x = 81.47,
            y = 59.66,
        },
        finish = {
            kind = "npc",
            id = 11035,
            name = {
                enUS = "Betina Bigglezink",
                zhCN = "贝蒂娜·比格辛克",
            },
            map = 1423,
            x = 81.47,
            y = 59.66,
        },
        after = { 5213 },
        summary = {
            enUS = "Recover 10 Plagued Flesh Samples from Stratholme and return them to Betina Bigglezink. You suspect that any creature in Stratholme would...",
            zhCN = "从斯坦索姆找回20个瘟疫肉块，并把它们交给贝蒂娜·比格辛克。你觉得斯坦索姆中的生灵都不大可能长着肉……",
        },
        rewards = {
            xp = 6600,
            money = 18000,
        },
    },
    [5214] = {
        name = {
            enUS = "The Great Fras Siabi",
            zhCN = "了不起的艾兹拉·格里姆",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 11033,
            name = {
                enUS = "Smokey LaRue",
                zhCN = "烟鬼拉鲁恩",
            },
            map = 1423,
            x = 80.61,
            y = 57.98,
        },
        finish = {
            kind = "npc",
            id = 11033,
            name = {
                enUS = "Smokey LaRue",
                zhCN = "烟鬼拉鲁恩",
            },
            map = 1423,
            x = 80.61,
            y = 57.98,
        },
        summary = {
            enUS = "Find Fras Siabi's smoke shop in Stratholme and recover a box of Siabi's Premium Tobacco. Return to Smokey LaRue when the job is done.",
            zhCN = "找到艾兹拉·格里姆在斯坦索姆的烟草店，并从中找回一盒格里姆的优质香烟，把它交给烟鬼拉鲁恩。",
        },
        rewards = {
            xp = 8300,
            referenceItems = {
                {
                    id = 13171,
                },
            },
        },
    },
    [5281] = {
        name = {
            enUS = "The Restless Souls (5281)",
            zhCN = "永不安息的灵魂",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "unassigned" },
        start = {
            kind = "npc",
            id = 11038,
            name = {
                enUS = "Caretaker Alen",
                zhCN = "护理者奥林",
            },
            map = 1423,
            x = 79.55,
            y = 63.86,
        },
        finish = {
            kind = "npc",
            id = 11140,
            name = {
                enUS = "Egan",
                zhCN = "埃根",
            },
            map = 1423,
            x = 14.45,
            y = 33.74,
        },
        after = { 5282 },
        summary = {
            enUS = "Find Egan. You only know that he was last seen around Stratholme.",
            zhCN = "找到埃根。你只知道他在斯坦索姆附近。",
        },
    },
    [5282] = {
        name = {
            enUS = "The Restless Souls (5282)",
            zhCN = "永不安息的灵魂",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "npc",
            id = 11140,
            name = {
                enUS = "Egan",
                zhCN = "埃根",
            },
            map = 1423,
            x = 14.45,
            y = 33.74,
        },
        finish = {
            kind = "npc",
            id = 11140,
            name = {
                enUS = "Egan",
                zhCN = "埃根",
            },
            map = 1423,
            x = 14.45,
            y = 33.74,
        },
        before = { 5281 },
        summary = {
            enUS = "Use Egan's Blaster on the ghostly and spectral citizens of Stratholme. When the restless souls break free from their ghostly shells,...",
            zhCN = "对斯坦索姆城中的鬼魂使用埃根的冲击器。当那些永不安息的灵魂挣脱他们的外壳时，再次使用埃根的冲击器——他们就可以获得自由了！ 解放15个永不安息的灵魂，然后回到埃根那里去。",
        },
        rewards = {
            xp = 8300,
            money = 18000,
            referenceItems = {
                {
                    id = 13315,
                },
            },
        },
    },
    [5262] = {
        name = {
            enUS = "The Truth Comes Crashing Down",
            zhCN = "可怕的真相",
        },
        level = 60,
        min = 55,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate", "main-gate" },
        start = {
            kind = "item",
            id = 13250,
            name = {
                enUS = "Head of Balnazzar",
                zhCN = "巴纳扎尔的头颅",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 11039,
            name = {
                enUS = "Duke Nicholas Zverenhoff",
                zhCN = "尼古拉斯·瑟伦霍夫公爵",
            },
            map = 1423,
            x = 81.44,
            y = 59.82,
        },
        before = { 5251 },
        after = { 5263, 5264, 5265 },
        summary = {
            enUS = "Take the Head of Balnazzar to Duke Nicholas Zverenhoff in the Eastern Plaguelands.",
            zhCN = "将巴纳扎尔的头颅交给东瘟疫之地的尼古拉斯·瑟伦霍夫公爵。",
        },
        rewards = {
            xp = 8300,
        },
    },
    [1475] = {
        name = {
            enUS = "Into The Temple of Atal'Hakkar",
            zhCN = "进入阿塔哈卡神庙",
        },
        level = 50,
        min = 41,
        faction = "A",
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 5384,
            name = {
                enUS = "Brohann Caskbelly",
                zhCN = "布罗哈恩·铁桶",
            },
            map = 1453,
            x = 70.2,
            y = 40.7,
        },
        finish = {
            kind = "npc",
            id = 5384,
            name = {
                enUS = "Brohann Caskbelly",
                zhCN = "布罗哈恩·铁桶",
            },
            map = 1453,
            x = 70.2,
            y = 40.7,
        },
        before = { 1448, 1449, 1450, 1451, 1452, 1469 },
        summary = {
            enUS = "Gather 10 Atal'ai Tablets for Brohann Caskbelly in Stormwind.",
            zhCN = "为暴风城的布罗哈恩·铁桶收集10块阿塔莱石板。",
        },
        rewards = {
            xp = 7100,
            referenceItems = {
                {
                    id = 1490,
                },
            },
        },
    },
    [4787] = {
        name = {
            enUS = "The Ancient Egg",
            zhCN = "远古之卵",
        },
        level = 50,
        min = 40,
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 8579,
            name = {
                enUS = "Yeh'kinya",
                zhCN = "叶基亚",
            },
            map = 1446,
            x = 66.99,
            y = 22.36,
        },
        finish = {
            kind = "npc",
            id = 8579,
            name = {
                enUS = "Yeh'kinya",
                zhCN = "叶基亚",
            },
            map = 1446,
            x = 66.99,
            y = 22.36,
        },
        after = { 4788, 3528 },
        summary = {
            enUS = "Bring the Ancient Egg to Yeh'kinya in Tanaris.",
            zhCN = "将远古之卵交给塔纳利斯的叶基亚。",
        },
    },
    [1445] = {
        name = {
            enUS = "The Temple of Atal'Hakkar",
            zhCN = "阿塔哈卡神庙",
        },
        level = 50,
        min = 38,
        faction = "H",
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 1443,
            name = {
                enUS = "Fel'zerul",
                zhCN = "费泽鲁尔",
            },
            map = 1435,
            x = 47.93,
            y = 54.78,
        },
        finish = {
            kind = "npc",
            id = 1443,
            name = {
                enUS = "Fel'zerul",
                zhCN = "费泽鲁尔",
            },
            map = 1435,
            x = 47.93,
            y = 54.78,
        },
        before = { 1424, 1429, 1444 },
        summary = {
            enUS = "Collect 20 Fetishes of Hakkar and bring them to Fel'Zerul in Stonard.",
            zhCN = "收集20个哈卡神像，把它们带给斯通纳德的费泽鲁尔。",
        },
        rewards = {
            xp = 5900,
            referenceItems = {
                {
                    id = 1490,
                },
            },
        },
    },
    [3446] = {
        name = {
            enUS = "Into the Depths",
            zhCN = "深入神庙",
        },
        level = 51,
        min = 46,
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 7771,
            name = {
                enUS = "Marvon Rivetseeker",
                zhCN = "玛尔冯·瑞文斯克",
            },
            map = 1446,
            x = 52.71,
            y = 45.92,
        },
        finish = {
            kind = "object",
            id = 148836,
            name = {
                enUS = "Altar of Hakkar",
                zhCN = "哈卡祭坛",
            },
        },
        before = { 3380, 3444 },
        after = { 3447 },
        summary = {
            enUS = "Find the Altar of Hakkar in the Sunken Temple in Swamp of Sorrows.",
            zhCN = "在悲伤沼泽沉没的神庙中找到哈卡祭坛。",
        },
        rewards = {
            xp = 4900,
        },
    },
    [3447] = {
        name = {
            enUS = "Secret of the Circle",
            zhCN = "雕像群的秘密",
        },
        level = 51,
        min = 46,
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 7771,
            name = {
                enUS = "Marvon Rivetseeker",
                zhCN = "玛尔冯·瑞文斯克",
            },
            map = 1446,
            x = 52.71,
            y = 45.92,
        },
        finish = {
            kind = "object",
            id = 148838,
            name = {
                enUS = "Idol of Hakkar",
                zhCN = "哈卡神像",
            },
        },
        before = { 3380, 3444, 3446 },
        summary = {
            enUS = "Travel into the Sunken Temple and discover the secret hidden in the circle of statues.",
            zhCN = "到沉没的神庙去，揭开雕像群中隐藏的秘密。",
        },
        rewards = {
            xp = 6100,
            referenceItems = {
                {
                    id = 10773,
                },
            },
        },
    },
    [4143] = {
        name = {
            enUS = "Haze of Evil",
            zhCN = "邪恶之雾",
        },
        level = 52,
        min = 47,
        faction = "A",
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 7775,
            name = {
                enUS = "Gregan Brewspewer",
                zhCN = "格雷甘·山酒",
            },
            map = 1444,
            x = 45.12,
            y = 25.57,
        },
        finish = {
            kind = "npc",
            id = 9119,
            name = {
                enUS = "Muigin",
                zhCN = "穆尔金",
            },
            map = 1449,
            x = 42.94,
            y = 9.64,
        },
        before = { 4141, 4142 },
        after = { 4144 },
        summary = {
            enUS = "Collect 5 samples of Atal'ai Haze, then return to Muigin in Un'Goro Crater.",
            zhCN = "收集5份阿塔莱之雾的样本，然后向安戈洛环形山的穆尔金复命。",
        },
    },
    [4146] = {
        name = {
            enUS = "Zapper Fuel",
            zhCN = "除草器的燃料",
        },
        level = 52,
        min = 47,
        faction = "H",
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 8496,
            name = {
                enUS = "Liv Rizzlefix",
                zhCN = "莉芙·雷兹菲克斯",
            },
            map = 1413,
            x = 62.45,
            y = 38.73,
        },
        finish = {
            kind = "npc",
            id = 9118,
            name = {
                enUS = "Larion",
                zhCN = "拉瑞安",
            },
            map = 1449,
            x = 45.54,
            y = 8.72,
        },
        summary = {
            enUS = "Deliver the Unloaded Zapper and 5 samples of Atal'ai Haze to Larion in Marshal's Refuge.",
            zhCN = "收集5份阿塔莱之雾的样本，然后将它们送到马绍尔营地的拉瑞安那里。",
        },
        rewards = {
            xp = 5100,
        },
    },
    [1446] = {
        name = {
            enUS = "Jammal'an the Prophet",
            zhCN = "预言者迦玛兰",
        },
        level = 53,
        min = 38,
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 5598,
            name = {
                enUS = "Atal'ai Exile",
                zhCN = "阿塔莱流放者",
            },
            map = 1425,
            x = 33.75,
            y = 75.21,
        },
        finish = {
            kind = "npc",
            id = 5598,
            name = {
                enUS = "Atal'ai Exile",
                zhCN = "阿塔莱流放者",
            },
            map = 1425,
            x = 33.75,
            y = 75.21,
        },
        summary = {
            enUS = "The Atal'ai Exile in The Hinterlands wants the Head of Jammal'an.",
            zhCN = "辛特兰的阿塔莱流放者要你给他带回迦玛兰的头。",
        },
        rewards = {
            xp = 6550,
            referenceItems = {
                {
                    id = 11123,
                },
                {
                    id = 11124,
                },
            },
        },
    },
    [3528] = {
        name = {
            enUS = "The God Hakkar",
            zhCN = "神灵哈卡",
        },
        level = 53,
        min = 40,
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "npc",
            id = 8579,
            name = {
                enUS = "Yeh'kinya",
                zhCN = "叶基亚",
            },
            map = 1446,
            x = 66.99,
            y = 22.36,
        },
        finish = {
            kind = "npc",
            id = 8579,
            name = {
                enUS = "Yeh'kinya",
                zhCN = "叶基亚",
            },
            map = 1446,
            x = 66.99,
            y = 22.36,
        },
        before = { 3520, 3527, 4787 },
        after = { 5065, 4788, 8181, 8182 },
        summary = {
            enUS = "Bring the Filled Egg of Hakkar to Yeh'kinya in Tanaris.",
            zhCN = "将装满的哈卡之卵交给塔纳利斯的叶基亚。",
        },
        rewards = {
            xp = 7900,
            money = 24000,
            referenceItems = {
                {
                    id = 10749,
                },
                {
                    id = 10750,
                },
                {
                    id = 10751,
                },
            },
        },
    },
    [3373] = {
        name = {
            enUS = "The Essence of Eranikus (3373)",
            zhCN = "伊兰尼库斯精华",
        },
        level = 55,
        min = 48,
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "item",
            id = 10454,
            name = {
                enUS = "Essence of Eranikus",
                zhCN = "伊兰尼库斯精华",
            },
        },
        inside = true,
        finish = {
            kind = "object",
            id = 148512,
            name = {
                enUS = "Essence Font",
                zhCN = "精华之泉",
            },
        },
        after = { 3374, 3512 },
        summary = {
            enUS = "Place the Essence of Eranikus in the Essence Font located in this lair in the Sunken Temple.",
            zhCN = "把伊兰尼库斯精华放在精华之泉里，精华之泉就在沉没的神庙中，伊兰尼库斯的巢穴里。",
        },
        rewards = {
            xp = 2800,
            referenceItems = {
                {
                    id = 10455,
                },
            },
        },
    },
    [3374] = {
        name = {
            enUS = "The Essence of Eranikus (3374)",
            zhCN = "伊兰尼库斯精华",
        },
        level = 55,
        min = 48,
        instances = { "temple-of-atalhakkar" },
        start = {
            kind = "item",
            id = 10589,
            name = {
                enUS = "Oathstone of Ysera's Dragonflight",
                zhCN = "伊瑟拉巨龙军团的誓言石",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 5353,
            name = {
                enUS = "Itharius",
                zhCN = "伊萨里奥斯",
            },
            map = 1435,
            x = 13.67,
            y = 71.72,
        },
        summary = {
            enUS = "Bring the Oathstone of Ysera's Dragonflight and the Chained Essence of Eranikus to Itharius in the Swamp of Sorrows. It is there...",
            zhCN = "把伊瑟拉巨龙军团的誓言石和被禁锢的伊兰尼库斯精华交给悲伤沼泽的伊萨里奥斯。在那里你可以决定是否要帮助伊瑟拉的绿龙军团。",
        },
    },
    [720] = {
        name = {
            enUS = "A Sign of Hope (720)",
            zhCN = "一线希望",
        },
        level = 35,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "object",
            id = 2868,
            name = {
                enUS = "Crumpled Map",
                zhCN = "弄皱的地图",
            },
            map = 1418,
            x = 53.03,
            y = 33.94,
        },
        finish = {
            kind = "npc",
            id = 2910,
            name = {
                enUS = "Prospector Ryedol",
                zhCN = "勘察员雷杜尔",
            },
            map = 1418,
            x = 53.42,
            y = 43.39,
        },
        after = { 721, 722, 1139 },
        summary = {
            enUS = "Find Prospector Ryedol and let him know Hammertoe Grez is alive.",
            zhCN = "找到勘察员雷杜尔，告诉他铁趾格雷兹还活着。",
        },
    },
    [721] = {
        name = {
            enUS = "A Sign of Hope (721)",
            zhCN = "一线希望",
        },
        level = 35,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 2910,
            name = {
                enUS = "Prospector Ryedol",
                zhCN = "勘察员雷杜尔",
            },
            map = 1418,
            x = 53.42,
            y = 43.39,
        },
        finish = {
            kind = "npc",
            id = 2909,
            name = {
                enUS = "Hammertoe Grez",
                zhCN = "铁趾格雷兹",
            },
            map = 1432,
            x = 37.28,
            y = 85.78,
        },
        before = { 720 },
        after = { 722, 723, 724, 725, 1139 },
        summary = {
            enUS = "Find Hammertoe Grez in Uldaman.",
            zhCN = "在奥达曼找到铁趾格雷兹。",
        },
    },
    [2418] = {
        name = {
            enUS = "Power Stones",
            zhCN = "能量石",
        },
        level = 36,
        min = 30,
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 2817,
            name = {
                enUS = "Rigglefuzz",
                zhCN = "里格弗兹",
            },
            map = 1418,
            x = 42.39,
            y = 52.93,
        },
        finish = {
            kind = "npc",
            id = 2817,
            name = {
                enUS = "Rigglefuzz",
                zhCN = "里格弗兹",
            },
            map = 1418,
            x = 42.39,
            y = 52.93,
        },
        summary = {
            enUS = "Bring 8 Dentrium Power Stones and 8 An'Alleum Power Stones to Rigglefuzz in the Badlands.",
            zhCN = "给荒芜之地的里格弗兹带去8块德提亚姆能量石和8块安纳洛姆能量石。",
        },
        rewards = {
            xp = 3500,
            referenceItems = {
                {
                    id = 9522,
                },
                {
                    id = 10358,
                },
                {
                    id = 10359,
                },
            },
        },
    },
    [707] = {
        name = {
            enUS = "Ironband Wants You!",
            zhCN = "铁环挖掘场需要你！",
        },
        level = 37,
        min = 30,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 1356,
            name = {
                enUS = "Prospector Stormpike",
                zhCN = "勘察员塔伯斯·雷矛",
            },
            map = 1455,
            x = 74.64,
            y = 11.74,
        },
        finish = {
            kind = "npc",
            id = 1344,
            name = {
                enUS = "Prospector Ironband",
                zhCN = "勘察员基恩萨·铁环",
            },
            map = 1432,
            x = 65.93,
            y = 65.62,
        },
        after = { 704 },
        summary = {
            enUS = "Speak with Prospector Ironband at Ironband's Excavation Site in Loch Modan.",
            zhCN = "和洛克莫丹铁环挖掘场的勘察员基恩萨·铁环谈一谈。",
        },
    },
    [704] = {
        name = {
            enUS = "Agmond's Fate",
            zhCN = "阿戈莫德的命运",
        },
        level = 38,
        min = 30,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 1344,
            name = {
                enUS = "Prospector Ironband",
                zhCN = "勘察员基恩萨·铁环",
            },
            map = 1432,
            x = 65.93,
            y = 65.62,
        },
        finish = {
            kind = "npc",
            id = 1344,
            name = {
                enUS = "Prospector Ironband",
                zhCN = "勘察员基恩萨·铁环",
            },
            map = 1432,
            x = 65.93,
            y = 65.62,
        },
        before = { 707, 738, 739 },
        summary = {
            enUS = "Bring 4 Carved Stone Urns to Prospector Ironband in Loch Modan.",
            zhCN = "收集4个雕纹石罐，把它们交给洛克莫丹的勘察员基恩萨·铁环。",
        },
        rewards = {
            xp = 2850,
            referenceItems = {
                {
                    id = 4980,
                },
            },
        },
    },
    [738] = {
        name = {
            enUS = "Find Agmond",
            zhCN = "寻找阿戈莫德",
        },
        level = 38,
        min = 30,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 1344,
            name = {
                enUS = "Prospector Ironband",
                zhCN = "勘察员基恩萨·铁环",
            },
            map = 1432,
            x = 65.93,
            y = 65.62,
        },
        finish = {
            kind = "object",
            id = 2875,
            name = {
                enUS = "Battered Dwarven Skeleton",
                zhCN = "残破的矮人骸骨",
            },
            map = 1418,
            x = 50.89,
            y = 62.4,
        },
        after = { 704 },
        summary = {
            enUS = "Find Agmond.",
            zhCN = "找到阿戈莫德。",
        },
    },
    [722] = {
        name = {
            enUS = "Amulet of Secrets",
            zhCN = "铁趾的护符",
        },
        level = 40,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 2909,
            name = {
                enUS = "Hammertoe Grez",
                zhCN = "铁趾格雷兹",
            },
            map = 1432,
            x = 37.28,
            y = 85.78,
        },
        finish = {
            kind = "npc",
            id = 2909,
            name = {
                enUS = "Hammertoe Grez",
                zhCN = "铁趾格雷兹",
            },
            map = 1432,
            x = 37.28,
            y = 85.78,
        },
        before = { 720, 721 },
        after = { 723, 724, 725, 726, 1139 },
        summary = {
            enUS = "Find Hammertoe's Amulet and return it to him in Uldaman.",
            zhCN = "找到铁趾的护符，把它交给奥达曼的铁趾。",
        },
        rewards = {
            xp = 3150,
        },
    },
    [1956] = {
        name = {
            enUS = "Power in Uldaman",
            zhCN = "奥达曼的能量源",
        },
        level = 40,
        min = 35,
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        finish = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        before = { 1953, 1954, 1955 },
        after = { 1957, 1958 },
        summary = {
            enUS = "Retrieve an Obsidian Power Source and bring it to Tabetha in Dustwallow Marsh.",
            zhCN = "找到一个黑曜石能量源，将其交给尘泥沼泽的塔贝萨。",
        },
    },
    [723] = {
        name = {
            enUS = "Prospect of Faith (723)",
            zhCN = "铁趾的遗愿",
        },
        level = 40,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 2909,
            name = {
                enUS = "Hammertoe Grez",
                zhCN = "铁趾格雷兹",
            },
            map = 1432,
            x = 37.28,
            y = 85.78,
        },
        finish = {
            kind = "npc",
            id = 2910,
            name = {
                enUS = "Prospector Ryedol",
                zhCN = "勘察员雷杜尔",
            },
            map = 1418,
            x = 53.42,
            y = 43.39,
        },
        after = { 1139 },
        summary = {
            enUS = "Take Hammertoe's Amulet to Prospector Ryedol in the Badlands.",
            zhCN = "把铁趾的护符交给荒芜之地的勘察员雷杜恩。",
        },
    },
    [724] = {
        name = {
            enUS = "Prospect of Faith (724)",
            zhCN = "铁趾的遗愿",
        },
        level = 40,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 2910,
            name = {
                enUS = "Prospector Ryedol",
                zhCN = "勘察员雷杜尔",
            },
            map = 1418,
            x = 53.42,
            y = 43.39,
        },
        finish = {
            kind = "npc",
            id = 2916,
            name = {
                enUS = "Historian Karnik",
                zhCN = "史学家卡尼克",
            },
            map = 1455,
            x = 77.54,
            y = 11.82,
        },
        after = { 1139 },
        summary = {
            enUS = "Take Hammertoe's Amulet to Historian Karnik in Ironforge.",
            zhCN = "把铁趾的护符交给铁炉堡的史学家卡尼克。",
        },
    },
    [709] = {
        name = {
            enUS = "Solution to Doom",
            zhCN = "化解灾难",
        },
        level = 40,
        min = 30,
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 2785,
            name = {
                enUS = "Theldurin the Lost",
                zhCN = "迷失者塞尔杜林",
            },
            map = 1418,
            x = 51.39,
            y = 76.87,
        },
        finish = {
            kind = "npc",
            id = 2785,
            name = {
                enUS = "Theldurin the Lost",
                zhCN = "迷失者塞尔杜林",
            },
            map = 1418,
            x = 51.39,
            y = 76.87,
        },
        after = { 727, 728 },
        summary = {
            enUS = "Bring the Tablet of Ryun'eh to Theldurin the Lost.",
            zhCN = "把雷乌纳石板带给迷失者塞尔杜林。",
        },
        rewards = {
            xp = 3150,
            referenceItems = {
                {
                    id = 4746,
                },
            },
        },
    },
    [2240] = {
        name = {
            enUS = "The Hidden Chamber",
            zhCN = "密室",
        },
        level = 40,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6906,
            name = {
                enUS = "Baelog",
                zhCN = "巴尔洛戈",
            },
            map = 1337,
            x = 65.1,
            y = 94.4,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 1356,
            name = {
                enUS = "Prospector Stormpike",
                zhCN = "勘察员塔伯斯·雷矛",
            },
            map = 1455,
            x = 74.64,
            y = 11.74,
        },
        before = { 2398 },
        summary = {
            enUS = "Read Baelog's Journal, explore the hidden chamber, then report to Prospector Stormpike.",
            zhCN = "阅读巴尔洛戈的日记，探索密室，然后向铁炉堡的勘察员塔伯斯·雷矛汇报。",
        },
        rewards = {
            xp = 3900,
            referenceItems = {
                {
                    id = 9626,
                },
                {
                    id = 9627,
                },
            },
        },
    },
    [2398] = {
        name = {
            enUS = "The Lost Dwarves",
            zhCN = "失踪的矮人",
        },
        level = 40,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 1356,
            name = {
                enUS = "Prospector Stormpike",
                zhCN = "勘察员塔伯斯·雷矛",
            },
            map = 1455,
            x = 74.64,
            y = 11.74,
        },
        finish = {
            kind = "npc",
            id = 6906,
            name = {
                enUS = "Baelog",
                zhCN = "巴尔洛戈",
            },
        },
        after = { 2240 },
        summary = {
            enUS = "Find Baelog in Uldaman.",
            zhCN = "在奥达曼找到巴尔洛戈。",
        },
    },
    [2199] = {
        name = {
            enUS = "Lore for a Price",
            zhCN = "昂贵的知识",
        },
        level = 41,
        min = 37,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        finish = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        before = { 2198 },
        after = { 2200, 2201, 2204, 2361 },
        summary = {
            enUS = "Bring five silver bars to Talvash del Kissel in Ironforge.",
            zhCN = "给铁炉堡的塔瓦斯德·基瑟尔带去五块银锭。",
        },
        rewards = {
            xp = 2450,
        },
    },
    [2283] = {
        name = {
            enUS = "Necklace Recovery",
            zhCN = "搜寻项链",
        },
        level = 41,
        min = 37,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6986,
            name = {
                enUS = "Dran Droffers",
                zhCN = "德兰·杜佛斯",
            },
            map = 1454,
            x = 59.49,
            y = 36.57,
        },
        finish = {
            kind = "npc",
            id = 6986,
            name = {
                enUS = "Dran Droffers",
                zhCN = "德兰·杜佛斯",
            },
            map = 1454,
            x = 59.49,
            y = 36.57,
        },
        after = { 2284, 2318, 2338, 2339 },
        summary = {
            enUS = "Look for a valuable necklace within the Uldaman dig site and bring it back to Dran Droffers in Orgrimmar. The necklace may be damaged.",
            zhCN = "在奥达曼挖掘场中寻找一条珍贵的项链，然后将其交给奥格瑞玛的德兰·杜佛斯。项链有可能已经损坏。",
        },
        rewards = {
            xp = 2450,
        },
    },
    [2284] = {
        name = {
            enUS = "Necklace Recovery, Take 2",
            zhCN = "搜寻项链，再来一次",
        },
        level = 41,
        min = 37,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6986,
            name = {
                enUS = "Dran Droffers",
                zhCN = "德兰·杜佛斯",
            },
            map = 1454,
            x = 59.49,
            y = 36.57,
        },
        finish = {
            kind = "npc",
            id = 6912,
            name = {
                enUS = "Remains of a Paladin",
                zhCN = "圣骑士的遗体",
            },
        },
        before = { 2283 },
        after = { 2318, 2338, 2339, 2340 },
        summary = {
            enUS = "Find a clue as to the gems' whereabouts in the depths of Uldaman.",
            zhCN = "在奥达曼里找寻宝石的线索。",
        },
    },
    [2198] = {
        name = {
            enUS = "The Shattered Necklace",
            zhCN = "破碎的项链",
        },
        level = 41,
        min = 37,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "item",
            id = 7666,
            name = {
                enUS = "Shattered Necklace",
                zhCN = "破碎的项链",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        after = { 2199, 2200, 2201, 2204, 2361 },
        summary = {
            enUS = "Search for the original creator of the shattered necklace to learn of its potential value.",
            zhCN = "找到破碎的项链的来源，从而了解其潜在的价值。",
        },
        rewards = {
            xp = 3300,
        },
    },
    [2200] = {
        name = {
            enUS = "Back to Uldaman",
            zhCN = "回到奥达曼",
        },
        level = 42,
        min = 37,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        finish = {
            kind = "npc",
            id = 6912,
            name = {
                enUS = "Remains of a Paladin",
                zhCN = "圣骑士的遗体",
            },
        },
        before = { 2198, 2199 },
        after = { 2201, 2204, 2361 },
        summary = {
            enUS = "Search for clues as to the current disposition of Talvash's necklace within Uldaman. The slain paladin he mentioned was the person who had it last.",
            zhCN = "去奥达曼寻找塔瓦斯的魔法项链，被杀的圣骑士是最后一个拿着它的人。",
        },
    },
    [739] = {
        name = {
            enUS = "Murdaloc",
            zhCN = "莫达洛克",
        },
        level = 42,
        min = 30,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "object",
            id = 2875,
            name = {
                enUS = "Battered Dwarven Skeleton",
                zhCN = "残破的矮人骸骨",
            },
            map = 1418,
            x = 50.89,
            y = 62.4,
        },
        finish = {
            kind = "npc",
            id = 1344,
            name = {
                enUS = "Prospector Ironband",
                zhCN = "勘察员基恩萨·铁环",
            },
            map = 1432,
            x = 65.93,
            y = 65.62,
        },
        after = { 704 },
        summary = {
            enUS = "Slay Agmond's killer, Murdaloc. Slay 12 Stonevault Bonesnappers. Report to Prospector Ironband in Loch Modan.",
            zhCN = "干掉杀害阿戈莫德的凶手：莫达洛克。 顺便杀掉12个石窟断骨者。 然后向洛克莫丹的勘察员基恩萨·铁环报告。",
        },
    },
    [2318] = {
        name = {
            enUS = "Translating the Journal (2318)",
            zhCN = "翻译日记",
        },
        level = 42,
        min = 37,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6912,
            name = {
                enUS = "Remains of a Paladin",
                zhCN = "圣骑士的遗体",
            },
            map = 1337,
            x = 59,
            y = 63.6,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        before = { 2283, 2284 },
        after = { 2338, 2339, 2340, 2341 },
        summary = {
            enUS = "Find someone who can translate the paladin's journal. The closest location that might have someone is Kargath, in the Badlands.",
            zhCN = "在荒芜之地的卡加斯哨所里寻找一个可以帮你翻译圣骑士日记的人。",
        },
    },
    [2338] = {
        name = {
            enUS = "Translating the Journal (2338)",
            zhCN = "翻译日记",
        },
        level = 42,
        min = 37,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        finish = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        before = { 2283, 2284, 2318 },
        after = { 2339, 2340, 2341 },
        summary = {
            enUS = "Let Jarkal borrow the necklace. In exchange, he will translate the journal for you.",
            zhCN = "将项链借给加卡尔。作为交换，他将帮你翻译日记。",
        },
        rewards = {
            xp = 345,
        },
    },
    [17] = {
        name = {
            enUS = "Uldaman Reagent Run (17)",
            zhCN = "奥达曼的蘑菇",
        },
        level = 42,
        min = 36,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 1470,
            name = {
                enUS = "Ghak Healtouch",
                zhCN = "加克",
            },
            map = 1432,
            x = 37.07,
            y = 49.38,
        },
        finish = {
            kind = "npc",
            id = 1470,
            name = {
                enUS = "Ghak Healtouch",
                zhCN = "加克",
            },
            map = 1432,
            x = 37.07,
            y = 49.38,
        },
        before = { 2500 },
        summary = {
            enUS = "Bring 12 Magenta Fungus Caps to Ghak Healtouch in Thelsamar.",
            zhCN = "收集12颗紫色蘑菇，把它们交给塞尔萨玛的加克。",
        },
        rewards = {
            xp = 3450,
            money = 5500,
            referenceItems = {
                {
                    id = 9030,
                },
            },
        },
    },
    [2202] = {
        name = {
            enUS = "Uldaman Reagent Run (2202)",
            zhCN = "奥达曼的蘑菇",
        },
        level = 42,
        min = 36,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        finish = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        before = { 2258 },
        after = { 2203 },
        summary = {
            enUS = "Bring 12 Magenta Fungus Caps to Jarkal Mossmeld in Kargath.",
            zhCN = "收集12颗紫色蘑菇，把它们交给卡加斯的加卡尔。",
        },
        rewards = {
            xp = 3450,
            money = 5500,
            referenceItems = {
                {
                    id = 9030,
                },
            },
        },
    },
    [2201] = {
        name = {
            enUS = "Find the Gems",
            zhCN = "寻找宝石",
        },
        level = 43,
        min = 40,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6912,
            name = {
                enUS = "Remains of a Paladin",
                zhCN = "圣骑士的遗体",
            },
            map = 1337,
            x = 59,
            y = 63.6,
            unverified = true,
        },
        inside = true,
        finish = {
            kind = "object",
            id = 112877,
            name = {
                enUS = "Talvash's Scrying Bowl",
                zhCN = "塔瓦斯德的占卜之碗",
            },
        },
        before = { 2198, 2199, 2200 },
        after = { 2204, 2361 },
        summary = {
            enUS = "Find the ruby, sapphire, and topaz that are scattered throughout Uldaman. Once acquired, contact Talvash del Kissel remotely by using the Phial of...",
            zhCN = "在奥达曼寻找红宝石、蓝宝石和黄宝石的下落。找到它们之后，通过塔瓦斯德给你的占卜之瓶和他进行联系。",
        },
        rewards = {
            xp = 3600,
        },
    },
    [1360] = {
        name = {
            enUS = "Reclaimed Treasures (1360)",
            zhCN = "失而复得",
        },
        level = 43,
        min = 33,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6294,
            name = {
                enUS = "Krom Stoutarm",
                zhCN = "克罗姆·粗臂",
            },
            map = 1455,
            x = 74.19,
            y = 9.39,
        },
        finish = {
            kind = "npc",
            id = 6294,
            name = {
                enUS = "Krom Stoutarm",
                zhCN = "克罗姆·粗臂",
            },
            map = 1455,
            x = 74.19,
            y = 9.39,
        },
        summary = {
            enUS = "Get Krom Stoutarm's treasured possession from his chest in the North Common Hall of Uldaman, and bring it to him in Ironforge.",
            zhCN = "到奥达曼的北部大厅去找到克罗姆·粗臂的箱子，从里面拿出他的宝贵财产，然后回到铁炉堡把东西交给他。",
        },
        rewards = {
            xp = 3600,
            money = 6000,
        },
    },
    [2342] = {
        name = {
            enUS = "Reclaimed Treasures (2342)",
            zhCN = "寻找宝物",
        },
        level = 43,
        min = 33,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 5651,
            name = {
                enUS = "Patrick Garrett",
                zhCN = "帕特里克·加瑞特",
            },
            map = 1458,
            x = 62.32,
            y = 48.61,
        },
        finish = {
            kind = "npc",
            id = 5651,
            name = {
                enUS = "Patrick Garrett",
                zhCN = "帕特里克·加瑞特",
            },
            map = 1458,
            x = 62.32,
            y = 48.61,
        },
        summary = {
            enUS = "Get Patrick Garrett's family treasure from their family chest in the South Common Hall of Uldaman, and bring it to him in the Undercity.",
            zhCN = "从奥达曼南部大厅的箱子中找到加勒特的家族宝藏，然后把它交给幽暗城的帕特里克·加瑞特。",
        },
        rewards = {
            xp = 3600,
            money = 6000,
        },
    },
    [2339] = {
        name = {
            enUS = "Find the Gems and Power Source",
            zhCN = "寻找宝贝",
        },
        level = 44,
        min = 37,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        finish = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        before = { 2283, 2284, 2318, 2338 },
        after = { 2340, 2341 },
        summary = {
            enUS = "Recover all three gems and a power source for the necklace from Uldaman, and then bring them to Jarkal Mossmeld in Kargath....",
            zhCN = "从奥达曼找回项链上的所有三块宝石和能量源，然后把它们交给卡加斯的加卡尔。 红宝石被藏在暗影矮人层层设防的地区。 黄宝石藏在石腭怪活动地区的一个瓮中。 蓝宝石在格瑞姆洛克手中，他是石腭怪的领袖。 能量源可能在奥达曼的某个最强生物的手中。",
        },
        rewards = {
            xp = 3750,
        },
    },
    [2361] = {
        name = {
            enUS = "Restoring the Necklace (2361)",
            zhCN = "修复项链",
        },
        level = 44,
        min = 37,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        finish = {
            kind = "npc",
            id = 6826,
            name = {
                enUS = "Talvash del Kissel",
                zhCN = "塔瓦斯德·基瑟尔",
            },
            map = 1455,
            x = 36.38,
            y = 3.61,
        },
        before = { 2198, 2199, 2200, 2201, 2204 },
        summary = {
            enUS = "Uldaman Level 44. View quest details and related records.",
            zhCN = "领取修复完成的项链。",
        },
        rewards = {
            xp = 5600,
            referenceItems = {
                {
                    id = 7673,
                },
            },
        },
    },
    [1139] = {
        name = {
            enUS = "The Lost Tablets of Will",
            zhCN = "意志石板",
        },
        level = 45,
        min = 35,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 2918,
            name = {
                enUS = "Advisor Belgrum",
                zhCN = "顾问贝尔格拉姆",
            },
            map = 1455,
            x = 77.34,
            y = 9.71,
        },
        finish = {
            kind = "npc",
            id = 2918,
            name = {
                enUS = "Advisor Belgrum",
                zhCN = "顾问贝尔格拉姆",
            },
            map = 1455,
            x = 77.34,
            y = 9.71,
        },
        before = { 720, 721, 722, 723, 724, 725, 726, 762 },
        summary = {
            enUS = "Find the Tablet of Will, and return them to Advisor Belgrum in Ironforge.",
            zhCN = "找到意志石板，把它们交给铁炉堡的顾问贝尔格拉姆。",
        },
        rewards = {
            xp = 5850,
            money = 13000,
            referenceItems = {
                {
                    id = 6723,
                },
            },
        },
    },
    [2279] = {
        name = {
            enUS = "The Platinum Discs (2279)",
            zhCN = "白金圆盘",
        },
        level = 47,
        min = 40,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "object",
            id = 131474,
            name = {
                enUS = "The Discs of Norgannon",
                zhCN = "诺甘农圆盘",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 5387,
            name = {
                enUS = "High Explorer Magellas",
                zhCN = "资深探险家麦格拉斯",
            },
            map = 1455,
            x = 69.93,
            y = 18.55,
        },
        summary = {
            enUS = "Take the miniature version of the Discs of Norgannon to the Explorers' League in Ironforge.",
            zhCN = "把迷你版的诺甘农圆盘带到铁炉堡的探险者协会去。",
        },
        rewards = {
            xp = 5250,
        },
    },
    [2280] = {
        name = {
            enUS = "The Platinum Discs (2280)",
            zhCN = "白金圆盘",
        },
        level = 47,
        min = 40,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "object",
            id = 131474,
            name = {
                enUS = "The Discs of Norgannon",
                zhCN = "诺甘农圆盘",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 3978,
            name = {
                enUS = "Sage Truthseeker",
                zhCN = "圣者图希克",
            },
            map = 1456,
            x = 34.4,
            y = 46.87,
        },
        after = { 2440, 2965, 2966, 2954 },
        summary = {
            enUS = "Take the miniature version of the Discs of Norgannon to the one of the sages in Thunder Bluff.",
            zhCN = "把迷你版的诺甘农圆盘带到雷霆崖的贤者那里。",
        },
        rewards = {
            xp = 5250,
        },
    },
    [2439] = {
        name = {
            enUS = "The Platinum Discs (2439)",
            zhCN = "白金圆盘",
        },
        level = 47,
        min = 40,
        faction = "A",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 5387,
            name = {
                enUS = "High Explorer Magellas",
                zhCN = "资深探险家麦格拉斯",
            },
            map = 1455,
            x = 69.93,
            y = 18.55,
        },
        finish = {
            kind = "npc",
            id = 7292,
            name = {
                enUS = "Dinita Stonemantle",
                zhCN = "丁尼塔·石衣",
            },
            map = 1455,
            x = 33.88,
            y = 59.15,
        },
        summary = {
            enUS = "Take your reward voucher to Dinita Stonemantle in the Vault of Ironforge.",
            zhCN = "把你的报酬凭证交给铁炉堡银行的丁尼塔·石衣。",
        },
    },
    [2440] = {
        name = {
            enUS = "The Platinum Discs (2440)",
            zhCN = "白金圆盘",
        },
        level = 47,
        min = 40,
        faction = "H",
        instances = { "uldaman" },
        start = {
            kind = "npc",
            id = 3978,
            name = {
                enUS = "Sage Truthseeker",
                zhCN = "圣者图希克",
            },
            map = 1456,
            x = 34.4,
            y = 46.87,
        },
        finish = {
            kind = "npc",
            id = 3009,
            name = {
                enUS = "Bena Winterhoof",
                zhCN = "本娜·冰蹄",
            },
            map = 1456,
            x = 46.62,
            y = 33.17,
        },
        summary = {
            enUS = "Take the reward voucher to Bena Winterhoof in Thunder Bluff.",
            zhCN = "把报酬凭证交给雷霆崖的本娜·冰蹄。",
        },
    },
    [886] = {
        name = {
            enUS = "The Barrens Oases",
            zhCN = "贫瘠之地的绿洲",
        },
        level = 10,
        min = 10,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 5769,
            name = {
                enUS = "Arch Druid Hamuul Runetotem",
                zhCN = "大德鲁伊哈缪尔·符文图腾",
            },
            map = 1456,
            x = 78.62,
            y = 28.56,
        },
        finish = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        summary = {
            enUS = "Speak with Tonga Runetotem at the Crossroads.",
            zhCN = "和十字路口的图加·符文图腾谈一谈。",
        },
    },
    [870] = {
        name = {
            enUS = "The Forgotten Pools",
            zhCN = "遗忘之池",
        },
        level = 13,
        min = 10,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        finish = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        after = { 914 },
        summary = {
            enUS = "Report back to Tonga Runetotem with your findings.",
            zhCN = "向图加·符文图腾报告你的发现。",
        },
    },
    [880] = {
        name = {
            enUS = "Altered Beings",
            zhCN = "变异的生物",
        },
        level = 16,
        min = 10,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        finish = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        after = { 914 },
        summary = {
            enUS = "Bring 8 Altered Snapjaw Shells to Tonga Runetotem at the Crossroads.",
            zhCN = "收集8块变异的钳嘴龟壳，把它们交给十字路口的图加。",
        },
    },
    [1489] = {
        name = {
            enUS = "Hamuul Runetotem",
            zhCN = "哈缪尔·符文图腾",
        },
        level = 16,
        min = 10,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        finish = {
            kind = "npc",
            name = {
                enUS = "Hamuul Runetotem",
                zhCN = "大德鲁伊哈缪尔·符文图腾",
            },
        },
        after = { 914 },
        summary = {
            enUS = "Speak with Hamuul Runetotem",
            zhCN = "和哈缪尔·符文图腾谈一谈。",
        },
        rewards = {
            xp = 290,
            reputation = {
                {
                    name = {
                        enUS = "Thunder Bluff",
                        zhCN = "雷霆崖",
                    },
                    value = 25,
                },
            },
        },
    },
    [1490] = {
        name = {
            enUS = "Nara Wildmane",
            zhCN = "纳拉·蛮鬃",
        },
        level = 16,
        min = 10,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 5769,
            name = {
                enUS = "Arch Druid Hamuul Runetotem",
                zhCN = "大德鲁伊哈缪尔·符文图腾",
            },
            map = 1456,
            x = 78.62,
            y = 28.56,
        },
        finish = {
            kind = "npc",
            id = 5770,
            name = {
                enUS = "Nara Wildmane",
                zhCN = "纳拉·蛮鬃",
            },
            map = 1456,
            x = 75.65,
            y = 31.61,
        },
        after = { 914 },
        summary = {
            enUS = "Speak with Nara Wildmane.",
            zhCN = "和纳拉·蛮鬃谈一谈。",
        },
        rewards = {
            xp = 120,
            reputation = {
                {
                    name = {
                        enUS = "Thunder Bluff",
                        zhCN = "雷霆崖",
                    },
                    value = 10,
                },
            },
        },
    },
    [877] = {
        name = {
            enUS = "The Stagnant Oasis",
            zhCN = "死水绿洲",
        },
        level = 16,
        min = 10,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        finish = {
            kind = "npc",
            id = 3448,
            name = {
                enUS = "Tonga Runetotem",
                zhCN = "图加·符文图腾",
            },
            map = 1413,
            x = 52.26,
            y = 31.93,
        },
        after = { 914 },
        summary = {
            enUS = "Return to Tonga at The Crossroads, after investigating the Stagnant Oasis.",
            zhCN = "调查死水绿洲，然后返回十字路口向图加·符文图腾报告。",
        },
    },
    [1486] = {
        name = {
            enUS = "Deviate Hides",
            zhCN = "变异皮革",
        },
        level = 17,
        min = 13,
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 5767,
            name = {
                enUS = "Nalpak",
                zhCN = "纳尔帕克",
            },
            map = 1413,
            x = 45.99,
            y = 35.66,
        },
        finish = {
            kind = "npc",
            id = 5767,
            name = {
                enUS = "Nalpak",
                zhCN = "纳尔帕克",
            },
            map = 1413,
            x = 45.99,
            y = 35.66,
        },
        summary = {
            enUS = "Nalpak in the Wailing Caverns wants 20 Deviate Hides.",
            zhCN = "哀嚎洞穴的纳尔帕克想要20张变异皮革。",
        },
        objectives = {
            enUS = { "Deviate Hide ×20" },
            zhCN = { "变异皮革 ×20" },
        },
        rewards = {
            xp = 4650,
            money = 1800,
            items = {
                {
                    id = 918,
                    count = 1,
                },
                {
                    id = 6480,
                    count = 1,
                },
            },
        },
    },
    [865] = {
        name = {
            enUS = "Raptor Horns",
            zhCN = "迅猛龙角",
        },
        level = 18,
        min = 13,
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3446,
            name = {
                enUS = "Mebok Mizzyrix",
                zhCN = "麦伯克·米希瑞克斯",
            },
            map = 1413,
            x = 62.37,
            y = 37.62,
        },
        finish = {
            kind = "npc",
            id = 3446,
            name = {
                enUS = "Mebok Mizzyrix",
                zhCN = "麦伯克·米希瑞克斯",
            },
            map = 1413,
            x = 62.37,
            y = 37.62,
        },
        after = { 1491 },
        summary = {
            enUS = "Gather 5 Intact Raptor Horns from Sunscale Scytheclaws, and bring them to Mebok Mizzyrix in Ratchet.",
            zhCN = "从赤鳞镰爪龙身上收集5根完整的迅猛龙角，把它们交给棘齿城的米希瑞克斯。",
        },
    },
    [962] = {
        name = {
            enUS = "Serpentbloom",
            zhCN = "毒蛇花",
        },
        level = 18,
        min = 14,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3419,
            name = {
                enUS = "Apothecary Zamah",
                zhCN = "药剂师扎玛",
            },
            map = 1456,
            x = 22.81,
            y = 20.89,
        },
        finish = {
            kind = "npc",
            id = 3419,
            name = {
                enUS = "Apothecary Zamah",
                zhCN = "药剂师扎玛",
            },
            map = 1456,
            x = 22.81,
            y = 20.89,
        },
        summary = {
            enUS = "Apothecary Zamah in Thunder Bluff wants you to collect 10 Serpentbloom.",
            zhCN = "为雷霆崖的药剂师扎玛收集10朵毒蛇花。",
        },
        objectives = {
            enUS = { "Serpentbloom ×10" },
            zhCN = { "毒蛇花 ×10" },
        },
        rewards = {
            xp = 4950,
            money = 2000,
            choices = {
                {
                    id = 10919,
                    count = 1,
                },
                {
                    id = 270008,
                    count = 1,
                },
                {
                    id = 270009,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Undercity",
                        zhCN = "幽暗城",
                    },
                    value = 150,
                },
            },
        },
    },
    [1491] = {
        name = {
            enUS = "Smart Drinks",
            zhCN = "智慧饮料",
        },
        level = 18,
        min = 13,
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3446,
            name = {
                enUS = "Mebok Mizzyrix",
                zhCN = "麦伯克·米希瑞克斯",
            },
            map = 1413,
            x = 62.37,
            y = 37.62,
        },
        finish = {
            kind = "npc",
            id = 3446,
            name = {
                enUS = "Mebok Mizzyrix",
                zhCN = "麦伯克·米希瑞克斯",
            },
            map = 1413,
            x = 62.37,
            y = 37.62,
        },
        before = { 865 },
        summary = {
            enUS = "Bring 6 portions of Wailing Essence to Mebok Mizzyrix in Ratchet.",
            zhCN = "收集6份哀嚎香精，把它们交给棘齿城的麦伯克·米希瑞克斯。",
        },
        objectives = {
            enUS = { "Wailing Essence ×6" },
            zhCN = { "哀嚎香精 ×6" },
        },
        rewards = {
            xp = 3900,
            money = 1000,
            reputation = {
                {
                    name = {
                        enUS = "Ratchet",
                        zhCN = "棘齿城",
                    },
                    value = 100,
                },
            },
        },
    },
    [959] = {
        name = {
            enUS = "Trouble at the Docks",
            zhCN = "港口的麻烦",
        },
        level = 18,
        min = 14,
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 3665,
            name = {
                enUS = "Crane Operator Bigglefuzz",
                zhCN = "起重机操作员比戈弗兹",
            },
            map = 1413,
            x = 63.09,
            y = 37.61,
        },
        finish = {
            kind = "npc",
            id = 3665,
            name = {
                enUS = "Crane Operator Bigglefuzz",
                zhCN = "起重机操作员比戈弗兹",
            },
            map = 1413,
            x = 63.09,
            y = 37.61,
        },
        summary = {
            enUS = "Crane Operator Bigglefuzz in Ratchet wants you to retrieve the bottle of 99-Year-Old Port from Mad Magglish who is hiding in the Wailing Caverns.",
            zhCN = "棘齿城的起重机操作员比戈弗兹让你从疯狂的马格利什那儿取回一瓶99年波尔多陈酿，疯狂的马格利什就藏在哀嚎洞穴里。",
        },
        objectives = {
            enUS = { "99-Year-Old Port" },
            zhCN = { "99年波尔多陈酿" },
        },
        rewards = {
            xp = 3900,
            money = 1000,
            reputation = {
                {
                    name = {
                        enUS = "Ratchet",
                        zhCN = "棘齿城",
                    },
                    value = 100,
                },
            },
        },
    },
    [1487] = {
        name = {
            enUS = "Deviate Eradication",
            zhCN = "清除变异者",
        },
        level = 21,
        min = 15,
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 5768,
            name = {
                enUS = "Ebru",
                zhCN = "厄布鲁",
            },
            map = 1413,
            x = 46.01,
            y = 35.74,
        },
        finish = {
            kind = "npc",
            id = 5768,
            name = {
                enUS = "Ebru",
                zhCN = "厄布鲁",
            },
            map = 1413,
            x = 46.01,
            y = 35.74,
        },
        summary = {
            enUS = "Ebru in the Wailing Caverns wants you to kill 7 Deviate Ravagers, 7 Deviate Vipers, 7 Deviate Shamblers and 7 Deviate Dreadfangs.",
            zhCN = "哀嚎洞穴的厄布鲁要求你杀掉7只变异破坏者、7只剧毒飞蛇、7只变异蹒跚者和7只变异尖牙风蛇。",
        },
        objectives = {
            enUS = { "Deviate Ravager ×7", "Deviate Viper ×7", "Deviate Shambler ×7", "Deviate Dreadfang ×7" },
            zhCN = { "变异破坏者 ×7", "剧毒飞蛇 ×7", "变异蹒跚者 ×7", "变异尖牙风蛇 ×7" },
        },
        rewards = {
            xp = 5950,
            money = 2500,
            choices = {
                {
                    id = 6476,
                    count = 1,
                },
                {
                    id = 8071,
                    count = 1,
                },
                {
                    id = 6481,
                    count = 1,
                },
            },
        },
    },
    [914] = {
        name = {
            enUS = "Leaders of the Fang",
            zhCN = "尖牙德鲁伊",
        },
        level = 22,
        min = 11,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 5770,
            name = {
                enUS = "Nara Wildmane",
                zhCN = "纳拉·蛮鬃",
            },
            map = 1456,
            x = 75.65,
            y = 31.61,
        },
        finish = {
            kind = "npc",
            id = 5770,
            name = {
                enUS = "Nara Wildmane",
                zhCN = "纳拉·蛮鬃",
            },
            map = 1456,
            x = 75.65,
            y = 31.61,
        },
        before = { 870, 877, 880, 1489, 1490 },
        summary = {
            enUS = "Bring the Gems of Cobrahn, Anacondra, Pythas and Serpentis to Nara Wildmane in Thunder Bluff.",
            zhCN = "将考布莱恩宝石、安娜科德拉宝石、皮萨斯宝石和瑟芬迪斯宝石交给雷霆崖的纳拉·蛮鬃。",
        },
        objectives = {
            enUS = { "Gem of Cobrahn", "Gem of Anacondra", "Gem of Pythas", "Gem of Serpentis" },
            zhCN = { "考布莱恩宝石", "安娜科德拉宝石", "皮萨斯宝石", "瑟芬迪斯宝石" },
        },
        rewards = {
            xp = 6400,
            choices = {
                {
                    id = 6505,
                    count = 1,
                },
                {
                    id = 6504,
                    count = 1,
                },
                {
                    id = 270018,
                    count = 1,
                },
            },
            reputation = {
                {
                    name = {
                        enUS = "Thunder Bluff",
                        zhCN = "雷霆崖",
                    },
                    value = 150,
                },
            },
        },
    },
    [3369] = {
        name = {
            enUS = "In Nightmares (3369)",
            zhCN = "在噩梦中",
        },
        level = 25,
        min = 15,
        faction = "H",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 8418,
            name = {
                enUS = "Falla Sagewind",
                zhCN = "菲拉·古风",
            },
            map = 1413,
            x = 48.18,
            y = 32.78,
        },
        finish = {
            kind = "npc",
            id = 5769,
            name = {
                enUS = "Arch Druid Hamuul Runetotem",
                zhCN = "大德鲁伊哈缪尔·符文图腾",
            },
            map = 1456,
            x = 78.62,
            y = 28.56,
        },
        summary = {
            enUS = "Bring the Nightmare Shard to Hamuul Runetotem on Elder Rise.",
            zhCN = "把噩梦碎片交给长者高地的哈缪尔·符文图腾。",
        },
    },
    [3370] = {
        name = {
            enUS = "In Nightmares (3370)",
            zhCN = "在噩梦中",
        },
        level = 25,
        min = 15,
        faction = "A",
        instances = { "wailing-caverns" },
        start = {
            kind = "npc",
            id = 8418,
            name = {
                enUS = "Falla Sagewind",
                zhCN = "菲拉·古风",
            },
            map = 1413,
            x = 48.18,
            y = 32.78,
        },
        finish = {
            kind = "npc",
            id = 4217,
            name = {
                enUS = "Mathrengyl Bearwalker",
                zhCN = "玛斯雷·驭熊者",
            },
            map = 1457,
            x = 35.37,
            y = 8.4,
        },
        summary = {
            enUS = "Bring the Nightmare Shard to Mathrengyl Bearwalker in Darnassus.",
            zhCN = "把噩梦碎片交给达纳苏斯的玛斯雷·驭熊者。",
        },
    },
    [3366] = {
        name = {
            enUS = "The Glowing Shard",
            zhCN = "发光的碎片",
        },
        level = 25,
        min = 15,
        instances = { "wailing-caverns" },
        start = {
            kind = "item",
            id = 10441,
            name = {
                enUS = "Glowing Shard",
                zhCN = "发光的碎片",
            },
        },
        inside = true,
        summary = {
            enUS = "Travel to Ratchet to find the meaning behind the Nightmare Shard.",
            zhCN = "寻找更多有关这块噩梦碎片的信息。",
        },
        objectives = {
            enUS = { "Glowing Shard" },
            zhCN = { "发光的碎片" },
        },
        rewards = {
            xp = 2550,
        },
    },
    [6981] = {
        name = {
            enUS = "The Glowing Shard",
            zhCN = "发光的碎片",
        },
        level = 26,
        min = 15,
        instances = { "wailing-caverns" },
        start = {
            kind = "item",
            id = 10441,
            name = {
                enUS = "Glowing Shard",
                zhCN = "发光的碎片",
            },
        },
        inside = true,
        finish = {
            kind = "npc",
            id = 8418,
            name = {
                enUS = "Falla Sagewind",
                zhCN = "菲拉·古风",
            },
            map = 1413,
            x = 48.18,
            y = 32.78,
        },
        summary = {
            enUS = "Travel to Ratchet to find someone that can tell you more about the glowing shard. Then, deliver the shard as you are directed.",
            zhCN = "寻找更多有关这块噩梦碎片的信息。",
        },
        objectives = {
            enUS = { "Glowing Shard" },
            zhCN = { "发光的碎片" },
        },
        rewards = {
            xp = 7700,
            referenceItems = {
                {
                    id = 10657,
                    followUp = true,
                },
                {
                    id = 10658,
                    followUp = true,
                },
            },
        },
    },
    [2865] = {
        name = {
            enUS = "Scarab Shells",
            zhCN = "圣甲虫的壳",
        },
        level = 45,
        min = 40,
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 7876,
            name = {
                enUS = "Tran'rek",
                zhCN = "特兰雷克",
            },
            map = 1446,
            x = 51.57,
            y = 26.76,
        },
        finish = {
            kind = "npc",
            id = 7876,
            name = {
                enUS = "Tran'rek",
                zhCN = "特兰雷克",
            },
            map = 1446,
            x = 51.57,
            y = 26.76,
        },
        before = { 2864 },
        summary = {
            enUS = "Bring 5 Uncracked Scarab Shells to Tran'rek in Gadgetzan.",
            zhCN = "给加基森的特兰雷克带去5个完整的圣甲虫壳。",
        },
        rewards = {
            xp = 3900,
            money = 6500,
        },
    },
    [2936] = {
        name = {
            enUS = "The Spider God",
            zhCN = "蜘蛛之神",
        },
        level = 45,
        min = 40,
        faction = "H",
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 3188,
            name = {
                enUS = "Master Gadrin",
                zhCN = "加德林大师",
            },
            map = 1411,
            x = 55.95,
            y = 74.72,
        },
        finish = {
            kind = "npc",
            id = 3188,
            name = {
                enUS = "Master Gadrin",
                zhCN = "加德林大师",
            },
            map = 1411,
            x = 55.95,
            y = 74.72,
        },
        before = { 2933, 2934, 2935 },
        after = { 2937, 2938 },
        summary = {
            enUS = "Read from the Tablet of Theka to learn the name of the Witherbark spider god, then return to Master Gadrin.",
            zhCN = "阅读塞卡石板，了解枯木巨魔的蜘蛛之神的名字，然后回到加德林大师那里。",
        },
    },
    [3042] = {
        name = {
            enUS = "Troll Temper",
            zhCN = "巨魔调和剂",
        },
        level = 45,
        min = 40,
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 7804,
            name = {
                enUS = "Trenton Lighthammer",
                zhCN = "特伦顿·轻锤",
            },
            map = 1446,
            x = 51.41,
            y = 28.75,
        },
        finish = {
            kind = "npc",
            id = 7804,
            name = {
                enUS = "Trenton Lighthammer",
                zhCN = "特伦顿·轻锤",
            },
            map = 1446,
            x = 51.41,
            y = 28.75,
        },
        summary = {
            enUS = "Bring 20 Vials of Troll Temper to Trenton Lighthammer in Gadgetzan.",
            zhCN = "收集20瓶巨魔调和剂，把它们交给加基森的特伦顿·轻锤。",
        },
        rewards = {
            xp = 3900,
            money = 19500,
        },
    },
    [2846] = {
        name = {
            enUS = "Tiara of the Deep",
            zhCN = "深渊皇冠",
        },
        level = 46,
        min = 40,
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        finish = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        before = { 2861 },
        summary = {
            enUS = "Bring the Tiara of the Deep to Tabetha in Dustwallow Marsh.",
            zhCN = "将深渊皇冠交给尘泥沼泽的塔贝萨。",
        },
        rewards = {
            xp = 6050,
            money = 6500,
            referenceItems = {
                {
                    id = 9527,
                },
                {
                    id = 9531,
                },
            },
        },
    },
    [2768] = {
        name = {
            enUS = "Divino-matic Rod",
            zhCN = "探水棒",
        },
        level = 47,
        min = 40,
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 7407,
            name = {
                enUS = "Chief Engineer Bilgewhizzle",
                zhCN = "首席工程师沙克斯·比格维兹",
            },
            map = 1446,
            x = 52.46,
            y = 28.51,
        },
        finish = {
            kind = "npc",
            id = 7407,
            name = {
                enUS = "Chief Engineer Bilgewhizzle",
                zhCN = "首席工程师沙克斯·比格维兹",
            },
            map = 1446,
            x = 52.46,
            y = 28.51,
        },
        summary = {
            enUS = "Bring the Divino-matic Rod to Chief Engineer Bilgewhizzle in Gadgetzan.",
            zhCN = "把探水棒交给加基森的首席工程师沙克斯·比格维兹。",
        },
        rewards = {
            xp = 6300,
            referenceItems = {
                {
                    id = 9533,
                },
                {
                    id = 9534,
                },
            },
        },
    },
    [2991] = {
        name = {
            enUS = "Nekrum's Medallion",
            zhCN = "耐克鲁姆的徽章",
        },
        level = 47,
        min = 40,
        faction = "A",
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 8022,
            name = {
                enUS = "Thadius Grimshade",
                zhCN = "萨迪斯·格希德",
            },
            map = 1419,
            x = 66.9,
            y = 19.47,
        },
        finish = {
            kind = "npc",
            id = 8022,
            name = {
                enUS = "Thadius Grimshade",
                zhCN = "萨迪斯·格希德",
            },
            map = 1419,
            x = 66.9,
            y = 19.47,
        },
        before = { 2988, 2989, 2990 },
        after = { 2992, 2993, 2994 },
        summary = {
            enUS = "Bring Nekrum's Medallion to Thadius Grimshade in the Blasted Lands.",
            zhCN = "将耐克鲁姆的徽章交给诅咒之地的萨迪斯·格希德。",
        },
        rewards = {
            xp = 5250,
            money = 7000,
        },
    },
    [3527] = {
        name = {
            enUS = "The Prophecy of Mosh'aru",
            zhCN = "摩沙鲁的预言",
        },
        level = 47,
        min = 40,
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 8579,
            name = {
                enUS = "Yeh'kinya",
                zhCN = "叶基亚",
            },
            map = 1446,
            x = 66.99,
            y = 22.36,
        },
        finish = {
            kind = "npc",
            id = 8579,
            name = {
                enUS = "Yeh'kinya",
                zhCN = "叶基亚",
            },
            map = 1446,
            x = 66.99,
            y = 22.36,
        },
        before = { 3520 },
        after = { 4787, 3528, 5065, 4788 },
        summary = {
            enUS = "Bring the First and Second Mosh'aru Tablets to Yeh'kinya in Tanaris.",
            zhCN = "将第一块和第二块摩沙鲁石板交给塔纳利斯的叶基亚。",
        },
        rewards = {
            xp = 5250,
        },
    },
    [2770] = {
        name = {
            enUS = "Gahz'rilla",
            zhCN = "加兹瑞拉",
        },
        level = 50,
        min = 40,
        instances = { "zulfarrak" },
        start = {
            kind = "npc",
            id = 4453,
            name = {
                enUS = "Wizzle Brassbolts",
                zhCN = "维兹尔·铜栓",
            },
            map = 1441,
            x = 78.14,
            y = 77.12,
        },
        finish = {
            kind = "npc",
            id = 4453,
            name = {
                enUS = "Wizzle Brassbolts",
                zhCN = "维兹尔·铜栓",
            },
            map = 1441,
            x = 78.14,
            y = 77.12,
        },
        before = { 2769 },
        summary = {
            enUS = "Bring Gahz'rilla's Electrified Scale to Wizzle Brassbolts in the Shimmering Flats.",
            zhCN = "把加兹瑞拉的鳞片交给闪光平原的维兹尔·铜栓。",
        },
        rewards = {
            xp = 7100,
            money = 7500,
            referenceItems = {
                {
                    id = 11122,
                },
            },
        },
    },
    [303] = {
        name = {
            enUS = "The Dark Iron War",
            zhCN = "黑铁战争",
        },
        level = 30,
        faction = "A",
        start = {
            kind = "npc",
            id = 1074,
            name = {
                enUS = "Motley Garmason",
                zhCN = "莫特雷·加玛森",
            },
            map = 1437,
            x = 49.67,
            y = 18.23,
        },
        after = { 378 },
        chainOnly = true,
    },
    [350] = {
        name = {
            enUS = "Look to an Old Friend",
            zhCN = "老朋友",
        },
        level = 31,
        faction = "A",
        start = {
            kind = "npc",
            id = 332,
            name = {
                enUS = "Master Mathias Shaw",
                zhCN = "马迪亚斯·肖尔",
            },
            map = 1453,
            x = 78.4,
            y = 70.7,
        },
        chainOnly = true,
    },
    [389] = {
        name = {
            enUS = "Bazil Thredd",
            zhCN = "巴吉尔·特雷德",
        },
        level = 22,
        faction = "A",
        start = {
            kind = "npc",
            id = 1646,
            name = {
                enUS = "Baros Alexston",
                zhCN = "巴隆斯·阿历克斯顿",
            },
            map = 1453,
            x = 57.7,
            y = 47.9,
        },
        after = { 391 },
        chainOnly = true,
    },
    [392] = {
        name = {
            enUS = "The Curious Visitor",
            zhCN = "好奇的访客",
        },
        level = 29,
        faction = "A",
        start = {
            kind = "npc",
            id = 1719,
            name = {
                enUS = "Warden Thelwater",
                zhCN = "典狱官塞尔沃特",
            },
            map = 1453,
            x = 51.8,
            y = 69.3,
        },
        chainOnly = true,
    },
    [393] = {
        name = {
            enUS = "Shadow of the Past",
            zhCN = "往日的阴影",
        },
        level = 29,
        faction = "A",
        start = {
            kind = "npc",
            id = 1646,
            name = {
                enUS = "Baros Alexston",
                zhCN = "巴隆斯·阿历克斯顿",
            },
            map = 1453,
            x = 57.7,
            y = 47.9,
        },
        chainOnly = true,
    },
    [725] = {
        name = {
            enUS = "Passing Word of a Threat",
            zhCN = "亡者的警告",
        },
        level = 40,
        faction = "A",
        start = {
            kind = "npc",
            id = 2916,
            name = {
                enUS = "Historian Karnik",
                zhCN = "史学家卡尼克",
            },
            map = 1455,
            x = 77.54,
            y = 11.82,
        },
        after = { 1139 },
        chainOnly = true,
    },
    [726] = {
        name = {
            enUS = "Passing Word of a Threat",
            zhCN = "亡者的警告",
        },
        level = 40,
        faction = "A",
        start = {
            kind = "npc",
            id = 2918,
            name = {
                enUS = "Advisor Belgrum",
                zhCN = "顾问贝尔格拉姆",
            },
            map = 1455,
            x = 77.34,
            y = 9.71,
        },
        after = { 1139 },
        chainOnly = true,
    },
    [727] = {
        name = {
            enUS = "To Ironforge for Yagyin's Digest",
            zhCN = "远赴铁炉堡",
        },
        level = 40,
        faction = "A",
        start = {
            kind = "npc",
            id = 2785,
            name = {
                enUS = "Theldurin the Lost",
                zhCN = "迷失者塞尔杜林",
            },
            map = 1418,
            x = 51.39,
            y = 76.87,
        },
        chainOnly = true,
    },
    [728] = {
        name = {
            enUS = "To the Undercity for Yagyin's Digest",
            zhCN = "远赴幽暗城",
        },
        level = 40,
        faction = "H",
        start = {
            kind = "npc",
            id = 2785,
            name = {
                enUS = "Theldurin the Lost",
                zhCN = "迷失者塞尔杜林",
            },
            map = 1418,
            x = 51.39,
            y = 76.87,
        },
        chainOnly = true,
    },
    [762] = {
        name = {
            enUS = "An Ambassador of Evil",
            zhCN = "邪恶的使者",
        },
        level = 44,
        faction = "A",
        start = {
            kind = "npc",
            id = 2916,
            name = {
                enUS = "Historian Karnik",
                zhCN = "史学家卡尼克",
            },
            map = 1455,
            x = 77.54,
            y = 11.82,
        },
        after = { 1139 },
        chainOnly = true,
    },
    [1149] = {
        name = {
            enUS = "Test of Faith",
            zhCN = "信仰的试炼",
        },
        level = 26,
        faction = "H",
        start = {
            kind = "npc",
            id = 2986,
            name = {
                enUS = "Dorn Plainstalker",
                zhCN = "多恩·平原行者",
            },
            map = 1441,
            x = 53.95,
            y = 41.49,
        },
        after = { 1160 },
        chainOnly = true,
    },
    [1150] = {
        name = {
            enUS = "Test of Endurance",
            zhCN = "耐力的试炼",
        },
        level = 30,
        faction = "H",
        start = {
            kind = "npc",
            id = 2986,
            name = {
                enUS = "Dorn Plainstalker",
                zhCN = "多恩·平原行者",
            },
            map = 1441,
            x = 53.95,
            y = 41.49,
        },
        after = { 1160 },
        chainOnly = true,
    },
    [1151] = {
        name = {
            enUS = "Test of Strength",
            zhCN = "力量的试炼",
        },
        level = 30,
        faction = "H",
        start = {
            kind = "npc",
            id = 2986,
            name = {
                enUS = "Dorn Plainstalker",
                zhCN = "多恩·平原行者",
            },
            map = 1441,
            x = 53.95,
            y = 41.49,
        },
        after = { 1160 },
        chainOnly = true,
    },
    [1152] = {
        name = {
            enUS = "Test of Lore",
            zhCN = "知识试炼",
        },
        level = 30,
        faction = "H",
        start = {
            kind = "npc",
            id = 2986,
            name = {
                enUS = "Dorn Plainstalker",
                zhCN = "多恩·平原行者",
            },
            map = 1441,
            x = 53.95,
            y = 41.49,
        },
        after = { 1160 },
        chainOnly = true,
    },
    [1154] = {
        name = {
            enUS = "Test of Lore",
            zhCN = "知识试炼",
        },
        level = 30,
        faction = "H",
        start = {
            kind = "npc",
            id = 4489,
            name = {
                enUS = "Braug Dimspirit",
                zhCN = "布劳格·幽魂",
            },
            map = 1442,
            x = 78.8,
            y = 45.69,
        },
        after = { 1160, 6627 },
        chainOnly = true,
    },
    [1394] = {
        name = {
            enUS = "Final Passage",
            zhCN = "通过试炼",
        },
        level = 36,
        faction = "H",
        start = {
            kind = "npc",
            id = 4488,
            name = {
                enUS = "Parqual Fintallas",
                zhCN = "帕科瓦·芬塔拉斯",
            },
            map = 1458,
            x = 57.8,
            y = 65.42,
        },
        chainOnly = true,
    },
    [1424] = {
        name = {
            enUS = "Pool of Tears",
            zhCN = "泪水之池",
        },
        level = 43,
        faction = "H",
        start = {
            kind = "npc",
            id = 1443,
            name = {
                enUS = "Fel'zerul",
                zhCN = "费泽鲁尔",
            },
            map = 1435,
            x = 47.93,
            y = 54.78,
        },
        after = { 1445 },
        chainOnly = true,
    },
    [1429] = {
        name = {
            enUS = "The Atal'ai Exile",
            zhCN = "阿塔莱流放者",
        },
        level = 44,
        faction = "H",
        start = {
            kind = "npc",
            id = 1443,
            name = {
                enUS = "Fel'zerul",
                zhCN = "费泽鲁尔",
            },
            map = 1435,
            x = 47.93,
            y = 54.78,
        },
        after = { 1445 },
        chainOnly = true,
    },
    [1444] = {
        name = {
            enUS = "Return to Fel'Zerul",
            zhCN = "向费泽鲁尔复命",
        },
        level = 44,
        faction = "H",
        start = {
            kind = "npc",
            id = 5598,
            name = {
                enUS = "Atal'ai Exile",
                zhCN = "阿塔莱流放者",
            },
            map = 1425,
            x = 33.75,
            y = 75.21,
        },
        after = { 1445 },
        chainOnly = true,
    },
    [1448] = {
        name = {
            enUS = "In Search of The Temple",
            zhCN = "调查神庙",
        },
        level = 43,
        faction = "A",
        start = {
            kind = "npc",
            id = 5384,
            name = {
                enUS = "Brohann Caskbelly",
                zhCN = "布罗哈恩·铁桶",
            },
            map = 1453,
            x = 70.2,
            y = 40.7,
        },
        after = { 1475 },
        chainOnly = true,
    },
    [1449] = {
        name = {
            enUS = "To The Hinterlands",
            zhCN = "去辛特兰的旅程",
        },
        level = 43,
        faction = "A",
        start = {
            kind = "npc",
            id = 5384,
            name = {
                enUS = "Brohann Caskbelly",
                zhCN = "布罗哈恩·铁桶",
            },
            map = 1453,
            x = 70.2,
            y = 40.7,
        },
        after = { 1475 },
        chainOnly = true,
    },
    [1450] = {
        name = {
            enUS = "Gryphon Master Talonaxe",
            zhCN = "狮鹫管理员",
        },
        level = 43,
        faction = "A",
        start = {
            kind = "npc",
            id = 5635,
            name = {
                enUS = "Falstad Wildhammer",
                zhCN = "弗斯塔德·蛮锤",
            },
            map = 1425,
            x = 11.81,
            y = 46.76,
        },
        after = { 1475 },
        chainOnly = true,
    },
    [1451] = {
        name = {
            enUS = "Rhapsody Shindigger",
            zhCN = "拉普索迪·铁铲",
        },
        level = 43,
        faction = "A",
        start = {
            kind = "npc",
            id = 5636,
            name = {
                enUS = "Gryphon Master Talonaxe",
                zhCN = "狮鹫管理员沙拉克·鹰斧",
            },
            map = 1425,
            x = 9.75,
            y = 44.47,
        },
        after = { 1475 },
        chainOnly = true,
    },
    [1452] = {
        name = {
            enUS = "Rhapsody's Kalimdor Kocktail",
            zhCN = "拉普索迪的卡利姆多鸡尾酒",
        },
        level = 43,
        faction = "A",
        start = {
            kind = "npc",
            id = 5634,
            name = {
                enUS = "Rhapsody Shindigger",
                zhCN = "拉普索迪·铁铲",
            },
            map = 1425,
            x = 26.94,
            y = 48.59,
        },
        after = { 1475 },
        chainOnly = true,
    },
    [1469] = {
        name = {
            enUS = "Rhapsody's Tale",
            zhCN = "拉普索迪的故事",
        },
        level = 43,
        faction = "A",
        start = {
            kind = "npc",
            id = 5634,
            name = {
                enUS = "Rhapsody Shindigger",
                zhCN = "拉普索迪·铁铲",
            },
            map = 1425,
            x = 26.94,
            y = 48.59,
        },
        after = { 1475 },
        chainOnly = true,
    },
    [1947] = {
        name = {
            enUS = "Journey to the Marsh",
            zhCN = "沼泽之旅",
        },
        level = 38,
        start = {
            kind = "npc",
            id = 5497,
            name = {
                enUS = "Jennea Cannon",
                zhCN = "詹妮亚·坎农",
            },
            map = 1453,
            x = 38.62,
            y = 79.3,
        },
        after = { 1951 },
        chainOnly = true,
    },
    [1949] = {
        name = {
            enUS = "Hidden Secrets",
            zhCN = "隐藏的秘密",
        },
        level = 38,
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        after = { 1951 },
        chainOnly = true,
    },
    [1950] = {
        name = {
            enUS = "Get the Scoop",
            zhCN = "解封咒语",
        },
        level = 30,
        start = {
            kind = "npc",
            id = 6548,
            name = {
                enUS = "Magus Tirth",
                zhCN = "大法师提尔斯",
            },
            map = 1441,
            x = 78.29,
            y = 75.7,
        },
        after = { 1951 },
        chainOnly = true,
    },
    [1952] = {
        name = {
            enUS = "Mage's Wand",
            zhCN = "法师的魔杖",
        },
        level = 40,
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        chainOnly = true,
    },
    [1953] = {
        name = {
            enUS = "Return to the Marsh",
            zhCN = "返回沼泽",
        },
        level = 40,
        start = {
            kind = "npc",
            id = 4568,
            name = {
                enUS = "Anastasia Hartwell",
                zhCN = "安娜斯塔西娅·哈特威尔",
            },
            map = 1458,
            x = 85.14,
            y = 10.03,
        },
        after = { 1956 },
        chainOnly = true,
    },
    [1954] = {
        name = {
            enUS = "The Infernal Orb",
            zhCN = "地狱火宝珠",
        },
        level = 40,
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        after = { 1956 },
        chainOnly = true,
    },
    [1955] = {
        name = {
            enUS = "The Exorcism",
            zhCN = "驱除魔鬼",
        },
        level = 40,
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        after = { 1956 },
        chainOnly = true,
    },
    [1957] = {
        name = {
            enUS = "Mana Surges",
            zhCN = "法力怒灵",
        },
        level = 40,
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        chainOnly = true,
    },
    [1958] = {
        name = {
            enUS = "Celestial Power",
            zhCN = "苍穹之力",
        },
        level = 40,
        start = {
            kind = "npc",
            id = 6546,
            name = {
                enUS = "Tabetha",
                zhCN = "塔贝萨",
            },
            map = 1445,
            x = 46.06,
            y = 57.09,
        },
        chainOnly = true,
    },
    [2041] = {
        name = {
            enUS = "Speak with Shoni",
            zhCN = "沉默的舒尼",
        },
        level = 15,
        faction = "A",
        start = {
            kind = "npc",
            id = 6569,
            name = {
                enUS = "Gnoarn",
                zhCN = "诺恩",
            },
            map = 1455,
            x = 69.18,
            y = 50.55,
        },
        after = { 2040 },
        chainOnly = true,
    },
    [2203] = {
        name = {
            enUS = "Badlands Reagent Run II",
            zhCN = "荒芜之地的试剂 II",
        },
        level = 44,
        faction = "H",
        start = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        chainOnly = true,
    },
    [2204] = {
        name = {
            enUS = "Restoring the Necklace",
            zhCN = "修复项链",
        },
        level = 44,
        faction = "A",
        start = {
            kind = "object",
            id = 112877,
            name = {
                enUS = "Talvash's Scrying Bowl",
                zhCN = "塔瓦斯德的占卜之碗",
            },
        },
        after = { 2361 },
        chainOnly = true,
    },
    [2258] = {
        name = {
            enUS = "Badlands Reagent Run",
            zhCN = "荒芜之地的试剂",
        },
        level = 39,
        faction = "H",
        start = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        after = { 2202 },
        chainOnly = true,
    },
    [2340] = {
        name = {
            enUS = "Deliver the Gems",
            zhCN = "交付宝石",
        },
        level = 44,
        faction = "H",
        start = {
            kind = "npc",
            id = 6868,
            name = {
                enUS = "Jarkal Mossmeld",
                zhCN = "加卡尔",
            },
            map = 1418,
            x = 2.42,
            y = 46.06,
        },
        chainOnly = true,
    },
    [2341] = {
        name = {
            enUS = "Necklace Recovery, Take 3",
            zhCN = "项链任务的终结",
        },
        level = 44,
        faction = "H",
        start = {
            kind = "npc",
            id = 6986,
            name = {
                enUS = "Dran Droffers",
                zhCN = "德兰·杜佛斯",
            },
            map = 1454,
            x = 59.49,
            y = 36.57,
        },
        chainOnly = true,
    },
    [2500] = {
        name = {
            enUS = "Badlands Reagent Run",
            zhCN = "荒芜之地的材料",
        },
        level = 39,
        faction = "A",
        start = {
            kind = "npc",
            id = 1470,
            name = {
                enUS = "Ghak Healtouch",
                zhCN = "加克",
            },
            map = 1432,
            x = 37.07,
            y = 49.38,
        },
        after = { 17 },
        chainOnly = true,
    },
    [2745] = {
        name = {
            enUS = "Infiltrating the Castle",
            zhCN = "潜入城堡",
        },
        level = 31,
        faction = "A",
        start = {
            kind = "npc",
            id = 482,
            name = {
                enUS = "Elling Trias",
                zhCN = "埃林·提亚斯",
            },
            map = 1453,
            x = 59.91,
            y = 64.18,
        },
        chainOnly = true,
    },
    [2864] = {
        name = {
            enUS = "Tran'rek",
            zhCN = "特兰雷克",
        },
        level = 45,
        start = {
            kind = "npc",
            id = 773,
            name = {
                enUS = "Krazek",
                zhCN = "克拉兹克",
            },
            map = 1434,
            x = 26.94,
            y = 77.21,
        },
        after = { 2865 },
        chainOnly = true,
    },
    [2933] = {
        name = {
            enUS = "Venom Bottles",
            zhCN = "毒液瓶",
        },
        level = 43,
        faction = "H",
        start = {
            kind = "object",
            id = 142702,
            name = {
                enUS = "Venom Bottle",
                zhCN = "毒液瓶",
            },
            map = 1425,
            x = 23.54,
            y = 58.8,
        },
        after = { 2936 },
        chainOnly = true,
    },
    [2934] = {
        name = {
            enUS = "Undamaged Venom Sac",
            zhCN = "完好无损的毒囊",
        },
        level = 45,
        faction = "H",
        start = {
            kind = "npc",
            id = 2216,
            name = {
                enUS = "Apothecary Lydon",
                zhCN = "药剂师林度恩",
            },
            map = 1424,
            x = 61.44,
            y = 19.06,
        },
        after = { 2936 },
        chainOnly = true,
    },
    [2935] = {
        name = {
            enUS = "Consult Master Gadrin",
            zhCN = "请教加德林大师",
        },
        level = 45,
        faction = "H",
        start = {
            kind = "npc",
            id = 2216,
            name = {
                enUS = "Apothecary Lydon",
                zhCN = "药剂师林度恩",
            },
            map = 1424,
            x = 61.44,
            y = 19.06,
        },
        after = { 2936 },
        chainOnly = true,
    },
    [2937] = {
        name = {
            enUS = "Summoning Shadra",
            zhCN = "召唤沙德拉",
        },
        level = 55,
        faction = "H",
        start = {
            kind = "npc",
            id = 3188,
            name = {
                enUS = "Master Gadrin",
                zhCN = "加德林大师",
            },
            map = 1411,
            x = 55.95,
            y = 74.72,
        },
        chainOnly = true,
    },
    [2938] = {
        name = {
            enUS = "Venom to the Undercity",
            zhCN = "送往幽暗城的毒药",
        },
        level = 55,
        faction = "H",
        start = {
            kind = "npc",
            id = 2216,
            name = {
                enUS = "Apothecary Lydon",
                zhCN = "药剂师林度恩",
            },
            map = 1424,
            x = 61.44,
            y = 19.06,
        },
        chainOnly = true,
    },
    [2954] = {
        name = {
            enUS = "The Stone Watcher",
            zhCN = "石头卫士",
        },
        level = 50,
        start = {
            kind = "npc",
            id = 7918,
            name = {
                enUS = "Stone Watcher of Norgannon",
                zhCN = "诺甘农的石卫兵",
            },
        },
        chainOnly = true,
    },
    [2965] = {
        name = {
            enUS = "Portents of Uldum",
            zhCN = "奥丹姆的线索",
        },
        level = 50,
        faction = "H",
        start = {
            kind = "npc",
            id = 3978,
            name = {
                enUS = "Sage Truthseeker",
                zhCN = "圣者图希克",
            },
            map = 1456,
            x = 34.4,
            y = 46.87,
        },
        chainOnly = true,
    },
    [2966] = {
        name = {
            enUS = "Seeing What Happens",
            zhCN = "拭目以待",
        },
        level = 50,
        faction = "H",
        start = {
            kind = "npc",
            id = 5770,
            name = {
                enUS = "Nara Wildmane",
                zhCN = "纳拉·蛮鬃",
            },
            map = 1456,
            x = 75.65,
            y = 31.61,
        },
        chainOnly = true,
    },
    [2988] = {
        name = {
            enUS = "Witherbark Cages",
            zhCN = "枯木巨魔的牢笼",
        },
        level = 45,
        faction = "A",
        start = {
            kind = "npc",
            id = 5636,
            name = {
                enUS = "Gryphon Master Talonaxe",
                zhCN = "狮鹫管理员沙拉克·鹰斧",
            },
            map = 1425,
            x = 9.75,
            y = 44.47,
        },
        after = { 2991 },
        chainOnly = true,
    },
    [2989] = {
        name = {
            enUS = "The Altar of Zul",
            zhCN = "祖尔祭坛",
        },
        level = 48,
        faction = "A",
        start = {
            kind = "npc",
            id = 5636,
            name = {
                enUS = "Gryphon Master Talonaxe",
                zhCN = "狮鹫管理员沙拉克·鹰斧",
            },
            map = 1425,
            x = 9.75,
            y = 44.47,
        },
        after = { 2991 },
        chainOnly = true,
    },
    [2990] = {
        name = {
            enUS = "Thadius Grimshade",
            zhCN = "萨迪斯·格希德",
        },
        level = 47,
        faction = "A",
        start = {
            kind = "npc",
            id = 5636,
            name = {
                enUS = "Gryphon Master Talonaxe",
                zhCN = "狮鹫管理员沙拉克·鹰斧",
            },
            map = 1425,
            x = 9.75,
            y = 44.47,
        },
        after = { 2991 },
        chainOnly = true,
    },
    [2992] = {
        name = {
            enUS = "The Divination",
            zhCN = "占卜",
        },
        level = 47,
        faction = "A",
        start = {
            kind = "npc",
            id = 8022,
            name = {
                enUS = "Thadius Grimshade",
                zhCN = "萨迪斯·格希德",
            },
            map = 1419,
            x = 66.9,
            y = 19.47,
        },
        chainOnly = true,
    },
    [2993] = {
        name = {
            enUS = "Return to the Hinterlands",
            zhCN = "返回辛特兰",
        },
        level = 47,
        faction = "A",
        start = {
            kind = "npc",
            id = 8022,
            name = {
                enUS = "Thadius Grimshade",
                zhCN = "萨迪斯·格希德",
            },
            map = 1419,
            x = 66.9,
            y = 19.47,
        },
        chainOnly = true,
    },
    [2994] = {
        name = {
            enUS = "Saving Sharpbeak",
            zhCN = "拯救沙普比克",
        },
        level = 53,
        faction = "A",
        start = {
            kind = "npc",
            id = 5636,
            name = {
                enUS = "Gryphon Master Talonaxe",
                zhCN = "狮鹫管理员沙拉克·鹰斧",
            },
            map = 1425,
            x = 9.75,
            y = 44.47,
        },
        chainOnly = true,
    },
    [3380] = {
        name = {
            enUS = "The Sunken Temple",
            zhCN = "沉没的神庙",
        },
        level = 51,
        faction = "H",
        start = {
            kind = "npc",
            id = 8115,
            name = {
                enUS = "Witch Doctor Uzer'i",
                zhCN = "巫医尤克里",
            },
            map = 1444,
            x = 74.42,
            y = 43.36,
        },
        after = { 3446, 3447 },
        chainOnly = true,
    },
    [3441] = {
        name = {
            enUS = "Divine Retribution",
            zhCN = "神圣的惩戒",
        },
        level = 48,
        start = {
            kind = "npc",
            id = 8479,
            name = {
                enUS = "Kalaran Windblade",
                zhCN = "卡拉然·温布雷",
            },
            map = 1427,
            x = 39.06,
            y = 38.99,
        },
        after = { 4024 },
        chainOnly = true,
    },
    [3442] = {
        name = {
            enUS = "The Flawless Flame",
            zhCN = "无瑕之焰",
        },
        level = 48,
        start = {
            kind = "npc",
            id = 8479,
            name = {
                enUS = "Kalaran Windblade",
                zhCN = "卡拉然·温布雷",
            },
            map = 1427,
            x = 39.06,
            y = 38.99,
        },
        after = { 4024 },
        chainOnly = true,
    },
    [3443] = {
        name = {
            enUS = "Forging the Shaft",
            zhCN = "铸造火炬杆",
        },
        level = 48,
        start = {
            kind = "npc",
            id = 8479,
            name = {
                enUS = "Kalaran Windblade",
                zhCN = "卡拉然·温布雷",
            },
            map = 1427,
            x = 39.06,
            y = 38.99,
        },
        after = { 4024 },
        chainOnly = true,
    },
    [3444] = {
        name = {
            enUS = "The Stone Circle",
            zhCN = "石环",
        },
        level = 51,
        start = {
            kind = "npc",
            id = 7771,
            name = {
                enUS = "Marvon Rivetseeker",
                zhCN = "玛尔冯·瑞文斯克",
            },
            map = 1446,
            x = 52.71,
            y = 45.92,
        },
        after = { 3446, 3447 },
        chainOnly = true,
    },
    [3452] = {
        name = {
            enUS = "The Flame's Casing",
            zhCN = "烈焰之盒",
        },
        level = 50,
        start = {
            kind = "npc",
            id = 8479,
            name = {
                enUS = "Kalaran Windblade",
                zhCN = "卡拉然·温布雷",
            },
            map = 1427,
            x = 39.06,
            y = 38.99,
        },
        after = { 4024 },
        chainOnly = true,
    },
    [3453] = {
        name = {
            enUS = "The Torch of Retribution",
            zhCN = "惩戒火炬",
        },
        level = 50,
        start = {
            kind = "npc",
            id = 8479,
            name = {
                enUS = "Kalaran Windblade",
                zhCN = "卡拉然·温布雷",
            },
            map = 1427,
            x = 39.06,
            y = 38.99,
        },
        after = { 4024, 3454 },
        chainOnly = true,
    },
    [3462] = {
        name = {
            enUS = "Squire Maltrake",
            zhCN = "侍卫玛特拉克",
        },
        level = 50,
        start = {
            kind = "npc",
            id = 8479,
            name = {
                enUS = "Kalaran Windblade",
                zhCN = "卡拉然·温布雷",
            },
            map = 1427,
            x = 39.06,
            y = 38.99,
        },
        after = { 4024 },
        chainOnly = true,
    },
    [3463] = {
        name = {
            enUS = "Set Them Ablaze!",
            zhCN = "烧掉它们！",
        },
        level = 52,
        start = {
            kind = "npc",
            id = 8509,
            name = {
                enUS = "Squire Maltrake",
                zhCN = "侍卫玛特拉克",
            },
            map = 1427,
            x = 39.17,
            y = 39.0,
        },
        after = { 4024 },
        chainOnly = true,
    },
    [3481] = {
        name = {
            enUS = "Trinkets...",
            zhCN = "打开箱子…",
        },
        level = 50,
        start = {
            kind = "object",
            id = 149502,
            name = {
                enUS = "Hoard of the Black Dragonflight",
                zhCN = "黑龙的财宝",
            },
            map = 1427,
            x = 38.85,
            y = 38.99,
        },
        after = { 4024 },
        chainOnly = true,
    },
    [3512] = {
        name = {
            enUS = "In Eranikus' Own Words",
            zhCN = "帮助伊兰尼库斯",
        },
        level = 55,
        start = {
            kind = "npc",
            id = 5353,
            name = {
                enUS = "Itharius",
                zhCN = "伊萨里奥斯",
            },
            map = 1435,
            x = 13.67,
            y = 71.72,
        },
        chainOnly = true,
    },
    [3520] = {
        name = {
            enUS = "Screecher Spirits",
            zhCN = "尖啸者的灵魂",
        },
        level = 44,
        start = {
            kind = "npc",
            id = 8579,
            name = {
                enUS = "Yeh'kinya",
                zhCN = "叶基亚",
            },
            map = 1446,
            x = 66.99,
            y = 22.36,
        },
        after = { 4788, 3528, 3527 },
        chainOnly = true,
    },
    [4002] = {
        name = {
            enUS = "The Eastern Kingdom",
            zhCN = "东部王国",
        },
        level = 54,
        faction = "H",
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        after = { 4003 },
        chainOnly = true,
    },
    [4004] = {
        name = {
            enUS = "The Princess Saved?",
            zhCN = "拯救公主？",
        },
        level = 60,
        faction = "H",
        start = {
            kind = "npc",
            id = 8929,
            name = {
                enUS = "Princess Moira Bronzebeard",
                zhCN = "铁炉堡公主茉艾拉·铜须",
            },
        },
        chainOnly = true,
    },
    [4141] = {
        name = {
            enUS = "Muigin and Larion",
            zhCN = "穆尔金和拉瑞安",
        },
        level = 52,
        faction = "A",
        start = {
            kind = "npc",
            id = 9119,
            name = {
                enUS = "Muigin",
                zhCN = "穆尔金",
            },
            map = 1449,
            x = 42.94,
            y = 9.64,
        },
        after = { 4143 },
        chainOnly = true,
    },
    [4142] = {
        name = {
            enUS = "A Visit to Gregan",
            zhCN = "造访格雷甘",
        },
        level = 52,
        faction = "A",
        start = {
            kind = "npc",
            id = 9119,
            name = {
                enUS = "Muigin",
                zhCN = "穆尔金",
            },
            map = 1449,
            x = 42.94,
            y = 9.64,
        },
        after = { 4143 },
        chainOnly = true,
    },
    [4144] = {
        name = {
            enUS = "Bloodpetal Sprouts",
            zhCN = "血瓣花苗",
        },
        level = 53,
        faction = "A",
        start = {
            kind = "npc",
            id = 9119,
            name = {
                enUS = "Muigin",
                zhCN = "穆尔金",
            },
            map = 1449,
            x = 42.94,
            y = 9.64,
        },
        chainOnly = true,
    },
    [4242] = {
        name = {
            enUS = "Abandoned Hope",
            zhCN = "被遗弃的希望",
        },
        level = 54,
        faction = "A",
        start = {
            kind = "npc",
            id = 9023,
            name = {
                enUS = "Marshal Windsor",
                zhCN = "温德索尔元帅",
            },
        },
        chainOnly = true,
    },
    [4264] = {
        name = {
            enUS = "A Crumpled Up Note",
            zhCN = "弄皱的便笺",
        },
        level = 58,
        faction = "A",
        start = {
            kind = "item",
            id = 11446,
            name = {
                enUS = "A Crumpled Up Note",
                zhCN = "弄皱的便笺",
            },
        },
        chainOnly = true,
    },
    [4282] = {
        name = {
            enUS = "A Shred of Hope",
            zhCN = "一丝希望",
        },
        level = 58,
        faction = "A",
        start = {
            kind = "npc",
            id = 9023,
            name = {
                enUS = "Marshal Windsor",
                zhCN = "温德索尔元帅",
            },
        },
        chainOnly = true,
    },
    [4322] = {
        name = {
            enUS = "Jail Break!",
            zhCN = "冲破牢笼！",
        },
        level = 58,
        faction = "A",
        start = {
            kind = "npc",
            id = 9023,
            name = {
                enUS = "Marshal Windsor",
                zhCN = "温德索尔元帅",
            },
        },
        after = { 6402 },
        chainOnly = true,
    },
    [4363] = {
        name = {
            enUS = "The Princess's Surprise",
            zhCN = "语出惊人的公主",
        },
        level = 59,
        faction = "A",
        start = {
            kind = "npc",
            id = 8929,
            name = {
                enUS = "Princess Moira Bronzebeard",
                zhCN = "铁炉堡公主茉艾拉·铜须",
            },
        },
        chainOnly = true,
    },
    [4726] = {
        name = {
            enUS = "Broodling Essence",
            zhCN = "雏龙精华",
        },
        level = 52,
        start = {
            kind = "npc",
            id = 10267,
            name = {
                enUS = "Tinkee Steamboil",
                zhCN = "丁奇·斯迪波尔",
            },
            map = 1428,
            x = 65.24,
            y = 24.0,
        },
        after = { 4771 },
        chainOnly = true,
    },
    [4734] = {
        name = {
            enUS = "Egg Freezing",
            zhCN = "冷冻龙蛋",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 10267,
            name = {
                enUS = "Tinkee Steamboil",
                zhCN = "丁奇·斯迪波尔",
            },
            map = 1428,
            x = 65.24,
            y = 24.0,
        },
        after = { 4771 },
        chainOnly = true,
    },
    [4735] = {
        name = {
            enUS = "Egg Collection",
            zhCN = "收集龙蛋",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 10267,
            name = {
                enUS = "Tinkee Steamboil",
                zhCN = "丁奇·斯迪波尔",
            },
            map = 1428,
            x = 65.24,
            y = 24.0,
        },
        after = { 4771 },
        chainOnly = true,
    },
    [4808] = {
        name = {
            enUS = "Felnok Steelspring",
            zhCN = "菲诺克",
        },
        level = 54,
        start = {
            kind = "npc",
            id = 10267,
            name = {
                enUS = "Tinkee Steamboil",
                zhCN = "丁奇·斯迪波尔",
            },
            map = 1428,
            x = 65.24,
            y = 24.0,
        },
        after = { 4771 },
        chainOnly = true,
    },
    [4809] = {
        name = {
            enUS = "Chillwind Horns",
            zhCN = "冰风奇美拉角",
        },
        level = 54,
        start = {
            kind = "npc",
            id = 10468,
            name = {
                enUS = "Felnok Steelspring",
                zhCN = "菲诺克",
            },
            map = 1452,
            x = 61.63,
            y = 38.61,
        },
        after = { 4771 },
        chainOnly = true,
    },
    [4810] = {
        name = {
            enUS = "Return to Tinkee",
            zhCN = "返回丁奇身边",
        },
        level = 54,
        start = {
            kind = "npc",
            id = 10468,
            name = {
                enUS = "Felnok Steelspring",
                zhCN = "菲诺克",
            },
            map = 1452,
            x = 61.63,
            y = 38.61,
        },
        after = { 4771, 4907 },
        chainOnly = true,
    },
    [4983] = {
        name = {
            enUS = "Bijou's Reconnaissance Report",
            zhCN = "比修的侦察报告",
        },
        level = 59,
        faction = "H",
        start = {
            kind = "npc",
            id = 10257,
            name = {
                enUS = "Bijou",
                zhCN = "比修",
            },
        },
        chainOnly = true,
    },
    [5122] = {
        name = {
            enUS = "The Medallion of Faith",
            zhCN = "信仰奖章",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 10917,
            name = {
                enUS = "Aurius",
                zhCN = "奥里克斯",
            },
        },
        after = { 5125 },
        chainOnly = true,
    },
    [5161] = {
        name = {
            enUS = "Wrath of the Blue Flight",
            zhCN = "蓝龙之怒",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 10929,
            name = {
                enUS = "Haleh",
                zhCN = "哈尔琳",
            },
            map = 1452,
            x = 54.55,
            y = 51.2,
        },
        chainOnly = true,
    },
    [5164] = {
        name = {
            enUS = "Catalogue of the Wayward",
            zhCN = "游荡者目录",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 10976,
            name = {
                enUS = "Jeziba",
                zhCN = "耶兹巴",
            },
            map = 1422,
            x = 39.37,
            y = 66.78,
        },
        chainOnly = true,
    },
    [5166] = {
        name = {
            enUS = "Breastplate of the Chromatic Flight",
            zhCN = "多彩巨龙胸甲",
        },
        level = 60,
        start = {
            kind = "object",
            id = 176192,
            name = {
                enUS = "Catalogue of the Wayward",
                zhCN = "游荡者目录",
            },
            map = 1422,
            x = 39.35,
            y = 66.6,
        },
        chainOnly = true,
    },
    [5167] = {
        name = {
            enUS = "Legplates of the Chromatic Defier",
            zhCN = "多彩挑战者腿甲",
        },
        level = 60,
        start = {
            kind = "object",
            id = 176192,
            name = {
                enUS = "Catalogue of the Wayward",
                zhCN = "游荡者目录",
            },
            map = 1422,
            x = 39.35,
            y = 66.6,
        },
        chainOnly = true,
    },
    [5264] = {
        name = {
            enUS = "Lord Maxwell Tyrosus",
            zhCN = "玛克斯韦尔·泰罗索斯男爵",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11039,
            name = {
                enUS = "Duke Nicholas Zverenhoff",
                zhCN = "尼古拉斯·瑟伦霍夫公爵",
            },
            map = 1423,
            x = 81.44,
            y = 59.82,
        },
        chainOnly = true,
    },
    [5265] = {
        name = {
            enUS = "The Argent Hold",
            zhCN = "银色黎明宝箱",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11034,
            name = {
                enUS = "Lord Maxwell Tyrosus",
                zhCN = "玛克斯韦尔·泰罗索斯男爵",
            },
            map = 1423,
            x = 81.74,
            y = 57.96,
        },
        chainOnly = true,
    },
    [5342] = {
        name = {
            enUS = "The Last Barov",
            zhCN = "巴罗夫的继承人",
        },
        level = 60,
        faction = "H",
        start = {
            kind = "npc",
            id = 11022,
            name = {
                enUS = "Alexi Barov",
                zhCN = "阿莱克斯·巴罗夫",
            },
            map = 1420,
            x = 83.06,
            y = 71.6,
        },
        chainOnly = true,
    },
    [5344] = {
        name = {
            enUS = "The Last Barov",
            zhCN = "巴罗夫的继承人",
        },
        level = 60,
        faction = "A",
        start = {
            kind = "npc",
            id = 11023,
            name = {
                enUS = "Weldon Barov",
                zhCN = "维尔顿·巴罗夫",
            },
            map = 1422,
            x = 43.45,
            y = 83.73,
        },
        chainOnly = true,
    },
    [5461] = {
        name = {
            enUS = "The Human, Ras Frostwhisper",
            zhCN = "莱斯·霜语",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11286,
            name = {
                enUS = "Magistrate Marduke",
                zhCN = "马杜克镇长",
            },
            map = 1422,
            x = 70.57,
            y = 74.11,
        },
        after = { 5466 },
        chainOnly = true,
    },
    [5462] = {
        name = {
            enUS = "The Dying, Ras Frostwhisper",
            zhCN = "亡灵莱斯·霜语",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11286,
            name = {
                enUS = "Magistrate Marduke",
                zhCN = "马杜克镇长",
            },
            map = 1422,
            x = 70.57,
            y = 74.11,
        },
        after = { 5466 },
        chainOnly = true,
    },
    [5463] = {
        name = {
            enUS = "Menethil's Gift",
            zhCN = "米奈希尔的礼物",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11036,
            name = {
                enUS = "Leonid Barthalomew the Revered",
                zhCN = "莱尼德·巴萨罗梅",
            },
            map = 1423,
            x = 81.73,
            y = 57.83,
        },
        after = { 5466 },
        chainOnly = true,
    },
    [5464] = {
        name = {
            enUS = "Menethil's Gift",
            zhCN = "米奈希尔的礼物",
        },
        level = 60,
        start = {
            kind = "object",
            id = 176631,
            name = {
                enUS = "Menethil's Gift",
                zhCN = "米奈希尔的礼物",
            },
        },
        after = { 5466 },
        chainOnly = true,
    },
    [5465] = {
        name = {
            enUS = "Soulbound Keepsake",
            zhCN = "禁锢灵魂的遗物",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11036,
            name = {
                enUS = "Leonid Barthalomew the Revered",
                zhCN = "莱尼德·巴萨罗梅",
            },
            map = 1423,
            x = 81.73,
            y = 57.83,
        },
        after = { 5466 },
        chainOnly = true,
    },
    [5515] = {
        name = {
            enUS = "Krastinov's Bag of Horrors",
            zhCN = "卡斯迪诺夫的恐惧之袋",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11216,
            name = {
                enUS = "Eva Sarkhoff",
                zhCN = "艾瓦·萨克霍夫",
            },
            map = 1422,
            x = 70.22,
            y = 73.71,
        },
        after = { 5384, 5466 },
        chainOnly = true,
    },
    [5522] = {
        name = {
            enUS = "Leonid Barthalomew",
            zhCN = "莱尼德·巴萨罗梅",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 10267,
            name = {
                enUS = "Tinkee Steamboil",
                zhCN = "丁奇·斯迪波尔",
            },
            map = 1428,
            x = 65.24,
            y = 24.0,
        },
        after = { 4771 },
        chainOnly = true,
    },
    [5531] = {
        name = {
            enUS = "Betina Bigglezink",
            zhCN = "贝蒂娜·比格辛克",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 11036,
            name = {
                enUS = "Leonid Barthalomew the Revered",
                zhCN = "莱尼德·巴萨罗梅",
            },
            map = 1423,
            x = 81.73,
            y = 57.83,
        },
        after = { 4771 },
        chainOnly = true,
    },
    [6566] = {
        name = {
            enUS = "What the Wind Carries",
            zhCN = "风吹来的消息",
        },
        level = 60,
        faction = "H",
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        chainOnly = true,
    },
    [6567] = {
        name = {
            enUS = "The Champion of the Horde",
            zhCN = "部落的勇士",
        },
        level = 60,
        faction = "H",
        start = {
            kind = "npc",
            id = 4949,
            name = {
                enUS = "Thrall",
                zhCN = "萨尔",
            },
            map = 1454,
            x = 31.73,
            y = 37.82,
        },
        after = { 6568 },
        chainOnly = true,
    },
    [7046] = {
        name = {
            enUS = "The Scepter of Celebras",
            zhCN = "塞雷布拉斯节杖",
        },
        level = 49,
        start = {
            kind = "npc",
            id = 13716,
            name = {
                enUS = "Celebras the Redeemed",
                zhCN = "赎罪的塞雷布拉斯",
            },
        },
        chainOnly = true,
    },
    [7492] = {
        name = {
            enUS = "Camp Mojache",
            zhCN = "莫沙彻营地",
        },
        level = 57,
        faction = "H",
        start = {
            kind = "npc",
            id = 10880,
            name = {
                enUS = "Warcaller Gorlach",
                zhCN = "公告员高拉克",
            },
            map = 1454,
            x = 37.56,
            y = 75.36,
        },
        after = { 7489 },
        chainOnly = true,
    },
    [7494] = {
        name = {
            enUS = "Feathermoon Stronghold",
            zhCN = "羽月要塞",
        },
        level = 57,
        faction = "A",
        start = {
            kind = "npc",
            id = 2198,
            name = {
                enUS = "Crier Goodman",
                zhCN = "公告员古德曼",
            },
            map = 1453,
            x = 73.0,
            y = 61.7,
        },
        after = { 7488 },
        chainOnly = true,
    },
    [7562] = {
        name = {
            enUS = "Mor'zul Bloodbringer",
            zhCN = "莫苏尔·召血者",
        },
        level = 58,
        start = {
            kind = "npc",
            id = 5520,
            name = {
                enUS = "Spackle Thornberry",
                zhCN = "斯巴克尔",
            },
            map = 1453,
            x = 25.66,
            y = 77.66,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7563] = {
        name = {
            enUS = "Rage of Blood",
            zhCN = "血之狂暴",
        },
        level = 58,
        start = {
            kind = "npc",
            id = 14436,
            name = {
                enUS = "Mor'zul Bloodbringer",
                zhCN = "莫苏尔·召血者",
            },
            map = 1428,
            x = 12.69,
            y = 31.64,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7564] = {
        name = {
            enUS = "Wildeyes",
            zhCN = "戈瑟奇·邪眼",
        },
        level = 58,
        start = {
            kind = "npc",
            id = 14436,
            name = {
                enUS = "Mor'zul Bloodbringer",
                zhCN = "莫苏尔·召血者",
            },
            map = 1428,
            x = 12.69,
            y = 31.64,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7623] = {
        name = {
            enUS = "Lord Banehollow",
            zhCN = "魔王贝恩霍勒",
        },
        level = 58,
        start = {
            kind = "npc",
            id = 14437,
            name = {
                enUS = "Gorzeeki Wildeyes",
                zhCN = "戈瑟奇·邪眼",
            },
            map = 1428,
            x = 12.44,
            y = 31.63,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7624] = {
        name = {
            enUS = "Ulathek the Traitor",
            zhCN = "背叛者乌拉泰克",
        },
        level = 58,
        start = {
            kind = "npc",
            id = 9516,
            name = {
                enUS = "Lord Banehollow",
                zhCN = "魔王贝恩霍勒",
            },
            map = 1448,
            x = 35.93,
            y = 44.42,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7625] = {
        name = {
            enUS = "Xorothian Stardust",
            zhCN = "克索诺斯星尘",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 9516,
            name = {
                enUS = "Lord Banehollow",
                zhCN = "魔王贝恩霍勒",
            },
            map = 1448,
            x = 35.93,
            y = 44.42,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7626] = {
        name = {
            enUS = "Bell of Dethmoora",
            zhCN = "达斯莫拉之铃",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 14436,
            name = {
                enUS = "Mor'zul Bloodbringer",
                zhCN = "莫苏尔·召血者",
            },
            map = 1428,
            x = 12.69,
            y = 31.64,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7627] = {
        name = {
            enUS = "Wheel of the Black March",
            zhCN = "黑暗战车之轮",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 14436,
            name = {
                enUS = "Mor'zul Bloodbringer",
                zhCN = "莫苏尔·召血者",
            },
            map = 1428,
            x = 12.69,
            y = 31.64,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7628] = {
        name = {
            enUS = "Doomsday Candle",
            zhCN = "末日蜡烛",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 14436,
            name = {
                enUS = "Mor'zul Bloodbringer",
                zhCN = "莫苏尔·召血者",
            },
            map = 1428,
            x = 12.69,
            y = 31.64,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7629] = {
        name = {
            enUS = "Imp Delivery",
            zhCN = "瓶中的小鬼",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 14437,
            name = {
                enUS = "Gorzeeki Wildeyes",
                zhCN = "戈瑟奇·邪眼",
            },
            map = 1428,
            x = 12.44,
            y = 31.63,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7630] = {
        name = {
            enUS = "Arcanite",
            zhCN = "奥金锭",
        },
        level = 60,
        start = {
            kind = "npc",
            id = 14437,
            name = {
                enUS = "Gorzeeki Wildeyes",
                zhCN = "戈瑟奇·邪眼",
            },
            map = 1428,
            x = 12.44,
            y = 31.63,
        },
        after = { 7631 },
        chainOnly = true,
    },
    [7667] = {
        name = {
            enUS = "Material Assistance",
            zhCN = "收集材料",
        },
        level = 60,
        faction = "H",
        start = {
            kind = "npc",
            id = 13417,
            name = {
                enUS = "Sagorne Creststrider",
                zhCN = "萨格尼",
            },
            map = 1454,
            x = 38.66,
            y = 35.92,
        },
        after = { 8258 },
        chainOnly = true,
    },
    [8181] = {
        name = {
            enUS = "Confront Yeh'kinya",
            zhCN = "面对叶基亚",
        },
        level = 58,
        start = {
            kind = "npc",
            id = 10460,
            name = {
                enUS = "Prospector Ironboot",
                zhCN = "勘查员詹斯·铁靴",
            },
            map = 1446,
            x = 66.89,
            y = 24.03,
        },
        chainOnly = true,
    },
    [8182] = {
        name = {
            enUS = "The Hand of Rastakhan",
            zhCN = "拉斯塔哈之手",
        },
        level = 58,
        start = {
            kind = "npc",
            id = 10460,
            name = {
                enUS = "Prospector Ironboot",
                zhCN = "勘查员詹斯·铁靴",
            },
            map = 1446,
            x = 66.89,
            y = 24.03,
        },
        chainOnly = true,
    },
    [96391] = {
        name = {
            enUS = "Underground Map",
            zhCN = "地下地图",
        },
        level = 15,
        start = {
            kind = "npc",
            id = 264936,
            name = {
                enUS = "Earthseer Farsen",
                zhCN = "大地先知法森",
            },
            map = 1426,
            x = 64.8,
            y = 58.5,
        },
        after = { 96393 },
        chainOnly = true,
    },
    [153] = {
        level = 15,
        min = 9,
        start = {
            kind = "npc",
            map = 1436,
            x = 56.6,
            y = 47.3,
        },
        unverified = true,
        chainOnly = true,
    },
    [1106] = {
        level = 26,
        start = {
            kind = "npc",
            name = {
                enUS = "Fizzle Brassbolts",
            },
        },
        after = { 1108 },
        unverified = true,
        chainOnly = true,
    },
    [1108] = {
        level = 28,
        start = {
            kind = "npc",
            name = {
                enUS = "Martek the Exiled",
            },
        },
        before = { 1106 },
        after = { 1137 },
        unverified = true,
        chainOnly = true,
    },
    [1137] = {
        level = 28,
        start = {
            kind = "npc",
            name = {
                enUS = "Martek the Exiled",
            },
        },
        before = { 1108 },
        after = { 1190 },
        unverified = true,
        chainOnly = true,
    },
    [1159] = {
        level = 25,
        start = {
            kind = "npc",
            name = {
                enUS = "Braug Dimspirit",
            },
        },
        before = { 6627 },
        unverified = true,
        chainOnly = true,
    },
    [1190] = {
        level = 29,
        start = {
            kind = "npc",
            name = {
                enUS = "Pozzik",
            },
        },
        before = { 1137 },
        after = { 1194 },
        unverified = true,
        chainOnly = true,
    },
    [1192] = {
        min = 29,
        start = {
            kind = "npc",
            id = 4630,
            name = {
                enUS = "Pozzik",
            },
            map = 1441,
            x = 80,
            y = 75.8,
        },
        before = { 1194 },
        unverified = true,
        instances = { "uldaman" },
    },
    [1193] = {
        min = 56,
        start = {
            kind = "npc",
            name = {
                enUS = "A Broken Trap",
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "north" },
    },
    [1194] = {
        level = 29,
        start = {
            kind = "npc",
            name = {
                enUS = "Rizzle's Schematics",
            },
        },
        before = { 1190 },
        after = { 1192 },
        unverified = true,
        chainOnly = true,
    },
    [1318] = {
        level = 60,
        min = 56,
        rewards = {
            xp = 8300,
            referenceItems = {
                {
                    id = 18366,
                },
                {
                    id = 18367,
                },
                {
                    id = 18368,
                },
                {
                    id = 18369,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [1650] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Duthorian Rall",
            },
        },
        before = { 1649 },
        after = { 1651 },
        unverified = true,
        chainOnly = true,
    },
    [1651] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Daphne Stilwell",
            },
        },
        before = { 1650 },
        after = { 1652 },
        unverified = true,
        chainOnly = true,
    },
    [1652] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Daphne Stilwell",
            },
        },
        before = { 1651 },
        after = { 1653 },
        unverified = true,
        chainOnly = true,
    },
    [1653] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Duthorian Rall",
            },
        },
        before = { 1652 },
        after = { 1654 },
        unverified = true,
        chainOnly = true,
    },
    [1654] = {
        min = 20,
        start = {
            kind = "npc",
            id = 6181,
            name = {
                enUS = "Jordan Stilwell",
            },
            map = 1426,
            x = 52.4,
            y = 36.8,
        },
        before = { 1653 },
        unverified = true,
        instances = { "deadmines" },
    },
    [1698] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Kelv Sternhammer",
            },
        },
        after = { 1699 },
        unverified = true,
        chainOnly = true,
    },
    [1699] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Yorus Barleybrew",
            },
        },
        before = { 1698 },
        after = { 1702 },
        unverified = true,
        chainOnly = true,
    },
    [1702] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Yorus Barleybrew",
            },
        },
        before = { 1699 },
        unverified = true,
        chainOnly = true,
    },
    [1823] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Torm Ragetotem",
            },
        },
        after = { 1824 },
        unverified = true,
        chainOnly = true,
    },
    [1824] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Ruga Ragetotem",
            },
        },
        before = { 1823 },
        after = { 1825 },
        unverified = true,
        chainOnly = true,
    },
    [1825] = {
        level = 20,
        start = {
            kind = "npc",
            name = {
                enUS = "Ruga Ragetotem",
            },
        },
        before = { 1824 },
        unverified = true,
        chainOnly = true,
    },
    [2278] = {
        min = 40,
        start = {
            kind = "npc",
            name = {
                enUS = "The Discs of Norgannon",
            },
        },
        unverified = true,
        instances = { "uldaman" },
    },
    [2769] = {
        level = 40,
        start = {
            kind = "npc",
            name = {
                enUS = "Klockmort Spannerspan",
            },
        },
        after = { 2770 },
        unverified = true,
        chainOnly = true,
    },
    [2861] = {
        level = 40,
        start = {
            kind = "npc",
            name = {
                enUS = "Ursyn Ghull / Anastasia Hartwell / Bink / Jennea Cannon / Deino",
            },
        },
        after = { 2846 },
        unverified = true,
        chainOnly = true,
    },
    [2925] = {
        level = 24,
        start = {
            kind = "npc",
            name = {
                enUS = "Mathiel",
            },
        },
        after = { 2924 },
        unverified = true,
        chainOnly = true,
    },
    [2931] = {
        level = 25,
        start = {
            kind = "npc",
            name = {
                enUS = "Gaxim Rustfizzle",
            },
        },
        after = { 2930 },
        unverified = true,
        chainOnly = true,
    },
    [2951] = {
        level = 30,
        min = 25,
        start = {
            kind = "npc",
            name = {
                enUS = "Super Cleaner 5200",
            },
        },
        inside = true,
        after = { 2952 },
        rewards = {
            xp = 2450,
            money = 300,
        },
        unverified = true,
        instances = { "gnomeregan" },
    },
    [2952] = {
        level = 30,
        min = 25,
        start = {
            kind = "npc",
            name = {
                enUS = "Super Cleaner 5200",
            },
        },
        inside = true,
        before = { 2951 },
        rewards = {
            xp = 2450,
            referenceItems = {
                {
                    id = 9363,
                },
            },
        },
        unverified = true,
        instances = { "gnomeregan" },
    },
    [3445] = {
        min = 46,
        start = {
            kind = "npc",
            id = 7900,
            name = {
                enUS = "Angelas Moonbreeze",
            },
            map = 1444,
            x = 31.8,
            y = 45.4,
        },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [3454] = {
        level = 40,
        start = {
            kind = "npc",
            name = {
                enUS = "Velarok Windblade",
            },
        },
        before = { 3453 },
        unverified = true,
        chainOnly = true,
    },
    [4083] = {
        level = 55,
        min = 40,
        start = {
            kind = "npc",
            name = {
                enUS = "Senani Thunderheart",
            },
        },
        inside = true,
        rewards = {
            xp = 5650,
        },
        unverified = true,
        instances = { "blackrock-depths" },
    },
    [4145] = {
        level = 47,
        start = {
            kind = "npc",
            name = {
                enUS = "Larion",
            },
        },
        after = { 4147 },
        unverified = true,
        chainOnly = true,
    },
    [4147] = {
        level = 47,
        start = {
            kind = "npc",
            name = {
                enUS = "Larion",
            },
        },
        before = { 4145 },
        unverified = true,
        chainOnly = true,
    },
    [4765] = {
        level = 60,
        min = 57,
        faction = "A",
        start = {
            kind = "npc",
            id = 9565,
            name = {
                enUS = "Mayara Brightwing",
            },
            map = 1428,
            x = 84.8,
            y = 69,
        },
        before = { 4764 },
        rewards = {
            xp = 6600,
            money = 27000,
            referenceItems = {
                {
                    id = 15861,
                },
                {
                    id = 15860,
                },
            },
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [4769] = {
        level = 57,
        start = {
            kind = "npc",
            name = {
                enUS = "Apothecary Zinge",
            },
        },
        unverified = true,
        chainOnly = true,
    },
    [4866] = {
        level = 60,
        min = 55,
        start = {
            kind = "npc",
            id = 9563,
            name = {
                enUS = "Ragged John",
            },
            map = 1428,
            x = 65,
            y = 23.6,
        },
        rewards = {
            xp = 9950,
            money = 18000,
            referenceItems = {
                {
                    id = 15873,
                },
            },
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [4867] = {
        level = 60,
        min = 55,
        start = {
            kind = "npc",
            id = 10799,
            name = {
                enUS = "Warosh",
            },
        },
        inside = true,
        rewards = {
            xp = 9950,
            referenceItems = {
                {
                    id = 15867,
                },
            },
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
    },
    [4907] = {
        level = 57,
        start = {
            kind = "npc",
            name = {
                enUS = "Felnok Steelspring",
            },
        },
        before = { 4810 },
        unverified = true,
        chainOnly = true,
    },
    [5047] = {
        level = 60,
        min = 55,
        start = {
            kind = "npc",
            id = 10776,
            name = {
                enUS = "Finkle Einhorn",
            },
        },
        inside = true,
        rewards = {
            xp = 6600,
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [5103] = {
        min = 56,
        start = {
            kind = "npc",
            name = {
                enUS = "Human Remains",
            },
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
    },
    [5305] = {
        min = 50,
        start = {
            kind = "npc",
            id = 11191,
            name = {
                enUS = "Lilith the Lithe",
            },
            map = 1452,
            x = 61.2,
            y = 37.2,
        },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [5306] = {
        min = 50,
        start = {
            kind = "npc",
            id = 11192,
            name = {
                enUS = "Kilram",
            },
            map = 1452,
            x = 61.2,
            y = 37,
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "lower" },
    },
    [5307] = {
        min = 50,
        start = {
            kind = "npc",
            id = 11193,
            name = {
                enUS = "Seril Scourgebane",
            },
            map = 1452,
            x = 61.2,
            y = 37.2,
        },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [5528] = {
        level = 60,
        min = 57,
        start = {
            kind = "npc",
            id = 14322,
            name = {
                enUS = "Trampler Craig",
            },
            map = 2557,
            x = 47.2,
            y = 38.8,
        },
        inside = true,
        rewards = {
            referenceItems = {
                {
                    id = 18269,
                },
                {
                    id = 18284,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [5529] = {
        level = 58,
        min = 55,
        start = {
            kind = "npc",
            id = 11035,
            name = {
                enUS = "Betina Bigglezink",
            },
            map = 1423,
            x = 81.4,
            y = 59.4,
        },
        after = { 5582 },
        rewards = {
            xp = 6200,
            money = 9000,
        },
        unverified = true,
        instances = { "scholomance" },
    },
    [5582] = {
        min = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Healthy Dragon Scale",
            },
        },
        before = { 5529 },
        unverified = true,
        instances = { "scholomance" },
    },
    [5742] = {
        level = 52,
        start = {
            kind = "npc",
            name = {
                enUS = "Tirion Fordring",
            },
        },
        before = { 5542 },
        after = { 5781 },
        unverified = true,
        chainOnly = true,
    },
    [5781] = {
        level = 52,
        start = {
            kind = "npc",
            name = {
                enUS = "Tirion Fordring",
            },
        },
        before = { 5742 },
        unverified = true,
        chainOnly = true,
    },
    [5846] = {
        level = 52,
        start = {
            kind = "npc",
            name = {
                enUS = "Tirion Fordring",
            },
        },
        before = { 5845 },
        after = { 5848 },
        unverified = true,
        chainOnly = true,
    },
    [5848] = {
        level = 60,
        min = 52,
        start = {
            kind = "npc",
            id = 11936,
            name = {
                enUS = "Artist Renfray",
            },
            map = 1422,
            x = 65.4,
            y = 75.4,
        },
        before = { 5846 },
        rewards = {
            xp = 6600,
        },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [6133] = {
        level = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "Nathanos Blightcaller",
            },
        },
        after = { 6135 },
        unverified = true,
        chainOnly = true,
    },
    [6135] = {
        level = 56,
        start = {
            kind = "npc",
            name = {
                enUS = "Nathanos Blightcaller",
            },
        },
        before = { 6133 },
        after = { 6163 },
        unverified = true,
        chainOnly = true,
    },
    [6141] = {
        level = 34,
        start = {
            kind = "npc",
            name = {
                enUS = "Brother Crowley",
            },
        },
        unverified = true,
        chainOnly = true,
    },
    [6163] = {
        level = 60,
        min = 56,
        faction = "H",
        start = {
            kind = "npc",
            id = 11878,
            name = {
                enUS = "Nathanos Blightcaller",
            },
            map = 1423,
            x = 26.4,
            y = 74.8,
        },
        before = { 6135 },
        rewards = {
            xp = 6600,
            money = 18000,
            referenceItems = {
                {
                    id = 18022,
                },
                {
                    id = 17001,
                },
            },
        },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [6402] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Marshal Maxwell",
            },
        },
        before = { 4322 },
        after = { 6403 },
        unverified = true,
        chainOnly = true,
    },
    [6403] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Reginald Windsor",
            },
        },
        before = { 6402 },
        after = { 6501 },
        unverified = true,
        chainOnly = true,
    },
    [6501] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Highlord Bolvar Fordragon",
            },
        },
        before = { 6403 },
        after = { 6502 },
        unverified = true,
        chainOnly = true,
    },
    [6502] = {
        level = 60,
        min = 50,
        faction = "A",
        start = {
            kind = "npc",
            id = 10929,
            name = {
                enUS = "Haleh",
            },
            map = 1452,
            x = 54.4,
            y = 51.2,
        },
        before = { 6501 },
        rewards = {
            xp = 8300,
            referenceItems = {
                {
                    id = 16309,
                },
            },
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [6568] = {
        level = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Rokaro",
            },
        },
        before = { 6567 },
        after = { 6569 },
        unverified = true,
        chainOnly = true,
    },
    [6569] = {
        min = 55,
        faction = "H",
        start = {
            kind = "npc",
            id = 11872,
            name = {
                enUS = "Myranda the Hag",
            },
            map = 1422,
            x = 50.8,
            y = 77.8,
        },
        before = { 6568 },
        after = { 6570 },
        rewards = {
            xp = 6600,
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [6570] = {
        level = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Myranda the Hag",
            },
        },
        before = { 6569 },
        after = { 6582, 6583, 6584 },
        unverified = true,
        chainOnly = true,
    },
    [6582] = {
        level = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Emberstrife",
            },
        },
        before = { 6570 },
        after = { 6585 },
        unverified = true,
        chainOnly = true,
    },
    [6583] = {
        level = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Emberstrife",
            },
        },
        before = { 6570 },
        after = { 6585 },
        unverified = true,
        chainOnly = true,
    },
    [6584] = {
        level = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Emberstrife",
            },
        },
        before = { 6570 },
        after = { 6585 },
        unverified = true,
        chainOnly = true,
    },
    [6585] = {
        level = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Emberstrife",
            },
        },
        before = { 6582, 6583, 6584 },
        after = { 6601 },
        unverified = true,
        chainOnly = true,
    },
    [6601] = {
        level = 55,
        start = {
            kind = "npc",
            name = {
                enUS = "Emberstrife",
            },
        },
        before = { 6585 },
        after = { 6602 },
        unverified = true,
        chainOnly = true,
    },
    [6602] = {
        level = 60,
        min = 55,
        faction = "H",
        start = {
            kind = "npc",
            id = 10182,
            name = {
                enUS = "Rokaro",
            },
            map = 1444,
            x = 44.8,
            y = 7.4,
        },
        before = { 6601 },
        rewards = {
            xp = 9950,
            referenceItems = {
                {
                    id = 16309,
                },
            },
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [6627] = {
        level = 25,
        start = {
            kind = "npc",
            name = {
                enUS = "Braug Dimspirit",
            },
        },
        before = { 1154 },
        after = { 1159 },
        unverified = true,
        chainOnly = true,
    },
    [7463] = {
        level = 60,
        min = 60,
        start = {
            kind = "npc",
            id = 14368,
            name = {
                enUS = "Lorekeeper Lydros",
            },
            map = 2557,
            x = 24.7,
            y = 64.7,
        },
        inside = true,
        rewards = {
            xp = 6600,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "east" },
    },
    [7483] = {
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "Lorekeeper Lydros",
            },
        },
        before = { 7482 },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7484] = {
        min = 54,
        start = {
            kind = "npc",
            id = 14368,
            name = {
                enUS = "The Tome of Defense",
            },
            map = 2557,
            x = 24.7,
            y = 64.7,
        },
        before = { 7482 },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7485] = {
        min = 54,
        start = {
            kind = "npc",
            id = 14368,
            name = {
                enUS = "Lorekeeper Lydros",
            },
            map = 2557,
            x = 24.7,
            y = 64.7,
        },
        before = { 7482 },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7498] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "Garona: A Study on Stealth and Treachery",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18465,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7499] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "The Bound Shade",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18466,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7500] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "The Arcanist's Cookbook",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18468,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7501] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "The Power of the Light",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18472,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7502] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "You and Frost Shock",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18467,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7504] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "What the Light Never Tells You",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18469,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7505] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "The Power of the Light",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18471,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7506] = {
        level = 60,
        min = 54,
        start = {
            kind = "npc",
            name = {
                enUS = "The Emerald Dream",
            },
        },
        rewards = {
            xp = 6600,
            money = 100,
            referenceItems = {
                {
                    id = 18470,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7507] = {
        level = 60,
        min = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Lorekeeper Lydros",
            },
        },
        after = { 7508 },
        rewards = {
            xp = 9950,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7508] = {
        level = 60,
        min = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Starts from the item [Dull and Flat Elven Blade]",
            },
        },
        before = { 7507 },
        rewards = {
            xp = 9950,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [7581] = {
        min = 60,
        start = {
            kind = "npc",
            id = 14463,
            name = {
                enUS = "Daio the Decrepit",
            },
            map = 1419,
            x = 34,
            y = 50.2,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "east" },
    },
    [7604] = {
        level = 60,
        min = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Lokhtos Darkbargainer",
            },
        },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 18592,
                },
            },
        },
        unverified = true,
        instances = { "blackrock-depths" },
    },
    [7621] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Eris Havenfire",
            },
        },
        after = { 7622 },
        unverified = true,
        chainOnly = true,
    },
    [7622] = {
        min = 60,
        start = {
            kind = "npc",
            id = 14494,
            name = {
                enUS = "Eris Havenfire",
            },
            map = 1423,
            x = 20.8,
            y = 18.4,
        },
        before = { 7621 },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [7637] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Lord Grayson Shadowbreaker",
            },
        },
        after = { 7639 },
        unverified = true,
        chainOnly = true,
    },
    [7639] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "High Priest Rohan",
            },
        },
        before = { 7637 },
        after = { 7640 },
        unverified = true,
        chainOnly = true,
    },
    [7640] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Lord Grayson Shadowbreaker",
            },
        },
        before = { 7639 },
        after = { 7641 },
        unverified = true,
        chainOnly = true,
    },
    [7641] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Lord Grayson Shadowbreaker",
            },
        },
        before = { 7640 },
        after = { 7642 },
        unverified = true,
        chainOnly = true,
    },
    [7642] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Grimand Elmore",
            },
        },
        before = { 7641 },
        after = { 7643 },
        unverified = true,
        chainOnly = true,
    },
    [7643] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Lord Grayson Shadowbreaker",
            },
        },
        before = { 7642 },
        after = { 7644 },
        unverified = true,
        chainOnly = true,
    },
    [7644] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Ancient Equine Spirit",
            },
        },
        before = { 7643 },
        after = { 7646 },
        unverified = true,
        chainOnly = true,
    },
    [7646] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Lord Grayson Shadowbreaker",
            },
        },
        before = { 7644 },
        after = { 7647 },
        unverified = true,
        chainOnly = true,
    },
    [7647] = {
        start = {
            kind = "npc",
            id = 928,
            map = 1453,
            x = 48.4,
            y = 50.2,
        },
        before = { 7646 },
        unverified = true,
        instances = { "scholomance" },
    },
    [8151] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Kary Thunderhorn / Xor'juul / Dorion / Olmin Burningbeard / Ulfir Ironbeard",
            },
        },
        after = { 8153 },
        unverified = true,
        chainOnly = true,
    },
    [8153] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Ogtinc",
            },
        },
        before = { 8151 },
        after = { 8231 },
        unverified = true,
        chainOnly = true,
    },
    [8231] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Ogtinc",
            },
        },
        before = { 8153 },
        after = { 8232 },
        unverified = true,
        chainOnly = true,
    },
    [8232] = {
        min = 50,
        start = {
            kind = "npc",
            id = 8405,
            name = {
                enUS = "Ogtinc",
            },
            map = 1447,
            x = 42.4,
            y = 42.6,
        },
        before = { 8231 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8233] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Ormok / Anishar / Miles Dexter / Ormyr Flinteye / Lord Tony Romano",
            },
        },
        after = { 8234 },
        unverified = true,
        chainOnly = true,
    },
    [8234] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Lord Jorach Ravenholdt",
            },
        },
        before = { 8233 },
        after = { 8235 },
        unverified = true,
        chainOnly = true,
    },
    [8235] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Archmage Xylem",
            },
        },
        before = { 8234 },
        after = { 8236 },
        unverified = true,
        chainOnly = true,
    },
    [8236] = {
        min = 50,
        start = {
            kind = "npc",
            id = 8379,
            name = {
                enUS = "Archmage Xylem",
            },
            map = 1447,
            x = 29.2,
            y = 40.2,
        },
        before = { 8235 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8250] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Thurston Xane / Pierce Shackleton / Juli Stormkettle / Elsharin / Enyo",
            },
        },
        after = { 8251 },
        unverified = true,
        chainOnly = true,
    },
    [8251] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Archmage Xylem",
            },
        },
        before = { 8250 },
        after = { 8252 },
        unverified = true,
        chainOnly = true,
    },
    [8252] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Archmage Xylem",
            },
        },
        before = { 8251 },
        after = { 8253 },
        unverified = true,
        chainOnly = true,
    },
    [8253] = {
        min = 50,
        start = {
            kind = "npc",
            id = 8379,
            name = {
                enUS = "Archmage Xylem, Morphras",
            },
            map = 1447,
            x = 29.2,
            y = 40.2,
        },
        before = { 8252 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8254] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "High Priestess Laurena / Malakai Cross / Father Cobb / Astarii Starseeker / Jandria / Aelthalyste / Father Lazarus / Theodrus Frostbeard / Braenna Flintcrag / Brother Joshua / X'yera / Priestess Alathea / High Priest Rohan",
            },
        },
        after = { 8255 },
        unverified = true,
        chainOnly = true,
    },
    [8255] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Ogtinc",
            },
        },
        before = { 8254 },
        after = { 8256 },
        unverified = true,
        chainOnly = true,
    },
    [8256] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Ogtinc",
            },
        },
        before = { 8255 },
        after = { 8257 },
        unverified = true,
        chainOnly = true,
    },
    [8257] = {
        min = 50,
        start = {
            kind = "npc",
            id = 8405,
            name = {
                enUS = "Ogtinc",
            },
            map = 1447,
            x = 42.4,
            y = 42.6,
        },
        before = { 8256 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8410] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Beram Skychaser",
            },
        },
        after = { 8412 },
        unverified = true,
        chainOnly = true,
    },
    [8412] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Bath'rah the Windwatcher",
            },
        },
        before = { 8410 },
        after = { 8413 },
        unverified = true,
        chainOnly = true,
    },
    [8413] = {
        min = 50,
        faction = "H",
        start = {
            kind = "npc",
            id = 6176,
            name = {
                enUS = "Bath'rah the Windwatcher",
            },
            map = 1416,
            x = 80,
            y = 62.4,
        },
        before = { 8412 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8414] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Commander Ashlam Valorfist",
            },
        },
        before = { 8415 },
        after = { 8416 },
        unverified = true,
        chainOnly = true,
    },
    [8415] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Lord Grayson Shadowbreaker",
            },
        },
        after = { 8414 },
        unverified = true,
        chainOnly = true,
    },
    [8416] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "High Priest Thel'danis",
            },
        },
        before = { 8414 },
        after = { 8418 },
        unverified = true,
        chainOnly = true,
    },
    [8417] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Torm Ragetotem / Sorek / Christoph Walker / Kelv Sternhammer / Wu Shen / Darnath Bladesinger",
            },
        },
        after = { 8423 },
        unverified = true,
        chainOnly = true,
    },
    [8418] = {
        min = 50,
        start = {
            kind = "npc",
            id = 10838,
            name = {
                enUS = "Ashlam Valorfist",
            },
            map = 1422,
            x = 42.8,
            y = 84,
        },
        before = { 8416 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8419] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Demisette Cloyce / Kartosh / Grol'dar / Mirkat / Zevrist / Kaal Soulreaper / Luther Pickman / Richard Kerwin / Thistleheart / Alexander Calder / Ursula Deline / Sandahl",
            },
        },
        after = { 8421 },
        unverified = true,
        chainOnly = true,
    },
    [8421] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Impsy",
            },
        },
        before = { 8419 },
        after = { 8422 },
        unverified = true,
        chainOnly = true,
    },
    [8422] = {
        min = 50,
        start = {
            kind = "npc",
            id = 14470,
            name = {
                enUS = "Impsy",
            },
            map = 1448,
            x = 41.4,
            y = 44.8,
        },
        before = { 8421 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8423] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Fallen Hero of the Horde",
            },
        },
        before = { 8417 },
        after = { 8424 },
        unverified = true,
        chainOnly = true,
    },
    [8424] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Fallen Hero of the Horde",
            },
        },
        before = { 8423 },
        after = { 8425 },
        unverified = true,
        chainOnly = true,
    },
    [8425] = {
        min = 50,
        start = {
            kind = "npc",
            id = 7572,
            name = {
                enUS = "Fallen Hero of the Horde",
            },
            map = 1435,
            x = 34.2,
            y = 65.4,
        },
        before = { 8424 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [8921] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Mux Manascrambler",
            },
        },
        before = { 8922 },
        after = { 8924 },
        unverified = true,
        chainOnly = true,
    },
    [8922] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Deliana",
            },
        },
        after = { 8921 },
        unverified = true,
        chainOnly = true,
    },
    [8924] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Mux Manascrambler",
            },
        },
        before = { 8921 },
        after = { 8925 },
        unverified = true,
        chainOnly = true,
    },
    [8925] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Mux Manascrambler",
            },
        },
        before = { 8924 },
        after = { 8928 },
        unverified = true,
        chainOnly = true,
    },
    [8926] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Deliana",
            },
        },
        before = { 8977 },
        after = { 8929 },
        unverified = true,
        chainOnly = true,
    },
    [8928] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Mux Manascrambler",
            },
        },
        before = { 8925 },
        after = { 8977 },
        unverified = true,
        chainOnly = true,
    },
    [8929] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Deliana",
            },
        },
        before = { 8926 },
        after = { 8945 },
        unverified = true,
        chainOnly = true,
    },
    [8945] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16016,
            name = {
                enUS = "Ysida Harmon",
            },
            map = 1415,
            x = 55,
            y = 17.4,
        },
        before = { 8929 },
        after = { 8946 },
        rewards = {
            xp = 8300,
            referenceItems = {
                {
                    id = 22137,
                },
            },
        },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [8946] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Ysida Harmon",
            },
        },
        before = { 8945 },
        after = { 8947 },
        unverified = true,
        chainOnly = true,
    },
    [8947] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Anthion Harmon",
            },
        },
        before = { 8946 },
        after = { 8948 },
        unverified = true,
        chainOnly = true,
    },
    [8948] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16016,
            name = {
                enUS = "Anthion Harmon",
            },
            map = 1415,
            x = 55,
            y = 17.4,
        },
        before = { 8947 },
        after = { 8949 },
        rewards = {
            xp = 6600,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [8949] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16032,
            name = {
                enUS = "Falrin Treeshaper",
            },
            map = 2557,
            x = 28.9,
            y = 68,
        },
        inside = true,
        before = { 8948 },
        after = { 8950 },
        rewards = {
            xp = 6600,
            referenceItems = {
                {
                    id = 22150,
                },
                {
                    id = 22149,
                },
            },
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [8950] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16032,
            name = {
                enUS = "Falrin Treeshaper",
            },
            map = 2557,
            x = 28.9,
            y = 68,
        },
        inside = true,
        before = { 8949 },
        after = { 9015 },
        rewards = {
            xp = 6600,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [8951] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Anthion Harmon",
            },
        },
        before = { 9015 },
        after = { 8960 },
        unverified = true,
        chainOnly = true,
    },
    [8960] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Deliana",
            },
        },
        before = { 8951 },
        after = { 8961 },
        unverified = true,
        chainOnly = true,
    },
    [8961] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8960 },
        after = { 8962, 8963, 8964, 8965 },
        unverified = true,
        chainOnly = true,
    },
    [8962] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8961 },
        after = { 8966 },
        unverified = true,
        chainOnly = true,
    },
    [8963] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8961 },
        after = { 8967 },
        unverified = true,
        chainOnly = true,
    },
    [8964] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8961 },
        after = { 8968 },
        unverified = true,
        chainOnly = true,
    },
    [8965] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8961 },
        after = { 8969 },
        unverified = true,
        chainOnly = true,
    },
    [8966] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8962 },
        after = { 8970 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [8967] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8963 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [8968] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8964 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [8969] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8965 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "scholomance" },
    },
    [8970] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8966 },
        after = { 8985, 8986, 8987, 8988 },
        unverified = true,
        chainOnly = true,
    },
    [8977] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Mux Manascrambler",
            },
        },
        before = { 8928 },
        after = { 8926 },
        unverified = true,
        chainOnly = true,
    },
    [8985] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8970 },
        after = { 8990 },
        unverified = true,
        chainOnly = true,
    },
    [8986] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8970 },
        after = { 8989 },
        unverified = true,
        chainOnly = true,
    },
    [8987] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8970 },
        after = { 8991 },
        unverified = true,
        chainOnly = true,
    },
    [8988] = {
        level = 58,
        start = {
            kind = "npc",
            name = {
                enUS = "Bodley",
            },
        },
        before = { 8970 },
        after = { 8992 },
        unverified = true,
        chainOnly = true,
    },
    [8989] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8986 },
        after = { 8994 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [8990] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8985 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "dire-maul" },
        sectionSlugs = { "west" },
    },
    [8991] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8987 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [8992] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8988 },
        rewards = {
            xp = 8300,
        },
        unverified = true,
        instances = { "scholomance" },
    },
    [8994] = {
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8989 },
        after = { 8995 },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [8995] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16033,
            name = {
                enUS = "Bodley",
            },
            map = 51,
            x = 39.9,
            y = 96.5,
        },
        before = { 8994 },
        rewards = {
            xp = 9950,
        },
        unverified = true,
        instances = { "blackrock-spire" },
        sectionSlugs = { "upper" },
    },
    [9015] = {
        level = 60,
        min = 58,
        start = {
            kind = "npc",
            id = 16032,
            name = {
                enUS = "Falrin Treeshaper",
            },
            map = 2557,
            x = 28.9,
            y = 68,
        },
        before = { 8950 },
        after = { 8951 },
        rewards = {
            xp = 6600,
        },
        unverified = true,
        instances = { "blackrock-depths" },
    },
    [9051] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Torwa Pathfinder",
            },
        },
        before = { 9052 },
        after = { 9053 },
        unverified = true,
        chainOnly = true,
    },
    [9052] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Torwa Pathfinder",
            },
        },
        before = { 9063 },
        after = { 9051 },
        unverified = true,
        chainOnly = true,
    },
    [9053] = {
        min = 50,
        start = {
            kind = "npc",
            id = 9619,
            name = {
                enUS = "Torwa Pathfinder",
            },
            map = 1449,
            x = 71.4,
            y = 76,
        },
        before = { 9051 },
        unverified = true,
        instances = { "temple-of-atalhakkar" },
    },
    [9063] = {
        level = 50,
        start = {
            kind = "npc",
            name = {
                enUS = "Turak Runetotem / Sheal Runetotem / Mathrengyl Bearwalker / Denatharion / Sheldras Moontree / Theridran / Jannos Lighthoof / Golhine the Hooded / Loganaar",
            },
        },
        after = { 9052 },
        unverified = true,
        chainOnly = true,
    },
    [9251] = {
        level = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Anachronos",
            },
        },
        before = { 9250 },
        after = { 9257 },
        unverified = true,
        chainOnly = true,
    },
    [9257] = {
        min = 60,
        start = {
            kind = "npc",
            name = {
                enUS = "Anachronos",
            },
        },
        before = { 9251 },
        unverified = true,
        instances = { "stratholme" },
        sectionSlugs = { "service-gate" },
    },
    [79987] = {
        level = 40,
        after = { 80131 },
        unverified = true,
        chainOnly = true,
    },
    [80131] = {
        level = 40,
        start = {
            kind = "npc",
            name = {
                enUS = "Talvash del Kissel",
            },
        },
        before = { 79987 },
        unverified = true,
        chainOnly = true,
    },
    [92742] = {
        name = {
            enUS = "Testing the Wells",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Alba Fairmoon",
            },
            map = 1436,
            x = 53,
            y = 53.3,
        },
        after = { 92753, 92744 },
        rewards = {
            xp = 460,
            money = 250,
        },
        unverified = true,
        chainOnly = true,
    },
    [92744] = {
        name = {
            enUS = "Murloc Gills",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Alba Fairmoon",
            },
        },
        before = { 92742 },
        after = { 92753, 92745 },
        rewards = {
            xp = 460,
            money = 250,
        },
        unverified = true,
        chainOnly = true,
    },
    [92745] = {
        name = {
            enUS = "The State of the Mines",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Alba Fairmoon",
            },
        },
        before = { 92744 },
        after = { 92753, 92747 },
        rewards = {
            xp = 490,
            money = 300,
        },
        unverified = true,
        chainOnly = true,
    },
    [92747] = {
        name = {
            enUS = "Moonbrook Espionage",
        },
        level = 16,
        min = 9,
        faction = "A",
        start = {
            kind = "npc",
            id = 253092,
            name = {
                enUS = "Alba Fairmoon",
            },
            map = 1436,
            x = 52.4,
            y = 53,
        },
        before = { 92745 },
        after = { 92753, 92748 },
        rewards = {
            xp = 580,
            money = 400,
        },
        unverified = true,
        instances = { "deadmines" },
    },
    [92748] = {
        name = {
            enUS = "Explosive Consultation",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Alba Fairmoon",
            },
        },
        before = { 92747 },
        after = { 92753, 92749 },
        unverified = true,
        chainOnly = true,
    },
    [92749] = {
        name = {
            enUS = "A Dynamite Plan",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Sprite Jumpsprocket",
            },
        },
        before = { 92748 },
        after = { 92753, 92750 },
        rewards = {
            xp = 580,
            money = 400,
        },
        unverified = true,
        chainOnly = true,
    },
    [92750] = {
        name = {
            enUS = "Detonation at a Distance",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Sprite Jumpsprocket",
            },
        },
        before = { 92749 },
        after = { 92753, 92751 },
        unverified = true,
        chainOnly = true,
    },
    [92751] = {
        name = {
            enUS = "Detonation at a Distance",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Jasper Fel",
            },
        },
        before = { 92750 },
        after = { 92753, 92752 },
        unverified = true,
        chainOnly = true,
    },
    [92752] = {
        name = {
            enUS = "Explosive Consultation",
        },
        level = 9,
        min = 9,
        start = {
            kind = "npc",
            name = {
                enUS = "Sprite Jumpsprocket",
            },
        },
        before = { 92751 },
        after = { 92753 },
        rewards = {
            xp = 580,
            money = 400,
        },
        unverified = true,
        chainOnly = true,
    },
    [92819] = {
        name = {
            enUS = "Destruction in Deadmines",
        },
        level = 18,
        min = 9,
        faction = "A",
        start = {
            kind = "npc",
            id = 253279,
            name = {
                enUS = "Alba Fairmoon",
            },
            map = 1436,
            x = 38.6,
            y = 83.2,
        },
        rewards = {
            xp = 680,
        },
        unverified = true,
        instances = { "deadmines" },
    },
    [95161] = {
        level = 15,
        start = {
            kind = "npc",
            name = {
                enUS = "Orphan Matron Nightingale",
            },
        },
        unverified = true,
        chainOnly = true,
    },
    [97289] = {
        level = 16,
        start = {
            kind = "npc",
            name = {
                enUS = "Master Apothecary Faranell",
            },
        },
        before = { 97288 },
        after = { 97290 },
        unverified = true,
        chainOnly = true,
    },
    [97290] = {
        level = 16,
        start = {
            kind = "npc",
            name = {
                enUS = "Unfinished Abomination",
            },
        },
        before = { 97289 },
        after = { 97291 },
        unverified = true,
        chainOnly = true,
    },
    [97291] = {
        level = 16,
        start = {
            kind = "npc",
            name = {
                enUS = "Master Apothecary Faranell",
            },
        },
        before = { 97290 },
        after = { 97292 },
        unverified = true,
        chainOnly = true,
    },
    [97292] = {
        level = 16,
        start = {
            kind = "npc",
            name = {
                enUS = "Master Apothecary Faranell",
            },
        },
        before = { 97291 },
        after = { 97288 },
        unverified = true,
        chainOnly = true,
    },
}
