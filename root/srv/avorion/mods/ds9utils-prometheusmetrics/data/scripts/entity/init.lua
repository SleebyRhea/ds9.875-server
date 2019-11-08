if onServer() then
    local entity = Entity()
	local etype = entity.type

	-- Ensure that we only player and alliance vessels
    if entity.playerOwned or entity.allianceOwned then
        if etype == EntityType.Ship
        or etype == EntityType.Station
        or etype == EntityType.Ship then
            entity:addScriptOnce("entity/gamemetrics-shiptracker.lua")
        end
    end   
end

