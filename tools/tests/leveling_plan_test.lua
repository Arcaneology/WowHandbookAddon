-- 冲级路线计算的单元测试：lua tools/tests/leveling_plan_test.lua
-- 与网站 tests/leveling-plan.test.ts 是同一批用例（网站另有 breaks / forced 的用例，插件不带这两项）。
-- 2026-11-17 起回收不打流通折扣、赚钱的配方优先，中间材料计入点数，网站已同步。
local ns = {}
assert(loadfile("WowHandbook/Core/LevelingPlan.lua"))("WowHandbook", ns)
local Plan = ns.LevelingPlan

local failures = 0
local function check(name, ok)
    print((ok and "PASS " or "FAIL ") .. name)
    if not ok then failures = failures + 1 end
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

local function market(t)
    t = t or {}
    return {
        levels = function(item) return t.levels and t.levels[item] end,
        auction = function(item) return t.auction and t.auction[item] end,
        vendorBuy = function(item) return t.vendorBuy and t.vendorBuy[item] end,
        vendorSell = function(item) return t.vendorSell and t.vendorSell[item] end,
        tier = function(item) return t.tier and t.tier[item] end,
    }
end
local function build(recipes, from, to, m, options, known)
    return Plan.Build({ recipes = recipes, from = from, to = to, faction = "A", market = market(m),
        options = options or { recovery = true, buyRecipes = true }, known = known })
end

-- 涨点概率
local r = { skill = { 10, 20, 30 } }
check("chance: orange always", Plan.Chance(r, 5) == 1)
check("chance: linear after yellow", near(Plan.Chance(r, 20), 0.5))
check("chance: gray never", Plan.Chance(r, 30) == 0)

-- 阶梯价
local cost, short = Plan.LadderCost({ levels = { { 10, 5 }, { 20, 5 } } }, 0, 8)
check("ladder: climbs levels", cost == 110 and short == 0)
cost, short = Plan.LadderCost({ levels = { { 10, 5 }, { 20, 5 } } }, 5, 8)
check("ladder: skips what was bought, reports shortfall", cost == 160 and short == 3)
cost = Plan.LadderCost({ levels = { { 10, 5 }, { 50, 5 } }, vendor = 30 }, 0, 8)
check("ladder: vendor caps the price", cost == 140)
check("ladder: no price", Plan.LadderCost({}, 0, 1) == nil)

-- 回收改变选择：便宜的做出来不值钱，贵一点的能卖回本
local recipes = {
    { id = 1, skill = { 50, 60, 70 }, makes = 101, reagents = { 900, 1 }, learn = 1 }, -- 材料 100，成品卖店 10
    { id = 2, skill = { 50, 60, 70 }, makes = 102, reagents = { 901, 1 }, learn = 1 }, -- 材料 150，成品拍卖 200（高流通）
}
local m = { vendorBuy = { [900] = 100, [901] = 150 }, vendorSell = { [101] = 10, [102] = 5 },
    auction = { [102] = 200 }, tier = { [101] = "low", [102] = "high" } }
