-- 植物视图组件
local PlantView = {}
PlantView.__index = PlantView

function PlantView:new()
    local self = setmetatable({}, PlantView)
    return self
end

-- 绘制植物实体
function PlantView:draw(plant)
    -- 检查实体和游戏对象是否存在
    if not plant or not plant.game or not plant.game.map then
        print("错误: 无法绘制植物实体，植物实体或游戏地图不存在")
        return
    end
    
    local map = plant.game.map
    local screenX, screenY = map:tileToScreen(plant.x, plant.y)
    
    -- 绘制在瓦片中心
    screenX = screenX + map.tileSize / 2
    screenY = screenY + map.tileSize / 2
    
    -- 根据植物类型和生长阶段绘制不同的外观
    love.graphics.setColor(plant.color)
    
    if plant.plantType == "crop" then
        self:drawCrop(plant, screenX, screenY)
    elseif plant.plantType == "berry" then
        self:drawBerry(plant, screenX, screenY)
    elseif plant.plantType == "flower" then
        self:drawFlower(plant, screenX, screenY)
    elseif plant.plantType == "grass" then
        self:drawGrass(plant, screenX, screenY)
    end
end

function PlantView:drawCrop(plant, x, y)
    -- 绘制作物
    local size = plant.size
    local Plant = require("src.entities.plant") -- 导入Plant模块以访问常量
    
    if plant.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.circle("fill", x, y, size)
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
    elseif plant.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.3, 0.7, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
        love.graphics.circle("fill", x, y - size * 2, size / 2)
    elseif plant.growthStage == Plant.GROWTH_STAGE.MATURE then
        -- 成熟
        love.graphics.setColor(0.3, 0.7, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
        love.graphics.setColor(0.9, 0.8, 0.1)
        love.graphics.circle("fill", x, y - size * 2, size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.7, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.setColor(0.6, 0.5, 0.1)
        love.graphics.circle("fill", x, y - size * 1.5, size / 2)
    end
end

function PlantView:drawBerry(plant, x, y)
    -- 绘制浆果
    local size = plant.size
    local Plant = require("src.entities.plant") -- 导入Plant模块以访问常量
    
    if plant.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.circle("fill", x, y, size)
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.circle("fill", x - size/2, y - size, size / 2)
        love.graphics.circle("fill", x + size/2, y - size, size / 2)
    elseif plant.growthStage == Plant.GROWTH_STAGE.MATURE then
        -- 成熟
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.setColor(0.8, 0.2, 0.3)
        love.graphics.circle("fill", x - size/2, y - size, size / 2)
        love.graphics.circle("fill", x + size/2, y - size, size / 2)
        love.graphics.circle("fill", x, y - size * 1.5, size / 2)
    elseif plant.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.6, 0.5, 0.1)
        love.graphics.line(x, y, x, y - size)
        love.graphics.setColor(0.5, 0.2, 0.2)
        love.graphics.circle("fill", x, y - size, size / 3)
    end
end

function PlantView:drawFlower(plant, x, y)
    -- 绘制花朵
    local size = plant.size
    local Plant = require("src.entities.plant") -- 导入Plant模块以访问常量
    
    if plant.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.circle("fill", x, y, size)
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
        love.graphics.setColor(0.7, 0.5, 0.8)
        love.graphics.circle("fill", x, y - size * 2, size / 2)
    elseif plant.growthStage == Plant.GROWTH_STAGE.MATURE then
        -- 成熟
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
        
        -- 绘制花瓣
        love.graphics.setColor(0.8, 0.6, 0.9)
        local petalCount = 5
        local petalSize = size * 0.8
        for i = 1, petalCount do
            local angle = (i - 1) * (2 * math.pi / petalCount)
            local px = x + math.cos(angle) * petalSize
            local py = (y - size * 2) + math.sin(angle) * petalSize
            love.graphics.circle("fill", px, py, size / 2)
        end
        
        -- 绘制花蕊
        love.graphics.setColor(0.9, 0.9, 0.1)
        love.graphics.circle("fill", x, y - size * 2, size / 3)
    elseif plant.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.6, 0.5, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.setColor(0.6, 0.5, 0.6)
        love.graphics.circle("fill", x, y - size * 1.5, size / 2)
    end
end

function PlantView:drawGrass(plant, x, y)
    -- 绘制草
    local size = plant.size
    local Plant = require("src.entities.plant") -- 导入Plant模块以访问常量
    
    if plant.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.line(x, y, x, y - size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.4, 0.7, 0.2)
        love.graphics.line(x - size/2, y, x - size/2, y - size)
        love.graphics.line(x, y, x, y - size * 1.2)
        love.graphics.line(x + size/2, y, x + size/2, y - size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.MATURE then
        -- 成熟
        love.graphics.setColor(0.3, 0.7, 0.1)
        love.graphics.line(x - size, y, x - size/2, y - size * 1.5)
        love.graphics.line(x - size/2, y, x, y - size * 1.8)
        love.graphics.line(x, y, x + size/2, y - size * 1.5)
        love.graphics.line(x + size/2, y, x + size, y - size)
    elseif plant.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.7, 0.6, 0.1)
        love.graphics.line(x - size/2, y, x - size/4, y - size)
        love.graphics.line(x, y, x, y - size)
        love.graphics.line(x + size/2, y, x + size/4, y - size)
    end
end

return PlantView 