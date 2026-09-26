local ADDON_NAME, ns = ...
local L = ns.L

-- 自动卖灰（F6）：打开商人时卖掉背包里全部灰色物品，在聊天框报出卖了多少钱。
-- 用游戏自带的“出售全部垃圾”接口；这个接口不存在时逐格出售灰色物品。
local Module = ns:NewModule("Vendor", { sellJunk = true })

local POOR = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0

local function JunkValue()
    local total, count = 0, 0
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == POOR and not info.hasNoValue then
                local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(info.itemID)
                total = total + (sellPrice or 0) * (info.stackCount or 1)
                count = count + 1
            end
        end
    end
    return total, count
end

local function SellEachJunk()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == POOR and not info.hasNoValue then
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end
end

local function OnMerchantShow()
    if not ns:GetModuleSettings(Module).sellJunk then
        return
    end
    local value, count = JunkValue()
    if count == 0 then
        return
    end
    if C_MerchantFrame.SellAllJunkItems and (not C_MerchantFrame.IsSellAllJunkEnabled or C_MerchantFrame.IsSellAllJunkEnabled()) then
        C_MerchantFrame.SellAllJunkItems()
    else
        SellEachJunk()
    end
    ns:Print(L["Sold %d junk items for %s."], count, ns.Money(value) or "0")
end

function Module:OnEnable()
    ns:RegisterEvent("MERCHANT_SHOW", OnMerchantShow)
end
