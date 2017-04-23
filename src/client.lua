local Global = require "global"
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
	self.clientName = "" -- the name assigned to the client by the server in the form "clientIp:clientPort"
	self.emptyOnScreenMessage = {message = "", r = 0, g = 0, b = 0, a = 0}
	self.onScreenMessage = self.emptyOnScreenMessage
	self.players = {}

	-- setup networking and connect to server
	Net:init("client")
	Net:connect(Global.ip, Global.port)
	Net:setMaxPing(Global.maxPingClient)
	self:registerCMD()
	Item:initiate()

	-- Set the default map
	Map:create(Global.map.tileImageName, Global.lobbyMap.map, Global.map.tileWidth, Global.map.tileHeight, Global.map.mapWidth, Global.map.mapHeight, Global.lobbyMap.seed)

	-- create bomb/explosion/item types and initialize the bomb/explosion/item instance lists
	Command:initiate()
	Bomb:initiate()
	Explosion:initiate()

	Global.characterTile.sprite = love.graphics.newImage(Global.characterTile.imageName)
	Global.characterTile.grid = anim8.newGrid(Global.characterTile.width, Global.characterTile.height, Global.characterTile.sprite:getWidth(), Global.characterTile.sprite:getHeight())

	-- Inverse of Global.actions, used to check if a pressed key is bound to a action
	self.keys = {}
	for k, v in pairs(Global.actions) do self.keys[v] = k end

	love.graphics.setFont(Global.font)
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
			-- reinitialize player incase it is already created, clientName is needed
			-- to correctly identify which character belongs to a specific client
			self.players[self.clientName] = nil
		end
	)

	-- Used by server to send text to be shown on clients
	Net:registerCMD("onScreenMessage",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			self.onScreenMessage = {message = inTable.message, r = inTable.r, g = inTable.g, b = inTable.b, a = inTable.a}
		end
	)

	-- Used by server to tell the client which map to create.
	Net:registerCMD("setMap",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			Global.gameMap.map = inTable.map
			Global.gameMap.seed = inTable.seed
			Map:create(Global.map.tileImageName, Global.gameMap.map, Global.map.tileWidth, Global.map.tileHeight, Global.map.mapWidth, Global.map.mapHeight, Global.gameMap.seed)
			Explosion:resetInstances()
			Bomb:resetInstances()
			if inTable.matchNumber > Global.matchNumber then
				Global.matchNumber = inTable.matchNumber
				Item:resetInstances()
			end
			self.onScreenMessage = self.emptyOnScreenMessage
		end
	)

	-- Used by server to tell clients to add a bomb instance.
	Net:registerCMD("addBomb",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			Bomb:addInstance(inTable.bombID, inTable.mapX, inTable.mapY)
		end
	)

	-- Used by server to add items on clients.
	Net:registerCMD("addItem",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			if inTable.matchNumber > Global.matchNumber then
				Global.matchNumber = inTable.matchNumber
				Item:resetInstances()
			end
			Item:add(inTable.type, inTable.x, inTable.y)
		end
	)

	-- Used by server to remove items on clients.
	Net:registerCMD("removeItem",
		function(inTable, param, dt, id)
			if Command:exists(inTable.id) then return end
			Item:remove(inTable.x, inTable.y)
			love.audio.play(love.audio.newSource("sound/press.wav"))
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
					self.players[k].healthBar = {
						r = 255, g = 0, b = 0, a = 100,
						width = 10, height = Global.characterTile.height
					}
					if k == self.clientName then
						self.players[k].healthBar.r = 0
						self.players[k].healthBar.g = 255
					end
				end

				-- update character sprite if player have changed sprite id
				if self.players[k].characterID ~= player.characterID then
					self.players[k].characterID = player.characterID
					self.players[k].animation = self:generateCharacterAnimation(self.players[k].characterID, 0.6)
				end

				-- player is still in the network
				self.players[k].alive = true
				self.players[k].x, self.players[k].y, self.players[k].direction, self.players[k].isMoving, self.players[k].health = player.x, player.y, player.direction, player.isMoving, player.health
				self.players[k].healthBar.height = Global.characterTile.height * (self.players[k].health / self.players[k].maxHealth)
			end

			-- check to see which players are still in the game
			-- delete players that are not
			for k, v in pairs(self.players) do
				if self.players[k].alive == false then
					self.players[k] = nil
					love.audio.play(love.audio.newSource("sound/wilhelmScream.mp3"))
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
	return self:generateCharacterAnimation(math.random(Global.characterTile.numberOfCharacters), duration)
end

--[[
	Return a character animation containing the character number "id".
	- id: which character that is chosen, 1 to number of characters in character spritesheet.
	- duration: the duration of the animation.
]]
client.generateCharacterAnimation = function(self, id, duration)
	local frameDuration = duration / 3
	local row = math.floor((id - 1) / 4) * 4
	local col = (id - 1) % 4
	col = 1 + col * 3 .. "-" .. 3 + col * 3
	return {
		anim8.newAnimation(Global.characterTile.grid(col, row + 1), frameDuration),
		anim8.newAnimation(Global.characterTile.grid(col, row + 4), frameDuration),
		anim8.newAnimation(Global.characterTile.grid(col, row + 3), frameDuration),
		anim8.newAnimation(Global.characterTile.grid(col, row + 2), frameDuration)
	}
end

--[[
	Turn of sound when window is out of focus.
]]
function love.focus(f)
  if f then
    love.audio.setVolume(.5)
  else
    love.audio.setVolume(0)
  end
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
		-- if player character is moving update animation, else set to idle pose
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
		v.animation[tonumber(v.direction)]:draw(Global.characterTile.sprite, v.x, v.y)
	end

	-- render health bars
	for k, v in pairs(self.players) do
		love.graphics.setColor(v.healthBar.r, v.healthBar.g, v.healthBar.b, v.healthBar.a)
		love.graphics.rectangle("fill",
			v.x + Global.characterTile.width, v.y + (Global.characterTile.height - v.healthBar.height),
			v.healthBar.width, v.healthBar.height)
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

	self:printOnscreenMessage(self.onScreenMessage.r, self.onScreenMessage.g, self.onScreenMessage.b, self.onScreenMessage.a, self.onScreenMessage.message)
end

--[[
	Print a match result message.
	- r: red color value of text.
	- g: green color value of text.
	- b: blue color value of text.
	- a: alpha color value of text.
	- message: message to be shown on screen.
]]
client.printOnscreenMessage = function(self, r, g, b, a, message)
	love.graphics.setColor(r, g, b, a)
	love.graphics.print(message, Global.map.tileWidth + 2, Global.window.height - Global.font:getHeight() + 8 - Global.map.tileHeight)
	love.graphics.setColor(255, 255, 255, 255)
end

--[[
	Quit function.
]]
client.quit = function(self)
	Net:disconnect()
end

return client
