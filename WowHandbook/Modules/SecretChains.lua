local ADDON_NAME, ns = ...

-- 解谜助手的长任务链定义（手工维护的“步骤脚本”，不是 tools/ 生成的数据表）。
-- 内容与 wowhandbook.com 上这两条线的攻略一致；任务与物品 ID 按客户端 1.60.1 数据核对。
--
-- 每条链：id、title（本地化键）、site（网站攻略 slug，复制链接用）、minLevel、reward（奖励物品 ID）、
--   groups（阶段：id、title、parallel = 阶段内各步可按任意顺序做）、steps、ending（全部完成后的说明）。
-- 每一步：
--   id、group、title（本地化键；有 quest 时标题用客户端的任务名）、optional（可选，不挡下一步）
--   quest      任务 ID，或 { A = 联盟, H = 部落 }：完成即这一步完成，在任务日志里为“进行中”
--   items      { { 物品 ID, 数量 } }：背包或银行里有其一即完成
--   equipped   物品 ID：装备着即完成
--   doneQuests { 任务 ID }：其一已完成即这一步完成（换了别的方式拿到也算）
--   after      { 步骤 id }：其一完成即这一步也算完成（物品被后面的步骤用掉、合成了）
--   manual     客户端看不出完成与否：由玩家在小窗里勾选
--   needs      { { item = ID } 或 { equipped = ID } }：做这一步要带的东西；缺了在小窗里标红提醒
--   todo       还没开始时的提示（本地化键，或 { A = 键, H = 键 } 按阵营）
--   active     任务在日志里时的提示（同上）
--   status     function(ctx) 返回本地化键：按玩家当前物品与任务细分的提示，优先于 todo / active
--   spots      { { uiMapID, x, y, 标签键[, 阵营] } }：可在地图上标记的地点（坐标 0–100）
ns.SecretChains = {
    {
        id = "sleepingBag",
        title = "Cozy Sleeping Bag",
        site = "cozy-sleeping-bag-in-wow-forever",
        minLevel = 14,
        reward = 211527,
        groups = {
            { id = "trail", title = "The trail of notes" },
        },
        steps = {
            {
                id = "note", group = "trail", title = "...and that note you found", quest = { A = 79008, H = 79007 },
                todo = {
                    A = "Click the Burned-Out Remains in the wagon wreck at Alexston Farm, Westfall.",
                    H = "Click the Burned-Out Remains at the burned tower south of Camp Taurajo, the Barrens.",
                },
                active = {
                    A = "Sail to the Barrens and click the second Burned-Out Remains south of Camp Taurajo.",
                    H = "Fly to Westfall and click the second Burned-Out Remains at Alexston Farm.",
                },
                spots = {
                    { 1436, 37.5, 50.7, "Burned-Out Remains" },
                    { 1413, 46.4, 73.9, "Burned-Out Remains" },
                },
            },
            {
                id = "stepping", group = "trail", title = "Stepping Stones", quest = 79192,
                todo = "Click the note pinned to the board beside the second Burned-Out Remains.",
                active = "In Stonetalon Mountains, take the trail north-east of Sun Rock Retreat west to an abandoned camp and click the Pocket Litter on the crate.",
                spots = {
                    { 1442, 50.9, 52.3, "Trail entrance" },
                    { 1442, 40.8, 52.5, "Pocket Litter" },
                },
            },
            {
                id = "rekindle", group = "trail", title = "Rekindle (optional)", manual = true, optional = true,
                todo = "Light the fire pit in the middle of the same camp with Simple Wood and Flint and Tinder. Skipping it changes nothing.",
                spots = { { 1442, 40.6, 52.4, "Fire pit" } },
            },
            {
                id = "scramble", group = "trail", title = "Scramble", quest = 79980,
                todo = "The next note in the camp starts this step.",
                active = "Walk a hundred paces due north of the camp, climb to the cliff edge and jump across to the Mound of Dirt.",
                spots = { { 1442, 39.6, 49.9, "Mound of Dirt" } },
            },
            {
                id = "wetJob", group = "trail", title = "Wet Job", quest = 79974,
                todo = "Finishing the last step gives you this one.",
                active = "At Stonewrought Dam in northern Loch Modan, drop onto the giant dwarf head on the Wetlands side and edge across to the Carved Figurine.",
                spots = { { 1432, 49.5, 12.8, "Carved Figurine" } },
            },
            {
                id = "eaglesFist", group = "trail", title = "Eagle's Fist", quest = 79975,
                todo = "Finishing the last step gives you this one.",
                active = "From the cart below Thoradin's Wall on the Hillsbrad side, climb into the wall, cross the inner chamber and click the Messenger Bag on the outer wall.",
                spots = {
                    { 1424, 87.3, 49.6, "Cart below the wall" },
                    { 1417, 22.5, 24.2, "Messenger Bag" },
                },
            },
            {
                id = "thisMustBe", group = "trail", title = "This Must Be the Place", quest = 79976,
                todo = "Clicking the Messenger Bag gives you this one.",
                active = "Click the Hastily Rolled-Up Satchel right below the Messenger Bag.",
                spots = { { 1417, 22.5, 24.2, "Hastily Rolled-Up Satchel" } },
            },
        },
        ending = "Done! Rest on the Cozy Sleeping Bag for 3 minutes before a long trip: up to 3% more experience for 2 hours.",
    },
    {
        id = "dawnWaker",
        title = "Dawn Waker",
        site = "dawn-waker-secret",
        groups = {
            { id = "prep", title = "Ring and torch", parallel = true },
            { id = "zephras", title = "The sword on Zephras Isle" },
            { id = "globe", title = "A tainted water globe" },
            { id = "spirit", title = "The Highborne trail" },
            { id = "reagents", title = "Three reagents", parallel = true },
            { id = "cleanse", title = "Cleansing and the prince" },
        },
        steps = {
            {
                id = "ring", group = "prep", title = "Get the Ancient Heirloom ring",
                items = { { 264908, 1 } }, equipped = 264908, doneQuests = { 92460 },
                todo = "Skyborne: turn in Coming of Age in Thendal Village. Every other race: climb to the top floor of the building at the marker in Thendal Village and loot the ring.",
                status = function(ctx)
                    if ctx.has(264908) and not ctx.equipped(264908) then
                        return "Equip the ring and keep it on: the hidden spirit, vault and switches only show while you wear it."
                    end
                end,
                spots = {
                    { 2521, 41.7, 23.4, "Ancient Heirloom (rooftop)" },
                    { 2521, 42.8, 23.4, "Ailee Farheart (Skyborne)" },
                    { 1416, 12.5, 51.8, "Skyboat from Dalaran", "A" },
                    { 1412, 34.3, 25.8, "Skyboat from Mulgore", "H" },
                },
            },
            {
                id = "torch", group = "prep", title = "Get the Night Watchman's Torch",
                items = { { 280612, 1 } }, doneQuests = { 98372 },
                todo = "A fallen Night Watch Guard lies by one of Duskwood's roads. Click him, accept An Unfortunate End and turn it in on the spot. He moves between these spots.",
                spots = {
                    { 1431, 17.0, 54.9, "Raven Hill" },
                    { 1431, 23.6, 33.4, "North of Raven Hill" },
                    { 1431, 28.7, 33.3, "Raven Hill Cemetery" },
                    { 1431, 22.0, 73.0, "Addle's Stead" },
                    { 1431, 30.1, 67.3, "East of Addle's Stead" },
                    { 1431, 47.6, 59.4, "Twilight Grove road" },
                    { 1431, 45.5, 79.2, "Southern road" },
                    { 1431, 66.1, 34.0, "Brightwood Grove" },
                    { 1431, 68.8, 69.4, "South-west of Darkshire" },
                },
            },
            {
                id = "hilt", group = "zephras", title = "Reveal the Ancient Hilt",
                items = { { 272313, 1 } }, after = { "blade" }, needs = { { item = 280612 } },
                todo = "At the Ruins of Ban'aethal on Zephras Isle, wait for Altairus to settle, light the torch on the marker and loot the Ancient Hilt.",
                spots = { { 2521, 58.13, 24.06, "Ancient Hilt" } },
            },
            {
                id = "blade", group = "zephras", title = "Claim Eluvi'ana", manual = true,
                needs = { { item = 272313 } },
                todo = "Show the hilt to Ealaane Nimbuswalker in Valanaar, then check the four spots for the glowing blade (skip empty ones) and bring it back. Keep the sword for good.",
                spots = {
                    { 2521, 65.94, 74.37, "Ealaane Nimbuswalker" },
                    { 2521, 48.94, 72.68, "Blade spot A" },
                    { 2521, 50.4, 44.3, "Blade spot B" },
                    { 2521, 66.25, 43.15, "Blade spot C" },
                    { 2521, 59.9, 82.2, "Blade spot D" },
                },
            },
            {
                id = "globe", group = "globe", title = "Get the Befouled Water Globe",
                items = { { 16408, 1 } }, after = { "cleanse", "prince" },
                todo = {
                    A = "In the Ruins of Mathystra, Darkshore, collect 20 Mathystra Amulet Fragments, then use the amulet at the Fathom Stone to summon Baron Marinous (level 21 elite).",
                    H = "Defeat Baron Aquanis in Blackfathom Deeps for the Strange Water Globe.",
                },
                status = function(ctx)
                    if ctx.has(279275) or ctx.onQuest(98028) then
                        return "Turn in Baron Marinous to Onu in the Grove of the Ancients, then talk to Onu again to take the globe back."
                    elseif ctx.questDone(98028) then
                        return "Talk to Onu once more: the globe is handed back in a second conversation."
                    elseif ctx.has(16782) or ctx.onQuest(6922) then
                        return "Take the Strange Water Globe to Je'neu Sancrea at Zoram'gar Outpost, then talk to him again to take it back."
                    elseif ctx.questDone(6922) then
                        return "Talk to Je'neu Sancrea once more: the globe is handed back in a second conversation."
                    end
                end,
                spots = {
                    { 1439, 58.9, 22.6, "Fathom Stone", "A" },
                    { 1439, 43.6, 76.4, "Onu", "A" },
                    { 1440, 11.6, 34.3, "Je'neu Sancrea", "H" },
                },
            },
            {
                id = "spirit", group = "spirit", title = "Find the hidden Highborne Spirit", manual = true,
                after = { "tome", "mordent" }, needs = { { equipped = 264908 }, { item = 16408 } },
                todo = "Wearing the ring and carrying the globe, talk to the Highborne Spirit at Zoram Strand and show it the globe.",
                spots = { { 1440, 15.68, 19.33, "Highborne Spirit" } },
            },
            {
                id = "tome", group = "spirit", title = "Take Narassin's Tome", manual = true, after = { "mordent" },
                todo = "Defeat Athrikus Narassin atop the Tower of Althalaxx, open the chest behind him with his key (Rogues can pick it) and bring the tome to the spirit.",
                spots = {
                    { 1439, 56.4, 26.5, "Athrikus Narassin" },
                    { 1440, 15.68, 19.33, "Highborne Spirit" },
                },
            },
            {
                id = "mordent", group = "spirit", title = "Bring the tome to Mordent Evenshade", manual = true,
                todo = "Bring Eluvi'ana and the tome to Mordent Evenshade in Shen'dralas. Talk to him before farming Winterspring.",
                spots = { { 2652, 35.05, 46.49, "Mordent Evenshade" } },
            },
            {
                id = "star", group = "reagents", title = "Star of Elune", manual = true, after = { "cleanse" },
                needs = { { equipped = 264908 } },
                todo = "Five players, each wearing the ring: four pull the switches in the Ruins of Isildien within about 15 seconds, the fifth opens the vault.",
                spots = {
                    { 1444, 58.5, 71.6, "Shen'dralar Vault" },
                    { 1444, 58.5, 71.0, "Switch 1 (upper floor)" },
                    { 1444, 57.3, 71.7, "Switch 2" },
                    { 1444, 59.7, 72.0, "Switch 3" },
                    { 1444, 61.1, 73.6, "Switch 4 (farthest)" },
                },
            },
            {
                id = "mote", group = "reagents", title = "Abyssal Mote", manual = true, after = { "cleanse" },
                todo = "Finish the demon-hunter chain from Kirith the Damned in the Blasted Lands through Azsharite, then loot the Abyssal Chest under the water off south-east Azshara.",
                status = function(ctx)
                    if ctx.questDone(3602) then
                        return "Your Loramus chain is done: dive to the Abyssal Chest and loot the mote."
                    end
                end,
                spots = { { 1447, 66.0, 54.1, "Abyssal Chest" } },
            },
            {
                id = "tears", group = "reagents", title = "Tears of Anguish x20", manual = true, after = { "cleanse" },
                todo = "Kill Anguished and Suffering Highborne around Lake Kel'Theril until you have 20 Tears of Anguish. No ring needed here.",
                spots = { { 1452, 53.6, 43.2, "Lake Kel'Theril" } },
            },
            {
                id = "cleanse", group = "cleanse", title = "Cleanse the globe at Mount Hyjal", manual = true,
                after = { "prince" }, needs = { { item = 16408 } },
                todo = "With all three reagents in your bags, use the globe at the Shrine of Coalescence, then bring the Cleansed Water Globe back to Mordent Evenshade.",
                spots = {
                    { 2482, 72.7, 37.2, "Shrine of Coalescence" },
                    { 2652, 35.05, 46.49, "Mordent Evenshade" },
                },
            },
            {
                id = "prince", group = "cleanse", title = "Speak to Prince Tortheldrin", manual = true,
                todo = "Enter Dire Maul and talk to Prince Tortheldrin. He names a second blade, Eluvi'tor.",
            },
        },
        ending = "You reached the end of the known trail. Shen'dralar reputation is the open lead for Eluvi'tor.",
    },
}
