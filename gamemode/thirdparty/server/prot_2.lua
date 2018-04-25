-- Not actually third party, but it is out-the-box prot_2 without
-- using the module system

local tag = "bw18-prot2"


--local c_physics = "PHYS"
local c_badents = "ENTS"
local c_baddamg = "DAMG"
local c_modules = "MODL"
--local c_frmtime = "TIME"
local c_luasend = "LUAS"
--local c_buildin = "BUIL"

local logf, warnf, fatalf, alertf
--local stopPenetration, freezeMovement, emergencyMode, antiPenetration

-- TODO: Missing features:
--	Model precache detection
--	Lag warn on freeze contacts
--	Physics defusal + sanatization
--	linux filesystem CS fixes
--	Crashy model stuff


--== Internal Stuff  ==--


local _R = debug.getregistry()

local ENTITY = _R.Entity
local PLAYER = _R.Player

do
	local logs_col = Color( 25,  75, 255, 255)
	local warn_col = Color(230, 180,   0, 255)
	local fatl_col = Color(240,  90,  60, 255)

	function logf(form, ...)
		MsgC(logs_col, "[" .. tag  .. "] ") print(string.format(form, ...))
	end

	function warnf(class, form, ...)
		MsgC(warn_col, "[" .. class .. "] ") print(string.format(form, ...))
	end

	function fatalf(class, form, ...)
		MsgC(fatl_col, "[" .. class .. "] ") print(string.format(form, ...))
	end

	local alrt_col = Color(200, 080, 190, 255)
	local alrt_snd = Sound("npc/roller/code2.wav")

	function alertf(form, ...)
		if chat and chat.AddText then -- aowl
			chat.AddText(alrt_col, "! ", color_white, string.format(form, ...))
			BroadcastLua("surface.PlaySound'" .. alrt_snd .. "'")
		elseif tetra and tetra.rpc then -- tetrahedron
			tetra.chat(nil, alrt_col, "! ", color_white, string.format(form, ...))
			tetra.rpc(nil, "surface.PlaySound", alrt_snd)
		end
	end
end

local LINUX = false
if system.IsLinux() then
	LINUX = true
	logf("Server is linux; loading modules for extended functionality.")

	local ok, err

	ok, err = pcall(require, "hosterror")
	if not ok then warnf(c_modules, "Failed to load hosterror module '%s'.", err) end

	ok, err = pcall(require, "slerpbones")
	if not ok then warnf(c_modules, "Failed to load slerpbones module '%s'.", err) end

	ok, err = pcall(require, "penicillin")
	if not ok then warnf(c_modules, "Failed to load penicillin module '%s'.", err) end
end

