if not Emitter then include('emitter.lua') end
Animatable = Emitter:callable()
AnimatableObjects = AnimatableObjects or {}
local objs = AnimatableObjects

AnimMeta = Emitter:extend()

if SERVER then return end --bruh

hook.Add("Think", "AnimatableThink", function()
	for k,v in ipairs(objs) do
		v:AnimationThink()
	end
end)

function AnimMeta:Stop()
	self.Parent.m_AnimList[self.Key] = nil
	self:Emit("Stop")
	self:Emit("End")
end

function AnimMeta:SetSwappable(b)
	self.Swappable = (b==nil and true) or b
	return self
end

function AnimMeta:Swap(length, delay, ease, callback)

	self.StartTime = delay + SysTime()
	self.EndTime = delay + length + SysTime()
	self.Ease = ease
	self.OnEnd = callback

	self.Ended = false

	self:Emit("Swap")

	return self
end

function Animatable:Initialize(auto_think)
	self.__Animations = {}
	self.m_AnimList = {}

	if auto_think ~= false then
		objs[#objs + 1] = self
	end

end

function Animatable:AnimationThink()
	local systime = SysTime()

	for k, anim in pairs( self.m_AnimList ) do
		if anim.Ended then continue end

		if ( systime >= anim.StartTime ) then

			local Fraction = math.TimeFraction( anim.StartTime, anim.EndTime, systime )
			Fraction = math.Clamp( Fraction, 0, 1 )

			if ( anim.Think ) then

				local Frac = Fraction ^ anim.Ease

				-- Ease of -1 == ease in out
				if ( anim.Ease < 0 ) then
					Frac = Fraction ^ ( 1.0 - ( ( Fraction - 0.5 ) ) )
				elseif ( anim.Ease > 0 && anim.Ease < 1 ) then
					Frac = 1 - ( ( 1 - Fraction ) ^ ( 1 / anim.Ease ) )
				end

				anim:Think( self, Frac )
				anim:Emit("Think", Frac)
			end

			if ( Fraction == 1 ) then

				if not anim.Ended then
					if anim.OnEnd then anim:OnEnd( self ) end
					anim:Emit("End")
					anim.Ended = true
				end

				if anim.Swappable then continue end

				self.m_AnimList[k] = nil
				anim.Valid = false
				anim.Key = 0	--this animation isn't "valid" anymore; zero out the key so stopping the animation actually does nothing
			end

		end

	end
end

function Animatable:NewAnimation( length, delay, ease, callback )

	if ( delay == nil ) then delay = 0 end
	if ( ease == nil ) then ease = -1 end

	delay = delay + SysTime()

	local anim = AnimMeta:new()

	table.Merge(anim, {
		EndTime = delay + length,
		StartTime = delay,
		Ease = ease,
		OnEnd = callback,
		Parent = self,
	})

	if ( self.m_AnimList == nil ) then self.m_AnimList = {} end

	local key = table.insert( self.m_AnimList, anim )
	anim.Key = key

	return anim

end

--everything below has been pretty much lifted from panellib meta.lua


local format = string.format

local function hex(t)
	return format("%p", t)
end

function Animatable:Lerp(key, val, dur, del, ease, forceswap)
	local anims = self.__Animations or {}
	self.__Animations = anims

	local anim
	local from = self[key] or 0

	if self[key] == val then return false, false end

	if anims[key] then
		anim = anims[key]
		if anim.ToVal == val and not forceswap then return anim, false end --don't re-create animation if we're already lerping to that anyways

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else
		anim = self:NewAnimation(dur, del, ease)

		anim:SetSwappable(true)

		anim.ToVal = val
		anims[key] = anim
	end

	anim:On("End", "RemoveAnim", function()
		anims[key] = nil
	end)

	anim.Think = function(anim, self, fr)
		self[key] = Lerp(fr, from, val)
	end

	return anim, true
end

Animatable.To = Animatable.Lerp

function Animatable:MemberLerp(tbl, key, val, dur, del, ease, forceswap)
	local anims = self.__Animations or {}
	self.__Animations = anims

	local as_str = hex(tbl)

	local anim = anims[key .. as_str]
	local from = tbl[key] or 0

	if tbl[key] == val then return false, false end

	if anim then
		if anim.ToVal == val and not forceswap then return anim, false end

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else

		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
		anim.FromTable = tbl
		anims[key .. as_str] = anim
	end

	anim:On("End", "RemoveAnim", function()
		anims[key] = nil
	end)

	anim.Think = function(anim, self, fr)
		tbl[key] = Lerp(fr, from, val)
	end

	return anim, true
end

Animatable.LerpMember = Animatable.MemberLerp

--CW has its' own LerpColor which seems to work differently from this
--src will be the source color from which the lerp starts
local function LerpColor(frac, col1, col2, src)

	col1.r = Lerp(frac, src.r, col2.r)
	col1.g = Lerp(frac, src.g, col2.g)
	col1.b = Lerp(frac, src.b, col2.b)

	if src.a ~= col2.a then
		col1.a = Lerp(frac, src.a, col2.a)
	end

end

local function LerpColorFrom(frac, col1, col2, col3) --the difference is that the result is written into col3 instead, acting like classic lerp
	col3.r = Lerp(frac, col1.r, col2.r)
	col3.g = Lerp(frac, col1.g, col2.g)
	col3.b = Lerp(frac, col1.b, col2.b)

	if col1.a ~= col2.a then
		col3.a = Lerp(frac, col1.a, col2.a)
	end
end

--[[
	Because colors are tables, instead of giving a key you can give LerpColor a color as the first arg,
	so the color structure will be changed instead
]]
function Animatable:LerpColor(key, val, dur, del, ease, forceswap)
	local anims = self.__Animations or {}
	self.__Animations = anims

	local anim

	local iscol = IsColor(key)
	local from = (iscol and key) or self[key]
	if not from then errorf("Didn't find color when provided %s (%s)", key, type(key)) end
	if from == val then return end

	if anims[key] then
		anim = anims[key]
		if anim.ToVal == val and not forceswap then return end --don't re-create animation if we're already lerping to that anyways

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else
		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
		anims[key] = anim
	end

	local newfrom = from:Copy()

	anim:On("End", "RemoveAnim", function()
		anims[key] = nil
	end)

	anim.Think = function(anim, self, fr)
		if iscol then
			LerpColorFrom(fr, newfrom, val, from)
		else
			self[key] = (IsColor(self[key]) and self[key]) or from
			LerpColor(fr, from, val, newfrom)
		end
	end

end