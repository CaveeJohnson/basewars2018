local ext = basewars.createExtension"spawn-denied"

if SERVER then
	util.AddNetworkString(ext:getTag())

	function ext:BW_DenyPlayerSpawnObject(ply)
		net.Start(self:getTag())
		net.Send(ply)
	end

	return
end

ext.alpha = 0
ext.sound = Sound("ambient/alarms/klaxon1.wav")

net.Receive(ext:getTag(), function()
	local pos = ply:GetPos()

	util.ScreenShake(pos, 2, 10, 1, 5000)
	util.ScreenShake(pos, 5, 5, 0.6, 5000)
	ply:EmitSound(ext.sound, 75, 90, 0.5)

	ext.alpha = 45
end)

function ext:DrawOverlay()
	if self.alpha <= 1 then return end
	self.alpha = self.alpha - 1

	surface.SetDrawColor(255, 50, 50, self.alpha)
	surface.DrawRect(0, 0, ScrW(), ScrH())
end
