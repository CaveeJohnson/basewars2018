AddCSLuaFile()

SWEP.Base          = "basewars_ck_base"
DEFINE_BASECLASS     "basewars_ck_base"
SWEP.PrintName     = "MATTER MANIPULATOR"

-- Contact and author are same as base
SWEP.Purpose       = "Equipped with a massenergy &lt;-&gt; money conversion matrix, the easiest way to create items on the go."

local reload       = SERVER and "R" or input.LookupBinding("reload"):upper()
local use          = SERVER and "E" or input.LookupBinding("use"):upper()
local speed        = SERVER and "SHIFT" or input.LookupBinding("speed"):upper()
--SWEP.Instructions  = "remake in progress, press r to toggle mode"

SWEP.Slot          = 0
SWEP.SlotPos       = 3

SWEP.Category      = "Basewars"
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
SWEP.DrawCrosshair = true

SWEP.weaponSelectionLetter = "l"

SWEP.reloadSound   = Sound("weapons/ar2/ar2_empty.wav")
SWEP.failSound     = Sound("buttons/button8.wav")
SWEP.shootSound    = "weapons/airboat/airboat_gun_energy%d.wav"

local ext = basewars.createExtension"core.matter-manipulator"
SWEP.ext  = ext
basewars.matter_manipulator = basewars.matter_manipulator or {}

do
	local shade     = Color(20 , 20 , 20 , 200)
	local off_white = Color(240, 240, 240, 255)

	local reload = SERVER and "R"     or input.LookupBinding("reload"):upper()
	local use    = SERVER and "E"     or input.LookupBinding("use"   ):upper()
	local speed  = SERVER and "SHIFT" or input.LookupBinding("speed" ):upper()

	local reverse = {
		E = use,
		SHIFT = speed,
		["SHIFT+E"] = speed .. " + " .. use,
	}

	function ext:BW_BuildModeHUD(x, y, mm, fonts)
		if not mm then return end
		y = y - 10

		self.mode      = self.mode or 1
		self.modeAlpha = math.max((self.modeAlpha or 80) * 0.98, 80)
		off_white.a    = self.modeAlpha
		shade.a        = self.modeAlpha - 55

		local mode = self.modes[self.mode]
		if not mode then return end

		y = y - draw.textOutlined(string.format("[%s] Change Mode", reload), fonts.font_smaller, x, y, off_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, shade)
		for key, info in pairs(mode.instructions) do
			key = key:upper()
			y = y - draw.textOutlined(string.format("[%s] %s", reverse[key] or key, info), fonts.font_smaller, x, y, off_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, shade)
		end

		y = y - draw.textOutlined(string.format("MODE %02d: %s", self.mode, mode.name), fonts.font_main, x, y, off_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, shade)
	end
end

function basewars.matter_manipulator.loadModes()
	ext.modes = {}
		hook.Run("BW_MatterManipulatorLoadModes", ext.modes)
	ext.mode_count = #ext.modes
end

function basewars.matter_manipulator.getModeList()
	return ext.modes, ext.mode_count
end

function SWEP:callForMode(event, ...)
	local mode = ext.modes[self:GetFireMode()]

	if mode[event] then
		return mode[event](self, ...)
	end
end

function SWEP:getModeColor()
	return ext.modes[self:GetFireMode()].color
end

function ext:PlayerLoadout(ply)
	ply:Give("basewars_matter_manipulator")
end

ext.rtName = "bw_matter_manipulator_rt"
ext.rtMatName = "!" .. ext.rtName .. "_mat"

