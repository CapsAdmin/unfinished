fts = fts or {}

fts.ActiveHooks = {}

function fts.IsInFTS(ent)
	return ent:IsValid() and (ent.InFTS or ent:GetOwner().InFTS or ent:GetParent().InFTS or (IsEntity(ent:CPPIGetOwner()) and ent:CPPIGetOwner().InFTS))
end

function fts.IsActive()
	for key, ply in pairs(player.GetAll()) do
		if ply:GetNWBool("InFTS") then
			return true
		end
	end
	return false
end

function fts.PlayerJoin(ply)
	ply.InFTS = true
	ply:SetNWBool("InFTS", true)
	
	umsg.Start("FTSJoin", ply)
		umsg.Bool(true)
	umsg.End()
	
	for key, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() and ent.InFTS then
			ent:AddEntityRelationship(ply, D_HT, 70)
			ent:AddEntityRelationship(ply, D_LI, 0)
		end
	end
	
	seagulls.CreateAll()
	fts.StartHooks()
	timer.Create("player_position_sampler", 0.3, 0, fts.SamplePositions)
end

function fts.PlayerLeave(ply)
	ply.InFTS = false
	ply:SetNWBool("InFTS", false)
	
	umsg.Start("FTSJoin", ply)
		umsg.Bool(false)
	umsg.End()
	
	for key, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() and ent.InFTS then
			ent:AddEntityRelationship(ply, D_HT, 0)
			ent:AddEntityRelationship(ply, D_LI, 100)
		end
	end
	
	if not fts.IsActive() then
		seagulls.RemoveAll()
		fts.StopHooks()
		timer.Remove("player_position_sampler")
		
		for key, val in pairs(ents.GetAll()) do
			if val:IsNPC() and val.InFTS then
				val:Remove()
			end
		end
	end
end

function fts.Hook(name, ...)
	if not fts.IsActive() then return end 
	
	hook.Add(name, "fts_" .. name, fts[name])
	
	for key, val in pairs({...}) do
		hook.Add(val, "fts_" .. val, fts[name])
	end
	
	fts.ActiveHooks[name] = "fts_" .. name
end

function fts.StartHooks()
	for key, val in pairs(fts.ActiveHooks) do
		fts.Hook(key, val)
	end
end

function fts.StopHooks()
	for key, val in pairs(fts.ActiveHooks) do
		hook.Remove(key, val)
	end
end

if aowl then
	aowl.AddCommand("joinfts", function(ply)
		fts.PlayerJoin(ply)
	end)
	
	aowl.AddCommand("leavefts", function(ply)
		fts.PlayerLeave(ply)
	end)	
else
	concommand.Add("joinfts", function(ply)
		fts.PlayerJoin(ply)
	end)
	
	concommand.Add("leavefts", function(ply)
		fts.PlayerLeave(ply)
	end)	
end

local HOOK = fts.Hook

function fts.PlayerNoClip(ply)
	if not ply:GetNWBool("InFTS") then return end
	
	ply:SetMoveType(MOVETYPE_WALK)
	return false
end
HOOK("PlayerNoClip")

if CLIENT then
	usermessage.Hook("FTSJoin", function(umr)
		local b = umr:ReadBool()
		
		if b then
			fts.StartHooks()
		else
			fts.StopHooks()
		end
	end)
	
	local t = 0

	local smooth_offset = Vector(0,0,0)
	local smooth_noise = Vector(0,0,0)
	local noise = vector_origin

	local cvar_fov = GetConVar("fov_desired")

	function fts.CalcView(ply, pos, ang, fov)
		local wep =  ply:GetActiveWeapon()

		if wep:IsValid() and (not wep.GetIronsights or not wep:GetIronsights()) and math.ceil(fov) == math.ceil(cvar_fov:GetFloat()) and not wep:GetNWBool("IronSights") then

			local delta = math.Clamp(FrameTime(), 0.001, 0.5)

			if math.random() > 0.8 then
				noise = noise + VectorRand() * 0.1

				noise.x = math.Clamp(noise.x, -1, 1)
				noise.y = math.Clamp(noise.y, -1, 1)
				noise.z = math.Clamp(noise.z, -1, 1)
			end

			local params = GAMEMODE:CalcView(ply, pos, ang, fov)

			local vel = ply:GetVelocity()
			vel.z = -ply:GetVelocity().z

			vel = vel * 0.01

			vel.x = math.Clamp(-vel.x, -8, 8)
			vel.y = math.Clamp(vel.y, -8, 8)
			vel.z = math.Clamp(vel.z, -8, 8)

			local offset = vel * 1
			local mult = vel:Length() * 5

			if ply:IsOnGround() then
				local x = math.sin(t)
				local y = math.cos(t)
				local z = math.abs(math.cos(t))

				offset = offset + (Vector(x, y, z) * 3)

				t = t + (mult * delta)
			end

			smooth_noise = smooth_noise + ((noise - smooth_noise) * delta * 0.5 )

			--offset = LocalToWorld(offset, vector_origin, pos, vector_origin)

			offset.x = math.Clamp(offset.x, -4, 4)
			offset.y = math.Clamp(offset.y, -4, 4)
			offset.z = math.Clamp(offset.z, -4, 4)

			offset = (offset * 0.2) + (smooth_noise * math.min(mult, 2))

			params.vm_origin = (params.vm_origin or pos) + (offset)
			--params.vm_angles = (params.vm_angles or ang) + Angle(vel.x, vel.y, vel.z)


			return params
		end
	end
	HOOK("CalcView")

	--This is not perfect, but good enough
	function fts.PlayerStepSoundTime(ply)
		local running = ply:KeyDown(IN_SPEED)
		local walking = ply:KeyDown(IN_WALK)
		local sideways = ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT)
		local forward = ply:KeyDown(IN_FORWARD)
		local back = ply:KeyDown(IN_BACK)

		local time = 240

		if running then
			time = 140
			if sideways then
				time = 200
			end
		end
		if walking then
			time = 285
			if forward then
				time = 390
			end
			if back then
				time = 330
			end
		end
		if sideways and not forward then
			time = time * 0.75
		end

		if not walking and not running and back then
			time = 200
		end

		return time
	end
	HOOK("PlayerStepSoundTime")
end

