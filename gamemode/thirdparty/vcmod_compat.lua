-- Someone requested this be done and since it's
-- so simple we may as well, it's a commonly used addon

-- we might need VC_postVehicleInit since it messes
-- with vehicle stuff internally

function GM:VC_canAfford(ply, amt)
	return ply:hasMoney(ply, amt)
end

function GM:VC_canAddMoney(ply, amt)
	ply:addMoney(ply, amt)

	return false
end
