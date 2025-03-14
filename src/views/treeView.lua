-- 树木视图组件
local TreeView = {}
TreeView.__index = TreeView

function TreeView:new()
    local self = setmetatable({}, TreeView)
    return self
end

-- 绘制树木实体
function TreeView:draw(tree)
    -- 检查实体和游戏对象是否存在
    if not tree or not tree.game or not tree.game.map then
        print("错误: 无法绘制树木实体，树木实体或游戏地图不存在")
        return
    end
    
    local map = tree.game.map
    local screenX, screenY = map:tileToScreen(tree.x, tree.y)
    
    -- 绘制在瓦片中心
    screenX = screenX + map.tileSize / 2
    screenY = screenY + map.tileSize / 2
    
    -- 根据树木类型和生长阶段绘制不同的外观
    if tree.treeType == "oak" then
        self:drawOak(tree, screenX, screenY)
    elseif tree.treeType == "pine" then
        self:drawPine(tree, screenX, screenY)
    elseif tree.treeType == "fruit" then
        self:drawFruit(tree, screenX, screenY)
    elseif tree.treeType == "palm" then
        self:drawPalm(tree, screenX, screenY)
    end
end

function TreeView:drawOak(tree, x, y)
    -- 绘制橡树
    local size = tree.size
    local Tree = require("src.entities.tree") -- 导入Tree模块以访问常量
    
    -- 绘制树干
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", x - size/4, y - size/2, size/2, size)
    
    -- 绘制树冠
    love.graphics.setColor(tree.color)
    love.graphics.circle("fill", x, y - size/2, size)
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("line", x, y - size/2, size)
    
    -- 如果是果树且成熟，绘制果实
    if tree.treeType == "fruit" and 
       (tree.growthStage == Tree.GROWTH_STAGE.MATURE or tree.growthStage == Tree.GROWTH_STAGE.OLD) then
        love.graphics.setColor(0.9, 0.2, 0.2)
        for i = 1, 5 do
            local angle = math.random() * math.pi * 2
            local distance = math.random() * size * 0.8
            love.graphics.circle("fill", x + math.cos(angle) * distance, 
                                (y - size/2) + math.sin(angle) * distance, size/6)
        end
    end
end

function TreeView:drawPine(tree, x, y)
    -- 绘制松树
    local size = tree.size
    
    -- 绘制树干
    love.graphics.setColor(0.5, 0.3, 0.1)
    love.graphics.rectangle("fill", x - size/5, y - size/3, size/2.5, size)
    
    -- 绘制树冠（三角形）
    love.graphics.setColor(tree.color)
    
    -- 多层三角形
    local layers = 3
    for i = 1, layers do
        local layerSize = size * (1 - (i-1) * 0.2)
        local layerY = y - size/3 - (i-1) * size * 0.3
        
        love.graphics.polygon("fill", 
            x, layerY - layerSize,
            x - layerSize, layerY,
            x + layerSize, layerY
        )
    end
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0, 0.5)
    for i = 1, layers do
        local layerSize = size * (1 - (i-1) * 0.2)
        local layerY = y - size/3 - (i-1) * size * 0.3
        
        love.graphics.polygon("line", 
            x, layerY - layerSize,
            x - layerSize, layerY,
            x + layerSize, layerY
        )
    end
end

function TreeView:drawFruit(tree, x, y)
    -- 绘制果树
    local size = tree.size
    local Tree = require("src.entities.tree") -- 导入Tree模块以访问常量
    
    -- 绘制树干
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", x - size/4, y - size/2, size/2, size)
    
    -- 绘制树冠
    love.graphics.setColor(tree.color)
    love.graphics.circle("fill", x, y - size/2, size)
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("line", x, y - size/2, size)
    
    -- 如果成熟，绘制果实
    if tree.growthStage == Tree.GROWTH_STAGE.MATURE or tree.growthStage == Tree.GROWTH_STAGE.OLD then
        love.graphics.setColor(0.9, 0.2, 0.2)
        for i = 1, 5 do
            local angle = math.random() * math.pi * 2
            local distance = math.random() * size * 0.8
            love.graphics.circle("fill", x + math.cos(angle) * distance, 
                                (y - size/2) + math.sin(angle) * distance, size/6)
        end
    end
end

function TreeView:drawPalm(tree, x, y)
    -- 绘制棕榈树
    local size = tree.size
    
    -- 绘制树干（弯曲）
    love.graphics.setColor(0.7, 0.5, 0.3)
    
    -- 弯曲的树干
    local trunkWidth = size/4
    local trunkHeight = size * 1.2
    local curve = size/3
    
    -- 使用多个点绘制弯曲的树干
    local points = {}
    for i = 0, 10 do
        local t = i / 10
        local px = x + curve * math.sin(t * math.pi/2)
        local py = y - t * trunkHeight
        table.insert(points, px - trunkWidth/2)
        table.insert(points, py)
        table.insert(points, px + trunkWidth/2)
        table.insert(points, py)
    end
    
    love.graphics.polygon("fill", unpack(points))
    
    -- 绘制棕榈叶
    love.graphics.setColor(tree.color)
    local leafCount = 5
    for i = 1, leafCount do
        local angle = (i - 1) * (2 * math.pi / leafCount)
        local leafLength = size * 1.2
        local leafWidth = size/2
        
        -- 叶子的起点
        local startX = x + curve
        local startY = y - trunkHeight
        
        -- 叶子的终点
        local endX = startX + math.cos(angle) * leafLength
        local endY = startY + math.sin(angle) * leafLength
        
        -- 叶子的控制点（弯曲）
        local ctrlX = startX + math.cos(angle) * leafLength * 0.5
        local ctrlY = startY + math.sin(angle) * leafLength * 0.5
        
        -- 绘制叶子（简化为线段）
        love.graphics.setLineWidth(leafWidth)
        love.graphics.line(startX, startY, endX, endY)
        love.graphics.setLineWidth(1)
    end
    
    -- 如果是果树且成熟，绘制椰子
    local Tree = require("src.entities.tree") -- 导入Tree模块以访问常量
    if tree.growthStage == Tree.GROWTH_STAGE.MATURE or tree.growthStage == Tree.GROWTH_STAGE.OLD then
        love.graphics.setColor(0.6, 0.4, 0.2)
        for i = 1, 3 do
            local angle = math.random() * math.pi * 2
            local distance = size/4
            love.graphics.circle("fill", 
                                (x + curve) + math.cos(angle) * distance, 
                                (y - trunkHeight) + math.sin(angle) * distance, 
                                size/5)
        end
    end
end

return TreeView 