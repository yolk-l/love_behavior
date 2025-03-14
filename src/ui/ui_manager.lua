-- UI管理系统
local UI = {}
UI.__index = UI
local FontManager = require("src.utils.font_manager")

function UI:new(game)
    local self = setmetatable({}, UI)
    
    self.game = game
    
    -- 初始化UI状态
    self.selectedTile = nil
    self.selectedEntity = nil
    self.showCardInfo = false
    self.selectedCard = nil
    
    -- 初始化按钮列表
    self.buttons = {}
    
    -- 初始化字体
    self.smallFont = FontManager.getFont(12)
    self.normalFont = FontManager.getFont(16)
    self.titleFont = FontManager.getFont(24)
    
    -- 初始化UI尺寸
    self.cardInfoWidth = 300
    self.cardInfoHeight = 400
    self.resourcePanelHeight = 40
    self.showResourcePanel = true
    
    print("UI管理器初始化成功")
    
    return self
end

function UI:update(dt)
    -- 更新UI状态
    
    -- 更新按钮悬停状态
    local mouseX, mouseY = love.mouse.getPosition()
    for _, button in pairs(self.buttons) do
        button.hover = mouseX >= button.x and mouseX <= button.x + button.width and
                       mouseY >= button.y and mouseY <= button.y + button.height
    end
    
    -- 更新"获取新卡牌"按钮的状态
    if self.buttons["getNewCards"] then
        self.buttons["getNewCards"].active = self.game.cardSystem:canGetNewCard()
    end
end

function UI:draw()
    -- 保存当前颜色
    local r, g, b, a = love.graphics.getColor()
    
    -- 绘制资源面板
    if self.showResourcePanel then
        self:drawResourcePanel()
    end
    
    -- 绘制卡牌信息
    if self.showCardInfo and self.selectedCard then
        self:drawCardInfo()
    end
    
    -- 绘制地块信息
    if self.selectedTile then
        self:drawTileInfo()
    end
    
    -- 绘制实体信息
    if self.selectedEntity then
        self:drawEntityInfo()
    end
    
    -- 绘制按钮
    self:drawButtons()
    
    -- 绘制帮助提示
    self:drawHelpTips()
    
    -- 恢复颜色
    love.graphics.setColor(r, g, b, a)
end

function UI:drawWithoutCards()
    -- 保存当前颜色
    local r, g, b, a = love.graphics.getColor()
    
    -- 绘制资源面板
    if self.showResourcePanel then
        self:drawResourcePanel()
    end
    
    -- 绘制卡牌信息
    if self.showCardInfo and self.selectedCard then
        self:drawCardInfo()
    end
    
    -- 绘制地块信息
    if self.selectedTile then
        self:drawTileInfo()
    end
    
    -- 绘制实体信息
    if self.selectedEntity then
        self:drawEntityInfo()
    end
    
    -- 绘制按钮
    self:drawButtons()
    
    -- 绘制帮助提示
    self:drawHelpTips()
    
    -- 恢复颜色
    love.graphics.setColor(r, g, b, a)
end

