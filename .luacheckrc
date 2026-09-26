-- luacheck 配置：WoW 客户端 Lua 5.1 环境
std = "lua51"
max_line_length = 140
codes = true

exclude_files = {
    "WowHandbook/Libs/",
}

-- 采集插件（内部工具）额外允许的全局名
files["WowHandbook_Collector/"] = {
    globals = {
        "WowHandbookCollectorDB",
        "SLASH_WOWHANDBOOKCOLLECTOR1",
    },
}

-- 生成的目标清单每行一个条目，不限行长
files["WowHandbook_Collector/Targets.lua"] = { max_line_length = false }

-- 翻译表每行一条，不限行长
files["WowHandbook_Collector/Locale.lua"] = { max_line_length = false }
files["WowHandbook/Locales/"] = { max_line_length = false }
-- 生成的数据文件不限行长
files["WowHandbook/Data/"] = { max_line_length = false }

ignore = {
    "212/self",        -- 方法未使用 self 参数
    "432/self",        -- 控件构造方法里的脚本回调各有自己的 self
    "211/ADDON_NAME",  -- 每个文件统一取命名空间，未必用到插件名
}

-- 本插件允许写入的全局名
globals = {
    "WowHandbookDB",
    "WowHandbookCharDB",
    "SlashCmdList",
    "SLASH_WOWHANDBOOK1",
    "SLASH_WOWHANDBOOK2",
    "UISpecialFrames",
    "WowHandbookAPI",
}

-- 只读引用的暴雪 API 与界面对象（用到新的就补进来）
read_globals = {
    "C_ActionBar",
    "C_Spell",
    "C_SpellBook",
    "C_SuperTrack",
    "C_UI",
    "ClearCursor",
    "CreateFromMixins",
    "Enum",
    "GetActionInfo",
    "HandleModifiedItemClick",
    "HasAction",
    "MapCanvasDataProviderMixin",
    "MapCanvasPinMixin",
    "Mixin",
    "PlaceAction",
    "UiMapPoint",
    "UnitClass",
    "UnitCreatureFamily",
    "UnitFactionGroup",
    "UnitRace",
    "WorldMapFrame",
    "C_AddOns",
    "C_CVar",
    "C_Container",
    "C_GossipInfo",
    "C_MerchantFrame",
    "C_TaxiMap",
    "C_Item",
    "C_Map",
    "C_MapExplorationInfo",
    "C_QuestLog",
    "C_TaskQuest",
    "C_Timer",
    "C_TooltipInfo",
    "CreateFont",
    "CreateFrame",
    "date",
    "FauxScrollFrame_GetOffset",
    "FauxScrollFrame_OnVerticalScroll",
    "FauxScrollFrame_Update",
    "GameTooltip",
    "GameTooltip_Hide",
    "OpenWorldMap",
    "LOCALIZED_CLASS_NAMES_MALE",
    "FACTION_ALLIANCE",
    "FACTION_HORDE",
    "GetQuestDifficultyColor",
    "hooksecurefunc",
    "MAP_AREA_LABEL_TYPE",
    "QuestDifficultyColors",
    "RGBTableToColorCode",
    "UNDISCOVERED_FACTION_FLIGHTPOINT",
    "UNDISCOVERED_NEUTRAL_FLIGHTPOINT",
    "WHITE_FONT_COLOR",
    "geterrorhandler",
    "GetMoneyString",
    "floor",
    "GetBuildInfo",
    "GetCursorPosition",
    "GetInstanceInfo",
    "GetInventoryItemID",
    "GetMerchantItemID",
    "GetMerchantNumItems",
    "GetNumTrainerServices",
    "GetTaxiMapID",
    "GetTrainerServiceCost",
    "GetTrainerServiceInfo",
    "GetTrainerServiceTypeFilter",
    "SetTrainerServiceTypeFilter",
    "UnitCreatureType",
    "UnitExists",
    "UnitPlayerControlled",
    "UnitReaction",
    "GetLootSlotLink",
    "GetLootSourceInfo",
    "GetNumLootItems",
    "GetNumQuestChoices",
    "GetNumQuestItems",
    "GetNumQuestRewards",
    "GetObjectiveText",
    "GetProgressText",
    "GetQuestID",
    "GetQuestItemInfo",
    "GetQuestItemLink",
    "GetNumQuestLogChoices",
    "GetNumQuestLogRewards",
    "GetQuestLogChoiceInfo",
    "GetQuestLogQuestText",
    "GetQuestLogRewardInfo",
    "GetQuestLogRewardMoney",
    "GetQuestLogRewardXP",
    "HaveQuestRewardData",
    "GetQuestText",
    "GetRewardMoney",
    "GetRewardText",
    "GetRewardXP",
    "GetTime",
    "GetTitleText",
    "DEFAULT_CHAT_FRAME",
    "GetAddOnMetadata",
    "GetLocale",
    "InCombatLockdown",
    "PanelTemplates_SetTab",
    "PanelTemplates_TabResize",
    "RETRIEVING_ITEM_INFO",
    "strsplit",
    "IsControlKeyDown",
    "IsMacClient",
    "IsMetaKeyDown",
    "strtrim",
    "UIParent",
    "UnitGUID",
    "UnitName",
    "UnitClassification",
    "UnitIsPlayer",
    "UnitLevel",
    "time",
    "tinsert",
    "wipe",
}
