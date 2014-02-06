--if not LocalPlayer():CheckUserGroupLevel("developers") then return end

local mat_screenspace = Material("models/screenspace")
local mdl_dome = Model("models/props_phx/construct/metal_dome360.mdl")
local white = Color(255, 255, 255, 255)

SafeRemoveEntity(fractal_renderer)

local renderer = ClientsideModel(mdl_dome)

local function scale(ent, vec)
	local mat = Matrix()
	mat:Scale(vec)
	ent:EnableMatrix("RenderMultiply", mat)
end

RunConsoleCommand("pp_bloom", "1")
RunConsoleCommand("pp_bloom_passes", "0")
RunConsoleCommand("pp_bloom_multiply", "0")
flomp = flomp or {} local f = flomp
do -- particles
	

	flomp.emitter = ParticleEmitter(EyePos(), false)
	flomp.emitter:SetNoDraw(true)

	f.FFT = {}
	f.FFT_Size = 1024

	f.FFT_Bass_1 = 0
	f.FFT_Bass_2 = 0

	f.max_volume = 0
	f.scale = 1
	f.eye_angles = Angle(0)
	f.eye_origin = vector_origin
	f.vol_multplier = 1

	f.fft_detail = 10
	f.mul_fft = f.FFT_Size/f.fft_detail

	for i = 1, f.FFT_Size do
		f.FFT[i] = 0
	end

	function flomp.SetSource(var)
		var = type(var) == "number" and Entity(var) or var
		if type(var) == "Vector" or (IsEntity(var) and var:IsValid()) then
			f.source = var
		end
	end

	function flomp.SetScale(n)
		f.scale = n
	end

	function flomp.SetVolumeInputScale(n)
		f.vol_multplier = n
	end

	function flomp.GetSourcePos()
		return type(f.source) == "Vector" and f.source or IsEntity(f.source) and f.source:IsValid() and f.source:EyePos() or vector_origin
	end

	function flomp.GetAverage(istart, iend)
		istart = math.Round(math.Clamp(istart, 1, f.FFT_Size))
		iend = math.Round(math.Clamp(iend, 1, f.FFT_Size))
		local n = 0
		for i=istart, iend do
		--	if f.FFT[i] then
				n = n + f.FFT[i]
	--		end
		end

		local div = (iend - istart)

		return div == 0 and 0 or (n / div)
	end

	function flomp.IsAround(number, min, max)
		return number > min and number < max and true or false
	end

	function flomp.ScaleVolume(volume, peak)
		return ((volume ^ flomp.powscale) * f.vol_multplier) * 2.5
	end

	function flomp.Spectrum2D()
		do return end
		--if bawss and bawss.channel then bawss.channel:stop() bawss = nil end -- declan interuption protection

		local h = ScrH() + -400
		local w = ScrW()
		local volume = 0

		for fr = 1, f.FFT_Size do
			volume = f.ScaleVolume(f.FFT[fr])

			surface.SetDrawColor(volume,volume,255*volume,255)
			surface.DrawLine(
				(w+fr)-ScrW(), h,
				(w+fr)-ScrW(), h-(volume*50)
			)
		end
	end

	local time = 0

	function flomp.SpectrumUpdate(data, peak)
		f.FFT = data

		f.FFT_Bass_1 = flomp.GetAverage(1, 6)
		
		time = time + f.FFT_Bass_1 * 50

		for i = 1, 4 do

			local fr = (i * 256)

			local volume = f.ScaleVolume(f.FFT[math.Clamp(math.Round(i*f.mul_fft), 1, f.FFT_Size)], peak)

			if volume < 0.01 then continue end

			local n_fr = -(fr-30) + f.FFT_Size -- negative fr, f.FFT_Size to 0

			local f_fr = (fr-30)/f.FFT_Size -- fraction fr, 0, 1
			local nf_fr = n_fr/f.FFT_Size -- negative fraction, 1, 0

			local max = 32
			
			for i2 = 1, max do
				local pi = (i2/max) * math.pi * 2

				local size = (f.FFT_Bass_1 * 50 ^ 1.5)
				local color = HSVToColor((time+(pi*volume))%360, 1, 1)
				
				local velocity = Vector(math.sin(pi+i+time), -volume / 5, math.cos(pi+i+time)) * volume ^ 1.3
				velocity = velocity * 5

				local particle = f.emitter:Add("particle/Particle_Glow_04_Additive", f:GetSourcePos() + (velocity*5*f.scale))

				particle:SetVelocity(velocity*1000*f.scale)

				particle:SetLifeTime(0)
				particle:SetDieTime(math.Clamp(volume*0.2, 0.1, 0.8))

				particle:SetStartLength(size*3*f.scale * 2)
				particle:SetEndLength(size*1.5*f.scale)
				particle:SetStartSize(size*f.scale*volume*0.5)
				particle:SetEndSize(0)

				particle:SetStartAlpha(50)
				particle:SetEndAlpha(0)

				particle:SetAirResistance(math.Clamp((-size+800), 10, 1200)*f.scale)
				--particle:SetGravity((VectorRand()*50)*f.scale)

				particle:SetColor(color.r, color.g, color.b)
				particle:SetCollide(true)
				particle:SetBounce(0.1)
			end
		end
	end

	f.smooth_pp = 0
	f.look_at_mult = 0

	function flomp.DrawPostProcess()
		local w = ScrW()
		local h = ScrH()

		local vec2 = f.GetSourcePos():ToScreen()

		local m = math.max(f.eye_angles:Forward():DotProduct((f.GetSourcePos()-f.eye_origin):GetNormalized()), 0) ^ 3
		f.look_at_mult = m
		m = m * (f.sound_vol * 2) ^ 2
		m = m / 5
		
		--m = m * math.Clamp((-f.eye_origin:Distance(f.GetSourcePos()) / 15000) + 1, 0, 1)
	
		if m < 0.001 then return end

		m = math.Clamp(m, 0, 1)

		local vol = f.FFT_Bass_1
		local darkness = (-m+1)

		local avr = math.Clamp(vol * 2  - 0.1,0,1) * m
		local blur = math.Clamp((vol*-0.5)+1, 0.2, 1)
		local invert = (vol*-10+1)

		local angle = Angle(math.Rand(-1,1), math.Rand(-1,1), math.Rand(-1,1)) * f.GetAverage(3, 7) * m
		angle.x = math.Clamp(angle.p, -0.52, 0.52)
		angle.y = math.Clamp(angle.y, -0.52, 0.52)
		angle.z = 0
		LocalPlayer():SetEyeAngles(LocalPlayer():EyeAngles() + angle)

		f.smooth_pp = f.smooth_pp + ((avr - f.smooth_pp)*FrameTime()*10)

		local mscale = m * f.vol_multplier

		local tbl= {}
		tbl[ "$pp_colour_addr" ] = 0
		tbl[ "$pp_colour_addg" ] = 0
		tbl[ "$pp_colour_addb" ] = 0
		tbl[ "$pp_colour_brightness" ] = -0.02
		tbl[ "$pp_colour_contrast" ] = 1.1-m
		tbl[ "$pp_colour_colour" ] = 1.25+(m^0.75)
		tbl[ "$pp_colour_mulr" ] = 0
		tbl[ "$pp_colour_mulg" ] = 0
		tbl[ "$pp_colour_mulb" ] = 0


		--DrawMotionBlur(blur, 1, 0)
		--DrawBloom(darkness, invert*m, math.max(invert*20+2, 5), math.max(invert*20+10, 5), 4, 10, 1, 1, 1 )
		DrawSunbeams(0.9, math.max(vol/4, 0.1), 0.2, vec2.x / ScrW(), vec2.y / ScrH())
		DrawColorModify(tbl)
		--DrawToyTown(Lerp(avr, 0, 10), ScrH()*0.55)
		DrawSharpen(m*10,m)
		
		local avr = (flomp.GetAverage(3, 5) * 2.5) ^ 1.5
		flomp.fov = Lerp(avr ^ 1.5, 150, 60)
	end

	hook.Add("HUDPaint", "flomp_Helper", flomp.Spectrum2D)
	hook.Add("RenderScreenspaceEffects", "flomp_RenderScreenspaceEffects", flomp.DrawPostProcess)


	hook.Add("RenderScene", "flomp_CalcView", function(pos, ang)
		f.eye_origin = pos
		f.eye_angles = ang
	end)

	local voldata = Vector(0,0,0) -- V, L, R

	local function calcsource(eye, rgt, src, dist, fwd, vel)
		local vol = math.Clamp(-((eye - src):Length() / dist) + 1, 0, 1)
		local dot = rgt:Dot((src - eye):GetNormalized())

		local left = math.Clamp(-dot, 0, 1) + 0.5
		local right = math.Clamp(dot, 0, 1) + 0.5

		if vol ~= 0 then
			return vol, -left + right
		end
	end

	function GetVolumeData(source, falloff)
		local ply = LocalPlayer()
		return calcsource(ply:EyePos(),f.eye_angles:Right(), source, falloff, f.eye_angles:Forward(), ply:GetVelocity())
	end

	f.sound_vol = 0

	hook.Add("Think","flomp_volume",function()
		local vol, panning = GetVolumeData(flomp.GetSourcePos(), 4000)

		if vol then
			f.sound_vol = vol
			if not f.wowo then vol = vol * f.look_at_mult end
			
			hook.Call("FlompVolume", GAMEMODE, (vol^1.5)*2, panning)
		else
			hook.Call("FlompVolume", GAMEMODE, 0, 0)
		end
	end)


	hook.Add("HUDPaintBackground", "itsaparty")
	hook.Add("CalcView", "itsaparty")
	
	
	local last_peak = 1
	hook.Add("Spectrum", "flomp_spectrum", function(fft)
		
		local peak = 0
		
		for k,v in pairs(fft) do
			peak = math.max(peak, v)
			fft[k] = (fft[k] ^ 1.75) * 0.75
		end
		
		last_peak = 0
		
		flomp.SpectrumUpdate(fft, peak)
	end)
