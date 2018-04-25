local net_tag = "bw-nuke-effect"

function basewars.doNukeEffect(pos)
	if hook.Run("BW_OnNukeEffect", pos) then return end

	if SERVER then
		ParticleEffect("explosion_huge_b", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_c", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_c", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_g", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_f", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("hightower_explosion", pos + Vector(0, 0, 10), Angle())
		ParticleEffect("mvm_hatch_destroy", pos + Vector(0, 0, 32), Angle())

		net.Start(net_tag)
			net.WriteVector(pos)
		net.Broadcast()
	end
end

if SERVER then
	util.AddNetworkString(net_tag)
else
	net.Receive(net_tag, function()
		basewars.doNukeEffect(net.ReadVector())
	end)
end
