local map = {}

function map:chooseMap(mapName, worldTileWidth, worldTileHeight, width, height)
	local map = nil
	if mapName == "empty" then map = emptyMap(width, height)
	else error("There is no such a map called \""..mapName.."\"!")
	end

	local tileset = love.graphics.newImage("image/example_tiles_small.png")
	local tilesetWidth = tileset:getWidth();
	local tilesetHeight = tileset:getHeight();

	tiles = {
		{walkable = true, destructable = false, img = love.graphics.newQuad(0, 0, worldTileWidth, worldTileHeight, tilesetWidth, tilesetHeight)},
		{walkable = true, destructable = false, img = love.graphics.newQuad(worldTileWidth, 0, worldTileWidth, worldTileHeight, tilesetWidth, tilesetHeight)},
		{walkable = true, destructable = false, img = love.graphics.newQuad(0, worldTileHeight, worldTileWidth, worldTileHeight, tilesetWidth, tilesetHeight)},
		{walkable = true, destructable = false, img = love.graphics.newQuad(worldTileWidth, worldTileHeight, worldTileWidth, worldTileHeight, tilesetWidth, tilesetHeight)}
	}

	return tileset, tiles, map
end

function emptyMap(width, height)
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

return map
