# Prop Hunt: X2Z - Weapon Loadout Manager
## Loadout & Ammo Editor for PH:X2Z

**BETA VERSION, Only works on Latest PH:X2Z Revision 17.01.24+!!**  
It does nothing on previous revision/version or any Prop Hunt that non X2Z version!

Weapon Loadout Manager & Ammo Editor for Prop Hunt: X2Z.
Allows you to modify Hunter's Loadout with any weapons you like.

Only works when gamemode is running, doesn't actually modify original ammo in the sandbox or any other gamemode. Fully Isolated.

## Features
- Loadout Editor
- Ammo Editor: Allow adds/set ammo when given so they're not 0 once equipped by player
- ULX support for quick access (Admin only)
- Keep/Unkeep Default PH:X2Z Loadout (Crowbar, 357, SMG, Shotgun)
- many more...

## Work in Progress/Future Addition
These are Work in Progress, See development progress at my [Ko-Fi page](http://ko-fi.com/wolvindra)
- Random Loadout
- Quick Access: Right Click on Weapon/Loadout -> Edit Ammo
- Updated UI?


## Links

- Discord: https://discord.gg/avaTPM7
- Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3141486825
- Donate: [Ko-Fi](http://ko-fi.com/wolvindra) or [buy me a coffee](https://www.buymeacoffee.com/wolvindra)


## Known Issues & Some Notes
- Ammo Editor: All weapons will share similar ammo types when equipped by a player.  
So if any weapons uses same ammo it will doubled if using `Add/Give Ammo`, However using `Set Ammo` will also Set other weapon ammo as well.
- This doesn't work if you use any "`give` weapon" command. This will only occurs when Hunter's blindfold time has over! (Including ammo)
- Unkeeping default loadout for SMG will also remove ability to add SMG grenade, Use ammo editor to edit your ammo (You'll have to disable/enable `ph_give_grenade_near_roundend` and `ph_give_grenade_roundend_before_time` if you want to receive/exclude additional SMG grenade ammo)


## ConVars or Settings

- `phx_wepmgr_enable (def: 1)`: Enable PH:X2Z Weapon Manager & Ammo Editor
- `phx_wepmgr_giveammo (def: 1)`: Give/Set ammo once Weapon was equipped when Hunter's Blind Time is Over (this to prevent ammo reserve being 0 when equipped, you need to modify ammo in PH:X2Z Ammo Editor)
- `phx_wepmgr_setammo_instead (def: 1)`: Set Ammo instead of Giving Ammo, default is "Set" (Warning: using "Give Ammo" means Doubles the number of ammo you give from Ammo Editor and weapons will also share simillar ammo types will also get doubled!)
- `phx_wepmgr_keep_default (def: 1)`: Keep Prop Hunt: X2Z Default Loadouts (Crowbar, Python, SMG, Shotgun), otherwise remove. Removing Default Loadouts but no Custom Loadouts were added will falling back to the Default Loadouts itself!
- `phx_wepmgr_add_ws (def: 0)`: [Require Map Restart] Allow any Weapon workshop addon to be available for download, if possible.\nThis will allow clients to download any installed weapon addons on this server. (Experimental)