file.CreateDir("emoticon_cache")

setfenv(1, _G)

local col = Color(255, 200, 0, 255)
local Msg = function(...) MsgC(col, ...)  end
local surface = surface 

local color_none = Color(0, 0, 0, 0)

local utflen = function(s)
	return (utf8.len(s:sub(#s, #s-1)) == 1 and #(s:sub(#s, #s-1) == 2)) and 2 or 1
end

local Run = function(func, ...)	--kinda like eval
	if isfunction(func) then 
		return func(...)
	end
end

local Emote = chathud.Emote 

chathud.oldShadow = chathud.oldShadow or false

--[[
	This chat is a piece of shit. Don't poke around for too long or you'll gouge your fucking eyes out.
	Good luck.
]]

chathud.FFZChannels = {
	"pajlada",
	"1poseidon3",
	"forsen",
	"benignmc",
	"clay0m"
}

chathud.Shortcuts = chathud.Shortcuts or {}
chathud.Items = chathud.Items or {}

chathud.x = 0.84 * 64



local ChatHUDYPos = ScrH() - (0.84 * 200) - (0.84 * 140)
chathud.y = ChatHUDYPos

chathud.W = 600
chathud.NameLeeway = chathud.W * 0.2

local blacklist = {
	["0"] = true,
	["1"] = true,
}
file.CreateDir("emoticon_cache")
file.CreateDir("emoticon_cache/twitch")
file.CreateDir("emoticon_cache/ffz")

--This is shitcode written when i was starting out lua, pls skip

function chathud.CreateFFZShortcuts(update)


	local function ReadChannelInfo(filename, chan)

		filename = string.lower(filename)
		Msg("[ChatHUD]: FFZ data file found! Creating shortcuts... \n")

		if file.Exists(filename, "DATA") and not update then

			local data = file.Read(filename, "DATA")
			local d = util.JSONToTable(data)
			if not d then print(#data) return ErrorNoHalt("ChatHUD: Failed to read existing FFZ Emote cache.\n") end

			local name

			for name1, v in pairs(d) do
				--if isnumber(v) then continue end
				if name1=="sets" then
					for k,_ in pairs(v) do --i hate it as much as you do
						name=_
					end
				continue
				end 
			end
			if not name then return end

			if istable(name["emoticons"]) then
				for num, cont in pairs(name["emoticons"]) do
					if (cont.name) and not chathud.Shortcuts[cont.name] and not blacklist[cont.name] then 
						local url
						if cont.urls[4] then url=cont.urls[4] elseif cont.urls[2] then url=cont.urls[2] else url=cont.urls[1] end

						chathud.Emotes[cont.display_name or cont.name] = Emote(cont.display_name or cont.name, "https:" .. url)
																			:AddToCollection("FFZ")
																			:SetStatic(true)
																			:AddShortcut()
					end

				end
			end
			hook.Run("ChatHUDFFZUpdated", Emotes.Collections.FFZ)
		end
	end

	local function DownloadChannelInfo(chan)

	 	local chan = string.lower(chan)
		local filename = "emoticon_cache/ffz_global_emotes_" .. chan .. ".dat"
		Msg("[ChatHUD]: FFZ data for channel "..chan.." not found! Downloading... \n")

		http.Fetch("https://api.frankerfacez.com/v1/room/"..tostring(chan), function(b)
				local d = util.JSONToTable(b)
				if not d then return ErrorNoHalt("ChatHUD: Failed to updated FFZ Emote cache.\n") end

				for name1, v in pairs(d) do
					--if isnumber(v) then continue end

					if name1=="sets" then
						for k,_ in pairs(v) do --i hate it as much as you do
							name=_
						end
						continue
					end 
				end

				if istable(name["emoticons"]) then
					for num, cont in pairs(name["emoticons"]) do
						if (cont.name) and not chathud.Shortcuts[cont.name] and not blacklist[cont.name] then 
							local url

							if cont.urls[4] then url=cont.urls[4] elseif cont.urls[2] then url=cont.urls[2] else url=cont.urls[1] end
							chathud.Emotes[cont.display_name or cont.name] = Emote(cont.display_name or cont.name, "https:" .. url)
																				:AddToCollection("FFZ")
																				:SetStatic(true)
																				:AddShortcut()
						end

					end
				end

				if not file.Exists(filename, "DATA") then
					file.Write(filename, b .. " ")
				else
					file.Append(filename, b .. " " )
				end

				hook.Run("ChatHUDFFZUpdated", Emotes.Collections.FFZ)
			end,
		function() 
			print("send help") 
		end)
		
	end



	local found = file.Find("emoticon_cache/ffz_global_emotes_*.dat", "DATA")

	for k,chan in pairs(chathud.FFZChannels) do
		if table.HasValue(found,"ffz_global_emotes_"..string.lower(chan)..".dat") then 
			ReadChannelInfo("emoticon_cache/ffz_global_emotes_"..string.lower(chan)..".dat", string.lower(chan))
		else
			DownloadChannelInfo(string.lower(chan))
		end
	end

end


--[[
	Twitch emotes shortcuts scrapped because Twitch changed API versions and i CBA to rewrite it.
	All of those emotes mostly suck anyways.

	"This api version is gone."
]]

local function env(msg, spec)
	local tick = 0
	local env = {
		sin = math.sin,
		cos = math.cos,
		tan = math.tan,
		sinh = math.sinh,
		cosh = math.cosh,
		tanh = math.tanh,
		rand = math.random,
		pi = math.pi,
		log = math.log,
		log10 = math.log10,

		lt = function(a,b) return a < b end, 	--because string parsing
		mt = function(a,b) return a > b end,

		time = CurTime,
		t = CurTime,
		realtime = RealTime,
		rt = RealTime,
		tick = function()
			local o = tick
			tick = tick + 1
			return o / 100
		end,
		st = msg.SendTime,
	}

	if spec then 
		env.__index = _G 
		env.env = env
		setmetatable(env, env)
	end

	return env
end

local badlua = {
	["while"] = true,
	["for"] = true,
	["do"] = true,
	["end"] = true,
	["if"] = true,
	["function"] = true, 
	["repeat"] = true, 
	["until"] = true
}

local function CompileExpression(str, msg, special, preenv)

	local env = preenv or env(msg, special)

	if not special then --special messages don't get all the checks and can run unrestricted codez

		local ch = str:match("[^=1234567890%-%+%*/%%%^%(%)%.A-z%s]")
	
		if ch then 	--disallow strings and string methods ( e.g. ("Stinky poopy"):rep(999) )
					--fun fact; the string library may not be in the envinroment but string methods will still work!
			return "expression: invalid character " .. ch
		end

		for word in str:gmatch("(.-)[%p%s]") do 
			if badlua[word] then return "simple expressions please" end
		end

		for word in str:gmatch("[%p%s](.-)") do 
			if badlua[word] then return "simple expressions please" end
		end
	end

	local compiled = CompileString("return (" .. str .. ")", "expression", false)
	
	if isstring(compiled) then
		compiled = CompileString(str, "expression", false)
	end

	if isstring(compiled) then
		return compiled
	end

	if not isfunction(compiled) then
		return "expression:1: unknown error"
	end
	setfenv(compiled, env)

	return compiled, env
end

chathud.CompileExpression = CompileExpression

--[[

	PepeLaugh YOU DONT EVEN KNOWN WHAT YOU ARE GOING INTO PepeLaugh

	Wear eye protection.

]]

local tagptrn = "<([/%w]+)=?([^>]*)>"
local tagendptrn = "/(.+)"
local expptrn = "(%b[]),?" 		--pattern that captures shit in []s and defines whether the arg is an expression
local valptrn = "%s*(.-)%s*,"	--match arg from a tag without spaces and commas
local lastarg = "([^,%s?]+)$"	--match last arg in a tag


--[[
	Returns a string without tags + draw queue for the tags (tag -> text -> tag -> text ...)
]]

function ParseTags(str, special)

	local tags = {} --this contains strings (regular text) and tables (tags)
	
	local prevtagwhere
	local env 		--envinroment for expressions, it's shared for one message

	for s1 in string.gmatch(str, ":(.-):") do --shortcuts, then tags 

		if chathud.Shortcuts[s1] then 
			str = str:gsub((":%s:"):format(s1), chathud.Shortcuts[s1], 1)
		end
		
	end

	for tag, argsstr in string.gmatch( str, tagptrn ) do
		local OGargsstr = argsstr --argsstr will be changed

		local chTag = chathud.TagTable[tag]
		if chTag and chTag.NoRegularUse and not special then continue end 


		local starts = str:find(tag, prevtagwhere or 1, true)
		if starts then starts = starts - 1 end --add the "<" which doesn't get matched 

		local ends = starts

		if argsstr then --V for "="		 v for ">"
			ends = starts + #tag + 1 + #argsstr + 1
		else 		
			ends = starts + #tag + 1 --1 for ">"
		end

		--local tag, argsstr = tagcont:match(tagptrn)

		if not chTag then

			local isend = tag:match(tagendptrn)
			if not isend or not chathud.TagTable[isend] then print("no such tag to end:", tag, isend) continue end

			for k,v in ipairs(table.Reverse(tags)) do
				if not istable(v) then continue end  
				if v.tag == isend and not v.ends and not v.ender then 
					--create an ender tag, which will disable tag at k
					v.ends = starts 

					str = str:gsub(tag:PatternSafe(), "", 1)

					local key = #tags + 1

					if prevtagwhere then 
						tags[key] = str:sub(prevtagwhere, starts+utflen(str)-2)	--if ender, put text first ender later
						key = key + 1
					end

					tags[key] = {
						tag = isend, 
						ender = true, 
						ends = v.realkey,	--ends tag with key v.realkey
						realkey = key
					}
					
					prevtagwhere = starts + 2 --+2 for <>

					break
				end 
			end

			continue
		end

		local info = {
			SendTime = CurTime(),
		}

		if not prevtagwhere then 
			tags[#tags + 1] = str:sub(1, starts - utflen(str)) --utflen decides whether or not sub 2 chars
		end

		local args = {}
		

		if argsstr then
			local lastargpos = 0
			
			for arg in argsstr:gmatch(expptrn) do 	--First parse all the expression args

		        local starts, ends = argsstr:find(arg, lastargpos, true)
		        lastargpos = starts + 1

		        local sepnum = 0
		        local lastsep = 0

		        local num = #args + 1
				if not chTag.args[num] then break end --more args than the tag takes: ignore eet

		      --  argst[#argst + 1] = arg

		        argsstr = argsstr:sub(0, starts-1) .. "-" .. argsstr:sub(ends+1) --"-" allows you to ignore a var and let it be set to a default value; unless it already has a value...
		        arg = arg:sub(2, -2) --get rid of []

		        local func, newenv = CompileExpression(arg, info, special, env)				-- like this handy expression we just compiled!
		        env = env or newenv

				if isstring(func) then 
					printf("Expression error: %s", func)
					continue
				end 

				args[#args + 1] = func 
		    end

		    local offset = 0
		    local i = 0

		    for arg in argsstr:gmatch(valptrn) do 	--Then parse all static args (non-expressions)
		        i = i + 1
		        if arg == "-" then continue end --this also increments i, basically offsetting arg by +1
		        if not chTag.args[i] then break end 

		        local typ = chTag.args[i].type
				if not chathud.TagTypes[typ] then printf("Unknown argument type! '%s'", typ) break end 

				local ret = chathud.TagTypes[typ](arg)	

				if ret then table.insert(args, i, ret) end --if conversion to type succeeded
		        
		    end

		    

			local lastargstr = argsstr:match(lastarg)

			if lastargstr and lastargstr ~= "-" then
				args[i+1] = lastargstr 
			end

		end
		
		local key = #tags + 1

		if prevtagwhere then 
			tags[key] = str:sub(prevtagwhere + utflen(str) - 1, starts-1)
			key = key + 1
		end


		for k,v in ipairs(chTag.args) do --clamp values to mins/maxs
			if isnumber(args[k]) then
				if v.min then 
					args[k] = math.max(args[k], v.min)
				end 
				if v.max then 
					args[k] = math.min(args[k], v.max)
				end
			end

			if not args[k] then 		--if that arg didnt exist set it to default
				args[k] = v.default 
			end 

		end

		tags[key] = {
			tag = tag, 
			args = args,
			starts = starts,
			realkey = key --for ender to keep track due to table reversing
		}

		prevtagwhere = starts

		local tosub = "<" .. tag .. ((OGargsstr and "=" .. OGargsstr) or "") .. ">"
		tosub = tosub:PatternSafe()
		str = str:gsub(tosub, "", 1) --remove the tag we just parsed
	end


	local start = prevtagwhere or 1

	tags[#tags + 1] = string.sub(str, start, #str)

	return str, tags
end

function chathud:AddMarkup()
	
end

function chathud:CleanupOldMarkups()
	
end

local consoleColor = Color(106, 90, 205, 255)
chathud.History = chathud.History or {}	--don't reset history on updates; preserves text on HUD
chathud.HistNum = 0

local names = {}

function chathud:AddText(...)

	local cont = {...}
	local special = false 

	if cont[1] == true then 
		table.remove(cont, 1)
		special = true 
	end

	local time = CurTime()
	local nw = 0

	

	local msgstarted = false 
	local entparsed = false 
	local hasentity = false 

	local name = ""	--sender name

	local retcont = {}

	local fulltxt = ""
	local curtext = ""

	local wrappedtxt = ""


	for k,v in ipairs(cont) do

		--[[ 
			Parse entity name. 
			Usually the sender, except on very rare occasions. 
		]]

		if isentity(v) then 
			fulltxt = fulltxt .. ((v.Nick and v:Nick()) or "Console")
			hasentity = true
			continue
		end

		if not isstring(v) then continue end 

		fulltxt = fulltxt .. v
	end


	local curwidth = 0

	local merged = {} --final table, containing everything 

	local namewid = 0

	for k,v in ipairs(cont) do 

		--[[ 
			Parse entity name and color.  
		]]

		if isentity(v) then 
			local col = GAMEMODE.GetTeamColor and GAMEMODE:GetTeamColor(v)

			merged[#merged + 1] = col 

			local n = IsValid(v) and (
				(v.Nick and v:Nick()) or 

				(	(v.GetName and v:GetName()) or 
					(v.GetClass and v:GetClass())
				)
			) or "Console"

			names[v], nw = string.WordWrap2(n, chathud.W, "CH_Name")
			curwidth = curwidth + nw
			merged[#merged + 1] = n

			name = name .. names[v]
			entparsed = true 
			surface.SetFont("CH_Text")
			namewid = math.min(chathud.NameLeeway, (surface.GetTextSize(name)))

			continue
		end

		if IsTag(v) then 
			local tag = {}

			tag.tag = v.Name
			tag.args = v.Args 
			tag.starts = #curtext
			tag.realkey = #merged + 1

			merged[#merged + 1] = tag
		end

		--[[
			Tag-parse the string and merge content table and tag table while also word-wrapping them.
		]]

		if isstring(v) then

			curtext = curtext .. v

			local untagged, tags = ParseTags(v, special)

			surface.SetFont("CH_Text")

			for k2,tg in pairs(tags) do 

				if isstring(tg) then
					local tw, th = surface.GetTextSize(tg)

					local str, newwid, wrapped = string.WordWrap2(tg, {chathud.W - curwidth, chathud.W - (namewid * chathud.WrapStyle)})

					if wrapped then 
						curwidth = (newwid or tw)
					else
						curwidth = curwidth + (newwid or tw)
					end

					wrappedtxt = wrappedtxt .. str
					merged[#merged + 1] = str
					continue 
				end

				if istable(tg) then 	--tag
					merged[#merged + 1] = tg
				end
			end

				
		end

		if IsColor(v) then 
			merged[#merged + 1] = v 
		end
	end

	local ignore = {}

	contents = untagged

	--surface.SetFont("CH_Text")
	--local tw, th = surface.GetTextSize(name .. ": ")

	local key = #self.History + 1
	self.History[key] = {
		t = time,	--time(for history time tracking)
		a = 50,	--alpha(for history fadeout)
		c = merged,	--contents(text+colors+tags to show)

		name = name,	--sender name
		namewid = math.min(namewid, chathud.NameLeeway),

		fulltxt = fulltxt,	--just the text
		wrappedtxt = wrappedtxt,

		tags = {},		--tags tbl which will be filled in
		buffer = buffer,	--buffer to use
		realkey = key,

		color = color_white:Copy(),
		heights = {}
	}

	return self.History[key]
end

function chathud:Think()

end

function chathud:PerformLayout()
	
end

surface.CreateFont("CH_Text", {
        font = "Roboto",
        size = 22,
        weight = 400,
})

surface.CreateFont("CH_Name", {
    font = "Titillium Web SemiBold",
    size = 28,
    weight = 400,
})

surface.CreateFont("CH_NameShadow", {
    font = "Titillium Web SemiBold",
    size = 28,
    weight = 400,
    blursize = 2
})

surface.CreateFont("CH_TextShadow", {
    font = "Roboto",
    size = 22,
    weight = 400,
    blursize = 2,
})

local matrix = Matrix()

chathud.CharH = 22
chathud.WrapStyle = 1  --1 = consider nickname, 0 = ignore nickname start from 0

local shadowfont = "CH_TextShadow"

local function DrawText(txt, buffer, a)
	if not txt then return false end 

	local font = buffer.font or "CH_Text"
	a = a or buffer.a

	local col = buffer.fgColor or Color(255, 255, 255)

	local amtoflines = 0
	local lines = {}
	local h = 22

	local shouldpaint = not buffer.EvaluationPaint --oh lord

	-- if text requires a rewrap then it's from a tag
	-- if we get what tag made us require a rewrap, we can try to pull out cache
	-- in case we re-wrapped text for this tag before

	local dat = buffer.hist

	if buffer.RequiresRewrap then 

		if not (dat.cache and dat.cache[buffer.RequiresRewrap]) then 	

			local tx, newlines = txt:gsub("-?\n", "")	--de-wrap text
			txt = tx

			dat.cache = dat.cache or {}
			local newtx = string.WordWrap2(txt, {chathud.W - buffer.x, chathud.W}, font)	

			local newnewlines = select(2, newtx:gsub("%c", ""))

			dat.newlines = dat.newlines - newlines + newnewlines 	--re-calculate amount of newlines for height calculation: only applies next frame :(

			dat.cache[buffer.RequiresRewrap] = newtx --cache it
		end

		txt = dat.cache[buffer.RequiresRewrap]	--use cache or whatever we just wrapped
		buffer.RequiresRewrap = buffer.RequiresRewrap + 1 --add 1 so other text also rewraps and caches

	end

	local tx, ty = buffer.x, buffer.y + (dat.heights[buffer.curline] or buffer.curh)/2 - h/2

	for s in string.gmatch(txt, "(.-)\n") do 
	
		if shouldpaint then 

			surface.SetFont(shadowfont)
			surface.SetTextColor( ColorAlpha(Color(0, 0, 0), a) )

			for i=1, 2 do
				surface.SetTextPos(tx + i, ty + i )

				surface.DrawText(s)
				if addText then
					surface.DrawText(addText)
				end
			end

			surface.SetFont(font)
			surface.SetTextColor(ColorAlpha(col, a))
			surface.SetTextPos(tx, ty)

			surface.DrawText(s)
		else 
			surface.SetFont(font)
		end

		local tw, th = surface.GetTextSize(s)
		buffer.curh = math.max(th, buffer.curh) 	--pick whatever's taller: the text or whatever came before it (like emotes)

		buffer.x = chathud.x + (dat.namewid * chathud.WrapStyle)
		tx = buffer.x

		buffer.h = buffer.h + buffer.curh
		buffer.y = buffer.y + buffer.curh 			--add that 

		ty = buffer.y + (dat.heights[buffer.curline+1] or buffer.curh)/2 - h/2

		dat.heights[buffer.curline + 1] = buffer.curh
		buffer.curline = buffer.curline + 1

		buffer.curh = th 							--then reset

	end

	local lastword = txt:match("[^%c]+$")

	if lastword then

		if shouldpaint then 

			surface.SetFont(shadowfont)
			surface.SetTextColor( ColorAlpha(Color(0,0,0), a) )

			for i=1, 2 do
				surface.SetTextPos(tx + i, ty + i )
				surface.DrawText(lastword)
				if addText then
					surface.DrawText(addText)
				end
			end

			surface.SetFont(font)
			surface.SetTextColor(ColorAlpha(col, a))
			surface.SetTextPos(tx, ty)

			surface.DrawText(lastword)
		else 
			surface.SetFont(font)
		end

		local tw, th = surface.GetTextSize(lastword)

		buffer.x = buffer.x + tw
		buffer.curh = math.max(th, buffer.curh)
	end


	return h
end
chathud.DrawText = DrawText

local frstY = 0
local frstnum = 0

chathud.Filter = true 
chathud.FadeTime = 5
chathud.Bench = false 

function chathud:TagPanic()
	for k,v in pairs(self.History) do 
		v.TagPanic = true 
	end
end

function chathud:Draw()
	if #self.History < 1 then return end 

	local b 

	if chathud.Bench and #self.History > 1 then 
		b = bench("ChatHUD"):Open()
	end

	local x, y = self.x, self.y 
	local chh = chathud.CharH 

	local isfirst = true 

	if chathud.Filter then 
		render.PushFilterMag( TEXFILTER.ANISOTROPIC )
		render.PushFilterMin( TEXFILTER.ANISOTROPIC )
	end


	local ok, err = pcall(function()
		for i = #self.History, 1, -1 do
			local histnum = i 
			local dat = self.History[i]
		--for histnum,dat in SortedPairs(self.History, true) do

			local mult = -2500

			if CurTime() - dat.t > chathud.FadeTime then 
				mult = 120 
			end

			if y < (self.y-220) then --if the message is too high up, start erasing it
				mult = 500
			end

			dat.a = math.min(dat.a, 255) - FrameTime() * mult

			if dat.a <= 0 or y < 0 or (histnum < 20 and #self.History > 20) then --if history is more than 20 messages long or alpha is 0,
				table.remove(self.History, histnum)								 -- remove self
				continue
			end


			local tags = dat.tags

			local name = dat.name

			local text = dat.text
			

			local cols = {}
				
			if isfirst then 
				frstnum = histnum 
				frstY = 0  
			end
			--[[

				DrawQueue types:

				Text: {string = true, cont = "I am the content.", san = true/false} // san means if the string should be sanitized("#VAC_ConnectionRefusedDetail")
				Tag: {tag = true, args = {}, TagStart = func, ModifyBuffer = func, TagEnd = func}
				Color: {color = true, cont = Color}

			]]

			local drawq = {}
			local tagfuncs = {}
			if not dat.DrawQ then

				--[[
					Create a Draw Queue table, which will define & parse objects and the order they will be executed in.
					This includes tags, texts, colors and entities.
				]]

				for k,v in ipairs(dat.c) do 

					--Parse color in data:

					if IsColor(v) then 
						drawq[#drawq+1] = {color = true, cont = v}
						continue
					end

					--[[
						Parse string in data.
						Handles shitty language exploits("#VAC_ConnectionRefusedDetail")
					]]

					if isstring(v) then 

						if drawq[#drawq] and drawq[#drawq].string then 

							local str = v

							if drawq[#drawq].san then 

								str = v:sub(2)

								if language.GetPhrase(sub) == sub then 
									drawq[#drawq].san = nil 
								end 

							end

							drawq[#drawq].cont = drawq[#drawq].cont .. str

						else 

							local sub = string.sub(v, 2)
							local san = false

							if v[1] == "#" and language.GetPhrase(sub) ~= sub then
								san = true
							end

							if san then
								drawq[#drawq+1] = {cont = "#", string = true, san = true}
								drawq[#drawq+1] = {cont = sub, string = true, san = true}
							else 
								drawq[#drawq+1] = {cont = v, string = true}
							end
						
						end

						continue
					end

					
					if istable(v) then 

						--TODO: Tag add to draw 
						local func

						if v.ender then 
							local tagbuf = {} --for storing data within the tag's function

							func = function(buf)
								local tg = tagfuncs[v.ends]
								Run(tg.TagEnd, tg.tagbuf, tg.tagbuf, buf, Run(tg.getargs))
							end

							drawq[#drawq+1] = {name = v.tag, func = func, ender = v.ends}
						else 
							local chTag = chathud.TagTable[v.tag]
							if not chTag then printf("No such tag: %s", v.tag) continue end --???

							local function getargs()

								local args = {}
								v.errs = v.errs or {}

								for key, val in pairs(v.args) do 
									if v.errs[key] then continue end 
									if not chTag.args[key] then continue end 

									local arg = chTag.args[key]

									local default = arg.default
									local typ = arg.type

									local min, max = arg.min, arg.max

									if isfunction(val) then 
										local ok, ret = pcall(val)
										if not ok then printf("Tag error! %s", ret) v.errs[key] = true continue end 

										if not ret then 

											if not v.ComplainedAboutReturning and not arg.default then
												--print("Tag function must return a value! Defaulting to", val)
												--v.ComplainedAboutReturning = true
											end

											args[key] = default

										elseif ret then
											ret = chathud.TagTypes[typ](ret) or default

											if min then 
												ret = math.max(min, ret)
											end 

											if max then 
												ret = math.min(max, ret)
											end

											args[key] = ret 

										end

									else 
										val = chathud.TagTypes[typ](val) or default

										if min then 
											val = math.max(min, val)
										end 

										if max then 
											val = math.min(max, val)
										end

										args[key] = val 

									end
								end 

								return args
							end

							local tagbuf = {}

							func = function(buf, tagbuf)
								local args = getargs()

								Run(chTag.TagStart, tagbuf, buf, buf, args)
								Run(chTag.Draw, tagbuf, buf, buf, args)
								Run(chTag.ModifyBuffer, tagbuf, buf, buf, args)

							end 

							drawq[#drawq+1] = {
								name = v.tag,
								func = func,
								ModifyBuffer = chTag.ModifyBuffer,
								TagEnd = chTag.TagEnd,
								ends = v.ends,
								taginfo = v,
								getargs = getargs,
								tagbuf = tagbuf
							}

							tagfuncs[v.realkey] = {
								TagStart = chTag.TagStart,
								ModifyBuffer = chTag.ModifyBuffer,
								TagEnd = chTag.TagEnd,

								tagbuf = tagbuf
							}

						end
						--drawq[#drawq+1] = v
						continue
					end

					--functions are ignored

				end
				dat.DrawQ = drawq 
			end

			--[[
				Draw queue was created; now actually paint
			]]
			drawq = table.Copy(dat.DrawQ)

			local lastseg = 0
			

			local a = dat.a

			local buffer = {}

			local txh = dat.HOverride

			if not txh then
				local amtoflines = dat.newlines

				if not amtoflines then 
					amtoflines = 1 + select(2, string.gsub(dat.wrappedtxt, "%c", ""))
					dat.newlines = amtoflines
				end

				txh = amtoflines * chh 
			end

			

			buffer.y = y - txh
			buffer.x = x 
			buffer.h = 0 
			buffer.curh = chh 	--Current line H: useful for emotes and such
			buffer.w = 0
			buffer.hist = dat
			buffer.drawq = drawq --if we need to access draw queue from buffer
			buffer.curline = 1
			buffer.fgColor = dat.color

			if not dat.Evaluated then 	
				buffer.EvaluationPaint = true 
				buffer.fgColor = color_none
				dat.Evaluated = true 
				a = 0
			end

			buffer.a = a
			local buf = buffer


			local curH = 0

			for k,v in ipairs(drawq) do 

				if v.string then 
					DrawText(v.cont, buf, a)
					continue
				end

				if v.color and not buffer.EvaluationPaint then 
					buffer.fgColor = v.cont 
					continue
				end

				if v.func and not dat.TagPanic then
					buffer.fgColor = ColorAlpha(buffer.fgColor, a) 		--apply fade-out alpha to fgColor if they're drawing
					local x_before = buffer.x --if x changes due to tag drawing, we'll need to re-wrap text
					v.func(buffer, v.tagbuf)

					dat.heights[buffer.curline] = math.max(dat.heights[buffer.curline] or 0, buffer.curh)

					if buffer.x > chathud.W then 
						buffer.x = x + (dat.namewid * chathud.WrapStyle)
						buffer.y = buffer.y + buffer.curh
						curH = curH + buffer.curh
						
						dat.heights[buffer.curline] = buffer.curh
						buffer.curline = buffer.curline + 1

						buffer.curh = chh 
					end

					if buffer.x ~= x_before then --fuck
						buffer.RequiresRewrap = k 	--use tag number in draw queue as key for wordwrap cache
					end
				end
			end

			for k,v in ipairs(drawq) do 

				-- not an ender, doesn't end later, has a run-func and end-func

				if not v.ender and not v.ends and v.func and v.TagEnd and not dat.TagPanic then 
					v.TagEnd(v.tagbuf, v.tagbuf, buffer, v.getargs and v.getargs())
				end
			end

			dat.heights[buffer.curline] = buffer.curh
			curH = curH + buffer.curh + buffer.h	--add last line's H to current H

			dat.HOverride = curH

			y = y - dat.HOverride

		end

	end) --End PCall
	
	if chathud.Filter then 
		render.PopFilterMag()
		render.PopFilterMin()
	end

	if not ok then 
		ErrorNoHalt(("[ChatHUD] Error during rendering! %s\n"):format(err))
	end

	if chathud.Bench then 
		b:Close()
		print(b)
	end

end

-------------------------

local emoticon_cache = {}
local busy = {}

local function MakeCache(filename, emoticon)
	local mat = Material("data/" .. string.lower(filename), "noclamp smooth")
	filename=string.lower(filename)
	emoticon_cache[emoticon or string.StripExtension(string.GetFileFromFilename(filename))] = mat

end

local Mcche = {}

local function MaterialCache(a, b)
	a = a:lower()
	if Mcche[a] then return Mcche[a] end
	local m = Material(a, b)
	Mcche[a] = m
	return m
end

local dec
do
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	function dec(data)
		data = string.gsub(data, "[^" .. b .. "=]", "")
		return data:gsub(".", function(x)
			if x == "=" then return "" end
			local r, f = "", b:find(x) - 1
			for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
			return r
		end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
			if #x ~= 8 then return "" end
			local c = 0
			for i = 1,8 do c = c + (x:sub(i,i) == "1" and 2 ^ (8 - i) or 0) end
			return string.char(c)
		end)
	end
end

function chathud:GetSteamEmoticon(emoticon)
	emoticon = emoticon:gsub(":",""):Trim()
	if emoticon_cache[emoticon] then
		return emoticon_cache[emoticon]
	end
	if busy[emoticon] then
		return false
	end
	if file.Exists("emoticon_cache/" .. emoticon .. ".png", "DATA") then
		MakeCache("emoticon_cache/" .. emoticon .. ".png", emoticon)
	return emoticon_cache[emoticon] or false end
	Msg"ChatHUD " printf("Downloading emoticon " .. emoticon)
	http.Fetch("http://steamcommunity-a.akamaihd.net/economy/emoticonhover/:" .. emoticon .. ":	", function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				Msg"ChatHUD " printf("Server returned OK but empty response")
			return end
			Msg"ChatHUD " printf("Download OK")
			local whole = body
			body = body:match("src=\"data:image/png;base64,(.-)\"")
			if not body then Msg"ChatHUD " printf("ERROR! (no body) %s", whole) return end
			local b64 = body
			body = dec(body)
			if not body then Msg"ChatHUD " printf("ERROR! (not b64) %s", b64) return end
			file.Write("emoticon_cache/" .. emoticon .. ".png", body)
			MakeCache("emoticon_cache/" .. emoticon .. ".png", emoticon)
		else
			Msg"ChatHUD " printf("Download failure. Code: %s", code)
		end
	end)
	busy[emoticon] = true
	return false
end

function chathud:GetFFZEmoticon(emoticon)
	if emoticon_cache[emoticon] then
		return emoticon_cache[emoticon]
	end
	if busy[emoticon] then
		return false
	end
	if file.Exists("emoticon_cache/ffz/" .. emoticon, "DATA") then
		MakeCache("emoticon_cache/ffz/" .. emoticon, emoticon)
	return emoticon_cache[emoticon] or false end
	Msg"ChatHUD " print("Downloading FFZ emoticon https://cdn.frankerfacez.com/" .. emoticon)
	http.Fetch("https://cdn.frankerfacez.com/" .. emoticon, function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				Msg"ChatHUD " print("Server returned OK but empty response")
			return end
			Msg"ChatHUD " print("Download OK")
			file.Write("emoticon_cache/ffz/" .. string.lower(emoticon) , body)
			MakeCache("emoticon_cache/ffz/" .. emoticon , emoticon)
		else
			Msg"ChatHUD " print("Download failure. Code: " .. code)
		end
	end, function() print("why emote dead wtf????") end)
	busy[emoticon] = true
	return false
end

emote_json = emote_json
emote_data = emote_data

local failed = false 
local forced = false 

file.CreateDir("hdl/emotes")

local function ParseEmotes(js)
	emote_json = js
	emote_data = util.JSONToTable(emote_json)

	--[[
	collections:
		{	
			collection = "collection_name",
			collectionname = "Nice Collection Name",
			collectiondescription = "description" OR: {
				txt = "text" 	--mandatory
				col = {r, g, b}	--optional, can use gray by default
				font = "muhfont" --optional, can use OS18 by default
			}

			data = {
				1. names of animated emotes
				2. names of static emotes
			}
		},
		{
			...
		}
	]]

	local url = "https://vaati.net/Gachi/emotes/%s.png"

	for _, collection in pairs(emote_data) do
		local colname = collection.collection

		local coldesc = collection.collectiondescription or chathud.CollectionDescriptions[colname]
		local colnicename = collection.collectionname or chathud.CollectionNames[colname]

		Emotes.Collections[colname] = Emotes.Collections[colname] or Emotes.Collection(colname, coldesc)
		local col = Emotes.Collections[colname]

		col	:SetDescription(coldesc)
			:SetNiceName(colnicename)

		local data = collection.data

		for k,v in ipairs(data[1]) do 
			chathud.Emotes[v] = Emote(v, url:format(v))
									:SetAnimated(true)
									:AddToCollection("Animated")
									:AddToCollection(colname)
									:AddShortcut()
		end

		for k,v in ipairs(data[2]) do 
			chathud.Emotes[v] = Emote(v, url:format(v))
									:SetStatic(true)
									:AddToCollection("Static")
									:AddToCollection(colname)
									:AddShortcut()
		end

	end

	

	if forced then
		for k,v in pairs(chathud.Emotes) do 
			MoarPanelsMats[v:GetHDLPath()] = nil 
		end
		MsgC(Color(100, 220, 100), "[ChatHUD] Loaded emote data successfully! Also unloaded cached emotes.\n")
	elseif failed then 
		MsgC(Color(100, 220, 100), "[ChatHUD] Loaded cached emote data successfully!\n\n")
	else
		MsgC(Color(100, 220, 100), "[ChatHUD] Loaded emote data successfully!\n")
	end

	hook.Run("ChatHUDEmotesUpdated", Emotes.Collections)

	return emote_data
end

function UpdateEmotes()
	if failed and not file.Exists("emoticon_cache/emote_info.dat", "DATA") and not forced then 
		MsgC(Color(200, 50, 50), "[ChatHUD] Failed to update emote data and failed to load cached emote data, since it doesn't exist.\n") 
		return 
	end 

	if failed and file.Exists("emoticon_cache/emote_info.dat", "DATA") then 
		local data = file.Read("emoticon_cache/emote_info.dat", "DATA")
		ParseEmotes(js)
		MsgC(Color(220, 220, 10), "[ChatHUD] Loaded cached emote data. Keep in mind it may be outdated.\n")
		return
	end
	
	MsgC(Color(100, 220, 100), "\n[ChatHUD] Loading new emote data...\n")

	hdl.DownloadFile("https://vaati.net/Gachi/emotes/emotes_list.dat", "-emoticon_cache/emote_info.dat", function(fn, body)
		if body:find("404 -") then error("Emotes list 404'd!") return end
		ParseEmotes(body)

		forced = false	
		failed = false

	end, function() 
		failed = true 
		forced = false
		MsgC(Color(250, 55, 55), "\n[ChatHUD] Failed to get emote data!\n")

		if file.Exists("emoticon_cache/emote_info.dat", "DATA") then 
			local data = file.Read("emoticon_cache/emote_info.dat", "DATA")
			MsgC(Color(220, 220, 10), "[ChatHUD] We'll use cached emote data. Keep in mind, it may be outdated.\n")
			ParseEmotes(data)
		else
			MsgC(Color(200, 50, 50), "[ChatHUD] You don't have any cached emote data, so emotes will be pretty much disabled.\nYou can try doing emotes_update to re-attempt fetching data.\n") 
		end 


	end, true)
end

hook.Add("HUDPaint", "ChatHUDEmotes", function() 
	hook.Remove("HUDPaint", "ChatHUDEmotes")

	timer.Simple(5, UpdateEmotes) 
	chathud.CreateFFZShortcuts()
end)

function DeleteEmotes()
	if not emote_data then print("No emotes data to use!") return end 
	for k,v in pairs(chathud.Emotes) do 
		if not v:GetName() then continue end

		local name = ("hdl/emotes/%s"):format(v:GetName())
		

		if file.Exists(name .. ".png", "DATA") then 
			file.Delete(name .. ".png")
			file.Delete(name .. "_info.png")
		end

		MoarPanelsMats[v:GetHDLPath()] = nil
	end

end
concommand.Add("emotes_update", function() failed = false forced = true UpdateEmotes() end)
concommand.Add("emotes_clearemotes", function() DeleteEmotes() end)

function chathud:GetEmoticon(emoticon)
	if not chathud.Emotes then return false end 

	local emote = chathud.Emotes[emoticon]
	if not emote then return false end --emote doesnt exist 

	return emote:GetURL()
end

function chathud:GetTwitchEmoticon(emoticon)
	if emoticon_cache[emoticon] then
		return emoticon_cache[emoticon]
	end
	if busy[emoticon] then
		return false
	end
	if file.Exists("emoticon_cache/twitch/" .. emoticon .. ".png", "DATA") then
		MakeCache("emoticon_cache/twitch/" .. emoticon .. ".png", emoticon)
	return emoticon_cache[emoticon] or false end
	Msg"ChatHUD " print("Downloading emoticon " .. emoticon)
	http.Fetch("https://static-cdn.jtvnw.net/emoticons/v1/" .. emoticon .. "/3.0", function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				Msg"ChatHUD " print("Server returned OK but empty response")
			return end
			Msg"ChatHUD " print("Download OK")
			file.Write("emoticon_cache/twitch/" .. emoticon .. ".png", body)
			MakeCache("emoticon_cache/twitch/" .. emoticon .. ".png", emoticon)
		else
			Msg"ChatHUD " print("Download failure. Code: " .. code)
		end
	end)
	busy[emoticon] = true
	return false
end


-------------------------


ChatHUDEmoticonCache = emoticon_cache

return chathud
