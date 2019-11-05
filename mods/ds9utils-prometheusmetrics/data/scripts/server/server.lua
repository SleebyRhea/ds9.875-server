do
	local __exportTime = 0
	local __doMetrics = true
	local __modName = "ds9utils-prometheusmetrics"
	local __metricsFile = "/moddata/" .. __modName .. "/export"

	local __vanillaUpdate = update
	local __vanillaOnShutdown = onShutDown
	local __vanillaOnStartup = onStartUp

	function exportMetrics()

	end

	function onStartUp()
		__vanillaOnStartup()

		local __serv = Server()

		-- Prevent files that failed to open from breaking everything, and
		-- overwrite our file so its empty if it exists
		local f = io.open(__serv.folder .. __metricsFile,"w")
		if type(f) == "nil" then
			__doMetrics = false
			print("[${mod}] Unable to open metrics file! File: <${file}>"%_T % {mod=__modName, file=__serv.folder .. __metricsFile})
		else
			print("[${mod}] Exporting metrics to: <${file}>"%T % {mod=__modName, file=__serv.folder .. __metricsFile})
			f:close()
		end
		

	end

	function update(timeStep)
		__vanillaUpdate(timeStep)

		-- Perform our operation every minute if our metrics
		-- file was successfully opened/created
		if __doMetrics then
			__exportTime = __exportTime + timeStep
			if __exportTime >= 60 then
				__exportTime=0
				
				local __serv = Server()
				local __servname = __serv.name
				local __plrcnt = __serv.players
				local __maxplr = __serv.maxPlayers
				local __time = os.time(os.date("!*t"))

				local f = io.open(__serv.folder .. __metricsFile, "w+")
				if type(f) == "nil" then
					__doMetrics = false
					print("[${mod}] Unable to write to our metrics file! File: <${file}>"%_T % {mod=__modName, file=__serv.folder .. __metricsFile})
					return false
				end
				
				print("[${mod}] Writing out metrics..."%_T % {mod=__modName} )
				f:seek("set")
				f:write('#HELP avorion_playercount Playercount for ${servname}\n'%_T % {servname=__servname} )
				f:write('#TYPE avorion_playercount counter\n')
				f:write('avorion_playercount { server="${servname}", count="online" } ${count} ${time}\n'%_T % {servname=__servname, count=__plrcnt, time=__time} )
				f:write('avorion_playercount { server="${servname}", count="max" } ${count} ${time}\n'%_T % {servname=__servname, count=__maxplr, time=__time} )
				f:close()
				print("[${mod}] Finished writing metrics."%_T % {mod=__modName} )
					end
		end

	end
	
	function onShutDown()
		__vanillaOnShutdown()

		-- Remove our metrics file upon server stop
		os.remove(__metricsFile)
	end
end

