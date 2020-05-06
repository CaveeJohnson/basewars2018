local net_tag = "bw-nuke-effect"

function basewars.doNukeEffect(pos, prepared)
	print("doing nuke effects", Realm())

	if hook.Run("BW_PlayNukeEffect", pos) then return end

	if SERVER then
		ParticleEffect("explosion_huge_b", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_c", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_c", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_g", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("explosion_huge_f", pos + Vector(0, 0, 32), Angle())
		ParticleEffect("hightower_explosion", pos + Vector(0, 0, 10), Angle())
		ParticleEffect("mvm_hatch_destroy", pos + Vector(0, 0, 32), Angle())

		if not prepared then
			net.Start(net_tag)
				net.WriteBool(false)
				net.WriteVector(pos)
			net.Broadcast()
		end
	end
end

local sat = basewars.getExtension("satellite")
function basewars.preparedNukeEffect(pos, time)

	local reachTime = sat.reachTime

	print("prepared nuke", Realm(), "in", reachTime)

	timer.Simple(time - reachTime, function()
		hook.Run("BW_StartNukeEffect", pos)
	end)

	timer.Simple(time, function()
		basewars.doNukeEffect(pos, true)
	end)

	if SERVER then
		net.Start(net_tag)
			net.WriteBool(true)
			net.WriteVector(pos)
			net.WriteFloat(time)
		net.Broadcast()
	end

	return reachTime
end

if SERVER then
	util.AddNetworkString(net_tag)
else
	net.Receive(net_tag, function()
		local prep = net.ReadBool()
		local pos = net.ReadVector()

		if prep then
			local time = net.ReadFloat()

			basewars.preparedNukeEffect(pos, time)

		else
			basewars.doNukeEffect(pos)
		end
	end)
end

