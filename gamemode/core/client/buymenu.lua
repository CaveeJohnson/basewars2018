local ext = basewars.createExtension"core.buy-menu"

--TODO: move somewhere more appropriate
local catsIcons = {

	Base = {
		URL = "https://i.imgur.com/jXyM6ss.png",
		Name = "base2.png",

		IconW = 24,
		IconH = 24,

		UnselectedColor = nil, 	--available for override
		SelectedColor = nil, 	--available for override

		Subcats = {
			Construction =  {
				URL = "https://i.imgur.com/poRxTau.png",
				Name = "electricity.png",

				IconW = 32,
				IconH = 32
			}
		}
	},

	Money = {
		URL = "https://i.imgur.com/04iGwnU.png",--"https://i.imgur.com/Pd6myv0.png",
		Name = "coins_pound32.png",

		IconW = 24,
		IconH = 24,

	},

}

local LerpColor = draw.LerpColor

local catsColor = Color(200, 200, 200) -- Categories color (panel on the left)
local catsGradColor = Color(65, 65, 65)

local catsTextColor = Color(75, 75, 75) -- Categories: unselected color for text + icon
local catsTextSelected = Color(50, 150, 250)

local catPush = 16 		--px to move to the right for selected categories
local catSelTime = 0.3 			--seconds to lerp to selected color + move out
local catUnselTime = catSelTime + 0.2 --seconds to lerp to unselected color + move in
local catEase = 0.4

local itemlistBGColor = Color(170, 170, 170, 200)
local itemlistGradColor = Color(20, 20, 20)

local itemSubcatBG = Color(0, 0, 0, 110)

local itemBorder = Color(80, 80, 80)
local itemClickedBorder = Color(220, 220, 220)
local itemBorderHeld = Color(10, 10, 10)

local grey  = Color(110 , 110 , 110 , 180)
local grey2 = Color(190, 190, 190, 180)
local green = Color(90 , 200, 0  , 180)
local red   = Color(200, 0  , 20 , 180)
local blue  = Color(60  , 115 , 200, 180)
local yello = Color(255, 234, 136, 180)

local shade = Color(0  , 0  , 0  , 192)
local white = Color(255, 255, 255, 255)