if SERVER then
	function fts.PlayerSpawn(ply)
		if not ply.InFTS then return end
		
		timer.Simple(0, function()
			ply:SetPos(fts.GetRandomSpawnPos(ply))
		end)
	end
	HOOK("PlayerSpawn")

	function fts.DoPlayerDeath(ply, wep, ent)
		if not ply.InFTS then return end
		if not ent.InFTS then return end
		
		ply:DropCoins(ply:GetCoins() / 70)
	end
	HOOK("DoPlayerDeath")

	function fts.OnNPCKilled(npc, inflictor, ply)
		if not ply.InFTS then return end
		if not npc.InFTS then return end
		
		coins.SpewCoins(npc:EyePos(), (VectorRand() + Vector(0,0,1)) * 300, npc:GetMaxHealth() / 2)
	end
	HOOK("OnNPCKilled")

	function fts.GetFallDamage(ply, speed)
		if not ply.InFTS then return end
		
		speed = speed - 580
		return speed * (100/(1024-580))
	end
	HOOK("GetFallDamage")
	
	function fts.PlayerShouldTakeDamage(ply, ent)
		if ply.InFTS then
			if ent:IsPlayer() and not ent.InFTS then 
				return false 
			end
			
			for key, ent in pairs(ents.FindByClass("fts_heavy")) do
				if ent.Heavy.owner == ply and ent:GetClass() ~= "fts_heavy" then
					ent.Enemy = ent
				end
			end
			
			return true
		end
	end	
	HOOK("PlayerShouldTakeDamage")

	function fts.ScalePlayerDamage(ply, hitgroup, dmginfo)
		if not ply.InFTS then return end
				
		if hitgroup == HITGROUP_HEAD then
			dmginfo:ScaleDamage(1.5)
		elseif hitgroup == HITGROUP_LEFTARM or
			hitgroup == HITGROUP_RIGHTARM or
			hitgroup == HITGROUP_LEFTLEG or
			hitgroup == HITGROUP_RIGHTLEG or
			hitgroup == HITGROUP_GEAR then
			dmginfo:ScaleDamage(0.5)
		end

	end
	HOOK("ScalePlayerDamage")
	
	function fts.ScaleNPCDamage(...)
		return fts.ScalePlayerDamage(...)
	end
	HOOK("ScaleNPCDamage")

	function fts.AowlCommand(data, ply, line, arg1)	
		if not ply.InFTS then return end
		
		if ply:CheckUserGroupLevel("moderators") then return end
		if data.cmd == "goto" then 
			if arg1 == "shop" or GotoLocations[arg1] then	
				return
			end
		end
		if data.cmd == "goto" or data.cmd == "bring" or data.cmd == "tp" then
			return false, "tp is not allowed in fts"
		end
	end
	HOOK("AowlCommand")
	
	fts.sampled_positions = {}

	function fts.SamplePositions()	
		for key, ply in pairs(player.GetAll()) do
			if ply.InFTS and ply:IsOnGround() and ply:GetVelocity():Length() > 5 then
				if #fts.sampled_positions > 500 then
					table.remove(fts.sampled_positions, 1)
				end
				table.insert(fts.sampled_positions, ply:GetPos())
			end
		end
	end

	function fts.GetRandomFloorPos()
		if #fts.sampled_positions > 0 then
			return table.Random(fts.sampled_positions)
		end
	end

	function fts.IsSpawnNearby(pos, filter)
		for key, ent in pairs(ents.FindByClass("info_player_start")) do
			if ent ~= filter and ent:GetPos():Distance(pos) < 2000 then
				return true
			end
		end
		
		return false
	end
	
	function fts.ArePlayersNearby(pos, filter)
		for key, ply in pairs(player.GetAll()) do
			if ply.InFTS and ply ~= filter and (ply:GetPos():Distance(pos) < 2000 or ply:VisibleVec(pos)) then
				return true
			end
		end
		
		return false
	end

	function fts.ArePlayersNearbyEx(pos, filter)
		for key, ply in pairs(player.GetAll()) do
			if ply.InFTS and ply ~= filter and ply:GetPos():Distance(pos) < 2000 then
				return true
			end
		end

		return false
	end

	function fts.AreNPCsNearby(pos, filter)
		for key, npc in pairs(ents.GetAll()) do
			if npc.InFTS and type(npc) == "NPC" and npc.fts_squad ~= filter then
				if npc:GetPos():Distance(pos) < 2000 then
					return true
				end
			end
		end

		return false
	end

	function fts.GetRandomSpawnPos()
		local spawns = ents.FindByClass("info_player_start")

		for key, pos in pairs(fts.sampled_positions) do
			if not fts.ArePlayersNearbyEx(pos) and #ents.FindInSphere(pos, 30) == 0 then
				return pos
			end
		end
		
		if #spawns > 2 then
			return table.Random(spawns):GetPos()
		end
		
		if #fts.sampled_positions > 2 then
			return table.Random(fts.sampled_positions)
		end
		
		return table.Random(player.GetAll()):GetPos() + Vector(math.Rand(-1,1), math.Rand(-1,1), math.Rand(0,1) * 100)
	end
end

