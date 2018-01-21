local ext = basewars.createExtension"afk-tracker"
ext.timeUntilAFK = 1 * 60

function ext:SetupPlayerDataTables(ply)
	ply:netVar("Int", "AFKLastUpdated")
end

function ext:PostSetupPlayerDataTables(ply)
	ply.getAFKTime = function(p)
		return CurTime() - p:getAFKLastUpdated()
	end
	ply.AFKTime = ply.getAFKTime -- support for stuff that depends on MS or BW15 method

	ply.isAFK = function(p)
		return p:getAFKTime() > self.timeUntilAFK
	end
	ply.IsAFK = ply.isAFK
end

local last = 0
function ext:clearAFK(ply)
	if CLIENT then
		if CurTime() - last < 2 then -- dont spam the server
			net.Start(ext:getTag())
			net.SendToServer()
		end

		return
	end

	ply:setAFKLastUpdated(CurTime())
end

ext.GUIOnCursorMoved        = ext.clearAFK

if CLIENT then return end

util.AddNetworkString(ext:getTag())

ext.PlayerReallySpawned     = ext.clearAFK
ext.PlayerSay               = ext.clearAFK
ext.CanPlayerSuicide        = ext.clearAFK
ext.ShouldPlayerSpawnObject = ext.clearAFK

function ext:StartCommand(ply, md)
	if md:GetMouseX() ~= 0 or md:GetMouseY() ~= 0 or
		md:GetButtons() ~= 0 or md:GetImpulse() ~= 0 then
		self:clearAFK(ply)
	end
end

net.Receive(ext:getTag(), function(ply)
	ext:clearAFK(ply)
end)
