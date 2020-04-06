--ent quickmenus

QuickMenus = QuickMenus or {}
QuickMenus.Registered = QuickMenus.Registered or {} --table that holds ents that registered for quickmenus for fast lookups
QuickMenus.IRegistered = QuickMenus.IRegistered or {} --table that holds same shit but sequential for fast ipairs, yes its microoptimization stfu

local qmregistered = QuickMenus.Registered	

local iqmr = QuickMenus.IRegistered			

openedQM = nil

local ENTITY = FindMetaTable("Entity")
local QMObj = {}
local QMMeta = {}
QMObj.__index = QMMeta

setmetatable(QMObj, QMMeta)

AccessorFunc(QMMeta, "progress", "Progress")
AccessorFunc(QMMeta, "dist", "UseDistance")
AccessorFunc(QMMeta, "time", "Time")
AccessorFunc(QMMeta, "KeepAlive", "KeepAlive")
AccessorFunc(QMMeta, "ent", "Entity")

--[[
	Functions for override
]]

function QMMeta:OnOpen(ent, pnl)

end

function QMMeta:OnHold(ent, pnl)

end


function QMMeta:OnClose(ent, pnl)		--this is called when the qm progress was 1 but became less than 1

end

function QMMeta:OnFullClose(ent, pnl)	--this is called when the qm progress reaches 0

end

function QMMeta:OnUnhold(ent, pnl)

end

function QMMeta:OnReopen(ent, pnl)

end

function QMMeta:OnRehold(ent, pnl)

end

function QMMeta:Think(ent, pnl)

end

function QMMeta:Paint(ent, pnl)

end


--[[
	Internal functions
]]
function QMMeta:__OnClose(ent, pnl)

	for k,v in pairs(self.PopIns) do 
		if not IsValid(v.Panel) then self.PopIns[k] = nil continue end 

		local btn = v.Panel 

		local oX, oY = v.OffX, v.OffY 

		if v.PopInAnim then 

			oX = v.X - btn.X + oX
			oY = v.Y - btn.Y + oY

			v.PopInAnim:Stop() 
			v.PopInAnim = nil 
		end 
		if v.MoveInAnim then v.MoveInAnim:Stop() v.MoveInAnim = nil end 

		v.PopOutAnim = btn:AlphaTo(0, self:GetTime(), 0)
		v.MoveOutAnim = btn:MoveBy(oX, oY, self:GetTime(), 0, 0.2)
	end

end

function QMMeta:__OnReopen(ent, pnl)

	for k,v in pairs(self.PopIns) do 

		if not IsValid(v.Panel) then self.PopIns[k] = nil continue end 

		local btn = v.Panel 

		if v.PopOutAnim then v.PopOutAnim:Stop() v.PopOutAnim = nil end 
		if v.MoveOutAnim then v.MoveOutAnim:Stop() v.MoveOutAnim = nil end 

		v.PopInAnim = btn:AlphaTo(255, 0.1, 0)
		v.MoveInAnim = btn:MoveTo(v.X, v.Y, self:GetTime(), 0, 0.2)
	end

end

--quick function for making fancy button pop-in & out animations without much hassle

