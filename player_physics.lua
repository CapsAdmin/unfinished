local ENT = {}

do -- ENT

	ENT.Type = "anim"
	ENT.Base = "base_entity"

	ENT.Bottom = Vector(-0.53724020719528,-0.059773083776236,-34.8798828125)
	ENT.ClassName = "player_physics"

	function ENT:GetBottom()
		return self:LocalToWorld(self.Bottom)
	end

	function ENT:GetEyePos()
		return self:GetBottom() + self:GetUp() * 64
	end

	function ENT:HasPlayer()
		return self:GetOwner():IsPlayer()
	end

	function ENT:GetPlayer()
		return self:GetOwner():IsPlayer() and self:GetOwner() or NULL
	end

	if CLIENT then

--[[ 		function ENT:Draw()
 			render.CullMode(1)
				render.SetBlend(0.9)
					render.SetColorModulation(0.2, 0.2, 0.2)
						self:DrawModel()
					render.SetColorModulation(1, 1, 1)
				render.SetBlend(1)
			render.CullMode(0)
		end ]]

	else

		function ENT:OnTakeDamage(dmg)
			if self:HasPlayer() then
				local pl=self:GetPlayer()
				local old=dmg:GetInflictor()
				if not IsValid(old) then
					dmg:SetInflictor( pl ) -- we need an inflictor
				end
				pl:TakeDamageInfo(dmg)
			end
		end

		function ENT:Initialize()
			self:SetModel("models/props_wasteland/controlroom_filecabinet002a.mdl")

			self:SetMoveType(MOVETYPE_VPHYSICS)
			self:PhysicsInit(SOLID_VPHYSICS)

			self:SetMaterial("models/debug/debugwhite")

			self:StartMotionController()
			self:GetPhysicsObject():SetMaterial("bloodyflesh")

			self:NextThink(CurTime()+2)
		end

		function ENT:SetPlayer(ply)
			self:RemovePlayer()

			ply:SetMoveType(MOVETYPE_NOCLIP)
			self:SetOwner(ply)
			self:SetPos(ply:GetPos() + Vector(0,0,40))

			ply:SetViewOffset(vector_origin)
			ply:SetViewOffsetDucked(vector_origin) -- view offset will fix player parent rotation
			ply:SetDuckSpeed(0.01)
			ply:SetUnDuckSpeed(0.01)

			if ply.CollisionRulesChanged then
				ply:CollisionRulesChanged()
			end

			ply:SetParent(self)
			self:PhysWake()

			if ply.CollisionRulesChanged then
				ply:CollisionRulesChanged()
			end

			hook.Call("SetPlayerPhysics", GAMEMODE, ply, self)
			umsg.Start("SetPlayerPhysics")
				umsg.Entity(ply)
				umsg.Entity(self)
			umsg.End()
		end

		function ENT:OnRemove()
			local ply = self:GetPlayer()

			if ply:IsPlayer() then
				ply:SetOwner()
				ply:SetParent()
				ply:SetMoveType(MOVETYPE_WALK)

				ply:SetViewOffset(Vector(0,0,64))
				ply:SetViewOffsetDucked(Vector(0,0,28))
				ply:SetDuckSpeed(0.15)
				ply:SetUnDuckSpeed(0.15)
			end
		end

		ENT.RemovePlayer = ENT.OnRemove

		function ENT:PhysicsSimulate(phys, delta)
			local ply = self:GetPlayer()

			if ply:IsPlayer() then
				hook.Call("PPhys", nil, ply, self, phys)
			end
		end

		function ENT:Think()
			if not self:HasPlayer() then self:Remove() return end

			if self:GetPlayer():GetPos():Distance(self:GetPos()) > 200 then
				--self:GetPlayer():SetPos(self:GetEyePos())
				self:Remove()
			end

			self:NextThink(CurTime()+2)
			return true
		end

		function ENT:PhysicsCollide(data, phys)
			local speed = data.Speed/15

			if speed > 20 then
				local dmg = DamageInfo()
				dmg:SetDamageType(DMG_FALL)
				dmg:SetDamagePosition(data.HitPos)
				dmg:SetDamage(speed)
				dmg:SetInflictor( self:GetPlayer() )
				self:GetPlayer():TakeDamageInfo(dmg)
			end
		end
	end

	scripted_ents.Register(ENT, ENT.ClassName, true)
end

