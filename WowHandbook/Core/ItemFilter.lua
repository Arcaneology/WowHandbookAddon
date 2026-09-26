local ADDON_NAME, ns = ...
local L = ns.L

-- 掉落筛选：物品大类（武器 / 护甲 / 其他）、护甲类型与职业可用性。
-- 物品的类别与子类别用 C_Item.GetItemInfoInstant 即时获取（不需要物品缓存）；
-- 职业能用哪些武器与护甲是游戏规则，按 Forever（经典时期规则）整理在下面的表里。
local ItemFilter = {}
ns.ItemFilter = ItemFilter

local WEAPON, ARMOR = 2, 4

-- 护甲子类别：0 杂项（项链、戒指、饰品、副手物品）、1 布、2 皮、3 锁、4 板、6 盾、7 圣契、8 神像、9 图腾
local ARMOR_KIND = { [1] = "cloth", [2] = "leather", [3] = "mail", [4] = "plate", [6] = "shield" }
-- 所有职业都能装备的装备位：披风的子类别是布甲，但任何职业都能穿，归入“饰品”
local ACCESSORY_SLOTS = {
    INVTYPE_NECK = true,
    INVTYPE_FINGER = true,
    INVTYPE_TRINKET = true,
    INVTYPE_CLOAK = true,
    INVTYPE_HOLDABLE = true,
}

-- 职业可装备的护甲与武器子类别（含需要训练的技能）
-- 武器子类别：0 单手斧、1 双手斧、2 弓、3 枪、4 单手锤、5 双手锤、6 长柄、7 单手剑、8 双手剑、
-- 10 法杖、13 拳套、14 杂项、15 匕首、16 投掷、18 弩、19 魔杖、20 鱼竿
local PROFICIENCY = {
    WARRIOR = { armor = { 1, 2, 3, 4, 6 }, weapon = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18 } },
    PALADIN = { armor = { 1, 2, 3, 4, 6, 7 }, weapon = { 0, 1, 4, 5, 6, 7, 8 } },
    HUNTER = { armor = { 1, 2, 3 }, weapon = { 0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18 } },
    ROGUE = { armor = { 1, 2 }, weapon = { 2, 3, 4, 7, 13, 15, 16, 18 } },
    PRIEST = { armor = { 1 }, weapon = { 4, 10, 15, 19 } },
    SHAMAN = { armor = { 1, 2, 3, 6, 9 }, weapon = { 0, 1, 4, 5, 10, 13, 15 } },
    MAGE = { armor = { 1 }, weapon = { 7, 10, 15, 19 } },
    WARLOCK = { armor = { 1 }, weapon = { 7, 10, 15, 19 } },
    DRUID = { armor = { 1, 2, 8 }, weapon = { 4, 5, 10, 13, 15 } },
}
ItemFilter.CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

local lookup = {}
for classFile, rules in pairs(PROFICIENCY) do
    lookup[classFile] = { armor = {}, weapon = { [14] = true, [20] = true } }
    for _, id in ipairs(rules.armor) do
        lookup[classFile].armor[id] = true
    end
    for _, id in ipairs(rules.weapon) do
        lookup[classFile].weapon[id] = true
    end
end

-- 返回 category（weapon / armor / other）、armorKind（cloth … shield / accessory / nil）、classID、subClassID
function ItemFilter.Classify(itemID)
    local classID, subClassID, equipLoc
    if C_Item and C_Item.GetItemInfoInstant then
        local _
        _, _, _, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
    end
    if classID == WEAPON then
        return "weapon", nil, classID, subClassID
    elseif classID == ARMOR then
        if ACCESSORY_SLOTS[equipLoc] or subClassID == 0 then
            return "armor", "accessory", classID, subClassID
        end
        return "armor", ARMOR_KIND[subClassID] or "accessory", classID, subClassID
    end
    return "other", nil, classID, subClassID
end

-- classFile 为 nil 表示“所有职业”
function ItemFilter.Usable(itemID, classFile)
    local rules = classFile and lookup[classFile]
    if not rules then
        return true
    end
    local category, armorKind, _, subClassID = ItemFilter.Classify(itemID)
    if category == "weapon" then
        return rules.weapon[subClassID] or false
    elseif category == "armor" and armorKind ~= "accessory" then
        return rules.armor[subClassID] or false
    elseif category == "armor" and subClassID and subClassID >= 7 then
        return rules.armor[subClassID] or false -- 圣契、神像、图腾
    end
    return true
end

-- 筛选：filter = { class = classFile 或 nil, category = "all"|"weapon"|"armor"|"other", armor = "all"|"cloth"|… }
function ItemFilter.Matches(itemID, filter)
    local category, armorKind = ItemFilter.Classify(itemID)
    if filter.category ~= "all" and filter.category ~= category then
        return false
    end
    if category == "armor" and filter.category == "armor" and filter.armor ~= "all" and filter.armor ~= armorKind then
        return false
    end
    return ItemFilter.Usable(itemID, filter.class)
end

-- 界面文字：职业名与物品类别名尽量用客户端自己的译名
function ItemFilter.ClassName(classFile)
    local names = LOCALIZED_CLASS_NAMES_MALE
    return names and names[classFile] or classFile
end

local function SubClassName(classID, subClassID, fallback)
    local name = C_Item and C_Item.GetItemSubClassInfo and C_Item.GetItemSubClassInfo(classID, subClassID)
    return type(name) == "string" and name or fallback
end

local function ClassName(classID, fallback)
    local name = C_Item and C_Item.GetItemClassInfo and C_Item.GetItemClassInfo(classID)
    return type(name) == "string" and name or fallback
end

function ItemFilter.CategoryItems()
    return {
        { id = "all", label = L["All"] },
        { id = "weapon", label = ClassName(WEAPON, L["Weapons"]) },
        { id = "armor", label = ClassName(ARMOR, L["Armor"]) },
        { id = "other", label = L["Other"] },
    }
end

function ItemFilter.ArmorItems()
    return {
        { id = "all", label = L["All"] },
        { id = "cloth", label = SubClassName(ARMOR, 1, L["Cloth"]) },
        { id = "leather", label = SubClassName(ARMOR, 2, L["Leather"]) },
        { id = "mail", label = SubClassName(ARMOR, 3, L["Mail"]) },
        { id = "plate", label = SubClassName(ARMOR, 4, L["Plate"]) },
        { id = "shield", label = SubClassName(ARMOR, 6, L["Shields"]) },
        { id = "accessory", label = L["Accessories"] },
    }
end
