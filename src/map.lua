local noise = require "noise"
local map = {tileWidth = 0}

--[[
	Create a map.
	- mapName: name of the type of map to create.
	- tileWidth: the width in pixels of the tiles.
	- tileHeight: the height in pixels of the tiles.
	- mapWidth: the number of tiles the map should be wide.
	- mapHeight: the number of tiles the map should be high.
	- seed: seed used for random functions. Same seed always give same maps.
]]
map.create = function(self, imageName, mapName, tileWidth, tileHeight, mapWidth, mapHeight, seed)
	local tileset = love.graphics.newImage(imageName)

	map.name = mapName
	map.width = mapWidth
	map.height = mapHeight
	map.tileWidth = tileWidth
	map.tileHeight = tileHeight
	map.tileset = {}
	map.tileset.image = tileset
	map.tileset.width = tileset:getWidth()
	map.tileset.height = tileset:getHeight()
	map.values = nil
	map.seed = seed or 0

	map.tiles = {}
	self:addTile(true, false, 0, 3)
	self:addTile(true, false, 1, 3)
	self:addTile(false, false, 2, 3)--wall
	self:addTile(false, true, 3, 3)--wall
	self:addTile(true, false, 0, 4)
	self:addTile(true, false, 1, 4)
	self:addTile(true, false, 2, 4)
	self:addTile(true, false, 3, 4)
	self:addTile(false, false, 4, 3)--wall

	if map.name == "empty" then
		map.values = map:emptyMap(3, 1)
	elseif map.name == "lobby" then
		map.values = map:lobbyMap(3, 1, 2, 2)
	elseif map.name == "full" then
		map.values = map:fullMap(3)
	elseif map.name == "random" then
		map.values = map:randomMap(map.seed)
	else
		error("There is no such a map called \""..map.name.."\"!")
	end
end

--[[
	Add a tile.
	- inWalkable: true/false depending on walkable or not. Walls should be false.
	- inDestructable: true/false indicating if the tile is destructable or not.
	- tileX: tile number in tile atlas.
	- tileY: tile number in tile atlas.
]]
map.addTile = function(self, inWalkable, inDestructable, tileX, tileY)
	map.tiles[#map.tiles + 1] = {
		walkable = inWalkable,
		destructable = inDestructable,
		img = love.graphics.newQuad(
			map.tileWidth * tileX,
			map.tileHeight * tileY,
			map.tileWidth,
			map.tileHeight,
			map.tileset.width,
			map.tileset.height)
	}
end

--[[
	Change value of a map element.
	- inX: column id.
	- inY: row id.
	- inValue: new tile id for element.
]]
map.setValue = function(self, inX, inY, inValue)
	if inX >= 1 and inX <= map.width and
		inY >= 1 and inY <= map.height and
		inValue >= 1 and inValue <= #map.tiles
	then
		map.values[inY][inX] = inValue
	end
end

--[[
	Returns 1 if map tile at (inX, inY) is walkable, else nil.
	- inX: tiles x coordinate in map.
	- inY: tiles y coordinate in map.
]]
map.isWalkable = function(self, inX, inY)
	if inX >= 1 and inX <= map.width and inY >= 1 and inY <= map.height then
		if self.tiles[map.values[inY][inX]].walkable then
			return 1
		end
	end
	return nil
end

--[[
	Returns 1 if map tile at (inX, inY) is destructable, else nil.
	- inX: tiles x coordinate in map.
	- inY: tiles y coordinate in map.
]]
map.isDestructable = function(self, inX, inY)
	if inX >= 1 and inX <= map.width and inY >= 1 and inY <= map.height then
		if self.tiles[map.values[inY][inX]].destructable then
			return 1
		end
	end
	return nil
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
	- wallID: id of wall tile.
	- floorID: id of floor tile.
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
	Returns a empty map with walls around the border. A center square of the floor
	have a different tile to indicate location of map that all players have to
	stand on to start a new game round.
	- wallID: the id of the wall tile.
	- floorID1: the id of the floor tile that will cover all of the floor.
	- floorID2: the id of the floor tile that will be the center square.
	- squareSize: the radius of the center square.
]]
map.lobbyMap = function (self, wallID, floorID1, floorID2, squareSize)
	-- fill map with walls
	local m = self:fullMap(wallID)
	local halfHeight = map.height * 0.5
	local halfWidth = map.width * 0.5

	-- fill everything except border with floors
	for row = 2, map.height - 1 do
		for col = 2, map.width - 1 do
			m[row][col] = floorID1
			if row > halfHeight - squareSize and row < halfHeight + squareSize + 1 and col > halfWidth - squareSize and col < halfWidth + squareSize + 1 then
				m[row][col] = floorID2
			end
		end
	end

	return m
