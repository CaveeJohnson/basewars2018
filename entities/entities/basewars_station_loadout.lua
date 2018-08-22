AddCSLuaFile()

ENT.Base = "basewars_upgradable_base"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Load-out Station"

ENT.Model = "models/props/cs_militia/table_shed.mdl"
ENT.BaseHealth = 1000

ENT.fontColor = Color(255, 255, 255)

local itemPos = {
	weapon = {
		Vector (-0.56234568357468, -25.057289123535, 36.501895904541),
		Angle (-1.1771992444992, -33.143810272217, -86.023040771484),
	},
	decorations = {
		{
			"models/healthvial.mdl",
			Vector (18.625749588013, 19.044828414917, 37.954071044922),
			Angle (0.8598530292511, -116.25936126709, 89.989776611328),
		},
		{
			"models/props_c17/suitcase_passenger_physics.mdl",
			Vector (12.377890586853, 14.239007949829, 13.502607345581),
			Angle (-0.0061229499988258, 60.155216217041, 90.08470916748),
		},
		{
			"models/items/healthkit.mdl",
			Vector (5.0942764282227, 34.403659820557, 35.535274505615),
			Angle (0.0012071025557816, -15.417972564697, -0.56726241111755),
		},
		{
			"models/items/healthkit.mdl",
			Vector (2.6795914173126, -25.383920669556, 10.183463096619),
			Angle (-0.11209133267403, 20.217632293701, 0.062514714896679),
		},
		{
			"models/items/healthkit.mdl",
			Vector (0.84233349561691, -16.563182830811, 13.088562011719),
			Angle (-0.51077288389206, 18.444370269775, -26.860403060913),
		},
	}
}

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("Int", "LastUsed")
end

function ENT:getCooldown()
	return 90 / self:getProductionMultiplier()
end

function ENT:Think()
	BaseClass.Think(self)
end

function ENT:onUpgradeCallback(level, last)
	if CLIENT then return end
	if level == last then return end

	self.decorations = self.decorations or {}

	local d = itemPos.decorations
	if last > level then
		for i = 1, #d do
			SafeRemoveEntity(self.decorations[i])
			self.decorations[i] = nil -- clear for regen
		end
	end

	for i = 1, math.min(level, #d) do
		if not IsValid(self.decorations[i]) then
			local ent = ents.Create("base_anim")
			self.decorations[i] = ent

			ent:Spawn()

			ent:SetParent(self)
			ent:SetMoveType(MOVETYPE_NONE)
			ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)

			local data = d[i]
			ent:SetModel(data[1])
			ent:SetPos(self:LocalToWorld(data[2]))
			ent:SetAngles(self:LocalToWorldAngles(data[3]))
		end
	end
end

function ENT:validWep(wep)
	if not IsValid(wep) then return false end
	if not basewars.items.get(wep:GetClass()) then return false end

	return true
end

function ENT:actuallyUse(user)
	local used = false

	-- TODO: config, config everywhere
	local healthCost = math.max(1, math.log10(user:getMoney()) - 4) ^ 4 * 500
	local health = user:Health()
	local max_health = user:GetMaxHealth()
	if health < max_health and self:getUpgradeLevel() > 0 and user:hasMoney(healthCost) then
		local calc = 35 * (self:getProductionMultiplier() - .5)
		local set = math.min(max_health, health + calc)

		user:SetHealth(set)
		used = true

		local used_frac = set / calc
		user:takeMoneyNotif(healthCost * used_frac, "For Purchasing Health")
		user:EmitSound("items/smallmedkit1.wav", 100, 90)
	end

	local armorCost = math.max(1, math.log10(user:getMoney()) - 4) ^ 4 * 2000
	if user:Armor() < 50 and self:getUpgradeLevel() > 1 and user:hasMoney(armorCost) then
		user:SetArmor(50)
		used = true

		user:takeMoneyNotif(armorCost, "For Purchasing Armor")
		user:EmitSound(string.format("npc/metropolice/gear%d.wav", math.random(1, 6)), 100, 90)
	end

	if IsValid(self.fakeWeapon) then
		local class = self.fakeWeapon:GetWeaponClass()
		local item = basewars.items.get(class)

		if not item then return ErrorNoHalt(string.format("unknown item on load-out bench: %s\n", class)) end

		if user:hasMoney(item.cost) and not IsValid(user:GetWeapon(class)) then
			local wep = user:Give(class)

			if IsValid(wep) then
				user:SelectWeapon(class)
				user:SetActiveWeapon(wep)

				user:takeMoneyNotif(item.cost,
					string.format("For Purchasing a(n) %s",
					item.name
				))

				used = true
			end
		end
	end

	if used then
		self:setLastUsed(CurTime())
	end
end

function ENT:Use(user)
	if not user:IsPlayer() then return end

	local wep = user:GetActiveWeapon()
	if not self:validWep(wep) then
		local time_since = CurTime() - self:getLastUsed()

		if time_since > self:getCooldown() then
			self:actuallyUse(user)
		end

		return
	end

	if IsValid(self.fakeWeapon) then
		self.fakeWeapon:Remove()
	end

	self.fakeWeapon = ents.Create("basewars_weapon_container")
		self.fakeWeapon:SetWeaponClass(wep:GetClass())
	self.fakeWeapon:Spawn()

	self.fakeWeapon:SetParent(self)
	self.fakeWeapon:SetMoveType(MOVETYPE_NONE)
	self.fakeWeapon:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self.fakeWeapon:SetPos(self:LocalToWorld(itemPos.weapon[1]))
	self.fakeWeapon:SetAngles(self:LocalToWorldAngles(itemPos.weapon[2]))

	self.fakeWeapon.Use = nil
end

if CLIENT then
	surface.CreateFont("loadout_station_font", {
		font = "DejaVu Sans Mono",
		size = 48,
	})

	surface.CreateFont("loadout_station_font_large", {
		font = "DejaVu Sans Mono",
		size = 128,
	})

	function ENT:drawDisplay(pos, ang, scale)
		local x, y = 0, 0

		local time_since = CurTime() - self:getLastUsed()
		local cooldown = self:getCooldown()
		if time_since < cooldown then
			local left = math.floor(cooldown - time_since)
			local m = math.floor(left / 60)
			local s = left - m * 60

			y = y - draw.text(string.format("%02.f:%02.f", m, s), "loadout_station_font_large", x, y, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local wep = LocalPlayer():GetActiveWeapon()
		if self:validWep(wep) then
			y = y - draw.text("PRESS 'E' TO ASSIGN WEAPON", "loadout_station_font", x, y, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	function ENT:calc3D2DParams()
		local pos = self:GetPos()
		local ang = self:GetAngles()

		pos = pos + ang:Up() * 55
		pos = pos-- + ang:Forward() * -12
		pos = pos-- + ang:Right() * 17.8

		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), -90)

		return pos, ang, 0.1 / 2
	end

	function ENT:Draw()
		self:DrawModel()

		local pos, ang, scale = self:calc3D2DParams()
		cam.Start3D2D(pos, ang, scale)
			pcall(self.drawDisplay, self, pos, ang, scale)
		cam.End3D2D()
	end
end
