-- TODO: Refactor how actions are handled so that it can
-- display an informational text when actions are available

local ext = basewars.createExtension"entity-hud"

do return end

ext.opNameToCode = {
	connect = {1, "Connect"},
	disconnect = {2, "Disconnect"},
}

if SERVER then
	util.AddNetworkString(ext:getTag())

	local function getCoreForEntity(ent)
		for k, v in ipairs(basewars.basecore.getList()) do
			if v:encompassesEntity(ent) then
				return v
			end
		end
	end

	ext.operations = {
		[1] = {
			func = function(ent)
				local core = getCoreForEntity(ent)
				if core:networkContainsEnt(ent) then return false, "Entity already connected!" end

				core:attachEntToNetwork(ent)
				return true
			end
		},

		[2] = {
			func = function(ent)
				local core = getCoreForEntity(ent)
				if not core:networkContainsEnt(ent) then return false, "Entity not connected!" end

				core:removeEntFromNetwork(ent)
				return true
			end
		},

		[3] = {
			func = function(core)
				if not core.isCore then return false, "What?" end
				if not core:isActive() and not core:canActivate() then return false, "Unable to start!" end
				if core:isSequenceOngoing() then return false, "Core did not respond to the command!" end

				core:toggle()
				return true
			end
		},
	}

	function ext:respond(ent, ply, suc, msg)
		msg = msg or (suc and "Success!" or "Failure!")

		net.Start(self:getTag())
			net.WriteEntity(ent)
			net.WriteBool(suc)
			net.WriteString(msg)
		net.Send(ply)
	end

	ext.rateLimitTime = 1.5
	ext._rateLimitPlayers = {}

	function ext.readNetwork(_, ply)
		local ent = net.ReadEntity()

		if
			not IsValid(ent) or
			not ent.isPoweredEntity
		then
			return ext:respond(ent, ply, false, "Invalid entity!")
		end

		ext._rateLimitPlayers[ply] = ext._rateLimitPlayers[ply] or CurTime()

		if ext._rateLimitPlayers[ply] > CurTime() then return ext:respond(ent, ply, false, "Interacting too fast!") end
		ext._rateLimitPlayers[ply] = CurTime() + ext.rateLimitTime

		local method = net.ReadUInt(4)
		local op = ext.operations[method]

		if method == 0 then
			method = net.ReadUInt(8)

			op = ent.coreControlOperations and ent.coreControlOperations[method]
			if not op then return ext:respond(panel, ply, false, "Invalid custom method!") end
		elseif not op then
			return ext:respond(ent, ply, false, "Invalid method!")
		end

		return ext:respond(ent, ply, op.func(ent, ply))
	end

else

-- CLIENT

	function ext:commitActionRaw(ent, action)
		net.Start(self:getTag())
			net.WriteEntity(ent)
			net.WriteUInt(action, 4)
		net.SendToServer()
	end

	function ext:commitAction(ent, action)
		local method = self.opNameToCode[action]
		if not method then
			if ent and ent.coreControlOpNameToCode and ent.coreControlOpNameToCode[action] and ent.coreControlOpNameToCode[action][1] then
				net.Start(self:getTag())
					net.WriteEntity(ent)
					net.WriteUInt(0, 4)
					net.WriteUInt(ent.coreControlOpNameToCode[action][1], 8)
				net.SendToServer()
			end

			return
		end

		net.Start(self:getTag())
			net.WriteEntity(ent)
			net.WriteUInt(method[1], 4)
		net.SendToServer()
	end

	function ext.readNetwork()
		local ent = net.ReadEntity()
		if not IsValid(ent) then print("???") return end

		local success = net.ReadBool()
		local response = net.ReadString()

		print(success, response)
	end

end

net.Receive(ext:getTag(), ext.readNetwork)

---

if SERVER then return end

if IsValid(basewars._entityPanel) then
	basewars._entityPanel:Remove()
	basewars._entityPanel = nil
end

ext.maxDrawDistance = 200 ^ 2

ext.fonts = {}

ext.outlineColor = Color(0, 0, 0, 200)

ext.titleFont = "BW.EntityPanel.Title.Font"
surface.CreateFont(ext.titleFont, {
	font = "DejaVu Sans",
	size = 18,
	weight = 800
})

ext.infoFont = "BW.EntityPanel.InfoLabel.Font"
surface.CreateFont(ext.infoFont, {
	font = "DejaVu Sans",
	size = 16
})

