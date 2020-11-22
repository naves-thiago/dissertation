rx = require'rx'
require'exhaustMap'

love.keypressed = rx.Subject.create()
input_a = love.keypressed:filter(function(key) return key == 'a' end)
input_b = love.keypressed:filter(function(key) return key == 'b' end)
reset   = love.keypressed:filter(function(key) return key == 'i' end)
output  = reset:exhaustMap(function()
	print('Início do jogo')
	return input_a:amb(input_b):take(1):map(function(key) return key .. ' venceu' end)
end)
output:subscribe(print)




--[[
tmp = rx.Subject.create()
output = input_a:amb(input_b):map(function(x) return x end)
--output = input_a:amb(tmp):map(function(x) return x end)
output:subscribe(print)
input_b:subscribe(print)
--love.keypressed('b')
--]]
