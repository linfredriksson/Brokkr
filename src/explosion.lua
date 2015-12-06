local explosion = {}

--[[
	Initiate the explosion instances and type lists.
]]
explosion.initiate = function(self)
	self.instances = {}
	self.type = {}
end

--[[
	Creates a object that can be used to render an explosion.
	- inImage: is a loaded image containing the tileset of a explosion animation.
	- inNumberOfTiles: is the number of tiles in the tileset image.
	- inAnimationDuration: is the total animation time of the explosion.
]]
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

--[[

]]
explosion.addInstance = function(self, type, directions, posX, posY, spreadDistance, spreadRate)
end

--[[

]]
explosion.updateAnimation = function(self, dt)
end

--[[

]]
explosion.update = function(self, dt)
end

return explosion
