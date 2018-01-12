Entities:
	[X] Passive Generator
	[ ] Active Generator (reactor)
	[X] Printer
	[ ] Turret
	[X] Cloner (spawnpoint)
	[X] Core
	[X] Core Control Panel
	[ ] Dispenser base
		[ ] Health Dispenser
		[ ] Armor Dispenser
	[ ] Energy Field Generator
	[ ] Money sink generator (power grid node, tax based on throughput)
	[ ] Telepad, massive money sink, fucking expensive, costs 1mil + 0.5% of your money to teleport

BUGS / NEEDS DOING:
	[X] Playervars need support for Doubles / string numbers
	[X] Players get stuck in cloner if y % 90 ~= 0 and other situations
	[X] extension 'core.money-distributer' hook 'BW_DistributeSaleMoney' failed: gamemodes/basewars2018/gamemode/core/server/money_distributer.lua:59: attempting to load data before player database init
	[X] distributer -> distributor
	[X] Factions and raids lose all data on reload, by nature they cannot recover it so it must be stored elsewhere
	[ ] Core area count/ents includes non-encompassed / non-owned entities (cant sell if someone puts shit nearby)
	[X] Optimize entity netvars (localize method names to avoid concat, move branching outside of functions, should allow for JIT)
	[#] Stuff to optimize on SV https://b.catgirlsare.sexy/GuGY.png related to below V
	[X] Make generic 'entity tracker' system for extensions
		- ext:addEntityTracker("tbl", "tbl_count", "wantEntity")
		- This code is cloned throughout the code base in an optimization effort
		- Will make it easier to implement custom entity lists, hence making optimization easier moving forward
	[X] Replace hardcoded £ with basewars.currency(num)
	[X] Unify name style (BaseWars, Basewars2018, etc)
	[ ] Divy up basewars.funcs into basewars.concept.funcs
	[ ] Make loader recursive - sv/cl folder, split files up into easier categories
	[ ] Moving weapon container doesn't move render
	[ ] Bw items no longer have deflect effect

Improvements (mark as [-] if its dumb):
	[ ] Alert when spawning fails in hostile area
	[X] Make blue bubble thing for range only show for own core
	[ ] Way to find your core
	[ ] You can spawn entities inside of players (also stop toolgun/props from doing this)
	[-] HUD health = red (complained about by literally everybody)
	[ ] Why have printer displays if the entity info shows everything / hide entity info for printers
	[ ] Make a proper crypto-miner base with nice gui etc, links into this ^
	[ ] Better vehicle spawning with vcmod support (requested)
	[ ] Convars for build mode
	[ ] Convar for how intense the core protection field is (alpha)

Minor Features:
	[ ] Give money with a reason, feed on hud
	[#] HUD completion + optimization
	[X] Scanning + heartbeat like R6S
	[ ] Entity upgrading
	[ ] RDM protection + raid grace for newer players
	[ ] Playtime tracking
	[ ] Deployed value tracking
	[ ] Damage numbers
	[ ] Spawn protection

Big stuff:
	[ ] Crypto market
	[ ] Drug/buff system
	[#] Faction system
		- Faction button
		- Flags for factions
		- Faction owner + admin + user, function to get highest ranking user, owner only changes on core reclaim
		- faction only items, with a faction vault which people can only deposit in
	[ ] Clan system
		- meta-game type stuff
		- minor ingame buffs
			- productivity = productivity + math.max(0, (clan_members - non_clan_members) / 100)
		- found for massive money?
		- should be linked to forums

External addons included with the gamemode:
	[ ] Admin mod
		- full cami support
	[ ] Prop protection
		- full unfettered cppi support (1.3)
		  no seriously, no deviation from the standard
		- lots of features like FPP
	[ ] ChatEXP remake from scratch
		- Base on warframe chat
	[ ] Titles + COH + Nametags

Big stuff that requires BIG changes/edits:
	[ ] Tutorial
	[ ] Language system
	[#] Config system which allows overrides but doesn't force everything into 1 massive file
		- Allows for people to change entity variables without breaking forward compat
	[ ] MYSQL support
		- needs to be perfect, we will be using this too

Fun / extra gameplay stuff:
	[ ] Superdrugs + selling drugs
	[ ] Alternative ways to make money?
		- drugs as mentioned above
		- meth lab
	[ ] PVE content
		- bosses (zeni)
		- fishing (aer)
		- ?
	[ ] Weapon factory
	[ ] Loudout table
	[ ] Random entity spawns (broken printers)

Endgame:
	[ ] Mediaplayer (as per the old endgame)

Security:
	[ ] Hash all clientside file paths automatically.
		- do string replacements for them too
		- lua/gamemodes/basewars2018/core/client/cock.lua -> lua/8f7d88316ba8274e849c7e90d90aa052b.lua
	[ ] String replacements for info such as client sid64
		- if ip ~= server's ip, crash
		- if sid64 ~= client's sid64, crash
		- if sessionid ~= sv sessionid (networked later), crash
		- request hexahedron.pw, if version ~= version, crash
		- Strip tabs completely totalling readability,
		  but making errors appear on the same lines (dont minify)
		- Package all of the above into a nice little security line at the top of
		  every file (automatically added)
	- This combined should make running any filestolen code completely impossible, since not only
	  is all SV code missing, but the clientside code is unstructured and full of hardcoded strings
	  specific to a single client on a single server for a single session

Cleanup:
	[ ] Finish every -- TODO: flag not covered in another point
	[ ] Finish every -- DOCUMENT: flag and create a small documentation file for hooks


Feedback:
	technical issues aside
	the gameplay issues are
		- defense is lackluster at best
		- midgame is afk simulator
		- endgame is mediaplayer simulator
