local ext = basewars.createExtension"spawn-denied"

if SERVER then
	util.AddNetworkString(ext:getTag())

	function ext:BW_DenyPlayerSpawnObject(ply)
		net.Start(self:getTag())
		net.Send(ply)

		if ply.bw_denySpawnTime and ply.bw_denySpawnTime + 1 > CurTime() then
			local count = ply.bw_denySpawnCount + 1
			ply.bw_denySpawnCount = count

			if count > 3 and not ply:IsOnFire() then
				ply:Ignite(2) -- stop that!
			end
		else
			ply.bw_denySpawnCount = 0
		end

		ply.bw_denySpawnTime = CurTime()
	end

	return
end

ext.alpha = 0
ext.sound = Sound("ambient/alarms/klaxon1.wav")

net.Receive(ext:getTag(), function()
	local ply = LocalPlayer()
	local pos = ply:GetPos()

	local spam = 1 + (ext.alpha / 100)
	util.ScreenShake(pos, 2, 10 * spam, 1, 5000)
	util.ScreenShake(pos, 5, 5 * spam, 0.6, 5000)
	ply:EmitSound(ext.sound, 75, 90, 0.5 * spam)

	ext.alpha = math.min(ext.alpha + 45, 100)
end)

function ext:DrawOverlay()
	if self.alpha <= 1 then return end
	self.alpha = self.alpha - 1

	surface.SetDrawColor(255, 50, 50, self.alpha)
	surface.DrawRect(0, 0, ScrW(), ScrH())
end
