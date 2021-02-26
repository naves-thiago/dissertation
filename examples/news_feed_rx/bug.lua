-- Report mouse Y movement while the mouse is down relative to the mouse down position
local mouse_drag = love.mousepressed:exhaustMap(function(start_x, start_y)
	return rx.Observable.concat(
			love.mousemoved
				:map(function(x, y) return y - start_y end) -- extract Y and offset by the start Y
				:takeUntil(love.mousereleased), -- stop tracking when the mouse is released
			load_ico_move_home
			)
				-- Trigger a news reload when we go past half window
				:tap(function(y) if y > window_height() / 2 then refresh:onNext(1) end end)
				:takeWhile(function(y) return y <= window_height() / 2 end) -- Stop when we get bellow half screen
				--:takeWhile(function(y) -- fix tap + takeWhile bug: tap still triggers after takeWhile completes
				--		local out = y <= window_height() / 2
				--		if not out then
				--			refresh:onNext(1)
				--		end
				--		return out
				--	end) -- Stop and refresh the news when we get bellow half screen
end)


