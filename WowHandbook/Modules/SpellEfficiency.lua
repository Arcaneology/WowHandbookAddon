local ADDON_NAME, ns = ...
local L = ns.L

-- 技能效率：鼠标移到会造成伤害、又消耗法力的技能上时，按技能说明里的伤害、施法时间与法力消耗，
-- 在提示末尾给出每秒伤害（DPS）与每点法力伤害（DPM）。
-- 伤害数字取自客户端自己的技能说明（已含法术强度加成），所以只在说明里能读出伤害时才显示；
-- 读不出来就什么都不加，不猜。瞬发技能按公共冷却 1.5 秒算，引导技能按引导时间算。
local Module = ns:NewModule("SpellEfficiency")

local GLOBAL_COOLDOWN = 1.5
local MANA = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0

local seenTooltips = setmetatable({}, { __mode = "k" })
local hooked = false

local function Number(text)
    return tonumber((text:gsub(",", "")))
end

local function IsChineseClient()
    local locale = ns.clientLocale or (GetLocale and GetLocale())
    return locale == "zhCN" or locale == "zhTW"
end

--------------------------------------------------------------------------------
-- 读技能说明：返回 直接伤害均值、持续伤害总量、持续时间（秒）
--------------------------------------------------------------------------------

-- 英文：“14 to 20 Fire damage”“2 Fire damage over 4 sec”“5 damage every 3 sec for 12 sec”
local function ParseEnglish(text)
    local direct, dot, duration = 0, 0, 0
    local position = 1
    while true do
        local first, last, low = text:find("(%d[%d,]*)", position)
        if not first then
            break
        end
        position = last + 1
        local high
        local rangeFirst, rangeLast, rangeHigh = text:find("^ to (%d[%d,]*)", position)
        if rangeFirst then
            high, position = rangeHigh, rangeLast + 1
        end
        local rest = text:sub(position)
        -- 数字后面跟百分号的不是伤害，不会匹配下面的“伤害”写法
        if rest:find("^%s*%a*%s*[Dd]amage") then
            local value = high and (Number(low) + Number(high)) / 2 or Number(low)
            local tail = rest:match("^%s*%a*%s*[Dd]amage(.*)") or ""
            local over = tail:match("^%s+over (%d+) sec")
            local every, total = tail:match("^%s+every (%d+) sec for (%d+) sec")
            if over then
                dot, duration = dot + value, math.max(duration, tonumber(over))
            elseif tail:match("^%s+for (%d+) sec") then
                -- “X damage for 5 sec”：每秒一波
                local seconds = tonumber(tail:match("^%s+for (%d+) sec"))
                dot, duration = dot + value * seconds, math.max(duration, seconds)
            elseif every then
                dot = dot + value * (tonumber(total) / tonumber(every))
                duration = math.max(duration, tonumber(total))
            else
                direct = direct + value
            end
        end
    end
    return direct, dot, duration
end

