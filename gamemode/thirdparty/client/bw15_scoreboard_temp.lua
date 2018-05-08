--if IsValid(Scoreboard) then Scoreboard:Remove() end

-- local stuff

function surface.DrawShadowedText(font, text, color,  x, y, x_offset, y_offset)
	surface.SetFont(font)
	surface.SetTextColor(0, 0, 0, 192)
	local _x, _y = surface.GetTextSize(text)
	surface.SetTextPos(x - (_x * 0.5) - x_offset, y - (_y * 0.5) - y_offset)
	surface.DrawText(text)

	surface.SetTextColor(color)
	surface.SetTextPos(x - (_x * 0.5), y - (_y * 0.5))
	surface.DrawText(text)
end

local tag = "Scoreboard"
local scrW, scrH = ScrW(), ScrH()

local ping = Material("icon16/transmit_blue.png")
local pingbad = Material("icon16/transmit.png")

local PLAYER = FindMetaTable("Player")
PLAYER.IsMod = PLAYER.IsMod or PLAYER.IsAdmin

local muted_players = {}

local function ScreenScale(size)
	return size * (ScrW() / 1280)
end

local function RemoveVBar(pnl)
	pnl.Paint = function() end
end

local function cmd(...)
	RunConsoleCommand("aowl", ...)
end

local function AddKick(reason, entid, pnl, mode)
	if mode then
		pnl:AddSpacer()
		pnl:AddOption(reason, function()
			Derma_StringRequest("Custom kick message", "Enter your kick reason.", "", function(text)
				cmd("kick", "_" .. entid, text)
			end)
		end):SetImage("icon16/cross.png")
		return
	end
	pnl:AddOption(reason, function()
			cmd("kick", "_" .. entid, reason)
	end):SetImage("icon16/cross.png")
end

local function AddBan(reason, entid, pnl, mode)
	if mode then
		pnl:AddSpacer()
		pnl:AddOption(reason, function()
			Derma_StringRequest("Custom ban message", "Enter your ban reason.", "", function(text)
				cmd("ban", "_" .. entid, "30m", "[QUICK BAN] " .. text)
			end)
		end):SetImage("icon16/stop.png")
		return
	end
	pnl:AddOption(reason, function()
			cmd("ban", "_" .. entid, "30m", "[QUICK BAN] " .. reason)
	end):SetImage("icon16/stop.png")
end

local function AddOption(title, command, entid, pnl, icon, arg)
	local a = pnl:AddOption(title, function()
		cmd(command, "_" .. entid, arg)
	end)
	if icon then
		a:SetImage(icon)
	end

	return a
end

-- Fonts

surface.CreateFont(tag, {
	font = "Verdana",
	size = ScreenScale(13.5),
	weight = 900,
	antialias = true,
})

surface.CreateFont(tag .. "Nick", {
	font = "Helvetica",
	size = ScreenScale(13.5),
	weight = 900,
	antialias = true,
})

-- Convars

local scoreboard_convar = CreateClientConVar("scoreboard", "1", true)
concommand.Add("scoreboard_reload", function()
	if IsValid(Scoreboard) then
		Scoreboard:Remove()
		gui.EnableScreenClicker(false)
	end
end)

-- Main code

