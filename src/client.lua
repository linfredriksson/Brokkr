local anim8 = require "dependencies/anim8"
local Net = require "dependencies/Net"
local Map = require "map"
local explosion = require "explosion"
local bomb = require "bomb"
local client = {}

math.randomseed(os.time())

--[[
]]
client.load = function(self)
	self.window = {width = love.graphics.getWidth(), height = love.graphics.getHeight()}
	self.players = {}
	self.characterTile = {grid = nil, width = 32, height = 32}
	self.charactersInTilesheet = 7
	self.ip, self.port, self.maxPing = "127.0.0.1", 6789, 1000
	self.defaultMapName = "random"

	-- Define keys for different actions
	self.actions = {up = "up", down = "down", left = "left", right = "right", bomb = "space"}

	-- Inverse of self.action, used to check if a pressed key is bound to a action
	self.keys = {}
	for k, v in pairs(self.actions) do self.keys[v] = k end

	Net:init("client")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)

	self:registerCMD()

	self.sound = love.audio.newSource("sound/footstep01.ogg")

	-- Set the default map
	Map:create(self.defaultMapName, 32, 32, 24, 16, os.time())

	self.player = {
		x = self.window.width * 0.5 - self.characterTile.width * 0.5, y = self.window.height * 0.5 - self.characterTile.height * 0.5,
		direction = 1, speed = 100, health = 100,
		spritesheet = love.graphics.newImage("image/characters1.png"),
		animation = {}
	}

	self.characterTile.grid = anim8.newGrid(self.characterTile.width, self.characterTile.height, self.player.spritesheet:getWidth(), self.player.spritesheet:getHeight())
	self.player.animation = self:generateCharacterAnimation(1, 0.6)

	-- bomb/explosion addType should not be done here as it is used by both client and server
	bomb:initiate()
	bomb:addType("image/bomb1.png", 1, 2, 1.8)

	explosion:initiate()
	explosion:addType(love.graphics.newImage("image/explosion_34FR.png"), 34, 2)
	explosion:addType(love.graphics.newImage("image/explosion_47FR.png"), 47, 2)
	explosion:addType(love.graphics.newImage("image/explosion_50FR.png"), 50, 2)
	explosion:addType(love.graphics.newImage("image/explosion_52FR.png"), 52, 2)
end

--[[
]]
client.registerCMD = function(self)
	Net:registerCMD("getMapName",
		function(table, param, dt, id)
			Map:create(table.map, Map.tileWidth, Map.tileHeight, Map.width, Map.height, table.seed)
		end
	)

	Net:registerCMD("showLocation",
		function(table, param, dt, id)

			table["Param"] = nil
			table["Command"] = nil

			for k, v in pairs(table) do
				if self.players[k] == nil then -- initiate if not done already
					self.players[k] = {}
					self.players[k].animation = self:generateCharacterAnimation(1, 0.6)
					self.players[k].maxHealth = 100;
					self.players[k].health = 100;
				end

				-- player is still in the network
				self.players[k].alive = true
				self.players[k].x, self.players[k].y, self.players[k].direction, self.players[k].isMoving, self.players[k].health = v:match("(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*)$")
			end

			for k, v in pairs(self.players) do
				if self.players[k].alive == false then
					self.players[k] = nil
				else
					self.players[k].alive = false
				end
			end

		end
	)

	Net:registerCMD("addBomb",
		function(table, param, dt, id)
			bomb:addInstance(1, table.mapX, table.mapY)
		end
	)
end

--[[
	Return a character animation containing a random characters.
]]
client.generateRandomCharacterAnimation = function(self, duration)
	return self:generateCharacterAnimation(math.random(self.charactersInTilesheet), duration)
end

--[[
]]
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

--[[
]]
client.mousepressed = function(self, x, y, button)
end

--[[
]]
client.keypressed = function(self, key)
	if key == "escape" then
		Net:disconnect()
		love.event.quit()
	end

--[[if self.actions.bomb == key then
		local mapX = math.floor((self.player.x + self.characterTile.width * 0.5) / self.window.width * self.world.width)
		local mapY = math.floor((self.player.y + self.characterTile.height) / self.window.height * self.world.height)
		self.bombs[#self.bombs + 1] = {
			bombType = self.bombType[1],
			countDown = self.bombType[1].countDown,
			x = mapX, y = mapY
		}
	end]]

	if self.keys[key] ~= nil then
		Net:send({}, "key_pressed", self.keys[key], Net.client.ip)
	end
end

--[[
]]
client.keyreleased = function(self, key)
	if self.keys[key] ~= nil then
		Net:send({}, "key_released", self.keys[key], Net.client.ip)
	end
end

