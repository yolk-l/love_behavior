-- 实体管理系统
local EntityManager = {}
EntityManager.__index = EntityManager

-- 导入实体类型
local Human = require("src.entities.human")
local Plant = require("src.entities.plant")
local Tree = require("src.entities.tree")

function EntityManager:new(game)
    local self = setmetatable({}, EntityManager)
    
    self.game = game
    self.entities = {} -- 所有实体
    self.nextEntityId = 1 -- 实体ID计数器
    self.entityGrid = {} -- 用于空间查询的网格
    self.gridCellSize = 5 -- 网格单元大小
    
    -- 调试标记
    self.debugMode = false
    
    print("实体管理器初始化成功")
    
    return self
end

function EntityManager:update(dt)
    -- 更新所有实体
    for id, entity in pairs(self.entities) do
        -- 检查实体是否有update方法
        if entity.update then
            entity:update(dt)
        end
    end
    
    -- 更新网格（如果实体移动了）
    self:updateGrid()
end

function EntityManager:draw()
    -- 绘制所有实体
    for id, entity in pairs(self.entities) do
        -- 检查实体是否有draw方法
        if entity.draw then
            entity:draw()
        end
    end
    
    -- 如果开启调试模式，绘制网格
    if self.debugMode then
        self:drawGrid()
    end
end

function EntityManager:addEntity(entityType, x, y, properties)
    -- 检查参数
    if not entityType or not x or not y then
        print("错误: 添加实体失败，参数不完整")
        return nil
    end
    
    -- 创建实体
    local entity = nil
    local id = self.nextEntityId
    
    if entityType == "human" then
        entity = Human:new(self.game, id, x, y, properties)
    elseif entityType == "plant" then
        entity = Plant:new(self.game, id, x, y, properties)
    elseif entityType == "tree" then
        entity = Tree:new(self.game, id, x, y, properties)
    else
        print("错误: 未知的实体类型: " .. entityType)
        return nil
    end
    
    -- 检查实体是否创建成功
    if not entity then
        print("错误: 创建实体失败，类型: " .. entityType)
        return nil
    end
    
    -- 添加到实体列表
    self.entities[id] = entity
    self.nextEntityId = self.nextEntityId + 1
    
    -- 添加到网格
    self:addToGrid(entity)
    
    print("成功添加实体: ID=" .. id .. ", 类型=" .. entityType .. ", 位置=(" .. x .. ", " .. y .. ")")
    
    return entity
end

function EntityManager:removeEntity(entity)
    -- 检查参数
    if not entity or not entity.id then
        print("错误: 移除实体失败，无效的实体")
        return false
    end
    
    -- 从网格中移除
    self:removeFromGrid(entity)
    
    -- 从实体列表中移除
    if self.entities[entity.id] then
        self.entities[entity.id] = nil
        print("成功移除实体: ID=" .. entity.id)
        return true
    else
        print("错误: 移除实体失败，找不到ID=" .. entity.id .. "的实体")
        return false
    end
end

function EntityManager:getEntity(id)
    return self.entities[id]
end

function EntityManager:getEntitiesAt(x, y)
    -- 获取指定位置的所有实体
    local entities = {}
    
    for id, entity in pairs(self.entities) do
        if entity.x == x and entity.y == y then
            table.insert(entities, entity)
        end
    end
    
    return entities
end

function EntityManager:getEntitiesInRadius(x, y, radius)
    -- 获取指定半径内的所有实体
    local entities = {}
    
    for id, entity in pairs(self.entities) do
        local dx = entity.x - x
        local dy = entity.y - y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance <= radius then
            table.insert(entities, entity)
        end
    end
    
    return entities
end

function EntityManager:getEntitiesByType(entityType)
    -- 获取指定类型的所有实体
    local entities = {}
    
    for id, entity in pairs(self.entities) do
        if entity.type == entityType then
            table.insert(entities, entity)
        end
    end
    
    return entities
end

function EntityManager:getClosestEntity(x, y, entityType, maxDistance)
    -- 获取最近的指定类型实体
    local closestEntity = nil
    local minDistance = maxDistance or math.huge
    
    for id, entity in pairs(self.entities) do
        if not entityType or entity.type == entityType then
            local dx = entity.x - x
            local dy = entity.y - y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < minDistance then
                minDistance = distance
                closestEntity = entity
            end
        end
    end
    
    return closestEntity
end

