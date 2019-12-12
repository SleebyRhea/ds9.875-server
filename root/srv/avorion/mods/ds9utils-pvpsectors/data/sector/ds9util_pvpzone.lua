package.path = package.path .. ";data/scripts/lib/?.lua"
include ("stringutility")

-- namespace NeutralZone
DS9PvPZone = {}

if onServer() then
    function DS9PvPZone.initialize()
        Sector():registerCallback("onPlayerEntered", "onPlayerEntered")
        Sector().pvpDamage = 1
        Sector():setValue("pvp_zone", 1)

        Sector():removeScript("data/scripts/sector/factionwar/initfactionwar.lua")
    end

    function DS9PvPZone.onPlayerEntered(playerIndex)
        local player = Player(playerIndex)
        local msg = "You have entered a PvP zone. Player to player damage is *forced* in this sector."

        player:sendChatMessage("", 0, msg)
        player:sendChatMessage("", 3, msg)
    end 
end
