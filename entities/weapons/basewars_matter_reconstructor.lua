AddCSLuaFile()

SWEP.Base          = "basewars_ck_base"
SWEP.PrintName     = "MATTER RECONSTRUCTOR"

SWEP.Purpose       = "Missing some matter here and there? Fear no more"
SWEP.Instructions  = "Hold LMB = Repair Target"

SWEP.Slot          = 0
SWEP.SlotPos       = 4

SWEP.Category      = "Basewars"
SWEP.Spawnable     = true

SWEP.HoldType = "physgun"
SWEP.ViewModelFOV = 69.748743718593
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_physcannon.mdl"
SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {}

SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = false

SWEP.Primary.Ammo        = "none"
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true

SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = true

local ext = basewars.createExtension"matter-reconstructor"
SWEP.ext  = ext

function ext:repair(res)
	local ent = res.Entity
	if not ent or ent.markedAsDestroyed then return false end

	local hp, max = ent:Health(), ent:GetMaxHealth()
	if hp <= 0 or max <= 0 or hp >= max then return false end

	if SERVER and IsFirstTimePredicted() then
		local newHealth = math.min(max, hp + math.random(5, 12)) -- TODO: this is boring
		ent:SetHealth(newHealth)

		-- TODO: color props / ents again
	end

	return true
end

ext.rtName = "bw18_matter_reconstructor_rt"
ext.rtMatName = "!" .. ext.rtName .. "_mat"

if CLIENT then
	local rtTex = GetRenderTargetEx(ext.rtName, 1024, 576, RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, 2, 0, IMAGE_FORMAT_RGBA8888)
	ext.rtMat = CreateMaterial(ext.rtName .. "_mat", "UnlitGeneric", { -- no ! needed
		["$basetexture"] = rtTex,
		["$model"] = "1"
	})

	local largeFont  = ext:getTag() .. "_large"
	local mediumFont = ext:getTag() .. "_med"
	local smallFont  = ext:getTag() .. "_small"
	local xsmallFont = ext:getTag() .. "_xsmall"

	surface.CreateFont(largeFont, {
		font = "DejaVu Sans",
		size = 116,
		weight = 1,
	})

	surface.CreateFont(mediumFont, {
		font = "DejaVu Sans",
		size = 92,
		weight = 1,
	})

	surface.CreateFont(smallFont, {
		font = "DejaVu Sans Bold",
		size = 60,
	})

	surface.CreateFont(xsmallFont, {
		font = "DejaVu Sans Bold",
		size = 52,
	})

	local function drawString(str, font, x, y, col, a, b)
		return draw.text(str, font, x, y, col, a, b)
	end

	function SWEP:renderTarget(trace, w, h)
		local x, y = 2, 2

		local ent = trace and trace.Entity or nil
		if not IsValid(ent) then
			y = y + drawString("Repair and Upgrade", largeFont, x, y)
			y = y + drawString("AIM AT AN ENTITY TO SEE MORE", smallFont, x, y)
			y = y + drawString("INFORMATION", xsmallFont, x, y)
		else
			y = y + drawString(basewars.getEntPrintName(ent), mediumFont, x, y)
			y = y + drawString(string.format("Health: %d / %d", ent:Health(), ent:GetMaxHealth()), smallFont, x, y)
		end
	end

	function SWEP:RenderScreen()
		local trace = self:trace()
		local w, h = 1024, 576

		render.PushRenderTarget(rtTex)
			render.ClearDepth()
			render.Clear(50, 50, 50, 255)

			cam.Start2D()
				self:renderTarget(trace, w, h)
			cam.End2D()
		render.PopRenderTarget()
		render.Clear(0, 0, 0, 255)

		ext.rtMat:SetTexture("$basetexture", rtTex)
	end

	local col  = Color(150, 150, 255, 255)
	local crosshairMat = surface.GetTextureID("sprites/hud/v_crosshair2")

	function SWEP:DrawHUD()
		local x, y = ScrW() / 2, ScrH() / 2

		surface.SetTexture(crosshairMat)
		surface.SetDrawColor(col)

		surface.DrawTexturedRectRotated(x, y, 32, 32, 90)
		surface.DrawTexturedRectRotated(x, y, 32, 32, 0)
	end

end

