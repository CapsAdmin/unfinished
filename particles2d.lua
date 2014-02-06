local ENT = this
local size = 1024

local max_size = 5

local count = 1000
local sand = {}

for i=1, count do
	local siz = math.Rand(1,max_size)
    sand[i] =
    {
        pos = {x = size*0.5, y = size*0.5},
        vel = {x = 0, y = 0},
        siz = siz,
		drag = (0.99 - (siz / (max_size * 80))),
    }
end

local drawpixel

do
	local col = {r=0, g=0, b=0, a=0}
	local cache = {}
	local vel
	
	local SetDrawColor = surface.SetDrawColor
	local DrawLine = surface.DrawLine
	local floor = math.floor

	drawpixel = function(data)
		vel = floor(data.vel.x + data.vel.y)
		
		-- cache the color
		col = cache[vel] or HSVToColor(vel, vel, 1)
		cache[vel] = col
		
		SetDrawColor(
			col.r, col.g, col.b,
			255
		)

		DrawLine(
			data.pos.x,
			data.pos.y,

			data.pos.x + data.vel.x * -0.2,
			data.pos.y + data.vel.y * -0.2
		)
	end
end

local new
local function localtoworld(vec, ang)
    new = WorldToLocal(vec, Angle(0), Vector(0), ang)
    new:Rotate(Angle(180,0,0))
    return new.x, new.y
end

local hash_map = {x={},y={}}

local function calc_self_collision(part)
	local x = math.Round(part.pos.x, 2)
	local y = math.Round(part.pos.y, 2)
		
	if hash_map.x[part.last_hash_x] then
		hash_map.x[part.last_hash_x] = false
		hash_map.y[part.last_hash_y] = false
	elseif hash_map.x[x] and hash_map.y[y] then
		part.vel.x = part.vel.x * -0.5
		part.vel.y = part.vel.y * -0.5
	end	
	
	hash_map.x[x] = true
	hash_map.y[y] = true
	
	part.last_hash_x = x
	part.last_hash_y = y
end

local WorldSound = WorldSound
local clamp = math.Clamp
local sqrt = math.sqrt
local random = math.random

local function play_sound(part)
	local len = clamp(sqrt(part.vel.x^2 + part.vel.y^2) + (random() * 0.1), 1, 100)
	if len > 30 then
		WorldSound("physics/flesh/flesh_bloody_impact_hard1.wav", ENT:GetPos(), len, 50 + math.random(1, 10) + (((-part.siz / max_size) + 1) * 200) )
	end
end

local function calc_collision(part)
	if part.pos.x - part.siz < 0 then
		play_sound(part)
		part.pos.x = part.siz
		part.vel.x = part.vel.x * -part.drag
	end
	
	if part.pos.x + part.siz > size then
		play_sound(part)
		part.pos.x = size - part.siz
		part.vel.x = part.vel.x * -part.drag
	end
	
	if part.pos.y - part.siz < 0 then
		play_sound(part)
		part.pos.y = part.siz
		part.vel.y = part.vel.y * -part.drag
	end
	
	if part.pos.y + part.siz > size then
		play_sound(part)
		part.pos.y = size - part.siz
		part.vel.y = part.vel.y * -part.drag
	end
end

local delta
local ext_vel_x, ext_vel_y 
local rand = math.Rand

local function DrawScreen()
    surface.SetDrawColor(50,50,50,255)
    surface.DrawRect(0,0,size,size)

	-- external velocity
	ext_vel_x, ext_vel_y = localtoworld(ENT:GetVelocity(), ENT:GetAngles())
	ext_vel_x = ext_vel_x * 0.3
	ext_vel_y = ext_vel_y * 0.3
	
	-- gravity
	local grav = ENT:WorldToLocalAngles(physenv.GetGravity():Angle()):Up() * 5
	ext_vel_x = ext_vel_x + grav.y
	ext_vel_y = ext_vel_y + grav.x
		
	delta = FrameTime() * 5
	
    for i, part in pairs(sand) do
		-- random velocity for some variation
        part.vel.x = part.vel.x + ext_vel_x + rand(-2,2)
        part.vel.y = part.vel.y + ext_vel_y + rand(-2,2)
		
		-- velocity
        part.pos.x = part.pos.x + (part.vel.x * delta)
        part.pos.y = part.pos.y + (part.vel.y * delta)
		
		-- friction
        part.vel.x = part.vel.x * part.drag
        part.vel.y = part.vel.y * part.drag
						
		-- collision
		calc_collision(part)
		
		-- collision with other particles (buggy)
		--calc_self_collision()

        drawpixel(part)
    end
end

function ENT:RenderOverride()
	self:DrawModel()
    cam.Start3D2D(self:GetPos() + self:GetRight() * -25 + self:GetForward() * -25 + self:GetUp() * 2, self:GetAngles(), 0.048)
		DrawScreen()
    cam.End3D2D()
end

ENT:SetRenderMode(1)