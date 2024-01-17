-- never use AmmoID -1. use "0" instead.

WepMgr.DefSweps = {}
local hl2 = "Half-Life 2"

WepMgr.DefSweps["weapon_crowbar"] = {
	class 		= "weapon_crowbar",
	name		= "Crowbar",
	model		= "models/weapons/w_crowbar.mdl",
	category    = hl2,
	ammo1id		= 0,
	ammo1clip	= -1,
	ammo1mag	= -1,
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1
}

WepMgr.DefSweps["weapon_stunstick"] = {
	class 		= "weapon_stunstick",
	name		= "Stun Baton",
	model		= "models/weapons/w_stunbaton.mdl",
	category    = hl2,
	ammo1id		= 0,
	ammo1clip	= -1,
	ammo1mag	= -1,
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1
}

WepMgr.DefSweps["weapon_pistol"] = {
	class 		= "weapon_pistol",
	name		= "HL2 Pistol",
	model		= "models/weapons/w_pistol.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("Pistol"),
	ammo1clip	= 15,
	ammo1mag	= tonumber(GetConVar("sk_max_pistol"):GetInt()),
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1
}

WepMgr.DefSweps["weapon_357"] = {
	class 		= "weapon_357",
	name		= "HL2 357",
	model		= "models/weapons/w_357.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("357"),
	ammo1clip	= 6,
	ammo1mag	= tonumber(GetConVar("sk_max_357"):GetInt()),
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1
}

WepMgr.DefSweps["weapon_smg1"] = {
	class 		= "weapon_smg1",
	name		= "HL2 Sub Machine Gun (SMG1)",
	model		= "models/weapons/w_smg1.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("SMG1"),
	ammo1clip	= 45,
	ammo1mag	= tonumber(GetConVar("sk_max_smg1"):GetInt()),
	ammo2id		= game.GetAmmoID("SMG1_Grenade"),
	ammo2clip	= -1,
	ammo2mag	= tonumber(GetConVar("sk_max_smg1_grenade"):GetInt())
}

WepMgr.DefSweps["weapon_ar2"] = {
	class 		= "weapon_ar2",
	name		= "HL2 Pulse Rifle (AR2)",
	model		= "models/weapons/w_irifle.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("AR2"),
	ammo1clip	= 30,
	ammo1mag	= tonumber(GetConVar("sk_max_ar2"):GetInt()),
	ammo2id		= game.GetAmmoID("AR2AltFire"),
	ammo2clip	= -1,
	ammo2mag	= tonumber(GetConVar("sk_max_ar2_altfire"):GetInt())
}

WepMgr.DefSweps["weapon_shotgun"] = {
	class 		= "weapon_shotgun",
	name		= "HL2 Shotgun",
	model		= "models/weapons/w_shotgun.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("Buckshot"),
	ammo1clip	= 6,
	ammo1mag	= tonumber(GetConVar("sk_max_buckshot"):GetInt()),
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1
}

WepMgr.DefSweps["weapon_crossbow"] = {
	class 		= "weapon_crossbow",
	name		= "HL2 Crossbow",
	model		= "models/weapons/w_crossbow.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("XBowBolt"),
	ammo1clip	= 1,
	ammo1mag	= tonumber(GetConVar("sk_max_crossbow"):GetInt()),
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1,
}

WepMgr.DefSweps["weapon_rpg"] = {
	class 		= "weapon_rpg",
	name		= "HL2 RPG",
	model		= "models/weapons/w_rocket_launcher.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("RPG_Round"),
	ammo1clip	= 0,	-- it's actually -1 but we'll render it as 1 ammo. It uses Ammo, not clip!
	ammo1mag	= tonumber(GetConVar("sk_max_rpg_round"):GetInt()),	-- it's actually -1 but we'll render it as 1 ammo. It uses Ammo, not clip!
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1,
}

WepMgr.DefSweps["weapon_frag"] = {
	class 		= "weapon_frag",
	name		= "HL2 Frag Grenade",
	model		= "models/weapons/w_grenade.mdl",
	category    = hl2,
	ammo1id		= game.GetAmmoID("Grenade"),
	ammo1clip	= 0,	-- it's actually -1 but we'll render it as 1 ammo. It uses Ammo, not clip!
	ammo1mag	= tonumber(GetConVar("sk_max_grenade"):GetInt()),	-- it's actually -1 but we'll render it as 1 ammo. It uses Ammo, not clip!
	ammo2id		= 0,
	ammo2clip	= -1,
	ammo2mag	= -1,
}

WepMgr.DefSweps["weapon_slam"] = {
	class 		= "weapon_slam",
	name		= "HL2 S.L.A.M",
	model		= "models/weapons/w_slam.mdl",
	category    = hl2,
	ammo1id		= 0,
	ammo1clip	= -1,
	ammo1mag	= -1,
	ammo2id		= game.GetAmmoID("slam"),
	ammo2clip	= 0,
	ammo2mag	= 3,
}