end

local size = 70

flomp.fov = 75-40
local t = 0
local offset = 6

function renderer:RenderOverride()
	cam.Start3D(EyePos() + (EyeAngles():Right() * offset) + (EyeAngles():Up() * offset), EyeAngles(), (flomp.fov or 0) + 40)
	--self:SetAngles(Angle(90,90, t*50%360))
	render.SuppressEngineLighting(true)
		render.MaterialOverride(mat_screenspace)
		--render.DrawSphere(self:GetPos(), -50, 32, 32, white)
		
		self:SetRenderOrigin(self:GetPos() + self:GetUp() * -size)
		scale(self, Vector(1,1,1) * size)
		self:SetupBones()
		self:DrawModel()
		
		render.CullMode(MATERIAL_CULLMODE_CW)
		self:SetRenderOrigin(self:GetPos() + self:GetUp() * size)
		scale(self, Vector(1,-1,1) * size)
		self:SetupBones()
		self:DrawModel()
		render.MaterialOverride()
		render.CullMode(MATERIAL_CULLMODE_CCW)
		
		self:SetRenderOrigin()
	render.SuppressEngineLighting(false)
	
	flomp.SetSource(self:GetPos())
	cam.End3D()
end

SafeRemoveEntity(fractal_tree)

local tree = ClientsideModel("models/props_combine/combinethumper001a.mdl")
tree:SetPos(LocalPlayer():EyePos() + LocalPlayer():GetAimVector() * 20)
timer.Simple(0.1, function()
	function tree:RenderOverride()
		t = t + flomp.FFT_Bass_1 / 1000
		
		--render.SetBlend(0.999)
		for i = 0, 16 do
			i = (i / 16) * 360
			scale(self, Vector(5,math.cos(t)*4,10))
			self:SetAngles(Angle(t+i, 0, math.sin(t)*180))
			self:SetupBones()
			render.SuppressEngineLighting(true)
			render.MaterialOverride(mat_screenspace)
			self:DrawModel()
			render.MaterialOverride()
			render.SuppressEngineLighting(false)
		end
		--render.SetBlend(1)
		
		self:SetPos(fractal_renderer:GetPos() + fractal_renderer:GetUp() * 200)
		
		cam.IgnoreZ(true)
		flomp.emitter:SetPos(self:GetPos())
		flomp.emitter:Draw()
		cam.IgnoreZ(false)
	end
end)

