local def = {
	run = 500,
	walk = 250,
	step = 18,
	jump = 200,
	bhop = 1.6,

	view = Vector(0,0,64),
	viewducked = Vector(0,0,28),

	min = Vector(-16, -16, 0),
	max = Vector(16, 16, 72),
	maxduck = Vector(16, 16, 36),

	mass = 85,

	gravity = 600,
}

function _R.Player:SetScale(scale, send)
	//self:SetPACConfig{}
	--check(scale, "number")

	local min = FrameTime()

	self:SetViewOffset(def.view * scale)
	self:SetViewOffsetDucked((def.viewducked * scale) - (vector_up*0.032))

	self:SetHull(def.min * scale, def.max * scale * 4)
	self:SetHullDuck(def.min * scale, def.maxduck * scale * 4)
	if scale < 0.01 then
		self:SetDuckSpeed(10000)
	else
		self:SetDuckSpeed(0.1)
	end

	self:SetRunSpeed(math.max(def.run * scale, min) * 4)
	self:SetWalkSpeed(math.max(def.walk * scale, min) * 4)
	self:SetStepSize(def.step * scale)
	self:SetJumpPower(math.max(def.jump * scale, min) * 4)

	if CLIENT then
		self:SetModelScale(Vector() * scale)
	end

	if SERVER then
		self:GetPhysicsObject():SetMass(def.mass * scale)

		if not send then SendUserMessage("player_scale", self, scale) end
	end

	self.scale = scale
end

function _R.Player:GetScale()
	return self.scale
end

if CLIENT then
	usermessage.Hook("player_scale", function(umr)
		LocalPlayer():SetScale(umr:ReadFloat())
	end)
end

hook.Add("PlayerSpawn", "scale", function(ply)
	if type(ply.scale) == "number" and ply.scale ~= 1 then
		ply:SetScale(1)
		ply:SetPos(ply:GetPos()+vector_up)
		timer.Simple(0.4, function()
			if ply:IsPlayer() then
				ply:SetScale(ply.scale)
			end
		end)
	end
end)

hook.Add("ScalePlayerDamage", "scale", function(ply, hitgroup, dmginfo)
	if dmginfo:GetDamageType() == DMG_BURN then return end

	local attacker = dmginfo:GetAttacker()
	if type(ply.scale) == "number" and ply.scale ~= 1 or attacker:IsPlayer() then
		local mult

		if attacker:IsPlayer() and attacker.scale ~= 1 then
			mult = attacker.scale / 10
		end

		dmginfo:SetDamage(dmginfo:GetDamage() * (mult or (1/ply.scale)))
		dmginfo:SetDamageForce((dmginfo:GetDamageForce() * (mult or (1/ply.scale))))
	end
end)

hook.Add("PlayerFootstep", "scale", function(ply, pos, foot, sound, volume, rf)
	if type(ply.scale) == "number" and ply.scale ~= 1 then
		if ply.scale < 0.2 then
			ply:EmitSound("npc/fast_zombie/foot2.wav", 40, math.random(170, 200))
			return true
		else
			ply:EmitSound(sound, 60, math.Clamp((1/ply.scale)*255, 0,255))
		end
	end
end)


hook.Add("PlayerStepSoundTime", "scale", function(ply, iType, bWalking )
	if type(ply.scale) == "number" and ply.scale ~= 1 then

		local fStepTime = 350
		local fMaxSpeed = ply:GetMaxSpeed()

		if ( iType == STEPSOUNDTIME_NORMAL || iType == STEPSOUNDTIME_WATER_FOOT ) then

			if ( fMaxSpeed <= 100 ) then
				fStepTime = 400
			elseif ( fMaxSpeed <= 300 ) then
				fStepTime = 350
			else
				fStepTime = 250
			end

		elseif ( iType == STEPSOUNDTIME_ON_LADDER ) then

			fStepTime = 450

		elseif ( iType == STEPSOUNDTIME_WATER_KNEE ) then

			fStepTime = 600

		end

		// Step slower if crouching
		if ( ply:Crouching() ) then
			fStepTime = fStepTime + 50
		end

		return fStepTime * ply.scale

	end
end)



