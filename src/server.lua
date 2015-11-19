local Net = require "dependencies/Net"
local server = {}

server.load = function(self)
  self.windowWidth = love.graphics.getWidth()
  self.windowHeight = love.graphics.getHeight()
  self.worldTileWidth = 64
  self.worldTileHeight = 64
  self.characterTileWidth = 32
  self.characterTileHeight = 32
  self.ip, self.port = nil, 6789
  self.maxPing = 3000
  self.totalDeltaTime = 0
  self.updateTimeStep = 0.01

  Net:init("Server")
  Net:connect(self.ip, self.port)
  Net:setMaxPing(self.maxPing)

  Net:registerCMD("key_pressed", function(table, param, id) self:keyPressed(id, param, true) end)
  Net:registerCMD("key_released", function(table, param, id) self:keyPressed(id, param, false) end)
end

server.mousepressed = function(self, x, y, button)
end

server.keyPressed = function(self, id, key, value)
  if Net.users[id] and (key == "up" or key == "down" or key == "right" or key == "left" or key == " ") then
    Net.users[id].key[key] = value
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
      Net:send({}, "print", "Welcome to Brokkr", id)
      data.greeted = true
      Net.users[id].x = self.windowWidth * 0.5 - self.characterTileWidth * 0.5
      Net.users[id].y = self.windowHeight * 0.5 - self.characterTileHeight * 0.5
      Net.users[id].speed = 100
      Net.users[id].direction = 1
      Net.users[id].isMoving = 0
      Net.users[id].key = {}
    end

    -- place bomb key
    if Net.users[id].key[" "] then
      print("do bomb stuff")
      Net.users[id].key[" "] = false
    end

    local change = dt * Net.users[id].speed
    if Net.users[id].key["up"] then Net.users[id].direction = 2; Net.users[id].y = Net.users[id].y - change end
    if Net.users[id].key["down"] then Net.users[id].direction = 1; Net.users[id].y = Net.users[id].y + change end
    if Net.users[id].key["right"] then Net.users[id].direction = 3; Net.users[id].x = Net.users[id].x + change end
    if Net.users[id].key["left"] then Net.users[id].direction = 4; Net.users[id].x = Net.users[id].x - change end

    Net.users[id].isMoving = 0
    if Net.users[id].key["up"] or Net.users[id].key["down"] or Net.users[id].key["right"] or Net.users[id].key["left"] then
      Net.users[id].isMoving = 1
    end

    clients[id] = Net.users[id].x .. "," .. Net.users[id].y .. "," .. Net.users[id].direction .. "," .. Net.users[id].isMoving
  end

  for id, data in pairs(Net:connectedUsers()) do
    Net:send(clients, "showLocation", "", id)
  end
end

server.draw = function(self)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, 1000, 1000)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.print("server", 10, love.graphics.getHeight() - 60)
end

return server
