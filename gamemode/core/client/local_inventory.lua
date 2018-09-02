-- setfenv(1, _G)

local ext = basewars.createExtension"local-inventory"

ext.listeners     = {}
ext.listeners_loc = {}

function ext:subscribe(ent, panel)
	if ent == LocalPlayer() then
		self.listeners_loc[panel] = true
	else
		local i = ent:EntIndex()

		self.listeners[i]        = self.listeners[i] or {}
		self.listeners[i][panel] = true
	end
end

function ext:unsubscribe(ent, panel)
	if ent:EntIndex() == LocalPlayer():EntIndex() then
		self.listeners_loc[panel] = nil
	else
		local i = ent:EntIndex()

		if self.listeners[i] then
			self.listeners[i][panel] = nil
		end
	end
end

function ext:createLocalInventoryPanel()
	local panel = vgui.Create("BWUI.LocalInventory", basewars.ui.getParent())
	panel:buildItems()
	panel:Hide()
	return panel
end

function ext:getLocalInventoryPanel()
	local panel = basewars.ui._localInvPanel

	if not IsValid(panel) then
		panel             = self:createLocalInventoryPanel()
		basewars.ui._localInvPanel = panel
	end

	return panel
end

function ext:BW_ReceivedInventory(ent, inv)
	local listeners = self.listeners[ent:EntIndex()]

	if listeners then
		for panel in pairs(listeners) do
			if panel.proxy then
				panel:update(inv)
			else
				panel:buildItemsFromInventory(inv)
			end
		end
	end
end

function ext:BW_ReceivedLocalInventoryUpdate(ply, id, amount)
	local listeners = self.listeners_loc

	if listeners then
		for panel in pairs(listeners) do
			if panel.proxy then
				panel:update(ply.bw_inventory)
			else
				panel:processItem(id, amount)
			end
		end
	end
end

function ext:OnContextMenuOpen()
	self:getLocalInventoryPanel():Show()
end

function ext:OnContextMenuClose()
	timer.Simple(0, function() basewars.ui.getTooltipPanel():Remove() end)
	self:getLocalInventoryPanel():Hide()
end

