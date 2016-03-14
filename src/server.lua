local Net = require "dependencies/Net"
local Map = require "map"
local explosion = require "explosion"
local bomb = require "bomb"
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
	self.characterID = 1

	self.clientMessageTimerValue = 0.1
	self.clientMessageID = 0
	self.clientMessages = {}

	Map:create(self.lobbyMap.map, 32, 32, 24, 16, 0)

	bomb:initiate()
	explosion:initiate()

	Net:init("Server")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)
	Net:registerCMD("key_pressed", function(table, param, id) self:keyRecieved(id, param, true) end)
	Net:registerCMD("key_released", function(table, param, id) self:keyRecieved(id, param, false) end)
	Net:registerCMD("message_recieved", function(table, param, id) self:removeClientMessage(table.id) end)
end

--[[
	Mouse down function.
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
end

--[[
	Key down function.
]]
server.keypressed = function(self, key)
end

--[[
	Key up function.
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

	for id, data in pairs(Net:connectedUsers()) do
		Net:send(clients, "setPosition", "", id)
	end

	-- send new messages and resend old messages to clients
	self:updateClientMessages(dt)
end

--[[
	Lobby.
]]
server.runLobby = function(self, clients, dt)
	local allPlayersInStartZone = true
	local numberOfPlayers = 0

	for id, data in pairs(Net:connectedUsers()) do
		if self.registeredClients[id] == nil then
			self.registeredClients[id] = self.characterID
			self.characterID = self.characterID % 7 + 1
		end

		if data.greeted ~= true then
			Net:send({}, "print", "Welcome to Brokkr! Now the server is up.", id)
			self:newClientMessage({name = id}, "setClientName", id)
			self:newClientMessage({map = self.lobbyMap.map, seed = self.lobbyMap.seed}, "getMapName", id)
			data.greeted = true
			Net.users[id].x = self.window.width * 0.5 - self.characterTile.width * 0.5
			Net.users[id].y = self.window.height * 0.5 - 100
			Net.users[id].speed = 100
			Net.users[id].bombCooldownTime = 1 -- time between player can play bombs
			Net.users[id].bombCountdown = 0 -- time left until player can place new bomb
			Net.users[id].direction = 1
			Net.users[id].isMoving = 0
			Net.users[id].health = 100
			Net.users[id].actions = {up = false, down = false, left = false, right = false, bomb = false}
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
	if allPlayersInStartZone == true then
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
			self:newClientMessage({map = self.gameMap.map, seed = self.gameMap.seed}, "getMapName", id)
			Net.users[id].x = startPositions[startPositionIndex % 4 + 1].x * Map.tileWidth
			Net.users[id].y = startPositions[startPositionIndex % 4 + 1].y * Map.tileHeight - 10
			Net.users[id].speed = 100
			Net.users[id].bombCooldownTime = 1 -- time between player can play bombs
			Net.users[id].bombCountdown = 0 -- time left until player can place new bomb
			Net.users[id].direction = 1
			Net.users[id].isMoving = 0
			Net.users[id].health = 100
			Net.users[id].actions = {up = false, down = false, left = false, right = false, bomb = false}
			startPositionIndex = startPositionIndex + 1
		end
		Map:create(self.gameMap.map, 32, 32, 24, 16, self.gameMap.seed)
		self.gameIsRunning = true
	end
end

--[[
	Match.
]]
server.runMatch = function(self, clients, dt)
	local allPlayersDead = true
	bomb:update(dt)
	explosion:update(dt)

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
				bomb:addInstance(1, location.mapX, location.mapY)

				for id, data in pairs(Net:connectedUsers()) do
					self:newClientMessage({mapX = location.mapX, mapY = location.mapY}, "addBomb", id)
				end
			end

			Net.users[id].bombCountdown = Net.users[id].bombCountdown - dt
			if Net.users[id].bombCountdown < 0 then Net.users[id].bombCountdown = 0 end

			self:explosionCheck(dt, id, 0.99)
			self:moveCheck(dt, id)

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
		explosion.instances = {}
		bomb.instances = {}
	end
end

--[[
	Draw function.
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
	--for id = 1, #bomb.instances do
	--	love.graphics.draw(
	--		bomb.type[bomb.instances[id].bombTypeID].image,
	--		bomb.instances[id].x * Map.tileWidth,
	--		bomb.instances[id].y * Map.tileHeight
	--	)
	--end
	--for id = 1, #explosion.instances do
	--	local e = explosion.instances[id]
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
	Quit function.
]]
server.quit = function(self)
	for id, data in pairs(Net:connectedUsers()) do
		Net:send({}, "print", "The server has been closed.", id)
	end
	Net:disconnect()
end

--[[
	Add a new client message.
	- inTable: table to be sent to client.
	- inCmd: name or client cmd.
	- inClientAddress: address of the receiving client.
]]
server.newClientMessage = function(self, inTable, inCmd, inClientAddress)
	self.clientMessageID = self.clientMessageID + 1
	inTable.id = self.clientMessageID -- add message id to table, client use this when replying
	self.clientMessages[self.clientMessageID] = {table = inTable, cmd = inCmd, clientAddress = inClientAddress, timer = 0}
end

--[[
	Update client messages.
	- dt: delta time in seconds.
]]
server.updateClientMessages = function(self, dt)
	for id, message in pairs(self.clientMessages) do
		message.timer = message.timer - dt
		if message.timer < 0 then
			message.timer = self.clientMessageTimerValue
			Net:send(message.table, message.cmd, "", message.clientAddress)
		end
	end
end

--[[
	Removes a client message.
	- messageID: index of the message to be removed.
]]
server.removeClientMessage = function(self, messageID)
	if self.clientMessages[messageID] ~= nil then
		self.clientMessages[messageID] = nil
	end
end

--[[
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
]]
server.explosionCheck = function(self, dt, id, sublimit)
	if explosion:playerCheck(Net.users[id], sublimit) then
		Net.users[id].health =  Net.users[id].health - dt * 100 --stable dt is 0.01
	end
	if Net.users[id].health < 0 then
		Net.users[id].greeted = false
	end
end

return server
