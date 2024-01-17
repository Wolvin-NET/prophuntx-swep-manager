WepMgr.WeaponList = WepMgr.WeaponList or {}
WepMgr.SwepMod 	= WepMgr.SwepMod or {}
WepMgr.Loadout = {}
--WepMgr.RandLoadout = {}
WepMgr._VERSION = "1.0"

function util.FallbackVGUI( smat )
	local mat = "vgui/entities/error"
	smat:lower()

	if file.Exists( "materials/" .. smat .. ".vmt", "GAME" ) or file.Exists( "materials/" .. smat, "GAME" ) then
		mat = smat
	else
		mat = smat:Replace( "vgui/entities/", "entities/" )
		mat = mat..".png"
	end

	return mat
end

local fcvar = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}
local cvar = {
	{ CTYPE_BOOL, 	"phx_wepmgr_enable",	"1", fcvar, "Enable PH:X2Z Weapon Manager & Ammo Editor", {min=0,max=1} },

	{ CTYPE_BOOL,	"phx_wepmgr_giveammo", 	 "1", fcvar, "Allow give ammo after loadout was given (to prevent ammo reserve being 0)", {min=0,max=1} },
	{ CTYPE_BOOL,	"phx_wepmgr_setammo_instead", "1", fcvar, "Set Ammo instead of Giving Ammo (Adding ammo will adds twice as much, use caution!)", {min=0,max=1} },
	{ CTYPE_BOOL,	"phx_wepmgr_keep_default",	 "1", fcvar, "Keep Prop Hunt: X2Z Default Loadouts (Crowbar, Python, SMG, Shotgun)", {min=0,max=1} },

	{ CTYPE_BOOL,	"phx_wepmgr_add_ws",		"0", fcvar, "[Require Map Restart] Allow any Weapon workshop addon to be available for download, if possible.\nThis will allow clients to download any installed weapon addons on this server.", {min=0,max=1} },

	--{ CTYPE_BOOL,	"phx_swep_rand_loadout",	  "0", fcvar, "Use Random Set of Loadouts", {min=0,max=1} },
	--{ CTYPE_BOOL,	"phx_swep_rand_every_player", "0", fcvar, "Should every player has different loadout individually or not?", {min=0,max=1} },
}
for _,cv in ipairs(cvar) do PHX:AddCVar( unpack(cv) ) end
WepMgr.Blacklisted={
	["weapon_base"] 		= true,
	["weapon_lps"] 			= true,
	["weapon_medkit"] 		= true,
	["weapon_flechettegun"] = true,
}

function WepMgr:GetTable() return self.SwepMod; end
function WepMgr:Reset() self.SwepMod = {}; end
function WepMgr:Add(name,data) self.SwepMod[name] = data; end
function WepMgr:Remove(name) self.SwepMod[name] = nil; end

-- Loadout
function WepMgr:SimpleLoadout(data)
	self.Loadout = data
end
--[[ function WepMgr:RandLoadout(data)
	self.RandLoadout = data
end ]]

function WepMgr:GetWeaponTable()

	-- Usually caused by LUA Refresh, do not replace the data when it get refreshed
	if (self.WeaponList) and !table.IsEmpty( self.WeaponList ) then return end

	-- init
	self.WeaponList = {}
	
	local swepList 	= weapons.GetList()
	
	for _,wep in ipairs(swepList) do
		local copy = {
			class 		= "weapon_base",
			name		= "UNKNOWN SWEP",
			--model		= "models/weapons/w_pistol.mdl",
			category	= "Other",
			ammo1id		= 0,	-- SWEP.Primary.Ammo
			ammo1clip	= -1,	-- SWEP.Primary.ClipSize
			ammo1mag	= -1,	-- SWEP.Primary.DefaultClip
			ammo2id		= 0,	-- SWEP.Secondary.Ammo 
			ammo2clip	= -1,	-- SWEP.Secondary.ClipSize
			ammo2mag	= -1	-- SWEP.Secondary.DefaultClip
		}
		
		if (self.Blacklisted[wep.ClassName]) then continue end
		if string.find(wep.ClassName, "base") or string.find(wep.ClassName, "share") then
			self.Blacklisted[wep.ClassName] = true
			continue
		end
		
		copy.class 	= wep.ClassName
		if wep.PrintName then copy.name = wep.PrintName; else copy.name = wep.ClassName; end
		if wep.Category then copy.category = wep.Category; end
		
		-- Primary
		if wep.Primary.Ammo then
			if isstring(wep.Primary.Ammo) then
				copy.ammo1id 	= game.GetAmmoID( wep.Primary.Ammo )
			else
				copy.ammo1id 	= wep.Primary.Ammo
			end
		end
		if wep.Primary.ClipSize then copy.ammo1clip	= wep.Primary.ClipSize end
		if wep.Primary.DefaultClip then copy.ammo1mag = wep.Primary.DefaultClip end
		
		-- Secondary
		if wep.Secondary.Ammo then
			if isstring(wep.Secondary.Ammo) then
				copy.ammo2id 	= game.GetAmmoID( wep.Secondary.Ammo )
			else
				copy.ammo2id 	= wep.Secondary.Ammo
			end
		end
		if wep.Secondary.ClipSize then copy.ammo2clip 	= wep.Secondary.ClipSize end
		if wep.Secondary.DefaultClip then copy.ammo2mag	= wep.Secondary.DefaultClip end
		
		self.WeaponList[wep.ClassName] = copy
	end
	
