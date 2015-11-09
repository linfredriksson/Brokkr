local Net = require "Net"

local windowWidth = 0
local windowHeight = 0

function love.load()
  windowWidth = love.graphics.getWidth()
  windowHeight = love.graphics.getHeight()

  Net:init("Server")
  Net:connect(nil, 6789)
end

function love.update(dt)
  Net:update(dt)
end

function love.draw()
end