--[[
do
	local function freezeTbl(tbl, sleep)
		for _, ent in ipairs(tbl) do
			local count = ent:GetPhysicsObjectCount()

			if count > 1 then
				for i = 1, count do
					local phys = ent:GetPhysicsObjectNum(i)

					if IsValid(phys) then
						if sleep then
							phys:Sleep()
						else
							phys:EnableMotion(false)
							phys:Sleep()
						end
					end
				end
			else
				local phys = ent:GetPhysicsObject()

				if IsValid(phys) then
					if sleep then
						phys:Sleep()
					else
						phys:EnableMotion(false)
						phys:Sleep()
					end
				end
			end
		end
	end

	function antiPenetration(say)
		local pen = {}
		local count = 0

		local owners = {}

		for _, ent in ipairs(ents.GetAll()) do
			if not (ent:IsPlayer() or ent:IsNPC()) then
				local count = ent:GetPhysicsObjectCount()

				local isPen = false
				if count > 1 then
					for i = 1, count do
						local phys = ent:GetPhysicsObjectNum(i)

						if isPen then
							phys:Sleep()
						elseif IsValid(phys) and phys:IsPenetrating() then
							isPen = true
							phys:Sleep()

							break
						end
					end
				else
					local phys = ent:GetPhysicsObject()

					if IsValid(phys) and phys:IsPenetrating() then
						isPen = true
						phys:Sleep()
					end
				end

				if isPen then
					count = count + 1
					pen[count] = ent

					local owner =
						(ent:IsWorld() and "world")
						or (IsValid(ent:GetOwner()) and ent:GetOwner())
						or ent.CPPIGetOwner and IsValid(ent:CPPIGetOwner()) and ent:CPPIGetOwner()
						or ent.Owner
						or "unknown"

					if owner ~= "" then
						owners[owner] = (owners[owner] or 0) + 1
					end
				end
			end
		end

		if say and count > 0 then
			local biggest, owner = 0
			for k, v in pairs(owners) do
				if v > biggest then
					biggest = v
					owner = k
				end
			end

			if biggest > 2 then
				warnf(c_physics, "Largest cause of lag was %d entities, owned by %s (%d total).", biggest, owner, count)

				local name = owner
				if isentity(owner) and owner:IsPlayer() then name = owner:Nick() end
				alertf("Anti-penetration determined that '%s' was the main cause of lag, with %d entities out of %d penetrating.", name, biggest, count)
			end
		end
	end

	do
		local function stopThat(...) return false end

		local hooks = {
			"OnPhysgunReload",
			"PhysgunPickup",
			"PlayerSpawnEffect",
			"PlayerSpawnVehicle",
			"PlayerSpawnNPC",
			"PlayerSpawnSENT",
			"PlayerSpawnSWEP",
			"PlayerSpawnProp",
			"PlayerSpawnObject",
			"PlayerGiveSWEP",
			"PlayerSpawnRagdoll",
			"CanTool",
		}

		function toggleBuilding(disabled)
			if not disabled then
				for _, v in ipairs(hooks) do
					hook.Remove(v, tag .. "stopBuilding")
				end

				stopPenetration(false)
			else
				for _, v in ipairs(hooks) do
					hook.Add(v, tag .. "stopBuilding", stopThat)
				end

				warnf(c_buildin, "Disabled all building.")
			end
		end
	end

	do
		local thinks = hook.GetTable()["Think"] or {} -- no addons = error
		local on = thinks[tag .. "antipen"] ~= nil

		local shutdown = 0
		function stopPenetration(enabled, timed)
			if timed then shutdown = CurTime() + timed end

			if enabled and not on then
				warnf(c_physics, "Enabling anti-penetration.")

				antiPenetration(true)
				hook.Add("Think", tag .. "antipen", antiPenetration)

				on = true
			elseif not enabled and on and CurTime() > shutdown then
				warnf(c_physics, "Disabling anti-penetration.")

				hook.Remove("Think", tag .. "antipen")

				on = false
			end
		end
	end

	function freezeMovement()
		freezeTbl(ents.GetAll(), true)
		stopPenetration(true)
	end

	function emergencyMode()
		fatalf(c_physics, "Emergency mode: Disabling all movement.")
		alertf("Server entering emergency mode, 10 seconds of forced anti-penetration, building disabled.")

		freezeTbl(ents.GetAll())
		stopPenetration(true, 9.5)

		toggleBuilding(true)
		timer.Create(tag .. "emergencyMode", 10, 1, toggleBuilding)
	end
end
]]

--== Brain Damage Prevention ==--


do
	local function stopPlayerTool(ply, trace)
		local ent = trace.Entity

		if ent:IsPlayer() then
			return false
		end
	end

	hook.Add("CanTool", tag, stopPlayerTool)
	logf("Fixed toolgun being usable on players.")
end