local SCOREBOARD_LINE = {}
function SCOREBOARD_LINE:Load(ply)
	self.ply = ply
	self.teamid = ply:Team()
	self:Reload()
	local colors = team.GetColor(self.teamid)
	local frame = self:Add("EditablePanel")
	frame:Dock(TOP)
	frame:SetTall(32)
	frame.alpha = 180
	frame.Paint = function(_self, w, h)
		if not IsValid(self.ply) then return end

		-- Line for teams
		surface.SetDrawColor(colors.r, colors.g, colors.b, 170)

		-- Team bar
		surface.DrawRect(15, 0, 5, h)
		-- Team line
		surface.DrawRect(15 + 5, 15, 10, 5)

		-- Team colored frame
		surface.SetDrawColor(colors.r, colors.g, colors.b, 170)
		surface.DrawRect(32 + 35, 1, w, h)

		-- Basic white frame
		local alpha = 0
		local banned = 0

		if self.ply.IsBanned and self.ply:IsBanned() then
			banned = 50
		else
			banned = 0
		end

		if self.ply.IsAFK and self.ply:IsAFK() then
			alpha = 80
		else
			alpha = 0
		end

		if self.ply:IsMod() and (self.ply.IsBanned and not self.ply:IsBanned()) then
			surface.SetDrawColor(232, 255, 232, _self.alpha - alpha)
		else
			surface.SetDrawColor(255, 255 - banned, 255 - banned, _self.alpha - alpha)
		end
		surface.DrawRect(32 + 36 + (5 * 0.5), (5 * 0.5), w - (32 + 36) - 5, h - 5)
		surface.DrawOutlinedRect(32 + 36 + (5 * 0.5), (5 * 0.5), w - (32 + 36) - 5 , h - 5)
	end

	local avatar = frame:Add("AvatarImage")
	avatar:Dock(LEFT)
	avatar:DockMargin(30, 2, 0, 2)
	avatar:SetWidth(32 - 2)
	avatar:SetPlayer(self.ply, 128)

	local avatarbutton = avatar:Add("DButton")
	avatarbutton:Dock(FILL)
	avatarbutton.OnMousePressed = function(_self, mouse)
		if mouse ~= MOUSE_RIGHT then return end

		local menu = DermaMenu()

		menu:AddOption("Open Profile", function() self.ply:ShowProfile() end):SetImage("icon16/page_world.png")
		menu:AddOption("Copy Profile Link", function() SetClipboardText("http://steamcommunity.com/profiles/" .. self.ply:SteamID64()) end):SetImage("icon16/page_white_text.png")
		menu:AddOption("Copy SteamID", function() SetClipboardText(self.ply:SteamID()) end):SetImage("icon16/page_white_text.png")
		menu:AddOption("Copy SteamID64", function() SetClipboardText(self.ply:SteamID64()) end):SetImage("icon16/page_white_text.png")
		menu:AddOption("Copy Name", function() SetClipboardText(self.ply:Nick()) end):SetImage("icon16/page_white_text.png")

		if LocalPlayer():IsMod() then
			menu:AddSpacer()

			menu:AddOption("Copy Entity Index", function() SetClipboardText(self.ply:EntIndex()) end):SetImage("icon16/page_white_text.png")
			menu:AddOption("Copy UserID", function() SetClipboardText(self.ply:UserID()) end):SetImage("icon16/page_white_text.png")
			menu:AddOption("Copy UniqueID", function() SetClipboardText(self.ply:UniqueID()) end):SetImage("icon16/page_white_text.png")
		end

		menu:Open()

		_self.openmenu = menu
	end
	avatarbutton.Paint = function(_self)
		if not IsValid(self.ply) and IsValid(_self.openmenu) then
			_self.openmenu:Remove()
		end
	end
	avatarbutton:SetText("")

	local info = frame:Add("EditablePanel")
	info:Dock(FILL)
	info.Paint = function(_self, w, h)
		if not IsValid(self.ply) then return end

		-- highlighted bar
		if _self:IsHovered() then
			frame.alpha = 235
		else
			frame.alpha = 180
		end

		-- nick name
		surface.SetFont(tag .. "Nick")
		if self.ply.IsBanned and self.ply:IsBanned() then
			surface.SetTextColor(255, 0, 0, 255)
		else
			surface.SetTextColor(0, 0, 0, 255)
		end
		local x, y = surface.GetTextSize(self.ply:Nick())
		surface.SetTextPos(15, (h * 0.5) - (y * 0.5) - 0.5)
		local name = self.ply:Nick()
		if markup_quickParse then
			name = markup_quickParse(name, self.ply)
		end
		surface.DrawText(name)

		-- country code
		surface.SetDrawColor(255, 255, 255, 255)
		if self.country and type(self.country) == "IMaterial" then
			surface.SetMaterial(self.country)
			surface.DrawTexturedRect(w - (10 + (16 * 0.5) + 5), (h * 0.5) - (10 * 0.5), 16, 10)
		else
			surface.SetDrawColor(50, 50, 50, 255)
			surface.DrawRect(w - (10 + (16 * 0.5) + 5), (h * 0.5) - (10 * 0.5), 16, 10)
		end

		-- ping text and icon
		local x, y = surface.GetTextSize(self.ply:Ping())
		surface.SetTextColor(0, 0, 0, 255)
		surface.SetTextPos(w - (x + 10 + (16 * 0.5) + 10) - 16 - (8), (h * 0.5) - (y * 0.5))
		surface.DrawText(self.ply:Ping())

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(type(self.ply:Ping()) == "number" and self.ply:Ping() > 160 and pingbad or ping) -- memers like me could override ping with a string
		surface.DrawTexturedRect(w - (10 + (16 * 0.5) + 5) - 16 - (8), (h * 0.5) - (16 * 0.5), 16, 16)
	end

	info.OnMousePressed = function(_self, mouse)
		local entindex = self.ply:EntIndex()
		if mouse == MOUSE_LEFT and not _self.MousePressed then
			_self.MousePressed = SysTime() + 0.3
		elseif mouse == MOUSE_LEFT and _self.MousePressed < SysTime() then
			_self.MousePressed = nil
		elseif mouse == MOUSE_LEFT and _self.MousePressed > SysTime() then
			if LocalPlayer():IsMod() and aowl and entindex ~= LocalPlayer():EntIndex() then
				cmd("goto", "_" .. entindex)
			end
			_self.MousePressed = nil
		end

		if mouse ~= MOUSE_RIGHT then return end

		local menu = DermaMenu()

		if LocalPlayer():IsMod() and aowl then
			local aowl, image = menu:AddSubMenu("aowl")
			image:SetImage("icon16/shield.png")

			if entindex ~= LocalPlayer():EntIndex() then
				local goto = AddOption("Goto", "goto", entindex, aowl, "icon16/arrow_up.png")

				local bring = goto:AddSubMenu("Bring")

				bring = AddOption("Bring", "bring", entindex, bring, "icon16/arrow_down.png")
			end

			aowl:AddSpacer()

			local kick = AddOption("Kick", "kick", entindex, aowl, "icon16/cross.png")
			kick = kick:AddSubMenu()

			AddKick("Prop Spam", 			entindex, kick)
			AddKick("Chat Spam", 			entindex, kick)
			AddKick("Annoying Player", 		entindex, kick)
			AddKick("Suspected cheater", 	entindex, kick)
			AddKick("Custom...",			entindex, kick, 1)

			local ban = AddOption("Ban", "ban", entindex, aowl, "icon16/stop.png")
			ban = ban:AddSubMenu()

			if self.ply.IsBanned and not self.ply:IsBanned() then
				AddBan("Prop Spam", 			entindex, ban)
				AddBan("Chat Spam", 			entindex, ban)
				AddBan("Annoying Player", 		entindex, ban)
				AddBan("Suspected cheater",		entindex, ban)
				AddBan("Custom...",				entindex, ban, 1)
			else
				AddOption("Unban", "unban", entindex, ban, "icon16/accept.png")
			end

			aowl:AddSpacer()

			AddOption("Spectate", 	"spectate", 	entindex, aowl, "icon16/television.png")
			AddOption("Cleanup", 	"cleanup", 		entindex, aowl, "icon16/arrow_undo.png")
			AddOption("Screenshot", "ss", 			entindex, aowl, "icon16/photo_link.png")
			AddOption("Scanlua", 	"scanlua", 		entindex, aowl, "icon16/database_go.png")

			aowl:AddSpacer()

			AddOption("Reconnect", "cexec", entindex, aowl, "icon16/arrow_refresh.png", "retry")

			menu:AddSpacer()

		end

		if entindex ~= LocalPlayer():EntIndex() then
			menu:AddOption(self.ply:IsMuted() and "Unmute" or "Mute", function()
				self.ply:SetMuted(not self.ply:IsMuted())
			end):SetImage(self.ply:IsMuted() and "icon16/sound_add.png" or "icon16/sound_mute.png")

			menu:AddOption(muted_players[self.ply:SteamID()] and "Ungag" or "Gag", function()
				if self.ply:IsMod() then return end

				muted_players[self.ply:SteamID()] = not muted_players[self.ply:SteamID()]
			end):SetImage(muted_players[self.ply:SteamID()] and "icon16/comments_add.png" or "icon16/comments_delete.png")
		end

		menu:Open()

		self.menu = menu
	end

	self:Dock(TOP)
	self:SetZPos(ply:Team())
	self:SetTall(32)

	self.frame = frame
	self.info = info
	self.avatar = avatar
