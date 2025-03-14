-- 人类实体
local Human = {}
Human.__index = Human

-- 人类状态
Human.STATE = {
    IDLE = "idle",
    MOVING = "moving",
    GATHERING = "gathering",
    BUILDING = "building",
    FARMING = "farming",
    RESTING = "resting"
}

-- 人类职业
Human.JOB = {
    NONE = "none",
    GATHERER = "gatherer",
    BUILDER = "builder",
    FARMER = "farmer",
    SCHOLAR = "scholar",
    PRIEST = "priest"
}

function Human:new(game, id, x, y, properties)
    properties = properties or {}
    
    local self = setmetatable({}, Human)
    
    self.game = game
    self.id = id
    self.type = "human"
    self.x = x
    self.y = y
    
    -- 基本属性
    self.name = properties.name or "村民" .. id
    self.health = properties.health or 100
    self.hunger = properties.hunger or 0
    self.age = properties.age or 0
    self.job = properties.job or Human.JOB.NONE
    
    -- 状态
    self.state = Human.STATE.IDLE
    self.stateTimer = 0
    self.targetX = nil
    self.targetY = nil
    self.targetEntity = nil
    self.inventory = {}
    
    -- 移动属性
    self.movementSpeed = properties.movementSpeed or 1.5  -- 每秒移动的格子数
    self.realX = x  -- 实际X坐标（浮点数）
    self.realY = y  -- 实际Y坐标（浮点数）
    
    -- AI属性
    self.needsFood = false
    self.needsRest = false
    self.taskPriority = {}
    
    -- 外观
    self.color = properties.color or {0.8, 0.2, 0.2}
    self.size = properties.size or 10
    
    -- 初始化任务优先级
    self:initTaskPriority()
    
    print("人类实体创建成功: ID=" .. id .. ", 位置=(" .. x .. ", " .. y .. ")")
    
    return self
end

function Human:initTaskPriority()
    -- 设置默认任务优先级
    self.taskPriority = {
        {task = "findFood", priority = 10, condition = function() return self.hunger > 50 end},
        {task = "buildHouse", priority = 5, condition = function() return true end},
        {task = "gatherResources", priority = 7, condition = function() return true end},
        {task = "farmFood", priority = 6, condition = function() return true end},
        {task = "explore", priority = 1, condition = function() return true end}
    }
end

function Human:update(dt)
    -- 更新状态计时器
    self.stateTimer = self.stateTimer + dt
    
    -- 更新饥饿度
    self.hunger = math.min(100, self.hunger + 0.01 * dt)
    
    -- 如果饥饿度过高，减少健康值
    if self.hunger > 80 then
        self.health = math.max(0, self.health - 0.05 * dt)
    end
    
    -- 如果健康值为0，死亡
    if self.health <= 0 then
        if self.game and self.game.removeEntity then
            self.game:removeEntity(self)
        end
        return
    end
    
    -- 根据当前状态执行行为
    if self.state == Human.STATE.IDLE then
        -- 空闲状态，寻找新任务
        if self.stateTimer > 1.0 then
            self:findNewTask()
            self.stateTimer = 0
        end
    elseif self.state == Human.STATE.MOVING then
        -- 移动状态，向目标移动
        self:moveToTarget(dt)
    elseif self.state == Human.STATE.GATHERING then
        -- 收集资源状态
        self:gatherResources(dt)
    elseif self.state == Human.STATE.BUILDING then
        -- 建造状态
        self:buildStructure(dt)
    elseif self.state == Human.STATE.FARMING then
        -- 耕种状态
        self:farmCrops(dt)
    elseif self.state == Human.STATE.RESTING then
        -- 休息状态
        self:rest(dt)
    end
end

function Human:updateAI()
    -- 更新需求状态
    self.needsFood = self.hunger > 50
    self.needsRest = self.health < 70
    
    -- 如果有紧急需求，中断当前任务
    if self.needsFood and self.state ~= Human.STATE.GATHERING then
        self:findFood()
    elseif self.needsRest and self.state ~= Human.STATE.RESTING then
        self:findRestPlace()
    end
end

function Human:findNewTask()
    -- 根据优先级选择任务
    local highestPriority = -1
    local selectedTask = nil
    
    for _, task in ipairs(self.taskPriority) do
        if task.condition() and task.priority > highestPriority then
            highestPriority = task.priority
            selectedTask = task.task
        end
    end
    
    -- 执行选定的任务
    if selectedTask == "findFood" then
        self:findFood()
    elseif selectedTask == "buildHouse" then
        self:findBuildingSpot()
    elseif selectedTask == "gatherResources" then
        self:findResources()
    elseif selectedTask == "farmFood" then
        self:findFarmingSpot()
    elseif selectedTask == "explore" then
        self:exploreMap()
    else
        -- 默认行为：随机移动
        self:randomMove()
    end
