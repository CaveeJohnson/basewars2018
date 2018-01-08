local ext = basewars.createExtension"core.raids"

ext.ongoingRaids = ext:extablishGlobalTable("ongoingRaids")

ext.raidIndicatorColor = Color(255, 165, 0, 255) -- orange
ext.raidOngoingColor   = Color(255,   0, 0, 255) -- red

function ext:BW_ShouldSell(ply)
	if self:getPlayerRaidTarget(ply) then return false, "You cannot sell during a raid!" end
end

function ext:BW_ShouldSpawn(ply)
	if self:getPlayerRaidTarget(ply) then return false, "You cannot buy during a raid!"  end
end

function ext:BW_GetCoreIndicatorColor(core)
	if self.ongoingRaids[core] then
		return self.raidIndicatorColor
	end
end

function ext:BW_GetCoreDisplayData(core, dt)
	local data = self.ongoingRaids[core]

	if data then
		local len = data.time - (CurTime() - data.started)
		local m = math.floor(len / 60)
		local s = math.floor(len - m * 60)

		table.insert(dt, self.raidOngoingColor)
		table.insert(dt, string.format("Raid Status:  ONGOING!    Time Left:  %.2d:%.2d", m, s))
	else
		table.insert(dt, 0)
		table.insert(dt, "Raid Status: Clear")
	end
end

function ext:getPlayerRaidTarget(ply)
	if not ply:IsPlayer() then return false end
	if not basewars.hasCore(ply) then return false end

	local core = basewars.getCore(ply)
	return ext.ongoingRaids[core] and ext.ongoingRaids[core].vs or false
end

function ext:getEntRaidTarget(ent)
	if ent.isCore then return ext.ongoingRaids[core] and ext.ongoingRaids[core].vs end

	if not ent:validCore() then return false end

	local core = ent:getCore()
	return ext.ongoingRaids[core] and ext.ongoingRaids[core].vs
end

function ext:getRaidInfo(ent)
	if not IsValid(ent) then return false end

	if ent:IsPlayer() then
		if not basewars.hasCore(ent) then return false end

		local core = basewars.getCore(ent)
		return ext.ongoingRaids[core]
	elseif ent.isCore then
		return ext.ongoingRaids[ent]
	elseif ent.validCore then
		if not ent:validCore() then return false end

		local core = ent:getCore()
		return ext.ongoingRaids[core]
	else
		return false
	end
end

function ext:canStartRaid(ply, core)
	if not basewars.hasCore(ply) then return false, "You must have a core to raid!" end
	if not IsValid(core) then return false, "Invalid raid target!" end

	if IsValid(self:getPlayerRaidTarget(ply)) then return false, "You are already participating in a raid!" end

	if core:IsPlayer() then
		core = basewars.getCore(core)

		if not IsValid(core) then return false, "Invalid raid target!" end
	end
	if not core.isCore then return false, "Invalid raid target!" end
	if IsValid(self:getEntRaidTarget(core)) then return false, "Your target is already participating in a raid!" end

	local ownCore = basewars.getCore(ply)
	if ownCore == core then return false, "You cannot raid yourself!" end

	local res, why = hook.Run("BW_ShouldRaid", ownCore, core, ply) -- DOCUMENT:
	if res == false then return false, why end

	return true, ownCore, core
end

-- TODO: Player methods

function ext:cleanOngoing()
	local new = {}

	local count = 0
	for k, v in pairs(ext.ongoingRaids) do
		if
			IsValid(k) and IsValid(v.vs) and
			v.started + v.time > CurTime()
		then
			new[k] = v

			count = count + 1
		end
	end

	ext.ongoingRaids = self:overwriteGlobalTable("ongoingRaids", new)
	return new, count
end
ext.getOngoing = ext.cleanOngoing

function ext:getOngoingNoDuplicates()
	local new = {}
	local done = {}

	local count = 0
	for k, v in pairs(ext.ongoingRaids) do
		if
			IsValid(k) and IsValid(v.vs) and
			not done[k] and not done[v.vs] and
			v.started + v.time > CurTime()
		then
			new[k] = v

			done[v.vs] = true
			done[k] = true

			count = count + 1
		end
	end

	return new, count
end

function ext:BW_ShouldDamageProtectedEntity(ent, info)
	local attacker = info:GetAttacker()
	if not attacker:IsPlayer() and info:GetInflictor():IsPlayer() then attacker = info:GetInflictor() end
	if not IsValid(attacker) then return false end

	if not attacker:IsPlayer() then
		if IsValid(attacker:CPPIGetOwner()) then
			attacker = attacker:CPPIGetOwner()
		elseif IsValid(attacker:GetParent()) and IsValid(attacker:GetParent():CPPIGetOwner()) then
			attacker = attacker:GetParent():CPPIGetOwner()
		end
	end

	local attacker_targ = self:getPlayerRaidTarget(attacker)
	if attacker_targ ~= ((ent.isCore and ent) or (ent.getCore and ent:getCore())) then return false end

	return true -- attackers core is raiding us
