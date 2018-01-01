local ext = basewars.createExtension"core.buyMenu"

function ext:buildCategory(layout, data)
	local items = data.items

	for _, tbl in SortedPairsByMemberValue(items, "cost") do
		local cost = tbl.cost
		local cost_text = "£" .. basewars.nformat(cost)

		local icon = layout:Add("SpawnIcon")
			icon:SetModel(tbl.model)
			icon:SetTooltip(tbl.name .. (cost > 0 and " (" .. cost_text .. ")" or ""))
			icon:SetSize(72, 72)

			local SpawnIcon = vgui.GetControlTable"SpawnIcon"

			function icon:DoClick()
				hook.Run("BW_SelectedEntityForPurchase", tbl.item_id)
			end

			function icon:Paint(w, h)
				SpawnIcon.Paint(self, w, h)
			end

			function icon:PaintOver(w, h)
				SpawnIcon.PaintOver(self, w, h)
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

		local cat = cats:Add(catName)
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
