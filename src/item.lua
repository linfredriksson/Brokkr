local Item = {}

--[[
	Initiate item types and instance list.
]]
Item.initiate = function(self)
	self:resetInstances()
	self.type = {}
	self:addType("health", 255, 0, 0, 50, function(player) player.health = player.maxHealth end)
	self:addType("speed", 0, 255, 0, 50, function(player) player.speed = player.baseSpeed * 1.1 end)
	self:addType("reload", 0, 0, 255, 50, function(player) player.bombCooldownTime = player.baseBombCooldownTime * 0.75 end)
end

--[[
	Add new type of item.
]]
Item.addType = function(self, type, r, g, b, a, callback)
	self.type[type] = {
		color = {r = r, g = g, b = b, a = a},
		callback = callback
	}
end

--[[
	Add item instance.
	- type: type of item.
	- x: x position on map.
	- y: y position on map.
]]
Item.add = function(self, type, x, y)
	self.instances[#self.instances + 1] = {
		type = self.type[type], x = x, y = y
	}
end

--[[
	Remove any item on the tile x, y.
	- x: x position of tile on map.
	- y: y position of tile on map.
]]
Item.remove = function(self, x, y)
	for id = #self.instances, 1, -1 do
		if self.instances[id].x == x and self.instances[id].y == y then
			table.remove(self.instances, id)
		end
	end
end

--[[
	Remove all existing items.
]]
Item.resetInstances = function(self)
	self.instances = {}
end

--[[
	Check if a position is ontop of a tile with a item. If it is then return the
	item, else return nil.
	- inX: x coordinate on game map.
	- inY: y coordinate on game map.
]]
Item.find = function(self, inX, inY)
	local x = math.ceil(inX / 32 - 0.5)
	local y = math.ceil(inY / 32)
	for key, item in pairs(self.instances) do
		if item.x == x and item.y == y then
			return item
		end
	end
	return nil
end

return Item
