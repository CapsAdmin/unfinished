if SERVER and ms then
	require"cvar3"
	all:ReplicateData("sv_cheats", "1")
	all:Cexec("mat_drawwater 0")
	all:Cexec("r_3dsky 0")
	return
end

local asdf =
{
	player.GetByUniqueID(--[[PotcFdk]] "2211883894"),
}

if table.HasValue(asdf, LocalPlayer()) then return end

kingdom = kingdom or {} local kingdom = kingdom

if kingdom.Plants then
	for key, data in pairs(kingdom.Plants) do	
		for key, mdl in pairs(data.models) do
			SafeRemoveEntity(data.models[key])
		end
	end
end

kingdom.Seed = 1

local math_random = math.random
local VectorRand = VectorRand

if false then
	local function R(seed)
		return util.CRC(seed) / (2^32-1)
	end

	function math_random(min, max, extra)
		extra = extra or 0
		
		if not min or not max then
			return R(kingdom.Seed + extra)
		end
		
		return min + (R(kingdom.Seed + extra) * (max-min))
	end

	function VectorRand()
		return Vector(math_random(-1, 1, 1), math_random(-1, 1, 2),math_random(-1, 1, 3))
	end
end
kingdom.Plants =
{
	trees = 
	{
		size = 0.2,
		dontmove = true,
		compare = function(ang) return ang < 0.75 and ang > 0.35 end,
		models = 
		{
			"models/props_foliage/rock_forest01d.mdl",
			"models/props_foliage/rock_forest01a.mdl",
			"models/props_foliage/rock_forest03.mdl",
			"models/props_foliage/rock_forest04.mdl",
		},
	},
	
	spooky =
	{
		chance = 0.5,
		size = 0.2,
		dontmove = true,
		compare = function(ang) return ang < 0.5 end,
		models =
		{
			"models/props_hive/nest_extract.mdl",
			"models/props_hive/nest_lrg_flat.mdl",
			"models/props_hive/nest_med_flat.mdl",
		}
	},
	
	misc = 
	{
		chance = 0.95,
		size = 5,
		height = 5,
		minheight = 7,
		compare = function(ang) return ang > 0.6 end,
		models =
		{
			--"models/props_swamp/shroom_ref_01_cluster.mdl",
			"models/props_swamp/shroom_ref_01.mdl",
		},
	},
		
	--[[bushes = 
	{
		chance = 0.99,
		size = 1,
		height = 1,
		compare = function(ang) return ang > 0.3 end,
		models =
		{
			"models/props_swamp/shrub_03_cluster.mdl",
			"models/props_swamp/shrub_03b.mdl",
			"models/props_swamp/shrub_03c.mdl",
		},
	},]]
		
	ferns =
	{
		chance = 0.99,
		size = 1,
		height = 2, 
		compare = function(ang) return ang > 0.3 end,
		models = 
		{
			"models/props_swamp/fern_01.mdl",
			"models/props_swamp/fern_02.mdl",
			"models/props_swamp/fern_03.mdl",
			"models/props_swamp/fern_04.mdl",
			"models/props_swamp/fern_05.mdl",
			"models/props_swamp/fern_06.mdl",
		}
	},
	
	grass =
	{
		size = 2,
		height = 0.7,
		compare = function(ang) return ang > 0.3 end,
		models = 
		{
			"models/props_swamp/tallgrass_03.mdl",
			"models/props_swamp/tallgrass_04.mdl",
			"models/props_swamp/tallgrass_05.mdl",
			"models/props_swamp/tallgrass_06.mdl",
			"models/props_swamp/tallgrass_07.mdl",
			"models/props_swamp/tallgrass_08.mdl",
		}
	},

	--[[crystals =
	{
		chance = 0.99,
		size = 2,
		compare = function(ang) return ang < 0 end,
		material = "debug/env_cubemap_model",
		models = 
		{
			"models/props_foliage/spikeplant01.mdl",
		}
	},
	
	grey_grass = 
	{
		chance = 0.8,
		size = 2,
		height = 0.5,
		compare = function(ang) return ang > 0.3 end,
		models =
		{
			"models/props_swamp/reeds.mdl",
			"models/props_swamp/cattails_ref01.mdl",
			"models/props_swamp/cattails_ref02.mdl",
		},
	},]]

}

