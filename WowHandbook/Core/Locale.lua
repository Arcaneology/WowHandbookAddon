local ADDON_NAME, ns = ...

-- 键就是英文原文：找不到翻译时直接回退为键本身，界面不会出现空白。
-- 各语言文件用 ns:NewTranslation(语言) 登记自己的翻译表；ns.L 每次取值时按当前语言 ns.locale 查表，
-- 所以玩家在设置里切换界面语言（ns:ApplyLanguage）后，之后生成的文字都用新语言。
-- 存档要到全部文件加载完才可用，因此文件加载阶段一律用客户端语言；切换语言后重载界面生效。
ns.clientLocale = GetLocale()
ns.locale = ns.clientLocale
ns.translations = {}
ns.L = setmetatable({}, {
    __index = function(_, key)
        local translation = ns.translations[ns.locale]
        return translation and translation[key] or key
    end,
})

-- 插件界面支持的语言（设置页的选项）
ns.LANGUAGES = { "enUS", "zhCN" }

function ns:NewTranslation(locale)
    self.translations[locale] = self.translations[locale] or {}
    return self.translations[locale]
end

-- 按设置切换界面语言：auto（默认）跟随客户端，enUS / zhCN 为指定语言
function ns:ApplyLanguage(choice)
    self.locale = (choice == "enUS" or choice == "zhCN") and choice or self.clientLocale
end

-- 当前界面语言是否为给定语言之一
function ns:IsLocale(...)
    for i = 1, select("#", ...) do
        if self.locale == select(i, ...) then
            return true
        end
    end
    return false
end
