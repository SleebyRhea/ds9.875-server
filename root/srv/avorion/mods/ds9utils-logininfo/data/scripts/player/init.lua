if onServer() then
	do
		-- **Dont** pollute the environment boys and girls
		local player = Player()
		local sector = Sector()
		local old_path = package.path
		package.path = package.path .. ";data/scripts/lib/?.lua"

		local __d = {
			mod = 'ds9utils-logininfo',
			plr = player.name,
			coords = sector.name,
			name_craft = (player.craft and player.craft.name or "None (Flying In Drone)"),
			name_alliance = (player.alliance and player.alliance.name or "None"),
			count_ships = (player.numShips and player.numShips or 0),
			count_stations = (player.numShips and player.numShips or 0),
			sector_objects = sector.numEntities,
			sector_players = sector.numPlayers,
		}

		if player.craft and player.craft.type ~= EntityType.Drone then
			__d["count_blocks"] = player:getShipPlan(player.craft.name).numBlocks
		else
			__d["count_blocks"] = 1
		end

		-- While I would LOVE nothing more than to just the fancy table up above, the string
		-- utility does NOT make use of a raw Lua table when passed it. Thus, the following
		-- syntax MUST be used. I've tried to make this as painless to interpret as possible.
		include ("stringutility")
		print("")

		-- Player Data
		print("[${m}] Printing Statistics for <${p}>"%_T % {m=__d.mod, p=__d.plr} )
		print("[${m}] ${p} ::> Current Location: <${n}>"%_T % {m=__d.mod, p=__d.plr, n=__d.coords} )
		print("[${m}] ${p} ::> Current Ship Name: <${n}>"%_T % {m=__d.mod, p=__d.plr, n=__d.name_craft} )
		print("[${m}] ${p} ::> Current Ship Block Count: <${n2}>"%_T % {m=__d.mod, p=__d.plr, n=__d.name_craft, n2=__d.count_blocks} )
		print("[${m}] ${p} ::> Total Station Count: <${n}>"%_T % {m=__d.mod, p=__d.plr, n=__d.count_stations} )
		print("[${m}] ${p} ::> Total Ship Count: <${n}>"%_T % {m=__d.mod, p=__d.plr, n=__d.count_ships} )

		-- Sector Data
		print("[${m}] ${p} ::> Objects in System: <${n}>"%_T % {m=__d.mod, p=__d.plr, s=__d.coords, n=__d.sector_objects} )
		print("[${m}] ${p} ::> Players in System: <${n}>"%_T % {m=__d.mod, p=__d.plr, s=__d.coords, n=__d.sector_players} )

		print(" ")
		package.path = old_path
	end
end
