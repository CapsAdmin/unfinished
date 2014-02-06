local function Print(...)
	if SERVER then print(...) return end
	local tbl = {...}
	for key, value in pairs(tbl) do
		if key ~= #tbl then
			EPOE.AddText(tostring(value)..", ")
		else
			EPOE.AddText(tostring(value).."\n")
		end
	end
end

local ENT = {}

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "CapsAdmin"
ENT.PrintName = "Bird Wings"
ENT.Author = "CapsAdmin"
ENT.Contact = "sboyto@gmail.com"
ENT.Purpose = "Fly around"
ENT.Instructions = "Spawn to wear, undo to unwear"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.PitchOffset = 90

function ENT:SetupDataTables()
	self:DTVar( "Entity", 0, "ply" )
	self:DTVar( "Float", 0, "cycle" )
	self:DTVar( "Int", 0, "thrust" )
end

function ENT:GetLocalVelocity(offset)
	offset = offset or self.PitchOffset
	local ply = self.dt.ply
	local eye = ply:EyeAngles()
	eye.p = eye.p + offset
	return ({WorldToLocal(ply:GetVelocity(), Angle(offset, 0, 0), Vector(0), eye)})[1]
end

hook.Add("Move", "BirdWings:Move", function(ply, data)
	local self = ply.birdwings
	if not IsValid(self) or ply:KeyDown(IN_DUCK) then return end

	local eye = ply:EyeAngles()
	eye.p = eye.p + self.PitchOffset

	local local_velocity = self:GetLocalVelocity() *-1
	local length = math.min(local_velocity:Length() / 2000, 1)

	local final = (((eye:Forward() - (eye:Up() * 0.3)):Normalize() * local_velocity.x) * Vector(1,1,0.5) * 0.04) * length

	data:SetVelocity(data:GetVelocity() + (final * FrameTime() * 200))

	return data
end)

