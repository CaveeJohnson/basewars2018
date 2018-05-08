AddCSLuaFile()

SWEP.Base          = "basewars_ck_base"
DEFINE_BASECLASS     "basewars_ck_base"
SWEP.PrintName     = "MATTER MANIPULATOR"

-- Contact and author are same as base
SWEP.Purpose       = "Equipped with a massenergy &lt;-&gt; money conversion matrix, the easiest way to create items on the go."

local reload       = SERVER and "R" or input.LookupBinding("reload"):upper()
local use          = SERVER and "E" or input.LookupBinding("use"):upper()
local speed        = SERVER and "E" or input.LookupBinding("speed"):upper()
SWEP.Instructions  = ([=[
  <color=192,192,192>LMB</color>\t[1] Create\t[2] Destroy
  <color=192,192,192>RMB</color>\t[1] UNUSED\t[2] UNUSED
  <color=192,192,192>]=] .. use    .. [=[</color>\t[1] Rotate\t[2] UNUSED
  <color=192,192,192>]=] .. reload .. [=[</color>\tChange between [1] and [2]
  <color=192,192,192>]=] .. speed  .. [=[</color>\tSnap to angle]=]):gsub("\\t", "\t")

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

local ext = basewars.createExtension"matter-manipulator"
SWEP.ext  = ext

function ext:PlayerLoadout(ply)
	ply:Give("basewars_matter_manipulator")
end

ext.rtName = "bw_matter_manipulator_rt"
ext.rtMatName = "!" .. ext.rtName .. "_mat"

function ext:getAngles(ply)
	local yaw = tonumber(ply:GetInfoNum("bw_mm_creation_yaw", 0)) or 0
	local snap = tonumber(ply:GetInfoNum("gm_snapangles", 0)) or 0
	if ply:KeyDown(IN_SPEED) then yaw = math.Round(yaw / snap) * snap end

	local ang = Angle() --res.HitNormal:Angle()
		ang.y = ang.y + yaw
	ang:Normalize()

	return ang
end

function ext:buyItem(ply, res)
	local id = ply:GetInfo("bw_mm_creation_item", "error") or "error"
	if id == "error" then return false end

	return basewars.items.spawn(id, ply, res.HitPos, self:getAngles(ply), res.HitNormal)
end

