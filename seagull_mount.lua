local function AccessorFunc(tbl, name, dt)
	tbl["Set" .. name] = function(self, var)
		if dt and self.dt then
			self.dt[name] = var
		else
			self[name] = var
		end
	end

	tbl["Get" .. name] = function(self, var)
		if dt and self.dt then
			return self.dt[name]
		else
			return self[name]
		end
	end
end

easylua.StartEntity("seagull_mount")

ENT.IsSeagullMount = true
ENT.ClassName = "seagull_mount"

ENT.Model = "models/seagull.mdl"
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Target = NULL
ENT.Size = 1

ENT.Animations = {
	Fly = "Fly",
	Run = "run",
	Walk = "walk",
	Idle = "idle01",
}

ENT.Sounds = {
	Pain= {
		"ambient/creatures/seagull_pain1.wav",
		"ambient/creatures/seagull_pain2.wav",
		"ambient/creatures/seagull_pain3.wav",
	},
	Idle= {
		"ambient/creatures/seagull_idle1.wav",
		"ambient/creatures/seagull_idle2.wav",
		"ambient/creatures/seagull_idle3.wav",
	},
	AmbientIdle= {
		"ambient/levels/coast/seagulls_ambient1.wav",
		"ambient/levels/coast/seagulls_ambient2.wav",
		"ambient/levels/coast/seagulls_ambient3.wav",
		"ambient/levels/coast/seagulls_ambient4.wav",
		"ambient/levels/coast/seagulls_ambient5.wav",
	},
	Impact= {
		"physics/body/body_medium_impact_soft1.wav",
		"physics/body/body_medium_impact_soft2.wav",
		"physics/body/body_medium_impact_soft3.wav",
		"physics/body/body_medium_impact_soft4.wav",
		"physics/body/body_medium_impact_soft5.wav",
		"physics/body/body_medium_impact_soft6.wav",
		"physics/body/body_medium_impact_soft7.wav",
	},
}

AccessorFunc(ENT, "Size", true)
AccessorFunc(ENT, "SetWingCycle", true)

function ENT:SetupDataTables()
	self:DTVar("Float", 0, "Size")
end

do -- util
	function ENT:PlaySound(type)
		self:EmitSound(
			table.Random(self.Sounds[type]),
			math.Clamp(math.Rand(40, 60) * self:GetSize(), 1, 160),
			math.Clamp(math.random(90,110) / self:GetSize(), 25, 255)
		)
	end

	function ENT:GetBottom()
		return self:GetPos() + Vector(0,0,-5 * self:GetSize())
	end

	function ENT:GetTop()
		return self:GetPos() + Vector(0,0,5 * self:GetSize())
	end

	function ENT:GetOnGround()
		if not self.LastOnGround or self.LastOnGround < CurTime() then
			self.OnGroundCache = util.QuickTrace(self:GetBottom(), vector_up * -10, {self}).Hit
			self.LastOnGround = CurTime() + 0.05
		end

		return self.OnGroundCache
	end
	
	function ENT:GetPlayerPosition()
		return self:GetPos() + Vector(0,0,self:GetSize() * 7)
	end
end

local function setup_player(ply, ent)
	if CLIENT then 
		ent:InvalidateBoneCache()
		ply:InvalidateBoneCache()
	end
	local pos, ang = ent:GetTop(), ent:GetAngles()
	
	pos, ang = LocalToWorld(Vector(5,3,0) * ent:GetSize(), Angle(0,10,-90), pos, ang)			
	
	ply:SetPos(pos)
	ply:SetAngles(ang)
	ply:SetRenderOrigin(pos)
	ply:SetRenderAngles(ang)
	
	ply:SetupBones()
	
	local wep = ply:GetActiveWeapon()
	if wep:IsValid() then
		wep:SetPos(pos)
		wep:SetAngles(ang)
		wep:SetRenderOrigin(pos)
		wep:SetRenderAngles(ang)
		
		wep:SetupBones()
	end
end

