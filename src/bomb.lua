local explosion = require "explosion"
local bomb = {}

--[[
	Initiate the bomb instances and bomb type lists.
]]
bomb.initiate = function(self)
	self:resetInstances()
	self.type = {}
	bomb:addType("image/bomb.png", 1, 2, 1.8)
	bomb:addType("image/bomb.png", 1, 5, 1.8)
end

--[[
	Removes all bomb instances.
]]
bomb.resetInstances = function(self)
	self.instances = {}
end

--[[
	Creates a object that represents one type of bomb.
	- inImage: is a loaded image containing the tileset of a bomb.
	- inCountDown: the cooldown time that indicates how long a player have to wait between dropping two bombs.
	- inSpreadDistance: how many tiles the explosion will spread from the bombs location.
	- inSpreadRate: how fast the explosion spreads to new tiles.
]]
bomb.addType = function(self, inImage, inCountDown, inSpreadDistance, inSpreadRate)
	local type = {
		image = love.graphics.newImage(inImage),
		countDown = inCountDown,
		spreadDistance = inSpreadDistance,
		spreadRate = inSpreadRate,
		directions = {1, 2, 3, 4}
	}
	self.type[#self.type + 1] = type;
end

--[[
	Creates a bomb instance on the map square coordX, coordY.
	- inBombTypeID: id of bomb type.
	- coordX: is the x coordinate on the game map.
	- coordY: is the y coordinate on the game map.
]]
bomb.addInstance = function(self, inBombTypeID, coordX, coordY)
	local instance = {
		bombType = self.type[inBombTypeID],
		countDown = self.type[inBombTypeID].countDown,
		x = coordX,
		y = coordY
	}
	self.instances[#self.instances + 1] = instance
end

--[[
	Updates all bombs placed on the map, counts them down untill they explode
	and generates explosions around them.
	- dt: delta time since last update.
]]
bomb.update = function(self, dt)
	local instances = self.instances
	self.instances = {}

	for i = 1, #instances do
		local instance = instances[i]
		instance.countDown = instance.countDown - dt

		if instance.countDown < 0.0 then
			explosion:addInstance(
				instance.bombType.directions,
				instance.x,
				instance.y,
				instance.bombType.spreadDistance,
				instance.bombType.spreadRate
			)
		else
			self.instances[#self.instances + 1] = instance
		end
	end
end

return bomb
