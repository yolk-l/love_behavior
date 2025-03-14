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
    
    -- 调试标记
    self.hasDrawn = false
    
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

function Tree:draw()
    -- 只在第一次绘制时打印日志
    if not self.hasDrawn then
        print("绘制树木实体: ID=" .. self.id .. ", 类型=" .. self.treeType .. ", 位置=(" .. self.x .. ", " .. self.y .. ")")
        self.hasDrawn = true
    end
    
    -- 检查游戏对象和地图是否存在
    if not self.game or not self.game.map then
        print("错误: 无法绘制树木实体，游戏对象或地图不存在")
        return
    end
    
    local map = self.game.map
    local screenX, screenY = map:tileToScreen(self.x, self.y)
    
    -- 绘制在瓦片中心
    screenX = screenX + map.tileSize / 2
    screenY = screenY + map.tileSize / 2
    
    -- 根据树木类型和生长阶段绘制不同的外观
    if self.treeType == Tree.TYPE.OAK then
        self:drawOak(screenX, screenY)
    elseif self.treeType == Tree.TYPE.PINE then
        self:drawPine(screenX, screenY)
    elseif self.treeType == Tree.TYPE.FRUIT then
        self:drawFruit(screenX, screenY)
    elseif self.treeType == Tree.TYPE.PALM then
        self:drawPalm(screenX, screenY)
    end
end

function Tree:drawOak(x, y)
    -- 绘制橡树
    local size = self.size
    
    -- 绘制树干
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", x - size/4, y - size/2, size/2, size)
    
    -- 绘制树冠
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", x, y - size/2, size)
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("line", x, y - size/2, size)
    
    -- 如果是果树且成熟，绘制果实
    if self.treeType == Tree.TYPE.FRUIT and 
       (self.growthStage == Tree.GROWTH_STAGE.MATURE or self.growthStage == Tree.GROWTH_STAGE.OLD) then
        love.graphics.setColor(0.9, 0.2, 0.2)
        for i = 1, 5 do
            local angle = math.random() * math.pi * 2
            local distance = math.random() * size * 0.8
            love.graphics.circle("fill", x + math.cos(angle) * distance, 
                                (y - size/2) + math.sin(angle) * distance, size/6)
        end
    end
end

function Tree:drawPine(x, y)
    -- 绘制松树
    local size = self.size
    
    -- 绘制树干
    love.graphics.setColor(0.5, 0.3, 0.1)
    love.graphics.rectangle("fill", x - size/5, y - size/3, size/2.5, size)
    
    -- 绘制树冠（三角形）
    love.graphics.setColor(self.color)
    
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

function Tree:drawFruit(x, y)
    -- 绘制果树
    local size = self.size
    
    -- 绘制树干
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", x - size/4, y - size/2, size/2, size)
    
    -- 绘制树冠
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", x, y - size/2, size)
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("line", x, y - size/2, size)
    
    -- 如果成熟，绘制果实
    if self.growthStage == Tree.GROWTH_STAGE.MATURE or self.growthStage == Tree.GROWTH_STAGE.OLD then
        love.graphics.setColor(0.9, 0.2, 0.2)
        for i = 1, 5 do
            local angle = math.random() * math.pi * 2
            local distance = math.random() * size * 0.8
            love.graphics.circle("fill", x + math.cos(angle) * distance, 
                                (y - size/2) + math.sin(angle) * distance, size/6)
        end
    end
end

function Tree:drawPalm(x, y)
    -- 绘制棕榈树
    local size = self.size
    
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
    love.graphics.setColor(self.color)
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
    if self.growthStage == Tree.GROWTH_STAGE.MATURE or self.growthStage == Tree.GROWTH_STAGE.OLD then
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

function Tree:tryReproduce()
    -- 尝试繁殖
    if not self.game or not self.game.map or not self.game.entityManager then
        return
    end
    
    -- 只有成熟的树木才能繁殖
    if self.growthStage ~= Tree.GROWTH_STAGE.MATURE then
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
                    tile.type == self.game.map.TILE_TYPES.FOREST) then
            
            -- 检查是否已有树木或其他实体
            local entities = self.game.entityManager:getEntitiesAt(newX, newY)
            local hasTree = false
            
            for _, entity in ipairs(entities) do
                if entity.type == "tree" or entity.type == "building" then
                    hasTree = true
                    break
                end
            end
            
            if not hasTree then
                -- 创建新树木
                self.game:addEntity("tree", newX, newY, {
                    treeType = self.treeType,
                    growthStage = Tree.GROWTH_STAGE.SAPLING,
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

function Tree:getHarvestValue()
    -- 返回收获价值
    local value = {
        wood = 0,
        food = 0
    }
    
    -- 根据生长阶段和树木类型确定收获价值
    if self.growthStage == Tree.GROWTH_STAGE.SAPLING then
        value.wood = self.woodValue * 0.2
    elseif self.growthStage == Tree.GROWTH_STAGE.YOUNG then
        value.wood = self.woodValue * 0.6
    elseif self.growthStage == Tree.GROWTH_STAGE.MATURE then
        value.wood = self.woodValue
        if self.treeType == Tree.TYPE.FRUIT then
            value.food = self.foodValue
        end
    elseif self.growthStage == Tree.GROWTH_STAGE.OLD then
        value.wood = self.woodValue * 1.2
        if self.treeType == Tree.TYPE.FRUIT then
            value.food = self.foodValue * 0.7
        end
    end
    
    return value
end

return Tree 