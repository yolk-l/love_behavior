-- 游戏主类
local Game = {}
Game.__index = Game

-- 导入系统
local MapSystem = require("src.systems.map")
local EntityManager = require("src.systems.entity_manager")
local CardSystem = require("src.systems.card_system")
local ResourceManager = require("src.systems.resource_manager")
local UIManager = require("src.ui.ui_manager")
-- 导入视图管理器
local ViewManager = require("src.views.view_manager")

function Game:new()
    local self = setmetatable({}, Game)
    
    -- 初始化游戏状态
    self.running = true
    self.paused = false
    self.gameTime = 0
    self.dayTime = 0
    self.dayLength = 60 -- 一天的长度（秒）
    self.dayCount = 1
    
    -- 初始化系统
    self.map = MapSystem:new(self)
    self.entityManager = EntityManager:new(self)
    self.cardSystem = CardSystem:new(self)
    self.resourceManager = ResourceManager:new(self)
    self.uiManager = UIManager:new(self)
    -- 初始化视图管理器
    self.viewManager = ViewManager:new(self)
    
    -- 初始化游戏世界
    self:initWorld()
    
    -- 调试标记
    self.debugMode = false
    
    print("游戏初始化成功")
    
    return self
end

function Game:load()
    -- 加载游戏
    print("游戏加载中...")
    
    -- 重置游戏状态
    self.gameTime = 0
    self.dayTime = 0
    self.dayCount = 1
    self.paused = false
    
    -- 重新初始化游戏世界
    self:initWorld()
    
    print("游戏加载完成")
end

function Game:initWorld()
    -- 生成地图
    self.map:generateMap(50, 50)
    
    -- 初始化资源
    self.resourceManager:initResources()
    
    -- 初始化卡牌系统
    self.cardSystem:initCards()
    
    -- 添加初始实体
    self:addInitialEntities()
    
    print("游戏世界初始化成功")
end

