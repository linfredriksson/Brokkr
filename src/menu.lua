local menu = {}

--[[
	Initialising function.
]]
menu.load = function(self)
	menu.originalFont = love.graphics.getFont()
	menu.font = love.graphics.newFont(50)
	love.graphics.setFont(menu.font)
end

--[[
	Mouse down function.
	- x: x coordinate of mouse pointer.
	- y: y coordinate of mouse pointer.
	- button: which button on the mouse was pressed.
]]
menu.mousepressed = function(self, x, y, button)
	love.graphics.setFont(menu.originalFont)

	-- start server or client depending which half of the screen the user clicks on.
	if y < love.graphics.getHeight() * 0.5 then
		run = require "server"
	else
		run = require "client"
	end

	-- initiate client or server.
	run:load()
end

--[[
	Key down function.
	- key: keyboard button beeing pressed.
]]
menu.keypressed = function(self, key)
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
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("fill", 0, 0, 1000, 1000)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle("fill", 0, love.graphics.getHeight() * 0.5, 1000, 1000)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.print("HOST GAME", 10, love.graphics.getHeight() * 0.5 - 55)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print("JOIN GAME", 10, love.graphics.getHeight() * 0.5 + 5)
end

--[[
	Quit function.
]]
menu.quit = function(self)
end

return menu
