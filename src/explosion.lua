local explosion = {}

explosion.initiate = function(self)
	self.instances = {}
	self.type = {}
end

explosion.addType = function(self, image, numberOfTiles, animationDuration)
end

explosion.addInstance = function(self, type, directions, posX, posY, spreadDistance, spreadRate)
end

explosion.updateAnimation = function(self, dt)
end

explosion.update = function(self, dt)
end

return explosion
