easylua.StartEntity("basewars_core_controls")

AddCSLuaFile()

ENT.Base = "basewars_power_sub"
ENT.Type = "anim"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Core Control Panel 2: Electic boogaloo"

ENT.Model = "models/props_phx/rt_screen.mdl"

ENT.isControlPanel = true
ENT.isCoreControlPanel = true

ENT.noActions = true

do
	local black = Color(0, 0, 0)
	local red = Color(100, 20, 20)
	local green = Color(20, 100, 20)

	function ENT:getStructureInformation()
		--[[return {
			{
				"Health",
				basewars.nformat(self:Health()) .. "/" .. basewars.nformat(self:GetMaxHealth()),
				self:isCriticalDamaged() and red or black
			},
			{
				"Connected",
				self:validCore(),
				self:validCore() and green or red
			},
		}]]
	end
end

local ext = basewars.createExtension"coreControls"

ext.maxPanelInteractDist = 700 ^ 2

ext.opNameToCode = {
	connect = {1, "Connect"},
	disconnect = {2, "Disconnect"},
}

if SERVER then

util.AddNetworkString(ext:getTag())

ext.operations = {
	[1] = {
		func = function(panel, ent)
			local core = panel:getCore()
			if core:networkContainsEnt(ent) then return false, "Entity already connected!" end

			core:attachEntToNetwork(ent)
			return true
		end,
		ent = true,
	},

	[2] = {
		func = function(panel, ent)
			local core = panel:getCore()
			if not core:networkContainsEnt(ent) then return false, "Entity not connected!" end

			core:removeEntFromNetwork(ent)
			return true
		end,
		ent = true,
	},

	[3] = {
		func = function(panel)
			local core = panel:getCore()
			if not core:isActive() and not core:canActivate() then return false, "Unable to start!" end
			if core:isSequenceOngoing() then return false, "Core did not respond to the command!" end

			core:toggle()
			return true
		end,
		ent = false,
	},
}

function ext:respond(panel, ply, suc, msg)
	msg = msg or (suc and "Success!" or "Failure!")

	net.Start(self:getTag())
		net.WriteEntity(panel)
		net.WriteBool(suc)
		net.WriteString(msg)
	net.Send(ply)
end

ext.rateLimitTime = 1.5
ext._rateLimitPlayers = {}

function ext.readNetwork(_, ply)
	local panel = net.ReadEntity()
	if
		not IsValid(panel) or
		not panel.isCoreControlPanel or
		ply:GetPos():DistToSqr(panel:GetPos()) > ext.maxPanelInteractDist
	then
		return
	end

	if not panel:validCore() then return false, "No core connected!" end
	local core = panel:getCore()

	ext._rateLimitPlayers[ply] = ext._rateLimitPlayers[ply] or CurTime()

	if ext._rateLimitPlayers[ply] > CurTime() then return ext:respond(panel, ply, false, "Interacting too fast!") end
	ext._rateLimitPlayers[ply] = CurTime() + ext.rateLimitTime

	local method = net.ReadUInt(4)
	local op = ext.operations[method]

	local ent
	if (op and op.ent) or method == 0 then
		ent = net.ReadEntity()
		if
			not IsValid(ent) or
			not ent.isPoweredEntity or
			not core:encompassesEntity(ent)
		then
			return ext:respond(panel, ply, false, "Invalid entity!")
		end
	end

	if method == 0 then
		method = net.ReadUInt(8)

		op = ent.coreControlOperations and ent.coreControlOperations[method]
		if not op then return ext:respond(panel, ply, false, "Invalid custom method!") end
	elseif not op then
		return ext:respond(panel, ply, false, "Invalid method!")
	end

	return ext:respond(panel, ply, op.func(panel, ent, ply))
end

else

-- CLIENT

function ext:commitActionRaw(panel, action, ent)
	net.Start(self:getTag())
		net.WriteEntity(panel)
		net.WriteUInt(action, 4)

		if ent then
			net.WriteEntity(ent)
		end
	net.SendToServer()
