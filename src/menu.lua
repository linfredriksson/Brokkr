local menu = {}

menu.load = function(self)
  menu.originalFont = love.graphics.getFont()
  menu.font = love.graphics.newFont(50)
  love.graphics.setFont(menu.font)
end

menu.mousepressed = function(self, x, y, button)
  if y < love.graphics.getHeight() * 0.5 then
    run = require "server"
  else
    run = require "client"
  end
  love.graphics.setFont(menu.originalFont)
  run:load()
end

menu.keypressed = function(self, key)
end

menu.keyreleased = function(self, key)
end

menu.update = function(self, dt)
end

menu.draw = function(self)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, 1000, 1000)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.rectangle("fill", 0, love.graphics.getHeight() * 0.5, 1000, 1000)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.print("SERVER", 10, love.graphics.getHeight() * 0.5 - 55)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.print("CLIENT", 10, love.graphics.getHeight() * 0.5 + 5)
end

return menu
