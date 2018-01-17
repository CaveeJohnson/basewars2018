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

function ext:PlayerSpawnShared(ply)
	print("antirdm PlayerSpawnShared", CLIENT, ply)
	ply.isHostile = false
end

function ext:PlayerSwitchWeapon(ply, old, new)
	if IsValid(new) and not self.nonHostileWeps[new:GetClass()] and not ply.isHostile then
		ply.isHostile = true
		hook.Run("BW_OnPlayerBecomeHostile", ply)
	end
end
