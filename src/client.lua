local anim8 = require "dependencies/anim8"
local Net = require "dependencies/Net"
local Map = require "map"
local client = {}

client.load = function(self)
  self.windowWidth = love.graphics.getWidth()
  self.windowHeight = love.graphics.getHeight()
  self.players = {}
  self.worldTileGrid = nil
  self.worldTileWidth = 64
  self.worldTileHeight = 64
  self.characterTileWidth = 32
  self.characterTileHeight = 32
  self.ip, self.port = "127.0.0.1", 6789
  self.maxPing = 1000

  Net:init("client")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)

	Net:registerCMD("showLocation",
		function(table, param, dt, id)
			table["Param"] = nil
			table["Command"] = nil

			for k, v in pairs(table) do
				if self.players[k] == nil then -- initiate if not done already
					self.players[k] = {}
					self.players[k].animation = {
						anim8.newAnimation(self.worldTileGrid("1-3", 1), 0.2),
						anim8.newAnimation(self.worldTileGrid("1-3", 4), 0.2),
						anim8.newAnimation(self.worldTileGrid("1-3", 3), 0.2),
						anim8.newAnimation(self.worldTileGrid("1-3", 2), 0.2)
					}
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

	local mapName = "example"
	--local mapName = "de" -- To check error
	self.tileset, self.tiles, self.map = Map:chooseMap(mapName, self.worldTileWidth, self.worldTileHeight)

	self.player = {
		x = self.windowWidth * 0.5 - self.characterTileWidth * 0.5, y = self.windowHeight * 0.5 - self.characterTileHeight * 0.5,
		direction = 1, speed = 100,
		keyUp = "up", keyDown = "down", keyRight = "right", keyLeft = "left",
		spritesheet = love.graphics.newImage("image/characters1.png"),
		animation = {}
	}

	self.worldTileGrid = anim8.newGrid(self.characterTileWidth, self.characterTileHeight, self.player.spritesheet:getWidth(), self.player.spritesheet:getHeight())
	self.player.animation = {
		anim8.newAnimation(self.worldTileGrid("1-3", 1), 0.2),
		anim8.newAnimation(self.worldTileGrid("1-3", 4), 0.2),
		anim8.newAnimation(self.worldTileGrid("1-3", 3), 0.2),
		anim8.newAnimation(self.worldTileGrid("1-3", 2), 0.2)
	}
end

client.mousepressed = function(self, x, y, button)
end

client.keypressed = function(self, key)
  if key == "escape" then
		Net:disconnect()
		love.event.quit()
	end

	if key == "up" or key == "down" or key == "right" or key == "left" or key == " " then
		Net:send({}, "key_pressed", key, Net.client.ip)
	end
end

client.keyreleased = function(self, key)
  if key == "up" or key == "down" or key == "right" or key == "left" then
		Net:send({}, "key_released", key, Net.client.ip)
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

	if love.keyboard.isDown(self.player.keyUp, self.player.keyDown, self.player.keyRight, self.player.keyLeft) then
		self.player.animation[self.player.direction]:update(dt)
		--sound:play()
	else
		self.player.animation[self.player.direction]:gotoFrame(2)
	end

	if love.keyboard.isDown(self.player.keyUp) then self.player.direction = 2; self.player.y = self.player.y - dt * self.player.speed end
	if love.keyboard.isDown(self.player.keyDown) then self.player.direction = 1; self.player.y = self.player.y + dt * self.player.speed end
	if love.keyboard.isDown(self.player.keyLeft) then self.player.direction = 4; self.player.x = self.player.x - dt * self.player.speed end
	if love.keyboard.isDown(self.player.keyRight) then self.player.direction = 3; self.player.x = self.player.x + dt * self.player.speed end

	Net:update(dt)
end

client.draw = function(self)
  -- draw map
	for y = 1, #self.map  do
		local row = self.map[y]
		for x = 1, #row do
			love.graphics.draw(self.tileset, self.tiles[self.map[y][x] + 1].img, x * self.worldTileWidth - self.worldTileWidth, y * self.worldTileHeight - self.worldTileHeight)
		end
	end

	-- draw all players
	for k, v in pairs(self.players) do
		v.animation[tonumber(v.direction)]:draw(self.player.spritesheet, v.x, v.y)
	end

	-- draw player
	self.player.animation[self.player.direction]:draw(self.player.spritesheet, self.player.x, self.player.y)
end

return client
