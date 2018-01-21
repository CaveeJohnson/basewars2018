include("include.lua")

if not (IsMounted("cstrike") and util.IsValidModel("models/props/cs_assault/money.mdl")) then
	basewars.requirementFailed("CS:S is not mounted", "http://wiki.garrysmod.com/page/Mounting_Content_on_a_DS")
end

resource.AddFile("resource/fonts/DejaVuSans.ttf")
resource.AddFile("resource/fonts/DejaVuSans-Bold.ttf")
resource.AddFile("resource/fonts/DejaVuSans-Mono.ttf")

local spawnicons = file.Find(GM.Folder  .. "/content/materials/entities/*", "GAME")
for _, v in ipairs(spawnicons) do
	resource.AddFile("materials/entities/" .. v)
end

-- Stuff for server, remove from here in future
resource.AddWorkshop("1132466603") -- stormfox

resource.AddWorkshop("160250458" ) -- wire
resource.AddWorkshop("173482196" ) -- sprops
