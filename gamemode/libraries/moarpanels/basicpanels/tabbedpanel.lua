--[[-------------------------------------------------------------------------
-- 	TabbedPanel/Frame

	TabbedPanel:AddTab(name, onopen, onclose)
	TabbedPanel:SelectTab(name)
	TabbedPanel:GetWorkSize()
	TabbedPanel:GetWorkY()
	TabbedPanel:AlignPanel(pnl)

---------------------------------------------------------------------------]]
local LerpColor = draw.LerpColor
local TabbedPanel = {}

function TabbedPanel:Init()

	self.ActiveTab = ""
	self.OpenTabs = {}
	self.CloseTabs = {}
	self.TabColor = Color(54, 54, 54)
	self.TabFont = "OS24"
	self.Tabs = {}

	self.TabSize = 26

	self.SelectedTabColor = Color(70, 170, 255)
	self.UnselectedTabColor = color_white:Copy()

	self:DockPadding(4, 26 + self.HeaderSize + 4, 4, 4)
end

function TabbedPanel:SetTabSize(size)
	self.TabSize = size
	local l, t, r, b = self:GetDockPadding()
	self:DockPadding(l, size + self.HeaderSize + 4, r, b)
end

function TabbedPanel:AddTab(name, onopen, onclose)

	local tab = vgui.Create("DButton", self)

	self.Tabs[name] = tab

	surface.SetFont(self.TabFont)
	local tx, _ = surface.GetTextSize(name or "")
	local x = (self.TabX or 0)

	tab:SetPos(x, self.HeaderSize)
	tab:SetSize(tx + 24, self.TabSize)
	tab:SetText("")

	self.TabX = x + tx + 24

	self.OpenTabs[name] = onopen
	self.CloseTabs[name] = onclose

	tab.Col = self.SelectedTabColor:Copy()

	tab.Hov = 0
	tab.SelTime = 0
	tab.SelColor = tab.Col:Copy()

	function tab.Paint(me, w, h)
		local tocol = self.ActiveTab == name and self.SelectedTabColor or self.UnselectedTabColor

		local frac = math.min((CurTime() - tab.SelTime) / 0.7, 1)
		frac = Ease(frac, 0.4)

		LerpColor(frac, me.Col, tocol)
		draw.SimpleText(name, self.TabFont, w/2, h/2 - 1, me.Col, 1, 1)

		if me:IsHovered() then
			me.Hov = L(me.Hov, 35, 15)
		else
			me.Hov = L(me.Hov, 0, 15)
		end

		if me.Hov > 1 then
			surface.SetDrawColor(Color(255, 255, 255, me.Hov))
			self:DrawGradientBorder(w, h, 2, 3)
		end
	end

	function tab.DoClick()
		local curtab = self.ActiveTab 	 --tab name, not button
		if curtab == name then return end

		local tabbtn = self.Tabs[curtab] --this is the tab button

		if isfunction(self.OpenTabs[name]) then

			if curtab ~= "" then 	--if there was a tab open,

				if isfunction(self.CloseTabs[curtab])  then 	--if there's a close function registered for the tab we're about to close,
					self.CloseTabs[curtab](self.OpenTabs[name])				--exec that
				end

				self.Tabs[curtab].SelTime = CurTime()
				self.Tabs[curtab].SelColor:Set(self.Tabs[curtab].Col)

				if tabbtn and tabbtn.ReturnedPanel then --if there's a panel registered for auto-close,

					local pnl = tabbtn.ReturnedPanel

					if pnl.TabClose then 			--if it has a close function, do that
						pnl:TabClose()
					elseif pnl.__InstaRemove then 	--__InstaRemove gets set for panels which are returned by OpenFunc if 2nd bool is true
						pnl:Remove()
					else
						pnl:PopOut()
					end

				end
			end

			if tabbtn then
				tabbtn.SelTime = CurTime()
				tabbtn.SelColor:Set(self.Tabs[curtab].Col)
			end

			local pnl, instaremove = self.OpenTabs[name]()

			if ispanel(pnl) then --if open func returned a panel then assume they want to auto-close it when tab switches
				pnl.__InstaRemove = instaremove
				tab.ReturnedPanel = pnl
			end
		end

		self.WentFrom = (self.Tabs[curtab] and self.Tabs[curtab].X) or 0
		self.ActiveTab = name

	end

	return tab
end

function TabbedPanel:SelectTab(name, dontanim)
	local tab = self.Tabs[name] --button
	if not tab then error("Tried opening a non-existent tab!") return end

	self.OpenTabs[name]()
	self.ActiveTab = name

	if dontanim then
		self.SelX = tab.X
		self.SelW = self.Tabs[name]:GetWide()
	end

end

function TabbedPanel:GetWorkSize()
	local w,h = self:GetSize()
	return w, h - self.TabSize - self.HeaderSize
end

function TabbedPanel:GetWorkY()
	return self.TabSize + self.HeaderSize
end

function TabbedPanel:AlignPanel(pnl)
	pnl:SetSize(self:GetWorkSize())
	pnl:SetPos(0, self:GetWorkY())
end

function TabbedPanel:Paint(w,h)

	self:PrePaint(w, h)

	self:DrawHeaderPanel(w, h)

	surface.SetDrawColor(self.TabColor)
	surface.DrawRect(0, self.HeaderSize, w, self.TabSize)

	local sel = self.Tabs[self.ActiveTab]

	if sel then
		local x, tw = sel.X, sel:GetWide()

		local dist = math.max(self.SelX or 0, x) - math.min(self.SelX or 0, x)

		local origdist = math.max(self.WentFrom or 0, self.SelX or 0) - math.min(self.WentFrom or 0, self.SelX or 0)

		local far = dist / origdist > 0.6

		self.SelW = L(self.SelW, (far and tw*0.8) or tw, 15, true)

		self.SelX = L(self.SelX, x, 15)

		surface.SetDrawColor(40, 140, 220)
		surface.DrawRect(self.SelX, self.HeaderSize + self.TabSize - 3, self.SelW, 3)
	end

	self:PostPaint(w, h)
end

vgui.Register("TabbedFrame", TabbedPanel, "FFrame")