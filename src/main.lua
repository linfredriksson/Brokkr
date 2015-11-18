run = require "menu"

function love.load()
  run:load()
end

function love.mousepressed(x, y, button)
  run:mousepressed(x, y, button)
end

function love.keypressed(key)
  run:keypressed(key)
end

function love.keyreleased(key)
  run:keyreleased(key)
end

function love.update(dt)
  run:update(dt)
end

function love.draw()
  run:draw()
end
