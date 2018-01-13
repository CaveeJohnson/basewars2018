local ext = basewars.createExtension"core.base-core-ownership"
basewars.basecore = basewars.basecore or {}

function basewars.basecore.get(ply)
	if not IsValid(ply) then return false end

	return hook.Run("BW_GetPlayerCore", ply) or ply:GetNW2Entity("baseCore") -- DOCUMENT:
end

function basewars.basecore.has(ply)
	return IsValid(basewars.basecore.get(ply))
end

function ext:wantEntity(ent)
	return ent.isCore
end

ext:addEntityTracker("core", "wantEntity")

function ext:PostEntityCreated(ent)
	self:receiveEntityCreate(ent)

	if CLIENT and ent.isCore then ent:requestAreaTransmit() end
end

function basewars.basecore.getList()
	return ext.core_list, ext.core_count
end

function basewars.basecore.getForPos(pos)
	pos = isvector(pos) and pos or pos:GetPos()

	for i = 1, ext.core_count do
		local v = ext.core_list[i]

		if v:encompassesPos(pos) then
			return v
		end
	end

	return nil
end

function basewars.basecore.canSpawn(ply, pos, class)
	if not IsValid(ply) then return false, "Invalid player!" end
	if not pos then return false, "Invalid position!" end
	if basewars.basecore.has(ply) then return false, "You already have a core!" end

	class = class or "basewars_core"

	local sent = scripted_ents.Get(class)
	if not (sent and sent.isCore) then return false, "Invalid core class!" end

	local rad = sent.DefaultRadius
	if not rad then return false, "Invalid core class!" end

	--[[local a = basewars.getExtension"areas"
	if a then
		a = a:new("coreSpawnTestRegion", pos, rad, stepTol)

		if not a then return false, "This area is not on the navigation mesh!" end
	end]]

	for i = 1, ext.core_count do
		local v = ext.core_list[i]

		local combined_rad = v:getProtectionRadius() + rad
		if v:encompassesPos(pos) or v:GetPos():DistToSqr(pos) <= combined_rad * combined_rad then
			return false, "Core conflicts with another core's claim!"
		elseif a and v.area and a:intersects(v.area) then
			return false, "Core conflicts with another core's claim!"
		end
	end

	return true, rad
end

if CLIENT then
	local prot   = Color(120, 100, 170, 2)
	local prot2  = Color(120, 100, 170, 4)

	ext.debug = false

	function ext:PostDrawTranslucentRenderables(d, s)
		if s then return end

		if self.debug then
			for i = 1, self.core_count do
				local v = self.core_list[i]

				render.SetColorMaterial()
				render.DrawSphere(v:GetPos(),  v:getProtectionRadius(), 25, 25, prot)
				render.DrawSphere(v:GetPos(), -v:getProtectionRadius(), 25, 25, prot2)
			end
		else
			local v = basewars.basecore.get(LocalPlayer())

			if IsValid(v) then
				render.SetColorMaterial()
				render.DrawSphere(v:GetPos(),  v:getProtectionRadius(), 25, 25, prot)
				render.DrawSphere(v:GetPos(), -v:getProtectionRadius(), 25, 25, prot2)
			end
		end
	end
end
