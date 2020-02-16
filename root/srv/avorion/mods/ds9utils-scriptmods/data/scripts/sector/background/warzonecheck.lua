if onServer() then
	package.path = package.path .. ";data/scripts/lib/?.lua"
	include("ds9utils-lib")("ds9utils-scriptmods")
	
	-- Run our cleanup on update. Updates are every 8 hours, so this should
	-- cause no issues
	function WarZoneCheck.updateServer(timeStep)
		WarZoneCheck.cleanup()
    end

    -- Remove on restoration.
    function WarZoneCheck.onRestoredFromDisk(timeSinceLastSimulation)
        WarZoneCheck.cleanup()
    end

    -- Cleanup function that removes the Warzone Check script from the sector
    -- entirely. This function *should* result in a clean removal.
	function WarZoneCheck.cleanup()
		print("Cleaning up warzone")
		local sector = Sector()
        WarZoneCheck.undeclareWarZone()
        sector:unregisterCallback("onDestroyed", "onDestroyed")
        sector:unregisterCallback("onBoardingSuccessful", "onBoardingSuccessful")
        sector:unregisterCallback("onRestoredFromDisk", "onRestoredFromDisk")
	end
	
	-- Just update every hour from here on out. We don't want to wholesale *remove*
	-- the script (in case we want to make adjustments later), but it is better to
	-- have it update *very* infrequently since it wont be doing anything. As it is,
	-- this sets it to every 8 hours.
	function WarZoneCheck.getUpdateInterval()
		return 60 * 60 * 8
	end
end