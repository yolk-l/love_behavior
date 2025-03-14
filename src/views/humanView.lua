-- 人类视图组件
local HumanView = {}
HumanView.__index = HumanView

-- 导入动画组件
local HumanAnimation = require("src.graphics.human_animation")

function HumanView:new()
    local self = setmetatable({}, HumanView)
    -- 创建人类动画
    self.animation = HumanAnimation:new()
    -- 加载动画资源
    if love.graphics then  -- 防止在没有LÖVE环境的情况下报错
        self.animation:load()
    end
    return self
end

-- 绘制人类实体
function HumanView:draw(human)
    -- 检查实体和游戏对象是否存在
    if not human or not human.game or not human.game.map then
        print("错误: 无法绘制人类实体，人类实体或游戏地图不存在")
        return
    end
    
    local map = human.game.map
    -- 使用realX和realY进行平滑显示
    local screenX, screenY
    
    if human.realX and human.realY then
        screenX, screenY = map:tileToScreen(human.realX, human.realY)
    else
        -- 向后兼容没有realX和realY的情况
        screenX, screenY = map:tileToScreen(human.x, human.y)
    end
    
    -- 绘制在瓦片中心
    screenX = screenX + map.tileSize / 2
    screenY = screenY + map.tileSize / 2
    
    -- 更新动画状态
    self.animation:update(0.033, human)  -- 假设大约30FPS
    
    -- 绘制人类动画
    self.animation:draw(screenX, screenY, 1.5, human.color)
    
    -- 绘制健康状态条
    self:drawHealthBar(human, map, screenX, screenY)
    
    -- 根据状态绘制不同的状态指示器
    self:drawStateIndicator(human, screenX, screenY)
    
    -- 绘制运动动画效果
    if human.state == "moving" then
        self:drawMovementEffect(human, screenX, screenY)
    end
end

-- 根据状态绘制状态指示器
function HumanView:drawStateIndicator(human, screenX, screenY)
    local Human = require("src/entities/human") -- 导入Human模块以访问状态常量
    
    -- 根据不同状态设置不同颜色
    if human.state == Human.STATE.GATHERING then
        love.graphics.setColor(0.2, 0.8, 0.2) -- 收集资源为绿色
    elseif human.state == Human.STATE.BUILDING then
        love.graphics.setColor(0.8, 0.8, 0.2) -- 建造为黄色
    elseif human.state == Human.STATE.FARMING then
        love.graphics.setColor(0.2, 0.8, 0.8) -- 耕种为青色
    elseif human.state == Human.STATE.RESTING then
        love.graphics.setColor(0.5, 0.5, 0.8) -- 休息为蓝色
    elseif human.state == Human.STATE.MOVING then
        love.graphics.setColor(0.8, 0.5, 0.2) -- 移动为橙色
    else -- IDLE状态
        love.graphics.setColor(0.5, 0.5, 0.5) -- 空闲为灰色
    end
    
    -- 绘制状态指示环
    love.graphics.circle("line", screenX, screenY, 12)
end

-- 绘制健康状态条
function HumanView:drawHealthBar(human, map, screenX, screenY)
    local healthBarWidth = map.tileSize * 0.8
    local healthBarHeight = 3
    local healthBarX = screenX - healthBarWidth / 2
    local healthBarY = screenY - human.size - 5
    
    -- 背景
    love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight)
    
    -- 健康值
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth * (human.health / 100), healthBarHeight)
    
    -- 如果饥饿度高，显示饥饿指示器
    if human.hunger > 60 then
        local hungerBarY = healthBarY + healthBarHeight + 1
        love.graphics.setColor(0.8, 0.6, 0.0, 0.7)
        love.graphics.rectangle("fill", healthBarX, hungerBarY, healthBarWidth * (human.hunger / 100), healthBarHeight)
    end
end

-- 绘制移动动画效果
function HumanView:drawMovementEffect(human, screenX, screenY)
    -- 绘制移动效果，例如脚印或移动指示线
    -- 根据移动方向绘制一些小点或线条
    love.graphics.setColor(0.8, 0.5, 0.2, 0.5)
    
    if human.targetX and human.targetY then
        local dirX = 0
        local dirY = 0
        
        if human.targetX > human.x then
            dirX = 1
        elseif human.targetX < human.x then
            dirX = -1
        end
        
        if human.targetY > human.y then
            dirY = 1
        elseif human.targetY < human.y then
            dirY = -1
        end
        
        -- 如果有方向，绘制移动指示
        if dirX ~= 0 or dirY ~= 0 then
            -- 绘制一些移动痕迹点
            for i = 1, 3 do
                local offsetX = -dirX * i * 3
                local offsetY = -dirY * i * 3
                love.graphics.circle("fill", screenX + offsetX, screenY + offsetY, 2)
            end
        end
    end
end

-- 可以添加更多绘制方法，例如：
-- 绘制人物信息标签
function HumanView:drawLabel(human, screenX, screenY)
    -- 实现绘制名称、职业等信息
end

-- 绘制人物动画
function HumanView:drawAnimation(human, screenX, screenY, dt)
    -- 实现绘制动画效果
end

return HumanView 