local postInitFixes
local delayHooks = {}
--local function delayHook(type, name, func) delayHooks[#delayHooks + 1] = {type, tag .. name, func} end

do
	local function dumbCommand(mod)
		return function(ply, command, args, str)
			str = str or table.concat(str, " ")

			ply:ChatPrint(string.format("%s is not installed on this server. (You tried to run '%s %s')", mod, mod, str))
		end
	end

	local function dumbCommHook(mod, command)
		concommand.Add(command, dumbCommand(mod))
	end

	local function dumbChat(mod, command)
		return function(ply, text)
			if text and text:match("^" .. command) then
				ply:ChatPrint(string.format("%s is not installed on this server. (You tried to run '%s')", mod, command))

				return ""
			end
		end
	end

	local function dumbChatHook(mod, command)
		hook.Add("PlayerSay", tag .. mod .. command, dumbChat(mod, command))
	end

	local function dumbPeopleAdminMods()
		if not concommand.GetTable then return end
		local concommands = concommand.GetTable()

		if not concommands.ulx or _G.FixesPerformed.ulx then
			dumbCommHook("ulx", "ulx")
			dumbCommHook("ulx", "xgui")

			dumbChatHook("ulx", "!menu")
			dumbChatHook("ulx", "!xgui")

			_G.FixesPerformed.ulx = true
			logf("Added dummy ulx commands.")
		end

		if not concommands.ev or _G.FixesPerformed.ev then
			dumbCommHook("evolve", "ev")
			dumbCommHook("evolve", "+ev_menu")

			dumbChatHook("evolve", "!ev_menu")

			_G.FixesPerformed.ev = true
			logf("Added dummy evolve commands.")
		end
	end

	function postInitFixes()
		concommand.Remove("kickid2")
		concommand.Remove("banid2")

		concommand.Remove("gm_save")

		logf("Removing useless commands.")

		dumbPeopleAdminMods()

		physenv.SetPerformanceSettings {MaxCollisionChecksPerTimestep = 500}

		for _, v in ipairs(delayHooks) do
			hook.Add(unpack(v))
		end
	end
	hook.Add("InitPostEntity", tag, postInitFixes)
end


--== Engine Crash Prevention ==--


do
	local function fixDamage(self, info)
		local inf = info:GetInflictor()
		local atk = info:GetAttacker()
		local inf_valid = IsValid(inf) or inf:IsWorld()
		local atk_valid = IsValid(atk) or atk:IsWorld()

		if atk_valid and not inf_valid then
			warnf(c_baddamg, "Entity (%s) took incorrect damage, Inflictor changed to Attacker (%s)", self, atk)
			info:SetInflictor(atk)
		elseif not atk_valid and inf_valid then
			warnf(c_baddamg, "Entity (%s) took incorrect damage, Attacker changed to Inflictor (%s)", self, inf)
			info:SetAttacker(inf)
		elseif not atk_valid and not inf_valid then
			warnf(c_baddamg, "Entity (%s) took incorrect damage, Attacker/Inflictor changed to World", self)

			local world = game.GetWorld()
			info:SetAttacker(world)
			info:SetInflictor(world)
		end
	end

	ENTITY.TakeDamageInfoUnsafe = ENTITY.TakeDamageInfoUnsafe or ENTITY.TakeDamageInfo
	function ENTITY:TakeDamageInfo(info, ...)
		if not info then
			error("No arguments provided to TakeDamageInfo", 2)
		end

		local world = self:IsWorld()
		if not self:IsValid() and not world then
			error("Invalid entity passed to TakeDamageInfo", 2)
		end

		if world or self:IsPlayer() then
			return self:TakeDamageInfoUnsafe(info, ...)
		end

		fixDamage(self, info)

		return self:TakeDamageInfoUnsafe(info, ...)
	end
	logf("Fixed invalid TakeDamageInfo.")

	local function fixNpcDamagers(self, info)
		if not self:IsNPC() then return end

		fixDamage(self, info)
	end

	hook.Add("EntityTakeDamage", tag, fixNpcDamagers)
	hook.Add("ScaleNPCDamage", tag, function(ent, hitgroup, info)
		fixNpcDamagers(ent, info)
	end)
	logf("Fixed npc crash and other EntityTakeDamage related issues.")
end

do

	local maxSafe = 8192 - 128

	ents.CreateUnsafe = ents.CreateUnsafe or ents.Create
	function ents.Create(class, ...)
		local count = ents.GetEdictCount()

		if count >= maxSafe then
			fatalf(c_badents, "Maximum safe edict count has been exceeded (%d/%d)!", count, maxSafe)
			alertf("Safe edict count has been exceeded, no more entities may spawn, delete any entities you do not need.")

			return NULL
		end

		if class == "prop_vehicle_jeep_old" then
			class = "prop_vehicle_jeep"
		end

		return ents.CreateUnsafe(class, ...)
	end

	logf("Added ents.Create saftey checks.")
end

do
	hook.Add("PropBreak", tag .. "constraints", function(_, ent)
		if IsValid(ent) then
			pcall(constraint.RemoveAll, ent)
		end
	end)

	hook.Add("PlayerCanPickupWeapon", tag .. "constraints", function(_, wep)
		if constraint.HasConstraints(wep) then
			pcall(constraint.RemoveAll, wep)

			return false
		end
	end)

	logf("Added constraint fixes.")
end

do
	scripted_ents.Register({Base = "base_point", Type = "point"}, "info_ladder")

	logf("Registering info_ladder entity.")
end

do
	local inf, ninf = 5e34, -5e34

	PLAYER.GetInfoNumUnsafe = PLAYER.GetInfoNumUnsafe or PLAYER.GetInfoNum
	function PLAYER:GetInfoNum(var, def, ...)
		local num = self:GetInfoNumUnsafe(var, def, ...)
		if num and (num >= inf or num <= ninf) then
			num = def or 0
		end

		return num
	end

	PLAYER.GetInfoUnsafe = PLAYER.GetInfoUnsafe or PLAYER.GetInfo
	function PLAYER:GetInfo(var, def, ...)
		local num = self:GetInfoUnsafe(var, def, ...)

		local comp = tonumber(num)
		if comp and (comp >= inf or comp <= ninf) then
			num = def or 0
		end

		return num
	end

	logf("Clamped GetInfo and GetInfoNum.")
end

do
	ENTITY.PhysicsDestroyUnsafe = ENTITY.PhysicsDestroyUnsafe or ENTITY.PhysicsDestroy
	function ENTITY:PhysicsDestroy(...)
		if self:GetClass() == "prop_ragdoll" then
			error("Attempting to call PhysicsDestroy on a ragdoll", 2)
		end

		return self:PhysicsDestroyUnsafe(...)
	end

	logf("Fixed physics destruction of ragdolls.")
end

if LINUX then
	util.IsValidModelCS = util.IsValidModelCS or util.IsValidModel
	function util.IsValidModel(m, ...)
		return util.IsValidModelCS(m, ...) or util.IsValidModelCS(m:lower(), ...)

	end

	util.IsValidPropCS = util.IsValidPropCS or util.IsValidProp
	function util.IsValidProp(m, ...)
		return util.IsValidPropCS(m, ...) or util.IsValidPropCS(m:lower(), ...)

	end

	util.IsValidRagdollCS = util.IsValidRagdollCS or util.IsValidRagdoll
	function util.IsValidRagdoll(m, ...)
		return util.IsValidRagdollCS(m, ...) or util.IsValidRagdollCS(m:lower(), ...)
	end

	logf("Fixed util.IsValidX being case sensitive on linux.")
end

do
	PLAYER.SendLuaUnsafe = PLAYER.SendLuaUnsafe or PLAYER.SendLua
	function PLAYER:SendLua(code, ...)
		if self:IsBot() then return end

		code = tostring(code)
		if not code then return end

		local len = code:len()
		if len >= 254 then
			if luadev and luadev.RunOnClient then
				warnf(c_luasend, "SendLua overflowed for '%s' (%d bytes), using luadev to transmit.", self, len)

				local _, err = luadev.RunOnClient(code, self, "SendLua")
				if err then
					warnf(c_luasend, "failed to send with luadev; %s...", err)
				end
			else
				warnf(c_luasend, "SendLua overflowed for '%s' (%d bytes); no luadev.RunOnClient, cannot rescue.", self, len)
			end

			return
		end

		return self:SendLuaUnsafe(code, ...)
	end

	BroadcastLuaUnsafe = BroadcastLuaUnsafe or BroadcastLua
	function BroadcastLua(code, ...)
		code = tostring(code)
		if not code then return end

		local len = code:len()
		if len >= 254 then
			if luadev and luadev.RunOnClients then
				warnf(c_luasend, "BroadcastLua overflowed (%d bytes), using luadev to transmit.", len)

				local _, err = luadev.RunOnClients(code, "BroadcastLua")
				if err then
					warnf(c_luasend, "failed to send with luadev; %s...", err)
				end
			else
				warnf(c_luasend, "BroadcastLua overflowed (%d bytes); no luadev.RunOnClients, cannot rescue.", len)
			end

			return
		end

		return BroadcastLuaUnsafe(code, ...)
	end

	logf("Fixed Broadcast/SendLua breaking with strings > 254 chars.")
end


--== Server Crash Prevention ==--

--[=[
do
	-- Think based antipen and freeze

	local longFrame = 0.1

	local lastThink = SysTime() + 1
	local lagStart, lagEnded, done

	local function doThink()
		local now = SysTime()
		local len = now - lastThink

		if len > longFrame then
			lagEnded = nil

			lagStart = lagStart or now
			done = done or 0

			local lag = now - lagStart

			if len > 0.5 then
				warnf(c_frmtime, "very long frame (%1.2f s)", len)
			end

			if lag > 5 and done < 5 then
				done = 5

				emergencyMode()
				warnf(c_frmtime, "[lag now %1.2f s]", lag)
			elseif lag > 3 and done < 3 then
				done = 3

				freezeMovement()
				warnf(c_frmtime, "[lag now %1.2f s]", lag)
			elseif lag > 1.5 and done < 1.5 then
				done = 1.5

				stopPenetration(true)
				warnf(c_frmtime, "[lag now %1.2f s]", lag)
			end
		elseif lagStart then
			lagEnded = lagEnded or now

			local lagover = now - lagEnded

			if lagover > 1 then
				lagStart = nil
				lagEnded = nil

				stopPenetration(false)
			end

			done = nil
		end

		lastThink = SysTime()
	end

	delayHook("Think", "antilag", doThink)

	logf("Added frametime lag detector.")
end

if LINUX then
	hook.Add("ShouldFreezeContacts", tag, function(count, tbl)
		-- TODO:
		return true
	end)

	hook.Add("AdditionalCollisions", tag, function(collisions)
		if collisions > 1000 then
			freezeMovement()
			return 0
		elseif collisions > 500 then
			antiPenetration()
			return 100
		else
			return 500
		end
	end)

	logf("Hooked penicillin to provide anti-lag.")
end

if false then
	local maxExecTime = 10
	local instructionInterval = 2^24

	local lastChecked = SysTime()

	do
		local hookFunc = function()
			if SysTime() - lastChecked > maxExecTime then
				error("Infinite loop detected!", 2)
			end
		end

		hook.Add("Think", tag .. "infinite_loop", function()
			lastChecked = SysTime()
			debug.sethook(hookFunc, "", instructionInterval)
		end)
	end

	logf("Added anti-infinite-loop protection.")
end
]=]

do
	if _G.FixesPerformed then -- reloading
		logf("Reloaded, re-performing post-init fixes.")
		postInitFixes()
	end

	_G.FixesPerformed = _G.FixesPerformed or {}
end