SWEP.VElements = {
	["dials_light"]  = { type = "Sprite", sprite = "sprites/light_glow02", bone = "Base", rel = "dials", pos = Vector(0.699, 0.699, 0), size = { x = 1, y = 1 }, color = Color(255, 0, 0, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["dials"]        = { type = "Model", model = "models/props_lab/reciever01a.mdl", bone = "Base", rel = "", pos = Vector(-0.201, 1.2, 6), angle = Angle(-1.17, 1.169, 90), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell1"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(-0.101, -1.558, 1), angle = Angle(73.636, -26.883, 0), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell2"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(0, -1.558, -0.519), angle = Angle(73.636, -26.883, 0), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell3"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "Base", rel = "", pos = Vector(0.09, -1.558, -1.759), angle = Angle(73.636, -26.883, 0), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["screen"]       = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "Base", rel = "", pos = Vector(2.7, 2.2, 7.792), angle = Angle(-90, 90, 0), size = Vector(0.08, 0.08, 0.08), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}, submaterial = { [1] = ext.rtMatName } },
}

SWEP.WElements = {
	["energy_cell1"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(5.791, 0.418, -7.393), angle = Angle(180, 0, -40.91), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell2"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.635, 0.319, -6.954), angle = Angle(180, 0, -40.91), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["energy_cell3"] = { type = "Model", model = "models/items/combine_rifle_ammo01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(7.791, 0.518, -7.792), angle = Angle(180, 0, -40.91), size = Vector(0.107, 0.107, 0.107), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["screen"]       = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(6.752, 1.557, -4.301), angle = Angle(180, 0, 0), size = Vector(0.05, 0.05, 0.05), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
}

if CLIENT then
	local crosshairMat = surface.GetTextureID("sprites/hud/v_crosshair2")

	function SWEP:DoDrawCrosshair(x, y)
		surface.SetTexture(crosshairMat)
		surface.SetDrawColor(self:getModeColor())

		surface.DrawTexturedRectRotated(x, y, 32, 32, 90)
		surface.DrawTexturedRectRotated(x, y, 32, 32, 0)

		return true
	end

	function SWEP:getElementColor(name)
		if name == "dials_light" then return self:getModeColor() end
	end

	function SWEP:updateGhostEntity(res)
		self.csEnt:SetNoDraw(true)
		self:callForMode("updateGhostEntity", res)
	end

	function SWEP:cleanupGhostEntity()
		if IsValid(self.csEnt) then self.csEnt:Remove() end
	end

	function SWEP:createGhostEntity()
		if IsValid(self.csEnt) then return end

		self.csEnt = ents.CreateClientProp("models/error.mdl")
			self.csEnt:SetNoDraw(true)

			self.csEnt:SetSolid(SOLID_VPHYSICS)
			self.csEnt:SetMoveType(MOVETYPE_NONE)
			self.csEnt:SetNotSolid(true)
			self.csEnt:SetRenderMode(RENDERMODE_TRANSALPHA)
			self.csEnt:SetColor(Color(255, 255, 255, 150))
		self.csEnt:Spawn()
	end

	function SWEP:Holster()
		self:cleanupGhostEntity()

		return BaseClass.Holster(self)
	end

	local rtTex = GetRenderTargetEx(ext.rtName, 1024, 576, RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, 2, 0, IMAGE_FORMAT_RGBA8888)
	ext.rtMat = CreateMaterial(ext.rtName .. "_mat", "UnlitGeneric", { -- no ! needed
		["$basetexture"] = rtTex,
		["$model"] = "1"
	})

	local largeFont  = ext:getTag() .. "_large"
	local mediumFont = ext:getTag() .. "_med"
	local smallFont  = ext:getTag() .. "_small"
	local xsmallFont = ext:getTag() .. "_xsmall"

	ext.fonts = {
		largeFont = largeFont,
		mediumFont = mediumFont,
		smallFont = smallFont,
		xsmallFont = xsmallFont,
	}

	surface.CreateFont(largeFont, {
		font = "DejaVu Sans",
		size = 128,
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

	function SWEP:RenderScreen()
		local trace = self:trace()

		self:createGhostEntity()
		self:updateGhostEntity(trace)

		local w, h = 1024, 576

		render.PushRenderTarget(rtTex)
			render.ClearDepth()
			render.Clear(50, 50, 50, 255)

			cam.Start2D()
				self:callForMode("renderScreen", ext.fonts, trace, w, h)
			cam.End2D()

		render.PopRenderTarget()
		render.Clear(0, 0, 0, 255)

		ext.rtMat:SetTexture("$basetexture", rtTex)
	end

	function SWEP:FreezeMovement()
		return self:callForMode("freezeMovement")
	end

	function SWEP:onModeChange(new)
		ext.mode = tonumber(new) -- shit game
		ext.modeAlpha = 1000

		-- TODO: instructions
	end
end

function SWEP:Think()
	self:callForMode("think", self:GetOwner())
	return BaseClass.Think(self)
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "FireMode")
	self:NetworkVar("Int", 1, "Var1")
	self:NetworkVar("Int", 2, "Var2")
end

function SWEP:Initialize()
	BaseClass.Initialize(self)
	if CLIENT then return end

	self:SetFireMode(1)
end

function SWEP:Reload()
	if self:GetOwner():KeyDownLast(IN_RELOAD) then return end
	self:EmitSound(self.reloadSound)

	if CLIENT then return end

	local count = #ext.modes
	local cur_mode = self:GetFireMode()

	if cur_mode >= count then
		self:SetFireMode(1)
	else
		self:SetFireMode(cur_mode + 1)
	end

	self:CallOnClient("onModeChange", self:GetFireMode())

	-- shared data for usage in modes
	self:SetVar1(0)
	self:SetVar2(0)
end

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

function SWEP:DoShootEffect(hitpos, hitnormal, entity, physbone, firstTimePredicted, noSound, noIndicator)
	if not noSound then self:EmitSound(string.format(self.shootSound, math.random(1, 2))) end

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	if not firstTimePredicted then return end

	local effectdata
	if not noIndicator then
		effectdata = EffectData()
			effectdata:SetOrigin(hitpos)
			effectdata:SetNormal(hitnormal)
			effectdata:SetEntity(entity)
			effectdata:SetAttachment(physbone)
		util.Effect("selection_indicator", effectdata)
	end

	effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetStart(self.Owner:GetShootPos())
		effectdata:SetAttachment(1)
		effectdata:SetEntity(self)
	util.Effect("ToolTracer", effectdata)
end

function SWEP:PrimaryAttack()
	if not self:trace() then return end
	-- TODO: alt fire mode?

	self.Primary.Automatic = false
	local res, bypass = self:callForMode("primaryFire", trace_res)

	if not bypass then
		if res then
			self:DoShootEffect(trace_res.HitPos, trace_res.HitNormal, trace_res.Entity, trace_res.PhysicsBone, IsFirstTimePredicted(), false, false)
		else
			self:EmitSound(self.failSound)
		end

		self:SetNextPrimaryFire(CurTime() + 0.6)
	end
end

function SWEP:SecondaryAttack()
end

basewars.matter_manipulator.loadModes()

function ext:PostReloaded()
	basewars.matter_manipulator.loadModes()
end