do -- meta
	do -- player

		ENT.OldMetaFunctions = ENT.OldMetaFunctions or {
			entity = {},
			player = {},
		}

		local oldmeta = ENT.OldMetaFunctions

		local player_meta = FindMetaTable("Player")
		local entity_meta = FindMetaTable("Entity")

		function player_meta:HasPlayerPhysics()
			if( self:IsValid() ) then
				return self:GetParent().ClassName == "player_physics"
			end
			return false
		end

		function player_meta:GetPlayerPhysics()
			if( self:IsValid() ) then
				return self:HasPlayerPhysics() and self:GetParent() or NULL
			end
			return NULL
		end

		oldmeta.TraceLine = oldmeta.TraceLine or util.TraceLine

		local function GetPlayerFromFilter(var)
			if IsEntity(var) then
				return var, false
			end

			if type(var) == "table" then
				for _, value in pairs(var) do
					if IsEntity(value) and value:IsPlayer() then
						return value, true
					end
				end
			end

			return NULL, false
		end

		do
		local ply, istbl
		function util.TraceLine(tbl, ...)
			ply, istbl = GetPlayerFromFilter(tbl.filter)
			if ply:IsPlayer() and ply:HasPlayerPhysics() then
				if not _istbl then
					tbl.filter = {ply, ply:GetPlayerPhysics()}
				else
					table.insert(tbl.filter, ply:GetPlayerPhysics())
				end
			end

			return oldmeta.TraceLine(tbl,...)
		end
		end

		if SERVER then
			function player_meta:SetPlayerPhysics(bool)
				if bool and not self:HasPlayerPhysics() then
					local entity = ents.Create(ENT.ClassName)
					entity:Spawn()
					entity:SetPlayer(self)
					return entity
				elseif bool == false and self:HasPlayerPhysics() then
					local ent = self:GetPlayerPhysics()
					ent:Remove()
				end
			end

			oldmeta.entity.SetPos = oldmeta.entity.SetPos or entity_meta.SetPos
				function entity_meta:SetPos(command, ...)
					if self and self:IsPlayer() and self:HasPlayerPhysics() then
						return self:GetPlayerPhysics():SetPos(command, ...)
					end

					return oldmeta.entity.SetPos(self, command, ...)
				end

			oldmeta.entity.GetPos = oldmeta.entity.GetPos or entity_meta.GetPos
				function entity_meta:GetPos(command, ...)
					if self and self:IsPlayer() and self:HasPlayerPhysics() then
						return self:GetPlayerPhysics():GetPos(command, ...)
					end

					return oldmeta.entity.GetPos(self, command, ...)
				end

			oldmeta.player.Give = oldmeta.player.Give or player_meta.Give
				function player_meta:Give(class, ...)
					if self and type(class) == "string" and self:HasPlayerPhysics() then

						local player_phys = self:GetPlayerPhysics()

						self:SetParent()

						local ent = self:Give(class, ...)

						self:SetParent(player_phys)

						return ent
					end
					return oldmeta.player.Give(self, class, ...)
				end
		end
	end
end

do -- hooks

	hook.Add("PlayerDeath", "player_physics", function(ply)
		if ply:HasPlayerPhysics() then
			ply:SetPlayerPhysics(false)
			ply.__pphys_spawn_enable = true
		end
	end)

	hook.Add("PlayerSpawn", "player_physics", function(ply)
		if ply.__pphys_spawn_enable then
			if ply:HasPlayerPhysics() then
				ply:SetPlayerPhysics(false)
			end

			timer.Simple(0.2, function()
				ply:SetPlayerPhysics(true)
				ply.__pphys_spawn_enable = nil
			end)
		end
	end)

	hook.Add("ShouldCollide", "player_physics", function(a, b)
		if a:IsPlayer() and a:GetPlayerPhysics() == b or b:IsPlayer() and b:GetPlayerPhysics() == a then
			return false
		end
	end)

	hook.Add("Move", "player_physics", function(ply, ucmd)
		if ply:HasPlayerPhysics() then

			if ply.phys_request_move_velocity then
				ucmd:SetVelocity(ply.phys_request_move_velocity)
				ply.phys_request_move_velocity = nil
			end

			return true
		end
	end)

	local function Disallow(ply, ent)
		if ply:GetPlayerPhysics() == ent then
			return false
		end
	end

	local function Disallow2(ply)
		if ply:HasPlayerPhysics() then
			return false
		end
	end

	hook.Add("GravGunPickupAllowed", "player_physics", Disallow)
	hook.Add("GravGunPunt", "player_physics", Disallow)
	hook.Add("PhysgunPickup", "player_physics", Disallow)
	hook.Add("PlayerNoClip", "player_physics", Disallow2)
	hook.Add("GravGunPunt", "player_physics", Disallow2)
	hook.Add("GravGunPickup", "player_physics", Disallow2)

	if CLIENT then

		local ply = LocalPlayer()

		hook.Add("UpdateAnimation", "player_physics", function(ply)
			if ply:HasPlayerPhysics() then
				local self = ply:GetPlayerPhysics()
				if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

				ply:SetPos(self:GetBottom())
				ply:SetRenderOrigin(ply:GetPos())
				ply:SetAngles(self:GetAngles())
				ply:SetRenderAngles(ply:GetAngles())
				ply:SetupBones()

				hook.Call("PPhys", nil, ply, self, NULL)
			end
		end)

		hook.Add("CalcView", "player_physics", function(ply,pos,ang,fov)
			if LocalPlayer():HasPlayerPhysics() then

				local new_pos, new_ang =  hook.Call("PPhys", nil, ply, ply:GetPlayerPhysics(), NULL)

				if new_pos or new_ang then
					pos = new_pos or pos
					pos = new_ang or ang

					return GAMEMODE:CalcView(ply,pos,ang,fov)
				end
			end
		end)

		usermessage.Hook("SetPlayerPhysics", function(umr)
			local ply = umr:ReadEntity()
			local ent = umr:ReadEntity()

			if ply:IsPlayer() and ent:IsValid() then
				hook.Call("SetPlayerPhysics", GAMEMODE, ply, self)
			end
		end)

	end
end