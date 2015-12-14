local noise = {
	width = 0,
	height = 0
}

--[[
	Set the size of noise.
	- inWidth: width of 2d noise array
	- inHeight: height of 2d noise array
]]
noise.setSize = function(self, inWidth, inHeight)
	self.width = inWidth
	self.height = inHeight
end

--[[
	Generate noise values.
]]
noise.generate = function(self, seed)
	-- initialize seed for random number generator
	math.randomseed(seed)

	self.noise = {}
	for y = 1, self.height do
		self.noise[y] = {}
		for x = 1, self.width do
			self.noise[y][x] = math.random()
		end
	end
end

--[[
	Get noise value at specific position in the noise array.
	- x: x position in 2d noise array.
	- y: y position in 2d noise array.
]]
noise.get = function(self, x, y)
	if x >= 1 and y >= 1 and x < self.width and y < self.height then
		return self.noise[y][x]
	end
	return 0
end

--[[
	Get smooth noise values at specific position in the noise array.
	- x: x position in 2d noise array.
	- y: y position in 2d noise array.
]]
noise.getSmooth = function(self, x, y)
	local fractX = x - math.floor(x)
	local fractY = y - math.floor(y)

	local x1 = (math.floor(x) + self.width) % self.width
	local y1 = (math.floor(y) + self.height) % self.height

	local x2 = (x1 + self.width - 1) % self.width
	local y2 = (y1 + self.height - 1) % self.height

	-- lua start index at 1 instead of 0, ugly fix
	x1 = x1 + 1
	x2 = x2 + 1
	y1 = y1 + 1
	y2 = y2 + 1

	local value = 0
	value = value + fractX       * fractY       * self.noise[y1][x1]
	value = value + fractX       * (1 - fractY) * self.noise[y2][x1]
	value = value + (1 - fractX) * fractY       * self.noise[y1][x2]
	value = value + (1 - fractX) * (1 - fractY) * self.noise[y2][x2]

	return value
end

--[[
	Turbulence adds together mutliple smooth noise values at different zoom levels.
	- x: x position in 2d noise array.
	- y: y position in 2d noise array.
	- size: zoom levels.
]]
noise.turbulence = function(self, x, y, size)
	local initialSize = size
	local value = 0

	while size >= 1 do
		value = value + self:getSmooth(x / size, y / size) * size
		size = size / 2
	end

	return value / initialSize
end

return noise