function UI:drawResourcePanel()
    -- 绘制资源面板背景
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), self.resourcePanelHeight)
    
    -- 绘制资源信息
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.normalFont)
    
    local resourceManager = self.game.resourceManager
    local resources = {
        {name = "人口", type = "population"},
        {name = "食物", type = "food"},
        {name = "木材", type = "wood"},
        {name = "石头", type = "stone"},
        {name = "知识", type = "knowledge"},
        {name = "信仰", type = "faith"}
    }
    
    -- 计算每行能显示的资源数量
    local screenWidth = love.graphics.getWidth()
    local resourceWidth = 120 -- 每个资源项的宽度
    local resourcesPerRow = math.floor(screenWidth / resourceWidth)
    
    -- 确保至少显示1个资源
    resourcesPerRow = math.max(1, resourcesPerRow)
    
    -- 调整面板高度以适应多行
    local rowCount = math.ceil(#resources / resourcesPerRow)
    self.resourcePanelHeight = 30 * rowCount
    
    -- 绘制资源
    for i, resource in ipairs(resources) do
        local row = math.ceil(i / resourcesPerRow) - 1
        local col = (i - 1) % resourcesPerRow
        
        local x = 10 + col * resourceWidth
        local y = 10 + row * 25
        
        local value = resourceManager:getResource(resource.type)
        local limit = resourceManager:getResourceLimit(resource.type)
        local rate = resourceManager:getNetResourceRate(resource.type)
        
        local text = string.format("%s: %d/%d", resource.name, math.floor(value), limit)
        if rate ~= 0 then
            text = text .. string.format(" (%s%.1f/s)", rate > 0 and "+" or "", rate)
        end
        
        love.graphics.print(text, x, y)
    end
end

function UI:drawCardInfo()
    -- 绘制卡牌信息面板
    local x = love.graphics.getWidth() - self.cardInfoWidth - 10
    local y = 50
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", x, y, self.cardInfoWidth, self.cardInfoHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.print(self.selectedCard.name, x + 10, y + 10)
    
    love.graphics.setFont(self.normalFont)
    love.graphics.print(self.selectedCard.description, x + 10, y + 40, 0, 1, 1, 0, 0, 0, 0, self.cardInfoWidth - 20)
    
    -- 绘制卡牌效果
    love.graphics.setFont(self.smallFont)
    local effectY = y + 100
    for _, effect in ipairs(self.selectedCard.effects or {}) do
        love.graphics.print(effect, x + 10, effectY)
        effectY = effectY + 20
    end
    
    -- 绘制卡牌成本
    if self.selectedCard.cost then
        local costY = y + self.cardInfoHeight - 60
        love.graphics.print("消耗:", x + 10, costY)
        costY = costY + 20
        
        for resourceType, amount in pairs(self.selectedCard.cost) do
            local resourceName = ""
            if resourceType == "population" then resourceName = "人口"
            elseif resourceType == "food" then resourceName = "食物"
            elseif resourceType == "wood" then resourceName = "木材"
            elseif resourceType == "stone" then resourceName = "石头"
            elseif resourceType == "knowledge" then resourceName = "知识"
            elseif resourceType == "faith" then resourceName = "信仰"
            end
            
            love.graphics.print(string.format("%s: %d", resourceName, amount), x + 20, costY)
            costY = costY + 20
        end
    end
end

function UI:drawButtons()
    for _, button in pairs(self.buttons) do
        -- 绘制按钮背景
        if button.hover then
            love.graphics.setColor(0.4, 0.4, 0.4, 0.8)
        elseif button.active == false then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        end
        
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        -- 绘制按钮边框
        love.graphics.setColor(0.8, 0.8, 0.8, button.active == false and 0.5 or 1)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        
        -- 绘制按钮文本
        love.graphics.setColor(1, 1, 1, button.active == false and 0.5 or 1)
        love.graphics.setFont(self.normalFont)
        
        local textWidth = self.normalFont:getWidth(button.text)
        local textHeight = self.normalFont:getHeight()
        local textX = button.x + (button.width - textWidth) / 2
        local textY = button.y + (button.height - textHeight) / 2
        
        love.graphics.print(button.text, textX, textY)
    end
end

function UI:addButton(id, text, x, y, width, height, callback)
    self.buttons[id] = {
        id = id,
        text = text,
        x = x,
        y = y,
        width = width,
        height = height,
        callback = callback,
        hover = false,
        active = true
    }
end

function UI:mousepressed(x, y, button)
    print("UI处理鼠标按下事件: x=" .. x .. ", y=" .. y .. ", button=" .. button)
    
    if button == 1 then -- 左键
        -- 检查是否点击了地块信息面板的关闭按钮（左侧）
        if self.selectedTile then
            local panelX = 10
            local panelY = 50
            local width = 250
            local closeButtonX = panelX + width - 30
            local closeButtonY = panelY + 10
            
            if x >= closeButtonX and x <= closeButtonX + 20 and
               y >= closeButtonY and y <= closeButtonY + 20 then
                self:hideInfo()
                return true
            end
        end
        
        -- 检查是否点击了实体信息面板的关闭按钮（右侧）
        if self.selectedEntity then
            local width = 250
            local panelX = love.graphics.getWidth() - width - 10
            local panelY = 50
            local closeButtonX = panelX + width - 30
            local closeButtonY = panelY + 10
            
            if x >= closeButtonX and x <= closeButtonX + 20 and
               y >= closeButtonY and y <= closeButtonY + 20 then
                self:hideInfo()
                return true
            end
        end
        
        -- 检查是否点击了按钮
        for id, btn in pairs(self.buttons) do
            if x >= btn.x and x <= btn.x + btn.width and
               y >= btn.y and y <= btn.y + btn.height and
               btn.active ~= false then
                if btn.callback then
                    print("点击了按钮: " .. btn.id)
                    btn.callback()
                    return true
                end
            end
        end
    end
    
    -- 如果没有点击按钮，尝试让卡牌系统处理点击
    return self.game.cardSystem:mousepressed(x, y, button)
end

function UI:mousereleased(x, y, button)
    -- 尝试让卡牌系统处理释放
    return self.game.cardSystem:mousereleased(x, y, button)
end

function UI:keypressed(key)
    if key == "tab" then
        self.showResourcePanel = not self.showResourcePanel
        return true
    end
    
    return false
end

function UI:keyreleased(key)
    return false
end

function UI:setSelectedCard(card)
    self.selectedCard = card
    self.showCardInfo = (card ~= nil)
end

function UI:drawHelpTips()
    -- 绘制帮助提示
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(self.smallFont)
    
    local tips = {
        "按N键或点击'获取新卡牌'按钮获取新卡牌",
        "拖动卡牌到地图上释放效果",
        "按Tab键显示/隐藏资源面板"
    }
    
    local y = love.graphics.getHeight() - 20 * #tips - 10
    for _, tip in ipairs(tips) do
        love.graphics.print(tip, 10, y)
        y = y + 20
    end
end

function UI:showTileInfo(tile, x, y)
    -- 显示瓦片信息
    print("显示瓦片信息: 位置=(" .. x .. ", " .. y .. "), 类型=" .. self.game.map.TILE_NAMES[tile.type])
    
    -- 保存当前选中的瓦片信息
    self.selectedTile = {
        tile = tile,
        x = x,
        y = y
    }
    
    -- 只隐藏卡牌信息，但保留实体信息
    self.showCardInfo = false
    self.selectedCard = nil
    -- 不再清除实体信息: self.selectedEntity = nil
end

function UI:showEntityInfo(entity)
    -- 显示实体信息
    print("显示实体信息: ID=" .. entity.id .. ", 类型=" .. entity.type)
    
    -- 保存当前选中的实体
    self.selectedEntity = entity
    
    -- 只隐藏卡牌信息，但保留地块信息
    self.showCardInfo = false
    self.selectedCard = nil
    -- 不再清除地块信息: self.selectedTile = nil
end

function UI:clearEntityInfo()
    -- 只清除实体信息，保留地块信息
    print("清除实体信息")
    self.selectedEntity = nil
end

function UI:hideInfo()
    -- 隐藏所有信息
    self.selectedTile = nil
    self.selectedEntity = nil
    self.showCardInfo = false
    self.selectedCard = nil
end

function UI:drawTileInfo()
    -- 绘制地块信息面板 - 放在左侧
    local x = 10
    local y = 50
    local width = 250
    local height = 200
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("地块信息", x + 10, y + 10)
    
    love.graphics.setFont(self.normalFont)
    
    -- 绘制地块坐标
    local posY = y + 50
    love.graphics.print(string.format("位置: (%d, %d)", self.selectedTile.x, self.selectedTile.y), x + 10, posY)
    posY = posY + 25
    
    -- 绘制地块类型
    local tileType = self.game.map.TILE_NAMES[self.selectedTile.tile.type]
    love.graphics.print(string.format("类型: %s", tileType), x + 10, posY)
    posY = posY + 25
    
    -- 绘制地块属性
    local tile = self.selectedTile.tile
    love.graphics.print(string.format("湿度: %.2f", tile.moisture), x + 10, posY)
    posY = posY + 25
    
    love.graphics.print(string.format("肥沃度: %.2f", tile.fertility), x + 10, posY)
    posY = posY + 25
    
    love.graphics.print(string.format("温度: %.2f℃", tile.temperature), x + 10, posY)
    posY = posY + 25
    
    -- 绘制关闭按钮
    local closeButtonX = x + width - 30
    local closeButtonY = y + 10
    
    love.graphics.setColor(0.7, 0.0, 0.0, 0.8)
    love.graphics.rectangle("fill", closeButtonX, closeButtonY, 20, 20)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.normalFont)
    love.graphics.print("X", closeButtonX + 5, closeButtonY)
