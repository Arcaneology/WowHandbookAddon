local ADDON_NAME, ns = ...
local L = ns.L

-- 启用时只扫一次生成数据。提示回调只按物品 ID 查表。
local Module = ns:NewModule("ItemSource")
local sources = {}
local seenTooltips = setmetatable({}, { __mode = "k" })
local hooked = false

local function ItemID(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)"))
end

local function AddSource(itemID, boss, dungeon, entry)
    if not itemID or sources[itemID] then
        return
    end
    local location = ns.Name(dungeon.name) or L["Dungeon"]
    local name = ns.BossName(boss) or L["Unknown boss"]
    local text = (L["Drops from: %s (%s)"]):format(name, location)
    if type(entry) == "table" and entry.rate then
        text = text .. " " .. (L["Drop rate: %s%%"]):format(tostring(entry.rate))
    end
    sources[itemID] = text
end

local function AddTooltip(tooltip, data)
    if not Module.enabled or not tooltip or not tooltip.AddLine then
        return
    end
    local itemID = data and data.id
    if ns.IsSecret(itemID) then
        return
    end
    if not itemID and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        itemID = ItemID(link)
    end
    local source = sources[itemID]
    if not source then
        return
    end
    local token = data and data.dataInstanceID or itemID
    if seenTooltips[tooltip] == token then
        return
    end
    seenTooltips[tooltip] = token
    tooltip:AddLine(source, unpack(ns.Theme.colors.textDim))
    if tooltip.Show then
        tooltip:Show()
    end
end

function Module:OnEnable()
    wipe(sources)
    for _, dungeon in ipairs(ns.Data.dungeons or {}) do
        for _, boss in ipairs(dungeon.bosses or {}) do
            for _, entry in ipairs(boss.items or {}) do
                AddSource(type(entry) == "table" and entry.id or entry, boss, dungeon, entry)
            end
        end
    end
    if hooked then
        return
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddTooltip)
        hooked = true
    elseif GameTooltip and GameTooltip.HookScript then
        -- 旧版提示处理路径；只操作提示框本身，不覆盖暴雪函数。
        GameTooltip:HookScript("OnTooltipSetItem", AddTooltip)
        hooked = true
    end
    if hooked and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
            seenTooltips[tooltip] = nil
        end)
    end
end

function Module:OnDisable()
    wipe(sources)
end

Module.Lookup = function(itemID)
    return sources[itemID]
end
