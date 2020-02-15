modLocation = ""
forceEnabling = false

local prefix = "/srv/avorion/mods/"
mods = {
	-- Disabled as of 11-15-2019 as a potential lag generator
	--{workshopid = "1741735681"}, --Carrier Commander
	--{workshopid = "1741744976"}, --Carrier Commander Commands
	--{workshopid = "1692998037"}, --Laserzwei's simple asteroid respawn mod
	--{workshopid = "1721567838"}, --Xsotan Dreadnought
	--{workshopid = "1819394387"}, --Roid Rage

	-- ACTIVE
	{workshopid = "1691591293"}, --claim.lua claim() hook
	{workshopid = "1691539727"}, --Laserzwei's Move Asteroids
    {workshopid = "1747899176"}, --Laserzwei's Admin Toolbox
    --{workshopid = "1720259598"}, --Mod configuration library
	--{workshopid = "1751636748"}, --Detailed Turret Tooltips
	--{workshopid = "1793763687"}, --No Independent Targeting Penalty
	--{workshopid = "1788913474"}, --Trash Compactor

    -- DS9 Server Specific Mods
    {path = prefix .. "ds9utils-lib"},
    {path = prefix .. "ds9utils-welcomemail"},
    {path = prefix .. "ds9utils-commandpack"},
    {path = prefix .. "ds9utils-scriptmods"},
	{path = prefix .. "ds9utils-logininfo"},
    {path = prefix .. "ds9utils-allcolors"},
}

allowed = {
	{id = "1769379152"}, --Resource Display (Rinart73)
	{id = "1924206157"}, --Resource Display (Molotov)
	{id = "1917119779"}, --AzimuthLib for Resource Display (Molotov)
	{id = "1722261398"}, --Compass-Like Gate Icons
}
