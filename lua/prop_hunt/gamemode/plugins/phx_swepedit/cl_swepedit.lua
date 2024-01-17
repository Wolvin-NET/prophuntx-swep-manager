local f = {}

f._MaxW=1024
f._MaxH=576
f.CurCat = "Prop Hunt: X2Z"
f.isHaventSave = false

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

local function doApplyChanges( bReset )
    local WepData = WepMgr.Loadout

    if !bReset and (!WepData or table.IsEmpty(WepData)) then
        Derma_Message("Error: No Weapons in Loadout slot. Try adding something before applying!", "Error", "OK")
        return
    end

    local class = {}
    --no data needed, as for now
    if !bReset then
        for cls,_ in pairs(WepData) do table.insert( class, cls ); end
    end

    local comp,size = util.PHXQuickCompress( class )

    net.Start("wepmgr.UpdateLoadout")
        net.WriteUInt(size,16)
        net.WriteData(comp,size)
    net.SendToServer()

    if (f) then
        if (f.isHaventSave) then f.isHaventSave = false end
    end
end

local function doResetChanges()
    Derma_Query("Are you sure you want to clear & reset loadout?\nThis will clear everything and you'll have to re-add weapons to your loadout!", "Warning",
        "Yes", function()
            doApplyChanges( true )
        end, 
        "No", function() end
    )

    if (f) then
        if (f.isHaventSave) then f.isHaventSave = false end
    end
end

local function getCat()
    local wep=WepMgr.WeaponList
    local hl2=WepMgr.DefSweps

    local DATA={}

    -- WeaponLists
    for class,data in pairs(wep) do
        local cat=data.category

        if !DATA[cat] then DATA[cat] = {} end
        if !DATA[cat][class] then DATA[cat][class] = data end
    end

    --Half-Life 2
    for class,data in pairs(hl2) do
        local cat=data.category

        if !DATA[cat] then DATA[cat] = {} end
        if !DATA[cat][class] then DATA[cat][class] = data end
    end

    return DATA
end

local function MakeIcons( pList, cat, class, data, fFix )
    local name = data.name
    local item = pList:Add("DPanel") -- 
    item.weaponClass = class
    item.weaponCat = cat
    item:SetSize(128,128)

    local label = item:Add("DLabel")
    label:Dock(BOTTOM)
    label:SetText(name)
    label:SetTextColor(color_black)
    label:SetTall(16)
    label:SetContentAlignment(5)

    local icon = item:Add("DImageButton")
    icon:Dock(FILL)
    icon:DockMargin(4,2,4,2)
    --icon:SetImage( "vgui/entities/"..class, "vgui/wlv_wepmgr_unknown" )
    icon:SetImage( util.FallbackVGUI( "vgui/entities/"..class ), "vgui/wlv_wepmgr_unknown" )
    
    return item,label,icon
end

local function createiconfunc( icon, ft, data )
    icon.DoClick = function(self)
        local pnl=self:GetParent() --item DPanel
        local pnlClass=pnl.weaponClass
        if !pnl.selected then
            pnl.selected = true
            ft:AddWeaponToLoadout( pnl, data )
        else
            pnl.selected = false
            ft:RemoveWeaponLoadout( pnl, data )
        end
        ft:LayoutScrollBarFix()
    end

    icon.DoRightClick = function(self)
        local pnl=self:GetParent() --item DPanel
        local menu=DermaMenu()

        menu:AddOption("Copy ClassName", function()
            SetClipboardText( pnl.weaponClass )
        end):SetIcon("icon16/page_copy.png")
        menu:AddOption("Copy Weapon Data (JSON)", function()
            local json = util.TableToJSON( data )
            SetClipboardText( json )
        end):SetIcon("icon16/page_white_copy.png")

        menu:Open()
    end
end

