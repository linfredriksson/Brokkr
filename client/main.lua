local anim8 = require "anim8"
local Net = require "Net"

local players = {}
local grid = nil

function love.load()
	Net:init("client")
	Net:connect("127.0.0.1", 6789)
	Net:setMaxPing(1000)

	Net:registerCMD("showLocation",
		function(table, param, dt, id)
			table["Param"] = nil
			table["Command"] = nil

			for k, v in pairs(table) do
				if players[k] == nil then -- initiate if not done already
					players[k] = {}
					players[k].animation = {}
					players[k].animation[0] = anim8.newAnimation(grid("1-3", 1), 0.2)
					players[k].animation[1] = anim8.newAnimation(grid("1-3", 4), 0.2)
					players[k].animation[2] = anim8.newAnimation(grid("1-3", 3), 0.2)
					players[k].animation[3] = anim8.newAnimation(grid("1-3", 2), 0.2)
				end
				
				-- player is still in the network
				players[k].alive = true

				players[k].x, players[k].y, players[k].direction, players[k].isMoving = v:match("^(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*)$")
			end

			for k, v in pairs(players) do
				if players[k].alive == false then
					players[k] = nil
				else
					players[k].alive = false
				end
			end

		end)

	sound = love.audio.newSource("sound/footstep01.ogg")

	tileset = love.graphics.newImage("img/example_tiles.png")
	local tilesetWidth = tileset:getWidth();
	local tilesetHeight = tileset:getHeight();
	tileWidth = 64
	tileHeight = 64

	tiles = {}
	tiles[0] = love.graphics.newQuad(0, 0, tileWidth, tileHeight, tilesetWidth, tilesetHeight)
	tiles[1] = love.graphics.newQuad(tileWidth, 0, tileWidth, tileHeight, tilesetWidth, tilesetHeight)
	tiles[2] = love.graphics.newQuad(0, tileHeight, tileWidth, tileHeight, tilesetWidth, tilesetHeight)
	tiles[3] = love.graphics.newQuad(tileWidth,	tileHeight, tileWidth, tileHeight, tilesetWidth, tilesetHeight)

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
		x = love.graphics.getWidth() * 0.5 - 16, y = love.graphics.getHeight() * 0.5 - 16, direction = 0, speed = 100,
		keyUp = "up", keyDown = "down", keyRight = "right", keyLeft = "left",
		spritesheet = love.graphics.newImage("img/characters1.png"),
		animation = {}
	}

	grid = anim8.newGrid(32, 32, player.spritesheet:getWidth(), player.spritesheet:getHeight())
	player.animation[0] = anim8.newAnimation(grid("1-3", 1), 0.2)
	player.animation[1] = anim8.newAnimation(grid("1-3", 4), 0.2)
	player.animation[2] = anim8.newAnimation(grid("1-3", 3), 0.2)
	player.animation[3] = anim8.newAnimation(grid("1-3", 2), 0.2)
end

function love.keypressed(key)
	if key == "escape" then
		Net:disconnect() 
		love.event.quit()
	end

	if key == "w" then
		love.audio.play(sound)
	end

	if key == "up" or key == "down" or key == "right" or key == "left" then
		Net:send({}, "key_pressed", key, Net.client.ip)
		--print("key_pressed: " .. key)
	end
end

function love.keyreleased(key)
	if key == "up" or key == "down" or key == "right" or key == "left" then
		Net:send({}, "key_released", key, Net.client.ip)
		--print("key_released: " .. key)
	end
end

function love.update(dt)
	for k, v in pairs(players) do
		if v.isMoving == "1" then
			v.animation[tonumber(v.direction)]:update(dt)
			--sound:play()
		else
			v.animation[tonumber(v.direction)]:gotoFrame(2)
		end
	end

	if love.keyboard.isDown(player.keyUp, player.keyDown, player.keyRight, player.keyLeft) then
		player.animation[player.direction]:update(dt)
		--sound:play()
	else
		player.animation[player.direction]:gotoFrame(2)
	end

	local x = player.x
	local y = player.y
	if love.keyboard.isDown(player.keyUp)		then player.direction = 1; y = y - dt * player.speed end
	if love.keyboard.isDown(player.keyDown)	then player.direction = 0; y = y + dt * player.speed end
	if love.keyboard.isDown(player.keyLeft)	then player.direction = 3; x = x - dt * player.speed end
	if love.keyboard.isDown(player.keyRight)then player.direction = 2; x = x + dt * player.speed end
	--local intX = math.floor((x + 16) / love.graphics.getWidth() * (12))
	--local intY = math.floor((y + 16) / love.graphics.getHeight() * (8))
	--if map[intY + 1][intX + 1] == 0 then player.x = x; player.y = y end
	player.x = x
	player.y = y

	Net:update(dt)
end

function love.draw()
	-- draw map
	for y = 1, #map  do
		local row = map[y]
		for x = 1, #row do
			love.graphics.draw(tileset, tiles[map[y][x]], x * tileWidth - tileWidth, y * tileHeight - tileHeight)
		end
	end

	-- draw all players
	for k, v in pairs(players) do
		v.animation[tonumber(v.direction)]:draw(player.spritesheet, v.x, v.y)
	end

	-- draw player
	player.animation[player.direction]:draw(player.spritesheet, player.x, player.y)

	-- print hello world
	--love.graphics.print("Hello World", love.graphics.getWidth() * 0.5 - 35, love.graphics.getHeight() * 0.5 - 5)
end
