-- 树木实体
local Tree = {}
Tree.__index = Tree

-- 树木类型
Tree.TYPE = {
    OAK = "oak",
    PINE = "pine",
    FRUIT = "fruit",
    PALM = "palm"
}

-- 树木生长阶段
Tree.GROWTH_STAGE = {
    SAPLING = "sapling",
    YOUNG = "young",
    MATURE = "mature",
    OLD = "old"
}

function Tree:new(game, id, x, y, properties)
    properties = properties or {}
    
    local self = setmetatable({}, Tree)
    
    self.game = game
    self.id = id
    self.type = "tree"
    self.x = x
    self.y = y
    
    -- 基本属性
    self.treeType = properties.treeType or Tree.TYPE.OAK
    self.growthStage = properties.growthStage or Tree.GROWTH_STAGE.SAPLING
    self.growthRate = properties.growthRate or 0.5
    self.maxAge = properties.maxAge or 120 -- 秒
    self.age = properties.age or 0
    self.reproductionRate = properties.reproductionRate or 0.05
    self.reproductionRadius = properties.reproductionRadius or 5
    self.reproductionTimer = 0
    
    -- 资源产出
    self.woodValue = properties.woodValue or 20
    self.foodValue = properties.foodValue or (self.treeType == Tree.TYPE.FRUIT and 15 or 0)
    
    -- 外观
    self.color = self:getColorForType()
    self.size = self:getSizeForStage()
    
    print("树木实体创建成功: ID=" .. id .. ", 类型=" .. self.treeType .. ", 位置=(" .. x .. ", " .. y .. ")")
    
    return self
end

function Tree:getColorForType()
    if self.treeType == Tree.TYPE.OAK then
        return {0.3, 0.5, 0.1}
    elseif self.treeType == Tree.TYPE.PINE then
        return {0.1, 0.4, 0.2}
    elseif self.treeType == Tree.TYPE.FRUIT then
        return {0.4, 0.6, 0.1}
    elseif self.treeType == Tree.TYPE.PALM then
        return {0.5, 0.7, 0.2}
    else
        return {0.3, 0.5, 0.1}
    end
end

function Tree:getSizeForStage()
    if self.growthStage == Tree.GROWTH_STAGE.SAPLING then
        return 5
    elseif self.growthStage == Tree.GROWTH_STAGE.YOUNG then
        return 10
    elseif self.growthStage == Tree.GROWTH_STAGE.MATURE then
        return 15
    elseif self.growthStage == Tree.GROWTH_STAGE.OLD then
        return 18
    else
        return 10
    end
end

function Tree:update(dt)
    -- 更新树龄
    self.age = self.age + dt * self.growthRate
    
    -- 更新生长阶段
    self:updateGrowthStage()
    
    -- 更新大小
    self.size = self:getSizeForStage()
    
    -- 如果是成熟阶段，尝试繁殖
    if self.growthStage == Tree.GROWTH_STAGE.MATURE then
        self.reproductionTimer = self.reproductionTimer + dt
        
        if self.reproductionTimer >= 20 then -- 每20秒尝试繁殖一次
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

function Tree:updateGrowthStage()
    local growthProgress = self.age / self.maxAge
    
    if growthProgress < 0.2 then
        self.growthStage = Tree.GROWTH_STAGE.SAPLING
    elseif growthProgress < 0.5 then
        self.growthStage = Tree.GROWTH_STAGE.YOUNG
    elseif growthProgress < 0.8 then
        self.growthStage = Tree.GROWTH_STAGE.MATURE
    else
        self.growthStage = Tree.GROWTH_STAGE.OLD
    end
end

function Tree:tryReproduce()
    -- 尝试繁殖
    if not self.game or not self.game.map or not self.game.entityManager then
        return
    end
    
    -- 检查是否可以繁殖
    if math.random() > self.reproductionRate then
        return
    end
    
    -- 在周围随机位置尝试创建新树木
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
        if tile and (tile.type == self.game.map.TILE_TYPES.GRASS or tile.type == self.game.map.TILE_TYPES.FOREST) then
            -- 检查是否已有实体
            local entities = self.game.entityManager:getEntitiesAt(newX, newY)
            if #entities == 0 then
                -- 创建新树木
                self.game:addEntity("tree", newX, newY, {
                    treeType = self.treeType,
                    growthStage = Tree.GROWTH_STAGE.SAPLING,
                    age = 0
                })
                
                print("树木繁殖成功: 父树木ID=" .. self.id .. ", 位置=(" .. self.x .. ", " .. self.y .. "), 新树木位置=(" .. newX .. ", " .. newY .. ")")
                return
            end
        end
        
        attempts = attempts + 1
    end
end

function Tree:getHarvestValue()
    -- 获取收获价值
    local multiplier = 1.0
    
    if self.growthStage == Tree.GROWTH_STAGE.SAPLING then
        multiplier = 0.2
    elseif self.growthStage == Tree.GROWTH_STAGE.YOUNG then
        multiplier = 0.6
    elseif self.growthStage == Tree.GROWTH_STAGE.MATURE then
        multiplier = 1.0
    elseif self.growthStage == Tree.GROWTH_STAGE.OLD then
        multiplier = 0.8
    end
    
    return {
        wood = math.floor(self.woodValue * multiplier),
        food = math.floor(self.foodValue * multiplier)
    }
end

return Tree 