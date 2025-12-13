AddCSLuaFile()

if SERVER then
	util.AddNetworkString( "SetTextscreenText" )
end

TOOL.Author = "Mikey"
TOOL.Name = "#tool.textscreen_revamped.name"
TOOL.Category = "Text Screens Revamped"
TOOL.ClientConVar["size_x"] = 500
TOOL.ClientConVar["size_y"] = 300


if CLIENT then
	TOOL.Information = {
		{
			name = "left"
		},
	}

	language.Add( "tool.textscreen_revamped.name", "Text Screen Revamped" )
	language.Add( "tool.textscreen_revamped.desc", "Creates a text screen." )
	language.Add( "tool.textscreen_revamped.left", "Create a Text Screen." )

	net.Receive( "SetTextscreenText", function()
		local ply = net.ReadEntity()
		local ent = net.ReadEntity()
		local updated = net.ReadBool()
		local sizeX = net.ReadFloat()
		local sizeY = net.ReadFloat()

		-- Since traces are going through the entity, I'm playing a fake tool sound just so the player knows they're doing something.
		if LocalPlayer() == ply and updated then
			surface.PlaySound( "Airboat.FireGunRevDown" )
		end

		ent:SetSize( Vector( sizeX, sizeY, 0 ) )
		ent:SetText( ply.textscreen_revamped.currentTextScreenText )
	end )
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end

	local ent = ents.Create( "textscreen" )
	ent:SetPos( trace.HitPos + trace.HitNormal * 1 )
	ent:SetAngles( trace.HitNormal:Angle() )
	ent:Spawn()
	ent:Activate()
	ent:SetNW2Entity( "owner", self:GetOwner() )

	timer.Simple( 0.1, function()
		if not IsValid( ent ) then return end
		net.Start( "SetTextscreenText" )
		net.WriteEntity( self:GetOwner() )
		net.WriteEntity( ent )
		net.WriteBool( false )
		net.WriteFloat( self:GetClientNumber( "size_x" ) )
		net.WriteFloat( self:GetClientNumber( "size_y" ) )
		net.Broadcast()
	end )

	if IsValid( trace.Entity ) then
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
--size: 5;
--color: rgb( 180, 220, 255 );
--shadow-color: rgb( 0, 180, 255 );
">
garry's mod
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
		local lastSavedTxt = file.Read( defaultFileName, "DATA" ) or [[
		<text style="
		--font: Coolvetica;
		--size: 5;
		--color: rgb( 180, 220, 255 );
		--shadow-color: rgb( 0, 180, 255 );
		">
		garry's mod
		]]
		textEdit:SetValue( lastSavedTxt )
		textEdit:SetUpdateOnType( true )

		function textEdit:OnValueChange( text )
			LocalPlayer().textscreen_revamped.currentTextScreenText = text
		end

		function presetPanel:OnSelect( id, name, data )
			local contents = file.Read( "textscreen_revamped/" .. name .. ".txt", "DATA" )
			textEdit:SetValue( contents )
			LocalPlayer().textscreen_revamped.currentTextScreenText = contents
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
	end

	hook.Add( "InitPostEntity", "TextscreenRevamped_PlayerInit", function()
		local ply = LocalPlayer()
		ply.textscreen_revamped = {}
		local lastSavedTxt = file.Read( defaultFileName, "DATA" ) or [[<font=NewFont><colour=255,255,255,255>garry's mod]]
		ply.textscreen_revamped.currentTextScreenText = lastSavedTxt
	end )
end