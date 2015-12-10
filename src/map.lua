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
	self:addTile(tiles, false, false, 1, 1, world, tileset)

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
		Where probability sums up to 1
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
	-- just to be safe, return the first value if all else fails
	return table[1].id
end

--[[ Returns a empty map with only walls around the border. ]]
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

--[[ Returns a map with walls randomly placed, as well as a border around the map. ]]
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

	for y = 2, height - 1 do
		for x = 2, width - 1 do
			if math.random() < floorRate then
				m[y][x] = self:random(floor)
			else
				m[y][x] = self:random(wall)
			end
		end
	end

	return m
end

--[[ Returns a full map with only empty spaces where the characters start. ]]
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
