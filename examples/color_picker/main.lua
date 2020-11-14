local rx = require'rx'

love.mousemoved = rx.Subject.create()

local dimX, dimY = 150, 150
local posX, posY = 50, 50

-- Vertices colors
local colors = {{{1, 0, 0}, {0, 1, 0}},
                {{0, 0, 1}, {1, 1, 1}}}

local imgData = love.image.newImageData(dimX,dimY) -- Pixel colors
local img -- Drawable version of imgData
local text = ''

function getColor(x, y)
	x = x / (dimX - 1)
	y = y / (dimY - 1)
	local out = {0, 0, 0}
	for i = 1, 3 do
		out[i] = (colors[1][1][i] * (1 - x) + colors[1][2][i] * x) * (1 - y) +
		         (colors[2][1][i] * (1 - x) + colors[2][2][i] * x) * y
	end
	return out
end

function drawSquare()
	for y = 0, dimY - 1 do
		for x = 0, dimX - 1 do
			local r, g, b = unpack(getColor(x, y))
			imgData:setPixel(x, y, r, g, b, 1)
		end
	end
	img = love.graphics.newImage(imgData)
end

function love.load()
	drawSquare()
	love.mousemoved
		:filter(function(x, y)
			return x >= posX and x < posX + dimX and
			       y >= posY and y < posY + dimY
		end)
		:map(function(x, y)
			local color = getColor(x - posX, y - posY)
			return string.format('R: %0.2f  G: %0.2f  B: %0.2f', unpack(color))
		end)
		:subscribe(function(s) text = s end)
end

function love.draw()
	love.graphics.draw(img, posX, posY)
	love.graphics.print(text, 10, posY + dimY + 10)
end