if CLIENT then
	ext.creationItemCVar = CreateClientConVar("bw_mm_creation_item", "error", true, true, "The unique identifier for the selected item you are creating.")
	ext.yawCVar          = CreateClientConVar("bw_mm_creation_yaw", "0", true, true, "The yaw offset of the entity.")
	ext.snapCVar         = GetConVar("gm_snapangles")

	function SWEP:FreezeMovement()
		if not self:GetFireMode() and ext.creationItem and self:GetOwner():KeyDown(IN_USE) then
			return true
		elseif self.clampYawNext then
			local cur = ext.yawCVar:GetFloat()
			local snap = ext.snapCVar:GetFloat()
			cur = math.Round(cur / snap) * snap

			RunConsoleCommand("bw_mm_creation_yaw", cur)
			self.clampYawNext = nil
		end
	end

	function SWEP:Think()
		local owner = self:GetOwner()
		if not self:GetFireMode() and ext.creationItem and owner:KeyDown(IN_USE) then
			local cmd = self:GetOwner():GetCurrentCommand()
			local deg = cmd:GetMouseX() * 0.02

			if math.abs(deg) > 0.001 then
				local cur = ext.yawCVar:GetFloat()
				cur = cur + deg

				RunConsoleCommand("bw_mm_creation_yaw", cur)
				if owner:KeyDown(IN_SPEED) then
					self.clampYawNext = true
				else
					self.clampYawNext = nil
				end
			end
		end

		return BaseClass.Think(self)
	end

	function ext:PostItemsLoaded()
		local id = self.creationItemCVar:GetString()

		self.creationItemId   = id
		self.creationItem     = basewars.items.get(id)
	end

	function ext:setCreationItem(id, dontSwap)
		if not dontSwap then
			local wep = LocalPlayer():GetWeapon("basewars_matter_manipulator")

			if IsValid(wep) then
				input.SelectWeapon(wep)
			end
		end

		self.creationItemId = id
		self.creationItem = basewars.items.get(id)

		RunConsoleCommand("bw_mm_creation_item", id)
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

	function SWEP:cleanupGhostEntity()
		if IsValid(self.csEnt) then self.csEnt:Remove() end
	end

	function SWEP:Holster()
		self:cleanupGhostEntity()

		return BaseClass.Holster(self)
	end

	local function DropToFloor(ent)
		local obb_mins   = ent:OBBMins()
		local obb_maxs   = ent:OBBMaxs()

		local res = util.TraceHull{
			start  = ent:GetPos(),
			endpos = ent:GetPos() - Vector(0, 0, 256),
			filter = ent,
			mins   = obb_mins,
			maxs   = obb_maxs,
		}

		if res.Hit and res.HitTexture ~= "**empty**" then -- .hit is always true :v
			ent:SetPos(res.HitPos)

			return res.HitPos
		end
	end

	local white = Color(255, 255, 255)
	local red   = Color(255, 0  , 0  )

	function SWEP:updateGhostEntity(res, item)
		if self:GetFireMode() or not res then
			self.csEnt:SetNoDraw(true)
			return
		end

		if item then
			self.csEnt:SetNoDraw(false)
			self.csEnt:SetModel(item.model or "models/error.mdl")

			local dot_maxs = res.HitNormal:Dot(self.csEnt:OBBMaxs())
			local dot_mins = res.HitNormal:Dot(self.csEnt:OBBMins())
			local off = math.max(dot_maxs, dot_mins) * res.HitNormal

			local pos = res.HitPos + off
			self.csEnt:SetPos(pos)

			pos = DropToFloor(self.csEnt) or pos
			self.ghostPos = pos

			local owner = self:GetOwner()
			local ang = ext:getAngles(owner)
			self.csEnt:SetAngles(ang)
			self.ghostAngs = ang

			local col = item.color or white
			if not basewars.items.canSpawn(item.item_id, owner, pos, ang) then
				col = red
			end

			self.csEnt:SetColor(Color(col.r, col.g, col.b, 150))
		else
			self.csEnt:SetNoDraw(true)
		end
	end

	cvars.AddChangeCallback("bw_mm_creation_item", function(_, old, new)
		if ext.creationItemId == new then return end

		ext:setCreationItem(new, true)
	end, ext:getTag())

	function ext:BW_SelectedEntityForPurchase(id)
		self:setCreationItem(id, false)
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

	local function drawString(str, font, x, y, col, a, b)
		return draw.text(str, font, x, y, col, a, b)
	end

	function SWEP:renderCreate(trace, item, w, h)
		local x, y = 2, 2

		if not item then
			y = y + drawString("No item selected", largeFont, x, y)
			y = y + drawString("HOLD " .. input.LookupBinding("+menu"):upper() .. " AND SELECT AN ITEM", smallFont, x, y)
			y = y + drawString("FROM THE BASEWARS CATEGORY", xsmallFont, x, y)

			y = h - 2

			y = y - drawString("Reload to toggle mode!", smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
		else
			self.icon:PaintManual()

			y = y + drawString(item.name, mediumFont, x, y)
			y = y + drawString(item.cost > 0 and string.format("Cost: %s", basewars.currency(item.cost)) or "Cost: FREE", smallFont, x, y)

			y = h - 2

			local res, err = basewars.items.canSpawn(item.item_id, self:GetOwner(), self.ghostPos, self.ghostAngs)
			err = err or "Spawn OK!"

			local col = res and Color(0, 200, 0) or Color(200, 0, 0)
			y = y - drawString(err, xsmallFont, x, y, col, nil, TEXT_ALIGN_BOTTOM)
		end
	end

	function SWEP:renderDestroy(trace, item, w, h)
		local x, y = 2, 2

		local ent = trace and trace.Entity or nil
		if not IsValid(ent) then
			y = y + drawString("Deconstructor", largeFont, x, y)
			y = y + drawString("AIM AT AN ENTITY TO SEE MORE", smallFont, x, y)
			y = y + drawString("INFORMATION AND DESTROY IT", xsmallFont, x, y)

			y = h - 2

			y = y - drawString("Reload to toggle mode!", smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
		else
			local value    = basewars.items.getSaleValue(ent, self:GetOwner(), false)
			local res, err = basewars.items.canSell(ent, self:GetOwner())

			if value or res or ent.isBasewarsEntity then
				value = value or 0

				y = y + drawString(basewars.getEntPrintName(ent), mediumFont, x, y)
				y = y + drawString(value > 0 and string.format("Return: %s", basewars.currency(value)) or "Return: NONE", smallFont, x, y)

				y = h - 2

				err = res and "Deconstruction OK!" or err or "Access denied!"
				local col = res and Color(0, 200, 0) or Color(200, 0, 0)
				y = y - drawString(err, xsmallFont, x, y, col, nil, TEXT_ALIGN_BOTTOM)

				local spawned_time = CurTime() - ent:GetNW2Int("bw_boughtAt", 0)
				res = spawned_time < 10 -- TODO: config, see items.lua

				if res then
					y = y - drawString(string.format("Refundable for %.1f more seconds.", 10 - spawned_time), xsmallFont, x, y, Color(200, 240, 200), nil, TEXT_ALIGN_BOTTOM)
				end
			else
				y = y + drawString("Deconstructor", largeFont, x, y)
				y = y + drawString("AIM AT AN ENTITY TO SEE MORE", smallFont, x, y)
				y = y + drawString("INFORMATION AND DESTROY IT", xsmallFont, x, y)

				y = h - 2

				y = y - drawString("Reload to toggle mode!", smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
			end
		end
	end

	function SWEP:RenderScreen()
		local trace = self:trace()
		local item = ext.creationItem

		self:createGhostEntity()
		self:updateGhostEntity(trace, item)

		local w, h = 1024, 576

		if item and self.lastModelUpdate ~= item.model then
			if not self.icon then
				self.icon = vgui.Create("SpawnIcon")
			end
				self.icon:SetSize(h / 2, h / 2)
				self.icon:SetPos (w - h / 2 - 2, h / 4)
				self.icon:SetPaintedManually(true)
				self.icon:SetModel(item.model)
				self.icon:SetMouseInputEnabled(false)
			self.lastModelUpdate = item.model
		end

		render.PushRenderTarget(rtTex)
			render.ClearDepth()
			render.Clear(50, 50, 50, 255)

			cam.Start2D()
				if self:GetFireMode() then self:renderDestroy(trace, item, w, h) else self:renderCreate(trace, item, w, h) end
			cam.End2D()

		render.PopRenderTarget()
		render.Clear(0, 0, 0, 255)

		ext.rtMat:SetTexture("$basetexture", rtTex)
	end

	local col  = Color(200, 200, 200, 255)
	local col2 = Color(255, 100, 100, 255)
	local crosshairMat = surface.GetTextureID("sprites/hud/v_crosshair2")

	function SWEP:DoDrawCrosshair(x, y)
		local fire_mode = self:GetFireMode()

		surface.SetTexture(crosshairMat)
		surface.SetDrawColor(fire_mode and col2 or col)

		surface.DrawTexturedRectRotated(x, y, 32, 32, 90)
		surface.DrawTexturedRectRotated(x, y, 32, 32, 0)

		return true
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
	["screen"]       = { type = "Model", model = "models/props_phx/rt_screen.mdl", bone = "Base", rel = "", pos = Vector(2.7, 2.2, 7.792), angle = Angle(-90, 90, 0), size = Vector(0.08, 0.08, 0.08), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {}, submaterial = { [1] = ext.rtMatName } },
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
		tr.endpos = tr.start + ply:GetAimVector() * 512
		tr.filter = ply

		util.TraceLine(tr)

		if not trace_res.Hit then return false end
		if trace_res.Entity and trace_res.Entity:IsPlayer() then return false end

		return trace_res
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

	effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetStart(self.Owner:GetShootPos())
		effectdata:SetAttachment(1)
		effectdata:SetEntity(self)
	util.Effect("ToolTracer", effectdata)
end

function SWEP:PrimaryAttack()
	if not self:trace() then return end

	local res
	if self:GetFireMode() then
		res = self:Attack2(trace_res)
	else
		res = self:Attack1(trace_res)
	end
	if res then
		self:DoShootEffect(trace_res.HitPos, trace_res.HitNormal, trace_res.Entity, trace_res.PhysicsBone, IsFirstTimePredicted())
	else
		self:EmitSound(self.failSound)
	end

	self:SetNextPrimaryFire(CurTime() + 0.6)
end

function SWEP:Attack1(tr_res)
	return ext:buyItem(self:GetOwner(), tr_res)
end

function SWEP:Attack2(tr_res)
	if IsValid(tr_res.Entity) then
		return basewars.items.sell(tr_res.Entity, self:GetOwner())
	else
		return false
	end
end

function SWEP:SecondaryAttack()
end