end

--[[
	Returns map filled with tiles of tileID.
	- tileID: id of tile that will fill the map.
]]
map.fullMap = function(self, tileID)
	local m = {}

	for row = 1, map.height do
		m[row] = {}
		for col = 1, map.width do
			m[row][col] = tileID
		end
	end

	return m
end

--[[
	Returns a map with walls randomly placed, as well as a border around the map.
]]
map.randomMap = function(self)
	local m = self:emptyMap(3, 1)
	local floorRate = 0.8
	local wall = {
		{id = 3, probability = .75},
		{id = 4, probability = .25}
	}
	local floor = {
		{id = 1, probability = 0.80},
		{id = 5, probability = 0.05},
		{id = 6, probability = 0.05},
		{id = 7, probability = 0.05},
		{id = 8, probability = 0.05},
	}

	local windowWidth = love.graphics.getWidth()
	local windowHeight = love.graphics.getHeight()
	noise:setSize(windowWidth, windowHeight)

	-- generate noise and use it to place walls and floors
	noise:generate(map.seed)
	for y = 2, map.height - 1 do
		for x = 2, map.width - 1 do
			local posX = math.floor((x / map.width) * windowWidth)
			local posY = math.floor((y / map.height) * windowHeight)
			m[y][x] = wall[1].id
			if noise:turbulence(posX + 16, posY + 16, 64) < 0.9 then
				m[y][x] = self:random(floor)
			end
		end
	end

	-- generate new noise and use it to change wall types where there is walls
	-- and change floor types where there is floors
	noise:generate(map.seed + 100)
	for y = 2, map.height - 1 do
		for x = 2, map.width - 1 do
			local posX = math.floor((x / map.width) * windowWidth)
			local posY = math.floor((y / map.height) * windowHeight)
			if noise:turbulence(posX + 16, posY + 16, 64) < 0.9 then
				m[y][x] = wall[2].id
			end
		end
	end
	m = self:clearStartAreas(m, 2, map.width, map.height)
	m = self:destructableSimplePath(m, wall[2].id, 1)

	return m
end

--[[
	Create paths of destructive walls between the four corner starting areas to
	make sure paths exist between all starting areas.
	- m: initial map
	- wallID: tile id of wanted destructable wall
	- distanceToEdge: the distance between the map borders and the destructive path.
]]
map.destructableSimplePath = function(self, m, wallID, distanceToEdge)
	local bottom = map.height - distanceToEdge
	local top = 1 + distanceToEdge
	local right = map.width - distanceToEdge
	local left = 1 + distanceToEdge

	for i = 2, map.height - 1 do
		if not map.tiles[m[i][left]].walkable then m[i][left] = wallID end
		if not map.tiles[m[i][right]].walkable then m[i][right] = wallID end
	end

	for i = 2, map.width - 1 do
		if not map.tiles[m[top][i]].walkable then m[top][i] = wallID end
		if not map.tiles[m[bottom][i]].walkable then m[bottom][i] = wallID end
	end

	return m
end

--[[
	Puts floor times on the corners in a map, used to free starting areas from walls.
	- m: the map that will be modified.
	- floorID: the tile id of wanted floor.
	- width: width of map.
	- height: height of map.
]]
map.clearStartAreas = function(self, m, floorID, width, height)
	local cols = 3
	for col = 1, cols do
		for row = 1, col do
			m[cols - col + 2][row + 1] = floorID -- top left
			m[cols - col + 2][map.width - row] = floorID -- top right
			m[map.height - cols + col - 1][row + 1] = floorID -- bottom left
			m[map.height - cols + col - 1][map.width - row] = floorID -- bottom right
		end
	end

	-- center square
	local w = math.floor(width / 2)
	local h = math.floor(height / 2)
	m[h + 0][w + 0] = floorID
	m[h + 1][w + 0] = floorID
	m[h + 0][w + 1] = floorID
	m[h + 1][w + 1] = floorID

	return m
end

return map
