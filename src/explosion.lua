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
	Creates a explosion instance on the map square newX, newY.
	- inType: is the explosion type.
	- inDirections: is used to show in wich directions the explosion will spread.
	- inPosX: is the x coordinate in the self.map.
	- inPosY: is the y coordinate in the selt.map.
	- inSpreadDistance: indicates how far the explision will spread from its center.
	- inSpreadRate: indicates how fast the explosion will spread.
]]
explosion.addInstance = function(self, inType, inDirections, inPosX, inPosY, inSpreadDistance, inSpreadRate)
	local instance = {
		type = inType,
		timer = inType.animationDuration,
		x = inPosX,
		y = inPosY,
		spreadDirections = inDirections,
		spreadDistance = inSpreadDistance,
		spreadRate = inSpreadRate,
		animation = anim8.newAnimation(inType.grid("1-" .. inType.numberOfTiles, 1), inType.frameDuration)
	}
	self.instances[#self.instances + 1] = instance
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
