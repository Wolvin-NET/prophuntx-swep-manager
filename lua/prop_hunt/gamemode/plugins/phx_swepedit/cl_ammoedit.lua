surface.CreateFont("swepEdit.StatusMsg", {
	font	= "Roboto",
	size	= 16,
	weight	= 600
})

local f = {}
f.panel_color_dark = Color( 46,44,44)
f.statusCode = {
	["generic"] = Color(230,230,230,255),
	["warning"]	= Color(250,120,  6,255),
	["good"]	= Color( 34,200, 76,255),
	["error"]	= Color(255,128,169,255),
	["info"]	= Color(  0,210,210,255)
}

local function isstaff( ply )
    if ply:PHXIsStaff() or ply:IsSuperAdmin() then return true; end
    return false
end

local function SndCmd( cv, val )
    local ply = LocalPlayer()
    if isstaff(ply) then
        net.Start("SvCommandReq")
            net.WriteString(cv)
            net.WriteString(tostring(val))
        net.SendToServer()
    end
end

f.MenuList = {
    ["Options"]	= {
		["Give/Set Ammo when Equip a weapon"] = { f = function()
			local cv = "phx_wepmgr_giveammo"
            SndCmd( cv, !GetConVar(cv):GetBool() and "1" or "0" )
        end, icon = function( menu ) 
            menu:SetIsCheckable(true)
            menu:SetChecked( GetConVar("phx_wepmgr_giveammo"):GetBool() )
        end },
		["'Set' Ammo instead of 'Give'"] = { f = function()
			local cv = "phx_wepmgr_setammo_instead"
            SndCmd( cv, !GetConVar(cv):GetBool() and "1" or "0" )
        end, icon = function( menu ) 
            menu:SetIsCheckable(true)
            menu:SetChecked( GetConVar("phx_wepmgr_setammo_instead"):GetBool() )
        end }
	},
	["Data"]	= {
        ["Restore to default"] = { f = function( fpanel )
            Derma_Query("Are you sure you want to restore everything to default?", "Warning",
                "Yes", function()
                    net.Start("wepmgr.RestoreAllAmmoDefault")
					net.SendToServer()
					if (fpanel) and (fpanel.isOpen) then
						fpanel:WindowState(false)
						fpanel:SetBtnState(false)
						fpanel:UpdateStatus("Restoring Everything back to default...","warning")
					end
                end, 
                "No", function() end)
        end, icon = "icon16/cross.png", NeedFramePanel = true },
	},
}

