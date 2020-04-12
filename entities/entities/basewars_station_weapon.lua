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

local lerpTime = 0.6
local lerpEasing = 0.3

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

local rotateWeapon


if SERVER then

	function rotateWeapon(self, ent)
		ent:SetPos(self:GetPos() + Vector(0, 0, 12))

		local ang = self:GetAngles()
			ang:RotateAroundAxis(ang:Right(), 90)
			ang:RotateAroundAxis(ang:Forward(), CurTime() * 5)
		ent:SetAngles(ang)
	end

else

	function rotateWeapon(self, ent)
		local t = self:getTakenTime()

		local pos = self:getTakenFrom()
		local ang = self:getTakenAngle()

		local wantpos = self:GetPos() + Vector(0, 0, 12)

		local wantang = self:GetAngles()
			wantang:RotateAroundAxis(wantang:Right(), 90)
			wantang:RotateAroundAxis(wantang:Forward(), (CurTime() - t) * 5)

		wantang:Normalize()

		local frac = math.min(CurTime() - t, lerpTime) / lerpTime
		frac = Ease(frac, lerpEasing)

		local newpos = LerpVector(frac, pos, wantpos)
		local newang = LerpAngle(frac, ang, wantang)
		newang:Normalize()

		ent:SetPos(newpos)
		ent:SetAngles(newang)
	end

end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:netVar("String", "WeaponClass")

	self:netVar("Float", "TakenTime")	--you can't guess these clientside,
	self:netVar("Vector", "TakenFrom")	--you have to network them
	self:netVar("Angle", "TakenAngle")	--if you want the animation

	self:netVar("Int", "MaxClip1")
	self:netVar("Int", "Clip1", nil, "getMaxClip1")

	self:netVar("Int", "MaxClip2")
	self:netVar("Int", "Clip2", nil, "getMaxClip2")

	self:netVar("Int", "MaxReserve")
	self:netVar("Int", "Reserve", nil, "getMaxReserve")

	if CLIENT then
		self:NetworkVarNotify("WeaponClass", function(ent, name, old, new)
			if new == "" then
				if IsValid(ent.fakeWeapon) then
					ent.fakeWeapon:Remove()
				end
			else
				local wep = weapons.Get(new)

				if IsValid(ent.fakeWeapon) then
					ent.fakeWeapon:Remove()
				end

				ent.fakeWeapon = ents.CreateClientProp(wep.WorldModel)
				ent.fakeWeapon:SetParent(self)
			end
		end)
	end
end

function ENT:OnRemove()
	if IsValid(self.fakeWeapon) then
		SafeRemoveEntity(self.fakeWeapon)
	end
end

function ENT:getRate()
	return 10 * self:getProductionMultiplier()
end

function ENT:Think()
	BaseClass.Think(self)

	if CLIENT or not IsValid(self.fakeWeapon) then return end

	--rotateWeapon(self, self.fakeWeapon)

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

	self:setTakenTime(CurTime())
	self:setTakenFrom(vector_origin) --0, 0, 0
	self:setTakenAngle(angle_zero)

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

	self:setTakenTime(CurTime())


	local ang = ply:EyeAngles()

	local dir = Angle() --we still need the angle for TakenAngle
	dir:Set(ang)
	dir.p = 0

	self:setTakenFrom(wep:GetPos() + Vector(0, 0, 32) + dir:Forward() * 24)

	ang:RotateAroundAxis(ang:Up(), 180)

	self:setTakenAngle(ang)

	self.fakeWeapon = ents.Create("basewars_weapon_container")
		self.fakeWeapon:SetWeaponClass(wep:GetClass())
		self.fakeWeapon:SetNoDraw(true)

		rotateWeapon(self, self.fakeWeapon)
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

		if IsValid(self.fakeWeapon) then
			rotateWeapon(self, self.fakeWeapon)
			self.fakeWeapon:DrawModel()
		end
	end
end
