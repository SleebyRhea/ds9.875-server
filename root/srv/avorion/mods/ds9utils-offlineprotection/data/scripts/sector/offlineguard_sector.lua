if onServer() then
	-- namespace OfflineGuardSector
	OfflineGuardSector = {}

	-- UPDATE
	function OfflineGuardSector.updateServer()
		if onServer() then
			OfflineGuardSector.checkAllFactions()
		end
	end

	-- CHECK ALL FACTIONS
	function OfflineGuardSector.checkAllFactions()
		if onServer() then
			local sector = Sector()
			print("[OfflineGuardSector] Checking for offline players in <%s> at <%s>", sector.name, os.clock())

			-- Since only entities that we want to work with have the offlineguard_entity.lua script
			-- attached, we simply grab all of those entities. Then, using the player refs we tabled
			-- after, we check the value of Entity()->OfflineGuardEntity.getOwner(). If a match is
			-- found, we abort that loop and set the craft in question to be vulnerable. Otherwise,
			-- the craft is set to invincible.
			local i, pass = 0, false
			for _, entity in ipairs({sector:getEntitiesByScript("offlineguard_entity.lua")}) do
				for _, player in ipairs(Server():getOnlinePlayers()) do
					if player.name == entity:invokeFunction("offlineguard_entity.lua", "getOwner") then
						pass = true
						break
					end
				end

				-- Here, pass means that the player is online.
				if not pass then
					entity.invincible = true
					i = i + 1
				else
					entity.invincible = false
				end
			end

			if i > 0 then
				print("[OfflineGuardSector] Found <%s> offline playercrafts.", i)
			end
		end
	end

	-- Only update every 30 seconds or so
	function OfflineGuardSector.getUpdateInterval()
		return 30
	end

	return OfflineGuardSector
end