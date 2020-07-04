AddCSLuaFile()

color_white = Color(255,255,255,255)

chathud = chathud or {}

chathud.CollectionDescriptions = {

}
chathud.CollectionNames = {

}

chathud.Emotes = chathud.Emotes or {}

function clinclude(f)
	if SERVER then AddCSLuaFile(f) else return include(f) end
end

function shinclude(f)
	include(f)
	AddCSLuaFile(f)
end



local convar_custom_handle = CreateConVar("xp_chat_force_source_handle", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE})
local convar_limited_tags  = CreateConVar("xp_chat_limited_tags",        "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE})

hook.Add("ChatShouldHandle", "chatexp.compat", function(handler, msg, mode)
	if DarkRP then return false end
	if convar_custom_handle:GetBool() then return false end
end)


function chathud.Include()

	shinclude("chathud/chattags.lua")
	shinclude("chathud/emotes.lua")

	clinclude("chathud/chathud.lua")
	clinclude("chathud/chatbox.lua")


	shinclude("chathud/chatexp.lua")

end

hook.Add("LibbedItUp", "ChatHUD", chathud.Include)

if LibItUp then 
	chathud.Include()
end

if SERVER then return end 



--[[
	CLIENTSIDE :
]]

local showTs = CreateConVar("xp_chat_timestamp_show",    "0", FCVAR_ARCHIVE, "Show timestamps in chat")
local hour24 = CreateConVar("xp_chat_timestamp_24h",     "1", FCVAR_ARCHIVE, "Display timestamps in a 24-hour format")
local tsSec  = CreateConVar("xp_chat_timestamp_seconds", "0", FCVAR_ARCHIVE, "Display timestamps with seconds")
local tickSn = CreateConVar("xp_chat_message_tick",      "1", FCVAR_ARCHIVE, "Enable tick sound when a message is received")

local dgray = Color(150, 150, 150)

local function pad(z)
	return z >= 10 and tostring(z) or "0" .. z
end

local zw = "\xE2\x80\x8B"
local function makeTimeStamp(t, h24, seconds)
	t[#t + 1] = dgray
	local d = os.date("*t")
	if h24 then
		t[#t + 1] = pad(d.hour) .. ":" .. zw .. pad(d.min) .. zw .. (seconds and ":" .. zw .. pad(d.sec) or "")
	else
		local h, pm = d.hour
		if h > 11 then
			pm = true
			h = h > 12 and h - 12 or h
		elseif h == 0 then
			h = 12
		end
		t[#t + 1] = pad(h) .. ":" .. zw .. pad(d.min) .. zw .. (seconds and ":" .. zw .. pad(d.sec) .. zw or "") .. (pm and " PM" or " AM")
	end
	t[#t + 1] = " - "
end

local function do_hook()
	local gm = GM or GAMEMODE
	if not gm then return end

	chatexp._oldGamemodeHook = chatexp._oldGamemodeHook or gm.OnPlayerChat
	function gm:OnPlayerChat(ply, msg, mode, dead, special)
		chatexp.LastPlayer = ply

		if hook.Run("ChatShouldHandle", "chatexp", msg, mode) == false then
			return chatexp._oldGamemodeHook(self, ply, msg, mode, dead)
		end

		if hook.Run("CheckChatCooldown", ply) == false then 
			return false
		end

		if mode == true  then mode = CHATMODE_TEAM end
		if mode == false then mode = CHATMODE_DEFAULT end

		local msgmode = chatexp.Modes[mode]
		local tbl = {}

		if showTs:GetBool() then
			makeTimeStamp(tbl, hour24:GetBool(), tsSec:GetBool())
		end

		local ret
		if msgmode and msgmode.Handle then
			ret = msgmode.Handle(tbl, ply, msg, dead, mode_data)
		else -- Some modes may just be a filter
			ret = chatexp.Modes[CHATMODE_DEFAULT].Handle(tbl, ply, msg, dead, mode_data)
		end

		if ret == false then return true end

		chat.AddText(unpack(tbl))
		return true
	end

	local green = Color(120, 219, 87)
	chatexp._oldGamemodeHook2 = chatexp._oldGamemodeHook2 or gm.ChatText
	function gm:ChatText(idx, name, text, type)
		if not IsValid(chatbox.frame) then chatbox.Build() end

		if type == "chat" then
			chatbox.ParseInto(chatbox.GetChatFeed(), green, name, color_white, ": " .. text)
			chathud:AddText(green, name, color_white, ": " .. text)
		return end

		if type == "darkrp" then return end -- Compat for some weird stuff with darkrp

		chatbox.ParseInto(chatbox.GetChatFeed(), green, text)
		chathud:AddText(green, text)

		return false
	end
end

do_hook()
hook.Add("InitPostEntity", "xp.do_hook", do_hook)
hook.Add("OnReloaded", "xp.do_hook", do_hook)

if chatbox and IsValid(chatbox.frame) then chatbox.frame:Close() end

local fontSize = CreateClientConVar("xp_chathud_font_size", "22", true, false, "Changes the Fonts of the chathud (not the chatbox).")

local function doFonts()
	surface.CreateFont("chathud_18", {
		font = "Roboto",
		extended = true,
		size = fontSize:GetInt(),
		weight = 400,
	})

	surface.CreateFont("chathud_18_blur", {
		font = "Roboto",
		extended = true,
		size = fontSize:GetInt(),
		weight = 400,
		blursize = 2,
	})
end

cvars.AddChangeCallback("xp_chathud_font_size", function(cv,_,new)
	doFonts()
end, "setFontsChathud")
doFonts()

do -- chathud
	local ew = {["CHudChat"] = true}
	hook.Add("HUDShouldDraw", "chathud.disable", function(ch)
		if ew[ch] then return false end
	end)

	local panics = {
		["sh"] = true,
		["stop"] = true,
		["shut"] = true
	}

	hook.Add("OnPlayerChat", "chathud.tagpanic", function(_,txt)
		if panics[txt:lower():Trim()] then chathud:TagPanic() end
	end)
end

do -- chatbox
	hook.Add("PreRender", "chatbox.close", function()
		if gui.IsGameUIVisible() and chatbox.IsOpen() then
			if input.IsKeyDown(KEY_ESCAPE) then gui.HideGameUI() end
			chatbox.Close()
		end
	end)

	hook.Add("SendDM", "chatbox.dm_send", function(ply, text)
		if not IsValid(chatbox.frame) then chatbox.Build() end

		chatbox.AddDMTab(ply)
		chatbox.ParseInto(chatbox.GetDMFeed(ply), LocalPlayer(), color_white, ": ", text)
	end)

	hook.Add("ReceiveDM", "chatbox.dm_receive", function(ply, text)
		if not IsValid(chatbox.frame) then chatbox.Build() end

		chatbox.AddDMTab(ply)
		chatbox.ParseInto(chatbox.GetDMFeed(ply), ply, color_white, ": ", text)
	end)

	hook.Add("HUDPaint", "chathud", function()
		if not chathud.Draw then return end --?
		chathud:Draw()
	end)

	hook.Add("PlayerBindPress", "chatbox.bind", function(ply, bind, down)
		if not down then return end
		if not IsValid(chatbox.frame) then chatbox.Build() end

		local team_chat = false

		if bind == "messagemode2" then
			chatbox.Open(true)
			return true
		elseif bind == "messagemode" then 
			chatbox.Open(false)
			return true
		elseif bind == "cancelselect" and chatbox.IsOpen() then 
			chatbox.Close()
			return true
		end

	end)
end

chat.old_text = chat.old_text or chat.AddText
function chat.AddText(...)
	if not IsValid(chatbox.frame) then chatbox.Build() end

	local cont = {...}

	for k,v in pairs(cont) do 
		if not isstring(v) then continue end 
		cont[k] = v:gsub("%c", "")
	end

	chatbox.ParseInto(chatbox.GetChatFeed(), ...)
	chat.old_text(...)

	chathud:AddText(...)

	if tickSn:GetBool() then
		chat.PlaySound()
	end
end

-- Start compatability for addons

chat.old_pos = chat.old_pos or chat.GetChatBoxPos
function chat.GetChatBoxPos()
	if not IsValid(chatbox.frame) then chatbox.Build() end

	return chatbox.frame:GetPos()
end

chat.old_size = chat.old_size or chat.GetChatBoxSize
function chat.GetChatBoxSize()
	if not IsValid(chatbox.frame) then chatbox.Build() end

	return chatbox.frame:GetSize()
end

chat.old_open = chat.old_open or chat.Open
function chat.Open(mode)
	chatbox.Open(mode == 1)
end

chat.old_close = chat.old_close or chat.Close
function chat.Close()
	chatbox.Close()
end

function chatbox.GetPos()
	return chat.GetChatBoxPos()
end

function chatbox.GetSize()
	return chat.GetChatBoxSize()
end
