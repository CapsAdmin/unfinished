for k,ply in pairs(player.GetAll()) do
	for k,v in pairs(v:GetTable()) do
		if k:find("cc2_") then
			ply[k] = nil
		end
	end
end

local print = function(...) print(...) epoe.Print(...) end

local function GetHeadPosAng(ply)

	if not ply:Alive() then ply = ply:GetRagdollEntity() end
	
	if not ply.cc2_head or ply.cc2_last_mdl ~= ply:GetModel() then
		for i = 0, ply:GetBoneCount() do
			local name = ply:GetBoneName(i):lower()
			if name:find("head") then
				ply.cc2_head = i
				ply.cc2_last_mdl = ply:GetModel()
				print(name)
				break
			end
		end
	end
		
	local pos, ang = ply.cc2_head and ply:GetBonePosition(ply.cc2_head)
	
	return pos or ply:EyePos(), ang or ply:EyeAngles()
end

local cur_txt = ""

local smooth_origin = Vector(0,0,0)
local smooth_angles = Vector(0,0,0)
local target_player = NULL

hook.Add("OnPlayerChat", "cc2", function(ply, str)
	local selforigin = GetHeadPosAng(ply)

	if selforigin:Distance(GetHeadPosAng(ply)) < 1500 then
		target_player = ply
		cur_txt = str
	end
end)

local function CalcView(ply)
	
	local selforigin = GetHeadPosAng(ply)
	local origin = Vector(0, 0, 0)
	local count = 0
	local players = {}
		
	for key, ent in pairs(player.GetAll()) do
		if selforigin:Distance(GetHeadPosAng(ent)) < 1500 then
			origin = origin + GetHeadPosAng(ent)
			count = count + 1
			table.insert(players, ent)
		end
	end

	if count > 0 then
		origin = origin / count
	else
		origin = selforigin
	end
		
	local targetorigin = GetHeadPosAng(target_player:IsValid() and target_player or players[1])
	
	origin = LerpVector(0.001, targetorigin, origin)
		
	local side = (origin - targetorigin):Angle():Forward() * 200
	
	local delta = FrameTime() * 4
	
	smooth_origin = smooth_origin + (((origin + side) - smooth_origin) * delta)
	smooth_angles = smooth_angles + (((origin - (origin + side)) - smooth_angles) * delta)

	return 
	{
		origin = smooth_origin,
		angles = smooth_angles:Angle(),
		fov = 15,
	}
end

local amount = 200
local font_name = "cc2_chat_font"
	
surface.CreateFont(
	font_name, 
	{
		font 		= "Tahoma",
		size 		= 30,
		weight 		= 800,
		antialias 	= true,
		additive 	= true,
	} 
)

local function RenderScreenspaceEffects()
	surface.SetDrawColor(0, 0, 0, 255)

	surface.DrawRect(0, -1, ScrW(), amount)
	surface.DrawRect(0, ScrH()-amount+1, ScrW(), amount)
	
	
	surface.SetFont(font_name)
	surface.SetTextColor(255, 255, 255, 255)
	local w,h = surface.GetTextSize(cur_txt)
	surface.SetTextPos((ScrW() / 2) - w/2, ScrH() - h/2 - (amount / 2))
	surface.DrawText(cur_txt)
end

local function HUDShouldDraw() return false end
local function ShouldDrawLocalPlayer() return true end
local function ChatTextChanged(str) if str ~= "" then LocalPlayer().coh_msg = str end end
local old = {}

concommand.Add("cc2", function(ply, _, args)
	if args[1] == "1" then
		for k,v in pairs(hook.GetTable().CalcView) do
			hook.Remove("CalcView",k)
			old[k] = v
		end

		hook.Add("HUDShouldDraw", "cc2", HUDShouldDraw)
		hook.Add("ShouldDrawLocalPlayer", "cc2", ShouldDrawLocalPlayer)
		hook.Add("RenderScreenspaceEffects", "cc2", RenderScreenspaceEffects)
		hook.Add("CalcView", "cc2", CalcView)
		hook.Add("ChatTextChanged", "cc2", ChatTextChanged)
	else 
		for k,v in pairs(old) do
			hook.Add("CalcView", k, v)
		end

		hook.Remove("HUDShouldDraw", "cc2")
		hook.Remove("ChatTextChanged", "cc2")
		hook.Remove("ShouldDrawLocalPlayer", "cc2")
		hook.Remove("RenderScreenspaceEffects", "cc2")
		hook.Remove("CalcView", "cc2")
	end
end)

if LocalPlayer() == me then
	RunConsoleCommand("cc2")	
	timer.Simple(0.1, function()
		RunConsoleCommand("cc2", "1")	
	end)
end