if false then
kingdom.Plants = 
{
	trees = 
	{
		size = 1,
		dontmove = true,
		compare = function(ang) return ang < 0.75 and ang > 0.35 end,
		models = 
		{
			"models/props_halloween/pumpkin_03.mdl",
			"models/props_halloween/pumpkin_02.mdl",
			"models/props_halloween/pumpkin_01.mdl",
		},
	},
	
	spooky =
	{
		chance = 0.9,
		size = 5,
		dontmove = true,
		compare = function(ang) return ang < 0.5 end,
		models =
		{
			"models/props_halloween/smlprop_spider.mdl",
		}
	},
	
	misc = 
	{
		chance = 0.95,
		size = 2,
		minheight = 7,
		compare = function(ang) return ang > 0.6 end,
		models =
		{
			--"models/props_swamp/shroom_ref_01_cluster.mdl",
			"models/props_halloween/candle.mdl",
		},
	},
	
	grass =
	{
		size = 3,
		compare = function(ang) return ang > 0.3 end,
		models = 
		{
			"models/skeleton/skeleton_arm.mdl",
			"models/skeleton/skeleton_arm_L.mdl",
			"models/skeleton/skeleton_arm_L_noskins.mdl",
			"models/skeleton/skeleton_arm_noskins.mdl",
			"models/skeleton/skeleton_leg.mdl",
			"models/skeleton/skeleton_leg_L.mdl",
			"models/skeleton/skeleton_leg_L_noskins.mdl",
			"models/skeleton/skeleton_leg_noskins.mdl",
			"models/skeleton/skeleton_torso.mdl",
			"models/skeleton/skeleton_torso2.mdl",
			"models/skeleton/skeleton_torso2_noskins.mdl",
			"models/skeleton/skeleton_torso3.mdl",
			"models/skeleton/skeleton_torso3_noskins.mdl",
			"models/skeleton/skeleton_torso_noskins.mdl",
			"models/props_mvm/mvm_skeleton_arm.mdl",
			"models/props_mvm/mvm_skeleton_leg.mdl",
		}
	},
}
end

local BOX_FRONT = 0
local BOX_BACK = 1
local BOX_RIGHT = 2
local BOX_LEFT = 3
local BOX_TOP = 4
local BOX_BOTTOM = 5

for key, data in pairs(kingdom.Plants) do
	for key, mdl in pairs(data.models) do
		local ent = ents.CreateClientProp()
		ent:SetModel(mdl)
		ent:Spawn()
		if data.material then
			ent:SetMaterial(data.material)
		end
		ent.mins = ent:OBBMins()
		ent.maxs = ent:OBBMaxs()
		ent.rads = ent:BoundingRadius()
		ent.center = ent.mins - ent.maxs
		
		ent.ldirs = 
		{
			[BOX_FRONT] = ent.center + Vector(0, ent.rads, 0),
			[BOX_BACK] = ent.center + Vector(0, -ent.rads, 0),
			
			[BOX_TOP] = ent.center + Vector(0, 0, ent.rads),
			[BOX_BOTTOM] = ent.center + Vector(0, 0, -ent.rads),
			
			[BOX_LEFT] = ent.center + Vector(ent.rads, 0, 0),
			[BOX_RIGHT] = ent.center + Vector(-ent.rads, 0, 0),
			
		}
		
		data.models[key] = ent
	end
end

local eyepos, eyeang = Vector(0,0,0), Angle(0,0,0) 
hook.Add("RenderScene", "kingdom", function(pos, ang) eyepos = pos eyeang = ang end)

local min_dist = 180
min_dist = min_dist * min_dist

local MAX_DRAW_CALLS = 2048
local PAUSE_RAY = false

