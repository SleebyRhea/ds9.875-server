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
    turret.dps=10
end

function onPlayerCreated (index)
    -- Call vanilla script
    vanilla_onPlayerLogIn(index)

    local player = Player(index)

    -- Resources (example)
    local iron, titanium, naonite, trinium, xanion, ogonite, avorion = 100, 100, 140, 2876, 1765, 285, 12 

    local mail = Mail()
    mail.money = 10000
    mail.sender = "DeepSpace 9.875"
    mail.header = "Greetings Tester!!"
    mail.text = "Welcome to the DS9 Testing Server!"
    mail:addTurret(turret)
    mail:setResources(iron,titanium,naonite,trinium,xanion,ogonite,avorion)

    player:addMail(mail)
end
