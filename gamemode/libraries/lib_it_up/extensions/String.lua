--- === String === ---

function string.Random(len)
	local rnd = ""
	for i=1, (len or math.random(6,11)) do
		local c = math.random(65,116)
		if c >= 91 and c <= 96 then
			c = c + 6
		end
		rnd = rnd .. string.char(c)
	end
	return rnd
end



function ValidString(v)
	return isstring(v) and v ~= ""
end

local cachetbl = {}
local cachenums = {}


function string.WordWrap(name, w, font)	-- this should be deprecated cuz it sucks

	surface.SetFont(font or "RL18")

	local txw, height = surface.GetTextSize(name)

	if istable(w) then

		if txw < table.GetWinningKey(w) then return name, {txw}, height end --no actions necessary
	else
		if txw < w then return name, {txw}, height end --no actions necessary
	end

	--check cache with width as table

	if cachetbl[name] and istable(w) then
		local cch = cachetbl[name]

		local rettxt, retwids = false, false

		for final, tbl in pairs(cch) do

			if tbl.w then
				local ineq = false
				for k,wid in pairs(tbl.w) do
					if wid ~= w[k] then ineq = true break end
				end
				if not ineq then rettxt = final retwids = tbl.widths break end
			end

		end

		if rettxt then
			return rettxt, retwids, height
		end

	end

	if cachenums[w] and cachenums[w][name] then
		return cachenums[w][name].text, cachenums[w][name].widths, height
	end

	local utflen, kk = utf8.len(name)
	local len = 0
	if kk then len = utflen else len = #name end

	local text = ""
	local ctxw = 0	--current text width
	local curline = 1

	local widths = {}

	local iter = utf8.codes(name)

	for i, char in iter do

		local notalot = utflen - i <= 4

		if char == 10 then --newline
			text = text .. "\n"
			widths[#widths + 1] = ctxw
			ctxw = 0
			curline = curline + 1
			continue
		end

		local char = utf8.char(char)
		text = text .. char
		ctxw = ctxw + surface.GetTextSize(char)

		local ww = w 	--current line's required width
		if istable(w) then ww = w[curline] or w[#w] or 600 end

		if ctxw > ww*0.8 then --attempt \n'ing nicely

			if char==" " and not notalot then
				text = text .. "\n"	--hijack the space
				widths[#widths+1] = ctxw
				ctxw = 0
				curline = curline + 1
				continue
			end

		end

		if ctxw > ww*0.8 and utflen - i >= 2 then  --wrap asap

			for i2 = 0, 2 do
				if name[i+i2] == " " then continue end --disregard, it can still be done nicely
			end

			text = text .. "-\n"
			widths[#widths+1] = ctxw
			ctxw = 0
			curline = curline + 1

		end

		if ctxw > ww*0.95 then --you _HAVE_ to wrap it
			text = text .. "-\n"
			widths[#widths+1] = ctxw
			ctxw = 0
			curline = curline + 1
		end

	end

	if istable(w) then
		cachetbl[name] = cachetbl[name] or {}
		local cch = cachetbl[name]
		widths[#widths + 1] = ctxw
		cch[text] = {w = w, widths = widths}
	end

	if isnumber(w) then
		cachenums[w] = cachenums[w] or {}
		local cch = cachenums[w]
		widths[#widths + 1] = ctxw
		cch[name] = {text = text, widths = widths}
	end

	return text, widths, height
end


local function WrapByLetters(txt, curwid, fullwid, wids, line)
	local ret = ""

	local line = line or 0
	local wrapped = false

	for i, code in utf8.codes(txt) do
		local char = utf8.char(code)
		local charw = (surface.GetTextSize(char))

		if charw > curwid then

			local shoulddash = ret:sub(#ret):match("[^%s%c]") --not a space or control char; need to dash it
			ret = ret .. (shoulddash and "-" or "") .. "\n" .. char

			if wids then
				fullwid = wids[line + 1] or wids[#wids]
				line = line + 1
			end

			curwid = fullwid - charw
			wrapped = true
		else
			ret = ret .. char
			curwid = curwid - charw
		end
	end

	return ret, (fullwid - curwid), line, wrapped
end

local function WrapWord(word, curwid, fullwid, widtbl, line)

	local tw, th = surface.GetTextSize(word)
	local ret = ""

	line = line or 1
	fullwid = fullwid or widtbl[line] or widtbl[#widtbl]

	local wrapped = false --did word wrap?

	if curwid + tw > fullwid - 8 then --have to wrap

		local too_wide = tw > fullwid * 0.65 --very wide word; wrap by letters if true

		if not too_wide then

			ret = ret .. "\n" .. word
			curwid = tw
			wrapped = true

			line = line + 1
		else
			local newtx, newwid, lines, didwrap = WrapByLetters(word, fullwid - curwid, fullwid, widtbl, line)
			--if widtbl was provided, WrapByLetters'll figure out what to do

			--lines is the amount of times the word has wrapped

			ret = ret .. newtx
			curwid = newwid
			line = lines
			wrapped = wrapped or didwrap
		end
	else
		ret = ret .. word
		curwid = curwid + tw
	end

	return ret, curwid, line, wrapped
end

function string.WordWrap2(txt, wid, font)
	if font then surface.SetFont(font) end

	local wrapped = false

	if istable(wid) then

		local ret = ""

		local curwid = 0
		local line = 1

		for word in string.gmatch(txt, "(.-)%s") do

			local r2, w2, lines, didwrap = WrapWord(word .. " ", curwid, nil, wid, line)

			ret = ret .. r2
			curwid = w2

			line = lines
			wrapped = wrapped or didwrap
		end

		local lastword = txt:match("[^%s]+$")

		if lastword then
			local r2, w2, _, didwrap = WrapWord(lastword, curwid, nil, wid, line)

			ret = ret .. r2
			curwid = w2
			wrapped = wrapped or didwrap

		end

		return ret, curwid, wrapped
	else

		local ret = ""

		local needwid = wid
		local curwid = 0

		for word in string.gmatch(txt, "(.-)%s") do
			local r2, w2, didwrap = WrapWord(word .. " ", curwid, needwid)
			ret = ret .. r2
			curwid = w2
			wrapped = wrapped or didwrap
		end

		local lastword = txt:match("[^%s]+$")

		if lastword then
			local r2, w2, didwrap = WrapWord(lastword, curwid, needwid)

			ret = ret .. r2
			curwid = w2
			wrapped = wrapped or didwrap
		end

		return ret, curwid, wrapped

	end

end

--[[function string.GetBetween(str, tag, num) --wtf is this
	local pat = "%b" .. tag
	local pat2 = tag[1] .. "(.+)" .. tag[2]

	if num then

		for i=1, 10000 do

			local match = str:match(pat)
			if not match then return end

			if match then
				if i ~= num then
					str = str:gsub(match:PatternSafe(), "")
				else
					return match:match(pat2)
				end
			end
		end

	else
		return str:match(pat):match(pat2)
	end
end]]

function string.TimeParse(time) --this is broken i think

	local h = math.floor(time / 3600)
	local m = math.floor(time/60) - h*60
	local s = time - h*3600 - m*60

	return string.format("%.2d:%.2d:%.2d", h, m, s)

end

function string.YeetNewlines(str, also_spaces)
	str = str:gsub("\n", " ")
	str = str:gsub("\r", "")
	str = str:gsub("\t", " ")

	if also_spaces then
		str = str:gsub("  ", " ")
		str = str:gsub("  ", " ")
		str = str:gsub("  ", " ")
	end
	return str
end

local vowels = {
	["a"] = true,
	["e"] = true,
	["i"] = true,
	["o"] = true,
	["u"] = true,
}

function string.IsVowel(char)
	return (not not vowels[string.lower(char:sub(1, 1))])
end

--[[
	Takes a string and a table of shortcuts: for every shortcut ("string :shortcut:"),
	attempts to replace it with table[shortcut]
]]
function string.Shortcut(str, shcuts)

	for s1 in string.gmatch(str, ":(.-):") do --shortcuts, then tags
		if shcuts[s1] then
			str = str:gsub((":%s:"):format(s1), shcuts[s1], 1)
		end
	end

	return str
end

local tagptrn = "<([/%w]+)=?([^>]*)>"
local tagendptrn = "/(.+)"
local expptrn = "(%b[]),?" 		--pattern that captures shit in []s and defines whether the arg is an expression
local valptrn = "%s*(.-)%s*,"	--match arg from a tag without spaces and commas
local lastarg = "([^,%s?]+)$"	--match last arg in a tag

local utflen = function(s)
	return (utf8.len(s:sub(#s, #s-1)) == 1 and #(s:sub(#s, #s-1) == 2)) and 2 or 1
end


--hoooolyyyyyy shit
function string.ParseTags(str, shortcuts, tagtable)

	local tags = {} --this contains strings (regular text) and tables (tags)

	local prevtagwhere
	local env 		--envinroment for expressions, it's shared for one message

	for s1 in string.gmatch(str, ":(.-):") do --shortcuts, then tags

		if shortcuts[s1] then
			str = str:gsub((":%s:"):format(s1), shortcuts[s1], 1)
		end

	end

	for tag, argsstr in string.gmatch( str, tagptrn ) do
		local OGargsstr = argsstr --argsstr will be changed

		local chTag = tagtable[tag]

		local starts = str:find(tag, prevtagwhere or 1, true)
		if starts then starts = starts - 1 end --add the "<" which doesn't get matched

		if not chTag then

			local isend = tag:match(tagendptrn)
			if not isend or not tagtable[isend] then print("no such tag to end:", tag, isend) continue end

			for k,v in ipairs(table.Reverse(tags)) do
				if not istable(v) then continue end

				if v.Tag == isend and not v.ends and not v.ender then
					--create an ender tag, which will disable tag at k
					v.ends = starts

					str = str:gsub(tag:PatternSafe(), "", 1)

					local key = #tags + 1

					if prevtagwhere then
						tags[key] = str:sub(prevtagwhere, starts + utflen(str) -2)	--if ender, put text first ender later
						key = key + 1
					end

					tags[key] = v:GetEnder()
					--[[tags[key] = {
						tag = isend,
						ender = true,
						ends = v.realkey,	--ends tag with key v.realkey
						realkey = key
					}]]

					prevtagwhere = starts + 3 --+3 for <>

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

				local _, ends = argsstr:find(arg, lastargpos, true)
				lastargpos = starts + 1

				local num = #args + 1
				if not chTag.args[num] then break end --more args than the tag takes: ignore eet

			  --  argst[#argst + 1] = arg

				argsstr = argsstr:sub(0, starts-1) .. "-" .. argsstr:sub(ends + 1) --"-" allows you to ignore a var and let it be set to a default value; unless it already has a value...
				arg = arg:sub(2, -2) --get rid of []

				local func, newenv = chathud.CompileExpression(arg, info, special, env)				-- like this handy expression we just compiled!
				env = env or newenv

				if isstring(func) then
					print("Expression error: " .. func)
					continue
				end

				args[#args + 1] = func
			end

			local i = 0

			for arg in argsstr:gmatch(valptrn) do

				i = i + 1
				if arg == "-" then continue end --this also increments i, basically offsetting arg by +1
				if not chTag.args[i] then break end

				local typ = chTag.args[i].type
				if not chathud.TagTypes[typ] then print("Unknown argument type! ", typ) break end

				local ret = chathud.TagTypes[typ](arg)

				if ret then table.insert(args, i, ret) end --if conversion to type succeeded

			end

			local lastargstr = argsstr:match(lastarg)

			if lastargstr and lastargstr ~= "-" then
				args[i + 1] = lastargstr
			end

		end

		local key = #tags + 1

		if prevtagwhere then
			tags[key] = str:sub(prevtagwhere, starts - 1)
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

		local TagObj = chathud.Tags(tag, unpack(args))
		TagObj.realkey = key
		TagObj.starts = starts

		tags[key] = TagObj--[[{
			tag = tag,
			args = args,
			starts = starts,
			realkey = key --for ender to keep track due to table reversing
		}]]

		prevtagwhere = starts

		local tosub = "<" .. tag .. ((OGargsstr and "=" .. OGargsstr) or "") .. ">"
		tosub = tosub:PatternSafe()
		str = str:gsub(tosub, "", 1) --remove the tag we just parsed

	end

	tags[#tags + 1] = string.sub(str, prevtagwhere or 1, #str)

	return str, tags
end

function printf(s, ...)
	print(s:format(...))
end

function errorf(s, ...)
	return error(s:format(...))
end

