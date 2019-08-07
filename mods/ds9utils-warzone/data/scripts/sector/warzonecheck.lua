WarZoneCheck.data.warZoneThreshold = 100        --Threshold before zone is hazardous
WarZoneCheck.data.pacefulThreshold = 70         --Threshold before the score reaches peaceful levels

if onServer() then
	function WarZoneCheck.updateServer(timeStep)
		local sector = Sector()
		if sector:getValue("war_zone") and not sector:getValue("admin_war_zone") then
			sector:setValue("war_zone", true)
		end
	end
	
	function WarZoneCheck.declareWarZone()
	end
	
	function WarZoneCheck.increaseScore()
	end
end
