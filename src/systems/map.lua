-- 地图系统
local Map = {}
Map.__index = Map

-- 地形类型
Map.TILE_TYPES = {
    EMPTY = 1,
    GRASS = 2,
    WATER = 3,
    SAND = 4,
    FOREST = 5,
    MOUNTAIN = 6,
    FARM = 7,
    HOUSE = 8
}

-- 地形颜色
Map.TILE_COLORS = {
    [Map.TILE_TYPES.EMPTY] = {0.8, 0.8, 0.8},
    [Map.TILE_TYPES.GRASS] = {0.2, 0.8, 0.2},
    [Map.TILE_TYPES.WATER] = {0.2, 0.2, 0.9},
    [Map.TILE_TYPES.SAND] = {0.9, 0.9, 0.5},
    [Map.TILE_TYPES.FOREST] = {0.0, 0.5, 0.0},
    [Map.TILE_TYPES.MOUNTAIN] = {0.5, 0.5, 0.5},
    [Map.TILE_TYPES.FARM] = {0.8, 0.6, 0.2},
    [Map.TILE_TYPES.HOUSE] = {0.8, 0.2, 0.2}
}

-- 地形名称
Map.TILE_NAMES = {
    [Map.TILE_TYPES.EMPTY] = "空地",
    [Map.TILE_TYPES.GRASS] = "草地",
    [Map.TILE_TYPES.WATER] = "水域",
    [Map.TILE_TYPES.SAND] = "沙地",
    [Map.TILE_TYPES.FOREST] = "森林",
    [Map.TILE_TYPES.MOUNTAIN] = "山脉",
    [Map.TILE_TYPES.FARM] = "农田",
    [Map.TILE_TYPES.HOUSE] = "房屋"
}

function Map:new(game, width, height)
    local self = setmetatable({}, Map)
    
    -- 保存对游戏实例的引用
    self.game = game
    
    -- 设置默认值或使用传入的值
    self.width = width or 100  -- 默认宽度100
    self.height = height or 100  -- 默认高度100
    self.tileSize = 24 -- 每个瓦片的像素大小，从16增加到24
    self.offsetX = 0 -- 地图偏移量
    self.offsetY = 0
    self.tiles = {} -- 地图瓦片数据
    
    -- 初始化地图数据
    for y = 1, self.height do
        self.tiles[y] = {}
        for x = 1, self.width do
            self.tiles[y][x] = {
                type = Map.TILE_TYPES.EMPTY,
                moisture = 0,
                fertility = 0,
                temperature = 20,
                resources = {}
            }
        end
    end
    
    return self
end

function Map:generateMap(width, height)
    -- 简单的地图生成算法
    -- 这里可以使用更复杂的噪声函数来生成更自然的地形
    self.width = width
    self.height = height
    
    -- 初始化地图数据
    for y = 1, height do
        self.tiles[y] = {}
        for x = 1, width do
            self.tiles[y][x] = {
                type = Map.TILE_TYPES.EMPTY,
                moisture = 0,
                fertility = 0,
                temperature = 20,
                resources = {}
            }
        end
    end
    
    -- 生成随机地形
    for y = 1, height do
        for x = 1, width do
            local rand = math.random()
            if rand < 0.3 then
                self.tiles[y][x].type = Map.TILE_TYPES.GRASS
            elseif rand < 0.4 then
                self.tiles[y][x].type = Map.TILE_TYPES.WATER
            elseif rand < 0.5 then
                self.tiles[y][x].type = Map.TILE_TYPES.SAND
            elseif rand < 0.6 then
                self.tiles[y][x].type = Map.TILE_TYPES.FOREST
            elseif rand < 0.7 then
                self.tiles[y][x].type = Map.TILE_TYPES.MOUNTAIN
            end
        end
    end
    
    print("地图生成成功: " .. width .. "x" .. height)
end

function Map:createWaterBody(centerX, centerY, size)
    for y = math.max(1, centerY - size), math.min(self.height, centerY + size) do
        for x = math.max(1, centerX - size), math.min(self.width, centerX + size) do
            local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)
            if distance <= size and math.random() < 0.7 then
                self.tiles[y][x].type = Map.TILE_TYPES.WATER
                self.tiles[y][x].moisture = 1.0
                
                -- 在水域周围创建沙地
                self:createSandAroundWater(x, y)
            end
        end
    end
end

function Map:createSandAroundWater(waterX, waterY)
    for y = math.max(1, waterY - 1), math.min(self.height, waterY + 1) do
        for x = math.max(1, waterX - 1), math.min(self.width, waterX + 1) do
            if self.tiles[y][x].type ~= Map.TILE_TYPES.WATER and math.random() < 0.4 then
                self.tiles[y][x].type = Map.TILE_TYPES.SAND
            end
        end
    end
end

function Map:createForest(centerX, centerY, size)
    for y = math.max(1, centerY - size), math.min(self.height, centerY + size) do
        for x = math.max(1, centerX - size), math.min(self.width, centerX + size) do
            local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)
            if distance <= size and math.random() < 0.6 and self.tiles[y][x].type == Map.TILE_TYPES.GRASS then
                self.tiles[y][x].type = Map.TILE_TYPES.FOREST
            end
        end
    end
