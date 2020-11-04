local loading_icon_t = require('loadingIcon').loading_icon_t

local square, dragging, offset_x, offset_y

function love.mousepressed(x, y)
	-- Only consider clicks inside the square
	dragging = x >= square.x and x <= square.x + square.size and
	           y >= square.y and y <= square.y + square.size
	if dragging then
		-- Find the click position realtive to the square corner
		offset_x = x - square.x
		offset_y = y - square.y
	end
end

function love.mousemoved(x, y)
	-- offset by the relative click position
	if dragging then
		square.x = x - offset_x
		square.y = y - offset_y
	end
end

function love.mousereleased()
	dragging = false
end

function love.load()
	square = loading_icon_t:new(200, 200, 50)

end

function love.draw()
	square:draw()
end