do -- seagulls
	seagulls = seagulls or {}
	seagulls.ClassName = "fts_seagull"

	seagulls.MaxSeagulls = 10
	seagulls.BlackList = seagulls.BlackList or {}

	do -- util
		seagulls.NestRadius = 500
		seagulls.RoofZ = -4096
		seagulls.Nest = Vector(-7885, -11016, -8350)

		function seagulls.GetNest()
			return seagulls.Nest
		end

		function seagulls.GetAll()
			return ents.FindByClass(seagulls.ClassName)
		end

		function seagulls.Create()
			if #seagulls.GetAll() < seagulls.MaxSeagulls then
				local ent = ents.Create(seagulls.ClassName)
				ent:SetPos(seagulls.Nest)
				ent:Spawn()
				return ent
			end
			
			return NULL
		end
		
		function seagulls.RemoveAll()
			for _, ent in pairs(seagulls.GetAll()) do
				ent:Remove()
			end
		end
		
		function seagulls.CreateAll()		
			for i=1, seagulls.MaxSeagulls do
				seagulls.Create()
			end
		end

		function seagulls.Respawn()
			local tbl = ents.FindByClass(seagulls.ClassName)
			local count = #tbl

			for key, ent in pairs(tbl) do
				ent:Remove()
			end

			for i=1, count do
				seagulls.Create()
			end
		end
		
		if SERVER then
			function seagulls.Initialize()
				seagulls.CreateAll()
				
				for key, value in pairs(ents.GetAll()) do
					value.seagull_lift = nil
				end
			end
		end
	end

	do -- meta
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

		do -- hitbox meta
			local ENT = {}
			ENT.IsSeagull = true
			ENT.InFTS = true
			ENT.FTSNPC = true

			ENT.Type = "ai"
			ENT.Base = "base_ai"
			ENT.ClassName = seagulls.ClassName .. "_hitbox"

			if SERVER then
				function ENT:Initialize()
					self:SetModel( "models/humans/group01/female_01.mdl" )

					self:SetHullType(HULL_HUMAN)
					self:SetHullSizeNormal()

					self:SetSolid( SOLID_BBOX )
					self:SetMoveType( MOVETYPE_NONE )

					self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_OPEN_DOORS | CAP_ANIMATEDFACE | CAP_TURN_HEAD | CAP_USE_SHOT_REGULATOR | CAP_AIM_GUN )
					self:SetNotSolid(true)

					self:SetNoDraw(true)

					self:SetHealth(9999999)
				end

				function ENT:OnRemove()
					SafeRemoveEntity(self.npc_hitbox)
				end

				hook.Add("OnEntityCreated", "seagull_hate", function(ent)
					timer.Simple(1, function()
						if ent:IsValid() and ent:IsNPC() and not ent.IsSeagull and fts.IsInFTS(ent) then
							for key, npc in pairs(ents.GetAll()) do
								if npc:IsNPC() and npc.IsSeagull then
									ent:AddEntityRelationship(npc, D_HT, 20)
								end
							end
						end
					end)
				end)
			end

			scripted_ents.Register(ENT, ENT.ClassName, true)
		end

		local ENT = {}

		ENT.IsSeagull = true
		ENT.ClassName = seagulls.ClassName
		ENT.FTSNPC = true

		ENT.Model = "models/seagull.mdl"
		ENT.Type = "anim"

		ENT.Target = NULL
		ENT.Size = 1

		ENT.Animations = {
			Fly = "fly",
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

		function ENT:SetupDataTables()
			self:DTVar("Float", 0, "Size")
			self:DTVar("Float", 1, "HeldEntityMass")
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
					self.OnGroundCache = util.QuickTrace(self:GetBottom(), vector_up * -3, {self, self.HeldEntity, self.FetchEntity}).Hit
					self.LastOnGround = CurTime() + 0.4
				end

				return self.OnGroundCache
			end

			function ENT:GetEntityFilter()
				if not self.LastFilterTime or self.LastFilterTime < CurTime() then
					local pos = self and self:GetPos() or vector_origin -- FIX ME
					self.LastFilter = {self, unpack(ents.FindInSphere(pos, self:GetSize()))}
					self.LastFilterTime = CurTime() + 0.3
				end
				return self.LastFilter
			end

			function seagulls.IsWithinMinMax(p)
				return true
			end

			function ENT:IsWithinMinMax(p)
				return seagulls.IsWithinMinMax(p)
			end
		end

		if CLIENT then
			language.Add("fts_seagull","Huge Seagull")

			do -- util
				function ENT:SetAnim(anim)
					self:SetSequence(self:LookupSequence(self.Animations[anim]))
				end
			end

			do -- calc
				ENT.Cycle = 0
				ENT.Noise = 0

				function ENT:AnimationThink(vel, len, ang)

					if self:GetOnGround() then

						if len < 3 then
							self:SetAnim("Idle")
							len = 15 / self:GetSize() * (self.Noise * 2)
						else
							self:StepSoundThink()

							if len > 50 then
								self:SetAnim("Run")
							else
								self:SetAnim("Walk")
							end
						end

						self.ang = Angle(0, ang.y, ang.r)
						self.Noise = (self.Noise + (math.Rand(-1,1) - self.Noise) * FrameTime() * 4)
					else
						self:SetAnim("Fly")

						if vel.z > 0 then
							len = len / 10
						else
							len = 0
							self.Cycle = 0.2
						end

						if self.dt.HeldEntityMass > 0 then
							len = len * self.dt.HeldEntityMass * 0.03
						end
					end

					self.Cycle = self.Cycle + (FrameTime() * len * 0.07)
					self:SetCycle(self.Cycle)
				end

				function ENT:StepSoundThink()
					local stepped = self.Cycle%0.5
					if stepped  < 0.3 then
						if not self.stepped then
							self:EmitSound(
								"npc/fast_zombie/foot2.wav",
								math.Clamp(20 * self:GetSize(), 70, 155) + math.Rand(-5,5),
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

					self:SetModelScale(Vector() * self:GetSize())
					if self.len > 5 or not self.lastang then
						self:SetAngles(self.ang)
						self.lastang = self.ang
					else
						self:SetAngles(self.lastang)
					end

					self:SetRenderOrigin(self:GetBottom())

					local min, max = self:GetRenderBounds()
					local size = self:GetSize() * 2
					self:SetRenderBounds(min * size, max * size)

					self:DrawShadow(false)
					self:SetupBones()
					self:DrawModel()
					self:SetRenderOrigin(nil)
				end

				function ENT:Think()
					if math.random() > 0.999 then
						self:EmitSound(table.Random(self.Sounds.AmbientIdle), 120, math.Clamp(100 / self:GetSize(), 30, 200) + math.Rand(-10,10))
					end
				end
			end

		end

		if SERVER then
			do -- util
				function ENT:GetAverageFlockPos()
					local pos = vector_origin
					local gulls = seagulls.GetAll()

					for _, ent in pairs(gulls) do
						if ent ~= self then
							pos = pos + ent:GetPos()
						end
					end

					local div = #gulls - 1

					if div ~= 0 then
						return pos / div
					end

					return seagulls.Nest
				end
			end

			do -- kill
				function ENT:KillTarget(ent)
					self:SetTargetPos(ent, "kill")
					self.Killing = true
				end
			end

			do -- move
				ENT.SmoothNoise = VectorRand()
				ENT.NextTry = 0

				AccessorFunc(ENT, "MoveDamping")
				AccessorFunc(ENT, "MovePos")

				function ENT:GetPrefferedStopRadius()
					return self.FetchEntity:IsValid() and 10 or 10 * self:GetSize()
				end

				function ENT:StopMoving()
					self.phys:AddVelocity(-self.phys:GetVelocity() * Vector(1,1,0))
					self.stop = true
				end

				function ENT:Trace(a, b)
					if not self.LastTrace or self.LastTrace < CurTime() then
						self.CachedTraceResults = util.TraceLine{
							start = a,
							endpos = b,
							filter = self:GetEntityFilter(),
						}
						self.LastTrace = CurTime() + 0.2
					end
					return self.CachedTraceResults
				end

				function ENT:CanSeePos(pos, threshold)
					return self:Trace(self:GetPos(), pos).HitPos:Distance(pos) < (threshold or 200)
				end

				function ENT:TryHeightPos(pos)
					self:SetMovePos(Vector(pos.x, pos.y, seagulls.RoofZ))
					self.Trying = "height"
				end

				function ENT:TryTracePos(pos)
					local hit_pos = self:Trace(self:GetPos(), pos).HitPos
					if hit_pos:Distance(pos) < 500 then
						local try = pos + Vector(math.Rand(-1000,1000), math.Rand(-1000,1000), 0)
						if self:CanSeePos(try) then
							self:SetMovePos(try)
							self.Trying = "trace"
						end
					end
				end

				function ENT:SetTargetPos(var, msg)
					local pos = IsVector(var) and var or IsEntity(var) and IsValid(var) and var:GetPos()

					if not pos or  pos:Distance(self:GetPos()) < self:GetPrefferedStopRadius() then return end

					self.TargetPos = var
					self.TargetReachMessage = msg

					if self:CanSeePos(pos) then
						self:SetMovePos(pos)
					else
						self:TryHeightPos(pos)
					end

					self.TryingTargetPos = {var = var, started = CurTime()}
				end

				function ENT:GetTargetPos()
					return self.TargetPos and (IsVector(self.TargetPos) and self.TargetPos or (IsValid(self.TargetPos) and self.TargetPos:GetPos()))
				end
			end

			do -- pickup
				ENT.FetchEntity = NULL
				ENT.HeldEntity = NULL
				AccessorFunc(ENT, "HeldEntity")

				function ENT:Pickup(ent)
					if ent:IsValid() and not self.HeldEntity:IsValid() then
						if not ent.seagull_carriers and not ent:GetClass():find("fts_") then
							constraint.RemoveAll(ent)
						end
						if ent:IsPlayer() then
							self.HoldingPlayer = true
						elseif ent:IsNPC() then
							ent:SetParent(self)
						else
							--ent:SetPos(self:GetPos())
							local weld = constraint.Weld(self, ent)
							if weld then
								ent:GetPhysicsObject():EnableMotion(true)

								for key, ent in pairs(constraint.GetAllConstrainedEntities(ent)) do
									ent:GetPhysicsObject():EnableMotion(true)
								end

								self.weld = weld
								self:SetHeldEntity(ent)
								self.dt.HeldEntityMass = self:GetPhysicsObject():GetMass()

								ent.seagull_carriers = ent.seagull_carriers or {}
								table.insert(ent.seagull_carriers, self)
							else
								ent:SetPos(self:GetBottom())
								ent:SetParent(self)
							end
						end

						ent:CallOnRemove(seagulls.ClassName, function()
							if self.IsSeagull and self.FetchEntity == ent then
								self:Drop()
							end
						end)
					end
				end
				function ENT:Drop()
					if self.weld and self.weld:IsValid() then
						self.weld:Remove()
					end
					local ent = self.FetchEntity
					if ent:IsValid() then
						if ent:IsPlayer() then
							ent:SetMoveType(MOVETYPE_WALK)
						elseif ent:IsNPC() then
							ent:SetParent()
							ent:SetAngles(Angle(0,ent:GetAngles().y,0))
						else
							ent:SetPos(self.FetchEntity:GetPos())
							if ent.seagull_carriers then
								for key, value in pairs(ent.seagull_carriers) do
									if value.IsSeagull and value ~= self then
										value.DropIt = true
									end
								end
							end
						end
						ent.seagull_lift = nil
						ent.seagull_carriers = nil
					end
					self.dt.HeldEntityMass = 0

					self.FetchEntity = NULL
					self.HeldEntity = NULL

					self.TargetPos = nil
					self.MovePos = nil

					self.HoldingPlayer = false
					self.Killing = false
				end

				function ENT:Fetch(ent)
					if ent:IsValid() and not self.FetchEntity:IsValid() then
						ent.seagull_lift = (ent.seagull_lift or 0) + self:GetSize()
						self.FetchEntity = ent
						self:SetTargetPos(ent, "pickup")
					end
				end

				function ENT:IsPickupAllowed(ent)				
					if math.random() > 0.5 then return false end
					
					if ent.FTSNPC then
						return false
					end
					
					if ent:IsVehicle() then
						return false
					end
					
					if ent.IsInFTS then
						return false
					end			

					if ent.IsSeagull then
						return false
					end

					if not ent:GetPhysicsObject():IsValid() then
						return false
					end

					if ent:GetMoveType() == 0 then
						return false
					end

					if ent.fts_store_owner and ent.fts_store_owner:IsValid() then
						return false
					end

					if seagulls.BlackList[ent] then
						return false
					end
					
					if ent:GetClass() == "fts_heavy" then
						return false
					end
					
					if ent:GetClass() == "fts_angry_baby" then
						return false
					end
					
					if not fts.IsInFTS(ent) then
						return false
					end

					if ent:GetPos():Distance(seagulls.Nest) < seagulls.NestRadius then
						return false
					end

					if ent:IsPlayer() or ent:GetClass() == "fts_van" then
						return false
					end

					if ent:GetClass():sub(0, 4) == "fts_" then
						return false
					end

					if
						not ent.IsSeagull and
						util.IsValidPhysicsObject(ent) and
						ent:GetMoveType() == MOVETYPE_VPHYSICS and
						(not ent.seagull_lift or (390 * ent.seagull_lift) < ent:GetPhysicsObject():GetMass() + 200)
					then
						return true
					end

					if ent:IsNPC() and not ent:GetParent().IsSeagull and not ent.seagull_lift and math.random() > 0.9999 then
						return true
					end

					return false
				end

				function ENT:FetchRandom()
					for key, ent in pairs(ents.GetAll()) do
						if self:IsPickupAllowed(ent) then
							self:Fetch(ent)
							break
						end
					end
				end
			end

			do -- calc
				function ENT:IdleThink(phys)
					if not self.TargetPos then
						if self:GetOnGround() then
							if (self.LastIdleDir or 0) < CurTime() then
								phys:AddVelocity(VectorRand() * phys:GetMass() * Vector(1,1,0) * 5)
								self.LastIdleDir = CurTime() + math.Rand(1.5,4)
							end
							phys:AddVelocity(phys:GetVelocity() *- 0.03)
						end

						if self:GetPos():Distance(seagulls.Nest) > seagulls.NestRadius then
							phys:AddVelocity(seagulls.Nest - phys:GetPos())
						end
					end
				end

				function ENT:TryThink()
					if self.NextTry < CurTime() then
						local pos = self:GetTargetPos()

						if pos then
							if self:CanSeePos(pos) then
								self:SetMovePos(pos)
								self.NextTry = 0
							else
								if
									self.Trying == "height" and
									(pos - self.pos):Length2D() < self:GetPrefferedStopRadius()
								then
									self:TryTracePos(pos)
								end

								if
									self.Trying == "trace" and
									(
										self.len < 100 or
										self.pos:Distance(pos) < self:GetPrefferedStopRadius()
									)
								then
									self.Trying = false
								end

								if self.MovePos and not self:CanSeePos(self.MovePos) and self.MovePos:Distance(pos) < 1000  then
									self:TryHeightPos(pos)
								end

								if not self.Trying then
									self:TryHeightPos(pos)
								end

								self.NextTry = CurTime() + math.Rand(0.2,0.4)
							end
						end
					end
				end

				function ENT:MoveThink(phys, pos, movepos, distance)
					local vel = movepos - pos
					phys:AddVelocity(vel:Normalize() * (math.Clamp(vel:Length()*0.1, 30, 500) * self:GetSize()))

					if self.TouchEntity:IsValid() then
						local phys, ent = self.TouchEntity:GetPhysicsObject(), self.TouchEntity
						if 
							not ent.IsSeagull and 
							ent ~= self.FetchEntity and 
							not ent.seagull_lift and 
							fts.IsInFTS(ent) and
							phys:IsValid() and 
							ent:GetMoveType() == MOVETYPE_VPHYSICS and 
							ent:GetClass():sub(0, 4) ~= "fts_" 
						then
							constraint.RemoveAll(ent)
							phys:EnableMotion(true)
							phys:AddVelocity(VectorRand()*10000)

							local ef = EffectData()
							ef:SetOrigin(ent:GetPos())
							util.Effect("explosion", ef)
						end
					end
				end
			end

			do -- standard
				function ENT:Initialize()
					self:SetSize(math.Rand(0.5, 10.5))

					self:SetModel(self.Model)
					self:PhysicsInitSphere(5 * self:GetSize())
					self:StartMotionController()
					self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)

					self.flight_dir = math.Rand(0.3,1) * (math.random() > 0.5 and -1 or 1)

					local phys = self:GetPhysicsObject()
						phys:SetMass(20 * self:GetSize())
						phys:SetMaterial("default_silent")
					self.phys = phys


					local hitbox = ents.Create(self.ClassName .. "_hitbox")
						self:SetOwner(hitbox)
						hitbox.FTSNPC = true
						hitbox.OnTakeDamage = function(_, dmg) if self.OnTakeDamage then self:OnTakeDamage(dmg) end end
						hitbox:SetPos(self:GetPos())
						hitbox:Spawn()
						hitbox:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
					self.HitBox = hitbox

					self:MakeNPCSHateMe()
				end

				function ENT:MakeNPCSHateMe()
					for key, npc in pairs(ents.GetAll()) do
						if npc:IsNPC() then
							npc:AddEntityRelationship(self.HitBox, D_HT, 20)
						end
					end
				end

				function ENT:Think()
					self:PhysWake()
					self:FetchRandom()
					self:NextThink(CurTime() + math.Rand(1,5))
					return true
				end

				function ENT:PhysicsSimulate(phys, delta)

					if self.HitBox and self.HitBox:IsValid() then
						self.HitBox:SetAngles(Angle(0,0,0))
						self.HitBox:SetPos(self:GetBottom())
					end

					-- Bugfix. Why does this happen?
					if not phys:IsValid() then

						if not self.error then
							self.error=true
							ErrorNoHalt("[Seagull] ",self,phys,self:GetModel(),self.FetchEntity,self.HoldingPlayer,"\n")
						end
						-- self:Remove()
						return

					end

					self.vel = phys:GetVelocity()
					self.len = self.vel:Length()
					self.len2d = self.vel:Length2D()
					self.pos = phys:GetPos()

					if self.DropIt then
						self:Drop()
						self.DropIt = false
					end

					if not self.FetchEntity:IsValid() then
						self:Drop()
					end

					if self.HoldingPlayer then
						self.FetchEntity:SetMoveType(MOVETYPE_NOCLIP)
						self.FetchEntity:GetPhysicsObject():SetVelocity(vector_origin)
						self.FetchEntity:SetVelocity(vector_origin)
						self.FetchEntity:SetPos(self:GetPos())
					end

					local reached_message

					if self:GetOnGround() then
						self.MoveDamping = 0.4
					elseif self.len2d > 10 then
						self.MoveDamping = 0.1
						phys:AddVelocity(vector_up * (self.len2d * 0.003))
					end

					if self.MovePos then
						self:TryThink()

						self.MoveDistance = (self.MovePos-phys:GetPos()):LengthSqr()

						if
							IsVector(self.TargetPos) and (self:GetTargetPos()-self.pos):LengthSqr() < 1300 or
							(IsEntity(self.TargetPos) and self.TargetPos:IsValid() and (self.TouchEntity == self.TargetPos) or (self:GetTargetPos()-self.pos):Length() < (self:GetSize() * 6))
						then
							reached_message = self.TargetReachMessage
						end

						if self.MoveDistance < self:GetPrefferedStopRadius()*100 then
							self:StopMoving()
						else
							self:MoveThink(phys, self.pos, self.MovePos, self.MoveDistance)

							phys:AddVelocity(-phys:GetVelocity() * self:GetMoveDamping() * math.min(self.len2d / 1000, 1000))
							phys:AddVelocity(self.SmoothNoise * Vector(1,1,0.5) * self:GetSize() * 30)
						end
					end

					if not self.Killing then
						self:IdleThink(phys)
					end

					if reached_message == "pickup" then
						timer.Simple(0, function()
							self:Pickup(self.FetchEntity)
							self:SetTargetPos(seagulls.Nest, "nest")
						end)
					elseif reached_message == "nest idle" then
						self.TargetPos = nil
						self.MovePos = nil
						--self:FetchRandom()
					elseif reached_message == "kill" then
						if self.TargetPos:IsPlayer() then
							self.TargetPos:TakeDamage(self:GetSize() * 10)

							if not self.TargetPos:Alive() or self.TargetPos:Health() < 5 then
								self:Drop()
							end
						end
					elseif reached_message == "nest" then
						if self.HeldEntity:IsValid() and self.HeldEntity:GetPos():Distance(self:GetPos()) > 500 then
							seagulls.BlackList[self.HeldEntity] = true
						end
						self:Drop()
					end

					if self.TryingTargetPos and self.TryingTargetPos.started + 50 < CurTime() then
						seagulls.BlackList[self.TryingTargetPos.var] = true
						self:Drop()
					end

					self.Stop = false
					self.SmoothNoise = self.SmoothNoise + (((VectorRand() * 0.1) - self.SmoothNoise) * FrameTime())
				end

				function ENT:OnTakeDamage(dmg)
					local ply = dmg:GetAttacker()
					if ply.InFTS and not ply.FTSNPC and (ply:IsPlayer() or ply:IsNPC()) then
						fts.ee.DamagaeEntity(self, dmg:GetDamage())
						self:Drop()
						self:KillTarget(ply)
					end
				end

				ENT.TouchEntity = NULL

				function ENT:StartTouch(ent)
					self.TouchEntity = ent
				end

				function ENT:EndTouch(...)
					self.TouchEntity = NULL
				end

				function ENT:PhysicsCollide(data)
					self.TouchEntity = data.HitEntity
				end

				function ENT:Die()
					if not self.DontSpawnCoin and coins then
						local coin = coins.Create(self:GetPos(), math.floor(self:GetSize()*100))
						coin:GetPhysicsObject():AddVelocity(VectorRand()*150)
					end
					self:Remove()
					self:PlaySound("Impact")
				end

				function ENT:OnRemove()
					self:Drop()
				end
			end
		end

		scripted_ents.Register(ENT, seagulls.ClassName, true)

		seagulls.EntityMeta = ENT
	end
end

do -- npcs

	if CLIENT then
		function fts.BoneMerge(npc, mdl)
			SafeRemoveEntity(npc.cs_mdl)

			local ent = ClientsideModel(mdl)
			ent:SetPos(npc:GetPos())
			ent:SetParent(npc)

			ent:AddEffects(EF_BONEMERGE)
			npc.cs_mdl = ent
			npc:SetColor(0,0,0,1)
			npc:SetMaterial("models/effects/vol_light001")
			npc:CallOnRemove("bonemerge", function()
				SafeRemoveEntity(npc.cs_mdl)
			end)
		end

		timer.Create("check_bonemerge_npcs", 1, 0, function()
			for key, ent in pairs(ents.GetAll()) do
				if ent:IsNPC() and not ent.cs_mdl then
					local mdl = ent:GetNWString("cs_model", false)
					if mdl then
						fts.BoneMerge(ent, mdl)
					end
				end
			end
		end)
	end

	if SERVER then 

		for key, ent in pairs(ents.GetAll()) do
			if not ent:IsPlayer() and ent.InFTS then
				ent:Remove()
			end
		end
		
		fts.NPCS =
		{
			{
				class = "npc_combine_s",
				squad = "combine_hard",
				max = 5,

				health = 500,

				weapon = "weapon_ar2",
				aim = WEAPON_PROFICIENCY_AVERAGE,

				keyvalues =
				{
					--spawnflags = "256", -- long shot
					tacticalvariant = "1",
				}
			},
			{
				class = "npc_combine_s",
				squad = "boomer_and_bomette",
				max = 1,

				health = 1000,

				weapon = "weapon_ar2",
				aim = WEAPON_PROFICIENCY_PERFECT,

				keyvalues =
				{
					--spawnflags = "256", -- long shot
					tacticalvariant = "1",
				},
				post_spawn = function(self)
					self:SetNWString("cs_model", "models/infected/boomer.mdl")
				end,
			},
			{
				class = "npc_combine_s",
				squad = "boomer_and_bomette",
				max = 1,

				health = 1000,

				weapon = "weapon_ar2",
				aim = WEAPON_PROFICIENCY_PERFECT,

				keyvalues =
				{
					--spawnflags = "256", -- long shot
					tacticalvariant = "1",
				},
				post_spawn = function(self)
					self:SetNWString("cs_model", "models/infected/boomette.mdl")
				end,
			},
			{
				class = "npc_citizen",
				squad = "citizen_hard",
				max = 3,

				health = 300,

				weapon = "weapon_smg1",
				aim = WEAPON_PROFICIENCY_POOR,

				keyvalues =
				{
					--spawnflags = "256", -- long shot
					tacticalvariant = "1",
				},

				post_spawn = function(self)
					self:SetNPCState(NPC_STATE_ALERT)
					for key, ent in pairs(ents.GetAll()) do
						if ent:IsNPC() and ent.InFTS and ent:GetClass():find("combine") then
							ent:AddEntityRelationship(self, D_HT, 99)
							self:AddEntityRelationship(ent, D_HT, 99)
						end
					end
				end,
			},
			{
				class = "npc_strider",
				squad = "combine_hard",
				max = 1,
				min_height = 500,
			},
			{
				class = "npc_antlionguard",
				squad = "antlions",
				max = 1,
			},
			{
				class = "npc_vortigaunt",
				squad = "vortigaunts",
				max = 5,
			},
			{
				class = "fts_heavy",
				max = 3,
			},
			{
				class = "fts_angry_baby",
				squad = "angry_baby",
				max = 20,
			},
			{
				class = seagulls.ClassName,
				squad = "seagulls",
				max = seagulls.MaxSeagulls,
				pre_spawn = function(self)
					seagulls.Create()
					return false
				end,
			},


		}

		timer.Create("npc_spawner", 4, 0, function()
			if not fts.IsActive() then return end
			
			if #fts.sampled_positions < 5 then return end

			--if math.random(100) ~= 1 then return end

			local data = table.Random(fts.NPCS)
			local npcs = ents.FindByClass(data.class)
			local count = 0

			for key, ent in pairs(npcs) do
				if not data.squad or ent.fts_squad == data.squad then
					count = count + 1
				end
			end

			if count < data.max then
				local pos

				if count >= 1 then
					pos = npcs[1]:GetPos() + (Vector(math.Rand(-1,1), math.Rand(-1,1), math.Rand(0,1)) * 100)
				else
					pos = fts.GetRandomFloorPos()
				end


				if	
					pos and
					not fts.IsSpawnNearby(pos) and
					not fts.ArePlayersNearbyEx(pos) and
					(not data.min_height or not util.QuickTrace(pos, Vector(0,0,-data.min_height)).HitWorld)
				then
					local npc = ents.Create(data.class)

					if data.pre_spawn and data.pre_spawn(npc) == false then
						return
					end
					
					npc.InFTS = true
					npc:SetPos(pos + Vector(0,0,100))

					if data.weapon then
						npc:SetKeyValue("additionalequipment", data.weapon)
					end

					if data.keyvalues then
						for key, value in pairs(data.keyvalues) do
							npc:SetKeyValue(key, value)
						end
					end

					if data.squad then
						npc:SetKeyValue("squad", data.squad)
						npc.fts_squad = data.squad
					end

					npc:Spawn()
					npc:Activate()

					if data.health then
						npc:SetHealth(data.health)
						npc:SetMaxHealth(data.health)
						npc:SetNWInt("fts_health", data.health)
						npc:SetNWInt("fts_maxhealth", data.health)
					end

					if data.squad then
						npc:Fire("StartPatrolling", "", 0.5)
						npc:Fire("SetSquad", data.squad, 0.5)
					end

					if data.post_spawn then
						data.post_spawn(npc)
					end
					
					if npc:IsNPC() then
					
						if data.aim then
							npc:SetCurrentWeaponProficiency(data.aim)
						end

						for key, ply in pairs(player.GetAll()) do
							if ply.InFTS then
								npc:AddEntityRelationship(ply, D_HT, 70)
							else
								npc:AddEntityRelationship(ply, D_LI, 100)
							end
						end
					end
				end
			end
		end)

	end
end

do -- heavy
	local ENT = {}

	ENT.Type = "anim"
	ENT.Base = "base_anim"
	ENT.ClassName = "fts_heavy"
	ENT.InFTS = true
	ENT.FTSNPC = true

	function ENT:SetupDataTables()
		self:DTVar("Entity", 0, "Heavy")
	end

	if SERVER then
		function ENT:Initialize()
			self:SetModel("models/props_junk/PopCan01a.mdl")
			self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
			self:SetNoDraw(true)
			
			local heavy = ents.Create("prop_ragdoll")
				heavy.FTSNPC = true
				heavy:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
				heavy:SetModel("models/player/heavy.mdl")
				heavy:SetPos(self:GetPos())
				heavy.fts_health_override = 20000
				heavy:Spawn()
			self.Heavy = heavy
			
			self:SetParent(self.Heavy)

			self.dt.Heavy = heavy
		end
			
		function ENT:SetPlayer(player)
		
			local number = math.random(17)
			if number < 10 then
				number = "0"..number
			end
			self:PlaySound("vo/heavy_sandwichtaunt"..number..".wav")
			
			self.target = player
			self.Heavy.owner = player
			if self.Heavy.CPPISetOwner then 
				self.Heavy:CPPISetOwner(player) 
			end
		end
		
		function ENT:PlaySound(path)
			if not self.busysound then
				self.Heavy:EmitSound(path, 100, math.random(90,110))
				self.busysound = true
			end
			timer.Simple(SoundDuration(path), function()
				if not IsValid(self) then return end
				self.busysound = false
			end)
		end	

		function ENT:Think()
			if not IsValid(self.Heavy.owner) then
				for key, ply in pairs(player.GetAll()) do
					if ply.InFTS and ply:GetPos():Distance(self:GetPos()) < 1000 then
						self:SetPlayer(ply)
					end
				end
			else
				local enemy = self.Enemy or NULL
							
				if enemy:IsValid() then
					self.target = enemy
					local handpos = self.Heavy:GetBonePosition(self.Heavy:LookupBone("bip_hand_l"))
					local distance = enemy:GetPos():Distance(handpos)
					
					if distance < 60 then
						local data = DamageInfo()
						data:SetAttacker(self.Heavy.owner)
						data:SetDamageType(DMG_BULLET)
						data:SetDamage(10)
						self.target:OnTakeDamage(data)
					end					
				end
			end
			
			if not IsValid(self.target) then self.target = self.Heavy.owner end
		
			local target = self.target
			if IsValid(target) then
				local heavy = self.Heavy
				
				for i=0, heavy:GetFlexNum() do
					heavy:SetFlexWeight(i, math.random()*0.4)
				end
				
				if math.random() > 0.999 then
					self:PlaySound("vo/heavy_positivevocalization0"..math.random(5)..".wav")
				end
			
				local head = heavy:GetPhysicsObjectNum(14)
				local lefthand = heavy:GetPhysicsObjectNum(11)
				local righthand = heavy:GetPhysicsObjectNum(13)
				local rightfoot = heavy:GetPhysicsObjectNum(15)
				local leftfoot = heavy:GetPhysicsObjectNum(5)
				local pelvis = heavy:GetPhysicsObjectNum(0)
				
				local velocity = (target:IsPlayer() and target:GetShootPos() or target:GetPos()) - heavy:GetPos()
				
				if target:IsPlayer() and target:GetShootPos():Distance(heavy:GetPos()) < 200 then
					velocity = Vector(0)
					
					constraint.RemoveAll(self.Heavy)
				end
				
				if target:GetClass() == "fts_seagull" then velocity = velocity:Normalize() * 1000 end
				
				local gravity = Vector(0,0,-20)
				
				head:AddVelocity(velocity)
				lefthand:AddVelocity(velocity)
				righthand:AddVelocity(velocity)
				
				head:AddAngleVelocity(Vector(-100,0,0))
				-- leftfoot:AddVelocity(gravity)
				
				for i=0,15 do
					local phys = heavy:GetPhysicsObject()
					phys:EnableGravity(false)
					local phys = heavy:GetPhysicsObjectNum(i)
					phys:EnableGravity(false)	
					if self.target:GetClass() ~= "fts_seagull" then phys:AddVelocity(phys:GetVelocity()*-0.1) end
				end
				
				--rightfoot:AddVelocity(gravity)
				--leftfoot:AddVelocity(gravity)
			end		
			self:NextThink(CurTime())
			return true
		end
		
		function ENT:OnRemove()
			if IsValid(self.Heavy) then self.Heavy:Remove() end
		end

	else
		function ENT:Initialize()
			self.emitter = ParticleEmitter(self.dt.Heavy:GetPos())
		end

		local bones = {
			"bip_foot_r",
			"bip_foot_l",
		}
		
		function ENT:Think()
			if self.dt.dead then return end
			
			local heavy = self.dt.Heavy
			
			for key, bone in pairs(bones) do
				local position = heavy:GetBonePosition(heavy:LookupBone(bone))
				
				local particle = self.emitter:Add( "effects/yellowflare", position )
				particle:SetVelocity( VectorRand() * 10 )
				particle:SetDieTime( 5 )
				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )
				particle:SetStartSize( 4 )
				particle:SetEndSize( 0 )
				particle:SetRoll( math.Rand( -360, 360 ) )
				particle:SetRollDelta( math.Rand( -30, 30 ) )
				particle:SetBounce( 1.0 )
			end
		end
	end

	scripted_ents.Register(ENT, ENT.ClassName, true)