end

function ext.readNetwork()
	local count = net.ReadUInt(8)

	for i = 1, count do
		local own = net.ReadEntity()
		local vs = net.ReadEntity()
		local time = net.ReadUInt(16)
		local started = net.ReadUInt(24)

		ext.ongoingRaids[own] = {vs = vs , time = time, started = started}
		ext.ongoingRaids[vs]  = {vs = own, time = time, started = started}
	end

	ext:cleanOngoing()
end
net.Receive(ext:getTag(), ext.readNetwork)

function ext.readNetworkStartEnd()
	local bit = net.ReadBit()
	if tobool(bit) then
		hook.Run("BW_RaidEnd", net.ReadEntity(), net.ReadEntity())
	else
		hook.Run("BW_RaidStart", net.ReadEntity(), net.ReadEntity())
	end
end
net.Receive(ext:getTag() .. "startEnd", ext.readNetworkStartEnd)

local error_message_color = Color(255, 0, 0)
function ext.readNetworkInteraction()
	local bit = net.ReadBit()
	if not tobool(bit) then
		local err = net.ReadString()
		chat.AddText(error_message_color, "GAMEMODE ERROR!!! Raid verification passed on client but failed on server: " .. err)
	end
end
net.Receive(ext:getTag() .. "interaction", ext.readNetworkInteraction)

