-- 天气卡牌
local WeatherCard = {}
WeatherCard.__index = WeatherCard

local FontManager = require("src.utils.font_manager")

function WeatherCard:new(game, weatherType)
    local self = setmetatable({}, WeatherCard)
    
    self.game = game
    self.type = "weather"
    self.weatherType = weatherType or "rain" -- rain, sun, wind
    
    -- 根据天气类型设置卡牌属性
    if self.weatherType == "rain" then
        self.name = "降雨"
        self.description = "在选定区域降下雨水，增加土地湿度，促进植物生长，可能将空地变成草地。"
        self.color = {0.2, 0.4, 0.8}
        self.effects = {
            "增加土地湿度",
            "促进植物生长",
            "可能将空地变成草地"
        }
        self.cost = {
            faith = 5
        }
        self.radius = 5
    elseif self.weatherType == "sun" then
        self.name = "阳光"
        self.description = "在选定区域增强阳光，提高温度，加速植物生长，可能将水域变成沙地。"
        self.color = {0.9, 0.8, 0.2}
        self.effects = {
            "提高温度",
            "加速植物生长",
            "可能将水域变成沙地"
        }
        self.cost = {
            faith = 5
        }
        self.radius = 4
    elseif self.weatherType == "wind" then
        self.name = "风"
        self.description = "在选定区域刮起风，传播种子，增加森林生成概率。"
        self.color = {0.7, 0.7, 0.7}
        self.effects = {
            "传播种子",
            "增加森林生成概率"
        }
        self.cost = {
            faith = 3
        }
        self.radius = 6
    end
    
    -- 卡牌位置
    self.x = 0
    self.y = 0
    
    return self
end

function WeatherCard:update(dt)
    -- 卡牌更新逻辑
end

function WeatherCard:draw()
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
    
    -- 绘制卡牌图标
    love.graphics.setColor(self.color)
    local iconX = self.x + self.game.cardSystem.cardWidth / 2
    local iconY = self.y + 50
    local iconSize = 30
    
    if self.weatherType == "rain" then
        -- 绘制雨滴
        for i = 1, 6 do
            local dropX = iconX - iconSize / 2 + (i - 1) * iconSize / 5
            local dropY = iconY - iconSize / 3 + (i % 2) * iconSize / 3
            
            love.graphics.setColor(0.2, 0.4, 0.8)
            love.graphics.circle("fill", dropX, dropY, 3)
            love.graphics.setColor(0.4, 0.6, 0.9)
            love.graphics.circle("fill", dropX, dropY, 2)
        end
        
        -- 绘制云
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.circle("fill", iconX - iconSize / 3, iconY - iconSize / 2, iconSize / 5)
        love.graphics.circle("fill", iconX, iconY - iconSize / 2, iconSize / 4)
        love.graphics.circle("fill", iconX + iconSize / 3, iconY - iconSize / 2, iconSize / 5)
    elseif self.weatherType == "sun" then
        -- 绘制太阳
        love.graphics.setColor(0.9, 0.8, 0.2)
        love.graphics.circle("fill", iconX, iconY, iconSize / 3)
        
        -- 绘制光芒
        for i = 1, 8 do
            local angle = (i - 1) * math.pi / 4
            local rayX1 = iconX + math.cos(angle) * iconSize / 3
            local rayY1 = iconY + math.sin(angle) * iconSize / 3
            local rayX2 = iconX + math.cos(angle) * iconSize / 1.5
            local rayY2 = iconY + math.sin(angle) * iconSize / 1.5
            
            love.graphics.setLineWidth(2)
            love.graphics.line(rayX1, rayY1, rayX2, rayY2)
            love.graphics.setLineWidth(1)
        end
    elseif self.weatherType == "wind" then
        -- 绘制风
        love.graphics.setColor(0.7, 0.7, 0.7)
        
        for i = 1, 3 do
            local y = iconY - iconSize / 3 + (i - 1) * iconSize / 3
            
            -- 绘制波浪线
            local points = {}
            for j = 0, 6 do
                local x = iconX - iconSize / 2 + j * iconSize / 6
                local yOffset = math.sin(j * math.pi / 3) * iconSize / 10
                table.insert(points, x)
                table.insert(points, y + yOffset)
            end
            
            love.graphics.setLineWidth(2)
            love.graphics.line(points)
            love.graphics.setLineWidth(1)
        end
    end
    
    -- 绘制卡牌描述
    love.graphics.setColor(0.9, 0.9, 0.9)
    FontManager.setFont(10)
    love.graphics.printf(self.description, self.x + 5, self.y + 90, self.game.cardSystem.cardWidth - 10, "center")
    
    -- 绘制卡牌消耗
    love.graphics.setColor(0.9, 0.7, 0.3)
    FontManager.setFont(12)
    love.graphics.print("消耗: 信仰 " .. self.cost.faith, self.x + 5, self.y + self.game.cardSystem.cardHeight - 20)
end

function WeatherCard:play(x, y)
    -- 检查目标位置是否有效
    local tile = self.game.map:getTile(x, y)
    if not tile then
        print("天气卡牌: 无效的位置")
        return false
    end
    
    -- 检查是否有足够的资源
    if not self.game.resourceManager:useResource("faith", self.cost.faith) then
        print("天气卡牌: 信仰不足")
        return false
    end
    
    -- 应用天气效果
    local success = self.game.map:applyWeather(self.weatherType, x, y, self.radius)
    
    if success then
        print("天气卡牌: 成功应用了" .. self.name .. "效果")
    else
        print("天气卡牌: 应用效果失败")
    end
    
    return success
end

return WeatherCard 