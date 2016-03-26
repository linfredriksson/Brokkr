local Net = require "dependencies/Net"
local Command = require "command"
local Map = require "map"
local Explosion = require "explosion"
local Bomb = require "bomb"
local Item = require "item"
local Item = require "item"
local server = {}

--[[
	Initialising function. Run when server starts.
]]
server.load = function(self)
	self.window = {width = love.graphics.getWidth(), height = love.graphics.getHeight()}
	self.characterTile = {grid = nil, width = 32, height = 32}
	self.ip, self.port, self.maxPing = nil, 6789, 3000
	self.totalDeltaTime, self.updateTimeStep = 0, 0.01
	self.gameMap = {map = "random", seed = os.time()}
	self.lobbyMap = {map = "lobby", seed = 0}
	self.gameIsRunning = false
	self.registeredClients = {}

	-- create the lobby map
	Map:create(self.lobbyMap.map, 32, 32, 24, 16, 0)

	-- create bomb/explosion types and initialize the bomb/explosion instance lists
	Bomb:initiate()
	Explosion:initiate()
	Item:initiate()
	Item:initiate()

	-- start server and register all cmd
	Net:init("Server")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)
	Net:registerCMD("key_pressed", function(table, param, id) self:keyRecieved(id, param, true) end)
	Net:registerCMD("key_released", function(table, param, id) self:keyRecieved(id, param, false) end)
	Net:registerCMD("command_recieved", function(table, param, id) Command:remove(table.id) end)
	Command:initiate(0.1)
end

--[[
	Mouse down function.
	- x: x coordinate of mouse pointer.
	- y: y coordinate of mouse pointer.
	- button: which button on the mouse was pressed.
]]
server.mousepressed = function(self, x, y, button)
end

--[[
	Runs when server recieves keys from clients.
	- id: client id.
	- key: the keyboard key sent by the client.
	- value: true or false depending on if the key is pressed or released.
]]
server.keyRecieved = function(self, id, key, value)
	if Net.users[id] ~= nil and Net.users[id].greeted == true and Net.users[id].actions[key] ~= nil then
		Net.users[id].actions[key] = value
	end

	if Net.users[id] ~= nil and Net.users[id].greeted == true and (key == "next" or key == "prev") and value == true and self.gameIsRunning == false then
		self:changeCharacterID(id, key)
	end
end

--[[
	Key down function.
	- key: the keyboard key being pressed.
]]
server.keypressed = function(self, key)
	if key == "escape" then
		love.event.quit()
	end
end

--[[
	Key up function.
	- key: the keyboard key being released.
]]
server.keyreleased = function(self, key)
end

--[[
	Update function.
	- dt: delta time, time since last update.
]]
server.update = function(self, dt)
	self.totalDeltaTime = self.totalDeltaTime + dt
	while self.totalDeltaTime > self.updateTimeStep do
		self:fixedUpdate(self.updateTimeStep)
		self.totalDeltaTime = self.totalDeltaTime - self.updateTimeStep
	end
end

--[[
	Fixed update function. This function is used by the update function so that the
	game updates in smaller interwalls, used to eliminate problems with heavy lag.
	- dt: delta time, time since last update.
]]
server.fixedUpdate = function(self, dt)
	local clients = {}
	Net:update(dt)

	if self.gameIsRunning == false then
		self:runLobby(clients, dt)
	end

	if self.gameIsRunning == true then
		self:runMatch(clients, dt)
	end

	-- update character positions in all connected clients.
	for id, data in pairs(Net:connectedUsers()) do
		Net:send(clients, "setPosition", "", id)
	end

	-- send new commands and resend old commands to clients
	Command:update(dt)
end

