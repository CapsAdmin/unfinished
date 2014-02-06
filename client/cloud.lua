/* local smoke = { 
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0007",
	"particle/smokesprites_0008",
	"particle/smokesprites_0009",
	"particle/smokesprites_0010",
	"particle/smokesprites_0012",
	"particle/smokesprites_0013",
	"particle/smokesprites_0014",
	"particle/smokesprites_0015",
	"particle/smokesprites_0016",
}

local function Particle3D(pos, scalex, scaley)
	mesh.Begin(MATERIAL_QUADS,2)	
		mesh.QuadEasy( pos, Vector(0,0,1), scalex, scaley )
		mesh.QuadEasy( pos, Vector(1,0,0), scalex, scaley )
	mesh.End()
end

hook.Add("PostDrawOpaqueRenderables", "Clouds", function()

	local matrix = Matrix()
	matrix:Scale(Vector(8*size,8*size,1)*5000)
	matrix:Translate( vector_origin )
	
	for layer=1,layers do
		render.SetMaterial( material )
		cam.PushModelMatrix( matrix )
			local scale = 1.5-math.abs(layer-layers/2)/(layers/3)*1.5 / 7, 
			mesh.Begin( MATERIAL_QUADS, 100*2 )
					mesh.Color(0,0,0,layer/layers*255)
					local alpha = 255-math.abs(layer-layers/2)/(layers/3)*255
					print(alpha)
					local z = layer/layers*0.02
					mesh.QuadEasy( vector_origin+Vector(0,0,z), Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(1,1,z), Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(0,1,z), Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(1,0,z), Vector(0,0,1), 1, 1 )
					
					mesh.QuadEasy( vector_origin+Vector(-1,1,z), Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(1,-1,z), Vector(0,0,1), 1, 1 )
					
					mesh.QuadEasy( vector_origin+Vector(-1,-1,z), Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(0,-1,z), Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(-1,0,z), Vector(0,0,1), 1, 1 )
			mesh.End( )
		cam.PopModelMatrix( )
	end
end) */

local layers = 100

local materials = {}

for layer=1,layers do
	materials[layer] = {}
	materials[layer].random = Vector(math.Rand(-1,1),math.Rand(-1,1),0) / 400
	materials[layer].material = CreateMaterial("cloud"..layer..CurTime(),"UnlitGeneric",{
		["$basetexture"] = "models/props/cs_office/clouds",
		["$translucent"] = 1,
		["$alpha"] = 1-math.abs(layer-layers/2)/(layers/3)*0.6,
		["$nocull"] = 1,
		["$color"] = Vector(2,2,2),
 		
 		Proxies = {
			TextureScroll = {
				texturescrollvar = "$baseTextureTransform",
				texturescrollrate = 0.02,
				texturescrollangle = 0,
			},
		},
	})
end

local size = 0.4

hook.Add("PostDrawOpaqueRenderables", "Clouds", function()

	local matrix = Matrix()
	matrix:Scale(Vector(8*size,8*size,layers*0.00005)*5000)
	matrix:Translate( vector_origin+Vector(0,0,230) )
	
	for layer=1,layers do
		render.SetMaterial( materials[layer].material )
		cam.PushModelMatrix( matrix )
			local scale = 1.5-math.abs(layer-layers/2)/(layers/3)*1.5 / 7, 
			mesh.Begin( MATERIAL_QUADS, 100*2 )
					mesh.QuadEasy( vector_origin+Vector(0,0,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(1,1,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(0,1,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(1,0,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					
					mesh.QuadEasy( vector_origin+Vector(-1,1,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(1,-1,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					
					mesh.QuadEasy( vector_origin+Vector(-1,-1,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(0,-1,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
					mesh.QuadEasy( vector_origin+Vector(-1,0,layer)+materials[layer].random, Vector(0,0,1), 1, 1 )
			mesh.End( )
		cam.PopModelMatrix( )
	end
end)