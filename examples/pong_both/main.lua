rx = require'rx'
require'exhaustMap'
tasks = require'tasks'

love.keypressed = rx.Subject.create()
love.keyreleased = rx.Subject.create()

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

local matchLen = 180 -- Seconds
local clockText = ''

local updateS = rx.Subject.create()
function love.update(dt)
	updateS(dt)
	tasks.emit('update', dt)
	tasks.update_time(dt * 1000)
end

function bumperPosFactory(keyUp, keyDown, currPos)
	return love.keypressed
		-- Filtra as teclas de interesse
		:filter(function(key) return key == keyUp or key == keyDown end)
		:exhaustMap(function(key)
			-- Define a direção do movimento (constante enquanto a
			-- tecla estiver pressionada)
			local speed = key == keyUp and -bumperSpeed or bumperSpeed
			return updateS:map(function(dt) return dt * speed end)
				-- Acumula a posição Y do rebatedor
				:scan(function(acc, new) return acc + new end, currPos)
				:takeWhile(function(pos)
					return pos >= 0 and pos <= screenHeight - bumperHeight
				end)
				-- Para ao soltar a tecla apenas se for a tecla que
				-- iniciou o movimento
				:takeUntil(love.keyreleased:filter(function(k) return key == k end))
				-- Guarda a posição atual para a próxima vez que o rebatedor
				-- for movido
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
	local dirY = top < bumperY + bumperHeight / 2 and -1 or 1
	ballYSpeed = distCenter * ballSpeed * dirY
end

function startBallTask()
	local function update_ball_pos()
		while true do
			local dt = tasks.await('update')
			-- Calcula o deslocamento da bola a cada dt segundos
			ballX = ballX + ballXSpeed * dt
			ballY = ballY + ballYSpeed * dt
			if didColideX() then
				-- Colisão com rebatedor -> calcula nova velocidade em Y
				ballXSpeed = -ballXSpeed
				setBallDirection()
			end
			if didColideY() then
				-- Colisão com a borda superior / inferior
				ballYSpeed = -ballYSpeed
			end
			if ballX > screenWidth - ballSize or
				ballX < 0 then
				-- Colisão com a borda direita / esquerda -> ponto
				print('score')
				ballX = ballXInitial
				ballY = ballYInitial
				ballYSpeed = 0
			end
		end
	end
	tasks.par_or(
		update_ball_pos,
		function()
			-- Para a bola quando acabar o tempo da partida
			tasks.await_ms(matchLen * 1000)
			clockText = '00:00'
		end,
		function()
			-- Atualiza o relógio na tela uma vez por segundo
			local time = math.ceil(matchLen - tasks.now_ms() / 1000)
			clockText = string.format('%02d:%02d', time / 60, time % 60)
			while true do
				tasks.await_ms(1000)
				time = math.ceil(matchLen - tasks.now_ms() / 1000)
				clockText = string.format('%02d:%02d', time / 60, time % 60)
			end
		end
	)(true, true)
end

function love.load()
	love.window.setMode(screenWidth, screenHeight)
	love.graphics.setFont(love.graphics.newFont(18))
	love.graphics.setColor(1, 1, 1)

	local bumper1YS = bumperPosFactory('w', 's', bumper1Y)
	local bumper2YS = bumperPosFactory('up', 'down', bumper2Y)
	bumper1YS:subscribe(function(pos) bumper1Y = pos end)
	bumper2YS:subscribe(function(pos) bumper2Y = pos end)

	startBallTask()
end

function love.draw()
	love.graphics.print(clockText, 280, 10)
	love.graphics.rectangle('fill', ballX, ballY, ballSize, ballSize)
	love.graphics.rectangle('fill', bumper1X, bumper1Y, bumperWidth, bumperHeight)
	love.graphics.rectangle('fill', bumper2X, bumper2Y, bumperWidth, bumperHeight)
end