function EntityManager:getEntityCount()
    -- 获取实体总数
    local count = 0
    for _ in pairs(self.entities) do
        count = count + 1
    end
    return count
end

function EntityManager:getEntityCountByType(entityType)
    -- 获取指定类型的实体数量
    local count = 0
    for _, entity in pairs(self.entities) do
        if entity.type == entityType then
            count = count + 1
        end
    end
    return count
end

function EntityManager:getHumanCount()
    return self:getEntityCountByType("human")
end

function EntityManager:getPlantCount()
    return self:getEntityCountByType("plant")
end

function EntityManager:getTreeCount()
    return self:getEntityCountByType("tree")
end

-- 网格相关方法

function EntityManager:getGridCell(x, y)
    -- 获取网格单元坐标
    local gridX = math.floor(x / self.gridCellSize)
    local gridY = math.floor(y / self.gridCellSize)
    return gridX, gridY
end

function EntityManager:addToGrid(entity)
    -- 将实体添加到网格
    local gridX, gridY = self:getGridCell(entity.x, entity.y)
    
    -- 初始化网格单元（如果不存在）
    if not self.entityGrid[gridX] then
        self.entityGrid[gridX] = {}
    end
    
    if not self.entityGrid[gridX][gridY] then
        self.entityGrid[gridX][gridY] = {}
    end
    
    -- 添加实体到网格单元
    self.entityGrid[gridX][gridY][entity.id] = entity
end

function EntityManager:removeFromGrid(entity)
    -- 从网格中移除实体
    local gridX, gridY = self:getGridCell(entity.x, entity.y)
    
    if self.entityGrid[gridX] and self.entityGrid[gridX][gridY] then
        self.entityGrid[gridX][gridY][entity.id] = nil
    end
end

function EntityManager:updateGrid()
    -- 更新网格（重建）
    self.entityGrid = {}
    
    for id, entity in pairs(self.entities) do
        self:addToGrid(entity)
    end
end

function EntityManager:getEntitiesInGridCell(gridX, gridY)
    -- 获取网格单元中的所有实体
    if not self.entityGrid[gridX] or not self.entityGrid[gridX][gridY] then
        return {}
    end
    
    local entities = {}
    for id, entity in pairs(self.entityGrid[gridX][gridY]) do
        table.insert(entities, entity)
    end
    
    return entities
end

function EntityManager:getEntitiesInGridArea(startX, startY, endX, endY)
    -- 获取网格区域中的所有实体
    local entities = {}
    
    for gridX = startX, endX do
        for gridY = startY, endY do
            local cellEntities = self:getEntitiesInGridCell(gridX, gridY)
            for _, entity in ipairs(cellEntities) do
                table.insert(entities, entity)
            end
        end
    end
    
    return entities
end

function EntityManager:drawGrid()
    -- 绘制网格（调试用）
    love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
    
    local map = self.game.map
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 计算屏幕上可见的网格范围
    local startX = math.floor(map.offsetX / (self.gridCellSize * map.tileSize))
    local startY = math.floor(map.offsetY / (self.gridCellSize * map.tileSize))
    local endX = startX + math.ceil(screenWidth / (self.gridCellSize * map.tileSize))
    local endY = startY + math.ceil(screenHeight / (self.gridCellSize * map.tileSize))
    
    -- 绘制网格线
    for x = startX, endX do
        local screenX = x * self.gridCellSize * map.tileSize - map.offsetX
        love.graphics.line(screenX, 0, screenX, screenHeight)
    end
    
    for y = startY, endY do
        local screenY = y * self.gridCellSize * map.tileSize - map.offsetY
        love.graphics.line(0, screenY, screenWidth, screenY)
    end
    
    -- 绘制网格单元中的实体数量
    love.graphics.setColor(1, 1, 1, 0.7)
    for x = startX, endX do
        for y = startY, endY do
            if self.entityGrid[x] and self.entityGrid[x][y] then
                local count = 0
                for _ in pairs(self.entityGrid[x][y]) do
                    count = count + 1
                end
                
                if count > 0 then
                    local screenX = x * self.gridCellSize * map.tileSize - map.offsetX + self.gridCellSize * map.tileSize / 2
                    local screenY = y * self.gridCellSize * map.tileSize - map.offsetY + self.gridCellSize * map.tileSize / 2
                    love.graphics.print(count, screenX, screenY)
                end
            end
        end
    end
end

return EntityManager 