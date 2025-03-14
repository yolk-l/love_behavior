-- 植物实体
local Plant = {}
Plant.__index = Plant

-- 植物类型
Plant.TYPE = {
    CROP = "crop",
    BERRY = "berry",
    FLOWER = "flower",
    GRASS = "grass"
}

-- 植物生长阶段
Plant.GROWTH_STAGE = {
    SEED = "seed",
    SPROUT = "sprout",
    GROWING = "growing",
    MATURE = "mature",
    WITHERING = "withering"
}

function Plant:new(game, id, x, y, properties)
    properties = properties or {}
    
    local self = setmetatable({}, Plant)
    
    self.game = game
    self.id = id
    self.type = "plant"
    self.x = x
    self.y = y
    
    -- 基本属性
    self.plantType = properties.plantType or Plant.TYPE.CROP
    self.growthStage = properties.growthStage or Plant.GROWTH_STAGE.SEED
    self.growthRate = properties.growthRate or 1.0
    self.growthTime = 0
    self.maxAge = properties.maxAge or 60 -- 秒
    self.age = properties.age or 0
    self.reproductionRate = properties.reproductionRate or 0.1
    self.reproductionRadius = properties.reproductionRadius or 3
    self.reproductionTimer = 0
    
    -- 资源产出
    self.foodValue = properties.foodValue or 10
    self.woodValue = 0
    
    -- 外观
    self.color = self:getColorForType()
    self.size = self:getSizeForStage()
    
    -- 调试标记
    self.hasDrawn = false
    
    print("植物实体创建成功: ID=" .. id .. ", 类型=" .. self.plantType .. ", 位置=(" .. x .. ", " .. y .. ")")
    
    return self
end

function Plant:getColorForType()
    if self.plantType == Plant.TYPE.CROP then
        return {0.4, 0.8, 0.2}
    elseif self.plantType == Plant.TYPE.BERRY then
        return {0.8, 0.2, 0.4}
    elseif self.plantType == Plant.TYPE.FLOWER then
        return {0.8, 0.6, 0.9}
    elseif self.plantType == Plant.TYPE.GRASS then
        return {0.5, 0.8, 0.3}
    else
        return {0.4, 0.8, 0.2}
    end
end

function Plant:getSizeForStage()
    if self.growthStage == Plant.GROWTH_STAGE.SEED then
        return 2
    elseif self.growthStage == Plant.GROWTH_STAGE.SPROUT then
        return 4
    elseif self.growthStage == Plant.GROWTH_STAGE.GROWING then
        return 6
    elseif self.growthStage == Plant.GROWTH_STAGE.MATURE then
        return 8
    elseif self.growthStage == Plant.GROWTH_STAGE.WITHERING then
        return 7
    else
        return 5
    end
end

function Plant:update(dt)
    -- 更新生长时间
    self.growthTime = self.growthTime + dt * self.growthRate
    self.age = self.age + dt
    
    -- 更新生长阶段
    self:updateGrowthStage()
    
    -- 更新大小
    self.size = self:getSizeForStage()
    
    -- 如果是成熟阶段，尝试繁殖
    if self.growthStage == Plant.GROWTH_STAGE.MATURE then
        self.reproductionTimer = self.reproductionTimer + dt
        
        if self.reproductionTimer >= 10 then -- 每10秒尝试繁殖一次
            self:tryReproduce()
            self.reproductionTimer = 0
        end
    end
    
    -- 如果超过最大年龄，死亡
    if self.age >= self.maxAge then
        if self.game and self.game.removeEntity then
            self.game:removeEntity(self)
        end
    end
end

function Plant:updateGrowthStage()
    local growthProgress = self.age / self.maxAge
    
    if growthProgress < 0.1 then
        self.growthStage = Plant.GROWTH_STAGE.SEED
    elseif growthProgress < 0.3 then
        self.growthStage = Plant.GROWTH_STAGE.SPROUT
    elseif growthProgress < 0.6 then
        self.growthStage = Plant.GROWTH_STAGE.GROWING
    elseif growthProgress < 0.9 then
        self.growthStage = Plant.GROWTH_STAGE.MATURE
    else
        self.growthStage = Plant.GROWTH_STAGE.WITHERING
    end
end

