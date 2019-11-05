do
	include ("stringutility")
	
	local __exportTime = 0
	local __metricsFile = "/Moddata/ds9utils-"
	local __doMetrics = true
	local __modName = "ds9utils-prometheusmetrics"

	local __vanillaUpdate = update
	local __vanillaOnShutdown = onShutDown
	local __vanillaOnStartup = onStartUp

	function exportMetrics (server)
		local __servname = server.name
		local __maxplr = server.players
		local __plrcnt = server.maxplayers
		local __time = os.time(os.date("!*t"))

		io.open(__metricsFile, "w+")
		
		-- Catch errors if the filesystem goes readonly.
		if type(f) == "nil" then
			__doMetrics = false
			printlog("[${mod}] Unable to open metrics file! File: <${file}>"%_T % {_mod=__modName, file=__metricsFile})
			return false
		end
		
		f:seek("set")
		f:write('#HELP avorion_playercount Playercount for ${servname}'%_T % {servname=__servname} )
		f:write('#TYPE avorion_playercount counter')
		f:write('avorion_playercount{ server="${servname}", count="online" } ${count} ${time}'%_T % {servname=__servname, count=__plrcnt, time=__time} )
		f:write('avorion_playercount{ server="${servname}", count="max" } ${count} ${time}'%_T % {servname=__servname, count=__maxplr, time=__time} )
		f:close
	end

	function onStartUp()
		__vanillaOnStartup(...)

		-- Prevent files that failed to open from breaking everything, and
		-- overwrite our file so its empty if it exists
		local f = io.open(__metricsFile,"w")
		if type(f) == "nil" then
			__doMetrics = false
			printlog("[${mod}] Unable to open metrics file! File: <${file}>"%_T % {_mod=__modName, file=__metricsFile})
		else
			f:close()
		end
	end

	function update(timeStep)
		__vanillaUpdate(...)

		-- Perform our operation every minute if our metrics
		-- file was successfully opened/created
		if __doMetrics then
			__exporttime = __exporttime + timeStep
			if timeStep >= 60 then
				__exporttime=0
				exportMetrics(Server())
			end
		else
			printlog("Skipping metrics run")
		end

	end
	
	function onShutDown()
		__vanillaOnShutdown(...)

		-- Remove our metrics file upon server stop
		
	end
end