local plan = build(recipes, 1, 11, m)
check("recovery: picks the recipe that sells", #plan.steps == 1 and plan.steps[1].recipe.id == 2)
check("recovery: totals", plan.materials == 1500 and near(plan.recovery, 10 * 200 * 0.95)
    and near(plan.net, 1500 - plan.recovery))
plan = build(recipes, 1, 11, m, { recovery = false })
check("no recovery: picks the cheapest materials", plan.steps[1].recipe.id == 1 and plan.recovery == 0)

-- 流通性：选配方时装备只按卖店价（拍卖价再高也不靠它排前面）；汇总里前 2 件按拍卖价
m.tier[102] = "low"
plan = build(recipes, 1, 11, m)
check("liquidity: gear is ranked by its vendor price", #plan.steps == 1 and plan.steps[1].recipe.id == 1)
plan = build({ recipes[2] }, 1, 11, m)
check("liquidity: gear totals count only 2 at auction", near(plan.recovery, 2 * 200 * 0.95 + 8 * 5)
    and near(plan.safeRecovery, 10 * 5))
local sold
for _, product in ipairs(plan.products) do if product.item == 102 then sold = product end end
check("liquidity: product destinations", sold and sold.auction == 2 and sold.vendor == 8)
-- 同样的价格，高流通（背包、布卷）的不设上限，排在装备前面
m.tier[102] = "high"
plan = build(recipes, 1, 11, m)
check("liquidity: a high-liquidity product wins and has no cap", #plan.steps == 1 and plan.steps[1].recipe.id == 2
    and near(plan.recovery, 10 * 200 * 0.95))

-- 学习门槛与图纸
recipes = {
    { id = 1, skill = { 1, 30, 60 }, makes = 101, reagents = { 900, 1 } },
    { id = 2, skill = { 30, 40, 50 }, makes = 102, reagents = { 900, 1 }, learn = 20 },
    { id = 3, skill = { 30, 40, 50 }, makes = 103, reagents = { 900, 1 }, learnedFrom = 700, learn = 5,
        buy = { A = 30 } },
    { id = 4, skill = { 30, 40, 50 }, makes = 104, reagents = {}, nip = true },
}
m = { vendorBuy = { [900] = 100 } }
plan = build(recipes, 1, 30, m, { recovery = true, buyRecipes = false })
check("learn: trainer recipe waits for its learn skill", plan.steps[1].recipe.id == 1 and plan.steps[1].to == 20
    and plan.steps[2].recipe.id == 2)
plan = build(recipes, 1, 30, m, { recovery = true, buyRecipes = true })
check("recipe item: bought when it pays, fee counted once", plan.steps[2].recipe.id == 3 and plan.steps[2].from == 5
    and #plan.recipesToBuy == 1 and plan.recipeCost == 30)
plan = build(recipes, 1, 30, m, { recovery = true, buyRecipes = false }, function(recipe) return recipe.id == 3 end)
check("recipe item: known recipe needs no purchase", plan.steps[2].recipe.id == 3 and plan.steps[2].from < 5
    and plan.recipeCost == 0)

-- 两个配方差不多时接着做上一步的，不来回换
plan = build({
    { id = 1, skill = { 50, 60, 70 }, makes = 101, reagents = { 900, 1 }, learn = 1 },
    { id = 2, skill = { 50, 60, 70 }, makes = 102, reagents = { 901, 1 }, learn = 1 },
}, 1, 11, { vendorBuy = { [900] = 100, [901] = 100 }, auction = { [101] = 60, [102] = 60 },
    tier = { [101] = "low", [102] = "low" } })
check("sticky: near ties do not flip back and forth", #plan.steps <= 3)

-- 没有可用配方的技能段
plan = build({ { id = 1, skill = { 1, 5, 10 }, makes = 101, reagents = { 900, 1 } } }, 1, 15, m)
check("gap: blocked skill reported", plan.blocked == 10 and plan.steps[#plan.steps].gap
    and plan.steps[#plan.steps].to == 15)

-- 中间材料：路线里做出来的留着用；自己做更便宜时自己做
recipes = {
    { id = 1, skill = { 10, 15, 20 }, makes = 500, reagents = { 900, 2 }, learn = 1 },   -- 布卷
    { id = 2, skill = { 20, 25, 30 }, makes = 501, reagents = { 500, 1 }, learn = 10 },  -- 用布卷
}
m = { vendorBuy = { [900] = 10 }, auction = { [500] = 100 }, tier = { [500] = "high" } }
plan = build(recipes, 1, 19, m, { recovery = false })
check("intermediate: stock is used before buying", plan.steps[2].recipe.id == 2 and plan.steps[2].cash == 0
    and plan.materials == 9 * 20)
-- 从 15 起布卷还是绿色，为配方 2 做的每个布卷也可能涨点：技能 s 时做一次配方 2 涨 1 + (20 - s) / 10 点，
-- 所以五点只要四次整次制作、四个整布卷（审计 2026-11-18：不再有半次制作）
plan = build({ recipes[1], recipes[2] }, 15, 20, m, { recovery = false })
check("intermediate: crafted when cheaper than buying, and its crafts count for skill", #plan.prepared == 1
    and plan.prepared[1].recipe.id == 1 and plan.prepared[1].crafts == 4
    and #plan.steps == 1 and plan.steps[1].from == 15 and plan.steps[1].to == 20 and plan.steps[1].crafts == 4
    and plan.materials == 4 * 20)

-- 站长的亚麻材料包：一个包用六个橙色亚麻布卷，每个布卷都涨一点，一点只要七分之一个包
recipes = {
    { id = 2963, skill = { 25, 37, 50 }, makes = 2996, reagents = { 2589, 2 }, learn = 1 },            -- 亚麻布卷
    { id = 1257013, skill = { 30, 47, 65 }, makes = 253664, reagents = { 2996, 6, 2320, 6 }, learn = 5 }, -- 亚麻材料包
}
local bag = { auction = { [2589] = 33, [2996] = 500, [253664] = 700 }, vendorBuy = { [2320] = 10 },
    tier = { [2996] = "none", [253664] = "high" } }
plan = build(recipes, 5, 12, bag)
check("intermediate points: the bag is the pick", plan.steps[1].recipe.id == 1257013
    and near(plan.steps[1].crafts, 1) and near(plan.prepared[1].crafts, 6))
plan = build(recipes, 50, 52, bag)
-- 布卷变灰以后不涨点：只剩包的 15/35、14/35，平均 4.8 次，所以做五个整包
check("intermediate points: grey bolts give nothing", plan.steps[1].crafts == 5)

-- 审计 2026-11-18：只做整次，购物单买的东西能做出路线说的成品
for _, to in ipairs({ 6, 11 }) do
    plan = build(recipes, 5, to, bag, { recovery = true, buyRecipes = true, priority = "saving" })
    local whole, bolts, bags = true, 0, 0
    for _, step in ipairs(plan.steps) do
        whole = whole and step.crafts == math.floor(step.crafts)
        for _, entry in ipairs(step.prepared) do
            whole = whole and entry[2] == math.floor(entry[2])
            bolts = bolts + entry[2]
        end
        if step.recipe and step.recipe.id == 2963 then bolts = bolts + step.crafts end
        if step.recipe and step.recipe.id == 1257013 then bags = bags + step.crafts end
    end
    local bought = {}
    for _, line in ipairs(plan.shopping) do bought[line.item] = line.count end
    check("whole crafts: 5 to " .. to .. " buys what it makes", whole and (bought[2589] or 0) >= bolts * 2
        and bolts >= bags * 6 and (bought[2320] or 0) >= bags * 6)
end

-- 审计 2026-11-18：一批布卷做到一半变黄，后面几个少算点数（不按起点全算一点）
plan = Plan.Build({ recipes = {
        { id = 1, skill = { 8, 15, 20 }, makes = 500, reagents = { 900, 1 }, learn = 1 },
        { id = 2, skill = { 30, 40, 50 }, makes = 501, reagents = { 500, 6 }, learn = 1 },
    }, from = 5, to = 12, faction = "A", options = { recovery = false },
    market = market({ vendorBuy = { [900] = 1 }, auction = { [500] = 1000 }, tier = { [500] = "none", [501] = "none" } }) })
local boltCount = 0
for _, entry in ipairs(plan.steps[1].prepared) do boltCount = boltCount + entry[2] end
-- 每个布卷都按一点算的话，一个包（六个布卷加包本身）就是七点，正好 5 到 12；变黄以后少算，要做第二个包
check("intermediate points: a batch that turns yellow counts less", plan.steps[1].recipe.id == 2
    and #plan.steps == 1 and plan.steps[1].to == 12 and plan.steps[1].crafts == 2 and boltCount == 12)

-- 附魔代工
recipes = {
    { id = 1, skill = { 20, 30, 40 }, reagents = { 900, 1 }, learn = 1 },
    { id = 2, skill = { 20, 30, 50 }, reagents = { 900, 5 }, learn = 1 },
}
plan = build(recipes, 1, 10, m, { recovery = true, commission = false })
check("commission off: enchants cost materials", plan.materials == 9 * 10 and not plan.steps[1].commission)
plan = build(recipes, 1, 10, m, { recovery = true, commission = true })
check("commission on: free, with alternatives", plan.materials == 0 and plan.steps[1].commission
    and #plan.steps[1].alternatives == 1)

-- 拍卖行在售不够
plan = build({ { id = 1, skill = { 20, 30, 40 }, makes = 101, reagents = { 900, 1 }, learn = 1 } }, 1, 11,
    { levels = { [900] = { { 10, 4 } } } }, { recovery = false })
check("shortfall: reported on the shopping list", plan.shopping[1].short == 6 and plan.shopping[1].count == 10)

-- 能赚钱的配方排在要花钱的前面，几个都赚钱时选每个技能点赚得多的；变灰前一直做
plan = build({
    { id = 1, skill = { 1, 1, 40 }, makes = 101, reagents = { 900, 1 }, learn = 1 },  -- 每次赚 85
    { id = 2, skill = { 1, 1, 40 }, makes = 102, reagents = { 900, 1 }, learn = 1 },  -- 每次赚 5
    { id = 3, skill = { 1, 40, 50 }, makes = 103, reagents = { 901, 1 }, learn = 1 }, -- 必涨，但要花钱
}, 1, 20, { vendorBuy = { [900] = 10, [901] = 10 }, auction = { [101] = 100, [102] = 16 },
    tier = { [101] = "high", [102] = "high" } })
check("profit: the craft that earns most per point is made the whole way", #plan.steps == 1
    and plan.steps[1].recipe.id == 1 and plan.steps[1].from == 1 and plan.steps[1].to == 20 and plan.net < 0)

-- 用户的例子：裁缝 133 点，红色毛纺包（5 毛布卷、1 红色染料、1 细线）卖 20 银。毛布卷用 3 毛料自己做（毛料 1 银），
-- 染料与细线向商人买（45 铜、90 铜），每次材料 16 银 35 铜，扣手续费回收 19 银：比任何要花钱的配方都优先
plan = build({
    { id = 2964, skill = { 70, 77, 85 }, makes = 2997, reagents = { 2592, 3 }, learn = 55 },
    { id = 6688, skill = { 115, 132, 150 }, makes = 5763, reagents = { 2997, 5, 2604, 1, 2321, 1 }, learn = 90 },
    { id = 9000, skill = { 125, 140, 160 }, makes = 9001, reagents = { 2592, 2 }, learn = 90 }, -- 必涨，卖店 1 银
}, 133, 135, { auction = { [2592] = 100, [2997] = 356, [2604] = 199, [2321] = 100, [5763] = 2000 },
    vendorBuy = { [2604] = 45, [2321] = 90 }, vendorSell = { [9001] = 100 },
    tier = { [2997] = "high", [5763] = "mid", [9001] = "low" } }, nil, function() return true end)
check("profit: red woolen bag at 133 beats a cheap orange recipe", plan.steps[1].recipe.id == 6688
    and plan.prepared[1] and plan.prepared[1].recipe.id == 2964)
local bagCost = 0
for _, entry in ipairs(plan.shopping) do bagCost = bagCost + entry.cost end
local bags = plan.steps[1].crafts
check("profit: bag materials cost 16s35c each", near(bagCost / bags, 1635))

-- 取向：技能点高时，省钱优先选赚钱但要做好几次的（红色毛纺包），均衡与效率优先选必涨的（小丝绸包）
local bagRecipes = {
    { id = 6688, skill = { 115, 132, 150 }, makes = 5763, reagents = { 900, 1 }, learn = 90 },  -- 每次赚 250，涨点约 31%
    { id = 3813, skill = { 145, 160, 175 }, makes = 4245, reagents = { 901, 1 }, learn = 125 }, -- 必涨，每次亏 1000
}
local bagMarket = { vendorBuy = { [900] = 1650, [901] = 2950 }, auction = { [5763] = 2000, [4245] = 2000 },
    tier = { [5763] = "high", [4245] = "high" } }
local picks = {}
for _, priority in ipairs({ "saving", "balanced", "speed" }) do
    plan = build(bagRecipes, 139, 140, bagMarket, { recovery = true, priority = priority })
    picks[priority] = plan.steps[1].recipe.id
end
check("priority: cheapest makes the profitable bag", picks.saving == 6688)
check("priority: balanced and fastest take the sure point", picks.balanced == 3813 and picks.speed == 3813)
check("priority: no priority means cheapest", build(bagRecipes, 139, 140, bagMarket).steps[1].recipe.id == 6688)
check("priority: time cost grows with skill", Plan.TimeCost("balanced", 150) == 2 * Plan.TimeCost("balanced", 75)
    and Plan.TimeCost("saving", 300) == 0)

-- 卖出价比买入价低、拍卖行一天只吃得下几件
local capped = market({ vendorBuy = { [900] = 100 }, vendorSell = { [101] = 5 }, auction = { [101] = 300 },
    tier = { [101] = "high" } })
capped.sale = function() return 200 end
capped.cap = function() return 4 end
plan = Plan.Build({ recipes = { { id = 1, skill = { 50, 60, 70 }, makes = 101, reagents = { 900, 1 }, learn = 1 } },
    from = 1, to = 11, faction = "A", options = { recovery = true }, market = capped })
check("sale cap: a lower sale price and a daily cap limit recovery",
    near(plan.recovery, 4 * 200 * 0.95 + 6 * 5) and plan.products[1].auction == 4)

-- 绑定的成品只能卖店
plan = build({ { id = 1, skill = { 50, 60, 70 }, makes = 101, reagents = { 900, 1 }, learn = 1 } }, 1, 11,
    { vendorBuy = { [900] = 100 }, vendorSell = { [101] = 7 }, auction = { [101] = 300 }, tier = { [101] = "none" } })
check("soulbound: a bound product goes to a vendor", plan.recovery == 10 * 7 and plan.products[1].auction == 0
    and plan.products[1].vendor == 10)

-- 有冷却的配方不用
plan = build({
    { id = 1, skill = { 1, 30, 60 }, makes = 101, reagents = {}, cooldown = 3600 },
    { id = 2, skill = { 1, 30, 60 }, makes = 102, reagents = { 900, 1 } },
}, 1, 5, { vendorBuy = { [900] = 10 } })
check("cooldown: a recipe on a cooldown is never used", #plan.steps == 1 and plan.steps[1].recipe.id == 2)

-- 只算选中的附魔
recipes = {
    { id = 1, skill = { 20, 30, 40 }, reagents = { 900, 1 }, learn = 1 },
    { id = 2, skill = { 20, 30, 50 }, reagents = { 900, 5 }, learn = 1 },
}
plan = build(recipes, 1, 10, { vendorBuy = { [900] = 10 } }, { recovery = true, commission = { 2 } })
check("commission: limited to chosen enchants", plan.steps[1].recipe.id == 2 and plan.steps[1].commission
    and #plan.steps[1].alternatives == 0 and plan.materials == 0)

-- 变绿以后不再按代工算
plan = build({ { id = 1, skill = { 10, 20, 30 }, reagents = { 900, 1 }, learn = 1 } }, 1, 25,
    { vendorBuy = { [900] = 10 } }, { recovery = true, commission = { 1 } })
check("commission: stops counting once the enchant turns green", #plan.steps == 2
    and plan.steps[1].from == 1 and plan.steps[1].to == 20 and plan.steps[1].commission
    and plan.steps[2].from == 20 and plan.steps[2].to == 25 and not plan.steps[2].commission and plan.materials > 0)

-- 每一步列出买了什么、用了前面做的什么
recipes = {
    { id = 1, skill = { 10, 15, 20 }, makes = 500, reagents = { 900, 2 }, learn = 1 },
    { id = 2, skill = { 20, 25, 30 }, makes = 501, reagents = { 500, 1 }, learn = 10 },
}
plan = build(recipes, 1, 19, { vendorBuy = { [900] = 10 } }, { recovery = false })
check("steps: each lists what it buys and what it uses", plan.steps[1].bought[1][1] == 900
    and plan.steps[1].bought[1][2] == 18 and plan.steps[1].bought[1][3] == 180
    and plan.steps[2].used[1][1] == 500 and plan.steps[2].used[1][2] == 9 and #plan.steps[2].bought == 0
    and plan.shopping[1].vendor == true)

-- 工具：先做一件留着用；好的工具能顶替差的；背包里已有就不用做
recipes = {
    { id = 1, skill = { 1, 5, 10 }, makes = 201, reagents = { 900, 3 }, learn = 1 },                 -- 铜棒
    { id = 2, skill = { 20, 30, 40 }, reagents = { 901, 1 }, learn = 1, tools = { { 201, 202 } } },
    { id = 3, skill = { 1, 30, 40 }, reagents = { 901, 9 }, learn = 1 },                               -- 贵，不要工具
    { id = 4, skill = { 20, 30, 40 }, reagents = { 901, 1 }, learn = 6, tools = { { 202 } } },       -- 要更好的棒，没处买
}
m = { vendorBuy = { [900] = 10, [901] = 10 }, vendorSell = { [201] = 5 } }
plan = build(recipes, 1, 8, m, { recovery = true })
-- 铜棒在 1 点是橙色：做它就是第一点，附魔从 2 开始（审计 2026-11-18）
check("tools: crafted once first, kept, never sold, and its point counts", #plan.steps == 2
    and plan.steps[1].recipe.id == 1 and plan.steps[1].from == 1 and plan.steps[1].to == 2 and plan.steps[1].stock
    and plan.steps[2].recipe.id == 2 and plan.steps[2].from == 2 and plan.steps[2].to == 8
    and plan.recovery == 0 and plan.materials == 30 + 6 * 10)
-- 变灰以后才做的工具不涨点
plan = Plan.Build({ recipes = {
        { id = 1, skill = { 1, 5, 10 }, makes = 201, reagents = { 900, 3 }, learn = 1 },
        { id = 2, skill = { 12, 30, 40 }, reagents = { 901, 1 }, learn = 12, tools = { { 201 } } },
    }, from = 12, to = 16, faction = "A", options = { recovery = true }, market = market(m) })
check("tools: a grey tool gives no point", #plan.steps == 2 and plan.steps[1].to == 12
    and plan.steps[2].from == 12 and plan.steps[2].to == 16)
plan = Plan.Build({ recipes = recipes, from = 1, to = 8, faction = "A", market = market(m),
    options = { recovery = true }, hasTool = function(item) return item == 202 end })
check("tools: one already in the bag is not made again", #plan.steps == 1 and plan.steps[1].recipe.id == 2
    and plan.materials == 7 * 10)

-- 手册路线：照给定的顺序计价；前面的成品给后面用，绑定的成品卖店；玩家技能在一步中间时次数按比例折算
recipes = {
    { id = 1, skill = { 1, 30, 60 }, makes = 101, reagents = { 900, 2 }, learn = 1 },           -- 布卷
    { id = 2, skill = { 10, 30, 60 }, makes = 102, reagents = { 101, 1, 901, 1 }, learn = 1 },  -- 用布卷做的绑定衬衣
}
plan = Plan.Build({ recipes = recipes, from = 5, to = 20, faction = "A", options = { recovery = true },
    market = market({ vendorBuy = { [900] = 10, [901] = 5 }, vendorSell = { [102] = 7 } }),
    fixed = { { recipe = 1, from = 1, to = 11, crafts = 10 }, { recipe = 2, from = 11, to = 21, crafts = 10 } } })
check("fixed: priced as written, cut to the skill range", #plan.steps == 2
    and plan.steps[1].recipe.id == 1 and plan.steps[1].from == 5 and plan.steps[1].to == 11
    and near(plan.steps[1].crafts, 6)
    and plan.steps[2].recipe.id == 2 and plan.steps[2].from == 11 and plan.steps[2].to == 20
    and near(plan.steps[2].crafts, 9))
check("fixed: earlier products feed later steps, a bound product goes to a vendor",
    plan.steps[2].used[1][1] == 101 and near(plan.steps[2].used[1][2], 6)
    and near(plan.materials, 6 * 20 + 3 * 20 + 9 * 5) and near(plan.recovery, 9 * 7))

-- 手册路线上勾选的附魔不花钱
recipes = { { id = 1, skill = { 1, 5, 10 }, reagents = { 900, 1 }, learn = 1 } }
local fixed = { { recipe = 1, from = 1, to = 9, crafts = 20 } }
plan = Plan.Build({ recipes = recipes, from = 1, to = 9, faction = "A", market = market({ vendorBuy = { [900] = 10 } }),
    fixed = fixed })
local freePlan = Plan.Build({ recipes = recipes, from = 1, to = 9, faction = "A",
    market = market({ vendorBuy = { [900] = 10 } }), fixed = fixed, options = { commission = { 1 } } })
check("fixed: a chosen enchant costs nothing", plan.materials == 200 and freePlan.materials == 0
    and freePlan.steps[1].commission)

-- 手册路线：备料步不涨点，技能过了就不再做；工具背包里有就跳过；材料没价格的步骤标出来
recipes = {
    { id = 1, skill = { 1, 30, 60 }, makes = 101, reagents = { 900, 1 }, learn = 1 },
    { id = 2, skill = { 1, 30, 60 }, makes = 201, reagents = { 900, 3 }, learn = 1 },                 -- 工具
    { id = 3, skill = { 1, 30, 60 }, reagents = { 901, 1 }, learn = 1, tools = { { 201 } } },
    { id = 4, skill = { 1, 30, 60 }, makes = 104, reagents = { 999, 1 }, learn = 1 },                 -- 材料没价格
}
fixed = {
    { recipe = 2, from = 1, to = 2, crafts = 1, forced = true },
    { recipe = 1, from = 2, to = 2, crafts = 5, stock = true, keepBelow = 10 },
    { recipe = 3, from = 2, to = 10, crafts = 8 },
    { recipe = 4, from = 10, to = 12, crafts = 2 },
}
m = { vendorBuy = { [900] = 10, [901] = 10 } }
plan = Plan.Build({ recipes = recipes, from = 1, to = 12, faction = "A", market = market(m), fixed = fixed,
    options = { recovery = false } })
check("fixed: tool, stock and unpriced steps", #plan.steps == 4 and plan.steps[1].forced
    and plan.steps[2].stock and plan.steps[2].from == 2 and plan.steps[2].to == 2 and plan.steps[2].crafts == 5
    and plan.steps[4].unpriced and plan.unpriced == 1 and plan.materials == 30 + 50 + 80)
plan = Plan.Build({ recipes = recipes, from = 10, to = 12, faction = "A", market = market(m), fixed = fixed,
    options = { recovery = false }, hasTool = function(item) return item == 201 end })
check("fixed: steps below the skill are dropped", #plan.steps == 1 and plan.steps[1].recipe.id == 4)
plan = Plan.Build({ recipes = recipes, from = 1, to = 12, faction = "A", market = market(m), fixed = fixed,
    options = { recovery = false }, hasTool = function(item) return item == 201 end })
check("fixed: a tool already in the bag is not made again", #plan.steps == 3 and plan.steps[1].recipe.id == 1)

-- 审计 2026-11-18：缺价是部分预算，缺价步骤做出来的东西不算卖钱
plan = Plan.Build({ recipes = {
        { id = 1, skill = { 1, 30, 60 }, makes = 101, reagents = { 900, 1 }, learn = 1 },                       -- 材料没价格
        { id = 2, skill = { 1, 30, 60 }, makes = 102, reagents = { 101, 1 }, learn = 1 },
        { id = 3, skill = { 1, 30, 60 }, makes = 103, reagents = { 901, 1 }, learn = 1, learnedFrom = 5003 },  -- 图纸没价格
    }, from = 1, to = 4, faction = "A", options = { recovery = true, buyRecipes = true },
    market = market({ vendorBuy = { [901] = 10 }, auction = { [101] = 500, [102] = 1000 }, tier = { [101] = "high", [102] = "high" } }),
    fixed = { { recipe = 1, from = 1, to = 2, crafts = 1 }, { recipe = 2, from = 2, to = 3, crafts = 1 },
        { recipe = 3, from = 3, to = 4, crafts = 1 } } })
local soldBolt = false
for _, product in ipairs(plan.products) do soldBolt = soldBolt or product.item == 101 end
check("missing: unpriced steps listed, their output not sold", plan.steps[1].unpriced and plan.steps[3].unpriced
    and #plan.missing == 2 and plan.missing[1][1] == 1 and plan.missing[1][2] == 2
    and plan.missing[2][1] == 3 and plan.missing[2][2] == 4 and not soldBolt and plan.materials == 10)
plan = build({
    { id = 1, skill = { 1, 5, 10 }, reagents = { 900, 1 }, learn = 1 },
    { id = 2, skill = { 8, 15, 20 }, reagents = { 901, 1 }, learn = 8 },
    { id = 3, skill = { 12, 20, 30 }, reagents = { 900, 1 }, learn = 12 },
}, 1, 16, { vendorBuy = { [900] = 10 } })
check("missing: a stretch with no priced recipe", #plan.missing == 1 and plan.missing[1][1] == 10
    and plan.missing[1][2] == 12)

if failures > 0 then
    print(failures .. " failed")
    os.exit(1)
end
print("leveling plan: all passed")
