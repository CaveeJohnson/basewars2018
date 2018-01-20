local ext = basewars.createExtension"anti-rdm"

ext.nonHostileWeps = {
	["weapon_physgun"   ] = true,
	["weapon_physcannon"] = true,
	["gmod_tool"        ] = true,
	["gmod_camera"      ] = true,

	["basewars_hands"               ] = true,
	["basewars_matter_manipulator"  ] = true,
	["basewars_matter_reconstructor"] = true,
}

function ext:becomeHostile(ply)
	if IsValid(ply) and ply:IsPlayer() and not ply.bw_isHostile then
		ply.bw_isHostile = true
		hook.Run("BW_OnPlayerBecomeHostile", ply)

		if SERVER then
			ply:SetColor(Color(255, 255, 255, 255))
			ply:GodDisable()

			timer.Remove(self:getTag() .. tostring(ply))
		end
	end
end

function ext:PlayerReallySpawned(ply)
	if not ply.bw_isHostile then
		local time = 60 -- TODO: config

		timer.Create(self:getTag() .. tostring(ply), time, 1, function()
			self:becomeHostile(ply)
		end)
	end
end

function ext:PlayerSpawnShared(ply)
	local time = 60 -- TODO: config

	if hook.Run("BW_ShouldPlayerHaveProtection", ply) == false then
		ply.bw_isHostile = true

		return
	end

	local neverBefore = ply.bw_isHostile == nil
	ply.bw_isHostile = false

	if SERVER then
		ply:SetRenderMode(RENDERMODE_TRANSALPHA)
		ply:SetColor(Color(255, 255, 255, 100))

		ply:GodEnable()

		if not neverBefore then -- reallyspawned does this
			timer.Create(self:getTag() .. tostring(ply), time, 1, function()
				self:becomeHostile(ply)
			end)
		end
	end
end

function ext:PlayerSwitchWeapon(ply, old, new)
	if IsValid(old) and IsValid(new) and not self.nonHostileWeps[new:GetClass()] then -- wep switch
		self:becomeHostile(ply)
	end
end

function ext:PlayerShouldTakeDamage(_, attack)
	self:becomeHostile(attack)
end
