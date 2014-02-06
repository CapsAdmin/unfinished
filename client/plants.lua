local emitter = ParticleEmitter(vector_origin)

local hair_count = 150
local origin = there

local emitter = ParticleEmitter(origin)

hairs = {}

function CreateFungi(origin, normal, color)
	normal = normal:Normalize()
	
	local size = math.Rand(0.2, 0.9)
	local length = ((size - 0.4) + 1) ^ 8
	
	local pos = AngleRand():Forward() * 2
	
	table.insert(
		hairs,
		{
			normal = normal,
			origin = origin,
			
			startpos = origin + (pos * Vector(1,1,0)),
			endpos = origin + (normal * length * 0.5),
			
			pos = origin + (normal * length),
			
			vel = Vector(0,0,0),
			drag = size * 0.9,
			size = ((size - 0.45) * 40) ^ 1.2,
			color = color or HSVToColor(length * 1.5, 0.25, 1),
			
			life = 1,
			growth = 0,
		}
	)
end

for i=1, 200 do	
	local data = util.QuickTrace(caps:EyePos(), VectorRand()*100, me)
	
	if data.HitWorld then
		CreateFungi(data.HitPos, data.HitNormal, HSVToColor(((data.HitNormal.x+data.HitNormal.y+data.HitNormal.z)/3) * 360, 0.15, 1))
	end
end


local function emit(data, vel, grav, siz)
	local particle = emitter:Add("particle/Particle_Glow_04_Additive", data.pos)
	if particle then
		local col = HSVToColor(math.random()*30, 0.1, 1)
		particle:SetColor(data.color.r, data.color.g, data.color.b, 266)

		particle:SetVelocity(vel or data.vel)

		particle:SetDieTime((math.random()+4)*3)
		particle:SetLifeTime(0)

		particle:SetAngles(AngleRand())
		particle:SetStartSize((siz or (math.random()+1)*2) * data.size * 0.1)
		particle:SetEndSize(0)

		if not grav then
			particle:SetStartAlpha(0)
			particle:SetEndAlpha(255)
			particle:SetAirResistance(500)
		else
			particle:SetStartAlpha(150)
			particle:SetEndAlpha(0)
			particle:SetStartLength(5*data.size* 0.1)
		end

		particle:SetGravity(grav or (VectorRand() * 10))
		particle:SetCollide(true)
		
		particle:SetCollideCallback(function(part, pos, normal)
			if math.random() > 0.9 then
				local h,s,v = ColorToHSV(data.color)
				CreateFungi(pos, normal, HSVToColor(h + math.random(20), s, v))
			end
		end)
	end
end

hook.Add("FairyParticleCollide", 1, function(ent, part, pos, normal)
	if math.random() > 0.5 then
		CreateFungi(pos, normal, Color(part:GetColor()))
	end
	part:SetDieTime(0)
	part:SetLifeTime(0)
end)

local heatwave = Material("sprites/heatwave")
local mat = Material("particle/Particle_Glow_04_Additive")
local mat_laser = Material("trails/laser")
local mat_ring = Material("particle/particle_sphere")
mdl:SetNoDraw(true)

local data

local ext_vel = vector_origin * 1
local wind = vector_origin * 1
local dist

local frame = 0

local function draw()
    local delta = FrameTime() * 5
    local eye = LocalPlayer():EyePos()
	local time = CurTime()
	
    for key, data in ipairs(hairs) do		
		if frame%3 == 0 then
			wind.x = math.sin(time * data.size * 2)
						
			ext_vel.x = data.pos.x - eye.x
			ext_vel.y = data.pos.y - eye.y
			ext_vel.z = data.pos.z - eye.z
			
			dist = ext_vel:Length2D()
			
			--if math.random() > 0.99 then 
			--	emit(data)
			--end
			
			if dist < 400 then
				if dist < 20 then
					ext_vel = ext_vel:Normalize() * 20
				else
					ext_vel = vector_origin * 1
				end
				
				data.vel.x = data.vel.x + (ext_vel.x + wind.x) + (data.endpos.x - data.pos.x)
				data.vel.y = data.vel.y + (ext_vel.y + wind.y) + (data.endpos.y - data.pos.y)
				data.vel.z = data.vel.z + (ext_vel.z + wind.z) + (data.endpos.z - data.pos.z)
	
				data.vel.x = (data.vel.x * data.drag) * data.growth
				data.vel.y = (data.vel.y * data.drag) * data.growth
				data.vel.z = (data.vel.z * data.drag) * data.growth

				data.pos.x = data.pos.x + (data.vel.x * delta)
				data.pos.y = data.pos.y + (data.vel.y * delta)
				data.pos.z = math.max(data.pos.z + (data.vel.z * delta), data.origin.z + data.size)
			end
		end
		
		if data.growth <= 1 then
			data.growth = math.min(data.growth + (delta * 0.001 * data.size), 1.1)
		else
			data.life = (data.life + delta * 0.000001)  ^ 1.08
			if data.life >= 5 then	
				for i = 1, math.random(20) do
					WorldSound("ambient/water/distant_drip2.wav", data.pos, 160, math.random(100, 200))
					emit(data, (data.normal + VectorRand()) * 100, physenv.GetGravity(), 1)
				end
				table.remove(hairs, key)
				continue
			end
		end
	
		local endpos = Lerp(data.growth, data.startpos, data.pos)
	
		render.SetMaterial(mat_laser)
		render.DrawBeam(data.startpos, endpos, (data.size / 7) * data.growth * 0.25, 1, 1, color_white)
		cam.IgnoreZ(true)
		render.SetMaterial(heatwave)
		render.DrawSprite(
			endpos, 
			
			data.size * 0.4 * data.growth * data.life, 
			data.size * 0.4 * data.growth * data.life, 
			
			data.color
		)
		cam.IgnoreZ(false)
		render.SetMaterial(mat)
		render.DrawSprite(
			endpos, 
			
			data.size * 0.1 * data.growth * data.life, 
			data.size * 0.1 * data.growth * data.life, 
			
			data.color
		)
		
		render.SetMaterial(mat)
		render.DrawSprite(
			endpos, 
			
			data.size * 0.25 * data.growth * data.life, 
			data.size * 0.25 * data.growth * data.life, 
			
			data.color
		)
		
				
		render.SetMaterial(mat_ring)
		render.DrawSprite(
			endpos, 
			
			data.size * data.growth * data.life * 0.25, 
			data.size * data.growth * data.life * 0.25, 
			
			Color(255, 255, 255, 50)
		)
	
    end
	
	frame = frame + 1
end

hook.Add("PostDrawTranslucentRenderables", 1, draw)