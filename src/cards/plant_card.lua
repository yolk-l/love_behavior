-- 植物卡牌
local PlantCard = {}
PlantCard.__index = PlantCard

local FontManager = require("src.utils.font_manager")

function PlantCard:new(game)
    local self = setmetatable({}, PlantCard)
    
    self.game = game
    self.type = "plant"
    self.name = "植物"
    self.description = "在选定区域种植植物。植物会生长并提供食物。"
    
    -- 卡牌外观
    self.color = {0.2, 0.8, 0.2}
    self.x = 0
    self.y = 0
    
    -- 卡牌效果
    self.effects = {
        "创建一种植物",
        "植物会自然生长",
        "成熟的植物可以提供食物",
        "植物会自然繁殖"
    }
    
    -- 卡牌消耗
    self.cost = {
        faith = 2
    }
    
    return self
end

function PlantCard:update(dt)
    -- 卡牌更新逻辑
end

function PlantCard:draw()
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
    
    -- 绘制卡牌图标（简单的植物图标）
    love.graphics.setColor(self.color)
    local iconX = self.x + self.game.cardSystem.cardWidth / 2
    local iconY = self.y + 50
    local iconSize = 30
    
    -- 茎
    love.graphics.setLineWidth(2)
    love.graphics.line(iconX, iconY + iconSize / 2, iconX, iconY - iconSize / 3)
    
    -- 叶子
    love.graphics.setColor(0.1, 0.7, 0.1)
    love.graphics.ellipse("fill", iconX - iconSize / 4, iconY, iconSize / 4, iconSize / 8)
    love.graphics.ellipse("fill", iconX + iconSize / 4, iconY - iconSize / 6, iconSize / 4, iconSize / 8)
    
    -- 花
    love.graphics.setColor(0.9, 0.5, 0.9)
    for i = 1, 5 do
        local angle = (i - 1) * math.pi * 2 / 5
        local petalX = iconX + math.cos(angle) * iconSize / 6
        local petalY = iconY - iconSize / 3 + math.sin(angle) * iconSize / 6
        love.graphics.circle("fill", petalX, petalY, iconSize / 10)
    end
    
    -- 花蕊
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", iconX, iconY - iconSize / 3, iconSize / 15)
    
    love.graphics.setLineWidth(1)
    
    -- 绘制卡牌描述
    love.graphics.setColor(0.9, 0.9, 0.9)
    FontManager.setFont(10)
    love.graphics.printf(self.description, self.x + 5, self.y + 90, self.game.cardSystem.cardWidth - 10, "center")
    
    -- 绘制卡牌消耗
    love.graphics.setColor(0.9, 0.7, 0.3)
    FontManager.setFont(12)
    love.graphics.print("消耗: 信仰 " .. self.cost.faith, self.x + 5, self.y + self.game.cardSystem.cardHeight - 20)
end

function PlantCard:play(x, y)
    print("植物卡牌: 开始执行play方法，位置: (" .. x .. ", " .. y .. ")")
    
    -- 检查目标位置是否有效
    local tile = self.game.map:getTile(x, y)
    if not tile then
        print("植物卡牌: 无效的位置")
        return false
    end
    
    print("植物卡牌: 地形类型: " .. self.game.map.TILE_NAMES[tile.type])
    
    -- 检查是否是可种植的地形
    if tile.type ~= self.game.map.TILE_TYPES.GRASS and 
       tile.type ~= self.game.map.TILE_TYPES.EMPTY and
       tile.type ~= self.game.map.TILE_TYPES.SAND then
        print("植物卡牌: 不可种植的地形，当前地形: " .. tile.type)
        return false
    end
    
    -- 检查是否有足够的资源
    print("植物卡牌: 检查资源，需要信仰: " .. self.cost.faith)
    if not self.game.resourceManager:useResource("faith", self.cost.faith) then
        print("植物卡牌: 信仰不足")
        return false
    end
    
    print("植物卡牌: 所有条件满足，开始创建植物")
    
    -- 随机选择植物类型
    local plantTypes = {"grass", "flower", "bush", "crop"}
    local plantType = plantTypes[math.random(#plantTypes)]
    print("植物卡牌: 随机选择的植物类型: " .. plantType)
    
    -- 创建植物
    local plant = self.game:addEntity("plant", x, y, {
        plantType = plantType
    })
    
    if plant then
        print("植物卡牌: 成功种植了一株" .. plantType .. "植物")
        return true
    else
        print("植物卡牌: 创建植物失败")
        return false
    end
end

return PlantCard 