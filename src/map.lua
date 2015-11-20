local map = {}

function map:chooseMap(mapName, worldTileWidth, worldTileHeight)
	local map = nil
	if mapName == "example" then map = exampleMap()
	else error("There is no such a map called \""..mapName.."\"!") 
	end

	local tileset = love.graphics.newImage("image/example_tiles.png")
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

function exampleMap()
	return {
		{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2},
		{2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
		{2, 0, 3, 0, 0, 0, 0, 0, 0, 3, 0, 2},
		{2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
		{2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
		{2, 0, 3, 0, 0, 0, 0, 0, 0, 3, 0, 2},
		{2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
		{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2}
	}
end

return map