end

do -- angry baby
	local ENT = {}

	ENT.Type = "anim"
	ENT.Base = "base_anim"
	ENT.ClassName = "fts_angry_baby"
	ENT.FTSNPC = true
	ENT.InFTS = true

	if SERVER then
		function ENT:Initialize()
			self:SetModel("models/props_c17/doll01.mdl")		

			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)

			self:StartMotionController()
			
			local phys = self:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetMass(100)
				phys:SetDamping(0,0)
				phys:SetBuoyancyRatio(0)
			end	
		end

		timer.Create("fts_angry_baby_find_target", 1, 0, function() 
			local number_of_babies = #ents.FindByClass("fts_angry_baby")
			if number_of_babies == 0 then return end
			local baby = ents.FindByClass("fts_angry_baby")[math.random(number_of_babies)]
			for key, entity in pairs(ents.FindInSphere(baby:GetPos(), 10000)) do
				if fts.IsInFTS(entity) then
					if entity:GetClass() == "prop_physics" and entity:WaterLevel() >= 1 and string.find(entity:GetModel() or "", "melon") then
						fts.AngryBabyTarget = entity
						return
					end
					if entity:GetClass() == "prop_physics" and string.find(entity:GetModel() or "", "melon") then
						fts.AngryBabyTarget = entity
						return
					end
					if IsValid(entity) and entity:GetClass() == "prop_physics" and (entity:GetClass() ~= "fts_angry_baby" and entity:GetVelocity():Length() > 20) then
						fts.AngryBabyTarget = entity
					end
				end
			end		
		end)

		function ENT:PhysicsSimulate(phys, deltatime)
			if self:WaterLevel() >= 3 then
				phys:SetDamping(1, 0)
				if math.random() > 0.95 then
					if ValidEntity(self.target) then
						phys:AddVelocity((self.target:GetPos() - self:GetPos()):Normalize()*100)
						phys:AddAngleVelocity(VectorRand()*2000)
					else
						phys:AddVelocity(VectorRand()*200)
						phys:AddAngleVelocity(VectorRand()*2000)
					end
				end
			else
				phys:SetDamping(3,0)
				if constraint.FindConstraint(self, "Weld") then
					phys:AddVelocity(VectorRand()*1000)
					phys:AddAngleVelocity(VectorRand()*5000)
					return
				end
			
				if ValidEntity(self.target) then
					phys:AddVelocity((self.target:GetPos() - self:GetPos()))
					phys:AddAngleVelocity(VectorRand()*2000)
				else
					phys:AddVelocity(VectorRand()*200)
					phys:AddAngleVelocity(VectorRand()*2000)
				end
			end
		end

		function ENT:Think()	
			self.target = fts.AngryBabyTarget
			
			self:PhysWake()
				
			self:NextThink(CurTime() + 0.3)
			return true
		end

	end

	scripted_ents.Register(ENT, ENT.ClassName, true)
