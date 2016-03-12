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
	self.defaultMapName = "lobby"
	self.clientName = ""
	self.serverMessages = {} -- contains all old important servermessages, used to not perform an action twise.

	-- Define keys for different actions
	self.actions = {up = "up", down = "down", left = "left", right = "right", bomb = "space"}

	-- Inverse of self.action, used to check if a pressed key is bound to a action
	self.keys = {}
	for k, v in pairs(self.actions) do self.keys[v] = k end

	Net:init("client")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)

	self:registerCMD()

	-- Set the default map
	Map:create(self.defaultMapName, 32, 32, 24, 16, os.time())

	bomb:initiate()
	explosion:initiate()

	self.spritesheet = love.graphics.newImage("image/characters1.png")

	self.characterTile.grid = anim8.newGrid(self.characterTile.width, self.characterTile.height, self.spritesheet:getWidth(), self.spritesheet:getHeight())
end

--[[
	Checks if a server message have been recieved before. If it have been recieved
	before it returns 1 (true) else nil (false)
	- messageID: index of the server message.
]]
client.checkIfOldServerMessage = function(self, messageID)
	Net:send({id = messageID}, "message_recieved", "", Net.client.ip)
	if self.serverMessages[messageID] ~= nil then return 1 end
	self.serverMessages[messageID] = 1 -- save something in position messageID
	return nil
end

--[[
	Registers all the cmd's available in the client.
]]
client.registerCMD = function(self)
	Net:registerCMD("setClientName",
		function(inTable, param, dt, id)
			if self:checkIfOldServerMessage(inTable.id) then return end
			self.clientName = inTable.name
		end
	)

	Net:registerCMD("getMapName",
		function(inTable, param, dt, id)
			if self:checkIfOldServerMessage(inTable.id) then return end
			Map:create(inTable.map, Map.tileWidth, Map.tileHeight, Map.width, Map.height, inTable.seed)
			explosion:resetInstances()
			bomb:resetInstances()
		end
	)

	Net:registerCMD("addBomb",
		function(inTable, param, dt, id)
			if self:checkIfOldServerMessage(inTable.id) then return end
			bomb:addInstance(1, inTable.mapX, inTable.mapY)
		end
	)

	Net:registerCMD("showLocation",
		function(inTable, param, dt, id)
			inTable["Param"] = nil
			inTable["Command"] = nil

			for k, v in pairs(inTable) do
				local player = {}
				player.x, player.y, player.direction, player.isMoving, player.health, player.characterID = v:match("(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*)$")
				if self.players[k] == nil then -- initiate if not done already
					self.players[k] = {}
					self.players[k].animation = self:generateCharacterAnimation(player.characterID, 0.6)
					self.players[k].maxHealth = 100;
					self.players[k].health = self.players[k].maxHealth;
				end

				-- player is still in the network
				self.players[k].alive = true
				self.players[k].x, self.players[k].y, self.players[k].direction, self.players[k].isMoving, self.players[k].health = player.x, player.y, player.direction, player.isMoving, player.health
			end

			-- check to see whick players are still in the game
			-- delete players that are not
			for k, v in pairs(self.players) do
				if self.players[k].alive == false then
					self.players[k] = nil
				else
					self.players[k].alive = false
				end
			end
		end
	)
end

--[[
	Return a character animation containing a random character.
	- duration: the duration of the animation.
]]
client.generateRandomCharacterAnimation = function(self, duration)
	return self:generateCharacterAnimation(math.random(self.charactersInTilesheet), duration)
end

--[[
	Return a character animation containing a the character number "id".
	- id: which character that is choosen, 1 to number of characters in character spritesheet.
	- duration: the duration of the animation.
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
		v.animation[tonumber(v.direction)]:draw(self.spritesheet, v.x, v.y)
	end

	-- render health bars
	for k, v in pairs(self.players) do
		-- set opponents health bar to read, and players ownhealth bar to green
		love.graphics.setColor(255, 0, 0, 100)
		if k == self.clientName then love.graphics.setColor(0, 255, 0, 100) end
		local healthScale = v.health / v.maxHealth
		love.graphics.rectangle("fill", v.x + self.characterTile.width, v.y + self.characterTile.height * (1 - healthScale), 10, self.characterTile.height * healthScale)
	end
	love.graphics.setColor(255, 255, 255, 255) -- reset color to white

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

return client
