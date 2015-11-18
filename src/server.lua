local server = {}

server.load = function(self)
  print("server")
end

server.mousepressed = function(self, x, y, button)
end

server.keypressed = function(self, key)
end

server.keyreleased = function(self, key)
end

server.update = function(self, dt)
end

server.draw = function(self)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.rectangle("fill", 0, 0, 1000, 1000)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.print("server", 10, love.graphics.getHeight() - 60)
end

return server
