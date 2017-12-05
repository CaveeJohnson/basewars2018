local ext = basewars.createExtension"core.levels"

ext.levelRate = 500

function ext:SetupPlayerDataTables(ply)
	ply:netVar("Int", "Level", true, 1, nil, 0)
	ply:netVar("Int", "XP", true, 0, nil, 0)

	if SERVER then ply:netVarCallback("XP", ext.checkForLevels, true) end

	function ply.Player:getNextLevelXP()
		return ext.levelRate * self:getLevel()
	end
end

if CLIENT then return end

function ext.checkForLevels(ply)
	local level = ply:getLevel()
	local xp = ply:getXP()

	local r = ext.levelRate
	local change = false
	repeat
		local rate = r * level

		if xp >= rate then
			level = level + 1
			xp = xp - rate

			change = true
		else
			break
		end
	until false

	if change then
		ply:setLevel(level)
		ply:setXP(xp)
	end
end