ext.subtitleFont = "BW.EntityPanel.Subtitle.Font"
surface.CreateFont(ext.subtitleFont, {
	font = "DejaVu Sans",
	size = 12
})

ext.subtitleFontBold = "BW.EntityPanel.Subtitle.Font.Bold"
surface.CreateFont(ext.subtitleFontBold, {
	font   = "DejaVu Sans",
	size   = 12,
	weight = 800
})

-- ext.fonts.actionButton = "BW.EntityPanel.Action.Button.Font"
ext.fonts.actionButton = ext.titleFont

function ext:PostDrawTranslucentRenderables()
	local panel = basewars._entityPanel
	if not IsValid(panel) then
		panel                 = vgui.Create("BW.EntityPanel")
		basewars._entityPanel = panel
	end

	local ply = LocalPlayer()
	local ent = ply:GetEyeTraceNoCursor().Entity

	if IsValid(ent) then
		if not ent.getStructureInformation then
			ent = ent:GetParent()
		end

		if ent.getStructureInformation then
			local needsUpdate
			if panel.ent and panel.ent ~= ent then
				needsUpdate = true
			end

			panel.ent    = ent
			panel.entPos = ent:LocalToWorld(ent:OBBCenter())

			local plyPos = ply:GetPos()
			local entPos = ent:GetPos()

			if plyPos:DistToSqr(entPos) <= self.maxDrawDistance then
				if not panel.prepared or needsUpdate then
					panel:hoverStart(ent)
				end

				panel:size()
			else
				panel:hoverEnd()
			end
		else
			panel:hoverEnd()
		end
	else
		panel:hoverEnd()
	end

	if panel.entPos then
		cam.Start3D()

			local panelPos = panel.entPos:ToScreen()
			panel:SetPos(panelPos.x - panel:GetWide() / 2, panelPos.y - panel:GetTall() / 2)

		cam.End3D()
	end
end

function ext:OnContextMenuOpen()
	local panel = basewars._entityPanel

	if IsValid(panel) and panel.prepared and panel.ent and panel.ent.isBasewarsEntity then
		panel.open = true
		panel:expand()
		panel:MakePopup()
	end
end

function ext:OnContextMenuClose()
	local panel = basewars._entityPanel

	if IsValid(panel) then
		panel.open = false
		panel:collapse()
		panel:SetMouseInputEnabled(false)
		panel:SetKeyboardInputEnabled(false)
	end
end

do -- BW.EntityPanel
	local PANEL = {}

	function PANEL:Init()
		self.main = vgui.Create("BW.EntityPanel.Main", self)

		self.actions = vgui.Create("BW.EntityPanel.Actions", self)
		self.actions:SetSize(0, 0)

		self:hoverEnd()
	end

	function PANEL:PerformLayout(w, h)
		self.main:size()
	end

	function PANEL:Paint()
		if self.prepared then
			local main, actions = self.main, self.actions

			local mw, aw  = main:GetWide(), actions._w
			local mh, ah  = main:GetTall(), actions._h
			local mw1     = mw + 8

			local w  = mw1 + aw
			local h  = math.max(mh, ah)
			local h2 = h / 2

			main:SetPos(0, h2 - mh / 2)
			actions:SetPos(mw1, h2 - ah / 2)

			if self:GetWide() ~= w then self:SetWide(w) end
			if self:GetTall() ~= h then self:SetTall(h) end
		end
	end

	function PANEL:hoverStart(ent)
		self.main:prepare(ent)
		self.actions:prepare(ent)

		if self.open then self:expand() end

		self.prepared = true
		self:InvalidateLayout(true)
	end

	function PANEL:expand()
		self.actions:expand()
	end

	function PANEL:collapse()
		self.actions:collapse()
	end

	function PANEL:hoverEnd()
		if not self.prepared then return end

		self:size()
		self.main:fadeOut()
		self.actions:fadeOut()
		self.prepared = false
	end

	function PANEL:size()
		self:SetSize(self.main:GetWide() + self.actions:GetWide() + 8, math.max(self.main:GetTall(), self.actions:GetTall()))
	end

	vgui.Register("BW.EntityPanel", PANEL, "EditablePanel")
end

