local ext = basewars.createExtension"core.garry-newmans-hairy-ballsack"

local function ballsack(a)
	return function(ent, ...)
		if ent == BALLSACK then
			return
		end
		return a(ent, ...)
	end
end

local ENTITY = debug.getregistry().Entity

UNSAFE_SafeRemoveEntity        = UNSAFE_SafeRemoveEntity        or SafeRemoveEntity
UNSAFE_SafeRemoveEntityDelayed = UNSAFE_SafeRemoveEntityDelayed or SafeRemoveEntityDelayed
ENTITY.UNSAFE_Remove           = ENTITY.UNSAFE_Remove           or ENTITY.Remove

SafeRemoveEntity               = ballsack(UNSAFE_SafeRemoveEntity)
SafeRemoveEntityDelayed        = ballsack(UNSAFE_SafeRemoveEntityDelayed)
ENTITY.Remove                  = ballsack(ENTITY.UNSAFE_Remove)

local BS_ENT = {}
BS_ENT.Type = "point"
BS_ENT.Base = "base_point"

function BS_ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

scripted_ents.Register(BS_ENT, "ballsack")

function ext:InitPostEntity()
	if CLIENT then return end
	if IsValid(BALLSACK) then return end

	BALLSACK = ents.Create"ballsack"
	if not IsValid(BALLSACK) then error"BALLSACK failure" end
	BALLSACK:Spawn()

	basewars.logf("BALLSACK created!")
end

function ext:EntityRemoved(ent)
	BALLSACK = ents.FindByClass("ballsack")[1]

	if ent == BALLSACK then
		-- got you ya fucker
		timer.Create("ballsack", 1, 1, function()
			hook.Run("OnFullUpdate")
		end)
	end
end