end

function ext:commitAction(panel, action, ent)
	local method = self.opNameToCode[action]
	if not method then
		if ent and ent.coreControlOpNameToCode and ent.coreControlOpNameToCode[action] and ent.coreControlOpNameToCode[action][1] then
			net.Start(self:getTag())
				net.WriteEntity(panel)
				net.WriteUInt(0, 4)
				net.WriteEntity(ent)
				net.WriteUInt(ent.coreControlOpNameToCode[action][1], 8)
			net.SendToServer()
		end

		return
	end

	net.Start(self:getTag())
		net.WriteEntity(panel)
		net.WriteUInt(method[1], 4)

		if ent then
			net.WriteEntity(ent)
		end
	net.SendToServer()
end

function ext.readNetwork()
	local panel = net.ReadEntity()
	if not IsValid(panel) then return end

	local success = net.ReadBool()
	local response = net.ReadString()

	panel.__temp_text    = response
	panel.__temp_success = success
	panel.__temp_ttime   = CurTime() + 5
end

end

net.Receive(ext:getTag(), ext.readNetwork)



-- entoty

if SERVER then


else


ENT.screenPosOffset = Vector(6.2256209373474, -27.453372955322, 34.882091522217)
ENT.screenW = 550
ENT.screenH = 278

local cursorMat = Material("icon16/cursor.png", "nocull noclamp")
local function cursor(self)
	local inputstate = self:GetInputStateWithinRenderBounds()

	-- If cursor is not within render bounds at all (is not hovering it)
	-- we should not draw a cursor
	if bit.band(inputstate, tdui.FSTATE_HOVERING) == 0 then
		return
	end

	local color, hoverColor, pressColor = self:_GetSkinParams("cursor", "color", "hoverColor", "pressColor")
	if bit.band(inputstate, tdui.FSTATE_JUSTPRESSED) ~= 0 then
		surface.SetDrawColor(hoverColor)
		LocalPlayer():EmitSound("buttons/button16.wav", 75, 100, 0.25)
	elseif bit.band(inputstate, tdui.FSTATE_PRESSING) ~= 0 then
		surface.SetDrawColor(pressColor)
	else
		surface.SetDrawColor(color)
	end

	local cursorSize = math.Round(10 * self:GetUIScale())
	surface.SetMaterial(cursorMat)
	surface.DrawTexturedRect(self._mx - 3, self._my - 1, cursorSize, cursorSize)
end

function ENT:Initialize()
	self.gui = tdui.Create()

	math.randomseed(self:EntIndex())
	self.bgColor  = HSVToColor(math.random(0, 360), math.random(60, 100) / 100, math.random(60, 100) / 100)
	self.boxColor = ColorAlpha(self.bgColor, 255)
end

function ENT:screenParams()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(), 180)

	return self:LocalToWorld(self.screenPosOffset), ang, 0.1
end

ENT.tabsNames = {
	"Entities",
	"Faction",
	"Raids",
	"Settings",
}

ENT.tabs = {}

local color_selected = Color(200, 50, 220, 255)

local function wrap_commit_action(action)
	return function(self, ent)
		ext:commitAction(self, action, ent)
	end
end