function QMMeta:AddPopIn(pnl, x, y, offx, offy)
	local pop = {}

	self.PopIns[#self.PopIns + 1] = pop

	pop.Panel = pnl
	pop.X = x 
	pop.Y = y 

	pop.OffX = offx or 0
	pop.OffY = offy or 0

	pnl:SetPos(x + offx, y + offy)

	pnl:SetAlpha(0)

	pop.PopInAnim = pnl:AlphaTo(255, 0.1, 0)
	pop.MoveInAnim = pnl:MoveTo(x, y, self:GetTime(), 0, 0.2)

	return pop
end

function ENTITY:SetQuickInteractable(b)

	if b==nil or b then 

		local key = #iqmr + 1

		local tbl = {
			key = key, 
			ent = self,

			dist = 192,
			time = 0.5,
			ease = 2,

			progress = 0,
			active = false,
			PopIns = {}
		}
		setmetatable(tbl, QMObj)

		qmregistered[self] = tbl
		iqmr[key] = tbl

		return tbl
	end

	table.remove(iqmr, qmregistered[self].key)
	qmregistered[self] = nil
end

function ENTITY:SetQuickMenuDist(num)
	qmregistered[self].dist = num
end

function ENTITY:SetQuickMenuTime(num)
	qmregistered[self].time = num
end

function ENTITY:SetQuickMenuEase(num)
	qmregistered[self].ease = num
end

local function DoTimer(qm, slow)

	if not qm then 
		for k,v in ipairs(iqmr) do 
			DoTimer(v, slow)
		end 
		return
	end

	local mult = (qm.active and 1 or -1) * (slow and 0.5 or 1)
	qm.progress = math.Clamp(qm.progress + (FrameTime()/qm.time) * mult, 0, 1)
end

local opened

local function CreateQuickMenu()
	local p = vgui.Create("DPanel")
	p:SetSize(600, 400)
	p:Center()

	local maxperc = 0

	local qm 	--the quick menu with maximum progress

	function p:Think()
		maxperc = 0

		local active = false 

		local hastime = false

		for k,v in ipairs(iqmr) do 
			if v.active then 
				active = true 

				if v.wasopened and not v.opened then 
					v:OnRehold()
				end
			end

			if v.progress > 0 then 
				hastime = true 
				v:Think(v.ent, self)
			else 
				v:OnFullClose(v.ent, self)
				v.wasopened = false
			end

			if v.progress == 1 and not v.opened and not self.CurrentQM then 	--progress = 100%, not open and no more opened quickmenus

				if v.wasopened then 
					v:OnReopen(v.ent, self)
					v:__OnReopen(v.ent, self)
				else
					v.wasopened = true
					v:OnOpen(v.ent, self)
					
				end

				v.opened = true
				opened = v
			end

			if v.progress ~= 1 and v.opened then 
				v:OnClose(v.ent, self)
				v:__OnClose(v.ent, self)
				v.opened = false
			end

			maxperc = math.max(v.progress, maxperc)

			if v.progress == maxperc then 
				qm = v
			end
			
		end

		self.CurrentQM = (qm.progress == 1 and qm)


		if not active and not hastime then 

			self:Remove()
			openedQM = nil 
			return
		end
	end

	local size = 64
	local pad = 6

	local shrinkanim
	local shrinking = false

	function p:Paint(w, h)

		local midX, midY = self.CircleX, self.CircleY

		if not midX or not midY then 

			local x, y = self:ScreenToLocal(ScrW()/2, ScrH()/2)	--w, h might change and the circle always needs to draw in the middle
																--(unless overridden with self.CircleX, self.CircleY)
			midX, midY = midX or x, midY or y 

			self.CircleX = midX
			self.CircleY = midY

		end

		local perc = (maxperc^2)*100

		local mask = function()
			draw.Circle(midX, midY, size+6, 32, perc)
		end

		local a = perc

		self.Alpha = a 
		if a > 100 then print(a) end

		local op = function()
			surface.SetDrawColor(Color(250, 250, 250, a*3))
			draw.MaterialCircle(midX, midY, (size-pad)*2 )
		end
	
		surface.SetDrawColor(Color(10, 10, 10, math.min(a*2.35, 150)))
		draw.MaterialCircle(midX, midY, size*2)

		draw.Masked(mask, op)

		self.CircleSize = size 

		if perc==100 and not shrinking then 
			shrinking = true 

			if shrinkanim then 
				shrinkanim:Swap(0.1, 0, 0.4)
			else
				shrinkanim = self:NewAnimation(0.1, 0, 0.4):SetSwappable()
			end

			self:MakePopup()

			self:SetMouseInputEnabled(true)
			self:SetKeyBoardInputEnabled(false)

			shrinkanim.Think = function(_, self, frac)
				size = 64 - 24*frac
			end

		elseif shrinking and perc~=100 then 

			shrinkanim:Swap(0.1, 0, 0.4)

			local sizediff = 64 - size
			shrinking = false

			self:SetMouseInputEnabled(false)

			shrinkanim.Think = function(_, self, frac)
				size = 64 - sizediff*(1 - frac)
			end

		end

		

		qm:Paint(qm.ent, self)
	end


	return p
end

hook.Add("Think", "QuickMenus", function()

	for k,v in ipairs(iqmr) do 
		if not IsValid(v.ent) then 
			table.remove(iqmr, k) 
			qmregistered[v.ent] = nil 
		end
	end

	for k,v in ipairs(iqmr) do 
		if not v.KeepAlive then 
			v.active = false
		end	
	end

	local lp = LocalPlayer()

	local using = lp:KeyDown(IN_USE)

	local tr = lp:GetEyeTrace()

	if not using then DoTimer() return end

	if not IsValid(tr.Entity) then 

		if openedQM then

			for k,v in ipairs(iqmr) do 
				if v ~= openedQM._qm then
					DoTimer(v)
				end 
			end

		else 
			DoTimer()
		end

	return end 

	local ent = tr.Entity
	local qm = qmregistered[ent]

	if not qm then DoTimer(nil, using) return end --??

	if tr.Fraction*32768 > qm.dist then DoTimer(qm) return end 

	--if:
	-- 	1. player held use
	-- 	2. player looks at a valid ent
	-- 	3. distance is ok

	--then quickmenu counts up

	qm.active = true
	
	DoTimer()

	if not IsValid(openedQM) then 
		openedQM = CreateQuickMenu()
	end

	qm:OnHold(qm.ent, openedQM)

end)