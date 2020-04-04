-- local function wrapDamageForAttack(targ, attacker, inflictor)
-- 	local ply = attacker

-- 	if not (IsValid(ply) and ply:IsPlayer()) then
-- 		ply = inflictor

-- 		if not (IsValid(ply) and ply:IsPlayer()) then
-- 			if IsValid(inflictor) then
-- 				ply = inflictor:CPPIGetOwner()

-- 				if IsValid(ply) and ply:IsPlayer() then
-- 					return ply, targ
-- 				end
-- 			end
-- 		else
-- 			return ply, targ
-- 		end
-- 	else
-- 		return ply, targ
-- 	end
-- end

-- basewars.isosnub.events.register("OnNPCKilled", "kill_npc", wrapDamageForAttack)

-- local melee = {
-- 	["weapon_crowbar"] = true,
-- 	["weapon_stunstick"] = true,
-- 	["weapon_fists"] = true,
-- 	["m9k_damascus"] = true,
-- }

-- basewars.isosnub.events.register("OnNPCKilled", "kill_npc_melee", function(npc, attacker, inflictor)
-- 	local ply
-- 	ply, npc = wrapDamageForAttack(npc, attacker, inflictor)

-- 	if ply and IsValid(ply:GetActiveWeapon()) and melee[ply:GetActiveWeapon():GetClass()] then
-- 		return ply, npc
-- 	end
-- end)

-- basewars.isosnub.templates.create("kill_zombies_2")
-- 	:setName("Slayer")
-- 	:setDescription("Slaughter the undead.")
-- 	:setThresholdFunction(function(self, tier)
-- 		return math.floor(10 ^ ((tier + 2) / 3))
-- 	end)
-- 	:setIcon("href:https://b.catgirlsare.sexy/j6gK.png")

-- 	:incrementOn("kill_npc")

-- 	:listen("tierup", function(self)
-- 		if CLIENT then return end

-- 		local killed = math.floor(10 ^ ((self:getCurrentTier() + 2) / 3))
-- 		self:getPlayer():GiveMoney(3e3 * killed)
-- 	end)

basewars.isosnub.events.register("PlayerSay", "say_gamer_word", function(ply, text)
    if nil ~= text:lower():find("nigger") then
        return ply
    end
end)

basewars.isosnub.templates.create("say_gamer_word")
	:setName("THE GAMER WORD")
	:setDescription("DONT SAY IT.")
	:setThresholdFunction(function(self, tier)
		return 1
	end)
	:setIcon("href:http://q2f2.u.catgirlsare.sexy/7q6m.png")

	:incrementOn("say_gamer_word")

	:listen("tierup", function(self)
		if CLIENT then return end

		self:getPlayer():Kill()
	end)
