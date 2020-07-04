chatbox = chatbox or {}

if IsValid(chatbox.frame) then
	chatbox.frame:Remove()
end

chatbox.settings = {

}

local box_font = CreateClientConVar("xp_chat_box_font","DermaDefaultBold",true,false,"Changes the Fonts of the chatbox itself.")
cvars.AddChangeCallback("xp_chat_box_font",function(cv,_,new) chatbox.box_font = new end)

surface.CreateFont("DefaultChatFont", {
	font = "Roboto",
	size = 18,
	weight = 300,
	shadow = true
})

local feed_font = CreateClientConVar("xp_chat_feed_font", "DefaultChatFont", true, false, "Changes the Font of the text displayed inside the chatbox.")
cvars.AddChangeCallback("xp_chat_feed_font",function(cv,_,new) chatbox.feed_font = new end)

chatbox.accent_color = Color(255, 192, 203, 255)
chatbox.back_color   = Color(0, 0, 0, 200)
chatbox.input_color  = Color(0, 0, 0, 150)
chatbox.feed_font    = feed_font:GetString()


function chatbox.WriteConfig()

	local x, y, w, h = chatbox.frame:GetBounds()
	chatbox.frame:SetCookie("x", x)
	chatbox.frame:SetCookie("y", y)
	chatbox.frame:SetCookie("w", w)
	chatbox.frame:SetCookie("h", h)

end

function chatbox.IsOpen()
	return IsValid(chatbox.frame) and chatbox.frame:IsVisible()
end

