if onClient() then return nil end

if onServer() then
	--namespace OfflineGuardEntity
	OfflineGuardEntity = {}

	local owner = ""

	function OfflineGuardEntity.initialize()
		owner = Player().name
	end

	function OfflineGuardEntity.getOwner()
		return owner
	end

	return OfflineGuardEntity
end