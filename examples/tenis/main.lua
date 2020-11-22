rx = require'rx'
require'exhaustMap'
require'resub'

--local scheduler = rx.CooperativeScheduler.create()
love.keypressed = rx.Subject.create()
love.keyreleased = rx.Subject.create()
love.update = rx.Subject.create()

local screenWidth = 640
local screenHeight = 480

local bumperSpeed = 300
local bumperWidth = 15
local bumperHeight = 80
local bumper1x = bumperWidth
local bumper1y = (screenHeight - bumperHeight) / 2
local bumper2x = screenWidth - 2 * bumperWidth
local bumper2y = bumper1y

local ballSize = 20
local ballx = (screenWidth - ballSize) / 2
local bally = (screenHeight - ballSize) / 2

function bumperPosFactory(keyUp, keyDown, currPos)
	return love.keypressed
		:filter(function(key) return key == keyUp or key == keyDown end)
		:exhaustMap(function(key)
			local speed = key == keyUp and -bumperSpeed or bumperSpeed
			return love.update:map(function(dt) return dt * speed end)
				:scan(function(acc, new) return acc + new end, currPos)
				:takeWhile(function(pos)
					return pos >= 0 and pos <= screenHeight - bumperHeight
				end)
				:takeUntil(love.keyreleased:filter(function(k) return key == k end))
				:tap(function(pos) currPos = pos end)
		end)
end

function love.load()
	love.window.setMode(screenWidth, screenHeight)

	bumper1yS = bumperPosFactory('w', 's', bumper1y)
	bumper2yS = bumperPosFactory('up', 'down', bumper2y)
	bumper1yS:subscribe(function(pos) bumper1y = pos end)
	bumper2yS:subscribe(function(pos) bumper2y = pos end)
end

--[[
function love.update(dt)
	scheduler:update(dt)
end
--]]

function love.draw()
	love.graphics.rectangle('fill', ballx, bally, ballSize, ballSize)
	love.graphics.rectangle('fill', bumper1x, bumper1y, bumperWidth, bumperHeight)
	love.graphics.rectangle('fill', bumper2x, bumper2y, bumperWidth, bumperHeight)
end