end

function Human:findFood()
    -- 寻找食物来源（农田、树等）
    if not self.game or not self.game.entityManager then
        self:randomMove()
        return
    end
    
    local foodSource = self.game.entityManager:getClosestEntity(self.x, self.y, "plant", 10)
    
    if foodSource then
        -- 找到食物来源，移动过去
        self.targetX = foodSource.x
        self.targetY = foodSource.y
        self.targetEntity = foodSource
        self.state = Human.STATE.MOVING
    else
        -- 没有找到食物，尝试找农田
        local farm = nil
        if self.game and self.game.map then
            for y = 1, self.game.map.height do
                for x = 1, self.game.map.width do
                    local tile = self.game.map:getTile(x, y)
                    if tile and tile.type == self.game.map.TILE_TYPES.FARM then
                        farm = {x = x, y = y}
                        break
                    end
                end
                if farm then break end
            end
        end
        
        if farm then
            -- 找到农田，移动过去
            self.targetX = farm.x
            self.targetY = farm.y
            self.state = Human.STATE.MOVING
        else
            -- 没有找到食物来源，随机移动
            self:randomMove()
        end
    end
end

function Human:findResources()
    -- 寻找资源（树、石头等）
    if not self.game or not self.game.entityManager then
        self:randomMove()
        return
    end
    
    local resource = self.game.entityManager:getClosestEntity(self.x, self.y, "tree", 10)
    
    if resource then
        -- 找到资源，移动过去
        self.targetX = resource.x
        self.targetY = resource.y
        self.targetEntity = resource
        self.state = Human.STATE.MOVING
    else
        -- 没有找到资源，随机移动
        self:randomMove()
    end
end

function Human:findBuildingSpot()
    -- 寻找建造房屋的位置
    if not self.game or not self.game.map then
        self:randomMove()
        return
    end
    
    -- 简单策略：在附近找一个空地
    local maxRadius = 10
    local buildingSpot = nil
    
    for radius = 1, maxRadius do
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    local x = self.x + dx
                    local y = self.y + dy
                    
                    local tile = self.game.map:getTile(x, y)
                    if tile and tile.type == self.game.map.TILE_TYPES.EMPTY then
                        -- 检查是否已有建筑
                        local entities = self.game.entityManager:getEntitiesAt(x, y)
                        local hasBuilding = false
                        
                        for _, entity in ipairs(entities) do
                            if entity.type == "building" then
                                hasBuilding = true
                                break
                            end
                        end
                        
                        if not hasBuilding then
                            buildingSpot = {x = x, y = y}
                            break
                        end
                    end
                end
            end
            if buildingSpot then break end
        end
        if buildingSpot then break end
    end
    
    if buildingSpot then
        -- 找到建造位置，移动过去
        self.targetX = buildingSpot.x
        self.targetY = buildingSpot.y
        self.state = Human.STATE.MOVING
    else
        -- 没有找到建造位置，随机移动
        self:randomMove()
    end
end

function Human:findFarmingSpot()
    -- 寻找耕种的位置
    if not self.game or not self.game.map then
        self:randomMove()
        return
    end
    
    -- 先检查是否已有农田
    local farm = nil
    for y = 1, self.game.map.height do
        for x = 1, self.game.map.width do
            local tile = self.game.map:getTile(x, y)
            if tile and tile.type == self.game.map.TILE_TYPES.FARM then
                -- 检查是否已有植物
                local entities = self.game.entityManager:getEntitiesAt(x, y)
                local hasPlant = false
                
                for _, entity in ipairs(entities) do
                    if entity.type == "plant" then
                        hasPlant = true
                        break
                    end
                end
                
                if not hasPlant then
                    farm = {x = x, y = y}
                    break
                end
            end
        end
        if farm then break end
    end
    
    if farm then
        -- 找到农田，移动过去
        self.targetX = farm.x
        self.targetY = farm.y
        self.state = Human.STATE.MOVING
    else
        -- 没有找到农田，寻找可以建造农田的位置
        local farmSpot = nil
        
        for y = 1, self.game.map.height do
            for x = 1, self.game.map.width do
                local tile = self.game.map:getTile(x, y)
                if tile and tile.type == self.game.map.TILE_TYPES.GRASS then
                    -- 检查是否已有实体
                    local entities = self.game.entityManager:getEntitiesAt(x, y)
                    if #entities == 0 then
                        farmSpot = {x = x, y = y}
                        break
                    end
                end
            end
            if farmSpot then break end
        end
        
        if farmSpot then
            -- 找到建造农田的位置，移动过去
            self.targetX = farmSpot.x
            self.targetY = farmSpot.y
            self.state = Human.STATE.MOVING
        else
            -- 没有找到建造农田的位置，随机移动
            self:randomMove()
        end
    end
