local anim8 = require 'lib.anim8'

local HumanAnimation = {}
HumanAnimation.__index = HumanAnimation

-- 定义人类状态常量，与Human实体保持一致
HumanAnimation.STATE = {
    IDLE = "idle",
    MOVING = "moving",
    GATHERING = "gathering",
    BUILDING = "building",
    FARMING = "farming",
    RESTING = "resting"
}

function HumanAnimation:new()
    local self = setmetatable({}, HumanAnimation)
    
    -- 精灵表尚未加载
    self.spritesheet = nil
    self.animations = {}
    self.currentAnimation = nil
    self.flipped = false  -- 是否翻转（朝向）
    
    -- 默认尺寸
    self.width = 16
    self.height = 24
    
    return self
end

function HumanAnimation:load(resourceManager)
    -- 加载精灵表
    if resourceManager then
        self.spritesheet = resourceManager:getImage('human_spritesheet')
    end
    
    -- 如果精灵表不存在，创建一个简单的像素艺术人类
    if not self.spritesheet then
        self:createDefaultSpritesheet()
    end
    
    -- 设置动画
    self:setupAnimations()
end

function HumanAnimation:createDefaultSpritesheet()
    -- 创建一个基本的人类精灵表
    -- 图像尺寸：4列 x 6行，每帧16x24像素
    local spriteWidth, spriteHeight = 16, 24
    local cols, rows = 4, 6
    local imgWidth, imgHeight = spriteWidth * cols, spriteHeight * rows
    
    self.spritesheet = love.graphics.newCanvas(imgWidth, imgHeight)
    
    love.graphics.setCanvas(self.spritesheet)
    love.graphics.clear()
    
    -- 绘制不同状态的简单像素人类
    -- 行1：空闲状态
    -- 行2：移动状态
    -- 行3：收集状态
    -- 行4：建造状态
    -- 行5：农耕状态
    -- 行6：休息状态
    
    -- 设置像素艺术模式
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- 循环绘制每一帧
    for row = 0, rows-1 do
        for col = 0, cols-1 do
            local x = col * spriteWidth
            local y = row * spriteHeight
            
            -- 绘制人类基本形状
            self:drawHumanFrame(x, y, row, col)
        end
    end
    
    -- 重置画布
    love.graphics.setCanvas()
end

function HumanAnimation:drawHumanFrame(x, y, row, col)
    -- 基本颜色
    local skinColor = {0.9, 0.7, 0.5}    -- 皮肤颜色
    local hairColor = {0.2, 0.1, 0.0}    -- 头发颜色
    local clothesColor = {0.3, 0.5, 0.9} -- 衣服颜色
    local pantsColor = {0.2, 0.2, 0.6}   -- 裤子颜色
    
    -- 头部和头发
    love.graphics.setColor(skinColor)
    love.graphics.rectangle("fill", x+5, y+1, 6, 6) -- 头部
    
    love.graphics.setColor(hairColor)
    love.graphics.rectangle("fill", x+5, y+1, 6, 2) -- 头发
    
    -- 身体 (衣服)
    love.graphics.setColor(clothesColor)
    love.graphics.rectangle("fill", x+4, y+7, 8, 10)
    
    -- 腿 (裤子)
    love.graphics.setColor(pantsColor)
    if row == 1 then -- 移动状态
        -- 走路动画
        local legOffset = col % 2 == 0 and 1 or -1
        love.graphics.rectangle("fill", x+4, y+17, 3, 6)
        love.graphics.rectangle("fill", x+9, y+17, 3, 6 - legOffset)
    else
        -- 默认站立
        love.graphics.rectangle("fill", x+4, y+17, 3, 6)
        love.graphics.rectangle("fill", x+9, y+17, 3, 6)
    end
    
    -- 手臂 (皮肤)
    love.graphics.setColor(skinColor)
    if row == 2 then -- 收集状态
        -- 收集动画：手臂抬起
        love.graphics.rectangle("fill", x+2, y+8, 2, 6)
        love.graphics.rectangle("fill", x+12, y+8, 2, (col % 2 == 0) and 4 or 6)
    elseif row == 3 then -- 建造状态
        -- 建造动画：双手抬起
        local armHeight = (col % 2 == 0) and 4 or 6
        love.graphics.rectangle("fill", x+2, y+8, 2, armHeight)
        love.graphics.rectangle("fill", x+12, y+8, 2, armHeight)
    elseif row == 4 then -- 农耕状态
        -- 农耕动画：手臂向下
        love.graphics.rectangle("fill", x+2, y+8, 2, 8)
        love.graphics.rectangle("fill", x+12, y+8, 2, 8)
    elseif row == 5 then -- 休息状态
        -- 休息动画：手臂放松
        love.graphics.rectangle("fill", x+2, y+10, 2, 4)
        love.graphics.rectangle("fill", x+12, y+10, 2, 4)
    else
        -- 默认手臂
        love.graphics.rectangle("fill", x+2, y+8, 2, 7)
        love.graphics.rectangle("fill", x+12, y+8, 2, 7)
    end
    
    -- 根据不同的状态和帧数增加细节
    if row == 0 then -- 空闲状态
        -- 呼吸效果
        if col == 1 or col == 3 then
            love.graphics.setColor(clothesColor)
            love.graphics.rectangle("fill", x+4, y+7, 8, 11) -- 身体稍微变高
        end
    end
    
    -- 面部细节
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x+6, y+3, 1, 1) -- 左眼
    love.graphics.rectangle("fill", x+9, y+3, 1, 1) -- 右眼
    
    -- 嘴巴
    if col % 2 == 0 then
        love.graphics.rectangle("fill", x+7, y+5, 2, 1) -- 闭嘴
    else
        love.graphics.rectangle("fill", x+7, y+5, 2, 1) -- 开嘴
        love.graphics.setColor(0.7, 0.1, 0.1)
        love.graphics.rectangle("fill", x+7, y+5, 1, 1) -- 红色嘴巴内部
    end
    
    -- 根据状态添加特殊效果或道具
    if row == 2 then -- 收集状态
        if col % 2 == 0 then
            love.graphics.setColor(0.6, 0.4, 0.1)
            love.graphics.rectangle("fill", x+13, y+5, 2, 4) -- 采集工具
        end
    elseif row == 3 then -- 建造状态
        if col % 2 == 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", x+14, y+6, 2, 4) -- 锤子头
            love.graphics.setColor(0.6, 0.4, 0.1)
            love.graphics.rectangle("fill", x+14, y+10, 1, 3) -- 锤子柄
        end
    elseif row == 4 then -- 农耕状态
        if col % 2 == 0 then
            love.graphics.setColor(0.6, 0.4, 0.1)
            love.graphics.rectangle("fill", x+1, y+15, 1, 6) -- 农具柄
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", x+0, y+15, 2, 2) -- 农具头
        end
    end
