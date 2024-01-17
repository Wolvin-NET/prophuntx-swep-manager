local netlist = {
	"wepmgr.__reqinitdata", --cl req
	"wepmgr.AmmoData",	--cl ammo & loadout
	"wepmgr.WeaponData",

	"wepmgr.UpdateLoadout", --cl->sv
	"wepmgr.UpdateAmmoData", --sv->cl
	"wepmgr.InformState", --ammo: status(if window still open)
	
	"wepmgr.UpdateModdedAmmo", --broadcast
	"wepmgr.UpdateModdedLoadout",

	-- Dangerous part: Reset Ammo data
	"wepmgr.RestoreAllAmmoDefault", --Entire WepMgr.SwepMod
	"wepmgr.RestoreIndivAmmoData", --Individual
}
for _,v in ipairs(netlist) do util.AddNetworkString(v) end

local addons = engine.GetAddons()
WepMgr._WeaponWS = WepMgr._WeaponWS or {}

local function getWeaponAddons()
	for _,wsdata in ipairs(addons) do
		local wsid = tostring(wsdata.wsid)
		local tags = tostring(wsdata.tags)
		local enabled = tobool(wsdata.mounted)

		if (tags) and isstring(tags) and tags ~= "" then
			tags = tags:lower()
			if (string.find( tags, "weapon" )) then
				WepMgr._WeaponWS[wsid] = { enabled, wsdata.title }
			end
		end

	end
end

-- This is Experimental, can't guarantee this will work 100%!
function WepMgr:AddWeaponWorkshop()
	if PHX:QCVar( "phx_wepmgr_add_ws" ) then
		getWeaponAddons()
		if istable(self._WeaponWS) and table.IsEmpty( self._WeaponWS ) then
			print("[WepMgr] No Weapon Workshop addons to be found, skipping...!")
		else
			for wsid,data in pairs( self._WeaponWS ) do
				local enabled=data[1]
				local title=data[2]
				if (enabled) then
					print( "[WepMgr:AddWorkshop] Adding Weapon Workshop: '"..title.."' (ID: "..wsid..")" )
					resource.AddWorkshop( wsid )
				else
					print( "[WepMgr:AddWorkshop] Trying to add Weapon Workshop: '"..title.."' (ID: "..wsid..") but it's not mounted!" )
				end
			end
		end

	end
end

local function wepmgr_isstaff(ply)
	if ply:PHXIsStaff() or ply:IsSuperAdmin() then return true; end
	return false
end
WepMgr.wepmod  = {_data = nil,_size = 0}
WepMgr.wepdata = {_data = nil,_size = 0}

function WepMgr:CompAmmoData()
	self.wepmod._data,self.wepmod._size = util.PHXQuickCompress( self.SwepMod )
end
function WepMgr:CompWepData()
	self.wepdata._data,self.wepdata._size = util.PHXQuickCompress( self.Loadout )
end

local CONFIG_FOLDER=PHX.ConfigPath.."/swep_manager"
local AMMO_CONFIG=CONFIG_FOLDER.."/swepammoinfo.txt"
local LO_CONFIG  =CONFIG_FOLDER.."/loadoutinfo.txt"

function WepMgr:LoadDB()
	
	if !file.Exists(CONFIG_FOLDER,"DATA") then
		PHX:VerboseMsg("[WepMgr] creating default config path...")
		file.CreateDir(CONFIG_FOLDER)
		PHX:VerboseMsg("[WepMgr] successfully created: "..CONFIG_FOLDER)
	end
	
	-- Ammo Editor Info
	local config = AMMO_CONFIG
	
	if file.Exists(config,"DATA") then
		PHX:VerboseMsg("[WepMgr] reading ammo config file '" .. config .. "'...")
		
		local f = file.Read(config, "DATA")
		local read = util.JSONToTable(f) or {}
		
		if (read) and istable(read) and !table.IsEmpty(read) then
			self:Reset()
			for class,data in pairs(read) do
				self:Add( class, data )
			end
		end
	else
		PHX:VerboseMsg("[WepMgr] creating default ammo config file...")
		
		local temp = {
			["__dummyweapon__"] = {
				ammo1 = {
					amount = 2,
					ammoid = game.GetAmmoID("357")
				},
				ammo2 = {
					amount = 0,
					ammoid = 0
				}
			}
		}
		local json = util.TableToJSON(temp,true)
		file.Write(config, json)
		
		for class, data in pairs(temp) do
			self:Add(class, data)
		end
	end
	
	-- Weapon Loadout Info

	local config = LO_CONFIG
	
	if file.Exists(config,"DATA") then
		PHX:VerboseMsg("[WepMgr] reading loadout file '" .. config .. "'...")
		
		local f = file.Read(config, "DATA")
		local read = util.JSONToTable(f) or {}
		
		if (read) and istable(read) and !table.IsEmpty(read) then
			self:SimpleLoadout(read)
		end
	else
		PHX:VerboseMsg("[WepMgr] creating default loadout config file...")
		
		local json = util.TableToJSON({},true)
		file.Write(config, json)
	end

	self:CompAmmoData()
	self:CompWepData()

