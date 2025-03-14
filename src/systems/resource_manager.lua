-- 资源管理系统
local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager:new()
    local self = setmetatable({}, ResourceManager)
    
    -- 资源类型及初始值
    self.resources = {
        population = 0,    -- 人口
        food = 0,          -- 食物
        wood = 0,          -- 木材
        stone = 0,         -- 石头
        knowledge = 0,     -- 知识
        faith = 0          -- 信仰
    }
    
    -- 资源上限
    self.resourceLimits = {
        population = 10,   -- 初始人口上限
        food = 100,        -- 初始食物上限
        wood = 100,        -- 初始木材上限
        stone = 100,       -- 初始石头上限
        knowledge = 100,   -- 初始知识上限
        faith = 100        -- 初始信仰上限
    }
    
    -- 资源生产率（每秒）
    self.resourceRates = {
        population = 0,
        food = 0,
        wood = 0,
        stone = 0,
        knowledge = 0,
        faith = 0
    }
    
    -- 资源消耗率（每秒）
    self.resourceConsumption = {
        population = 0,
        food = 0,
        wood = 0,
        stone = 0,
        knowledge = 0,
        faith = 0
    }
    
    -- 资源更新计时器
    self.updateTimer = 0
    self.updateInterval = 1.0 -- 资源更新间隔（秒）
    
    return self
end

function ResourceManager:initResources()
    -- 初始化资源
    self.resources = {
        population = 0,    -- 人口
        food = 50,        -- 初始食物
        wood = 30,        -- 初始木材
        stone = 20,       -- 初始石头
        knowledge = 0,    -- 初始知识
        faith = 0         -- 初始信仰
    }
    
    -- 重置资源生产率
    self.resourceRates = {
        population = 0,
        food = 0,
        wood = 0,
        stone = 0,
        knowledge = 0,
        faith = 0
    }
    
    -- 重置资源消耗率
    self.resourceConsumption = {
        population = 0,
        food = 0,
        wood = 0,
        stone = 0,
        knowledge = 0,
        faith = 0
    }
    
    print("资源系统初始化成功")
end

function ResourceManager:update(dt)
    -- 资源自动更新
    self.updateTimer = self.updateTimer + dt
    if self.updateTimer >= self.updateInterval then
        self:updateResources()
        self.updateTimer = 0
    end
end

function ResourceManager:updateResources()
    -- 更新所有资源
    for resource, rate in pairs(self.resourceRates) do
        local netRate = rate - self.resourceConsumption[resource]
        self:addResource(resource, netRate * self.updateInterval)
    end
    
    -- 人口消耗食物
    local foodPerPerson = 0.1 -- 每人每秒消耗的食物
    local foodConsumption = self.resources.population * foodPerPerson * self.updateInterval
    self:useResource("food", foodConsumption)
    
    -- 如果食物不足，人口减少
    if self.resources.food <= 0 then
        local populationLoss = math.min(1, self.resources.population * 0.05)
        self:addResource("population", -populationLoss)
    end
end

function ResourceManager:getResource(resourceType)
    return self.resources[resourceType] or 0
end

function ResourceManager:setResource(resourceType, amount)
    if self.resources[resourceType] ~= nil then
        self.resources[resourceType] = math.max(0, math.min(amount, self.resourceLimits[resourceType]))
        return true
    end
    return false
end

function ResourceManager:addResource(resourceType, amount)
    if self.resources[resourceType] ~= nil then
        local newAmount = self.resources[resourceType] + amount
        self.resources[resourceType] = math.max(0, math.min(newAmount, self.resourceLimits[resourceType]))
        return true
    end
    return false
end

function ResourceManager:useResource(resourceType, amount)
    if self.resources[resourceType] ~= nil and amount > 0 then
        print("尝试使用资源: " .. resourceType .. " 数量: " .. amount .. " 当前拥有: " .. self.resources[resourceType])
        if self.resources[resourceType] >= amount then
            self.resources[resourceType] = self.resources[resourceType] - amount
            print("资源使用成功，剩余 " .. resourceType .. ": " .. self.resources[resourceType])
            return true
        else
            print("资源不足，无法使用")
        end
    else
        print("无效的资源类型或数量: " .. resourceType .. " 数量: " .. amount)
    end
    return false
end

function ResourceManager:setResourceRate(resourceType, rate)
    if self.resourceRates[resourceType] ~= nil then
        self.resourceRates[resourceType] = rate
        return true
    end
    return false
end

function ResourceManager:setResourceConsumption(resourceType, rate)
    if self.resourceConsumption[resourceType] ~= nil then
        self.resourceConsumption[resourceType] = rate
        return true
    end
    return false
end

function ResourceManager:increaseResourceLimit(resourceType, amount)
    if self.resourceLimits[resourceType] ~= nil then
        self.resourceLimits[resourceType] = self.resourceLimits[resourceType] + amount
        return true
    end
    return false
end

function ResourceManager:getResourceLimit(resourceType)
    return self.resourceLimits[resourceType] or 0
end

function ResourceManager:getResourceRate(resourceType)
    return self.resourceRates[resourceType] or 0
end

function ResourceManager:getNetResourceRate(resourceType)
    return (self.resourceRates[resourceType] or 0) - (self.resourceConsumption[resourceType] or 0)
end

-- 每日资源更新
function ResourceManager:updateDailyResources()
    print("执行每日资源更新...")
    
    -- 此处可以添加一些每日特殊的资源更新逻辑
    -- 比如一些资源可能每天固定增加一定量
    
    -- 信仰值每天增加一些
    local faithIncrease = 5 + math.floor(self.resources.population / 2)
    self:addResource("faith", faithIncrease)
    print("每日信仰增加: " .. faithIncrease)
    
    -- 知识值每天可能增加一些，基于人口
    local knowledgeIncrease = math.floor(self.resources.population * 0.2)
    if knowledgeIncrease > 0 then
        self:addResource("knowledge", knowledgeIncrease)
        print("每日知识增加: " .. knowledgeIncrease)
    end
    
    -- 更新每日的资源状态
    self:updateResources()
end

return ResourceManager 