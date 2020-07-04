setfenv(1, _G)
MarkupTags = Class:callable()
local tag = MarkupTags
tag.IsTag = true

--[[
	Created by

	MarkupTags("TagName", args)

	args can be functions or numbers or anything else, as long as the tag supports it

	for example,
		local s = function() return 60 + math.abs(math.sin(CurTime() * 5) * 40) end
		MarkupTags("color", 200, s, s)
]]
MarkupTagArgTypes = {
	["number"] = tonumber,
	["string"] = tostring,
}
function IsTag(obj)
	return istable(obj) and obj.IsTag
end

--make name "true" to ignore existence check
function tag:Initialize(name, ...)
	if not MarkupTagTable[name] and name ~= true then
		errorf("Attempt to create non-existant tag! \"%s\"", name)
	end

	local tag = MarkupTagTable[name]

	local args = {...}

	self.Name = name
	self.Tag = name --alias

	self.BaseTag = tag
	self.Args = {}
	self.TagBuffer = {}
	self.Errs = {}

	local targs = self.Args

	for k, arg in ipairs(args) do
		if not tag.args[k] then break end
		local btarg = tag.args[k]

		if isfunction(arg) then
			targs[#targs + 1] = arg
		else

			local typ = btarg.type

			local ret = MarkupTagArgTypes[typ](arg) or btarg.default

			local min = btarg.min
			local max = btarg.max

			if min then
				ret = math.max(min, ret)
			end

			if max then
				ret = math.min(max, ret)
			end

			targs[k] = ret
		end

	end

	if tag then
		for i=#args + 1, #tag.args do
			self.Args[i] = tag.args[i].default
		end
	end
end

local function eval_exp(self, key, f, ...)

	local ok, ret = pcall(f, ...)
	if not ok then print("Tag error!", ret) self.Errs[key] = true end

	local arg = self.BaseTag.args[key]
	local default, min, max = arg.default, arg.min, arg.max
	local typ = arg.type

	if not ret then
		return default

	elseif ret then
		ret = MarkupTagArgTypes[typ](ret) or default

		if min then
			ret = math.max(min, ret)
		end

		if max then
			ret = math.min(max, ret)
		end

		return ret
	end

end

function tag:Run(buffer, ...)

	local args = {}

	for k, arg in pairs(self.Args) do
		if isfunction(arg) then
			args[#args + 1] = eval_exp(self, k, arg, ...)
		else
			args[#args + 1] = arg
		end
	end

	if self.BaseTag.TagStart then
		self.BaseTag.TagStart(self.TagBuffer, buffer, args)
	end

	if self.BaseTag.Draw then
		self.BaseTag.Draw(self.TagBuffer, buffer, args)
	end

	if self.BaseTag.ModifyBuffer then
		self.BaseTag.ModifyBuffer(self.TagBuffer, buffer, args)
	end

	self.Ended = false
end

function tag:End(buffer)
	local args = {}

	for k,v in pairs(self.Args) do
		if isfunction(arg) then
			args[#args + 1] = eval_exp(self, k, arg)
		else
			args[#args + 1] = v
		end
	end

	if self.BaseTag.TagEnd then
		self.BaseTag.TagEnd(self.TagBuffer, buffer, buffer, args)
	end

	self.Ended = true
end

function tag:GetEnder()
	if self.ender then return false end

	local ender = MarkupTags(true)
	ender.ender = true
	ender.Run = function(_, buf) self:End(buf) end
	ender.End = function(_, buf) self:End(buf) end
	return ender

end

ChainAccessor(tag, "BaseTag", "BaseTag")

MarkupBaseTag = MarkupBaseTag or Class:callable()
local bt = MarkupBaseTag

local blankfunc = function() end

function bt:Initialize(name)
	assert(name, "Base tag must be constucted with a name!")

	self.Name = name
	self.args = {}

	self.TagStart = blankfunc
	self.ModifyBuffer = blankfunc
	self.Draw = blankfunc
	self.TagEnd = blankfunc


	MarkupTagTable[name] = self
end

function bt:AddArg(type, default, min, max)
	self.args[#self.args + 1] = {type = type, min = min, max = max, default = default}
	return self
end

ChainAccessor(bt, "TagStart", "Start")
ChainAccessor(bt, "ModifyBuffer", "ModifyBuffer")
ChainAccessor(bt, "TagEnd", "End")
ChainAccessor(bt, "Draw", "Draw")

ChainAccessor(bt, "NoRegularUse", "Special")



MarkupBuffer = Emitter:callable()
local buf = MarkupBuffer

buf._wrapCache = WeakTable() -- this is shared between all buffers
							 -- muh ram!
--[[

_wrapCache = {
	[font] = {										 string			number 	   number,   bool
		[beginX .. ":" .. width .. ":" .. text] = {wrappedtxt, lastline_width, txline, wrapped}
	}
}

]]

ChainAccessor(buf, "TextColor", "Color")
ChainAccessor(buf, "TextColor", "TextColor")

ChainAccessor(buf, "BackgroundColor", "TextColor")

local fontheights = {}

local t = {}
local tlen = 0
for i=32, 127 do
	tlen = tlen + 1
	t[tlen] = i
end

local alphabet = string.char(unpack(t)) --wtf

function buf:Initialize(w)
	self.x = 0
	self.y = 0

	self.width = w
end

function buf:SetFont(font)
	if font == self.Font then return end

	surface.SetFont(font)
	local h = fontheights[font] or select(2, surface.GetTextSize(alphabet)) --get da highest char
	self:SetTextHeight(h)
	self.Font = font
	return self
end

function buf:GetFont()
	return self.Font
end

ChainAccessor(buf, "TextHeight", "TextHeight")

function buf:Reset()
	self:SetPos(0, 0)
	self:Emit("Reset")
end

function buf:GetPos()
	return self.x, self.y
end

function buf:SetPos(x, y)
	self.x = x or self.x
	self.y = y or self.y
	return self
end

function buf:Offset(x, y)
	self.x = self.x + (x or 0)
	self.y = self.y + (y or 0)
end

function buf:AllocateSpace(w, h)
	if self.x + w > self.width then
		self.x = 0
		self.y = self.y + h/2
	end
end

function buf:WrapText(tx, width, font)
	if not self:GetTextHeight() then
		error("please :SetFont() on the buffer before wrapping text")
	end

	font = font or self:GetFont()

	local fontcache = self._wrapCache[font] or {}
	self._wrapCache[font] = fontcache

	local key = self.x .. ":" .. width .. ":" .. tx
	local txcache = fontcache[key]

	if txcache then
		local tw, th = txcache[2], txcache[3] * self:GetTextHeight()

		local offX = 0

		if txcache[4] then
			self:SetPos(tw)
		else
			offX = tw
		end

		self:Offset(offX, th)
		return txcache[1], tw, th
	else

		local wrapped, cur_wid, didwrap = string.WordWrap2(tx, {width - self.x, width}, font)

		local offX = 0

		if not didwrap then 				--if we didn't wrap text, then we should offset textW from current X (cuz cur_wid doesn't current X already)
			offX = cur_wid
		else 							--otherwise we got onto a new line, so we don't have an offset there; just setpos
			self:SetPos(cur_wid)
		end

		local _, lines = wrapped:gsub("\n", "")
		local th = lines * self:GetTextHeight()
		self:Offset(offX, th)

		fontcache[key] = {wrapped, cur_wid, lines, didwrap}
		return wrapped, cur_wid, th
	end

end

MarkupTagTable = MarkupTagTable or {}

local tr = MarkupBaseTag("translate")

tr:AddArg("number", 0, -400, 400)	--X
tr:AddArg("number", 0, -400, 400)	--Y
local mtrx = Matrix()	--empty matrix
local mtrx2 = Matrix()  --actually used matrix

tr:SetStart(function(tag, buf, args)
	local vec = Vector(args[1], args[2])
	mtrx2:Set(mtrx)
	mtrx2:Translate(vec)
	cam.PushModelMatrix(mtrx2)
end)

tr:SetEnd(function(tag, buf, args)
	cam.PopModelMatrix(mtrx2)
end)



local hsv = MarkupBaseTag("hsv")

hsv:AddArg("number", 0)	--H
hsv:AddArg("number", 1)	--S
hsv:AddArg("number", 1)	--V

local COLOR = FindMetaTable("Color") --RUBAAAAAT!!!

hsv:SetStart(function(tag, buf, args)
	local cur = buf:GetTextColor()
	tag.curColor = cur
	local col = HSVToColor(args[1] % 360, args[2], args[3])
	setmetatable(col, COLOR)
	buf:SetTextColor(col)
end)

hsv:SetEnd(function(tag, buf, args)
	buf:SetTextColor(tag.curColor)
end)

local col = MarkupBaseTag("color")

col:AddArg("number", 255)	--R
col:AddArg("number", 255)	--G
col:AddArg("number", 255)	--B

col:SetStart(function(tag, buf, args)
	local cur = buf:GetTextColor()

	tag.curColor = tag.curColor or {}
	tag.curColor[1], tag.curColor[2], tag.curColor[3] = cur:Unpack()

	cur:Set(args[1], args[2], args[3])
end)

col:SetEnd(function(tag, buf, args)
	buf:GetTextColor():Set(tag.curColor[1], tag.curColor[2], tag.curColor[3])
end)

local chtr = MarkupBaseTag("chartranslate")

chtr:AddArg("number", 0)	--x
chtr:AddArg("number", 0)	--y

chtr:SetStart(function(tag, buf, args)
	local vec = Vector(args[1], args[2])

	mtrx2:Set(mtrx)
	mtrx2:Translate(vec)
	cam.PushModelMatrix(mtrx2)
end)

chtr:SetEnd(function(tag, buf, args)
	cam.PopModelMatrix(mtrx2)
end)

chtr.ExecutePerChar = true

local emote = MarkupBaseTag("emote")

emote:AddArg("string", "__error") --emote name
emote:AddArg("number", 32) --width
emote:AddArg("number", 32) --height

emote:SetDraw(function(tag, buf, args)

	local emote = chathud.Emotes[args[1]]
	if not emote then return end

	buf:AllocateSpace(args[2], args[3])

	surface.SetDrawColor(255, 255, 255)
	local x, y = buf:GetPos()
	emote:Paint(x, y, args[2], args[3])
end)