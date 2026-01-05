AddCSLuaFile()

if SERVER then
	util.AddNetworkString( "SetTextscreenText" )
	util.AddNetworkString( "InitTextscreenText" )
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
		{
			name = "reload"
		},
	}

	language.Add( "tool.textscreen_revamped.name", "Text Screen Revamped" )
	language.Add( "tool.textscreen_revamped.desc", "Creates a text screen." )
	language.Add( "tool.textscreen_revamped.left", "Create a Text Screen." )
	language.Add( "tool.textscreen_revamped.right", "Update a Text Screen." )
	language.Add( "tool.textscreen_revamped.reload", "Create a Text Screen In The Air." )

	net.Receive( "SetTextscreenText", function()
		local txt = net.ReadString()
		local entId = net.ReadInt( 32 )

		timer.Create( "WaitForTextscreen" .. tostring( entId ), 0.01, 0, function()
			local ent = Entity( entId )
			if not IsValid( ent ) then return end
			
			if not ent.SetText then
				timer.Remove( "WaitForTextscreen" .. tostring( entId ) )
				return
			end
			ent:SetText( txt )

			ent:UpdateHTML()
			timer.Remove( "WaitForTextscreen" .. tostring( entId ) )
		end )
	end )

	net.Receive( "RetrieveTextscreenText", function()
		local ent = net.ReadEntity()
		local txt = net.ReadString()

		ent:SetText( txt )
		ent:UpdateHTML()
	end )

	net.Receive( "InitTextscreenText", function()
		local textscreenId = net.ReadInt( 32 )
		local txt = LocalPlayer().textscreen_revamped.currentTextScreenText
		net.Start( "InitTextscreenText" )
		net.WriteInt( textscreenId, 32 )
		net.WriteString( txt )
		net.SendToServer()
	end )
end

if SERVER then
	local function SpawnTextscreen( ply, data )
		if not ply:CheckLimit( "revamped_textscreens" ) then return end
		local ent = ents.Create( "revamped_textscreen" ) --duplicator.GenericDuplicatorFunction( ply, data )
		ent.boxSize = data.Mins - data.Maxs
		ent.text = data.text
		ent.parent = data.parent

		ent:SetPos( data.Pos )
		ent:SetAngles( data.Angle )
		ent:SetNWEntity( "owner", ply )
		ent:Spawn()

		ply:AddCount( "revamped_textscreens", ent )

		return ent
	end

	duplicator.RegisterEntityClass( "revamped_textscreen", SpawnTextscreen, "Data" )
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end

	if not self:GetOwner():CheckLimit( "revamped_textscreens" ) then return true end

	if CPPI and self:GetClientBool( "should_parent" ) and IsValid( trace.Entity ) then
		local traceEnt = trace.Entity
		if not traceEnt:CPPICanTool( self:GetOwner() ) then return false end
	end

	local placeAng = trace.Normal:Angle()

	if trace.Hit then
		placeAng = trace.HitNormal:Angle()
		if math.abs( trace.HitNormal[3] ) > 0.95 then
			local offset = self:GetOwner():GetShootPos() - trace.HitPos

			local upDot = placeAng:Up():Dot( offset:GetNormalized() )
			local rightDot = placeAng:Right():Dot( offset:GetNormalized() )

			placeAng:RotateAroundAxis( placeAng:Forward(), -math.atan2( rightDot, -upDot ) * 180 / math.pi + ( trace.HitNormal[3] < 0 and 180 or 0 ) )
		end
	end

	local ent = ents.Create( "revamped_textscreen" )
	ent:SetPos( trace.HitPos + trace.HitNormal * 1 )
	ent:SetAngles( placeAng )
	ent:SetNWEntity( "owner", self:GetOwner() )
	ent.owner = self:GetOwner()

	ent:Spawn()
	ent:Activate()

	if CPPI then
		ent:CPPISetOwner( self:GetOwner() )
	end

	if not IsValid( ent ) then return end

	net.Start( "InitTextscreenText" )
	net.WriteInt( ent:EntIndex(), 32 )
	net.Send( self:GetOwner() )

	if self:GetClientBool( "should_parent" ) and IsValid( trace.Entity ) then
		ent:SetParent( trace.Entity )
	end


	undo.Create( "Text Screen" )
	undo.SetPlayer( self:GetOwner() )
	undo.AddEntity( ent )
	undo.Finish()

	self:GetOwner():AddCount( "revamped_textscreens", ent )

	return true
end


