local explosion = {}

explosion.initiate = function(self)
	self.instances = {}
	self.type = {}
end

explosion.addType = function(self, inImage, inNumberOfTiles, inAnimationDuration)
	local type = {
		animationDuration = inAnimationDuration,
		frameDuration = inAnimationDuration / inNumberOfTiles,
		numberOfTiles = inNumberOfTiles,
		tileset = inImage,
		tileWidth = math.floor(inImage:getWidth() / inNumberOfTiles),
		tileHeight = image:getHeight(),
		grid = nil
	}
	type.grid = anim8.newGrid(
		type.tileWidth,
		type.tileHeight,
		inImage:getWidth(),
		inImage:getHeight()
	)
	self.type[#self.type + 1] = type
end

explosion.addInstance = function(self, type, directions, posX, posY, spreadDistance, spreadRate)
end

explosion.updateAnimation = function(self, dt)
end

explosion.update = function(self, dt)
end

return explosion