do -- BW.EntityPanel.AnimatedPanel
	local PANEL = {}

	local fadeTime = 0.2

	function PANEL:fadeIn()
		self:SetAlpha(1)
		self:startFade(255)
	end

	function PANEL:fadeOut()
		self:startFade(0)
	end

	function PANEL:startFade(target)
		if self:GetAlpha() == target then return end

		self.fromAlpha   = self:GetAlpha()
		self.targetAlpha = target
		self.target      = CurTime() + fadeTime

		self:Show()
	end

	function PANEL:Think()
		local from, to, target = self.fromAlpha, self.targetAlpha, self.target
		if target then
			if to ~= self:GetAlpha() then
				self:SetAlpha(Lerp(1 - ((target - CurTime()) / fadeTime), from, to))
				if self:GetAlpha() == 0 then self:Hide() end
			end
		end
	end

	vgui.Register("BW.EntityPanel.AnimatedPanel", PANEL, "EditablePanel")
end

do -- BW.EntityPanel.Main
	local PANEL = {}

	function PANEL:Init()
		self.title = vgui.Create("BW.EntityPanel.Title", self)
		self.infoContainer = vgui.Create("BW.EntityPanel.InfoContainer", self)
	end

	local function safeUpdate(panel)
		if IsValid(panel.ent) then
			panel:update()
		end
	end

	function PANEL:PerformLayout(w, h)
		safeUpdate(self.title)
		self.title:size()
		self.title:SetPos(16, 16)

		safeUpdate(self.infoContainer)
		self.infoContainer:size()
		self.infoContainer:SetPos(16, self.title:GetTall() + 16 + 4)
	end

	function PANEL:prepare(ent)
		self.title:setEntity(ent)
		self.title:update()
		self.infoContainer:setEntity(ent)
		self.infoContainer:update()
		self:InvalidateLayout(true)
		self:fadeIn()
	end

	function PANEL:size()
		self:SetWide(math.max(self.title:GetWide(), self.infoContainer:GetWide()) + 16 + 16)
		self:SetTall(self.title:GetTall() + self.infoContainer:GetTall() + 4 + 16 + 16)
	end


	function PANEL:Paint(w, h)
		surface.SetDrawColor(10, 10, 10, 100)
		surface.DrawRect(0, 0, w, h)
	end

	vgui.Register("BW.EntityPanel.Main", PANEL, "BW.EntityPanel.AnimatedPanel")
end

local function _updateThink(self, t)
	if self:IsVisible() then
		if IsValid(self.ent) then
			if self._nextUpdate < CurTime() then
				self._nextUpdate = CurTime() + t
				self:update()
			end
		end
	else
		self._nextUpdate = 0
	end
end

local function updateThink(t)
	return function(self)
		_updateThink(self, t)
	end
end

do -- BW.EntityPanel.Title
	local PANEL = {}

	function PANEL:Init()
		self._nextUpdate = 0
		self.expanded    = false
	end

	PANEL.Think = updateThink(0.1)

	function PANEL:setEntity(ent)
		self.ent = ent
	end

	function PANEL:update()
		local ent = self.ent

		local info = self.info or {}

		surface.SetFont(ext.titleFont)
		info[1]                = {ent.PrintName or ""}
		info[1][2], info[1][3] = surface.GetTextSize(info[1][1])

		if ent.isUpgradableEntity then
			surface.SetFont(ext.subtitleFontBold)
			info[2]                = {"LV "}
			info[2][2], info[2][3] = surface.GetTextSize("LV ")
			info[3]                = {"XP "}
			info[3][2], info[3][3] = surface.GetTextSize("XP ")

			surface.SetFont(ext.subtitleFont)
			info[4] = {basewars.nformat(ent:getUpgradeLevel() or 0) .. " "}
			info[4][2], info[4][3] = surface.GetTextSize(info[4][1])
			info[5] = {basewars.nformat(ent:getXP() or 0) .. " "}
			info[5][2], info[5][3] = surface.GetTextSize(info[5][1])
		else
			info[2] = nil
		end

		self.info = info

		self:size()
		self:InvalidateParent()
	end

	function PANEL:calcSize()
		local info = self.info

		if info then
			if info[2] then
				return math.max(
					info[1][2],
					info[2][2] +
					info[3][2] +
					info[4][2] +
					info[5][2]
				),  info[1][3] + 2 + math.max(
					info[2][3],
					info[3][3]
				)
			else
				return info[1][2], info[1][3]
			end
		end
	end

	function PANEL:size()
		self:SetSize(self:calcSize())
	end

	function PANEL:Paint(w, h)
		local info = self.info
		if not info then return end

		surface.SetFont(ext.titleFont)
		surface.SetTextPos(0, 0)
		surface.SetTextColor(255, 255, 255)
		surface.DrawText(info[1][1])

		if info[2] then
			local y = info[1][3] + 2

			surface.SetFont(ext.subtitleFontBold)
			surface.SetTextPos(0, y)
			surface.SetTextColor(255, 255, 255)
			surface.DrawText(info[2][1])

			local i22, i32 = info[2][2], info[3][2]
			local i22i32   = i22 + i32
			surface.SetTextPos(i22i32, y)
			surface.DrawText(info[3][1])

			surface.SetFont(ext.subtitleFont)
			surface.SetTextPos(i22, y)
			surface.DrawText(info[4][1])

			surface.SetTextPos(i22i32 + info[3][2], y)
			surface.DrawText(info[5][1])
		end
	end

	vgui.Register("BW.EntityPanel.Title", PANEL, "EditablePanel")
