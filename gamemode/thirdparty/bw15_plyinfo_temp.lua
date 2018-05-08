PlyInfo = {}
local PLAYER = debug.getregistry().Player

if SERVER then

PlyInfo.Plys = {}

hook.Add( "PlayerInitialSpawn", "PlyInfo_CollectInfo", function( ply )
	PlyInfo:GetInfo( ply )
end )

function PlyInfo:GetIP( ply )
	if not IsValid( ply ) then return end
	local plyAddr = ply:IPAddress()
	local ip = string.Explode( ":", plyAddr )[ 1 ]

	return ip
end

function PlyInfo:GetCountry( ply )
	if not IsValid( ply ) then return end
	if PlyInfo.Plys[ PlyInfo:GetIP( ply ) ] then
		return PlyInfo.Plys[ PlyInfo:GetIP( ply ) ].country
	else
		return "N/A"
	end
end

function PlyInfo:GetCountryCode( ply )
	if not IsValid( ply ) then return end
	return PlyInfo:GetIP( ply ) and PlyInfo.Plys[ PlyInfo:GetIP( ply ) ] and PlyInfo.Plys[ PlyInfo:GetIP( ply ) ].countryCode or "N/A"
end

function PlyInfo:GetTimeZone( ply )
	if not IsValid( ply ) then return end
	return PlyInfo:GetIP( ply ) and PlyInfo.Plys[ PlyInfo:GetIP( ply ) ] and PlyInfo.Plys[ PlyInfo:GetIP( ply ) ].timezone or "N/A"
end

function PlyInfo:GetCity( ply )
	if not IsValid( ply ) then return end
	return PlyInfo:GetIP( ply ) and PlyInfo.Plys[ PlyInfo:GetIP( ply ) ] and PlyInfo.Plys[ PlyInfo:GetIP( ply ) ].city or "N/A"
end

function PlyInfo:GetInfo( ply )
	if not IsValid( ply ) then return end
	local plyIP = PlyInfo:GetIP( ply )
	if IsValid( PlyInfo.Plys[ plyIP ] ) then return end
	http.Fetch( "http://ip-api.com/json/" .. plyIP,
	function ( data )
		if string.len ( data ) > 5 then
			data = util.JSONToTable ( data )
			PlyInfo.Plys[ plyIP ] = data
			if not IsValid( ply ) then return end
			ply:SetNW2String( "Country", ply:GetCountry() )
			ply:SetNW2String( "CountryCode", ply:GetCountryCode() )
			ply:SetNW2String( "TimeZone", ply:GetTimeZone() )
			ply:SetNW2String( "City", ply:GetCity() )
		end
	end,
	function ( err )
		timer.Simple( 2, function() PlyInfo:GetInfo( ply ) end )
	end )
end

function PlyInfo:ReloadInfo()
	for k, v in pairs( player.GetAll() ) do
		PlyInfo:GetInfo( v )
		print( v:Name() .. " data loaded" )
	end
end

function PlyInfo:Countries()
	local tbl = {}
	for k, v in next,player.GetAll() do
		table.insert( tbl, v:Name() .. " - " .. v:GetCountry() )
	end
	return tbl
end

PlyInfo:ReloadInfo()

end --SV END

function PLAYER:GetCountry()
	if not IsValid( self ) then return end
	if SERVER then
		return PlyInfo:GetCountry( self )
	else
		return self:GetNW2String( "Country", "ERROR" )
	end
end

function PLAYER:GetCountryCode()
	if not IsValid( self ) then return end
	if SERVER then
		return PlyInfo:GetCountryCode( self )
	else
		return self:GetNW2String( "CountryCode", "ERROR" )
	end
end

function PLAYER:GetTimeZone()
	if not IsValid( self ) then return end
	if SERVER then
		return PlyInfo:GetTimeZone( self )
	else
		return self:GetNW2String( "TimeZone", "ERROR" )
	end
end

function PLAYER:GetCity()
	if not IsValid( self ) then return end
	if SERVER then
		return PlyInfo:GetCity( self )
	else
		return self:GetNW2String( "City", "ERROR" )
	end
end