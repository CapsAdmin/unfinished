if SERVER then return end

flomp = flomp or {} local f = flomp

flomp.emitter = ParticleEmitter(EyePos(), false)

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

function flomp.ScaleVolume(volume)
	return (volume ^ flomp.powscale) * f.vol_multplier * 7
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

function flomp.SpectrumUpdate(data)
	f.FFT = data

	f.FFT_Bass_1 = flomp.GetAverage(1, 6)
	
	time = time + f.FFT_Bass_1 * 50

	for i = 1, 4 do

		local fr = (i * 256)

		local volume = f.ScaleVolume(f.FFT[math.Clamp(math.Round(i*f.mul_fft), 1, f.FFT_Size)])

		if volume < 0.01 then continue end

		local n_fr = -(fr-30) + f.FFT_Size -- negative fr, f.FFT_Size to 0

		local f_fr = (fr-30)/f.FFT_Size -- fraction fr, 0, 1
		local nf_fr = n_fr/f.FFT_Size -- negative fraction, 1, 0

		for i = 1, math.Clamp(math.Round(volume*4),0,15) do

			local size = (f.FFT_Bass_1 * 15 ^ 1.8)
			local color = HSVToColor((time+(f_fr+volume*100))%360, f.FFT_Bass_1*20, 1)
			local velocity = ((f.eye_origin - f.GetSourcePos() ):Normalize() * 2 + VectorRand()):GetNormal()* volume ^ 2 * 5

			local particle = f.emitter:Add("particle/Particle_Glow_04_Additive", f:GetSourcePos() + (velocity*5*f.scale))

			particle:SetVelocity(velocity*500*f.scale)

			particle:SetLifeTime(0)
			particle:SetDieTime(math.Clamp(volume*0.2, 0.1, 0.8))

			particle:SetStartLength(size*7*f.scale)
			particle:SetEndLength(size*2*f.scale)
			particle:SetStartSize(size*f.scale)
			particle:SetEndSize(0)

			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)

			particle:SetAirResistance(math.Clamp((-size+800), 10, 2000)*f.scale*1.5)
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

	local m = 1
	m = m * (f.sound_vol * 2) ^ 2
	m = m * math.Clamp((-f.eye_origin:Distance(f.GetSourcePos()) / 8000) + 1.1, 0, 1)
	m = m * math.max(f.eye_angles:Forward():DotProduct((f.GetSourcePos()-f.eye_origin):Normalize()), 0) ^ 3
	
	f.look_at_mult = m

	if m < 0.001 then return end

	m = math.Clamp(m, 0, 1) * 1.5

	local vol = f.FFT_Bass_1 ^ 1.5
	local darkness = (-m+1)

	local avr = math.Clamp(vol * 2  - 0.1,0,1) * m
	local blur = math.Clamp((vol*-0.5)+1, 0.2, 1)
	local invert = (vol*-10+1)

	local angle = Angle(math.Rand(-1,1), math.Rand(-1,1), math.Rand(-1,1)) * f.GetAverage(3, 7) ^ 1.75 * m * 0.15
	angle.p = math.Clamp(angle.p, -0.52, 0.52)
	angle.y = math.Clamp(angle.y, -0.52, 0.52)
	angle.r = 0
	LocalPlayer():SetEyeAngles(LocalPlayer():EyeAngles() + angle)

	f.smooth_pp = f.smooth_pp + ((avr - f.smooth_pp)*FrameTime()*10)

	local mscale = m * f.vol_multplier

	local tbl= {}
	tbl[ "$pp_colour_addr" ] = 3/255*m
	tbl[ "$pp_colour_addg" ] = 0
	tbl[ "$pp_colour_addb" ] = 4/255*m
	tbl[ "$pp_colour_brightness" ] = -0.05*m
	tbl[ "$pp_colour_contrast" ] = Lerp(m, 0.75, 1.25)
	tbl[ "$pp_colour_colour" ] = 1.15+(0.4*m)
	tbl[ "$pp_colour_mulr" ] = 0
	tbl[ "$pp_colour_mulg" ] = 0
	tbl[ "$pp_colour_mulb" ] = 0

	--DrawMotionBlur(blur, 1, 0)
	--DrawBloom(darkness, invert*(m/20), math.max(invert*20+2, 5), math.max(invert*20+10, 5), 4, 3, 1, 1, 1 )
	DrawSunbeams(0.8, math.max(vol*0.25, 0.1), 0.1 * vol ^ 2, vec2.x / ScrW(), vec2.y / ScrH())
	DrawColorModify(tbl)
	--DrawToyTown(Lerp(avr, 0, 10), ScrH()*0.55)
	
	--print(blur)
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
flomp.SetScale(0.6)
flomp.SetVolumeInputScale(0.75)

flomp.powscale = 1.75

hook.Add("HUDPaintBackground", "itsaparty")
hook.Add("CalcView", "itsaparty")


function startmusic(URL)
	URL = URL or "http://dl.dropbox.com/u/244444/insect.ogg"

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