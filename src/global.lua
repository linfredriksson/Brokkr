local global = {
	actions = {
		up = "up",       -- move up
		down = "down",   -- move down
		left = "left",   -- move left
		right = "right", -- move right
		bomb = "space",  -- place bomb
		prev = "a",      -- choose previous character, while in lobby
		next = "s"       -- choose next character, while in lobby
	},
	window = {
		width = love.graphics.getWidth(),
		height = love.graphics.getHeight()
	},
	characterTile = {
		imageName = "image/characters1.png",
		sprite = nil,
		grid = nil,
		width = 32,
		height = 32,
		numberOfCharacters = 7
	},
	map = {
		tileImageName = "image/tiles.png",
		tileWidth = 32,
		tileHeight = 32,
		mapWidth = 24,
		mapHeight = 16
	},
	gameMap = {
		map = "random", -- type of map
		seed = os.time() -- seed used in math.random() when generating map
	},
	lobbyMap = {
		map = "lobby",
		seed = 0
	},
	ip = "127.0.0.1",
	port = 6789,
	maxPingServer = 3000,
	maxPingClient = 1000, -- ping time before it pings the server again
	-- used to keep track of old and new items. when a new match starts
	-- matchNumber is increased and only items with the same matchNumber
	-- will be shown.
	matchNumber = 1,
	font = love.graphics.newFont("font/Ash.ttf", 50)
}

return global
