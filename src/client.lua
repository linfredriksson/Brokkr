local anim8 = require "dependencies/anim8"
local Net = require "dependencies/Net"
local Map = require "map"
local client = {}

math.randomseed(os.time())

client.load = function(self)
	self.windowWidth = love.graphics.getWidth()
	self.windowHeight = love.graphics.getHeight()
	self.players = {}
	self.characterTileGrid = nil
	self.worldTileWidth = 32
	self.worldTileHeight = 32
	self.worldWidth = 24
	self.worldHeight = 16
	self.characterTileWidth = 32
	self.characterTileHeight = 32
	self.ip, self.port = "127.0.0.1", 6789
	self.maxPing = 1000
	self.mapName = "empty" -- Nil is not an option, needs a default value
	self.doNtimes = 0 -- For updating the map

	Net:init("client")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)

	Net:registerCMD("getMapName", 
		function(table, param, dt, id)
			self.mapName = table["map"]
			--print("got the name:", self.mapName)
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

		--print("mapname before choosemap,", self.mapName)
		--self.tileset, self.tiles, self.map = Map:chooseMap(self.mapName, self.worldTileWidth, self.worldTileHeight, self.worldWidth, self.worldHeight)

		self.player = {
			x = self.windowWidth * 0.5 - self.characterTileWidth * 0.5, y = self.windowHeight * 0.5 - self.characterTileHeight * 0.5,
			direction = 1, speed = 100,
			keyUp = "up", keyDown = "down", keyRight = "right", keyLeft = "left",
			spritesheet = love.graphics.newImage("image/characters1.png"),
			animation = {}
		}

		self.characterTileGrid = anim8.newGrid(self.characterTileWidth, self.characterTileHeight, self.player.spritesheet:getWidth(), self.player.spritesheet:getHeight())
		--self.player.animation = self:generateCharacterAnimation(1, 0.6)
		self.player.animation = self:generateCharacterAnimation(1, 0.6)
	end

	client.generateRandomCharacterAnimation = function(self, duration)
	return self:generateCharacterAnimation(math.random(7), duration)
end

client.generateCharacterAnimation = function(self, id, duration)
  local frameDuration = duration / 3
  local row = math.floor(id / 5) * 4
  local col = 1 + ((id - 1) % 4)
  col = 1 + ((col - 1) * 3) .. "-" .. 3 + ((col - 1) * 3)
  return {
    anim8.newAnimation(self.characterTileGrid(col, row + 1), frameDuration),
    anim8.newAnimation(self.characterTileGrid(col, row + 4), frameDuration),
    anim8.newAnimation(self.characterTileGrid(col, row + 3), frameDuration),
    anim8.newAnimation(self.characterTileGrid(col, row + 2), frameDuration)
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

	-- Update the map
	-- TODO: How can we be sure that the map is always updated?
	if self.doNtimes < 5 then
		--print("mapname before choosemap,", self.mapName)
		self.tileset, self.tiles, self.map = Map:chooseMap(self.mapName, self.worldTileWidth, self.worldTileHeight, self.worldWidth, self.worldHeight)
		self.doNtimes = self.doNtimes + 1
	end

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
