if onServer() then
	do
		-- Return table size
		local function __getLength(t)
			local __cnt = 0
			for _ in pairs(t) do cnt = cnt + 1 end
			return __cnt
		end

		-- Get ownership counts for the entities in the given table
		local function __getOwnerCount(t)
			local __ip, __ia, __io = 0, 0, 0
			for _, v in ipairs(t) do
				if v.playerOwned then
					__ip = __ip + 1
				elseif v.allianceOwned then
					__ia = __ia + 1
				else
					__io = __io + 1
				end
			end
			return __ip, __ia, __io
		end

		-- **Dont** pollute the environment boys and girls
		local player = Player()
		local sector = Sector()
		local old_path = package.path
		local alliance = (player.allianceIndex and Alliance(player.allianceIndex) or nil)
		package.path = package.path .. ";data/scripts/lib/?.lua"

		local __d = {
			mod = 'ds9utils-logininfo',
			plr = player.name,
			name_craft = (player.craft and player.craft.name or "None (Flying In Drone)"),
			name_alliance = (player.alliance and player.alliance.name or "None"),
			count_blocks = 1,
			count_ships_player = (player.numShips and player.numShips or 0),
			count_ships_alliance = (alliance and alliance.numShips or 0),
			count_stations_player = (player.numStations and player.numStations or 0),
			count_stations_alliance = (alliance and alliance.numStations or 0),
			sector_objects = sector.numEntities,
			sector_players = sector.numPlayers,
			sector_drones = __getLength({sector:getEntitiesByType(EntityType.Drone)}),
			sector_player_ships = 0,
			sector_alliance_ships = 0,
			sector_player_stations = 0,
			sector_alliance_stations = 0,
		}

		__d["coordsx"], __d["coordsy"] = sector:getCoordinates()

		if player.craft and player.craft.type ~= EntityType.Drone and player.craft.name then
			local __plan

			if player.craft.playerOwned then
				__plan = player:getShipPlan(player.craft.name)
			elseif player.craft.allianceOwned then
				__plan = alliance:getShipPlan(player.craft.name)
			end

			__d["count_blocks"] = (__plan and __plan.numBlocks or "Error")
		end

		__d["sector_player_stations"], __d["sector_alliance_stations"] = __getOwnerCount({sector:getEntitiesByType(EntityType.Station)})
		__d["sector_player_ships"], __d["sector_alliance_ships"] = __getOwnerCount({sector:getEntitiesByType(EntityType.Ship)})

		-- While I would LOVE nothing more than to just the fancy table up above, the string
		-- utility does NOT make use of a raw Lua table when passed it. Thus, the following
		-- syntax MUST be used. I've tried to make this as painless to interpret as possible.
		include ("stringutility")

		-- Player Data
		print("[${m}] ${p} ::> Current Ship Name=<${n1}>, Blocks=<${b}>, Loc=<${x}:${y}>"%_T % {m=__d.mod,p=__d.plr,n1=__d.name_craft,b=__d.count_blocks,x=__d.coordsx,y=__d.coordsy} )
		print("[${m}] ${p} ::> Total Station Counts: player=<${n1}>, alliance=<${n2}>"%_T % {m=__d.mod,p=__d.plr,n1=__d.count_stations_player,n2=__d.count_stations_alliance} )
		print("[${m}] ${p} ::> Total Ship Counts: player=<${n1}>, alliance=<${n2}>"%_T % {m=__d.mod,p=__d.plr,n1=__d.count_ships_player,n2=__d.count_ships_alliance} )
		print("[${m}] ${p} ::> System: objects=<${n1}>, onlineplayers=<${n2}>"%_T % {m=__d.mod, p=__d.plr, s=__d.coords, n1=__d.sector_objects, n2=__d.sector_players} )
		print("[${m}] ${p} ::> System: drones=<${n1}>, playerships=<${n2}>, allianceships=<${n3}>"%_T % {m=__d.mod, p=__d.plr, n1=__d.sector_drones, n2=__d.sector_player_ships, n3=__d.sector_alliance_ships} )
		print("[${m}] ${p} ::> System: playerstations=<${n1}>, alliancestations=<${n2}>"%_T % {m=__d.mod, p=__d.plr, n1=__d.sector_player_stations, n2=__d.sector_alliance_stations} )

		package.path = old_path
	end
end
