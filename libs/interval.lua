local rx = require"rx"
local Observable = rx.Observable
local Observer = rx.Observer
local Subscription = rx.Subscription

function Observable.Interval(interval, scheduler)
	local count = 0
	local observers = {}

	local function onNext()
		for _, o in pairs(observers) do
			o:onNext(count)
		end
		count = count + 1
		scheduler:schedule(onNext, interval)
	end
	scheduler:schedule(onNext, interval)

	return Observable.create(function(observer)
		table.insert(observers, observer)

		return Subscription.create(function()
			for i, j in ipairs(observers) do
				if j == observer then
					table.remove(observers, i)
					break
				end
			end
		end)
	end)
end