--[[
	Lobby that is run when not in a active match.
	- clients: list of client data that will be sent to all connected clients.
	- dt: delta time, time in seconds since last update.
]]
server.runLobby = function(self, clients, dt)
	local allPlayersInStartZone = true
	local numberOfPlayers = 0

	for id, data in pairs(Net:connectedUsers()) do
		if self.registeredClients[id] == nil then
			self.registeredClients[id] = math.random(7)
		end

		if data.greeted ~= true then
			Net:send({}, "print", "Welcome to Brokkr! Now the server is up.", id)
			Command:add({name = id}, "setClientName", id)
			Command:add({map = self.lobbyMap.map, seed = self.lobbyMap.seed}, "setMap", id)
			data.greeted = true
			Net.users[id].x = self.window.width * 0.5 - self.characterTile.width * 0.5
			Net.users[id].y = self.window.height * 0.5 - 100
			Net.users[id].speed = 100
			Net.users[id].bombCooldownTime = 1 -- time between player can play bombs
			Net.users[id].bombCountdown = 0 -- time left until player can place new bomb
			Net.users[id].direction = 1
			Net.users[id].isMoving = 0
			Net.users[id].health = 100
			Net.users[id].actions = {up = false, down = false, left = false, right = false, bomb = false, prev = false, next = false}
			Net.users[id].characterID = self.registeredClients[id]
		end

		self:moveCheck(dt, id)
		Net.users[id].isMoving = 0
		if Net.users[id].actions.up or Net.users[id].actions.down or Net.users[id].actions.left or Net.users[id].actions.right then
			Net.users[id].isMoving = 1
		end

		clients[id] = Net.users[id].x .. "," .. Net.users[id].y .. "," .. Net.users[id].direction .. "," .. Net.users[id].isMoving .. "," .. Net.users[id].health .. "," .. Net.users[id].characterID

		-- check to see if any players are outside of the start square on the map
		if Net.users[id].x < 304 or Net.users[id].x > 432 or Net.users[id].y < 160 or Net.users[id].y > 288 then
			allPlayersInStartZone = false
		end

		-- count number of players currently in lobby
		numberOfPlayers = numberOfPlayers + 1
	end

	-- if all players are in the start square on the map, then start a new match
	if allPlayersInStartZone == true and numberOfPlayers > 0 then
		self.gameMap.seed = os.time()
		local startPositions = {
			{x = 1, y = 1},
			{x = Map.width - 2, y = 1},
			{x = Map.width - 2, y = Map.height - 2},
			{x = 1, y = Map.height - 2}
		}

		local startPositionIndex = 0
		for id, data in pairs(Net:connectedUsers()) do
			Net:send({}, "print", "New game is starting", id)
			Command:add({map = self.gameMap.map, seed = self.gameMap.seed}, "setMap", id)
			Net.users[id].x = startPositions[startPositionIndex % 4 + 1].x * Map.tileWidth
			Net.users[id].y = startPositions[startPositionIndex % 4 + 1].y * Map.tileHeight - 10
			Net.users[id].baseSpeed = 100
			Net.users[id].speed = Net.users[id].baseSpeed
			Net.users[id].baseBombCooldownTime = 1 -- time between player can play bombs
			Net.users[id].bombCooldownTime = Net.users[id].baseBombCooldownTime
			Net.users[id].bombCountdown = 0 -- time left until player can place new bomb
			Net.users[id].direction = 1
			Net.users[id].isMoving = 0
			Net.users[id].maxHealth = 100
			Net.users[id].health = Net.users[id].maxHealth
			Net.users[id].actions = {up = false, down = false, left = false, right = false, bomb = false}
			startPositionIndex = startPositionIndex + 1
		end

		-- create new map
		Map:create(self.gameMap.map, 32, 32, 24, 16, self.gameMap.seed)

		-- generate 10 items ontop of destructable walls
		self:addItems(5, 3, 3)

		-- set game to running
		self.gameIsRunning = true
	end
end

