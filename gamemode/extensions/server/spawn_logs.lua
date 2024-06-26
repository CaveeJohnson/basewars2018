local ext = basewars.createExtension"spawn-logs"

ext.cyan, ext.white, ext.grey = Color(0  , 255, 255), Color(255, 255, 255), Color(192, 192, 192)

function ext:log(event, ply, ...)
	MsgC(self.cyan, "[", event, "] ")
	Msg(ply, " ")
	MsgC(...)
	Msg("\n")
end

function ext:formEnt(entity)
	local pos = entity:GetPos()
	return string.format("%s:%i @ %1.0f %1.0f %1.0f", entity:GetClass(), entity:EntIndex(), pos.x, pos.y, pos.z)
end

function ext:PlayerSpawnedProp(ply, model, entity)
	self:log("prop", ply, self.white, entity:GetModel(), self.grey, " (" .. self:formEnt(entity) .. ")")
end

function ext:PlayerSpawnedEffect(ply, model, entity)
	self:log("effect", ply, self.white, entity:GetModel(), self.grey, " (" .. self:formEnt(entity) .. ")")
end

function ext:PlayerSpawnedSENT(ply, entity)
	self:log("sent", ply, self.white, entity.PrintName or entity:GetClass(), self.grey, " (" .. self:formEnt(entity) .. ")")
end

function ext:PlayerSpawnedVehicle(ply, entity)
	self:log("vehicle", ply, self.white, entity.VehicleTable.Name, self.grey, " (" .. tostring(entity) .. ")")
end

function ext:CanTool(ply, tr, tool)
	self:log("tool", ply, self.white, tool, self.grey, " " .. tostring(tr.Entity) .. " @ " .. tostring(tr.HitPos))
end

function ext:OnPhysgunReload(physgun, ply)
	if ply.FrozenPhysicsObjects and ply.LastPhysUnfreeze and CurTime() - ply.LastPhysUnfreeze < 0.25 then
		self:log("unfreeze", ply, self.white, "unfroze ", self.grey, #ply.FrozenPhysicsObjects, " entities")
	end
end
