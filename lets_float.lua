if SERVER then
	hook.Add("PPhys",1,function(ply, ent, phys)
		if phys:IsValid() then
			phys:EnableGravity(false)

			ply.mousex = ply.mousex or 0
			ply.mousey = ply.mousey or 0

			if not ent.thrust_sound then
				ent.thrust_sound = CreateSound(ent, "ambient/gas/cannister_loop.wav")
				ent.thrust_sound:Play()
			end

			local dir = Vector(0,0,0)
			local eye = ent:GetAngles()
			local aim = eye:Forward()
			local side = eye:Right()
			local mult = 6

			local vol = 0

			if ply.mousex ~= 0 or ply.mousey ~= 0 then
				vol = 1
			end

			if ply:KeyDown(IN_SPEED) then
				mult = mult * 2
			end

			if ply:KeyDown(IN_FORWARD) then
				phys:AddVelocity(aim * mult)
				vol = 1
			end

			if ply:KeyDown(IN_JUMP) then
				phys:AddVelocity(eye:Up() * mult)
				vol = 1
			end

			if ply.crouching then
				phys:AddVelocity(eye:Up() * -mult)
				vol = 1
			end

			if ply:KeyDown(IN_BACK) then
				phys:AddVelocity(aim * -mult)
				vol = 1
			end

			if ply:KeyDown(IN_MOVELEFT) then
				if ply:KeyDown(IN_WALK) then
					phys:AddAngleVelocity(Angle(-mult*0.3, 0, 0))
				else
					phys:AddVelocity(side * -mult)
				end
				vol = 1
			end

			if ply:KeyDown(IN_MOVERIGHT) then
				if ply:KeyDown(IN_WALK) then
					phys:AddAngleVelocity(Angle(mult*0.3, 0, 0))
				else
					phys:AddVelocity(side * mult)
				end
				vol = 1
			end

			ent.thrust_sound:ChangeVolume(vol)
			ent.thrust_sound:ChangePitch(200)

			phys:AddAngleVelocity(Angle(0, ply.mousey*0.05, -ply.mousex*0.05))

			phys:AddVelocity(-phys:GetVelocity()*0.01)
			phys:AddAngleVelocity(-phys:GetAngleVelocity()*0.01)

			--ply:SetDSP(14)
		end
	end)

	hook.Add("Move",1,function(ply)
		if ply:HasPlayerPhysics() then
			local cmd = ply:GetCurrentCommand()

			ply.mousex = cmd:GetMouseX()
			ply.mousey = cmd:GetMouseY()
		end
	end)

	concommand.Add("+thrust_crouch", function(ply, _, args)
		ply.crouching = true
	end)

	concommand.Add("-thrust_crouch", function(ply, _, args)
		ply.crouching = false
	end)
end

if CLIENT then
	hook.Add("SetPlayerPhysics", 1, function(ply, ent)
		ply.pphys_request_duck = true
	end)

	hook.Add("CreateMove", 1, function(ucmd)
		local ply = LocalPlayer()
		if ply:HasPlayerPhysics() then
			ucmd:SetViewAngles(Angle(0,0,0))

			if ply.pphys_request_duck then
				RunConsoleCommand("+duck")
			end
		end
	end)

	hook.Add("PlayerBindPress", 1,function(ply, bind, pressed)
		if not  bind:find("duck") then return end
		if ply.pphys_request_duck then
			ply.pphys_request_duck = nil
			RunConsoleCommand("-duck")
		return end

		if ply:HasPlayerPhysics() then

			if pressed then
				RunConsoleCommand("+thrust_crouch")
			else
				RunConsoleCommand("-thrust_crouch")
			end

			print(pressed)

			return true
		end
	end)
end