-- 视图管理器
local ViewManager = {}
ViewManager.__index = ViewManager

-- 引入视图组件
local HumanView = require("src.views.humanView")
local PlantView = require("src.views.plantView")
local TreeView = require("src.views.treeView")

function ViewManager:new(game)
    local self = setmetatable({}, ViewManager)
    
    self.game = game
    
    -- 初始化各种实体的视图组件
    self.humanView = HumanView:new()
    self.plantView = PlantView:new()
    self.treeView = TreeView:new()
    
    -- 将来可以添加更多的视图组件
    -- self.plantView = PlantView:new()
    -- self.treeView = TreeView:new()
    -- ...
    
    print("视图管理器初始化成功")
    
    return self
end

function ViewManager:draw()
    -- 从实体管理器获取所有实体
    local entities = self.game.entityManager.entities
    
    -- 根据实体类型选择对应的视图组件进行绘制
    for id, entity in pairs(entities) do
        if entity.type == "human" then
            self.humanView:draw(entity)
        elseif entity.type == "plant" then
            self.plantView:draw(entity)
        elseif entity.type == "tree" then
            self.treeView:draw(entity)
        else
            -- 对于未知类型的实体，如果它们有自己的绘制方法，则使用它们自己的方法
            if entity.draw then
                entity:draw()
            end
        end
    end
end

-- 添加更多视图相关的方法
function ViewManager:drawDebugInfo()
    -- 绘制视图系统的调试信息
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("视图系统正在运行", 10, 200)
end

return ViewManager 