-- SEPARATE THIS

local meta = FindMetaTable("Player")

hook.Add("PPhys", "restrict_player", function(ply, ent, phys)
	if ply:GetRestricted() and phys:IsValid() then
		phys:EnableGravity(false)
	end
end)

hook.Add("PlayerSay","restrict_player",function(ply)
	if(ply:GetRestricted()) then return "" end
end)

function engineConsoleCommand(...)
   if hook.Call("LuaCommand", nil, ...) ~= false then
      return concommand.Run(...)
   end
   
   return false
end

if CLIENT then

	function meta:GetRestricted()
		local num = self:GetNWInt("restricted", 0)
		return num == 1 and true or num == 0 and false or num == 2 and "shame on you"
	end

	--[[ hook.Add("HUDShouldDraw", "restrict_player", function(element)
		if LocalPlayer():GetRestricted() == "shame on you" then
			if vgui.CursorVisible() then
				gui.SetMousePos( math.random(ScrW()), math.random(ScrH()))
			end
			return false
		end
	end)]]

	hook.Add("OnPlayerChat", "restrict_player", function(ply)
		if ply:GetRestricted() and ply:EyePos():Distance(LocalPlayer():EyePos()) > 300 then
			return true
		end
	end)

	hook.Add("PlayerBuildBonePositions", "restrict_player", function(ply)
		if ply:GetRestricted() then
			local index = ply:LookupBone(BONE_HEAD)
			local matrix = ply:GetBoneMatrix(index)

			matrix:Translate(VectorRand()*0.07)
			ply:SetBoneMatrix(index, matrix)
		end
	end)

	local sounds = {
		"ambient/water/drip1.wav",
		"ambient/water/drip3.wav",
		"ambient/water/drip4.wav",
	}

	local ball = ClientsideModel("models/dav0r/hoverball.mdl")
	ball:SetNoDraw(true)
	ball:SetMaterial("models/shiny")

	usermessage.Hook("restrict_player_touch", function(umr)
		local ply = umr:ReadEntity()
		if ply:IsPlayer() then
			ply.restricted_hit = 4+math.random()
			ply.restricted_hit_speedx = 3+math.random()*5
			ply.restricted_hit_speedy = 3+math.random()*5
			ply.restricted_hit_speedz = 3+math.random()*5
			ply:EmitSound(table.Random(sounds), 100, math.random(30, 50))
		end
	end)

	local emitter = ParticleEmitter(vector_origin)
	local part

	local function Bubble(pos)
		part = emitter:Add("effects/bubble", pos)
		part:SetVelocity(VectorRand()*20)
		part:SetGravity((VectorRand()*40*Vector(1,1,0)) + Vector(0,0,100))
		part:SetAirResistance(80)
		part:SetColor(255,255,255)
		part:SetDieTime(5)
		part:SetStartSize(5)
		part:SetEndSize(0)
		part:SetStartAlpha(255)
		part:SetEndAlpha(0)
		part:SetLifeTime(1)
	end

	hook.Add("PostPlayerDraw", "restrict_player", function(ply)
		if ply:GetRestricted() then
			local ent = ply:GetPlayerPhysics()
			if ent:IsValid() then
				ply.restricted_hit = ply.restricted_hit or 0
				ply.restricted_hit_speedx = ply.restricted_hit_speedx or 0
				ply.restricted_hit_speedy = ply.restricted_hit_speedy or 0
				ply.restricted_hit_speedz = ply.restricted_hit_speedz or 0

				ball:SetPos(ent:GetPos())
				ball:SetRenderOrigin(ent:GetPos())
				ball:SetModelScale((Vector() * 8) + ((Vector(math.sin(ply.restricted_hit*ply.restricted_hit_speedx), math.sin(-ply.restricted_hit*ply.restricted_hit_speedy), math.cos(ply.restricted_hit*ply.restricted_hit_speedz))*0.5)*ply.restricted_hit))
				ball:SetupBones()



				render.SetColorModulation(1,1.5,2)
					render.SetBlend(0.1)
						ball:DrawModel()
					render.SetBlend(1)
				render.SetColorModulation(1,1,1)
				ply.restricted_hit = math.max(ply.restricted_hit - FrameTime(), 0)

				if math.random() > 0.97 then Bubble(ply:GetBonePosition(ply:LookupBone(BONE_HEAD))) end
			end
		end
	end)

	else
	local meta = FindMetaTable("Player")

	function meta:GetRestricted()
		local num = self:GetNWInt("restricted", 0)
		return num == 1 and true or num == 0 and false or num == 2 and "shame on you"
	end

	function meta:SetRestricted(bool)
		if bool == false and self:GetRestricted() and not self:GetPlayerPhysics():IsValid() then
			self:SetPlayerPhysics(false)
			self.restricted = false

			timer.Simple(0.1, function() self:SetRestricted(true) end)
		return end


		if bool then
			--self:SetUserGroup(":D")
			self:SetJumpPower(0)
			self:SetRunSpeed(40)
			self:SetWalkSpeed(40)
			self:SetDuckSpeed(100000000000)
			self:SetCanWalk(false)
			if FAST_ADDON_BHOP then self:SetSuperJumpMultiplier(-1, true) end

			self:StripWeapons()

			self.restricted = true

			for _, ent in pairs(ents.GetAll()) do
				if ent:GetModel() and not ent:GetModel():find("*", nil, true) and ent.CPPIGetOwner and ent:CPPIGetOwner() == self then
					ent:Remove()
				end
			end

			local ENT = self:SetPlayerPhysics(true)

			if ENT then
				function ENT:PhysicsCollide(data, phys)
					umsg.Start("restrict_player_touch")
						umsg.Entity(self:GetPlayer())
					umsg.End()

					phys:AddVelocity(-data.OurOldVelocity*0.9)
				end
			end
		else
			if FAST_ADDON_BHOP then self:SetSuperJumpMultiplier(1.5, true) end
			local old = self:GetPos()
			self:Spawn()
			self:SetPos(old)

			self:SetJumpPower(200)
			self.restricted = false
			self:SetPlayerPhysics(false)
		end

		self:SetNWInt("restricted", bool == true and 1 or bool == false and 0 or bool)
		self:SetPData("restricted", tostring(bool))
	end

	-- ughhh

	hook.Add("PlayerSpawn", "restrict_player", function(ply)
		local id = ply:UniqueID()
		hook.Add("KeyPress", "restrict_player_temp"..id, function(_ply)
			if _ply == ply then
				if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply:OnGround() and (ply:GetRestricted() or tobool(ply:GetPData("restricted"))) then
					ply:SetRestricted(true)
				end
			end
			hook.Remove("KeyPress", "restrict_player_temp"..id)
		end)
	end)

	hook.Add("LuaCommand", "restrict_player", function(ply, cmd, args)
		if ply:IsPlayer() and ply:GetRestricted() and cmd ~= "\1ch" then
			return false
		end
	end)

	hook.Add("PlayerNoClip", "restrict_player", function(ply)
		if ply:GetRestricted() then
			return false
		end
	end)

	hook.Add("WeaponEquip", "restrict_player", function(wep)
		timer.Simple(0.1, function()
			if IsValid(wep) and IsValid(wep:GetOwner()) and wep:GetOwner():IsPlayer() and wep:GetOwner():GetRestricted() then
				wep:Remove()
			end
		end)
	end)

	hook.Add("PhysgunPickup", "restrict_player", function(ply, ent)
		if ent.ClassName == "player_physics" and ent:HasPlayer() and ent:GetPlayer():GetRestricted() then
			return true
		end
	end)

	hook.Add("PlayerSwitchFlashlight", "restrict_player", function(ply)
		if ply:GetRestricted() then
			return false
		end
	end)

	hook.Add("CanPlayerSuicide", "restrict_player", function(ply)
		if ply:GetRestricted() then
			return false
		end
	end)

	hook.Add("PlayerSpray", "restrict_player", function(ply)
		if ply:GetRestricted() then
			return false
		end
	end)

	hook.Add("PlayerUse", "restrict_player", function(ply)
		if ply:GetRestricted() then
			return false
		end
	end)

	hook.Add("PreChatSoundsSay", "restrict_player", function(ply)
		if ply:GetRestricted() then
			return false
		end
	end)

	hook.Add("PlayerCanHearPlayersVoice", "restrict_player", function(listener, speaker)
		if speaker:GetRestricted() and listener:GetPos():Distance(speaker:GetPos()) > 50 then return false end
	end)

	hook.Add("PlayerTraceAttack", "restrict_player", function(_, dmginfo)
		if dmginfo:GetAttacker():IsPlayer() and dmginfo:GetAttacker():GetRestricted() then
			return false
		end
	end)

	hook.Add("SetupMove", "restrict_player", function(self, move)
		if self:GetRestricted() then
			for key, ply in pairs(player.GetAll()) do
				if ply ~= self and self:GetPos():Distance(ply:GetPos()) < 150 then
					move:SetVelocity(vector_origin)
					return true
				end
			end
		end
	end)

	hook.Add("Move", "restrict_player", function(self, move)
		if self:GetRestricted() then
			for key, ply in pairs(player.GetAll()) do
				if ply ~= self and self:GetPos():Distance(ply:GetPos()) < 150 then
					move:SetVelocity(vector_origin)
					return true
				end
			end
		end
	end)

	timer.Create("restrict_player", 1, 0, function()
		for key, ply in pairs(player.GetAll()) do
			 if ply:Alive() and ply:GetRestricted() then
				ply:SetRestricted(true)
			end
		end
	end)

	concommand.Add("abort_restrict", function()
		for k,v in pairs(player.GetAll()) do
			if v:GetRestricted() then
				v:SetRestricted(false)
			end
		end
	end)

	local PLAYER = FindMetaTable("Player")
	
	-- BANNI
	PLAYER.SetRestricted2 = PLAYER.SetRestricted2 or PLAYER.SetRestricted
	function PLAYER:SetRestricted(restricted)
		self:SetLuaDataOption("restricted", restricted)
		self:SetNWBool("restricted", restricted)
		return self:SetRestricted2(restricted)
	end

	hook.Add("PlayerInitialSpawn", "BanniSpawn", function(ply)
		if( ply:GetLuaDataOption("restricted", false) ) then
			ply:SetRestricted(true)
		end
	end)
end
