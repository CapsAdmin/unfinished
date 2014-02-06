local ents = {}

local ENT = {}
ENT.__index = ENT

ENT.x = 0
ENT.y = 0
ENT.color = color_white
ENT.vel = Vector(0)
ENT.drag = 0.98
ENT.size = 50
ENT.texture = surface.GetTextureID("sprites/sent_ball.vtf")

local function CreateEntity()
    local ent = setmetatable({}, ENT)
    ent.size = math.random()*200
   -- ent.texture = math.random(1,50)
    ent.drag = ((-(ent.size / 200) + 1) / 100) + 0.98
    table.insert(ents, ent)

    return ent
end

function ENT:SetVelocity(vel)
    self.vel = vel
end

function ENT:SetDrag(drag)
    self.drag = drag
end

function ENT:SetPos(pos)
    self.pos = pos
end

function ENT:SetColor(col)
    self.color = col
end

function ENT:Draw()
    local c = self.color
    surface.SetDrawColor(c.r, c.g, c.b, c.a)
    surface.SetTexture(self.texture)

    surface.DrawTexturedRect(self.pos.x , self.pos.y, self.size, self.size)
end

function ENT:Think(w,h)
    local size = self.size
    self.pos = self.pos + (self.vel * FrameTime())

    self.vel = Vector((-(self.size) + 340) / 10,math.sin(CurTime())*15,0) + (self.vel * self.drag)


    if self.pos.x < 0 then
        self.pos.x = w-1
       -- self.vel.x = -self.vel.x * math.Rand(0.7, 1)
    end
    if self.pos.x > w then
        self.pos.x = 0+1
       -- self.vel.x = -self.vel.x * math.Rand(0.7, 1)
    end
    if self.pos.y < 0 then
        self.pos.y = 1
        self.vel.y = -self.vel.y * math.Rand(0.7, 1)
    end
    if self.pos.y > h then
        self.pos.y = h-1
        self.vel.y = -self.vel.y * math.Rand(0.7, 1)
    end
end

local screen = this
function screen:Draw3D2D(w,h)
    surface.SetDrawColor(10*3,18*3,25*3,255)
    surface.DrawRect(0,0,w,h)

    for key, ent in pairs(ents) do

        ent:SetVelocity(ent.vel + (Vector(math.Rand(-1,1), math.Rand(0, 1)) * -10 * self.size))

        ent:Think(w,h)
        ent:Draw()


    end
end

for i=1, 10 do
    local ent = CreateEntity()
    ent:SetPos(Vector(500,500))
    ent:SetVelocity(VectorRand() * 1000)
    ent:SetColor(Color(10*8,18*8,25*math.Rand(8,16), math.random(50,255)))
end