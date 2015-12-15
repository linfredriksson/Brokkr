local noise = require "noise"
local map = {}

function map:chooseMap(mapName, world)
	local m = nil
	if mapName == "empty" then
		m = map:emptyMap(world.width, world.height)
	elseif mapName == "full" then
		m = map:fullMap(world.width, world.height)
	elseif mapName == "random" then
		m = map:randomMap(world.width, world.height)
	else
		error("There is no such a map called \""..mapName.."\"!")
	end

	local tileset = love.graphics.newImage("image/example_tiles_small.png")
	local tilesetWidth = tileset:getWidth();
	local tilesetHeight = tileset:getHeight();

	tiles = {}
	self:addTile(tiles, true, false, 0, 0, world, tileset)
	self:addTile(tiles, true, false, 1, 0, world, tileset)
	self:addTile(tiles, false, false, 0, 1, world, tileset)
	self:addTile(tiles, false, true, 1, 1, world, tileset)

	return {tileset = tileset, tiles = tiles, values = m}
end

--[[
	Add a tile.
]]
map.addTile = function(self, tiles, inWalkable, inDestructable, tileX, tileY, world, tileset)
	tiles[#tiles + 1] = {
		walkable = inWalkable,
		destructable = inDestructable,
		img = love.graphics.newQuad(
			world.tileWidth * tileX,
			world.tileHeight * tileY,
			world.tileWidth,
			world.tileHeight,
			tileset:getWidth(),
			tileset:getHeight())
	}
end

--[[
	Return a random id based on probabilities stored in table
	- inTable: table of structure
		{
			{id = id1, probability = p1},
			{id = id2, probability = p2}
		}
		Where probability sums up to 1.
]]
map.random = function(self, inTable)
	local p = math.random()
	local cumulativeProbability = 0
	for key, v in pairs(inTable) do
		cumulativeProbability = cumulativeProbability + v.probability
		if p <= cumulativeProbability then
			return v.id
		end
	end
	-- incase probability dont sum up to 1 or table is empty
	if #table > 0 then return table[1].id end
	return -1
end

--[[
	Returns a empty map with only walls around the border.
]]
map.emptyMap = function (self, width, height)
	local m = {}
	local wall = 2
	local floor = 0

	for y = 1, height do
		m[y]= {}
		for x = 1, width do m[y][x] = floor end
		m[y][width] = wall
		m[y][1] = wall
	end

	for i = 1, width do
		m[height][i] = wall
		m[1][i] = wall
	end

	return m
end

--[[
	Returns a map with walls randomly placed, as well as a border around the map.
]]
map.randomMap = function(self, width, height)
	local m = self:emptyMap(width, height)
	local floorRate = 0.8
	local wall = {
		{id = 2, probability = .75},
		{id = 3, probability = .25}
	}
	local floor = {
		{id = 0, probability = 0.85},
		{id = 1, probability = 0.15}
	}

	local windowWidth = love.graphics.getWidth()
	local windowHeight = love.graphics.getHeight()
	noise:setSize(windowWidth, windowHeight)

	-- generate noise and use it to place walls and floors
	noise:generate(os.time())
	for y = 2, height - 1 do
		for x = 2, width - 1 do
			local posX = math.floor((x / width) * windowWidth)
			local posY = math.floor((y / height) * windowHeight)
			if noise:turbulence(posX + 16, posY + 16, 64) < 0.9 then
				m[y][x] = floor[1].id
			else
				m[y][x] = wall[1].id
			end
		end
	end

	-- generate new noise and use it to change wall types where there is walls
	-- and change floor types where there is floors
	noise:generate(os.time() + 100)
	for y = 2, height - 1 do
		for x = 2, width - 1 do
			local posX = math.floor((x / width) * windowWidth)
			local posY = math.floor((y / height) * windowHeight)
			if noise:turbulence(posX + 16, posY + 16, 64) < 0.9 then
				if m[y][x] == floor[1].id then
					m[y][x] = floor[2].id
				else
					m[y][x] = wall[2].id
				end
			end
		end
	end
	m = self:clearStartAreas(m, self:random(floor), width, height)

	return m
end

--[[
	Puts floor times on the corners in a map, used to free starting areas from walls.
	- floorID: the tile id of wanted floor.
	- width: width of map.
	- height: height of map.
]]
map.clearStartAreas = function(self, m, floorID, width, height)
	for i = 0, 2 do -- line of 3 floor
		m[2][2 + i] = floorID                  -- top left
		m[height - 1][2 + i] = floorID         -- bottom left
		m[2][width - 1 - i] = floorID          -- topRight
		m[height - 1][width - 1 - i] = floorID -- bottomRight
	end

	for i = 0, 1 do -- line of 2 floor
		m[3][2 + i] = floorID
		m[height - 2][2 + i] = floorID
		m[3][width - 1 - i] = floorID
		m[height - 2][width - 1 - i] = floorID
	end

	m[4][2] = floorID -- one floor
	m[height - 3][2] = floorID
	m[4][width - 1] = floorID
	m[height - 3][width - 1] = floorID

	-- center square
	local w = math.floor(width / 2)
	local h = math.floor(height / 2)
	print(w .. ":" .. h)
	m[h + 0][w + 0] = floorID
	m[h + 1][w + 0] = floorID
	m[h + 0][w + 1] = floorID
	m[h + 1][w + 1] = floorID

	return m
end

--[[
	Returns a full map with only empty spaces where the characters start.
]]
map.fullMap = function(self, width, height)
	local m = {}
	local wall = {
		{id = 2, probability = .75},
		{id = 3, probability = .25}
	}
	local floor = {
		{id = 0, probability = 0.85},
		{id = 1, probability = 0.15}
	}

	for y = 1, height do
		m[y] = {}
		for x = 1, width do m[y][x] = self:random(wall) end
	end

	local offset = {{0, 0}, {0, 1}, {1, 0}, {1, 1}}
	for i = 1, 4 do
		m[offset[i][1] + 2][offset[i][2] + 2] = self:random(floor)
		m[offset[i][1] + 2][-offset[i][2] + width - 1] = self:random(floor)
		m[-offset[i][1] + height - 1][offset[i][2] + 2] = self:random(floor)
		m[-offset[i][1] + height - 1][-offset[i][2] + width - 1] = self:random(floor)
	end

	return m
end

return map
