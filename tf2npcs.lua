do
	local SWEP = {Primary = {}, Secondary = {}}
	SWEP.Base = "weapon_base"
	SWEP.WorldModel = "models/weapons/w_models/w_minigun.mdl"
	weapons.Register(SWEP, "angry_heavy_minigun", true)
end

do
	local ENT = {}

	ENT.Base = "base_ai"
	ENT.Type = "ai"

	ENT.target = NULL

	function ENT:Initialize()
		self:SetModel( "models/gman_high.mdl"  )
		self:SetHullType( HULL_HUMAN )
		self:SetHullSizeNormal()
		self:SetSolid( SOLID_BBOX )
		self:SetMoveType( MOVETYPE_STEP )
		self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_TURN_HEAD | CAP_AIM_GUN | CAP_OPEN_DOORS )
		self:SetHealth(200)
		self.health = self:Health()
		--self:SetNotSolid(true)
	end

	function ENT:Think()
		if not ValidEntity(self.target) then return end
		self:SetTarget(self.target)

		self:NextThink(CurTime())
		return true
	end


	function ENT:SelectSchedule()
		local dummyTask = ai_schedule.New( "Heavy Dummy" )

		if not self.heavy.sandwichActive and (self.health < 50 or self.heavy.isEscaping) then
			print("fleeing")
			self.heavy:DropMinigun()
			self.heavy:WindDown()
			self.heavy.isEscaping = true
			self:SetEnemy(self.target)
			dummyTask:EngTask("TASK_FIND_COVER_FROM_ENEMY")
			dummyTask:EngTask("TASK_FACE_PATH")
			self:StartSchedule(dummyTask)
			return
		else
			self:SetEnemy(NULL)
		end

		if self.target:IsPlayer() and self.target:GetPos():Distance(self:GetPos()) < 200 then
			dummyTask:EngTask("TASK_STOP_MOVING")
			dummyTask:EngTask("TASK_FACE_TARGET")
			self:StartSchedule(dummyTask)
		else
			dummyTask:EngTask("TASK_GET_PATH_TO_TARGET")
			dummyTask:EngTask("TASK_RUN_PATH")
			dummyTask:EngTask("TASK_FACE_PATH")
			self:StartSchedule(dummyTask)
		end
	end

	function ENT:OnTakeDamage(dmg)

		if dmg:GetAttacker():IsPlayer() and self.health > 50 then
			self.target = dmg:GetAttacker()
			if dmg:GetDamage() > 5 then
				self.heavy.isAngry = true
			end
		end

		if dmg:GetDamage() < 15 then
			self.heavy:Taunt("Pain")
		else
			self.heavy:Taunt("PainServe")
		end

		self:SetHealth(self:Health() - dmg:GetDamage())
		self.health = self.health - dmg:GetDamage() --Health doesn't update
		if self:Health() <= 0 then
			self.heavy:Taunt("Death")

			local ragdoll = ents.Create("prop_ragdoll")
			ragdoll:SetPos(self:GetPos())
			ragdoll:SetAngles(self:GetAngles())
			ragdoll:SetModel("models/player/heavy.mdl")
			self:Remove()
			ragdoll:Spawn()

			local weapon
			if not self.heavy.droppedMinigun then
				weapon = ents.Create("prop_physics")
				weapon:SetPos(self:GetPos() + Vector(0,0,60))
				weapon:SetAngles(self:GetAngles())
				weapon:SetModel("models/weapons/w_models/w_minigun.mdl")
				weapon:Spawn()
				constraint.NoCollide(ragdoll, weapon, 0)
			end
			local fader = 255

			timer.Create("angry_heavy_fader" .. tostring(ragdoll), 0, fader, function()
				fader = fader - 1
				if ValidEntity(weapon) then weapon:SetColor(255,255,255,fader) end
				ragdoll:SetColor(255,255,255,fader)

				if fader < 1 then
					if ValidEntity(weapon) then weapon:Remove() end
					ragdoll:Remove()
				end
			end)
		end
	end

	scripted_ents.Register(ENT, "npc_heavy_dummy", true)

end