SWEP.VElements = {
	["CoreAttach"] = { type = "Model", model = "models/props_c17/pulleywheels_small01.mdl", bone = "Base", rel = "", pos = Vector(2, 0.1, -2.901), angle = Angle(90, 0, 22), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Monitor"] = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "Base", rel = "", pos = Vector(6, -3, -26.701), angle = Angle(-70, 0, -90), size = Vector(0.059, 0.059, 0.059), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}, submaterial = { [1] = ext.rtMatName } },
	["Handle"] = { type = "Model", model = "models/props_c17/canister02a.mdl", bone = "Base", rel = "", pos = Vector(7, 3.7, -5.6), angle = Angle(80, -5, -5), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Base"] = { type = "Model", model = "models/props_c17/furnitureboiler001a.mdl", bone = "Base", rel = "", pos = Vector(3.2, 1.6, -17), angle = Angle(0, -135, 0), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Battery"] = { type = "Model", model = "models/props/de_train/de_train_horizontalcoolingtank.mdl", bone = "Base", rel = "", pos = Vector(-2.3, -3.8, -22), angle = Angle(90, 45, -90), size = Vector(0.05, 0.05, 0.05), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Core"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(2.2, 0, 6), angle = Angle(179, 0, 2), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["BaseEngine"] = { type = "Model", model = "models/props_c17/TrapPropeller_Engine.mdl", bone = "Base", rel = "", pos = Vector(2.9, 0.4, -16), angle = Angle(0, 180, 0), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["Handle+"] = { type = "Model", model = "models/props_c17/canister02a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4, 0.699, -2), angle = Angle(-180, 90, 19.87), size = Vector(0.25, 0.25, 0.15), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Bottom"] = { type = "Model", model = "models/props_phx/construct/plastic/plastic_angle_360.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3, 0.2, -6.5), angle = Angle(94, 0, 19), size = Vector(0.078, 0.078, 0.078), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Core"] = { type = "Model", model = "models/Items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(25, -6, -4.901), angle = Angle(-80, 15.5, 0), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Base"] = { type = "Model", model = "models/props_c17/furnitureboiler001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(16.104, -1.558, -5.715), angle = Angle(85.324, -169.482, 5.843), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Battery"] = { type = "Model", model = "models/props/de_train/de_train_horizontalcoolingtank.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(10, -7, -8), angle = Angle(5.9, 16, -120), size = Vector(0.05, 0.05, 0.05), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["Handle"] = { type = "Model", model = "models/props_c17/canister02a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(8.6, 3.599, -5.401), angle = Angle(-85.325, 94.675, -10.52), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["BaseEngine"] = { type = "Model", model = "models/props_c17/TrapPropeller_Engine.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(18, -4, -5.901), angle = Angle(3.5, 105, 85), size = Vector(0.349, 0.349, 0.349), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

local trace_res = {}
do
	local tr  = {output = trace_res}

	function SWEP:trace()
		local ply = self:GetOwner()

		tr.start  = ply:GetShootPos()
		tr.endpos = tr.start + ply:GetAimVector() * 512
		tr.filter = ply

		util.TraceLine(tr)

		if not trace_res.Hit then return false end
		if trace_res.Entity and trace_res.Entity:IsPlayer() then return false end

		return trace_res
	end
end

function SWEP:DoShootEffect(hitpos, hitnormal, entity, physbone, firstTimePredicted)
	local random_id = "bw18_matter_reconstructor_" .. CurTime() .. tostring(self)
	local shared_random = math.Round(util.SharedRandom(random_id, 1, 2, 0))
	local shared_random2 = math.Round(util.SharedRandom(random_id, 45, 55, 1))

	self:EmitSound(string.format("weapons/airboat/airboat_gun_energy%d.wav", shared_random), 75, shared_random2, 0.2)

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	if not firstTimePredicted then return end

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetStart(self.Owner:GetShootPos())
		effectdata:SetAttachment(1)
		effectdata:SetEntity(self)
	util.Effect("PhyscannonImpact", effectdata)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.2)
	if not self:trace() then return end

	if ext:repair(trace_res) then
		self:DoShootEffect(trace_res.HitPos, trace_res.HitNormal, trace_res.Entity, trace_res.PhysicsBone, IsFirstTimePredicted())
	end
end

function SWEP:SecondaryAttack()

end

function SWEP:Reload()
	return true
end
