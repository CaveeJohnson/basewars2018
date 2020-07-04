
--[[
	DeltaTextPiece: the object that holds the text and values for it.
]]


DeltaTextPiece = DeltaTextPiece or Object:extend()


local function NewFragment(text, col)
	return {
		Text = text,
		OffsetY = 0,
		OffsetX = 0,

		--AlignX = 0,
		--AlignY = 0,

		Alpha = 255,
		Color = col,
	}
end

local pmeta = DeltaTextPiece

function pmeta:Initialize(par, tx, font, key, rep)
	self.Text = tx
	self.Font = font
	self.Key = key

	self.DropStrength = 24	--Text replacement animation: height to which text drops FROM the text
	self.LiftStrength = 24	--Text replacement animation: height to which text drops TO the text

	self.Parent = par 		--DeltaTextMain

	self.Color = color_white:Copy()
	self.Alpha = 0

	local aninfo = {}
	self.Animation = aninfo

	self.Offsets = {X = 0, Y = 0}

	self.Offsets.XAppear = 0
	self.Offsets.YAppear = -36

	self.Offsets.XDisappear = 0
	self.Offsets.YDisappear = 24

	--[[
		Default animation data; if you don't provide length and delay
		to :CreateAnimation, this will be used
	]]

	aninfo.Length = 0.4
	aninfo.Ease = 0.3
	aninfo.Delay = 0
	aninfo.AnimationFunction = function(self, len, delay, ease, onend, think) return NewAnimation(len, delay, ease, onend) end

	self.Animations = {}	--Keeping track of existing animations for the ability to stop and run any animation, as long as you know the name

	--[[
		Text fragments.
		TODO: Make a text fragment into an object as well.
	]]

	self.Fragmented = false
	self.Fragments = {}

end

function pmeta:SetColor(col, g, b, a)
	self.Color:Set(col, g, b, a)
	return self
end

function pmeta:StopAnimation(name)

	if self.Animations[name] then
		self.Animations[name]:Stop()
		self.Animations[name] = nil
	end

end

ChainAccessor(pmeta, "DropStrength", "DropStrength")
ChainAccessor(pmeta, "LiftStrength", "LiftStrength")

--ChainAccessor(pmeta, "Text", "Text") --custom GetText implemented
ChainAccessor(pmeta, "Font", "Font")
ChainAccessor(pmeta, "Parent", "Parent")

function pmeta:CreateAnimation(name, think, cb, len, del)
	local anim = self.Animations.Alpha
	local aninfo = self.Animation

	if anim and not anim.Finished then return end

	if anim then
		anim:Swap(len or aninfo.Length, del or aninfo.Delay, aninfo.Ease)
		return
	end

	local anim, nooverride = aninfo.AnimationFunction(self, len or aninfo.Length, del or aninfo.Delay, aninfo.Ease, cb, think)

	if not nooverride then
		anim.Animate = think
	end

	self.Animations[name] = anim
end

--[[
	Returning anything in these functions will stop default animations from playing.
]]

function pmeta:AppearAnimation(fr)

end

function pmeta:DisappearAnimation(fr)

end

--[[
	This is called by the Appear and Disappear animation(which, in turn, is created by :Appear() and :Disappear())
	Don't override it; use :AppearAnimation() and :DisappearAnimation callbacks instead.
]]

function pmeta:AnimateAppearance(fr, a)
	if self:AppearAnimation(fr) then return end

	self.Alpha = fr * 255

	local xo, yo = self.Offsets.XAppear, -self:GetLiftStrength()

	self.Offsets.X = Lerp(fr, xo, 0)
	self.Offsets.Y = Lerp(fr, yo, 0)

	self:AppearAnimation(fr)
end

function pmeta:AnimateDisappearance(fr, a, x, y)
	if self:DisappearAnimation(fr) then return end

	self.Alpha = a - fr * a
	local xo, yo = self.Offsets.XDisappear, self:GetDropStrength()

	self.Offsets.X = Lerp(fr, x, xo)
	self.Offsets.Y = Lerp(fr, y, yo)

