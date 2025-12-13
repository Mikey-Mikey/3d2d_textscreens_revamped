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
	resource.AddSingleFile( "resource/fonts/Spicy Sale.ttf" )
	resource.AddSingleFile( "resource/fonts/Segment.ttf" )
	resource.AddSingleFile( "resource/fonts/Coolvetica.ttf" )
	-- This is used to scale the textscreen physics based on the text length
	net.Receive( "SetTextscreenText", function()
		local textscreen = net.ReadEntity()
		local textW, textH = net.ReadFloat(), net.ReadFloat()
		local scale = Vector( 0.5, textW, textH )
		textscreen:PhysicsInitBox( Vector( scale.x * -0.5, scale.y * -0.5, scale.z * -0.5 ), Vector( scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 ) )
		textscreen:SetCollisionBounds( Vector( scale.x * -0.5, scale.y * -0.5, scale.z * -0.5 ), Vector( scale.x * 0.5, scale.y * 0.5, scale.z * 0.5 ) )
		textscreen:SetMoveType( MOVETYPE_VPHYSICS )
		textscreen:SetSolid( SOLID_VPHYSICS )
		textscreen:EnableCustomCollisions( true )
		textscreen:SetCustomCollisionCheck( true )
		textscreen:CollisionRulesChanged()
		textscreen:SetCollisionGroup( COLLISION_GROUP_WORLD )
		local mass = 50
		textscreen:GetPhysicsObject():SetMass( mass )
		textscreen:SetSolidFlags( 0 )
		textscreen:AddSolidFlags( FSOLID_CUSTOMRAYTEST )
		textscreen:AddSolidFlags( FSOLID_CUSTOMBOXTEST )
	end )
end

function ENT:Initialize()
	if SERVER then
		self:SetModel( "models/hunter/blocks/cube05x05x05.mdl" )
		self:SetMaterial( "models/wireframe" )
		self:SetRenderMode( RENDERMODE_TRANSCOLOR )
	end

	if CLIENT then
		self.pixelScale = 0.2
		self.size = Vector( 0, 0, 0 )
		self.htmlPanel = vgui.Create( "DHTML" )
		self.htmlPanel:SetSize( self.size[1], self.size[2] )
		self:DrawShadow( false )
	end
end

if CLIENT then
	function ENT:SetSize( size )
		self.size = size
		self.htmlPanel:SetSize( self.size[1], self.size[2] )
	end

	function ENT:SetText( text )
		local modelMaxs = self:OBBMaxs()

		local newHtml = [[
			<head>
				<meta name="referrer" content="origin" />
				<style>
					@font-face {
						font-family: 'Spicy Sale'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Spicy Sale.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					@font-face {
						font-family: 'Segment'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Segment.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					@font-face {
						font-family: 'Coolvetica'; /* The name you will use in CSS */
						src: url('asset://garrysmod/resource/fonts/Coolvetica.ttf') format('truetype'); /* Path relative to the GMod root, using the file:// protocol */
					}
					body {
						background: transparent;
						overflow: hidden;
						overflow-wrap: anywhere;
						margin: 0;
						padding: 0;
						transform: translateZ(0);
						--font: 'Arial';
						--size: 15;
						--font-style: none;
						--color: rgb(255, 255, 255);
						--shadow-color: rgba( 0, 0, 0, 0.0 );
						--shadow-blur: 1;
						--shadow-x: 0;
						--shadow-y: 0;
						--stroke: 1;
						--stroke-color: rgb( 0, 0, 0 );
					}

					.container {
						display: flex;
						position: relative;
						width: max-content;
						height: max-content;
						padding: 2em;
						align-items: center;
						justify-content: center;
						background: #fff0;
						max-width: 2000px;
						max-height: 2000px;
					}
					text {
						display: inline;
						position: relative;
						text-align: center;
						white-space: pre-wrap;
						color: var(--color);
						-webkit-text-stroke: calc( var( --stroke ) * 1px + 1px ) var( --stroke-color );
						font-family: var(--font);
						font-size: calc( var(--size) * 1em );
						font-style: var(--font-style);
						text-shadow: calc( var( --shadow-x ) * 1em ) calc( var( --shadow-y ) * 1em ) calc( var( --shadow-blur ) * 0.1em ) var( --shadow-color );
					}
				</style>
			</head>
			<body>
				<div class="container" id="main">
		]]

		text = string.Replace( text, ">\n", ">" ) -- Remove line breaks right after tags
		text = string.TrimRight( text )

		newHtml = newHtml .. text
		newHtml = newHtml .. "</div>"
		newHtml = newHtml .. "</body>"

		self.htmlPanel:SetHTML( newHtml )

		--local scale = Vector( 0.5, self.size[1] * self.pixelScale, self.size[2] * self.pixelScale )

		self.htmlPanel:AddFunction( "textscreen", "resizeTextscreen", function( w, h )
			print( w, h )
			local scale = Vector( 0.5, w * self.pixelScale, h * self.pixelScale )
			local sclMat = Matrix()
			sclMat:SetScale( scale / ( modelMaxs[1] - 0.25 ) / 2 )
			self:EnableMatrix( "RenderMultiply", sclMat )
			self:SetRenderBounds( -scale, scale )
			self:SetSize( Vector( w, h, 0 ) )

			if LocalPlayer() ~= self:GetNW2Entity( "owner" ) then return end

			net.Start( "SetTextscreenText" )
			net.WriteEntity( self )
			net.WriteFloat( scale[2] )
			net.WriteFloat( scale[3] )
			net.SendToServer()
		end )

		self.htmlPanel:QueueJavascript( [[
			const elem = document.getElementById( "main" );
			var rect = elem.getBoundingClientRect();
			textscreen.resizeTextscreen( rect.width, rect.height );
		]] );
	end

	function ENT:Think()
		if CLIENT then
			local physobj = self:GetPhysicsObject()

			if IsValid( physobj ) then
				physobj:SetPos( self:GetPos() )
				physobj:SetAngles( self:GetAngles() )
			end
		end
	end

	function ENT:OnRemove()
		self.htmlPanel:Remove()
	end

	function ENT:Draw()
		--self:DrawModel()
		local mat = Matrix()
		mat:Translate( self:WorldSpaceCenter() )
		mat:Rotate( self:GetAngles() )
		mat:Rotate( Angle( 0, 90, 90 ) )
		mat:Translate( Vector( -self.size[1], self.size[2], 0 ) * 0.5 * self.pixelScale )

		vgui.Start3D2D( mat:GetTranslation(), mat:GetAngles(), self.pixelScale )
			self.htmlPanel:Paint3D2D()
		vgui.End3D2D()

		mat = Matrix()
		mat:Translate( self:WorldSpaceCenter() )
		mat:Rotate( self:GetAngles() )
		mat:Rotate( Angle( 0, -90, 90 ) )
		mat:Translate( Vector( -self.size[1], self.size[2], 0 ) * 0.5 * self.pixelScale )

		vgui.Start3D2D( mat:GetTranslation(), mat:GetAngles(), self.pixelScale )
			self.htmlPanel:Paint3D2D()
		vgui.End3D2D()

		local renderCube = IsValid( LocalPlayer():GetActiveWeapon() ) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool"
		renderCube = renderCube or IsValid( LocalPlayer():GetActiveWeapon() ) and LocalPlayer():GetActiveWeapon():GetClass() == "weapon_physgun"

		if renderCube then
			self:DrawModel()
		end
	end
end