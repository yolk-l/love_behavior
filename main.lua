-- 主游戏文件
-- 导入所需模块
local Game = require("src.game")
local FontManager = require("src.utils.font_manager")

-- 全局游戏实例
local game

function love.load()
    -- 使用字体管理器设置默认字体
    FontManager.setFont(16)
    print("中文字体加载成功")
    
    -- 设置随机数种子
    math.randomseed(os.time())
    
    -- 初始化游戏
    game = Game:new()
    game:load()
    
    -- 打印游戏启动信息
    print("游戏已启动")
end

function love.update(dt)
    -- 更新游戏状态
    game:update(dt)
end

function love.draw()
    -- 绘制游戏
    game:draw()
end

function love.mousepressed(x, y, button)
    print("鼠标按下事件: x=" .. x .. ", y=" .. y .. ", button=" .. button)
    game:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    print("鼠标释放事件: x=" .. x .. ", y=" .. y .. ", button=" .. button)
    game:mousereleased(x, y, button)
end

function love.keypressed(key)
    print("按键按下: " .. key)
    game:keypressed(key)
end

function love.keyreleased(key)
    game:keyreleased(key)
end 