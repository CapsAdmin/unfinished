do -- gmod base
	local SWEP = {}

	SWEP.IsTestWeapon = true
	SWEP.AdminSpawnable = true
	SWEP.AnimPrefix = ""
	SWEP.Author = ""
	SWEP.Base = "weapon_base"
	SWEP.Contact = ""
	SWEP.Category = ""
	SWEP.Folder = ""
	SWEP.Instructions = ""
	SWEP.m_WeaponDeploySpeed = 1
	SWEP.Primary = {}
	SWEP.Purpose = ""
	SWEP.Secondary = {}
	SWEP.Spawnable = true
	SWEP.ViewModel = ""
	SWEP.ViewModelFlip = true
	SWEP.ViewModelFOV = 75
	SWEP.WorldModel = ""
	SWEP.HoldType = ""

	SWEP.Primary.Ammo = ""
	SWEP.Primary.Automatic = false
	SWEP.Primary.ClipSize = 10
	SWEP.Primary.DefaultClip = 1

	function SWEP:Ammo1()

	end

	function SWEP:Ammo2()

	end

	function SWEP:CanPrimaryAttack()
		return false
	end

	function SWEP:CanSecondaryAttack()
		return false
	end

	function SWEP:ContextScreenClick(dir, mcode, pressed, ply)
		--local data = util.QuickTrace(ply:EyePos(), dir*1000, ply)
	end

	function SWEP:Deploy()
		return true
	end

	function SWEP:Holster()
		return true
	end

	function SWEP:Initialize()

	end

	function SWEP:OnRemove()

	end

	function SWEP:OnRestore()

	end

	function SWEP:Precache()

	end

	function SWEP:PrimaryAttack()

	end

	function SWEP:PrintWeaponInfo()

	end

	function SWEP:Reload()

	end

	function SWEP:SecondaryAttack()

	end

	function SWEP:SetDeploySpeed(speed)

	end

	function SWEP:ShootBullet()

	end

	function SWEP:ShootEffects()

	end

	function SWEP:TakePrimaryAmmo(num)

	end

	function SWEP:TakeSecondaryAmmo(num)

	end

	function SWEP:Think()

	end

	function SWEP:TranslateActivity()

	end

	if CLIENT then
		SWEP.BobScale = 1
		SWEP.BounceWeaponIcon = true
		SWEP.DrawAmmo = true
		SWEP.DrawCrosshair = true
		SWEP.DrawWeaponInfoBox = true
		SWEP.PrintName = ""
		SWEP.RenderGroup = RENDERMODE_NORMAL
		SWEP.Slot = 1
		SWEP.SlotPos = 1
		SWEP.SpeechBubbleLid = ""
		SWEP.SwayScale = 1
		SWEP.WepSelection = 0
		SWEP.CSMuzzleFlashes = false

		function SWEP:AdjustMouseSensitivity()
			return 1
		end

		function SWEP:CalcView(ply, origin, angles, fov)

			return origin, angles, fov
		end

		function SWEP:CustomAmmoDisplay()

		end

		function SWEP:DoImpactEffect(data, damage_type)
			return true
		end

		function SWEP:DrawHUD()

		end

		function SWEP:DrawWeaponSelection(x, y, w, h, a)

		end

		function SWEP:DrawWorldModel()
			self:DrawModel()
		end

		function SWEP:DrawWorldModelTranslucent()
			self:DrawModel()
		end

		-- events https:--developer.valvesoftware.com/wiki/Animation_Events
		function SWEP:FireAnimationEvent(pos, ang, event)

		end

		function SWEP:FreezeMovement()
			return false
		end

		function SWEP:GetTracerOrigin()
			--return self:EyePos()
		end

		function SWEP:GetViewModelPosition(pos, ang)

			return pos, ang
		end

		function SWEP:HUDShouldDraw()
			return true
		end

		function SWEP:TranslateFOV(fov)
			return 75
		end

		function SWEP:ViewModelDrawn()

		end
	end

	if SERVER then
		SWEP.AutoSwitchFrom = true
		SWEP.AutoSwitchTo = true
		SWEP.Weight = 100

		function SWEP:AcceptInput()

		end

		function SWEP:Equip()

		end

		function SWEP:EquipAmmo()

		end

		function SWEP:GetCapabilities()

		end

		function SWEP:KeyValue()

		end

		function SWEP:OnDrop()

		end

		function SWEP:OwnerChanged()

		end

		function SWEP:ShouldDropOnDie()

		end
	end

	_G.SWEP = SWEP
		include("weapons/weapon_base/ai_translations.lua")
		include("weapons/weapon_base/sh_anim.lua")
	_G.SWEP = nil

	weapons.Register(SWEP, "test_weapon", true)

