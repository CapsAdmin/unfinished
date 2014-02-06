local ENT = Entity(52) or this
local res = 32
function ENT:RenderOverride()
	local t = UnPredictedCurTime()
	res = math.floor(t*0.5%32)
	for i=1, 360 / res do
		i = i * res
		self:SetModelScale(Vector(1,2,2)*5)
		self:SetRenderAngles(Angle(t+i, self:GetAngles().y, t*res))
		self:SetupBones()
		render.SetColorModulation(math.sin(t+i+1)+1, math.cos(t+i+2)+1, math.sin(t+i+5)+1)
		self:DrawModel()
		self:SetRenderAngles()
	end
end