if CLIENT then
	language.Add("seagull_mount", "Seagull Mount")

	do -- util
		function ENT:SetAnim(anim)
			self:SetSequence(self:LookupSequence(self.Animations[anim]))
		end
	end

	do -- calc
		ENT.Cycle = 0
		ENT.Noise = 0

		function ENT:AnimationThink(vel, len, ang)			
			local siz = self:GetSize()
			len = len / siz
			
			if self:GetOnGround() then
				if len < 3 / siz then
					self:SetAnim("Idle")
					len = 15 / self:GetSize() * (self.Noise * 2)
				else
					self:StepSoundThink()

					if len > 50 / siz then
						self:SetAnim("Run")
					else
						self:SetAnim("Walk")
					end
				end
				
				self.Noise = (self.Noise + (math.Rand(-1,1) - self.Noise) * FrameTime())
			else
				self:SetAnim("Fly")

				if vel.z > 0 then
					len = len / 20
				else
					len = 0
					self.Cycle = 0.2
				end
			end

			self.Cycle = (self.Cycle + (len / (15 / siz)) * FrameTime()) % 1
			self:SetCycle(self.Cycle)
		end

		function ENT:StepSoundThink()
			local stepped = self.Cycle%0.5
			if stepped  < 0.3 then
				if not self.stepped then
					WorldSound(
						"npc/fast_zombie/foot2.wav",
						self:GetPos(),
						math.Clamp(30 * self:GetSize(), 70, 160) + math.Rand(-5,5),
						math.Clamp(100 / (self:GetSize()/2), 40, 200) + math.Rand(-10,10)
					)
					self.stepped = true
				end
			else
				self.stepped = false
			end
		end
	end

	do -- standard
		function ENT:Draw()
			self.vel = self:GetVelocity() / self:GetSize()
			self.len = self.vel:Length()
			self.ang = self.vel:Angle()
			
			self:AnimationThink(self.vel, self.len, self.ang)

			self:SetModelScale(self:GetSize(), 0)
			
			if self.len > 5 or not self.lastang then
				self:SetAngles(self.ang)
				self.lastang = self.ang
			else
				self:SetAngles(self.lastang)
			end
			
			if self:GetOnGround() then
				self.ang = Angle(0, self.ang.y, 0)
				self.lastang = Angle(0, self.lastang and self.lastang.y or self.ang.y, 0)
			end

			self:SetRenderOrigin(self:GetBottom())

			--local min, max = self:GetRenderBounds()
			--local size = self:GetSize() * 2
			--self:SetRenderBounds(min * size, max * size)

			self:DrawShadow(false)
			--self:SetupBones()
			self:DrawModel()
			self:SetRenderOrigin(nil)
		end

		function ENT:Think()					
			if math.random() > 0.999 then
			--	self:EmitSound(table.Random(self.Sounds.AmbientIdle), 120, math.Clamp(100 / self:GetSize(), 30, 200) + math.Rand(-10,10))
			end
		end
	end
	
	local P = {}
	
	hook.Add("CalcView", ENT.ClassName, function(ply)
		local ent = ply:GetOwner()
	
		if ent.IsSeagullMount and not ply:ShouldDrawLocalPlayer() then
			
			P.origin = ent:GetPlayerPosition()
			--P.angles = ply:EyeAngles()
			
			setup_player(ply, ent)
			
			return P
		end
	end)
	
	hook.Add("PrePlayerDraw", ENT.ClassName, function(ply)
		local ent = ply:GetOwner()
	
		if ent.IsSeagullMount then
			setup_player(ply, ent)			
		end
	end)
	
	hook.Add("PostPlayerDraw", ENT.ClassName, function(ply)
		local ent = ply:GetOwner()
	
		if ent.IsSeagullMount then			
			setup_player(ply, ent)
		end
	end)
end
	
local translate_sit = {
	pistol = "sit_pistol",
	smg = "sit_smg1",
	grenade = "sit_grenade",
	ar2 = "sit_ar2",
	shotgun = "sit_shotgun",
	rpg = "sit_rpg",
	physgun = "sit_gravgun",
	crossbow = "sit_crossbow",
	melee = "sit_melee",
	slam = "sit_slam",
	normal = "sit_rollercoaster",
	fists = "sit_fist",
	fist = "sit_fist",
}

hook.Add("UpdateAnimation", ENT.ClassName, function(ply)
	local ent = ply:GetOwner()

	if ent.IsSeagullMount then	
		local wep = ply:GetActiveWeapon()
		
		if wep:IsValid() and wep.GetHoldType and wep:GetHoldType() and #wep:GetHoldType() > 0 then
			ply:SetSequence(ply:LookupSequence(translate_sit[wep:GetHoldType()]))
		else
			ply:SetSequence(ply:LookupSequence("sit_rollercoaster"))
		end
		
		if CLIENT then
			--setup_player(ply, ent)
		end
		
		return true
	end
end)	

