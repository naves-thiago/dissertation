--------------------------------------------------------------------
-- Example:
-- News feed: Reads a list of posts from an HTTP server (mockup) and
-- displays them on the screen.
-- Posts are refreshed every 30s.
-- Draging down with the mouse past half of the screen reloads the
-- posts. A spinnig square indicates the news are being loaded.
--
-- RxLua API example
--
-- This example was adapted from the one presented by Ben Lesh (@benlesh)
-- in the "Complex features made easy with RxJS" talk presented at
-- JSFoo 2018.
--
-- Author: Thiago Duarte Naves
--------------------------------------------------------------------
local suit = require('suit')
local tasks = require'tasks'
local cards = require'cards'
local loading_icon_t = require('loadingIcon').loading_icon_t
local animations = require'animations'
local rx = require'rx'
require'exhaustMap'
require'catchError'
require'share'
require'resub'
require'endWith'

love.mousemoved = rx.Subject.create()
love.mousepressed = rx.Subject.create()
love.mousereleased = rx.Subject.create()

local show_login = true
local news_cards
local load_ico

function love.load()
	love.window.setMode(410, 600)
	love.window.setTitle("News")
end

function start_news_feed()
	local news = rx.Subject.create()
	tasks.task_t:new(function()
		while true do
			local ok, response = http_get_future('/newsfeed'):get()
			if ok then
				news:onNext(response)
			else
				print('[ERROR] error loading news feed')
				print('[ERROR] ' .. response)
			end
			tasks.await('refresh')
		end
	end)(true, true)

	-- Reload news periodically
	timer(0, 30000):subscribe(function() tasks.emit('refresh') end)

	-- Card list to display the news
	news_cards = cards.card_list_t:new(5, 5, 400, window_height() - 5)
	news:subscribe(function(n)
		news_cards:clear()
		for _, str in ipairs(n) do
			local c = cards.card_t:new(str)
			news_cards:add_card(c)
		end
	end)

	-- Loading icon object
	load_ico = loading_icon_t:new(195, 0, 20)

	-- Loading icon spring back animation
	local load_ico_move_home = rx.Observable.defer(function()
			return animations.tween(load_ico.y, 0, 200)
		end)

	-- Report mouse Y movement while the mouse is down relative to the mouse down position
	local mouse_drag = love.mousepressed:exhaustMap(function(start_x, start_y)
		return rx.Observable.concat(
				love.mousemoved
					:map(function(x, y) return y - start_y end) -- extract Y and offset by the start Y
					:takeUntil(love.mousereleased), -- stop tracking when the mouse is released
				load_ico_move_home
				)
					-- Trigger a news reload when we go past half window
					:tap(function(y) if y > window_height() / 2 then tasks.emit('refresh') end end)
					:takeWhile(function(y) return y <= window_height() / 2 end) -- Stop when we get bellow half screen
	end):share()

	-- Animate the icon back home after loading the news
	local load_ico_position_update = mouse_drag:exhaustMap(function()
		return rx.Observable.concat(
			mouse_drag:takeUntil(news),
			load_ico_move_home)
	end)

	-- Emits the positions for the loading icon
	local load_ico_position = load_ico_position_update
		:startWith(-load_ico.size / 2) -- Start outside the screen (account for diagonal size due to rotation)
		:map(function(y) return y - load_ico.size end) -- Offset by the square size

	-- Loading icon rotation observable
	local load_ico_start_rotating = rx.Subject.create()
	local load_ico_rotate = load_ico_start_rotating:exhaustMap(function()
		return animations.tween(0, 360, 500)
				:resub()
				:takeUntil(news)
				:endWith(0)
	end)
	tasks.listen('refresh', load_ico_start_rotating)

	load_ico_position:subscribe(function(p) load_ico.y = p end)
	load_ico_rotate:subscribe(function(r) load_ico.rotation = r end)
end

local login_left = 55
local login_top = 100
local login_user = {text = ''}
local login_pass = {text = ''}
local login_status_text = ''
local login_button_text = 'Login'
function love.update(dt)
	tasks.update_time(dt * 1000)
	if show_login then
		suit.Label('Login:', {align = 'left'}, login_left, login_top, 300, 10)
		suit.Input(login_user, login_left, login_top + 20, 300, 30)

		suit.Label('Senha:', {align = 'left'}, login_left, login_top + 60, 300, 10)
		suit.Input(login_pass, login_left, login_top + 80, 300, 30)

		if suit.Button(login_button_text, {id = 1}, login_left, login_top + 150, 300, 30).hit then
			check_login(login_user.text, login_pass.text)
		end

		suit.Label(login_status_text, {align = 'left'}, login_left, login_top + 220, 300, 10)
	end
end

