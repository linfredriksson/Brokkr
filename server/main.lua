local Net = require "Net"

local windowWidth = 0
local windowHeight = 0

function love.load()
  windowWidth = love.graphics.getWidth()
  windowHeight = love.graphics.getHeight()

  Net:init("Server")
  Net:connect(nil, 6789)

  Net:registerCMD("key_pressed", function(table, param, id) keyPressed(id, param, true) end)
  Net:registerCMD("key_released", function(table, param, id) keyPressed(id, param, false) end)
end

function keyPressed(id, key, value)
  if Net.users[id] and (key == "up" or key == "down" or key == "right" or key == "left") then
    Net.users[id].key[key] = value
  end
end

function love.update(dt)
  Net:update(dt)

  local clients = {}

  for id, data in pairs(Net:connectedUsers()) do
    if data.greeted ~= true then
      Net:send({}, "print", "Welcome to Brokkr", id)
      data.greeted = true
      Net.users[id].x = windowWidth * 0.5
      Net.users[id].y = windowHeight * 0.5
      Net.users[id].speed = 100
      Net.users[id].key = {}
    end

    local change = dt * Net.users[id].speed
    if Net.users[id].key["up"] then Net.users[id].y = Net.users[id].y - change end
    if Net.users[id].key["down"] then Net.users[id].y = Net.users[id].y + change end
    if Net.users[id].key["right"] then Net.users[id].x = Net.users[id].x + change end
    if Net.users[id].key["left"] then Net.users[id].x = Net.users[id].x - change end

    clients[id] = Net.users[id].x .. "," .. Net.users[id].y
  end

  for id, data in pairs(Net:connectedUsers()) do
    Net:send(clients, "showLocation", "", id)
  end
end

function love.draw()
end
