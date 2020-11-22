running = false
function love.keypressed(key)
	if running then
		if key == 'a' or key == 'b' then
			print(key .. ' venceu')
			running = false
		end
	else
		if key == 'i' then
			print('Início do jogo')
			running = true
		end
	end
end