-- Link code is from qchat/EPOE.
local function CheckFor(tbl, a, b)
	local a_len = #a
	local res, endpos = true, 1

	while res and endpos < a_len do
		res, endpos = a:find(b, endpos)

		if res then
			tbl[#tbl + 1] = {res, endpos}
		end
	end
end

local function AppendTextLink(a, callback)
	local result = {}

	CheckFor(result, a, "https?://[^%s%\"]+")
	CheckFor(result, a, "ftp://[^%s%\"]+")
	CheckFor(result, a, "steam://[^%s%\"]+")

	if #result == 0 then return false end

	table.sort(result, function(b, c) return b[1] < c[1] end)

	-- Fix overlaps
	local _l, _r
	for k, tbl in ipairs(result) do
		local l = tbl[1]

		if not _l then
			_l, _r = tbl[1], tbl[2]
			continue
		end

		if l < _r then table.remove(result, k) end

		_l, _r = tbl[1], tbl[2]
	end

	local function TEX(str) callback(false, str) end
	local function LNK(str) callback(true, str) end

	local offset = 1
	local right

	for _, tbl in ipairs(result) do
		local l, r = tbl[1], tbl[2]
		local link = a:sub(l, r)
		local left = a:sub(offset, l - 1)
		right = a:sub(r + 1, -1)
		offset = r + 1

		TEX(left)
		LNK(link)
	end

	TEX(right)

	return true
end

local function quick_parse(txt)
	return txt
end

function chatbox.ParseInto(feed, ...)

	local tbl = {...}

	feed:InsertColorChange(120, 219, 87, 255)

	if #tbl == 1 and isstring(tbl[1]) then
		feed:AppendText(quick_parse(tbl[1]))
		feed:AppendText("\n")

		return
	end

	for i, v in next, tbl do
		if IsColor(v) or istable(v) then
			feed:InsertColorChange(v.r, v.g, v.b, 255)
		elseif isentity(v) then
			if v:IsPlayer() then
				local col = GAMEMODE:GetTeamColor(v)
				feed:InsertColorChange(col.r, col.g, col.b, 255)

				feed:AppendText(quick_parse(v:Nick()))
			else
				local name = (v.Name and isfunction(v.name) and v:Name()) or v.Name or v.PrintName or tostring(v)
				if v:EntIndex() == 0 then
					feed:InsertColorChange(106, 90, 205, 255)
					name = "Console"
				end

				feed:AppendText(quick_parse(name))
			end
		elseif v ~= nil then
			local function linkAppend(islink, text)
				if islink then
					feed:InsertClickableTextStart(text)
						feed:AppendText(text)
					feed:InsertClickableTextEnd()
				return end

				feed:AppendText(text)
			end

			local res = AppendTextLink(tostring(v), linkAppend)

			if not res then
				feed:AppendText(quick_parse(tostring(v)))
			end
		end
	end

	feed:AppendText("\n")

end

function chatbox.OpenEmotesMenu(btn)
	if IsValid(chatbox.EmoteMenu) then chatbox.EmoteMenu:StartClosing() chatbox.EmoteMenu = nil return end

	local emotes = vgui.Create("TabbedFrame")
	chatbox.EmoteMenu = emotes
	emotes.Shadow = {intensity = 3, blur = 1, spread = 0.7}

	emotes.TabColor = Color(65, 65, 65)

	emotes:SetCloseable(false, true)
	emotes:SetDraggable(false)
	emotes:SetSizable(true)
	emotes:SetSizablePos(2)

	emotes:PopIn()

	emotes:SetCookieName("ChatHUDEmoteMenuW")
	emotes:SetCookieName("ChatHUDEmoteMenuH")

	local ew, eh = emotes:GetCookie("ChatHUDEmoteMenuW", 300), emotes:GetCookie("ChatHUDEmoteMenuH", 180)

	emotes:SetSize(ew, eh)

	local x = chatbox.frame:LocalToScreen(chatbox.frame:GetWide(), 0) - 8
	local _, y = btn:LocalToScreen(0, 0)

	chatbox.frame:On("OnSizeChanged", emotes, function(self, w)
		x = (chatbox.frame:LocalToScreen(w, 0)) + 16
		_, y = btn:LocalToScreen(0, 0)

		emotes:SetPos(x, y + btn:GetTall() - eh)
	end)


	emotes:SetPos(x, y - eh + btn:GetTall())
	emotes:MoveBy(16, 0, 0.3, 0.05, 0.4)

	chatbox.frame:On("OnClose", emotes, function(self)
		emotes:PopOut()
	end)


	function emotes:StartClosing()
		self:MoveBy(0, 8, 0.07, 0, 0.4)
		self:PopOut(0.07)
		self:Emit("OnClose")
	end

	function emotes:OnMouseReleased()

		self.Dragging = nil
		self.Sizing = nil

		self:MoveTo(x + 16, y - self:GetTall() + btn:GetTall(), 0.3, 0, 0.5)

		self:MouseCapture( false )

		self:SetCookie("ChatHUDEmoteMenuW", self:GetWide())
		self:SetCookie("ChatHUDEmoteMenuH", self:GetTall())

		ew, eh = self:GetWide(), self:GetTall()
	end

	emotes.TabFont = "OS20"
	emotes.HeaderSize = 20

	emotes:SetTabSize(18)

	emotes:On("OnSizeChanged", emotes.OnSizeChanged)

	function emotes:OnSizeChanged(w, h)
		self:Emit("OnSizeChanged", w, h)
	end

	function emotes:OnRemove()
		self:Emit("OnRemove")
	end

	local reload = vgui.Create("FButton")
	reload:SetPos(emotes.X + 16, emotes.Y + emotes:GetTall() - 8)
	reload:SetSize(32, 32)
	reload:MoveBy(0, 16, 0.3, 0, 0.4)

	reload.AlwaysDrawShadow = true

	function reload:PostPaint(w, h)
		surface.SetDrawColor(color_white)
		surface.DrawMaterial("https://i.imgur.com/Kr2xpAj.png", "swap_inv.png", 4, 4, w-8, h-8)
	end

	function reload:OnHover()
		if not IsValid(self.Cloud) then
			self.Cloud = vgui.Create("Cloud", self)
			self.Cloud:SetText("Reload all emotes")

			self.Cloud.YAlign = 0 --align by top
			self.Cloud.MaxW = 400
			self.Cloud.Middle = 0 --and by left

			self.Cloud:SetAbsPos(0, self:GetTall() + 8)
			self.Cloud:AddFormattedText("Use if all animated emotes look scuffed.")
			self.Cloud.RemoveWhenDone = true
		end

		self.Cloud:Popup(true)
	end

	function reload:OnUnhover()
		if not IsValid(self.Cloud) then return end
		self.Cloud:Popup(false)
	end

	function reload:DoClick()

		for k,v in pairs(Emotes.Collections.Animated:GetEmotes()) do
			RunConsoleCommand("mat_reloadmaterial", "data/hdl/" .. v:GetHDLPath())
		end
	end

	emotes:On("OnClose", reload, function()
		reload:PopOut()
	end)

	emotes:On("OnRemove", reload, function()
		reload:Remove()
	end)

	local emotesLoading = false --if this is true, an emote button won't attempt to paint the emote and will instead display a loading animation
								--if this is false and an emote material wasn't loaded this will switch to true

								--this gets reset every frame by list:PostPaint

								--this way, we're letting only 1 emote per frame to load

	for name, coll in pairs(Emotes.Collections) do
		local tab = emotes:AddTab(name, function()
			local list = vgui.Create("FScrollPanel", emotes)
			list:Dock(FILL)

			--apply filters to all children (emotes)

			list.Paint = function()
				render.PushFilterMag( TEXFILTER.ANISOTROPIC )
				render.PushFilterMin( TEXFILTER.ANISOTROPIC )
			end

			list.PaintOver = function(self, w, h)
				render.PopFilterMag()
				render.PopFilterMin()

				emotesLoading = false
			end

			emotes:AlignPanel(list)

			local size = 40

			local il = list:Add("DIconLayout")
			il:Dock(FILL)
			local minspace = 6
			il:SetSpaceX(6)
			il:SetSpaceY(4)
			il:SetBorder(2)

			il:Layout()

			local toscrW, toscrH = emotes:LocalToScreen(emotes:GetWide(), emotes:GetTall())
			local midX, midY = emotes:LocalToScreen(emotes:GetWide() / 2, emotes:GetTall() / 2)

			emotes:On("OnSizeChanged", il, function(self, w, h)
				local odd = (il:GetWide() - il:GetBorder()) % (size + minspace)
				il:SetSpaceX(minspace + odd / (w / size) )

				midX, midY = self:LocalToScreen(w/2, h/2)

				toscrW = midX + w/2
				toscrH = midY + h/2
			end)

			for k,v in pairs(coll:GetEmotes()) do
				local b = il:Add("DButton")
				b:SetSize(size, size)
				b:SetText("")
				b:SetDoubleClickingEnabled(false) 	--let 'em spam
				b.Emote = v

				function b:Paint(w, h)
					if not MoarPanelsMats[self.Emote:GetHDLPath()] and not emotesLoading then 	-- emote material hasn't preloaded and we're not loading anything
						emotesLoading = true													-- switch emotesLoading to true and allow 1 mat to load
					elseif emotesLoading then 													-- emote material is loading and we're already loading something, don't do anything
						draw.DrawLoading(self, w/2, h/2, w, h)
						return
					end

					surface.SetDrawColor(color_white)
					self.Emote:Paint(0, 0, w, h, self)
				end

				function b:OnCursorEntered()
					if not IsValid(self.Cloud) then
						self.Cloud = vgui.Create("Cloud", self)
						self.Cloud:SetText(self.Emote:GetName())
						self.Cloud:SetSize(self:GetSize())	--makes cloud always paint even if 0,0 of the button is hidden

						self.Cloud.YAlign = 0 --align by top cuz the cloud is at the bottom of the emotes panel
						self.Cloud.MaxW = 300
						self.Cloud.Middle = 0.5
						self.Cloud:SetAbsPos(size/2, -8)
						self.Cloud.RemoveWhenDone = true

					end
					self.Cloud:Popup(true)
				end

				function b:OnCursorExited()
					if not IsValid(self.Cloud) then return end
					self.Cloud:Popup(false)
				end

				function b:DoClick()
					if IsValid(chatbox.frame.chat.input) then
						chatbox.frame.chat.input:SetValue(chatbox.frame.chat.input:GetValue() .. ":" .. self.Emote:GetShortcut() .. ":")
					end
				end
			end

			return list
		end)

		function tab:OnCursorEntered()
			if not coll:GetNiceName() then return end

			if not IsValid(self.Cloud) then
				self.Cloud = vgui.Create("Cloud", self)
				self.Cloud:SetText(coll:GetNiceName())

				self.Cloud.MaxW = emotes:GetWide()
				self.Cloud.Middle = 0.5

				if coll:GetDescription() then
					local desc = coll:GetDescription()

					if isstring(desc) then
						self.Cloud:AddFormattedText(desc, Color(150, 150, 150), "OS18")
					elseif istable(desc) then
						for k,v in pairs(desc) do
							self.Cloud:AddFormattedText(v.txt, v.col or Color(150, 150, 150), v.font or "OS18")
						end
					end

				end

				self.Cloud:SetAbsPos(emotes:GetWide() / 2 - self.X, -32)	--i don't know why i had to subtract self.X tbh
				self.Cloud.RemoveWhenDone = true
			end

			self.Cloud:Popup(true)
		end

		function tab:OnCursorExited()
			if not IsValid(self.Cloud) then return end
			self.Cloud:Popup(false)
		end
	end
end

local function input_type(enter, tab, all)
	return function(pan, key)
		local txt = pan:GetText():Trim()
		all(pan, txt)

		if key == KEY_ENTER then
			if txt ~= "" then
				pan:AddHistory(txt)
				pan:SetText("")

				pan.HistoryPos = 0
			end

			enter(pan, txt)
		end

		if key == KEY_TAB then
			tab(pan, txt)
		end

		if key == KEY_UP then
			pan.HistoryPos = pan.HistoryPos - 1
			pan:UpdateFromHistory()
		end

		if key == KEY_DOWN then
			pan.HistoryPos = pan.HistoryPos + 1
			pan:UpdateFromHistory()
		end

		if key == KEY_ESCAPE then
			pan.HistoryPos = 0
			pan:UpdateFromHistory()
		end
	end
end

local function input_paint(pan, w, h)
	paint_back(pan, w, h, true)

	pan:DrawTextEntryText(chatbox.accent_color, pan:GetHighlightColor(), chatbox.accent_color)
end

local function feed_layout(pan)
	pan:SetFontInternal(chatbox.feed_font)
end

function chatbox.GetModeString()
	return (CHATMODE_TEAM and chatbox.mode == CHATMODE_TEAM or chatbox.mode == true) and "Team" or "Chat"
end

function chatbox.BuildTabChat(self, a)
	self.chat = vgui.Create("DPanel", self.tabs)
	self:DockPadding(0, 24, 0, 0)

		function self.chat:Paint(w, h) end
		self.chat:Dock(FILL)

		self.chat.text_feed = vgui.Create("RichText", self.chat)
			self.chat.text_feed:Dock(FILL)
			self.chat.text_feed:DockMargin(4, 0, 4, 0)

			self.chat.text_feed.PerformLayout = feed_layout

			function self.chat.text_feed:ActionSignal(name, val)
				if name == "TextClicked" then
					if val:match("https://.+") then
						gui.OpenURL(val)
					end
				end
			end
		self.chat.input_base = vgui.Create("DPanel", self.chat)
		self.chat.input_base:Dock(BOTTOM)

		function self.chat.input_base:Paint(w, h)
			draw.RoundedBoxEx(8, 0, 0, w, h, Color(30, 30, 30, 230), false, false, true, true)
		end


		self.chat.input_base:SetHeight(40)
		self.chat.input_base:SetAlpha(220)

			self.chat.emotes = vgui.Create("FButton", self.chat.input_base)
			local emote = self.chat.emotes
			emote:SetSize(32, 32)

			emote:Dock(RIGHT)
			emote:SetColor(Color(40, 140, 250))
			emote:DockMargin(4, 4, 4, 4)

			emote.DoClick = function(self)
				chatbox.OpenEmotesMenu(self)
			end

			function self.chat.emotes:PostPaint(w, h)
				surface.SetDrawColor(color_white)
				surface.DrawMaterial("https://i.imgur.com/4J6pfR0.png", "emotes64.png", 4, 4, w-8, h-8)
			end

			self.chat.input = vgui.Create("FTextEntry", self.chat.input_base)
				self.chat.input:SetFont("OSB18")
				self.chat.input:Dock(FILL)
				self.chat.input:DockMargin(4, 4, 0, 4)

				self.chat.input:SetHistoryEnabled(true)
				self.chat.input.HistoryPos = 0

				self.chat.input.OnKeyCodeTyped = input_type(
				function(pan, txt)
					if txt ~= "" then
						local team = (chatexp and chatbox.mode == CHATMODE_TEAM) or (not chatexp and chatbox.mode == true)

						if chatexp and hook.Run("ChatShouldHandle", "chatexp", txt, chatbox.mode) ~= false then
							chatexp.Say(txt, chatbox.mode)
						elseif chitchat and chitchat.Say and hook.Run("ChatShouldHandle", "chitchat", txt, chatbox.mode and 2 or 1) ~= false then
							chitchat.Say(txt, team and 2 or 1)
						else
							LocalPlayer():ConCommand((team and "say_team \"" or "say \"") .. txt .. "\"")
						end
					end

					chatbox.Close()
				end,
				function(pan, txt)
					local tab = hook.Run("OnChatTab", txt)

					if tab and isstring(tab) and tab ~= txt then
						pan:SetText(tab)
					end

					timer.Simple(0, function() pan:RequestFocus() pan:SetCaretPos(pan:GetText():len()) end)
				end,
				function(pan, txt)
					hook.Run("ChatTextChanged", txt)
				end)

				--self.chat.input.Paint = input_paint

				function self.chat.input:OnChange()
					hook.Run("ChatTextChanged", self:GetText() or "")
				end

				function self.chat.input.Think(pan) pan:SetFont(chatbox.box_font) end

			self.chat.mode = vgui.Create("Panel", self.chat.input_base)
				self.chat.mode:Dock(LEFT)
				self.chat.mode:SetWide(32)

				function self.chat.mode:Paint(w, h)
					local text = chatbox.GetModeString()
					draw.SimpleText(text, chatbox.box_font, w/2, h/2, color_white, 1, 1)
				end

end

local cache = {}
local function get_player(sid)
	if IsValid(cache[sid]) then return cache[sid] end

	for k, v in next, player.GetAll() do
		if v:SteamID() == sid then cache[sid] = v return v end
	end

	return NULL
end

function chatbox.BuildTabSettings(self, a)
	self.settings = vgui.Create("DScrollPanel", self.tabs)
		function self.settings:Paint(w, h) end
		self.settings:Dock(FILL)

		build_settings_from_table(self.settings, chatbox.settings)

		a = self.tabs:AddSheet("Settings", self.settings)
		a.Tab.Paint = tab_paint
		function a.Tab.Think(pan) pan:SetFont(chatbox.box_font) end
end

function chatbox.Build()
	if IsValid(chatbox.frame) then return end

	chatbox.frame = vgui.Create("FFrame")

	local self = chatbox.frame
		self:PopIn()
		self:SetVisible(true)
		self:SetCookieName("chathud")

		self.BackgroundColor.a = 170
		self.HeaderColor.a = 250

		local x = self:GetCookie("x", 20)
		local y = self:GetCookie("y", ScrH() - math.min(650, ScrH() - 350))
		local w = self:GetCookie("w", 600)
		local h = self:GetCookie("h", 350)

		self:SetPos(x, y)
		self:SetSize(w, h)

		self:SetSizable(true)
		self:SetSizablePos(2)

		function self:OnSizeChanged(w, h)
			self:Emit("OnSizeChanged", w, h)
		end

		self:SetMinHeight(145)
		self:SetMinWidth(275)

		self:ShowCloseButton(false)

		--function self.lblTitle.Think(pan) pan:SetFont(chatbox.box_font) end

		function self:PerformLayout()
			local titlePush = 0

			if IsValid(self.imgIcon) then
				self.imgIcon:SetPos(5, 5)
				self.imgIcon:SetSize(16, 16)
				titlePush = 18
			end

			self.btnClose:SetPos(0,0)
			self.btnClose:SetSize(0,0)

			self.btnMaxim:SetPos(0,0)
			self.btnMaxim:SetSize(0,0)

			self.btnMinim:SetPos(self:GetWide() - 31 - 4, 4)
			self.btnMinim:SetSize(32, 18)

			self.lblTitle:SetPos(10 + titlePush, 3)
			self.lblTitle:SetSize(self:GetWide() - 25 - titlePush, 20)
			self.lblTitle:SetColor(chatbox.accent_color)

			if self.direct_messages then
				self.direct_messages.new:SetPos(self:GetWide() - self.direct_messages.new:GetWide() - 8, 30)
			end
		end


	self.tabs = vgui.Create("DPropertySheet", self)
		function self.tabs:Paint(w, h) end
		self.tabs:Dock(FILL)

		local a = {}

		chatbox.BuildTabChat(self, a)

		chatbox.Close(true)
end

function chatbox.GetChatFeed()
	return chatbox.frame.chat.text_feed
end

function chatbox.GetChatInput()
	return chatbox.frame.chat.input
end

function chatbox.GiveChatFocus()
	if not chatbox.IsOpen() then return end

	chatbox.frame.chat.input:RequestFocus()
end

function chatbox.GiveDMFocus(ply)
	if not chatbox.IsOpen() or not chatexp or not IsValid(ply) then return end

	chatbox.AddDMTab(ply)

	chatbox.frame.tabs:SwitchToName("DMs")
	chatbox.frame.direct_messages:SwitchToName(ply:Nick())
	chatbox.frame.direct_messages.tabs[ply:SteamID()].input:RequestFocus()
end

function chatbox.Close(no_hook)
	chatbox.WriteConfig()
	chatbox.GetChatInput():SetText("")

	chatbox.frame:SetMouseInputEnabled(false)
	chatbox.frame:SetKeyboardInputEnabled(false)
	chatbox.frame:SetCloseable(false, true)
	chatbox.Shadow = {intensity = 3}

	chatbox.frame:PopOut(nil, nil, function(_, self) self:SetVisible(false) end)

	chatbox.frame:Emit("OnClose")

	if IsValid(chatbox.frame.dmSelector) then
		chatbox.frame.dmSelector:Remove()
	end

	if not no_hook then hook.Run("FinishChat") end
end

function chatbox.Open(t)
	chatbox.Build()

	if chatexp then
		chatbox.mode = t and CHATMODE_TEAM or CHATMODE_DEFAULT
	else
		chatbox.mode = t
	end

	chatbox.frame:SetVisible(true)
	chatbox.frame:PopIn()
	chatbox.frame:MakePopup()

	chatbox.frame.OnRemove = function()
		chatbox.frame:Emit("OnClose", true)
	end

	chatbox.GiveChatFocus()

	hook.Run("StartChat", t)
	hook.Run("ChatTextChanged", "")
end

return chatbox