end

function WepMgr:sendmoddedtoadmin( ply )
	if !IsValid( ply ) then return end
	local name = ply:Nick()
	local AmmoSize,AmmoData = self.wepmod._size,self.wepmod._data
	local LoadSize,LoadData = self.wepdata._size,self.wepdata._data

	PHX:VerboseMsg("[WepMgr] Sending Ammo Data to "..name)
	net.Start("wepmgr.AmmoData")
		net.WriteUInt(AmmoSize, 16)
		net.WriteData(AmmoData, AmmoSize)
	net.Send(ply)
	PHX:VerboseMsg("[WepMgr] Sending Loadout Data to "..name)
	net.Start("wepmgr.WeaponData")
		net.WriteUInt(LoadSize, 16)
		net.WriteData(LoadData, LoadSize)
	net.Send(ply)
end
hook.Add("OnReloaded", "WepMgr.SVLuaRefresh", function() 
	print("WepMgr->OnReload [SERVER] - Reloading Database")
	WepMgr:LoadDB()
end)
hook.Add("Initialize", "WepMgr.PrepareWeaponInfo", function()	
	WepMgr:LoadDB()
	WepMgr:AddWeaponWorkshop()
end)

local function UpdateAmmoDB( strClass, id1, am, id2, am2, ply, bClear )
	local wmgr = WepMgr
	local updateBy = ""

	if isbool(strClass) and (strClass) then

		local ply = id1
		if (ply) and IsValid( ply ) then
			updateBy = "[WepMgr] Warning: All Ammo Information has RESTORED by "..ply:Nick().."(SteamID: " .. ply:SteamID() ..")"
		end

		-- clear all ammo data
		wmgr:Reset()

	else

		local Data = {
			ammo1 = {
				amount = am,
				ammoid = id1
			},
			ammo2 = {
				amount = am2,
				ammoid = id2
			}
		}
		print( "[WepMgr] DEBUG:", "Class: ".. strClass, "AmmoID 1: " .. id1, "Amount: "..am, "AmmoID 2: "..id2, "Ammount: "..am2 )
		updateBy = "[WepMgr] Ammo Information has Updated by "..ply:Nick().."(SteamID: " .. ply:SteamID() ..")"

		if (bClear) then
			wmgr:Add( strClass, nil ) --will it work?
		else
			wmgr:Add( strClass, Data )
		end

	end

	wmgr:CompAmmoData()
	
	local warn = ""
	
	if !file.Exists(CONFIG_FOLDER,"DATA") then
		warn = "[WepMgr] Error: Cannot save the weapon data because folder '"..CONFIG_FOLDER.."' do not exist!"
		if IsValid(ply) then ply:ChatPrint(warn) end
		print(warn)
	end
	
	local config = AMMO_CONFIG
	
	if file.Exists(config,"DATA") then
		PHX:VerboseMsg("[WepMgr] reading config file '" .. config .. "'...")
		
		local j = util.TableToJSON( wmgr.SwepMod, true )
		file.Write(config, j)
		
		if file.Exists(config,"DATA") and file.Size(config,"DATA") > 0 then
			PHX:VerboseMsg("[WepMgr] file '" .. config .. "' saved successfully.")
		else
			print("[WepMgr] file '" .. config .. "' contains 0 byte or missing. Something is causing error!")
		end
	else
		warn = "[WepMgr] Error: Cannot save the weapon data because configuration file is missing!"
		if IsValid(ply) then ply:ChatPrint(warn) end
		print(warn)
	end
	
	local AdminsOnly = {}
	for _,v in pairs(player.GetAll()) do
		if wepmgr_isstaff(v) then
			table.insert(AdminsOnly, v)
		end
	end
	
	local data,size = wmgr.wepmod._data,wmgr.wepmod._size

	net.Start("wepmgr.UpdateModdedAmmo")
		net.WriteUInt(size, 16)
		net.WriteData(data, size)
	net.Send( AdminsOnly )
	
	if IsValid(ply) then
		print( updateBy )
	end