function ENT:getActions(ent)
	if ent.__actions then return ent.__actions end

	if ent.noActions then
		ent.__actions = {}
		return ent.__actions
	end

	if ent.isCore then
		ent.__actions = {
			{"Toggle active", function() ext:commitActionRaw(self, 3) end}
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

local color_nosucc = Color(100, 20, 20)
local color_succ = Color(20, 100, 20)

ENT.tabs.Entities  = function(self, p, x, y, w, h)
	local space = x

	p:Text("Entities", "!DejaVu Sans@16", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 16 + space

	local amount_of_entities_shown = math.floor((h - space) / 16) - (self.__temp_text and 1 or 0)
	local display_height = amount_of_entities_shown * 16
	local display_end = y + display_height

	local core = self:getCore()
	local ent_list, ent_total = core:getAreaEnts()

	local display_width = IsValid(self.entitySelected) and w * 0.65 or w
	p:Rect(x, y, display_width, display_height, color_transparent, color_white, 1)

	self.entityScroll = self.entityScroll or 1

	local display_width_corrected = display_width
	if ent_total > amount_of_entities_shown then
		local scroll_width = 16
		display_width_corrected = display_width - scroll_width
		p:Rect(x + display_width_corrected, y, scroll_width, display_height, color_transparent, color_white, 1)

		-- TODO: bollocks here look at slider
	end

	local restore_y = y

	for i = self.entityScroll, math.min(ent_total + 2 - self.entityScroll, amount_of_entities_shown) do
		local ent =  i == 1 and core or ent_list[i - 1]

		if IsValid(ent) and ent ~= self then
			local con = (ent.isCore and ent:isActive()) or (ent.validCore and ent:validCore())

			if p:LeftButton(basewars.getEntPrintName(ent), "!DejaVu Sans@14", x, y, display_width_corrected, 16, ent == self.entitySelected and color_selected) then
				self.entitySelected = ent
			end
			p:Rect(x + display_width_corrected - 12 - space, y + 2, 12, 12, ent.bgColor or (con and color_succ) or color_nosucc)

			y = y + 16
		end
	end

	y = display_end + space * 2

	if self.__temp_text then
		local text = tostring(self.__temp_text)
		local time = CurTime() - self.__temp_ttime
		local succ = self.__temp_success

		if time > 10 then
			self.__temp_text = nil
		end

		p:Text(text, "!DejaVu Sans@14", x, y, succ and color_succ or color_nosucc, TEXT_ALIGN_LEFT)
	end

	if not IsValid(self.entitySelected) then return end

	y = restore_y
	if p:Button("Cancel", "!DejaVu Sans@14", x + display_width - w / 4, y - 16 - space, w / 4, 16) then
		self.entitySelected = nil

		return
	end

	-- tdui queues the render, we are still in 3d until the end
	local time = CurTime()
	self.boxColor.a = (125 + math.sin(time * 4) * 50) * (math.floor(time * 15) % 2 == 0 and 1 or 0.85)

	local ent = self.entitySelected
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	render.SetColorMaterial()
	render.DrawBox(ent:GetPos(), ent:GetAngles(), mins, maxs, self.boxColor, true)

	x = x + display_width + space * 3
	local button_width = w - display_width - space * 6

	for _, data in ipairs(self:getActions(ent)) do
		if p:Button(data[1], "!DejaVu Sans@14", x, y, button_width, 16) then
			data[2](self, ent)
		end
		y = y + 16 + space
	end
end

ENT.tabs.factions_active = function(self, p, x, y, w, h)
	local space = x

	p:Text("sorry, this isn't finished", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	y = y + h - 16 - space
	if p:Button("Leave Faction", "!DejaVu Sans@14", x, y, w - space * 2, 16) then
		basewars.factions.sendEvent("leave")
	end

	if self.baseFaction.hierarchy.owner == LocalPlayer():SteamID64() then
		y = y - 16 - space
		if p:Button("Disband Faction", "!DejaVu Sans@14", x, y, w - space * 2, 16) then
			basewars.factions.sendEvent("disband")
		end
	end
end

ENT.tabs.factions_inactive = function(self, p, x, y, w, h)
	local space = x

	local tw = p:TextSized("Name: ", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT)
	local tw2 = p:TextSized("Password: ", "!DejaVu Sans@14", x, y + 14 + space, color_white, TEXT_ALIGN_LEFT)
	tw = math.max(tw, tw2)

	self.factionName = self.factionName or ""
	self.factionPass = self.factionPass or ""

	local restore_x = x
	x = x + tw + space

	if p:ClickyRect(x, y, w - tw - space * 3, 14, color_white) then
		Derma_StringRequest(
			"Faction Name",
			"Input your chosen faction name",
			self.factionName,
			function(str) self.factionName = str end,
			function(str) end
		)
	end
	p:Text(self.factionName, "!DejaVu Sans@12", x, y + 1, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 14 + space

	if p:ClickyRect(x, y, w - tw - space * 3, 14, color_white) then
		Derma_StringRequest(
			"Faction Password",
			"Input your chosen faction password",
			self.factionPass,
			function(str) self.factionPass = str end,
			function(str) end
		)
	end
	p:Text(self.factionPass, "!DejaVu Sans@12", x, y + 1, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 14 + space * 2
	x = restore_x

	self.factionColor = self.factionColor or HSVToColor(math.random(359), 0.8 + 0.2 * math.random(), 0.8 + 0.2 * math.random())

	p:Text("Color", "!DejaVu Sans@14", x, y, self.factionColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 16 + space

	p:_ParseFont("!DejaVu Sans@14")
	local rgb_width = surface.GetTextSize("G ")
	local square_size = 16 * 3 + space * 3
	local slider_width = w - space * 4 - square_size - rgb_width

	local y_restore = y
	p:Text("R ", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT)
	self.factionColor.r = p:Slider(self.factionColor.r / 255, x + rgb_width, y, slider_width, 16) * 255
	y = y + 16 + space

	p:Text("G ", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT)
	self.factionColor.g = p:Slider(self.factionColor.g / 255, x + rgb_width, y, slider_width, 16) * 255
	y = y + 16 + space

	p:Text("B ", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT)
	self.factionColor.b = p:Slider(self.factionColor.b / 255, x + rgb_width, y, slider_width, 16) * 255
	y = y + 16 + space

	p:Rect(x + rgb_width + slider_width + space * 2, y_restore - space, square_size, square_size, self.factionColor)

	y = y + space

	p:Text("WARNING! Disbanding will destroy your core!", "!DejaVu Sans@14", x, y, color_white, TEXT_ALIGN_LEFT)

	y = y + 14 + space

	local ok, err = basewars.factions.canStartFaction(LocalPlayer(), self.factionName, self.factionPass, color_white)
	if p:Button(ok and "Create Faction" or err or "unknown", "!DejaVu Sans@14", x, y, w - space * 2, 16, ok and color_succ or color_nosucc) and ok then
		basewars.factions.startFaction(LocalPlayer(), self.factionName, self.factionPass, self.factionColor)
	end
end

ENT.tabs.Faction = function(self, p, x, y, w, h)
	local space = x

	p:Text("Factions", "!DejaVu Sans@16", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 16 + space

	self.baseFaction = basewars.factions.getByCore(self:getCore())
	if self.baseFaction then
		self.tabs.factions_active(self, p, x, y, w, h)
	else
		self.tabs.factions_inactive(self, p, x, y, w, h)
	end
end

ENT.tabs.Raids    = function(self, p, x, y, w, h)
	local space = x

	p:Text("Raids", "!DejaVu Sans@16", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	y = y + 16 + space

	local amount_of_cores_shown = math.floor((h - space) / 16) - (IsValid(self.raidcoreSelected) and 2 or 0)
	local display_height = amount_of_cores_shown * 16
	local display_end = y + display_height

	local core_list, core_total = basewars.basecore.getList()

	local display_width = w
	p:Rect(x, y, display_width, display_height, color_transparent, color_white, 1)

	self.raidsScroll = self.raidsScroll or 1

	local display_width_corrected = display_width
	if core_total > amount_of_cores_shown then
		local scroll_width = 16
		display_width_corrected = display_width - scroll_width
		p:Rect(x + display_width_corrected, y, scroll_width, display_height, color_transparent, color_white, 1)

		-- TODO: bollocks here look at slider
	end

	local core = self:getCore()

	for i = self.raidsScroll, math.min(core_total + 1 - self.raidsScroll, amount_of_cores_shown) do
		local ent = core_list[i]

		if IsValid(ent) and ent ~= core then
			local fac = basewars.factions.getByCore(ent)
			local cppi_owner, owner_id = ent:CPPIGetOwner()
			local name = (fac and fac.name) or (IsValid(cppi_owner) and cppi_owner:Nick()) or owner_id

			if p:LeftButton(string.format("%s's core", name), "!DejaVu Sans@14", x, y, display_width_corrected, 16, ent == self.raidcoreSelected and color_selected) then
				self.raidcoreSelected = ent
			end
			p:Text(math.floor(core:GetPos():Distance(ent:GetPos()) * 0.01905) .. "m away", "!DejaVu Sans@14", x + display_width_corrected - space * 2, y, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

			y = y + 16
		end
	end

	if not IsValid(self.raidcoreSelected) then return end

	y = display_end + space
	self.nextScan = self.nextScan or 0

	if p:Button("Scan target (FREE, NOT FINISHED)", "!DejaVu Sans@14", x, y, display_width_corrected, 16, color_white) and self.nextScan <= CurTime() then
		hook.Run("BW_DoScanEffect", self.raidcoreSelected) -- TODO: make actual thing
		self.nextScan = CurTime() + 11
	end

	y = y + 16 + space

	if p:Button("Begin raid", "!DejaVu Sans@14", x, y, display_width_corrected, 16, color_white) then
		basewars.raids.startRaid(nil, self.raidcoreSelected)
	end
end

ENT.tabs.Settings = function(self, p, x, y, w, h)
	p:Text("Settings", "!DejaVu Sans@16", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function ENT:handleTabs(p, w, h)
	local x, y = 2, 2

	self.curTab = self.curTab or self.tabsNames[1]

	local space = x
	local count = #self.tabsNames
	local each_width = (w - (space * (count + 2))) / count
	local each_height = 16

	for _, name in ipairs(self.tabsNames) do
		if p:Button(name, "!DejaVu Sans@14", x, y, each_width, each_height, self.bgColor) and self.curTab ~= name then
			self.curTab = name
		end
		x = x + each_width + space
	end

	y = y + each_height + space * 2
	x = space

	local core = self:getCore()

	local ongoing = basewars.raids.getForEnt(core)
	if ongoing then
		local ent = ongoing.vs
		local fac = basewars.factions.getByCore(ent)
		local cppi_owner, owner_id = ent:CPPIGetOwner()
		local name = (fac and fac.name) or (IsValid(cppi_owner) and cppi_owner:Nick()) or owner_id

		p:Text(string.format("Ongoing raid VS %s", name), "!DejaVu Sans@20", w / 2, h / 2 - 11, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		y = y + 14 + space

		local len = ongoing.time - (CurTime() - ongoing.started)
		local m = math.floor(len / 60)
		local s = math.floor(len - m * 60)

		p:Text(string.format("%.2d:%.2d", m, s), "!DejaVu Sans@20", w / 2, h / 2 + 11, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		return
	elseif self.tabs[self.curTab] then
		self.tabs[self.curTab](self, p, x, y, w, h)
	else
		p:Text("Warning: Invalid tab selected?!?!!", "!DejaVu Sans@16", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		self.curTab = self.tabsNames[1]
	end
end

function ENT:Draw()
	BaseClass.Draw(self)

	local w, h = self.screenW, self.screenH
	local p = self.gui

	if self:validCore() then
		self:handleTabs(p, w, h)
		p:Custom(cursor)
	else
		p:Text("NO CORE CONNECTED", "!DejaVu Sans@32", w / 2, h / 2, Color(255, 0, 0))
	end

	p:Render(self:screenParams())
end


end

easylua.EndEntity()
