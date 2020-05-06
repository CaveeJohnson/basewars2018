if not CLIENT then return end

--[[
	Icon:

	Icon(URL or IMaterial, name)
		create an Icon object; it's white by default
		if you give it a URL you hafta give it a name as well

	ic:SetColor(col)
		duh

	ic:Paint(x, y, w, h[, rotation])
		duh
		be careful, if you're using rotation then it uses surface.DrawTexturedRectRotated instead of just texturedrect
		this means xy will be not the top left but the middle of the icon now
]]
Icon = Class:callable()

function Icon:Initialize(url, name)
	if not url then error("Icon.Initialize: expected IMaterial in arg #1 or URL + name, got nothing instead") return end

	local is_url = isstring(url) and url:match("^http[s]?://")

	if is_url and not isstring(name) then error("Icon.Initialize: got URL as arg #1, expected name as arg #2 as well, got nothing instead") return end

	if IsMaterial(url) then
		self.Material = url
	else

		if is_url then
			self.URL = url
			self.Name = name
		else
			local mat = MoarPanelsMats[url] or Material(url)

			MoarPanelsMats[url] = mat
			self.Material = mat
		end

	end

	self.Color = color_white
end

function Icon:SetColor(col)
	self.Color = col
end

function Icon:Paint(x, y, w, h, rot)
	local col = self.Color
	surface.SetDrawColor(col.r, col.g, col.b, col.a)

	if not self.Material then
		local mat = surface.DrawMaterial(self.URL, self.Name, x, y, w, h, rot)

		if mat then 			--cache the downloaded material as an IMaterial asap
			self.Material = mat.mat
		end

	else
		surface.SetMaterial(self.Material)

		if rot then
			surface.DrawTexturedRectRotated(x, y, w, h, rot)
		else
			surface.DrawTexturedRect(x, y, w, h)
		end

	end
end