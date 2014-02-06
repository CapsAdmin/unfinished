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
				prt:SetStartAlpha(math.abs((cur_hp / (max_hp / 4)) * 255 - 255))
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
				local radius = old_ent:BoundingRadius() * 5
				old_ent.ee_exploded = true
				util.BlastDamage(old_ent, old_ent, old_ent:GetPos(), math.Clamp(radius, 0, 500), radius * 2)
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
	
	ent.ee_max_hp = ent.ee_max_hp or ent:BoundingRadius()
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
		ent.ee_color = ent.ee_color or {ColorToHSV(Color(ent:GetColor()))}
		local col = HSVToColor(ent.ee_color[1], ent.ee_color[2], ent.ee_color[3] * fract)
		ent:SetColor(col.r, col.g, col.b, 255)
	end
end

hook.Add("EntityTakeDamage", "ee_damage", function(ent, _, _, damage)
	if ent:IsValid() and not ent:IsPlayer() and not ent:IsNPC() and ent:GetClass() ~= "ee_debris_entity" then
		ee.DamagaeEntity(ent, damage)
	end
end)

--_G.explosive_entities = ee