f.MenuList = {
    ["Options"]	= {
		["Keep Default Weapons"] = { f = function()
            SndCmd( "phx_wepmgr_keep_default", !GetConVar("phx_wepmgr_keep_default"):GetBool() and "1" or "0" )
        end, icon = function( menu ) 
            menu:SetIsCheckable(true)
            menu:SetChecked( GetConVar("phx_wepmgr_keep_default"):GetBool() )
        end },
        ["Open Ammo Editor"] = { f = function() 
            WepMgr:openAmmoEditor()
        end },
    },
    ["Data"]	= {
        --
        --["spacer1"] = "--",
        --
        ["Apply Changes"] = { f = function() 
            doApplyChanges()
        end, icon = "icon16/arrow_rotate_clockwise.png" },
        ["Clear & Reset"] = { f = function() 
            doResetChanges()
        end, icon = "icon16/cross.png" },
		
        --[[ ["Use Random Loadouts"] = { f = function()
            local cv = "phx_swep_rand_loadout"
            local result = !PHX:GetCVar(cv) and true or false
            SndCmd( cv, result )
		end, icon = function()
            return PHX:GetCVar("phx_swep_rand_loadout") and "icon16/tick.png" or "icon16/cross.png"
        end } ]]
	},
}

function WepMgr:WeaponManager()
    f.isOpen = true
    if !f.DATA then f.DATA = getCat() end
    local ply = LocalPlayer()

    if not isstaff(ply) then
		chat.AddText(Color(220,40,40), "You have no rights to access this feature!")
		return
	end
	if (not PHX:GetCVar("phx_wepmgr_enable")) then
		chat.AddText(Color(220,40,40), "Swep Ammo Editor is disabled. Enable this feature under Plugins menu!")
		return
	end

    local scrW = ScrW() * 0.8
    local scrH = ScrH() * 0.8
    if scrW<=f._MaxW then scrW=f._MaxW end
    if scrH<=f._MaxH then scrH=f._MaxH end

    local _copy=table.Copy( self.Loadout ) -- for cancel

    f.frame = vgui.Create("DFrame")
	f.frame:SetSize(scrW,scrH)
	f.frame:SetTitle( "Prop Hunt: X2Z Weapon Manager" )
	f.frame:SetVisible(true)
	f.frame:ShowCloseButton(true)
	f.frame:Center()

    f.frame.OnClose = function()
		f.isOpen = false
	end

	f.menuBar = vgui.Create("DMenuBar", f.frame)
	f.menuBar:DockMargin(-3,-6,-3,0)
	
	for topMenu,ListSubMenu in SortedPairs(f.MenuList) do
		local H = f.menuBar:AddMenu( topMenu )
		for subMenu,Data in SortedPairs(ListSubMenu) do
            --[[ if isstring(Data) and Data == "--" then
                H:AddSpacer()
            else ]]
                local S = H:AddOption( subMenu, Data.f )
                if Data.icon then 
                    if isfunction(Data.icon) then
                        Data.icon(S)
                    else
                        S:SetIcon(Data.icon)
                    end
                end
            --end
		end
	end

    -- Left Panel
    f.left = f.frame:Add("DPanel")
	--f.left:Dock(FILL)
    --f.left:DockMargin(4,4,4,4)
    --f.left:SetWide(f.frame:GetWide()*0.5)
    f.left:SetPaintBackground(false)

    -- Bottom Panel, for status/apply change button
    f.bottom = f.frame:Add("DPanel")
    f.bottom:Dock(BOTTOM)
    f.bottom:SetTall(32)

    -- Right Panel
    f.rSheet = f.frame:Add("DPropertySheet")


    --//// LeftPanel: Source Weapon Browser
    f.pTopLabel = vgui.Create("DPanel",f.left)
    f.pTopLabel:Dock(TOP)
    f.pTopLabel:SetTall(24)
    f.pTopLabel:DockMargin(4,4,4,4)
    f.pTopLabel:SetPaintBackground(false)

    f.cmbLabel = vgui.Create("DLabel", f.pTopLabel)
    f.cmbLabel:Dock(LEFT)
    f.cmbLabel:SetWide(60)
    f.cmbLabel:SetText("Category:")
    f.cmbLabel:DockMargin(2,0,4,0)
    f.cmbLabel:SetContentAlignment(4)

    f.comb = vgui.Create("DComboBox", f.pTopLabel)
	f.comb:Dock(FILL)
	f.comb:SetValue( f.CurCat )
    for iCat,_ in pairs( f.DATA ) do -- Add Categories
        if iCat == "Prop Hunt: X2Z" then 
            f.comb:AddChoice(iCat,iCat,true)
        else
            f.comb:AddChoice(iCat)
        end
    end
    
    f.lScroll = vgui.Create("DScrollPanel",f.left)
    f.lScroll:SetName("SCROLL1")
    f.lScroll:Dock(FILL)
    f.lScroll:DockMargin(0,4,0,0)

    f.ListWep = f.lScroll:Add("DIconLayout")
    f.ListWep:Dock(FILL)
    f.ListWep:SetSpaceX(5)
    f.ListWep:SetSpaceY(5)

    -- //// Right Panel: Add to Loadout Weapon Panel

    -- Sheet #1: Simple Loadout
    f.pnlLoadout = vgui.Create("DScrollPanel",f.rSheet)
    f.pnlLoadout:SetName("SCROLL2")
    f.pnlLoadout:Dock(FILL)
    f.pnlLoadout:DockMargin(8,4,8,4)

    f.RAddedWep = f.pnlLoadout:Add("DIconLayout")
    f.RAddedWep:Dock(FILL)
    f.RAddedWep:SetSpaceX(5)
    f.RAddedWep:SetSpaceY(5)

    for class,data in pairs( WepMgr.Loadout ) do        
        local item,label,icon = MakeIcons( f.RAddedWep, data.category, class, data, function() f:LayoutScrollBarFix() end )
        item.selected = true
        createiconfunc( icon, f, data )
    end

    -- Sheet #2: Random Loadout (Coming soon, feature disabled...)
    f.pnlRandLoadout = vgui.Create("DPanel",f.rSheet)
    f.pnlRandLoadout:Dock(FILL)
    f.pnlRandLoadout:DockMargin(8,4,8,4)
    f.pnlRandLoadout:SetPaintBackground(false)

    f.rLabel = vgui.Create("DLabel",f.pnlRandLoadout)
    f.rLabel:Dock(TOP)
    f.rLabel:SetTall(86)
    f.rLabel:DockMargin(8,4,8,4)
    f.rLabel:SetText( "Coming Soon!\nThis feature will be added in future version.\nCheck out for update progress on my Ko-Fi posts.\nThanks!" )
    f.rLabel:SetFont( "Trebuchet24" )

    local pnbtn = vgui.Create("DPanel",f.pnlRandLoadout)
    pnbtn:Dock(TOP)
    pnbtn:SetTall(32)
    pnbtn:DockMargin(8,2,8,2)
    pnbtn:SetPaintBackground(false)

    local btn = vgui.Create("DButton",pnbtn)
    btn:Dock(LEFT)
    btn:DockMargin(0,2,0,2)
	btn:SetSize(128,0)
	btn:SetText("Visit Ko-Fi")
    btn.DoClick = function() gui.OpenURL( "https://ko-fi.com/wolvindra/posts" ) end

    --[[
    -- Upcoming feature, currently disabled, I'll just put in future reference
    -- Having difficult time when sorting this out, sorry.

    f.pnlRandLoadout = vgui.Create("DPanel",f.rSheet)
    f.pnlRandLoadout:Dock(FILL)
    f.pnlRandLoadout:DockMargin(8,4,8,4)

    f.RLDCombo = vgui.Create("DComboBox", f.pnlRandLoadout)
    f.RLDCombo:Dock(FILL)
	f.RLDCombo:SetValue( "Loadout 1" )
    for rCat,_ in pairs( WepMgr.RandLoadout ) do
        if rCat == "Loadout 1" then 
            f.RLDCombo:AddChoice(rCat,rCat,true)
        else
            f.RLDCombo:AddChoice(rCat)
        end
    end

    -- TODO: 
    - DCategoryList
        - DIconLayout
        - 1 Toggleable DButton:"Edit"
    
    - Procedure
    - Click Source, Copy on Right
    -- ....
    ]]

    -- Add to Sheet
    f.rSheet:AddSheet( "Loadout", f.pnlLoadout, "icon16/gun.png" )
    f.rSheet:AddSheet( "Multiple Loadout", f.pnlRandLoadout, "icon16/application_cascade.png" )
    --f.rSheet:SwitchToName("Multiple Loadout")

    -- //// Bottom Panel: Status/Apply Button
    f.btmApply = f.bottom:Add("DButton")
    f.btmApply:Dock(RIGHT)
    f.btmApply:DockMargin(4,2,4,2)
    f.btmApply:SetWide(128)
    f.btmApply:SetText("Apply Loadout")
    f.btmApply:SetIcon( "icon16/tick.png" )
    f.btmApply.DoClick = function() doApplyChanges() end

    f.btmCancel = f.bottom:Add("DButton")
    f.btmCancel:Dock(RIGHT)
    f.btmCancel:DockMargin(4,2,4,2)
    f.btmCancel:SetWide(128)
    f.btmCancel:SetText("Cancel")
    f.btmCancel.DoClick = function()
        if (f.isHaventSave) then
            f.isHaventSave = false
            self.Loadout = _copy
            f.frame:Close()
            timer.Simple(0.2, function() WepMgr:openWeaponManager() end)
        end
    end

    f.btmReset = f.bottom:Add("DButton")
    f.btmReset:Dock(RIGHT)
    f.btmReset:DockMargin(4,2,4,2)
    f.btmReset:SetWide(128)
    f.btmReset:SetText("Clear & Reset")
    f.btmReset:SetIcon( "icon16/cross.png" )
    f.btmReset.DoClick = function() doResetChanges() end

    f.btmLabel = f.bottom:Add("DLabel")
    f.btmLabel:Dock(FILL)
    f.btmLabel:DockMargin(4,0,4,0)
    f.btmLabel:SetText("")
    f.btmLabel:SetFont( "TargetID" )
    f.btmLabel:SetTextColor(Color(235,16,16))
    f.btmLabel:SetContentAlignment(4)
    function f:TriggHaventSave(b)
        if (b) then
            f.btmLabel:SetText("[WARNING] You haven't applied your loadout! Click on 'Apply Changes' to confirm your change!")
        else
            f.btmLabel:SetText("")
        end
    end
    if (f.isHaventSave) then f:TriggHaventSave(true) end

    -- //// Divider \\\\ 
    f.div = vgui.Create("DHorizontalDivider", f.frame)
    f.div:Dock(FILL)
    f.div:SetLeft( f.left )
    f.div:SetRight( f.rSheet )
    f.div:SetDividerWidth(6)
    f.div:SetLeftMin(400)
    f.div:SetRightMin(400)
    f.div:SetLeftWidth( f.frame:GetWide()*0.5 )




    --///////////////// Functions \\\\\\\\\\\\\\\\\--
    function f.comb:OnSelect(num,val,data)
        f.CurCat=val
        f:UpdateCategoryData( f.CurCat )
	end

    function f:LayoutScrollBarFix()
        -- Unknown bug for what caused to be so scroll can be fucked
        -- The Second ScrollBar on the right was just fine
        local scroll = self.lScroll
        f.ListWep:Layout()
        timer.Simple(0,function() scroll:InvalidateLayout() end) --true?
    end

    -- Add/Remove to Simple Loadout
    function f:AddWeaponToLoadout( panel, data )
        -- panel must have panel.weaponClass !!
        if (panel.weaponClass) then

            if !self.isHaventSave then
                self.isHaventSave=true
                self:TriggHaventSave( self.isHaventSave )
            end

            if !WepMgr.Loadout[panel.weaponClass] then
                self.RAddedWep:Add( panel )
                WepMgr.Loadout[panel.weaponClass] = data
            else
                if f.CurCat == panel.weaponCat then
                    self.ListWep:Add( panel )
                else
                    panel:Remove()
                end
                WepMgr.Loadout[panel.weaponClass] = nil
            end
        else
            print(panel:GetName(), "--> !Error: panel.weaponClass is nil!")
        end
    end
    function f:RemoveWeaponLoadout( panel, data )
        -- panel must have panel.weaponClass !!
        if (panel.weaponClass) then
            
            if !self.isHaventSave then
                self.isHaventSave=true
                self:TriggHaventSave( self.isHaventSave )
            end

            if WepMgr.Loadout[panel.weaponClass] then
                if f.CurCat == panel.weaponCat then
                    self.ListWep:Add( panel )
                else
                    panel:Remove()
                end
                WepMgr.Loadout[panel.weaponClass] = nil
            else
                self.RAddedWep:Add( panel )
                WepMgr.Loadout[panel.weaponClass] = data
            end
        else
            print(panel:GetName(), "--> !Error: panel.weaponClass is nil!")
        end
    end

    --[[ 
    -- Add/Remove to Random Loadout, needs category #1 to #n

    function f:AddRandLoadout( LoadoutID, cls, data )
    end
    function f:RemoveRandLoadout( LoadoutID, cls )
    end
    ]]

    function f:UpdateCategoryData( cat )
        if !cat then cat = "Prop Hunt: X2Z" end
        self.ListWep:Clear()

        local CatData = self.DATA[cat]

        for class,data in pairs( CatData ) do

            if (WepMgr.Loadout[class]) then 
                continue
            end

            local item,label,icon = MakeIcons( f.ListWep, cat, class, data, function() f:LayoutScrollBarFix() end )

            createiconfunc( icon, f, data )
            
            --[[
            icon.DoRightClick = function(self)
                local pnl=self:GetParent() --item DPanel
                local Data=WepMgr.Loadout
                local cls = pnl.weaponClass
                local has = Data[cls]

                local menu = DermaMenu()
                local addto = menu:AddOption("Add to Loadout", function()
                    if has then
                        pnl.selected = false
                        f:RemoveWeaponLoadout( pnl, data )
                    else
                        pnl.selected = true
                        f:AddWeaponToLoadout( pnl, data )
                    end
                    if (fFix) then fFix() end
                end)
                if has then addto:SetIcon("icon16/tick.png") end

                menu:AddSpacer()
                
                local subm,parm = menu:AddSubMenu("Add to:")
                parm:SetIcon("icon/arrow_right.png")

                local RandData=WepMgr.RandLoadout
                for LoadoutID,_ in SortedPairs( RandData ) do
                    local exists = RandData[LoadoutID][cls]
                    local addtoR = subm:AddOption( LoadoutID, function()
                        if exists then
                            f:RemoveRandLoadout( LoadoutID, cls )
                        else
                            f:AddRandLoadout( LoadoutID, cls, data )
                        end
                        if (fFix) then fFix() end
                    end )

                    if exists then addtoR:SetIcon("icon16/accept.png") end
                end
                menu:Open()
            end 
            ]]

        end

        self:LayoutScrollBarFix()
        
    end
    f:UpdateCategoryData()

    f.frame:MakePopup()

    return f

