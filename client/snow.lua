hook.Add("PlayerFootstep", "snow", function(ply, pos, foot, sound, volume, rf)
	if sound:find("grass") then
		ply:EmitSound(Format("player/footsteps/snow%s.wav", math.random(6)), 60, math.random(95,105))
		return true
	end
end)

if SERVER then return end
module 	( "ms" , package.seeall )

--snow_data = nil
snow_data = snow_data or {}


local LP


local replace = {
	["METASTRUCT_2/GRASS"] = true,
	["GM_CONSTRUCT/GRASS"] = true,
--[[ 	["maps/metastruct_2/metastruct_2/road_6120_8680_-12944"] = true,
	["maps/metastruct_2/metastruct_2/road_-3656_12928_-13216"] = true,
	["maps/metastruct_2/metastruct_2/road_-6332_11456_-13184"] = true,
	["CONCRETE/CONCRETEFLOOR001A"] = true,
	["maps/metastruct_2/tile/tileroof004b_-13744_12784_-13200"] = true,
	["maps/metastruct_2/tile/tileroof004a_-14224_11856_-13216"] = true,
	["maps/metastruct_2/tile/tileroof004a_-14192_12176_-12784"] = true,
	["maps/metastruct_2/metastruct_2/road_-13008_12656_-13104"] = true,
	
	
	
	
	["maps/metastruct_2/tile/tileroof004a_6120_8680_-12944"] = true,
	["maps/metastruct_2/tile/tileroof004b_-14192_12176_-12784"] = true,
	["maps/metastruct_2/tile/tileroof004b_-9035_13056_-13188"] = true,	
	["maps/metastruct_2/metastruct_2/road_-9035_13056_-13188"] = true,	
	["maps/metastruct_2/tile/tileroof004a_-6332_11456_-13184"] = true,	
	["maps/metastruct_2/tile/tileroof004b_6120_8680_-12944"] = true,	 ]]
	
	 
}
local rt = { "roof", "grass", "ceiling" }

if table.Count(snow_data) == 0 then

	local max = 16000
	local grid_size = 768
	local range = max/grid_size

	local pos

 	for x = -range, range do
		x = x * grid_size
		for y = -range, range do
			y = y * grid_size
			for z = -range, range do
				z = z * grid_size
				
				pos = Vector(x,y,z)
				local conents = util.PointContents( pos )
				
				if conents == CONTENTS_EMPTY or conents == CONTENTS_TESTFOGVOLUME then
					local up = util.QuickTrace(pos, vector_up*max*2)
					if up.HitTexture == "TOOLS/TOOLSSKYBOX" or up.HitTexture == "**empty**" then
						table.insert(snow_data, pos)
--[[ 						local down = util.QuickTrace(pos, (vector_up*-1)*max*2)
						if down.Hit then
							local t = down.HitTexture:lower()
							for k,v in pairs(rt) do
								if string.find(t, v) ~= nil then
									replace[t] = true
								end
							end
						end ]]
					end
				end
			end
		end
	end
end

local function FastLength(point)
	return point.x*point.x+point.y*point.y+point.z*point.z
end

draw_these = {}

local emitter = ParticleEmitter(EyePos(), false)

local snow_explode = CreateClientConVar("snow_explode", "0", true, false)

local function SnowCallback(p, hitpos)
	if snow_explode:GetBool() then
		local efdata = EffectData() --Grab base EffectData table
		efdata:SetOrigin(hitpos) --Sets the origin of it to the hitpos of the particle
		efdata:SetStart(hitpos)
		efdata:SetScale(0.2)
		util.Effect("Explosion", efdata) --Create the effect
	end
	p:SetDieTime(0)
end

hook.Add("Think", "snow", function()
	for _, point in pairs(draw_these) do
		if math.random() < 0.95 then continue end
		local particle = emitter:Add("particle/snow", point)
		if (particle) then
			particle:SetVelocity(VectorRand()*100*Vector(1,1,0))
			particle:SetAngles(Angle(math.random(360), math.random(360), math.random(360)))
			particle:SetLifeTime(0)
			particle:SetDieTime(10)
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetStartSize(0)
			particle:SetEndSize(5)
			particle:SetGravity(Vector(0,0,math.Rand(-30, -200)))
			particle:SetCollide(true)
			particle:SetCollideCallback(SnowCallback)
		end
	end
end)

