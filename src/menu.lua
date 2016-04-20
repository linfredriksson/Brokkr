local Global = require "global"
local menu = {}

--[[
	Initialising function.
]]
menu.load = function(self)
	menu.originalFont = love.graphics.getFont()
	menu.font = love.graphics.newFont(50)
	love.graphics.setFont(menu.font)
	self.ip = Global.ip
	self.invalid = {r = 255, g = 0, b = 0, a = 255} -- color for when self.ip is not a valid ip adress
	self.valid = {r = 0, g = 255, b = 0, a = 255} -- color for when self.ip is a valid ip adress
	self.ipColor = self.valid
end

--[[
	Mouse down function.
	- x: x coordinate of mouse pointer.
	- y: y coordinate of mouse pointer.
	- button: which button on the mouse was pressed.
]]
menu.mousepressed = function(self, x, y, button)
	local start = false

	-- server
	if y < love.graphics.getHeight() * 0.5 then
		run = require "server"
		start = true
	end

	-- client
	if y >= love.graphics.getHeight() * 0.5 and self.ipColor == self.valid then
		run = require "client"
		Global.ip = self.ip
		start = true
	end

	-- start server or client depending which half of the screen the user clicks on.
	if start then
		love.graphics.setFont(menu.originalFont)
		run:load()
	end
end

--[[
	Key down function.
	- key: keyboard button beeing pressed.
]]
menu.keypressed = function(self, key)
	if key == "backspace" then self.ip = string.sub(self.ip, 0, -2) end
	local char = key:gsub("kp", "")
	if tonumber(char) or char == "." then self.ip = self.ip .. char end
	self.ipColor = self.invalid
	if self:validIp(self.ip) then self.ipColor = self.valid end
end

--[[
	Key up function.
	- key: keyboard button beeing pressed.
]]
menu.keyreleased = function(self, key)
end

--[[
	Update function.
	- dt: delta time, time since last update.
]]
menu.update = function(self, dt)
end

--[[
	Draw function. Draw two buttons, top half of window is server button,
	bottom half of window is client button.
]]
menu.draw = function(self)
	love.graphics.rectangle("fill", 0, 0, 1000, 1000)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle("fill", 0, love.graphics.getHeight() * 0.5, 1000, 1000)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.print("HOST GAME", 10, love.graphics.getHeight() * 0.5 - 55)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print("JOIN GAME", 10, love.graphics.getHeight() * 0.5 + 5)
	love.graphics.setColor(self.ipColor.r, self.ipColor.g, self.ipColor.b, self.ipColor.a)
	love.graphics.print("IP: " .. self.ip, 10, love.graphics.getHeight() - menu.font:getHeight())
	love.graphics.setColor(255, 255, 255, 255)
end

--[[
	Quit function.
]]
menu.quit = function(self)
end

--[[
	Check if a certain ip is a valid ip4 adress with four sequences of numbers
	in the range of 0 to 999 separated by dots. Returns true if it is valid,
	otherwise false.
	- ip: a string containing the ip to check.
]]
menu.validIp = function(self, ip)
	local tmp = {self.ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")}
	for k, v in pairs(tmp) do if tonumber(v) > 255 then return false end end
	if #tmp == 4 then
		return true
	end
	return false
end

return menu
