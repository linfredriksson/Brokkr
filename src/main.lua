run = require "menu"

--[[
	Initialising function.
]]
function love.load()
	love.audio.setVolume(.5)
	love.audio.play(love.audio.newSource("sound/music.mp3"))
	run:load()
end

--[[
	Mouse down function.
	- x: x coordinate of mouse pointer.
	- y: y coordinate of mouse pointer.
	- button: which button on the mouse was pressed.
]]
function love.mousepressed(x, y, button)
	run:mousepressed(x, y, button)
end

--[[
	Key down function.
	- key: keyboard button being pressed.
]]
function love.keypressed(key)
	run:keypressed(key)
end

--[[
	Key up function.
	- key: keyboard button being pressed.
]]
function love.keyreleased(key)
	run:keyreleased(key)
end

--[[
	Update function.
	- dt: delta time, time since last update.
]]
function love.update(dt)
	run:update(dt)
end

--[[
	Draw function.
]]
function love.draw()
	run:draw()
end

--[[
	Quit function.
]]
function love.quit()
	run:quit()
end
