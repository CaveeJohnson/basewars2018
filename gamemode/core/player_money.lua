local ext = basewars.createExtension"core.money"

function ext:SetupPlayerDataTables(ply)
	ply:netVar("Int", "Money", true, 5e3, nil, 0)
end
