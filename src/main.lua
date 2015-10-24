local anim8 = require "anim8"

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
	
	animatedImage = love.graphics.newImage("img/characters1.png")
	local grid = anim8.newGrid(32, 32, animatedImage:getWidth(), animatedImage:getHeight())
	animation = {}
	animation[0] = anim8.newAnimation(grid("1-3", 1), 0.2)
	animation[1] = anim8.newAnimation(grid("1-3", 4), 0.2)
	animation[2] = anim8.newAnimation(grid("1-3", 3), 0.2)
	animation[3] = anim8.newAnimation(grid("1-3", 2), 0.2)
	
	animation[0]:update(0.1)
	animation[1]:update(0.2)
	animation[2]:update(0.0)
	animation[3]:update(0.3)
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.update(dt)
	animation[0]:update(dt)
	animation[1]:update(dt)
	animation[2]:update(dt)
	animation[3]:update(dt)
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	for y = 1, mapHeight  do
		for x = 1, mapWidth do
			local id = map[y][x]
			love.graphics.draw(tileset, tiles[id], x * tileWidth - tileWidth, y * tileHeight - tileHeight)
		end
	end
	
	animation[0]:draw(animatedImage, 80, 80)
	animation[1]:draw(animatedImage, 80 + 64, 80)
	animation[2]:draw(animatedImage, 80 + 128, 80)
	animation[3]:draw(animatedImage, 80 + 192, 80)
	
	love.graphics.setColor(255, 255, 255)
    love.graphics.print("Hello World", love.graphics.getWidth() * 0.5 - 35, love.graphics.getHeight() * 0.5 - 5)
end