local segments
local numCorners

local bWidth = 1
local bTexCoord = 1
local bColor = Color(255,255,255,255)

function render.StartBeam3D(corners)

	numCorners = math.max(corners or 3,3)

	segments = {}
end

function render.AddBeam3D(pos,width,texCoord,color)

	segments[#segments+1] = {pos=pos,width=width or bWidth,texCoord=texCoord or bTexCoord,color=color or bColor}
end

function render.EndBeam3D()

	local rings = {}
	
	for i=1,#segments-1 do
	
		local pos = segments[i].pos
		local nextPos = segments[i+1].pos
		
		local dir = (nextPos-pos):GetNormal()
		
		rings[i] = {}
		
		for j=1,numCorners do
		
			local p = dir:Angle()
			
			p:RotateAroundAxis(p:Forward(),360*j/numCorners)
			
			p = pos+p:Right()*segments[i].width
			
			rings[i][j] = p
		end		
		
		debugoverlay.Line(pos,nextPos,RealFrameTime())
	end
	
	mesh.Begin(MATERIAL_QUADS,#segments*numCorners)
	
	for i=1,#segments-2 do
	
		local ring = rings[i]
		local nextRing = rings[i+1]
		
		local t = segments[i+1].texCoord
				
		for j=1,numCorners-1 do
		
			local c = segments[i].color
			local c2 = segments[i+1].color
				
			local p = ring[j]
			local p2 = ring[j+1]
			local p3 = nextRing[j+1]
			local p4 = nextRing[j]
			
			local norm = (p2-p):Cross(p3-p):GetNormal()
			
			mesh.Position(p4)
			mesh.Normal(norm)
			mesh.Color(c2.r,c2.g,c2.b,c2.a)
			mesh.TexCoord(0,0,0)
			mesh.AdvanceVertex()
				
			mesh.Position(p3)
			mesh.Normal(norm)
			mesh.Color(c2.r,c2.g,c2.b,c2.a)
			mesh.TexCoord(0,1,0)
			mesh.AdvanceVertex()
				
			mesh.Position(p2)
			mesh.Normal(norm)
			mesh.Color(c.r,c.g,c.b,c.a)
			mesh.TexCoord(0,1,t)
			mesh.AdvanceVertex()
				
			mesh.Position(p)
			mesh.Normal(norm)
			mesh.Color(c.r,c.g,c.b,c.a)
			mesh.TexCoord(0,0,t)
			mesh.AdvanceVertex()		
			
			debugoverlay.Line(p,p2,RealFrameTime())
			debugoverlay.Line(p2,p3,RealFrameTime())
			debugoverlay.Line(p,p4,RealFrameTime())			
		end
		
		local c = segments[i].color
		local c2 = segments[i+1].color
				
		local p = ring[numCorners]
		local p2 = ring[1]
		local p3 = nextRing[1]
		local p4 = nextRing[numCorners]
			
		local norm = (p2-p):Cross(p3-p):GetNormal()
			
		mesh.Position(p4)
		mesh.Normal(norm)
		mesh.Color(c2.r,c2.g,c2.b,c2.a)
		mesh.TexCoord(0,0,0)
		mesh.AdvanceVertex()
			
		mesh.Position(p3)
		mesh.Normal(norm)
		mesh.Color(c2.r,c2.g,c2.b,c2.a)
		mesh.TexCoord(0,1,0)
		mesh.AdvanceVertex()
			
		mesh.Position(p2)
		mesh.Normal(norm)
		mesh.Color(c.r,c.g,c.b,c.a)
		mesh.TexCoord(0,1,t)
		mesh.AdvanceVertex()
			
		mesh.Position(p)
		mesh.Normal(norm)
		mesh.Color(c.r,c.g,c.b,c.a)
		mesh.TexCoord(0,0,t)
		mesh.AdvanceVertex()		
			
		debugoverlay.Line(p,p2,RealFrameTime())
		debugoverlay.Line(p2,p3,RealFrameTime())
		debugoverlay.Line(p,p4,RealFrameTime())	
	end
	
	mesh.End()
	
	segments = nil
	numCorners = nil
end

local points = {}

local material = Material("models/shiny")
local entity1 = Entity(206)
local entity2 = Entity(227)

local length = 15--math.max(math.Round((entity1:GetPos() - entity2:GetPos()):Length()/30), 2)

for point = 1, length do
    points[point] = {
		position = entity1:GetPos(),-- + (entity1:GetPos() - entity2:GetPos()):Normalize() * (entity1:GetPos():Distance(entity2:GetPos()) / length) * -point, 
		velocity = Vector(0)
	}
end

--Optimize
local Clamp = math.Clamp
local Max = math.max
local Vector = Vector
local Draw = draw.SimpleText
local FrameTime = FrameTime

hook.Add("PreDrawOpaqueRenderables", "RopePhysics:RenderScreenspaceEffects", function()

	render.SetMaterial(material)
	render.StartBeam3D(20)
		render.AddBeam3D(points[1].position, 0, 0, color_white)
			for point = 1, length do	
				render.AddBeam3D(points[point].position,length-point+math.random()/10,HSVToColor(point/length*360, 1, 1))
			end
		render.AddBeam3D(points[length].position, 0, 0, color_white)
	render.EndBeam3D()
	for point = 1, length do
		local pos = points[point].position:ToScreen()
		Draw(  point,  "ScoreboardText",  pos.x,  pos.y,  color_white,  0,  0 )
	end
	
end)

hook.Add("Think", "RopePhysics:Think", function()
	for point = 1, length do
		local tbl = points[point]
		
		local position1 = points[Clamp(point-1, 1, length)].position - tbl.position
		local magnitude1 = position1:Length()
		local extension1 = magnitude1 - 0.1
		
		local position2 = points[Clamp(point+1, 1, length)].position - tbl.position
		local magnitude2 = position1:Length()
		local extension2 = magnitude2 - 0.1
		
		local velocity = (position1 / Max(magnitude1, 0.0001) * Max(extension1, 0.0001)) + (position2 / Max(magnitude2 or 0, 0.0001) * Max(extension2, 0.0001)) + (Vector(0,0,50) * 0.01)
	
		local frame = FrameTime()
		
		tbl.velocity = tbl.velocity * 0.96 + (velocity * 0.04)
		tbl.position = tbl.position + tbl.velocity
    end

    points[1].position = entity1:GetPos()
    points[1].velocity = Vector(0)
end)