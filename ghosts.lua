local PORT = 23666

local SERVERS = {/*"88.191.109.120"*/"213.64.253.44"}

function C(...)
	
	local str = ""
	for k,v in pairs{...} do
		
		str = str..string.char(v)
	end
	
	return str
end

function B(str)

	return string.byte(str:sub(1,1)),string.byte(str:sub(2,2)),string.byte(str:sub(3,3)),string.byte(str:sub(4,4))
end

local function BTOA(char)

	return Angle(0,360*char/255,0)
end

local function ATOB(ang)

	return string.char(math.floor(255*(ang.Yaw%360)/360))
end

local function ITOB(i)

	i = math.Round(i)
	
	local n = i<0 and 1 or 0
	
	i = math.abs(i)
	
	local a = (i & 0x0f000000) >> 24
	local b = (i & 0x00ff0000) >> 16
	local c = (i & 0x0000ff00) >> 8
	local d = (i & 0x000000ff)
	
	return a+(n<<4),b,c,d
end

local function BTOI(a,b,c,d)
	
	local n = (a & 0x10) != 0 and -1 or 1
	
	a = (a & (0xff-0x10))	
	
	return n*((a<<24)+(b<<16)+(c<<8)+d)
end

local function VTOB(vec)

	return C(ITOB(vec.x))..C(ITOB(vec.y))..C(ITOB(vec.z))
end

local function BTOV(str)

	local x = BTOI(B(str:sub(0,4)))
	local y = BTOI(B(str:sub(5,8)))
	local z = BTOI(B(str:sub(9,12)))
	
	return Vector(x,y,z)
end

local GHOST = {}

require("oosocks")

local socket = OOSock(IPPROTO_UDP)

socket:SetBinaryMode(true)

socket:SetCallback(function(self,call,id,err,data,peer,port)

	if (call == SCKCALL_BIND) then
	
		self:Receive(26)
	
	elseif (call == SCKCALL_REC_SIZE) then
	
		local PID = data:ReadByte()
		local pos = ""
		for i=1,12 do
			pos = pos..string.char(data:ReadByte())
		end
		
		local ang = data:ReadByte()
		
		local vel = ""
		for i=1,12 do
			vel = vel..string.char(data:ReadByte())
		end
		
		pos = BTOV(pos)
		ang = BTOA(ang)
		vel = BTOV(vel)
		
		if !IsValid(GHOST[PID]) then
		
			GHOST[PID] = ents.Create("prop_dynamic")
			GHOST[PID]:SetModel("models/props_halloween/ghost.mdl")
			GHOST[PID]:Spawn()
		end
		
		GHOST[PID]:SetPos(pos)
		GHOST[PID]:SetAngles(ang)
		GHOST[PID]._vel = vel
		
		self:Receive(26)
	end
end)

socket:Bind("",PORT)

timer.Create("update",0.1,0,function()

	for k,v in pairs(player.GetAll()) do
		
		local send = k
		local pos = v:GetPos()
		local ang = v:EyeAngles()
		local vel = v:GetVelocity()
		
		send = send..VTOB(pos)
		send = send..ATOB(ang)
		send = send..VTOB(vel)
		
		for _,ip in pairs(SERVERS) do
		
			socket:Send(send,ip,PORT)
		end
	end
end)

hook.Add("Think","predict_ghosts",function()

	for k,v in pairs(GHOST) do
	
		if IsValid(v) and v._vel then
		
			v:SetPos(v:GetPos()+v._vel*FrameTime())
		end
	end
end)//*/

hook.Add("ShutDown","closesocket",function()

	socket:Close()
	socket = nil
end)