do

	local ENT = {}

	ENT.Base = "base_ai"
	ENT.Type = "ai"

	local battleCry =
	{
	"vo/heavy_BattleCry01.wav",
	"vo/heavy_BattleCry02.wav",
	"vo/heavy_BattleCry03.wav",
	"vo/heavy_BattleCry04.wav",
	"vo/heavy_BattleCry05.wav",
	"vo/heavy_BattleCry06.wav"
	}

	local cheers =
	{
	"vo/heavy_Cheers01.wav",
	"vo/heavy_Cheers02.wav",
	"vo/heavy_Cheers03.wav",
	"vo/heavy_Cheers04.wav",
	"vo/heavy_Cheers05.wav",
	"vo/heavy_Cheers06.wav",
	"vo/heavy_Cheers07.wav",
	"vo/heavy_Cheers08.wav"
	}

	local jeers =
	{
	"vo/heavy_Jeers01.wav",
	"vo/heavy_Jeers02.wav",
	"vo/heavy_Jeers03.wav",
	"vo/heavy_Jeers04.wav",
	"vo/heavy_Jeers05.wav",
	"vo/heavy_Jeers06.wav",
	"vo/heavy_Jeers07.wav",
	"vo/heavy_Jeers08.wav",
	"vo/heavy_Jeers09.wav"
	}

	local pain =
	{
	"vo/heavy_PainSharp01.wav",
	"vo/heavy_PainSharp02.wav",
	"vo/heavy_PainSharp03.wav",
	"vo/heavy_PainSharp04.wav",
	"vo/heavy_PainSharp05.wav"
	}

	local painServe =
	{
	"vo/heavy_PainSevere01.wav",
	"vo/heavy_PainSevere02.wav",
	"vo/heavy_PainSevere03.wav"
	}

	local death =
	{
	"vo/heavy_PainCrticialDeath01.wav",
	"vo/heavy_PainCrticialDeath02.wav",
	"vo/heavy_PainCrticialDeath03.wav"
	}

	local escape =
	{
	"vo/heavy_negativevocalization01.wav",
	"vo/heavy_negativevocalization02.wav",
	"vo/heavy_negativevocalization03.wav",
	"vo/heavy_negativevocalization04.wav",
	"vo/heavy_negativevocalization05.wav",
	"vo/heavy_negativevocalization06.wav"
	}

	local sandwich =
	{
	"vo/heavy_sandwichtaunt01.wav",
	"vo/heavy_sandwichtaunt02.wav",
	"vo/heavy_sandwichtaunt03.wav",
	"vo/heavy_sandwichtaunt04.wav",
	"vo/heavy_sandwichtaunt05.wav",
	"vo/heavy_sandwichtaunt06.wav",
	"vo/heavy_sandwichtaunt07.wav",
	"vo/heavy_sandwichtaunt08.wav",
	"vo/heavy_sandwichtaunt09.wav",
	"vo/heavy_sandwichtaunt10.wav",
	"vo/heavy_sandwichtaunt11.wav",
	"vo/heavy_sandwichtaunt12.wav",
	"vo/heavy_sandwichtaunt13.wav",
	"vo/heavy_sandwichtaunt14.wav",
	"vo/heavy_sandwichtaunt15.wav",
	"vo/heavy_sandwichtaunt16.wav",
	"vo/heavy_sandwichtaunt17.wav"
	}

	local gettingBullied =
	{
	"vo/heavy_yell2.wav",
	"vo/heavy_yell1.wav",
	"vo/heavy_negativevocalization01.wav",
	"vo/heavy_negativevocalization02.wav",
	"vo/heavy_negativevocalization03.wav",
	"vo/heavy_negativevocalization04.wav",
	"vo/heavy_negativevocalization05.wav",
	"vo/heavy_negativevocalization06.wav",
	"vo/heavy_jeers05.wav",
	"vo/heavy_jeers04.wav",
	"vo/heavy_jeers03.wav",
	"vo/heavy_jeers02.wav",
	"vo/heavy_jeers01.wav"
	}

	function ENT:SpawnFunction( ply, trace )
		if ( !trace.Hit ) then return end

		local heavy = ents.Create( "npc_angry_heavy" )
		heavy.target = ply
		heavy:SetPos( trace.HitPos+Vector(0,0,100) )
		heavy:Spawn()
		heavy:Activate()
		return heavy
	end

	function ENT:Initialize()
		local dummy = ents.Create("npc_heavy_dummy")
		dummy.target = player.GetByUniqueID(--[[[50DKP] Hunter]] "1416729906")
		dummy:SetPos(self:GetPos())
		self:SetParent(dummy)
		dummy:Spawn()
		dummy:SetOwner(self)

		local velocity = ents.Create("prop_physics")
		velocity:SetModel("models/props_junk/PopCan01a.mdl")
		velocity:SetPos(dummy:GetPos()+Vector(0,0,100))
		velocity:Spawn()
		velocity:SetNotSolid(true)
		constraint.Weld(velocity, dummy)

		self.target = dummy
		self.dummy = dummy
		self.velocity = velocity
		dummy.stop = velocity
		dummy.heavy = self

		self:SetNotSolid(true)
		self:SetModel( "models/player/heavy.mdl"  )
		self:SetHullSizeNormal()
		self:SetSolid( SOLID_BBOX )
		self:SetMoveType( MOVETYPE_NONE )
		self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_OPEN_DOORS | CAP_ANIMATEDFACE | CAP_TURN_HEAD | CAP_USE_SHOT_REGULATOR | CAP_AIM_GUN )
		self:SetMaxYawSpeed( 5000 )
		self:SetHealth ( 200 )
		self:Give("angry_heavy_minigun")
		self:SetGravity(0.2)
		self.targetSwitchWait = true
		self.sandwichTable = {}
		self:Taunt("BattleCry")
		self.smoothAngle = Angle(0,0,0)
		self.MinigunShoot = CreateSound(self, "weapons/minigun_shoot.wav")
		self.MinigunSpin = CreateSound(self, "weapons/minigun_spin.wav")
		self.MinigunWindUp = CreateSound(self, "weapons/minigun_wind_up.wav")
		self.MinigunWindDown = CreateSound(self, "weapons/minigun_wind_down.wav")
		self.spinning = true
		self.isAngry = false
		self.minigunStart = true
		self.angryFuse = 0
		self.getAutoStepPos = true
		self.speed = 35
	end

	function ENT:Taunt(tauntType)
		if self.isPlaying then return end

		if tauntType == "BattleCry" then
			self:PlayTaunt(self:TableRandom(battleCry))
		elseif tauntType == "Pain" then
			self:PlayTaunt(self:TableRandom(pain))
		elseif tauntType == "PainServe" then
			self:PlayTaunt(self:TableRandom(painServe))
		elseif tauntType == "Death" then
			self:PlayTaunt(self:TableRandom(death))
		elseif tauntType == "Cheers" then
			self:PlayTaunt(self:TableRandom(cheers))
		elseif tauntType == "Jeers" then
			self:PlayTaunt(self:TableRandom(jeers))
		elseif tauntType == "Escape" then
			self:PlayTaunt(self:TableRandom(escape))
		elseif tauntType == "Sandwich" then
			self:PlayTaunt(self:TableRandom(sandwich))
		elseif tauntType == "GettingBullied" then
			self:PlayTaunt(self:TableRandom(gettingBullied))
		end
	end

	function ENT:PlayTaunt(randomTaunt)
		if not ValidEntity(self) then return end
		taunt = CreateSound(self, Sound(randomTaunt))
		taunt:SetSoundLevel(100)
		taunt:PlayEx(1, math.random(90,110))
		duration = SoundDuration(randomTaunt)
		self.isPlaying = true
		timer.Simple(duration, function() self.isPlaying = false end)
	end

	function ENT:GettingBullied()
		if not isAngry then
			if math.random(0,200) == 50 then
				self:Taunt("GettingBullied")
			end
		end
		self.angryFuse = self.angryFuse + 1
		if self.angryFuse > 100 then
			self.dummy.target = self.mocker
		end
		if self.angryFuse > 500 then
			self.target = self.mocker
			self.dummy.target = self.mocker
			self.isAngry = true
			self.mocker.beingChased = true
			self:GetMockers()
			if not ValidEntity(self.mocker) then
				self.isAngry = false
				self:ChooseRandomTarget()
				self.gettingBullied = false
				self.angryFuse = 0
				self:WindDown()
			end
		end
	end

	function ENT:GetMockers()
		for key, mocker in pairs(ents.FindByClass("npc_annoying_scout")) do
			if mocker.beingChased then
				self.mocker = mocker
			end
		end
	end

	if CLIENT then
		function ENT:Think()
			if self:GetNWBool("Attacking") then
				ParticleEffectAttach("muzzle_minigun_constant", PATTACH_ABSORIGIN , self:GetActiveWeapon(), self:GetActiveWeapon():LookupAttachment("muzzle"))
			end
		end
	end

	if SEVRER then

		function ENT:Think()
			--debugoverlay.Sphere(self:GetPos(), 50, 0, Color(255,0,0, 10), true)
			self:Animate()
			self:CleanSandwichTable()

			if self.getBackToMinigun then
				self:GetMinigun()
			end

			if self.gettingBullied then
				self:GettingBullied()
			end

			if self.sandwichActive and not self.getBackToMinigun then
				self:DoneSandwichHarvesting()
			end

			if self:GetSandwiches() and not self.getBackToMinigun then
				print("getting sandwiches")
				self:Distracted()
				self:DropMinigun()
			end

			if not self.sandwichActive and not self.getBackToMinigun then
				if self.dummy.health > 50 then
					self:FollowTargetMinigun()
				else
					self:DropMinigun()
					self:Escape()
					self.isEscaping = true
				end
			end
			self:NextThink(CurTime())
			return true
		end

	end

	--[[ function ENT:HeavyOnFire()
		self:HeavySetAngles(Angle(0,math.sin(CurTime()),0))
		if self.dummy:IsOnGround() then
			self:SetVelocity(self:GetForward() * 20)
		end
		self:PlaySequence("run_loser")
	end ]]

	function ENT:CleanSandwichTable()
		for key, sandwich in pairs(self.sandwichTable) do
			if not ValidEntity(sandwich) then
				self.sandwichTable[key] = nil
			end
		end
	end

	function ENT:GetSandwiches()
		for key, sandwich in pairs(ents.FindInSphere(self:GetPos(), 1000)) do
			if sandwich:GetModel() == "models/weapons/c_models/c_sandwich/c_sandwich.mdl" then
				if not table.HasValue( self.sandwichTable, sandwich) then
					self.sandwichTable[key] = sandwich
				end
				return true
			end
		end
	end

	function ENT:DoneSandwichHarvesting()
		if table.ToString(self.sandwichTable) == "{}" then --I've tried literally everything here, and this is the only method that seems to be working.
			if not self:GetSandwiches() then
				self.sandwichActive = false
				self.getBackToMinigun = true
			end
		end
	end

	function ENT:Distracted()
		self:GetSandwiches()

		if self.sandwichTable then
			self.sandwichTarget = self:TableRandom(self.sandwichTable)
		end

		if ValidEntity(self.sandwichTarget) then
			self.dummy.target = self.sandwichTarget
			self.sandwichActive = true
			self:SetAngles(self.dummy:GetAngles())
			if self.dummy:IsOnGround() then
				self:PlaySequence("run_loser")
			end

			if self:GetPos():Distance(self.sandwichTarget:GetPos()) < 50 then
				self:Taunt("Sandwich")
				self.dummy:SetHealth(self.dummy.health+50)
				self.sandwichTarget:Remove()
				self.sandwichTarget = nil
			end
		else
			self.sandwichActive = false
		end
	end

	function ENT:GetMinigun()
		if not ValidEntity(self.minigun) then self:Escape() return end
		self:SetAngles(self.dummy:GetAngles())
		self.dummy.target = self.minigun
		self:PlaySequence("run_item1")
		if self.dummy:GetPos():Distance(self.minigun:GetPos()) < 100 then
			self:Give("angry_heavy_minigun")
			self.minigun:Remove()
			self.getBackToMinigun = false
		end
	end

	function ENT:Shoot()
		if self.isAngry then
			local weapon = self:GetActiveWeapon()

			if not ValidEntity(weapon) then return end
			local hitTarget = util.QuickTrace( self:GetPos()+Vector(0,0,80), (weapon:GetAngles():Forward()), { self } ).Entity

			if self.minigunStart then
				self.MinigunWindUp:Play()
				timer.Simple(SoundDuration("weapons/minigun_spin.wav"), function() if not ValidEntity(self) then return end self.spinning = false self.MinigunShoot:Play() self.MinigunSpin:Play() end)
				self.minigunStart = false
			end

			if self.spinning and not hitTarget == self.target then return end

			local pos = self:GetAttachment(weapon:LookupAttachment("muzzle")).Pos
			bullet = {}
			bullet.Src = pos + VectorRand() * 20
			bullet.Attacker = self
			bullet.Dir = weapon:GetAngles():Forward()
			bullet.Spread = Vector(0.1,0.1,0)
			bullet.Num = 5
			bullet.Damage = 1
			bullet.Force = 21000
			bullet.Tracer = 1
			bullet.TracerName = "Tracer"
			bullet.Callback	=
			function ( attacker, tr, dmginfo )
				if tr.Entity:IsPlayer() then
					self:Taunt("Cheers")
					if self.isAngry then
						if tr.Entity == self.dummy.target then
							if tr.Entity:Health() == 0 then
								self.isAngry = false
								self:WindDown()
							end
						end
					end
				end
			end

			self:FireBullets(bullet)
		end
	end

	function ENT:DropMinigun()
		if not ValidEntity(self:GetActiveWeapon()) then return end
		self:GetActiveWeapon():Remove()
		local weapon = ents.Create("prop_physics")
		weapon:SetPos(self:GetPos() + Vector(0,0,60))
		weapon:SetAngles(self:GetAngles())
		weapon:SetModel("models/weapons/w_models/w_minigun.mdl")
		weapon:Spawn()
		self.minigun = weapon
		constraint.NoCollide(self, weapon, 0)
		self.droppedMinigun = true
	end

	function ENT:OnRemove()
		if ValidEntity(self.minigun) and ValidEntity(self.target) and ValidEntity(self.velocity) then self.minigun:Remove() end
		self.MinigunShoot:Stop()
		self.MinigunSpin:Stop()
		if not self.spinning then
			self.MinigunWindDown:Play()
		end
		self.dummy:Remove()
		self.velocity:Remove()
	end

	function ENT:PlaySequence(sequence)
		local data = {}
		--print("sequence: ", sequence)
		data.Name = sequence
		data.Wait = nil
		data.Speed = 1
		self:TaskStart_PlaySequence(data)
	end

	function ENT:HeavySetAngles(angles)
		local smoother = 2
		self.smoothAngle.p = math.ApproachAngle(self.smoothAngle.p, angles.p, smoother)
		self.smoothAngle.y = math.ApproachAngle(self.smoothAngle.y, angles.y, smoother)
		self.smoothAngle.r = math.ApproachAngle(self.smoothAngle.r, angles.r, smoother)
		self:SetAngles(Angle(self.smoothAngle.p,self.smoothAngle.y,self.smoothAngle.r))
	end

	function ENT:FollowTargetMinigun()
		if not ValidEntity(self.target) then print("choosing random target") self:ChooseRandomTarget() return end

		if self.velocity:GetVelocity():Length() < 5 then
			self:PlaySequence("stand_secondary")
			self:Shoot()
			return
		end

		local alive
		if self.mocker then alive = self.mocker else alive = self.target end
		if alive then
			if self.dummy:IsOnGround() then
				self:PlaySequence("run_secondary")
				self:Shoot()
			end
		end
	end

	function ENT:WindDown()
		self.MinigunShoot:Stop()
		self.MinigunSpin:Stop()
		self.MinigunWindDown:Play()
		self.minigunStart = true
		self.spinning = true
	end

	function ENT:Escape()
		if not ValidEntity(self.target) then return end
		if math.random(0,500) == 50 then
			self:Taunt("Escape")
		end
		self.getBackToMinigun = false
		self:PlaySequence("run_loser")

	end

	function ENT:Animate() --Thanks azuisleet
		local vel = self.velocity:GetVelocity()
		local velspeed = vel:Length()
		local eye = self:GetAngles()

		self:SetPoseParameter("body_pitch", -eye.p)

		eye.p = 0
		local forward, right = eye:Forward(), eye:Right()


		local veln = vel:GetNormal()
		local dot = veln:Dot(forward)
		local dotr = veln:Dot(right)

		local spd = math.Clamp(velspeed/100, 0, 1)

		self:SetPoseParameter("move_x", spd*dot)
		self:SetPoseParameter("move_y", spd*dotr)
	end

	function ENT:ChooseRandomTarget()
		self.target = self:TableRandom(player.GetAll())
		self.dummy.target = self:TableRandom(player.GetAll())
	end

	function ENT:TableRandom(t)
		local count = table.Count( t )
		if not count or count < 1 then count = 1 end
		local rk = math.random( 1, count )
		local i = 1
		for k, v in pairs(t) do
		if ( i == rk ) then return v end
			i = i + 1
		end
	end

	scripted_ents.Register(ENT, "npc_angry_heavy", true)

end