fractal_tree = tree

renderer:SetPos(Vector(-178, -3, -4777))
renderer:SetAngles(Angle(90,90,0))
renderer:Spawn()
renderer:SetRenderBounds(Vector(1,1,1)*-size*100, Vector(1,1,1)*size*100)

flomp.SetScale(1)
flomp.SetVolumeInputScale(3)
flomp.powscale = 1

fractal_renderer = renderer


hook.Add("RenderScene", "flomp_CalcView", function(pos, ang)
	f.eye_origin = pos
	f.eye_angles = ang
end)

local voldata = Vector(0,0,0) -- V, L, R

local function calcsource(eye, rgt, src, dist, fwd, vel)
    local vol = math.Clamp(-((eye - src):Length() / dist) + 1, 0, 1)
    local dot = rgt:Dot((src - eye):Normalize())

    local left = math.Clamp(-dot, 0, 1) + 0.5
    local right = math.Clamp(dot, 0, 1) + 0.5

    if vol ~= 0 then
		return vol, -left + right
    end
end

function GetVolumeData(source, falloff)
    local ply = LocalPlayer()
    return calcsource(ply:EyePos(),f.eye_angles:Right(), source, falloff, f.eye_angles:Forward(), ply:GetVelocity())
end

f.sound_vol = 0