end

hook.Add("OnReloaded", "WepMgr.LuaRefresh", function() 
	print("WepMgr->OnReload - Refreshing Weapon Data")
	WepMgr:GetWeaponTable()

	if CLIENT then
		net.Start("wepmgr.__reqinitdata")
		net.SendToServer()
	end
end)

if CLIENT then
	hook.Add("InitPostEntity", "WepMgr.InitialRequestInfo", function()
		-- Init WeaponTable.
		WepMgr:GetWeaponTable()

		net.Start("wepmgr.__reqinitdata")
		net.SendToServer()
	end)

	local ADDON_INFO = {
		name	= "Weapon Manager",
		version	= WepMgr._VERSION,
		info	= "Allow modify default weapon spawn for Hunters",
		
		settings = {
			{"", "label", false, "Editor" },
			{"", "btn", {
				[1] = {
					"Open Ammo Editor", function()
						if LocalPlayer():PHXIsStaff() or LocalPlayer():IsSuperAdmin() then
							
							if PHX:GetCVar("phx_wepmgr_enable") then
								WepMgr:openAmmoEditor()
							else
								Derma_Message(
								"Weapon Manager is disabled! If you'd like to enable this feature, please set the ConVar: 'phx_wepmgr_enable 1' !",
								"Warning",
								"OK"
								)
							end
							
						end
					end
				},
				[2] = {
					"Open Weapon Manager", function()
						if LocalPlayer():PHXIsStaff() or LocalPlayer():IsSuperAdmin() then
							
							if PHX:GetCVar("phx_wepmgr_enable") then
								WepMgr:openWeaponManager()
							else
								Derma_Message(
								"Weapon Manager is disabled! If you'd like to enable this feature, please set the ConVar: 'phx_wepmgr_enable 1' !",
								"Warning",
								"OK"
								)
							end
							
						end
					end
				}
			}, "" },
		
			{"", "label", false, "Weapon Manager Settings" },
			
			{"phx_wepmgr_enable", "check", "SERVER", "Enable 'Weapon Manager' feature"},
			{"phx_wepmgr_giveammo", "check", "SERVER", "Allow modify weapon ammo (Needed to prevent ammo being 0 on spawn/give)" },
			{"phx_wepmgr_setammo_instead","check", "SERVER", "Set Ammo instead of Adding Ammo (Adding ammo will adds twice as much)" },
			{"phx_wepmgr_keep_default", "check", "SERVER", "Keep Prop Hunt: X2Z Default Weapon Loadouts (Crowbar,357,SMG,Shotgun)" },

			{"phx_wepmgr_add_ws",	"check", "SERVER", "[*Require Map Restart] Allow any Weapon workshop addon to be available for download, if possible.\nThis will allow clients to download any installed weapon addons on this server."}
		},
		
		client	= {}
	}
	list.Set("PHX.Plugins", ADDON_INFO.name, ADDON_INFO)
end

-- ULX
local CATEGORY_NAME = PHX.TITLE

local function WeaponManager( calling_ply )
	calling_ply:SendLua(" WepMgr:openWeaponManager()")
end
if (!ulx or ulx == nil) then
	print("[WepMgr:ULX] WARNING: ULX is not installed! Not going to add ulx phwepmanager ...")
else
	local cmd = ulx.command( CATEGORY_NAME, "ulx phwepmanager", WeaponManager, "!phwepmanager" )
	cmd:defaultAccess( ULib.ACCESS_SUPERADMIN ) --Default is Super Amin
	cmd:help( "Open PH:X2Z Weapon Manager" )
end

local function AmmoEditor( calling_ply )
	calling_ply:SendLua(" WepMgr:openAmmoEditor()")
end
if (!ulx or ulx == nil) then
	print("[WepMgr:ULX] WARNING: ULX is not installed! Not going to add ulx phammoeditor ...")
else
	local cmd = ulx.command( CATEGORY_NAME, "ulx phammoeditor", AmmoEditor, "!phammoeditor" )
	cmd:defaultAccess( ULib.ACCESS_SUPERADMIN ) --Default is Super Amin
	cmd:help( "Open PH:X2Z Ammo Editor" )
end