if SERVER then
	function ENT:SetSize(siz)	
		self.dt.Size = siz
		self:PhysicsInitSphere(5 * self:GetSize())
		self:GetPhysicsObject():SetMass(20 * self:GetSize())
		self:StartMotionController()
	end

	function ENT:Initialize()	
		self:SetSize(math.Rand(0.75, 4))
		
		self:SetModel(self.Model)
		self:PhysicsInitSphere(5 * self:GetSize())
		self:StartMotionController()
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

		local phys = self:GetPhysicsObject()
			phys:SetMass(20 * self:GetSize())
			phys:SetMaterial("default_silent")
		self.phys = phys
	end
	
	local P = {}
	
	P.maxangular = 1
	P.maxspeed = 1000000
	
	P.maxspeeddamp = 1
	P.maxangulardamp = 1000000
	
	P.secondstoarrive = 2
	P.dampfactor = 0.9
	P.teleportdistance = 0

	function ENT:PhysicsUpdate(phys)
		self.vel = phys:GetVelocity()
		self.len2d = self.vel:Length2D()
		
		local owner = self:GetOwner()
		local vel = vector_origin * 1
		
		local damp = 0
		
		if self:GetOnGround() then
		
			if self.len2d < 5 * self:GetSize() then
				damp = 1
			else
				damp = 0.08
			end
			
			if owner:IsValid() then
				if owner:KeyDown(IN_FORWARD) then
					local dir = self.last_dir or self.vel:GetNormalized()
					vel = vel + dir * self:GetSize() * 3
					
					damp = 0.05
					
					
					if owner:KeyDown(IN_MOVELEFT) then
						vel = vel + owner:EyeAngles():Right() * -self:GetSize() * 3
					elseif owner:KeyDown(IN_MOVERIGHT) then
						vel = vel + owner:EyeAngles():Right() * self:GetSize() * 3
					end
					
					if owner:KeyDown(IN_SPEED) then
						vel = vel * 2
					elseif owner:KeyDown(IN_WALK) then
						vel = vel * 0.5
					end
					
					if owner:KeyPressed(IN_JUMP) then
						vel.z = vel.z + self:GetSize() * 3
						vel = vel * self:GetSize() * 5
					end
				elseif self.len2d > 0 then
					self.last_dir = owner:GetAimVector()
				end
			else
				if me and me:IsValid() then					
					local pos = me:GetPos()
					
					if pos:Distance(phys:GetPos()) > 150 then
						damp = 0.5 / self:GetSize()
						
						vel = pos - phys:GetPos()
						vel = vel + Vector(math.Rand(-1,1), math.Rand(-1,1), 0) *  200 / self:GetSize()
					else
						if math.random() > 0.995 then
							vel = vel + Vector(math.Rand(-1,1), math.Rand(-1,1), 0) *  100 * self:GetSize()
						end
						
						damp = 0.1
					end
				end
			end	
			
			phys:AddVelocity(vel / 2)
			phys:AddVelocity(phys:GetVelocity() * -damp)
		else
			if me and me:IsValid() then					
				local pos = me:GetPos()				
				
				vel = (pos - phys:GetPos()):GetNormalized() * 100
				vel = vel + VectorRand() * 20
				
				damp = 0.01
			
				phys:AddVelocity(vel / 2)
				phys:AddVelocity(phys:GetVelocity() * -damp)
			else
				
				local ext_dir = vector_origin * 1

				if owner:IsValid() then
					if owner:KeyPressed(IN_JUMP) then
						vel.z = vel.z + self:GetSize() * 30
					end
					
					ext_dir = owner:GetAimVector() * self:GetSize() * 20
				end			
				
				local ang = self.vel:Angle()
				ang.p = math.NormalizeAngle(ang.p) / 90
			
				local dir = (self.vel * Vector(0.05, 0.05, -0.1))
				dir.z = dir.z * (-ang.p)
				
				dir = dir + ext_dir
				
				phys:AddVelocity((dir * 0.9) / 2)
			end
		end
	end
	
	function ENT:OwnerEnter(owner)
		local old_owner = self:GetOwner()
		
		if not old_owner:IsValid() then
			
			if owner:IsPlayer() then 
				owner:SetViewOffset(Vector(0, 0, 0))
			end
			
			owner:SetPos(self:GetPos())
			
			owner:SetOwner(self)
			self:SetOwner(owner)
			
			owner:SetAngles(Angle(0, 0, 0))
		end
	end
	
	function ENT:DropOwner()
		local owner = self:GetOwner()
		
		if owner:IsValid() then
			if owner:IsPlayer() then 
				owner:SetViewOffset(Vector(0, 0, 64))
			end
			
			owner:SetOwner(NULL)
			self:SetOwner(NULL)
			
			timer.Simple(0.1, function()
				if owner:IsValid() and self:IsValid() then
					owner:SetPos(self:GetPos() + Vector() * self:GetSize() * 5)
				end
			end)
		end
	end
	
	function ENT:Use(owner)
		if me and me ~= owner then return end
		
		if owner:GetOwner().IsSeagullMount then return end
		
		if (self.last_use or 0) < CurTime() then
			self:OwnerEnter(owner)
			self.last_use = CurTime() + 0.5
		end
	end
	
	hook.Add("KeyRelease", ENT.ClassName, function(ply, key)		
		local ent = ply:GetOwner()
		
		if ent.IsSeagullMount and key == IN_USE then
			if ent:IsValid() then
				if (ent.last_use or 0) < CurTime() then
					ent:DropOwner()
					ent.last_use = CurTime() + 0.5
				end
			end
		end
	end)

	function ENT:OnTakeDamage(dmg)
		print(self, dmg:GetAttacker(), dmg:GetDamage())
	end

	function ENT:Die()
		self:Remove()
		self:PlaySound("Impact")
	end

	function ENT:OnRemove()
		self:DropOwner()
	end
end

hook.Add("Move", ENT.ClassName, function(ply, mov)
	local ent = ply:GetOwner()
	
	if ent.IsSeagullMount then
		ply:SetViewOffset(vector_origin)
		
		mov:SetVelocity(vector_origin)
		mov:SetOrigin(ent:GetPlayerPosition())
		
		ent:PhysWake()
			
		return true
	end
end)

easylua.EndEntity()