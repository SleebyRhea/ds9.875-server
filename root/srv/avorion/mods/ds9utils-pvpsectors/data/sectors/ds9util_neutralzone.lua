package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include ("SectorGenerator")
local Placer = include("placer")
include("music")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 500
end

function SectorTemplate.offgrid(x, y)
    return false
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return true
end

-- this function returns what relevant contents there will be in the sector (exact)
function SectorTemplate.contents(x, y)
    local __galaxy = Galaxy()
    local seed = Seed(string.join({GameSeed(), x, y, "neutralzone"}, "-"))
    math.randomseed(seed);

    local random = random()
    local contents = {ships = 0, stations = 0, seed = tostring(seed)}

    contents.resourceDepots = 0
    contents.tradingPosts = 0
    contents.repairDocks = 1
    contents.neighborTradingPosts = 0

    -- create trading posts from other factions
    local faction
    local otherFactions = {}

    if onServer() then
        faction = __galaxy:getLocalFaction(x, y) or __galaxy:getNearestFaction(x, y)
        contents.faction = faction.index

        otherFactions[faction.index] = true
    end

    if onServer() then
        otherFactions[faction.index] = nil
    end

    contents.ships = 0
    contents.stations = 1

    return contents, random, faction, otherFactions
end

-- Just return the allmusic table three times, since we want music to
-- be the same regardless.
function SectorTemplate.musicTracks()
    local allmusic = {
        primary = TrackCollection.Middle(),
        secondary = TrackCollection.Neutral(),
    }

    return allmusic, allmusic, allmusic
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    local contents, random, faction, otherFactions = SectorTemplate.contents(x, y)
    local pos

    local generator = SectorGenerator(x, y)

    generator:createRepairDock(faction);


    for i = 1, random:getInt(0, 1) do generator:createEmptyAsteroidField() end
    for i = 1, random:getInt(0, 1) do generator:createAsteroidField()      end
    for i = 1, random:getInt(0, 5) do generator:createSmallAsteroidField() end

    if SectorTemplate.gates(x, y) then generator:createGates() end

    Sector():addScriptOnce("data/scripts/sector/eventscheduler.lua")
    generator:addAmbientEvents()

    -- this one is added last since it will adjust the events that have been added
    Sector():addScript("data/scripts/sector/ds9util_pvpzone.lua")

    Placer.resolveIntersections()
end

return SectorTemplate