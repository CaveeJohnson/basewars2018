local tag = "sitting"

if SERVER then
	util.AddNetworkString(tag)

	net.Receive(tag, function(_, ply)
		ply.sit_prev_weapon = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or "basewars_hands"
		ply:Give("basewars_hands")	-- should have this by default?
		ply:SelectWeapon("basewars_hands")
		ply:SetActiveWeapon(ply:GetWeapon("basewars_hands"))
		ply._is_sitting = true
		net.Start(tag)
		net.WriteUInt(ply:EntIndex(), 16)
		net.WriteBool(true)
		net.Broadcast()
	end)
end

if CLIENT then
	concommand.Add("toggle_sitting", function()
		net.Start(tag)
		net.SendToServer()
	end)

	net.Receive(tag, function()
		local ply = Entity(net.ReadUInt(16))
		if not IsValid(ply) then return end

		local state = net.ReadBool()
		ply._is_sitting = state
	end)

	hook.Add("KeyPress", tag, function(ply, key)
		if not IsFirstTimePredicted() then return end

		if key ~= IN_USE then return end

		local walk = ply:KeyDown(IN_WALK)
		if not walk then return end

		local frac = ply:GetAimVector():Dot(Vector(0, 0, -1))
		if frac < 0.9 then return end

		RunConsoleCommand("toggle_sitting")
	end)
end

FindMetaTable("Player").IsSitting = function(self)
	if not self._is_sitting then return false end
	return self._is_sitting
end

hook.Add("CalcMainActivity", tag, function(ply, vel)
	if not ply:IsSitting() then return end
	if ply:IsSitting() and vel:Length2DSqr() > 0 then return end

	local seq = ply:LookupSequence("pose_ducking_02")
	if not seq then return end

	return -1, seq
end)

hook.Add("SetupMove", tag, function(ply, mv, cmd)
	if ply:IsSitting() then
		if not cmd:KeyDown(IN_DUCK) then
			mv:SetButtons(IN_DUCK)
			mv:SetMaxClientSpeed(1)
		else
			mv:SetMaxClientSpeed(70)
		end

		if cmd:KeyDown(IN_JUMP) or ply:GetMoveType() ~= MOVETYPE_WALK then
			ply._is_sitting = nil
			if SERVER then
				ply:SelectWeapon(ply.sit_prev_weapon)
				ply.sit_prev_weapon = nil
				net.Start(tag)
				net.WriteUInt(ply:EntIndex(), 16)
				net.WriteBool(false)
				net.Broadcast()
			else
				timer.Simple(0.05, function()
					if IsValid(ply) and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon().sendWeaponAnim then
						ply:GetActiveWeapon():sendWeaponAnim("draw", 1)
					end
				end)
			end
		end
	end
end)

hook.Add("PlayerSwitchWeapon", tag, function(ply, owep, nwep)
	if ply:IsSitting() then
		if SERVER and ply.Unrestricted then return end
		if nwep:GetClass() == "basewars_hands" then return true end
		if IsFirstTimePredicted() and SERVER then
			ply:ChatPrint("You're sitting!")
		end
		return true
	end
end)
