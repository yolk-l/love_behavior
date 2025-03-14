-- 人类卡牌
local HumanCard = {}
HumanCard.__index = HumanCard

local FontManager = require("src.utils.font_manager")

function HumanCard:new(game)
    local self = setmetatable({}, HumanCard)
    
    self.game = game
    self.type = "human"
    self.name = "人类"
    self.description = "创建一个新的人类。人类会自动收集资源、建造房屋和耕种。"
    
    -- 卡牌外观
    self.color = {0.8, 0.2, 0.2}
    self.x = 0
    self.y = 0
    
    -- 卡牌效果
    self.effects = {
        "创建一个新的人类",
        "人类会自动收集资源",
        "人类会建造房屋",
        "人类会耕种"
    }
    
    -- 卡牌消耗
    self.cost = {
        food = 10
    }
    
    return self
end

function HumanCard:update(dt)
    -- 卡牌更新逻辑
end

function HumanCard:draw()
    -- 绘制卡牌
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.game.cardSystem.cardWidth, self.game.cardSystem.cardHeight)
    
    -- 绘制卡牌边框
    love.graphics.setColor(self.color)
    love.graphics.rectangle("line", self.x, self.y, self.game.cardSystem.cardWidth, self.game.cardSystem.cardHeight)
    
    -- 绘制卡牌名称
    love.graphics.setColor(1, 1, 1)
    FontManager.setFont(14)
    love.graphics.printf(self.name, self.x + 5, self.y + 5, self.game.cardSystem.cardWidth - 10, "center")
    
    -- 绘制卡牌图标（简单的人形图标）
    love.graphics.setColor(self.color)
    local iconX = self.x + self.game.cardSystem.cardWidth / 2
    local iconY = self.y + 50
    local iconSize = 30
    
    -- 头部
    love.graphics.circle("fill", iconX, iconY - iconSize / 3, iconSize / 4)
    
    -- 身体
    love.graphics.rectangle("fill", 
        iconX - iconSize / 6, 
        iconY - iconSize / 6, 
        iconSize / 3, 
        iconSize / 2)
    
    -- 手臂
    love.graphics.rectangle("fill", 
        iconX - iconSize / 3, 
        iconY - iconSize / 6, 
        iconSize / 1.5, 
        iconSize / 6)
    
    -- 腿
    love.graphics.rectangle("fill", 
        iconX - iconSize / 6, 
        iconY + iconSize / 3, 
        iconSize / 12, 
        iconSize / 3)
    love.graphics.rectangle("fill", 
        iconX + iconSize / 12, 
        iconY + iconSize / 3, 
        iconSize / 12, 
        iconSize / 3)
    
    -- 绘制卡牌描述
    love.graphics.setColor(0.9, 0.9, 0.9)
    FontManager.setFont(10)
    love.graphics.printf(self.description, self.x + 5, self.y + 90, self.game.cardSystem.cardWidth - 10, "center")
    
    -- 绘制卡牌消耗
    love.graphics.setColor(0.9, 0.7, 0.3)
    FontManager.setFont(12)
    love.graphics.print("消耗: 食物 " .. self.cost.food, self.x + 5, self.y + self.game.cardSystem.cardHeight - 20)
end

function HumanCard:play(x, y)
    print("人类卡牌: 开始执行play方法，位置: (" .. x .. ", " .. y .. ")")
    
    -- 检查目标位置是否有效
    local tile = self.game.map:getTile(x, y)
    if not tile then
        print("人类卡牌: 无效的位置")
        return false
    end
    
    print("人类卡牌: 地形类型: " .. self.game.map.TILE_NAMES[tile.type])
    
    -- 检查是否是可行走的地形
    if tile.type == self.game.map.TILE_TYPES.WATER or 
       tile.type == self.game.map.TILE_TYPES.MOUNTAIN then
        print("人类卡牌: 不可行走的地形")
        return false
    end
    
    -- 检查是否有足够的资源
    print("人类卡牌: 检查资源，需要食物: " .. self.cost.food)
    if not self.game.resourceManager:useResource("food", self.cost.food) then
        print("人类卡牌: 食物不足")
        return false
    end
    
    print("人类卡牌: 所有条件满足，开始创建人类")
    
    -- 创建人类
    local human = self.game:addEntity("human", x, y, {})
    
    if human then
        -- 增加人口
        self.game.resourceManager:addResource("population", 1)
        
        print("人类卡牌: 成功创建了一个人类，当前人口: " .. self.game.resourceManager:getResource("population"))
        return true
    else
        print("人类卡牌: 创建人类失败")
        return false
    end
end

return HumanCard 