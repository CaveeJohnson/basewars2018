local ext = basewars.createExtension"core.player-money"

function ext:SetupPlayerDataTables(ply)
	ply:netVar("Double", "Money", true, 5e3, nil, 0)
end