end

do -- explosive entities
	local ee = {}

	do -- effects
		if CLIENT then
			local R = math.Rand
			
			do -- materials
				local smoke = 
				{
					"particle/smokesprites_0001",
					"particle/smokesprites_0002",
					"particle/smokesprites_0003",
					"particle/smokesprites_0004",
					"particle/smokesprites_0005",
					"particle/smokesprites_0006",
					"particle/smokesprites_0007",
					"particle/smokesprites_0008",
					"particle/smokesprites_0009",
					"particle/smokesprites_0010",
					"particle/smokesprites_0012",
					"particle/smokesprites_0013",
					"particle/smokesprites_0014",
					"particle/smokesprites_0015",
					"particle/smokesprites_0016",
				}

				function ee.GetMaterial(typ)
					if ee.use_custom_materials == nil then						
						if file.Exists("materials/modulus/particles/fire8.vtf", true) then
							ee.use_custom_materials = true
						else
							ee.use_custom_materials = false
						end			
					end
				
					if ee.use_custom_materials == true then
						if typ == "fire" then
							return "modulus/particles/fire"..math.random(1,8)
						elseif typ == "smoke" then
							return "modulus/particles/smoke"..math.random(1,6)
						end
					elseif ee.use_custom_materials == false then
						if typ == "fire" then
							return "particles/flamelet" .. math.random(1,5)
						elseif typ == "smoke" then
							return table.Random(smoke)
						end
					end
				end
			end

			function ee.DrawSunBeams(pos, mult, siz)
				local ply = LocalPlayer()
				local eye = EyePos()
				
				if not util.QuickTrace(eye, pos-eye, {ply}).HitWorld then
					local spos = pos:ToScreen()
					DrawSunbeams(
						0, 
						mult * math.Clamp(ply:GetAimVector():DotProduct((pos - eye):Normalize()) - 0.5, 0, 1) * 2, 
						siz, 
						spos.x / ScrW(), 
						spos.y / ScrH()
					)
				end
			end
			
			do -- particles
				local emt = ParticleEmitter(vector_origin)
				local prt

				function ee.EmitExplosion(pos, size)
					size = math.max(size, 10) / 2
					
					emt:SetPos(pos)
					
					for i = 1, 30 do
						prt = emt:Add(ee.GetMaterial("smoke"), pos)
						prt:SetVelocity(VectorRand() * size * 10)
						prt:SetDieTime(R(5, 10))
						prt:SetStartAlpha(R(200, 255))
						prt:SetEndAlpha(0)
						prt:SetStartSize(size * 2)
						prt:SetEndSize(size * 4)
						prt:SetAirResistance(200)
						prt:SetRoll(R(-5, 5))
						prt:VelocityDecay(true)
						prt:SetLighting(true)
						
						prt = emt:Add(ee.GetMaterial("fire"), pos)
						prt:SetVelocity(VectorRand() * size * 10) 		
						prt:SetDieTime(0.3) 		 
						prt:SetStartAlpha(R(200, 255)) 
						prt:SetEndAlpha(0) 	 
						prt:SetStartSize(size) 
						prt:SetEndSize(size * 2) 		 
						prt:SetRoll(R(-5, 5))
						prt:SetAirResistance(400) 
						--prt:SetLighting(true)
					end
					
					for i = 0, math.pi*2, math.pi*2/50 do
						prt = emt:Add(ee.GetMaterial("smoke"), pos)
						prt:SetVelocity(Vector(math.sin(i) * size * 30, math.cos(i) * size * 30, R(-5, 5)))
						prt:SetDieTime(R(1, 2))
						prt:SetStartAlpha(R(40, 100))
						prt:SetEndAlpha(0)
						prt:SetStartSize(size * 2)
						prt:SetEndSize(size * 4)
						prt:SetAirResistance(100)
						prt:SetRoll(R(-5, 5))
						prt:VelocityDecay(true)
						prt:SetLighting(true)
						prt:SetGravity(Vector(0, 0, size))
					end
				end

				function ee.EmitHealthSmoke(pos, size, cur_hp, max_hp)
					size = math.max(size, 10)
					
					emt:SetPos(pos)
					
					prt = emt:Add(ee.GetMaterial("smoke"), pos)
					prt:SetVelocity(VectorRand() * size)
					prt:SetDieTime(R(5, 10))
					prt:SetStartAlpha((cur_hp / max_hp) * 255)
					prt:SetEndAlpha(0)
					prt:SetStartSize(size * 2)
					prt:SetEndSize(size * 4)
					prt:SetAirResistance(200)
					prt:SetRoll(R(-5, 5))
					prt:VelocityDecay(true)
					prt:SetLighting(true)
				end
				
				function ee.EmitDeadEntity(ent)
					local min, max = ent:WorldSpaceAABB()
					local offset = Vector(R(min.x, max.x), R(min.y, max.y), R(min.z, max.z))
					local normal = (offset - ent:GetPos()):GetNormalized()
				
					local size = math.Clamp(ent:BoundingRadius() + R(0, 20), 5, 1000)
					
					emt:SetPos(offset)

					prt = emt:Add(ee.GetMaterial("fire"), offset)
					prt:SetVelocity(normal * 1000)
					prt:SetAirResistance(1000)
					prt:SetDieTime(0.5)
					prt:SetStartAlpha(255)
					prt:SetStartSize(size)
					prt:SetEndSize(size * 2)
					prt:SetRoll(R(-5, 5))
					prt:SetColor(255, 255, 255)
					--prt:SetLighting(true)

					prt = emt:Add(ee.GetMaterial("smoke"), offset)
					prt:SetVelocity(normal * R(10, 20))
					prt:SetDieTime(R(5, 10))
					prt:SetStartAlpha(255)
					prt:SetStartSize(size)
					prt:SetEndSize(size * 4)
					prt:SetRoll(R(-5, 5))
					prt:SetLighting(true)
				end
			end
			
			ee.SmokingEntities = {}
			
			function ee.SmokeThink()
				for key, ent in pairs(ee.SmokingEntities) do
					if ent:IsValid() then
						ee.EmitHealthSmoke(ent:GetPos(), ent:BoundingRadius(), ent:GetNWInt("ee_health"), ent.ee_max_hp or ent:BoundingRadius())
					else
						ee.SmokingEntities[key] = nil
					end
				end
			end
			
			hook.Add("Think", "ee_smoke_think", ee.SmokeThink)
			
			function ee.AttachSmoke(ent, max)
				ent.ee_max_hp = max
				table.insert(ee.SmokingEntities, ent)
			end
			
			usermessage.Hook("ee_smoke", function(umr)
				local ent = umr:ReadEntity()
				local max = umr:ReadLong()
				
				if ent:IsValid() then
					ee.AttachSmoke(ent, max)
				end
			end)
			
			usermessage.Hook("ee_explosion", function(umr)
				local pos = umr:ReadVector()
				local size = umr:ReadFloat()
				
				ee.EmitExplosion(pos, size)
			end)
		end
		
		if SERVER then
			local last = 0
			local count = 0
			
			function ee.EmitExplosion(pos, size)
				if last > CurTime() and count > 5 then return end
				
				umsg.Start("ee_explosion")
					umsg.Vector(pos)
					umsg.Float(size)
				umsg.End()
				
				ee.PlayExplosionSound(pos, size)
				
				last = CurTime() + 0.1
				count = count + 1
			end
			
			function ee.AttachSmoke(ent, max)
				umsg.Start("ee_smoke")
					umsg.Entity(ent)
					umsg.Long(max or ent.ee_max_hp)
				umsg.End()
			end
		end
		
		function ee.PlayExplosionSound(pos, size)
			WorldSound(
				"ambient/explosions/explode_" .. math.random(1,4) .. ".wav", 
				pos,
				0, 
				math.Clamp(-(size / 100) + 100 + math.Rand(-20, 20), 50, 255)
			)
		end
	end

	do -- debris entity
		local ENT = {}

		ENT.Type = "anim"
		ENT.Base = "base_anim"
		ENT.ClassName = "ee_debris_entity"
		
		if CLIENT then
			function ENT:Think()
				ee.EmitDeadEntity(self)
				self:NextThink(CurTime()+0.2)
				return true
			end
		end
		
		if SERVER then
			function ENT:Initialize()
				self:PhysicsInit(SOLID_VPHYSICS)
				self:SetMoveType( MOVETYPE_VPHYSICS)   
				self:SetSolid(SOLID_VPHYSICS)
				self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				
				local phys = self:GetPhysicsObject()
				
				if not phys:IsValid() then
					self:Explode()
					return
				end
				
				phys:EnableGravity(true)
				phys:EnableCollisions(true)
				phys:EnableDrag(false) 
				phys:Wake()
				
				local radius = self:BoundingRadius()
				phys:SetVelocity(Vector(radius * math.random(-30, 30), radius * math.random(-30, 30), radius * 30))
				phys:AddAngleVelocity(VectorRand() * radius * 2)
				
				self:Explode()
			end
			 
			function ENT:Explode()
				ee.EmitExplosion(self:GetPos(), self:BoundingRadius())
				
				local ent = ents.Create("env_shake")
				ent:SetKeyValue("spawnflags", 4 + 8 + 16)
				
				ent:SetKeyValue("amplitude", 16)
				ent:SetKeyValue("frequency", 200.0)
				ent:SetKeyValue("duration", 2)
				ent:SetKeyValue("radius", self:BoundingRadius() * 5)
				
				ent:SetPos(self:GetPos())
				ent:Fire("StartShake", "", 0)
				ent:Fire("Kill", "", 4)
			end

			function ENT:PhysicsCollide(data, physobj)
				if self.dead then return end
				
				if not self.first then 
					self.first = true
				else
					self.dead = true
					self:Explode()
					timer.Simple(0.1, function() 
						if self:IsValid() then
							self:Remove() 
						end
					end)
				end
			end
		end
		
		scripted_ents.Register(ENT, ENT.ClassName, true)
		
		function ee.MakeDebris(old_ent, chain)
			local ent = ents.Create("ee_debris_entity")
			if ent:IsValid() then
				ent:SetPos(old_ent:GetPos())
				ent:SetAngles(old_ent:GetAngles())
				ent:SetOwner(old_ent)
				ent:SetModel(old_ent:GetModel())
				ent:Spawn()
				
				if chain and not old_ent.ee_exploded then
					local radius = ent:OBBMins():Distance(ent:OBBMaxs()) * 10
					old_ent.ee_exploded = true
					util.BlastDamage(old_ent, old_ent, old_ent:GetPos(), math.Clamp(ent:BoundingRadius()*2, 0, 1000), radius * 2)
				end
			end
		end
	end

	function ee.DamagaeEntity(ent, damage)
		-- vehicle hacks
		if ent:IsVehicle() and damage < 1 then 
			damage = damage * 10000 
		end
		
		damage = math.ceil(damage)
		
		ent.ee_max_hp = ent.ee_max_hp or ent:OBBMins():Distance(ent:OBBMaxs()) * 10
		ent.ee_cur_hp = (ent.ee_cur_hp or ent.ee_max_hp) - damage
		
		local fract = (ent.ee_cur_hp / ent.ee_max_hp)
		
		if fract < 0.25 then
			ee.AttachSmoke(ent)
		end
		
		if ent.ee_cur_hp <= 0 and not ent.ee_dead then
			timer.Simple(math.Rand(0, 0.7), function()
				if ent:IsValid() and not ent.ee_dead then
					ee.MakeDebris(ent, true) 
					ent:Remove()
					ent.ee_dead = true
				end
			end)
		else
			ent.ee_color = ent.ee_color or Color(ent:GetColor())
			local h,s,v = ColorToHSV(ent.ee_color)
			local col = HSVToColor(h, s, v * fract)
			ent:SetColor(col.r, col.g, col.b, ent.ee_color.a)
		end
	end

	hook.Add("EntityTakeDamage", "ee_damage", function(ent, _, ply, damage, dmginfo)
		if not fts.IsInFTS(ent) then return end
		if not fts.IsInFTS(ply) then
			dmginfo:SetDamage(0)
			return 
		end
		
		if ent:IsValid() and not ent:IsPlayer() and not ent:IsNPC() and (ent.IsSeagull or not ent.FTSNPC) and ent:GetClass() ~= "ee_debris_entity" then
			ee.DamagaeEntity(ent, damage)
		end
	end)

	fts.ee = ee
