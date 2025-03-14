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

function Plant:tryReproduce()
    -- 尝试繁殖
    if not self.game or not self.game.map or not self.game.entityManager then
        return
    end
    
    -- 检查是否可以繁殖
    if math.random() > self.reproductionRate then
        return
    end
    
    -- 在周围随机位置尝试创建新植物
    local maxAttempts = 10
    local attempts = 0
    
    while attempts < maxAttempts do
        -- 生成随机方向和距离
        local angle = math.random() * math.pi * 2
        local distance = math.random(1, self.reproductionRadius)
        
        local newX = math.floor(self.x + math.cos(angle) * distance)
        local newY = math.floor(self.y + math.sin(angle) * distance)
        
        -- 检查是否是有效位置
        local tile = self.game.map:getTile(newX, newY)
        if tile and (tile.type == self.game.map.TILE_TYPES.GRASS or tile.type == self.game.map.TILE_TYPES.FARM) then
            -- 检查是否已有实体
            local entities = self.game.entityManager:getEntitiesAt(newX, newY)
            if #entities == 0 then
                -- 创建新植物
                self.game:addEntity("plant", newX, newY, {
                    plantType = self.plantType,
                    growthStage = Plant.GROWTH_STAGE.SEED,
                    age = 0
                })
                
                print("植物繁殖成功: 父植物ID=" .. self.id .. ", 位置=(" .. self.x .. ", " .. self.y .. "), 新植物位置=(" .. newX .. ", " .. newY .. ")")
                return
            end
        end
        
        attempts = attempts + 1
    end
end

function Plant:getHarvestValue()
    -- 获取收获价值
    local multiplier = 1.0
    
    if self.growthStage == Plant.GROWTH_STAGE.SEED then
        multiplier = 0.1
    elseif self.growthStage == Plant.GROWTH_STAGE.SPROUT then
        multiplier = 0.3
    elseif self.growthStage == Plant.GROWTH_STAGE.GROWING then
        multiplier = 0.7
    elseif self.growthStage == Plant.GROWTH_STAGE.MATURE then
        multiplier = 1.0
    elseif self.growthStage == Plant.GROWTH_STAGE.WITHERING then
        multiplier = 0.6
    end
    
    return {
        food = math.floor(self.foodValue * multiplier),
        wood = math.floor(self.woodValue * multiplier)
    }
end

return Plant 