local anim8 = require "dependencies/anim8"
local Net = require "dependencies/Net"
local Command = require "command"
local Map = require "map"
local Explosion = require "explosion"
local Bomb = require "bomb"
local Item = require "item"
local client = {}

math.randomseed(os.time())

--[[
	Initialising function. Run when client starts.
]]
client.load = function(self)
	self.window = {width = love.graphics.getWidth(), height = love.graphics.getHeight()}
	self.players = {}
	self.characterTile = {imageName = "image/characters1.png", width = 32, height = 32, numberOfCharacters = 7}
	self.serverInfo = {ip = "127.0.0.1", port = 6789, maxPing = 2000}
	self.defaultMapName = "lobby"
	self.clientName = "" -- the name assigned to the client by the server in the form "clientIp:clientPort"

	-- Define keys for different actions
	-- up/down/left/right: Movement.
	-- bomb: Drop bomb.
	-- prev/next: Can be used to change character while in lobby.
	self.actions = {up = "up", down = "down", left = "left", right = "right", bomb = "space", prev = "a", next = "s"}

	-- Inverse of self.action, used to check if a pressed key is bound to a action
	self.keys = {}
	for k, v in pairs(self.actions) do self.keys[v] = k end

	-- setup networking and connect to server
	Net:init("client")
	Net:connect(self.serverInfo.ip, self.serverInfo.port)
	Net:setMaxPing(self.serverInfo.maxPing)
	self:registerCMD()

	-- Set the default map
	Map:create(self.defaultMapName, 32, 32, 24, 16, os.time())

	Command:initiate()
	Bomb:initiate()
	Explosion:initiate()
	Item:initiate()

	self.characterTile.sprite = love.graphics.newImage(self.characterTile.imageName)
	self.characterTile.grid = anim8.newGrid(self.characterTile.width, self.characterTile.height, self.characterTile.sprite:getWidth(), self.characterTile.sprite:getHeight())
end

--[[
	Registers all the cmd's available in the client.
]]
client.registerCMD = function(self)
	-- Used by server to send the servers id for the client to the id.
	Net:registerCMD("setClientName",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			self.clientName = inTable.name
		end
	)

	-- Used by server to tell the client which map to create.
	Net:registerCMD("setMap",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			Map:create(inTable.map, Map.tileWidth, Map.tileHeight, Map.width, Map.height, inTable.seed)
			Explosion:resetInstances()
			Bomb:resetInstances()
			Item:resetInstances()
		end
	)

	-- Used by server to tell clients to add a bomb instance.
	Net:registerCMD("addBomb",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			Bomb:addInstance(1, inTable.mapX, inTable.mapY)
		end
	)

	-- Used by server to add items on clients.
	Net:registerCMD("addItem",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			Item:add(inTable.type, inTable.x, inTable.y)
		end
	)

	-- Used by server to remove items on clients.
	Net:registerCMD("removeItem",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			Item:remove(inTable.x, inTable.y)
		end
	)

	-- Used by server to send all clients player position to clients.
	Net:registerCMD("setPosition",
		function(inTable, param, dt, id)
			inTable["Param"] = nil
			inTable["Command"] = nil

			for k, v in pairs(inTable) do
				local player = {}
				player.x, player.y, player.direction, player.isMoving, player.health, player.characterID = v:match("(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*),(%-?[%d.e]*)$")
				if self.players[k] == nil then -- initiate if not done already
					self.players[k] = {}
					self.players[k].characterID = 0
					self.players[k].maxHealth = 100
					self.players[k].health = self.players[k].maxHealth
				end

				-- update character sprite if player have changed sprite id
				if self.players[k].characterID ~= player.characterID then
					self.players[k].characterID = player.characterID
					self.players[k].animation = self:generateCharacterAnimation(self.players[k].characterID, 0.6)
				end

				-- player is still in the network
				self.players[k].alive = true
				self.players[k].x, self.players[k].y, self.players[k].direction, self.players[k].isMoving, self.players[k].health = player.x, player.y, player.direction, player.isMoving, player.health
			end

			-- check to see which players are still in the game
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
	return self:generateCharacterAnimation(math.random(self.characterTile.numberOfCharacters), duration)
end

--[[
	Return a character animation containing the character number "id".
	- id: which character that is chosen, 1 to number of characters in character spritesheet.
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
	Mouse down function.
	- x: x coordinate of mouse pointer.
	- y: y coordinate of mouse pointer.
	- button: which button on the mouse was pressed.
]]
client.mousepressed = function(self, x, y, button)
end

--[[
	Key down function.
	- key: keyboard button being pressed.
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
	Key up function.
	- key: keyboard button being pressed.
]]
client.keyreleased = function(self, key)
	if self.keys[key] ~= nil then
		Net:send({}, "key_released", self.keys[key], Net.client.ip)
	end
end

--[[
	Update function.
	- dt: delta time, time since last update.
]]
client.update = function(self, dt)
	Bomb:update(dt)
	Explosion:updateAnimation(dt)
	Explosion:update(dt)

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
	Draw function.
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

	-- draw item instances
	for k, v in pairs(Item.instances) do
		love.graphics.setColor(v.type.color.r, v.type.color.g, v.type.color.b, v.type.color.a)
		love.graphics.rectangle("fill", v.x * Map.tileWidth, v.y * Map.tileHeight, Map.tileWidth, Map.tileHeight)
	end
	love.graphics.setColor(255, 255, 255, 255)

	-- draw bomb instances
	for k, v in pairs(Bomb.instances) do
		love.graphics.draw(v.bombType.image, v.x * Map.tileWidth, v.y * Map.tileHeight)
	end

	-- draw all players
	for k, v in pairs(self.players) do
		v.animation[tonumber(v.direction)]:draw(self.characterTile.sprite, v.x, v.y)
	end

	-- render health bars
	for k, v in pairs(self.players) do
		-- set opponents health bar to read, and players own health bar to green
		love.graphics.setColor(255, 0, 0, 100)
		if k == self.clientName then love.graphics.setColor(0, 255, 0, 100) end
		local healthScale = v.health / v.maxHealth
		love.graphics.rectangle("fill",
			v.x + self.characterTile.width,
			v.y + self.characterTile.height * (1 - healthScale),
			10, self.characterTile.height * healthScale)
	end
	love.graphics.setColor(255, 255, 255, 255) -- reset color to white

	-- draw explosion instances
	for k, v in pairs(Explosion.instances) do
		v.animation:draw(
			v.type.tileset,
			(v.x + 0.5) * Map.tileWidth - v.type.tileWidth * 0.5,
			(v.y + 0.5) * Map.tileHeight - v.type.tileHeight * 0.5
		)
	end
end

--[[
	Quit function.
]]
client.quit = function(self)
	Net:disconnect()
end

return client
