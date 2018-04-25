AddCSLuaFile()

SWEP.Base          = "weapon_base"
DEFINE_BASECLASS     "weapon_base"

SWEP.PrintName     = "Basewars 2018 Construction Kit Base"

SWEP.Author        = GAMEMODE.Author .. ", Clavus"
SWEP.Contact       = GAMEMODE.Website
SWEP.Purpose       = ""
SWEP.Instructions  = ""

-- This is a cleaned + optimized version of the construction kit
-- base code with several features to allow for eaiser modification

-- New Features:
-- 	SWEP:getElementColor(name)
-- 	element.submaterial
-- 	NO MEMORY LEAKS (models are cleaned up)
-- 	fixes
-- 	hl2 styled weaponselection icons

-- Original by Clavus
-- https://github.com/Clavus/SWEP_Construction_Kit

function SWEP:getElementColor(name)

end

function SWEP:Initialize()
	if self.SetHoldType then
		self:SetHoldType(self.HoldType or "normal")
	else
		self:SetWeaponHoldType(self.HoldType or "normal")
	end

	if CLIENT then
		self:ckInit()
	end
end

function SWEP:Holster(wep)
	local owner = self:GetOwner()
	if CLIENT and IsValid(owner) and IsFirstTimePredicted() then
		local vm = owner:GetViewModel()

		if IsValid(vm) then
			self:ckResetBonePositions(vm)

			if IsValid(wep) then
				self:ckSetupViewModel(vm, wep.ShowViewModel ~= false)
			else
				self:ckSetupViewModel(vm, true)
			end
		end
	end

	return true
end

function SWEP:Deploy()
	local owner = self:GetOwner()

	if CLIENT and IsValid(owner) and IsFirstTimePredicted() then
		local vm = owner:GetViewModel()

		if IsValid(vm) then
			self:ckResetBonePositions(vm)
			self:ckSetupViewModel(vm, self.ShowViewModel ~= false)
		end
	end

	return true
end

function SWEP:OnRemove()
	if CLIENT then
		self:ckCleanupModels()
	end

	self:Holster()
end

function SWEP:ShouldDropOnDie()
	return false
end

