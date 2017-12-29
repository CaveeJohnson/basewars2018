local PLAYER = {}

do
	local clamp = math.ClampRev
	local m_max = math.max

	local canData = {
		["Int"] = true,
		["Float"] = true,
		["String"] = true,
		["Bool"] = true,
	}

	function PLAYER:makeGSAT(type, name, databased, initial, max, min)
		self = self.Player

		if databased then
			if not canData[type] then
				error(string.format("cannot hava a databased '%s' variable '%s'", type, name), 3)
			elseif not initial then
				error(string.format("databased variable '%s' must have an initial value", name), 3)
			end
		end

		local getVar = function(minMax)
			if self[minMax] and isfunction(self[minMax]) then return self[minMax](self) end
			if self[minMax] and isnumber(self[minMax]) then return self[minMax] end
			return minMax or 0
		end

		local bool = type == "Bool"
		local getType = bool and "is" or "get"

		local setter = self["SetNW2" .. type]
		local getter = self["GetNW2" .. type]

		self[getType .. name] = function(self)
			return getter(self, name)
			--return self.dt[name]
		end

		local numerical = type == "Int" or type == "Float"

		if numerical then
			self["has" .. name] = function(_, amt)
				return self["get" .. name](self) >= amt
			end
		elseif bool then
			if SERVER then
				self["toggle" .. name] = function(_)
					self["set" .. name](self, not self["is" .. name](self))
				end
			end
		elseif type == "Entity" then
			self["valid" .. name] = function(_, amt)
				return IsValid(self["get" .. name](self))
			end
		end

		if SERVER then
			self["set" .. name] = function(self, var, noSave)
				setter(self, name, var)
				--self.dt[name] = var

				if databased and not noSave then
					basewars.savePlayerVar(self, name, var)
				end
			end

			if numerical or type == "Vector" or type == "Angle" then
				self["add" .. name] = function(_, var)
					local val = self["get" .. name](self) + var

					if min and max then
						val = clamp(val, getVar(min), getVar(max))
					elseif min then
						val = m_max(val, getVar(min))
					end

					self["set" .. name](self, val)
				end

				self["take" .. name] = function(_, var)
					local val = self["get" .. name](self) - var

					if min and max then
						val = clamp(val, getVar(min), getVar(max))
					elseif min then
						val = m_max(val, getVar(min))
					end

					self["set" .. name](self, val)
				end
			end

			if databased then
				self.__varsToLoad = self.__varsToLoad or {}
				self.__varsToLoad[name] = {initial, function(self, _, val)
					if numerical then
						val = tonumber(val)
					elseif bool then
						val = tobool(val)
					end

					self["set" .. name](self, val, true)
				end}
			elseif initial then
				self["set" .. name](self, initial)
			end
		end
	end

	function PLAYER:netVar(type, name, databased, initial, max, min)
		self.__dataTableCount = self.__dataTableCount or {}

		local index
		local indexType = type

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

		--self:NetworkVar(indexType, index, name)
		self:makeGSAT(type, name, databased, initial, max, min)
	end

	function PLAYER:netVarCallback(name, func, delay)
		local id = "plyvarcallbackdelay" .. tostring(self) .. name

		self.Player:SetNWVarProxy(name, (not delay and func) or function(ply, var, old, new)
			timer.Create(id, 0, 1, function() func(ply, var, old, new) end)
		end)
	end
end

function PLAYER:SetupDataTables()
	hook.Run("SetupPlayerDataTables", self)
	hook.Run("PostSetupPlayerDataTables", self.Player)
end

player_manager.RegisterClass("player_extended", PLAYER, "player_sandbox")
