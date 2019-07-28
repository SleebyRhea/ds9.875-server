include("utility")
include("stringutility")
include("weapontype")

vanilla_onPlayerCreated = onPlayerCreated
vanilla_onStartUp = onStartUp

local turret = nil

--[[
--   Credit to Darenkal (Conico) of the DS9 Discord for
--   helping me get this working and working out how to get
--   good scaling for newbies!
--]]
function onStartUp()
    vanilla_onStartUp()

    --Sector x y and offset
    local tx, ty, to = -200, -200, 275
    
    -- Rarity, and Type
    local tr, tt = 2, WeaponType.RawMiningLaser

    turret = include("turretgenerator").generate(yx, ty, to, Rarity(tr), tt, Material(MaterialType.Naonite))
end

function onPlayerCreated (index)
    -- Call vanilla script
    vanilla_onPlayerCreated(index)

    local player = Player(index)

    -- Resources (example)
    local iron, titanium, naonite, trinium, xanion, ogonite, avorion = 50000, 50000, 50000, 50000, 0, 0, 0

    local mail = Mail()
    mail.money = 500000
    mail.sender = "DS9 Admin Team"
    mail.header = "Welcome!"
    mail.text = "Welcome to the DS9.875 Server! Here are some resources to get you going. If you have any questions, feel free to ask!"
    mail:addTurret(turret)
    mail:setResources(iron,titanium,naonite,trinium,xanion,ogonite,avorion)

    player:addMail(mail)
end
