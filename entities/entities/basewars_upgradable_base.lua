AddCSLuaFile()

ENT.Base = "basewars_base"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Basewars 2018 Base Upgradable"

ENT.isUpgradableEntity = true

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Int", "XP")
	self:netVar("Int", "UpgradeLevel")
end

function ENT:getProductionMultiplier()
	local default = 1 + (self:getUpgradeLevel() ^ 0.5) + (self:getXP() * 0.00025) -- TODO: config

	local res = hook.Run("BW_EntityProductionMultiplier", self, default) -- DOCUMENT:
	if res and tonumber(res) then
		default = tonumber(res)
	end

	return default
end
