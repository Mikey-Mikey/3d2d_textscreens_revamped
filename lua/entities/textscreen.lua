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

if CLIENT then
	include( "includes/3d2dvgui.lua" )
else
	util.AddNetworkString( "RetrieveTextscreenText" )
	resource.AddSingleFile( "resource/fonts/Coolvetica.ttf" )
	resource.AddSingleFile( "resource/fonts/Oxanium.ttf" )
	resource.AddSingleFile( "resource/fonts/Roboto.ttf" )
	resource.AddSingleFile( "resource/fonts/Segment.ttf" )
	resource.AddSingleFile( "resource/fonts/Spicy Sale.ttf" )

	function SetTextscreenText( textscreen, width, height )
		if not IsValid( textscreen ) then return end

		local scale = Vector( 0.5, width, height )
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

	net.Receive( "UpdatePlayerCurrentTextscreenText", function()
		local ply = net.ReadPlayer()
		local txt = net.ReadString()

		net.Start("UpdatePlayerCurrentTextscreenText")
		net.WritePlayer( ply )
		net.WriteString( txt )
		net.Broadcast()
	end )

	-- This is used to scale the textscreen physics based on the text length
	net.Receive( "SetTextscreenText", function()
		local textscreen = net.ReadEntity()
		local w = net.ReadFloat()
		local h = net.ReadFloat()
		local txt = net.ReadString()

		textscreen.text = txt

		SetTextscreenText( textscreen, w, h )
	end )

	net.Receive( "RetrieveTextscreenText", function()
		local ply = net.ReadPlayer()
		local textscreen = net.ReadEntity()
		local txt = textscreen.text
		net.Start( "RetrieveTextscreenText" )
		net.WriteEntity( textscreen )
		net.WriteString( txt )
		net.Send( ply )
	end )
end

