AddCSLuaFile()

ENT.Base = "basewars_power_sub_upgradable"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Weapon Station"

ENT.Model = "models/props_combine/combine_mortar01b.mdl"
ENT.BaseHealth = 1000
ENT.BasePassiveRate = -5
ENT.BaseActiveRate = -5

ENT.multEnergyTP = false

ENT.fontColor = Color(255, 255, 255)

local ext = basewars.createExtension"weapon-station"

ext.nonHostileWeps = {
	["weapon_physgun"   ] = true,
	["weapon_physcannon"] = true,
	["gmod_tool"        ] = true,
	["gmod_camera"      ] = true,

	["basewars_hands"               ] = true,
	["basewars_matter_manipulator"  ] = true,
	["basewars_matter_reconstructor"] = true,
} -- TODO: config

function ext:weaponValid(wep)
	if self.nonHostileWeps[wep:GetClass()] then return false end
	if wep.DrawAmmo == false then return false end

	return true
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("String", "WeaponClass")

	self:netVar("Int", "MaxClip1")
	self:netVar("Int", "Clip1", nil, "getMaxClip1")

	self:netVar("Int", "MaxClip2")
	self:netVar("Int", "Clip2", nil, "getMaxClip2")

	self:netVar("Int", "MaxReserve")
	self:netVar("Int", "Reserve", nil, "getMaxReserve")
end

function ENT:getRate()
	return 10 * self:getProductionMultiplier()
end

function ENT:Think()
	BaseClass.Think(self)

	if CLIENT or not IsValid(self.fakeWeapon) then return end

	self.fakeWeapon:SetPos(self:GetPos() + Vector(0, 0, 12))

	local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Forward(), CurTime() * 5)
	self.fakeWeapon:SetAngles(ang)

	if not self:isPowered() then return end
	if self.lastRefill and CurTime() - self.lastRefill <= 1 then return end
	self.lastRefill = CurTime()

	self:addReserve(self:getRate())
	self:addClip1(self:getRate())
	self:addClip2(self:getRate())
end

function ENT:ejectWeapon(ply)
	local wep = self:getWeaponClass()
	if wep == "" then return false end

	if ply:HasWeapon(wep) then return false end

	local ent = ply:Give(wep, true)
	if not IsValid(ent) then return false end

	self:setWeaponClass("")
	SafeRemoveEntity(self.fakeWeapon)

	ent:SetClip1(self:getClip1())
	ent:SetClip2(self:getClip2())
	ply:GiveAmmo(self:getReserve(), ent:GetPrimaryAmmoType())
	self:setActive(false)

	return true
end

function ENT:collectWeapon(ply)
	if self:getWeaponClass() ~= "" then return false end

	local wep = ply:GetActiveWeapon()
	if not ext:weaponValid(wep) then return false end

	local ammo_type = wep:GetPrimaryAmmoType()
	if ammo_type == -1 then return false end

	self:setWeaponClass(wep:GetClass())

	self.fakeWeapon = ents.Create("basewars_weapon_container")
		self.fakeWeapon:SetWeaponClass(wep:GetClass())
	self.fakeWeapon:Spawn()

	self.fakeWeapon:SetParent(self)
	self.fakeWeapon:SetMoveType(MOVETYPE_NONE)
	self.fakeWeapon:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self.fakeWeapon.Use = nil -- TODO: maybe?

	self:setClip1(wep:Clip1())
	self:setMaxClip1(wep:GetMaxClip1())

	self:setClip2(wep:Clip2())
	self:setMaxClip2(wep:GetMaxClip2())

	self:setReserve(ply:GetAmmoCount(ammo_type))
	ply:RemoveAmmo(self:getReserve(), ammo_type)
	self:setMaxReserve(999)

	wep:Remove()
	self:setActive(true)
	self.lastRefill = CurTime() + 0.1 -- stops abuse

	return true
end

function ENT:Use(user)
	if not user:IsPlayer() then return end

	if self:getWeaponClass() ~= "" then
		if not self:ejectWeapon(user) then self:EmitSound("buttons/button11.wav") end
	else
		if not self:collectWeapon(user) then self:EmitSound("buttons/button8.wav") end
	end
end

if CLIENT then
	surface.CreateFont("weapon_station_font", {
		font = "DejaVu Sans Mono",
		size = 24,
	})

	function ENT:drawDisplay(pos, ang, scale)
		local class = self:getWeaponClass()
		local x, y = 0, 0

		if class == "" then
			y = y - draw.text("INSERT WEAPON", "weapon_station_font", x, y, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			return
		end

		y = y - draw.text(class, "weapon_station_font", x, y, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		y = y - 8

		local rate = self:getRate()

		local maxc1 = self:getMaxClip1()
		if maxc1 > 0 then y = y - draw.text(string.format("CLIP      |  %03d / %03d  +%03d/s", self:getClip1(), maxc1, rate), "weapon_station_font", x, y, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end

		local maxc2 = self:getMaxClip2()
		if maxc2 > 0 then y = y - draw.text(string.format("ALT CLIP  |  %03d / %03d  +%03d/s", self:getClip2(), maxc2, rate), "weapon_station_font", x, y, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end

		y = y - draw.text(string.format("RESERVE   |  %03d / %03d  +%03d/s", self:getReserve(), self:getMaxReserve(), rate), "weapon_station_font", x, y, self.fontColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
