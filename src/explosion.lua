local anim8 = require "dependencies/anim8"

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
		tileHeight = inImage:getHeight(),
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
	- inDirections: is used to show in wich directions the explosion will spread.
		1, 2, 3, 4 equals to up, right, down, left.
	- inPosX: is the x coordinate in the self.map.
	- inPosY: is the y coordinate in the selt.map.
	- inSpreadDistance: indicates how far the explision will spread from its center.
	- inSpreadRate: indicates how fast the explosion will spread.
]]
explosion.addInstance = function(self, inDirections, inPosX, inPosY, inSpreadDistance, inSpreadRate)
	local inType = self.type[math.random(#self.type)] -- assign random explosion type
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
	Updates all animations of explosions currently on the map.
	- dt: delta time since last update.
]]
explosion.updateAnimation = function(self, dt)
	for i = 1, #self.instances do
		self.instances[i].animation:update(dt)
	end
end

--[[
	Updates all explosion instances currently on the map and spread new ones if needed.
	- dt: delta time since last update.
]]
explosion.update = function(self, inMap, dt)
	local instances = self.instances

	-- empty the instance list, then add back the instances that still
	-- have time left on its timer.
	self.instances = {}

	-- update all instances in the local instance table
	for instanceID = 1, #instances do
		local instance = instances[instanceID]
		instance.timer = instance.timer - dt

		if instance.spreadDistance > 0 and instance.timer < instance.spreadRate then
			self:spread(instance, inMap, dt)
			instance.spreadDistance = 0
		end

		if instance.timer > 0 then
			self.instances[#self.instances + 1] = instance
		end
	end
end

--[[
	Spread a instance if needed.
	- instance: instance of a explosion.
	- dt: delta time since last update.
]]
explosion.spread = function(self, instance, inMap, dt)
	local walkable = {
		current = true,
		above = inMap.tiles[inMap.values[instance.y + 0][instance.x + 1] + 1].walkable,
		below = inMap.tiles[inMap.values[instance.y + 2][instance.x + 1] + 1].walkable
	}
	local offsetX = {0, 1, 0, -1}
	local offsetY = {-1, 0, 1, 0}

	for dir1ID = 1, #instance.spreadDirections do
		local dir1 = instance.spreadDirections[dir1ID]
		local directions = {}
		local pos = {
			x = instance.x + offsetX[dir1],
			y = instance.y + offsetY[dir1]
		}
		walkable.current = inMap.tiles[inMap.values[pos.y + 1][pos.x + 1] + 1].walkable

		if walkable.current then
			-- find wich directions the explosion will continue to spread in
			for dir2ID = 1, #instance.spreadDirections do
				local dir2 = instance.spreadDirections[dir2ID]

				if ((dir1 == 2 and dir2 ~= 4) or -- dont add dir2 if opposite to dir1
					(dir1 == 4 and dir2 ~= 2) or
					(dir1 == dir2))
					and -- only spread up or down if no wall is in the way
					not((dir2 == 1 and not walkable.above) or
					(dir2 == 3 and not walkable.below))
				then
					directions[#directions + 1] = dir2
				end
			end

			self:addInstance(
				directions,
				pos.x,
				pos.y,
				instance.spreadDistance - 1,
				instance.spreadRate
			)
		end
	end
end

return explosion