end

function Map:createMountain(centerX, centerY, size)
    for y = math.max(1, centerY - size), math.min(self.height, centerY + size) do
        for x = math.max(1, centerX - size), math.min(self.width, centerX + size) do
            local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)
            if distance <= size and math.random() < 0.7 and self.tiles[y][x].type ~= Map.TILE_TYPES.WATER then
                self.tiles[y][x].type = Map.TILE_TYPES.MOUNTAIN
            end
        end
    end
end

function Map:update(dt)
    -- 更新地图状态，例如水分蒸发、温度变化等
    -- 这里可以添加更复杂的地形变化逻辑
end

function Map:draw()
    love.graphics.push()
    love.graphics.translate(self.offsetX, self.offsetY)
    
    -- 绘制地图瓦片
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            local color = Map.TILE_COLORS[tile.type]
            
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", 
                (x - 1) * self.tileSize, 
                (y - 1) * self.tileSize, 
                self.tileSize, 
                self.tileSize)
            
            -- 绘制瓦片边框
            love.graphics.setColor(0, 0, 0, 0.2)
            love.graphics.rectangle("line", 
                (x - 1) * self.tileSize, 
                (y - 1) * self.tileSize, 
                self.tileSize, 
                self.tileSize)
        end
    end
    
    love.graphics.pop()
end

function Map:getTile(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return nil
    end
    return self.tiles[y][x]
end

function Map:setTile(x, y, tileType)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return false
    end
    
    self.tiles[y][x].type = tileType
    return true
end

function Map:screenToTile(screenX, screenY)
    local tileX = math.floor((screenX - self.offsetX) / self.tileSize) + 1
    local tileY = math.floor((screenY - self.offsetY) / self.tileSize) + 1
    
    -- 只在鼠标释放时打印日志，避免过多输出
    if love.mouse.isDown(1) then
        print("屏幕坐标 (" .. screenX .. ", " .. screenY .. ") 转换为地图坐标 (" .. tileX .. ", " .. tileY .. ")")
    end
    
    if tileX < 1 or tileX > self.width or tileY < 1 or tileY > self.height then
        if love.mouse.isDown(1) then
            print("地图坐标超出范围")
        end
        return nil, nil
    end
    
    local tile = self.tiles[tileY][tileX]
    if love.mouse.isDown(1) then
        print("地图坐标 (" .. tileX .. ", " .. tileY .. ") 的地形类型: " .. self.TILE_NAMES[tile.type])
    end
    
    return tileX, tileY
end

function Map:tileToScreen(tileX, tileY)
    local screenX = (tileX - 1) * self.tileSize + self.offsetX
    local screenY = (tileY - 1) * self.tileSize + self.offsetY
    return screenX, screenY
end

function Map:moveOffset(dx, dy)
    self.offsetX = self.offsetX + dx
    self.offsetY = self.offsetY + dy
end

function Map:applyWeather(weatherType, centerX, centerY, radius)
    -- 应用天气效果到地图
    if weatherType == "rain" then
        for y = math.max(1, centerY - radius), math.min(self.height, centerY + radius) do
            for x = math.max(1, centerX - radius), math.min(self.width, centerX + radius) do
                local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)
                if distance <= radius then
                    local tile = self.tiles[y][x]
                    tile.moisture = math.min(1.0, tile.moisture + 0.3)
                    
                    -- 雨水可能会将空地变成草地
                    if tile.type == Map.TILE_TYPES.EMPTY and math.random() < 0.3 then
                        tile.type = Map.TILE_TYPES.GRASS
                    end
                end
            end
        end
        return true
    elseif weatherType == "sun" then
        for y = math.max(1, centerY - radius), math.min(self.height, centerY + radius) do
            for x = math.max(1, centerX - radius), math.min(self.width, centerX + radius) do
                local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)
                if distance <= radius then
                    local tile = self.tiles[y][x]
                    tile.temperature = tile.temperature + 5
                    tile.moisture = math.max(0, tile.moisture - 0.2)
                    
                    -- 阳光可能会将水域变成沙地
                    if tile.type == Map.TILE_TYPES.WATER and math.random() < 0.1 then
                        tile.type = Map.TILE_TYPES.SAND
                    end
                end
            end
        end
        return true
    elseif weatherType == "wind" then
        -- 风可以传播种子，增加森林生成概率
        for y = math.max(1, centerY - radius), math.min(self.height, centerY + radius) do
            for x = math.max(1, centerX - radius), math.min(self.width, centerX + radius) do
                local distance = math.sqrt((x - centerX)^2 + (y - centerY)^2)
                if distance <= radius then
                    local tile = self.tiles[y][x]
                    
                    -- 风可能会将草地变成森林
                    if tile.type == Map.TILE_TYPES.GRASS and math.random() < 0.1 then
                        tile.type = Map.TILE_TYPES.FOREST
                    end
                end
            end
        end
        return true
    end
    
    return false
end

return Map 