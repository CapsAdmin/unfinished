local CLASSNAME = "gmod_tool"

local function check(variable, ...)
	local name = debug.getinfo(2, "n").name
	local func = debug.getinfo(2, "f").func
	local types = {...}
	local allowed = ""
	
	local matched = false
	
	for key, value in ipairs(types) do
		if #types ~= key then
			allowed = allowed .. value .. " or "
		else
			allowed = allowed .. value
		end
		
		if type(variable) == value then
			matched = true
		end
	end
	
	local arg = "???"
	
	for i=1, math.huge do 
		local key, value = debug.getlocal(2, i)
		-- I'm not sure what to do about this part
		if value == variable then
			arg = i
		break end
	end
	
	if not matched then
		error(("bad argument #%s to '%s' (%s expected, got %s)"):format(arg, name, allowed, type(typ)), 3)
	end
end

stool = stool or {} 
	local s = stool

stool.utils = {} 
	local u = {}

stool.stored_tools = {}
stool.stool_meta = {}
stool.weapon_meta = {}

stool.base_folder = "weapons/gmod_tool/stools/"

function u.GetFilnameFromPath(path, extension)
	check(path, "string")
	check(extension, "string", "nil")

	local tbl = ("/"):Explode(path)
	
	return tbl[#tbl]:Left(extension and -#extension or -5)
end

function u.IsValidPhysics(v)
	return type(v) == "PhysObj"
end

function u.IsValidEntity(v)
	return IsEntity(v) and v:IsValid()
end

do -- register

	function stool.Register(TOOL, name)
		check(TOOL, "table")
		check(name, "string")
			TOOL = s.GetSToolMeta():Create(TOOL)
			
			TOOL.Mode = name
			TOOL:CreateConVars()
			
			s.stored_tools[name] = TOOL
		_G.ToolObj = nil
		
		return TOOL
	end

	function stool.RegisterFromFile(path, name)
		check(path, "string")
		check(name, "string", "nil")
			
		name = name or u.GetFilnameFromPath(path)
		
		_G.TOOL = {ClientConVar = {}}
		_G.ToolObj = s.GetSToolMeta()
		_G.SWEP = s.GetWeaponMeta()
		
			AddCSLuaFile(path)
			include(path)
			stool.Register(TOOL, name)
			
		_G.SWEP = nil
		_G.ToolObj = nil
		_G.TOOL = nil
	end
	
	function stool.LoadTools(path, extension)
		check(path, "string", "nil")
		check(extension, "string", "nil")
		
		path = path or s.base_folder
		extension = extension or "*.lua"
		
		for _, name in pairs(file.FindInLua(path .. extension)) do
			stool.RegisterFromFile(path .. name)
		end
	end
		 
	concommand.Add((SERVER and "sv_" or "cl_") .. "stool_reload", function(ply, _, args)
		if ply:IsPlayer() and ply:IsAdmin() then	
			local path = args[1]
			
			if path then
				s.RegisterFromFile(path)
			else
				stool.LoadTools()
			end
		end
	end)
end

do -- get
	function stool.Get(name)
		check(name, "string")
		
		return table.Copy(s.GetStored(name))
	end

	function stool.GetStored(name)
		check(name, "string")
		
		return s.stored_tools[name]
	end

	function stool.GetAll()
		return s.stored_tools
	end
	
	function stool.GetWeaponMeta()
		return s.weapon_meta
	end
	
	function stool.GetSToolMeta()
		return s.stool_meta
	end
end

do -- weapon meta
	local SWEP = stool.weapon_meta
	
	SWEP.ClassName = "gmod_tool"
	SWEP.Base = "weapon_base"
		
	SWEP.Author = ""
	SWEP.Contact = ""
	SWEP.Purpose = ""
	SWEP.Instructions = ""

	SWEP.ViewModel = Model("models/weapons/v_toolgun.mdl")
	SWEP.WorldModel = Model("models/weapons/w_toolgun.mdl")
	SWEP.AnimPrefix = "python"
	
	SWEP.Weight = 5
	SWEP.AutoSwitchTo = false
	SWEP.AutoSwitchFrom = false

	SWEP.ShootSound = Sound( "Airboat.FireGunRevDown" )
	
	local mode_settings = {
		ClipSize 	= -1,
		DefaultClip = -1,
		Automatic = false,
		Ammo = "none"
	}
	
	SWEP.Primary = table.Copy(mode_settings)
	SWEP.Secondary = table.Copy(mode_settings)

	SWEP.CanHolster = true
	SWEP.CanDeploy = true
	
	SWEP.Tool = {}
	
	function SWEP:SetupDataTables()
		self:DTVar("Int", 0, "Stage")
	end
	
	function SWEP:CheckLimit( str ) 
		return self.Owner:CheckLimit( str )
	end

	function SWEP:ShouldDropOnDie()
		return false
	end

	function SWEP:InitializeTools()
		local temp = {}
		
		for k,v in pairs( stool.GetAll() ) do
			temp[k] = table.Copy(v)
			temp[k].SWEP = self
			temp[k].Owner = self.Owner
			temp[k].Weapon = self.Weapon
		end
		
		self.Tool = temp
	end

	function SWEP:Initialize()
		self:InitializeTools()
		
		// We create these here. The problem is that these are meant to be constant values.
		// in the toolmode they're not because some tools can be automatic while some tools aren't.
		// Since this is a global table it's shared between all instances of the gun.
		// By creating new tables here we're making it so each tool has its own instance of the table
		// So changing it won't affect the other tools.
		
		self.Primary = table.Copy(mode_settings)
		self.Secondary = table.Copy(mode_settings)
	end

	function SWEP:OnRestore()
		self:InitializeTools()
	end

	function SWEP:Reload()
		
		local tool = self:GetToolObject()
		
		if not self.Owner:KeyPressed(IN_RELOAD) or not tool then return end

		local mode = self:GetMode()
		local trace = self.Owner:GetEyeTrace()
		if trace.Hit then
			tool:CheckObjects()
			if tool:Allowed() and gamemode.Call( "CanTool", self.Owner, trace, mode ) and tool:Reload( trace ) then
				self:DoShootEffect(trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, IsFirstTimePredicted())
			end
		end
	end
	
	function SWEP:GetMode()
		return self.Mode
	end

	local mode
	local tool
	
	function SWEP:Think()
		mode = self.Owner:GetInfo( "gmod_toolmode" )
		self.Mode = mode
		
		tool = self:GetToolObject()
		
		if tool then
			tool:CheckObjects()
			
			self.last_mode = self.current_mode
			self.current_mode = mode
			
			if tool:Allowed() then 
				if self.last_mode ~= self.current_mode and self:GetToolObject( self.last_mode ) then
					self:GetToolObject(self.last_mode):Holster()
				end
				
				self.Primary.Automatic = tool.LeftClickAutomatic or false
				self.Secondary.Automatic = tool.RightClickAutomatic or false
				self.RequiresTraceHit = tool.RequiresTraceHit or true
				
				tool:Think()
			else
				self:GetToolObject( self.last_mode ):ReleaseGhostEntity()
			end
		end
	end

	function SWEP:DoShootEffect( hitpos, hitnormal, entity, physbone, bFirstTimePredicted )

		self:EmitSound( self.ShootSound	)
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		
		if not bFirstTimePredicted then return end
		
		local effectdata = EffectData()
			effectdata:SetOrigin( hitpos )
			effectdata:SetNormal( hitnormal )
			effectdata:SetEntity( entity )
			effectdata:SetAttachment( physbone )
		util.Effect( "selection_indicator", effectdata )	
		
		local effectdata = EffectData()
			effectdata:SetOrigin( hitpos )
			effectdata:SetStart( self.Owner:GetShootPos() )
			effectdata:SetAttachment( 1 )
			effectdata:SetEntity( self )
		util.Effect( "ToolTracer", effectdata )
		
	end
	
	function SWEP:Attack(toolfunc)
		local tool = self:GetToolObject()
		if tool then			
			local trace = util.GetPlayerTrace( self.Owner )
			trace.mask = ( CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MONSTER|CONTENTS_WINDOW|CONTENTS_DEBRIS|CONTENTS_GRATE|CONTENTS_AUX )
			trace = util.TraceLine( trace )
			if trace.Hit then
				tool:CheckObjects()				
				if 
					tool:Allowed() and 
					gamemode.Call( "CanTool", self.Owner, trace, self:GetMode() ) and 
					tool[toolfunc](tool, trace)
				then
					self:DoShootEffect( trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, IsFirstTimePredicted() )
				end
			end
		end
	end

	function SWEP:PrimaryAttack()
		self:Attack("LeftClick")
	end

	function SWEP:SecondaryAttack()
		self:Attack("RightClick")
	end

	function SWEP:ContextScreenClick( aimvec, mousecode, pressed, ply )
		local tool = self:GetToolObject()
		if tool and not (CLIENT and SinglePlayer()) and pressed then					
			local trace = util.TraceLine( utilx.GetPlayerTrace( CLIENT and GetViewEntity() or ply:GetViewEntity(), aimvec ) )
			
			if trace.Hit then		
				tool:CheckObjects()
				if 
					tool:Allowed() and 
					gamemode.Call( "CanTool", self.Owner, trace, self:GetMode()) and
					(
						mousecode == MOUSE_LEFT and tool:LeftClick( trace ) or
						mousecode == MOUSE_RIGHT and tool:RightClick( trace )
					)
				then			
					self:DoShootEffect( trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, true )
				end
			end
		end
	end

	function SWEP:Holster()
		local tool = self:GetToolObject()
		return tool and tool:Holster() or self.CanHolster
	end

	function SWEP:OnRemove()
		local tool = self:GetToolObject()
		if tool then
			tool:ReleaseGhostEntity()
		end		
	end

	SWEP.OwnerChanged = SWEP.OnRemove

	function SWEP:Deploy()
		local tool = self:GetToolObject()
		if tool then 
			tool:UpdateData() 
			return tool:Deploy()
		end
		return self.CanDeploy
	end

	function SWEP:GetToolObject( mode )
		return self.Tool[ mode or self:GetMode() ] or false
	end

	function SWEP:FireAnimationEvent( _,_,event )
		return event == 21 or event == 5003 or nil
	end
	
	if CLIENT then
		local matScreen 	= Material( "models/weapons/v_toolgun/screen" )
		local txidScreen	= surface.GetTextureID( "models/weapons/v_toolgun/screen" )
		local txRotating	= surface.GetTextureID( "pp/fb" )
		local txBackground	= surface.GetTextureID( "models/weapons/v_toolgun/screen_bg" )
		local RTTexture 	= GetRenderTarget( "GModToolgunScreen", 256, 256 )

		surface.CreateFont( "Arial Black", 82, 1000, true, false, "GModToolScreen" )

		local function DrawScrollingText( text, y, texwide )

				local w, h = surface.GetTextSize( text  )
				w = w + 64
				
				local x = math.fmod( CurTime() * 400, w ) * -1;
				
				while ( x < texwide ) do
				
					surface.SetTextColor( 0, 0, 0, 255 )
					surface.SetTextPos( x + 3, y + 3 )
					surface.DrawText( text )
						
					surface.SetTextColor( 255, 255, 255, 255 )
					surface.SetTextPos( x, y )
					surface.DrawText( text )
					
					x = x + w
					
				end

		end
		
		local render = render
		local gmod_toolmode = gmod_toolmode
		local cam = cam
		local ScrH = ScrH
		local ScrW = ScrW
		
		local tool
		
		local TEX_SIZE = 256
		local mode 	= gmod_toolmode:GetString()
		local NewRT = RTTexture
		local oldW = ScrW()
		local oldH = ScrH()
		
		function SWEP:RenderScreen()
			tool = self:GetToolObject()
			
			if tool then	
				mode = gmod_toolmode:GetString()
				NewRT = RTTexture
				oldW = ScrW()
				oldH = ScrH()
				
				matScreen:SetMaterialTexture( "$basetexture", NewRT )
				
				local OldRT = render.GetRenderTarget()
					render.SetRenderTarget( NewRT )
					render.SetViewPort( 0, 0, TEX_SIZE, TEX_SIZE )
					cam.Start2D()
						surface.SetDrawColor( 255, 255, 255, 255 )
						surface.SetTexture( txBackground )
						surface.DrawTexturedRect( 0, 0, TEX_SIZE, TEX_SIZE )
						if tool.DrawToolScreen then 
							self:GetToolObject():DrawToolScreen( TEX_SIZE, TEX_SIZE )
						else
							surface.SetFont( "GModToolScreen" )
							DrawScrollingText( "#Tool_"..mode.."_name", 64, TEX_SIZE )
						end

					cam.End2D()
				render.SetRenderTarget( OldRT )
				render.SetViewPort( 0, 0, oldW, oldH )
			end
		end
	

		local gmod_drawhelp = CreateClientConVar( "gmod_drawhelp", "1", true, false )
		gmod_toolmode = CreateClientConVar( "gmod_toolmode", "rope", true, true )

		SWEP.PrintName = "Tool Gun NEW"			
		SWEP.Slot = 5	
		SWEP.SlotPos = 6	
		SWEP.DrawAmmo = false
		SWEP.DrawCrosshair = true

		SWEP.Spawnable = false
		SWEP.AdminSpawnable = false

		SWEP.WepSelectIcon = surface.GetTextureID( "vgui/gmod_tool" )
		SWEP.Gradient = surface.GetTextureID( "gui/gradient" )
		SWEP.InfoIcon = surface.GetTextureID( "gui/info" )

		SWEP.ToolNameHeight = 0
		SWEP.InfoBoxHeight = 0

		surface.CreateFont( "Arial Black", 48, 1000, true, false, "GModToolName" )
		surface.CreateFont( "Arial", 24, 1000, true, false, "GModToolSubtitle" )
		surface.CreateFont( "Arial", 17, 1000, true, false, "GModToolHelp" )

		local x, y = 50, 40
		local w, h = 0, 0
			
		function SWEP:DrawHUD()

			if not gmod_drawhelp:GetBool() then return end
			
			local mode = gmod_toolmode:GetString()
			
			if not self:GetToolObject() then return end
			
			self:GetToolObject():DrawHUD()
				
			w, h = 0, 0
			
			local TextTable = {}
			local QuadTable = {}
			
			QuadTable.texture 	= self.Gradient
			QuadTable.color		= Color( 10, 10, 10, 180 )
			
			QuadTable.x = 0
			QuadTable.y = y-8
			QuadTable.w = 600
			QuadTable.h = self.ToolNameHeight - (y-8)
			draw.TexturedQuad( QuadTable )
			
			TextTable.font = "GModToolName"
			TextTable.color = Color( 240, 240, 240, 255 )
			TextTable.pos = { x, y }
			TextTable.text = "#Tool_"..mode.."_name"
			
			w, h = draw.TextShadow( TextTable, 2 )
			y = y + h
			

			TextTable.font = "GModToolSubtitle"
			TextTable.pos = { x, y }
			TextTable.text = "#Tool_"..mode.."_desc"
			w, h = draw.TextShadow( TextTable, 1 )
			y = y + h + 8
			
			self.ToolNameHeight = y
			
			//y = y + 4
			
			QuadTable.x = 0
			QuadTable.y = y
			QuadTable.w = 600
			QuadTable.h = self.InfoBoxHeight
			local alpha =  math.Clamp( 255 + (self:GetToolObject().LastMessage - CurTime())*800, 10, 255 )
			QuadTable.color = Color( alpha, alpha, alpha, 230 )
			draw.TexturedQuad( QuadTable )
				
			y = y + 4
			
			TextTable.font = "GModToolHelp"
			TextTable.pos = { x + self.InfoBoxHeight, y  }
			TextTable.text = "#Tool_"..mode.."_"..self:GetToolObject():GetStage()
			w, h = draw.TextShadow( TextTable, 1 )
			
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetTexture( self.InfoIcon )
			surface.DrawTexturedRect( x+1, y+1, h-3, h-3 )	
			
			self.InfoBoxHeight = h + 8
			
		end

		function SWEP:SetStage( ... )
			return self:GetToolObject() and self:GetToolObject():SetStage( ... ) or false
		end

		function SWEP:GetStage( ... )
			return self:GetToolObject() and self:GetToolObject():GetStage( ... ) or false
		end

		function SWEP:ClearObjects( ... )			
			if self:GetToolObject() then self:GetToolObject():ClearObjects( ... ) end
		end

		function SWEP:StartGhostEntities( ... )
			if self:GetToolObject() then self:GetToolObject():StartGhostEntities( ... ) end
		end

		function SWEP:PrintWeaponInfo( x, y, alpha )	
		end

		function SWEP:FreezeMovement()
			if self:GetToolObject() then self:GetToolObject():FreezeMovement() end
		end


	end
	
	weapons.Register(SWEP, CLASSNAME, true)
end

do -- stool meta
	local META = s.stool_meta
	META.__index = META
	
	function META:Create(override)
		local o = setmetatable(override or {},	META)
		o.Mode = nil
		o.SWEP = nil
		o.Owner = nil
		o.ClientConVar = {}
		o.ServerConVar = {}
		o.Objects = {}
		o.Stage = 0
		o.Message = "start"
		o.LastMessage = 0
		o.AllowedCVar = 0
		return o
	end

	function META:UpdateData()
		self:SetStage(self:NumObjects())
	end

	function META:SetStage(i)
		if SERVER then
			self:GetWeapon().dt.Stage = i
		end
	end

	function META:GetStage()
		return self:GetWeapon().dt.Stage
	end

	function META:ClearObjects()
		self:ReleaseGhostEntity()
		self.Objects = {}
		self:SetStage( 0 )
	end

	function META:GetEnt(i)		
		return self.Objects[i] and self.Objects[i].Ent or NULL
	end

	function META:GetPos(i)
		local object = self.Objects[i]
		
		-- a b or c overkill?
		return 
			object and			
				object.Ent:IsWorld() and 
					object.Pos 
				or 
				
				u.IsValidPhysics(object.Phys) and 
					object.Phys:LocalToWorld(object.Pos) 
				or 
				
				object.Ent:IsValid() and
					object.Ent:LocalToWorld(object.Pos)
				or
				
				nil
	end

	function META:GetLocalPos(i)
		return self.Objects[i].Pos
	end

	function META:GetBone(i)
		return self.Objects[i].Bone
	end

	function META:GetNormal(i)
		local object = self.Objects[i]
		
		if object then
			if object:IsWorld() then
				return object.Normal
			else
				local normal = 
				
					u.IsValidPhysics(object.Phys) and 
						object.Phys:LocalToWorld(object.Normal)
					or
					
					u.IsValidEntity(object.Ent) and
						object.Ent:LocalToWorld(object.Normal)
				
				return normal and (normal - self:GetPos(i)) or nil
			end
		end
	end

	function META:GetPhys(i)
		return self.Objects[i].Phys
	end

	function META:SetObject(i, ent, pos, phys, bone, norm)

		local object = {}
		object.Ent = ent
		object.Phys = phys
		object.Bone = bone
		object.Normal = norm
		
		if ent:IsWorld() then
			object.Phys = nil
			object.Pos = pos
		else
			norm = norm + pos

			if u.IsValidPhysics(phys) then
				object.Normal = object.Phys:WorldToLocal(norm)
				object.Pos = object.Phys:WorldToLocal(pos)
			elseif u.IsValidEntity(ent) then
				object.Normal = object.Ent:WorldToLocal(norm)
				object.Pos = object.Ent:WorldToLocal(pos)
			end
		end
		
		PrintTable(object)
		
		self.Objects[i] = object
		
	end

	function META:NumObjects()
		return CLIENT and self:GetStage() or #self.Objects
	end

	function META:CreateConVars()
		local mode = self:GetMode():lower()

		if CLIENT then
			for cvar, default in pairs( self.ClientConVar ) do
				CreateClientConVar( mode.."_"..cvar, default, true, true )
			end
		else
			self.AllowedCVar = CreateConVar( "toolmode_allow_"..mode, 1, FCVAR_NOTIFY )
		end
	end

	function META:GetServerInfo(property)		
		return GetConVarString( self:GetMode():lower().."_"..property )
	end

	function META:GetClientInfo(property)		
		return self:GetOwner():GetInfo( self:GetMode():lower().."_"..property )
	end

	function META:GetClientNumber( property, default )
		return self:GetOwner():GetInfoNum( self:GetMode().."_"..property, default or 0 )
	end

	function META:Allowed()
		return SERVER and self.AllowedCVar:GetBool() or true
	end

	function META:GetMode() return self.Mode end
	function META:GetSWEP() return self.SWEP end
	function META:GetOwner() return self:GetSWEP().Owner or self.Owner end
	function META:GetWeapon() return self:GetSWEP().Weapon or self.Weapon end

	function META:LeftClick() return false end
	function META:RightClick() return false end
	function META:Reload() self:ClearObjects() end
	function META:Deploy() self:ReleaseGhostEntity() return end
	function META:Holster() self:ReleaseGhostEntity() return end
	function META:Think() self:ReleaseGhostEntity() end
	
	function META:CheckObjects()
		for k, v in pairs( self.Objects ) do
			if not v.Ent:IsWorld() or not v.Ent:IsValid() then
				self:ClearObjects()
			end
		end
	end
	
	if CLIENT then
	
		function META:FreezeMovement()
			return false 
		end
		
		function META:DrawHUD() end
		
	end

	function META:MakeGhostEntity( model, pos, angle )
		if SERVER and not SinglePlayer() or CLIENT and SinglePlayer() then return end
		
		
		self:ReleaseGhostEntity()
		
		if util.IsValidProp( model ) then
			local ghost = ents.Create( "prop_physics" )
			
			if ghost:IsValid() then				
				ghost:SetModel( model )
				ghost:SetPos( pos )
				ghost:SetAngles( angle )
				ghost:Spawn()
				
				ghost:SetSolid( SOLID_VPHYSICS )
				ghost:SetMoveType( MOVETYPE_NONE )
				ghost:SetNotSolid( true )
				ghost:SetRenderMode( RENDERMODE_TRANSALPHA )
				ghost:SetColor( 255, 255, 255, 150 )
				
				self.GhostEntity = ghost
			end
		end
	end

	function META:StartGhostEntity( ent )
		if SERVER and not SinglePlayer() or CLIENT and SinglePlayer() then return end
		self:MakeGhostEntity( ent:GetModel(), ent:GetPos(), ent:GetAngles() )
	end

	function META:ReleaseGhostEntity()
		if self.GhostEntity then
			SafeRemoveEntity(self.GhostEntity)
			self.GhostEntity = nil
		end
		
		if self.GhostEntities then
			for k,v in pairs( self.GhostEntities ) do
				SafeRemoveEntity(self.GhostEntities[k])
				self.GhostEntities[k] = nil
			end
			self.GhostEntities = nil
		end
		
		self.GhostOffset = nil		
	end

	function META:UpdateGhostEntity()
		local ghost = self.GhostEntity
		if u.IsValidEntity(ghost) then
			local trace = util.TraceLine( util.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() ) )
			local ent = self:GetEnt(1)
			if trace.Hit and ent:IsValid() then				
				ghost:SetPos( ent:GetPos() )
				ghost:SetAngles( ent:AlignAngles( self:GetNormal(1):Angle(), (trace.HitNormal * -1):Angle() ) )
				ghost:SetPos(trace.HitPos + (ent:GetPos() - ghost:LocalToWorld(self:GetLocalPos(1))) + trace.HitNormal)
			end
		end
	end

end

--stool.LoadTools()

if SERVER then
	All(CLASSNAME):Remove()
	
	timer.Simple(0.1, function()
		Ply"oh":Give(CLASSNAME)
	end)
end

local TOOL = {}

TOOL.AddToMenu		= false

TOOL.Category = "My Category"		// Name of the category
TOOL.Name = "#Example"		// Name to display
TOOL.Command = nil				// Command on click (nil for default)
TOOL.ConfigName = nil				// Config file name (nil for default)

function TOOL:LeftClick( trace )
	Msg( "PRIMARY FIRE\n" )
end

function TOOL:RightClick( trace )
	Msg( "ALT FIRE\n" )
end

function TOOL:Reload( trace )
	// The SWEP doesn't reload so this does nothing :(
	Msg( "RELOAD\n" )
end

function TOOL:Think()
end