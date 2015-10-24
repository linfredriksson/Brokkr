function love.load()	
	tileset = love.graphics.newImage("img/example_tiles.png")	
	local tilesetWidth = tileset:getWidth();
	local tilesetHeight = tileset:getHeight();
	tileWidth = 64
	tileHeight = 64
	
	tiles = {}
	tiles[0] = love.graphics.newQuad(0,                        0, tileWidth, tileHeight, tilesetWidth, tilesetHeight)
	tiles[1] = love.graphics.newQuad(tileWidth,             0, tileWidth, tileHeight, tilesetWidth, tilesetHeight)
	tiles[2] = love.graphics.newQuad(0,            tileHeight, tileWidth, tileHeight, tilesetWidth, tilesetHeight)
	tiles[3] = love.graphics.newQuad(tileWidth, tileHeight, tileWidth, tileHeight, tilesetWidth, tilesetHeight)
	
	mapWidth = 12
	mapHeight = 8
	map = {
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

function love.update()
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	for y = 1, mapHeight  do
		for x = 1, mapWidth do
			local id = map[y][x]
			love.graphics.draw(tileset, tiles[id], x * tileWidth - tileWidth, y * tileHeight - tileHeight)
		end
	end
	
	love.graphics.setColor(255, 255, 255)
    love.graphics.print("Hello World", love.graphics.getWidth() * 0.5 - 35, love.graphics.getHeight() * 0.5 - 5)
end