--[[
	Run when server is running a active match.
	- clients: list of client data that will be sent to all connected clients.
	- dt: delta time, time in seconds since last update.
]]
server.runMatch = function(self, clients, dt)
	local allPlayersDead = true
	Bomb:update(dt)
	Explosion:update(dt)

	for id, data in pairs(Net:connectedUsers()) do
		if data.greeted == true then
			allPlayersDead = false
			-- place bomb key
			if Net.users[id].actions.bomb  and Net.users[id].bombCountdown <= 0 then
				Net.users[id].actions.bomb = false
				Net.users[id].bombCountdown = Net.users[id].bombCooldownTime

				-- take location from the bottom middle of the character sprite
				local location = {
					mapX = math.floor((Net.users[id].x + self.characterTile.width * 0.5) / self.window.width * Map.width),
					mapY = math.floor((Net.users[id].y + self.characterTile.height) / self.window.height * Map.height)
				}
				Bomb:addInstance(1, location.mapX, location.mapY)

				for id, data in pairs(Net:connectedUsers()) do
					Command:add({mapX = location.mapX, mapY = location.mapY}, "addBomb", id)
				end
			end

			Net.users[id].bombCountdown = Net.users[id].bombCountdown - dt
			if Net.users[id].bombCountdown < 0 then Net.users[id].bombCountdown = 0 end

			self:explosionCheck(dt, id, 0.99)
			self:moveCheck(dt, id)
			self:itemCheck(Net.users[id])

			Net.users[id].isMoving = 0
			if Net.users[id].actions.up or Net.users[id].actions.down or Net.users[id].actions.left or Net.users[id].actions.right then
				Net.users[id].isMoving = 1
			end

			clients[id] = Net.users[id].x .. "," .. Net.users[id].y .. "," .. Net.users[id].direction .. "," .. Net.users[id].isMoving .. "," .. Net.users[id].health .. "," .. Net.users[id].characterID
		end
	end

	-- if no players left alive go to lobby
	if allPlayersDead == true then
		self.gameIsRunning = false
		Map:create(self.lobbyMap.map, 32, 32, 24, 16, 0)
		Explosion:resetInstances()
		Bomb:resetInstances()
		Item:resetInstances()
	end
end

--[[
	Draw function. Mostly used for debugging.
]]
server.draw = function(self)
	--for y = 1, #Map.values  do
	--	for x = 1, #Map.values[y] do
	--		love.graphics.draw(
	--			Map.tileset.image,
	--			Map.tiles[Map.values[y][x]].img,
	--			(x - 1) * Map.tileWidth,
	--			(y - 1) * Map.tileHeight
	--		)
	--	end
	--end
	--for k, v in pairs(Item.instances) do
	--	love.graphics.setColor(v.type.color.r, v.type.color.g, v.type.color.b, v.type.color.a)
	--	love.graphics.rectangle("fill", v.x * Map.tileWidth, v.y * Map.tileHeight, Map.tileWidth, Map.tileHeight)
	--end
	--love.graphics.setColor(255, 255, 255, 255)
	--for id = 1, #Bomb.instances do
	--	love.graphics.draw(
	--		Bomb.type[Bomb.instances[id].bombTypeID].image,
	--		Bomb.instances[id].x * Map.tileWidth,
	--		Bomb.instances[id].y * Map.tileHeight
	--	)
	--end
	--for id = 1, #Explosion.instances do
	--	local e = Explosion.instances[id]
	--	e.animation:draw(
	--		e.type.tileset,
	--		(e.x + 0.5) * Map.tileWidth - e.type.tileWidth * 0.5,
	--		(e.y + 0.5) * Map.tileHeight - e.type.tileHeight * 0.5
	--	)
	--end

	love.graphics.print("SERVER", 10, 10)

	local textY = 30
	-- draw all players
	for k, v in pairs(Net.users) do
		if v.greeted == true then
			love.graphics.rectangle("fill", v.x, v.y, self.characterTile.width, self.characterTile.height)
			love.graphics.print(k .. ", " .. v.x .. ":" .. v.y, 10, textY)
			textY = textY + 20
		end
	end
end

--[[
	Quit function. Run when server is shutting down.
]]
server.quit = function(self)
	for id, data in pairs(Net:connectedUsers()) do
		Net:send({}, "print", "The server has been closed.", id)
	end
	Net:disconnect()
end

