local Global = require "global"
local menu = {}

--[[
	Initialising function.
]]
menu.load = function(self)
	self.originalFont = love.graphics.getFont()
	self.ip = Global.ip
	self.invalid = {r = 255, g = 0, b = 0, a = 255} -- color for when self.ip is not a valid ip adress
	self.valid = {r = 0, g = 255, b = 0, a = 255} -- color for when self.ip is a valid ip adress
	self.ipColor = self.valid
	self.headerFont = love.graphics.newFont("font/Ash.ttf", 70)
	self.buttonFont = love.graphics.newFont("font/Ash.ttf", 30)
	self.ipFont = love.graphics.newFont("font/Ash.ttf", 20)
	self.backgroundImage = love.graphics.newImage("image/background.png")

	-- initiate gui
	self.guiElements = {}
	self:addGuiItem("BROKKR", menu.headerFont, {r = 0, g = 0, b = 0, a = 255}, {r = 0, g = 0, b = 0, a = 0}, 10, 200, Global.window.width - 20, menu.headerFont:getHeight() - 15, 0)
	self:addGuiItem("HOST SERVER", menu.buttonFont, {r = 144, g = 144, b = 144, a = 255}, {r = 0, g = 0, b = 0, a = 255}, 10, 10, Global.window.width - 40, menu.buttonFont:getHeight(), 10)
	self:addGuiItem("JOIN SERVER", menu.buttonFont, {r = 144, g = 144, b = 144, a = 255}, {r = 0, g = 0, b = 0, a = 255}, 10, 10, Global.window.width - 40, menu.buttonFont:getHeight(), 10)
	self:addGuiItem("IP: 127.0.0.1", menu.ipFont, self.valid, {r = 0, g = 0, b = 0, a = 0}, 10, 10, Global.window.width - 20, menu.ipFont:getHeight(), 0)
end

--[[
	Mouse down function.
	- x: x coordinate of mouse pointer.
	- y: y coordinate of mouse pointer.
	- button: which button on the mouse was pressed.
]]
menu.mousepressed = function(self, x, y, button)
	local start = false

	-- check to see if server button is pressed
	local b1 = self.guiElements[2]
	if self:overButton(x, y, b1.x, b1.y, b1.width, b1.height) then
		run = require "server"
		start = true
	end

	-- check to see if client button is pressed
	local b2 = self.guiElements[3]
	if self:overButton(x, y, b2.x, b2.y, b2.width, b2.height) and self.ipColor == self.valid then
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
	self.guiElements[4].color = self.ipColor
	self.guiElements[4].text = "IP: " .. self.ip
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
	love.graphics.draw(self.backgroundImage, 0, 0)
	--love.graphics.rectangle("fill", 0, 0, Global.window.width, Global.window.height)
	for k, v in pairs(self.guiElements) do
		love.graphics.setFont(v.font)
		love.graphics.setColor(v.bgColor.r, v.bgColor.g, v.bgColor.b, v.bgColor.a)
		love.graphics.rectangle("fill", v.x, v.y, v.width, v.height)
		love.graphics.setColor(v.color.r, v.color.g, v.color.b, v.color.a)
		love.graphics.print(v.text, v.x + v.padding, v.y + v.padding)
	end
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
	local tmp = {ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")}
	for k, v in pairs(tmp) do if tonumber(v) > 255 then return false end end
	if #tmp == 4 then return true end
	return false
end

--[[
	Add a new element to the gui.
	- text: text contained whitin the gui element.
	- font: font used to display the text.
	- color: font color.
	- bgColor: color of the element box.
	- xOffset: horizontal offset from the left side of the window.
	- yOffset: vertical offset from the previous element.
	- width: width of the element box.
	- height: height of the element box.
	- padding: padding between the box edge and the containing text.
]]
menu.addGuiItem = function(self, text, font, color, bgColor, xOffset, yOffset, width, height, padding)
	local previousOffsetY = 0
	local lastElement = self.guiElements[#self.guiElements]
	-- offset it with respect of the previous gui element
	if #self.guiElements > 0 then previousOffsetY = lastElement.y + lastElement.height end
	local item = {
		text = text,
		font = font,
		color = color,
		bgColor = bgColor,
		x = xOffset,
		y = previousOffsetY + yOffset,
		width = width + padding * 2,
		height = height + padding * 2,
		padding = padding
	}
	table.insert(self.guiElements, item)
end

--[[
	Check if the mouse is ontop of a gui element.
	- mouseX: mouse x coordinate.
	- mouseY: mouse y coordinate.
	- boxX: x coordinate of upper left corner of the button.
	- boxY: y coordinate of upper left corner of the button.
	- width: width of the button.
	- height: height of the button.
]]
menu.overButton = function(self, mouseX, mouseY, boxX, boxY, width, height)
	if mouseX > boxX and mouseX < boxX + width and mouseY > boxY and mouseY < boxY + height then return true end
	return false
end

return menu
