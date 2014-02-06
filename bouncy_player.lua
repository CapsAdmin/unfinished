local ENT = {}

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.Model = Model("models/dav0r/hoverball.mdl")
ENT.ClassName = "bouncy_player"

if CLIENT then
	function ENT:Initialize()
		self:SetModelScale(Vector()*5)
		self:SetMaterial("debug/shiney")
	end
	
	function ENT:Draw()
		local ply = self:GetParent()
		
		if ply:IsPlayer() then
			self:DrawModel()
		end
	end
end
	
if SERVER then
	function ENT:Initialize()
		self:SetModel( self.Model )
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:PhysWake()
	end
	
	function ENT:Think()
		
		self:NextThink(CurTime() + 1)
		return true
	end
end

scripted_ents.Register(ENT, ENT.ClassName, true)

for key, entity in pairs(ents.FindByClass(ENT.ClassName)) do
	table.Merge(entity:GetTable(), ENT)
	--entity:Initialize()
end