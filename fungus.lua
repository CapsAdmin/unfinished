fungus_world_health = {}

easylua.StartEntity("fungus")

ENT.Model = "models/holograms/hq_icosphere.mdl"
ENT.Radius =  8
ENT.MaxSize = 50

function ENT:SetupDataTables()
	self:DTVar("Float", 0, "size")
end

if CLIENT then
	function ENT:Draw()
		self:SetModelScale((self.Radius or self:BoundingRadius()) / Vector() * self.dt.size)
		self:DrawModel()
	end
end

if SERVER then
	for k,v in pairs(ents.FindByClass("fungus")) do SafeRemoveEntity(v) end

    function ENT:Initialize()
		self.FungusChildren = {}

		self:SetModel(self.Model)

		self:SetMoveType(MOVETYPE_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

		self.dt.size = self.MaxSize
    end

	function ENT:RemoveChildren()
		for key, ent in ipairs(self.FungusChildren) do
			SafeRemoveEntity(ent)
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		self.dt.size = self.dt.size - dmginfo:GetDamage()
	end

	function ENT:Think()
		self.dt.size = self.dt.size - 0.1
		if self.dt.size < 0.1 then
			self:Remove()
		end

		--if math.random() > 0.5 then
			self:Spread()
		--end
	end

	function ENT:GetHashFromPos(pos)
		local x = math.Round(pos.x/16) * 16
		local y = math.Round(pos.y/16) * 16
		local z = math.Round(pos.z/16) * 16

		local hash = util.CRC(x+y+z)

		return hash
	end

	function ENT:EatPos(pos)
		local data = fungus_world_health[self:GetHashFromPos(pos)]

		if not data then
			data = {}
			fungus_world_health[self:GetHashFromPos(pos)] = data
		end

		local amt = math.Rand(10, 30)

		data.health = (data.health or 100) - amt
		if data.health > 0 then
			self.dt.size = self.dt.size + (amt / 10)
		end
	end

	function ENT:Shrink(size)
		self.dt.size = (size or self.dt.size) * 0.9
		local val = math.Clamp(math.Round((self.dt.size / self.MaxSize) * 255), 1, 255)
		self:SetColor((val*3)%255, val, (val*2)%255, 255)
	end

	function ENT:GetFungusInSphere(origin, siz)
		siz = siz or self.dt.size
		local tbl = {}

		for key, ent in pairs(ents.FindByClass(self:GetClass())) do
			if (ent:GetPos() - origin):LengthSqr() < self.dt.size * self.dt.size then
				table.insert(tbl, ent)
			end
		end

		return tbl
	end

	function ENT:CreateFungus(pos, ang, hit_ent)
		if self.dt.size > 0.2 and #ents.FindByClass("fungus") < 500 then
			hit_ent = hit_ent or NULL

			local ent = ents.Create(self.ClassName)
				ent:SetPos(pos)
				ent:SetAngles(Angle(math.Rand(-180, 180), math.Rand(-180, 180),math.Rand(-180, 180)))
				ent:Spawn()
				ent:Shrink(self.dt.size)

			if hit_ent:IsValid() and hit_ent:GetClass() ~= self:GetClass() then
				ent:SetParent(hit_ent)
				if hit_ent:Health() > 0 then
					ent.dt.size = ent.dt.size + (hit_ent:Health() / 4)
					hit_ent:TakeDamage(ent.dt.size / 4)
				end
			else
				self:EatPos(pos)
			end

			table.insert(self.FungusChildren, ent)

			return ent
		end

		return NULL
	end

    function ENT:Spread()
		local data = util.QuickTrace(self:GetPos(), VectorRand() * self.dt.size, self)

		if not data.Hit then
			local data = util.QuickTrace(data.HitPos, VectorRand() * self.dt.size * 2, self)
			if data.Hit and #self:GetFungusInSphere(data.HitPos) == 0 then
				return self:CreateFungus(data.HitPos + (data.HitNormal * 2), data.HitNormal:Angle(), data.Entity)
			end
		end

		return NULL
    end
end

easylua.EndEntity()