end

function HumanAnimation:setupAnimations()
    -- 使用anim8库设置动画
    local g = anim8.newGrid(self.width, self.height, self.spritesheet:getWidth(), self.spritesheet:getHeight())
    
    -- 创建各种状态的动画
    self.animations = {
        [HumanAnimation.STATE.IDLE] = anim8.newAnimation(g('1-4', 1), 0.5),
        [HumanAnimation.STATE.MOVING] = anim8.newAnimation(g('1-4', 2), 0.2),
        [HumanAnimation.STATE.GATHERING] = anim8.newAnimation(g('1-4', 3), 0.3),
        [HumanAnimation.STATE.BUILDING] = anim8.newAnimation(g('1-4', 4), 0.3),
        [HumanAnimation.STATE.FARMING] = anim8.newAnimation(g('1-4', 5), 0.4),
        [HumanAnimation.STATE.RESTING] = anim8.newAnimation(g('1-4', 6), 0.6)
    }
    
    -- 设置默认动画
    self.currentAnimation = self.animations[HumanAnimation.STATE.IDLE]
end

function HumanAnimation:update(dt, human)
    -- 根据人类状态更新动画
    if human then
        -- 将人类状态映射到动画状态
        local stateMap = {
            idle = HumanAnimation.STATE.IDLE,
            moving = HumanAnimation.STATE.MOVING,
            gathering = HumanAnimation.STATE.GATHERING,
            building = HumanAnimation.STATE.BUILDING,
            farming = HumanAnimation.STATE.FARMING,
            resting = HumanAnimation.STATE.RESTING
        }
        
        local animationState = stateMap[human.state] or HumanAnimation.STATE.IDLE
        local newAnimation = self.animations[animationState]
        
        if newAnimation ~= self.currentAnimation then
            self.currentAnimation = newAnimation
            self.currentAnimation:gotoFrame(1)
        end
        
        -- 根据移动方向设置翻转
        if human.state == "moving" then
            if human.targetX and human.x then
                self.flipped = (human.targetX < human.x)
            end
        end
    end
    
    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end
end

function HumanAnimation:draw(x, y, scale, color)
    scale = scale or 1
    color = color or {1, 1, 1}
    
    if self.currentAnimation then
        love.graphics.setColor(color)
        
        -- 绘制动画
        self.currentAnimation:draw(
            self.spritesheet, 
            x, 
            y, 
            0, 
            self.flipped and -scale or scale, 
            scale, 
            self.width/2, 
            self.height/2
        )
        
        -- 重置颜色
        love.graphics.setColor(1, 1, 1)
    end
end

return HumanAnimation 