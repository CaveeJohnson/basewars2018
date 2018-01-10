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

BUGS / NEEDS DOING:
	[X] Playervars need support for Doubles / string numbers
	[X] Players get stuck in cloner if y % 90 ~= 0 and other situations
	[X] extension 'core.money-distributer' hook 'BW_DistributeSaleMoney' failed: gamemodes/basewars2018/gamemode/core/server/money_distributer.lua:59: attempting to load data before player database init
	[X] distributer -> distributor
	[X] Factions and raids lose all data on reload, by nature they cannot recover it so it must be stored elsewhere
	[ ] Core area count/ents includes non-encompassed / non-owned entities (cant sell if someone puts shit nearby)
	[X] Optimize entity netvars (localize method names to avoid concat, move branching outside of functions, should allow for JIT)
	[#] Stuff to optimize on SV https://b.catgirlsare.sexy/GuGY.png related to below V
	[#] Make generic 'entity tracker' system for extensions
		- ext:addEntityTracker("tbl", "tbl_count", "wantEntity")
		- This code is cloned throughout the code base in an optimization effort
		- Will make it easier to implement custom entity lists, hence making optimization easier moving forward
	[X] Replace hardcoded £ with basewars.currency(num)
	[X] Unify name style (BaseWars, Basewars2018, etc)

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
	[ ] Drug/buff system
	[ ] Faction system
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
	[ ] Admin mod
		- full cami support

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

Cleanup:
	[ ] Finish every -- TODO: flag not covered in another point
	[ ] Finish every -- DOCUMENT: flag and create a small documentation file for hooks


Feedback:
	technical issues aside
	the gameplay issues are
		- defense is lackluster at best
		- midgame is afk simulator
		- endgame is mediaplayer simulator