function TOOL:Reload()
	if CLIENT then return true end

	if not self:GetOwner():CheckLimit( "revamped_textscreens" ) then return true end

	local trace = util.TraceLine( {
		start = self:GetOwner():GetShootPos(),
		endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * 100,
		filter = self:GetOwner()
	} )

	if CPPI and self:GetClientBool( "should_parent" ) and IsValid( trace.Entity ) then
		local traceEnt = trace.Entity
		if not traceEnt:CPPICanTool( self:GetOwner() ) then return false end
	end

	local placeAng = trace.Normal:Angle()

	if trace.Hit then
		placeAng = trace.HitNormal:Angle()
		if math.abs( trace.HitNormal[3] ) > 0.95 then
			local offset = self:GetOwner():GetShootPos() - trace.HitPos

			local upDot = placeAng:Up():Dot( offset:GetNormalized() )
			local rightDot = placeAng:Right():Dot( offset:GetNormalized() )

			placeAng:RotateAroundAxis( placeAng:Forward(), -math.atan2( rightDot, -upDot ) * 180 / math.pi + ( trace.HitNormal[3] < 0 and 180 or 0 ) )
		end
	end

	local ent = ents.Create( "revamped_textscreen" )
	ent:SetPos( trace.HitPos )
	ent:SetAngles( placeAng )
	ent:SetNWEntity( "owner", self:GetOwner() )
	ent:Spawn()
	ent:Activate()

	if CPPI then
		ent:CPPISetOwner( self:GetOwner() )
	end

	if not IsValid( ent ) then return end

	net.Start( "InitTextscreenText" )
	net.WriteInt( ent:EntIndex(), 32 )
	net.Send( self:GetOwner() )

	if self:GetClientBool( "should_parent" ) and IsValid( trace.Entity ) then
		ent:SetParent( trace.Entity )
	end

	undo.Create( "Text Screen" )
	undo.SetPlayer( self:GetOwner() )
	undo.AddEntity( ent )
	undo.Finish()

	self:GetOwner():AddCount( "revamped_textscreens", ent )

	return true
end

