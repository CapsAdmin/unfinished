setfenv(1, _G)
battle = battle or {}

battle.entity_vars = battle.entity_vars or {}

function battle.SetEntityVar(ent, key, value, nw)
	if ent and key then
		battle.entity_vars[ent:EntIndex()] = battle.entity_vars[ent:EntIndex()] or {}
		battle.entity_vars[ent:EntIndex()][key] = value
		if nw and SERVER then
			ent:SetNWBool("battle_" .. key, value)
		end
	else
		debug.Trace()
	end
end

function battle.GetEntityVar(ent, key)
	if (not ent or not ent:IsValid()) or not key then
	return end

	local var
	if CLIENT then
		var = ent:GetNWBool("battle_" .. key, nil)
	end
	local vars = battle.entity_vars[ent:EntIndex()]
	return vars and vars[key] or var
end

function battle.ClearEntityVars(ent)
	if battle.entity_vars[ent:EntIndex()] and SERVER then
		for key, val in pairs(battle.entity_vars[ent:EntIndex()]) do
			ent:SetNWBool("battle_" .. key, false)
		end
	end
	battle.entity_vars[ent:EntIndex()] = nil
	if ent:IsPlayer() then
		--ent:Freeze(false)
	end
end

function battle.IsInBattle(ent)
	return battle.GetEntityVar(ent, "hp") or ent.battle_teamid
end

local function table_RemoveValue(tbl, var)
	for key, val in pairs(tbl) do
		if val == var then
			table.remove(tbl, key)
			break
		end
	end
end

function battle.IsAlive(ent)
	return ent:IsPlayer() and ent:Alive()
end


function battle.GetHeadBone(ent)
	if ent.battle_head then return ent.battle_head end
	for i=1, ent:GetBoneCount() do
		local name = ent:GetBoneName(i)
		if name and name:lower():find("head") then
			ent.battle_head = name
			return name
		end
	end
end

function battle.GetHeadPosAng(ent)
	local bone = battle.GetHeadBone(ent)
	if bone then
		return ent:GetBonePosition(ent:LookupBone(bone))
	end
	return ent:EyePos(), ent:EyeAngles()
end

function battle.GetBonePos(ent, bone)
	return ent:GetBonePosition(ent:LookupBone(bone or BONE_HEAD)) or ent:EyePos()
end

function battle.GetHitPos(ent, wep)
	return battle.GetBonePos(ent)
	--[[local spread = 0.01

	if false and wep and wep:IsValid() then
		if wep.Primary and wep.Primary.Recoil then
			spread = wep.Primary.Recoil / 3
		end
	end

	local rad = ent:BoundingRadius()
	return ent:GetPos() + (Vector(0,0,72/2) + (VectorRand()*ent:BoundingRadius())*spread)]]
end

function battle.GetCenterOf(entities)
	local pos = vector_origin
	local count = 0

	if table.Count(entities) == 1 then
		return entities[1]:IsValid() and entities[1]:EyePos() or LocalPlayer():EyePos()
	elseif table.Count(entities) > 1 then
		for key, ent in pairs(entities) do
			if ent:IsValid() then
				pos = pos + ent:EyePos()
				count = count + 1
			else
				pos = pos + LocalPlayer():EyePos()
				count = count + 1
			end
		end
		if count > 0 then pos = pos / count end
	end
	
	return pos
end

function battle.GetFloorPos(pos)
	return
		util.TraceLine
		{
			start = pos + physenv.GetGravity():Normalize() * -5,
			endpos = pos + physenv.GetGravity() * 32000,
			filter = ents.GetAll(),
		}.HitPos
end

if CLIENT then

	function battle.StartMusic(url)
		battle.StopMusic()

		url = url or "http://www.infinitelooper.com/?v=dkv10qgFaW8&p=n"

		battle_html = vgui.Create("HTML")

		battle_html:OpenURL(url)
		battle_html:SetSize(500, 500)
		battle_html:SetVisible(false)

	end

	function battle.StopMusic()
		if battle_html and battle_html:IsValid() then
			battle_html:Remove()
		end
	end

	hook.Remove("CreateMove", "stalk_pc")

	battle.CurrentPlayers = nil
	battle.CurrentEnemies = nil
	battle.selected_menu = {}

	usermessage.Hook("battle_event", function(umr)
		local event = umr:ReadString()
		local args = glon.decode(umr:ReadString()) or {}

		if battle[event] then
			battle[event](unpack(args))
		end
	end)

	function battle.CheckPlayers()
		if battle.CurrentPlayers and battle.CurrentEnemies then
			for key, ply in pairs(battle.CurrentPlayers) do
				if not battle.IsInBattle(ply) then
					print("not in battle", ply)
					table.remove(battle.CurrentPlayers, key)
				end
			end
			for key, ply in pairs(battle.CurrentEnemies) do
				if not battle.IsInBattle(ply) then
					print("not in battle", ply)
					table.remove(battle.CurrentEnemies, key)
				end
			end
		end
	end

	timer.Create("battle_checkplayers", 0.1, 0, battle.CheckPlayers)

	function battle.OnStart(a, b)
		local players
		local enemies
		if table.HasValue(a, LocalPlayer()) then
			players = a
			enemies = b
		elseif table.HasValue(b, LocalPlayer()) then
			players = b
			enemies = a
		end
		battle.CurrentPlayers = players
		battle.CurrentEnemies = enemies
		battle.AddHooks()

		battle.StartMusic()

		battle.won = false

		timer.Simple(1, function()
			battle.SetInstantCamera(true)
			battle.CenterCamera()
			battle.SetInstantCamera(false)
		end)
	end

	function battle.OnPlayerDeath(ply)
		if ply == LocalPlayer() then
			battle.OnEnd()
		end
	end

	function battle.OnEnd()
		battle.CurrentPlayers = nil
		battle.CurrentEnemies = nil
		battle.selected_menu = nil
		battle.StopMusic()
		battle.RemoveHooks()
		gui.EnableScreenClicker(false)
	end

	function battle.OnWin()
		gui.EnableScreenClicker(false)
		battle.won = true
		battle.CenterCamera()
	end

	function battle.RemoveHooks()
		hook.Remove("CalcView", "battle", battle.CalcView)
		hook.Remove("ShouldDrawLocalPlayer", "battle", battle.ShouldDrawLocalPlayer)
		hook.Remove("UpdateAnimation", "battle", battle.UpdateAnimation)
		hook.Remove("Move", "battle", battle.Move)
		hook.Remove("CreateMove", "battle", battle.CreateMove)
		hook.Remove("PostRenderVGUI", "battle", battle.PostRenderVGUI)
		hook.Remove("HUDShouldDraw", "battle", battle.HUDShouldDraw)
	end

	function battle.AddHooks()
		hook.Add("CalcView", "battle", battle.CalcView)
		hook.Add("ShouldDrawLocalPlayer", "battle", battle.ShouldDrawLocalPlayer)
		hook.Add("UpdateAnimation", "battle", battle.UpdateAnimation)
		hook.Add("Move", "battle", battle.Move)
		hook.Add("CreateMove", "battle", battle.CreateMove)
		hook.Add("PostRenderVGUI", "battle", battle.PostRenderVGUI)
		hook.Add("HUDShouldDraw", "battle", battle.HUDShouldDraw)
	end

	function battle.CalcViewBobbing(cmd)
		local t = RealTime() * 7.5
		cmd:SetViewAngles(cmd:GetViewAngles() + Angle(-math.abs(math.cos(t)*5)+2.5,math.sin(t)*1.5,0))
	end

	function battle.CreateMove(cmd)
		local ply = LocalPlayer()
		local ent = battle.GetEntityVar(ply, "target_ent") or NULL

		if ent:IsValid() then
			local ang = (ent:EyePos() - ply:EyePos()):Angle()

			ang.p = math.Clamp(math.NormalizeAngle(ang.p), -90, 90)
			ang.y = math.NormalizeAngle(ang.y)
			ang.r = 0

			cmd:SetViewAngles(ang)

			battle.CalcViewBobbing(cmd)
		end

	end

	local smooth_origin = vector_origin
	local velocity = vector_origin
	function battle.UpdateAnimation(ply)
		if ply == LocalPlayer() then
			velocity = (ply:GetPos() - smooth_origin) * FrameTime() * 10
			smooth_origin = smooth_origin + velocity
			ply:SetPos(smooth_origin)
		end
	end

	function battle.Move(ply, mov)
		if battle.IsInBattle(ply) then
			mov:SetVelocity(velocity*40)
			return true
		end
	end