end

function SCOREBOARD_LINE:Think()
	if not IsValid(self.ply) then
		if IsValid(self.menu) then
			self.menu:Remove()
		end
		return self:Remove()
	end
end

function SCOREBOARD_LINE:Reload()
	if not IsValid(self.ply) then return end
	if self.country then return end
	local country = self.ply.GetCountryCode and self.ply:GetCountryCode():lower() or "n/a"

	local exists = file.Exists("materials/flags16/" .. country .. ".png", "GAME")

	if exists then
		country = Material("flags16/" .. country .. ".png")
		if country:IsError() then
			country = nil
		end
	end

	if country and (country == "n/a" or country == "error") then
		country = nil
	end
	self.country = country

	return country
end


SCOREBOARD_LINE = vgui.RegisterTable(SCOREBOARD_LINE, "EditablePanel")

local SCOREBOARD = {}
function SCOREBOARD:Init()
	self.Scoreboardlines = {}
	self.teamcols = {}
	local header = self:Add("EditablePanel")
	local lowerheader = self:Add("EditablePanel")
	local playerlist = self:Add("DScrollPanel")

	header:Dock(TOP)
	header:SetTall(60)
	header:SetPos(0, 50)
	header.Paint = function(self, w, h)
		if self:IsHovered() then
			surface.SetDrawColor(130, 130, 130, 220)
		else
			surface.SetDrawColor(100, 100, 100, 220)
		end
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(190, 190, 190, 255)
		surface.DrawOutlinedRect(0, 0, w, h)


		surface.DrawShadowedText(tag, GetHostName(), Color(255, 255, 255), (w * 0.5), (h * 0.5), 3, -1)
	end
	local x, y = header:LocalToScreen(header:GetPos())
	header.OnMousePressed = function(_self, mouse)
		if mouse == MOUSE_RIGHT then
			local menu = DermaMenu()

			menu:AddOption("Reload scoreboard?", function() Scoreboard:Remove() gui.EnableScreenClicker(false) end):SetImage("icon16/arrow_refresh.png")

			menu:Open()

			return
		end

		lowerheader:SizeTo(-1, self.open and 0 or 40, 0.2, 0, 1, function()
			self.open = !self.open
		end)
	end

	lowerheader:Dock(TOP)
	lowerheader:DockMargin(50, 0, 50, 0)
	lowerheader:SetTall(0)
	lowerheader:SetPos(((scrW * 0.4) - (scrW * 0.35)) * 0.5, y + 60)
	lowerheader.Paint = function(_self, w, h)
		-- inner box
		surface.SetDrawColor(100, 100, 100, 220)
		surface.DrawRect(0, 0, w, h)

		-- outline
		surface.SetDrawColor(190, 190, 190, 255)
		surface.DrawOutlinedRect(0, -1, w, h)

		-- info
		surface.DrawShadowedText(tag .. "Nick", "Total Props: " .. #ents.FindByClass("prop_physics"), Color(255, 255, 255), 100, (h * 0.5), 2.5, -1)
		surface.DrawShadowedText(tag .. "Nick", "Your Props: " .. LocalPlayer():GetCount("props"), Color(255, 255, 255), (w * 0.5), (h * 0.5), 2.5, -1)
		surface.DrawShadowedText(tag .. "Nick", "Total Players: " .. player.GetCount(), Color(255, 255, 255), (w - 100), (h * 0.5), 2.5, -1)
	end

	playerlist:Dock(FILL)
	playerlist:DockMargin(5, 5, 5, 30)
	local scrollbar = playerlist:GetVBar()
	RemoveVBar(scrollbar.btnUp)
	RemoveVBar(scrollbar.btnDown)
	RemoveVBar(scrollbar.btnGrip)
	RemoveVBar(scrollbar)

	self.header = header
	self.lowerheader = lowerheader
	self.playerlist = playerlist
end

function SCOREBOARD:PerformLayout()
	self:SetSize(scrW * 0.4, scrH * 0.9)
	self:Center()
end

function SCOREBOARD:Think()
	for _, ply in next, player.GetAll() do
		if IsValid(self.Scoreboardlines[ply]) then continue end

		self.Scoreboardlines[ply] = vgui.CreateFromTable(SCOREBOARD_LINE, self)
		self.Scoreboardlines[ply]:Load(ply)

		self:DoTeamCol(ply:Team())

		self.playerlist:AddItem(self.Scoreboardlines[ply])
	end
	self:CheckCol()
end

function SCOREBOARD:DoTeamCol(teamid)
	if self.teamcols[teamid] then return end
	local col = self:Add("EditablePanel", self)
	col.teamid = teamid
	local colors = team.GetColor(teamid)
	col.colors = colors -- debugging reasons
	local teamname = team.GetName(teamid)

	col:SetTall(24)
	col.Paint = function(self, w, h)
		local poly = {
			{x =  w - 24, y = 24	},
			{x =  w - 24, y = 0	},
			{x = w, y = 24	}
		}
		-- team header bar
		surface.SetDrawColor(colors.r, colors.g, colors.b, 170)
		surface.DrawRect(24, 0, w - 24 * 2, h)
		-- team left bar connector
		surface.DrawRect(15, 12, 5, 12)
		surface.DrawRect(15 - (4 * 0.5), 5, 5 + 3, 8)
		surface.DrawRect(15 + 5, 5 + (5 * 0.5), 4, 5)

		-- team name
		surface.DrawShadowedText(tag, teamname, Color(255, 255, 255), (w * 0.5), (h * 0.5) - 1, 2, -1)

		-- amount of players in the team
		surface.DrawShadowedText(tag, self.count, Color(255, 255, 255), 30 + (30 * 0.5), (h * 0.5) - 1, 2, -1)

		draw.NoTexture()
		surface.DrawPoly(poly)

		-- team header small line
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawLine(15 + 5 + 4, h - 2, w - 1, h - 2)
	end

	col:Dock(TOP)
	col:DockMargin(0, 10, 0, 0)
	col:SetZPos(teamid)
	self.teamcols[teamid] = col
	self.playerlist:AddItem(col)

	self:CheckCol()
end

function SCOREBOARD:CheckCol()
	local count = {}
	for teamid, pnl in next, self.teamcols do
		count[teamid] = {0, pnl}
	end
	for ply, pnl in next, self.Scoreboardlines do
		if (IsValid(ply) and ply.Team and IsValid(pnl) and ply:Team() ~= pnl.teamid) or (not IsValid(pnl)) then
			self.Scoreboardlines[ply]:Remove()
			self.Scoreboardlines[ply] = nil
		elseif IsValid(ply) and ply.Team and count[ply:Team()] then
			count[ply:Team()][1] = count[ply:Team()][1] + 1
		end
	end
	for teamid, tbl in next, count do
		tbl[2].count = tbl[1]
		if tbl[1] == 0 then
			tbl[2]:Remove()
			self.teamcols[teamid] = nil
		end
	end
end

function SCOREBOARD:Reload()
	local count = 0
	for _, ply in next, player.GetAll() do
		if ply:IsMod() then
			count = count + 1
		end
	end

	for ply, pnl in next, self.Scoreboardlines do
		if IsValid(pnl) and pnl.Reload then
			pnl:Reload()
		end
	end

	self.adminsonline = count

	return count
end

SCOREBOARD = vgui.RegisterTable(SCOREBOARD, "EditablePanel")

-- hooks

hook.Add("ScoreboardShow", tag, function()
	if not scoreboard_convar:GetBool() then return end
	if not IsValid(Scoreboard) then
		Scoreboard = vgui.CreateFromTable(SCOREBOARD)
	end

	Scoreboard:Reload()
	Scoreboard:Show()
	Scoreboard:SetMouseInputEnabled(true) -- apparently not putting this here causes it to break

	return false
end)

hook.Add("ScoreboardHide", tag, function()
	if not scoreboard_convar:GetBool() then return end
	if IsValid(Scoreboard) then
		Scoreboard:Hide()

		gui.EnableScreenClicker(false)

		CloseDermaMenus()
	end
end)

hook.Add("PlayerBindPress", tag, function(ply, bind, pressed)
	if bind == "+attack2" and pressed and (Scoreboard and Scoreboard:IsVisible()) then
		gui.EnableScreenClicker(true)

		return true
	end
end)

hook.Add("OnPlayerChat", tag, function(ply)
	if IsValid(ply) and muted_players[ply:SteamID()] then
		return true
	end
end)
