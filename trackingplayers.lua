tracker = tracker or {} local t = tracker

t.Recorded = t.Recorded or {}
t.ActiveProps = {}

t.index = t.index or 0

for key, entity in pairs(ents.FindByClass("prop_dynamic")) do
	if entity.istracker then
		entity:Remove()
	end
end

t.ActiveProps = {}

function tracker.GetAllTrackers()
	local tbl = {}
	for key, entity in pairs(ents.FindByClass("prop_dynamic")) do
		if entity.istracker then
			table.insert(tbl, entity)
		end
	end
	return tbl
end

hook.Add("Tick", "Tracking", function()
	for key, ply in pairs(player.GetAll()) do
		if ply.AllowTracking and ply:GetVelocity():Length() > 5 and ply:IsInWorld() and t.Recorded[ply:UniqueID()] and t.Recorded[ply:UniqueID()][ply.AllowTracking] then
			table.insert(t.Recorded[ply:UniqueID()][ply.AllowTracking], ply:GetPos())
		end
	end
	
	for uniqueid, tbl in pairs(t.Recorded) do
		for id, vectors in pairs(tbl) do
			if vectors.finished == true then continue end
			t.ActiveProps[uniqueid..id] = t.ActiveProps[uniqueid..id] or ents.Create("prop_dynamic")
			local p = t.ActiveProps[uniqueid..id]
			if not IsValid(p) then
				p:Remove()
				t.ActiveProps[uniqueid..id] = nil
			end
			if not p.Spawned then
				p:SetModel(table.Random(player_manager.AllValidModels()))
				p:Spawn()
				p.Spawned = true
				p.index = 0
				p.istracker = true
				p.max = #vectors
				local ply = player.GetByUniqueID(uniqueid)
				if IsValid(ply) then
					COH.UpdateMessage(p, ply:Nick())
				else
					p:SetModel("models/props_halloween/ghost.mdl")
					p.isghost = true
				end
				
				--print("PLAYING TRACK", uniqueid, id)
				
				hook.Add("Tick", "PlayerTrackingTimer"..uniqueid..id, function()
					
					if vectors[p.index] == true then return end
					if not IsValid(p) then error("TRACKER IS INVALID") end
					
					if p.isghost and math.random() > 0.99 then
						p:EmitSound("vo/taunts/spy_taunts05.wav", 100, math.random(20, 60))
					end

					p.index = p.index + 1
									
					if p.index > p.max then	
						p:Remove()
						--print("TRACKER IS DONE", p, uniqueid, id)
						hook.Remove("Tick", "PlayerTrackingTimer"..uniqueid..id)
						t.ActiveProps[uniqueid..id] = nil
					end

					if vectors[p.index] then
					
						if vectors[p.index] == vector_origin then 
							p:Remove() 
							t.ActiveProps[uniqueid..id] = nil
							t.Recorded[uniqueid][id] = nil
							print("INVALID RECORDING", uniqueid, id)
						return end
						
						local velocity = vectors[p.index] - vectors[math.max(p.index-5, 1)]
						
						local angle = (velocity):Angle()
						angle.p = 0
						angle.r = 0
						
						local fade = math.min(math.sin((p.index / #vectors) * math.pi) * 5, 1)
						
						p:SetColor(255,255,255,fade*255)
						p:SetPos(vectors[p.index])
						p:SetAngles(angle)
						p:SetPlaybackRate(velocity:Length()/20)
												
						if velocity:Length() < 10 then
							p:ResetSequence(p:LookupSequence("idle_all"))
						else
							p:ResetSequence(p:LookupSequence("run_all"))
						end
						--local cycle = CurTime()*velocity:Length()/10%1
						--print(cycle)
						--p:SetCycle(0)
					end
				end)
			end
		end
	end
end)

hook.Add("Tick", "PickRandomPlayerToTrack", function(ply)

	if math.random() < 0.9996 then return end
	
	local ply = table.Random(player.GetAll())
	
	if ply.AllowTracking then return end
	
	--timer.Simple(math.random(50), function()
		
		--if not IsValid(ply) then return end
	
		t.index = t.index + 1

		local index = t.index
	
		ply.AllowTracking = index
		
		t.Recorded[ply:UniqueID()] = t.Recorded[ply:UniqueID()] or {}
		t.Recorded[ply:UniqueID()][index] = {}
		
		print("START TRACKING", ply, index)
		--print(tostring(t.Recorded[ply:UniqueID()]), tostring(t.Recorded[ply:UniqueID()][index]), t.index, index)
		
		timer.Simple(math.random(50,100), function()
			if IsValid(ply) then
				ply.AllowTracking = false
				--print(tostring(t.Recorded[ply:UniqueID()]), tostring(t.Recorded[ply:UniqueID()][index]), t.index, index)
				t.Recorded[ply:UniqueID()][index].finished = true
				print("END TRACKING", ply, index)
			end
		end)
	--end)
end)