local ext = basewars.createExtension"core.buy-menu"

do
	local grey  = Color(90 , 90 , 90 , 180)
	local grey2 = Color(190, 190, 190, 180)
	local green = Color(90 , 200, 0  , 180)
	local red   = Color(200, 0  , 20 , 180)
	local blue  = Color(0  , 90 , 200, 180)

	local shade = Color(0  , 0  , 0  , 192)
	local white = Color(255, 255, 255, 255)

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

	function ext:paintSpawnIcon(w, h, ply, item)
		if hook.Run("BW_PaintBuymenuSpawnIcon", w, h, ply, item) then return end
		local level = not item.level or ply:hasLevel(item.level)
		local cost  = item.cost

		local col
		if not level then
			col = grey
		elseif cost > 0 then
			col = green
			local money = ply:getMoney()

			if cost >= money * 25 then
				col = grey
			elseif cost > money then
				col = red
			elseif cost < money / 100 then
				col = blue
			end
		end

		draw.RoundedBox(4, 1, 1, w - 2, h - 2, col or grey2)
	end

	function ext:paintOverSpawnIcon(w, h, ply, item, costText)
		if hook.Run("BW_PaintOverBuymenuSpawnIcon", w, h, ply, item, costText) then return end
		local level = not item.level or ply:hasLevel(item.level)

		if not level then

		else
			if not item.displayName then
				local item_name = item.name

				surface.SetFont(smallFont)
				local w = surface.GetTextSize(item_name)
				local total_w = 92 - 9
				local dots = 0
				local dot = "."

				while w > total_w do
					dots = math.min(dots + 1, 3)

					item_name = utf8.sub(item_name, 1, utf8.len(item_name) - 1)
					w = surface.GetTextSize(item_name .. dot:rep(dots))
				end

				item.displayName = item_name .. dot:rep(dots)
			end

			draw.SimpleText(item.displayName, smallFont, 5, 5, shade, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(item.displayName, smallFont, 4, 4, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			draw.SimpleText(costText, largeFont, w - 3, h - 3, shade, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(costText, largeFont, w - 4, h - 4, white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
		end
	end
end

function ext:buildCategory(layout, data)
	local items = data.items

	local ply = LocalPlayer()
	for _, tbl in SortedPairsByMemberValue(items, "cost") do
		local cost = tbl.cost

		local cost_text
		if cost > 0 then
			cost_text = "£" .. basewars.nformat(cost)
		else
			cost_text = "FREE"
		end

		local icon = layout:Add("SpawnIcon")
			icon:SetModel(tbl.model)
			icon:SetTooltip(tbl.name .. (cost > 0 and " (" .. cost_text .. ")" or ""))
			icon:SetSize(92, 92)

			local SpawnIcon = vgui.GetControlTable"SpawnIcon"

			function icon:DoClick()
				surface.PlaySound("buttons/button9.wav")

				hook.Run("BW_SelectedEntityForPurchase", tbl.item_id)
			end

			function icon.Paint(panel, w, h)
				self:paintSpawnIcon(w, h, ply, tbl)

				SpawnIcon.Paint(panel, w, h)
			end

			function icon.PaintOver(panel, w, h)
				self:paintOverSpawnIcon(w, h, ply, tbl, cost_text)

				SpawnIcon.PaintOver(panel, w, h)
			end
	end
end

function ext:buildItems(pnl)
	local cats = pnl:Add("DCategoryList")
		cats:Dock(FILL)
		function cats:Paint() end

	local items = basewars.getItemsCategorized()
	for catName, data in SortedPairs(items) do
		local layout = vgui.Create("DIconLayout")
			layout:Dock(FILL)

			layout:SetSpaceX(4)
			layout:SetSpaceY(4)

		self:buildCategory(layout, data)

		local cat = cats:Add(catName:gsub("([%[%]]*)", ""))
			cat:SetContents(layout)
			cat:SetExpanded(true)
	end
end

function ext.makeBuyMenuPanel()
	local pnl = vgui.Create("DPanel")
		function pnl:Paint(w, h) end

	ext:buildItems(pnl)

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

	cvars.AddChangeCallback("developer", function(_, old, new)
		local val = tonumber(new) or 1

		local old_dev = developer
		developer = val ~= 0

		if developer ~= old_dev then
			ext.reloadSpawnmenu()
		end
	end, "bw18_spawnmenu_reload")

	if g_SpawnMenu then
		ext.reloadSpawnmenu()
	end
end
