local ext = basewars.createExtension"playtime-tracker"
ext.saveInterval = 1 * 60

function ext:SetupPlayerDataTables(ply)
	ply:netVar("Int", "Playtime", true, 0, nil, 0)
	ply:netVar("Int", "PlaytimeLastSaved")
end

if CLIENT then return end

function ext:PostSetupPlayerDataTables(ply)
	ply.getPlaytimeAccurate = function(p)
		return p:getPlaytime() + (p:TimeConnected() - p:getPlaytimeLastSaved())
	end
end

function ext:PlayerReallySpawned(ply)
	ply:setPlaytimeLastSaved(ply:TimeConnected()) -- we ready
end

function ext:saveTime(ply)
	local ls = ply.getPlaytimeLastSaved and ply:getPlaytimeLastSaved()
	if not ls or ls <= 0 then return end

	local tc = ply:TimeConnected()
	local timeDelta = tc - ls
	ply:setPlaytimeLastSaved(ply:TimeConnected())

	ply:addPlaytime(timeDelta)
end

ext.PlayerDisconnected = ext.saveTime

function ext:saveAll()
	for _, v in ipairs(player.GetAll()) do
		self:saveTime(v)
	end
end

ext.ShutDown = ext.saveAll

timer.Create(ext:getTag(), ext.saveInterval, 0, function()
	ext:saveAll()
end)
