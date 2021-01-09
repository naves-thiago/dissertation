local tasks = require'tasks'

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

function startBumper1Task()
	tasks.task_t:new(function()
		while true do
			-- Sub-tarefas criadas como independentes para que ao iniciar o
			-- movimento em uma direção o par_or pare de esperar a tecla da
			-- direção oposta
			tasks.par_or(
				function()
					tasks.await('w_down')
					tasks.par_or(
						function()
							while true do
								local dt = tasks.await('update')
								bumper1Y = math.max(0, bumper1Y - bumperSpeed * dt)
							end
						end,
						function()
							tasks.await('w_up')
							tasks.emit('bumper1_done')
						end
					)(true, true)
				end,
				function()
					tasks.await('s_down')
					tasks.par_or(
						function()
							while true do
								local dt = tasks.await('update')
								bumper1Y = math.min(screenHeight - bumperHeight,
								                    bumper1Y + bumperSpeed * dt)
							end
						end,
						function()
							tasks.await('s_up')
							tasks.emit('bumper1_done')
						end
					)(true, true)
				end
			)()
			-- A atualização da posição executa como uma tarefa independente
			-- Espera ela terminar antes de permitir iniciar o movimento novamente
			tasks.await('bumper1_done')
		end
	end)(true, true)
end

function startBumper2Task()
	tasks.task_t:new(function()
		while true do
			-- Sub-tarefas criadas como independentes para que ao iniciar o
			-- movimento em uma direção o par_or pare de esperar a tecla da
			-- direção oposta
			tasks.par_or(
				function()
					tasks.await('up_down')
					tasks.par_or(
						function()
							while true do
								local dt = tasks.await('update')
								bumper2Y = math.max(0, bumper2Y - bumperSpeed * dt)
							end
						end,
						function()
							tasks.await('up_up')
							tasks.emit('bumper2_done')
						end
					)(true, true)
				end,
				function()
					tasks.await('down_down')
					tasks.par_or(
						function()
							while true do
								local dt = tasks.await('update')
								bumper2Y = math.min(screenHeight - bumperHeight,
								                    bumper2Y + bumperSpeed * dt)
							end
						end,
						function()
							tasks.await('down_up')
							tasks.emit('bumper2_done')
						end
					)(true, true)
				end
			)()
			-- A atualização da posição executa como uma tarefa independente
			-- Espera ela terminar antes de permitir iniciar o movimento novamente
			tasks.await('bumper2_done')
		end
	end)(true, true)
end

function startBallTask()
	tasks.task_t:new(function()
		while true do
			local dt = tasks.await('update')
			ballX = ballX + ballXSpeed * dt
			ballY = ballY + ballYSpeed * dt
			if didColideX() then
				ballXSpeed = -ballXSpeed
				setBallDirection()
			end
			if didColideY() then
				ballYSpeed = -ballYSpeed
			end
			if ballX > screenWidth - ballSize or
				ballX < 0 then
				print('score')
				ballX = ballXInitial
				ballY = ballYInitial
				ballYSpeed = 0
			end
		end
	end)(true, true)
end

function love.load()
	love.window.setMode(screenWidth, screenHeight)
	startBumper1Task()
	startBumper2Task()
	startBallTask()
end

function love.keypressed(key, scancode, isrepeat)
	tasks.emit(key .. '_down')
end

function love.keyreleased(key)
	tasks.emit(key .. '_up')
end

function love.update(dt)
	tasks.emit('update', dt)
end

function love.draw()
	love.graphics.rectangle('fill', ballX, ballY, ballSize, ballSize)
	love.graphics.rectangle('fill', bumper1X, bumper1Y, bumperWidth, bumperHeight)
	love.graphics.rectangle('fill', bumper2X, bumper2Y, bumperWidth, bumperHeight)
end
