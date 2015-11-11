local Net = require "Net"

local windowWidth = 768 -- client window size
local windowHeight = 512 -- client window size
local worldTileWidth = 64
local worldTileHeight = 64
local characterTileWidth = 32
local characterTileHeight = 32
local ip, port = nil, 6789
local maxPing = 3000

function love.load()
  Net:init("Server")
  Net:connect(ip, port)
  Net:setMaxPing(maxPing)

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
      Net.users[id].x = windowWidth * 0.5 - characterTileWidth * 0.5
      Net.users[id].y = windowHeight * 0.5 - characterTileHeight * 0.5
      Net.users[id].speed = 100
      Net.users[id].direction = 0
      Net.users[id].isMoving = 0
      Net.users[id].key = {}
    end

    local change = dt * Net.users[id].speed
    if Net.users[id].key["up"] then Net.users[id].direction = 1; Net.users[id].y = Net.users[id].y - change end
    if Net.users[id].key["down"] then Net.users[id].direction = 0; Net.users[id].y = Net.users[id].y + change end
    if Net.users[id].key["right"] then Net.users[id].direction = 2; Net.users[id].x = Net.users[id].x + change end
    if Net.users[id].key["left"] then Net.users[id].direction = 3; Net.users[id].x = Net.users[id].x - change end

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

function love.draw()
end