end

local panel = {}
panel.isOpen = false

function WepMgr:openWeaponManager()

	local ply = LocalPlayer()
	if isstaff( ply ) then
		if !panel.isOpen then panel = self:WeaponManager(); end
	else
		chat.AddText(Color(220,40,40), "You have no rights to access this feature.")
	end

end

local function updatedata( t )
    --Server only needs WepMgr.Loadout = { < weapon data > }, so it will be different on client.
	--because WepMgr.Loadout[class] has data on clientside, we need to verify something here.

    if (t) and istable(t) then
		print("[WepMgr] Received Loadout Data Table, adding...")

        if table.IsEmpty(t) then
            print( "[WepMgr] Receiving with no Loadout data, probably got reset/first time run")
        end

        local List = WepMgr.WeaponList
        local hl2 = WepMgr.DefSweps

        WepMgr.Loadout = {}

		for _,class in pairs(t) do
			if !WepMgr.Loadout[class] then
                local data = List[class]
                local data2 = hl2[class]
                if (data) then WepMgr.Loadout[class] = data; end
                if (data2) then WepMgr.Loadout[class] = data2; end
            end
		end

        return true
	end

    return false
end

net.Receive("wepmgr.WeaponData", function()
	local size = net.ReadUInt(16)
	local data = net.ReadData(size)
	
	local t = util.PHXQuickDecompress(data)
	local result=updatedata(t)
	
    if result then
	    print("[WepMgr] Loadout table count: " .. table.Count(WepMgr.Loadout))
    else
        print("[WepMgr] Cannot load Loadout table: Invalid/Error")
    end
end)

net.Receive("wepmgr.UpdateModdedLoadout", function()	
	local size = net.ReadUInt(16)
	local data = net.ReadData(size)
	
	local t = util.PHXQuickDecompress(data) or {}
	local result=updatedata(t)
	
    if result then
        print("[WepMgr] Loadout table count: " .. table.Count(WepMgr.Loadout))
        
        -- Close the panel and reopen
        if (panel) and panel.isOpen then
            panel.frame:Close()
            timer.Simple(0.2, function()
                Derma_Message("Loadout has been successfully updated!", "Info", "OK")
                WepMgr:openWeaponManager()
            end)
        end
    else
        Derma_Message( "Cannot receive Loadout Table: Invalid/Error!", "Warning", "OK" )
        print("[WepMgr] Cannot load Loadout table: Invalid/Error!")
    end
end)