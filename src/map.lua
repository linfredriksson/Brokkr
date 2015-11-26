local map = {}

function map:chooseMap(mapName, world)
	local m = nil
	if mapName == "empty" then m = map:emptyMap(world.width, world.height)
	elseif mapName == "full" then m = map:fullMap(world.width, world.height)
	else error("There is no such a map called \""..mapName.."\"!")
	end

	local tileset = love.graphics.newImage("image/example_tiles_small.png")
	local tilesetWidth = tileset:getWidth();
	local tilesetHeight = tileset:getHeight();

	tiles = {
		{walkable = true, destructable = false, img = love.graphics.newQuad(0, 0, world.tileWidth, world.tileHeight, tilesetWidth, tilesetHeight)},
		{walkable = true, destructable = false, img = love.graphics.newQuad(world.tileWidth, 0, world.tileWidth, world.tileHeight, tilesetWidth, tilesetHeight)},
		{walkable = true, destructable = false, img = love.graphics.newQuad(0, world.tileHeight, world.tileWidth, world.tileHeight, tilesetWidth, tilesetHeight)},
		{walkable = true, destructable = false, img = love.graphics.newQuad(world.tileWidth, world.tileHeight, world.tileWidth, world.tileHeight, tilesetWidth, tilesetHeight)}
	}

	return tileset, tiles, m
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

--[[ Returns a full map with only empty spaces where the characters start. ]]
map.fullMap = function(self, width, height)
	local m = {}
	local wall = 2
	local floor = 0

	for y = 1, height do
		m[y] = {}
		for x = 1, width do m[y][x] = wall end
	end

	local offset = {{0, 0}, {0, 1}, {1, 0}, {1, 1}}
	for i = 1, 4 do
		m[offset[i][1] + 2][offset[i][2] + 2] = floor
		m[offset[i][1] + 2][-offset[i][2] + width - 1] = floor
		m[-offset[i][1] + height - 1][offset[i][2] + 2] = floor
		m[-offset[i][1] + height - 1][-offset[i][2] + width - 1] = floor
	end

	return m
end

return map
