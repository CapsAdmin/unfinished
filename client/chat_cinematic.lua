chatcinematic = chatcinematic or {}
chatcinematic.random_seed = ""
chatcinematic.ActiveHooks = chatcinematic.ActiveHooks or {}

for key, ply in pairs(player.GetAll()) do
	ply.chat_cinematic = false
end

function chatcinematic.RandomSeed(min, max, seed)
	seed = seed or chatcinematic.random_seed
	max = max + 1
	seed = seed .. tostring(max) .. tostring(min)

	return min + (max - min) * (util.CRC(seed)/10000000000)
end

local function HOOK(name)
	hook.Add(name, "chatcinematic_" .. name, chatcinematic[name])
	chatcinematic.ActiveHooks[name] = "chatcinematic_" .. name
end

function chatcinematic.Stop()
	chatcinematic.players = {}
	chatcinematic.active_player = NULL
	for key, val in pairs(chatcinematic.ActiveHooks) do
		hook.Remove(key, val)
	end	
end

function chatcinematic.IsActive()
	return chatcinematic.GetActivePlayer():IsPlayer()
end

do -- players

	function chatcinematic.SetActivePlayer(ply)
		chatcinematic.active_player = ply
	end

	function chatcinematic.GetActivePlayer()
		return chatcinematic.active_player or NULL
	end

	function chatcinematic.CheckPlayer(a)
		return a.chat_cinematic == true
	end
	
	function chatcinematic.AddPlayer(ply)
		ply.chat_cinematic = true
	end
	
	function chatcinematic.RemovePlayer(ply)
		ply.chat_cinematic = false
	end

	function chatcinematic.OnPlayerChat(ply, str)
		if not chatcinematic.CheckPlayer(LocalPlayer()) then return end
		
		chatcinematic.random_seed = str

		if chatcinematic.CheckPlayer(ply) then
			if (ply.last_active_chatcinematic or 0) < CurTime() and (chatcinematic.last_active_chatcinematic or 0) < CurTime() then
				chatcinematic.ChooseRandomCameraPos(ply)
				chatcinematic.SetActivePlayer(ply)

				ply.last_active_chatcinematic = CurTime() + 3
				chatcinematic.last_active_chatcinematic = CurTime() + 1.5
			end
		end
	end

	HOOK("OnPlayerChat")

end