end

function Human:exploreMap()
    -- 探索地图
    self:randomMove()
end

function Human:randomMove()
    -- 随机移动
    if not self.game or not self.game.map then
        return
    end
    
    local directions = {
        {dx = 0, dy = -1}, -- 上
        {dx = 1, dy = 0},  -- 右
        {dx = 0, dy = 1},  -- 下
        {dx = -1, dy = 0}  -- 左
    }
    
    -- 随机打乱方向
    for i = #directions, 2, -1 do
        local j = math.random(i)
        directions[i], directions[j] = directions[j], directions[i]
    end
    
    -- 检查每个方向
    for _, dir in ipairs(directions) do
        local newX = self.x + dir.dx
        local newY = self.y + dir.dy
        
        -- 检查是否是有效的位置
        local tile = self.game.map:getTile(newX, newY)
        if tile and tile.type ~= self.game.map.TILE_TYPES.WATER and
                   tile.type ~= self.game.map.TILE_TYPES.MOUNTAIN then
            -- 设置目标位置
            self.targetX = newX
            self.targetY = newY
            self.state = Human.STATE.MOVING
            return
        end
    end
end

function Human:moveToTarget(dt)
    -- 向目标移动
    if not self.targetX or not self.targetY then
        self.state = Human.STATE.IDLE
        return
    end
    
    -- 检查是否已到达目标(基于整数网格坐标)
    if math.abs(self.realX - self.targetX) < 0.1 and math.abs(self.realY - self.targetY) < 0.1 then
        -- 同步网格坐标
        self.x = self.targetX
        self.y = self.targetY
        self.realX = self.targetX
        self.realY = self.targetY
        
        -- 到达目标，执行相应行为
        if self.targetEntity then
            if self.targetEntity.type == "plant" then
                self.state = Human.STATE.GATHERING
            elseif self.targetEntity.type == "tree" then
                self.state = Human.STATE.GATHERING
            else
                self.state = Human.STATE.IDLE
            end
        else
            -- 根据目标位置的地形决定行为
            local tile = self.game.map:getTile(self.x, self.y)
            if tile then
                if tile.type == self.game.map.TILE_TYPES.FARM then
                    self.state = Human.STATE.FARMING
                elseif tile.type == self.game.map.TILE_TYPES.EMPTY then
                    self.state = Human.STATE.BUILDING
                else
                    self.state = Human.STATE.IDLE
                end
            else
                self.state = Human.STATE.IDLE
            end
        end
        
        self.stateTimer = 0
        return
    end
    
    -- 计算移动方向和距离
    local dirX = 0
    local dirY = 0
    
    -- 计算目标方向
    if self.targetX > self.realX then
        dirX = 1
    elseif self.targetX < self.realX then
        dirX = -1
    end
    
    if self.targetY > self.realY then
        dirY = 1
    elseif self.targetY < self.realY then
        dirY = -1
    end
    
    -- 更新实际位置（平滑移动）
    local moveDistance = self.movementSpeed * dt
    local nextX = self.realX
    local nextY = self.realY
    local moved = false
    
    -- 检查路径并移动
    if dirX ~= 0 then
        -- 计算下一步位置
        local targetGridX = math.floor(self.realX) + (dirX > 0 and 1 or 0)
        nextX = self.realX + dirX * moveDistance
        
        -- 检查是否越过了目标
        if (dirX > 0 and nextX > self.targetX) or (dirX < 0 and nextX < self.targetX) then
            nextX = self.targetX
        end
        
        -- 检查新位置是否可通行
        local newGridX = math.floor(nextX + (dirX > 0 and 0.1 or 0.9))
        if newGridX ~= math.floor(self.realX + 0.5) then
            -- 需要检查是否可以进入新格子
            local nextTile = self.game.map:getTile(newGridX, math.floor(self.realY + 0.5))
            if not nextTile or nextTile.type == self.game.map.TILE_TYPES.WATER or
                        nextTile.type == self.game.map.TILE_TYPES.MOUNTAIN then
                -- 不可通行，保持在当前格子边缘
                if dirX > 0 then
                    nextX = math.floor(self.realX) + 0.99
                else
                    nextX = math.floor(self.realX + 1) - 0.99
                end
            else
                moved = true
            end
        else
            moved = true
        end
        
        -- 更新实际X坐标
        self.realX = nextX
        -- 更新网格坐标
        self.x = math.floor(self.realX + 0.5)
    end
    
    if dirY ~= 0 then
        -- 计算下一步位置
        local targetGridY = math.floor(self.realY) + (dirY > 0 and 1 or 0)
        nextY = self.realY + dirY * moveDistance
        
        -- 检查是否越过了目标
        if (dirY > 0 and nextY > self.targetY) or (dirY < 0 and nextY < self.targetY) then
            nextY = self.targetY
        end
        
        -- 检查新位置是否可通行
        local newGridY = math.floor(nextY + (dirY > 0 and 0.1 or 0.9))
        if newGridY ~= math.floor(self.realY + 0.5) then
            -- 需要检查是否可以进入新格子
            local nextTile = self.game.map:getTile(math.floor(self.realX + 0.5), newGridY)
            if not nextTile or nextTile.type == self.game.map.TILE_TYPES.WATER or
                        nextTile.type == self.game.map.TILE_TYPES.MOUNTAIN then
                -- 不可通行，保持在当前格子边缘
                if dirY > 0 then
                    nextY = math.floor(self.realY) + 0.99
                else
                    nextY = math.floor(self.realY + 1) - 0.99
                end
            else
                moved = true
            end
        else
            moved = true
        end
        
        -- 更新实际Y坐标
        self.realY = nextY
        -- 更新网格坐标
        self.y = math.floor(self.realY + 0.5)
    end
    
    -- 如果无法移动，尝试重新寻找路径
    if not moved then
        self:randomMove()
    end
