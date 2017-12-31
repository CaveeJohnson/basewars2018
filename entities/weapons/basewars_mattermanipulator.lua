AddCSLuaFile()

SWEP.Base          = "basewars_ck_base"
SWEP.PrintName     = "MATTER MANIPULATOR"

-- Contact and author are same as base
SWEP.Purpose       = "Converts between massenergy and money"
SWEP.Instructions  = ""

SWEP.Slot          = 0
SWEP.SlotPos       = 3

SWEP.Category      = "BaseWars"
SWEP.Spawnable     = true

SWEP.HoldType      = "ar2"
SWEP.UseHands      = true

SWEP.WorldModel    = "models/weapons/w_irifle.mdl"
SWEP.ViewModel     = "models/weapons/c_irifle.mdl"

SWEP.Primary.Ammo        = "none"
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false

SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false

SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = false

SWEP.weaponSelectionLetter = "l"

SWEP.reloadSound   = Sound("weapons/ar2/ar2_empty.wav")
SWEP.shootSound    = "weapons/airboat/airboat_gun_energy%d.wav"

local ext = basewars.createExtension"matter-manipulator"

function ext:sellEntity(ply, ent, pos)
	if not IsValid(ent) then return false end
	if ent.beingDestructed then return false end
	if ent:CPPIGetOwner() ~= ply then return false end
	if ent.isCore then return false end

	local should_sell = hook.Run("BW_ShouldSell", ply, ent)
	if should_sell == false then return false end

	if CLIENT then
		ent.beingDestructed = true
		return true
	end

	basewars.destructWithEffect(ent, 1, math.random(1, 100000))
	basewars.onEntitySale(ply, ent)

	return true
end

function ext:buyEntity(ply, ent, pos)
	return true
end

ext.rtName = "bw18_matter_manipulator_rt"
ext.rtMatName = "!" .. ext.rtName .. "_mat"

if CLIENT then
	local rtTex = GetRenderTargetEx(ext.rtName, 1024, 576, RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, 2, 0, IMAGE_FORMAT_RGBA8888)
	ext.rtMat = CreateMaterial(ext.rtName .. "_mat", "UnlitGeneric", { -- no ! needed
		["$basetexture"] = rtTex,
		["$model"] = "1"
	})

	local largeFont = ext:getTag() .. "_large"
	local smallFont = ext:getTag() .. "_small"

	surface.CreateFont(largeFont, {
		font = "DejaVu Sans",
		size = 128,
		weight = 1,
	})

	surface.CreateFont(smallFont, {
		font = "DejaVu Sans Bold",
		size = 80,
	})

	function SWEP:RenderScreen()
		render.PushRenderTarget(rtTex)
			render.ClearDepth()
			render.Clear(100, 100, 100, 255)

			cam.Start2D()
				draw.SimpleText("TEST", largeFont, 2, 2)
				draw.SimpleText("TEST", smallFont, 2, 130)
			cam.End2D()

		render.PopRenderTarget()
		render.Clear(0, 0, 0, 255)

		ext.rtMat:SetTexture("$basetexture", rtTex)
	end

	local col  = Color(200, 200, 200, 255)
	local col2 = Color(255, 100, 100, 255)
	local crosshairMat = surface.GetTextureID("sprites/hud/v_crosshair2")

	function SWEP:DrawHUD()
		local x, y = ScrW()/2, ScrH()/2
		local fire_mode = self:GetFireMode()

		surface.SetTexture(crosshairMat)
		surface.SetDrawColor(fire_mode and col2 or col)

		surface.DrawTexturedRectRotated(x, y, 32, 32, 90)
		surface.DrawTexturedRectRotated(x, y, 32, 32, 0)
	end

	function SWEP:getElementColor(name)
		if name == "dials_light" then return self:GetFireMode() and col2 or col end
	end
end

SWEP.VElements = {
	["dials_light"]  = { type = "Sprite", sprite = "sprites/light_glow02", bone = "Base", rel = "dials", pos = Vector(0.699, 0.699, 0), size = { x = 1, y = 1 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["dials"]        = { type = "Model", model = "models/props_lab/reciever01a.mdl", bone = "Base", rel = "", pos = Vector(-0.201, 1.2, 6), angle = Angle(-1.17, 1.169, 90), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell1"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(-0.101, -1.558, 1), angle = Angle(73.636, -26.883, 0), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell2"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(0, -1.558, -0.519), angle = Angle(73.636, -26.883, 0), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell3"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(0.09, -1.558, -1.759), angle = Angle(73.636, -26.883, 0), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["screen"]       = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "Base", rel = "", pos = Vector(1.299, 0.4, 6.752), angle = Angle(-90, 90, 0), size = Vector(0.05, 0.05, 0.05), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}, submaterial = { [1] = ext.rtMatName } },
}

SWEP.WElements = {
	["energy_cell1"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5.791, 0.418, -7.393), angle = Angle(180, 0, -40.91), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell2"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.635, 0.319, -6.954), angle = Angle(180, 0, -40.91), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell3"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(7.791, 0.518, -7.792), angle = Angle(180, 0, -40.91), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["screen"]       = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(6.752, 1.557, -4.301), angle = Angle(180, 0, 0), size = Vector(0.05, 0.05, 0.05), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
}

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "FireMode")
end

function SWEP:Reload()
	if self:GetOwner():KeyDownLast(IN_RELOAD) then return end
	self:EmitSound(self.reloadSound)

	if CLIENT then return end

	if not self:GetFireMode() then
		self:SetFireMode(true)
	else
		self:SetFireMode(false)
	end
end

local trace_res = {}
do
	local tr  = {output = trace_res}

	function SWEP:trace()
		local ply = self:GetOwner()

		tr.start  = ply:GetShootPos()
		tr.endpos = tr.start + ply:GetAimVector() * 1024
		tr.filter = ply

		util.TraceLine(tr)

		if not trace_res.Hit then return false end
		if trace_res.Entity and trace_res.Entity:IsPlayer() then return false end

		return true
	end
end

function SWEP:DoShootEffect(hitpos, hitnormal, entity, physbone, firstTimePredicted)
	self:EmitSound(string.format(self.shootSound, math.random(1, 2)))

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	if not firstTimePredicted then return end

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
		effectdata:SetEntity(entity)
		effectdata:SetAttachment(physbone)
	util.Effect("selection_indicator", effectdata)

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetStart(self.Owner:GetShootPos())
		effectdata:SetAttachment(1)
		effectdata:SetEntity(self)
	util.Effect("ToolTracer", effectdata)
end

function SWEP:PrimaryAttack()
	if not self:trace() then return end
	local target, pos = trace_res.Entity, trace_res.HitPos

	local res
	if self:GetFireMode() then
		res = self:Attack2(target, pos)
	else
		res = self:Attack1(target, pos)
	end
	if res then self:DoShootEffect(pos, trace_res.HitNormal, target, trace_res.PhysicsBone, IsFirstTimePredicted()) end
end

function SWEP:Attack1(target, pos)
	return ext:buyEntity (self:GetOwner(), target, pos)
end
function SWEP:Attack2(target, pos)
	return ext:sellEntity(self:GetOwner(), target, pos)
end

function SWEP:SecondaryAttack()
	-- boilerplate
end
