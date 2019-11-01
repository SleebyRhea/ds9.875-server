if onServer() then
	local entity = Entity()

	-- We only want to operate on player ships
	-- just to be safe, we make sure to exclude AI
	-- and alliance ships
	if entity.playerOwned
	and not entity.allianceOwned
	and not entity.aiOwned then
		if entity.type == EntityType.Ship
		or entity.type == EntityType.Station
		or entity.type == EntityType.Ship then
			entity:addScriptOnce("entity/offlineguard_entityplaceholder.lua")
		end
	end
end