function love.load()
end

function love.update()
end

function love.draw()
	love.graphics.setColor(255, 100, 100)
	love.graphics.rectangle("fill", 10, 10, 10, 10)

	love.graphics.setColor(255, 255, 255)
    love.graphics.print("Hello World", 400, 300)
end