function Plant:draw()
    -- 只在第一次绘制时打印日志
    if not self.hasDrawn then
        print("绘制植物实体: ID=" .. self.id .. ", 类型=" .. self.plantType .. ", 位置=(" .. self.x .. ", " .. self.y .. ")")
        self.hasDrawn = true
    end
    
    -- 检查游戏对象和地图是否存在
    if not self.game or not self.game.map then
        print("错误: 无法绘制植物实体，游戏对象或地图不存在")
        return
    end
    
    local map = self.game.map
    local screenX, screenY = map:tileToScreen(self.x, self.y)
    
    -- 绘制在瓦片中心
    screenX = screenX + map.tileSize / 2
    screenY = screenY + map.tileSize / 2
    
    -- 根据植物类型和生长阶段绘制不同的外观
    love.graphics.setColor(self.color)
    
    if self.plantType == Plant.TYPE.CROP then
        self:drawCrop(screenX, screenY)
    elseif self.plantType == Plant.TYPE.BERRY then
        self:drawBerry(screenX, screenY)
    elseif self.plantType == Plant.TYPE.FLOWER then
        self:drawFlower(screenX, screenY)
    elseif self.plantType == Plant.TYPE.GRASS then
        self:drawGrass(screenX, screenY)
    end
end

function Plant:drawCrop(x, y)
    -- 绘制作物
    local size = self.size
    
    if self.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif self.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.circle("fill", x, y, size)
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
    elseif self.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.3, 0.7, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
        love.graphics.circle("fill", x, y - size * 2, size / 2)
    elseif self.growthStage == Plant.GROWTH_STAGE.MATURE then
        -- 成熟
        love.graphics.setColor(0.3, 0.7, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
        love.graphics.setColor(0.9, 0.8, 0.1)
        love.graphics.circle("fill", x, y - size * 2, size)
    elseif self.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.7, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.setColor(0.6, 0.5, 0.1)
        love.graphics.circle("fill", x, y - size * 1.5, size / 2)
    end
end

function Plant:drawBerry(x, y)
    -- 绘制浆果
    local size = self.size
    
    if self.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif self.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.circle("fill", x, y, size)
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size)
    elseif self.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.circle("fill", x - size/2, y - size, size / 2)
        love.graphics.circle("fill", x + size/2, y - size, size / 2)
    elseif self.growthStage == Plant.GROWTH_STAGE.MATURE then
        -- 成熟
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.setColor(0.8, 0.2, 0.3)
        love.graphics.circle("fill", x - size/2, y - size, size / 2)
        love.graphics.circle("fill", x + size/2, y - size, size / 2)
        love.graphics.circle("fill", x, y - size * 1.5, size / 2)
    elseif self.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.6, 0.5, 0.1)
        love.graphics.line(x, y, x, y - size)
        love.graphics.setColor(0.5, 0.2, 0.2)
        love.graphics.circle("fill", x, y - size, size / 3)
    end
end

function Plant:drawFlower(x, y)
    -- 绘制花朵
    local size = self.size
    
    if self.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif self.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.circle("fill", x, y, size)
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size)
    elseif self.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.3, 0.6, 0.1)
        love.graphics.line(x, y, x, y - size * 2)
        love.graphics.setColor(0.7, 0.5, 0.8)
        love.graphics.circle("fill", x, y - size * 2, size / 2)
    elseif self.growthStage == Plant.GROWTH_STAGE.MATURE then
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
    elseif self.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.6, 0.5, 0.1)
        love.graphics.line(x, y, x, y - size * 1.5)
        love.graphics.setColor(0.6, 0.5, 0.6)
        love.graphics.circle("fill", x, y - size * 1.5, size / 2)
    end
end