end

local function UpdateLoadoutDB( t, ply )
	local wmgr = WepMgr

	wmgr.Loadout = t
	wmgr:CompWepData()
	
	local warn = ""
	
	if !file.Exists(CONFIG_FOLDER,"DATA") then
		warn = "[WepMgr] Error: Cannot save the weapon data because folder '"..CONFIG_FOLDER.."' do not exist!"
		if IsValid(ply) then ply:ChatPrint(warn) end
		print(warn)
	end
	
	local config = LO_CONFIG
	
	if file.Exists(config,"DATA") then
		PHX:VerboseMsg("[WepMgr] reading config file '" .. config .. "'...")
		
		local j = util.TableToJSON( wmgr.Loadout, true )
		file.Write(config, j)
		
		if file.Exists(config,"DATA") and file.Size(config,"DATA") > 0 then
			PHX:VerboseMsg("[WepMgr] file '" .. config .. "' saved successfully.")
		else
			print("[WepMgr] file '" .. config .. "' contains 0 byte or missing. Something is causing error!")
		end
	else
		warn = "[WepMgr] Error: Cannot save the weapon data because configuration file is missing!"
		if IsValid(ply) then ply:ChatPrint(warn) end
		print(warn)
	end
	
	local AdminsOnly = {}
	for _,v in pairs(player.GetAll()) do
		if wepmgr_isstaff(v) then
			table.insert(AdminsOnly, v)
		end
	end
	
	local data,size = wmgr.wepdata._data,wmgr.wepdata._size

	net.Start("wepmgr.UpdateModdedLoadout")
		net.WriteUInt(size, 16)
		net.WriteData(data, size)
	net.Send( AdminsOnly )
	
	if IsValid(ply) then
		print( "[WepMgr] Loadout has updated by: "..ply:Nick().."(SteamID: " .. ply:SteamID() ..")" )
	end
end

local function ModifyWeaponAmmo( ply, weapon )
	
	if IsValid(ply) and IsValid(weapon) then
	
		local tbl = WepMgr:GetTable()
		local class = weapon:GetClass()
		local UseSet = PHX:QCVar( "phx_wepmgr_setammo_instead" )
		
		if tbl[class] and tbl[class] ~= nil then
			local data = tbl[class]
			
			if data.ammo1 and data.ammo1 ~= nil and (data.ammo1.ammoid and data.ammo1.amount) and !weapon.HasPrimaryModded then
			  if (data.ammo1.ammoid > 0 and data.ammo1.amount > -1) then
				if (UseSet) then
					ply:SetAmmo(data.ammo1.amount, data.ammo1.ammoid)
				else
					ply:GiveAmmo(data.ammo1.amount, data.ammo1.ammoid)
				end
				weapon.HasPrimaryModded = true
			  end
			end
			
			if data.ammo2 and data.ammo2 ~= nil and (data.ammo2.ammoid and data.ammo2.amount) and !weapon.HasSecondaryModded then
			  if (data.ammo2.ammoid > 0 and data.ammo2.amount > -1) then
				if (UseSet) then
					ply:SetAmmo(data.ammo2.amount, data.ammo2.ammoid)
				else
					ply:GiveAmmo(data.ammo2.amount, data.ammo2.ammoid)
				end
				weapon.HasSecondaryModded = true
			  end
			end
		end
		
	end
	
end

-- Event Hooks: WeaponEquip.
-- https://wiki.facepunch.com/gmod/GM:WeaponEquip	
hook.Add( "WeaponEquip", "WepMgr.ChangeDefaultAmmo", function( weapon, ply )
	local Enable=PHX:QCVar( "phx_wepmgr_enable" )
	local AddAmmo=PHX:QCVar( "phx_wepmgr_giveammo" )

	if Enable and AddAmmo then
		timer.Simple(0, function()
			if ply:Alive() and ply:Team() == TEAM_HUNTERS then
				ModifyWeaponAmmo(ply, weapon)
			end
		end)
	end
end )

