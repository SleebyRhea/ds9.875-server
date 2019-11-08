if not OnServer() then return end

-- namespace GameMetrics
GameMetrics = {}

local __servname = Server().name
local __datastore = {}
local __metricscache = ""

function GameMetrics.initialize ()
	local __serv = Server()
	__datastore.players = {}

	for i in 1, __serv.getPlayers(), 1 do
		GameMetrics.initPlayer(i)
	end
end

function GameMetrics.update (etime)
	local __server = Server()
end

function GameMetrics.initPlayer (plrid)
	local __plr = Player(plrid)
	__datastore.players[__plr.name] = {}
end

function GameMetrics.destroyPlayer (plrid)
	__datastore.players[Player(plrid).name] = nil
end

function GameMetrics.emit()
end

return GameMetrics