end

if SERVER then

	function battle.OnWin(players)
		for key, ply in pairs(players) do
			battle.SetTargetEntity(ply, NULL)
			battle.SetEntityVar(ply, "done", true)
			if ply:IsPlayer() then
				local pos = ply:GetPos()
				ply:StripWeapons()
				ply:Spawn()
				ply:SetPos(pos)
				ply.battle_teamid = nil
				ply.battle_busy = nil
			end
		end
		battle.BroadcastEvent("StartMusic", "http://www.youtube.com/watch?feature=player_detailpage&v=I-6kSBR8qZ8")
		battle.BroadcastEvent("OnWin")
		hook.Call("BattleEnd", GAMEMODE, players)
		timer.Simple(8+math.random()*4, function()
			battle.BroadcastEvent("OnEnd")
			battle.Stop(players)
			for key, npc in pairs(battle.NPCs) do
				if npc:IsValid() then
					npc:Remove()
				end
			end
		end)
	end

	function battle.Stop(players)
		players = IsEntity(players) and {players} or players
		for key, ent in pairs(players) do
			if ent:IsPlayer() then
				local pos = ent:GetPos()
				ent:StripWeapons()
				ent:Spawn()
				ent:SetPos(pos)
				ent.battle_teamid = nil
				ent.battle_busy = nil
				battle.BroadcastEvent("OnPlayerDeath", ent)
			end
			battle.ClearEntityVars(ent)
		end

	end

	function battle.BroadcastEvent(event, ...)
		if type(event) == "string" then
			local str = glon.encode({...})

			local rp = RecipientFilter()
			for k,v in pairs(player.GetAll()) do
				if battle.IsInBattle(v) then
					rp:AddPlayer(v)
				end
			end

			umsg.Start("battle_event", rp)
				umsg.String(event)
				umsg.String(str)
			umsg.End()
		end
	end

	function battle.CheckTarget(ply)
		local ent = battle.GetEntityVar(ply, "target_ent") or NULL

		if ent:IsValid() then
			if ent:IsPlayer() and not battle.IsAlive(ent) then
				battle.SetEntityVar(ply, "target_ent", NULL, true)
				battle.KeyPress(ply, IN_MOVELEFT)
			end
		end
	end

	function battle.Think()
		for key, ply in pairs(player.GetAll()) do
			if battle.IsInBattle(ply) then
				if not ply:Alive() then
					battle.PlayerDeath(ply, NULL, ply)
					return
				end
				local time = battle.GetEntityVar(ply, "wait")
				if time and time < CurTime() then
					battle.SetEntityVar(ply, "wait", nil, true)
				end
			end
		end

		--battle.CheckNPCS()
	end

	timer.Create("battle_think", 0.1, 0, battle.Think)

	function battle.PlayerShouldTakeDamage(a,b, dmg)
		if battle.IsInBattle(a) and (b:IsNPC() or battle.__allow_damage == b) then
			timer.Simple(0, function() battle.SetEntityVar(a, "hp", a:Health(), true) end)
			return true
		end
	end
	hook.Add("PlayerShouldTakeDamage", "battle", battle.PlayerShouldTakeDamage)

	function battle.CheckStatus(ply)
		local tbl = battle.GetEntityVar(ply, "enemies")

		if tbl then
			for key, ent in pairs(tbl) do
				if not ent:IsValid() then
					table.remove(tbl, key)
					if not ply:Alive() then
						table_RemoveValue(tbl, ply)
					end
				end
			end

			if #tbl == 0 then
				local players = battle.GetEntityVar(ply, "players")
				battle.SetEntityVar(ply, "enemies", nil)
				battle.OnWin(players)
			end
		end
	end

	function battle.PlayerDeath(a, _, b)
		if battle.IsInBattle(a) then
			if a == b then
				battle.Stop(a)
				return
			end

			battle.BroadcastEvent("OnPlayerDeath", a)
			battle.Stop(a)

			local tbl = battle.GetEntityVar(b, "enemies")
			if tbl then
				table_RemoveValue(tbl, a)
				battle.SetEntityVar(b, "enemies", tbl)
			end

			battle.CheckStatus(b)
		end
	end
	hook.Add("PlayerDeath", "battle", battle.PlayerDeath)
	hook.Add("OnNPCKilled", "battle", function(a,b,_)
		battle.PlayerDeath(a,_,b)
	end)
	hook.Add("EntityRemoved", "battle", function(ply)
		if ply:IsPlayer() and battle.IsInBattle(ply) then
			local b = battle.GetEntityVar(ply, "enemies")
			timer.Simple(0.2, function()
				battle.CheckStatus(table.Random(b))
			end)
		end
	end)

	function battle.TakeEntityDamage(ent, dmginfo)
		if _SKIP_ENT == ent then return end
		if not ent.battle_health_init then
			local max = 100

			local phys = ent:GetPhysicsObject()

			if phys:IsValid() and phys:GetMass() and phys:GetVolume() then
				max = phys:GetMass() / 5 + (phys:GetVolume() / 300)
			end

			if max then
				battle.SetEntityVar(ent, "hp_max", max, true)
				battle.SetEntityVar(ent, "hp", max, true)

				ent.battle_health_init = true
			end
		end

		local health = battle.GetEntityVar(ent, "hp")

		health = health - dmginfo:GetDamage()
		battle.SetEntityVar(ent, "hp", health, true)

		if health < 0 then
			local max = battle.GetEntityVar(ent, "hp_max")
			local pos = ent:GetPos()
			local rad = ent:BoundingRadius() * 4

			max = max > 0 and max or 100

			if not ent:IsPlayer() then
				ent:Remove()
			end

			timer.Simple(math.random()*0.5, function()
				local data = EffectData()
				data:SetOrigin(pos)
				util.Effect("explosion", data)

				for key, ent in pairs(ents.FindInSphere(pos, rad)) do
					local mult = ent:GetPos():Distance(pos) / rad

					local phys = ent:GetPhysicsObject()
					if phys:IsValid() then
						phys:Wake()

						phys:AddVelocity((ent:GetPos() - phys:GetPos()) * phys:GetMass() * 1000 * (((-mult)+1) * 5) )
						phys:AddAngleVelocity((VectorRand() * phys:GetMass() * mult) * 10)
					end

					local _dmginfo = DamageInfo()
					local attacker = dmginfo:GetAttacker()
					if attacker:IsValid() then
						_dmginfo:SetAttacker()
					end
					_dmginfo:SetDamage(mult*100)
					_SKIP_ENT = ent
						ent:TakeDamage(_dmginfo)
					_SKIP_ENT = nil
				end
			end)
		end
	end

	function battle.EntityTakeDamage(a, wep, b, _, dmg)
		if battle.IsInBattle(a) and not battle.IsInBattle(b) and b:IsPlayer() then
			dmg:ScaleDamage(0)
		end
		if (battle.__allow_damage == b or a:IsNPC()) and battle.IsInBattle(a) and battle.IsInBattle(b) and a ~= b then
			if a:IsPlayer() or a:IsNPC() then
				if battle.GetEntityVar(ply, "critical") then
					dmg:ScaleDamage(1) -- uh
				else
					dmg:ScaleDamage(0.1)
				end
			else
				battle.TakeEntityDamage(a, dmg)
			end
			dmg:AddDamage(1)
			local health = b:Health()
			if a:IsNPC() and (a:Health() - dmg:GetDamage()) <= 1 then
				a:SetHealth(-1)
				a:SetSchedule(SCHED_DIE)
				timer.Simple(5, function()
					SafeRemoveEntity(a)
				end)
			end
			battle.ShowHitDamage(a, dmg)
			return dmg
		end
	end
	hook.Add("EntityTakeDamage", "battle", battle.EntityTakeDamage )

	battle.NPCs = {}

	function battle.SolveRelationships(a, b)
		for k,v in pairs(a) do
			if(v:IsNPC()) then
				for k2,v2 in pairs(b) do
					v:AddEntityRelationship(v2,D_HT,99)
				end
				for k2,v2 in pairs(a) do
					v:AddEntityRelationship(v2,D_LI,99)
				end
				table.insert(battle.NPCs, v)
			end
		end
		for k,v in pairs(b) do
			if(v:IsNPC()) then
				for k2,v2 in pairs(a) do
					v:AddEntityRelationship(v2,D_HT,99)
				end
				for k2,v2 in pairs(b) do
					v:AddEntityRelationship(v2,D_LI,99)
				end
				table.insert(battle.NPCs, v)
			end
		end
	end

	battle.AllowedWeapons =-- {}
	--[[for k,v in pairs(weapons.GetList()) do
		table.insert(battle.AllowedWeapons, v.ClassName)
	end]]
	{
		"weapon_sh_five-seven",
		"weapon_sh_aug",
		"weapon_sh_awp",
		"weapon_mp5",
		"weapon_sh_rpg",
		"weapon_sh_g3sg1",
		"weapon_mac10",
		"weapon_sh_scout",
		"weapon_sh_usp",
		"weapon_sh_xm1014",
		"weapon_sh_tmp",
		"weapon_pumpshotgun",
		"weapon_sh_p90",
		"weapon_fiveseven",
		"weapon_sh_galil",
		"weapon_sh_m4a2",
		"weapon_sh_ak47",
		"weapon_deagle",
		"weapon_ak47",
		"weapon_sh_sg550",
		"weapon_glock",
		"weapon_sh_mp5a4",
		"weapon_sh_c4",
		"weapon_m4",
		"weapon_sh_sg552",
		"weapon_sh_pumpshotgun",
		"weapon_sh_m249",
		"weapon_sh_pumpshotgun2",
		"weapon_para",
		"weapon_sh_glock18",
		"weapon_sh_famas",
		"weapon_tmp",
		"weapon_sh_deagle",
		"weapon_sh_p228",
		"weapon_sh_ump_45",
		"weapon_crowbar",
		"weapon_stunstick",
		"weapon_flamethrower",
		"weapon_rpg",
	}

	function battle.SetupPlayer(ent)
		if ent:IsPlayer() then
			ent:StripWeapons()
			ent:Give"weapon_crowbar"
		
			do return end
			--ent:Freeze(true)
			for i=1, 5 do
				ent:Give(table.Random(battle.AllowedWeapons))
			end
		end
	end

	function battle.Start(a, b, pos, health, radius, skip_b_setpos)

		a = IsEntity(a) and {a} or a
		b = IsEntity(b) and {b} or b

		if #a == 0 then return end
		if #b == 0 then return end

		pos = pos or Vector(-1971.28125, -12308.817382812, -13303.96875)
		health = health or 500
		local ang = Angle(0,0,0)

		local function setup(players, enemies, skip_b_setpos, forward)
			for key, val in pairs(players) do
				if type(val) == "string" then
					local ent = ents.Create(val)
					--ent:SetPos(pos + Vector(math.Rand(-300, 300), math.Rand(-300, 300), 0))
					ent:Spawn()
					players[key] = ent
				end
			end

			for key, ent in pairs(players) do
				if not ent:IsValid() then 
					table.remove(players, key) 
				continue end
				
				if not battle.IsAlive(ent) then 
					ent:Spawn() 
				end

				ent.battle_teamid = tostring(players)

				if health and ent:IsPlayer() then
					ent:SetHealth(health)
					ent:SetMaxHealth(health)
				end
				
				if not skip_b_setpos then
					ent.battle_origin = nil
					ent:SetPos(pos + ang:Forward() * forward + ang:Right() * (ent:BoundingRadius() * 3 * (key-(#players/2))))
					battle.SetupPlayer(ent)
				end
				
				if ent:IsNPC() then
					ent:SetPos(ent:GetPos() + Vector(0,0,ent:BoundingRadius()*1.5))
					ent:DropToFloor()
				end

				battle.ClearEntityVars(ent)
				if radius then 
					battle.SetEntityVar(ent, "enemy_radius", radius, true) 
				end

				battle.SetEntityVar(ent, "players", players)
				battle.SetEntityVar(ent, "enemies", enemies)
				battle.SetEntityVar(ent, "hp", ent:Health(), true)
				battle.SetEntityVar(ent, "hp_max", ent:GetMaxHealth(), true)
			end
			
			return table.Copy(players) -- uhh
		end

		a = setup(a,b, nil, 100)
		b = setup(b,a,skip_b_setpos, -100)
		
		battle.SolveRelationships(a, b)
		timer.Simple(0.1, function()
			battle.BroadcastEvent("OnStart", a, b)
		end)

		hook.Call("BattleStart",GAMEMODE, a, b)

	end
end

if CLIENT then -- camera

	function battle.GetBonePos(ent, bone)
		return ent:GetBonePosition(ent:LookupBone(bone)) or data.ent:EyePos()
	end


	do -- internal view
		battle.CameraPosEntity = {ent = NULL, bone = "", offset = vector_origin}
		battle.CameraDirEntity = {ent = NULL, bone = "", offset = vector_origin}

		battle.CameraOffset = vector_origin
		battle.CameraPos = vector_origin
		battle.CameraDir = vector_origin
		battle.CameraFOV = 75
		battle.CameraRoll = 0
		battle.CameraSpeed = 4

		local smooth_pos = vector_origin
		local smooth_dir = vector_origin
		local smooth_fov = 0
		local smooth_roll = 0

		function battle.GetCurrentCameraPos()
			return smooth_pos
		end

		local function GetTraceBlock(start_pos, end_pos)
			local trace_forward = util.TraceLine({
				start = start_pos,
				endpos = end_pos,
			})

			if trace_forward.Hit and not trace_forward.Entity:IsPlayer() and not trace_forward.Entity:IsVehicle() then
				return trace_forward.HitPos
			end

			return end_pos
		end

		function battle.CalcView(ply)
			if not battle.CurrentEnemies or not battle.CurrentPlayers then return end

			if battle.busy_with_animation or battle.won then
				battle.CameraSpeed = 10
			else
				battle.CameraSpeed = 4
				battle.CalcTrackCamera()
			end

			local speed = FrameTime() * battle.CameraSpeed

			local pos = battle.CameraPos + battle.CameraOffset
			local dir = battle.CameraDir
			local fov = battle.CameraFOV
			local roll = battle.CameraRoll

			if battle.CameraPosEntity.ent:IsValid() then
				local data = battle.CameraPosEntity
				pos = LocalToWorld(battle.CameraOffset, Angle(), battle.GetBonePos(data.ent, data.bone), data.ent:EyeAngles())
			end

			if battle.CameraDirEntity.ent:IsValid() then
				local data = battle.CameraDirEntity
				dir = LocalToWorld(battle.CameraOffset, Angle(), battle.GetBonePos(data.ent, data.bone), data.ent:EyeAngles()) - pos
			end

			if battle.InstantCamera then
				smooth_pos = pos
				smooth_dir = dir
				smooth_fov = fov
				smooth_roll = roll
			else
				smooth_pos = smooth_pos + ((pos - smooth_pos) * speed)
				smooth_dir = smooth_dir + ((dir - smooth_dir) * speed)
				smooth_fov = smooth_fov + ((fov - smooth_fov) * speed)
				smooth_roll = smooth_roll + (math.AngleDifference(roll, smooth_roll) * speed)
			end

			--smooth_pos = (GetTraceBlock(battle.CameraPos , smooth_pos) + battle.CameraOffset) or smooth_pos

			local angles = smooth_dir:Angle()
			angles.r = math.NormalizeAngle(smooth_roll)

			return
			{
				origin = smooth_pos,
				angles = angles,
				fov = smooth_fov,
			}
		end

		function battle.ShouldDrawLocalPlayer()
			return true
		end
	end

	do -- view
		function battle.SetInstantCamera(b)
			battle.InstantCamera = b
		end

		do -- interpolation

			--[[2:11 AM - Morten: ]]
			local function lerp_vectors(x, alpha)
				local y = {}

				for i = 1, #x - 1 do
					y[i] = LerpVector(alpha, x[i], x[i + 1])
				end

				if #y > 1 then return lerp_vectors(y, alpha) else return y[1] end
			end

			local function lerp_numbers(x, alpha)
				local y = {}

				for i = 1, #x - 1 do
					y[i] = Lerp(alpha, x[i], x[i + 1])
				end

				if #y > 1 then return lerp_numbers(y, alpha) else return y[1] end
			end

			local function animate(tbl, speed, func, tag, lerp_func)
				if #tbl == 0 then return end

				speed = speed or 1
				local frame = 0

				hook.Add("Think", "battle_" .. tag .. "_camera", function()
					battle.busy_with_animation = true
					local pos = lerp_func(tbl, frame)

					func(pos)

					frame = frame + FrameTime() * speed

					if frame > 1 then

						timer.Create("battle_busy_annimation", 0.5, 1, function()
							battle.busy_with_animation = false
						end)
						hook.Remove("Think", "battle_" .. tag .. "_camera")
					end
				end)
			end

			local function extract(tbl, key)
				local temp = {}
				for k,v in ipairs(tbl) do
					temp[k] = v[key]
				end
				return temp
			end

			function battle.PlayAnimation(tbl, speed, aim_at_pos)
				animate(extract(tbl, "pos", vector_origin), speed, battle.MoveCamera, "move", lerp_vectors)
				animate(extract(tbl, "offset", vector_origin), speed, battle.OffsetCamera, "offset", lerp_vectors)
				animate(extract(tbl, aim_at_pos and "pos" or "aim", vector_origin), speed, battle.AimCamera, "aim", lerp_vectors)
				animate(extract(tbl, "roll", 0), speed, battle.RollCamera, "roll", lerp_numbers)
				animate(extract(tbl, "fov", 0), speed, battle.ZoomCamera, "fov", lerp_numbers)
			end
		end

		function battle.MoveCamera(pos)
			if IsEntity(pos) then
				battle.CameraPosEntity = {ent = pos, bone = bone or ""}
			else
				battle.CameraPos = pos
				battle.CameraPosEntity.ent = NULL
			end
		end

		function battle.AimCamera(pos, dont_store)
			if type(pos) == "Angle" then
				battle.CameraDir = pos:Forward()
				battle.CameraDirEntity.ent = NULL
			elseif IsEntity(pos) then
				if not dont_store then battle.LastAimedEntity = pos end
				battle.CameraDirEntity = {ent = pos, bone = bone or ""}
			else
				battle.CameraDir = (pos - (battle.CameraPos - battle.CameraOffset)):Normalize()
				battle.CameraDirEntity.ent = NULL
			end
		end

		function battle.OffsetCamera(offset)
			battle.CameraOffset = offset
		end

		function battle.RollCamera(roll)
			battle.CameraRoll = roll
		end

		function battle.ZoomCamera(mult)
			battle.CameraFOV = 75 * mult
		end

		function battle.CalcTrackCamera()
			local a_center = battle.GetCenterOf(battle.CurrentPlayers, battle.GetCurrentCameraPos(), 1000)
			local b_center = battle.GetCenterOf(battle.CurrentEnemies, battle.GetCurrentCameraPos(), 1000)
			
			local center = a_center + b_center
			center = center / 2
			center = center + (a_center - b_center) * 2

			center.z = battle.GetFloorPos(LocalPlayer():EyePos()).z + 100

			battle.MoveCamera(center)
			battle.ZoomCamera(0.7)

			if #battle.CurrentEnemies == 1 then
				battle.AimCamera(b_center)
			end
		end
	end

	do -- animations

		function battle.SpinAnimation(pos, spins, speed)
			spins = spins or 2

			local tbl = {}
			local max = spins*4

			for i=1, max do
				local offset = (Vector(math.sin((i/max)*(math.pi*spins)), math.cos((i/max)*(math.pi*spins)), (i/max)-1) * (Vector(spins, spins, spins*0.5)*(-(i/max)+2)) * 10)
				tbl[i] =
				{
					pos = pos + offset,
					fov = math.min(-(i/max)+1.25, 1),
					aim = pos,
					roll = ((i/max)*10)-5,
				}
			end

			battle.PlayAnimation(
				tbl,
				speed or 0.25
			)
		end

		function battle.CameraSpinEntity(ent, spins, speed)
			local origin = battle.GetHeadPosAng(ent)

			battle.SpinAnimation(origin, spins, speed)
		end

		function battle.SlideAnimation(a, b, fov, speed)
			battle.PlayAnimation(
				{
					{
						pos = a,
						fov = fov,
						roll = 10,
					},
					{
						pos = b,
						fov = fov,
						roll = 0,
					}
				},
				speed or 0.25
			)
		end

		function battle.CameraSlideEntity(ent, fov)
			surface.PlaySound("misc/flame_engulf.wav")
			local origin, angles = battle.GetHeadPosAng(ent)

			local forward = -ent:EyeAngles():Forward()
			local right = ent:EyeAngles():Right()

			battle.AimCamera(forward:Angle())
			battle.SlideAnimation(
				origin + forward * -70 + right * 50,
				origin + forward * -70 + right,
				fov or 0.2,
				2
			)
		end

	end

	do -- helpers
		function battle.GetAllParticipants()
			if battle.CurrentPlayers and battle.CurrentEnemies then
				local entities = {}
				for k,v in pairs(battle.CurrentPlayers) do
					table.insert(entities, v)
				end
				for k,v in pairs(battle.CurrentEnemies) do
					table.insert(entities, v)
				end
				return entities
			end
			return {}
		end

		function battle.CenterCameraPos(offset)
			local center = battle.GetCenterOf(battle.GetAllParticipants())
			battle.MoveCamera(center + offset)
			battle.AimCamera(center)
			return center + offset, center
		end

		local function random(min, max, protect)
			local rand = math.Rand(min, max)
			if math.abs(rand) > protect then
				rand = rand + (math.random() > 0.5 and protect or -protect)
			end
			return rand
		end

		function battle.CenterCamera()
			battle.SetInstantCamera(true)
			local radius = battle.GetEntityVar(LocalPlayer(), "enemy_radius") or 100
			local pos, origin = battle.CenterCameraPos(Vector(random(-8,8, 4),random(-8,8, 4),math.Rand(0.5, 1.2))*radius)
			battle.ZoomCamera(math.max((-(pos:Distance(origin)/1500)+1) + math.Rand(-0.2, 0.2), 0.1))
			battle.SetInstantCamera(false)
		end
	end

end

do -- HUD
	if CLIENT then

		local PAD = 16
		local function draw_text(str, x, y, font, ax, ay, wscale)
			surface.SetFont(font or "budgetlabel")

			ax = ax or 0
			ay = ay or 0

			local w,h = surface.GetTextSize(str)

			ax = ax * (wscale or w)
			ay = ay * h

			x, y = PAD+x+ax, (PAD + (h*0.5))+y+ay
			surface.SetTextPos(x,y)
			surface.DrawText(str)
			return x,y
		end

		local function draw_hp(x,y, ply)
			local min = battle.GetEntityVar(ply, "hp") or 100
			local max = battle.GetEntityVar(ply, "hp_max") or 100

			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(PAD+x,PAD+y, 100, 2)

			local col = HSVToColor((min/max)*180, 1, 1)
			surface.SetDrawColor(col.r, col.g, col.b, 255)
			surface.DrawRect(PAD+x,PAD+y, (min/max)*100, 2)
			draw_text(min .. "/" .. max, x, y, nil, nil, -1.5)
		end

		local function draw_time(x,y, ply)
			local min = tonumber(battle.GetEntityVar(ply, "wait") or 0)
			if min then
				min = math.Clamp((min-CurTime())/2, 0, 1) * 100
			end
			local max = 100

			local x,y = PAD+x, PAD+y - 10

			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(x, y, 50, 10)

			surface.SetDrawColor(200, (min/max)*200, 100, 255)
			surface.DrawRect(x, y, ((min/max)*-50)+50, 10)

			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawOutlinedRect(x, y, 50, 10)
		end

		local attack_menu
		local item_menu
		local main_menu

		local function populate_items()
			local tbl = {}
			for key, wep in pairs(LocalPlayer():GetWeapons()) do
				if true or wep.PrimaryAttack and wep.Category and wep.Category:find("Counter") then -- css only for now
					table.insert(tbl,
						{
							str = wep.PrintName or wep:GetClass(),
							callback = function()
								if wep:IsValid() then
									RunConsoleCommand("battle_select_weapon", wep:GetClass())
								end
								battle.selected_menu = main_menu
								battle.AimCamera(LocalPlayer())
							end,
						}
					)
				end
			end
			return tbl
		end

		local function populate_enemies()
			local tbl = {}
			for key, ent in pairs(battle.CurrentEnemies) do
				if battle.IsInBattle(ent) then
					table.insert(tbl,
						{
							str = ent:IsPlayer() and ent:GetName() or ent:GetClass():gsub("npc_", ""):gsub("_", " "),
							callback = function()
								RunConsoleCommand("battle_select_enemy", ent:EntIndex())
								battle.selected_menu = main_menu
							end,
							hover = function()
								battle.AimCamera(ent)
							end,
						}
					)
				end
			end
			return tbl
		end

		main_menu =
		{
			{
				str = "attack",
				callback = function()
					attack_menu = populate_enemies()
					battle.selected_menu = attack_menu
				end,
			},
			{
				str = "items",
				callback = function()
					item_menu = populate_items()
					battle.selected_menu = item_menu
				end,
			}
		}

		item_menu = {}

		battle.selected_menu = main_menu

		local selected = 1
		local last = 0

		local function calc_input()
			if last > RealTime() then return end

			if input.IsKeyDown(KEY_UP) or input.IsKeyDown(KEY_W) or input.IsKeyDown(KEY_A) then
				selected = math.Clamp(selected - 1, 1, #battle.selected_menu)
				if battle.selected_menu[selected] and battle.selected_menu[selected].hover then
					battle.selected_menu[selected].hover()
				end
				last = RealTime() + 0.1
			elseif input.IsKeyDown(KEY_DOWN) or input.IsKeyDown(KEY_S) or input.IsKeyDown(KEY_D) then
				selected = math.Clamp(selected + 1, 1, #battle.selected_menu)
				if battle.selected_menu[selected] and battle.selected_menu[selected].hover then
					battle.selected_menu[selected].hover()
				end
				last = RealTime() + 0.1
			elseif input.IsKeyDown(KEY_ENTER) or input.IsMouseDown(MOUSE_LEFT) then
				if battle.selected_menu[selected] then
					battle.selected_menu[selected].callback()
					selected = 1
					if battle.selected_menu[selected] and battle.selected_menu[selected].hover then
						battle.selected_menu[selected].hover()
					end
					last = RealTime() + 0.2
				end
			elseif input.IsKeyDown(KEY_BACKSPACE) or input.IsMouseDown(MOUSE_RIGHT)then
				battle.selected_menu = main_menu
				selected = 1
				last = RealTime() + 0.1
			end
		end

		local mat_cursor = Material("vgui/minixhair")

		local function draw_main_menu(x,y)
			if not battle.selected_menu then
				battle.selected_menu = main_menu
				attack_menu = populate_enemies()
			end
			calc_input()

			surface.SetTextColor(255, 255, 255, 255)
			for i=1, 3 do
				local data = battle.selected_menu[i+math.max(selected, 4)-4]
				if data then
					draw_text(data.str, x, y, "tablarge", 0.5, (i-2), PAD)
				end
			end
			surface.SetMaterial(mat_cursor)
			surface.DrawTexturedRect(x+(PAD/4), y+(select(2, surface.GetTextSize("W"))*(math.Clamp(selected, 1, 3)-0.5)), PAD, PAD)
		end

		function battle.PostRenderVGUI()
			local players = battle.CurrentPlayers
			local enemies = battle.CurrentEnemies
			if players and enemies then
				gui.EnableScreenClicker(true)

				local w = PAD*32
				local h = #players == 1 and PAD*4.5 or ((#players)*PAD*2.3)
				local x = ScrW() - ((ScrW() * 0.5) + (w*0.5))
				local y = ScrH() - h

				local x2 = x+(w/2.5)*1.5
				local w2 = w/2.5

				surface.SetDrawColor(64, 64, 64, 255)
				surface.DrawRect(x, y, w, h)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawOutlinedRect(x, y, w2, h)
				surface.DrawOutlinedRect(x2, y, w2, h)

				local x3 = x2-w2*0.5
				local w3 = w2*0.5

				draw_main_menu(x3, y)
				surface.DrawOutlinedRect(x3, y, w3, h)

				local right = PAD*2

				for key, ply in pairs(players) do
					if not ply:IsValid() then
						table.remove(players, key)
						continue
					end
					key = key - 1
					key = key * 1.5
					surface.SetTextColor(255, 255, 255, battle.IsAlive(ply)and 255 or 50)
					local x,y = draw_text(ply:IsPlayer() and ply:GetName() or ply:GetClass(), x, y+(PAD/2), "trebuchet20", 0, key)
					draw_hp(x2, y, ply)
					draw_time(x2+(PAD*(PAD/2)), y, ply)
				end

				surface.SetTextColor(255, 255, 255, 255)
				draw_text("NAME", x, y, "budgetlabel", 0, -0.5, PAD)
				draw_text("HP", x2, y, "budgetlabel", 0, -0.5, PAD)
				draw_text("TIME", x2, y, "budgetlabel", 8, -0.5, PAD)

				--surface.DrawLine(x, y, )
			end

			battle.DrawDamage()
		end

		function battle.HUDShouldDraw(name)
			return name == "CHudGMod"
		end

		do -- hit
			battle.damage_texts = {}

			local function low_health(self)
				local max = battle.GetEntityVar(self, "hp_max") or 100
				local cur = battle.GetEntityVar(self, "hp") or 100
				local per = (cur/max) * 200
				if per > 50 then
					self:DrawModel()
				return end

				local inv_per = -per+50

				self:DrawModel()

				render.SetBlend((CurTime()*inv_per)%1 > 0.5 and 1 or 0)
					render.SetColorModulation(inv_per/3,1,1)
						self:DrawModel()
					render.SetColorModulation(1,1,1)
				render.SetBlend(1)

				if per < 20 then
					self.cs_sound = self.cs_sound or CreateSound(self, "weapons/explode5.wav")
					self.cs_sound:PlayEx(100, 50)
					self.i = (self.i or 0) + 1
					if self.i%10 == 2 then
						local ef = EffectData()
						ef:SetOrigin(self:GetPos()+(VectorRand()*self:BoundingRadius()))
						util.Effect("HelicopterMegaBomb", ef)
						self.cs_sound:Stop()
					end
				end
			end

			function battle.DrawDamage()
				local data = battle.current_text
				if data then
					if data.ent:IsValid() and data.ent:IsNPC() then
						local origin = data.real_pos
						if data.ent:IsValid() and data.ent:IsNPC() then
							origin = (data.ent:EyePos() + Vector(0,0,data.ent:BoundingRadius()/2)):ToScreen()
						end

						surface.SetFont("HUDNumber5")
						surface.SetTextColor(255,255,255, 255)
						local w,h = surface.GetTextSize(data.max_str)
						surface.SetTextPos(origin.x - (w * 0.5), origin.y - (h * 0.5))
						surface.DrawText(data.max_str)
					end
				end

				for key, data in pairs(battle.damage_texts) do
					local pos = data.real_pos

					if data.ent:IsValid() then
						pos = data.ent:LocalToWorld(data.local_pos):ToScreen()
					end

					surface.SetFont("HUDNumber5")
					surface.SetTextColor(data.dif_color.r, data.dif_color.g, data.dif_color.b, ((data.life/255)^0.5)*255)
					surface.SetTextPos(data.pos.x + pos.x, data.pos.y + pos.y)
					surface.DrawText(math.Round(math.min((-(data.life/255)+1)*4, 1)*tonumber(data.dif_str)))

					if data.life < 100 then
						data.pos.x = data.pos.x + (data.vel.x * FrameTime() * 100)
						data.pos.y = data.pos.y + (data.vel.y * FrameTime() * 100)
					end

					data.life = data.life - (FrameTime() * 200)
					if data.life < 0 then
						table.remove(battle.damage_texts, key)
					end
				end
			end

			function battle.ShowDamage(ent, amt, pos, cur, max)
				if not ent:IsPlayer() and cur/max < 50 then ent.RenderOverride = low_health end

				amt = math.Round(amt, 2)

				local id = table.insert(battle.damage_texts,
					{
						pos = {x=0,y=0},
						ent = ent,
						real_pos = ent:GetPos(),
						local_pos = pos,
						max_str = max > 0 and string.format("%d/%d", cur, max) or "",
						dif_str = amt == 0 and 0 or amt > 0 and string.format("-%s", amt) or string.format("+%s", -amt),
						dif_color = amt == 0 and color_white or amt > 0 and Color(255,50,50) or Color(50,255,50),
						vel = Vector(0,-1),
						life = 255,
					}
				)

				battle.current_text = battle.damage_texts[id]

				if not ent.battle_prev_color and not ent.battle_prev_mat then
					ent.battle_prev_color = {ent:GetColor()}
					ent.battle_prev_mat = ent:GetMaterial()

					ent:SetColor(255, 150, 0, 255)
					ent:SetMaterial("models/shiny")
					timer.Simple(FrameTime(), function()
						if ent:IsValid() and ent.battle_prev_color and ent.battle_prev_mat then
							ent:SetColor(unpack(ent.battle_prev_color))
							ent:SetMaterial(ent.battle_prev_mat)

							ent.battle_prev_color = nil
							ent.battle_prev_mat = nil
						end
					end)
				end
			end

			usermessage.Hook("battle_damage", function(umr)
				local ent = umr:ReadEntity()
				local pos = umr:ReadVector()
				local amt = umr:ReadFloat()
				local cur = umr:ReadLong()
				local max = umr:ReadLong()

				if ent:IsValid() then
					battle.ShowDamage(ent, amt, pos, cur, max)
				end
			end)
		end
	end

	if SERVER then

		function battle.ShowHitDamage(ent, dmginfo)
			local rp = RecipientFilter()

			for key, ply in pairs(player.GetAll()) do
				if battle.IsInBattle(ply) then
					rp:AddPlayer(ply)
				end
			end

			umsg.Start("battle_damage", rp)
				umsg.Entity(ent)
				umsg.Vector(ent:WorldToLocal(dmginfo:GetDamagePosition()))
				umsg.Float(dmginfo:GetDamage())
				umsg.Long(ent:Health())
				umsg.Long(ent:GetMaxHealth())
			umsg.End()
		end

	end
end

if SERVER then -- move

	battle.moving_players = {}

	function battle.Move(ply, mov)
		if battle.IsInBattle(ply) then
			local data = battle.moving_players[ply:UniqueID()]
			if data then
				local origin = mov:GetOrigin()
				local pos = data.pos

				if IsEntity(pos) then
					pos = data.pos:EyePos()
				end

				ply.battle_origin = ply.battle_origin or mov:GetOrigin()
				ply.battle_origin = LerpVector(math.Clamp(data.speed * FrameTime(), 0, 1), ply.battle_origin, pos)
				mov:SetOrigin(battle.GetFloorPos(ply.battle_origin, ply))
				ply.battle_moving = true

				local dist = (origin - pos):Length2D()

				if dist < data.tolerance then

					if not IsEntity(data.pos) then
						mov:SetOrigin(data.pos)
					end

					ply.battle_moving = nil
					battle.moving_players[ply:UniqueID()] = nil

					mov:SetVelocity(vector_origin)

					if data.callback then
						data.callback(ply)
					end
				end
			else
				local others = table.Copy(battle.GetEntityVar(ply, "players"))
				if others then
					table_RemoveValue(others, ply)
					local center = battle.GetCenterOf(others)
					if ply:GetPos():Distance(center) > 1000 then
						ply:SetPos(center + (VectorRand() * Vector(100,100,0)))
					end
					mov:SetVelocity(vector_origin)
				end
			end
			ply:DropToFloor()
			ply:SetMoveType(MOVETYPE_NONE)

			--end
			return true
		end
	end
	hook.Add("Move", "battle", battle.Move)

	function battle.MoveEntity(ply, pos, tolerance, callback, speed)
		speed = speed or 1

		if IsEntity(pos) and not tolerance then
			tolerance = pos:BoundingRadius()
		end

		battle.moving_players[ply:UniqueID()] =
		{
			ply = ply,
			pos = pos,
			speed = 5 * speed,
			callback = callback,
			tolerance = tolerance or 20
		}
	end

	function battle.AllowDamage(ent)
		battle.__allow_damage = ent
	end

	function battle.TriggerAttack(ply, ent)
		local T = type(ply)
		if T == "Player" then
			local wep = ply:GetActiveWeapon()
			if wep:IsValid() then
				if wep.PrimaryAttack then

					battle.AllowDamage(ply)
						ply:SetEyeAngles((battle.GetHitPos(ent, wep) - ply:EyePos()):Angle())
						wep:SetClip1(100)
						wep:PrimaryAttack()
					battle.AllowDamage()

					if wep.Primary.Automatic then
						timer.Create("battle_trigger_attack_" .. ply:EntIndex(), 0.1, 5, function()
							battle.AllowDamage(ply)
								ply:SetEyeAngles((battle.GetHitPos(ent, wep) - ply:EyePos()):Angle())
								wep:SetClip1(100)
								wep:PrimaryAttack()
							battle.AllowDamage()
						end)
					end
				else
					battle.AllowDamage(ply)
					if ply:IsBot() then
						RunConsoleCommand("bot_attack", "1")
					else
						ply:ConCommand("+attack")
					end
					timer.Simple(0.1, function()
						if ply:IsBot() then
							RunConsoleCommand("bot_attack", "0")
						else
							ply:ConCommand("-attack")
						end
						battle.AllowDamage()
					end)
				end
			end
		elseif T == "NPC" then

		end
	end

	function battle.MoveBackToStance(ply, callback)
		if battle.IsInBattle(ply) then
			local a = battle.GetEntityVar(ply, "players")
			local b = battle.GetEntityVar(ply, "enemies")
			if a and b then	
				local radius = battle.GetEntityVar(ply, "enemy_radius") or 80
				
				local pos

				if #a > 1 then
					local a_center = battle.GetFloorPos(battle.GetCenterOf(a)) + Vector(math.random() > 0.5 and -radius or radius, math.random() > 0.5 and -radius or radius, 0)
					local b_center = battle.GetFloorPos(battle.GetCenterOf(b)) + Vector(math.random() > 0.5 and -radius or radius, math.random() > 0.5 and -radius or radius, 0)

					pos = a_center
					if a_center:Distance(b_center) < 120 then
						pos = a_center + ((a_center - b_center) * Vector(2,2,0))
					end
					if not util.IsInWorld(pos) then
						pos = battle.GetFloorPos(VectorRand()*Vector(50,50,0))
					end
				elseif #a == 1 then
					local a = select(2, next(a))
					local b = select(2, next(b))
					
					if IsValid(a) and IsValid(b) then
						
						pos = battle.GetFloorPos(battle.GetCenterOf({a, b}))
						if a:GetPos():Distance(b:GetPos()) < 120 then
							pos = a:GetPos() + ((a:GetPos() - b:GetPos()) * Vector(2,2,0))
						end
						if not util.IsInWorld(pos) then
							pos = battle.GetFloorPos(VectorRand() * Vector(50,50,0))
						end
					else
						print("but somethings wrong with this house")
						print(a,b)
					end
				end

				if pos then
					battle.MoveEntity(ply, pos, nil, callback)
				end
			end
		end
	end

	function battle.SetTargetEntity(ply, ent)
		if battle.IsInBattle(ent) then
			battle.SetEntityVar(ply, "target_ent", ent, true)
		end
	end

	function battle.GetTargetEntity(ply)
		return battle.GetEntityVar(ply, "target_ent")
	end

	function battle.AttackEntity(ply, ent, critical)
		if ply:IsValid() and battle.IsInBattle(ply) and battle.IsInBattle(ent) and not battle.GetEntityVar(ply, "wait") then
			ply.battle_busy = true
			battle.SetEntityVar(ply, "critical", critical)
			if critical then
				battle.BroadcastEvent("CameraSlideEntity", ply)
			end
			local wep = ply:GetActiveWeapon()
			if wep:IsValid() then
				battle.SetTargetEntity(ply, ent)
				local hold_type = wep:GetHoldType()
				if hold_type == "melee" or hold_type == "melee2" then
					timer.Simple(critical and 2.5 or 0, function()
						if critical then battle.BroadcastEvent("CameraSlideEntity", ent, 1) end
						battle.MoveEntity(ply, ent:GetPos(), ent:BoundingRadius()*0.75, function()
							battle.TriggerAttack(ply, ent)
							battle.SetEntityVar(ply, "busy", true)
							timer.Simple(0.3, function()
								battle.SetEntityVar(ent, "being_attacked", NULL, true)
								battle.MoveBackToStance(ply, function()
									battle.SetEntityVar(ply, "busy", false)
									ply.battle_busy = nil
								end)
							end)
						end)
					end)
				else
					timer.Simple(critical and 2.5 or 0, function()
						if critical then
							battle.TriggerAttack(ply, ent)
							battle.TriggerAttack(ply, ent)
						end
						battle.TriggerAttack(ply, ent)
						battle.SetEntityVar(ply, "busy", true)
						timer.Simple(0.3, function()
							battle.MoveBackToStance(ply, function()
								battle.SetEntityVar(ply, "busy", false)
								ply.battle_busy = nil
							end)
						end)
					end)
				end

				battle.SetEntityVar(ent, "being_attacked", ply, true)
				battle.SetEntityVar(ply, "wait", CurTime()+2, true)
			end
		end
	end

	function battle.ShouldCollide(a, b)
		if
			(a.battle_teamid and b.battle_teamid and a.battle_teamid == b.battle_teamid) or
			(a.battle_busy and b:IsNPC())-- or (b.battle_busy and a:IsNPC())) -- need to be able to shoot b (a requests to shoot b) mhmm
		then
			return false
		end
	end
	--ghook.Add("ShouldCollide", "battle", battle.ShouldCollide)
end

if SERVER then -- cmds
	function battle.SelectWeapon(ply, class_name)
		if battle.IsInBattle(ply) then
			ply:SelectWeapon(class_name)
		end
	end
	concommand.Add("battle_select_weapon", function(ply, _, args)
		battle.SelectWeapon(ply, args[1])
	end)

	function battle.SelectEnemy(ply, ent)
		if battle.IsInBattle(ply) then
			battle.SetTargetEntity(ply, ent)
			battle.AttackEntity(ply, ent, math.random() > 0.94)
		end
	end
	concommand.Add("battle_select_enemy", function(ply, _, args)
		battle.SelectEnemy(ply, Entity(tonumber(args[1])))
	end)
end

if CLIENT then
	local modify_bones = function(s)
		local pos = s:EyePos()
		for i=1, s:GetBoneCount() do
		local mat = s:GetBoneMatrix(i)

		if mat then



		mat:Scale(Vector()*3.5)
		--mat:SetTranslation(pos)



		--s:SetBonePosition(i, pos, Angle(0,0,0))
		s:SetBoneMatrix(i, mat)

		end

		end
	end

	timer.Create("battle_monk", 0.1, 0, function()
		for key, val in pairs(ents.FindByClass("npc_monk")) do
			if val:GetNWBool("battle_monk") then
				val.BuildBonePositions = modify_bones
			end
		end
	end)
end

if SERVER then

	function battle.CreateMonkBoss(pos)
		local ent = ents.Create("npc_monk")
		ent:SetPos(pos)
		ent:Spawn()
		ent:SetNWBool("battle_monk", true)
		ent:SetHealth(1000)
		ent:SetMaxHealth(1000)
		ent:Give("weapon_annabelle")
		timer.Simple(7, function()
			for i=1, 10 do ent:EmitSound("vo/ravenholm/cartrap_iamgrig.wav", 100, 70) end
			battle.BroadcastEvent("StartMusic", "http://www.youtube.com/watch?feature=player_detailpage&v=fH5QcBC0G28")
		end)
		return ent
	end

end

if SERVER then
	for _, ent in pairs(player.GetAll()) do
		battle.ClearEntityVars(ent)
	end
	print("hi")
else
	battle.OnEnd()
	easylua.PrintOnServer("hi")
end