local CheckDefault={["weapon_crowbar"]=true,["weapon_shotgun"]=true,["weapon_smg1"]=true,["weapon_357"]=true}
hook.Add("PH_OnHunterLoadOut", "WepMgr.HunterLoadout", function(ply)
	local Enable=PHX:QCVar( "phx_wepmgr_enable" )
	if Enable then
		if !ply:Alive() then return end

		local Blacklist = WepMgr.Blacklisted
		local override = !PHX:QCVar( "phx_wepmgr_keep_default" ) and true or false

		--print("OVERRIDE:", override)

		if override and istable(WepMgr.Loadout) and table.IsEmpty(WepMgr.Loadout) then
			print("[PH:X Weapon Manager] Error: Loadout is Empty but 'keep default PH:X2Z loadout' is OFF! Falling Back to PH:X2Z Default Loadouts.")
			return false
		end

		for _,class in pairs( WepMgr.Loadout ) do
			if Blacklist[ class ] then
				print("[PH:X Weapon Manager] Attempted to spawn blacklisted weapon: "..class.." ignoring!")
				continue
			end
			if !override and CheckDefault[class] then continue end --silently fails if default loadout was found in Loadout table

			if !ply:HasWeapon( class ) then
				local wep = ply:Give( class )
				if !IsValid( wep ) then
					local Err="Error Spawning Weapon ["..class.."]: Invalid or does not exists!"
					print("[PH:X Weapon Manager] "..Err)
					ply:ChatPrint(Err)
				end
			end
		end

		return override
	end
end)

net.Receive("wepmgr.__reqinitdata", function(len, ply)
	if wepmgr_isstaff(ply) then
		WepMgr:sendmoddedtoadmin( ply )
	end
end)

-- for Ammo Editor
local function UpdateState( ply, isFail, strMsg )
	net.Start("wepmgr.InformState")
	net.WriteBool( tobool(isFail) and true or false )
	net.WriteString(strMsg)
	net.Send(ply)
end

net.Receive("wepmgr.RestoreIndivAmmoData", function(len,ply)
	if wepmgr_isstaff(ply) then
		local class = net.ReadString()

		if !class or class == "" then
			UpdateState(ply, true, "entity class name is empty or invalid")
			return
		end

		UpdateAmmoDB(class, 0, 0, 0, 0, ply, true)
		UpdateState(ply, false, "weapon '" .. class .. "' has been restored to default")
	end
end)

net.Receive("wepmgr.RestoreAllAmmoDefault", function(len,ply)
	if wepmgr_isstaff(ply) then
		UpdateAmmoDB(true, ply)
		UpdateState(ply, false, "All ammo has been restored to default")
	end
end)

net.Receive("wepmgr.UpdateAmmoData", function(len, ply)
	if wepmgr_isstaff(ply) then
		local class = net.ReadString()
		local size = net.ReadUInt(9)
		local data = net.ReadData(size)
		
		local t = util.PHXQuickDecompress( data )
		ammoid = t.ammo1id
		ammoid2 = t.ammo2id
		
		if !class or class == "" then
			UpdateState(ply, true, "entity class name is empty or invalid")
			return
		end
		
		if !t or istable(t) and table.IsEmpty(t) then
			UpdateState(ply, true, "weapon table data is empty or invalid")
			return
		end
		
		-- Empty Primary AmmoID should be rejected, unless it has Secondary Ammo that present.
		if !ammoid and !ammoid2 then
			UpdateState(ply, true, "primary and secondary ammo id is empty or invalid")
			return
		end
		
		if (ammoid < 0) and (ammoid2 < 0) then
			UpdateState(ply, true, "no ammo detected on '".. class.."', maybe this weapon was supposed to be a melee or unlimited ammo.")
			return
		end
		
		UpdateAmmoDB(class, ammoid, t.ammo1, ammoid2, t.ammo2, ply)
		UpdateState(ply, false, "weapon '" .. class .. "' has been updated successfully")
		
	end
end)

net.Receive("wepmgr.UpdateLoadout", function(len,ply)
    local size = net.ReadUInt(16)
    local data = net.ReadData(size)

	local t = util.PHXQuickDecompress(data)

	if (t) and istable(t) then
		if table.IsEmpty(t) then
			ply:ChatPrint("[WepMgr] Loadout has been reset")
			print("[WepMgr] Saving with no loadout data, possibly intention for reset!")
		end
		UpdateLoadoutDB( t, ply )
	end
end)