function Game:addInitialEntities()
    -- 添加一些初始树木
    local treeCount = 20
    for i = 1, treeCount do
        local x, y = self:findSuitableLocation("tree")
        if x and y then
            local treeTypes = {"oak", "pine", "fruit", "palm"}
            local treeType = treeTypes[math.random(#treeTypes)]
            self:addEntity("tree", x, y, {treeType = treeType})
        end
    end
    
    -- 添加一些初始植物
    local plantCount = 30
    for i = 1, plantCount do
        local x, y = self:findSuitableLocation("plant")
        if x and y then
            local plantTypes = {"crop", "berry", "flower", "grass"}
            local plantType = plantTypes[math.random(#plantTypes)]
            self:addEntity("plant", x, y, {plantType = plantType})
        end
    end
    
    -- 添加一些初始人类
    local humanCount = 5
    for i = 1, humanCount do
        local x, y = self:findSuitableLocation("human")
        if x and y then
            self:addEntity("human", x, y)
        end
    end
    
    print("初始实体添加成功")
end

function Game:findSuitableLocation(entityType)
    -- 根据实体类型找到合适的位置
    local maxAttempts = 100
    local attempts = 0
    
    while attempts < maxAttempts do
        local x = math.random(1, self.map.width)
        local y = math.random(1, self.map.height)
        local tile = self.map:getTile(x, y)
        
        if tile then
            if entityType == "tree" and (tile.type == self.map.TILE_TYPES.GRASS or tile.type == self.map.TILE_TYPES.FOREST) then
                -- 检查是否已有实体
                local entities = self.entityManager:getEntitiesAt(x, y)
                if #entities == 0 then
                    return x, y
                end
            elseif entityType == "plant" and tile.type == self.map.TILE_TYPES.GRASS then
                -- 检查是否已有实体
                local entities = self.entityManager:getEntitiesAt(x, y)
                if #entities == 0 then
                    return x, y
                end
            elseif entityType == "human" and (tile.type == self.map.TILE_TYPES.GRASS or tile.type == self.map.TILE_TYPES.EMPTY) then
                -- 检查是否已有实体
                local entities = self.entityManager:getEntitiesAt(x, y)
                if #entities == 0 then
                    return x, y
                end
            end
        end
        
        attempts = attempts + 1
    end
    
    print("警告: 无法为 " .. entityType .. " 找到合适的位置")
    return nil, nil
end

function Game:addEntity(entityType, x, y, properties)
    -- 添加实体
    properties = properties or {}
    
    -- 检查参数
    if not entityType or not x or not y then
        print("错误: 添加实体失败，参数不完整")
        return nil
    end
    
    -- 调用实体管理器添加实体
    local entity = self.entityManager:addEntity(entityType, x, y, properties)
    
    if entity then
        -- 更新资源
        if entityType == "human" then
            self.resourceManager:addResource("population", 1)
        end
        
        print("实体添加成功: 类型=" .. entityType .. ", 位置=(" .. x .. ", " .. y .. ")")
    else
        print("错误: 实体添加失败")
    end
    
    return entity
end

function Game:removeEntity(entity)
    -- 移除实体
    if not entity then
        print("错误: 移除实体失败，实体为空")
        return false
    end
    
    -- 调用实体管理器移除实体
    local success = self.entityManager:removeEntity(entity)
    
    if success then
        -- 更新资源
        if entity.type == "human" then
            self.resourceManager:addResource("population", -1)
        end
        
        print("实体移除成功: ID=" .. entity.id)
    else
        print("错误: 实体移除失败")
    end
    
    return success
end

function Game:update(dt)
    -- 如果游戏暂停，不更新
    if self.paused then
        return
    end
    
    -- 更新游戏时间
    self.gameTime = self.gameTime + dt
    self.dayTime = self.dayTime + dt
    
    -- 检查是否过了一天
    if self.dayTime >= self.dayLength then
        self.dayTime = 0
        self.dayCount = self.dayCount + 1
        self:onNewDay()
    end
    
    -- 更新各个系统
    self.map:update(dt)
    self.entityManager:update(dt)
    self.cardSystem:update(dt)
    self.resourceManager:update(dt)
    self.uiManager:update(dt)
end

function Game:onNewDay()
    -- 每天开始时的处理
    print("第 " .. self.dayCount .. " 天开始")
    
    -- 更新资源产出
    self.resourceManager:updateDailyResources()
    
    -- 抽取新卡牌
    if self.cardSystem:canDrawCard() then
        self.cardSystem:drawCard()
    end
    
    -- 其他每日事件
    self:processDailyEvents()
end

function Game:processDailyEvents()
    -- 处理每日随机事件
    local eventChance = 0.2 -- 20%的概率发生事件
    
    if math.random() < eventChance then
        local events = {
            self.spawnRandomEntities,
            self.triggerWeatherEvent,
            self.triggerResourceEvent
        }
        
        local event = events[math.random(#events)]
        event(self)
    end
end

function Game:spawnRandomEntities()
    -- 随机生成新实体
    local entityTypes = {"tree", "plant"}
    local entityType = entityTypes[math.random(#entityTypes)]
    local count = math.random(1, 5)
    
    print("事件: 自然生长，将生成 " .. count .. " 个 " .. entityType)
    
    for i = 1, count do
        local x, y = self:findSuitableLocation(entityType)
        if x and y then
            if entityType == "tree" then
                local treeTypes = {"oak", "pine", "fruit", "palm"}
                local treeType = treeTypes[math.random(#treeTypes)]
                self:addEntity("tree", x, y, {treeType = treeType})
            elseif entityType == "plant" then
                local plantTypes = {"crop", "berry", "flower", "grass"}
                local plantType = plantTypes[math.random(#plantTypes)]
                self:addEntity("plant", x, y, {plantType = plantType})
            end
        end
    end
end

function Game:triggerWeatherEvent()
    -- 触发天气事件
    local weatherEvents = {
        "rain",
        "drought",
        "storm"
    }
    
    local event = weatherEvents[math.random(#weatherEvents)]
    print("事件: 天气变化 - " .. event)
    
    if event == "rain" then
        -- 雨水使植物生长更快
        local plants = self.entityManager:getEntitiesByType("plant")
        for _, plant in ipairs(plants) do
            plant.growthRate = plant.growthRate * 1.5
        end
        
        -- 增加水资源
        self.resourceManager:addResource("water", 20)
    elseif event == "drought" then
        -- 干旱使植物生长变慢
        local plants = self.entityManager:getEntitiesByType("plant")
        for _, plant in ipairs(plants) do
            plant.growthRate = plant.growthRate * 0.5
        end
        
        -- 减少水资源
        self.resourceManager:addResource("water", -10)
    elseif event == "storm" then
        -- 风暴可能摧毁一些树木
        local trees = self.entityManager:getEntitiesByType("tree")
        local destroyCount = math.min(math.random(1, 3), #trees)
        
        for i = 1, destroyCount do
            if #trees > 0 then
                local index = math.random(#trees)
                self:removeEntity(trees[index])
                table.remove(trees, index)
            end
        end
    end
end

function Game:triggerResourceEvent()
    -- 触发资源事件
    local resourceEvents = {
        "discovery",
        "shortage",
        "abundance"
    }
    
    local event = resourceEvents[math.random(#resourceEvents)]
    print("事件: 资源变化 - " .. event)
    
    if event == "discovery" then
        -- 发现新资源
        local resources = {"food", "wood", "stone", "water"}
        local resource = resources[math.random(#resources)]
        local amount = math.random(10, 30)
        
        self.resourceManager:addResource(resource, amount)
        print("发现了 " .. amount .. " 单位的 " .. resource)
    elseif event == "shortage" then
        -- 资源短缺
        local resources = {"food", "wood", "stone", "water"}
        local resource = resources[math.random(#resources)]
        local amount = math.random(5, 15)
        
        self.resourceManager:addResource(resource, -amount)
        print("损失了 " .. amount .. " 单位的 " .. resource)
    elseif event == "abundance" then
        -- 资源丰富
        local resources = {"food", "wood", "stone", "water"}
        for _, resource in ipairs(resources) do
            local amount = math.random(5, 15)
            self.resourceManager:addResource(resource, amount)
        end
        print("所有资源都增加了")
    end
end

function Game:draw()
    -- 绘制游戏
    -- 绘制地图
    self.map:draw()
    
    -- 使用视图管理器绘制实体，而不是直接使用实体管理器
    -- self.entityManager:draw() -- 旧的绘制方式
    self.viewManager:draw() -- 新的绘制方式
    
    -- 绘制UI（不包括卡牌系统）
    self.uiManager:drawWithoutCards()
    
    -- 最后绘制卡牌系统，确保它在最上层
    self.cardSystem:draw()
    
    -- 绘制调试信息
    if self.debugMode then
        self:drawDebugInfo()
        -- 也可以显示视图管理器的调试信息
        self.viewManager:drawDebugInfo()
    end
end

function Game:drawDebugInfo()
    -- 绘制调试信息
    love.graphics.setColor(1, 1, 1, 1)
    
    local debugInfo = {
        "FPS: " .. love.timer.getFPS(),
        "游戏时间: " .. string.format("%.1f", self.gameTime) .. "s",
        "天数: " .. self.dayCount,
        "实体数量: " .. self.entityManager:getEntityCount(),
        "人类: " .. self.entityManager:getHumanCount(),
        "植物: " .. self.entityManager:getPlantCount(),
        "树木: " .. self.entityManager:getTreeCount(),
        "手牌数量: " .. #self.cardSystem.hand
    }
    
    for i, info in ipairs(debugInfo) do
        love.graphics.print(info, 10, 10 + (i-1) * 20)
    end
end

function Game:mousepressed(x, y, button)
    -- 处理鼠标按下事件
    -- 先检查UI和卡牌系统
    if self.uiManager:mousepressed(x, y, button) then
        return
    end
    
    if self.cardSystem:mousepressed(x, y, button) then
        return
    end
    
    -- 如果没有UI交互，检查地图交互
    local tileX, tileY = self.map:screenToTile(x, y)
    if tileX and tileY then
        self:handleMapClick(tileX, tileY, button)
    end
end

function Game:mousereleased(x, y, button)
    -- 处理鼠标释放事件
    self.uiManager:mousereleased(x, y, button)
    self.cardSystem:mousereleased(x, y, button)
end

function Game:mousemoved(x, y, dx, dy)
    -- 处理鼠标移动事件
    self.uiManager:mousemoved(x, y, dx, dy)
    self.cardSystem:mousemoved(x, y, dx, dy)
    
    -- 如果按住右键，移动地图
    if love.mouse.isDown(2) then
        self.map:move(-dx, -dy)
    end
end

function Game:handleMapClick(tileX, tileY, button)
    -- 处理地图点击
    if button == 1 then -- 左键
        -- 总是显示瓦片信息
        local tile = self.map:getTile(tileX, tileY)
        if tile then
            self.uiManager:showTileInfo(tile, tileX, tileY)
        end
        
        -- 获取点击位置的实体，如果有则显示实体信息，如果没有则清除实体信息
        local entities = self.entityManager:getEntitiesAt(tileX, tileY)
        if #entities > 0 then
            -- 显示实体信息
            self.uiManager:showEntityInfo(entities[1])
        else
            -- 清除实体信息
            self.uiManager:clearEntityInfo()
        end
    elseif button == 2 then -- 右键
        -- 右键菜单或取消选择
        self.uiManager:hideInfo()
    end
end

function Game:keypressed(key)
    -- 处理键盘按下事件
    if key == "escape" then
        -- 暂停/继续游戏
        self.paused = not self.paused
        print(self.paused and "游戏已暂停" or "游戏已继续")
    elseif key == "space" then
        -- 抽取卡牌
        if self.cardSystem:canDrawCard() then
            self.cardSystem:drawCard()
        end
    elseif key == "d" then
        -- 切换调试模式
        self.debugMode = not self.debugMode
        self.entityManager.debugMode = self.debugMode
        print(self.debugMode and "调试模式已开启" or "调试模式已关闭")
    elseif key == "r" then
        -- 重新生成地图
        self:resetGame()
    end
end

function Game:keyreleased(key)
    -- 处理键盘释放事件
    -- 可以在这里添加键盘释放的处理逻辑
    -- 例如处理组合键等
end

function Game:resetGame()
    -- 重置游戏
    print("重置游戏...")
    
    -- 重置游戏状态
    self.gameTime = 0
    self.dayTime = 0
    self.dayCount = 1
    
    -- 重新初始化游戏世界
    self:initWorld()
    
    print("游戏已重置")
end

function Game:playCard(card, tileX, tileY)
    -- 检查参数
    if not card or not tileX or not tileY then
        print("错误: 使用卡牌失败，参数不完整")
        return false
    end
    
    -- 检查卡牌是否有效
    if not card.type then
        print("错误: 无效的卡牌")
        return false
    end
    
    -- 检查是否有足够的资源使用卡牌
    if card.cost then
        for resourceType, amount in pairs(card.cost) do
            if not self.resourceManager:useResource(resourceType, amount) then
                print("错误: 资源不足，无法使用卡牌")
                return false
            end
        end
    end
    
    -- 根据卡牌类型执行不同的效果
    local success = false
    
    if card.type == "human" then
        -- 创建人类
        local entity = self:addEntity("human", tileX, tileY)
        success = (entity ~= nil)
    elseif card.type == "plant" then
        -- 创建植物
        local entity = self:addEntity("plant", tileX, tileY, {plantType = card.plantType})
        success = (entity ~= nil)
    elseif card.type == "tree" then
        -- 创建树木
        local entity = self:addEntity("tree", tileX, tileY, {treeType = card.treeType})
        success = (entity ~= nil)
    elseif card.type == "weather" then
        -- 应用天气效果
        success = self.map:applyWeather(card.weatherType, tileX, tileY, card.radius or 3)
    end
    
    if success then
        -- 卡牌使用成功，将其移到弃牌堆
        self.cardSystem:discardCard(card)
        print("卡牌使用成功: " .. card.name)
    else
        -- 如果使用失败，返还资源
        if card.cost then
            for resourceType, amount in pairs(card.cost) do
                self.resourceManager:addResource(resourceType, amount)
            end
        end
        print("卡牌使用失败: " .. card.name)
    end
    
    return success
end

return Game 