if onServer() then
	local player = Player()
	print("[ds9utils-allcolors] Adding all colors to " .. player.name)
	for _, color in pairs({ColorPalette()}) do
			player:addColor(color)
	end
end