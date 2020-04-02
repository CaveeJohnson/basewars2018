AddCSLuaFile()

local original = ENT

local function addUpgradeFunctionality(e)
	DEFINE_BASECLASS(e.Base)

	function e:getProductionMultiplier(level)
		local default = 1 + ((level or self:getUpgradeLevel()) ^ 0.5) + (self:getXP() * 0.00025) -- TODO: config

		local res = hook.Run("BW_EntityProductionMultiplier", self, default) -- DOCUMENT:
		if res and tonumber(res) then
			default = tonumber(res)
		end

		return default
	end

	function e:getNextUpgradeCost()
		return math.max(500, self:getCurrentValue()) -- 500, 1000, 2000, 4000? seems good --TODO: config
	end

	function e:onUpgradeCallback(level, last)
		-- STUB
	end

	local function upgradeCallback(self, name, old, new)
		self:onUpgradeCallback(new, old)
	end

	function e:SetupDataTables()
		BaseClass.SetupDataTables(self)

		self:netVar("Int", "XP")
		self:netVar("Int", "UpgradeLevel")

		self:netVarCallback("UpgradeLevel", upgradeCallback)
	end
end

-- Cancer due to different levels of code being shared
do
	ENT = {}
	ENT.Base = "basewars_power_base"
	ENT.Type = "anim"
	ENT.isUpgradableEntity = true

	ENT.PrintName = "Basewars Powered Upgradable"

	addUpgradeFunctionality(ENT)
	scripted_ents.Register(ENT, "basewars_power_upgradable")
end

do
	ENT = {}
	ENT.Base = "basewars_power_sub"
	ENT.Type = "anim"
	ENT.isUpgradableEntity = true

	ENT.multEnergyTP = true

	ENT.PrintName = "Basewars Powered Sub Upgradable"

	addUpgradeFunctionality(ENT)
	scripted_ents.Register(ENT, "basewars_power_sub_upgradable")
end

do
	ENT = original
	ENT.Base = "basewars_base"
	ENT.Type = "anim"
	ENT.isUpgradableEntity = true

	ENT.PrintName = "Basewars Base Upgradable"

	addUpgradeFunctionality(ENT)
	--scripted_ents.Register(ENT, "basewars_upgradable_base")
end
