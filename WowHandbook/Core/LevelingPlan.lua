local ADDON_NAME, ns = ...

-- 冲级路线的计算（不碰界面与游戏接口，价格与物品分类由调用方传入，便于测试）。
-- 源自 wowhandbook.com 专业攻略页的冲级计算（网站另有分段与指定制作，插件不带这两项）。
-- 背包归高流通由调用方的分档决定（Modules/Workbench.lua 的 CLASS_TIER）。
-- 也能给一条现成的路线计价（input.fixed，手册路线）：顺序和次数照给的走，不选配方，只算要买什么、花多少、回收多少。
--
-- 每个技能点选“期望净花费”最低的配方：
--   （每次的材料花费 − 每次成品的回收）÷ 涨点概率 + （图纸钱 + 还缺的工具钱）摊到它能用的技能点上
-- 涨点概率：没到变黄点 100%，之后按 (变灰点 − 当前技能) ÷ (变灰点 − 变黄点) 线性下降，到变灰点为 0。
-- 能赚钱的配方（成品回收比材料还多）净花费为负，排在所有要花钱的配方前面，几个都赚钱时选每个技能点赚得多的：
--   又赚钱又涨点，变灰之前一直做（例：裁缝 133 点的红色毛纺包）。
--   拍卖行吃得下的件数（流通档 cap）会让回收降到卖店价，做到上限就自然换配方，不会建议挂几十件。
--
-- 材料：商人价与拍卖行阶梯价取低者，买得多时逐档往上吃；拍卖行在售不够又没有商人卖的，记为缺口。
--       路线里先做出来的东西留在库存，后面的配方优先用；本专业现在能做、而且自己做更便宜的中间材料改为自己做。
-- 工具（附魔棒、铁匠锤等）：配方要的工具背包里没有时，先做一个（本专业能做）或买一个，取便宜的；
--       做出来的第一件留着用，不卖也不当材料。
-- 有冷却的配方（转化、月布等）不能连做，路线不用。
-- 回收按成品的流通性分档（调用方给每件成品定档）：
--   high  中间材料、消耗品等，卖得动：按拍卖价（扣 5% 手续费），数量不限
--   mid   背包等：前 cap 件按拍卖价，其余卖店
--   low   装备：汇总的预计回收里前 cap 件按拍卖价，其余卖店；选配方时只按卖店价（要考虑流通率，
--         装备的拍卖价不能让它排到背包前面）
--   拍卖价不另打折扣（利润就是卖价扣手续费减材料）；流通性只靠 cap 体现。
--   none  绑定的：只能卖店（附魔到装备上没有成品，不回收）
--   同一种成品做得越多，后面的回收越低，路线会自己换配方，不会建议做几十件装备全挂拍卖。
--   调用方还可以给 market.sale（卖出价与买入价不同）与 market.cap（拍卖行一天吃得下多少件）。
-- 代工：没有成品的配方（附魔）按客人出材料算，材料花费为 0；可以全部算，也可以只算选中的几个。
--       只在配方还是橙色或黄色时算：变绿以后一个技能点要找太多客人。
local Plan = {}
ns.LevelingPlan = Plan

local max, min, huge = math.max, math.min, math.huge
local insert = table.insert

Plan.AH_CUT = 0.05 -- 拍卖行手续费
Plan.NEUTRAL_CUT = 0.15 -- 中立拍卖行手续费
Plan.TIERS = {
    high = { factor = 1, cap = huge },
    mid = { factor = 1, cap = 10 },
    low = { factor = 1, cap = 2 },
    none = { factor = 0, cap = 0 },
}
-- 路线的取向：每多做一次制作折合多少钱（时间成本，铜）。技能点高时配方多半已不是橙色，
-- 每个技能点要做好几次；按时间算，必涨的配方哪怕花点钱也比便宜但要做三四次的划算。
--   saving   省钱优先：不算时间，只比钱
--   balanced 均衡：每次制作折 PRIORITY.balanced 铜，乘上技能段系数（技能越高，同样的时间越值钱）
--   speed    效率优先：每次制作折得很贵，基本按次数最少选，次数差不多再比钱
Plan.PRIORITY = { saving = 0, balanced = 500, speed = 3000 }
local function TimeCost(priority, skill)
    local base = Plan.PRIORITY[priority or "saving"] or 0
    return base * max(1, (skill or 1) / 75)
