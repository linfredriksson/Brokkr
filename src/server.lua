local Net = require "dependencies/Net"
local Map = require "map"
local explosion = require "explosion"
local server = {}

server.load = function(self)
	self.window = {width = love.graphics.getWidth(), height = love.graphics.getHeight()}
	self.characterTile = {grid = nil, width = 32, height = 32}
	self.ip, self.port, self.maxPing = nil, 6789, 3000
	self.totalDeltaTime, self.updateTimeStep = 0, 0.01
	self.mapTable = {map = "random", seed = os.time()}

	Map:create(self.mapTable.map, 32, 32, 24, 16, self.mapTable.seed)

	Net:init("Server")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)

	Net:registerCMD("key_pressed", function(table, param, id) self:keyRecieved(id, param, true) end)
	Net:registerCMD("key_released", function(table, param, id) self:keyRecieved(id, param, false) end)
end

server.mousepressed = function(self, x, y, button)
end

server.keyRecieved = function(self, id, key, value)
	if Net.users[id].actions[key] ~= nil then
		Net.users[id].actions[key] = value
	end
end

server.keypressed = function(self, key)
end

server.keyreleased = function(self, key)
end

server.update = function(self, dt)
	self.totalDeltaTime = self.totalDeltaTime + dt
	while self.totalDeltaTime > self.updateTimeStep do
		self:fixedUpdate(self.updateTimeStep)
		self.totalDeltaTime = self.totalDeltaTime - self.updateTimeStep
	end
end

server.fixedUpdate = function(self, dt)
	Net:update(dt)

	local clients = {}

	for id, data in pairs(Net:connectedUsers()) do
		if data.greeted ~= true then
			Net:send({}, "print", "Welcome to Brokkr! Now the server is up.", id)
			Net:send(self.mapTable, "getMapName", "", id)
			data.greeted = true
			Net.users[id].x = self.window.width * 0.5 - self.characterTile.width * 0.5
			Net.users[id].y = self.window.height * 0.5 - self.characterTile.height * 0.5
			Net.users[id].speed = 100
			Net.users[id].bombCooldownTime = 1 -- time between player can play bombs
			Net.users[id].bombCountdown = 0 -- time left until player can place new bomb
			Net.users[id].direction = 1
			Net.users[id].isMoving = 0
			Net.users[id].actions = {up = false, down = false, left = false, right = false, bomb = false}
		end

		-- place bomb key
		if Net.users[id].actions.bomb  and Net.users[id].bombCountdown <= 0 then
			Net.users[id].actions.bomb = false
			Net.users[id].bombCountdown = Net.users[id].bombCooldownTime

			-- take location from the bottom middle of the character sprite
			local location = {
				mapX = math.floor((Net.users[id].x + self.characterTile.width * 0.5) / self.window.width * Map.width),
				mapY = math.floor((Net.users[id].y + self.characterTile.height) / self.window.height * Map.height)
			}

			for id, data in pairs(Net:connectedUsers()) do
				Net:send(location, "addBomb", "", id)
			end
		end

		Net.users[id].bombCountdown = Net.users[id].bombCountdown - dt
		if Net.users[id].bombCountdown < 0 then
			Net.users[id].bombCountdown = 0
		end

		local change = dt * Net.users[id].speed

		self:moveCheck(dt, id)

		Net.users[id].isMoving = 0
		if Net.users[id].actions.up or Net.users[id].actions.down or Net.users[id].actions.left or Net.users[id].actions.right then
			Net.users[id].isMoving = 1
		end

		clients[id] = Net.users[id].x .. "," .. Net.users[id].y .. "," .. Net.users[id].direction .. "," .. Net.users[id].isMoving
	end

	for id, data in pairs(Net:connectedUsers()) do
		Net:send(clients, "showLocation", "", id)
	end
end

server.draw = function(self)
	--[[for y = 1, #Map.values  do
		for x = 1, #Map.values[y] do
			love.graphics.draw(
				Map.tileset.image,
				Map.tiles[Map.values[y][x] + 1].img,
				(x - 1) * Map.tileWidth,
				(y - 1) * Map.tileHeight
			)
		end
	end]]

	love.graphics.print("SERVER", 10, 10)

	local textY = 30
	-- draw all players
	for k, v in pairs(Net.users) do
		love.graphics.rectangle("fill", v.x, v.y, self.characterTile.width, self.characterTile.height)
		love.graphics.print(k .. ", " .. v.x .. ":" .. v.y, 10, textY)
		textY = textY + 20
	end
end

server.quit = function(self)
	for id, data in pairs(Net:connectedUsers()) do
		Net:send({}, "print", "The server has been closed.", id)
	end
	Net:disconnect()
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

return server
