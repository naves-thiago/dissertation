tasks = require"tasks"
rx = require"rx"
require"exhaustMap"
require"catchError"
require"share"
require"resub"
require"endWith"
animations = require'animations'

--[[
a = rx.Subject.create()
b = rx.Subject.create()
c = rx.Subject.create()

loadNews_ = rx.Observable.create(function(observer)
	print("Load news")
	function n(...)
		observer:onNext(...)
		observer:onCompleted()
	end
	return rx.Subscription.create(function() end)
	-- Load news and send to the observer
end)

refresh_ = rx.BehaviorSubject.create(1)
news = refresh_:exhaustMap(function() return loadNews_ end)
news:subscribe(print)
--]]

o = rx.Observable.create(function(observer)
	print("Subscribe")
	function n(...) observer:onNext(...) end
	function e(...) observer:onError(...) end
	function c() observer:onCompleted() end
	return rx.Subscription.create(function() print("Unsubscribe") end)
end)

--s = o:share()
--a = s:subscribe(function(...) print("a", ...) end, function(e) print("a - err:", e) end, function() print("a - cmp") end)
--b = s:subscribe(function(...) print("b", ...) end, function(e) print("b - err:", e) end, function() print("b - cmp") end)

function timer(initial, interval)
	return rx.Observable.create(function(observer)
		local count = initial
		local function onNext()
			observer:onNext(count)
			count = count + 1
		end
		local timer = tasks.every_ms(interval, onNext)
		return rx.Subscription.create(function()
			timer:stop()
		end)
	end)
end

--t = timer(10, 1000)
--s = t:subscribe(print)