if CLIENT then
	surface.CreateFont("bw_ck_base_weapon_selection_blur", {
		font = "HalfLife2",
		size = 128,
		blursize = 9,
		scanlines = 4,
	})

	surface.CreateFont("bw_ck_base_weapon_selection", {
		font = "HalfLife2",
		size = 128,
	})

	function SWEP:DrawWeaponSelection(x, y, w, h, a)
		if self.weaponSelectionLetter then
			draw.SimpleText(self.weaponSelectionLetter, self.weaponSelectionFontBlur or "bw_ck_base_weapon_selection_blur", x + w / 2, y + h / 2, Color(200, 200, 200, math.max(a - 8, 0)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(self.weaponSelectionLetter, self.weaponSelectionFont     or "bw_ck_base_weapon_selection",      x + w / 2, y + h / 2, Color(200, 200, 200, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			self:PrintWeaponInfo(x + w + 20, y + h * 0.95, a)
		else
			BaseClass.DrawWeaponSelection(self, x, y, w, h, a)
		end
	end

	local fullCopy
	function fullCopy(tab)
		if not tab then return nil end

		local res = {}
		for k, v in pairs(tab) do
			if type(v) == "table" then
				res[k] = fullCopy(v)
			elseif type(v) == "Vector" then
				res[k] = Vector(v.x, v.y, v.z)
			elseif type(v) == "Angle" then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end

		return res
	end

	local white = Color(255,255,255,255)
	local trans = Color(255,255,255,1  )

	function SWEP:ckSetupViewModel(vm, show)
		if show then
			vm:SetColor(white)
			vm:SetMaterial("")
		else
			vm:SetColor(trans)
			vm:SetMaterial("vgui/hsv")
		end
	end

	function SWEP:ckInit()
		self.VElements         = fullCopy(self.VElements)
		self.WElements         = fullCopy(self.WElements)
		self.ViewModelBoneMods = fullCopy(self.ViewModelBoneMods)
		self:ckCreateModels(self.VElements)
		self:ckCreateModels(self.WElements)
		self._ckModelsActive   = true

		local owner = self:GetOwner()
		if IsValid(owner) and owner:GetActiveWeapon() == self then
			local vm = owner:GetViewModel()

			if IsValid(vm) then
				self:ckResetBonePositions(vm)
				self:ckSetupViewModel(vm, self.ShowViewModel ~= false)
			end
		end
	end

	function SWEP:ckDeleteModels(tab)
		if not tab then return end

		-- Delete our models, they aren't garbage collected.
		for _, v in pairs(tab) do
			local model = v.modelEnt

			if v.type == "Model" and IsValid(model) then
				v.createdModel = nil
				v.modelEnt = nil

				model:Remove()
			end
		end
	end

	function SWEP:ckCleanupModels()
		self:ckDeleteModels(self.VElements)
		self:ckDeleteModels(self.WElements)
		self._ckModelsActive = false
	end

	local function createModel(self, v, model)
		if
			(not IsValid(v.modelEnt) or v.createdModel ~= model) and
			model:match("%.mdl$") and (file.Exists(model, "GAME") or util.IsValidModel(model))
		then
			v.modelEnt = ClientsideModel(model, RENDERGROUP_VIEWMODEL)

			if IsValid(v.modelEnt) then
				v.modelEnt:SetPos(self:GetPos())
				v.modelEnt:SetAngles(self:GetAngles())
				v.modelEnt:SetParent(self)
				v.modelEnt:SetNoDraw(true)
				v.createdModel = model
			else
				v.modelEnt = nil
			end
		end
	end

	local function createSpite(self, v, sprite)
		if
			(not v.spriteMaterial or v.createdSprite ~= sprite)
			and file.Exists("materials/" .. sprite .. ".vmt", "GAME")
		then
			local name = sprite .. "-"
			local params = {
				["$basetexture"] = sprite
			}

			-- make sure we create a unique name based on the selected options
			local tocheck = {"nocull", "additive", "vertexalpha", "vertexcolor", "ignorez"}
			for _, j in pairs(tocheck) do
				if v[j] then
					params["$" .. j] = 1
					name = name .. "1"
				else
					name = name .. "0"
				end
			end

			v.createdSprite = sprite
			v.spriteMaterial = CreateMaterial(name, v.shader or "UnlitGeneric", params)
		end
	end

	function SWEP:ckCreateModels(tab)
		if not tab then return end

		-- Create the clientside models here because they are entities and only need creating once
		for _, v in pairs(tab) do
			local model = v.model
			local sprite = v.sprite

			if     v.type == "Model"  and model  and model ~= ""  then
				createModel(self, v, model )
			elseif v.type == "Sprite" and sprite and sprite ~= "" then
				createSpite(self, v, sprite)
			end
		end
	end

	function SWEP:ckRenderElement(name, v, pos, ang)
		local model  = v.modelEnt
		local sprite = v.spriteMaterial

		if v.type == "Model" and IsValid(model) then
			model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)

			ang = ang * 1
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			model:SetAngles(ang)

			local matrix = Matrix()
				matrix:Scale(v.size)
			model:EnableMatrix("RenderMultiply", matrix)

			if v.material == "" then
				model:SetMaterial("")
			elseif model:GetMaterial() ~= v.material then
				model:SetMaterial(v.material)
			end

			if v.skin and v.skin ~= model:GetSkin() then
				model:SetSkin(v.skin)
			end

			if v.bodygroup then
				for g, b in pairs(v.bodygroup) do
					if model:GetBodygroup(g) ~= b then
						model:SetBodygroup(g, b)
					end
				end
			end

			if v.submaterial then
				for m, n in pairs(v.submaterial) do
					if model:GetSubMaterial(m) ~= n then
						model:SetSubMaterial(m, n)
					end
				end
			end

			if v.surpresslightning then
				render.SuppressEngineLighting(true)
			end

				local color = self:getElementColor(name) or v.color
				render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
				render.SetBlend(color.a / 255)

					model:DrawModel()

				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)

			if v.surpresslightning then
				render.SuppressEngineLighting(false)
			end
		elseif v.type == "Sprite" and sprite then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			local color = self:getElementColor(name) or v.color

			render.SetMaterial(sprite)
			render.DrawSprite(drawpos, v.size.x, v.size.y, color)
		elseif v.type == "Quad" and v.draw_func then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z

			ang = ang * 1
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

			cam.Start3D2D(drawpos, ang, v.size)
				v.draw_func(self)
			cam.End3D2D()
		end
	end

	function SWEP:ckGenerateRenderOrder(tbl, to)
		for k, v in pairs(tbl) do
			if v.type == "Model" then
				table.insert(to, 1, k)
			elseif v.type == "Sprite" or v.type == "Quad" then
				table.insert(to, k)
			end
		end
	end

	function SWEP:PreDrawViewModel(vm)
		self:ckSetupViewModel(vm, self.ShowViewModel ~= false)
	end

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		local owner = self:GetOwner()
		local vm = owner:GetViewModel()
		if not IsValid(vm) then return end

		self:ckSetupViewModel(vm, true)

		if not self.VElements then return end

		if not self._ckModelsActive then -- fix for onremove being called at the wrong time
			self:ckInit()
		end

		self:ckUpdateBonePositions(vm)
		if not self.vRenderOrder then
			self.vRenderOrder = {}
			self:ckGenerateRenderOrder(self.VElements, self.vRenderOrder)
		end

		for _, name in ipairs(self.vRenderOrder) do
			local v = self.VElements[name]
			if not v then self.vRenderOrder = nil break end

			if v.bone and not v.hide then
				local pos, ang = self:ckGetBoneOrientation(self.VElements, v, vm)

				if pos then
					self:ckRenderElement(name, v, pos, ang)
				end
			end
		end
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		if self.ShowWorldModel ~= false then
			self:DrawModel()
		end

		if not self.WElements then return end

		if not self._ckModelsActive then -- fix for onremove being called at the wrong time
			self:ckInit()
		end

		if not self.wRenderOrder then
			self.wRenderOrder = {}
			self:ckGenerateRenderOrder(self.WElements, self.wRenderOrder)
		end

		local bone_ent = self:GetOwner()
		if not IsValid(bone_ent) then
			bone_ent = self
		end

		for _, name in ipairs(self.wRenderOrder) do
			local v = self.WElements[name]
			if not v then self.wRenderOrder = nil break end

			if not v.hide then
				local pos, ang
				if v.bone then
					pos, ang = self:ckGetBoneOrientation(self.WElements, v, bone_ent)
				else
					pos, ang = self:ckGetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand")
				end

				if pos then
					self:ckRenderElement(name, v, pos, ang)
				end
			end
		end
	end

	function SWEP:ckGetBoneOrientation(basetab, tab, ent, bone_override)
		local bone
		local pos, ang = Vector(), Angle()

		if tab.rel and tab.rel ~= "" then
			local v = basetab[tab.rel]
			if not v then return end

			pos, ang = self:ckGetBoneOrientation(basetab, v, ent)
			if not pos then return end

			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
		else
			bone = ent:LookupBone(bone_override or tab.bone)
			if not bone then return end

			local m = ent:GetBoneMatrix(bone)
			if m then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end

			local owner = self:GetOwner()
			if
				IsValid(owner) and owner:IsPlayer() and
				ent == owner:GetViewModel() and
				self.ViewModelFlip
			then
				ang.r = -ang.r
			end
		end

		return pos, ang
	end

	local hasGarryFixedBoneScalingYet = false

	local vec1 = Vector(1, 1, 1)
	local vec0 = Vector()
	local ang0 = Angle()

	local identity_bone = {
		scale = vec1,
		pos = vec0,
		angle = ang0,
	}

	function SWEP:ckUpdateBonePositions(vm)
		local bone_mods = self.ViewModelBoneMods
		if not bone_mods then
			return self:ckResetBonePositions(vm)
		end

		local count = vm:GetBoneCount()
		if not count or count == 0 then return end

		-- workaround
		if not hasGarryFixedBoneScalingYet then
			for i = 0, count do
				local bonename = vm:GetBoneName(i)

				if not bone_mods[bonename] then
					bone_mods[bonename] = identity_bone
				end
			end
		end

		for name, v in pairs(bone_mods) do
			local bone = vm:LookupBone(name)

			if bone then
				local scale = Vector(v.scale.x, v.scale.y, v.scale.z)

				-- workaround
				if not hasGarryFixedBoneScalingYet then
					local total_scale = Vector(1, 1, 1)

					local current_bone = vm:GetBoneParent(bone)
					while current_bone >= 0 do
						local parent_scale = bone_mods[vm:GetBoneName(current_bone)].scale
						total_scale = total_scale * parent_scale

						current_bone = vm:GetBoneParent(current_bone)
					end

					scale = scale * total_scale
				end

				if vm:GetManipulateBoneScale(bone) ~= scale then
					vm:ManipulateBoneScale(bone, scale)
				end
				if vm:GetManipulateBoneAngles(bone) ~= v.angle then
					vm:ManipulateBoneAngles(bone, v.angle)
				end
				if vm:GetManipulateBonePosition(bone) ~= v.pos then
					vm:ManipulateBonePosition(bone, v.pos)
				end
			end
		end
	end

	function SWEP:ckResetBonePositions(vm)
		local count = vm:GetBoneCount()
		if not count or count == 0 then return end

		for i = 0, count do
			vm:ManipulateBoneScale   (i, vec1)
			vm:ManipulateBoneAngles  (i, ang0)
			vm:ManipulateBonePosition(i, vec0)
		end
	end
end