do -- BWUI.Inventory
	local PANEL = {}
	DEFINE_BASECLASS"DDragBase"

	function PANEL:Init()
		local scroll = vgui.Create("DScrollPanel", self)
		local canvas = vgui.Create("DIconLayout", scroll)
		scroll:Dock(FILL)
		canvas:Dock(FILL)

		self._scroll = scroll
		self._canvas = canvas

		self.tileSize      = 48
		self.minTileWidth  = 0
		self.maxTileWidth  = math.huge
		self.minTileHeight = 0
		self.maxTileHeight = math.huge
		self:setTileMargin(2)

		self.managedTiles = {}

		do
			local self2 = self
			function canvas:DropAction_Normal(drops, d, ...)
				if d then
					for k, panel in pairs(drops) do
						local item, amount, ent = panel.item, panel.amount, panel.ent

						if item and self2:filter(item, amount, ent, panel) ~= false then
							self2:onDropped(item, amount, ent, panel)

							local drag_amt = panel._dragAmount
							local tiles    = panel.inv.managedTiles
							local ourtiles = self2.managedTiles

							local tile, ourtile = tiles[item], ourtiles[item]

							if drag_amt and drag_amt ~= amount then
								if IsValid(ourtile) then
									ourtile:setItem(item, ourtile.amount + drag_amt)
								else
									panel = vgui.Create("BWUI.Inventory.Tile")
									panel:setItem(item, drag_amt)
									ourtiles[item] = panel
									drops[k] = panel
								end

								tile:setItem(item, tile.amount - drag_amt)
							else
								if IsValid(ourtile) then
									ourtile:setItem(item, ourtile.amount + amount)
									drops[k] = nil
								else
									ourtiles[item] = panel
								end

								tiles[item] = nil
							end
						else
							drops[k] = nil
						end
					end
				end

				self2:InvalidateLayout()
				BaseClass.DropAction_Normal(self, drops, d, ...)
			end
		end

		self.emptyTile = canvas:Add("Panel")
		self.emptyTile:Hide()

		canvas:MakeDroppable("bwui_inventory", false)
	end

	function PANEL:PerformLayout()
		local canvas = self._canvas
		local scroll = self._scroll

		local empty = self.emptyTile

		if canvas:ChildCount() == 1 then
			empty:Show()
		else
			empty:Hide()
		end

		for _, panel in ipairs(canvas:GetChildren()) do
			if panel == empty then
				local ts, tm = self.tileSize, self.tileMargin
				local tstm   = ts + tm
				panel:SetSize(self.minTileWidth * tstm - tm, self.minTileHeight * tstm - tm)
			else
				panel:SetSize(self.tileSize, self.tileSize)
			end
		end

		self:size()
	end

	function PANEL:calcBounds()
		local n = self._canvas:ChildCount()

		local ts, tm     = self.tileSize, self.tileMargin
		local tstm       = ts + tm
		local mw         = self.minTileWidth * tstm - tm
		local tr         = self.maxTileWidth
		local Mw         = tr * tstm - tm
		local mh         = self.minTileHeight * tstm - tm
		local Mh         = self.maxTileHeight * tstm - tm

		local w, h

		if n > tr then
			w, h = Mw, tstm * math.ceil(n / tr) - tm
		else
			w, h = math.max(mw, tstm * n - tm), ts
		end

		if h > Mh then
			w = w + self._scroll:GetVBar():GetWide()
			h = Mh
		end

		return w, math.max(mh, h)
	end

	function PANEL:size()
		self:SetSize(self:calcBounds())
	end

	function PANEL:getTiles()
		return self._canvas:GetChildren()
	end

	function PANEL:getTile(i)
		return self._canvas:GetChildren()[i]
	end

	function PANEL:getItem(id)
		return self.managedTiles[id]
	end

	function PANEL:setMinTileWidth(n)
		self.minTileWidth = n
		self:InvalidateLayout()
	end

	function PANEL:getMinTileWidth()
		return self.minTileWidth
	end

	function PANEL:setMaxTileWidth(n)
		self.maxTileWidth = n
		self:InvalidateLayout()
	end

	function PANEL:getMaxTileWidth()
		return self.maxTileWidth
	end

	function PANEL:setMinTileHeight(n)
		self.minTileHeight = n
		self:InvalidateLayout()
	end

	function PANEL:getMinTileHeight()
		return self.minTileHeight
	end

	function PANEL:setMaxTileHeight(n)
		self.maxTileHeight = n
		self:InvalidateLayout()
	end

	function PANEL:getMaxTileHeight()
		return self.maxTileHeight
	end

	function PANEL:setTileMargin(m)
		local canvas = self._canvas
		canvas:SetSpaceX(m)
		canvas:SetSpaceY(m)

		self.tileMargin = m
		self:InvalidateLayout()
	end

	function PANEL:getTileMargin()
		return self.tileMargin
	end

	function PANEL:addTile()
		local panel = vgui.Create("BWUI.Inventory.Tile", self._canvas)
		panel.inv = self
		panel:SetSize(self.tileSize, self.tileSize)
		return panel
	end

	function PANEL:buildItemsFromInventory(inv)
		local tiles = self.managedTiles
		local done  = {}

		for id, amount in pairs(inv) do
			self:processItem(id, amount)

			done[id] = true
		end

		self:_cleanupTiles(done)
		self:InvalidateLayout()
	end

	function PANEL:processItem(id, amount)
		local tiles = self.managedTiles

		if amount and amount > 0 then
			local panel = tiles[id]
			if not IsValid(panel) then
				panel     = self:addTile()
				tiles[id] = panel
			end

			panel:setItem(id, amount)
			panel.ent = self.ent
		else
			local panel = tiles[id]
			if IsValid(panel) then
				panel:Remove()
				tiles[id] = nil
			end
		end

		self:InvalidateLayout()
	end

	function PANEL:_cleanupTiles(done)
		local tiles = self.managedTiles

		for id in pairs(tiles) do
			if not done[id] then
				local panel = tiles[id]
				if IsValid(panel) then panel:Remove() end
				tiles[id] = nil
			end
		end
	end

	function PANEL:setFilter(filter)
		self.filter = filter
	end

	function PANEL:setDropCallback(cb)
		self.onDropped = cb
	end

	function PANEL:setEntity(ent)
		self.ent = ent
		ext:subscribe(ent, self)
		self:buildItemsFromInventory(ent.bw_inventory)
	end

	function PANEL:OnRemove()
		if self.ent then
			ext:unsubscribe(self.ent, self)
		end
	end

	function PANEL.filter()
	end

	function PANEL.onDropped()
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(10, 10, 10, 100)
		surface.DrawRect(0, 0, w, h)
	end

	function PANEL:_receive(...)
		self._canvas:DropAction_Normal(...)
	end

	vgui.Register("BWUI.Inventory", PANEL, "BWUI.Base")
end