end

function UI:drawEntityInfo()
    -- 绘制实体信息面板 - 放在右侧
    local width = 250
    local height = 250
    local x = love.graphics.getWidth() - width - 10 -- 右侧位置
    local y = 50
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleFont)
    
    -- 根据实体类型设置标题
    local titleText = "实体信息"
    if self.selectedEntity.type == "human" then
        titleText = "人类信息"
    elseif self.selectedEntity.type == "plant" then
        titleText = "植物信息"
    elseif self.selectedEntity.type == "tree" then
        titleText = "树木信息"
    end
    
    love.graphics.print(titleText, x + 10, y + 10)
    
    -- 绘制实体基本信息
    love.graphics.setFont(self.normalFont)
    local posY = y + 50
    
    -- ID和类型
    love.graphics.print("ID: " .. self.selectedEntity.id, x + 10, posY)
    posY = posY + 25
    
    -- 位置信息
    love.graphics.print(string.format("位置: (%.1f, %.1f)", self.selectedEntity.x, self.selectedEntity.y), x + 10, posY)
    posY = posY + 25
    
    -- 根据实体类型显示不同的属性
    if self.selectedEntity.type == "human" then
        -- 人类特有属性
        if self.selectedEntity.health then
            love.graphics.print(string.format("生命值: %.1f/%.1f", self.selectedEntity.health, self.selectedEntity.maxHealth or 100), x + 10, posY)
            posY = posY + 25
        end
        
        if self.selectedEntity.hunger ~= nil then
            love.graphics.print(string.format("饥饿度: %.1f", self.selectedEntity.hunger), x + 10, posY)
            posY = posY + 25
        end
        
        if self.selectedEntity.state then
            love.graphics.print("状态: " .. self.selectedEntity.state, x + 10, posY)
            posY = posY + 25
        end
        
        if self.selectedEntity.task then
            love.graphics.print("任务: " .. self.selectedEntity.task, x + 10, posY)
            posY = posY + 25
        end
    elseif self.selectedEntity.type == "plant" or self.selectedEntity.type == "tree" then
        -- 植物/树木特有属性
        if self.selectedEntity.growth ~= nil then
            love.graphics.print(string.format("生长度: %.1f%%", self.selectedEntity.growth * 100), x + 10, posY)
            posY = posY + 25
        end
        
        if self.selectedEntity.maturity ~= nil then
            love.graphics.print(string.format("成熟度: %.1f%%", self.selectedEntity.maturity * 100), x + 10, posY)
            posY = posY + 25
        end
        
        if self.selectedEntity.health then
            love.graphics.print(string.format("健康度: %.1f/%.1f", self.selectedEntity.health, self.selectedEntity.maxHealth or 100), x + 10, posY)
            posY = posY + 25
        end
    end
    
    -- 如果实体有产出资源，显示产出信息
    if self.selectedEntity.resourceProduction then
        love.graphics.print("资源产出:", x + 10, posY)
        posY = posY + 25
        
        for resourceType, rate in pairs(self.selectedEntity.resourceProduction) do
            local resourceName = ""
            if resourceType == "population" then resourceName = "人口"
            elseif resourceType == "food" then resourceName = "食物"
            elseif resourceType == "wood" then resourceName = "木材"
            elseif resourceType == "stone" then resourceName = "石头"
            elseif resourceType == "knowledge" then resourceName = "知识"
            elseif resourceType == "faith" then resourceName = "信仰"
            end
            
            if rate > 0 then
                love.graphics.print(string.format("  %s: +%.1f/s", resourceName, rate), x + 10, posY)
                posY = posY + 20
            end
        end
    end
    
    -- 绘制关闭按钮
    local closeButtonX = x + width - 30
    local closeButtonY = y + 10
    
    love.graphics.setColor(0.7, 0.0, 0.0, 0.8)
    love.graphics.rectangle("fill", closeButtonX, closeButtonY, 20, 20)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.normalFont)
    love.graphics.print("X", closeButtonX + 5, closeButtonY)
end

return UI 