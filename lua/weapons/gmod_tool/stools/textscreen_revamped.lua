AddCSLuaFile()

if SERVER then
	util.AddNetworkString( "SetTextscreenText" )
	util.AddNetworkString( "UpdatePlayerCurrentTextscreenText" )
end

TOOL.Author = "Mikey"
TOOL.Name = "#tool.textscreen_revamped.name"
TOOL.Category = "Text Screens Revamped"
TOOL.ClientConVar["should_parent"] = 1


if CLIENT then
	TOOL.Information = {
		{
			name = "left"
		},
		{
			name = "right"
		},
	}

	language.Add( "tool.textscreen_revamped.name", "Text Screen Revamped" )
	language.Add( "tool.textscreen_revamped.desc", "Creates a text screen." )
	language.Add( "tool.textscreen_revamped.left", "Create a Text Screen." )
	language.Add( "tool.textscreen_revamped.right", "Update a Text Screen." )

	net.Receive( "SetTextscreenText", function()
		local ply = net.ReadEntity()
		local ent = net.ReadEntity()
		local updated = net.ReadBool()
		local scale = Vector( 0.5, ent.size[1] * ent.pixelScale, ent.size[2] * ent.pixelScale )

		-- Since traces are going through the entity, I'm playing a fake tool sound just so the player knows they're doing something.
		if LocalPlayer() == ply and updated then
			surface.PlaySound( "Airboat.FireGunRevDown" )
		end

		ent.PhysCollide = CreatePhysCollideBox( Vector( scale.x * -0.5, scale.y * -0.5, scale.z * -0.5 ), Vector( scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 ) )

		ent:SetText( ply.textscreen_revamped.currentTextScreenText )
		print( ent.text )
		ent:UpdateHTML()
	end )

	net.Receive( "UpdatePlayerCurrentTextscreenText", function()
		local ply = net.ReadPlayer()
		local txt = net.ReadString()

		ply.textscreen_revamped = ply.textscreen_revamped or {}
		ply.textscreen_revamped.currentTextScreenText = txt
	end )
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end

	if CPPI and self:GetClientBool( "should_parent" ) and IsValid( trace.Entity ) then
		local traceEnt = trace.Entity
		if not traceEnt:CPPICanTool( self:GetOwner() ) then return false end
	end

	local ent = ents.Create( "textscreen" )
	ent:SetPos( trace.HitPos + trace.HitNormal * 1 )
	ent:SetAngles( trace.HitNormal:Angle() )
	ent:Spawn()
	ent:Activate()
	ent:SetNWEntity( "owner", self:GetOwner() )

	if CPPI then
		ent:CPPISetOwner( self:GetOwner() )
	end

	if not IsValid( ent ) then return end

	timer.Simple( 0, function() -- RAHHHHH I HATE THIS
		net.Start( "SetTextscreenText" )
		net.WriteEntity( self:GetOwner() )
		net.WriteEntity( ent )
		net.WriteBool( false )
		net.Broadcast()
	end )

	if self:GetClientBool( "should_parent" ) and IsValid( trace.Entity ) then
		ent:SetParent( trace.Entity )
	end

	undo.Create( "Text Screen" )
	undo.SetPlayer( self:GetOwner() )
	undo.AddEntity( ent )
	undo.Finish()

	return true
end

function TOOL:RightClick( trace )
	if CLIENT then
		PrintTable( trace )
		return IsValid( trace.Entity ) and trace.Entity:GetClass() == "textscreen"
	end
	local ent = trace.Entity

	if CPPI and IsValid( ent ) then
		local traceEnt = ent
		if not traceEnt:CPPICanTool( self:GetOwner() ) then return false end
	end

	if IsValid( ent ) and ent:GetClass() == "textscreen" then
		net.Start( "SetTextscreenText" )
		net.WriteEntity( self:GetOwner() )
		net.WriteEntity( ent )
		net.WriteBool( true )
		net.Broadcast()

		return true
	end

	return false
end