hook.Add("Think","flomp_volume",function()
	local vol, panning = GetVolumeData(flomp.GetSourcePos(), 4000)

	if vol then
		f.sound_vol = vol
		if not f.wowo then vol = vol * f.look_at_mult end
		
		hook.Call("FlompVolume", GAMEMODE, (vol^1.5)*2, panning)
	else
		hook.Call("FlompVolume", GAMEMODE, 0, 0)
	end
end)


hook.Add("HUDPaintBackground", "itsaparty")
hook.Add("CalcView", "itsaparty")


local last_peak = 1
hook.Add("Spectrum", "flomp_spectrum", function(fft)
	
	local peak = 0
	
	for k,v in pairs(fft) do
		peak = math.max(peak, v)
		fft[k] = (fft[k] ^ 2) 
	end
	
	last_peak = 0
	
	flomp.SpectrumUpdate(fft, peak)
end)
	
flomp.SetSource(Vector(-5826.2895507812, -10898.263671875, -6722.1826171875))
flomp.SetScale(0.3)
flomp.SetVolumeInputScale(1.25)

flomp.powscale = 1.75

hook.Add("HUDPaintBackground", "itsaparty")
hook.Add("CalcView", "itsaparty")


function startmusic(URL)
	URL = URL or "http://dl.dropbox.com/u/244444/star.ogg"

	if html and html:IsValid() then html:Remove() end

	local html = vgui.Create("DHTML") _G.html = html

	html:AddFunction("gmod", "print", print)
	html:AddFunction("gmod", "data", function(data)
		pcall(function()
			local data = CompileString(data, "data")()
			hook.Call("Spectrum", nil, data)
		end)
	end)

	local player = setmetatable(
		{
		}, 
		{
			__index = function(self, func_name)
				return function(...)
					local tbl = {...}
					
					for key, val in pairs(tbl) do
						tbl[key] = tostring(val)
						
						if tbl[key] == "nil" or tbl[key] == "NULL" then
							tbl[key] = "null"
						end
					end
					
					local str = ("%s(%q)"):format(func_name, table.concat(tbl, ", "))
					html:QueueJavascript(str)
					--print(str)
				end
			end
		}
	)

	html:SetPos(ScrW(), ScrH())
	html:OpenURL("http://dl.dropbox.com/u/244444/gmod_audio.html")
	html:QueueJavascript[[
		var AudioContext = window.AudioContext || window.webkitAudioContext;

		window.onerror = function(desc, file, line)
		{
			gmod.print(desc)
			gmod.print(file)
			gmod.print(line)
		}

		var audio = new AudioContext
		var analyser = audio.createAnalyser()
		analyser.connect(audio.destination)
		
		setInterval(
			function()
			{
				var spectrum = new Uint8Array(analyser.frequencyBinCount);
				analyser.getByteFrequencyData(spectrum);
				
				var lol = new Array(spectrum.length);
				
				for(var i = 0; i < spectrum.length; ++i) 
					lol[i] = spectrum[i] / 255;
				
				gmod.data("return {" + lol.join(",") + "}");
			},
			10
		);
		
		function download(url, callback) 
		{
			var request = new XMLHttpRequest
			
			request.open("GET", url, true)
			request.responseType = "arraybuffer"
			request.send(null)
			
			request.onload = function() 
			{
				gmod.print("loaded \"" + url + "\"")
				gmod.print("status " + request.status)
				callback(request.response)
			}
			
			request.onprogress = function(event) 
			{
				gmod.print(Math.round(event.loaded / event.total * 100) + "%")
			}		
		}
		
		var source = audio.createBufferSource()
		var volctrl = audio.createGainNode()
		
		function play(url)				
		{				
			download(url, function(data)
			{
				gmod.print("decoding " + data.byteLength + " ...")
				audio.decodeAudioData(data, function(buffer) 
				{
					source = audio.createBufferSource()
					
					source.connect(analyser)
					analyser.connect(volctrl)
					volctrl.connect(audio.destination)
					
					source.buffer = buffer
					source.loop = true
					source.noteOn(0)
					
					gmod.print("LOADED AND DECODED")
				}, 
				function(err)
				{
					gmod.print("decoding error " + err)
				})
			})
		}
		
		function SetVolume(vol)
		{
			if(volctrl) volctrl.gain.value = vol
		}
	]]

	player.play(URL)
	
	timer.Simple(1, function()
		timer.Create("fractals",0,0, function()
			if not html and html:IsValid() then return end
			player.SetVolume(f.look_at_mult-1)
		end)
	end)
end

if not html then
	startmusic()
end