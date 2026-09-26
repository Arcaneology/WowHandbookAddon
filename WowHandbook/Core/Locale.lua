local ADDON_NAME, ns = ...

-- 键就是英文原文：找不到翻译时直接回退为键本身，界面不会出现空白。
ns.locale = GetLocale()
ns.L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

-- 语言文件用它判断是否需要加载自己的翻译。
function ns:IsLocale(...)
    for i = 1, select("#", ...) do
        if self.locale == select(i, ...) then
            return true
        end
    end
    return false
end