if CLIENT then -- GUI (temp)
	local PANEL = {}

	DEFINE_BASECLASS "DFrame"

	function PANEL:Init()
		self:SetTitle("basewars - raids")
		self:SetDraggable(false)

		self.list   = vgui.Create("DListView", self)
		self.list:Dock(FILL)
		self.list:SetHideHeaders(true)

		function self.list.OnRowSelected(list, i, line)
			self:handleButtonState(line)
		end

		self.column = self.list:AddColumn("")

		self.rbutton = vgui.Create("DButton", self)
		self.rbutton:SetText("Start raid")
		self.rbutton:SetEnabled(false)
		self.rbutton:Dock(BOTTOM)

		function self.rbutton.DoClick()
			self:handleButtonClick()
		end

		self:populateList()
		self:resize()
	end

	function PANEL:Think()
		self:populateList()
	end

	function PANEL:populateList()
		local cores, l = basewars.getCores()
		local list = self.list

		local sel_i    = list:GetSelectedLine()
		local sel_line = sel_i and list:GetLine(sel_i)
		local sel_core = sel_line and sel_line.ent

		local x = 0
		for i = 1, math.max(#list:GetLines(), l) do
			local core = cores[i]

			if not core then
				print("[rg] dbg: remove i:" .. x)
				list:RemoveLine(x)
				if sel_i == x then list:ClearSelection() end
			end

			local owner = core:CPPIGetOwner()

			if IsValid(owner) and owner ~= LocalPlayer() then
				x = x + 1
				local line = list:GetLine(x)

				if not line then
					print("[rg] dbg: add i:" .. x .. " c:" .. tostring(core))
					list:AddLine(self:lineText(core)).ent = core
				elseif not line.ent:IsValid() or line.ent:getAbsoluteOwner() ~= core:getAbsoluteOwner() then
					print("[rg] dbg: update i:" .. x .. " n:" .. tostring(core))

					if sel_line and (sel_line ~= line and core == sel_core) then
						print("[rg] dbg: selupdate i:" .. x .. " o:" .. tostring(self_core) .. " n:" .. tostring(core))
						list:SelectItem(x)
					end

					line.ent = core
					line:SetColumnText(1, self:lineText(core))
				end
			end
		end

		list:SortByColumn(1)
		self:handleButtonState()
	end

	function PANEL:lineText(core)
		if not core then return "<this should not possible>" end
		local o = core:CPPIGetOwner()
		if not (o and o:IsValid()) then return "<disowned core>" end
		return o:GetName()
	end

	function PANEL:resize()
		self:SetSize(ScrW() / 2, ScrH() / 2)
		self:Center()
	end

	function PANEL:checkLineValidity(line)
		local ent = line.ent
		if not (ent and ent:IsValid()) then return false end
		if not (ent:CPPIGetOwner() and ent:CPPIGetOwner():IsValid()) then return false end
		if ent:CPPIGetOwner() == LocalPlayer() then return false end
		return true
	end

	function PANEL:handleButtonState(line)
		local button = self.rbutton

		local ourCore = basewars.getCore(LocalPlayer())
		if not ourCore and ourCore:IsValid() then button:SetEnabled(false) return end
		if ext.ongoingRaids[ourCore] then button:SetEnabled(false) return end

		if not line then
			local list   = self.list
			local sel_i  = list:GetSelectedLine()
			if not sel_i then
				button:SetEnabled(false)
				return
			end

			line = list:GetLine(sel_i)
		end

		button:SetEnabled(self:checkLineValidity(line))
	end

	function PANEL:handleButtonClick()
		local list     = self.list
		local sel_i    = list:GetSelectedLine()
		if not sel_i then self:displayError("Something has gone horribly wrong! (sel_i == nil)") return end

		local sel_line = list:GetLine(sel_i)
		if not sel_line then self:displayError("Something has gone horribly wrong! (sel_line == nil)") return end

		local sel_core = sel_line.ent
		if not sel_core and sel_core:IsValid() then self:displayError("Something has gone horribly wrong! (invalid core??)") return end

		local ok, why = ext:canStartRaid(LocalPlayer(), sel_core)
		if not ok then self:displayError(why) return end

		net.Start(ext:getTag() .. "interaction")
			net.WriteEntity(sel_core)
		net.SendToServer()
	end

	function PANEL:displayError(msg)
		Derma_Message(msg, "Error", "OK")
	end

	vgui.Register("BW_Raids_MainPanel", PANEL, "DFrame")

	function ext:openRaidGUI()
		if self.raidPanel and self.raidPanel:IsValid() then
			self.raidPanel:Remove()
		end

		self.raidPanel = vgui.Create("BW_Raids_MainPanel")
		self.raidPanel:MakePopup()
	end

	concommand.Add("bw18_raid_gui", function() ext:openRaidGUI() end)
end

if CLIENT then return end

util.AddNetworkString(ext:getTag())
util.AddNetworkString(ext:getTag() .. "startEnd")
util.AddNetworkString(ext:getTag() .. "interaction")

function ext:transmitRaidStartEnd(ended, own, vs)
	net.Start(self:getTag() .. "startEnd")
		net.WriteBit(ended and 1 or 0)

		net.WriteEntity(own)
		net.WriteEntity(vs)
	net.Broadcast()
end

function ext:transmitRaidSingle(own, vs, time, started)
	net.Start(self:getTag())
		net.WriteUInt(1, 8)

		net.WriteEntity(own)
		net.WriteEntity(vs)
		net.WriteUInt(time, 16)
		net.WriteUInt(math.floor(started), 24)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function ext:transmitRaids(ply)
	local tbl, count = self:getOngoingNoDuplicates()

	net.Start(self:getTag())
		net.WriteUInt(count, 8)

		for own, v in pairs(tbl) do
			net.WriteEntity(own)
			net.WriteEntity(v.vs)
			net.WriteUInt(v.time, 16)
			net.WriteUInt(math.floor(v.started), 24)
		end

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function ext:PostPlayerInitialSpawn(ply)
	self:transmitRaids(ply)
end

function ext:startRaid(ply, core)
	local can, ownCore, core = self:canStartRaid(ply, core)
	if not can then return false, ownCore end

	self:cleanOngoing()

	local time = hook.Run("BW_GetRaidTime", ownCore, core, ply) or 300 -- TODO: Config -- DOCUMENT:
	local started = CurTime()

	ext.ongoingRaids[ownCore] = {vs = core   , time = time, started = started}
	ext.ongoingRaids[core]    = {vs = ownCore, time = time, started = started}

	core:raidEffect()
	self:transmitRaidSingle(ownCore, core, time, started)

	hook.Run("BW_RaidStart", ownCore, core)
	self:transmitRaidStartEnd(false, ownCore, core)

	local raidOver = function()
		ext.ongoingRaids[ownCore] = nil
		ext.ongoingRaids[core] = nil

		self:cleanOngoing()
		self:transmitRaids()

		hook.Run("BW_RaidEnd", ownCore, core)
		self:transmitRaidStartEnd(true, ownCore, core)
	end

	local tid = string.format("raid%s%s", tostring(ownCore), tostring(core))
	timer.Create(
		tid .. "tick",
		1,
		time,

		function()
			if not (IsValid(ownCore) and IsValid(core)) then
				timer.Destroy(tid.."tick")
				timer.Destroy(tid)

				basewars.logf("raid ended earlier due to validity failure: %s vs %s", tostring(ownCore), tostring(core))
				raidOver()
			end
		end
	)

	timer.Create(
		tid,
		time,
		1,

		raidOver
	)
end

function ext.readNetworkInteraction(_, ply)
	local core = net.ReadEntity()
	if not core:IsValid() then return end

	local t
	local ok, why = ext:startRaid(ply, core)
	if ok == false then
		print("GAMEMODE ERROR!!! Raid verification passed on client but failed on server: " .. why)
		t = true
	end

	net.Start(ext:getTag() .. "interaction")
		net.WriteBit(t and 0 or 1)
		if t then
			net.WriteString(why)
		end
	net.Send(ply)
end

net.Receive(ext:getTag() .. "interaction", ext.readNetworkInteraction)