do -- raymond
	local scale = 2
	local density = 1.25
	
	local res = 70
	local max = 64
	local max_cache = 1024
	local ray_length = 2048*2
	local box_size = 64
	local forward_amount = 1.25

	kingdom.RayCache = {}

	local _in = {}
	local cache_count = 0
	local ordered = {}
	
	max = math.floor(max)
	res = math.floor(res)
	max_cache = math.floor(max_cache)
	
	function kingdom.SerializePos(pos, _res)
		_res = _res or res
		return string.format("%i%i%i", (pos.x+32000) / res, (pos.y+32000)  / res, (pos.z+32000) / res)
	end
	
	local function VectorRandEx() return Vector(1 + math_random(), 1 + math_random(), 1 + math_random()) end
	
	function kingdom.HandleTraceResults(data)
		if data.HitTexture == "**displacement**" then
			local ang = data.HitNormal:Angle()
			ang:RotateAroundAxis(ang:Right(), 270)
			ang:RotateAroundAxis(data.HitNormal, math_random() * 360)
			data.HitAngles = ang
			
			data.RandomVector = VectorRandEx()
			data.RandomNumber = math_random()
			
			data.Dot = data.HitNormal:GetNormalized():Dot(-physenv.GetGravity():GetNormalized())
			
			data.CenterPos = data.HitPos - (data.Normal * 4)
			data.LightColor = render.GetLightColor(data.CenterPos) * 0.2
			
			data.PixVis = util.GetPixelVisibleHandle()
			data.LastVisible = 0
			data.Alpha = 1
			data.FadeIn = 0
			
			data.ModelInfo = {}
						
			for key, info in RandomPairs(kingdom.Plants) do				
				if (not info.chance or math.random() > info.chance) and info.compare(data.Dot) then
					data.ModelInfo.Entity = info.models[math.random(#info.models)]
					
					local scale = kingdom.BaseScale * (VectorRandEx() * info.size)
											
					if info.height then
						if info.minheight then
							scale.z = info.minheight + (math.random() * info.height)
						else
							scale.z = (math.random() * info.height)
						end
					end
					
					data.ModelScale = scale
					data.ModelRadius = data.ModelInfo.Entity.rads * scale
					
					for k,v in pairs(info) do
						data.ModelInfo[k] = data.ModelInfo[k] or  v
					end
					break
				end
			end
			
			return data
		end
	end
	
	local VectorRand = VectorRand
	local util_TraceLine = util.TraceLine
	local MASK_SOLID_BRUSHONLY = MASK_SOLID_BRUSHONLY
	
	local key
	local data
	local wait = 0
	local dir = Vector()

	function kingdom.GetFields(pos)	
		if PAUSE_RAY then
			return kingdom.RayCache
		end
	
		pos = pos or eyepos
		pos = pos + LocalPlayer():GetVelocity() / 20
				
		key = kingdom.SerializePos(pos)
		
		--kingdom.Seed = (kingdom.Seed + tonumber(kingdom.SerializePos(eyepos, 4)))%10000000
		
		if not util.QuickTrace(pos, Vector(0,0,1000)).Hit then
			pos = pos + Vector(0,0,1000)
			dir = Vector(0,0,-2)
		else
			dir = Vector(0,0,0)
		end
		
		if not kingdom.RayCache[key] and wait < RealTime() then
			for i = 1, max do
				key = kingdom.SerializePos(pos)
				
				if kingdom.RayCache[key] then
					pos = eyepos + VectorRand() * box_size
					continue 
				end
				
				_in.start = pos
				_in.endpos = _in.start + (eyepos-pos):GetNormalized()*0.5 + (VectorRand()+dir) * ray_length
				_in.mask = MASK_SOLID_BRUSHONLY
				
				data = util_TraceLine(_in)
				if data.Hit then
					key = kingdom.SerializePos(data.HitPos)

					if kingdom.HandleTraceResults(data) and not kingdom.RayCache[key] then
						pos = data.HitPos
						kingdom.RayCache[key] = data
					end
				else
					wait = RealTime() + 0.25
					break
				end
			end
		end
				
		return kingdom.RayCache	
	end
end

kingdom.BaseScale = Vector(1, 1, 1) 

local forward = 64
local sway_scale = 2
local brightness = 1

local sway = 0


local util_PixelVisible = util.PixelVisible

local max_dist = 3000
max_dist = max_dist * max_dist

local len
local alpha

local world_min = Vector(7000, -4000, -16000)
local world_max = Vector(12000, 5000, -13000)

local next_calc = 0

function kingdom.CalcVis()
	if 
		(
			eyepos.x < world_min.x or 
			eyepos.y < world_min.y or
			eyepos.z < world_min.z
		)
		or
		(
			eyepos.x > world_max.x or
			eyepos.y > world_max.y or
			eyepos.z > world_max.z
		)
	then
		return false
	end

	local t = RealTime()
	local ply = LocalPlayer()
	
	local w,h = ScrW(), ScrH()

	for key, params in pairs(kingdom.GetFields()) do
		if not params.last_calc or params.last_calc > t then
			len = (eyepos - params.CenterPos):LengthSqr()
			params.last_len = len
		else
			len = params.last_len
		end
		params.last_dist = len
		params.last_calc = t + 0.25
		
		if len > max_dist then
			kingdom.RayCache[key] = nil
		elseif len < min_dist then
			params.Alpha = 1
			params.Visible = true
		else
			alpha = util_PixelVisible(params.CenterPos, params.ModelInfo and params.ModelInfo.ModelRadius or 64, params.PixVis)
			params.Alpha = math.min((-(len / max_dist) + 1)*2 + alpha * 10, 1)
			params.Visible = alpha > 0
		end
	end
	
	return true
end

local render_SetBlend = render.SetBlend
local render_SetLightingOrigin = render.SetLightingOrigin
local render_SetColorModulation = render.SetColorModulation
local render_ResetModelLighting = render.ResetModelLighting
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_SetModelLighting = render.SetModelLighting
local render_GetSurfaceColor = render.GetSurfaceColor

local c
	

function kingdom.Draw()	
	local delta = FrameTime()
	local t = RealTime()
	local ply = LocalPlayer()
	local i = 0
	
	render.SetBlend(1)
	render_SuppressEngineLighting(true)
	
	for key, params in pairs(kingdom.GetFields()) do	
		if params.Visible then
			local data = params.ModelInfo			
			local ent = data.Entity or NULL
			
			if not ent:IsValid() then continue end
			
			-- pos
			ent:SetRenderOrigin(params.HitPos)
			
			-- ang
			local ang = params.HitAngles
			
			if not data.dontmove then
				ang = ang + Angle(0,math.sin(t + params.HitPos.z) * sway_scale,0)
			end
			
			ent:SetRenderAngles(ang)

			-- fade
			if params.Alpha ~= 1 or params.FadeIn ~= 1 then
				params.FadeIn = math.min(params.FadeIn + delta * 4, 1)
				local fade = params.Alpha * params.FadeIn
				local mat = Matrix()
				mat:Scale(params.ModelScale * math.max(fade, 0.75))
				ent:EnableMatrix("RenderMultiply", mat)
				--render_SetBlend(fade)
			else 
				-- scale
				local mat = Matrix()
				mat:Scale(params.ModelScale)
				ent:EnableMatrix("RenderMultiply", mat)
			end
			
			ent:SetupBones()
			
			-- lighting
			render_SetLightingOrigin(params.CenterPos)
			render_ResetModelLighting(
				params.LightColor.r,
				params.LightColor.g, 
				params.LightColor.b
			)
							
			for k, v in pairs(ent.ldirs) do
				params.SurfaceColors = params.SurfaceColors or {}
				c = params.SurfaceColors[k]
				
				if not c then
					c = render_GetSurfaceColor(params.CenterPos, ang:Up() *-5 + params.CenterPos + v * -20)
					c.r = c.r ^ 1.25
					c.g = c.g ^ 1.25
					c.b = c.b ^ 1.25
				end
						
				render_SetModelLighting(
					k, 
					c.r,
					c.g, 
					c.b
				)
				-- sometimes it fails, so let's just use a blank color instead of it going super bright
				if c.r < 2 and c.g < 2 and c.b < 2 then
					params.SurfaceColors[k] = c
				else
					params.SurfaceColors[k] = Vector(1,1,1)
				end
			end
				
			ent:DrawModel()
			
			render.SetColorModulation(brightness,brightness,brightness)
		end
	end
	render_SuppressEngineLighting(false)
	render.SetColorModulation(1,1,1)
end

local draw_method = 1

if draw_method == 1 then
	hook.Add("PostDrawOpaqueRenderables", "kingdom", function(_, b)
		if b == true then return end
		--local frame = FrameNumber()
		--if frame == last_frame then print("skipping!!!!", frame) return end
		
		kingdom.CalcVis()
		kingdom.Draw()
		
		last_frame = frame
	end)
elseif draw_method == 2 then
	SafeRemoveEntity(kingdom.render_node)
	local node = ClientsideModel("error.mdl")
	kingdom.render_node = node
	
	hook.Add("PostDrawOpaqueRenderables", "kingdom", function()
		node:SetPos(eyepos + eyeang:Forward() * 32)
	end)
	
	local last_frame = 0
	function node:RenderOverride()
		local frame = FrameNumber()
		if frame == last_frame then print("skipping!!!!", frame) return end
		if kingdom.CalcVis() then
			kingdom.Draw()
		end
		last_frame = frame
	end
end
