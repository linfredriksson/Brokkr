local noise = require "noise"
local map = {}

function map:chooseMap(mapName, world)
	local tileset = love.graphics.newImage("image/example_tiles_small.png")
	local tilesetWidth = tileset:getWidth();
	local tilesetHeight = tileset:getHeight();

	tiles = {}
	self:addTile(tiles, true, false, 0, 0, world, tileset)
	self:addTile(tiles, true, false, 1, 0, world, tileset)
	self:addTile(tiles, false, false, 0, 1, world, tileset)
	self:addTile(tiles, false, true, 1, 1, world, tileset)

	--map.values = m
	map.width = world.width
	map.height = world.height
	map.tiles = tiles
	map.tileset = {
		image = tileset,
		width = tilesetWidth,
		height = tilesetHeight
	}

	local m = nil
	if mapName == "empty" then
		m = map:emptyMap(2, 0)
	elseif mapName == "full" then
		m = map:fullMap(2)
	elseif mapName == "random" then
		m = map:randomMap()
	else
		error("There is no such a map called \""..mapName.."\"!")
	end

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
map.emptyMap = function (self, wallID, floorID)
	-- fill map with walls
	local m = self:fullMap(wallID)

	-- fill everything except border with floors
	for row = 2, map.height - 1 do
		for col = 2, map.width - 1 do
			m[row][col] = floorID
		end
	end

	return m
end

--[[
	Returns map filled with tiles of tileID.
]]
map.fullMap = function(self, tileID)
	local m = {}

	for y = 1, map.height do
		m[y] = {}
		for x = 1, map.width do
			m[y][x] = tileID
		end
	end

	return m
end

--[[
	Returns a map with walls randomly placed, as well as a border around the map.
]]
map.randomMap = function(self)
	local m = self:emptyMap(2, 0)
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
	for y = 2, map.height - 1 do
		for x = 2, map.width - 1 do
			local posX = math.floor((x / map.width) * windowWidth)
			local posY = math.floor((y / map.height) * windowHeight)
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
	for y = 2, map.height - 1 do
		for x = 2, map.width - 1 do
			local posX = math.floor((x / map.width) * windowWidth)
			local posY = math.floor((y / map.height) * windowHeight)
			if noise:turbulence(posX + 16, posY + 16, 64) < 0.9 then
				if m[y][x] == floor[1].id then
					m[y][x] = floor[2].id
				else
					m[y][x] = wall[2].id
				end
			end
		end
	end
	m = self:clearStartAreas(m, self:random(floor), map.width, map.height)
	m = self:destructableSimplePath(m, wall[2].id, tiles, map.width, map.height)

	return m
end

--[[
	Create paths of destructive walls between the four corner starting areas to
	make sure paths exist between all starting areas.
	- m: initial map
	- wallID: tile id of wanted destructable wall
	- tiles: list of existing tiles
	- width: width of map
	- height: height of map
]]
map.destructableSimplePath = function(self, m, wallID, tiles, width, height)
	local bottom = height - 1
	local top = 2
	local right = width - 1
	local left = 2

	for i = 2, height - 1 do
		if not tiles[m[i][left] + 1].walkable then m[i][left] = wallID end
		if not tiles[m[i][right] + 1].walkable then m[i][right] = wallID end
	end

	for i = 2, width - 1 do
		if not tiles[m[top][i] + 1].walkable then m[top][i] = wallID end
		if not tiles[m[bottom][i] + 1].walkable then m[bottom][i] = wallID end
	end

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

return map