do

	local largeFont  = ext:getTag() .. "_large"
	local smallFont = ext:getTag() .. "_small"

	surface.CreateFont(smallFont, {
		font = "DejaVu Sans Bold",
		size = 10,
		weight = 1,
	})

	surface.CreateFont(largeFont, {
		font = "DejaVu Sans Bold",
		size = 12,
		weight = 1,
	})

	function ext:getIconColor(ply, item, core)
		local level = not item.level or ply:hasLevel(item.level)
		local cost  = item.cost
		local needscore = item.requiresCore

		local col, err
		if (needscore and not core) then
			col = grey
			err = "Item requires base core!"
		elseif not level then
			col = grey
			err = "Insufficient level!"
		elseif cost > 0 then
			col = green
			local money = ply:getMoney()

			if cost >= money * 25 then
				col = grey
				err = "Not enough money!"
			elseif cost > money then
				col = red
				err = "Not enough money!"
			elseif cost > money / 3 then
				col = yello
			elseif cost < money / 100 then
				col = blue
			end
		end

		return col or grey2, err

	end

	function ext:paintOverSpawnIcon(x, y, w, h, ply, item, costText)
		if hook.Run("BW_PaintOverBuymenuSpawnIcon", w, h, ply, item, costText) then return end
		local level = not item.level or ply:hasLevel(item.level)

		if not level then

		else
			if not item.displayName then
				local item_name = item.name

				surface.SetFont(smallFont)
				local tw = surface.GetTextSize(item_name)
				local total_w = w - x*2 - 6
				local dots = 0
				local dot = "."

				while tw > total_w do
					dots = math.min(dots + 1, 3)

					item_name = utf8.sub(item_name, 1, utf8.len(item_name) - 1)
					tw = surface.GetTextSize(item_name .. dot:rep(dots))
				end

				item.displayName = item_name .. dot:rep(dots)
			end

			draw.SimpleText(item.displayName, smallFont, w/2, y + 3, shade, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(item.displayName, smallFont, w/2, y + 2, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			draw.SimpleText(costText, largeFont, w/2, y + h - 6, shade, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(costText, largeFont, w/2, y + h - 7, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end
end

local noIconMat

function ext:openCategory(catname, catpnl, catdata)
	local subcatFrame = vgui.Create("InvisPanel", self.mainFrame)
	self.subcategoryPanel = subcatFrame

	subcatFrame:SetPos(catpnl.X + catpnl:GetWide() - 8, catpnl.Y)	--can't use docking because i want to animate this popping up to the right

	local width = self.mainFrame:GetWide() - catpnl:GetWide() - catpnl.X - 16

	subcatFrame:SetSize(width, self.mainFrame:GetTall() - catpnl.Y - 4) -- 4px on the bottom

	subcatFrame:MoveBy(16, 0, 0.3, 0.05, 0.4)
	subcatFrame:PopIn(nil, 0.05)


	local subcats = vgui.Create("InvisPanel", subcatFrame)
	subcats:Dock(LEFT)
	subcats:SetWide(80)		--ideally 64px for the icons and 8px padding

	function subcats:Paint(w, h)
		draw.RoundedBox(8, 0, 0, w, h, catsColor)

		surface.SetDrawColor(catsGradColor)
		self:DrawGradientBorder(w, h, 3, 3)

		draw.DrawText("subcat\nicons\nwill go\nhere l8r", "OS24", w/2, 12, Colors.Gray, 1)
	end

	local items = vgui.Create("FScrollPanel", subcatFrame)
	items:Dock(FILL)
	items:DockMargin(4, 0, 0, 0)
	items.BackgroundColor = itemlistBGColor:Copy()
	items.GradBorder = true
	items.BorderColor = itemlistGradColor:Copy()

	items.Buttons = {}

	function items:Think()
		self.hasCore = LocalPlayer():hasCore()
	end

	items:GetCanvas():DockPadding(8, 8, 8, 0)

	subcatFrame:InvalidateLayout(true)

	self:buildSubcategory(items, catdata, catname)
end

function ext:closeCategory(catname, catpnl, catdata)
	if IsValid(self.subcategoryPanel) then
		self.subcategoryPanel:PopOut(0.15)
		self.subcategoryPanel:MoveBy(0, 24, 0.15, 0, 1.4)
	end

end

function ext:buildSubcategory(scr, catdata, catname)
	local items = catdata.items

	local ply = LocalPlayer()
	local subcats = catdata.subcats
	local sorted = {}

	for k,v in pairs(subcats) do
		sorted[#sorted + 1] = {k, v.prio}
	end

	table.sort(sorted, function(a, b)
		local ap = a[2]
		local bp = b[2]

		if ap and ap > 0 and not bp then return true end 	--if A has prio set and its more than 0 and B doesn't, auto-move A above
		if bp and bp > 0 and not ap then return false end 	--vice versa

		if ap and bp then return ap > bp end 				--if both have prio set, just compare and select the highest
		return a[1] < b[1]									--otherwise, alphabetical sort
	end)

	for k,v in ipairs(sorted) do
		local sc_name = v[1]
		local sc_data = subcats[v[1]]

		local subframe = vgui.Create("InvisPanel", scr)
		subframe:Dock(TOP)
		subframe:DockMargin(0, 8, 0, 4)
		subframe:DockPadding(8, 24, 8, 4)
		subframe:SetWide(scr:GetWide())

		local subcat_icon = (catsIcons[catname] and catsIcons[catname].Subcats and catsIcons[catname].Subcats[sc_name])

		function subframe:Paint(w, h)
			draw.RoundedBox(8, 0, 0, w, h, itemSubcatBG)

			surface.SetDrawColor(color_white)

			if subcat_icon then
				local w, h = subcat_icon.IconW or 32, subcat_icon.IconH or 32

				surface.DrawMaterial(subcat_icon.URL, subcat_icon.Name, 8, 36/2 - h/2, w, h)
			else
				surface.SetMaterial(noIconMat)
				surface.DrawTexturedRect(8, 4, 32, 32)
			end

			draw.SimpleText(sc_name, "OSB32", 32 + 8 + 4, 36/2, color_white, 0, 1)
		end

		local itemlist = vgui.Create("DIconLayout", subframe)
		itemlist:Dock(BOTTOM)
		itemlist:SetWide(subframe:GetWide())
		itemlist:SetSpaceX(4)


		for id, item in ipairs(sc_data.items) do

			local cost = item.cost
			local cost_text

			if cost > 0 then
				cost_text = basewars.currency(cost)
			else
				cost_text = "FREE"
			end

			local btn = itemlist:Add("FButton")

			scr.Buttons[#scr.Buttons + 1] = btn

			btn:SetDoubleClickingEnabled(false) --fast clixx
			btn:SetSize(88, 88)

			btn.Label = ""
			btn.Border = {}
			btn.borderColor = itemBorder:Copy()
			btn.DrawShadow = false
			btn.Description = item.description
			--btn.HovMult = 1.1

			local icon = vgui.Create("SpawnIcon", btn)
			icon:SetMouseInputEnabled(false)
			icon:SetModel(item.model)
			icon:SetTooltip(item.name .. (cost > 0 and " (" .. cost_text .. ")" or ""))

			icon:SetSize(76, 76)
			icon:SetPos(6, 6)

			local SpawnIcon = vgui.GetControlTable"SpawnIcon"

			local clicc = 0

			local down = 0
			local held = false

			function btn:DoClick()
				surface.PlaySound("buttons/button9.wav")

				hook.Run("BW_SelectedEntityForPurchase", item.item_id)
				self.borderColor:Set(itemClickedBorder)
				clicc = CurTime() + 0.05
			end

			function btn:PrePaint(w, h)
				if hook.Run("BW_PaintBuymenuSpawnIcon", self, w, h, ply, item) then return end
				local col = itemBorder

				local frac

				local time = 0.5 --0.5s to lerp back

				if CurTime() - clicc > 0.5 then --if we didn't click, animations go quicker
					time = 0.2					--(aka hold/unhold animation)
				end

				if self:IsDown() then
					col = itemBorderHeld

					if not held then
						down = CurTime()
					end

					held = true
				elseif held then 	--button got unpushed this frame
					down = CurTime()
					held = false
				end

				frac = math.min(CurTime() - clicc, CurTime() - down, time) * (1/time)

				LerpColor(frac, self.borderColor, col)

				local col, err = ext:getIconColor(ply, item, scr.hasCore)

				self.Color = col
				self.Error = err

				if self.Error and self:IsHovered() then 	--moved this to PrePaint cuz it was unreliable if you opened the spawnmenu while a condition changed
					local cl, new = self:AddCloud("whynot") --this shouldn't make too much of a performance difference cuz AddCloud and GetCloud cache already

					if new then
						cl.Font = "OS20"
						cl:SetText(self.Error)
						cl.TextColor = Colors.DarkerRed
						cl.MaxW = 500
						cl:SetRelPos(self:GetWide() / 2, self:GetTall())
						cl.ToY = 8
						cl.YAlign = 0

						hook.Add("OnSpawnMenuClose", cl, function()
							cl:Hide()
						end)

						hook.Add("OnSpawnMenuOpen", cl, function()
							cl:Show()
						end)

						cl:On("Remove", "spawnmenu", function()
							hook.Remove("OnSpawnMenuClose", cl)
							hook.Remove("OnSpawnMenuOpen", cl)
						end)

					end

				else
					local cl = self:GetCloud("whynot")

					if cl then
						self:RemoveCloud("whynot")
					end
				end

			end

			function btn:PaintOver(w, h)
				ext:paintOverSpawnIcon(4, 4, w, h, ply, item, cost_text)

				--SpawnIcon.PaintOver(panel, w, h)
			end

			function btn:OnHover()

				--[[if self.Error then
					local cl, new = self:AddCloud("whynot")

					if new then
						cl.Font = "OS20"
						cl:SetText(self.Error)
						cl.TextColor = brighterred
						cl.MaxW = 500
						cl:SetRelPos(self:GetWide() / 2, self:GetTall())
						cl.ToY = 8
						cl.YAlign = 0

						hook.Add("OnSpawnMenuClose", cl, function()
							cl:Hide()
						end)

						hook.Add("OnSpawnMenuOpen", cl, function()
							cl:Show()
						end)
					end

				end]]
				print(self.Description, item.description)
				if self.Description then
					local cl, new = self:AddCloud("description")

					if new then
						cl.Font = "OS20"
						cl:SetText(self.Error)
						cl.TextColor = color_white
						cl.MaxW = 350
						cl:SetRelPos(self:GetWide() / 2, 4)
						cl.ToY = -8

						hook.Add("OnSpawnMenuClose", cl, function()
							cl:Hide()
						end)

						hook.Add("OnSpawnMenuOpen", cl, function()
							cl:Show()
						end)
					end
				end
			end

			function btn:OnUnhover()
				--[[local cl = self:GetCloud("whynot")
				if cl then
					self:RemoveCloud("whynot")
					cl:On("Remove", "spawnmenu", function()
						hook.Remove("OnSpawnMenuClose", cl)
						hook.Remove("OnSpawnMenuOpen", cl)
					end)
				end
				]]
				self:RemoveCloud("description")
			end

		end

		itemlist:InvalidateLayout(true)
		subframe:SetTall(itemlist:GetTall() + 8 + 32)

	end
	--[[
	for _, tbl in SortedPairsByMemberValue(items, "cost") do

	end]]

end

local LerpColor = draw.LerpColor

local function catBtnPaint(self, w, h)
	local ic = self.Icon

	local unselCol = (ic and ic.UnselectedColor) or catsTextColor
	local selCol = (ic and ic.SelectedColor)	 or catsTextSelected

	self.currentColor = self.currentColor or unselCol:Copy()

	local fr = self.selFrac

	if ext.selectedCategory == self.catName then
		self:To("selFrac", 1, catSelTime, 0, catEase)
		LerpColor(fr, self.currentColor, selCol)
	else
		self:To("selFrac", 0, catUnselTime, 0, catEase)
		LerpColor(1 - fr, self.currentColor, unselCol)
	end

	self.iconX = math.ceil( 4 + fr * catPush )
	self.TextX = math.ceil( self.iconX + ((ic and (ic.IconW or 24) + 4) or 0) )

	if ic then
		surface.SetDrawColor(self.currentColor)
		surface.DrawMaterial(ic.URL, ic.Name, self.iconX, h/2 - ic.IconH/2, ic.IconW, ic.IconH)
	end

	self.LabelColor = self.currentColor
end

function ext:buildCategories(pnl)
	noIconMat = nil --thank you garry very cool
					--(refresh the mat so it's not black when you change gfx settings)

	ext.mainFrame = pnl

	local catpnl = pnl:Add("InvisPanel")
	catpnl:Dock(LEFT)
	catpnl:DockMargin(0, 32, 0, 4)
	catpnl:DockPadding(0, 8, 0, 0)

	catpnl:SetWide(175)

	function catpnl:Paint(w, h)
		if not noIconMat then
			noIconMat = draw.RenderOntoMaterial("spawnmenu-noicon", 32, 32, function()
				draw.SimpleText("*", "R64", 16, 14, color_white, 1, 1)
			end)
		end

		draw.RoundedBox(8, 0, 0, w, h, catsColor)

		surface.SetDrawColor(catsGradColor)
		self:DrawGradientBorder(w, h, 3, 3)
	end

	local cats = basewars.items.getCategorized()

	for catname, catdata in pairs(cats) do

		local cat = vgui.Create("FButton", catpnl)
		cat:Dock(TOP)
		cat:DockMargin(4, 4, 4, 4)
		cat.Label = catname
		cat:SetTall(28)
		cat.NoDraw = true

		cat.LabelColor = catsTextColor:Copy()
		cat.Font = "OSB28"

		cat.TextX = 2
		cat.TextAX = 0

		cat.catName = catname
		cat.selFrac = 0

		local icon = catsIcons[catname]

		if icon then
			cat.Icon = icon

			cat.TextX = 2 + icon.IconW + 4
		end

		cat.PostPaint = catBtnPaint

		function cat:DoClick()
			if ext.selectedCategory == catname then return end --kk

			ext:closeCategory(catname, catpnl, catdata)
			ext.selectedCategory = catname
			ext:openCategory(catname, catpnl, catdata)

		end

	end
end

function ext.makeBuyMenuPanel()
	local pnl = vgui.Create("InvisPanel")

	local ok, err = pcall(ext.buildCategories, ext, pnl)

	if not ok then --remove me when done editing
		pnl:Remove()
		errorf("Spawnmenu error!\n %s", err)
	end

	return pnl
end

spawnmenu.AddCreationTab("Basewars", ext.makeBuyMenuPanel, "icon16/building.png", 2)

do
	local to_remove = {
		"#spawnmenu.category.saves",
		"#spawnmenu.category.weapons",
		"#spawnmenu.category.npcs",
		"#spawnmenu.category.entities",
		"#spawnmenu.category.postprocess",
		"#spawnmenu.category.dupes",
	}

	if not SERVER_DEVMODE then
		table.insert(to_remove, "#spawnmenu.category.vehicles")
	end

	local developer = GetConVar("developer"):GetBool()
	function ext.reloadSpawnmenu(...)
		if not next(g_SpawnMenu.CreateMenu.Items) then return end
		spawnmenu.Reload(...)

		if developer then return end

		for i, v in ipairs(g_SpawnMenu.CreateMenu.Items) do
			if table.HasValue(to_remove, v.Name) then
				g_SpawnMenu.CreateMenu.tabScroller.Panels[i] = nil
				g_SpawnMenu.CreateMenu.Items[i] = nil

				v.Tab:Remove()
			end
		end
	end
	ext.InitPostEntity  = ext.reloadSpawnmenu
	ext.PostItemsLoaded = ext.reloadSpawnmenu

	spawnmenu.Reload = spawnmenu.Reload or concommand.GetTable().spawnmenu_reload
	concommand.Add("spawnmenu_reload", ext.reloadSpawnmenu)

	if not _G.addedDeveloperCallback then

		cvars.AddChangeCallback("developer", function(_, old, new)
			local val = tonumber(new) or 1

			local old_dev = developer
			developer = val ~= 0

			if developer ~= old_dev then
				ext.reloadSpawnmenu()
			end
		end, "bw_spawnmenu_reload")

		_G.addedDeveloperCallback = true
	end

	if g_SpawnMenu then
		ext.reloadSpawnmenu()
	end
end
