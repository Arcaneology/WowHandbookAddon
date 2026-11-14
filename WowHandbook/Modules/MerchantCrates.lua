local ADDON_NAME, ns = ...
local L = ns.L

-- 遭劫的板条箱：已辨认的板条箱（阅读标签后的那种）要任选一种捆绑包装满才能交给商人换商人青睐。
-- 本模块在板条箱的鼠标提示里列出每种可装的物品、件数与装满要花的钱（商人售价与拍卖行价格取低者，
-- 来自 ns.Prices），最便宜的一种标绿。哪些箱子装什么来自网站数据（Data/MerchantCrates.lua），
-- 物品名称运行时向客户端获取。未辨认的通用板条箱不知道是哪种，不加内容。
local Module = ns:NewModule("MerchantCrates")
local Prices = ns.Prices

local seenTooltips = setmetatable({}, { __mode = "k" })
local hooked = false

local function Crates()
    local data = ns.Data and ns.Data.merchantCrates
    return data and data.crates or {}
end

local function ItemName(itemID)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if not name then
        ns.RequestItem(itemID)
    end
    return name or ("item:" .. itemID)
end

-- 每种捆绑包的单价、总价与来源；最便宜一种的序号（都没有价格时为 nil）
local function Evaluate(crateID)
    local bundles = Crates()[crateID]
    if not bundles then
        return nil
    end
    local options, cheapest = {}, nil
    for index, bundle in ipairs(bundles) do
        local itemID, count = bundle[1], bundle[2]
        local unit, source = Prices.BuyCost(itemID)
        local option = { itemID = itemID, count = count, unit = unit, source = source,
            total = unit and floor(unit * count + 0.5) or nil }
        options[index] = option
        if option.total and (not cheapest or option.total < options[cheapest].total) then
            cheapest = index
        end
    end
    return options, cheapest
end

local function AddTooltip(tooltip, data)
    if not (Module.enabled and tooltip and tooltip.AddDoubleLine) then
        return
    end
    local itemID = data and data.id
    if ns.IsSecret(itemID) then
        return
    end
    if not itemID and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        itemID = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    end
    local options, cheapest = Evaluate(itemID)
    if not options then
        return
    end
    local token = data and data.dataInstanceID or itemID
    if seenTooltips[tooltip] == token then
        return
    end
    seenTooltips[tooltip] = token
    local colors = ns.Theme.colors
    local dim, text, good = colors.textDim, colors.text, colors.green
    tooltip:AddLine(" ")
    tooltip:AddLine(L["Cost to fill this crate:"], unpack(colors.gold))
    local missing = false
    for index, option in ipairs(options) do
        local left = ("%s x%d"):format(ItemName(option.itemID), option.count)
        local right
        if option.total then
            right = (L["%s (%s each)"]):format(ns.Money(option.total) or "0", ns.Money(option.unit) or "0")
            if option.source == "vendor" then
                right = ("%s %s"):format(right, L["vendor"])
            end
        else
            right = L["no price yet"]
            missing = true
        end
        local color = index == cheapest and good or text
        tooltip:AddDoubleLine(left, right, dim[1], dim[2], dim[3], color[1], color[2], color[3])
    end
    if missing then
        tooltip:AddLine(L["Search for these at the auction house, or scan it, to fill in the missing prices."],
            dim[1], dim[2], dim[3], true)
    end
    if tooltip.Show then
        tooltip:Show()
    end
end

local function HookTooltips()
    if hooked then
        return
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddTooltip)
        hooked = true
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetItem", AddTooltip)
        hooked = true
    end
    if hooked and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
            seenTooltips[tooltip] = nil
        end)
    end
end

function Module:OnEnable()
    HookTooltips()
end

function Module:OnDisable()
    -- 鼠标提示的挂钩无法撤掉，关闭后 AddTooltip 直接返回
end

-- 测试用：按当前价格算一个板条箱
Module.Evaluate = Evaluate