local function CreateSnowLoop(t)
	local iterations = math.min(math.ceil(#snow_data/(1/t)), #snow_data)
	local lastkey = 1
	local lastpos = nil
	local len = 3000^2
	local movelen = 100^2
	local LastLoop = -1
	timer.Create("hide_points", t, 0, function()
		if not IsValid(LP) then
			LP = LocalPlayer()
			if not IsValid(LP) then return end
		end
		local EP = LP:EyePos()+LP:GetVelocity()
		--[[local d = SysTime()-LastLoop
		if LastLoop ~= -1 and d > t+0.1 then
			local nt = t+0.05
			CreateSnowLoop(nt)
			return
		elseif t >= 0.1 and d <= t+0.01 then
			local nt = t-0.05
			CreateSnowLoop(nt)
			return
		end]]
		if lastpos == nil or FastLength(lastpos-EP) > movelen then
			local c = #snow_data
			local r = math.min(iterations, c)
			local completed = false
			for i=1,r do
				local key = lastkey+1
				if key > c then
					completed = true
					lastkey = 1
					break
				end
				local point = snow_data[key]
				local dc = FastLength(point - EP) < len
				if dc and draw_these[key] == nil then
					draw_these[key] = point
				elseif not dc and draw_these[key] ~= nil then
					draw_these[key] = nil
				end
				lastkey = key
			end
			if completed then lastpos = EP end
		end
	end)
end
CreateSnowLoop(0.1)

do
materials = materials or {} local self = materials


materials.Replaced = {}

function materials.ReplaceTexture(path, to)
	check(path, "string")
	check(to, "string", "ITexture", "Material")

	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then

		local typ = type(to)
		local tex

		if typ == "string" then
			tex = Material(to):GetMaterialTexture("$basetexture")
		elseif typ == "ITexture" then
			tex = to
		elseif typ == "Material" then
			tex = to:GetMaterialTexture("$basetexture")
		else return false end

		self.Replaced[path] = self.Replaced[path] or {}	

		self.Replaced[path].OldTexture = self.Replaced[path].OldTexture or mat:GetMaterialTexture("$basetexture")
		self.Replaced[path].NewTexture = tex

		mat:SetMaterialTexture("$basetexture",tex) 

		return true
	end

	return false
end


function materials.SetColor(path, color)
	check(path, "string")
	check(color, "Vector")

	path = path:lower()

	local mat = Material(path)

	if not mat:IsError() then
		self.Replaced[path] = self.Replaced[path] or {}
		self.Replaced[path].OldColor = self.Replaced[path].OldColor or mat:GetMaterialVector("$color")
		self.Replaced[path].NewColor = color

		mat:SetMaterialVector("$color", color)

		return true
	end

	return false
end


function materials.RestoreAll()
	for name, tbl in pairs(self.Replaced) do
		if 
			!pcall(function()
				if tbl.OldTexture then
					materials.ReplaceTexture(name, tbl.OldTexture)
				end

				if tbl.OldColor then
					materials.SetColor(name, tbl.OldColor)
				end
			end) 
		then 
			print("Failed to restore: " .. tostring(name)) 
		end
	end
end
hook.Add('ShutDown','MatRestorer',materials.RestoreAll)

-- Material Extensions / SkyBox modder
local sky = 
{
	["up"]=true,
	["dn"]=true,
	["lf"]=true,
	["rt"]=true,
	["ft"]=true,
	["bk"]=true,
}

local sky_name = GetConVarString("sv_skyname")

for side, path in pairs(sky) do	
	path = "skybox/" .. sky_name .. side
	materials.ReplaceTexture(path, "Decals/decal_paintsplatterpink001")
	--materials.SetColor(path, Vector(1.4, 1, 1)*3)
end

end

for k,v in pairs(replace) do
	materials.ReplaceTexture(k, "NATURE/SNOWFLOOR001A")
end

hook.Add("RenderScreenspaceEffects", "hm", function()
    --DrawToyTown( 2, 200)
	

	local tbl = {}
		tbl[ "$pp_colour_addr" ] = -0.01
		tbl[ "$pp_colour_addg" ] = 0.03
		tbl[ "$pp_colour_addb" ] = 0.10
		tbl[ "$pp_colour_brightness" ] = 0
		tbl[ "$pp_colour_contrast" ] = 1
		tbl[ "$pp_colour_colour" ] = 0.6
		tbl[ "$pp_colour_mulr" ] = 0
		tbl[ "$pp_colour_mulg" ] = 0
		tbl[ "$pp_colour_mulb" ] = 0
	DrawColorModify( tbl )
	
end)