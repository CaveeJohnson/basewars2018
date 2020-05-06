function basewars.dropToFloor(ent, pos, min, max, filter, collision)

	local trmin, trmax = Vector(), Vector()
	trmin:Set(min)
	trmax:Set(max)

	trmin:Mul(0.5)
	trmax:Mul(0.5)

	trmin.z = 0
	trmax.z = 0	--flatten out the OBB so it doesn't leak through world upwards/downwards

	local res = util.TraceHull{
		start  = pos,
		endpos = pos - Vector(0, 0, 128),
		filter = ent,
		mins   = trmin,
		maxs   = trmax,

		filter = filter,
		collisiongroup = collision or COLLISION_GROUP_WORLD 		--COLLISION_GROUP_WORLD = doesn't collide with props or players
	}

	if res.StartSolid then
		return pos
	else

		local hp = Vector()
		hp:Set(res.HitPos)
		hp.z = hp.z - min.z

		return hp

	end

end