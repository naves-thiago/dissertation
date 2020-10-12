suit = require('suit')

local show_login = true

function love.load()
	love.window.setMode(410, 600)

end

local login_left = 55
local login_top = 100
local login_user = {text = ''}
local login_pass = {text = ''}
function love.update(dt)
	if show_login then
		suit.Label('Login:', {align = 'left'}, login_left, login_top, 300, 10)
		suit.Input(login_user, login_left, login_top + 20, 300, 30)

		suit.Label('Senha:', {align = 'left'}, login_left, login_top + 60, 300, 10)
		suit.Input(login_pass, login_left, login_top + 80, 300, 30)

		if suit.Button('Login', login_left, login_top + 160, 300, 30).hit then
			print(login_user.text, login_pass.text)
		end
	end
end

function love.draw()
	suit.draw()
end

function love.textedited(text, start, length)
    suit.textedited(text, start, length)
end

function love.textinput(t)
	suit.textinput(t)
end

function love.keypressed(key)
	suit.keypressed(key)
end