function Plant:drawGrass(x, y)
    -- 绘制草
    local size = self.size
    
    if self.growthStage == Plant.GROWTH_STAGE.SEED then
        -- 种子
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", x, y, size)
    elseif self.growthStage == Plant.GROWTH_STAGE.SPROUT then
        -- 幼苗
        love.graphics.setColor(0.5, 0.8, 0.3)
        love.graphics.line(x, y, x, y - size)
    elseif self.growthStage == Plant.GROWTH_STAGE.GROWING then
        -- 生长中
        love.graphics.setColor(0.4, 0.7, 0.2)
        love.graphics.line(x - size/2, y, x - size/2, y - size)
        love.graphics.line(x, y, x, y - size * 1.2)
        love.graphics.line(x + size/2, y, x + size/2, y - size)
    elseif self.growthStage == Plant.GROWTH_STAGE.MATURE then
        -- 成熟
        love.graphics.setColor(0.3, 0.7, 0.1)
        love.graphics.line(x - size, y, x - size/2, y - size * 1.5)
        love.graphics.line(x - size/2, y, x, y - size * 1.8)
        love.graphics.line(x, y, x + size/2, y - size * 1.5)
        love.graphics.line(x + size/2, y, x + size, y - size)
    elseif self.growthStage == Plant.GROWTH_STAGE.WITHERING then
        -- 枯萎
        love.graphics.setColor(0.7, 0.6, 0.1)
        love.graphics.line(x - size/2, y, x - size/4, y - size)
        love.graphics.line(x, y, x, y - size)
        love.graphics.line(x + size/2, y, x + size/4, y - size)
    end
end

function Plant:tryReproduce()
    -- 尝试繁殖
    if not self.game or not self.game.map or not self.game.entityManager then
        return
    end
    
    -- 只有成熟的植物才能繁殖
    if self.growthStage ~= Plant.GROWTH_STAGE.MATURE then
        return
    end
    
    -- 随机决定是否繁殖
    if math.random() > self.reproductionRate then
        return
    end
    
    -- 在周围随机位置尝试繁殖
    local attempts = 5
    while attempts > 0 do
        -- 随机选择周围的位置
        local dx = math.random(-self.reproductionRadius, self.reproductionRadius)
        local dy = math.random(-self.reproductionRadius, self.reproductionRadius)
        local newX, newY = self.x + dx, self.y + dy
        
        -- 检查位置是否有效
        local tile = self.game.map:getTile(newX, newY)
        if tile and (tile.type == self.game.map.TILE_TYPES.GRASS or 
                    tile.type == self.game.map.TILE_TYPES.FARM) then
            
            -- 检查是否已有植物
            local entities = self.game.entityManager:getEntitiesAt(newX, newY)
            local hasPlant = false
            
            for _, entity in ipairs(entities) do
                if entity.type == "plant" or entity.type == "tree" then
                    hasPlant = true
                    break
                end
            end
            
            if not hasPlant then
                -- 创建新植物
                self.game:addEntity("plant", newX, newY, {
                    plantType = self.plantType,
                    growthStage = Plant.GROWTH_STAGE.SEED,
                    growthRate = self.growthRate * (0.9 + math.random() * 0.2), -- 略微变异
                    maxAge = self.maxAge * (0.9 + math.random() * 0.2), -- 略微变异
                    reproductionRate = self.reproductionRate * (0.9 + math.random() * 0.2) -- 略微变异
                })
                
                return -- 成功繁殖
            end
        end
        
        attempts = attempts - 1
    end
end

function Plant:getHarvestValue()
    -- 返回收获价值
    local value = {
        food = 0,
        wood = 0
    }
    
    -- 根据生长阶段和植物类型确定收获价值
    if self.growthStage == Plant.GROWTH_STAGE.MATURE then
        if self.plantType == Plant.TYPE.CROP then
            value.food = self.foodValue
        elseif self.plantType == Plant.TYPE.BERRY then
            value.food = self.foodValue * 0.8
        elseif self.plantType == Plant.TYPE.FLOWER then
            value.food = self.foodValue * 0.3
        elseif self.plantType == Plant.TYPE.GRASS then
            value.food = self.foodValue * 0.2
        end
    elseif self.growthStage == Plant.GROWTH_STAGE.GROWING then
        if self.plantType == Plant.TYPE.CROP then
            value.food = self.foodValue * 0.5
        elseif self.plantType == Plant.TYPE.BERRY then
            value.food = self.foodValue * 0.4
        elseif self.plantType == Plant.TYPE.FLOWER then
            value.food = self.foodValue * 0.1
        elseif self.plantType == Plant.TYPE.GRASS then
            value.food = self.foodValue * 0.1
        end
    elseif self.growthStage == Plant.GROWTH_STAGE.WITHERING then
        if self.plantType == Plant.TYPE.CROP then
            value.food = self.foodValue * 0.3
        elseif self.plantType == Plant.TYPE.BERRY then
            value.food = self.foodValue * 0.2
        else
            value.food = 0
        end
    end
    
    return value
end

return Plant 