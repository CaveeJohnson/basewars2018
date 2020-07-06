local ext = basewars.__ext["f3.menu"] or basewars.createExtension"f3.menu" 	--don't overwrite the extension if it exists; we need the reference to the f3 menu if its open
																			--we also need the original, not a copy
setfenv(1, _G)

local is_down = false
ext.scale = math.max(ScrH() / 1080, 0.5)

function ext.createMenu()
	if IsValid(ext.FF) then ext.FF:Remove() end --we never want more than 1 F3 menus open
	local FF = vgui.Create("NavFrame")
	ext.FF = FF

	local w = math.max(ext.scale * 750, 600)
	FF:SetSize(w, w * 0.565)
	FF:Center()

	FF:PopIn()
	FF.Shadow = {}
	FF:MakePopup()
	FF:AddDockPadding(4, 4, 4, 4)
	FF:SetRetractedSize(w * 0.08)
	FF:SetTabSize(48 + w * 0.02)

	function FF:OnKeyCodePressed(key)
		if key == KEY_F3 then
			self:OnClose()
		end
	end

	function FF:OnClose()
		if self.popInAnim then self.popInAnim:Stop() self.popInAnim = nil end
		if self.hiding then return end

		self.popOutAnim = self:PopOut(nil, nil, function()
			self:SetVisible(false)
			self:Emit("Hide")
		end)

		self:SetInput(false)

		if self.moveAnim then
			self.moveAnim:Stop()
		end

		self.moveAnim = self:MoveBy(0, 16, 0.25, 0, 0.5)

		self.hiding = true
		return false
	end

	function FF:PostPaint(w, h)
		self:Emit("Paint", w, h)
	end

	hook.Run("F3_CreateTab", FF)

	return FF
end

hook.Add("PlayerButtonUp", "Basewars.F3", function(ply, key)
	if key ~= KEY_F3 then return end
	is_down = false
end)

hook.Add("PlayerButtonDown", "Basewars.F3", function(ply, key)
	if key ~= KEY_F3 then return end
	if not IsFirstTimePredicted() then return end

	if CW_CUSTOMIZE ~= nil then
		local wep = ply:GetActiveWeapon().dt
		if IsValid(wep) and (wep.dt and wep.dt.State == CW_CUSTOMIZE) then return end --cw 2.0 support
	end

	local firstpress = not is_down
	is_down = true

	if IsValid(ext.FF) then

		local FF = ext.FF

		if not FF:IsVisible() and firstpress then

			FF:SetVisible(true)

			FF:Center()
			FF.Y = FF.Y + 16

			if FF.moveAnim then
				FF.moveAnim:Stop()
			end

			FF.moveAnim = FF:MoveBy(0, -16, 0.2, 0, 0.5)

			if FF.popOutAnim then
				FF.popOutAnim:Stop()
				FF.popOutAnim = nil
			end

			FF.popInAnim = FF:PopIn(nil, nil, nil, true)
			FF:MakePopup()
			FF:SetInput(true)
			FF.hiding = false
			FF:Emit("Show")

		end

		return
	end

	ext.createMenu()
end)

function ext:F3_ModuleLoaded()
	if IsValid(self.FF) then
		local vis = self.FF:IsVisible()
		self.FF:Remove()

		local menu = self.createMenu()
		menu:SetVisible(vis)
	end
end

ext:F3_ModuleLoaded()

concommand.Add("f3_remove", function()
	if IsValid(ext.FF) then
		ext.FF:Remove()
	end
end)

hook.Add("OnScreenSizeChanged", "F3Reset", function()
	if IsValid(ext.FF) then
		ext.FF:Remove()
	end
end)