-- 中文：“造成14到20点火焰伤害”“在4秒内造成额外2点火焰伤害”“每3秒造成5点伤害，持续12秒”
local function ParseChinese(text)
    local direct, dot, duration = 0, 0, 0
    local position = 1
    while true do
        local first, last, low = text:find("(%d[%d,]*)", position)
        if not first then
            break
        end
        local before = text:sub(math.max(1, first - 60), first - 1)
        position = last + 1
        local high
        local rangeFirst, rangeLast, rangeHigh = text:find("^到(%d[%d,]*)", position)
        if rangeFirst then
            high, position = rangeHigh, rangeLast + 1
        end
        local rest = text:sub(position)
        local damageAt = rest:find("伤害", 1, true)
        local gap = damageAt and rest:sub(1, damageAt - 1)
        -- 数字与“伤害”之间只允许“点”和伤害类型，不能跨过标点或别的数字
        if gap and #gap <= 18 and not gap:find("[%d%%,.]") and not gap:find("，", 1, true)
            and not gap:find("。", 1, true) and not gap:find("；", 1, true) and not gap:find("、", 1, true) then
            local value = high and (Number(low) + Number(high)) / 2 or Number(low)
            local over = before:match("在(%d+)秒内[^%d]*$")
            local every = before:match("每(%d+)秒[^%d]*$")
            local total = rest:match("伤害[^%d]-持续(%d+)秒")
            local afterDamage = rest:sub(damageAt + #"伤害")
            local perSecond = tonumber(afterDamage:match("^，持续(%d+)秒") or afterDamage:match("^,持续(%d+)秒")
                or afterDamage:match("^持续(%d+)秒"))
            if over then
                dot, duration = dot + value, math.max(duration, tonumber(over))
            elseif every and total then
                dot = dot + value * (tonumber(total) / tonumber(every))
                duration = math.max(duration, tonumber(total))
            elseif perSecond then
                -- 奥术飞弹这类：“造成100点伤害，持续5秒”是每秒一波，共 5 波
                dot, duration = dot + value * perSecond, math.max(duration, perSecond)
            elseif rest:match("^[^，。]-伤害，?持续(%d+)秒") then
                -- 奥术飞弹这类：“造成100点伤害，持续5秒”是每秒一波，共 5 波
                local seconds = tonumber(rest:match("^[^，。]-伤害，?持续(%d+)秒"))
                dot, duration = dot + value * seconds, math.max(duration, seconds)
            else
                direct = direct + value
            end
        end
    end
    return direct, dot, duration
end

function Module.Parse(text, chinese)
    if type(text) ~= "string" or ns.IsSecret(text) or text == "" then
        return 0, 0, 0
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[\r\n]+", " ")
    if chinese == nil then
        chinese = IsChineseClient()
    end
    return (chinese and ParseChinese or ParseEnglish)(text)
end

--------------------------------------------------------------------------------
-- 效率计算（不碰界面）：说明读出的伤害、施法时间（秒）、法力消耗
--------------------------------------------------------------------------------

-- channeled 为真时按持续时间当作引导时间；返回 nil 表示不适用
function Module.Compute(direct, dot, duration, castSeconds, mana, channeled)
    local total = (direct or 0) + (dot or 0)
    if total <= 0 or not mana or mana <= 0 then
        return nil
    end
    local seconds = castSeconds or 0
    if channeled and duration and duration > 0 then
        seconds = duration
    elseif seconds < GLOBAL_COOLDOWN then
        seconds = GLOBAL_COOLDOWN
    end
    return {
        total = total,
        seconds = seconds,
        mana = mana,
        dps = total / seconds,
        dpm = total / mana,
        instant = (castSeconds or 0) <= 0 and not channeled,
        channeled = channeled and true or false,
    }
end

--------------------------------------------------------------------------------
-- 向客户端取数据
--------------------------------------------------------------------------------

local function CastSeconds(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if type(info) == "table" and type(info.castTime) == "number" then
            return info.castTime / 1000
        end
    end
    if GetSpellInfo then
        local _, _, _, castTime = GetSpellInfo(spellID)
        if type(castTime) == "number" then
            return castTime / 1000
        end
    end
    return nil
end

local function ManaCost(spellID)
    local costs
    if C_Spell and C_Spell.GetSpellPowerCost then
        costs = C_Spell.GetSpellPowerCost(spellID)
    elseif GetSpellPowerCost then
        costs = GetSpellPowerCost(spellID)
    end
    if type(costs) ~= "table" then
        return nil
    end
    for _, cost in ipairs(costs) do
        if cost.type == MANA and type(cost.cost) == "number" and cost.cost > 0 then
            return cost.cost
        end
    end
    return nil
end

local function Description(spellID)
    if C_Spell and C_Spell.GetSpellDescription then
        return C_Spell.GetSpellDescription(spellID)
    end
    if GetSpellDescription then
        return GetSpellDescription(spellID)
    end
    return nil
end

-- 提示里有没有“引导”字样（施法时间一行）：英文 Channeled，中文 引导
local function IsChanneled(tooltip)
    local name = tooltip.GetName and tooltip:GetName()
    if not name then
        return false
    end
    for index = 1, 8 do
        for _, side in ipairs({ "TextLeft", "TextRight" }) do
            local line = _G[name .. side .. index]
            local text = line and line.GetText and line:GetText()
            if type(text) == "string" and not ns.IsSecret(text)
                and (text:find("引导", 1, true) or text:lower():find("channel", 1, true)) then
                return true
            end
        end
    end
    return false
end

function Module.Evaluate(spellID, channeled)
    if type(spellID) ~= "number" then
        return nil
    end
    local mana = ManaCost(spellID)
    if not mana then
        return nil
    end
    local direct, dot, duration = Module.Parse(Description(spellID))
    return Module.Compute(direct, dot, duration, CastSeconds(spellID), mana, channeled)
end

--------------------------------------------------------------------------------
-- 鼠标提示
--------------------------------------------------------------------------------

local function Format(value)
    return value >= 100 and ("%d"):format(value + 0.5) or ("%.1f"):format(value)
end

local function AddTooltip(tooltip, data)
    if not (Module.enabled and tooltip and tooltip.AddDoubleLine) then
        return
    end
    local spellID = data and data.id
    if ns.IsSecret(spellID) then
        return
    end
    if not spellID and tooltip.GetSpell then
        spellID = select(2, tooltip:GetSpell())
    end
    if type(spellID) ~= "number" or ns.IsSecret(spellID) then
        return
    end
    local token = data and data.dataInstanceID or spellID
    if seenTooltips[tooltip] == token then
        return
    end
    seenTooltips[tooltip] = token
    local result = Module.Evaluate(spellID, IsChanneled(tooltip))
    if not result then
        return
    end
    local colors = ns.Theme.colors
    local dim, text = colors.textDim, colors.text
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L["DPS"], Format(result.dps), colors.gold[1], colors.gold[2], colors.gold[3],
        text[1], text[2], text[3])
    tooltip:AddDoubleLine(L["DPM"], Format(result.dpm), colors.gold[1], colors.gold[2], colors.gold[3],
        text[1], text[2], text[3])
    local timing
    if result.channeled then
        timing = (L["channeled %s sec"]):format(Format(result.seconds))
    elseif result.instant then
        timing = (L["instant, %s sec global cooldown"]):format(Format(result.seconds))
    else
        timing = (L["cast %s sec"]):format(Format(result.seconds))
    end
    tooltip:AddLine((L["Damage %s, %s, mana %d"]):format(Format(result.total), timing, result.mana),
        dim[1], dim[2], dim[3], true)
    if tooltip.Show then
        tooltip:Show()
    end
end

local function HookTooltips()
    if hooked then
        return
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, AddTooltip)
        hooked = true
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetSpell", AddTooltip)
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

-- 测试用
Module.AddTooltip = AddTooltip
