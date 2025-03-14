-- 树木卡牌
local TreeCard = {}
TreeCard.__index = TreeCard

local FontManager = require("src.utils.font_manager")

function TreeCard:new(game)
    local self = setmetatable({}, TreeCard)
    
    self.game = game
    self.type = "tree"
    self.name = "树木"
    self.description = "在选定区域种植树木。树木会生长并提供木材，某些树木还会提供食物。"
    
    -- 卡牌外观
    self.color = {0.1, 0.5, 0.1}
    self.x = 0
    self.y = 0
    
    -- 卡牌效果
    self.effects = {
        "创建一棵树",
        "树木会自然生长",
        "成熟的树木可以提供木材",
        "果树可以提供食物",
        "树木会自然繁殖"
    }
    
    -- 卡牌消耗
    self.cost = {
        faith = 3
    }
    
    return self
end

function TreeCard:update(dt)
    -- 卡牌更新逻辑
end

function TreeCard:draw()
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
    
    -- 绘制卡牌图标（简单的树木图标）
    local iconX = self.x + self.game.cardSystem.cardWidth / 2
    local iconY = self.y + 50
    local iconSize = 30
    
    -- 树干
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.rectangle("fill", 
        iconX - iconSize / 8, 
        iconY - iconSize / 6, 
        iconSize / 4, 
        iconSize / 2)
    
    -- 树冠
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", iconX, iconY - iconSize / 3, iconSize / 3)
    
    -- 绘制卡牌描述
    love.graphics.setColor(0.9, 0.9, 0.9)
    FontManager.setFont(10)
    love.graphics.printf(self.description, self.x + 5, self.y + 90, self.game.cardSystem.cardWidth - 10, "center")
    
    -- 绘制卡牌消耗
    love.graphics.setColor(0.9, 0.7, 0.3)
    FontManager.setFont(12)
    love.graphics.print("消耗: 信仰 " .. self.cost.faith, self.x + 5, self.y + self.game.cardSystem.cardHeight - 20)
end

function TreeCard:play(x, y)
    -- 检查目标位置是否有效
    local tile = self.game.map:getTile(x, y)
    if not tile then
        print("树木卡牌: 无效的位置")
        return false
    end
    
    -- 检查是否是可种植的地形
    if tile.type ~= self.game.map.TILE_TYPES.GRASS and 
       tile.type ~= self.game.map.TILE_TYPES.EMPTY and
       tile.type ~= self.game.map.TILE_TYPES.SAND then
        print("树木卡牌: 不可种植的地形")
        return false
    end
    
    -- 检查是否已有植物或树
    local entities = self.game.entityManager:getEntitiesAt(x, y)
    for _, entity in ipairs(entities) do
        if entity.type == "plant" or entity.type == "tree" then
            print("树木卡牌: 该位置已有植物或树")
            return false
        end
    end
    
    -- 检查是否有足够的资源
    if not self.game.resourceManager:useResource("faith", self.cost.faith) then
        print("树木卡牌: 信仰不足")
        return false
    end
    
    -- 随机选择树木类型
    local treeTypes = {"oak", "pine", "apple", "palm"}
    local treeType = treeTypes[math.random(#treeTypes)]
    
    -- 创建树木
    local tree = self.game:addEntity("tree", x, y, {
        treeType = treeType
    })
    
    -- 如果是在草地上种树，有概率将瓦片变为森林
    if tile.type == self.game.map.TILE_TYPES.GRASS and math.random() < 0.5 then
        self.game.map:setTile(x, y, self.game.map.TILE_TYPES.FOREST)
        print("树木卡牌: 草地变成了森林")
    end
    
    print("树木卡牌: 成功种植了一棵" .. treeType .. "树")
    return true
end

return TreeCard 