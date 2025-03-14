-- 卡牌系统
local CardSystem = {}
CardSystem.__index = CardSystem

-- 导入卡牌类型
local HumanCard = require("src.cards.human_card")
local WeatherCard = require("src.cards.weather_card")
local PlantCard = require("src.cards.plant_card")
local TreeCard = require("src.cards.tree_card")
local FontManager = require("src.utils.font_manager")

function CardSystem:new(game)
    local self = setmetatable({}, CardSystem)
    
    self.game = game
    self.hand = {} -- 玩家手中的卡牌
    self.deck = {} -- 牌库
    self.discardPile = {} -- 弃牌堆
    
    self.maxHandSize = 8 -- 最大手牌数量，增加到8张
    self.cardWidth = 80 -- 卡牌宽度，从100减小到80
    self.cardHeight = 120 -- 卡牌高度，从150减小到120
    self.cardSpacing = 5 -- 卡牌间距，从10减小到5
    
    -- 计算固定手牌区域大小，但限制最大宽度为屏幕宽度的80%
    local maxAreaWidth = love.graphics.getWidth() * 0.8
    self.handAreaWidth = math.min(
        maxAreaWidth,
        self.cardWidth * self.maxHandSize + self.cardSpacing * (self.maxHandSize - 1)
    )
    self.handAreaPadding = 10 -- 手牌区域内边距
    
    self.selectedCard = nil -- 当前选中的卡牌
    self.draggedCard = nil -- 当前拖拽的卡牌
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    -- 卡牌获取冷却时间
    self.cardCooldown = 0
    self.cardCooldownMax = 10 -- 10秒冷却时间
    
    -- 上次检查是否可以获取新卡牌的结果
    self.lastCanGetNewCardResult = nil
    
    -- 上次绘制的手牌数量
    self.lastHandCount = 0
    
    return self
end

function CardSystem:initCards()
    -- 清空现有卡牌
    self.hand = {}
    self.deck = {}
    self.discardPile = {}
    
    -- 添加初始卡牌
    self:addStarterCards()
    
    -- 重置卡牌冷却时间
    self.cardCooldown = 0
    
    print("卡牌系统初始化成功")
end

