rx = require'rx'
require'exhaustMap'
require'resub'

love.keypressed = rx.Subject.create()
love.keyreleased = rx.Subject.create()
love.update = rx.Subject.create()

local screenWidth = 640
local screenHeight = 480

local bumperSpeed = 400
local bumperWidth = 15
local bumperHeight = 80
local bumper1X = bumperWidth
local bumper1Y = (screenHeight - bumperHeight) / 2
local bumper2X = screenWidth - 2 * bumperWidth
local bumper2Y = bumper1Y

local ballSpeed = 250
local ballSize = 20
local ballXInitial = (screenWidth - ballSize) / 2
local ballYInitial = (screenHeight - ballSize) / 2
local ballX = ballXInitial
local ballY = ballYInitial
local ballXSpeed = ballSpeed
local ballYSpeed = 0

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

function didColideX()
	if ballY + ballSize>= bumper1Y and ballY <= bumper1Y + bumperHeight and
		ballX <= bumper1X + bumperWidth and ballXSpeed < 0 then
		return true
	end

	if ballY + ballSize >= bumper2Y and ballY <= bumper2Y + bumperHeight and
		ballX + ballSize >= bumper2X and ballXSpeed > 0 then
		return true
	end

	return false
end

function didColideY()
	return (ballY <= 0 and ballYSpeed < 0) or
		(ballY + ballSize >= screenHeight and ballYSpeed > 0)
end

function setBallDirection()
	local bumperY = ballX < screenWidth / 2 and bumper1Y or bumper2Y
	local top = math.max(ballY, bumperY)
	local distCenter = 2 * math.abs(bumperY + bumperHeight / 2 - top) / bumperHeight
	local dirX = ballXSpeed ~=0 and ballXSpeed / math.abs(ballXSpeed) or 1
	local dirY = top < bumperY + bumperHeight / 2 and -1 or 1
	ballYSpeed = distCenter * ballSpeed * dirY
end

function love.load()
	love.window.setMode(screenWidth, screenHeight)

	bumper1YS = bumperPosFactory('w', 's', bumper1Y)
	bumper2YS = bumperPosFactory('up', 'down', bumper2Y)
	bumper1YS:subscribe(function(pos) bumper1Y = pos end)
	bumper2YS:subscribe(function(pos) bumper2Y = pos end)

	didScoreS = rx.Subject.create()
	startMovingS = rx.BehaviorSubject.create(1)
	local ballPosS = startMovingS:exhaustMap(function()
		return love.update
			:map(function(dt) return dt * ballXSpeed, dt * ballYSpeed end)
			:scan(function(acc, newX, newY)
				acc = acc or {0, 0}
				acc[1] = acc[1] + newX
				acc[2] = acc[2] + newY
				return acc
			end, {ballX, ballY})
			:takeUntil(didScoreS)
			:tap(function()
				if didColideX() then
					ballXSpeed = -ballXSpeed
					setBallDirection()
				end
				if didColideY() then
					ballYSpeed = -ballYSpeed
				end
			end)
	end)

	ballPosS:subscribe(function(pos)
		ballX = pos[1]
		ballY = pos[2]
	end)

	ballPosS:subscribe(function(x)
		if ballX > screenWidth - ballSize or
			ballX < 0 then
			print('score')
			didScoreS(1)
			ballX = ballXInitial
			ballY = ballYInitial
			ballYSpeed = 0
			startMovingS(1)
		end
	end)
end

function love.draw()
	love.graphics.rectangle('fill', ballX, ballY, ballSize, ballSize)
	love.graphics.rectangle('fill', bumper1X, bumper1Y, bumperWidth, bumperHeight)
	love.graphics.rectangle('fill', bumper2X, bumper2Y, bumperWidth, bumperHeight)
end
