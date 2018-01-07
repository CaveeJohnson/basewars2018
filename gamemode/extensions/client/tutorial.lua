local ext = basewars.createExtension"tutorial-client"

local font_large  = ext:getTag() .. "_large"
local font_normal = ext:getTag() .. "_normal"

ext.tutorialIntroText = [[
<font=font_normal>
Welcome to Basewars 2018, you will now face your first decision.

<color=200,200,200>If you ALREADY KNOW HOW TO PLAY, you can skip this tutorial.
If you HAVE NOT PLAYED BEFORE, or are USED TO THE 2015 VERSION, you will NEED to become acquainted.
IT IS RECOMMENDED YOU PLAY THIS REGARDLESS!

In the tutorial you will be unable to interact with any other players except in specific places.</color>
</font>
<font=font_large><color=255,255,255>IT IS RECOMMENDED YOU PLAY THIS REGARDLESS!</color></font>
]]


ext.tutorialBeforeText = ext.tutorialIntroText .. [[
<font=font_large><color=255,100,100>THE TUTORIAL HAS BEEN UPDATED SINCE YOU LAST SAW THIS!</color></font>
]]

ext.tutorialIntroText = ext.tutorialIntroText:gsub("font_normal", font_normal)
ext.tutorialIntroText = ext.tutorialIntroText:gsub("font_large", font_large)

surface.CreateFont(font_large, {
	font      = "DejaVu Sans",
	size      = 20,
})

surface.CreateFont(font_normal, {
	font      = "DejaVu Sans",
	size      = 14,
})

ext.tutorialVersion = 20180103
ext.file = "basewars2018_tutorial_done.txt"

function ext:writeDecisionMade()
	file.Write(self.file, self.tutorialVersion)
end

function ext:doneLatest()
	if not file.Exists(self.file, "DATA") then
		return false, false
	end

	local last_play = tonumber(file.Read(self.file, "DATA")) or 0
	if ext.tutorialVersion > last_play then
		return false, true
	else
		return true, true
	end
end

function ext:BW_PostContentNotification()
	local done, before = self:doneLatest()
	if done then return end

	local frame = vgui.Create("DFrame")
		frame:SetTitle("Basewars 2018 Edition Tutorial...")
		frame:SetDraggable(false)
		frame:ShowCloseButton(false)
		frame:SetBackgroundBlur(true)
		frame:SetDrawOnTop(true)

		frame:SetSize(ScrW() / 2.5, ScrH() / 4)

	local panel = vgui.Create("DPanel", frame)
		panel:SetPaintBackground(false)
		panel:Dock(FILL)

	local text = vgui.Create("DPanel", panel)
		text:SetPaintBackground(false)
		text:Dock(FILL)

		text.markup = markup.Parse(before and self.tutorialBeforeText or self.tutorialIntroText, frame:GetWide())
		text:SetSize(text.markup:Size())

		function text.Paint(p, w, h)
			p.markup:Draw(w / 2, h / 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

	local controls = vgui.Create("DPanel", frame)
		controls:SetTall(40)
		controls:SetPaintBackground(true)
		controls:Dock(BOTTOM)

	local play = vgui.Create("DButton", controls)
		play:Dock(TOP)
		play:SetHeight(20)

		play:SetText("Yes, I want to play the tutorial.")

		function play.DoClick(p)
			frame:Close()
			self:writeDecisionMade()

			hook.Run("BW_TutorialStart")
			LocalPlayer():ChatPrint("TUTORIAL IS NOT FINISHED, PLEASE ASK AN ADMIN IF YOU NEED HELP")
		end

	local skip = vgui.Create("DButton", controls)
		skip:Dock(TOP)
		skip:SetHeight(20)

		skip.clicks = 10 -- TODO: config? idk

		local clicks_rem = "No, I know this is not DarkRP. (Clicks remaining %d)"
		skip:SetText(clicks_rem:format(skip.clicks))

		function skip.DoClick(p)
			if skip.clicks <= 1 then
				frame:Close()
				self:writeDecisionMade()

				return
			end

			skip.clicks = skip.clicks - 1
			skip:SetText(clicks_rem:format(skip.clicks))
		end

	frame:Center()
	frame:MakePopup()
	frame:DoModal()
end
