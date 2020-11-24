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
local ballxInitial = (screenWidth - ballSize) / 2
local ballyInitial = (screenHeight - ballSize) / 2
local ballx = ballxInitial
local bally = ballyInitial
local ballxSpeed = 300
local ballySpeed = 300

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

function didColide()
	if bally + ballSize>= bumper1y and bally <= bumper1y + bumperHeight and
		ballx <= bumper1x + bumperWidth and ballxSpeed < 0 then
		return true
	end

	if bally + ballSize >= bumper2y and bally <= bumper2y + bumperHeight and
		ballx + ballSize >= bumper2x and ballxSpeed > 0 then
		return true
	end

	return false
end

--[[
function clamp(val, min, max)
	if val > max then
		return max
	end

	if val < min then
		return min
	end

	return val
end
--]]

function love.load()
	love.window.setMode(screenWidth, screenHeight)

	bumper1yS = bumperPosFactory('w', 's', bumper1y)
	bumper2yS = bumperPosFactory('up', 'down', bumper2y)
	bumper1yS:subscribe(function(pos) bumper1y = pos end)
	bumper2yS:subscribe(function(pos) bumper2y = pos end)

	didScoreS = rx.Subject.create()
	startMovingS = rx.BehaviorSubject.create(1)
	ballxS = startMovingS:exhaustMap(function()
		return love.update
			:map(function(dt) return dt * ballxSpeed end)
			:scan(function(acc, new) return acc + new end, ballx)
			:takeUntil(didScoreS)
			:tap(function()
				if didColide() then
					ballxSpeed = -ballxSpeed
				end
			end)
			--:tap(nil, nil, function() print("complete") end)
	end)

	ballxS:subscribe(function(x) ballx = x end)

	ballxS:subscribe(function(x)
		if ballx > screenWidth - ballSize or
			ballx < 0 then
			print('score')
			didScoreS(1)
			ballx = ballxInitial
			bally = ballyInitial
			startMovingS(1)
		end
	end)
end

function love.draw()
	love.graphics.rectangle('fill', ballx, bally, ballSize, ballSize)
	love.graphics.rectangle('fill', bumper1x, bumper1y, bumperWidth, bumperHeight)
	love.graphics.rectangle('fill', bumper2x, bumper2y, bumperWidth, bumperHeight)
end
