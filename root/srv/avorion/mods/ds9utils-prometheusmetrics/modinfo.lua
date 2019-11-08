meta = {
    id = "ds9875PrometheusExporter",
    name = "ds9875PrometheusExporter",
    title = "DS9.875 Utils: Prometheus Exporter",
    description = "Output a prometheus compatible export file in moddata",
    authors = {"Arcturus615"},
    version = "0.1",
    dependencies = { {id = "Avorion", min = "0.27.*"} },

    -- Set to true if the mod only has to run on the server. Clients will get notified that the mod is running on the server, but they won't download it to themselves
    serverSideOnly = true,
    clientSideOnly = false,
    saveGameAltering = false,
    
	-- Contact info for other users to reach you in case they have questions
    contact = "arcturus615@gmail.com",
}
