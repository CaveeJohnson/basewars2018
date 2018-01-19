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
	if ply:IsPlayer() and not ply.isHostile then
		ply.isHostile = true
		hook.Run("BW_OnPlayerBecomeHostile", ply)

		if SERVER then
			ply:SetColor(255, 255, 255, 255)
			ply:GodDisable()
		end
	end
end

function ext:PlayerSpawnShared(ply)
	if hook.Run("BW_ShouldPlayerHaveProtection", ply) == false then
		ply.isHostile = true

		return
	end

	ply.isHostile = false

	if SERVER then
		ply:SetRenderMode(RENDERMODE_TRANSALPHA)
		ply:SetColor(255, 255, 255, 100)

		ply:GodEnable()

		local time = 60 -- TODO: config
		timer.Create(self:getTag() .. tostring(ply), time, 1, function()
			self:becomeHostile(ply)
		end)
	end
end

function ext:PlayerSwitchWeapon(ply, old, new)
	if IsValid(new) and not self.nonHostileWeps[new:GetClass()] then
		self:becomeHostile(ply)
	end
end

function ext:PlayerShouldTakeDamage(_, attack)
	self:becomeHostile(attack)
end
