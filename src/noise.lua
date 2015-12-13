local noise = {
	width = 0,
	height = 0
}

-- initialize seed for random number generator
math.randomseed(os.time())

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
noise.generate = function(self)
	self.noise = {}
	for y = 1, self.height do
		self.noise[y] = {}
		for x = 1, self.width do
			self.noise[y][x] = math.random()
		end
	end
end

return noise