end


function pmeta:Disappear()
	self:StopAnimation("Appear")	--stop spazzing out

	self.Parent.Disappearing[self.Key] = self	-- set self for disappearing
	self.Disappearing = true

	local fromX, fromY = self.Offsets.X, self.Offsets.Y
	local a = self.Alpha

	self:CreateAnimation("Disappear", function(fr)
		self:AnimateDisappearance(fr, a, fromX, fromY)
	end, function()
		self.Parent.Disappearing[self.Key] = nil
		self.Disappeared = true
	end)

end

function pmeta:Appear()
	self:StopAnimation("Disappear")
	self:CreateAnimation("Appear", function(fr) self:AnimateAppearance(fr) end, function() end)

	self.Disappearing = false
	self.Disappeared = false
end

--[[
	:CreateAnimation uses a regular NewAnimation function by default.


	By setting your own animation you can change what kind of animation it uses. The AnimationFunction gets called with these arguments:
	self, Length, Delay, Ease, onend, think

	For example,
	piece:SetAnimationFunction(function(self, len, del, ease, onend, think)
		return Animations.InElastic(len, del, think, onend, ease), true
	end)

	Don't forget to return true as the second arg, otherwise the Animate function will be replaced.
]]

function pmeta:SetAnimationFunction(func)
	self.AnimationFunction = func
end


function pmeta:DrawText(x, y, col, tx, frag) --Available for override
	surface.SetTextPos(x, y)
	surface.SetTextColor(col.r, col.g, col.b, col.a)
	surface.DrawText(tx)
end

function pmeta:Paint(x, y)
	local parent = self.Parent

	self.Color.a = self.Alpha

	if self.Font ~= parent.LastFont then
		parent.LastFont = self.Font
		surface.SetFont(self.Font)
	end

	local curfont = self.Font

	if self.Fragmented then

		local x = x
		local lastw = 0
		local lasttx = ""

		local lerpnext = 1
		local lerpfrom = 0

		for k,v in pairs(self.Fragments) do
			local alignX = v.AlignX or parent.AlignX or 0
			alignX = alignX / 2
			if (not v.Font and curfont ~= self.Font) or (v.Font and v.Font ~= curfont) then
				surface.SetFont(v.Font or self.Font)
				curfont = v.Font
			end

			local tw, th = surface.GetTextSize(v.Text)


			if v.LerpNext then --if lerpnext is active then this fragment's width will be calculated by the next fragment
				lerpnext = Ease(v.LerpNext, v.Ease or 0.6)
				lerpfrom = tw*alignX
			else
				x = x - Lerp(lerpnext, lerpfrom, tw * alignX)
				lerpnext = 1
				lerpfrom = 0
			end

			lastw = v.Fading and tw

		end

		lastw = 0

		for k,v in pairs(self.Fragments) do
			if v.Text == "" then continue end

			--if fragment doesn't have a custom font, and current font is not default font (for example, from last frag)
			--or fragment has a custom font and it's not the same one as the current,
			--change it

			if (not v.Font and curfont ~= self.Font) or (v.Font and v.Font ~= curfont) then
				surface.SetFont(v.Font or self.Font)
				curfont = v.Font
			end

			local oldA = v.Color.a --we only want to change the alpha of the color temporarily, in case there's the same color being used for multiple fragments

			v.Color.a = math.min(v.Alpha or 255, self.Alpha, v.Color.a)

			local tw, th = surface.GetTextSize(v.Text)

			local alignX, alignY = v.AlignX or parent.AlignX or 0, v.AlignY or parent.AlignY or 0
			alignX, alignY = alignX / 2, alignY / 2

			--0 = left/top
			--1 = middle
			--2 = bottom/right

			--current x/y + fragment offset + parent offset + alignment

			local tX = x + v.OffsetX + self.Offsets.X -- alignX * tw
			local tY = y + v.OffsetY + self.Offsets.Y + alignY * th

			self:DrawText(tX, tY, v.Color, v.Text, v)

			if not v.RewindTextPos then

				if v.LerpFromLast then
					x = x + Lerp(Ease(v.LerpFromLast, v.Ease or 0.6), lastw or tw, tw)
				elseif not v.Fading then
					x = x + tw
				end

			end

			v.Color.a = oldA --reset the alpha to what it was

			lastw = v.Fading and tw
			lasttx = v.Text
		end

		return
	end

	local tw, th = surface.GetTextSize(self.Text)

	local alignX = self.AlignX or parent.AlignX or 0
	local alignY = self.AlignY or parent.AlignY or 0

	alignX, alignY = alignX / 2, alignY / 2

	local tX = x + self.Offsets.X - alignX * tw
	local tY = y + self.Offsets.Y + alignY * th

	self:DrawText(tX, tY, self.Color, self.Text)