end

do -- coins
	coins = {}

	local META = FindMetaTable("Player")

	function META:GetCoins()
		return self:GetNWInt("coins")
	end

	if CLIENT then
		usermessage.Hook("CoinsMessage", function(umr)
			chat.AddText(Color(255,255,0), "[COINS] ", Color(255,255,255), umr:ReadString())
		end)
	end

	if SERVER then
		if not ms then
			local META = FindMetaTable("Player")

			function META:SetCoins(amount)
				amount = math.Round(math.max(amount, 0))
				file.Write("fts/"..self:UniqueID().."/coins.txt", amount)
				self:SetNWInt("coins", amount)
			end

			function META:LoadCoins()
				self:SetNWInt("coins", tonumber(file.Read("fts/"..self:UniqueID().."/coins.txt") or "0"))
			end

			function META:TakeCoins(amount)
				self:SetCoins(math.Clamp(self:GetCoins() - amount, 0, self:GetCoins()))
			end

			function META:GiveCoins(amount)
				print("giving", self, amount, "coins")
				self:SetCoins(math.max(self:GetCoins() + amount, 0))
			end

			function META:PayCoins(amount)
				if self:GetCoins() >= amount then
					self:TakeCoins(amount)
					return true
				end
				return false
			end

			function META:DropCoins(value)
				if value <= 0 then return false end
				if self:PayCoins(value) then
					print(self, "dropping", value, "coins")
					coins.SpewCoins(self:EyePos(), VectorRand() * 1000,  value)
					return true
				end
				return false
			end
		end
		
		function coins.Message(ply, text)
			umsg.Start("CoinsMessage", ply)
				umsg.String(text)
			umsg.End()
		end

		function coins.Create(position, value)
			local coin = ents.Create("coin")
			coin:SetPos(position)
			coin:Spawn()
			coin:SetValue(value)
			return coin
		end

		concommand.Add("coins_drop", function(ply, command, arguments)
			local value = tonumber(arguments[1])
			if (ply.last_coin_drop or 0) < CurTime() then
				if not ply:DropCoins(value) then
					coins.Message(ply, "You don't have enough Coins to drop " .. value .. " Coins.")
				end
				ply.last_coin_drop = CurTime() + 4
			else
				coins.Message(ply, "You can't drop coins this fast!")
			end
		end)

		function coins.SplitSum(num, max)
			num = math.Round(num)

			local tbl = {}
			local str = tostring(num)

			local len = #str-1
			local i = len
			for num in str:gmatch("(%d)") do
				if num ~= "0" then
					table.insert(tbl, tonumber(num .. ("0"):rep(i)))
				end
				i=i-1
			end

			max = max or math.max(tonumber("1" .. ("0"):rep(#str-2)), 100)

			local temp = -1
			for key, value in pairs(tbl) do
				if value >= max then
					local len = (value / max)
					temp = temp + len
					table.remove(tbl, key)
				end
			end

			for i=0, temp do
				table.insert(tbl, 1, max)
			end

			return tbl
		end	
		
		function coins.SpewCoins(pos, vel, amt)
			local tbl = coins.SplitSum(amt)
			local i = 1
			timer.Create("coin_spew" .. tostring(self), 0.1, #tbl, function()
				local amt = tbl[i]
				if amt then
					local coin = coins.Create(pos, amt)
					coin:GetPhysicsObject():SetVelocity(vel)
					coin:SetAllowTouch(false)

					timer.Simple(math.random(), function()
						if IsValid(coin) then
							coin:SetAllowTouch(true)
						end
					end)
				end
				i=i+1
			end)
		end
	end
	
	do -- coin
		local ENT = {}

		ENT.Base = "base_entity"
		ENT.Type = "anim"

		function ENT:SetupDataTables()
			self:DTVar("Int", 0, "value")
			self:DTVar("Int", 1, "realvalue")
		end

		function ENT:GetValue()
			return self.dt.value
		end

		if CLIENT then

			function ENT:Initialize()
				self.glow_offset = math.random() * 200
				self.emitter = ParticleEmitter(self:GetPos())
			end

			local glow = Material("particle/fire")
			local r,g,b = 1, 0.8, 0.3
			local i = 0
			function ENT:Draw()
				i=RealTime() + self.glow_offset

				self:SetModelScale(Vector(1,1,0.1)*math.Clamp(self:GetValue()/200, 1, 50))
				self:SetRenderBounds(Vector(-1,-1,-0.1)*self:GetValue(), Vector(1,1,0.1)*self:GetValue())

				local sin = (math.abs(math.sin(i*3+self.glow_offset)) + 1) * 2

				render.SetColorModulation(r*sin, g*sin, b*sin)
					self:SetRenderAngles(Angle(90,0,i*100))
					self:DrawModel()
				render.SetColorModulation(1,1,1)

				render.SetMaterial(glow)
				render.DrawSprite( self:GetPos(), self:GetValue()/20*sin, self:GetValue()/20*sin , Color( r,g,b, 100 ) )
			end

			function ENT:Think()
				if math.random() > 0.995 then

					self:EmitSound("ambient/levels/canals/windchime".. math.random(4,5) ..".wav", 60, math.random(200, 255))

					for i = 1, math.random(5) do
						local particle = self.emitter:Add( "particle/fire", self:GetPos())
						particle:SetVelocity( Vector(math.Rand(-1,1),math.Rand(-1,1),math.Rand(0.5,1)) * 100 )
						particle:SetColor( r, g, b )
						particle:SetDieTime( 0.7 )
						particle:SetStartSize( self:GetValue() / 200 )
						particle:SetEndSize( 0 )
						particle:SetCollide( true )
						particle:SetBounce( 1 )
						particle:SetGravity(Vector(0, 0, -600))
						particle:SetAirResistance(50)
					end

				end

				self:NextThink(CurTime())
				return true
			end
		end

		if SERVER then
			function ENT:Initialize()
				self:SetModel("models/props_junk/PopCan01a.mdl")

				self:SetMaterial("models/debug/debugwhite")

				self:PhysicsInit(SOLID_VPHYSICS)
				self:SetSolid(SOLID_VPHYSICS)
				self:SetMoveType( MOVETYPE_VPHYSICS )
				self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				self:SetTrigger(true)

				self:SetValue(1)

				self:DrawShadow(false)

				self:PhysWake()

				self:SetAllowTouch(true)

				self:SetPos(self:GetPos() + Vector(0,0,20))

				self.LifeTime = CurTime() + math.random(100, 200)
			end

			function ENT:SetValue(value)
				self.dt.value = value

				self:PhysicsInitSphere(math.Clamp(10+(value/50), 0, 500))
				self:SetSolid(SOLID_VPHYSICS)
				self:SetMoveType(MOVETYPE_VPHYSICS)
				self:PhysWake()
				self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			end

			function ENT:Touch(ent)
				if self.AllowTouch and ent:IsPlayer() then
					ent:GiveCoins(self:GetValue())
					self:EmitSound("ambient/levels/labs/coinslot1.wav", 100, math.random(90,110))
					self:SetAllowTouch(false) --it gets called more than once sometimes even though I remove the coin when it gets called once.
					self:Remove()
				end
			end

			function ENT:Think()

				local tbl = ents.FindInSphere(self:GetPos(), 500)

				if not table.HasValue(tbl, self.target) then
					for key, ply in RandomPairs(tbl) do
						if ply:IsPlayer() and ply:Alive() --[[and self.target ~= ply or ply:IsNPC()]] then
							self.target = ply
							break
						end
					end
				end

				if self.AllowTouch and IsValid(self.target) then
					local phys = self:GetPhysicsObject()
					phys:AddVelocity((self.target:EyePos() - self:GetPos()):Normalize() * 50)
					phys:SetDamping(2)
				end

				if self.LifeTime < CurTime() then
					self:Remove()
				end

				self:NextThink(CurTime() + 0.1)
				return true
			end

			function ENT:SetAllowTouch(b)
				self.AllowTouch = b
			end

			function ENT:PreEntityCopy()
				self:Remove()
			end

			function ENT:PostEntityPaste()
				self:Remove()
			end
		end

		scripted_ents.Register(ENT, "coin", true)
	end
end

if SERVER then	
	for key, ent in pairs(ents.GetAll()) do
		if ent.InFTS then
			if ent:IsPlayer() then
				fts.PlayerLeave(ent)
			end
			
			if ent:IsNPC() then
				ent:Remove()
			end
			
			ent.InFTS = nil
		end
	end
end

print("asdasd")