end

function Human:gatherResources(dt)
    -- 收集资源
    if not self.targetEntity then
        self.state = Human.STATE.IDLE
        return
    end
    
    -- 收集时间
    if self.stateTimer >= 3.0 then
        -- 收集完成
        if self.targetEntity.type == "plant" then
            -- 收集植物资源
            local value = self.targetEntity:getHarvestValue()
            if value then
                self.game.resourceManager:addResource("food", value.food)
            end
            
            -- 移除植物
            self.game:removeEntity(self.targetEntity)
        elseif self.targetEntity.type == "tree" then
            -- 收集树木资源
            local value = self.targetEntity:getHarvestValue()
            if value then
                self.game.resourceManager:addResource("wood", value.wood)
                if value.food > 0 then
                    self.game.resourceManager:addResource("food", value.food)
                end
            end
            
            -- 移除树木
            self.game:removeEntity(self.targetEntity)
        end
        
        -- 重置状态
        self.targetEntity = nil
        self.state = Human.STATE.IDLE
        self.stateTimer = 0
    end
end

function Human:buildStructure(dt)
    -- 建造结构
    if self.stateTimer >= 5.0 then
        -- 建造完成
        local tile = self.game.map:getTile(self.x, self.y)
        if tile and tile.type == self.game.map.TILE_TYPES.EMPTY then
            -- 将空地变为房屋
            self.game.map:setTile(self.x, self.y, self.game.map.TILE_TYPES.HOUSE)
            
            -- 增加人口上限
            self.game.resourceManager:increaseResourceLimit("population", 5)
        end
        
        -- 重置状态
        self.state = Human.STATE.IDLE
        self.stateTimer = 0
    end
end

function Human:farmCrops(dt)
    -- 耕种
    if self.stateTimer >= 4.0 then
        -- 耕种完成
        local tile = self.game.map:getTile(self.x, self.y)
        if tile and tile.type == self.game.map.TILE_TYPES.GRASS then
            -- 将草地变为农田
            self.game.map:setTile(self.x, self.y, self.game.map.TILE_TYPES.FARM)
        elseif tile and tile.type == self.game.map.TILE_TYPES.FARM then
            -- 在农田上种植作物
            local entities = self.game.entityManager:getEntitiesAt(self.x, self.y)
            local hasPlant = false
            
            for _, entity in ipairs(entities) do
                if entity.type == "plant" then
                    hasPlant = true
                    break
                end
            end
            
            if not hasPlant then
                -- 创建作物
                self.game:addEntity("plant", self.x, self.y, {
                    plantType = "crop"
                })
            end
        end
        
        -- 重置状态
        self.state = Human.STATE.IDLE
        self.stateTimer = 0
    end
end

function Human:rest(dt)
    -- 休息
    if self.stateTimer >= 3.0 then
        -- 休息完成，恢复健康
        self.health = math.min(100, self.health + 30)
        
        -- 重置状态
        self.state = Human.STATE.IDLE
        self.stateTimer = 0
    end
end

function Human:findRestPlace()
    -- 寻找休息的地方
    -- 简单实现：原地休息
    self.state = Human.STATE.RESTING
    self.stateTimer = 0
end

return Human 