end

function pmeta:GetText(ignore_fading)
	if not self.Fragmented then
		return self.Text
	else

		local s = ""

		for k,v in pairs(self.Fragments) do
			if ignore_fading and v.RewindTextPos then continue end
			s = s .. v.Text
		end

		return s
	end
end
function pmeta:OnAppear()	--for override

end

--[[
	When the text appears or disappears due to cycling,
	it uses these offsets to animate from/to.
]]

function pmeta:SetOffsetDisappear(x, y)
	self.Offsets.XDisappear = x
	self.Offsets.YDisappear = y
end

function pmeta:SetOffsetAppear(x, y)
	self.Offsets.XAppear = x
	self.Offsets.YAppear = y
end

--[[
	TODO: Return fragment object.
]]
function pmeta:FragmentText(from, to)

	if not self.Fragmented then

		self.Fragmented = true

		local t = {}

		if from then
			to = to or from --same char

			local t1, t2, t3 = self.Text:sub(0, from-1), self.Text:sub(from, to), self.Text:sub(to+1, #self.Text)

			t[1] = NewFragment(t1, self.Color) 
			t[1].ID = 1

			t[2] = NewFragment(t2, self.Color)
			t[2].ID = 2

			t[3] = NewFragment(t3, self.Color) 
			t[3].ID = 3

			self.Fragments = t
		else
			t[1] = NewFragment(self.Text, self.Color)
			t[1].ID = 1

			self.Fragments = t
		end



		return t
	else

		local len = 0

		if from < 0 then
			from = #self.Text + from
		end

		for k,v in pairs(self.Fragments) do

			local txt = v.Text

			len = len + #txt

			if from < len and to <= len then
				local frag = {
					Text = txt:sub(from - len + #txt + 1, to - len + #txt),
					OffsetX = 0,
					OffsetY = 0,
					Color = self.Color,
				}

				local newtext = from - len + #txt --new text for the old frag length

				if newtext == 0 then --they didn't leave any text; just remove the frag
					table.remove(self.Fragments, k)
				else
					v.Text = txt:sub(0, newtext)
				end

				local where = table.insert(self.Fragments, k+1, frag)
				frag.ID = where

				return where

			end
		end

	end
end

function pmeta:SetFragmentFont(ind, font)
	if not self.Fragmented then error("Can't set font for unfragmented text piece!") return end
	if not self.Fragments[ind] then error("No fragment #" .. ind .. "!") return end

	self.Fragments[ind].Font = font
end

function pmeta:AddFragment(text, num, anim, onend)	--adds a fragment on top
	local newfrag = NewFragment(text, self.Color)

	if anim then
		newfrag.Alpha = 0
	end

	if not self.Fragmented then
		self:FragmentText()
	end

	if anim then

		self:CreateAnimation("AddFragText" .. newfrag.Text, function(fr)
			newfrag.OffsetY = 24 - (fr * 24)
			newfrag.Alpha = fr*255
		end, function()
			if onend then onend() end
		end, nil, 0.1)

	end

	local where

	if num then
		where = table.insert(self.Fragments, num, newfrag)
	else
		where = table.insert(self.Fragments, newfrag)
	end
	newfrag.ID = where

	return where, newfrag
end

--[[
	Having fragmented text isn't really nice, especially since it doesn't need to be after a reset(probably...)
	Either way, just re-fragment it if you really need it.

	Gets called after a cycle reset.
]]

function pmeta:OnReset()

end

function pmeta:Reset()
	if self:OnReset() then return end

	if self.Fragmented then
		local tx = self.Text
		self:CollectFragments()
		self.Text = tx
	end
end

--[[
	The first argument is the number of a fragment you're going to be changing. Text MUST be fragmented for this!
	The second argument is the string you're going to be changing the fragment to.
	The third arg is optional and is a callback for when the text is inserted.

	Returns the new fragment which is inserted into the text object on success,
	or false if it failed(either because the fragment with this number doesn't exist or
	the text in the fragment is exactly the same as you're trying to change it to)
]]

function pmeta:ReplaceText(num, rep, onend, nolerp)

	local newfrag = NewFragment(rep, self.Color)

	newfrag.Alpha = 0
	newfrag.ID = num
	--newfrag.LerpFromLast = 0
	--newfrag.RewindTextPos = true

	local frag

	for k,v in pairs(self.Fragments) do --find the frag we'll be replacing
		if not v.Fading and v.ID == num then
			frag = v
			break
		end
	end

	if not frag then return false end

	if frag.Text == rep then return false end --its the same text
	frag.RewindTextPos = true
	frag.Fading = true

	frag.LerpNext = 0


	newfrag.AlignX = frag.AlignX
	newfrag.AlignY = frag.AlignY
	newfrag.Color = frag.Color

	self:StopAnimation(frag.ID .. "AddText" .. frag.Text)	--in case it existed

	local dropstr = self:GetDropStrength()

	local a = frag.Alpha

	self:CreateAnimation(num .. "SubText" .. frag.Text, function(fr)
		frag.OffsetY = fr * dropstr
		frag.Alpha = a - fr*a

		frag.LerpNext = fr
		newfrag.LerpFromLast = fr --doing it in the fading _out_ looks better than doing it on fading _in_

	end, function()

		local found = false

		for k,v in pairs(self.Fragments) do 	--this is done like this because the keys might change by the time the animation finishes
			if v == frag then
				table.remove(self.Fragments, k)
				return
			end
		end

		newfrag.Finished = true
		--newfrag.LerpFromLast = 0
	end)

	local appstr = self:GetLiftStrength()

	self:CreateAnimation(num .. "AddText" .. newfrag.Text, function(fr)
		frag.RewindTextPos = true	--to prevent the new fragment's X pos being impacted by the one we're removing.
		newfrag.RewindTextPos = false


		newfrag.OffsetY = appstr - (fr * appstr)
		newfrag.Alpha = fr*255

	end,

	function()
		if onend then onend() end
	end,
	nil,
	0.1)	--delay

	local inswhere = num+1

	for k,v in pairs(self.Fragments) do 	--find latest fragment with this ID which is fading, to put the new frag after it
		if v.Fading and v.ID == num then 	--this is done for text X rewinding to work properly(ORDERRR!)
			inswhere = k+1
		end
	end

	local where = table.insert(self.Fragments, inswhere, newfrag)

	return where, newfrag
end

--[[
	Re-collects all fragments, and if an argument isn't provided,
	unites all text fragments into its' .Text member.

	Removes fragmentation entirely.
]]
function pmeta:CollectFragments(keeptxt)

	if not keeptxt then
		local s = ""

		for k,v in pairs(self.Fragments) do
			s = s .. v.Text
		end

		self.Text = s
	end

	self.Fragmented = false

	table.Empty(self.Fragments)
end