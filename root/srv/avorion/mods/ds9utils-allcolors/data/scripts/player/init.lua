--[[

    DS9 Utilities - All Colors
    --------------------------
	Adds every color available to a player that logs in.
	As this uses a snippet from the official Avorion lua
	code is unlicensed and subject to be withdrawn at any
	point in time.

]]

do
	local __oldpath = package.path
    package.path = package.path .. ";data/scripts/lib/?.lua"

	-- Set modname for print function
	include("ds9utils-lib")('ds9utils-allcolors')

	if onServer() then
		local player = Player()
		print("Adding all colors to " .. player.name)
		for _, color in pairs({ColorPalette()}) do
				player:addColor(color)
		end
	end
	package.path = __oldpath
end