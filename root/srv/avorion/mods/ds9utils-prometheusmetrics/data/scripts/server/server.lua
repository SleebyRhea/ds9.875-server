do
	local __exportTime = 0
	local __doMetrics = true
	local __modName = "ds9utils-prometheusmetrics"
	local __metricsFile = "/moddata/" .. __modName .. "/export"

	local __vanillaUpdate = update
	local __vanillaOnShutdown = onShutDown
	local __vanillaOnStartup = onStartUp

	function onStartUp()
		__vanillaOnStartup()
		
		local __serv = Server()
		__metricsFile = __serv.folder .. __metricsFile

		-- Prevent files that failed to open from breaking everything, and
		-- overwrite our file so its empty if it exists
		local f = io.open(__metricsFile,"w")
		if type(f) == "nil" then
			__doMetrics = false
			print("[${mod}] Unable to initialize metrics file! File: <${file}>"%_T % {mod=__modName, file=__metricsFile})
			print("[${mod}] Disabling metrics collection."%_T % {mod=__modName})
		else
			print("[${mod}] Exporting metrics to: <${file}>"%T % {mod=__modName, file=__metricsFile})
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
				local __f = io.open(__metricsFile, "w+")
				
				if type(__f) == "nil" then
					print("[${mod}] Unable to update metrics export file! File: <${file}>"%_T % {mod=__modName, file=__metricsFile})
				else
					print("[${mod}] Writing out metrics..."%_T % {mod=__modName} )
					__f:seek("set")
					__f:write('#HELP avorion_playercount Playercount for ${servname}\n'%_T % {servname=__servname} )
					__f:write('#TYPE avorion_playercount counter\n')
					__f:write('avorion_playercount { server="${servname}", count="online" } ${count} ${time}\n'%_T % {servname=__servname, count=__plrcnt, time=__time} )
					__f:write('avorion_playercount { server="${servname}", count="max" } ${count} ${time}\n'%_T % {servname=__servname, count=__maxplr, time=__time} )
					__f:close()
					print("[${mod}] Finished writing metrics."%_T % {mod=__modName} )
				end
			end
		end

	end
	
	function onShutDown()
		__vanillaOnShutdown()

		-- Remove our metrics file upon server stop
		os.remove(__metricsFile)
	end
end

