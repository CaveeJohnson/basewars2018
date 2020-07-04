AddCSLuaFile()

local col = Color(200, 0, 255, 255)
local Msg = function(...) MsgC(col, ...)  end

chatexp = chatexp or {}
chatexp.NetTag = "chatexp" -- Do not change this unless you experience some very strange issues
chatexp.AbuseMode = "Kick" -- Kick or EarRape, this is what happens to people who try and epxloit the system
chatexp.CharLimit = 1024
-- This is basicly chitchat3
-- Max message length is now 0x80000000 (10^31)
-- Filters are fixed, better mode handling.

local color_red = Color(225, 0, 0, 255)
local color_greentext = Color(0, 240, 0, 255)
local color_green = Color(0, 200, 0, 255)
local color_hint = Color(240, 220, 180, 255)

function net.HasOverflowed()
	return (net.BytesWritten() or 0) >= 65536
end

CHATHUD_ONLY = 8

chatexp.Modes = {
	{
			Name = "Default",
			Filter = function(send, ply)
				return true
			end,
			Handle = function(tbl, ply, msg, dead, mode_data)
				if dead then
					tbl[#tbl + 1] = color_red
					tbl[#tbl + 1] = "*DEAD* "
				end

				tbl[#tbl + 1] = ply -- ChatHUD parses this automaticly
				tbl[#tbl + 1] = color_white
				tbl[#tbl + 1] = ": "
				tbl[#tbl + 1] = color_white

				if msg:StartWith(">") and #msg > 1 then
					tbl[#tbl + 1] = color_greentext
				end

				tbl[#tbl + 1] = msg
			end,
	},
	{
			Name = "Team",
			Filter = function(send, ply)
				return send:Team() == ply:Team()
			end,
			Handle = function(tbl, ply, msg, dead, mode_data)
				if dead then
					tbl[#tbl + 1] = color_red
					tbl[#tbl + 1] = "*DEAD* "
				end

				tbl[#tbl + 1] = color_green
				tbl[#tbl + 1] = "(TEAM) "

				tbl[#tbl + 1] = ply -- ChatHUD parses this automaticly
				tbl[#tbl + 1] = color_white
				tbl[#tbl + 1] = ": "
				tbl[#tbl + 1] = color_white

				if msg:StartWith(">") and #msg > 1 then
					tbl[#tbl + 1] = color_greentext
				end

				tbl[#tbl + 1] = msg
			end,
	},
	
	[CHATHUD_ONLY] = {
		Name = "HUDOnly",

		Handle = function(tbl, ply, msg, dead, special)
			chathud:AddText(true, msg)
			return false
		end
	}

}

for k, v in next, chatexp.Modes do
	_G["CHATMODE_"..v.Name:upper()] = k
end

if CLIENT then
	function chatexp.Say(msg, mode, mode_data)
		local cdata = util.Compress(msg)

		local suc, err = pcall(function()
		net.Start(chatexp.NetTag)
			net.WriteUInt(#cdata, 16)
			net.WriteData(cdata, #cdata)

			net.WriteUInt(mode, 8)
			net.WriteUInt(mode_data or 0, 16)
		net.SendToServer()
		end)

		if not suc then
			Msg("CEXP: Not installed correctly!\n" .. err)

			if mode ~= CHATMODE_DM then
				LocalPlayer():ConCommand((mode == CHATMODE_TEAM and "say_team \"" or "say \"") .. msg .. "\"")
			end -- fallback
		end
	end

	function chatexp.SayChannel(msg, channel)
		chatexp.Say(msg, CHATMODE_CHANNEL, channel)
	end

	function chatexp.DirectMessage(msg, ply)
		chatexp.Say(msg, CHATMODE_DM, ply:UserID())
	end

	net.Receive(chatexp.NetTag, function(len2)

		local special = net.ReadBool()
		local ply 	= net.ReadEntity()

		local len 	= net.ReadUInt(16)
		local data 	= net.ReadData(len)

		local mode 	= net.ReadUInt(8)
		local mode_data = net.ReadUInt(16)

		data = util.Decompress(data, 2^12)

		if not data or data == "" then
			printf("CEXP: Failed to decompress message from player %s", ply)
			return
		end

		local dead = ply:IsValid() and ply:IsPlayer() and not ply:Alive()
		hook.Run("OnPlayerChat", ply, data, mode, dead, special)
	end)
end
if SERVER then

	util.AddNetworkString(chatexp.NetTag)

	local realPrint = _print or print

	local cds = {}

	function chatexp.SayAs(ply, data, mode)
		if #data > chatexp.CharLimit then
			cds[ply] = (cds[ply] or 0) + 1

			if cds[ply] < 2 then printf("CEXP: Too much data from %s (%s > %s)", ply, #data, chatexp.CharLimit) return end

			if not timer.Exists("ChatHUDCoolDown" .. ply:SteamID64()) then 
				timer.Create("ChatHUDCoolDown" .. ply:SteamID64(), 1, 0, function()
					if cds[ply] < 2 then cds[ply] = 0 return end
					printf("CEXP: %s seems to repeatedly spam overly long messages: violated %s times within 1s", ply, cds[ply])
					cds[ply] = 0
				end)
			end

			return
		end
		data = data:gsub("%c", "")
		local ret = hook.Run("PlayerSay", ply, data, mode)

		if ret == "" or ret == false then return end
		if isstring(ret) then data = ret end

		local filter = player.GetHumans()

		local cdata = util.Compress(data)
		if not cdata then
			Msg("CEXP: Failed to re-compress message.")
			return
		end

		net.Start(chatexp.NetTag)
			net.WriteBool(false) 	--special message?
			net.WriteEntity(ply)	--sender

			net.WriteUInt(#cdata, 16)	--len of data and compressed data
			net.WriteData(cdata, #cdata)

			net.WriteUInt(mode, 8)		--idfk what these are lmao

			if net.HasOverflowed() then
				Msg("CEXP: Net overflow -> '" .. data .. "'")
				return
			end
		net.Send(filter)

		realPrint(ply:Nick() .. ": " .. data)
	end

	local lastmsges = {}

	chathud.ChatCDPadding = 1
	chathud.ChatCD = 0.5
	chathud.ChatSpamCD = 3 
	chathud.LetViolate = 2

	net.Receive(chatexp.NetTag, function(_, ply)
		local cant = hook.Run("CheckChatCooldown", ply) == false 
		if cant then return end 

		local len		= net.ReadUInt(16)
		local cdata	= net.ReadData(len)

		local mode	= net.ReadUInt(8)

		--TODO: add the number to Decompress to prevent decompression bombs
		--im not doing it rn cuz i wanna test it :^)

		local data = util.Decompress(cdata, 2^12)

		if not data or data == "" then
			printf("CEXP: Failed to decompress message from %s", ply)
			return
		end

		chatexp.SayAs(ply, data, mode)
	end)

	hook.Add("CheckChatCooldown", "ChatHUD", function(ply)

		local cd = ply.ChatCD

		if cd then

			local cd = ply.ChatCD

			local overcd = CurTime() < cd.NextWrite

			if overcd then 
				
				cd.Violations = cd.Violations + 1

				if cd.Violations <= chathud.LetViolate then --lets you violate chat cooldown a few times before giving you a big cooldown

					goto docd
				else 

					if not cd.ViolationCooldown then 
						cd.NextWrite = CurTime() + chathud.ChatSpamCD
						local t = CurTime() + 5
						local holyshit = [[<eval=[env.of=lt(t(), %.2f)]><color=[(env.of and 220 or 140) + sin(t()*6)*40],[140 + sin(t()*6) *30],[(env.of and 140 or 220)+sin(t()*6)*40]>You're <text=[(env.of and "now on cooldown for ".. string.format("%%.2f", %.2f-t()) .." seconds") or "not on cooldown anymore."]>]]
						holyshit = holyshit:format(math.Round(cd.NextWrite, 1), math.Round(cd.NextWrite, 1))
						ply:SendChatHUD(holyshit)
					end --we haven't punished yet

					cd.ViolationCooldown = true
					return false
				end

			else 

				local nextcd = math.min((CurTime() - cd.NextWrite) / chathud.ChatCDPadding, chathud.ChatCDPadding)
				cd.NextWrite = CurTime() + chathud.ChatCD + (chathud.ChatCDPadding - nextcd)

				local newviol = math.max(
					(nextcd < chathud.ChatCDPadding/2 and 0)
					or cd.Violations - 1,
				0)

				cd.Violations = newviol
				goto allow
			end

		else 
			ply.ChatCD = {NextWrite = CurTime() + chathud.ChatCD, Violations = 0}
			cd = ply.ChatCD
		end

		::docd::
		cd.NextWrite = CurTime() + chathud.ChatCD

		::allow::
		cd.ViolationCooldown = false 

		return true
	end)





	local PLAYER = FindMetaTable("Player")

	function PLAYER:SendChatHUD(tx)
		--we don't need as many checks because this is supposed to be for trusted things like addons, not players

		local cdata = util.Compress(tx)

		if not cdata then
			Msg("CEXP: Failed to re-compress message.")
			return
		end

		net.Start(chatexp.NetTag)
			net.WriteBool(true) 	--special message?
			net.WriteEntity(ply)	--sender

			net.WriteUInt(#cdata, 16)	--len of data and compressed data
			net.WriteData(cdata, #cdata)

			net.WriteUInt(CHATHUD_ONLY, 8)		--idfk what these are lmao

			if net.HasOverflowed() then
				Msg("CEXP: Net overflow -> '" .. data .. "'")
				return
			end

		net.Send(self)

	end
end -- SERVER
