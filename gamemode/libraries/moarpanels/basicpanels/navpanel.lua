
local btnPaint = function(self, w, h)
	local col = self.Color
	surface.SetDrawColor(col.r, col.g, col.b, col.a)
	surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png", w/2, h/2, w, h, self.Rotation)
end

local holderPaint = function(self, w, h)
	local navbar = self:GetParent()

	local x = 0

	if navbar.X < 0 then --ew
		x = -navbar.X
	end

	surface.SetDrawColor(self.Color)
	surface.DrawRect(0, 0, w, h)

	--[[surface.DisableClipping(true)
		surface.SetMaterial(MoarPanelsMats.gu)
		local gc = self.GradColor
		surface.SetDrawColor(gc.r, gc.g, gc.b, gc.a)
		surface.DrawTexturedRect(x, h, w - x, 3)
	surface.DisableClipping(false)]]
end

--[[

	A navbar choice

]]

local NavbarChoice = {}
local questionMark

hook.Add("OnScreenSizeChanged", "garry_die", function()
	questionMark = nil
end)

function NavbarChoice:Init()
	self:SetText("")
	self:SetTall(64)
	self.TextColor = color_white:Copy()

	questionMark = questionMark or draw.RenderOntoMaterial("questionMark", 48, 48, function(w, h)
		draw.SimpleText("?", "MRB72", w/2, h/2, color_white, 1, 1)
	end)

	self.Icon = Icon(questionMark)
	self.IconSize = self:GetTall() * 0.6

	self.DescriptionFont = "OSL16"
	self.DescriptionColor = Color(170, 170, 170)
	self.DescriptionFontShiftUpwards = 4 --source text alignment >:(
	self.DescriptionFontHeight = 14 --?????????????? draw.DrawText sucks because vertical spacing is fucking HUGE
									-- 				 amd we're kinda limited on that

	self.SelectedColor = Color(60, 150, 250, 150)
	self.SelectedGradColor = Color(250, 250, 100, 150)
	self.GradDistance = 250

	self.ActiveFrac = 0
end

function NavbarChoice:OnSizeChanged(nw, nh)
	self.IconSize = self:GetTall() * 0.6
	if self.Description then
		self.WrappedDescription = self.Description:WordWrap2(self:GetWide() - 16 - self.IconSize, self.DescriptionFont)
		local _, newlines = self.WrappedDescription:gsub("[^%c]+", "")
		self.DescripitionNewlines = newlines
	end
end

function NavbarChoice:OnRetract(nav)
	self:Emit("Retract", nav)
end

function NavbarChoice:OnExpand(nav)
	self:Emit("Expand", nav)
end

function NavbarChoice:PrePaint()
end

function NavbarChoice:PostPaint()
end

function NavbarChoice:SetIcon(url, name, h)
	local ic = Icon(url, name)
	self.Icon = ic

	self.IconSizeOverride = h
end

AccessorFunc(NavbarChoice, "Name", "Name")


function NavbarChoice:SetDescription(desc)
	self.Description = desc
	self.WrappedDescription = desc:WordWrap2(self:GetWide() - self.IconSize - 4 - 16, self.DescriptionFont)
end

function NavbarChoice:ActiveMask(w, h, frac)
	if frac == 0 then return end

	surface.SetDrawColor(0, 0, 0, 255)
	local leg_length = 48

	local tx = -(w + leg_length) * (1 - frac)
	draw.RightTrapezoid(tx, 0, w + leg_length, h, leg_length, true)
end

function NavbarChoice:ActivePaint(w, h, frac)
	if frac == 0 then return end

	surface.SetDrawColor(self.SelectedColor:Unpack())
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(self.SelectedGradColor:Unpack())
end

function NavbarChoice:GetExpFrac(frac, easein, easeout)
	local nav = self.Navbar

	if nav.Expanded then
		frac = Ease(frac, easein)
	else
		frac = 1 - Ease(1 - frac, easeout)
	end

	return frac
end

function NavbarChoice:Draw(w, h)

	local nav = self.Navbar

	if not self.Active then
		self:To("ActiveFrac", 0, 0.2, 0, 1.8)
	else
		self:To("ActiveFrac", 1, 0.4, 0, 0.3)
	end

	draw.Masked(self.ActiveMask, self.ActivePaint, nil, nil, self, w, h, self.ActiveFrac)

	local ix = 8
	local tx = 4

	local frac = self:GetExpFrac(nav.ExpandFrac, 0.8, 0.5)

	local size = self.IconSizeOverride or self.IconSize

	--  when expanded becomes 8,		when expanded, becomes 8 (padding from left edge)
	--  otherwise centers				otherwise, becomes the left edge of visible area (area that's not clipped by parent)
	ix = Lerp(frac, nav.RetractedSize/2 - size/2, 8) + Lerp(frac, nav:GetWide() - nav.RetractedSize, 0)

	self.Icon:Paint(ix, h/2 - size/2, size, size)

	local frac = self:GetExpFrac(nav.ExpandFrac, 0.9, 0.5) 	--different frac; more eased so text goes to the right faster than the icon
															--(and goes left slower)

	tx = ix + size + Lerp(frac, size, 0) + 4
	self.TextColor.a = 255 * (nav.ExpandFrac - 0.35) * 1/0.65 	--mmmmmm yes cancer maths
																--(basically makes so text is invisible until 35% expanded)


	draw.SimpleText(self.Name, "BS22", tx, 2, self.TextColor, 0, 5)

	if self.WrappedDescription then
		local frac = math.max((nav.ExpandFrac - 0.4) * 1/0.6, 0)
		frac = self:GetExpFrac(frac, 0.9, 0.5)
		local descx = ix + size + Lerp(frac, size, 0) + 4 + 4

		local height = self.DescripitionNewlines * self.DescriptionFontHeight
		local space = self:GetTall() - 24
		local ty = 24 + space/2 - height/2 - self.DescriptionFontShiftUpwards
		--surface.SetDrawColor(Colors.Red)
		--surface.DrawOutlinedRect(descx, ty, w - descx, height)

		local i = 0
		surface.SetFont(self.DescriptionFont) 					-- microoptimization reeeeeeeeeee
		surface.SetTextColor(self.DescriptionColor:Unpack()) 	-- (coulda just used draw.SimpleText but im not aligning anyways and im drawing multiple lines, so)

		for s in self.WrappedDescription:gmatch("[^%c]+") do
			surface.SetTextPos(descx, ty + i * self.DescriptionFontHeight)
			surface.DrawText(s)
			i = i + 1
		end
	end
end

function NavbarChoice:Paint(w, h)
	self:PrePaint(w, h)
	self:Draw(w, h)
	self:PostPaint(w, h)
end

function NavbarChoice:OnSelect()
end

function NavbarChoice:Select(noanim)
	if self.Active then return end
	local can = self:OnSelect()
	if can == false then return end

	self.Navbar:OnSelect(self, noanim)
	self.Active = true
	if noanim then
		self.ActiveFrac = 1
	end
end

function NavbarChoice:DoClick()
	self:Select()
end

vgui.Register("NavbarChoice", NavbarChoice, "DButton")
--[[

	The navbar itself

]]

local RoundingMask = function(scr, w, h)
	local nav = scr.Navbar
	local x = -nav.X
	draw.RoundedPolyBox(8, x, 0, w, h, color_white, true, true, false, true)
end

local Navbar = {}

function Navbar:Init()
	local showHolder = vgui.Create("InvisPanel", self)
	showHolder:SetSize(self:GetWide(), 28)
	showHolder:Dock(TOP)
	showHolder:SetMouseInputEnabled(true)

	showHolder.GradColor = Color(25, 25, 25)
	showHolder.Color = Colors.Gray:Copy()

	showHolder.Paint = holderPaint
	showHolder.Navbar = self

	self.ShowHolder = showHolder

	local show = vgui.Create("DButton", showHolder)
	show:SetSize(20, 20)
	show:CenterVertical()
	show:SetText("")
	show.Color = color_white:Copy()
	show.Paint = btnPaint
	show.Rotation = 0

	show.DoClick = function(btn)
		self:OnClick(btn)
	end

	show.Navbar = self

	self.ShowBtn = show

	local scr = vgui.Create("FScrollPanel", self)
	scr:Dock(FILL)
	scr.BackgroundColor = Color(40, 40, 40)


	scr.Navbar = self

	scr.GradBorder = true
	function scr:Draw()
	end

	function scr:PaintOver(w, h)
		surface.SetDrawColor(0, 0, 0)
		draw.Masked(RoundingMask, self.DrawBorder, nil, nil, self, w, h, self:GetBorders())
		self:Emit("PaintOver", w, h)
	end

	self.Scroll = scr

	self.Active = false

	self.Color = Color(40, 40, 40)
	self.GradColor = color_black:Copy()

	self.ExpandFrac = 0
	self.RetractedSize = 50

	self.Tabs = {}
end

function Navbar:OnClick()
	local btn = self.ShowBtn

	self.Active = not self.Active
	btn.Active = self.Active

	if self.Active then
		self:Expand(btn)
	else
		self:Retract(btn)
	end
end

function Navbar:OnSelect(btn, noanim)
	if IsValid(self.ActiveBtn) then
		self.ActiveBtn:Emit("Deselect", self, noanim)
		self.ActiveBtn.Active = false
	end

	self.ActiveBtn = btn
	btn.Active = true
	btn:Emit("Select", self, noanim)
end

function Navbar:Expand()
	local btn = self.ShowBtn
	btn:To("Rotation", 180, 0.7, 0, 0.2)

	local anim = self:MoveTo(0, self.Y, 0.4, 0, 0.3)
	local oldfrac = self.ExpandFrac

	anim:On("Think", function(anim, frac)
		self.ExpandFrac = Lerp(frac, oldfrac, 1)
	end)

	btn:MoveBy(-8, 0, 0.2, 0.3, 0.3)

	self.Expanded = true
	self:Emit("Expand")
	--self.Scroll:AlphaTo(255, 0.3, 0)
	--self.Scroll:SetMouseInputEnabled(true)
end

function Navbar:Retract()
	local btn = self.ShowBtn
	btn.Rotation = btn.Rotation - 360 --flip it around so it lerps the opposite way
	btn:To("Rotation", 0, 0.7, 0, 0.2)

	local oldfrac = self.ExpandFrac
	local anim = self:MoveTo(-self:GetWide() + self.RetractedSize, self.Y, 0.4, 0, 0.3)

	anim:On("Think", function(anim, frac)
		self.ExpandFrac = Lerp(frac, oldfrac, 0)
	end)

	btn:MoveBy(8, 0, 0.2, 0.3, 0.3)

	self.Expanded = false
	self:Emit("Retract")
	--self.Scroll:AlphaTo(50, 0.3, 0)
	--self.Scroll:SetMouseInputEnabled(false)
end

function Navbar:GetExpanded()
	return self.Expanded, self.ExpandFrac
end

function Navbar:Add(fr)
	self.Scroll:Add(fr)
	fr.Navbar = self
	fr.Scroll = self.Scroll
	fr:Dock(TOP)
	fr:DockPadding(0, 8, 0, 8)

	self:On("Retract", fr, function(self)
		fr:OnRetract(self)
	end)

	self:On("Expand", fr, function(self)
		fr:OnExpand(self)
	end)

	self.Tabs[#self.Tabs + 1] = fr
end

function Navbar:PrePaint()
end

function Navbar:PostPaint()
end

function Navbar:Draw(w, h)

	local x = 0

	if self.X < 0 then  -- if its too far to the left, find the proper X for the
		x = -self.X 	-- rounded box to match the parent's bottom-left rounding
	end

	draw.RoundedBoxEx(8, x, 0, w, h, self.Color, false, false, true, false)

	surface.DisableClipping(true)
		surface.SetMaterial(MoarPanelsMats.gl)
		local gc = self.GradColor
		surface.SetDrawColor(gc.r, gc.g, gc.b, gc.a)
		surface.DrawTexturedRect(w, 0, 3, h)
	surface.DisableClipping(false)
end

function Navbar:Paint(w, h)
	self:PrePaint(w, h)
	self:Draw(w, h)
	self:PostPaint(w, h)
end

function Navbar:PerformLayout(w, h)
	if not w then return end

	local show = self.ShowHolder

	if IsValid(show) and self.LastWidth ~= w then
		show:SetWide(w)
		self.ShowBtn.X = w - 24
	end

	self.LastWidth = w
	self.LastHeight = h
end

vgui.Register("Navbar", Navbar, "InvisPanel")

local NavPanel = {}

function NavPanel:Init()

	self.BackgroundColor = Color(55, 55, 55)
	self.HeaderColor = Color(45, 45, 45)
	local navbar = vgui.Create("Navbar", self)
	navbar:SetPos(-150, self.HeaderSize)
	navbar:SetWide(200)

	navbar:On("Expand", function(...)
		self:GenerateInvisibleButton(...)
	end)

	navbar:On("Retract", function(...)
		self:RemoveInvisibleButton(...)
	end)

	self.RetractedSize = 50
	self.Navbar = navbar

	local canv = vgui.Create("InvisPanel", self)
	canv:SetPos(navbar.X + navbar:GetWide(), self.HeaderSize)

	self.Canvas = canv
	self:DockPadding(4, self.HeaderSize + 4, 4, 4)

	self.Dim = true 	--dim everything when the navbar is expanded?
end

function NavPanel:GenerateInvisibleButton(nav)
	if IsValid(self.__InvisButton) then error("this should never happen: invisible un-retract button generated twice!") return end
	local btn = vgui.Create("DButton", self)
	btn:SetPos(0, self.HeaderSize)
	btn:SetSize(self:GetWide(), self:GetTall())
	btn:SetText("")
	btn.Paint = BlankFunc
	btn.DoClick = function()
		self.Navbar:OnClick()
	end
	btn:SetZPos(32766)
	self.__InvisButton = btn
end

function NavPanel:RemoveInvisibleButton(nav)
	if IsValid(self.__InvisButton) then self.__InvisButton:Remove() return end
end

function NavPanel:SetRetractedSize(size)
	self.RetractedSize = size
	local navbar = self.Navbar
	navbar.RetractedSize = size

	local x = -navbar:GetWide() * (1 - navbar.ExpandFrac) + size
	navbar.X = x
end

function NavPanel:SetExpandedSize(size)
	self.Navbar:SetWide(size)
end
function NavPanel:SetTabSize(size)
	self.TabSize = size
	local l, t, r, b = self:GetDockPadding()
	self:DockPadding(l, size + self.HeaderSize, r, b)
end

function NavPanel:PerformLayout(w, h)
	local navbar = self.Navbar
	navbar:SetTall(h - self.HeaderSize)
	navbar:SetZPos(32767)

	local canv = self.Canvas
	canv:SetPos(navbar.X + navbar:GetWide(), self.HeaderSize)

	if IsValid(self.ActivePnl) then
		self.ActivePnl:SetPos(self.RetractedSize + 8, self.HeaderSize)
		self.ActivePnl:SetSize(self:GetWide() - self.RetractedSize - 8, self:GetTall() - self.HeaderSize)
	end

	if IsValid(self.__InvisButton) then
		self.__InvisButton:SetPos(self.RetractedSize, self.HeaderSize)
		self.__InvisButton:SetSize(self:GetWide(), self:GetTall())
	end

	self:Emit("PerformLayout", w, h)
end

function NavPanel:AddCustomElement(fr)
	local nb = self.Navbar
	nb:Add(fr)
end

function NavPanel:PositionPanel(pnl)
	pnl:SetPos(self.RetractedSize, self.HeaderSize)
	pnl:SetSize(self:GetWide() - self.RetractedSize, self:GetTall() - self.HeaderSize)
end

function NavPanel:SetActivePanel(pnl, nopopout, noanim) --nil is acceptable as pnl

	if IsValid(self.ActivePnl) and not self.ActivePnl.__navNoPopout then
		self.ActivePnl:PopOut(nil, nil, function(_, self)
			self:SetVisible(false)
		end)
		self.ActivePnl:MoveBy(0, 24, 0.1, 0, 0.2)
	end

	self.ActivePnl = pnl

	if pnl then
		pnl.__navNoPopout = nopopout
		pnl:SetPos(self.RetractedSize, self.HeaderSize)
		pnl:SetSize(self:GetWide() - self.RetractedSize, self:GetTall() - self.HeaderSize)

		if not noanim then pnl:PopIn() end
		pnl:SetVisible(true)
	end
end

function NavPanel:AddTab(name, onopen, onclose)
	local tab = vgui.Create("NavbarChoice", self.Navbar)
	tab:SetName(name)
	tab.NavPanel = self

	tab:On("Select", function(btn, navbar, noanim, ...)
		local pnl, nofade, noanimret

		if onopen then
			pnl, nofade, noanimret = onopen(btn.NavPanel, btn, btn.HiddenPanel, noanim, ...)
			noanim = noanim or noanimret
		end

		self:SetActivePanel(pnl, nofade, noanim)
		btn.HiddenPanel = pnl
	end)

	if onclose then
		tab:On("Deselect", function(btn, ...)
			onclose(btn.NavPanel, btn, btn.HiddenPanel, ...)
		end)
	end

	self.Navbar:Add(tab)

	return tab
end

function NavPanel:GetNavbarSize()
	return self.Navbar:GetWide(), self.RetractedSize
end

function NavPanel:SelectTab(name, dontanim)
	local tabs = self.Navbar.Tabs

	for k,v in pairs(tabs) do

		if v:GetName() == name then
			v:Select(dontanim)
		end
	end
end

function NavPanel:Paint(w,h)
	self:PrePaint(w, h)

	self:DrawHeaderPanel(w, h)

	self:PostPaint(w, h)
end

function NavPanel:PaintOver(w, h)

	if self.Dim then
		surface.SetDrawColor(0, 0, 0, self.Navbar.ExpandFrac * 210)
		surface.DrawRect(self.Navbar.X + self.Navbar:GetWide(), self.HeaderSize, w, h)
	end

	self:Emit("PaintOver", w, h)
end

vgui.Register("NavFrame", NavPanel, "FFrame")
vgui.Register("NavPanel", NavPanel, "FFrame")

local Testing = false


if not Testing then return end

if IsValid(NAV) then NAV:Remove() end

NAV = vgui.Create("NavFrame")
NAV:SetSize(800, 500)
NAV:Center()
NAV:MakePopup()
NAV.Shadow = {}

local btn = NAV:AddTab("Bruh", function(btn, navbar)
	local btn = vgui.Create("FButton", NAV)
	btn:PopIn()
	return btn
end)
btn:SetIcon("https://i.imgur.com/hTA3WB7.png", "twaysh.png")
btn:SetDescription("what a bruh moment, innit")
local btn2 = NAV:AddTab("Bruh 2")

local btn3 = NAV:AddTab("Bruh 3")
