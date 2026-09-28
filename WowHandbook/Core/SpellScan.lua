local ADDON_NAME, ns = ...

-- 扫描玩家技能书：技能名（小写）-> { best = 最高等级数字, ids = { [等级数字] = spellID } }。
-- 等级数字取自技能副标题（英文 "Rank 3"、中文 "等级 3"）里的数字；没有等级的技能记为 0。
-- 技能书有变化时（SPELLS_CHANGED）清空缓存，下次使用时重新扫描。
local cache

local function RankNumber(subName)
    return tonumber(subName and subName:match("(%d+)")) or 0
end
ns.RankNumber = RankNumber

function ns.KnownSpells()
    if cache then
        return cache
    end
    cache = {}
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if info and not info.shouldHide then
            for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                if item and item.spellID and item.name then
                    local key = item.name:lower()
                    local rank = RankNumber(item.subName)
                    local entry = cache[key]
                    if not entry then
                        entry = { best = rank, ids = {}, passive = item.isPassive }
                        cache[key] = entry
                    end
                    entry.ids[rank] = item.spellID
                    if rank > entry.best then
                        entry.best = rank
                    end
                end
            end
        end
    end
    return cache
end

function ns.InvalidateKnownSpells()
    cache = nil
end

-- 缓存失效由核心负责，不依赖哪个显示模块开着。核心在所有模块之前订阅，
-- 同一事件里模块的处理函数读到的已经是失效后的缓存。
ns:RegisterEvent("SPELLS_CHANGED", ns.InvalidateKnownSpells)
ns:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE", ns.InvalidateKnownSpells)
