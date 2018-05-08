if CLIENT then
	timer.Simple(0, function()
		local world_panel = vgui.GetWorldPanel()
		assert(IsValid(world_panel), "world_panel is invalid")

		function world_panel:OnCursorMoved(x, y)
			hook.Run("GUIOnCursorMoved", x, y)
		end
	end)
end

function GM:OnEntityCreated(ent, ...)
	local a = {...}
	timer.Simple(0, function()
		if IsValid(ent) then
			hook.Run("PostEntityCreated", ent, unpack(a))
		end
	end)

	return self.BaseClass.OnEntityCreated(self, ent, ...)
end

function GM:PlayerInitialSpawn(ply, ...)
	local a = {...}
	timer.Simple(0, function()
		if IsValid(ply) then hook.Run("PostPlayerInitialSpawn", ply, unpack(a)) end
	end)

	hook.Run("SharedPlayerInitialSpawn", ply, ...)

	return self.BaseClass.PlayerInitialSpawn(self, ply, ...)
end

if SERVER then
	util.AddNetworkString("sharedTakeDamage")

	function GM:EntityTakeDamage(targ, info, ...)
		if targ.PreTakeDamage and targ:PreTakeDamage(info) then
			return true
		end

		local res = self.BaseClass.EntityTakeDamage(self, targ, info, ...)
		if res then return true end

		hook.Run("EntityTakeDamageFinal", targ, info, ...)

		net.Start("sharedTakeDamage")
			net.WriteEntity(targ)
			net.WriteCTakeDamageInfo(info)
		net.Broadcast()

		hook.Run("SharedEntityTakeDamage", targ, info, ...)
	end
else
	net.Receive("sharedTakeDamage", function()
		local targ = net.ReadEntity()
		if not IsValid(targ) then return end

		local info = net.ReadCTakeDamageInfo()

		hook.Run("SharedEntityTakeDamage", targ, info)
		if targ.SharedOnTakeDamage then targ:SharedOnTakeDamage(info) end
	end)
end

function GM:OnReloaded(...)
	local a = {...}
	timer.Create("post_gamemodereload", 1, 1, function()
		hook.Run("PostReloaded", unpack(a))
	end)

	return self.BaseClass.OnReloaded(self, ...)
end

function GM:PlayerSpawnObject(ply, ...)
	if hook.Run("ShouldPlayerSpawnObject", ply, ply:GetEyeTrace(), "object", ...) == false then return false end

	return self.BaseClass.PlayerSpawnObject(self, ply, ...)
end

function GM:PlayerSpawnSENT(ply, ...)
	if hook.Run("ShouldPlayerSpawnObject", ply, ply:GetEyeTrace(), "sent", ...) == false then return false end

	return self.BaseClass.PlayerSpawnSENT(self, ply, ...)
end

function GM:PlayerSpawnSWEP(ply, ...)
	if hook.Run("ShouldPlayerSpawnObject", ply, ply:GetEyeTrace(), "swep", ...) == false then return false end

	return self.BaseClass.PlayerSpawnSENT(self, ply, ...)
end

function GM:PlayerSpawnVehicle(ply, ...)
	if hook.Run("ShouldPlayerSpawnObject", ply, ply:GetEyeTrace(), "vehicle", ...) == false then return false end

	return self.BaseClass.PlayerSpawnVehicle(self, ply, ...)
end

function GM:CanTool(ply, tr, ...)
	if hook.Run("ShouldPlayerSpawnObject", ply, tr, "tool", tr, ...) == false then return false end

	return self.BaseClass.CanTool(self, ply,  tr, ...)
end

function GM:PlayerSpawn(ply, ...)
	local res = hook.Run("GetPlayerSpawnPosOverride", ply) -- DOCUMENT:
	if res and isvector(res) then
		ply:SetPos(res)
	end

	local a = {...}
	timer.Simple(0, function()
		if IsValid(ply) then hook.Run("PostPlayerSpawn", ply, unpack(a)) end
	end)

	hook.Run("PlayerSpawnShared", ply)
	return self.BaseClass.PlayerSpawn(self, ply, ...)
end
