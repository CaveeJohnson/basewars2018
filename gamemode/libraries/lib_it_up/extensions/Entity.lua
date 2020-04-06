EntitySubscribers = EntitySubscribers or {}

local subs = EntitySubscribers.Players or {} 		-- key = player, value = { {ply, dist_sqr, callback}, {ply, dist_sqr, callback} }
EntitySubscribers.Players = subs					-- this is used for distance-checking logic 



local ent_subs = EntitySubscribers.Entities or {}		-- key = entity, value = { [player] = ntid_in_plysub, [player] = entid_in_plysub }
EntitySubscribers.Entities = ent_subs					-- this is used for adding/removing subs from entity

--[[
	onunsub callback will be called with args:
		entity - from which the player unsubscribed
		player - which got unsubscribed

	make 4th arg "true" if you want to add subscriber multiple times
]]


local BlankFunc = function() end

local Entity = FindMetaTable("Entity")
local Player = FindMetaTable("Player")

function Entity:Subscribe(ply, dist, onunsub, addtwice)

	if CLIENT then
		ply = LocalPlayer()
	end

	onunsub = onunsub or BlankFunc

	if ent_subs[self] and ent_subs[self][ply] and not addtwice then return end  --prevent subscribing multiple times for the same entity
																				--..unless you want to.

	local sub_ply = subs[ply] or {}
	subs[ply] = sub_ply

	local plysub_key = #sub_ply + 1

	sub_ply[plysub_key] = {self, dist^2, onunsub}


	local sub_ent = ent_subs[self] or {}
	ent_subs[self] = sub_ent

	sub_ent[ply] = ply
end

function Entity:IsSubscribed(ply)
	local my_subs = ent_subs[self]

	if my_subs and my_subs[ply] then
		return true
	end

	return false
end

function Entity:Unsubscribe(ply)
	local my_subs = ent_subs[self]

	if my_subs then
		table.remove(subs, my_subs[ply])
		ent_subs[self][ply] = nil
	end
end

function Entity:GetSubscribers()
	local t = {}
	local i = 1

	local my_subs = ent_subs[self]

	if my_subs then

		for k,v in pairs(my_subs) do
			t[i] = k
			i = i + 1
		end

	end

	return t
end

function Entity:GetSubscribersKeys()

	local my_subs = ent_subs[self]

	return my_subs or {}
end


function Player:Subscribe(ent, ...)
	return ent:Subscribe(self, ...)
end

function Player:IsSubscribed(ent)
	return ent:IsSubscribed(self)
end

hook.Add("FinishMove", "EntitySubscriptions", function(pl, mv)
	if not subs[pl] then return end

	local pos = mv:GetOrigin()

	for key, dat in ipairs(subs[pl]) do

		local ent = dat[1]
		local dist = dat[2]
		local callback = dat[3]

		local epos = ent:GetPos()

		if pos:DistToSqr(epos) > dist then
			local unsub = callback(ent, pl)

			if unsub ~= false then
				table.remove(subs[pl], key) --preserve sequential order
				ent_subs[ent][pl] = nil
			end

		end

	end
end)
