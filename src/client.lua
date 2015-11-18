local client = {}

client.load = function(self)
  print("client")
end

client.mousepressed = function(self, x, y, button)
end

client.keypressed = function(self, key)
end

client.keyreleased = function(self, key)
end

client.update = function(self, dt)
end

client.draw = function(self)
  love.graphics.print("client", 10, 10)
end

return client
