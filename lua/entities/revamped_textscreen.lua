AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Text Screen"
ENT.Author = "Mikey"
ENT.Spawnable = false
ENT.PhysicsSounds = true
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.AutomaticFrameAdvance = true

AddCSLuaFile( "includes/3d2dvgui.lua" )
AddCSLuaFile( "includes/purify.lua" )

if CLIENT then
	include( "includes/3d2dvgui.lua" )
	language.Add("sboxlimit_revamped_textscreens", "You've hit the Textscreens limit!")
else
	util.AddNetworkString( "RetrieveTextscreenText" )

	CreateConVar( "sbox_maxrevamped_textscreens", 10, { FCVAR_NOTIFY }, "Maximum textscreens a single player can create" )

	function tableToColor( tbl )
		return Color( tbl.r, tbl.g, tbl.b, tbl.a )
	end

	function SetTextscreenText( textscreen, width, height )
		if not IsValid( textscreen ) or textscreen.boxSize then
			if IsValid( textscreen ) and IsValid( textscreen:GetParent() ) then
				textscreen:SetNotSolid( true )
			end
			return
		end
		
		local scale = Vector( 0.5, width, height )

		textscreen.Mins, textscreen.Maxs = -scale * 0.5, scale * 0.5

		textscreen:PhysicsInitBox( Vector( scale.x * -0.5, scale.y * -0.5, scale.z * -0.5 ), Vector( scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 ) )
		textscreen:SetCollisionBounds( Vector( scale.x * -0.5, scale.y * -0.5, scale.z * -0.5 ), Vector( scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 ) )
		textscreen:SetMoveType( MOVETYPE_VPHYSICS )
		textscreen:SetSolid( SOLID_VPHYSICS )
		textscreen:EnableCustomCollisions( true )

		textscreen:SetCollisionGroup( COLLISION_GROUP_WORLD )
		local mass = 50
		textscreen:GetPhysicsObject():SetMass( mass )
		textscreen:SetSolidFlags( 0 )
		textscreen:AddSolidFlags( FSOLID_CUSTOMRAYTEST )
		textscreen:AddSolidFlags( FSOLID_CUSTOMBOXTEST )

		textscreen:CollisionRulesChanged()

		if IsValid( textscreen:GetParent() ) then
			textscreen:SetNotSolid( true )
		end

		textscreen.PhysCollide = CreatePhysCollideBox( Vector( scale.x * -0.5, scale.y * -0.5, scale.z * -0.5 ), Vector( scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 ) )
		
	end

	-- This is used to scale the textscreen physics based on the text length
	net.Receive( "SetTextscreenText", function( _, ply )
		local textscreen = net.ReadEntity()

		if not IsValid( textscreen ) then return end
		
		if CPPI and not textscreen:CPPIGetOwner() == ply then
			return
		elseif textscreen:GetNWEntity( "owner" ) ~= ply then
			return
		end
		
		local w = math.Clamp( net.ReadFloat(), 0, 1024 )
		local h = math.Clamp( net.ReadFloat(), 0, 1024 )
		local entryCount = net.ReadUInt( 8 )
		local entries = {}
		for i = 1, entryCount do
			entries[i] = {}
			entries[i].effectData = {}
			entries[i].text = net.ReadString()
			entries[i].effectData.font = net.ReadString()
			entries[i].effectData.size = net.ReadFloat()
			entries[i].effectData.style = net.ReadString()
			entries[i].effectData.weight = net.ReadString()
			entries[i].effectData.color = net.ReadColor()
			entries[i].effectData.stroke = net.ReadFloat()
			entries[i].effectData.strokeColor = net.ReadColor()
			entries[i].effectData.shadowBlur = net.ReadFloat()
			entries[i].effectData.shadowColor = net.ReadColor()
			entries[i].effectData.shadowOffset = { net.ReadFloat(), net.ReadFloat() }
		end
		local fullbright = net.ReadBool()
		local pixelized = net.ReadBool()

		local block = hook.Run( "RevampedTextscreen_CanCreate", textscreen:GetNWEntity( "owner" ), entries )
		
		if block then
			SafeRemoveEntityDelayed( textscreen, 0 )
			return
		end

		textscreen.entries = entries
		textscreen.fullbright = fullbright
		textscreen.pixelized = pixelized

		SetTextscreenText( textscreen, w, h )
	end )

	gameevent.Listen( "OnRequestFullUpdate" )
	hook.Add( "OnRequestFullUpdate", "TextscreenRevamped_RetrieveTextscreenText", function( data )
		local UID = data.userid
		local ply = Player( UID )
		if ply.textscreensRetrieved then return end
		RetrieveTextscreenText( ply )
		ply.textscreensRetrieved = true
	end )

	function RetrieveTextscreenText( ply )
		local textscreens = ents.FindByClass( "revamped_textscreen" )
		local retrieveCor = coroutine.wrap( function()
			for _, textscreen in ipairs( textscreens ) do
				local entries = textscreen.entries
				local fullbright = textscreen.fullbright
				local pixelized = textscreen.pixelized

				net.Start( "RetrieveTextscreenText" )
				net.WriteEntity( textscreen )
				net.WriteUInt( #entries, 8 )
				net.WriteBool( fullbright )
				net.WriteBool( pixelized )
				for i = 1, #entries do
					net.WriteString( entries[i].text )
					net.WriteString( entries[i].effectData.font )
					net.WriteFloat( entries[i].effectData.size )
					net.WriteString( entries[i].effectData.style )
					net.WriteString( entries[i].effectData.weight )
					net.WriteColor( entries[i].effectData.color )
					net.WriteFloat( entries[i].effectData.stroke )
					net.WriteColor( entries[i].effectData.strokeColor )
					net.WriteFloat( entries[i].effectData.shadowBlur )
					net.WriteColor( entries[i].effectData.shadowColor )
					net.WriteFloat( entries[i].effectData.shadowOffset[1] )
					net.WriteFloat( entries[i].effectData.shadowOffset[2] )
				end
				net.Send( ply )
				coroutine.yield()
			end
			return true
		end )

		timer.Create( "RetrieveTextscreenText" .. tostring( ply ), 0.1, 0, function()
			if retrieveCor() then
				timer.Remove( "RetrieveTextscreenText" .. tostring( ply ) )
			end
		end )
	end

	net.Receive( "InitTextscreenText", function( _, ply )
		local textscreenId = net.ReadUInt( MAX_EDICT_BITS )

		local entryCount = net.ReadUInt( 8 )
		local fullbright = net.ReadBool()
		local pixelized = net.ReadBool()

		net.Start( "SetTextscreenText" )
		net.WriteUInt( textscreenId, MAX_EDICT_BITS )
		net.WriteUInt( entryCount, 8 )
		net.WriteBool( fullbright )
		net.WriteBool( pixelized )
		for i = 1, entryCount do
			net.WriteString( net.ReadString() )

			net.WriteString( net.ReadString() )
			net.WriteFloat( net.ReadFloat() )
			net.WriteString( net.ReadString() )
			net.WriteString( net.ReadString() )
			net.WriteColor( net.ReadColor() )
			net.WriteFloat( net.ReadFloat() )
			net.WriteColor( net.ReadColor() )
			net.WriteFloat( net.ReadFloat() )
			net.WriteColor( net.ReadColor() )
			net.WriteFloat( net.ReadFloat() )
			net.WriteFloat( net.ReadFloat() )
		end
		net.Broadcast()
	end )
end

function ENT:Initialize()
	if SERVER then
		local ply = self:GetNWEntity( "owner" )

		self:SetModel( "models/hunter/blocks/cube05x05x05.mdl" )
		self:SetMaterial( "models/debug/debugwhite" )
		self:SetRenderMode( RENDERMODE_TRANSCOLOR )
		
		if self.entries then -- Basically if it's duped d:
			net.Start( "SetTextscreenText" )
			net.WriteUInt( self:EntIndex(), MAX_EDICT_BITS )
			net.WriteUInt( #self.entries, 8 )
			net.WriteBool( self.fullbright )
			net.WriteBool( self.pixelized )
			for i = 1, #self.entries do
				net.WriteString( self.entries[i].text )
				net.WriteString( self.entries[i].effectData.font )
				net.WriteFloat( self.entries[i].effectData.size )
				net.WriteString( self.entries[i].effectData.style )
				net.WriteString( self.entries[i].effectData.weight )
				net.WriteColor( tableToColor( self.entries[i].effectData.color ) )
				net.WriteFloat( self.entries[i].effectData.stroke )
				net.WriteColor( tableToColor( self.entries[i].effectData.strokeColor ) )
				net.WriteFloat( self.entries[i].effectData.shadowBlur )
				net.WriteColor( tableToColor( self.entries[i].effectData.shadowColor ) )
				net.WriteFloat( self.entries[i].effectData.shadowOffset[1] )
				net.WriteFloat( self.entries[i].effectData.shadowOffset[2] )
			end
			net.Broadcast()

			self:PhysicsInitBox( -self.boxSize * 0.5, self.boxSize * 0.5 )
			self:SetCollisionBounds( -self.boxSize * 0.5, self.boxSize * 0.5 )
			self:SetMoveType( MOVETYPE_VPHYSICS )
			self:SetSolid( SOLID_VPHYSICS )
			self:EnableCustomCollisions( true )

			self:SetCollisionGroup( COLLISION_GROUP_WORLD )
			local mass = 50
			self:GetPhysicsObject():SetMass( mass )
			self:SetSolidFlags( 0 )
			self:AddSolidFlags( FSOLID_CUSTOMRAYTEST )
			self:AddSolidFlags( FSOLID_CUSTOMBOXTEST )

			self:CollisionRulesChanged()

			self.PhysCollide = CreatePhysCollideBox( -self.boxSize * 0.5, self.boxSize * 0.5 )
		end
	end

	if CLIENT then
		self.originalModelSize = self:OBBMaxs()
		self.pixelScale = 0.2
		self.size = Vector( 0, 0, 0 )
		self.htmlPanel = nil--vgui.Create( "DHTML" )
		--self.htmlPanel:SetSize( self.size[1], self.size[2] )
		self.firstFrame = true
		self.nextRenderCheck = 0.1
		self.modelColor = Color( 255, 0, 0, 5 )
		self.sizeAnim = 0
		self.shouldDraw = true
		self.entries = self.entries or {}
		self.fullbright = self.fullbright == nil and false or self.fullbright
		self.pixelized = self.pixelized == nil and false or self.pixelized
		self.mesh = Mesh()
	end
	self:DrawShadow( false )
end

if SERVER then
	function ENT:OnDuplicated( data )
		net.Start( "SetTextscreenText" )
		net.WriteTable( data.entries )
		net.WriteBool( data.fullbright )
		net.WriteInt( self:EntIndex(), 32 )
		net.Broadcast()
	end
end

function ENT:TestCollision( startpos, delta, isbox, extents )
    if not IsValid( self.PhysCollide ) then
        return
    end

    -- TraceBox expects the trace to begin at the center of the box, but TestCollision is bad
    local max = extents
    local min = -extents
    max.z = max.z - min.z
    min.z = 0

    local hit, norm, frac = self.PhysCollide:TraceBox( self:GetPos(), self:GetAngles(), startpos, startpos + delta, min, max )

    if not hit then
        return
    end

    return { 
        HitPos = hit,
        Normal  = norm,
        Fraction = frac,
    }
end

if CLIENT then
	function ENT:SetFullbright( b )
		self.fullbright = b
	end

	function ENT:SetPixelized( b )
		self.pixelized = b
	end

	function ENT:SetSize( size )
		self.size = size
		self.htmlPanel:SetSize( self.size[1], self.size[2] )
	end

	function ENT:SetText( text )
		self.text = text
	end

	function ENT:Think()
		if CLIENT then
			local physobj = self:GetPhysicsObject()

			if not IsValid( self.PhysCollide ) then
				local scale = Vector( 0.5, self.size[1] * self.pixelScale, self.size[2] * self.pixelScale )

				self.PhysCollide = CreatePhysCollideBox( Vector( scale.x * -0.5, scale.y * -0.5, scale.z * -0.5 ), Vector( scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 ) )
			end

			if IsValid( physobj ) then
				physobj:SetPos( self:GetPos() )
				physobj:SetAngles( self:GetAngles() )
			end
			if IsValid( self.htmlPanel ) and self.htmlPanel:GetHTMLMaterial() then
				if self.shouldDraw then
					if self.sizeAnim <= 0 then
						self:SetNoDraw( false )
					end
					self.sizeAnim = math.min( self.sizeAnim + FrameTime() * 2, 1 )
				else
					self.sizeAnim = math.max( 0, self.sizeAnim - FrameTime() * 2 )
					if self.sizeAnim <= 0 then
						self:SetNoDraw( not ( self:GetNWEntity( "owner" ) == LocalPlayer() and self.firstFrame ) )
					end
				end
			end

			self.nextRenderCheck = self.nextRenderCheck - FrameTime()

			if self.nextRenderCheck <= 0 then
				local renderDist = TEXTSCREEN_REVAMPED.RenderDistanceCVar:GetFloat() ^ 2
				local eyeDist = LocalPlayer():EyePos():DistToSqr( self:GetPos() )
				self.shouldDraw = ( self:GetNWEntity( "owner" ) == LocalPlayer() and self.firstFrame ) or eyeDist <= renderDist
				self.nextRenderCheck = 0.1
			end
		end
	end

	function ENT:OnRemove()
		if self.htmlPanel == nil then return end
		self.htmlPanel:Remove()
		self.PhysCollide:Destroy()
	end

	function ENT:UpdateHTML()
		if IsValid( self.htmlPanel ) then
			self.htmlPanel:Remove()
		end

		self.htmlPanel = vgui.Create( "DHTML" )

		self.htmlPanel:SetSize( 0, 0 )
		local newHtml = ""

		newHtml = newHtml .. [[
			<head>
				<meta name="referrer" content="origin" />
				<style>
		]]

		for i, fontName in ipairs( TEXTSCREEN_REVAMPED.FONTS ) do
			newHtml = newHtml .. string.format([[
				@font-face {
					font-family: '%s'; /* The name you will use in CSS */
					src: url('asset://garrysmod/resource/fonts/%s.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
				}
			]], fontName, fontName )
		end

		newHtml = newHtml .. [[
					body {
						background: transparent;
						overflow: hidden;
						overflow-wrap: anywhere;
						margin: 0;
						padding: 0;
						paint-order: stroke fill;
						user-select: none;
						--font: 'Arial';
						--size: 6;
						--weight: 400;
						--style: none;
						--color: rgb(255, 255, 255);
						--shadow-color: rgba( 0, 0, 0, 0.0 );
						--shadow-blur: 1;
						--shadow-x: 0;
						--shadow-y: 0;
						--stroke: 1;
						--stroke-color: rgba( 0, 0, 0, 1 );
					}

					.container {
						display: flex;
						flex-direction: column;
						position: relative;
						padding: 0;
						margin: 0;
						overflow: hidden;
						overflow-wrap: anywhere;
						width: max-content;
						height: max-content;
						align-items: center;
						justify-content: center;
						background: #fff0;
						max-width: 1024px;
						max-height: 1024px;
					}
					text {
						display: block;
						position: relative;
						text-align: center;
						white-space: pre-wrap;
						color: var(--color);
						margin: 
							calc( max( 0.01, max( 0, var( --shadow-y ) * -1 ) * 0.2 ) * 1em + var(--shadow-blur) * 0.2em )
							calc( max( 0.01, max( 0, var( --shadow-x ) ) * 0.2 ) * 1em + var(--shadow-blur) * 0.2em )
							calc( max( 0.01, max( 0, var( --shadow-y ) ) * 0.2 ) * 1em + var(--shadow-blur) * 0.2em )
							calc( max( 0.01, max( 0, var( --shadow-x ) * -1 ) * 0.2 ) * 1em + var(--shadow-blur) * 0.2em );
						padding: 0;
						font-weight: var(--weight);
						font-family: var(--font);
						font-size: calc( var(--size) * 1em );
						font-style: var(--style);
						text-shadow:
							calc( var( --shadow-x ) * 0.2em ) calc( var( --shadow-y ) * 0.2em ) calc( var( --shadow-blur ) * 0.1em ) var( --shadow-color ),
							calc( var( --shadow-x ) * 0.2em ) calc( var( --shadow-y ) * 0.2em ) calc( var( --shadow-blur ) * 0.1em ) var( --shadow-color ),
							calc( var( --shadow-x ) * 0.2em ) calc( var( --shadow-y ) * 0.2em ) calc( var( --shadow-blur ) * 0.1em ) var( --shadow-color );
						-webkit-text-stroke: calc( var( --stroke ) * ( var( --size ) / 6 ) * 3px ) var( --stroke-color );
					}
				</style>
			</head>
			<body>
				<div class="container" id="main">
		]]

		

		self.htmlPanel:QueueJavascript( TEXTSCREEN_REVAMPED.DOMPurify )
		local entries = self.entries

		local txt = ""
		for i, entry in ipairs( entries ) do
			local entryTxt = entry.text
			-- replace angle brackets with html safe
			entryTxt = string.Replace( entryTxt, "<", "&lt;" )
			entryTxt = string.Replace( entryTxt, ">", "&gt;" )
			txt = txt .. string.format( [[
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
				">%s</text>]], 
				entry.effectData.font, 
				entry.effectData.size, 
				entry.effectData.style,
				entry.effectData.weight,
				entry.effectData.color and ToHex( entry.effectData.color ) or "#FFFFFF",
				entry.effectData.stroke,
				entry.effectData.strokeColor and ToHex( entry.effectData.strokeColor ) or "#000000",
				entry.effectData.shadowBlur,
				entry.effectData.shadowColor and ToHex( entry.effectData.shadowColor ) or "#000000",
				entry.effectData.shadowOffset[1],
				entry.effectData.shadowOffset[2],
				entryTxt ) .. "\n"
		end

		txt = string.Replace( txt, ">\n", ">" ) -- Remove line breaks right after tags
		txt = string.TrimRight( txt )

		--[[
		self.htmlPanel:AddFunction( "textscreen", "sanitizeText", function( sanitizedText )
			
		end )
		]]
		--txt = sanitizedText

		newHtml = newHtml .. txt
		newHtml = newHtml .. "</div>"
		newHtml = newHtml .. "</body>"

		self.htmlPanel:SetHTML( newHtml )
		--self.htmlPanel:SetPaintedManually( true )
		self.htmlPanel:SetPaintedManually( true )

		self.htmlPanel:AddFunction( "textscreen", "resizeTextscreen", function( w, h )
			--self.pixelScale = 0.1 * w * h / 1024^2
			--w = w * self.pixelScale
			--h = h * self.pixelScale

			local scale = Vector( 0.5, w * self.pixelScale, h * self.pixelScale )
			local sclMat = Matrix()
			sclMat:SetScale( scale / ( self.originalModelSize[1] - 0.25 ) / 2 )
			self:EnableMatrix( "RenderMultiply", sclMat )
			self:SetRenderBounds( -scale, scale )
			self:SetSize( Vector( w, h, 0 ) )

			timer.Simple( 0.02, function()
				self.meshUpdated = true
			end )

			if LocalPlayer() ~= self:GetNWEntity( "owner" ) then return end

			net.Start( "SetTextscreenText" )
			net.WriteEntity( self )
			net.WriteFloat( scale[2] )
			net.WriteFloat( scale[3] )
			net.WriteUInt( #self.entries, 8 )
			for _, entry in ipairs( self.entries ) do
				net.WriteString( entry.text )
				local effectData = entry.effectData or {}
				net.WriteString( effectData.font )
				net.WriteFloat( effectData.size )
				net.WriteString( effectData.style )
				net.WriteString( effectData.weight )
				net.WriteColor( effectData.color )
				net.WriteFloat( effectData.stroke )
				net.WriteColor( effectData.strokeColor )
				net.WriteFloat( effectData.shadowBlur )
				net.WriteColor( effectData.shadowColor )
				net.WriteFloat( effectData.shadowOffset and effectData.shadowOffset[1] )
				net.WriteFloat( effectData.shadowOffset and effectData.shadowOffset[2] )
			end
			net.WriteBool( self.fullbright )
			net.WriteBool( self.pixelized )
			net.SendToServer()
		end )

		self.htmlPanel:QueueJavascript( [[
			const elem = document.getElementById( "main" );
			var rect = elem.getBoundingClientRect();
			textscreen.resizeTextscreen( rect.width, rect.height );
		]] )
	end

	local debugwhite = Material( "debug/env_cubemap_model" )

	function ENT:DrawModelOrMesh()
		if not IsValid( self.htmlPanel ) and self.text ~= "" then
			self:UpdateHTML()
		end

		if self.size[1] <= 0 or self.size[2] <= 0 then return end

		self.htmlPanel:UpdateHTMLTexture()

		local renderCube = IsValid( LocalPlayer():GetActiveWeapon() ) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool"
		renderCube = renderCube or IsValid( LocalPlayer():GetActiveWeapon() ) and LocalPlayer():GetActiveWeapon():GetClass() == "weapon_physgun"

		if renderCube and TEXTSCREEN_REVAMPED.ShowTextscreenBoundsCVar:GetBool() then
			--self:DrawModel()

			render.SetColorMaterial()

			render.DrawBox(
				self:GetPos(),
				self:GetAngles(),
				self:OBBMins(),
				self:OBBMaxs(),
				self.modelColor
			)
			
			render.DrawWireframeBox(
				self:GetPos(),
				self:GetAngles(),
				self:OBBMins(),
				self:OBBMaxs(),
				self.modelColor,
				true
			)
		end
		
		local htmlMat = self.htmlPanel:GetHTMLMaterial()
	
		if self.meshUpdated then
			if htmlMat then
				local matSclX, matSclY = htmlMat:Width() * self.pixelScale, htmlMat:Height() * self.pixelScale
				local sclX, sclY = self.size[1] * self.pixelScale, self.size[2] * self.pixelScale--htmlMat:Width() * self.pixelScale, htmlMat:Height() * self.pixelScale

				local totalSclX = 1 / matSclX * sclX
				local totalSclY = 1 / matSclY * sclY

				local matdata = {
					["$basetexture"] = htmlMat:GetName(),
					["$translucent"] = 1,
					--["$color"] = Vector( 1, 1, 1 ),
					["$basetexturetransform"] = "center 0 0 scale " .. totalSclX .. " " .. totalSclY .. " rotate 0 translate 0 0",
					["$model"] = 1
				}

				self.mat = CreateMaterial( htmlMat:GetName() .. "_textscreen", self.fullbright and "UnlitGeneric" or "VertexLitGeneric", matdata )

				self.mesh = Mesh( self.mat )
				mesh.Begin( self.mesh, MATERIAL_QUADS, 2 )
					
					mesh.Position( Vector( 0, -sclX, sclY ) * 0.5 )
					mesh.TexCoord( 0, 0, 0 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( 1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()

					mesh.Position( Vector( 0, sclX, sclY ) * 0.5 )
					mesh.TexCoord( 0, 1, 0 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( 1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()

					mesh.Position( Vector( 0, sclX, -sclY ) * 0.5 )
					mesh.TexCoord( 0, 1, 1 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( 1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()

					mesh.Position( Vector( 0, -sclX, -sclY ) * 0.5 )
					mesh.TexCoord( 0, 0, 1 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( 1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()

					-- Back --

					mesh.Position( Vector( 0, -sclX, -sclY ) * 0.5 )
					mesh.TexCoord( 0, 0, 1 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( -1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()

					mesh.Position( Vector( 0, sclX, -sclY ) * 0.5 )
					mesh.TexCoord( 0, 1, 1 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( -1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()

					mesh.Position( Vector( 0, sclX, sclY ) * 0.5 )
					mesh.TexCoord( 0, 1, 0 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( -1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()

					mesh.Position( Vector( 0, -sclX, sclY ) * 0.5 )
					mesh.TexCoord( 0, 0, 0 )
					mesh.TangentS( 1, 0, 0 )
					mesh.TangentT( 0, 1, 0 )
					mesh.UserData( 1, 0, 0, 1 )
					mesh.Normal( -1, 0, 0 )
					mesh.Color( 255, 255, 255, 255 )
					mesh.AdvanceVertex()
					
				mesh.End()
				self.meshUpdated = false
			end
		end

		if htmlMat then
			local scl = 1 - ( math.cos( self.sizeAnim * math.pi ) * 0.5 + 0.5 )
			local mat = Matrix()
			mat:Translate( self:WorldSpaceCenter() )
			mat:SetAngles( self:GetAngles() )
			mat:SetScale( Vector( scl, scl, scl ) )
			--mat:Translate( Vector( 0, htmlMat:Width(), -htmlMat:Height() ) * 0.5 * self.pixelScale )
			--mat:Translate( Vector( 0, -self.size[1], self.size[2] ) * 0.5 * self.pixelScale )
			render.PushFilterMin( self.pixelized and TEXFILTER.POINT or TEXFILTER.ANISOTROPIC )
			render.PushFilterMag( self.pixelized and TEXFILTER.POINT or TEXFILTER.ANISOTROPIC )

			cam.PushModelMatrix( mat )
				render.SetMaterial( self.mat or debugwhite )
				self.mesh:Draw()
			cam.PopModelMatrix()

			render.PopFilterMin()
			render.PopFilterMag()
		end

		self.firstFrame = false
	end

	function ENT:Draw()
		render.SetBlend( 0 )
		self:DrawModel()
		render.SetBlend( 1 )
		self:DrawModelOrMesh()
		render.RenderFlashlights( function() self:DrawModelOrMesh() end )
	end
end