if onServer() then
	local entity = Entity()
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