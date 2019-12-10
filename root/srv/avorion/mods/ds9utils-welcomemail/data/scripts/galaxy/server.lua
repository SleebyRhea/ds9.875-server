include("utility")
include("stringutility")
include("weapontype")

vanilla_onPlayerCreated = onPlayerCreated
vanilla_initialize = initialize

local turret = nil

--[[
--   Credit to Darenkal (Conico) of the DS9 Discord for
--   helping me get this working and working out how to get
--   good scaling for newbies!
--]]
-- function initialize()
--     vanilla_initialize()

--     --Sector x y and offset
--     local tx, ty, to = -200, -200, 275

--     -- Rarity, and Type
--     local tr, tt = 2, WeaponType.RawMiningLaser

--     turret = include("turretgenerator").TurretGenerator.generateTurret(yx, ty, to, Rarity(tr), tt, Material(MaterialType.Naonite))
-- end

function onPlayerCreated (index)
    -- Call vanilla script
    vanilla_onPlayerCreated(index)

    local player = Player(index)

    -- Resources
    local iron, titanium, naonite, trinium, xanion, ogonite, avorion = 50000, 50000, 50000, 0, 0, 0, 0

    local mail = Mail()
    mail.money = 100000
    mail.sender = "DS9 Admin Team"
    mail.header = "Welcome to DS9.875!"
    mail.text = "Welcome to the DS9.875 Server! Here are some resources to get you going. If you have any questions, feel free to ask! Discord link: https://discord.gg/ZangShh"
    -- mail:addTurret(turret)
    mail:setResources(iron,titanium,naonite,trinium,xanion,ogonite,avorion)

    player:addMail(mail)
end
