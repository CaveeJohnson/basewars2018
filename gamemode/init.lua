include("include.lua")

if not (IsMounted("cstrike") and util.IsValidModel("models/props/cs_assault/money.mdl")) then
	basewars.requirementFailed("CS:S is not mounted", "http://wiki.garrysmod.com/page/Mounting_Content_on_a_DS")
end

resource.AddFile("resource/fonts/DejaVuSans.ttf")
resource.AddFile("resource/fonts/DejaVuSans-Bold.ttf")