function check_login(user, pass)
	login_button_text = 'Aguarde...'
	local response = http_get_future('/login', '["' .. user .. '","' .. pass .. '"]')
	tasks.par_or(
		function()
			local request_ok, response = response:get()
			if response == 'OK' then
				show_login = false
				start_news_feed()
			else
				login_status_text = 'Login inválido'
			end
			login_button_text = 'Login'
		end,
		function()
			tasks.await_ms(3000)
			response:cancel()
			login_status_text = 'Timeout'
			login_button_text = 'Login'
		end
	)(true, true)
end

function love.draw()
	if show_login then
		suit.draw()
	else
		news_cards:draw()
		load_ico:draw()
	end
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

function window_height()
	local _, h = love.window.getMode()
	return h
end

-------------------------------------------------
-- HTTP request mock
local mock_content = {
	'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nunc nisl, '..
		'volutpat id aliquet eu, semper in nisi.',
	'Maecenas nec ornare libero. Class aptent taciti sociosqu ad litora '..
		'torquent per conubia nostra, per inceptos himenaeos. '..
		'Praesent mattis ex eget dolor sagittis ornare.',
	'Morbi imperdiet pharetra arcu.',
	'Curabitur rhoncus, lectus ac elementum lacinia, ligula elit mollis velit, '..
		'egestas porttitor nisi dui in eros.',
	'Nam turpis tellus, malesuada at augue ac, mollis dictum lorem. Morbi mi mi, '..
		'laoreet ut erat sed, faucibus egestas lorem. '..
		'Nam sodales lacus nec viverra sagittis.',
	'Mauris in sodales lorem, non blandit nulla. Vestibulum ante ipsum primis '..
		'in faucibus orci luctus et ultrices posuere cubilia curae; '..
		'Aenean mollis metus eget venenatis venenatis. '..
		'Mauris elementum cursus rhoncus. Duis at nisl eu dolor congue aliquam.',
	'Aliquam eu magna vel odio malesuada lacinia et sit amet justo. '..
		'Curabitur in posuere quam.',
	'Pellentesque ultricies bibendum sapien ac lobortis. Mauris eget ex augue.',
	'Phasellus dignissim vitae urna id hendrerit. '..
		'Maecenas malesuada vulputate arcu a accumsan. '..
		'Quisque dictum blandit risus, ac consequat lectus scelerisque vitae.',
	'Duis ac gravida velit. Nulla lectus ipsum, ullamcorper a nulla sed, '..
		'volutpat blandit ipsum. Donec cursus tellus ut vestibulum posuere.',
	'Vestibulum nec odio sed magna venenatis porttitor ac ut metus. '..
		'Vivamus eu tortor eget est venenatis '..
		'lacinia. Mauris aliquet nunc ut velit sollicitudin luctus. '..
		'Curabitur iaculis commodo enim, nec volutpat libero sollicitudin id. '..
		'Phasellus nec cursus tortor. Donec ultrices, justo at pharetra laoreet, '..
		'lacus dui blandit risus, quis vehicula augue justo nec lacus.',
	'Phasellus varius pulvinar tristique. Fusce mi arcu, venenatis eu nulla at, '..
		'fringilla porta turpis. Praesent commodo condimentum risus, '..
		'id lobortis ex. Ut eget nisl ligula.',
}

local mock_content_steps = {3, 5, 3} -- how many posts to add on each reply
local mock_current_step = 1 -- next content step to use
local mock_sent = 0 -- sent posts
local http_task = tasks.task_t:new(function()
	while true do
		tasks.await('get news')
		tasks.await_ms(2000)
		local count = mock_sent + mock_content_steps[mock_current_step]
		count = math.min(count, #mock_content)
		tasks.emit('news', true, {unpack(mock_content, 1, count)})
		if mock_current_step < #mock_content_steps then
			mock_sent = mock_sent + mock_content_steps[mock_current_step]
			mock_current_step = mock_current_step + 1
		end
		tasks.emit('news done')
	end
end)
http_task()

function http_get(path)
	return rx.Observable.create(function(observer)
		local function onNext(_, n)
			observer:onNext(n)
		end

		local function onCompleted()
			observer:onCompleted()
		end

		tasks.listen('news', function(ok, ...) onNext(...) end)
		tasks.listen('news done', onCompleted)
		tasks.emit('get news')
		return rx.Subscription.create(function()
			tasks.stop_listening('news', onNext)
			tasks.stop_listening('news done', onCompleted)
		end)
	end)
end

function http_get_mock_login(params)
	local t
	local f = tasks.future_t:new('http',
		function() t:kill() end)

	t = tasks.task_t:new(function()
--		tasks.await_ms(2000)
		-- Login validation mockup
		if params == '["a","a"]' then
			tasks.emit('http', true, 'OK')
		else
			tasks.emit('http', true, 'ERROR')
		end
	end)
	t(true, true)
	return f
end

function http_get_mock_news()
	local f = tasks.future_t:new('news')
	tasks.emit('get news')
	return f
end

function http_get_future(path, params)
	if path == '/login' then
		return http_get_mock_login(params)
	else
		return http_get_mock_news()
	end
end

-----------------------------------------------
-- Timer interface
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
