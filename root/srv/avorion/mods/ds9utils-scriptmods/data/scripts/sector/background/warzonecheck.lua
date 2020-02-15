self.data.noDecayTime = 60 * 5 --Set the decay timer to 5 minutes

if onServer() then

    -- Remove on update after decay timer.
    function WarZoneCheck.updateServer(timeStep)
        -- while the timer is running, no decay happens
        self.data.noDecayTimer = math.max(0, self.data.noDecayTimer - timeStep)

        if self.data.noDecayTimer == 0 then
            WarZoneCheck.cleanup()
        end
    end

    -- Remove on restoration.
    function WarZoneCheck.onRestoredFromDisk(timeSinceLastSimulation)
        WarZoneCheck.cleanup()
    end

    -- Cleanup function that removes the Warzone Check script from the sector
    -- entirely. This function *should* result in a clean removal.
    function WarZoneCheck.cleanup()
        WarZoneCheck.undeclareWarZone()
        local sector = Sector()
        sector:unregisterCallback("onDestroyed", "onDestroyed")
        sector:unregisterCallback("onBoardingSuccessful", "onBoardingSuccessful")
        sector:unregisterCallback("onRestoredFromDisk", "onRestoredFromDisk")
        sector:removeScript("warzonecheck.lua")
    end
end