do -- BWUI.LocalInventory
	local PANEL = {}
	DEFINE_BASECLASS"BWUI.Inventory"

	function PANEL:Init()
		self:setEntity(LocalPlayer())
		self:setMaxTileWidth(10)
		self:setMaxTileHeight(2)
	end

	function PANEL:PerformLayout(...)
		BaseClass.PerformLayout(self, ...)

		self:positionOnScreen()
	end

	function PANEL:buildItems()
		self:buildItemsFromInventory(LocalPlayer().bw_inventory)
	end

	function PANEL:positionOnScreen()
		local w, h   = self:GetSize()
		local pw, ph = self:GetParent():GetSize()

		self:SetPos(pw / 2 - w / 2, ph - h - self.tileSize)
	end

	vgui.Register("BWUI.LocalInventory", PANEL, "BWUI.Inventory")
end

do -- BWUI.Inventory.Tile
	local PANEL = {}

	function PANEL:Init()
		self.modelPanel = vgui.Create("DModelPanel", self)
		self.modelPanel:Dock(FILL)
		self.modelPanel:SetMouseInputEnabled(false)

		function self.modelPanel.PreDrawModel()
			render.SetBlend(self:GetAlpha() / 255)
		end

		function self.modelPanel.PostDrawModel()
			render.SetBlend(1)
		end

		self:SetCursor("hand")
	end

	function PANEL:setItem(id, amount)
		local data = basewars.inventory.resolveData(id)
		if not data then return false end

		local actions = basewars.inventory.resolveActions(id)
		self:setData(data)
		self:setActions(actions)
		self:setAmount(amount)
		self:prepare()

		self.item = id

		return true
	end

	function PANEL:getItem()
		return self.item
	end

	function PANEL:setData(data)
		self.data = data
	end

	function PANEL:getData()
		return self.data
	end

	function PANEL:setActions(actions)
		self.actions = actions
	end

	function PANEL:getActions()
		return self.actions
	end

	function PANEL:setAmount(amount)
		self.amount = amount
	end

	function PANEL:getAmount()
		return self.amount
	end

	function PANEL:setColor(color)
		self.color           = Color(color.r, color.g, color.b, color.a)
		self._active_color   = basewars.ui.clampColorValue(color, 1, 1)
		self._inactive_color = Color(color.r / 3, color.g / 3, color.b / 3)
	end

	function PANEL:getColor()
		return self.color, self._active_color, self._inactive_color
	end

	function PANEL:positionModel(panel)
		local mn, mx = panel.Entity:GetRenderBounds()
		local size = 0
		size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
		size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
		size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
		size = size * 1.5

		panel:SetFOV(45)
		panel:SetCamPos(Vector(size, size, size))
		panel:SetLookAt((mn + mx) * 0.5)
	end

	local color_white = _G.color_white or Color(255, 255, 255)
	function PANEL:prepare()
		local data, actions, amount = self.data or {info = {}}, self.actions or {}, self.amount or 1

		self:setColor(data.color or color_white)

		local mp = self.modelPanel

		if data.model then
			mp:Show()

			mp:SetModel(data.model)
			mp:SetColor(data.model_color or color_white)
			mp.Entity:SetSkin(data.model_skin or 0)
			mp.Entity:SetMaterial(data.model_material or "")

			local submats = data.model_submaterial
			if submats then
				for _, t in ipairs(submats) do mp.Entity:SetSubMaterial(t[1], t[2]) end
			end

			self:positionModel(mp)
		else
			mp:Hide()
		end

		self:buildTooltip(data.name or "Unknown Item", amount, data)
	end

	local function buildInfo(t, info, x)
		local first = true

		x = x or 0

		for key, value in pairs(info) do
			if first then
				first = nil
			else
				t[#t + 1] = { newline = true }
			end

			t[#t + 1] = { xadd = x }

			if istable(value) then
				t[#t + 1] = { yadd = 4 }

				t[#t + 1] = {
					font    = basewars.ui.font_mono12Bold,
					color   = basewars.ui.color_fg,
					outline = basewars.ui.color_outline,
					text    = string.format(tostring(key))
				}

				t[#t + 1] = { newline = true, yadd = 4 }

				buildInfo(t, value, x + 16)
			else
				t[#t + 1] = {
					font    = basewars.ui.font_sans16Bold,
					color   = basewars.ui.color_fg,
					outline = basewars.ui.color_outline,
					text    = string.format("%s: ", tostring(key))
				}

				t[#t + 1] = {
					font    = basewars.ui.font_sans16,
					color   = basewars.ui.color_fg,
					outline = basewars.ui.color_outline,
					text    = tostring(value)
				}
			end
		end
	end

	function PANEL:buildTooltip(name, amount, data)
		local t = {}

		t[#t + 1] = {
			font    = basewars.ui.font_sans18Bold,
			color   = basewars.ui.clampColorValue(data.color or basewars.ui.color_fg, 0.3, 1) or basewars.ui.color_fg,
			outline = basewars.ui.color_outline,
			text    = name
		}

		if amount ~= 1 then
			t[#t + 1] = {
				font    = basewars.ui.font_sans18,
				color   = basewars.ui.color_fg,
				outline = basewars.ui.color_outline,
				text    = string.format(" (%s)", tostring(amount))
			}
		end

		if name or amount then
			t[#t + 1] = { yadd = 4, newline = true }
		end

		if data.info then
			buildInfo(t, data.info)
		end

		self:setTooltipData(t)
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(basewars.ui.color_bg)
		surface.DrawRect(0, 0, w, h)

		local amount = self.amount or 0

		local f_amount = amount - math.floor(amount)

		if f_amount >= 0.01 then
			surface.SetDrawColor(255, 153, 0, 50)
			surface.DrawRect(3, 3, f_amount * (w - 6), h - 6)
		end
	end

	local Lerp = _G.Lerp
	function PANEL:PaintOver(w, h)
		local active = self:IsHovered() or self:IsDragging()
		local color  = active and self.color or self._inactive_color

		if not color then return end

		local r,  g,  b  = color.r, color.g, color.b
		local tr, tg, tb = self._target_r, self._target_g, self._target_b

		if tr then
			tr = Lerp(0.1, tr, color.r)
			tg = Lerp(0.1, tg, color.g)
			tb = Lerp(0.1, tb, color.b)
		else
			tr = color.r
			tg = color.g
			tb = color.b
		end

		self._target_r, self._target_g, self._target_b = tr, tg, tb

		surface.SetDrawColor(tr, tg, tb, 250)
		surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
		surface.DrawOutlinedRect(2, 2, w - 4, h - 4)

		local amount = self.amount or 0

		local r_amount = math.floor(amount)
		local f_amount = amount - r_amount

		if f_amount >= 0.01 then
			draw.textOutlined(
				string.format("%.3g", f_amount),
				basewars.ui.font_sans12,
				w - 4,
				h - 4,
				basewars.ui.color_fg,
				TEXT_ALIGN_RIGHT,
				TEXT_ALIGN_BOTTOM,
				basewars.ui.color_outline
			)
		end

		if r_amount > 1 then
			draw.textOutlinedLT(string.format("%d", r_amount), basewars.ui.font_sans12, 4, 4, basewars.ui.color_fg, basewars.ui.color_outline)
		end
	end

	vgui.Register("BWUI.Inventory.Tile", PANEL, "BWUI.Base")
end

do -- BWUI.Inventory.ProxyTile
	local PANEL = {}

	PANEL.proxy = true

	function PANEL:Init()
		self:resetTile()

		self:SetDnD("bwui_inventory")
		self:Receiver("bwui_inventory", self.dropped)
	end

	function PANEL:resetTile()
		if IsValid(self.tile) then self.tile:Remove() end

		self.tile = vgui.Create("BWUI.Inventory.Tile", self)
		self.tile:Dock(FILL)
		self.tile:SetMouseInputEnabled(true)

		self.tile.OnMousePressed = function(x)
			if x.tooltip_data then
				basewars.ui.getTooltipPanel():fadeOut()
			end

			self:resetTile()
		end
	end

	function PANEL:getActualTile()
		return self.tile
	end

	function PANEL:setInventory(inv)
		self.inventory = inv
	end

	function PANEL:getInventory()
		return self.inventory
	end

	function PANEL:subscribe(ent)
		self:unsubscribe()
		ext:subscribe(ent, self)
		self.ent = ent

		self.inventory = ent.bw_inventory
		self:update()
	end

	function PANEL:unsubscribe()
		if self.ent then
			ext:unsubscribe(self.ent, self)
		end
	end

	function PANEL:setItem(id)
		self.item = id
	end

	function PANEL:setFilter(filter)
		self.filter = filter
	end

	function PANEL:update(inv)
		inv = inv or self.inventory
		if not inv then return false end

		local item = self.item
		if not item then return false end

		local amount = inv[item]
		if not amount then return false end

		self.tile:setItem(item, amount)

		return true
	end

	function PANEL:dropped(drops, dropping, ...)
		if not dropping then return end
		local drop = drops[1]
		if not drop then return end
		if not drop.item then return end
		if self.filter and not self.filter(drop.item) then return end

		if drop.ent then
			self:subscribe(drop.ent)
		end

		self:setItem(drop.item)
		self:update()
	end

	function PANEL:OnRemove()
		self:unsubscribe()
	end

	vgui.Register("BWUI.Inventory.ProxyTile", PANEL, "DDragBase")
end
