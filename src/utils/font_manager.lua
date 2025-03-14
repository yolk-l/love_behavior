-- 字体管理器
local FontManager = {}

-- 字体缓存
local fontCache = {}

-- 默认中文字体路径
local defaultChineseFontPath = "src/assets/fonts/simsun.ttc"

-- 获取字体，如果已经加载过则从缓存中获取
function FontManager.getFont(size, fontPath)
    fontPath = fontPath or defaultChineseFontPath
    local cacheKey = fontPath .. "_" .. tostring(size)

    if not fontCache[cacheKey] then
        -- 检查字体文件是否存在
        fontCache[cacheKey] = love.graphics.newFont(fontPath, size)
    end

    return fontCache[cacheKey]
end

-- 设置当前字体
function FontManager.setFont(size, fontPath)
    local fontData = FontManager.getFont(size, fontPath)
    love.graphics.setFont(fontData)
end

return FontManager 