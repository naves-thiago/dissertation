local loading_icon_t = require('loadingIcon').loading_icon_t
local rx = require'rx'
require'exhaustMap'

love.mousemoved = rx.Subject.create()
love.mousepressed = rx.Subject.create()
love.mousereleased = rx.Subject.create()

local square

function love.load()
	square = loading_icon_t:new(200, 200, 50)

	love.mousepressed
		:filter(function(x, y) -- Only consider clicks inside the square
			return x >= square.x and x <= square.x + square.size and
			       y >= square.y and y <= square.y + square.size
		end)
		:exhaustMap(function(start_x, start_y) -- Restart for each mousepressed event
			local squarex = start_x - square.x -- Find the click position realtive to the square corner
			local squarey = start_y - square.y
			return love.mousemoved
						:map(function(x, y) -- offset by the relative click position
							return x - squarex, y - squarey
						end)
						:takeUntil(love.mousereleased) -- stop tracking when the mouse is released
		end)
		:subscribe(function(x, y)
			square.x = x
			square.y = y
		end)
end

function love.draw()
	square:draw()
end