function TOOL:RightClick( trace )
	if CLIENT then
		return IsValid( trace.Entity ) and trace.Entity:GetClass() == "revamped_textscreen"
	end
	local ent = trace.Entity

	if CPPI and IsValid( ent ) then
		local traceEnt = ent
		if not traceEnt:CPPICanTool( self:GetOwner() ) then return false end
	end

	if IsValid( ent ) and ent:GetClass() == "revamped_textscreen" then
		net.Start( "InitTextscreenText" )
		net.WriteInt( ent:EntIndex(), 32 )
		net.Send( self:GetOwner() )

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
	for name, data in pairs( TEXTSCREEN_REVAMPED.DEFAULT_PRESETS ) do
		file.Delete( "textscreen_revamped/" .. name .. ".txt", "DATA" )
		if not file.Exists( "textscreen_revamped/" .. name .. ".txt", "DATA" ) then
			file.Write( "textscreen_revamped/" .. name .. ".txt", util.TableToJSON( data, true ) )
		end
	end

	local function TableToColor( tbl )
		return tbl and Color( tbl.r, tbl.g, tbl.b, tbl.a ) or nil
	end

	function TOOL.BuildCPanel( panel )
		local presetPanel = vgui.Create( "ControlPresets", panel )
		local files, _ = file.Find( "textscreen_revamped/*.txt", "DATA" )

		for _, fileName in pairs( files ) do
			fileName = string.sub( fileName, 1, -5 ) -- Remove .txt from filename
			presetPanel:AddOption( fileName, nil )
		end
		
		local presetLabel = presetPanel:GetChildren()[1]
		presetLabel:SetText( "default" )

		local presetEditorIcon = presetPanel:GetChildren()[2]
		presetEditorIcon:Remove()

		local presetRemoveIcon = vgui.Create( "DButton", presetPanel )
		presetRemoveIcon:SetText( "" )
		presetRemoveIcon:SetIcon( "icon16/delete.png" )
		presetRemoveIcon:Dock( RIGHT )
		presetRemoveIcon:SetTall( 20 )
		presetRemoveIcon:SetWide( 20 )
		presetRemoveIcon:SetZPos( -1 )

		function presetRemoveIcon:Paint() end

		function presetRemoveIcon:DoClick()
			if presetLabel:GetText() ~= "default" then
				file.Delete( "textscreen_revamped/" .. presetLabel:GetText() .. ".txt" )
				
				presetPanel:Clear()
				local files, _ = file.Find( "textscreen_revamped/*.txt", "DATA" )

				for _, fileName in pairs( files ) do
					fileName = string.sub( fileName, 1, -5 ) -- Remove .txt from filename
					presetPanel:AddOption( fileName, nil )
				end
				presetLabel:SetText( "default" )
				presetPanel:OnSelect( 1, "default", nil )
			end
		end

		local textSheet = vgui.Create( "DPropertySheet", panel )
		

		textSheet:SetTall( 700 )

		textSheet.entries = {}

		local function updateCurrentText()
			local ply = LocalPlayer()
			
			ply.textscreen_revamped = ply.textscreen_revamped or {}
			ply.textscreen_revamped.currentTextScreenText = ""
			
			for i, entry in ipairs( textSheet.entries ) do

				local text = entry.text
				text = string.Replace( text, "<", "&lt;" )
				text = string.Replace( text, ">", "&gt;" )
				
				local textDataStr = entry.text
				textDataStr = string.Replace( textDataStr, "<", "&lt;" )
				textDataStr = string.Replace( textDataStr, ">", "&gt;" )
				textDataStr = string.Replace( textDataStr, "\\", "\\\\" )
				textDataStr = string.Replace( textDataStr, "\n", " \\A " )
				textDataStr = string.Replace( textDataStr, "'", "\\'" )
				textDataStr = string.Replace( textDataStr, '"', '&quot;' )

				ply.textscreen_revamped.currentTextScreenText = ply.textscreen_revamped.currentTextScreenText .. 
				string.format( [[
				<text style="
				--font: %s;
				--size: %s;
				--style: %s;
				--weight: %s;
				--color: %s;
				--stroke: %s;
				--stroke-color: %s;
				--shadow-blur: %s;
				--shadow-color: %s;
				--shadow-x: %s;
				--shadow-y: %s;
				--text-data: '%s';
				">%s</text>]], 
				entry.effectData.font, 
				entry.effectData.size, 
				entry.effectData.style,
				entry.effectData.weight,
				entry.effectData.color:ToHex(),
				entry.effectData.stroke,
				entry.effectData.strokeColor:ToHex(),
				entry.effectData.shadowBlur,
				entry.effectData.shadowColor:ToHex(),
				entry.effectData.shadowOffset[1],
				entry.effectData.shadowOffset[2],
				textDataStr,
				text ) .. "\n"
			end
		end

		-- Remove a text line and shift down the other lines properly
		-- Make sure to set new lineId's
		function textSheet.removeTextLine( id )
			if #textSheet.entries < 2 then return end
			
			table.remove( textSheet.entries, id )
			
			local tabs = textSheet:GetItems()
			for i = #tabs, 2, -1 do
				local tabData = tabs[i]
				textSheet:CloseTab( tabData.Tab, true )
			end
			for id, entry in ipairs( textSheet.entries ) do
				textSheet.addTextLine( entry.text, entry.effectData, id )
			end
			textSheet:CloseTab( textSheet:GetItems()[1].Tab, true )

			updateCurrentText()
		end
		
		function textSheet.addTextLine( text, effectData, id )
			text = text or ""
			effectData = effectData or {}
			effectData = {
				font = effectData.font or "Coolvetica",
				size = effectData.size or 6,
				style = effectData.style or "regular",
				weight = effectData.weight or "regular",
				color = TableToColor( effectData.color ) or Color( 255, 255, 255, 255 ),
				stroke = effectData.stroke or 1,
				strokeColor = TableToColor( effectData.strokeColor ) or Color( 0, 0, 0, 255 ),
				shadowBlur = effectData.shadowBlur or 1,
				shadowColor = TableToColor( effectData.shadowColor ) or Color( 0, 0, 0, 255 ),
				shadowOffset = effectData.shadowOffset or { 0, 0 },
			}

			local panel = vgui.Create( "DScrollPanel", textSheet )
			panel:DockMargin( 5, 5, 5, 5 )
			panel:Dock( FILL )
			panel:SetPaintBackgroundEnabled( true )

			panel.lineId = id

			function panel:ApplySchemeSettings()
				panel:SetBGColor( 120, 120, 120, 255 )
			end

			local buttonPanel = vgui.Create( "DPanel", panel )
			buttonPanel:DockMargin( 5, 5, 5, 0 )
			buttonPanel:Dock( TOP )
			buttonPanel:SetTall( 20 )
			function buttonPanel:Paint() end

			-- Add a button to add a new text line
			local addLineButton = vgui.Create( "DButton", buttonPanel )
			addLineButton:SetIcon( "icon16/add.png" )
			addLineButton:SetText( "" )
			addLineButton:Dock( RIGHT )
			addLineButton:SetWidth( 20 )
			addLineButton:SetHeight( 20 )
			addLineButton:SetTooltip( "Add a new text line" )
			--addLineButton:DockPadding( 0, 0, 0, 0 )

			addLineButton.Paint = function() end

			addLineButton.DoClick = function()
				textSheet.addTextLine( nil, nil, #textSheet.entries + 1 )
			end

			local removeLineButton = vgui.Create( "DButton", buttonPanel )
			removeLineButton:SetIcon( "icon16/delete.png" )
			removeLineButton:SetText( "" )
			removeLineButton:Dock( RIGHT )
			removeLineButton:SetWidth( 20 )
			removeLineButton:SetHeight( 20 )
			removeLineButton:SetTooltip( "Remove this text line" )
			--removeLineButton:DockPadding( 0, 0, 0, 0 )

			removeLineButton.Paint = function() end

			removeLineButton.DoClick = function()
				textSheet.removeTextLine( panel.lineId )
			end

			-- font dropdown
			local fontControl = vgui.Create( "DComboBox", panel )
			fontControl:DockMargin( 50, 5, 5, 5 )
			fontControl:Dock( TOP )
			fontControl:InvalidateParent( true )

			fontControl.label = vgui.Create( "DLabel", panel )
			fontControl.label:SetText( "Font" )
			fontControl.label:SetPos( fontControl:GetX() - 45, fontControl:GetY() )

			for _, font in pairs( TEXTSCREEN_REVAMPED.FONTS ) do
				fontControl:AddChoice( font )
			end

			fontControl:SetValue( effectData.font )

			function fontControl:OnSelect( index, value, data )
				textSheet.entries[panel.lineId].effectData.font = value
				updateCurrentText()
			end

			local orderIndex = 0

			-- Text box
			local textEntry = vgui.Create( "DTextEntry", panel )
			textEntry:SetMultiline( true )
			textEntry:SetUpdateOnType( true )
			textEntry:DockMargin( 5, 5, 5, 5 )
			textEntry:SetHeight( 50 )
			textEntry:SetValue( text )
			textEntry:Dock( TOP )
			textEntry:SetZPos( orderIndex )
			orderIndex = orderIndex + 1

			textSheet.entries[panel.lineId] = {
				text = text,
				effectData = effectData
			}

			local sizeControl = vgui.Create( "DNumSlider", panel )
			sizeControl:SetTall( 20 )
			sizeControl:SetText( "Size" )
			sizeControl:SetMin( 1 )
			sizeControl:SetMax( 12 )
			sizeControl:SetValue( effectData.size )
			sizeControl:DockMargin( 5, 5, 5, 5 )
			sizeControl:Dock( TOP )
			sizeControl:SetZPos( orderIndex )
			orderIndex = orderIndex + 1

			function sizeControl:OnValueChanged( value )
				textSheet.entries[panel.lineId].effectData.size = value
				updateCurrentText()
			end
			--[[
			local weightControl = vgui.Create( "DNumSlider", panel )
			weightControl:SetTall( 20 )
			weightControl:SetText( "Weight" )
			weightControl:SetMin( 200 )
			weightControl:SetMax( 800 )
			weightControl:SetDecimals( 0 )
			weightControl:SetValue( effectData.weight )
			weightControl:DockMargin( 5, 5, 5, 5 )
			weightControl:Dock( TOP )
			weightControl:SetZPos( orderIndex )
			orderIndex = orderIndex + 1

			function weightControl:OnValueChanged( value )
				textSheet.entries[panel.lineId].effectData.weight = value
				updateCurrentText()
			end
			]]

			local styleControl = vgui.Create( "DListView", panel )
			styleControl:SetMultiSelect( false )
			styleControl:SetSortable( false )
			styleControl:SetTall( 100 )
			styleControl:DockMargin( 5, 5, 5, 5 )
			styleControl:Dock( TOP )
			styleControl:SetZPos( orderIndex )
			orderIndex = orderIndex + 1

			styleControl:AddColumn( "Style" )
			styleControl:AddColumn( "Weight" )

			for _, style in pairs( TEXTSCREEN_REVAMPED.STYLES ) do
				styleControl:AddLine( style.style, style.weight )
			end

			function styleControl:OnRowSelected( index, line )
				textSheet.entries[panel.lineId].effectData.style = line:GetValue( 1 )
				textSheet.entries[panel.lineId].effectData.weight = line:GetValue( 2 )
				updateCurrentText()
			end


			local colorControl = vgui.Create( "DColorMixer", panel )
			colorControl:SetSize( 200, 160 )
			colorControl:SetColor( effectData.color )
			colorControl:DockMargin( 50, 5, 5, 5 )
			colorControl:Dock( TOP )
			colorControl:SetZPos( orderIndex )
			colorControl:InvalidateParent( true )
			orderIndex = orderIndex + 1

			colorControl.label = vgui.Create( "DLabel", panel )
			colorControl.label:SetPos( colorControl:GetX() - 45, colorControl:GetY() )
			colorControl.label:SetText( "Color" )
			colorControl.label:SetZPos( orderIndex )
			orderIndex = orderIndex + 1

			function colorControl:ValueChanged( color )
				textSheet.entries[panel.lineId].effectData.color = TableToColor( color )
				updateCurrentText()
			end

			local effectSheet = vgui.Create( "DPropertySheet", panel )
			effectSheet:Dock( TOP )
			effectSheet:SetTall( 300 )
			effectSheet:DockMargin( 5, 5, 5, 5 )
			effectSheet:SetZPos( orderIndex )
			orderIndex = orderIndex + 1
			
			local strokePanel = vgui.Create( "DPanel", effectSheet )
			strokePanel:DockMargin( 5, 0, 5, 5 )
			strokePanel:Dock( FILL )
			strokePanel:SetPaintBackgroundEnabled( true )

			function strokePanel:ApplySchemeSettings()
				strokePanel:SetBGColor( 120, 120, 120, 255 )
			end

			local strokeControl = vgui.Create( "DNumSlider", strokePanel )
			strokeControl:SetTall( 20 )
			strokeControl:SetText( "Stroke" )
			strokeControl:SetMin( 0 )
			strokeControl:SetMax( 10 )
			strokeControl:SetValue( effectData.stroke )
			strokeControl:SetSize( 300, 25 )
			strokeControl:DockMargin( 5, 0, 5, 5 )
			strokeControl:Dock( TOP )

			function strokeControl:OnValueChanged( value )
				textSheet.entries[panel.lineId].effectData.stroke = value
				updateCurrentText()
			end
			
			local strokeColorControl = vgui.Create( "DColorMixer", strokePanel )
			strokeColorControl:SetPos( 5, 30 )
			strokeColorControl:SetSize( 200, 160 )
			strokeColorControl:SetColor( effectData.strokeColor )
			strokeColorControl:DockMargin( 5, 0, 5, 5 )
			strokeColorControl:Dock( TOP )

			function strokeColorControl:ValueChanged( color )
				textSheet.entries[panel.lineId].effectData.strokeColor = TableToColor( color )
				updateCurrentText()
			end

			effectSheet:AddSheet( "Stroke", strokePanel, "icon16/pencil.png" )

			local shadowPanel = vgui.Create( "DPanel", effectSheet )
			shadowPanel:DockMargin( 5, 0, 5, 5 )
			shadowPanel:Dock( FILL )
			shadowPanel:SetPaintBackgroundEnabled( true )

			function shadowPanel:ApplySchemeSettings()
				shadowPanel:SetBGColor( 120, 120, 120, 255 )
			end

			local shadowBlurControl = vgui.Create( "DNumSlider", shadowPanel )
			shadowBlurControl:SetTall( 20 )
			shadowBlurControl:SetText( "Shadow Blur" )
			shadowBlurControl:SetMin( 0 )
			shadowBlurControl:SetMax( 10 )
			shadowBlurControl:SetValue( effectData.shadowBlur )
			shadowBlurControl:SetSize( 300, 25 )
			shadowBlurControl:DockMargin( 5, 0, 5, 5 )
			shadowBlurControl:Dock( TOP )

			function shadowBlurControl:OnValueChanged( value )
				textSheet.entries[panel.lineId].effectData.shadowBlur = value
				updateCurrentText()
			end

			local shadowColorControl = vgui.Create( "DColorMixer", shadowPanel )
			shadowColorControl:SetPos( 5, 30 )
			shadowColorControl:SetSize( 200, 160 )
			shadowColorControl:SetColor( effectData.shadowColor )
			shadowColorControl:DockMargin( 5, 5, 5, 5 )
			shadowColorControl:Dock( TOP )

			function shadowColorControl:ValueChanged( color )
				textSheet.entries[panel.lineId].effectData.shadowColor = TableToColor( color )
				updateCurrentText()
			end
			
			local shadowOffsetControlX = vgui.Create( "DNumSlider", shadowPanel )
			shadowOffsetControlX:SetTall( 20 )
			shadowOffsetControlX:SetText( "Shadow Offset X" )
			shadowOffsetControlX:SetMin( -10 )
			shadowOffsetControlX:SetMax( 10 )
			shadowOffsetControlX:SetValue( effectData.shadowOffset[1] )
			shadowOffsetControlX:SetSize( 300, 25 )
			shadowOffsetControlX:DockMargin( 5, 0, 5, 5 )
			shadowOffsetControlX:Dock( TOP )

			function shadowOffsetControlX:OnValueChanged( value )
				textSheet.entries[panel.lineId].effectData.shadowOffset[1] = value
				updateCurrentText()
			end

			local shadowOffsetControlY = vgui.Create( "DNumSlider", shadowPanel )
			shadowOffsetControlY:SetTall( 20 )
			shadowOffsetControlY:SetText( "Shadow Offset Y" )
			shadowOffsetControlY:SetMin( -10 )
			shadowOffsetControlY:SetMax( 10 )
			shadowOffsetControlY:SetValue( effectData.shadowOffset[2] )
			shadowOffsetControlY:SetSize( 300, 25 )
			shadowOffsetControlY:DockMargin( 5, 0, 5, 5 )
			shadowOffsetControlY:Dock( TOP )

			function shadowOffsetControlY:OnValueChanged( value )
				textSheet.entries[panel.lineId].effectData.shadowOffset[2] = value
				updateCurrentText()
			end

			effectSheet:AddSheet( "Shadow", shadowPanel, "icon16/shading.png" )

			function textEntry:OnChange()
				if self:GetValue() == "" then
					textSheet.entries[panel.lineId].text = "[Insert Text Here]"
				else
					textSheet.entries[panel.lineId].text = self:GetValue()
				end
				updateCurrentText()
			end

			textSheet:AddSheet( "Line " .. panel.lineId, panel, "icon16/book_open.png" )
		end

		textSheet.addTextLine( nil, nil, 1 )

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
				textSheet.addTextLine( entry.text, entry.effectData, id )
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

		timer.Simple( 0, function()
			presetPanel:OnSelect( 1, "default", nil )
		end )

		panel:AddItem( presetPanel )
		panel:AddItem( textSheet )
		panel:CheckBox( "Should Parent?", "textscreen_revamped_should_parent", false )
		panel:Help( "This enables parenting to the entity you're looking at." )

		panel:CheckBox( "Show Textscreen Bounds?", "textscreen_show_bounds" )
		panel:Help( "This enables rendering bounds when holding either the toolgun or physgun." )

		local renderDistanceSlider = vgui.Create( "DNumSlider", panel )
		renderDistanceSlider:SetText( "Render Distance" )
		renderDistanceSlider:SetMin( 0 )
		renderDistanceSlider:SetMax( 10000 )
		renderDistanceSlider:SetValue( TEXTSCREEN_REVAMPED.RenderDistanceCVar:GetInt() )
		renderDistanceSlider:SetDecimals( 0 )
		renderDistanceSlider:SetConVar( "textscreen_render_distance" )
		renderDistanceSlider:Dock( TOP )
		renderDistanceSlider:SetDark( true )

		panel:AddItem( renderDistanceSlider )
		panel:Help( "This controls the render distance of the textscreen. 0 = don't draw any textscreens" )

		LocalPlayer().textscreen_revamped.currentTextScreenText = lastSavedTxt or ""
	end

	hook.Add( "InitPostEntity", "TextscreenRevamped_PlayerInit", function()
		LocalPlayer().textscreen_revamped = LocalPlayer().textscreen_revamped or {}
		LocalPlayer().textscreen_revamped.currentTextScreenText = LocalPlayer().textscreen_revamped.currentTextScreenText or ""

		local textscreens = ents.FindByClass( "revamped_textscreen" )
		for _, textscreen in pairs( textscreens ) do
			net.Start( "RetrieveTextscreenText" )
			net.WritePlayer( LocalPlayer() )
			net.WriteEntity( textscreen )
			net.SendToServer()
		end
	end )
end