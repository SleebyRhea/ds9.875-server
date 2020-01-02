do
	local __oldpath = package.path
    package.path = package.path .. ";data/scripts/lib/?.lua"

	include("ds9utils-lib")

	if onServer() then
		local player = Player()
		print("[ds9utils-allcolors] Adding all colors to " .. player.name)
		for _, color in pairs({ColorPalette()}) do
				player:addColor(color)
		end
	end
	package.path = __oldpath
end