--[[
	Checks the collision between the client's position and inaccessible tiles.
	- dt: delta time in seconds.
	- id: client id.
]]
server.moveCheck = function(self, dt, id)
	local tiles, map = Map.tiles, Map.values
	local tileWidth, tileHeight = self.characterTile.width * 0.5, self.characterTile.height
	local absOffsetX, absOffsetY = 10, 3
	local actions = Net.users[id].actions

	if actions.up or actions.down then
		local dir = 1
		Net.users[id].direction = 1
		if actions.up then Net.users[id].direction = 2; dir = -1 end
		local y = Net.users[id].y + dir * Net.users[id].speed * dt
		local mapY = math.ceil((tileHeight + y + dir * absOffsetY) / Map.tileHeight)
		local mapX1 = math.ceil((tileWidth + Net.users[id].x + absOffsetX) / Map.tileWidth)
		local mapX2 = math.ceil((tileWidth + Net.users[id].x - absOffsetX) / Map.tileWidth)
		if tiles[map[mapY][mapX1]].walkable and tiles[map[mapY][mapX2]].walkable then Net.users[id].y = y end
	end

	if actions.left or actions.right then
		local dir = 1
		Net.users[id].direction = 3
		if actions.left then Net.users[id].direction = 4; dir = -1 end
		local x = Net.users[id].x + dir * Net.users[id].speed * dt
		local mapX = math.ceil((tileWidth + x + dir * absOffsetX) / Map.tileWidth)
		local mapY1 = math.ceil((tileHeight + Net.users[id].y + absOffsetY) / Map.tileHeight)
		local mapY2 = math.ceil((tileHeight + Net.users[id].y - absOffsetY) / Map.tileHeight)
		if tiles[map[mapY1][mapX]].walkable and tiles[map[mapY2][mapX]].walkable then Net.users[id].x = x end
	end
end

--[[
	Checks if the client in an explosion tile.
	- dt: delta time in seconds.
	- id: client id.
	- sublimit: client doesn't take damage if less than sublimit seconds are left of the instance animation.
]]
server.explosionCheck = function(self, dt, id, sublimit)
	if Explosion:playerCheck(Net.users[id], sublimit) then
		Net.users[id].health =  Net.users[id].health - dt * 100 --stable dt is 0.01
	end
	if Net.users[id].health < 0 then
		Net.users[id].greeted = false
	end
end

--[[
	Changes client's character with keys next and prev.
	- id: client id.
	- key: pressed key (next or prev)
]]
server.changeCharacterID = function(self, id, key)
	if key == "next" then
		Net.users[id].characterID = Net.users[id].characterID % 7 + 1
	end

	if key == "prev" then
		Net.users[id].characterID = (Net.users[id].characterID + 5) % 7 + 1
	end

	self.registeredClients[id] = Net.users[id].characterID
end

--[[
	Checks if the client in an tile with a item.
	- player: the client to check.
]]
server.itemCheck = function(self, player)
	-- check if player is on top of any item
	local item = Item:find(player.x, player.y)
	-- if item found
	if item ~= nil then
		-- remove item from all clients
		for id, data in pairs(Net:connectedUsers()) do
			Command:add({x = item.x, y = item.y}, "removeItem", id)
		end
		-- apply item effect to player
		item.type.callback(player)
		-- remove item from server
		Item:remove(item.x, item.y)
	end
end

--[[
	Add x number of items on destructable walls.
	- numberOfHealth: number of health items to create.
	- numberOfSpeed: number of speed items to create.
	- numberOfReload: number of reload items to create.
]]
server.addItems = function(self, numberOfHealth, numberOfSpeed, numberOfReload)
	for i = 1, numberOfHealth + numberOfSpeed + numberOfReload do
		local type = "reload"
		if i <= numberOfHealth + numberOfSpeed then type = "speed" end
		if i <= numberOfHealth then type = "health" end

		-- generate positions for items, only on destructable walls.
		local available, x, y = nil, 0, 0
		while available == nil do
			x = math.floor((Map.width - 2) * math.random()) + 1
			y = math.floor((Map.height - 2) * math.random()) + 1
			if Map:isDestructable(x + 1, y + 1) ~= nil and Item:find(x * Map.tileWidth, y  * Map.tileHeight) == nil then
				available = true
			end
		end

		-- add item to server and send it to all connected clients
		Item:add(type, x, y)
		for id, data in pairs(Net:connectedUsers()) do
			Command:add({type = type, x = x, y = y}, "addItem", id)
		end
	end
end

return server