end

do -- BW.EntityPanel.InfoContainer
	local PANEL = {}

	function PANEL:Init()
		self.panels      = {}
		self._nextUpdate = 0
	end

	function PANEL:setEntity(ent)
		self.ent = ent
	end

	function PANEL:update()
		self:buildInfo(self.ent:getStructureInformation())
	end

	PANEL.Think = updateThink(1)

	function PANEL:buildInfo(info_t)
		if not info_t then return end -- TODO: Needs to not display

		local n      = #info_t
		local panels = self.panels

		local w, h = 0, 0

		for i = 1, n do
			local panel             = panels[i]
			local name, info, color = unpack(info_t[i])

			if not IsValid(panel) then
				panel     = vgui.Create("BW.EntityPanel.InfoLabel", self)
				panels[i] = panel

				panel.y = h
			end

			if panel:setName(name) or panel:setInfo(info) then
				local _w, _h = panel:calcSize()

				panel:SetWide(_w)
				panel:SetTall(_h)
			end


			w = math.max(w, panel:GetWide())
			h = h + panel:GetTall() + 1

			panel:setColor(color)
		end

		if panels[n + 1] then
			for i = #panels, n + 1, -1 do
				local panel = panels[i]
				if IsValid(panel) then
					panel:Remove()
				end
				panels[i] = nil
			end
		end

		self.w = w
		self.h = h - 1
	end

	function PANEL:size()
		self:SetSize(self.w or 0, self.h or 0)
	end

	vgui.Register("BW.EntityPanel.InfoContainer", PANEL, "EditablePanel")
end

local function rgbToHSV(c)
	local r, g, b = c.r / 255, c.g / 255, c.b / 255

	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then s = 0 else s = d / max end

	if max == min then
		h = 0 -- achromatic
	else
		if max == r then
		h = (g - b) / d
		if g < b then h = h + 6 end
		elseif max == g then h = (b - r) / d + 2
		elseif max == b then h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h * 360, s, v, c.a
end


do -- BW.EntityPanel.InfoLabel
	local PANEL = {}

	function PANEL:Init()
		self.name  = ""
		self.info  = ""
		self.color = Color(255, 255, 255)
	end

	function PANEL:setName(name)
		if self.name ~= name then
			self.name = name
			self:InvalidateLayout()
			return true
		end
	end

	function PANEL:setInfo(info)
		info = tostring(info)

		if self.info ~= info then
			self.info = info
			self:InvalidateLayout()
			return true
		end
	end

	function PANEL:setColor(color)
		local h, s, v = rgbToHSV(color)
		self.color = HSVToColor(h, s, math.Clamp(v, 0.5, 1))
	end

	function PANEL:calcSize()
		surface.SetFont(ext.infoFont)
		return surface.GetTextSize(self.name .. ": " .. self.info)
	end

	function PANEL:Paint(w, h)
		surface.SetFont(ext.infoFont)

		local name, info = self.name .. ": ", self.info
		local tw         = surface.GetTextSize(name)

		surface.SetTextColor(255, 255, 255)
		surface.SetTextPos(0, 0)
		surface.DrawText(name)

		draw.textOutlinedLT(info, ext.infoFont, tw, 0, self.color, ext.outlineColor) -- TODO:
	end

	vgui.Register("BW.EntityPanel.InfoLabel", PANEL, "EditablePanel")
