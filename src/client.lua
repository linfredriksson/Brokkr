local anim8 = require "dependencies/anim8"
local Net = require "dependencies/Net"
local Map = require "map"
local client = {}

math.randomseed(os.time())

client.load = function(self)
	self.window = {width = love.graphics.getWidth(), height = love.graphics.getHeight()}
	self.players = {}
	self.characterTile = {grid = nil, width = 32, height = 32}
	self.world = {tileWidth = 32, tileHeight = 32, width = 24, height= 16}
	self.ip, self.port, self.maxPing = "127.0.0.1", 6789, 1000
	self.map = {name = "empty"} -- empety is the default value

	-- Define keys for different actions
	self.actions = {up = "up", down = "down", left = "left", right = "right", bomb = " "}

	-- Inverse of self.action, used to check if a pressed key is bound to a action
	self.keys = {}
	for k, v in pairs(self.actions) do self.keys[v] = k end

	Net:init("client")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)

	Net:registerCMD("getMapName",
		function(table, param, dt, id)
			self.map.name = table["map"]
			self.map.received = true
		end)

	Net:registerCMD("showLocation",
		function(table, param, dt, id)

			table["Param"] = nil
			table["Command"] = nil

			for k, v in pairs(table) do
				if self.players[k] == nil then -- initiate if not done already
					self.players[k] = {}
					self.players[k].animation = self:generateCharacterAnimation(1, 0.6)
				end

				-- player is still in the network
				self.players[k].alive = true
				self.players[k].x, self.players[k].y, self.players[k].direction, self.players[k].isMoving = v:match("^(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*)$")
			end

			for k, v in pairs(self.players) do
				if self.players[k].alive == false then
					self.players[k] = nil
				else
					self.players[k].alive = false
				end
			end

		end)

	self.sound = love.audio.newSource("sound/footstep01.ogg")

	-- Set the default map
	self.map.tileset, self.map.tiles, self.map.values = Map:chooseMap(self.map.name, self.world)

	self.player = {
		x = self.window.width * 0.5 - self.characterTile.width * 0.5, y = self.window.height * 0.5 - self.characterTile.height * 0.5,
		direction = 1, speed = 100,
		spritesheet = love.graphics.newImage("image/characters1.png"),
		animation = {}
	}

	self.characterTile.grid = anim8.newGrid(self.characterTile.width, self.characterTile.height, self.player.spritesheet:getWidth(), self.player.spritesheet:getHeight())
	self.player.animation = self:generateCharacterAnimation(1, 0.6)
end

client.generateRandomCharacterAnimation = function(self, duration)
	return self:generateCharacterAnimation(math.random(7), duration)
end

client.generateCharacterAnimation = function(self, id, duration)
	local frameDuration = duration / 3
	local row = math.floor(id / 5) * 4
	local col = (id - 1) % 4
	col = 1 + col * 3 .. "-" .. 3 + col * 3
	return {
		anim8.newAnimation(self.characterTile.grid(col, row + 1), frameDuration),
		anim8.newAnimation(self.characterTile.grid(col, row + 4), frameDuration),
		anim8.newAnimation(self.characterTile.grid(col, row + 3), frameDuration),
		anim8.newAnimation(self.characterTile.grid(col, row + 2), frameDuration)
	}
end

client.mousepressed = function(self, x, y, button)
end

client.keypressed = function(self, key)
	if key == "escape" then
		Net:disconnect()
		love.event.quit()
	end

	if self.keys[key] ~= nil then
		Net:send({}, "key_pressed", self.keys[key], Net.client.ip)
	end
end

client.keyreleased = function(self, key)
	if self.keys[key] ~= nil then
		Net:send({}, "key_released", self.keys[key], Net.client.ip)
	end
end

client.update = function(self, dt)
	for k, v in pairs(self.players) do
		if v.isMoving == "1" then
			v.animation[tonumber(v.direction)]:update(dt)
			--sound:play()
		else
			v.animation[tonumber(v.direction)]:gotoFrame(2)
		end
	end

	if love.keyboard.isDown(self.actions.up, self.actions.down, self.actions.right, self.actions.left) then
		self.player.animation[self.player.direction]:update(dt)
		--sound:play()
	else
		self.player.animation[self.player.direction]:gotoFrame(2)
	end

	if love.keyboard.isDown(self.actions.up) then self.player.direction = 2; self.player.y = self.player.y - dt * self.player.speed end
	if love.keyboard.isDown(self.actions.down) then self.player.direction = 1; self.player.y = self.player.y + dt * self.player.speed end
	if love.keyboard.isDown(self.actions.left) then self.player.direction = 4; self.player.x = self.player.x - dt * self.player.speed end
	if love.keyboard.isDown(self.actions.right) then self.player.direction = 3; self.player.x = self.player.x + dt * self.player.speed end

	Net:update(dt)

	-- Update the map
	if self.map.received then
		self.map.tileset, self.map.tiles, self.map.values = Map:chooseMap(self.map.name, self.world)
		self.map.received = false -- Server sends the message once anyway
	end
end

client.draw = function(self)
	-- draw map
	for y = 1, #self.map.values  do
		for x = 1, #self.map.values[y] do
			love.graphics.draw(self.map.tileset, self.map.tiles[self.map.values[y][x] + 1].img, x * self.world.tileWidth - self.world.tileWidth, y * self.world.tileHeight - self.world.tileHeight)
		end
	end

	-- draw all players
	for k, v in pairs(self.players) do
		v.animation[tonumber(v.direction)]:draw(self.player.spritesheet, v.x, v.y)
	end

	-- draw player
	self.player.animation[self.player.direction]:draw(self.player.spritesheet, self.player.x, self.player.y)
end

client.quit = function(self)
	Net:disconnect()
end

return client
