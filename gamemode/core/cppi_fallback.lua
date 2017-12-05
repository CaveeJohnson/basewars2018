local PLAYER = debug.getregistry().Player
local ENTITY = debug.getregistry().Entity

if CPPI then
	return
elseif SERVER then
	basewars.requirementFailed("CPPI is not present", "Install a prop protection addon")
end

-- II.a Variables
CPPI                     = {}
CPPI.CPPI_DEFER          = 100100
CPPI.CPPI_NOTIMPLEMENTED = 7080

-- II.b Global Functions
function CPPI:GetName()
	return "BaseWars 2018"
end

function CPPI:GetVersion()
	return "bw18 cppi_fallback"
end

function CPPI:GetInterfaceVersion()
	return 1.3
end

function CPPI:GetNameFromUID(uid)
	return CPPI.CPPI_NOTIMPLEMENTED
end

-- II.c Player Functions
function PLAYER:CPPIGetFriends()
	return CPPI.CPPI_NOTIMPLEMENTED
end

-- II.d Entity Functions
if SERVER then
	function ENTITY:CPPISetOwner(ply)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPISetOwnerUID(uid)
		return CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanTool(ply, tool)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanPhysgun(ply)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanPickup(ply)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanPunt(ply)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanUse(ply)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanDamage(ply)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanDrive(ply)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanProperty(ply, prop)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end

	function ENTITY:CPPICanEditVariable(ply, key, val, edit)
		return true, CPPI.CPPI_NOTIMPLEMENTED
	end
end

function ENTITY:CPPIGetOwner()
	return NULL, CPPI.CPPI_NOTIMPLEMENTED
end

-- II.e Hook Functions
function GM:CPPIAssignOwnership(ply, ent, uid)
	-- stub
end

function GM:CPPIFriendsChanged(ply, friends)
	-- stub
end
