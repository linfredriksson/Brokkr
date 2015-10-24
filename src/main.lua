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
	
	player = {
		x = 80, y = 80, direction = 0, speed = 100,
		keyUp = "up", keyDown = "down", keyRight = "right", keyLeft = "left",
		spritesheet = love.graphics.newImage("img/characters1.png"),
		animation = {}
	}
	
	local grid = anim8.newGrid(32, 32, player.spritesheet:getWidth(), player.spritesheet:getHeight())
	player.animation[0] = anim8.newAnimation(grid("1-3", 1), 0.2)
	player.animation[1] = anim8.newAnimation(grid("1-3", 4), 0.2)
	player.animation[2] = anim8.newAnimation(grid("1-3", 3), 0.2)
	player.animation[3] = anim8.newAnimation(grid("1-3", 2), 0.2)
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.update(dt)
	if love.keyboard.isDown(player.keyUp, player.keyDown, player.keyRight, player.keyLeft) then
		player.animation[player.direction]:update(dt)
	else
		player.animation[player.direction]:gotoFrame(2)
	end
	
	if love.keyboard.isDown(player.keyUp)		then player.direction = 1; player.y = player.y - dt * player.speed end
	if love.keyboard.isDown(player.keyDown)	then player.direction = 0; player.y = player.y + dt * player.speed end
	if love.keyboard.isDown(player.keyLeft)	then player.direction = 3; player.x = player.x - dt * player.speed end
	if love.keyboard.isDown(player.keyRight)	then player.direction = 2; player.x = player.x + dt * player.speed end
end

function love.draw()
	-- draw map
	for y = 1, #map  do
		local row = map[y]
		for x = 1, #row do
			love.graphics.draw(tileset, tiles[map[y][x]], x * tileWidth - tileWidth, y * tileHeight - tileHeight)
		end
	end

	-- draw player
	player.animation[player.direction]:draw(player.spritesheet, player.x, player.y)
	
	-- print hello world
    love.graphics.print("Hello World", love.graphics.getWidth() * 0.5 - 35, love.graphics.getHeight() * 0.5 - 5)
end