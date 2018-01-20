local ext = basewars.createExtension"core.money-notifs"

if SERVER then
	util.AddNetworkString(ext:getTag())

	function ext:send(ply, amt, res)
		net.Start(self:getTag())
			net.WriteString(tostring(amt))
			net.WriteString(res)
		net.Send(ply)
	end

	function ext:PostSetupPlayerDataTables(ply)
		ply.addMoneyNotif = function(p, amt, res)
			p:addMoney(amt)
			if res then self:send(p, amt, res) end
		end

		ply.takeMoneyNotif = function(p, amt, res)
			p:takeMoney(amt)
			if res then self:send(p, -amt, res) end
		end
	end

	return
end

net.Receive(ext:getTag(), function()
	local amt = tonumber(net.ReadString()) or 0
	local res = net.ReadString()

	hook.Run("BW_OnMoneyNotification", amt, res)
end)