end

do -- BW.EntityPanel.Actions
	local PANEL = {}

	function PANEL:Init()
		self.panels = {}

		self.w = 0
		self.h = 0
	end

	local function wrap_commit_action(action)
		return function(ent)
			ext:commitAction(ent, action)
		end
	end

	local function getActions(ent)
		if ent.__actions then return ent.__actions end

		if ent.noActions then
			ent.__actions = {}
			return ent.__actions
		end

		if ent.isCore then
			ent.__actions = {
				{"Toggle active", function(e) ext:commitActionRaw(e, 3) end}
			}
			return ent.__actions
		end

		local actions = {}

		if ent.coreControlOpNameToCode then
			for action, t in SortedPairsByMemberValue(ent.coreControlOpNameToCode, 1) do
				actions[#actions + 1] = {
					t[2],
					wrap_commit_action(action)
				}
			end
		end

		for action, t in SortedPairsByMemberValue(ext.opNameToCode, 1) do
			actions[#actions + 1] = {
				t[2],
				wrap_commit_action(action)
			}
		end

		ent.__actions = actions

		return actions
	end

	function PANEL:prepare(ent)
		self:buildActions(getActions(ent), ent)
		self.ent = ent
	end

	function PANEL:buildActions(actions, ent)
		local panels = self.panels

		local w, h = 0, 8

		local n = #actions

		for i = 1, n do
			local action  = actions[i]
			local name, f = action[1], action[2]

			local panel = panels[i]
			if not IsValid(panel) then
				panel = vgui.Create("BW.EntityPanel.Actions.Button", self)
				panels[i] = panel
			end

			panel:setText(name)
			panel:setFunction(f)
			panel:setEntity(ent)
			panel:SetPos(8, h)
			panel:SetSize(panel:calcSize())

			w = math.max(w, panel:GetWide())
			h = h + panel:GetTall() + 2
		end

		if panels[n + 1] then
			for i = #panels, n + 1, -1 do
				local panel = panels[i]
				if IsValid(panel) then
					panel:Remove()
				end
				panels[i] = nil
			end
		end

		self._w = w + 16
		self._h = h + 16 - 8
	end

	function PANEL:expand()
		self:Show()
		self:fadeIn()
		self:SetTall(self._h)
		self:InvalidateParent()
		self:SizeTo(self._w, -1, 0.15, 0, -1, function() self:Show() end)
	end

	function PANEL:collapse()
		self:Show()
		self:fadeOut()
		self:SizeTo(0, -1, 0.15, 0, -1, function() end)
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(10, 10, 10, 100)
		surface.DrawRect(0, 0, w, h)
	end

	vgui.Register("BW.EntityPanel.Actions", PANEL, "BW.EntityPanel.AnimatedPanel")
end

do -- BW.EntityPanel.Actions.Button
	local PANEL = {}

	function PANEL:Init()
		self.text = ""
	end

	function PANEL:setText(text)
		self.text = text
		self:InvalidateLayout()
	end

	function PANEL:setFunction(f)
		self.func = f
	end

	function PANEL:setEntity(ent)
		self.ent = ent
	end

	function PANEL:calcSize()
		surface.SetFont(ext.fonts.actionButton)
		local w, h = surface.GetTextSize(self.text)
		return w + 4, h + 2
	end

	function PANEL:Paint(w, h)
		local hover = self:IsHovered()
		local down  = hover and input.IsMouseDown(MOUSE_LEFT)

		if down then
			surface.SetDrawColor(255, 255, 255, 100)
		elseif hover then
			surface.SetDrawColor(255, 255, 255, 25)
		else
			surface.SetDrawColor(0, 0, 0, 0)
		end

		surface.DrawRect(0, 0, w, h)

		surface.SetFont(ext.fonts.actionButton)

		local text = self.text
		surface.SetTextPos(3, 3)
		surface.SetTextColor(0, 0, 0)
		surface.DrawText(text)
		surface.SetTextPos(2, 2)
		surface.SetTextColor(255, 255, 255)
		surface.DrawText(text)
	end

	function PANEL:OnMouseReleased(mouse)
		if self.func and mouse == MOUSE_LEFT and self:IsHovered() then
			self.func(self.ent)
		end
	end

	vgui.Register("BW.EntityPanel.Actions.Button", PANEL, "EditablePanel")
end
