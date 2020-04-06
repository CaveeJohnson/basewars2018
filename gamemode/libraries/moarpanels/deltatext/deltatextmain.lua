

--[[
	DeltaText: The object that holds all of the deltatext objects and calls appropriate functions.
]]


DeltaText = DeltaText or Object:extend() 	--allow autorefresh of existing objects' metas
local dmeta = DeltaText.Meta 

DeltaText.__call = DeltaText.new 


function dmeta:Initialize()
	self.Elements = {}
	self.Active = {}

	self.Disappearing = {}

	self.Timings = {}
	self.LastTiming = 0

	self.LastActive = 0		--last active element
	self.LastActiveText = 0 --last active text element
	self.Alignment = 0

	self.LastAddedText = 0

	self.ActiveWhen = CurTime()

	self.Font = "SDZ20"
end

ChainAccessor(dmeta, "Font", "Font")

function dmeta:AddText(tx, rep, timing)

	local key = #self.Elements + 1
	local t

	if not rep then 

		t = DeltaTextPiece:new(self, tx, self.Font, key, rep)

		self.Elements[key] = t
		self.LastAddedText = key

	else 
		local txel = self.Elements[self.LastAddedText] --grab last text
		if not txel then PrintTable(self.Elements) print(self.LastAddedText) error("can't add a text replacer if there's no textpieces!") return end 

		t = DeltaTextEvent:new(key)

		function t:OnActive()
			local frag = txel:FragmentText(#txel.Text - rep, #txel.Text)
			txel:ReplaceText(frag, tx)
		end

		self.Elements[key] = t
	end

	if timing then 

		self.Timings[key] = {
			time = timing, 
			elem = t, 
			key = key, 

			OnActive = function(self, dt)
				dt:ActivateElement(key)
			end
		} 
	end

	return t 
end

function dmeta:SetAlignment(a)
	self.Alignment = a
	return self
end

function dmeta:AddEvent(timing)
	local key = #self.Elements + 1

	local t = DeltaTextEvent:new(key)

	self.Elements[key] = t 	--it's not really a text

	if timing then 

		self.Timings[key] = {
			time = timing, 
			elem = t, 
			key = key, 

			OnActive = function(self, dt)
				dt:ActivateElement(key)
			end
		} 
	end

	return t 
end

function dmeta:CycleReset()
	local last

	for i=1, #self.Active do 
		local elem = self.Active[i]
		if elem and not elem.IsEvent then 
			elem:Reset() 
			last = elem 
		end
	end

	self.LastActive = 0
	self.LastTiming = 0 

	table.Empty(self.Active)

	if last then last:Disappear() end
	for k,v in pairs(self.Timings) do 
		v.Activated = false 
	end
end

function dmeta:GetElements()
	return self.Elements 
end

function dmeta:GetPreviousElement()
	return self.Active[#self.LastActive - 1]
end

function dmeta:GetCurrentElement()
	return self.Active[#self.LastActive]
end

function dmeta:CycleNext()
	
	local key = self.LastActive or #self.Active
	local tx = self.Elements[key + 1] --new object to activate

	local lasttx = self.LastActiveText

	if tx then 

		if tx.IsEvent then 
			self.Active[key + 1] = tx
			self.LastActive = key + 1
			self.ActiveWhen = CurTime()

			tx:OnActive()		
			return tx
		end

		tx:Appear()
		tx:OnAppear()

		self.Active[key + 1] = tx

		self.LastActiveText = key + 1
		self.LastActive = key + 1


		self.ActiveWhen = CurTime()

		local ac = self.Active[lasttx]	--current text, make it disappear
		if ac and not ac.IsEvent then key = ac.Key ac:Disappear() end

		return self.Active[key + 1]
	else 
		return false 
	end
	
end

function dmeta:GetSize()

	--[[
		TODO: make dmeta loop around all of its' active objects and
		return the maximum width with offsets and text width calculations here
	]]

end

function dmeta:ActivateElement(num) 	--this skips certain elements from the cycle

	local tx = self.Elements[num] --new object to activate

	if tx then 

		if tx.IsEvent then 
			self.Active[num] = tx
			self.LastActive = num
			self.ActiveWhen = CurTime()

			tx:OnActive()		
			return tx
		end

		tx:Appear()
		tx:OnAppear()

		self.Active[num] = tx

		self.LastActiveText = num
		self.LastActive = num

		self.ActiveWhen = CurTime()

		local ac = self.Active[lasttx]	--current text, make it disappear
		if ac and not ac.IsEvent and not tx.PreventDisappear then key = ac.Key ac:Disappear() end

		return self.Active[num]
	end
end

function dmeta:Paint(x, y)

	--[[
		Grab text full width
	]]
	local tw = 0

	surface.SetFont(self.Font)
	self.LastFont = self.Font 

	for k, tp in pairs(self.Active) do 
		if not tp.Paint then continue end

		if tp.Font ~= self.LastFont then self.LastFont = tp.Font surface.SetFont(self.Font) end
		tw = tw + (surface.GetTextSize(tp:GetText(true)))
	end

	self.TextWidth = tw

	local offx = -self.Alignment / 2 * tw

	for k, tp in pairs(self.Active) do 
		if not tp.Paint then continue end
		tp:Paint(x + offx, y)
	end

	for k, tp in pairs(self.Disappearing) do 
		if not tp.Paint then continue end
		tp:Paint(x, y)
	end


	local timing = self.Timings[self.LastActive + 1]

	if timing then 
		local when = self.ActiveWhen

		if not timing.Activated and when + timing.time < CurTime() then 
			--activate 
			timing:OnActive(self)
			timing.Activated = true
			--self:ActivateElement(timing.key)
		end
	end
end