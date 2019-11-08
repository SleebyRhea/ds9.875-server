modname = "ds9utils-prometheusmetrics"
if onServer() then
	function initialize()
		createDirectory(Server().folder .. "/moddata/" .. modname)
	end
end