function WepMgr:swepAmmoEditor()

	local ply = LocalPlayer()

	if (not ply:PHXIsStaff()) or (not ply:IsSuperAdmin()) then
		chat.AddText(Color(220,40,40), "You have no rights to access this feature!")
		return
	end
	
	if (not PHX:GetCVar("phx_wepmgr_enable")) then
		chat.AddText(Color(220,40,40), "Swep Ammo Editor is disabled. Enable this feature under Plugins menu!")
		return
	end

	f.isOpen = true
	f.SelectedItem = {}
	
	f.frame = vgui.Create("DFrame")
	f.frame:SetSize(1024, 750)
	f.frame:SetTitle( "Prop Hunt: X2Z - Ammo Editor" )
	f.frame:SetVisible(true)
	f.frame:ShowCloseButton(true)
	f.frame:Center()
	
	f.frame.OnClose = function()
		f.isOpen = false
		f.SelectedItem = {}
	end

	f.menuBar = vgui.Create("DMenuBar", f.frame)
	f.menuBar:DockMargin(-3,-6,-3,0)
	
	for topMenu,ListSubMenu in SortedPairs(f.MenuList) do
		local H = f.menuBar:AddMenu( topMenu )
		for subMenu,Data in SortedPairs(ListSubMenu) do
			local S
			if (Data.NeedFramePanel) then
				S = H:AddOption( subMenu, function() Data.f(f) end )
			else
				S = H:AddOption( subMenu, Data.f )
			end

			if (S) and Data.icon then 
				if isfunction(Data.icon) then
					Data.icon(S)
				else
					S:SetIcon(Data.icon)
				end
			end
		end
	end
	
	f.mainpanel = vgui.Create("DPanel", f.frame)
	f.mainpanel:Dock(FILL)
	f.mainpanel:SetBackgroundColor(Color(0,0,0,0))
	
	f.statusbar = vgui.Create("DPanel", f.frame)
	f.statusbar:Dock(BOTTOM)
	f.statusbar:DockMargin(0,3,0,0)
	f.statusbar:SetSize(0,24)
	f.statusbar:SetBackgroundColor(Color(96,96,96,220))
	
	f.labelStatus = vgui.Create("DLabel", f.statusbar)
	f.labelStatus:Dock(FILL)
	f.labelStatus:DockMargin(5,2,2.5,2)
	f.labelStatus:SetFont("swepEdit.StatusMsg")
	f.labelStatus:SetText("Status: Ready.")
	f.labelStatus:SetTextColor(f.statusCode["generic"])
	
	function f.UpdateStatus(me, str, colorcode)
		if !str or str == nil or str == "" then str = "Ready." end
		if !colorcode or colorcode == nil or colorcode == "" then colorcode = "generic" end
		me.labelStatus:SetText( "Status: " .. str )
		me.labelStatus:SetTextColor( me.statusCode[ colorcode ] )
	end
	
	f.mainpanel:InvalidateParent(true)
	
	f.list = vgui.Create("DListView", f.mainpanel)
	f.list:SetMultiSelect(false)
	f.list:AddColumn("Name",  1)
	f.list:AddColumn("Class", 2)
	f.list:AddColumn("Category", 3)
	f.list:AddColumn("Mod Ammo (Prim/Sec)", 4)
	
	f.list:Dock(LEFT)
	f.list:SetSize( f.mainpanel:GetWide()*0.6, 0 )
	
	--f.list:SetDataHeight(24) -- 17, default
	
	local function dotheloop( weapontable, modtable, listPanel )
	
		for class,data in SortedPairs( weapontable ) do
		
			local mod = modtable[class]
			local primsec = "-"
			if mod and mod ~= nil then
				primsec = mod.ammo1.amount .. " / " .. mod.ammo2.amount
			end
			
			local p = listPanel:AddLine(data.name, data.class, data.category, primsec)
			if mod and mod ~= nil then
				p.data = {
					class 	 = class,
					wepinfo  = data,
					ammoinfo = mod
				}
			else
				p.data = {
					class 	 = class,
					wepinfo  = data,
					ammoinfo = nil
				}
			end
			
		end
	
	end
	
	f.UpdateList = function()
		f.list:Clear()
		-- List HL2 Weapons
		dotheloop( self.DefSweps, self.SwepMod, f.list )
		-- List all weapons
		dotheloop( self.WeaponList, self.SwepMod, f.list )
		-- Sort
		f.list:SortByColumn(3)
	end
	
	f.UpdateList()
	
	function f:WindowState( bool )
		bool = tobool(bool)
		self.frame:ShowCloseButton(bool)
		self.list:SetEnabled(bool)
	end
	
	f.list:SelectFirstItem()
	
	f.pan = vgui.Create("DPanel", f.mainpanel)
	f.pan:Dock(FILL)
	f.pan:DockMargin(2,0,0,5)
	f.pan:SetBackgroundColor(Color(96,96,96,255))
	
	f.pnImage = vgui.Create("DPanel", f.mainpanel)
	f.pnImage:Dock(TOP)
	f.pnImage:SetTall(256)
	f.pnImage:SetBackgroundColor(f.panel_color_dark)
	f.pnImage:InvalidateParent(true)

	f.model = vgui.Create("DImage", f.pnImage)
	f.model:SetPos(f.pnImage:GetWide()*0.5-125,3)
	f.model:SetSize(250,250)
	f.model:SetImage( "vgui/wlv_wepmgr_unknown" )

	YFF_MODEL=f.model
	YFF_PAN=f.pnImage
	
	f.paninfo = vgui.Create("DPanel", f.pan)
	f.paninfo:Dock(FILL)
	f.paninfo:SetBackgroundColor(Color(60,60,60,255))
	
	f.label = vgui.Create("DListView", f.paninfo)
	f.label:Dock(FILL)
	f.label:DockMargin(10,10,10,10)
	
	f.label:SetMultiSelect(false)
	f.label:AddColumn("Property", 1)
	f.label:AddColumn("Value", 2)
	
	f.label:AddLine("Click an item on the left", "to start editing!")
	
	-- buttons
	
	f.panBtn = vgui.Create("DPanel", f.paninfo)
	f.panBtn:Dock(BOTTOM)
	f.panBtn:SetSize(0,30)
	f.panBtn:DockMargin(10,2.5,10,2.5)
	f.panBtn:SetBackgroundColor(Color(255,255,255,0))
	
	f.btnApply = vgui.Create("DButton", f.panBtn)
	f.btnApply:Dock(RIGHT)
	f.btnApply:DockMargin(2,1,2,0)
	f.btnApply:SetSize(100,0)
	f.btnApply:SetText("Apply")
	f.btnApply:SetEnabled(false)
	
	f.btnReset = vgui.Create("DButton", f.panBtn)
	f.btnReset:Dock(RIGHT)
	f.btnReset:DockMargin(2,1,2,1)
	f.btnReset:SetSize(100,0)
	f.btnReset:SetText("Reset")
	f.btnReset:SetEnabled(false)

	f.btnRestore = vgui.Create("DButton", f.panBtn)
	f.btnRestore:Dock(RIGHT)
	f.btnRestore:DockMargin(2,1,2,1)
	f.btnRestore:SetSize(120,0)
	f.btnRestore:SetText("Restore Default")
	f.btnRestore:SetEnabled(false)
	
	-- Primary
	
	local panelText = {
		p = {
			[0] = "Cannot modify this weapon! [Primary]",
			[1] = "Primary Ammo Override:"
		},
		s = {
			[0] = "Cannot modify this weapon! [Secondary]",
			[1] = "Secondary Ammo Override:",
			[2] = "No secondary ammo available."
		}
	}
	
	f.lineNoticeColor = Color(220,210,140)
	f.lineNoticeColorMod = Color(175,210,105)
	
	f.panbtSec = vgui.Create("DPanel", f.paninfo)
	f.panbtSec:Dock(BOTTOM)
	f.panbtSec:SetSize(0,30)
	f.panbtSec:DockMargin(10,2.5,10,2.5)

	f.panbt = vgui.Create("DPanel", f.paninfo)
	f.panbt:Dock(BOTTOM)
	f.panbt:SetSize(0,30)
	f.panbt:DockMargin(10,2.5,10,2.5)
	
	f.wang = vgui.Create("DNumberWang", f.panbt)
	f.wang:Dock(RIGHT)
	f.wang:SetSize(56,0)
	f.wang:SetMinMax(-1,300)
	f.wang:SetText( 3 )
	f.wang:SetVisible(false)
	
	local isPrimaryModable = 0
	local isSecondaryModable = 0
	
	f.lbprimary = vgui.Create("DLabel", f.panbt)
	f.lbprimary:Dock(FILL)
	f.lbprimary:SetText("Awaiting data...")
	f.lbprimary:DockMargin(10,0,0,0)
	f.lbprimary:SetTextColor(Color(22,22,22))
	
	f.wangSec = vgui.Create("DNumberWang", f.panbtSec)
	f.wangSec:Dock(RIGHT)
	f.wangSec:SetSize(56,0)
	f.wangSec:SetMinMax(-1,300)
	f.wangSec:SetText( 3 )
	f.wangSec:SetVisible(false)
	
	f.lbsecond = vgui.Create("DLabel", f.panbtSec)
	f.lbsecond:Dock(FILL)
	f.lbsecond:SetText("Awaiting data...")
	f.lbsecond:DockMargin(10,0,0,0)
	f.lbsecond:SetTextColor(Color(22,22,22))
	
	function f:SetBtnState( bool )
		bool = tobool(bool)
		self.btnApply:SetEnabled(bool)
		self.btnReset:SetEnabled(bool)
		self.btnRestore:SetEnabled(bool)
	end
	
	f.btnApply.DoClick = function()
		local wang1 = math.Clamp(f.wang:GetValue(), 0, f.wang:GetMax())
		local wang2 = math.Clamp(f.wangSec:GetValue(), 0, f.wangSec:GetMax())	-- Keep the min always 0, even though ammo is -1.
	
		local p = f.SelectedItem[2]
		local info = {
			["ammo1"] = wang1,
			["ammo2"] = wang2,
			["ammo1id"] = p.wepinfo.ammo1id,
			["ammo2id"] = p.wepinfo.ammo2id
		}
		local comp,size = util.PHXQuickCompress( info )
		
		net.Start("wepmgr.UpdateAmmoData")
			net.WriteString(p.class)
			net.WriteUInt(size,9)
			net.WriteData(comp,size)
		net.SendToServer()
		
		f:WindowState(false)
		f:SetBtnState(false)
		f:UpdateStatus("Updating...","info")
	end
	
	f.btnReset.DoClick = function()
		local p = f.SelectedItem[2]
		
		if !p or p == nil then
			f:UpdateStatus("An Error performing action: Selected weapon data contains no information.", "error")
			return
		end
		
		if istable(p) and table.Count(p) < 1 then
			f:UpdateStatus("An Error performing action: Selected weapon data table is empty.", "error")
			return
		end
		
		f.wang:SetValue( p.wepinfo.ammo1mag )
		f.wangSec:SetValue( p.wepinfo.ammo2mag )
		
		f:UpdateStatus("Ammo value reset.", "warning")
	end

	f.btnRestore.DoClick = function()
		local netname = "wepmgr.RestoreIndivAmmoData"
		local pClass = f.SelectedItem[3] --class

		if !pClass then
			f:UpdateStatus("An Error performing action: Selected weapon data contains no information.", "error")
			return
		end
		
		net.Start( netname )
			net.WriteString(pClass)
		net.SendToServer()
		
		f:WindowState(false)
		f:SetBtnState(false)
		f:UpdateStatus("Restoring...","info")
	end
	
	f.UpdateLabel = function(name, info)
		isPrimaryModable	= 0
		isSecondaryModable	= 0
		f.wang:SetVisible(false)
		f.wangSec:SetVisible(false)
		
		f.panbt:SetBackgroundColor(color_white)
		f.panbtSec:SetBackgroundColor(color_white)
		
		local copy = {}
		copy.ammoinfo = {}
		copy.ammoinfo.ammo1 = {}
		copy.ammoinfo.ammo2 = {}
		copy.ammoinfo.ammo1.amount = 0
		copy.ammoinfo.ammo1.ammoid = -1
		copy.ammoinfo.ammo2.amount = 0
		copy.ammoinfo.ammo2.ammoid = -1
	
		if info.ammoinfo and info.ammoinfo ~= nil and (not table.IsEmpty(info.ammoinfo)) then			
			copy.ammoinfo.ammo1.amount = info.ammoinfo.ammo1.amount
			copy.ammoinfo.ammo1.ammoid = info.ammoinfo.ammo1.ammoid
			copy.ammoinfo.ammo2.amount = info.ammoinfo.ammo2.amount
			copy.ammoinfo.ammo2.ammoid = info.ammoinfo.ammo2.ammoid
		end
		
		local w = {
			wi1 = "No Ammo", wi2 = "No Ammo",
			mod1 = "No Ammo", mod2 = "No Ammo"
		}
		
		if info.wepinfo.ammo1id > 0 then 
			f.wang:SetVisible(true)
			isPrimaryModable = 1
			w.wi1 = game.GetAmmoName(info.wepinfo.ammo1id)
			f.panbt:SetBackgroundColor(f.lineNoticeColor)
		end
		if info.wepinfo.ammo2id > 0 then
			f.wangSec:SetVisible(true)
			isSecondaryModable = 1
			w.wi2 = game.GetAmmoName(info.wepinfo.ammo2id)
			f.panbtSec:SetBackgroundColor(f.lineNoticeColor)
		end
		if info.wepinfo.ammo2id <= 0 and info.wepinfo.ammo1id > 0 then
			f.wangSec:SetVisible(false)
			isSecondaryModable = 2
		end
		
		local modammo1 = info.wepinfo.ammo1mag
		local modammo2 = info.wepinfo.ammo2mag
		
		-- Ammo Name/ID Cannot be less than 0. It must be at least Ammo ID "1" is present!
		if copy.ammoinfo.ammo1.ammoid > 0 then
			modammo1 = copy.ammoinfo.ammo1.amount
			w.mod1 = game.GetAmmoName(copy.ammoinfo.ammo1.ammoid)
			f.panbt:SetBackgroundColor(f.lineNoticeColorMod)
		end
		if copy.ammoinfo.ammo2.ammoid > 0 then
			modammo2 = copy.ammoinfo.ammo2.amount
			w.mod2 = game.GetAmmoName(copy.ammoinfo.ammo2.ammoid) 
			f.panbtSec:SetBackgroundColor(f.lineNoticeColorMod)
		end
		
		if string.find(name, '^#') then
			name = language.GetPhrase(name)
		end
		
		-- str, str, str, i, i, str, i, i, i, str, i, str
		f.label:Clear()
		local l = { -- store in order.
			{"Name",  						name}, 
			{"Class",  						info.class},
			{"Primary Ammo",  				w.wi1},
			{"Primary Clip",  				info.wepinfo.ammo1clip}, 
			{"Primary Ammo Count",  		info.wepinfo.ammo1mag, function(s, w, h) surface.SetDrawColor(f.lineNoticeColor) surface.DrawRect(0,0,w,h) end},
			{"Secondary Ammo",  			w.wi2}, 
			{"Secondary Clip",  			info.wepinfo.ammo2clip}, 
			{"Secondary Ammo Count",  		info.wepinfo.ammo2mag, function(s, w, h) surface.SetDrawColor(f.lineNoticeColor) surface.DrawRect(0,0,w,h) end},
			{"-- Modded Section --", 		"-- Modded Value --", function(s,w,h) if s:IsSelected() then surface.SetDrawColor(Color(30,30,30)) else surface.SetDrawColor(color_white) end surface.DrawRect(0,0,w,h) end},
			{"MOD Primary Ammo Count",  	copy.ammoinfo.ammo1.amount, function(s, w, h) surface.SetDrawColor(f.lineNoticeColorMod) surface.DrawRect(0,0,w,h) end},
			{"MOD Primary Ammo Name",  		w.mod1},
			{"MOD Secondary Ammo Count", 	copy.ammoinfo.ammo2.amount, function(s, w, h) surface.SetDrawColor(f.lineNoticeColorMod) surface.DrawRect(0,0,w,h) end},
			{"MOD Secondary Ammo Name",  	w.mod2}
		}
		for _,v in ipairs(l) do
			local tempPanel = f.label:AddLine(v[1], v[2])
			local f = v[3]
			
			if f and f ~= nil and isfunction(f) then
				function tempPanel:Paint(w,h)
					f(self,w,h)
				end
			end
		end
		
		f.lbprimary:SetText( panelText.p[isPrimaryModable] )
		f.lbsecond:SetText( panelText.s[isSecondaryModable] )
		
		f.wang:SetValue( modammo1 )
		f.wangSec:SetValue( modammo2 )
		
		f:UpdateStatus(string.format("Loaded weapon info from %s (%s)", name, info.class))
	end
	
	-- Called Externally.
	function f.UpdateData( name, class, lineid, strError )
		
		local wepinfo	= self.WeaponList[class]
		if !wepinfo or wepinfo == nil then
			-- fallback to self.DefSweps, this must the hl2 weapon.
			wepinfo = self.DefSweps[class]
		end
		local mod		= self.SwepMod[class]
		
		-- We somewhat can't get the data. Don't update the window but instead give a warning to re-open the window!
		if !wepinfo or wepinfo == nil then
			f:UpdateStatus("Error: Couldn't get any weapon data from .SwepMod or .WeaponList. Try re-open this window to refresh!", "error")
			Derma_Message("Error: Couldn't get any weapon data from .SwepMod or .WeaponList. Did the weapon table was edited by dwep or something else?","Error Updating Wepaon Data", "OK")
			f.SetBtnState(true)
			return
		end
		
		local data = {
			class 		= class,
			wepinfo 	= wepinfo,
			ammoinfo 	= nil
		}
		
		if mod and mod ~= nil then data.ammoinfo = mod end
	
		f.UpdateLabel( name, data )
		f:SetBtnState(true)
		
		if strError and strError ~= nil and strError ~= "" then
			f:UpdateStatus(strError, "error")
		else
			f:UpdateStatus(string.format("Data for '%s' (%s) has been successfully updated.", name, class), "good")
		end
		
		f.list:SelectItem( f.list:GetLines()[lineid] )
	end

	f.list.OnRowSelected = function(me, rowIndex, row)
		--local line = f.list:GetLine(f.list:GetSelectedLine())
		local line = row
		f.SelectedItem = { line:GetValue(1), line.data, line.data.class, lineid }
		
		local image = "vgui/entities/" .. line.data.class
		f.model:SetImage( util.FallbackVGUI( image ), "vgui/wlv_wepmgr_unknown" )
		
		f.UpdateLabel(line:GetValue(1), line.data)
		
		if line.data.wepinfo.ammo1id < 1 and line.data.wepinfo.ammo2id < 1 then
			f:SetBtnState(false)
		else
			f:SetBtnState(true)
		end
	end
	
	f.list.OnRowRightClick = function(me, id, p)
		
		local name = me:GetLine(id):GetValue(1)
		local class = me:GetLine(id):GetValue(2)
		
		local function state( color, msg, isError )
			if !color or color == nil then color = color_white end
			if isError == nil then isError = false end
			
			chat.AddText(color, msg)
			if isError then
				f:UpdateStatus(msg, "error")
			else
				f:UpdateStatus(msg, "info")
			end
		end
		
		local m = DermaMenu()
		m:AddOption("Copy Name", function()
			state( color_white, "Copied Name to Clipboard: " .. name )
			SetClipboardText( name )
		end)
		m:AddOption("Copy Class Name", function()
			state( Color(220,220,10), "Copied ClassName to Clipboard: " .. class )
			SetClipboardText( class )
		end)
		m:AddOption("Print Weapon Info in Console", function()
			state( Color(10,220,220), "Open your console to view Weapon info." )
			PrintTable( p.data.wepinfo )
		end)
		m:AddOption("Print Modded Info in Console", function()
			local DAT = p.data.ammoinfo
			if DAT and DAT ~= nil and (not table.IsEmpty(DAT)) then
				state(Color(10,220,220), "Open your console to view Modded Ammo data.")
				PrintTable(DAT)
			else
				state(Color(220,10,10), "Modded Ammo data is not available.", true)
			end
		end)
		
		m:Open()
		
	end
	
	f.frame:MakePopup()
	
	return f