-- Create a json file that keeps the settings between sessions
if CLIENT then
	local defaultFileName = "textscreen_revamped/default.txt"
	local lastPresetFiles = ""

	if not file.Exists( "textscreen_revamped", "DATA" ) then
		file.CreateDir( "textscreen_revamped" )
	end
	--[[
	<text style="
	--font: Coolvetica;
	--size: 6;
	--color: rgb( 180, 220, 255 );
	--shadow-color: rgb( 0, 180, 255 );
	--stroke-color: #0000;
	">
	garry's mod textscreens revamped
	]]
	if not file.Exists( defaultFileName, "DATA" ) then
		file.Write( defaultFileName, util.TableToJSON( {
			entries = {
				{
					text = "garry's mod textscreens revamped",
					effectData = {
						font = "Coolvetica",
						size = 6,
						color = {
							r = 180,
							g = 220,
							b = 255,
							a = 255
						},
						shadowColor = {
							r = 0,
							g = 180,
							b = 255,
							a = 255
						},
						strokeColor = {
							r = 0,
							g = 0,
							b = 0,
							a = 0
						},
						stroke = 1
					}
				}
			}
		}, true ) )
	end

	local function TableToColor( tbl )
		return tbl and Color( tbl.r, tbl.g, tbl.b, tbl.a ) or nil
	end

	function TOOL.BuildCPanel( panel )
		local presetPanel = vgui.Create( "ControlPresets" )
		local files, _ = file.Find( "textscreen_revamped/*.txt", "DATA" )

		for _, fileName in pairs( files ) do
			fileName = string.sub( fileName, 1, -5 ) -- Remove .txt from filename
			presetPanel:AddOption( fileName, nil )
		end

		-- Advanced html shiz
		--[[
		local textEdit = vgui.Create( "DTextEntry" )
		textEdit:Dock( TOP )
		textEdit:SetTall( 200 )
		textEdit:SetMultiline( true )
		local lastSavedTxt = file.Read( defaultFileName, "DATA" )
		textEdit:SetValue( lastSavedTxt )
		textEdit:SetUpdateOnType( true )

		function textEdit:OnValueChange( text )
			LocalPlayer().textscreen_revamped.currentTextScreenText = text

			net.Start( "UpdatePlayerCurrentTextscreenText" )
			net.WritePlayer(  LocalPlayer() )
			net.WriteString( text )
			net.SendToServer()
		end
		]]

		local textSheet = vgui.Create( "DPropertySheet", panel )
		textSheet:Dock( TOP )
		textSheet:SetTall( 200 )

		textSheet.entries = {}

		local function updateCurrentText()
			local ply = LocalPlayer()
			
			ply.textscreen_revamped = ply.textscreen_revamped or {}
			ply.textscreen_revamped.currentTextScreenText = ""
			
			for i, entry in ipairs( textSheet.entries ) do
				ply.textscreen_revamped.currentTextScreenText = ply.textscreen_revamped.currentTextScreenText .. 
				string.format( [[
				<text style="
				--font: %s;
				--size: %s;
				--color: %s;
				--shadow-color: %s;
				--stroke-color: %s;
				--stroke: %s;
				">%s</text>]], 
				entry.effectData.font, 
				entry.effectData.size, 
				entry.effectData.color:ToHex(),
				entry.effectData.shadowColor:ToHex(),
				entry.effectData.strokeColor:ToHex(),
				entry.effectData.stroke,
				entry.text ) .. "\n"
				
			end

			net.Start( "UpdatePlayerCurrentTextscreenText" )
			net.WritePlayer( ply )
			net.WriteString( ply.textscreen_revamped.currentTextScreenText )
			net.SendToServer()
		end
		
		local function addTextLine( text, effectData )
			text = text or ""
			effectData = effectData or {}
			effectData = {
				font = effectData.font or "Coolvetica",
				size = effectData.size or 6,
				color = TableToColor( effectData.color ) or Color( 255, 255, 255, 255 ),
				shadowColor = TableToColor( effectData.shadowColor ) or Color( 0, 0, 0, 255 ),
				strokeColor = TableToColor( effectData.strokeColor ) or Color( 0, 0, 0, 255 ),
				stroke = effectData.stroke or 1,
			}

			local panel = vgui.Create( "DPanel", textSheet )
			panel:DockMargin( 5, 0, 5, 5 )
			panel:Dock( FILL )
			panel:SetPaintBackgroundEnabled( true )

			function panel:ApplySchemeSettings()
				panel:SetBGColor( 120, 120, 120, 255 )
			end

			-- Add a button to add a new text line
			local addLineButton = vgui.Create( "DButton", panel )
			addLineButton:SetIcon( "icon16/add.png" )
			addLineButton:SetText( "" )
			addLineButton:Dock( RIGHT )
			addLineButton:SetWidth( 20 )
			addLineButton:SetHeight( 20 )
			addLineButton:DockMargin( 0, 0, 5, 140 )
			addLineButton:DockPadding( 0, 0, 0, 0 )

			addLineButton.Paint = function() end

			addLineButton.DoClick = function()
				addTextLine()
			end

			local removeLineButton = vgui.Create( "DButton", panel )
			removeLineButton:SetIcon( "icon16/delete.png" )
			removeLineButton:SetText( "" )
			removeLineButton:Dock( RIGHT )
			removeLineButton:SetWidth( 20 )
			removeLineButton:SetHeight( 20 )
			removeLineButton:DockMargin( 0, 0, 0, 140 )
			removeLineButton:DockPadding( 0, 0, 0, 0 )

			removeLineButton.Paint = function() end

			removeLineButton.DoClick = function()
				local tabs = textSheet:GetItems()
				if #tabs == 1 then return end
				textSheet:CloseTab( tabs[#tabs].Tab, true )
			end

			-- Text box
			local textEntry = vgui.Create( "DTextEntry", panel )
			textEntry:Dock( TOP )
			textEntry:SetMultiline( true )
			textEntry:SetUpdateOnType( true )
			textEntry:DockPadding( 0, 0, 0, 0 )
			textEntry:SetHeight( 50 )
			textEntry:SetValue( text )
			textEntry.id = #textSheet.entries + 1

			textSheet.entries[textEntry.id] = {
				text = text,
				effectData = effectData
			}

			--- Effect controls

			-- font dropdown
			local fontControl = vgui.Create( "DComboBox", panel )
			fontControl:SetPos( 50, 55 )
			fontControl:SetSize( 200, 20 )

			fontControl.label = vgui.Create( "DLabel", panel )
			fontControl.label:SetPos( 5, 55 )
			fontControl.label:SetSize( 200, 20 )
			fontControl.label:SetText( "Font" )

			for _, font in pairs( TEXTSCREEN_REVAMPED.FONTS ) do
				fontControl:AddChoice( font )
			end

			fontControl:SetValue( effectData.font )

			function fontControl:OnSelect( index, value, data )
				textSheet.entries[textEntry.id].effectData.font = value
				updateCurrentText()
			end

			local sizeControl = vgui.Create( "DNumSlider", panel )
			sizeControl:SetTall( 20 )
			sizeControl:SetText( "Size" )
			sizeControl:SetMin( 1 )
			sizeControl:SetMax( 12 )
			sizeControl:SetValue( effectData.size )
			sizeControl:SetSize( 300, 25 )
			sizeControl:SetPos( 5, 80 )

			function sizeControl:OnValueChanged( value )
				textSheet.entries[textEntry.id].effectData.size = value
				updateCurrentText()
			end

			function textEntry:OnChange()
				textSheet.entries[self.id].text = self:GetValue()

				updateCurrentText()
			end

			textSheet:AddSheet( "Line " .. #textSheet.entries, panel, "icon16/book_open.png" )
		end

		addTextLine()

		function presetPanel:OnSelect( id, name, _ )
			local contents = file.Read( "textscreen_revamped/" .. name .. ".txt", "DATA" )
			textSheet.entries = {}
			
			local tabs = textSheet:GetItems()
			for i = #tabs, 2, -1 do
				local tabData = tabs[i]
				textSheet:CloseTab( tabData.Tab, true )
			end

			local data = util.JSONToTable( contents )

			for id, entry in pairs( data.entries ) do
				addTextLine( entry.text, entry.effectData )
			end

			textSheet:CloseTab( textSheet:GetItems()[1].Tab, true )

			updateCurrentText()
		end

		-- Override this bitch since we're not using cvars
		function presetPanel:QuickSaveInternal( name )
			name = string.lower( name )
			lastPresetFiles = ""

			local data = {
				entries = textSheet.entries
			}

			file.Write( "textscreen_revamped/" .. name .. ".txt", util.TableToJSON( data, true ) )
			presetPanel:Clear()
			files, directories = file.Find( "textscreen_revamped/*.txt", "DATA" )

			for _, fileName in pairs( files ) do
				fileName = string.sub( fileName, 1, -5 ) -- Remove .txt from filename
				presetPanel:AddOption( fileName, nil )
				lastPresetFiles = lastPresetFiles .. fileName
			end
		end

		panel:AddItem( presetPanel )
		panel:AddItem( textSheet )
		panel:CheckBox( "Should Parent?", "textscreen_revamped_should_parent", false )
		panel:Help( "This enables parenting to the entity you're looking at." )

		panel:CheckBox( "Show Textscreen Bounds?", "textscreen_show_bounds" )
		panel:Help( "This enables rendering bounds when holding either the toolgun or physgun." )

		LocalPlayer().textscreen_revamped.currentTextScreenText = lastSavedTxt or ""

		net.Start( "UpdatePlayerCurrentTextscreenText" )
		net.WritePlayer(  LocalPlayer() )
		net.WriteString( lastSavedTxt or "" )
		net.SendToServer()
	end

	hook.Add( "InitPostEntity", "TextscreenRevamped_PlayerInit", function()
		for _, ply in player.Iterator() do
			ply.textscreen_revamped = ply.textscreen_revamped or {}
			if ply == LocalPlayer() then
				local lastSavedTxt = file.Read( defaultFileName, "DATA" ) or ""
				ply.textscreen_revamped.currentTextScreenText = lastSavedTxt or ""
			else
				ply.textscreen_revamped.currentTextScreenText = ply.textscreen_revamped.currentTextScreenText or ""
			end
		end
	end )
end