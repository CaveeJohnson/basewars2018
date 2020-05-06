local ext = basewars.createExtension"core.matter-manipulator.buy"
local mode = {}

ext.mode = mode
mode.color = Color(200, 200, 200, 255)
mode.name = "Constructor"
mode.instructions = {
	LMB = "Spawn Item",
	E = "Rotate Item",
	["SHIFT+E"] = "Rotate Item (Snapping)",
}

function ext:BW_MatterManipulatorLoadModes(modes)
	table.insert(modes, mode)
end

function ext:getAngles(ply, tr, sticksurf)
	local yaw = tonumber(ply:GetInfoNum("bw_mm_creation_yaw", 0)) or 0
	local snap = tonumber(ply:GetInfoNum("gm_snapangles", 0)) or 0
	if ply:KeyDown(IN_SPEED) then yaw = math.Round(yaw / snap) * snap end

	local ang

	if sticksurf then
		ang = tr.HitNormal:Angle()
	else
		ang = Angle() --res.HitNormal:Angle()
			ang.y = ang.y + yaw
		ang:Normalize()
	end

	return ang
end

function ext:buyItem(ply, res)
	local id = ply:GetInfo("bw_mm_creation_item", "error") or "error"
	if id == "error" then return false end

	local item = basewars.items.get(id)
	if not item then return false end

	return basewars.items.spawn(id, ply, res.HitPos, self:getAngles(ply, res, item.stickToSurface), res.HitNormal)
end

if CLIENT then
	ext.creationItemCVar = CreateClientConVar("bw_mm_creation_item", "error", true, true, "The unique identifier for the selected item you are creating.")
	ext.yawCVar          = CreateClientConVar("bw_mm_creation_yaw", "0", true, true, "The yaw offset of the entity.")
	ext.snapCVar         = GetConVar("gm_snapangles")

	-- actual ext hooks
	function ext:BW_SelectedEntityForPurchase(id)
		self:setCreationItem(id, false)
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

	-- mode functions
	function mode:freezeMovement()
		if ext.creationItem and self:GetOwner():KeyDown(IN_USE) then
			return true
		elseif self.clampYawNext then
			local cur = ext.yawCVar:GetFloat()
			local snap = ext.snapCVar:GetFloat()
			cur = math.Round(cur / snap) * snap

			RunConsoleCommand("bw_mm_creation_yaw", cur)
			self.clampYawNext = nil
		end
	end

	function mode:think(owner)
		if not (ext.creationItem and owner:KeyDown(IN_USE)) then return end

		local cmd = owner:GetCurrentCommand()
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

	local white = Color(255, 255, 255)
	local red   = Color(255, 0  , 0)

	function mode:updateGhostEntity(res)
		local item = ext.creationItem
		if not (res and item) then return end

		self.csEnt:SetNoDraw(false)
		self.csEnt:SetModel(item.model or "models/error.mdl")

		local owner = self:GetOwner()
		local ang = ext:getAngles(owner, res, item.stickToSurface)

		self.csEnt:SetAngles(ang)
		self.ghostAngs = ang

		local min, max = self.csEnt:GetRotatedAABB(self.csEnt:OBBMins(), self.csEnt:OBBMaxs())

		local dot_maxs = res.HitNormal:Dot(min)
		local dot_mins = res.HitNormal:Dot(max)
		local off = math.max(dot_maxs, dot_mins) * res.HitNormal

		local pos = res.HitPos + off + res.HitNormal

		if item.stickToSurface then
			pos = pos - (min + max) / 2
		else
			pos = basewars.dropToFloor(self.csEnt, pos, min, max)
		end

		self.csEnt:SetPos(pos)
		self.ghostPos = pos

		local col = item.color or white
		if not basewars.items.canSpawn(item.item_id, owner, pos, ang) then
			col = red
		end

		self.csEnt:SetColor(Color(col.r, col.g, col.b, 150))
	end

	cvars.AddChangeCallback("bw_mm_creation_item", function(_, old, new)
		if ext.creationItemId == new then return end

		ext:setCreationItem(new, true)
	end, ext:getTag())

	function mode:renderScreen(fonts, trace, w, h)
		local item = ext.creationItem
		local x, y = 2, 2

		if not item then
			y = y + draw.text("No item selected", fonts.largeFont, x, y)
			y = y + draw.text("HOLD " .. input.LookupBinding("+menu"):upper() .. " AND SELECT AN ITEM", fonts.smallFont, x, y)
			y = y + draw.text("FROM THE BASEWARS CATEGORY", fonts.xsmallFont, x, y)

			y = h - 2

			y = y - draw.text("Reload to change mode!", fonts.smallFont, x, y, nil, nil, TEXT_ALIGN_BOTTOM)
		else
			local item_model = item and item.model or "models/error.mdl"
			if not self.icon then
				self.icon = vgui.Create("SpawnIcon")
			end
			if self.lastModelUpdate ~= item_model then
					self.icon:SetSize(h / 2, h / 2)
					self.icon:SetPos (w - h / 2 - 2, h / 4)
					self.icon:SetPaintedManually(true)
					self.icon:SetModel(item_model)
					self.icon:SetMouseInputEnabled(false)
				self.lastModelUpdate = item_model
			end

			self.icon:PaintManual()

			y = y + draw.text(item.name, fonts.mediumFont, x, y)
			y = y + draw.text(item.cost > 0 and string.format("Cost: %s", basewars.currency(item.cost)) or "Cost: FREE", fonts.smallFont, x, y)

			y = h - 2

			local res, err = basewars.items.canSpawn(item.item_id, self:GetOwner(), self.ghostPos, self.ghostAngs)
			err = err or "Spawn OK!"

			local col = res and Color(0, 200, 0) or Color(200, 0, 0)
			y = y - draw.text(err, fonts.xsmallFont, x, y, col, nil, TEXT_ALIGN_BOTTOM)
		end
	end
end

function mode:primaryFire(tr_res)
	local ok = ext:buyItem(self:GetOwner(), tr_res)
	return ok
end