if CLIENT then

	local bones = {
		"ValveBiped.Bip01_R_Thigh",
		"ValveBiped.Bip01_L_Thigh",
	}

	hook.Add("PlayerBuildBonePositions", "birdwings", function(ply)
		ply.bwsmoothlegs = ply.bwsmoothlegs or Vector(0,0,0)
		if ply.birdwings and not ply:OnGround() then
			for key, bone in pairs(bones) do
				local index = ply:LookupBone(bone)
				local matrix = ply:GetBoneMatrix(index)
				if not matrix then continue end
				local velocity = WorldToLocal(ply:GetVelocity(), Angle(0), Vector(0), ply:EyeAngles())
				ply.bwsmoothlegs = LerpVector(FrameTime()*2,ply.bwsmoothlegs,velocity*0.1)

				matrix:Rotate(ply.birdlegsoverride or Angle(math.Clamp(ply.bwsmoothlegs.y/4,-60,60)-5,math.Clamp(ply.bwsmoothlegs.x/5,-60,60)-30,0))
				ply:SetBoneMatrix(index, matrix)
			end
		end
	end)

	local pitch = 0
	local yaw = 0
	local roll = 0

	hook.Add("CreateMove", "BirdWings:CreateMove", function(ucmd)

		local ply = LocalPlayer()
		local self = ply.birdwings
		if not IsValid(self) then return end

		if
			ply:GetMoveType() ~= MOVETYPE_NOCLIP and
			ply:Alive() and
			not ply:OnGround()
		then
			ucmd:SetForwardMove(0)
			ucmd:SetSideMove(0)
			if ucmd:GetMouseX() > 0 then
				ucmd:SetSideMove(1)
			elseif ucmd:GetMouseX() < 0 then
				ucmd:SetSideMove(-1)
			end
		end
	end)

	local localplayervisible = false

	hook.Add("PrePlayerDraw", "BirdWings:PrePlayerDraw", function(ply)
		local self = ply.birdwings
		if not IsValid(self) then return end

		if not IsValid(ply:GetVehicle()) and not ply:OnGround() then

			local trace = util.QuickTrace(ply:GetPos(), Vector(0,0,-50), ply)

			local eye = ply:EyeAngles()

			eye.p = eye.p + self.PitchOffset

			local angle = LerpAngle(trace.Fraction, ply:EyeAngles(), eye + Angle(-40, 10, 5))

			ply.birdlegsoverride = trace.Hit and Angle(0,45*trace.Fraction,0)

			ply:SetRenderAngles(angle)
			ply:SetupBones()
			local weapon = ply:GetActiveWeapon()
			if IsValid(weapon) then
				weapon:SetRenderAngles(angle)
				weapon:SetupBones()
			end
		end

		self:DrawThirdperson(ply)

		if ply == LocalPlayer() then
			localplayervisible = true
			timer.Create("BirdWingsLocalPlayerVisible", 0.1, 1, function()
				localplayervisible = false
			end)
		end

	end)

	hook.Add("PreDrawOpaqueRenderables", "BirdWings:PreDrawOpaqueRenderables", function()
		local self = LocalPlayer().birdwings
		if localplayervisible or not IsValid(self) then return end

		--self:DrawFirstperson()
	end)

	hook.Add("UpdateAnimation", "BirdWings:UpdateAnimation", function(ply)
		local self = ply.birdwings
		if not IsValid(self) then return end
		if ply:Alive() and not ply:OnGround() then
			ply:SetPoseParameter("aim_pitch", -80.4)
			ply:SetPoseParameter("head_pitch", -20)
		end
		return false
	end)

	local bones = {
		{name = "Crow.Humerus_R", scale = Vector(10,10,10)},
		{name = "Crow.Humerus_L", scale = Vector(10,10,10)},
		--{name = "Seagull.Body", scale = Vector(0.1,0.1,0.1)},
	}

	function ENT:Initialize()
		local ply = self.dt.ply

		self.sound_flap = CreateSound(self, "vehicles/fast_windloop1.wav")
		self.sound_wind = CreateSound(self, "ambient/wind/windgust_strong.wav")
		self.sound_flap:PlayEx(0,0)
		self.sound_wind:PlayEx(0,0)

		wings = self

		self.flap = 0

		self.smoothview = Angle(0)
		self.thrust = 0

		ply.birdwings = self

		self.bone = ply:LookupBone("ValveBiped.Bip01_pelvis")

		self.wings = ClientsideModel("models/crow.mdl")
		self.wings:SetSequence(self.wings:LookupSequence("fly01"))
		self.wings:SetPos(ply:GetPos())
		self.wings:SetNoDraw(true)
 		self.wings.BuildBonePositions = function(self)
			for key, bone in pairs(bones) do
				local index = self:LookupBone(bone.name)
				local matrix = self:GetBoneMatrix(index)
				matrix:Scale(bone.scale*0.9)
				self:SetBoneMatrix(index, matrix)
			end
		end
	end

	function ENT:GetWingsCycle()
		return self.wings:GetCycle()
	end

	function ENT:SetWingsCycle(cycle)
		cycle = cycle/3%(1/3)
		--cycle = -cycle + 1
		self.wings:SetCycle(cycle)
	end

	function ENT:CalculateWingsCycle()
		local ply = self.dt.ply
		local cycle = self.dt.cycle
		local pitch = cycle * 10

		self.sound_wind:ChangePitch(70)
		self.sound_wind:ChangeVolume(math.Clamp(ply:GetVelocity():Length() / 4000, 0, 1))

		self.sound_flap:ChangePitch(math.Clamp(50+pitch, 0, 255))
		self.sound_flap:ChangeVolume(math.Clamp(cycle^10, 0, 1))

		self:SetWingsCycle(cycle)
	end

	function ENT:Think()
		self:CalculateWingsCycle()

		self:NextThink(CurTime())
		return true
	end

	function ENT:DrawFirstperson()
		local ply = LocalPlayer()
		local position, angles = LocalToWorld(Vector(0, 0, 10), Angle(-100,0,0), ply:EyePos(), ply:EyeAngles())

		self.wings:SetRenderOrigin(position)
		self.wings:SetRenderAngles(angles)
		self.wings:SetModelScale(Vector(1,2,2)*0.8)
		--cam.IgnoreZ(true)
		render.CullMode(MATERIAL_CULLMODE_CW)
		self.wings:DrawModel()
		render.CullMode(MATERIAL_CULLMODE_CCW)
		self.wings:DrawModel()
		--cam.IgnoreZ(false)
		self.wings:SetModelScale(Vector())
	end

	function ENT:DrawThirdperson(ply)

		if not ply:Alive() then return end

		local position, angles = LocalToWorld(Vector(0, 8, -2), Angle(-20,90,180), ply:GetBonePosition(self.bone))

		self.wings:SetRenderOrigin(position)
		self.wings:SetRenderAngles(angles)
		--render.CullMode(MATERIAL_CULLMODE_CW)
		--self.wings:DrawModel()
		--render.CullMode(MATERIAL_CULLMODE_CCW)
		self.wings:DrawModel()
	end

	function ENT:OnRemove()
		self.wings:Remove()
		self.dt.ply.birdwings = nil
	end