do -- view
	chatcinematic.cam_distance = 200
	chatcinematic.smooth_speed = 2

	chatcinematic.pos_smooth = vector_origin
	chatcinematic.dir_smooth = vector_origin
	chatcinematic.fov_smooth = 0

	chatcinematic.pos_target = vector_origin
	chatcinematic.dir_target = vector_origin
	chatcinematic.fov_target = 75

	chatcinematic.local_camera_pos = vector_origin
	chatcinematic.angle_offset = Angle(0,0,0)
	function chatcinematic.GetEyePos(ply)
		ply = not ply:Alive() and ply:GetRagdollEntity() or ply

		local pos, ang = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1"))
		return pos + ang:Forward() * 2
	end

	function chatcinematic.ChooseRandomCameraPos(ply)
		local prev = chatcinematic.GetActivePlayer()

		if prev ~= ply then
			ply = ply or prev

			if ply:IsPlayer() then
				chatcinematic.local_camera_pos = Vector(chatcinematic.RandomSeed(-1,1)*0.2, chatcinematic.RandomSeed(-1,1)*0.2, chatcinematic.RandomSeed(-1,1)*0.3)
				chatcinematic.angle_offset = Angle(chatcinematic.RandomSeed(-1,1)*2, chatcinematic.RandomSeed(-1,1)*8, chatcinematic.RandomSeed(-1,1))
				chatcinematic.fov_target = chatcinematic.RandomSeed(10, 40)

				chatcinematic.new_angle = true
				chatcinematic.panning_dir = Angle(0,0,0)
				chatcinematic.panning_vel = chatcinematic.RandomSeed(1,3) * chatcinematic.angle_offset.y > 0 and -1 or 1
				chatcinematic.pos_target = nil
			end
		end
	end

	function chatcinematic.GetLocalCameraPos()
		local ply = chatcinematic.GetActivePlayer()

		if ply:IsPlayer() then
			return (ply:GetAimVector() * Vector(1,1,0)) + chatcinematic.local_camera_pos
		end

		return vector_origin
	end

	function chatcinematic.GetWorldCameraPos()
		local middle = vector_origin
		local players = player.GetAll()
		local i = 0
		
		for _, ply in pairs(players) do
			if chatcinematic.CheckPlayer(ply) then
				middle = middle + chatcinematic.GetEyePos(ply)
				i = i + 1
			end
		end

		if middle ~= vector_origin then
			middle = middle / i
		end

		local ply = chatcinematic.GetActivePlayer()

		return LerpVector(0.2, chatcinematic.GetEyePos(ply) + (chatcinematic.GetLocalCameraPos() * (chatcinematic.cam_distance * 0.5)), middle)
	end

	function chatcinematic.CalcSmooth()
		local delta = FrameTime()

		chatcinematic.pos_smooth = chatcinematic.pos_smooth + ((chatcinematic.pos_target - chatcinematic.pos_smooth) * (delta * chatcinematic.smooth_speed))
		chatcinematic.dir_smooth = chatcinematic.dir_smooth + ((chatcinematic.dir_target - chatcinematic.dir_smooth) * (delta * chatcinematic.smooth_speed))
		chatcinematic.fov_smooth = chatcinematic.fov_smooth + ((chatcinematic.fov_target - chatcinematic.fov_smooth) * (delta * chatcinematic.smooth_speed))
	end

	chatcinematic.panning_dir = vector_origin
	chatcinematic.panning_vel = 0

	function chatcinematic.CalcPanning()
		if math.abs(chatcinematic.panning_dir.y) < 5 then
			chatcinematic.panning_dir = chatcinematic.panning_dir + (Angle(0, FrameTime()*chatcinematic.panning_vel, 0))
		end
	end

	local params = {}

	function chatcinematic.CalcView()
		local ply = chatcinematic.GetActivePlayer()

		if ply:IsPlayer() then
			chatcinematic.pos_target = chatcinematic.pos_target or chatcinematic.GetWorldCameraPos()
			chatcinematic.dir_target = chatcinematic.GetEyePos(ply) - chatcinematic.pos_target + chatcinematic.panning_dir

			chatcinematic.CalcSmooth()
			chatcinematic.CalcPanning()

			if chatcinematic.new_angle then
				chatcinematic.pos_smooth = chatcinematic.pos_target
				chatcinematic.dir_smooth = chatcinematic.dir_target
				chatcinematic.fov_smooth = chatcinematic.fov_target

				chatcinematic.new_angle = false
			end

			params.origin = chatcinematic.pos_smooth
			params.angles = chatcinematic.dir_smooth:Angle() + chatcinematic.angle_offset + chatcinematic.panning_dir
			params.fov = chatcinematic.fov_smooth

			return params
		end
	end

	HOOK("CalcView")

	function chatcinematic.ShouldDrawLocalPlayer()
		local ply = chatcinematic.GetActivePlayer()

		if ply:IsPlayer() then
			return true
		end
	end

	HOOK("ShouldDrawLocalPlayer")

	surface.CreateFont("cachatcinematicri", 48, 500, true, false, "subtitle")

	chatcinematic.letterbox_ratio = 2.39 / 1
	chatcinematic.letterbox_color = Color(0, 0, 0, 255)
	chatcinematic.letterbox_vignette = 2
	chatcinematic.letterbox_message = "hi2"
	chatcinematic.letterbox_fade = 255

	function chatcinematic.PreChatSound(data)
		chatcinematic.letterbox_message = data.key
		chatcinematic.letterbox_fade = 255
	end

	HOOK("PreChatSound")

	local grad_up = surface.GetTextureID("gui/gradient_up")
	local grad_down = surface.GetTextureID("gui/gradient_down")

	function chatcinematic.DrawLetterBox()
		local width, height = surface.ScreenWidth(), surface.ScreenHeight()
		local ratio = width / height

		surface.SetDrawColor(chatcinematic.letterbox_color)
		local vx, vy, vw, vh

		if ratio < chatcinematic.letterbox_ratio then
			vw = width
			vh = width / chatcinematic.letterbox_ratio
			vx = (width - vw) / 2
			vy = (height - vh) / 2

			surface.DrawRect(-1, -1, vw, vy)
			surface.DrawRect(-1, vy + vh, vw, height - (vy + vh))
		else
			vw = height * chatcinematic.letterbox_ratio
			vh = height
			vx = (width - vw) / 2
			vy = (height - vh) / 2

			surface.DrawRect(0, 0, vx, vh)
			surface.DrawRect(vx + vw, 0, width - (vx + vw), vh)
		end

		local c = chatcinematic.letterbox_color
		surface.SetDrawColor(c.r, c.g, c.b, c.a*0.8)

		surface.SetTexture(grad_up)
		surface.DrawTexturedRect(vx, vy + vh - vh / chatcinematic.letterbox_vignette, vw, vh / chatcinematic.letterbox_vignette)

		surface.SetTexture(grad_down)
		surface.DrawTexturedRect(vx, vy, vw, vh / chatcinematic.letterbox_vignette)
	end

	function chatcinematic.DrawSubtitles()
		surface.SetFont("subtitle")
		local w, h = surface.GetTextSize(chatcinematic.letterbox_message)
		surface.SetTextPos((ScrW() - w) / 2, (ScrH() - h) * 0.95)
		surface.SetTextColor(Color(255, 255, 255, chatcinematic.letterbox_fade))
		surface.DrawText(chatcinematic.letterbox_message)
		chatcinematic.letterbox_fade = math.Clamp(chatcinematic.letterbox_fade - 1, 0, 255)
	end

	local mat = Material("particle/Particle_Glow_04_Additive")
	local size = 400
	function chatcinematic.RenderScreenspaceEffects()
		if not chatcinematic.IsActive() then return end

		DrawSharpen(1.5, 0.3)


		DrawColorModify({
			["$pp_colour_colour"] = 0.8,
			["$pp_colour_brightness"] = -0.10,
			["$pp_colour_contrast"] = 0.5,
		})

		DrawBloom( 0, 2, 0, 0, 0.15, 0.1, 1, 1, 1 )

		cam.Start2D()
			surface.SetMaterial(mat)
			surface.SetDrawColor(150,150,150,5)
			surface.DrawTexturedRect(-size, -size, ScrW()+size*2, ScrH()+size*2)
		cam.End2D()

		chatcinematic.DrawLetterBox()

		chatcinematic.DrawSubtitles()

		--cam.Start2D()
		--	surface.SetDrawColor(120,110,150,10)
		--	surface.DrawRect(0, 0, ScrW(), ScrH())
		--cam.End2D()

	end

	HOOK("RenderScreenspaceEffects")

	function chatcinematic.HUDShouldDraw(str)
		if not chatcinematic.IsActive() then return end
		if str ~= "CHudWeaponSelection" then
			return false
		end
	end

	HOOK("HUDShouldDraw")

	local emitter = ParticleEmitter(EyePos())
	emitter:SetNoDraw(true)

	function chatcinematic.PostDrawOpaqueRenderables()
		if not chatcinematic.IsActive() then return end

		for i=1, 5 do
			local particle = emitter:Add("particle/Particle_Glow_05", LocalPlayer():EyePos() + VectorRand() * 500)
			if particle then
				local col = HSVToColor(math.random()*30, 0.1, 1)
				particle:SetColor(col.r, col.g, col.b, 266)

				particle:SetVelocity(VectorRand() )

				particle:SetDieTime((math.random()+4)*3)
				particle:SetLifeTime(0)

				local size = 1

				particle:SetAngles(AngleRand())
				particle:SetStartSize((math.random()+1)*2)
				particle:SetEndSize(0)

				particle:SetStartAlpha(0)
				particle:SetEndAlpha(255)

				--particle:SetRollDelta(math.Rand(-1,1)*20)
				particle:SetAirResistance(500)
				particle:SetGravity(VectorRand() * 10)
			end
		end
		emitter:Draw()
	end

	HOOK("PostDrawOpaqueRenderables")
end