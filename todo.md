-- Overall notes:
	- Gameplay of bw15 was bloody obnoxious, the main redeeming features were stuff like mediaplayers
	- GUI is gone, so is stuff like raids on the HUD, make as much responsive in a 3d environment as possible

ENTITIES:
	[X] Passive Generator
	[ ] Active Generator
	[ ] Printer
	[ ] Turret
	[ ] Spawnpoint
	[X] Core
	[X] Core Control Panel
	[ ] Radar
	[ ] Health Dispenser
	[ ] Armor Dispenser
	[ ] Ammo Dispenser
	[ ] Energy Field Generator


Fixes:
	[#] Cores dont handle players disconnecting, nothing does really
	[ ] Area tolerence causes overlaps, currently disabled
	[ ] Hands dont autoselect, maybe needs a 1 tick delay
	[ ] Playervars need support for Doubles / string numbers
	[ ] Control panel works on literaly any entity, check if the entitiy is encompassed


Weekend: Done
	[X] Entity damage
	[X] Remove downsyndrome from interaction hud
	[X] Fill control panel entity list (network valid attachable stuff)
		- also related to ownership of entities
	[X] Make 'protected' forcefield also on core and nicer material
	[X] Sounds for entity attached/detached from network
	[X] Entity levels
	[X] Entity upgrades
	[#] Hooks for everything so far
	[X] Core raid alert effect
	[X] Make protection field less redundant and nicer looking

Mon: Done
	[X] TOP PRIORITY: Disable spawning of bloody everything, noclip, etc
	[X] TOP PRIORITY: Block driving
	[X] Package anticrash with gamemode
	[#] Decrap base gamemode stuff and profile
	[X] Deflect / anti damage in area for props
	[#] Anti-spawning and moving for core area
	[X] Core ownership

Tues: Done
	[X] Indicate much more distinctively if the core is active
	[X] Core sound sequences
	[X] Make interaction HUD have a method of 'canuse'
	[X] Add hands

Wed: Done
	[X] Join notification warning about lack of css
	[X] Warn server about lack of CSS
	[X] Loader for all folders / files
	[X] Credits

Thurs: Done
	[X] Player info system
	[X] Money system
	[X] XP / Level system
	[X] Destroyable props

Fri: Done
	[X] Visuals for the prop destruction
	[X] Raid system backend
	[X] Cores dont transmit area when rejoining

Sat:
	[ ] Raid system frontend

[ ] Faction system
[ ] Entity purchasing system
[ ] Chat / Command system
[ ] Add some basic entity which CONSUMES power and test if its :isPowered method is right
[ ] Language system
[#] Config system which allows overrides but doesn't force everything into 1 massive file
	- Allows for people to change entity variables without breaking forward compat
[ ] Finish every -- TODO: flag not covered in another point
[ ] Finish every -- DOCUMENT: flag and create a small documentation file for hooks

[ ] Packing system
[ ] Entity destruct effect (explosion for damage is done, but selling / packing should have its own method)
[ ] Add cam protection system, and console commands for gui\_cleanup and cam\_reset