end
if SERVER then

	concommand.Add("bird_wings_spawn", function(ply)
		scripted_ents.Get("birdwings"):SpawnFunction(ply)
	end)

	concommand.Add("bird_wings_remove", function(ply)
		local self = ply.birdwings
		if IsValid(self) then
			self:Remove()
		end
	end)

	hook.Add("KeyPress", "BirdWings:KeyPress", function(ply, key)
		local self = ply.birdwings
		if not IsValid(self) then return end

		if key == IN_JUMP then
			self:Flap()
		end
	end)

	hook.Add("SetPlayerAnimation", "BirdWings:SetPlayerAnimation", function(ply, anim)
		local self = ply.birdwings
		if not IsValid(self) then return end

		if not ply:OnGround() then
			ply:SetSequence(-1)
		end

	end)

	local function FindInTable(tbl, find)
		for key, value in pairs(tbl) do
			if value:find(find, nil, true) then
				return true
			end
		end
	end

	function ENT:SpawnFunction(ply)
		if ply.birdwings then return end

		local self = ents.Create("birdwings")
		ply.birdwings = self
		self.ply = ply

		self:SetModel("models/props_junk/PopCan01a.mdl")
		self:SetNotSolid(true)
		self:SetNoDraw(true)
		self:SetParent(ply)
		self:SetPos(ply:GetPos())

		self:Spawn()
	end

	function ENT:Initialize()
		self.dt.ply = self.ply
		self.flapcycle = 0
		self.flapped = 0
	end

	function ENT:Flap()
		if self.flapped > 10 then return end
		self.flapped = 100
	end

	function ENT:CalculateWingsCycle()
		local zup = math.Clamp(self:GetVelocity().z/1000,0,5)
		if zup < 3 then
			self.flapcycle = math.max(self.flapcycle - (self.flapcycle/2),0)
		else
			self.flapcycle = self.flapcycle + zup
		end

		if self.flapped > 0 then
			local ply = self.dt.ply
			local velocity = self:GetLocalVelocity()
			velocity.x = 0
			local mult = 500 / (1 + velocity:Length() / 2000)
			ply:SetVelocity((ply:EyeAngles():Up() + ply:EyeAngles():Forward()) * mult * (-(self.flapped / 100) + 1) * 0.1 )

			self.flapped = self.flapped - math.Clamp(math.abs((self:GetLocalVelocity().z + 900) / 700), 0, 1.5)
			self.flapcycle = -self.flapped
			--Print(self.flapped)
		end

		self.dt.cycle = (math.Clamp(-(self:GetLocalVelocity().x/80)+25,0,50) + self.flapcycle) % 100
		self.dt.cycle = self.dt.cycle / 100
		self.dt.cycle = self.dt.cycle%1

		if self.ply:KeyDown(IN_DUCK) then
			self.dt.cycle = 60
		end
	end

	function ENT:Think()
		self:CalculateWingsCycle()
		self:NextThink(CurTime())
		return true
	end

	function ENT:OnRemove()
		self.ply.birdwings = nil
	end

end

scripted_ents.Register(ENT, "birdwings", true)

if SERVER then
	for key, ply in pairs(player.GetAll()) do
		if ply.birdwings then
			ply:ConCommand("bird_wings_remove")
			timer.Simple(0.5, function()
				ply:ConCommand("bird_wings_spawn")
			end)
		end
	end
end