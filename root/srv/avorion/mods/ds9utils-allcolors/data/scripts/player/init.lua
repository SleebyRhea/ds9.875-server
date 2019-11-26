
if onServer() then

local player = Player()
	print("[AllOfTheColors] Adding all colors to " .. player.name)
    if player.infiniteResources then
        for _, color in pairs({ColorPalette()}) do
            player:addColor(color)
        end
    end
end