end
Plan.TimeCost = TimeCost

local MAX_ALTERNATIVES = 8
local STICKY = 0.03 -- 上一步的配方只贵这么多以内就接着做，免得两个差不多的配方来回换

-- 当前技能做这个配方涨点的概率
function Plan.Chance(recipe, skill)
    local points = recipe.skill
    if not points then
        return 0
    end
    local yellow, gray = points[1], points[3]
    if skill >= gray then
        return 0
    elseif skill < yellow or gray <= yellow then
        return 1
    end
    return min(1, (gray - skill) / (gray - yellow))
end

-- 买 count 个要多少钱：已经买过 skip 个（它们吃掉了最便宜的几档）。
-- 返回 花费, 拍卖行不够的数量；一点价格都没有时返回 nil
local function LadderCost(info, skip, count)
    local vendor = info.vendor
    local cost, left = 0, count
    if info.levels then
        for _, level in ipairs(info.levels) do
            local price, quantity = level[1], level[2]
            if vendor and price >= vendor then
                break
            end
            local used = min(skip, quantity)
            skip = skip - used
            local take = min(left, quantity - used)
            if take > 0 then
                cost = cost + take * price
                left = left - take
            end
            if left <= 0 then
                return cost, 0
            end
        end
        if vendor then
            return cost + left * vendor, 0
        end
        -- 拍卖行在售的不够：缺的按最贵一档估价，并记为缺口
        local last = info.levels[#info.levels]
        return cost + left * last[1], left
    end
    if vendor and (not info.auction or vendor <= info.auction) then
        return count * vendor, 0
    elseif info.auction then
        return count * info.auction, 0 -- 只知道最低价、不知道在售数量
    end
    return nil
end
Plan.LadderCost = LadderCost

local function PriceInfo(ctx, item)
    local info = ctx.prices[item]
    if not info then
        local market = ctx.market
        info = { levels = market.levels and market.levels(item), auction = market.auction(item),
            vendor = market.vendorBuy(item) }
        if info.levels and #info.levels == 0 then
            info.levels = nil
        end
        if info.levels and not info.auction then
            info.auction = info.levels[1][1]
        end
        ctx.prices[item] = info
    end
    return info
end

local function SaleInfo(ctx, item)
    local info = ctx.sales[item]
    if not info then
        local market = ctx.market
        local auction
        if market.sale then
            auction = market.sale(item)
        else
            auction = market.auction(item)
        end
        local tier = market.tier(item) or "none"
        if not Plan.TIERS[tier] then
            tier = "none"
        end
        info = { tier = tier, vendor = market.vendorSell(item) or 0,
            net = auction and auction * (1 - Plan.AH_CUT) or nil,
            cap = min(Plan.TIERS[tier].cap, market.cap and market.cap(item) or huge) }
        ctx.sales[item] = info
    end
    return info
end

-- 库存里第 already + 1 件能回收多少：预计值（各档都算）与稳妥值（只有卖店和高流通按拍卖价）
local function SaleUnit(ctx, item, already)
    if not ctx.options.recovery then
        return 0, 0
    end
    local info = SaleInfo(ctx, item)
    local tier = Plan.TIERS[info.tier]
    local market = (info.net and already < info.cap) and info.net * tier.factor or 0
    local expected = max(info.vendor, market)
    return expected, info.tier == "high" and expected or info.vendor
end

-- 库存里已有 already 件时，接下来 count 件能回收多少：还没到拍卖上限的按拍卖价，其余卖店。
-- 选配方用：低流通（装备）只按卖店价算，挂拍卖卖不卖得掉没把握，不能靠它把装备排到背包、布卷前面
local function SaleNext(ctx, item, already, count)
    if not ctx.options.recovery or count <= 0 then
        return 0
    end
    local info = SaleInfo(ctx, item)
    if info.tier == "low" then
        return count * info.vendor
    end
    local market = info.net and info.net * Plan.TIERS[info.tier].factor or 0
    if market <= info.vendor then
        return count * info.vendor
    end
    local atAuction = max(0, min(count, info.cap - already))
    return atAuction * market + (count - atAuction) * info.vendor
end

-- count 件成品一共回收多少（预计、稳妥），以及其中按拍卖价卖的件数
local function SaleTotal(ctx, item, count)
    if not ctx.options.recovery or count <= 0 then
        return 0, 0, 0
    end
    local info = SaleInfo(ctx, item)
    local tier = Plan.TIERS[info.tier]
    local market = info.net and info.net * tier.factor or 0
    if market <= info.vendor then
        return count * info.vendor, count * info.vendor, 0
    end
    local atAuction = min(count, info.cap)
    local expected = atAuction * market + (count - atAuction) * info.vendor
    return expected, info.tier == "high" and expected or count * info.vendor, atAuction
end

-- 这个配方现在能不能用：返回 可用, 要先花的图纸钱（没有时为 nil）, 图纸钱的来源（"vendor" / "auction"）
local function Usable(ctx, recipe, skill)
    if recipe.nip or recipe.cooldown or not recipe.skill then
        return false
    end
    if ctx.known(recipe) or ctx.owned[recipe.id] then
        return true
    end
    if recipe.auto then
        return true
    end
    if skill < (recipe.learn or recipe.skill[1]) then
        return false
    end
    if not recipe.learnedFrom then
        return true -- 训练师教
    end
    if not ctx.options.buyRecipes then
        return false
    end
    local vendor = recipe.buy and recipe.buy[ctx.faction]
    local auction = ctx.market.auction(recipe.learnedFrom)
    if vendor and (not auction or vendor <= auction) then
        return true, vendor, "vendor"
    elseif auction then
        return true, auction, "auction"
    end
    return false
end

local function Yield(recipe)
    return recipe.count or 1
end

-- 本专业里现在能做、不用另买图纸的“做出 item 的配方”
local function Maker(ctx, item, skill)
    for _, recipe in ipairs(ctx.makers[item] or {}) do
        local usable, fee = Usable(ctx, recipe, skill)
        if usable and not fee then
            return recipe
        end
    end
end

-- 自己做 count 个 item 的材料花费（材料都按买算，只下一层）；有材料没价格时返回 nil
local function CraftCost(ctx, maker, count)
    local crafts = count / Yield(maker)
    local total = 0
    local reagents = maker.reagents or {}
    for index = 1, #reagents, 2 do
        local item = reagents[index]
        local cost = LadderCost(PriceInfo(ctx, item), ctx.bought[item] or 0, crafts * (reagents[index + 1] or 1))
        if not cost then
            return nil
        end
        total = total + cost
    end
    return total, crafts
end

-- 记到当前这一步的明细里：{ 键, 数量, 花费 }，同一个键累加
local function Note(list, key, count, cost)
    if not list then
        return
    end
    for _, entry in ipairs(list) do
        if entry[1] == key then
            entry[2] = entry[2] + count
            if cost then
                entry[3] = entry[3] + cost
            end
            return
        end
    end
    insert(list, { key, count, cost })
end

local function Buy(ctx, item, count, commit)
    local info = PriceInfo(ctx, item)
    local cost, short = LadderCost(info, ctx.bought[item] or 0, count)
    if cost and commit then
        ctx.bought[item] = (ctx.bought[item] or 0) + count
        ctx.spent[item] = (ctx.spent[item] or 0) + cost
        Note(ctx.step and ctx.step.bought, item, count, cost)
        if short and short > 0 then
            ctx.short[item] = (ctx.short[item] or 0) + short
        end
        if not info.levels and info.auction and not (info.vendor and info.vendor <= info.auction) then
            ctx.unknownDepth[item] = true
        end
    end
    return cost
end

-- 弄到 count 个材料：先用路线里做出来的库存（按它本来能卖的钱算机会成本），不够的买或自己做，取便宜的。
-- 返回 现金花费, 用掉库存的机会成本；有材料没价格时返回 nil。commit 为真时记账
local function Acquire(ctx, item, count, skill, commit)
    local stock = ctx.stock[item] or 0
    local fromStock = min(stock, count)
    local opportunity = 0
    if fromStock > 0 then
        opportunity = fromStock * SaleUnit(ctx, item, max(0, stock - fromStock))
        if commit then
            ctx.stock[item] = stock - fromStock
            ctx.consumed[item] = (ctx.consumed[item] or 0) + fromStock
            Note(ctx.step and ctx.step.used, item, fromStock)
        end
    end
    local need = count - fromStock
    if need <= 0 then
        return 0, opportunity
    end
    local buyCost = Buy(ctx, item, need, false)
    local maker = Maker(ctx, item, skill)
    local craftCost, crafts
    if maker then
        craftCost, crafts = CraftCost(ctx, maker, need)
    end
    if craftCost and (not buyCost or craftCost < buyCost) then
        -- 中间材料也是本专业的制作，没变灰之前同样涨点（2026-11-17）：六个橙色布卷做一个包是七点，不是一点
        if not commit then
            -- 选配方时：按期望算中间材料的份额和它在这个技能上的点数
            if ctx.prep then
                ctx.prep.crafts = ctx.prep.crafts + crafts
                ctx.prep.points = ctx.prep.points + crafts * Plan.Chance(maker, skill)
            end
            return craftCost, opportunity
        end
        -- 真正做的时候按整次做，多出来的进库存；每一次按做它那一刻的技能算涨点，
        -- 做到一半变黄的批次后面几次就少算
        local whole = math.ceil(crafts - 1e-9)
        local cash = 0
        local reagents = maker.reagents or {}
        for index = 1, #reagents, 2 do
            cash = cash + (Buy(ctx, reagents[index], whole * (reagents[index + 1] or 1), true) or 0)
        end
        ctx.prepared[maker.id] = (ctx.prepared[maker.id] or 0) + whole
        Note(ctx.step and ctx.step.prepared, maker.id, whole)
        local spare = whole * Yield(maker) - need
        if spare > 1e-9 then
            ctx.stock[item] = (ctx.stock[item] or 0) + spare
        end
        if ctx.prep then
            for _ = 1, whole do
                ctx.prep.crafts = ctx.prep.crafts + 1
                ctx.prep.points = ctx.prep.points + Plan.Chance(maker, skill + math.floor(ctx.prep.points))
            end
        end
        return cash, opportunity
    end
    if not buyCost then
        return nil
    end
    if commit then
        Buy(ctx, item, need, true)
    end
    return buyCost, opportunity
end

-- 代工只在附魔还是橙色或黄色时算：变绿以后一个技能点要找太多客人
local function IsCommission(ctx, recipe, skill)
    return not recipe.makes and ctx.commission(recipe) and skill < (recipe.skill and recipe.skill[2] or 0)
end

-- 做 crafts 次这个配方的材料花费（现金 + 库存机会成本）；代工时为 0
local function MaterialCost(ctx, recipe, crafts, skill, commit)
    if IsCommission(ctx, recipe, skill) then
        return 0, 0
    end
    local cash, opportunity = 0, 0
    local reagents = recipe.reagents or {}
    for index = 1, #reagents, 2 do
        local a, b = Acquire(ctx, reagents[index], crafts * (reagents[index + 1] or 1), skill, commit)
        if not a then
            return nil
        end
        cash, opportunity = cash + a, opportunity + b
    end
    return cash, opportunity
end

-- 这个配方还缺的工具：每件做一个（本专业现在能做）或买一个，取便宜的。
-- 返回 花费, { { item = 工具, recipe = 做它的配方（买的没有） } }；有工具既做不了也买不到时返回 nil（配方暂时用不了）
local function ToolNeeds(ctx, recipe, skill)
    local cost, get = 0, {}
    for _, options in ipairs(recipe.tools or {}) do
        local have = false
        for _, item in ipairs(options) do
            have = have or ctx.tools[item]
        end
        if not have then
            local pick
            for _, item in ipairs(options) do
                local made = Maker(ctx, item, skill)
                if made then
                    local cash, opportunity = MaterialCost(ctx, made, 1, skill, false)
                    if cash and (not pick or cash + opportunity < pick.cost) then
                        pick = { item = item, recipe = made, cost = cash + opportunity }
                    end
                end
                local bought = Buy(ctx, item, 1, false)
                if bought and (not pick or bought < pick.cost) then
                    pick = { item = item, cost = bought }
                end
            end
            if not pick then
                return nil
            end
            cost = cost + pick.cost
            insert(get, pick)
        end
    end
    return cost, get
end

-- 这一个技能点上各配方的期望净花费，取最低的
local function Best(ctx, skill)
    ctx.timeCost = TimeCost(ctx.options.priority, skill)
    local best, previous
    for _, recipe in ipairs(ctx.recipes) do
        local chance = Plan.Chance(recipe, skill)
        if chance > 0 then
            local usable, fee, feeSource = Usable(ctx, recipe, skill)
            if usable then
                -- 先按做一次试算，记下顺手要做的中间材料次数和它们带来的点数
                ctx.prep = { crafts = 0, points = 0 }
                local unit = MaterialCost(ctx, recipe, 1, skill, false)
                local prep = ctx.prep
                ctx.prep = nil
                local gain = chance + prep.points
                local crafts = 1 / gain
                local extra = prep.crafts * crafts
                local cash, opportunity
                if unit then
                    cash, opportunity = MaterialCost(ctx, recipe, crafts, skill, false)
                end
                local toolCost, get
                if cash then
                    toolCost, get = ToolNeeds(ctx, recipe, skill)
                else
                    ctx.unpriced[recipe.id] = true
                end
                if toolCost then
                    local recovery = 0
                    if recipe.makes then
                        recovery = SaleNext(ctx, recipe.makes, ctx.stock[recipe.makes] or 0, crafts * Yield(recipe))
                    end
                    local span = max(1, min(ctx.to, recipe.skill[2]) - skill)
                    -- 能赚钱的 raw 为负，排在要花钱的前面，赚得越多越靠前（见文件头）
                    local raw = cash + opportunity - recovery
                    -- 时间成本：每多做一次按 ctx.timeCost 铜算（省钱优先为 0，见 Plan.PRIORITY），中间材料的制作也算
                    local score = raw + ((fee or 0) + toolCost) / span + ctx.timeCost * (crafts + extra)
                    if recipe == ctx.last then
                        previous = { recipe = recipe, score = score, raw = raw, chance = gain, crafts = crafts,
                            get = get }
                    end
                    if not best or score < best.score - 1e-6
                        or (score < best.score + 1e-6 and (gain > best.chance
                            or (gain == best.chance and (raw < best.raw - 1e-6
                                or (raw < best.raw + 1e-6 and recipe.id < best.recipe.id))))) then
                        best = { recipe = recipe, score = score, raw = raw, chance = gain, crafts = crafts,
                            fee = fee, feeSource = feeSource, get = get }
                    end
                end
            end
        end
    end
    if previous and best and previous.score <= best.score + math.abs(best.score) * STICKY then
        return previous
    end
    return best
end

-- 代工时这一点上还能涨点的其他代工附魔（按涨点概率从高到低）
local function Alternatives(ctx, skill, chosen)
    local list = {}
    for _, recipe in ipairs(ctx.recipes) do
        if recipe ~= chosen and IsCommission(ctx, recipe, skill) and Usable(ctx, recipe, skill) then
            local chance = Plan.Chance(recipe, skill)
            if chance > 0 then
                insert(list, { recipe = recipe, chance = chance })
            end
        end
    end
    table.sort(list, function(a, b)
        if a.chance ~= b.chance then
            return a.chance > b.chance
        end
        return a.recipe.id < b.recipe.id
    end)
    for index = #list, MAX_ALTERNATIVES + 1, -1 do
        list[index] = nil
    end
    return list
end

-- input = {
--   recipes = 本专业配方表（RecipeData 的格式）, from = 当前技能, to = 目标技能, faction = "A" / "H",
--   known = function(recipe) 已学会, hasTool = function(item) 背包里已经有这件工具,
--   market = { levels(item) 阶梯价 {{单价, 数量}}, auction(item) 拍卖最低单价, vendorBuy(item) 商人卖价,
--              vendorSell(item) 卖店价, tier(item) 流通档,
--              sale(item) 卖出价（不给时用 auction）, cap(item) 拍卖行吃得下的件数（不给时只按流通档） },
--   options = { recovery 计入回收, commission 代工：true 全部附魔 / { 配方 ID, ... } 只算这几个, buyRecipes 可买图纸 },
--   fixed = { { recipe 配方 ID, from, to, crafts, stock, keepBelow, forced } } 给了就按它计价，不再选配方：
--           stock 为后面的步骤备料，不涨点，玩家技能低于 keepBelow 时保留（until 是 Lua 的保留字）；
--           forced 是做一件留着的工具（已有就跳过）；
--           玩家技能在一步中间时，次数按剩下的技能点折算,
-- }
-- 返回 {
--   steps = { { recipe, from, to, crafts, cash 材料现金, commission, alternatives,
--               bought = { { 物品, 数量, 花费 } } 这一步买的, used = { { 物品, 数量 } } 用掉前面做的,
--               prepared = { { 配方 ID, 次数 } } 这一步先自己做的中间材料,
--               stock 为真：不涨点（forced 也为真是先做一件工具，否则是给后面备料）,
--               unpriced 有材料没价格，这一步的花费算不出（只在 fixed 时） }
--             或 { gap = true, from, to } },
--   shopping = { { item, count, cost, short 拍卖行缺口, unknownDepth 不知道在售数量, vendor 向商人买 } },
--   recipesToBuy = { { recipe, fee, source } }, prepared = { { recipe, crafts } } 要先做的中间材料,
--   products = { { item, made, used, auction, vendor, tier, value } },
--   materials 材料现金合计, recipeCost 图纸合计, recovery 预计回收, safeRecovery 稳妥回收, net 净花费,
--   blocked 第一个没有配方可用的技能点, unpriced 因材料没价格没法比较的配方数,
--   missing = { { from, to } } 汇总没算进去的技能区间（断档或缺价），有就是部分预算,
-- }
function Plan.Build(input)
    local ctx = {
        recipes = input.recipes or {}, to = input.to, faction = input.faction, market = input.market,
        known = input.known or function() return false end, options = input.options or {},
        prices = {}, sales = {}, stock = {}, made = {}, consumed = {}, bought = {}, spent = {}, short = {},
        unknownDepth = {}, owned = {}, prepared = {}, unpriced = {}, makers = {}, tools = {}, toolItems = {},
        commission = function() return false end,
    }
    local commission = ctx.options.commission
    if type(commission) == "table" then
        local chosen = {}
        for _, id in ipairs(commission) do
            chosen[id] = true
        end
        ctx.commission = function(recipe) return chosen[recipe.id] or false end
    elseif commission then
        ctx.commission = function() return true end
    end
    for _, recipe in ipairs(ctx.recipes) do
        if recipe.makes and recipe.skill and not recipe.nip and not recipe.cooldown then
            ctx.makers[recipe.makes] = ctx.makers[recipe.makes] or {}
            insert(ctx.makers[recipe.makes], recipe)
        end
        for _, options in ipairs(recipe.tools or {}) do
            for _, item in ipairs(options) do
                ctx.toolItems[item] = true
                if input.hasTool and input.hasTool(item) then
                    ctx.tools[item] = true
                end
            end
        end
    end

    local plan = { steps = {}, recipesToBuy = {}, recipeCost = 0, options = ctx.options }
    local function NewStep(recipe, skill)
        return { recipe = recipe, from = skill, to = skill, crafts = 0, cash = 0, bought = {}, used = {},
            prepared = {} }
    end
    -- 这一步做 crafts 次：买材料、用库存，做出来的进库存。points 为真时返回顺手做的中间材料带来的点数
    local function Craft(step, recipe, crafts, skill, points)
        ctx.step = step
        if points then
            ctx.prep = { crafts = 0, points = 0 }
        end
        local cash = MaterialCost(ctx, recipe, crafts, skill, true)
        local gained = ctx.prep and ctx.prep.points or 0
        ctx.prep = nil
        ctx.step = nil
        step.crafts = step.crafts + crafts
        step.cash = step.cash + (cash or 0)
        if recipe.makes then
            local count = crafts * Yield(recipe)
            ctx.made[recipe.makes] = (ctx.made[recipe.makes] or 0) + count
            -- 工具的第一件留在背包里：不卖，也不当材料用掉
            local kept = (ctx.toolItems[recipe.makes] and not ctx.tools[recipe.makes]) and 1 or 0
            if kept > 0 then
                ctx.tools[recipe.makes] = true
            end
            ctx.stock[recipe.makes] = (ctx.stock[recipe.makes] or 0) + max(0, count - kept)
        end
        return gained
    end
    local byID = {}
    for _, recipe in ipairs(ctx.recipes) do
        byID[recipe.id] = recipe
    end
    for _, entry in ipairs(input.fixed or {}) do
        local recipe = byID[entry.recipe]
        local from, to = max(entry.from, input.from), min(entry.to, input.to)
        local crafts = entry.crafts
        local keep = recipe ~= nil
        if entry.stock then
            keep = keep and (entry.keepBelow or entry.from + 1) > input.from and entry.from < input.to
        else
            keep = keep and to > from
            crafts = keep and math.ceil(entry.crafts * (to - from) / (entry.to - entry.from) - 1e-9) or 0
        end
        -- 背包里已经有的工具不用再做
        if keep and entry.forced and recipe.makes and ctx.tools[recipe.makes] then
            keep = false
        end
        if keep then
            local feeMissing = false
            if not ctx.owned[recipe.id] and recipe.learnedFrom and not recipe.auto and not ctx.known(recipe) then
                local vendor = recipe.buy and recipe.buy[ctx.faction]
                local auction = ctx.market.auction(recipe.learnedFrom)
                local source = (vendor and (not auction or vendor <= auction)) and "vendor" or "auction"
                local fee = source == "vendor" and vendor or auction
                if fee then
                    insert(plan.recipesToBuy, { recipe = recipe, fee = fee, source = source })
                    plan.recipeCost = plan.recipeCost + fee
                else
                    feeMissing = true
                end
            end
            ctx.owned[recipe.id] = true
            local step = NewStep(recipe, entry.stock and entry.from or from)
            step.to = entry.stock and entry.from or to
            step.stock, step.forced = entry.stock or nil, entry.forced or nil
            -- 图纸没价格：材料照常计价，这一步仍标缺价
            step.unpriced = feeMissing or nil
            -- 固定路线上勾选的附魔不论颜色都按客人出材料算：次数是路线定好的
            if not recipe.makes and ctx.commission(recipe) then
                step.commission, step.crafts = true, crafts
            elseif MaterialCost(ctx, recipe, crafts, from, false) then
                Craft(step, recipe, crafts, from)
            else
                step.unpriced, step.crafts = true, crafts
                ctx.unpriced[recipe.id] = true
                -- 后面的步骤照样用它做出来的东西，但不算卖钱：成本不知道，卖钱会算出路线未必有的利润
                if recipe.makes then
                    ctx.stock[recipe.makes] = (ctx.stock[recipe.makes] or 0) + crafts * Yield(recipe)
                end
            end
            insert(plan.steps, step)
        end
    end
    -- 工具和多出来的期望点数里还没用掉的部分：满 1 点就把路线往前推一点
    local credit = 0
    local skill = input.from
    local last = input.fixed and input.from or input.to
    local rounds = 0
    while skill < last do
        rounds = rounds + 1
        if rounds > 100000 then
            break
        end
        if credit >= 1 - 1e-6 then
            credit = credit - 1
            plan.steps[#plan.steps].to = skill + 1
        else
            local best = Best(ctx, skill)
            -- 先备好工具：自己做的单独成一步，买的记在要用它的那一步上；做工具也是一次制作，同样涨点
            local toolsToBuy, made = {}, nil
            for _, need in ipairs(best and best.get or {}) do
                if need.recipe then
                    made = NewStep(need.recipe, skill)
                    made.stock, made.forced = true, true
                    Craft(made, need.recipe, 1, skill)
                    credit = credit + Plan.Chance(need.recipe, skill)
                    ctx.owned[need.recipe.id] = true
                    insert(plan.steps, made)
                else
                    insert(toolsToBuy, need.item)
                end
                ctx.tools[need.item] = true
            end
            local step = plan.steps[#plan.steps]
            if made and #toolsToBuy == 0 and credit >= 1 - 1e-6 then
                -- 这一点就是工具给的：要用它的配方从下一点起、带着工具重新选
                credit = credit - 1
                made.to = skill + 1
            elseif not best then
                plan.blocked = plan.blocked or skill
                if not (step and step.gap) then
                    step = { gap = true, from = skill, to = skill }
                    insert(plan.steps, step)
                end
                step.to = skill + 1
            else
                local recipe = best.recipe
                if best.fee and not ctx.owned[recipe.id] then
                    insert(plan.recipesToBuy, { recipe = recipe, fee = best.fee, source = best.feeSource })
                    plan.recipeCost = plan.recipeCost + best.fee
                end
                ctx.owned[recipe.id] = true
                ctx.last = recipe
                local onCommission = IsCommission(ctx, recipe, skill)
                if not step or step.recipe ~= recipe or step.forced or (step.commission or false) ~= onCommission then
                    step = NewStep(recipe, skill)
                    if onCommission then
                        step.commission = true
                        step.alternatives = Alternatives(ctx, skill, recipe)
                    end
                    insert(plan.steps, step)
                end
                ctx.step = step
                for _, item in ipairs(toolsToBuy) do
                    Buy(ctx, item, 1, true)
                end
                ctx.step = nil
                -- 整次制作，直到这一点挣到：每次给它的涨点概率，加上先做的中间材料的点数；
                -- 多出来的留给后面的点（不再有半次制作）
                local done = 0
                while credit < 1 - 1e-6 and done < 1000 do
                    local level = skill + math.floor(credit)
                    local gained = Craft(step, recipe, 1, level, true)
                    credit = credit + gained + Plan.Chance(recipe, level + math.floor(gained))
                    done = done + 1
                end
                credit = credit - 1
                step.to = skill + 1
            end
        end
        skill = skill + 1
    end

    plan.shopping, plan.materials = {}, 0
    for item, count in pairs(ctx.bought) do
        local info = PriceInfo(ctx, item)
        insert(plan.shopping, { item = item, count = count, cost = ctx.spent[item] or 0, short = ctx.short[item],
            unknownDepth = ctx.unknownDepth[item],
            vendor = not info.levels and info.vendor ~= nil and (not info.auction or info.vendor <= info.auction) })
        plan.materials = plan.materials + (ctx.spent[item] or 0)
    end
    table.sort(plan.shopping, function(a, b)
        if a.cost ~= b.cost then
            return a.cost > b.cost
        end
        return a.item < b.item
    end)

    plan.prepared = {}
    for id, crafts in pairs(ctx.prepared) do
        insert(plan.prepared, { recipe = byID[id], crafts = crafts })
    end
    table.sort(plan.prepared, function(a, b) return a.recipe.id < b.recipe.id end)

    plan.products, plan.recovery, plan.safeRecovery = {}, 0, 0
    for item, made in pairs(ctx.made) do
        local left = ctx.stock[item] or 0
        local expected, safe, atAuction = SaleTotal(ctx, item, left)
        plan.recovery, plan.safeRecovery = plan.recovery + expected, plan.safeRecovery + safe
        insert(plan.products, { item = item, made = made, used = ctx.consumed[item] or 0, auction = atAuction,
            vendor = left - atAuction, tier = SaleInfo(ctx, item).tier, value = expected })
    end
    table.sort(plan.products, function(a, b) return a.item < b.item end)

    plan.net = plan.materials + plan.recipeCost - plan.recovery
    -- 汇总没算进去的技能区间：动态路线的断档，固定路线里材料或图纸没价格的步骤。有任何一段，汇总就只是部分预算
    plan.missing = {}
    for _, step in ipairs(plan.steps) do
        if step.gap or step.unpriced then
            local range = { step.from, max(step.to, step.from + 1) }
            local prev = plan.missing[#plan.missing]
            if prev and range[1] <= prev[2] then
                prev[2] = max(prev[2], range[2])
            else
                insert(plan.missing, range)
            end
        end
    end
    plan.unpriced = 0
    for _ in pairs(ctx.unpriced) do
        plan.unpriced = plan.unpriced + 1
    end
    return plan
end
