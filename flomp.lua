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

			local size = (f.FFT_Bass_1 * 20 ^ 1.5)
			local color = HSVToColor((time+(f_fr*100))%360, 0.3, 1)
			local velocity = ((f.eye_origin - f.GetSourcePos() ):Normalize() * 2 + VectorRand()):GetNormal()* volume ^ 1.3

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

	local m = math.max(f.eye_angles:Forward():DotProduct((f.GetSourcePos()-f.eye_origin):Normalize()), 0) ^ 3
	f.look_at_mult = m
	m = m * (f.sound_vol * 2) ^ 2

	--m = m * math.Clamp((-f.eye_origin:Distance(f.GetSourcePos()) / 15000) + 1, 0, 1)

	if m < 0.001 then return end

	m = math.Clamp(m, 0, 1)

	local vol = f.FFT_Bass_1
	local darkness = (-m+1)

	local avr = math.Clamp(vol * 2  - 0.1,0,1) * m
	local blur = math.Clamp((vol*-0.5)+1, 0.2, 1)
	local invert = (vol*-10+1)

	local angle = VectorRand() * f.GetAverage(3, 7) ^ 1.5 * m * 5
	angle.x = math.Clamp(angle.x, -0.52, 0.52)
	angle.y = math.Clamp(angle.y, -0.52, 0.52)
	angle.z = 0
	LocalPlayer():SetEyeAngles(LocalPlayer():EyeAngles() + angle)

	f.smooth_pp = f.smooth_pp + ((avr - f.smooth_pp)*FrameTime()*10)

	local mscale = m * f.vol_multplier

	local tbl= {}
	tbl[ "$pp_colour_addr" ] = 3/255*m
	tbl[ "$pp_colour_addg" ] = 0
	tbl[ "$pp_colour_addb" ] = 4/255*m
	tbl[ "$pp_colour_brightness" ] = -0.05*m
	tbl[ "$pp_colour_contrast" ] = Lerp(m, 1, 1.5)
	tbl[ "$pp_colour_colour" ] = 1+(0.4*m)
	tbl[ "$pp_colour_mulr" ] = 0
	tbl[ "$pp_colour_mulg" ] = 0
	tbl[ "$pp_colour_mulb" ] = 0


	--DrawMotionBlur(blur, 1, 0)
	DrawBloom(darkness, invert*(m/20), math.max(invert*20+2, 5), math.max(invert*20+10, 5), 4, 3, 1, 1, 1 )
	DrawSunbeams(darkness+0.2, math.max(vol*0.5, 0.1), 0.05 * (vol * 20) ^ 1.5, vec2.x / ScrW(), vec2.y / ScrH())
	DrawColorModify(tbl)
	DrawToyTown(Lerp(avr, 0, 10), ScrH()*0.55)

	if materials.SetSkyColor then 
		materials.SetSkyColor(Vector()*(darkness ^ 2))
	end
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

flomp.SetSource(Vector(9668.3935546875, -3830.9357910156, -6239.7133789062))
flomp.SetScale(0.15)
flomp.SetVolumeInputScale(5)

hook.Add("HUDPaintBackground", "itsaparty")
hook.Add("CalcView", "itsaparty")

if require("bass_edit2") then 
	function flomp.PlayURL(url)
		flomp.SetScale(1.5)
		flomp.SetVolumeInputScale(10)
		flomp.powscale = 0.7
		if flomp_current_channel then
			flomp_current_channel:stop()
			flomp_current_channel = nil
		end
		BASS.StreamFileURL(url, 0, function(channel, err)	
			if err == 0 then
				flomp_current_channel = channel
				channel:play(true)
				
				hook.Add("Think", 1, function()
					if channel:getplaying() then
						flomp.SpectrumUpdate(channel:fft2048())
					end
				end)
				
				hook.Add("FlompVolume", 1, function(vol, pan)
					
					--channel:setpos(vol)
				end)
			else
				print("bass can't play file " .. url .. ". errors with error code: " .. err)
			end
		end)
	end
	
	flomp.PlayURL("http://dl.dropbox.com/u/244444/boxed.mp3")
end