local ext = basewars.createExtension"playerRestrictions"

function ext:PlayerSpawnRagdoll(ply, model)
	if not ply:IsAdmin() then
		return false
	end
end

function ext:PlayerSpawnSENT(ply, class)
	if not ply:IsAdmin() then
		return false
	end
end

function ext:PlayerSpawnNPC(ply, class, wepclass)
	if not ply:IsAdmin() then
		return false
	end
end

function ext:PlayerGiveSWEP(ply, class, swep)
	if not ply:IsAdmin() then
		return false
	end
end

function ext:PlayerSpawnSWEP(ply, class, swep)
	if not ply:IsAdmin() then
		return false
	end
end

function ext:PlayerSpawnVehicle(ply, model, name, vtable)
	if not (ply:IsAdmin() or SERVER_DEVMODE) then
		return false
	end
end

function ext:PlayerNoClip(ply, desire)
	if desire and not (ply:IsAdmin() or SERVER_DEVMODE) then
		return false
	end
end

function ext:OnPhysgunReload(physgun, ply)
	if not ply:IsAdmin() then
		return false
	end
end

function ext:CanTool(ply, trace, tool)
	if tool == "dynamite" then
		if not ply:IsSuperAdmin() then return false end return
	end

	if trace.Entity then
		if trace.Entity:GetClass():match("^basewars_.+") and not SERVER_DEVMODE then
			if not ply:IsAdmin() then return false end return
		elseif trace.Entity:IsPlayer() then
			if not ply:IsAdmin() then return false end return
		end
	end
end

-- HACK: gmod checks .PhysgunDisabled in PhysgunPickup but not here, why?
function ext:CanPlayerUnfreeze(ply, ent)
	if ent.PhysgunDisabled then return false end
end

function ext:CanProperty(ply, prop, ent, ...)
	local class = ent:GetClass()

	if prop == "persist"    then return false end

	if prop == "ignite"     and not SERVER_DEVMODE then if not ply:IsAdmin() then return false end return end
	if prop == "extinguish" and not SERVER_DEVMODE then if not ply:IsAdmin() then return false end return end

	if prop == "remover"    and not SERVER_DEVMODE and class:match("^basewars_.+") then if not ply:IsAdmin() then return false end return end
end

function ext:GravGunPunt(ply, ent)
	if ent:IsVehicle() then
		return false
	end
end

if SERVER then
	-- begone thot
	game.ConsoleCommand("sbox_weapons 0\n")
	game.ConsoleCommand("mp_falldamage 1\n")
end