hook.Add("UpdateAnimation", "scale", function(ply, vel, max)
	if type(ply.scale) == "number" and ply.scale < 1 then
		ply.scale_cycle = tonumber(tostring(ply.scale_cycle)) and ply.scale_cycle or 0
		ply.scale_cycle = (ply.scale_cycle or 0) + (vel:Length() * FrameTime() * (1/ply.scale) * 0.01)
		ply:SetCycle(ply.scale_cycle)
	end
end)

--hook.Add("PreChatSound", "scale", function(chtsnd)
--	chtsnd:SetPitch(math.Clamp(chtsnd:GetPitch() * (1/chtsnd:GetPlayer().scale), 0, 255))
--end)

hook.Add("Move", "scale", function(self, move)
	do return end
	if self.scale and self.scale ~= 1 then
		move:SetVelocity(move:GetVelocity() + LerpVector(math.Clamp(self.scale+0.25,0,2), Vector(0,0, (FrameTime() * def.gravity)), vector_origin))

		local trace = util.QuickTrace(self:GetPos(), -vector_up, self)
		if trace.HitWorld then
			local z = (self:GetPos() - trace.HitPos).z
			if not self:KeyDown(IN_JUMP) and z < 1 and z > 0 then
				move:SetOrigin(move:GetOrigin() + Vector(0,0,-z ))
			end
		end
	end
end)

hook.Add("PreChatSound", "scale", function(chtsnd)
	local self = chtsnd:GetPlayer()
	if self:IsPlayer() and self.scale and self.scale ~= 1 then
		--chtsnd:SetPitch(chtsnd:GetPitch()*(2/self.scale))
	end
end)


if CLIENT then
	hook.Add("CalcView", "scale", function(ply, origin, angles, fov, znear, zfar)
		local ply = LocalPlayer()
		if ply.scale and ply.scale < 0.5 then
			return {
				origin = origin + Vector(0,0,-(ply.scale ^ ply.scale)+0.98),
				znear = znear * ply.scale,
				--zfar = zfar * ply.scale*10,
			}
		end
	end)

 	hook.Add("CreateMove", "scale", function(cmd)
		local scale = math.max(LocalPlayer().scale * 34, 0.001)
		cmd:SetForwardMove(cmd:GetForwardMove() * scale)
		cmd:SetSideMove(cmd:GetSideMove() * scale)
	end)

	--end

	hook.Add("PrePlayerDraw", "scale", function(ply)
		if type(ply.scale) == "number" and ply.scale ~= 1 then
			ply:SetModelScale(Vector()*ply.scale)

			if CLIENT and ply ~= LocalPlayer() then
				ply.oldscalepos = ply:GetPos()
				ply:SetPos((ply:GetRenderOrigin() or ply:GetPos()) + Vector(0,0,-0.12))
				ply:SetupBones()
			end
		end
	end)

	hook.Add("PostPlayerDraw", "scale", function(ply)
		if type(ply.scale) == "number" and ply.scale ~= 1 then
			if CLIENT and ply ~= LocalPlayer() then
				ply:SetPos(ply.oldscalepos)
			end
		end
	end)

	local mat = Material("models/debug/debugwhite")

	hook.Add("PostDrawOpaqueRenderables", "scale", function()
		do return end
		local ply = LocalPlayer()
		if ply.scale and ply.scale < 0.2 then
			render.SetMaterial(mat)
			render.SetBlend(1)
			render.SuppressEngineLighting(true)
			render.SetColorModulation(0,0,0)
			render.DrawQuadEasy(ply:EyePos() + (ply:GetAimVector() * ((0.1/ply.scale)) * (-(ply:GetFOV()/120)+1)), -ply:GetAimVector(), 10000, 10000, Color(120,100,60), 0)
			render.SetColorModulation(1,1,1)
			render.SuppressEngineLighting(false)
			render.SetBlend(1)
		end
	end)

	--materials.SetColor("sprites/physg_glow1", Vector(0,0,0))
	--materials.SetColor("sprites/physg_glow2", Vector(0,0,0))
	--materials.SetColor("sprites/glow1", Vector(0,0,0))
	--materials.SetColor("sprites/glow1_noz", Vector(0,0,0))

end