end

local panel = {}
panel.isOpen = false

function WepMgr:openAmmoEditor()

	local ply = LocalPlayer()
	if ply:PHXIsStaff() or ply:IsSuperAdmin() then
		if !panel.isOpen then panel = self:swepAmmoEditor(); end
	else
		chat.AddText(Color(220,40,40), "You have no rights to access this feature.")
	end

end

local function updateAmmoData( t )
	if (t) and istable(t) and !table.IsEmpty(t) then
		print("[WepMgr] Received Ammo Data Table, adding...")
		for class,data in pairs(t) do
			WepMgr:Add(class, data)
		end
		return true
	end
	return false
end

net.Receive("wepmgr.AmmoData", function()
	local size = net.ReadUInt(16)
	local data = net.ReadData(size)
	local t = util.PHXQuickDecompress(data) or {}

	updateAmmoData( t )
	print("[WepMgr] SwepMod table count: " .. table.Count(WepMgr.SwepMod))
end)

local function RefreshPanel( p, isError, strInfoMsg )
	
	if !isError then isError = false end
	
	if (p) and p.isOpen and (p.frame) and p.frame:IsValid() and p.UpdateList then
		if !isError then
			local name,class,id = p.SelectedItem[1],p.SelectedItem[3],p.SelectedItem[4]
			p.UpdateList()
			p.UpdateData(name, class, id, strInfoMsg)
		end
		p:WindowState(true)
		p:SetBtnState(true)
	end
	
end

net.Receive("wepmgr.InformState", function()
	local msg = "Data Updated: %s"
	
	local bool	= net.ReadBool()
	local err	= net.ReadString()
	
	if bool then
		msg = "Error modifying data: %s"
		MsgC( Color(250,65,97), "Error!\n", string.format(msg, err), "\n" )
		RefreshPanel( panel, true, string.format(msg,err) ) -- force to true.
	end
	
	chat.AddText(Color(0,220,0), "Success - ", string.format(msg,err))
	MsgC( Color(0,220,0), "Success!\n", string.format(msg, err), "\n" )
end)

net.Receive("wepmgr.UpdateModdedAmmo", function()	
	local size = net.ReadUInt(16)
	local data = net.ReadData(size)
	
	local t = util.PHXQuickDecompress(data) or {}
	
	WepMgr:Reset()
	
	updateAmmoData(t)
	
	print("[WepMgr] SwepMod table count: " .. table.Count(WepMgr.SwepMod))
	
	RefreshPanel( panel )
end)