AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.RenderGroup = RENDERGROUP_BOTH

ENT.PrintName = "BaseWars2018 Base Entity"

ENT.Model = "models/props_interiors/pot02a.mdl"
ENT.Skin = 0
ENT.BaseHealth = 100

ENT.isBaseWarsEntity = true

ENT.criticalDamagePercent = 0.09

ENT.packExt = basewars.getExtension"packing"
if ENT.packExt then
	ENT.PhysgunDisabled = true
end

do
	local clamp = math.ClampRev
	local max = math.max

	function ENT:makeGSAT(type, name, max, min)
		local numberString = type == "Double"

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
			if numberString then
				return tonumber(self:GetNW2String(name)) or 0
				--return tonumber(self.dt[name]) or 0
			end

			return getter(self, name)
			--return self.dt[name]
		end

		if numberString then
			self["set" .. name] = function(self, var)
				self:SetNW2String(name, var)
				--self.dt[name] = tostring(var)
			end
		else
			self["set" .. name] = function(self, var)
				setter(self, name, var)
				--self.dt[name] = var
			end
		end

		local numerical = numberString or type == "Int" or type == "Float"

		if numerical or type == "Vector" or type == "Angle" then
			self["add" .. name] = function(_, var)
				local val = self["get" .. name](self) + var

				if min and max then
					val = clamp(val, getVar(min), getVar(max))
				elseif min then
					val = max(val, getVar(min))
				end

				self["set" .. name](self, val)
			end

			self["take" .. name] = function(_, var)
				local val = self["get" .. name](self) - var

				if min and max then
					val = clamp(val, getVar(min), getVar(max))
				elseif min then
					val = max(val, getVar(min))
				end

				self["set" .. name](self, val)
			end
		end

		if numerical then
			self["has" .. name] = function(_, amt)
				return self["get" .. name](self) >= amt
			end
		elseif bool then
			self["toggle" .. name] = function(_)
				self["set" .. name](self, not self["is" .. name](self))
			end
		elseif type == "Entity" then
			self["valid" .. name] = function(_, amt)
				return IsValid(self["get" .. name](self))
			end
		end

		if numberString then
			self["set" .. name](self, "0")
		end
	end

	function ENT:netVar(type, name, max, min)
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

		--self:NetworkVar(indexType, index, name)
		self:makeGSAT(type, name, max, min)
	end

	function ENT:netVarCallback(name, func)
		self:SetNWVarProxy(name, func)
	end

	function ENT:SetupDataTables()
		self:netVar("Int", "XP")
		self:netVar("Int", "UpgradeLevel")

		self:netVar("String", "AbsoluteOwner")
	end
end

function ENT:getProductionMultiplier()
	local default = 1 + (self:getUpgradeLevel() ^ 0.5) + (self:getXP() * 0.00025) -- TODO: config

	local res = hook.Run("BW_EntityProductionMultiplier", self, default) -- DOCUMENT:
	if res and tonumber(res) then
		default = tonumber(res)
	end

	return default
end

function ENT:isCriticalDamaged()
	return self:Health() <= (self:GetMaxHealth() * self.criticalDamagePercent)
end

function ENT:ownershipCheck(ent)
	if self:CPPIGetOwner() == ent then return true end

	local abs_owner = self:getAbsoluteOwner()

	if isentity(ent) then 
		if ent:IsPlayer() and abs_owner == ent:SteamID64() then return true end
	else
		if abs_owner == ent then return true end
	end

	local res = hook.Run("BW_HasOwnership", ent, abs_owner)
	if res ~= nil then return res end

	return false
end

if CLIENT then return end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)

	self:SetUseType(SIMPLE_USE)
	if self.doBlinkEffect then self:AddEffects(EF_ITEM_BLINK) end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	self:Activate()

	self:SetMaxHealth(self.BaseHealth)
	self:SetHealth(self.BaseHealth)
end

ENT.repairSounds = {"physics/metal/metal_barrel_impact_hard5.wav", "physics/metal/metal_barrel_impact_hard6.wav", "physics/metal/metal_barrel_impact_hard7.wav"}

function ENT:repair()
	local hp, max = self:Health(), self:GetMaxHealth()
	if math.floor(hp) == math.floor(max) then return end

	self:SetHealth(max)
	self:EmitSound(self.repairSounds[math.random(1, #self.repairSounds)])

	hook.Run("BW_OnEntityRepaired", self, hp, max) -- DOCUMENT:
end

function ENT:spark(effect)
	local ed = EffectData()
		ed:SetOrigin(self:GetPos())
		ed:SetScale(1)
	util.Effect(effect or "ManhackSparks", ed)

	self:EmitSound("DoSpark")
end

function ENT:explode(soft, mag)
	local pos = self:GetPos()

	if soft then
		local ed = EffectData()
			ed:SetOrigin(pos)
		util.Effect("Explosion", ed)

		self:Remove()
		return
	end

	local ex = ents.Create("env_explosion")
		ex:SetPos(pos)
	ex:Spawn()
	ex:Activate()

	ex:SetKeyValue("iMagnitude", mag or 100)
	ex:Fire("explode")

	self:spark()
	self:spark("cball_bounce")
	self:Remove()

	SafeRemoveEntityDelayed(ex, 0.1)
end

function ENT:OnTakeDamage(dmginfo)
	local dmg = dmginfo:GetDamage()
	if dmg <= 0.0001 then
		return
	end

	if dmg >= 30 then
		self:spark()
	end

	self:SetHealth(self:Health() - dmg)
	if self:Health() <= 0 and not self.exploded then
		self.exploded = true

		local res = hook.Run("BW_PreEntityExplode", self, dmginfo) -- DOCUMENT:

		if res ~= false then
			self:explode(dmginfo:IsExplosionDamage())
		end
		hook.Run("BW_OnEntityExplode", self, dmginfo) -- DOCUMENT:
	end
end