--[[
]]
client.update = function(self, dt)
	bomb:update(dt)
	explosion:updateAnimation(dt)
	explosion:update(dt)

	for k, v in pairs(self.players) do
		if v.isMoving == "1" then
			v.animation[tonumber(v.direction)]:update(dt)
		else
			v.animation[tonumber(v.direction)]:gotoFrame(2)
		end
	end

	if love.keyboard.isDown(self.actions.up, self.actions.down, self.actions.right, self.actions.left) then
		self.player.animation[self.player.direction]:update(dt)
	else
		self.player.animation[self.player.direction]:gotoFrame(2)
	end


	self:explosionCheck()
	self:moveCheck(dt)

	Net:update(dt)
end

--[[
]]
client.draw = function(self)
	-- draw map
	for y = 1, #Map.values  do
		for x = 1, #Map.values[y] do
			love.graphics.draw(
				Map.tileset.image,
				Map.tiles[Map.values[y][x]].img,
				(x - 1) * Map.tileWidth,
				(y - 1) * Map.tileHeight
			)
		end
	end
	
	for id = 1, #bomb.instances do
		love.graphics.draw(
			bomb.type[bomb.instances[id].bombTypeID].image,
			bomb.instances[id].x * Map.tileWidth,
			bomb.instances[id].y * Map.tileHeight
		)
	end

	-- draw all players
	for k, v in pairs(self.players) do
		v.animation[tonumber(v.direction)]:draw(self.player.spritesheet, v.x, v.y)
	end

	-- render health bars
	love.graphics.setColor(255, 0, 0, 100)
	for k, v in pairs(self.players) do
		local healthScale = v.health / v.maxHealth
		love.graphics.rectangle("fill", v.x + self.characterTile.width, v.y + self.characterTile.height * (1 - healthScale), 10, self.characterTile.height * healthScale)
	end
	love.graphics.setColor(255, 255, 255, 255)

	-- draw player
	self.player.animation[self.player.direction]:draw( self.player.spritesheet, self.player.x, self.player.y)

	-- draw explosions
	for id = 1, #explosion.instances do
		local e = explosion.instances[id]
		e.animation:draw(
			e.type.tileset,
			(e.x + 0.5) * Map.tileWidth - e.type.tileWidth * 0.5,
			(e.y + 0.5) * Map.tileHeight - e.type.tileHeight * 0.5
		)
	end
end

--[[
]]
client.quit = function(self)
	Net:disconnect()
end

--[[
]]
client.moveCheck = function(self, dt)
	local tiles, map = Map.tiles, Map.values
	local tileWidth, tileHeight = self.characterTile.width * 0.5, self.characterTile.height
	local absOffsetX, absOffsetY = 10, 3
	local actions = self.actions

	if love.keyboard.isDown(actions.up, actions.down) then
		local dir = 1
		self.player.direction = 1
		if love.keyboard.isDown(actions.up) then self.player.direction = 2; dir = -1 end
		local y = self.player.y + dir * self.player.speed * dt
		local mapY = math.ceil((tileHeight + y + dir * absOffsetY) / Map.tileHeight)
		local mapX1 = math.ceil((tileWidth + self.player.x + absOffsetX) / Map.tileWidth)
		local mapX2 = math.ceil((tileWidth + self.player.x - absOffsetX) / Map.tileWidth)
		if tiles[map[mapY][mapX1]].walkable and tiles[map[mapY][mapX2]].walkable then self.player.y = y end
	end

	if love.keyboard.isDown(actions.left, actions.right) then
		local dir = 1
		self.player.direction = 3
		if love.keyboard.isDown(actions.left) then self.player.direction = 4; dir = -1 end
		local x = self.player.x + dir * self.player.speed * dt
		local mapX = math.ceil((tileWidth + x + dir * absOffsetX) / Map.tileWidth)
		local mapY1 = math.ceil((tileHeight + self.player.y + absOffsetY) / Map.tileHeight)
		local mapY2 = math.ceil((tileHeight + self.player.y - absOffsetY) / Map.tileHeight)
		if tiles[map[mapY1][mapX]].walkable and tiles[map[mapY2][mapX]].walkable then self.player.x = x end
	end
end

--[[
]]
client.explosionCheck = function(self)
	for id = 1, #explosion.instances do
		local e = explosion.instances[id]
		if e.x == math.ceil(self.player.x / Map.tileWidth) and e.y == math.ceil(self.player.y / Map.tileHeight) then
			self.player.health = self.player.health - 1
		end
		if self.player.health < 0 then
			--self.player.x = self.window.width * 0.5 - self.characterTile.width * 0.5
			--self.player.y = self.window.height * 0.5 - self.characterTile.height * 0.5
			self.player.health = 100
		end
		--print("My HP now is", self.player.health)
	end
end


return client