function CardSystem:addStarterCards()
    print("添加初始卡牌...")
    
    -- 添加初始卡牌到牌库
    table.insert(self.deck, HumanCard:new(self.game))
    table.insert(self.deck, WeatherCard:new(self.game, "rain"))
    table.insert(self.deck, WeatherCard:new(self.game, "sun"))
    table.insert(self.deck, WeatherCard:new(self.game, "wind"))
    table.insert(self.deck, PlantCard:new(self.game))
    table.insert(self.deck, TreeCard:new(self.game))
    
    -- 洗牌
    self:shuffleDeck()
    
    -- 抽初始手牌
    print("抽取初始手牌...")
    for i = 1, math.min(self.maxHandSize, #self.deck) do
        local card = self:drawCard()
        if card then
            print("初始手牌 " .. i .. ": " .. card.name)
        end
    end
    
    -- 设置初始信仰值，让玩家可以使用卡牌
    self.game.resourceManager:setResource("faith", 50)
    
    print("初始卡牌添加完成，当前手牌数量: " .. #self.hand)
end

function CardSystem:addAllCardTypes()
    -- 添加所有类型的卡牌到牌库
    table.insert(self.deck, HumanCard:new(self.game))
    table.insert(self.deck, WeatherCard:new(self.game, "rain"))
    table.insert(self.deck, WeatherCard:new(self.game, "sun"))
    table.insert(self.deck, WeatherCard:new(self.game, "wind"))
    table.insert(self.deck, PlantCard:new(self.game))
    table.insert(self.deck, TreeCard:new(self.game))
    
    -- 洗牌
    self:shuffleDeck()
    
    -- 直接将一张卡牌添加到手牌中，而不是尝试抽牌
    if #self.hand < self.maxHandSize and #self.deck > 0 then
        local card = table.remove(self.deck, 1)
        if card then
            table.insert(self.hand, card)
            print("成功添加了一张新卡牌到手牌: " .. card.name)
            
            -- 确保卡牌有正确的游戏引用
            card.game = self.game
            
            -- 打印手牌信息
            print("当前手牌:")
            for i, handCard in ipairs(self.hand) do
                print(i .. ": " .. handCard.name)
            end
        else
            print("错误: 无法从牌库中获取卡牌")
        end
    else
        print("手牌已满或牌库为空，无法添加新卡牌")
    end
    
    -- 重置冷却时间
    self.cardCooldown = self.cardCooldownMax
    
    -- 打印日志，确认函数被调用
    print("添加了新卡牌到牌库，当前手牌数量: " .. #self.hand)
    
    -- 强制更新lastHandCount，确保下次绘制时能够显示正确的手牌
    self.lastHandCount = -1
    
    return true
end

function CardSystem:shuffleDeck()
    -- 洗牌算法
    for i = #self.deck, 2, -1 do
        local j = math.random(i)
        self.deck[i], self.deck[j] = self.deck[j], self.deck[i]
    end
    
    -- 打印日志，确认洗牌
    print("牌库已洗牌，牌库中有 " .. #self.deck .. " 张卡牌")
end

function CardSystem:drawCard()
    -- 打印日志，确认函数被调用
    print("尝试抽牌，当前手牌数量: " .. #self.hand .. ", 牌库数量: " .. #self.deck)
    
    if #self.deck == 0 then
        -- 如果牌库为空，将弃牌堆洗入牌库
        if #self.discardPile > 0 then
            print("牌库为空，将弃牌堆洗入牌库")
            for i = 1, #self.discardPile do
                table.insert(self.deck, self.discardPile[i])
            end
            self.discardPile = {}
            self:shuffleDeck()
        else
            -- 如果弃牌堆也为空，无法抽牌
            print("牌库和弃牌堆都为空，无法抽牌")
            return nil
        end
    end
    
    if #self.hand >= self.maxHandSize then
        -- 手牌已满
        print("手牌已满，无法抽牌")
        return nil
    end
    
    -- 从牌库顶部抽一张牌
    local card = table.remove(self.deck, 1)
    if card then
        -- 确保卡牌有正确的游戏引用
        card.game = self.game
        
        table.insert(self.hand, card)
        print("成功抽了一张卡牌: " .. card.name .. "，当前手牌数量: " .. #self.hand)
        
        -- 强制更新lastHandCount，确保下次绘制时能够显示正确的手牌
        self.lastHandCount = -1
        
        return card
    else
        print("错误: 无法从牌库中抽取卡牌")
        return nil
    end
end

function CardSystem:discardCard(card)
    -- 从手牌中移除卡牌
    for i, handCard in ipairs(self.hand) do
        if handCard == card then
            table.remove(self.hand, i)
            table.insert(self.discardPile, card)
            print("弃掉了一张卡牌，当前手牌数量: " .. #self.hand)
            break
        end
    end
    
    -- 如果手牌为空，抽一张新牌
    if #self.hand == 0 then
        print("手牌为空，自动抽一张新牌")
        self:drawCard()
    end
end

function CardSystem:update(dt)
    -- 更新手牌中的卡牌
    for _, card in ipairs(self.hand) do
        card:update(dt)
    end
    
    -- 如果有拖拽中的卡牌，更新其位置
    if self.draggedCard then
        self.draggedCard.x = love.mouse.getX() - self.dragOffsetX
        self.draggedCard.y = love.mouse.getY() - self.dragOffsetY
    end
    
    -- 更新卡牌获取冷却时间
    if self.cardCooldown > 0 then
        self.cardCooldown = self.cardCooldown - dt
        if self.cardCooldown < 0 then
            self.cardCooldown = 0
            print("卡牌冷却结束，现在可以获取新卡牌")
        end
    end
end

function CardSystem:draw()
    -- 只在手牌数量变化时打印调试信息
    if self.lastHandCount ~= #self.hand then
        print("绘制卡牌系统，手牌数量: " .. #self.hand)
        for i, card in ipairs(self.hand) do
            print("手牌 " .. i .. ": " .. card.name)
        end
        self.lastHandCount = #self.hand
    end
    
    -- 计算固定的手牌区域位置
    local handAreaX = (love.graphics.getWidth() - self.handAreaWidth) / 2
    local handAreaY = love.graphics.getHeight() - self.cardHeight - 20
    
    -- 绘制手牌背景区域
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 
        handAreaX - self.handAreaPadding, 
        handAreaY - self.handAreaPadding, 
        self.handAreaWidth + self.handAreaPadding * 2, 
        self.cardHeight + self.handAreaPadding * 2)
    
    -- 居中展示手牌 - 计算所有手牌的总宽度
    local totalCardsWidth = self.cardWidth * #self.hand + self.cardSpacing * (#self.hand - 1)
    -- 计算居中的起始X坐标
    local startX = (love.graphics.getWidth() - totalCardsWidth) / 2
    local startY = handAreaY
    
    -- 绘制手牌
    for i, card in ipairs(self.hand) do
        if card ~= self.draggedCard then
            card.x = startX + (i - 1) * (self.cardWidth + self.cardSpacing)
            card.y = startY
            
            if card == self.selectedCard then
                -- 选中的卡牌稍微上移
                card.y = card.y - 20
            end
            
            -- 确保卡牌绘制函数不会出错
            if type(card.draw) == "function" then
                -- 绘制卡牌边框，帮助调试
                love.graphics.setColor(1, 0, 0, 1)
                love.graphics.rectangle("line", card.x, card.y, self.cardWidth, self.cardHeight)
                
                -- 绘制卡牌
                card:draw()
            else
                print("警告: 卡牌没有draw方法")
                -- 绘制一个简单的卡牌代替
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.rectangle("fill", card.x, card.y, self.cardWidth, self.cardHeight)
                love.graphics.setColor(1, 1, 1, 1)
                FontManager.setFont(14)
                love.graphics.print("卡牌", card.x + 10, card.y + 10)
            end
        end
    end
    
    -- 最后绘制拖拽中的卡牌，确保它在最上层
    if self.draggedCard then
        if type(self.draggedCard.draw) == "function" then
            -- 绘制拖拽卡牌边框，帮助调试
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle("line", self.draggedCard.x, self.draggedCard.y, self.cardWidth, self.cardHeight)
            
            -- 绘制拖拽卡牌
            self.draggedCard:draw()
            
            -- 在地图上高亮显示卡牌影响区域
            local mouseX, mouseY = love.mouse.getPosition()
            local map = self.game.map
            local tileX, tileY = map:screenToTile(mouseX, mouseY)
            
            if tileX and tileY then
                self:drawCardEffectArea(self.draggedCard, tileX, tileY)
            end
        end
    end
end

-- 绘制卡牌效果区域
function CardSystem:drawCardEffectArea(card, centerX, centerY)
    local map = self.game.map
    
    -- 获取卡牌影响半径
    local radius = card.radius or 1
    
    -- 对于没有明确半径的卡牌类型，设置默认值
    if card.type == "human" or card.type == "plant" or card.type == "tree" then
        radius = 1 -- 单点效果
    end
    
    -- 保存当前变换状态
    love.graphics.push()
    love.graphics.translate(map.offsetX, map.offsetY)
    
    -- 设置高亮颜色（使用卡牌自身颜色，添加透明度）
    local color = card.color or {1, 1, 1}
    love.graphics.setColor(color[1], color[2], color[3], 0.3)
    
    -- 绘制影响区域
    if radius == 1 then
        -- 单点效果，只高亮一个地块
        love.graphics.rectangle("fill", 
            (centerX - 1) * map.tileSize, 
            (centerY - 1) * map.tileSize, 
            map.tileSize, 
            map.tileSize)
    else
        -- 区域效果，高亮圆形区域内的所有地块
        for y = centerY - radius, centerY + radius do
            for x = centerX - radius, centerX + radius do
                -- 计算到中心的距离
                local dx = x - centerX
                local dy = y - centerY
                local distance = math.sqrt(dx * dx + dy * dy)
                
                -- 仅高亮半径内的地块
                if distance <= radius then
                    love.graphics.rectangle("fill", 
                        (x - 1) * map.tileSize, 
                        (y - 1) * map.tileSize, 
                        map.tileSize, 
                        map.tileSize)
                end
            end
        end
        
        -- 绘制半径范围指示边界
        love.graphics.setColor(color[1], color[2], color[3], 0.6)
        love.graphics.circle("line", 
            (centerX - 0.5) * map.tileSize, 
            (centerY - 0.5) * map.tileSize, 
            radius * map.tileSize)
    end
    
    -- 恢复变换状态
    love.graphics.pop()
end

function CardSystem:mousepressed(x, y, button)
    if button == 1 then -- 左键
        -- 检查是否点击了手牌中的卡牌
        for i, card in ipairs(self.hand) do
            if x >= card.x and x <= card.x + self.cardWidth and
               y >= card.y and y <= card.y + self.cardHeight then
                -- 选中卡牌
                self.selectedCard = card
                
                -- 开始拖拽
                self.draggedCard = card
                self.dragOffsetX = x - card.x
                self.dragOffsetY = y - card.y
                
                -- 通知UI系统显示卡牌信息
                if self.game.uiManager then
                    self.game.uiManager:setSelectedCard(card)
                end
                
                print("选中了一张卡牌: " .. card.name)
                return true
            end
        end
    end
    
    return false
end

function CardSystem:mousereleased(x, y, button)
    if button == 1 and self.draggedCard then
        print("释放卡牌: " .. self.draggedCard.name .. " 在位置 (" .. x .. ", " .. y .. ")")
        
        -- 计算手牌区域位置（与draw函数保持一致）
        local totalCardsWidth = self.cardWidth * #self.hand + self.cardSpacing * (#self.hand - 1)
        local handAreaStartX = (love.graphics.getWidth() - totalCardsWidth) / 2
        local handAreaY = love.graphics.getHeight() - self.cardHeight - 20
        
        -- 检查是否在手牌区域内
        local isInHandArea = x >= handAreaStartX - self.handAreaPadding and
                            x <= handAreaStartX + totalCardsWidth + self.handAreaPadding and
                            y >= handAreaY - self.handAreaPadding and
                            y <= handAreaY + self.cardHeight + self.handAreaPadding
        
        -- 只有当卡牌被拖出手牌区域时才能使用
        if not isInHandArea then
            -- 检查是否在地图上释放卡牌
            local map = self.game.map
            local tileX, tileY = map:screenToTile(x, y)
            
            if tileX and tileY then
                -- 尝试在地图上使用卡牌
                print("尝试在位置 (" .. tileX .. ", " .. tileY .. ") 使用卡牌: " .. self.draggedCard.name)
                local success = self.game:playCard(self.draggedCard, tileX, tileY)
                
                if success then
                    print("成功使用了卡牌")
                    -- 卡牌使用成功后，重置选中的卡牌
                    self.selectedCard = nil
                    if self.game.uiManager then
                        self.game.uiManager:setSelectedCard(nil)
                    end
                else
                    print("使用卡牌失败")
                end
            else
                print("无效的地图位置")
            end
        else
            print("卡牌未被拖出手牌区域，无法使用")
            -- 将卡牌放回手牌区域
        end
        
        -- 结束拖拽
        self.draggedCard = nil
        return true
    end
    
    return false
end

function CardSystem:canGetNewCard()
    local result = self.cardCooldown <= 0 and #self.hand < self.maxHandSize
    -- 减少日志输出频率，只在状态变化时打印
    if result ~= self.lastCanGetNewCardResult then
        print("检查是否可以获取新卡牌: " .. tostring(result) .. " (冷却: " .. self.cardCooldown .. ", 手牌: " .. #self.hand .. "/" .. self.maxHandSize .. ")")
        self.lastCanGetNewCardResult = result
    end
    return result
end

-- 为了保持兼容性，添加canDrawCard作为canGetNewCard的别名
function CardSystem:canDrawCard()
    return self:canGetNewCard()
end

return CardSystem 