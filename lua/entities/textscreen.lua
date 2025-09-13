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

if CLIENT then
	surface.CreateFont("NewFont", {
		font = "Coolvetica",
		size = 256,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		outline = false
	})
else
	net.Receive("SetTextscreenText", function() -- This is used to scale the textscreen physics based on the text length
		local textscreen = net.ReadEntity()
		local textW, textH = net.ReadFloat(), net.ReadFloat()

		local scale = Vector(0.5, textW, textH)

		textscreen:PhysicsInitBox(Vector(scale.x * -0.5,scale.y * -0.5,scale.z * -0.5),Vector(scale.x * 0.5,scale.y * 0.5,scale.z * 0.5))

		textscreen:SetCollisionBounds(Vector(scale.x * -0.5,scale.y * -0.5,scale.z * -0.5),Vector(scale.x * 0.5,scale.y * 0.5,scale.z * 0.5))

		textscreen:SetMoveType(MOVETYPE_VPHYSICS)
		textscreen:SetSolid(SOLID_VPHYSICS)

		textscreen:EnableCustomCollisions(true)
		textscreen:SetCustomCollisionCheck(true)
		textscreen:CollisionRulesChanged()

		textscreen:SetCollisionGroup(COLLISION_GROUP_WORLD)

		local mass = 50

		textscreen:GetPhysicsObject():SetMass(mass)


		textscreen:SetSolidFlags( 0 )
		textscreen:AddSolidFlags( FSOLID_CUSTOMRAYTEST )
		textscreen:AddSolidFlags( FSOLID_CUSTOMBOXTEST )
	end)
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/hunter/blocks/cube05x05x05.mdl")
		self:SetMaterial("models/wireframe")
		self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	end

	if CLIENT then
		self.parsedMarkup = markup.Parse("")
		self:DrawShadow(false)
	end
end

if CLIENT then

	function ENT:SetText(text)
		self.parsedMarkup = markup.Parse(text)
		local textW, textH = self.parsedMarkup:GetWidth(), self.parsedMarkup:GetHeight()
		local scale = Vector(0.5, textW, textH)

		local modelMin, modelMax = self:GetModelBounds()

		local modelSize = math.min(modelMax.x - modelMin.x, modelMax.y - modelMin.y, modelMax.z - modelMin.z) - 0.5

		local textSize = textH

		local sclMat = Matrix()
		sclMat:SetScale(scale / modelSize * 32 / textSize)

		self:EnableMatrix("RenderMultiply", sclMat)

		self:SetRenderBounds(-scale * 32 / textSize * 0.5, scale * 32 / textSize * 0.5)

		if LocalPlayer() ~= self:GetNW2Entity("owner") then return end

		net.Start("SetTextscreenText")
			net.WriteEntity(self)
			net.WriteFloat(textW * 32 / textSize)
			net.WriteFloat(textH * 32 / textSize)
		net.SendToServer()
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

	function ENT:DrawTranslucent()
		local textW, textH = self.parsedMarkup:GetWidth(), self.parsedMarkup:GetHeight()
		local textSize = textH
		--self:DrawModel()
		local mat = Matrix()
		mat:Translate(self:WorldSpaceCenter())
		mat:Rotate(self:GetAngles())
		mat:Rotate(Angle(0,90,90))


		cam.Start3D2D( mat:GetTranslation(), mat:GetAngles(), 32 / textSize)
			self.parsedMarkup:Draw(0, 0, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()

		mat:Rotate(Angle(180,0,0))

		cam.Start3D2D( mat:GetTranslation(), mat:GetAngles(), 32 / textSize)
			self.parsedMarkup:Draw(0, 0, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()

		local renderCube = IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool" and LocalPlayer():GetTool().Mode == "textscreen_revamped"
		renderCube = renderCube or (IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "weapon_physgun")

		if renderCube then
			self:DrawModel()
		end
	end
end