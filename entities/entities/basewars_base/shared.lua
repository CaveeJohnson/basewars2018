AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.RenderGroup = RENDERGROUP_BOTH

ENT.PrintName = "Basewars Base Entity"

ENT.Model = "models/props_interiors/pot02a.mdl"
ENT.Skin = 0
ENT.BaseHealth = 100

ENT.isBasewarsEntity = true

ENT.criticalDamagePercent = 0.09

do
	local clamp = math.ClampRev
	local nmax = math.max
	local nmin = math.min

	local net_tag = "bw-dtv_transmit"
	if SERVER then
		util.AddNetworkString(net_tag)

		function ENT:dtvTransmit()
			if not self.dtv_transmit or self.dtv_transmit_count == 0 then return end

			net.Start(net_tag)
				net.WriteUInt(self:EntIndex(), 16)
				net.WriteUInt(self.dtv_transmit_count, 8)

				for name, v in pairs(self.dtv_transmit) do
					net.WriteString(name)

					net.WriteType(v[1])
					net.WriteType(v[2])
				end
			net.Broadcast()

			self.dtv_transmit = {}
			self.dtv_transmit_count = 0
		end

		function ENT:Think()
			BaseClass.Think(self)

			self:dtvTransmit()
		end
	else
		local function callChanges(self, data)
			for name, v in pairs(data) do
				self:queueDtvChange(name, v[1], v[2])
			end
		end

		net.Receive(net_tag, function()
			local eidx  = net.ReadUInt(16)
			local count = net.ReadUInt(8 )

			local data = {}
			for i = 1, count do
				data[net.ReadString()] = {net.ReadType(), net.ReadType()}
			end

			local ent = Entity(eidx)
			if not (IsValid(ent) and ent.queueDtvChange) then
				local timer_id = net_tag .. "_" .. tostring(eidx)  .. "_" .. tostring(math.random()) -- just has to be unique

				timer.Create(timer_id, 2, 5, function()
					ent = Entity(eidx)
					if not (IsValid(ent) and ent.queueDtvChange) then return end

					timer.Remove(timer_id)
					callChanges(ent, data)
				end)
			else
				callChanges(ent, data)
			end
		end)
	end

	function ENT:queueDtvChange(name, old, new)
		if not (self.dtv_callbacks and self.dtv_callbacks[name]) then return end

		for _, v in ipairs(self.dtv_callbacks[name]) do
			v(self, name, old, new)
		end

		if SERVER then
			self.dtv_transmit       = self.dtv_transmit or {}
			self.dtv_transmit[name] = {old, new}

			self.dtv_transmit_count = (self.dtv_transmit_count or 0) + 1
		end
	end

	-- OPT:
	function ENT:makeGSAT(type, name, min, max)
		local numberString = type == "Double"

		local getVar = function(minMax)
			if self[minMax] and isfunction(self[minMax]) then return self[minMax](self) end
			if self[minMax] and isnumber(self[minMax]) then return self[minMax] end
			return minMax or 0
		end

		local bool    = type == "Bool"
		local getType = bool and "is" or "get"

		--local setter  = self["SetNW2" .. type]
		--local getter  = self["GetNW2" .. type]

		local getName = getType .. name
		local setName = "set"   .. name

		if numberString then
			self[getName] = function(ent)
				return tonumber(ent.dt[name]) or 0
			end
		else
			self[getName] = function(ent)
				return ent.dt[name]
			end
		end

		if numberString then
			self[setName] = function(ent, var)
				--ent:SetNW2String(name, var)
				ent:queueDtvChange(name, ent.dt[name], var)
				ent.dt[name] = tostring(var)
			end
		else
			self[setName] = function(ent, var)
				--setter(ent, name, var)
				ent:queueDtvChange(name, ent.dt[name], var)
				ent.dt[name] = var
			end
		end

		local numerical = numberString or type == "Int" or type == "Float"

		if numerical or type == "Vector" or type == "Angle" then
			if min and max then
				self["add" .. name] = function(ent, var)
					local val = ent[getName](ent) + var
					val = clamp(val, getVar(min), getVar(max))

					ent[setName](ent, val)
				end
				self["take" .. name] = function(ent, var)
					local val = ent[getName](ent) - var
					val = clamp(val, getVar(min), getVar(max))

					ent[setName](ent, val)
				end
			elseif min then
				self["add" .. name] = function(ent, var)
					local val = ent[getName](ent) + var
					val = nmax(val, getVar(min))

					ent[setName](ent, val)
				end
				self["take" .. name] = function(ent, var)
					local val = ent[getName](ent) - var
					val = nmax(val, getVar(min))

					ent[setName](ent, val)
				end
			elseif max then
				self["add" .. name] = function(ent, var)
					local val = ent[getName](ent) + var
					val = nmin(val, getVar(max))

					ent[setName](ent, val)
				end
				self["take" .. name] = function(ent, var)
					local val = ent[getName](ent) - var
					val = nmin(val, getVar(max))

					ent[setName](ent, val)
				end
			else
				self["add" .. name] = function(ent, var)
					ent[setName](ent, ent[getName](ent) + var)
				end
				self["take" .. name] = function(ent, var)
					ent[setName](ent, ent[getName](ent) - var)
				end
			end
		end

		if numerical then
			self["has" .. name] = function(ent, amt)
				return ent[getName](ent) >= amt
			end
		elseif bool then
			self["toggle" .. name] = function(ent)
				self[setName](ent, not ent[getName](ent))
			end
		elseif type == "Entity" then
			self["valid" .. name] = function(ent)
				return ent[getName](ent):IsValid()
			end
		end

		if numberString then
			self[setName](self, "0")
		end
	end

	function ENT:netVar(type, name, min, max)
		self.__dataTableCount = self.__dataTableCount or {}

		local index
		local indexType = type == "Double" and "String" or type

		if self.__dataTableCount[indexType] then
			index = self.__dataTableCount[indexType]
			self.__dataTableCount[indexType] = index + 1
		else
			self.__dataTableCount[indexType] = 1
			index = 0
		end

		if index > 31 or (indexType == "String" and index > 3) then
			error(string.format("entity networking failed: Index out of range for '%s' of type '%s'", name, type), 2)
		end

		self:NetworkVar(indexType, index, name)
		self:makeGSAT(type, name, min, max)
	end

	function ENT:netVarCallback(name, func)
		--self:SetNWVarProxy(name, func)

		self.dtv_callbacks[name] = self.dtv_callbacks[name] or {}
		table.insert(self.dtv_callbacks[name], func)
	end

	function ENT:SetupDataTables()
		self.dtv_callbacks = {}

		self:netVar("String", "AbsoluteOwner")
		self:netVar("Double", "CurrentValue")
	end
end

function ENT:isCriticalDamaged()
	return self:Health() <= (self:GetMaxHealth() * self.criticalDamagePercent)
end

function ENT:ownershipCheck(ent)
	if self:CPPIGetOwner() == ent then return true end

	local abs_owner = self:getAbsoluteOwner()

	if IsValid(ent) then
		if ent:IsPlayer() and abs_owner == ent:SteamID64() then
			return true
		elseif ent.getAbsoluteOwner and abs_owner == ent:getAbsoluteOwner() then
			return true
		end
	else
		if abs_owner == ent then return true end
	end

	local res = hook.Run("BW_HasOwnership", ent, abs_owner)
	if res ~= nil then return res end

	return false
end