end

do -- weapon base
	local SWEP = {}

	SWEP.Base = "test_weapon"
	SWEP.AllowDSP = true

	if CLIENT then
		usermessage.Hook("test_weapon_client_call", function(umr)
			local wep = umr:ReadEntity()
			if wep:IsValid() then
				local func = umr:ReadString()
				local args = glon.decode(umr:ReadString())
				print(wep, wep.Owner)
				wep[func](wep, unpack(args))
			end
		end)

		function SWEP:CallClientFunction(func, players, ...)
			self[func](self, ...)
		end
	end

	if SERVER then
		function SWEP:CallClientFunction(func, players, ...)
			local rp = RecipientFilter()
			if not players then
				rp = nil
			elseif type(players) == "Player" then
				rp:AddPlayer(rp)
			elseif type(players) == "table" then
				for key, val in pairs(players) do
					rp:AddPlayer(val)
				end
			end

 			umsg.Start("test_weapon_client_call", rp)
				umsg.Entity(self)
				umsg.String(func)
				umsg.String(glon.encode({...}))
			umsg.End()
		end

		function SWEP:GetAllButOwner()
			local tbl = {}

			for key, ply in pairs(player.GetAll()) do
				if ply ~= self.Owner then
					table.insert(tbl, ply)
				end
			end

			return tbl
		end
	end

	do -- viewmodel

		function SWEP:GetViewModelSequences()
			if self.ViewModelSequences then
				return self.ViewModelSequences
			end

			self.ViewModelSequences = {}
			self.ViewModelSequencesPatternCache = {}

			local ent = self.Owner:GetViewModel()

			for i=0, 100 do
				local key = ent:GetSequenceName(i)
				if key ~= "Unknown" then
					self.ViewModelSequences[key] = i
				else
					break
				end
			end

			return self.ViewModelSequences
		end

		function SWEP:FindViewModelSequence(target)
			if self.ViewModelSequencesPatternCache and self.ViewModelSequencesPatternCache[target] then
				return self.ViewModelSequencesPatternCache[target]
			end
			for name, seq in pairs(self:GetViewModelSequences()) do
				if name:lower():find(target:lower()) then
					self.ViewModelSequencesPatternCache[target] = seq
					return seq
				end
			end
		end

		function SWEP:PlayViewModelSequence(target)
			local seq = self:FindViewModelSequence(target)
			if seq then
				local ent = self.Owner:GetViewModel()
				ent:ResetSequenceInfo(0)
				ent:SetSequence(seq)
			end
		end

	end

	function SWEP:Initialize()
		self.KeysDown = {}
		if CLIENT then
			self:SKCInitialize()
		end
	end

	function SWEP:OnRemove()
		if CLIENT then
			self:SKCOnRemove()
		end
	end

	function SWEP:OnInputEvent(key, press)

	end

	function SWEP:IsKeyDown(key)
		return self.KeysDown[key]-- self.Owner:KeyDown(key)
	end

	function SWEP:KeyPress(ply, key)
		self.KeysDown[key] = true
		self:OnInputEvent(key, true)
		if SERVER then
			self:CallClientFunction("KeyPress", self:GetAllButOwner(), ply, key)
		end
	end

	function SWEP:KeyRelease(ply, key)
		self.KeysDown[key] = false
		self:OnInputEvent(key, false)
		if SERVER then
			self:CallClientFunction("KeyRelease", self:GetAllButOwner(), ply, key)
		end
	end

	function SWEP:GetShootPos()
		return self.Owner:IsPlayer() and self.Owner:GetShootPos() or self:GetPos()
	end

	function SWEP:GetShootDir()
		return self.Owner:IsPlayer() and self.Owner:GetAimVector() or self:GetForward()
	end

	function SWEP:GetTrace(length)
		return util.QuickTrace(self:GetTracerOrigin(), self:GetShootDir() * (length or 32000), {self, self.Owner})
	end

	function SWEP:BulletCallback(ply, data, dmg_info, decal)
		util.Decal("Impact.Concrete", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
	end

	function SWEP:PlaySound(params)
		local path = params.Path

		if type(path) == "table" then
			path = table.Random(params.Path)
		elseif type(path) == "function" then
			path = path(self)
		end

		local pitch = params.Pitch or 100
		if type(pitch) == "table" then
			pitch = math.random(pitch[1], pitch[2])
		elseif type(pitch) == "function" then
			pitch = pitch(self)
		end

		local vol = params.Volume or 100
		if type(vol) == "table" then
			vol = math.random(vol[1], vol[2])
		elseif type(vol) == "function" then
			vol = vol(self)
		end

		for i=1, params.Mult or 1 do
			WorldSound(path, self:GetPos(), vol, pitch)
		end
	end

	function SWEP:ShootBullets(O)
		O = O or {}
		--self.Owner:LagCompensation(true)

		self:FireBullets
		{
			Src = self:GetShootPos(),
			Dir = self:GetShootDir(),
			Force = O.Force or 100,
			Spread = Vector(1,1,1) * (O.Spread or 0.01),
			Attacker = self.Owner,
			Inflictor = self,
			Num = O.Num or 1,
			Damage = O.Damage or 10,
			AmmoType = O.AmmoType or self.Primary.Ammo,
			Tracer = 1,
			--Hull = 0,
			TracerName = "Tracer",
			Callback = function(ply, data, dmg_info)
				self:BulletCallback(ply, data, dmg_info, O.Decal or "Impact.Concrete")
			end,
		}
		--self.Owner:LagCompensation(false)
	end

	weapons.Register(SWEP, "test_weapon2", true)
end

do -- test pistol
	local SWEP = {}
	SWEP.Base = "test_weapon2"

	SWEP.HoldType = "pistol"
	SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"
	SWEP.ViewModel = "models/weapons/v_pist_glock18.mdl"
	SWEP.CSMuzzleFlashes = true

	SWEP.Primary =
	{
		Ammo = "pistol",
		Automatic = false,
		ClipSize = 10,
		DefaultClip = 1,

		Damage = 100,

		Sound =
		{
			Path = "/weapons/smg1/smg1_fire1.wav",
			Pitch = 50,
		},
	}

	SWEP.Secondary =
	{
		Ammo = "pistol",
		Automatic = false,
		ClipSize = 10,
		DefaultClip = 1,

		Damage = 1,

		Sound =
		{
			Path = "/weapons/smg1/smg1_fire1.wav",
			Pitch = 150,
		},
	}

	function SWEP:OnInputEvent(key, press)
		if press and key == IN_ATTACK then
			if SERVER then
				SuppressHostEvents(self.Owner)


					self:SetAnimation(PLAYER_ATTACK)
					self:ShootBullets(self.Primary.Bullet)

				SuppressHostEvents(NULL)
				self:PlayViewModelSequence("single")
			else
				self:PlaySound(self.Primary.Sound)
			end
		end
	end

	function SWEP:OnUpdate()
		if self:IsKeyDown(IN_ATTACK2) then
			if SERVER then
				SuppressHostEvents(self.Owner)

					self:SetAnimation(PLAYER_ATTACK)
					self:ShootBullets(self.Secondary.Bullet)

				SuppressHostEvents(NULL)
				self:PlayViewModelSequence("single")
			else
				self:PlaySound(self.Secondary.Sound)
			end
		end
	end

	weapons.Register(SWEP, "test_pistol", true)

	if SERVER then
		local function give(ply)
			SafeRemoveEntity(ply:GetWeapon("test_pistol"))
			timer.Simple(0.1,function()
				ply:Give("test_pistol")
			end)
		end
		timer.Simple(1, function()
			give(player.GetByUniqueID(--[[RealName]] "1416729906"))
			give(player.GetByUniqueID(--[[Morten]] "2698589489"))
			--give(player.GetByUniqueID(--[[·´`·.¸.»hm]] "2551268529"))
			--give(noiw)
		end)
	end
end

do -- helpers
	local function HOOK(event, check, alias)
		hook.Add(event, "test_weapon_event", function(...)
			for key, ent in pairs(ents.GetAll()) do
				if ent.IsTestWeapon and ent:IsValid() and (not check or check(ent, ...)) and (alias and ent[alias] or not alias and ent[event]) then
					local ok, err = pcall(ent[alias or event], ent, ...)
					if not ok then
						ErrorNoHalt(err)
					end
				end
			end
		end)
	end

	if SERVER then
		HOOK("KeyPress", function(wep, ply) return ply:GetActiveWeapon() == wep end)
		HOOK("KeyRelease", function(wep, ply) return ply:GetActiveWeapon() == wep end)
	end
	HOOK("Think", nil, "OnUpdate")

	function GetSwepModifier(class_name)
		return setmetatable({}, {
			__newindex = function(s, key, val)
				for _, ent in pairs(ents.FindByClass(class_name)) do
					ent[key] = val
				end
			end,
		})
	end
end