function ENT:Initialize()
	if SERVER then
		self:SetModel( "models/hunter/blocks/cube05x05x05.mdl" )
		self:SetMaterial( "models/debug/debugwhite" )
		self:SetRenderMode( RENDERMODE_TRANSCOLOR )
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
		self.text = ""
	end
	self:DrawShadow( false )
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
		if self.htmlPanel ~= nil then
			self.htmlPanel:Remove()
		end

		self.htmlPanel = vgui.Create( "DHTML" )

		self.htmlPanel:SetSize( 0, 0 )
		local newHtml = [[
			<head>
				<meta name="referrer" content="origin" />
				<style>
					@font-face {
						font-family: 'Coolvetica'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Coolvetica.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					@font-face {
						font-family: 'Oxanium'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Oxanium.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					@font-face {
						font-family: 'Roboto'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Roboto.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					@font-face {
						font-family: 'Segment'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Segment.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					@font-face {
						font-family: 'Spicy Sale'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Spicy Sale.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					body {
						background: transparent;
						overflow: hidden;
						overflow-wrap: anywhere;
						margin: 0;
						padding: 0;
						paint-order: stroke fill;
						--font: 'Arial';
						--size: 6;
						--weight: 400;
						--font-style: none;
						--color: rgb(255, 255, 255);
						--shadow-color: rgba( 0, 0, 0, 0.0 );
						--shadow-blur: 1;
						--shadow-x: 0;
						--shadow-y: 0;
						--stroke: 1;
						--stroke-color: rgba( 0, 0, 0, 1 );
						--text-data: "Data";
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
							calc( max( 0.01, max( 0, var( --shadow-y ) * -1 ) ) * 1em + var(--shadow-blur) * 0.1em )
							calc( max( 0.01, max( 0, var( --shadow-x ) ) ) * 1em + var(--shadow-blur) * 0.1em )
							calc( max( 0.01, max( 0, var( --shadow-y ) ) ) * 1em + var(--shadow-blur) * 0.1em )
							calc( max( 0.01, max( 0, var( --shadow-x ) * -1 ) ) * 1em + var(--shadow-blur) * 0.1em );
						padding: 0;
						font-family: var(--font);
						font-size: calc( var(--size) * 1em );
						font-style: var(--font-style);
						font-variation-settings: "wght" var( --weight );
						-webkit-text-stroke: calc( var( --stroke ) * ( var( --size ) / 6 ) * 2px + 4px * var( --size ) / 6 ) var( --stroke-color );
						text-shadow:
							calc( var( --shadow-x ) * 1em ) calc( var( --shadow-y ) * 1em ) calc( var( --shadow-blur ) * 0.1em ) var( --shadow-color ),
							calc( var( --shadow-x ) * 1em ) calc( var( --shadow-y ) * 1em ) calc( var( --shadow-blur ) * 0.1em ) var( --shadow-color );

					}
					text::before {
						white-space: pre-wrap;
						display: block;
						content: var(--text-data);
						position: absolute;
						left: 0;
						-webkit-text-stroke-color: #0000;
						font-size: 1em;
					}
				</style>
				<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/dompurify/3.2.7/purify.min.js"></script>
			</head>
			<body>
				<div class="container" id="main">
		]]
		local txt = self.text

		txt = string.Replace( txt, ">\n", ">" ) -- Remove line breaks right after tags
		txt = string.TrimRight( txt )

		self.htmlPanel:AddFunction( "textscreen", "sanitizeText", function( sanitizedText )
			txt = sanitizedText
		end )

		-- Sanitize text
		self.htmlPanel:QueueJavascript( string.format( [[
			const txt = DOMPurify.sanitize( `%s`, { USE_PROFILES: {  } });
			textscreen.sanitizeText( txt );
		]], txt ) )

		newHtml = newHtml .. txt
		newHtml = newHtml .. "</div>"
		newHtml = newHtml .. "</body>"

		self.htmlPanel:SetHTML( newHtml )

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

			if LocalPlayer() ~= self:GetNWEntity( "owner" ) then return end

			net.Start( "SetTextscreenText" )
			net.WriteEntity( self )
			net.WriteFloat( scale[2] )
			net.WriteFloat( scale[3] )
			net.WriteString( self.text )
			net.SendToServer()
		end )

		self.htmlPanel:QueueJavascript( [[
			const elem = document.getElementById( "main" );
			var rect = elem.getBoundingClientRect();
			textscreen.resizeTextscreen( rect.width, rect.height );
		]] )
		self.htmlPanel:SetPaintedManually( true )
	end

	function ENT:Draw()
		--[[
		local renderDist = TEXTSCREEN_REVAMPED.RenderDistanceCVar:GetFloat() ^ 2
		local eyeDist = EyePos():DistToSqr( self:GetPos() )

		if eyeDist > renderDist and not ( self:GetNWEntity( "owner" ) == LocalPlayer() and self.firstFrame ) then
			return
		end
		]]
		if self.htmlPanel == nil and self.text ~= "" then
			self:UpdateHTML()
		end

		if self.size[1] <= 0 or self.size[2] <= 0 then return end

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

		local scl = self.pixelScale * ( math.cos( math.pi + self.sizeAnim * math.pi ) * 0.5 + 0.5 )

		local mat = Matrix()
		mat:Translate( self:WorldSpaceCenter() )
		mat:Rotate( self:GetAngles() )
		mat:Rotate( Angle( 0, 90, 90 ) )
		mat:Translate( Vector( -self.size[1], self.size[2], 0 ) * 0.5 * scl )

		vgui.Start3D2D( mat:GetTranslation(), mat:GetAngles(), scl )
			self.htmlPanel:Paint3D2D()
		vgui.End3D2D()

		mat = Matrix()
		mat:Translate( self:WorldSpaceCenter() )
		mat:Rotate( self:GetAngles() )
		mat:Rotate( Angle( 0, -90, 90 ) )
		mat:Translate( Vector( -self.size[1], self.size[2], 0 ) * 0.5 * scl )

		vgui.Start3D2D( mat:GetTranslation(), mat:GetAngles(), scl )
			self.htmlPanel:Paint3D2D()
		vgui.End3D2D()

		self.firstFrame = false
	end
end