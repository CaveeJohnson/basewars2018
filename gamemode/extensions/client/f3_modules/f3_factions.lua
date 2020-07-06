local ext = basewars.createExtension"f3.factions"
local f3ext = basewars.getExtension"f3.menu"

local brightTextColor = color_white:Copy() --Color for bright text (when V in faction color's HSV is <0.75)
local darkTextColor = color_black:Copy()   --Color for dark text (when V in faction color's HSV is >0.75)

local pushedBorderColor = Colors.Money:Copy()
local alt_pushedBorderColor = color_white:Copy() --Color(255, 60, 60)

local pickBorderColor = function(h, s, v)	--called to determine if we should pick an alternate color for the pushed border; return a color to override

	if (h < 90 or h > 160) or (s < 0.75 and v < 0.75) then --if the faction color isn't a greenish hue and it's pretty dark, return green
		return pushedBorderColor
	else												 --if its a greenish hue and it's pretty bright, return white instead
		return alt_pushedBorderColor
	end
end

local memFont = "OS"

local pickFactionTextColor = function(h, s, v, fcol)
	return v > 0.4 and fcol or color_white
end

local emptyMtrx = Matrix()

local ownerColor = Color(230, 170, 60)			--owner color
local officerColor = color_white:Copy() 	--officer color
local memberColor = Color(160, 160, 160) 	--plebian member color


--expansion of the member list box
--https://i.imgur.com/gp08ObO.png

--i recommend keeping expH = iconExpH

local iconExpH = 4
local expW, expH = 0, iconExpH


local rankPaints = {
	owner = function(lbl, lW, lH, info)
		surface.SetDrawColor(ownerColor)
		surface.DrawMaterial("https://i.imgur.com/ddd8Wca.png", "crown32.png", lW + expW + 8, lH / 2 - 8, 16, 16)
		return 0, 2
	end,

	officer = function(ply, x, y)

	end,

	member = function(ply, x, y)

	end
}

function ext.generateBasePanel(par)	--helper function to create an invis panel which will automatically fill the parent
	local pnl = vgui.Create("InvisPanel", par)
	pnl:SetPos(par.Scroll:GetWide() + 16 + 8, 0) --+16 padding +8 offset for the animation
	pnl:SetSize(par:GetWide() - pnl.X, par:GetTall()) --fuck docking

	pnl:PopIn()
	pnl:MoveBy(-8, 0, 0.3, 0, 0.3)

	function pnl:FadeOut()
		self:SetAlpha(120) --fade out a bit instantly
		self:PopOut()
		self:MoveBy(0, 12, 0.15, 0, 1.7)
	end

	function pnl:Paint(w, h)
		self:Emit("Paint", w, h)
	end

	return pnl
end

function ext.getSortedMembersList(fac)
	local plys = {}

	local hier = fac.hierarchy
	local ow_ply = player.GetBySteamID64(hier.owner)
	local is_bot = hier.owner:match("^900")

	plys[1] = {
		name = (ow_ply and ow_ply:Nick()) or (is_bot and "Some bot") or "[left?]",
		ply = ow_ply,
		rank = "owner",
		col = ownerColor:Copy(),
		prio = 9001,	--the bigger the number, the higher that player will be in the list
							--owner is always at the top regardless of whether or not he's here
	}

	if #hier.officers > 0 then

		plys[#plys + 1] = {
			func = function(x, y, w, h)
				surface.SetDrawColor(Colors.LighterGray)
				surface.DrawLine(x + w/8, y + 2, x + w/2 * 1.75, y + 2)
				return 0, 4
			end,
			prio = 9000
		}

		for k, sid in ipairs(hier.officers) do
			local ply = player.GetBySteamID64(sid)
			local is_bot = sid:match("^900")

			plys[#plys + 1] = {
				name = (ply and ply:Nick()) or (is_bot and "Some bot") or "[left]",
				ply = ply,
				rank = "officer",
				col = officerColor:Copy(),
				prio = (ply and 3) or 2 		--officers that left will show up lower than those that are here
			}
		end

	end

	if #hier.members > 0 then

		plys[#plys + 1] = {
			func = function(x, y, w, h)
				surface.SetDrawColor(Colors.LighterGray)
				surface.DrawLine(x + w/8, y + 2, x + w/2 * 1.75, y + 2)
				return 0, 4
			end,
			prio = 9000
		}

		for k, sid in ipairs(hier.members) do
			local ply = player.GetBySteamID64(sid)
			local is_bot = sid:match("^900")

			plys[#plys + 1] = {
				name = (ply and ply:Nick()) or (is_bot and "Some bot") or "[left]",
				ply = ply,
				rank = "member",
				col = officerColor:Copy(),
				prio = (ply and 1) or 0
			}
		end

	end

	table.sort(plys, function(a, b) return a.prio and b.prio and a.prio > b.prio end)

	return plys
end

function ext.paintMember(lbl, w, h, info)
	local rank = info.rank
	if rankPaints[rank] then
		surface.DisableClipping(true)
			rankPaints[rank](lbl, w, h, info)
		surface.DisableClipping(false)
	end
end

function ext.createMemberList(par, plys)

	local membs = vgui.Create("InvisPanel", par)
	local fac = vgui.Create("Icon", membs)

	membs:SetPos(24, 64)

	local fontHeight = Fonts.PickSize(14 + f3ext.scale * 12)
	local scale = f3ext.scale

	function membs:Paint(w, h)
		--oh lord
		local boxX = fac:GetWide() + 6 - expW
		local boxY = -iconExpH

		local memBoxX = fac:GetWide() + expW + 4
		local memBoxW = w - memBoxX - 8 --8 = member icon padding
		local memBoxH = h + expH

		surface.DisableClipping(true)
			draw.RoundedBoxEx(8, -4, boxY, memBoxX + 4, fac:GetTall() + iconExpH + 4, Colors.DarkGray, true, false, true, false) 	--box behind the icon on the left
			draw.RoundedBoxEx(8, memBoxX - 2, boxY, w - memBoxX + 4, memBoxH + 4, Colors.DarkGray, false, true, true, true)	--black box behind the members
			draw.RoundedBox(8, memBoxX, boxY + 2, w - memBoxX, memBoxH, f3ext.FF.BackgroundColor) --gray box behind the members
		surface.DisableClipping(false)

		--surface.SetDrawColor(Colors.Red)
		--surface.DrawOutlinedRect(memBoxX, boxY, w-memBoxX, memBoxH)
		self:Emit("Paint", w, h)
	end

	

	fac:SetSize(16 + scale * 16, 16 + scale * 16)

	fac.IconURL = "https://i.imgur.com/Nn1MHPd.png"
	fac.IconName = "faction_32.png"

	local x = fac:GetWide() + expW + 8

	local y

	local fullW = 0
	local fullH = 0

	local memLabels = {}

	local addHooks = {}

	function membs:AddMember(info)
		local lbl = vgui.Create("DLabel", membs)
		memLabels[#memLabels + 1] = lbl
		lbl:SetPos(x, y or 0)

		local fnt = memFont .. Fonts.PickSize(12 + f3ext.scale * 14)

		local wraptx = string.WordWrap2(info.name, par:GetWide() - fac:GetWide() - membs.X - 16, fnt)
		local tx = wraptx:gsub("%c.+$", "...") --galaxy brain


		lbl:SetFont(fnt)
		lbl:SetText(tx)
		lbl:SetTextColor(info.col)
		lbl:SizeToContents()
		--lbl:SetWide(lbl:GetWide() + 2)
		lbl:SetMouseInputEnabled(true)

		if not y then
			lbl.Y = fac.Y + fac:GetTall()/2 - lbl:GetTall()/2
			y = lbl.Y
			beginY = y
		end

		fullW = math.max(lbl:GetWide(), fullW)
		local h = lbl:GetTall()

		y = y + h
		lasth = h

		fullH = fullH + h
		function lbl:Paint(w, h)
			self:Emit("Paint", w, h, info)
		end

		lbl:On("Paint", ext.paintMember)
		self:Resize()
	end

	function membs:Resize()
		self:SetSize(fac:GetWide() + expW + 8 + fullW + 2, fullH + 8)
	end

	function membs:ReloadMembers(fac, plys)

		for k,v in ipairs(memLabels) do
			v:Remove()
		end

		for k,v in ipairs(addHooks) do
			membs:RemoveHook("Paint", k)
		end

		memLabels = {}
		addHooks = {}

		fullW = 0
		fullH = 0
		y = nil

		plys = plys or ext.getSortedMembersList(fac)

		for k,v in ipairs(plys) do
			local i = k - 1 --0ind

			if v.func then 	--sometimes you wanna draw something else besides a name

				local addx, addy = v.func(x, y, fullW, fullH, true)

				addHooks[#addHooks + 1] = {v.func, x, y} --we're doing it this way because we need to calculate the highest label width for slot paint,
														 --but we also need to draw these hooks afterwards

				x, y = x + (addx or 0), y + (addy or 0)
			else
				membs:AddMember(v)
			end

		end

		for k,v in ipairs(addHooks) do
			membs:On("Paint", k, function(self, w, h)
				v[1](v[2], v[3], fullW, fullH)
			end)
		end

	end

	membs:ReloadMembers(nil, plys)
	membs:Resize()


	--par:On("Paint", function(self, w, h)

	--end)



	return membs
end

function ext.generateNewFactionControls(par)
	local pnl = ext.generateBasePanel(par)
	pnl.nameLenFrac = 0
	pnl.FactionCreation = true

	local hgtFrac = par:GetTall() / 388
	local txHgt = 32 * hgtFrac

	local name = vgui.Create("FTextEntry", pnl)
	name:SetFont("OSB" .. Fonts.PickSize(txHgt - 2))
	name:SetSize(pnl:GetWide() - (48 * hgtFrac), txHgt)
	name:CenterHorizontal()
	name.Y = 32 * hgtFrac
	name:SetPlaceholderText("Faction name...")

	if ext.lastFacName then
		name:SetValue(ext.lastFacName)
	end

	--[[
	--no faction char limit but i'll leave it here in the event it's ever gonna happen

	local tx, ty = name:GetPos()
	local tw, th = name:GetSize()

	local lenHintCol = Color(170, 170, 170, 0)

	pnl:On("Paint", function(self, w, h)
		local fr = self.nameLenFrac
		print(fr, w, h, tx + tw/2, ty + th - 4 + 8*fr)
		lenHintCol.a = fr * 255

		draw.SimpleText("name char limit would go here", "OS24", tx + tw/2, ty + th - 4 + (8 * fr), lenHintCol, 1, 5)
	end)

	function name:OnGetFocus()
		pnl:To("nameLenFrac", 1, 0.6, 0, 0.3)
	end

	hook.Add("OnTextEntryLoseFocus", name, function(self, pnl)
		if self ~= pnl then return end --?????
		pnl:To("nameLenFrac", 0, 0.4, 0, 1.5)
	end)]]

	local pw = vgui.Create("FTextEntry", pnl)
	pw:SetFont("OSB" .. Fonts.PickSize(txHgt - 2))
	pw:SetSize(pnl:GetWide() - (96 * hgtFrac), txHgt)
	pw:CenterHorizontal()
	pw.Y = name.Y + name:GetTall() + 8
	pw:SetPlaceholderText("Password...")

	if ext.lastFacPW then
		pw:SetValue(ext.lastFacPW)
	end

	local col = vgui.Create("DColorMixer", pnl)
	col.Y = pw.Y + pw:GetTall() + 8
	col:SetPalette(false)
	col:SetLabel(false)
	col:SetAlphaBar(false)

	col:SetSize(pnl:GetWide() - 32, hgtFrac * 150)
	col:CenterHorizontal()

	local h, s, v
	local curcol

	if ext.lastFacCol then
		curcol = ext.lastFacCol
		h, s, v = ColorToHSV(ext.lastFacCol)
	else
		h, s, v = math.random(359), 0.8 + 0.2 * math.random(), 0.8 + 0.2 * math.random()
		curcol = HSVToColor(h, s, v)
	end

	if v > 0.75 then
		name.TextColor = color_black:Copy()
	else
		name.TextColor = color_white:Copy()
	end

	local colmt = FindMetaTable("Color")

	function name:Think()
		self.PHTextColor:Set(self.TextColor)
		self.PHTextColor.a = 125 * self.PHTextFrac

		self.HTextColor:Set(self.TextColor)
		self.HTextColor.a = 150
	end


	function col:ValueChanged(col)
		setmetatable(col, colmt) --ty rubat
		name.BGColor = col
		local h, s, v = ColorToHSV(col)
		if v > 0.75 then
			name:LerpColor(name.TextColor, color_black, 0.4, 0, 0.3)
		else
			name:LerpColor(name.TextColor, color_white, 0.4, 0, 0.3)
		end

		curcol = col
	end

	col:SetColor(curcol)

	local doeet = vgui.Create("FButton", pnl)
	doeet.Y = col.Y + col:GetTall() + 20
	doeet:SetSize(170, 40)
	doeet:CenterHorizontal()

	local me = LocalPlayer()

	local errDT = DeltaText()
	errDT:SetFont("OS" .. Fonts.PickSize(8 + 12 * hgtFrac))
	errDT.AlignX = 1
	--local errpiece = errDT:AddText("")
	--errDT:CycleNext()

	local elems = {}

	--local facname = name:GetValue()
	--local facpw = pw:GetValue()

	--local can, err = basewars.factions.canStartFaction(me, facname, facpw, curcol)
	--create an error for deltapiece instantly

	local green = Color(60, 210, 60)

	function doeet:Think()
		local name = name:GetValue()
		local pw = pw:GetValue()

		local can, err = basewars.factions.canStartFaction(me, name, pw, curcol)
		self.can = can
		self.err = err or self.err

		self:SetColor(can and green or Colors.Button)
	end

	function doeet:DoClick()
		if not self.can then return end

		hook.Add("BW_FactionCreated", pnl, function(self, owsid, fac)
			if ext.curFacPnl == self and owsid == LocalPlayer():SteamID64() then
				ext.fac = fac
				ext.TabFrame:GenerateFactionPanel(fac)
			end
		end)

		local wut, huh = basewars.factions.startFaction(LocalPlayer(), name:GetValue(), pw:GetValue(), col:GetColor())
	end

	local txCol = Color(220, 70, 70)

	--local fragnum, frag = errpiece:AddFragment(err or "", nil, false)
	--frag.Color = txCol
	--frag.AlignX = 1

	--errpiece:SetDropStrength(12)
	--errpiece:SetLiftStrength(-12)

	pnl.errorFrac = 0

	pnl:On("Paint", function(self, w, h)
		if not doeet.can then
			self:To("errorFrac", 1, 0.3, 0, 0.3)
		else
			self:To("errorFrac", 0, 0.2, 0, 0.3)
		end

		local err = doeet.err

		if not doeet.can then

			if not elems[err] then
				local elem, num = errDT:AddText(err)

				elem:SetDropStrength(18)
				elem:SetLiftStrength(18)

				elem.Color = txCol
				elem.AlignX = 1

				elem.error = err

				elems[err] = num

				errDT:ActivateElement(num)
			else--if errDT:GetCurrentElement().error ~= err then
				errDT:ActivateElement(elems[err])
			end
			--local _, fr = errpiece:ReplaceText(fragnum, doeet.err, nil, true)
		else
			if errDT:GetCurrentElement() then
				errDT:DisappearCurrentElement()
			end
		end

		txCol.a = self.errorFrac * 255
		errDT:Paint(w/2, doeet.Y + doeet:GetTall() + (8 * self.errorFrac))
	end)

	pnl:On("Disappear", function()
		ext.lastFacCol = col:GetColor()
		ext.lastFacName = name:GetValue()
		ext.lastFacPW = pw:GetValue()
	end)

	return pnl
end

function ext.generateFactionControls(par, fac)	--panel that lets you control or leave your own faction
	local pnl = ext.generateBasePanel(par)
	pnl.Faction = fac

	local faccol = fac.color

	local ch, cs, cv = ColorToHSV(faccol)
	local picked = pickFactionTextColor(ch, cs, cv, faccol)

	local plys = ext.getSortedMembersList(fac)
	local memblist = ext.createMemberList(pnl, plys)

	hook.Add("BW_FactionJoined", memblist, function(self, fac2, ply)
		if fac ~= fac2 then return end
		self:ReloadMembers(fac)
	end)

	hook.Add("BW_FactionLeft", memblist, function(self, fac2, ply)
		if fac ~= fac2 then return end
		self:ReloadMembers(fac)
	end)

	local fac = ext.fac
	local sid = LocalPlayer():SteamID64()

	local rank = ext.fac.hierarchy_reverse[sid]
	local isowner = rank == "owner"
	local memamt = ext.fac.flat_member_count

	pnl:On("Paint", function(self, w, h)
		draw.SimpleText(fac.name, "OSB36", w/2, 8, picked, 1, 5)
	end)

	local disband = vgui.Create("FButton", pnl)
	local btnW = 80 + f3ext.scale * 70

	disband:SetSize(btnW, 25 + f3ext.scale * 20)
	local pad = 4 + 12 * f3ext.scale

	disband.X = pnl:GetWide()/2 - btnW - pad
	disband.Y = pnl:GetTall() - disband:GetTall() - 10

	disband.Font = "OS" .. Fonts.PickSize(16 + f3ext.scale * 8)


	local red = Color(190, 70, 70)			--used for Leave Faction
	local brighterred = Color(220, 100, 100) --used for shake animation for leave, also used for cloud error if the player attempts to disband a faction while not being the owner

	local darkred = Color(150, 40, 40)		--used for Disband Faction
	local brightred = Color(210, 80, 80)	--used for shake animation for disband

	disband.Color = (isowner and darkred) or Colors.Button

	disband.LastHold = 0
	disband.HoldFrac = 0
	disband.LeaveTime = 3

	local function ShakeThink(self, orX, orY)
		local shake = 6
		local needTime = self.LeaveTime

		if self:IsDown() and not self.NoShake then
			self.HoldFrac = math.min(1, self.HoldFrac + FrameTime()/needTime)
			self.LastHold = CurTime()
			shake = shake * self.HoldFrac
		elseif CurTime() - self.LastHold > 0.5 or self.NoShake then
			self.HoldFrac = math.max(0, self.HoldFrac - FrameTime()/needTime)
			shake = shake * self.HoldFrac / 3
		else
			shake = shake * self.HoldFrac / 1.5
		end

		self:SetPos(orX + math.random(-shake, shake), orY + math.random(-shake, shake))

		if self.HoldFrac == 1 and not self.NoShake then
			self:FullShake()
		end
	end

	local disX, disY = disband:GetPos()
	local fac

	function disband:Think()
		fac = ext.fac
		if not fac then return end

		rank = fac and fac.hierarchy_reverse[sid]
		isowner = rank == "owner"

		if isowner then ShakeThink(self, disX, disY) end
	end

	function disband:PostPaint(w, h)
		local sx, sy = self:LocalToScreen(0, 0)
		local fr = Ease(self.HoldFrac, 0.2)
		render.SetScissorRect(sx, sy, sx + w * fr, sy + h, true)
			draw.RoundedBox(self.RBRadius, 0, 0, w, h, brightred)
		render.SetScissorRect(0, 0, 0, 0, false)

		draw.SimpleText("Disband Faction", self.Font, w/2, h/2, color_white, 1, 1) --doing it in postpaint because of the roundedbox above
	end

	function disband:OnHover()
		if not isowner then
			local cl, new = self:AddCloud("whynot")
			if new then
				cl.Font = "OS20"
				cl:SetText("Only the owner can disband a faction!")
				cl.TextColor = brighterred
				cl.MaxW = 500
				cl:SetRelPos(self:GetWide() / 2, -4)
				cl.ToY = -8

				ext.FF:On("Hide", cl, function()
					cl:Remove()
				end)
			end
		end
	end

	function disband:OnUnhover()
		self:RemoveCloud("whynot")
	end

	function disband:FullShake()
		fac = ext.fac
		if not fac then return end

		if not isowner then return end
		basewars.factions.sendEvent("disband")
		self.NoShake = true
	end

	local leave = vgui.Create("FButton", pnl)
	leave:SetSize(disband:GetSize())
	leave.X = pnl:GetWide()/2 + pad
	leave.Y = disband.Y
	leave.Color = red
	leave.Font = "OS" .. Fonts.PickSize(16 + f3ext.scale * 8)

	local lX, lY = leave:GetPos()

	leave.HoldFrac = 0
	leave.LastHold = 0
	leave.LeaveTime = 1.5

	local canLeave = false

	function leave:Think()
		fac = ext.fac
		if not fac then return end

		memamt = fac.flat_member_count

		if memamt > 1 then canLeave = true elseif isowner then canLeave = false end

		if canLeave then
			ShakeThink(self, lX, lY)
			self:SetColor(red)
		else
			self:SetColor(Colors.Button)
		end

	end

	function leave:PostPaint(w, h)
		local sx, sy = self:LocalToScreen(0, 0)
		local fr = Ease(self.HoldFrac, 0.2)

		render.SetScissorRect(sx, sy, sx + w * fr, sy + h, true)
			draw.RoundedBox(self.RBRadius, 0, 0, w, h, brighterred)
		render.SetScissorRect(0, 0, 0, 0, false)

		draw.SimpleText("Leave Faction", self.Font, w/2, h/2, color_white, 1, 1) --doing it in postpaint because of the roundedbox above

	end

	function leave:FullShake()
		fac = ext.fac

		if not fac then return end
		if not canLeave then return end

		ext.fac = nil
		ext.TabFrame:GenerateFactionPanel()

		local can = basewars.factions.sendEvent("leave")
		self.NoShake = true
		self.drawColor:Set(brighterred)
		self:SetColor(Colors.Button)
	end

	function leave:OnHover()
		if not canLeave then
			local cl, new = self:AddCloud("whynot")
			if new then
				cl.Font = "OS20"
				cl:SetText("You can't leave a faction as the only person in it!")
				cl.TextColor = brighterred
				cl.MaxW = 500
				cl:SetRelPos(self:GetWide() / 2, -4)
				cl.ToY = -8
				ext.FF:On("Hide", cl, function()
					cl:Remove()
				end)
			end
		end
	end

	function leave:OnUnhover()
		self:RemoveCloud("whynot")
	end

	local btn = vgui.Create("FButton", pnl)
	btn:SetSize(36, 36)

	local ph = ( f3ext.FF:GetTall() - f3ext.FF.HeaderSize) / 2
	btn.Y = ph/2 + par.Y - btn:GetTall() / 2

	btn.X = pnl:GetWide() - 64
	--btn.X = pnl:GetWide()/2 - 170 - 8

	btn.Font = "OS12"
	local shad = btn.Shadow

	shad.Intensity = 4
	shad.MaxSpread = 1
	shad.HoverSpeed = 0.1
	shad.UnhoverSpeed = 0.1
	shad.HoverEase = 0.3

	btn.rot = 0

	local bCol = color_white:Copy()

	function btn:DrawButton(x, y, w, h)

		surface.SetDrawColor(color_white)
		surface.DrawMaterial("https://i.imgur.com/ik8nyZx.png", "invite_64.png", x + w/2, y + h/2, w, h, self.rot*20)

	end

	function btn:PostPaint(w, h) --don't shadow the wind boxes

		surface.DisableClipping(true)
			bCol.a = (self.rot^4)*255

			if self.rot > 0 then
				for i=1, 3 do
					local bx = i*6 - self.rot*8 - self.rot*(i*6) - 4
					local by = h/2 + (i-2)*h/4

					local bw = 8+6*i

					draw.RoundedBox(2, bx - bw, by, 8 + 6*i, 4, bCol)
				end
			end
		surface.DisableClipping(false)

	end

	function btn:OnHover()
		self:To("rot", 1, 0.4, 0, 0.2)
		local cl, new = self:AddCloud("tip", "Invite Members")

		if new then

			cl:SetRelPos(self:GetWide() / 2, -8)
			ext.FF:On("Hide", cl, function()
				cl:Remove()
			end)

		end

	end

	function btn:OnUnhover()
		self:To("rot", 0, 0.4, 0, 0.2)
		self:RemoveCloud("tip")
	end
	btn.Color = Color(70, 180, 70)

	return pnl
end

function ext.generateFactionActions(par)	--panel that gives you the options to create your own faction
	local pnl = ext.generateBasePanel(par)

	function pnl:Paint(w, h)
		draw.SimpleText("no fac dude", "OSB36", w/2, 8, color_white, 1, 5)
	end

	return pnl
end

function ext.generateFactionPanel(par, fac)	--faction panel that gives you more info about a faction you selected

	local pnl = ext.generateBasePanel(par)
	pnl.Faction = fac

	local faccol = fac.color

	local ch, cs, cv = ColorToHSV(faccol)
	local picked = pickFactionTextColor(ch, cs, cv, faccol)

	function pnl:FadeOut()
		self:PopOut()
		self:MoveBy(0, 12, 0.15, 0, 2)
	end

	--https://i.imgur.com/Cf8EYa7.png : crown icon

	local plys = ext.getSortedMembersList(fac)
	local memblist = ext.createMemberList(pnl, plys)

	hook.Add("BW_FactionJoined", memblist, function(self, fac2, ply)
		if fac ~= fac2 then return end
		self:ReloadMembers(fac)
	end)

	hook.Add("BW_FactionLeft", memblist, function(self, fac2, ply)
		if fac ~= fac2 then return end
		self:ReloadMembers(fac)
	end)

	pnl:On("Paint", function(self, w, h)
		draw.SimpleText(fac.name, "OSB36", w/2, 8, picked, 1, 5)
	end)

	return pnl
end


local facBtns = {
	--[[
	[1] = {btn, fac},
	...
	]]
}

function ext:BW_FactionCreated(owsid, fac)
	if IsValid(self.Scroll) then
		self.Scroll:AddButton(fac)
	end
end

function ext:BW_FactionDisband(disfac)
	for k, t in ipairs(facBtns) do
		if t[2] == disfac and IsValid(t[1]) then
			t[1]:GetOut()
		end
	end

	if self.fac == disfac then
		self.fac = nil
	end

	local curtab = self.curFacPnl

	if IsValid(curtab) and curtab.Faction == disfac then
		ext.TabFrame:GenerateFactionPanel()
	end

end

function ext.addFactionButton(scr, fac)

	local name = fac.name
	local col = fac.color
	local membcount = fac.flat_member_count

	local btn = vgui.Create("FButton", scr)
	facBtns[#facBtns + 1] = {btn, fac}

	local key = #facBtns
	scr.Buttons[key] = btn

	btn.DrawShadow = false
	btn:SetSize(scr:GetWide() - 16, 48)

	local btnY = 8 + (56 * (key - 1))
	btn:SetPos(8, btnY) 	--[pain]

	--btn:Dock(TOP) --fuck docking you can't make pop out animations with docking
	--btn:DockMargin(0, 4, 0, 4)

	btn.key = key

	local ch, cs, cv = ColorToHSV(col)
	local txCol = cv > 0.75 and darkTextColor or brightTextColor

	btn.DominantColor = txCol

	local nch = ch
	local ncs = math.min(cs, 0.6)
	local ncv = math.max(cv * 0.7, 0.05)

	local newcol = HSVToColor(nch, ncs, ncv)
	local borderColor = pickBorderColor(nch, ncs, ncv)

	btn:SetColor(newcol.r, newcol.g, newcol.b)

	btn.HovMult = 1.2
	btn.SelTime = 0
	btn.Selected = false

	function btn:GetOut() 	--this is pain
		local x = self.X 	--i have no idea how this will behave if there are two factions which got disbanded simultaneously; i can't test it properly with bots
		local k = self.key

		local ended = false



		local function OnEnd()

			if not ended then 	--if this is the first time we ended an animation, erase the button from the buttons list
				ended = true
				table.remove(facBtns, k)
			else 				--otherwise, make sure every button is on the proper Y axis

				for i=1, #facBtns do

					local btn = facBtns[i] and facBtns[i][1]
					if IsValid(btn) then
						btn.Y = 8 + (56 * (i - 1))
					end
				end

			end

		end


		self:InElastic(0.6, 0, function(_, _, fr) --yeet the button to the right (elastic animation)
			self.X = x + fr*(scr:GetWide() + 8)
		end, function()
			self:Remove()
			OnEnd()
		end, 1.6, 1.3, 1.15)

		for i=k, #facBtns do
			local btn = facBtns[i] and facBtns[i][1]
			if not IsValid(btn) then continue end

			btn.newIndex = (btn.newIndex or i-1) - 1

			if btn.shiftAnim then
				btn.shiftAnim:Stop()
			end

			btn.shiftAnim = btn:MoveTo(btn.X, 8 + (56 * btn.newIndex), 1, 0.75, 0.1)
		end

		--[[
		local a = scr:NewAnimation(1, 0.75, 0.1) 	--shift every other button up

		a.Think = function(_, _, fr)
			for i=k, #facBtns do
				local btn = facBtns[i] and facBtns[i][1]
				local ni = btn.NewIndex
				if IsValid(btn) then
					btn.Y = 8 + (56 * ni) - (56*fr)
				end
			end
			--self:DockMargin(0, 4, 0, 4 - (self:GetTall() + 4)*fr)

		end

		a.OnEnd = function()
			OnEnd()
		end]]
	end

	function btn:PushedPaint(w, h) --what's painted behind the pushed button
		draw.RoundedBox(8, 2, 0, w - 4, h, borderColor)
	end

	function btn:FactionPaint(w, h)
		membcount = fac.flat_member_count
		draw.SimpleText(name, "OSB24", w/2, 2, txCol, 1, 5)

		local tW, tH = draw.SimpleText("Members: " .. membcount, "OS18", 8 + 20 + 4, h - 4, self.DominantColor, 0, 4)

		surface.SetDrawColor(self.DominantColor)
		surface.DrawMaterial("https://i.imgur.com/Nn1MHPd.png", "faction_32.png", 8, h - 4 - tH/2 - 8, 20, 20)
	end

	----------------------


	local mtrx = Matrix()

	function btn:PrePaint(w, h)
		local frac = math.min( (CurTime() - self.SelTime) / 0.5, 1 )
		frac = Ease(frac, 0.2)

		if not self.Selected then
			frac = 1 - frac
		end

		self.Frac = frac

		if frac >= 0.05 then self:PushedPaint(w, h) end

		mtrx:Set(emptyMtrx)
		local x, y = self:LocalToScreen(w/2, h/2)

		local tr = Vector(x, y, 0)
		local scale = Vector(1 - frac*0.04, 1 - frac*0.06, 1)

		mtrx:Translate(tr)
			mtrx:Scale(scale)

		tr:Mul(-1)
		mtrx:Translate(tr)

		render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		cam.PushModelMatrix(mtrx)
	end

	function btn:PostPaint(w, h)

		local ok, err = pcall(self.FactionPaint, self, w, h)

		cam.PopModelMatrix()
		render.PopFilterMin()
		if not ok then
			error(err)
		end

	end

	return btn
end


function ext:F3_CreateTab(FF)
	for k,v in pairs(facBtns) do
		if IsValid(v) then v:Remove() end
	end
	facBtns = {}

	ext.fac = LocalPlayer():getFaction()
	ext.FF = FF

	local btn = FF:AddTab("Factions", function(navpnl, tab, oldpanel, hasanim)

		if IsValid(oldpanel) then
			return oldpanel
		end

		local f = vgui.Create("InvisPanel", FF)
		ext.TabFrame = f
		FF:PositionPanel(f) 	--has to be done to make correct sizes n' shit

		local scr = vgui.Create("FScrollPanel", f)
		f.Scroll = scr
		f.MainFrame = FF

		scr:SetWide(150 + f3ext.scale * 100)
		scr:Dock(LEFT)
		scr:InvalidateParent(true)
		scr.GradBorder = true
		scr:DockMargin(0, 0, 0, 48)
		scr:GetCanvas():DockPadding(8, 4, 8, 0)
		scr.Buttons = {}

		ext.Scroll = scr

		local selBtn

		local curFacPnl

		function f:SetCurrentPanel(pnl)
			if IsValid(curFacPnl) then
				curFacPnl:FadeOut()
				curFacPnl:Emit("Disappear")
				curFacPnl = nil
			end

			curFacPnl = pnl
			ext.curFacPnl = curFacPnl
			curFacPnl:Emit("Appear")
		end

		local gray = Color(45, 45, 45)
		f.PushedColor = gray

		function f:Paint(w, h)
			local x = w - scr:GetWide() - 16

			draw.RoundedBoxEx(9, scr:GetWide() + 16, 0, w - scr:GetWide() - 16, h, self.PushedColor, false, false, false, true)

			surface.SetMaterial(MoarPanelsMats.gl)
			surface.SetDrawColor(20, 20, 20)
			surface.DrawTexturedRect(scr:GetWide() + 16, 0, 4, h + 16)

			surface.SetMaterial(MoarPanelsMats.gu)
			surface.DrawTexturedRect(scr:GetWide() + 16, 0, w - scr:GetWide() - 8, 4)

		end

		function f:GenerateFactionPanel(btnfac)
			local valid = IsValid(curFacPnl)

			if valid and curFacPnl.Faction and curFacPnl.Faction == (btnfac or ext.fac) then return end --if we're trying to view the same faction we're viewing ; bail

			local newpnl

			if btnfac then 	--button preview enabled

				if btnfac == ext.fac then 	--trying to preview your own faction; enable controls instead
					newpnl = ext.generateFactionControls(self, ext.fac)
				else 					--enable preview for other factions
					newpnl = ext.generateFactionPanel(self, btnfac)
				end

			elseif ext.fac then 											--button preview disabled; return to old controls/actions panel
				newpnl = ext.generateFactionControls(self, ext.fac)			--has faction; switch to controls
			else
				newpnl = ext.generateFactionActions(self)				--doesn't have faction; switch to actions
			end

			self.CreateFactionBtn:Deactivate(true)
			self:SetCurrentPanel(newpnl)
		end

		function scr:AddButton(fac)

			local btn = ext.addFactionButton(self, fac)

			function btn:DoClick()

				if IsValid(selBtn) then
					selBtn.Selected = false
					selBtn.SelTime = CurTime()
				end

				if selBtn == self then
					selBtn = nil
					f:GenerateFactionPanel()
					return
				end

				selBtn = self

				self.SelTime = CurTime()
				self.Selected = true

				f:GenerateFactionPanel(fac)
			end

		end

		local makeFac = vgui.Create("FButton", f)
		makeFac:SetPos(scr.X + 24, f:GetTall() - 44)
		makeFac:SetSize(scr:GetWide() - 48, 40)
		makeFac.Font = "OS" .. Fonts.PickSize(16 + 10 * f3ext.scale)

		local ply = LocalPlayer()
		local canCol = Color(65, 190, 65)
		makeFac.Color = (basewars.factions.eligibleForCreation(ply) and canCol) or Colors.Button

		function makeFac:Think()
			local can, err = basewars.factions.eligibleForCreation(ply)

			self.can = can
			self.error = err and err:gsub("%p$", "") .. "!" --exclamate it!

			if not can then
				self.Color = Colors.Button
			else
				self.Color = canCol
			end
		end

		function makeFac:OnHover()

			if not self.can then
				local cl, new = self:AddCloud("whynot")
				if new then
					cl.MaxW = 450
					cl.Font = "OS20"

					cl.ToY = 4
					cl.TextColor = Color(230, 80, 80)
					cl.YAlign = 0
					cl:SetRelPos(self:GetWide()/2, self:GetTall() + 8)

					cl:SetText(self.error)

					FF:On("Hide", cl, function()
						cl:Remove()
					end)

				end
			end

		end

		function makeFac:OnUnhover()
			self:RemoveCloud("whynot")
		end

		makeFac.Label = "Create faction"

		makeFac.Shadow.MaxSpread = 0.4
		makeFac.Shadow.Color = Color(50, 50, 50)
		makeFac.Shadow.Color2 = Color(25, 25, 25)
		makeFac.Shadow.Alpha = 150
		makeFac.ShadowFrac = 0

		local activeShadCol = Color(25, 25, 25)
		local inactiveShadCol = color_black

		--yes its a plus icon stfu
		makeFac:SetIcon("https://i.imgur.com/dO5eomW.png", "plus.png", 8 + 12 * f3ext.scale, 8 + 12 * f3ext.scale)

		function makeFac:PrePaint()
			draw.LerpColorFrom(self.ShadowFrac, inactiveShadCol, activeShadCol, self.Shadow.Color2)
		end

		function makeFac:DoClick()

			if curFacPnl and curFacPnl.FactionCreation then --let them close the creation pnl even if they can't make a faction
				self:Deactivate()
			elseif self.can then
				self:Activate()
			end

		end

		function makeFac:Activate()
			local newPnl = ext.generateNewFactionControls(f)
			f:SetCurrentPanel(newPnl)
			self.ForceHovered = true
			self.Shadow.MaxSpread = 0.7

			self:Lerp("ShadowFrac", 1, 1, 0, 0.4)
		end

		function makeFac:Deactivate(nopnl)
			if not nopnl then f:GenerateFactionPanel() end --reset panel and close faction creation panel
			self.ForceHovered = false
			self.Shadow.MaxSpread = 0.4

			self:Lerp("ShadowFrac", 0, 0.2, 0, 0.3)
		end

		f.CreateFactionBtn = makeFac

		local list = basewars.factions.getList()
		local facs = {}

		for k,v in pairs(list) do
			facs[#facs + 1] = v
		end

		table.sort(facs, function(a, b) return (a.flat_member_count > b.flat_member_count) or (a.core:EntIndex() > b.core:EntIndex()) end)


		for k, fac in ipairs(facs) do
			scr:AddButton(fac)
		end


		f:GenerateFactionPanel()	--generate first faction panel

		return f
	end)
	
	FF:SelectTab("Factions", true)

	FF:On("Show", function()
		self.fac = LocalPlayer():getFaction()
	end)

	btn:SetIcon("https://i.imgur.com/MLRSYYG.png", "faction.png")
	btn:SetDescription("faction n' shit")

	_wtf = btn

	local btn = FF:AddTab("settings or smth", function(_, navbar)
		local b = vgui.Create("FButton", FF)
		FF:PositionPanel(b)
		b.Label = "Jebaited no settings yet Jebaited"
		b:PopIn()
		return b
	end)

	btn:SetIcon("https://i.imgur.com/ZDzJwTM.png", "gear64.png")
	btn:SetDescription("poggers settings, you can setup so much shit!!! fuckin AMAZING")
end

hook.Run("F3_ModuleLoaded", ext)