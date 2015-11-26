local Net = require "dependencies/Net"
local server = {}

server.load = function(self)
	self.window = {width = love.graphics.getWidth(), height = love.graphics.getHeight()}
	self.characterTile = {grid = nil, width = 32, height = 32}
	self.world = {tileWidth = 32, tileHeight = 32, width = 24, height= 16}
	self.ip, self.port, self.maxPing = nil, 6789, 3000
	self.totalDeltaTime, self.updateTimeStep = 0, 0.01
	self.mapTable = {map = "full"} 

	Net:init("Server")
	Net:connect(self.ip, self.port)
	Net:setMaxPing(self.maxPing)

	Net:registerCMD("key_pressed", function(table, param, id) self:keyRecieved(id, param, true) end)
	Net:registerCMD("key_released", function(table, param, id) self:keyRecieved(id, param, false) end)

	--self.tileset, self.tiles, self.map.values = Map:chooseMap(self.map.name, self.world)
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
			Net.users[id].direction = 1
			Net.users[id].isMoving = 0
			Net.users[id].actions = {up = false, down = false, left = false, right = false, bomb = false}
		end

		-- place bomb key
		if Net.users[id].actions.bomb then
			print("do bomb stuff")
			Net.users[id].actions.bomb = false
		end

		local change = dt * Net.users[id].speed
		if Net.users[id].actions.up then Net.users[id].direction = 2; Net.users[id].y = Net.users[id].y - change end
		if Net.users[id].actions.down then Net.users[id].direction = 1; Net.users[id].y = Net.users[id].y + change end
		if Net.users[id].actions.left then Net.users[id].direction = 4; Net.users[id].x = Net.users[id].x - change end
		if Net.users[id].actions.right then Net.users[id].direction = 3; Net.users[id].x = Net.users[id].x + change end

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
	love.graphics.print("SERVER", 10, 10)

	local textY = 30
	-- draw dots for all players
	for k, v in pairs(Net.users) do
		love.graphics.circle("fill", v.x, v.y, self.characterTile.width * 0.5)
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

return server
