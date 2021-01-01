tasks = require'tasks'
love.keypressed = tasks.emit
tasks.task_t:new(function()
	while true do
		tasks.await('i')
		print('Início')
		tasks.par_or(
			function()
				tasks.await('a')
				print('a venceu')
			end,
			function()
				tasks.await('b')
				print('b venceu')
			end
		)()
	end
end)()
