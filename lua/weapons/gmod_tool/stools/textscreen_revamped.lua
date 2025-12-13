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

		-- Since traces are going through the entity, I'm playing a fake tool sound just so the player knows they're doing something.
		if LocalPlayer() == ply and updated then
			surface.PlaySound( "Airboat.FireGunRevDown" )
		end

		ent:SetText( ply.textscreen_revamped.currentTextScreenText )
		ent:UpdateHTML()
	end )

	net.Receive( "UpdatePlayerCurrentTextscreenText", function()
		local ply = net.ReadPlayer()
		local txt = net.ReadString()
		if ply == LocalPlayer() then return end
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
	net.Start( "SetTextscreenText" )
	net.WriteEntity( self:GetOwner() )
	net.WriteEntity( ent )
	net.WriteBool( false )
	net.Broadcast()

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
	if CLIENT then return false end
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

	if not file.Exists( defaultFileName, "DATA" ) then
		file.Write( defaultFileName, [[
<text style="
--font: Coolvetica;
--size: 6;
--color: rgb( 180, 220, 255 );
--shadow-color: rgb( 0, 180, 255 );
--stroke-color: #0000;
">
garry's mod textscreens revamped
		]] )
	end

	function TOOL.BuildCPanel( panel )
		local presetPanel = vgui.Create( "ControlPresets" )
		local files, _ = file.Find( "textscreen_revamped/*.txt", "DATA" )

		for _, fileName in pairs( files ) do
			fileName = string.sub( fileName, 1, -5 ) -- Remove .txt from filename
			presetPanel:AddOption( fileName, nil )
		end

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

		function presetPanel:OnSelect( id, name, data )
			local contents = file.Read( "textscreen_revamped/" .. name .. ".txt", "DATA" )
			textEdit:SetValue( contents )
			LocalPlayer().textscreen_revamped.currentTextScreenText = contents

			net.Start( "UpdatePlayerCurrentTextscreenText" )
			net.WritePlayer(  LocalPlayer() )
			net.WriteString( contents )
			net.SendToServer()
		end

		-- Override this bitch since we're not using cvars
		function presetPanel:QuickSaveInternal( name )
			name = string.lower( name )
			lastPresetFiles = ""
			file.Write( "textscreen_revamped/" .. name .. ".txt", textEdit:GetValue() )
			presetPanel:Clear()
			files, directories = file.Find( "textscreen_revamped/*.txt", "DATA" )

			for _, fileName in pairs( files ) do
				fileName = string.sub( fileName, 1, -5 ) -- Remove .txt from filename
				presetPanel:AddOption( fileName, nil )
				lastPresetFiles = lastPresetFiles .. fileName
			end
		end

		timer.Remove( "Textscreen_Revamped_WatchFiles" )

		timer.Create( "Textscreen_Revamped_WatchFiles", 0.2, 0, function()
			if not presetPanel then return end
			files, directories = file.Find( "textscreen_revamped/*.txt", "DATA" )
			local newPresetFiles = ""

			for _, fileName in pairs( files ) do
				newPresetFiles = newPresetFiles .. fileName
			end

			if newPresetFiles ~= lastPresetFiles then
				lastPresetFiles = ""
				presetPanel:Clear()

				for _, fileName in pairs( files ) do
					fileName = string.sub( fileName, 1, -5 ) -- Remove .txt from filename
					presetPanel:AddOption( fileName, nil )
					lastPresetFiles = lastPresetFiles .. fileName
				end
			end

			lastPresetFiles = newPresetFiles
		end )

		panel:AddItem( presetPanel )
		panel:AddItem( textEdit )
		panel:CheckBox( "Should Parent?", "textscreen_revamped_should_parent", false )
		panel:Help( "This enables parenting to the entity you're looking at." )

		panel:CheckBox( "Show Textscreen Bounds?", "textscreen_show_bounds" )
		panel:Help( "This enables rendering bounds when holding either the toolgun or physgun." )

		net.Start( "UpdatePlayerCurrentTextscreenText" )
		net.WritePlayer(  LocalPlayer() )
		net.WriteString( lastSavedTxt )
		net.SendToServer()
	end

	hook.Add( "InitPostEntity", "TextscreenRevamped_PlayerInit", function()
		local ply = LocalPlayer()
		ply.textscreen_revamped = {}
		local lastSavedTxt = file.Read( defaultFileName, "DATA" ) or [[<font=NewFont><colour=255,255,255,255>garry's mod]]
		ply.textscreen_revamped.currentTextScreenText = lastSavedTxt
	end )
end