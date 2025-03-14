-- 测试实体创建
local Human = nil
local Plant = nil
local Tree = nil

-- 创建一个模拟的游戏对象
local game = {
    map = {
        tileSize = 16,
        tileToScreen = function(self, x, y)
            return x * self.tileSize, y * self.tileSize
        end
    },
    resourceManager = {
        getResource = function(self, resourceType)
            return 100
        end,
        addResource = function(self, resourceType, amount)
            return true
        end
    }
}

function love.load()
    print("加载测试...")
    
    -- 尝试加载实体类
    local success, result = pcall(function()
        Human = require("src.entities.human")
        Plant = require("src.entities.plant")
        Tree = require("src.entities.tree")
        return true
    end)
    
    if not success then
        print("加载实体类失败: " .. tostring(result))
        return
    end
    
    print("实体类加载成功")
    
    -- 测试创建人类
    testHuman()
    
    -- 测试创建植物
    testPlant()
    
    -- 测试创建树木
    testTree()
    
    print("测试完成")
end

-- 测试创建人类
function testHuman()
    print("测试创建人类...")
    local success, result = pcall(function()
        local human = Human:new(game, 1, 10, 10, {})
        if human then
            print("人类创建成功: " .. human.type .. ", ID=" .. human.id)
            return human
        else
            print("人类创建失败")
            return nil
        end
    end)
    
    if not success then
        print("创建人类时发生错误: " .. tostring(result))
    end
end

-- 测试创建植物
function testPlant()
    print("测试创建植物...")
    local success, result = pcall(function()
        local plant = Plant:new(game, 2, 15, 15, {plantType = "flower"})
        if plant then
            print("植物创建成功: " .. plant.type .. ", ID=" .. plant.id .. ", 类型=" .. plant.plantType)
            return plant
        else
            print("植物创建失败")
            return nil
        end
    end)
    
    if not success then
        print("创建植物时发生错误: " .. tostring(result))
    end
end

-- 测试创建树木
function testTree()
    print("测试创建树木...")
    local success, result = pcall(function()
        local tree = Tree:new(game, 3, 20, 20, {treeType = "oak"})
        if tree then
            print("树木创建成功: " .. tree.type .. ", ID=" .. tree.id .. ", 类型=" .. tree.treeType)
            return tree
        else
            print("树木创建失败")
            return nil
        end
    end)
    
    if not success then
        print("创建树木时发生错误: " .. tostring(result))
    end
end

function love.update(dt)
    -- 空函数
end

function love.draw()
    love.graphics.print("查看控制台输出", 10, 10)
end 