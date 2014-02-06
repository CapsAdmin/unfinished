local function escape(s)
    return string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02x", string.byte(c))
    end)
end

local function geturl(str, to, from)
	from = from or "en"
	assert(str)
	assert(to)
	return ("http://translate.google.com/translate_a/t?client=t&text=%s&sl=%s&tl=%s&ie=UTF-8&oe=UTF-8"):format(escape(str), from, to)
end

local function translate(str, from, to, callback)
	http.Fetch(geturl(str, to, from), function(data)
		local res = data:match("%[%[%[\"(.-)\"")
		callback(res)
	end)
end

google_translate = translate


local jp = 
{
	player.GetByUniqueID(--[[[JP]gordon freeman]] "3814210471"),
	player.GetByUniqueID(--[[acchan]] "1115178630"),
	player.GetByUniqueID(--[[TM02]] "3650594320"),	
}

jp = nil

local function checkA(ply)
	ply = ply or LocalPlayer()
	
	if jp then
		return not table.HasValue(jp, ply)
	end
	
	return 
		ply == arctic or 
		ply == caps or 
		ply == shell or 
		ply == funt or 
		ply == newbieking or 
		ply == kesor or 
		ply == morshmellow or 
		ply == player.GetByUniqueID(--[[urgent appeal for bones]] "4252829127") or
		ply == whey or 
		ply == player.GetByUniqueID(--[[깜쮞읭]] "2759125494") or 
		ply == adam
end

local function checkB(ply)
	--ply = ply or LocalPlayer()
	--return ply == bubu
	return not checkA(ply)
	
	--return true --ply == bubu
end

if CLIENT then
	if checkA() then
		hook.Add("OnPlayerChat", "1", function(ply, str)
			if ply == LocalPlayer() then 
			return end
				
			translate(str, "ja", "en", function(str) 
				chat.AddText(unpack(chat.AddTimeStamp({ply, color_white, ": ", str})))
				hook.Call("OnPlayerChatTranslated", GAMEMODE, ply, str)
			end)
					
			return true
		end)
	end

	if jp and checkB() then
		hook.Add("OnPlayerChat", "1", function(ply, str)
			if ply == LocalPlayer() then 
			return end
				
			translate(str, "auto", "ja", function(str) 
				chat.AddText(unpack(chat.AddTimeStamp({ply, color_white, ": ", str})))
				hook.Call("OnPlayerChatTranslated", GAMEMODE, ply, str)
			end)
					
			return true
		end)
	end
	
	local function handle(ply, out, str)
		if not ply:IsValid() then return end
		
		chat.AddText(unpack(chat.AddTimeStamp({ply, color_white, ": ", out})))
		hook.Call("OnPlayerChatTranslated", GAMEMODE, ply, str)
		if chatsounds then
			chatsounds.Say(ply, str, out..str)
		end
	end
	
	net.Receive("tr", function()
		if checkB() then return end
		local tbl = net.ReadTable()
		handle(unpack(tbl))
	end)
end

if SERVER then
	util.AddNetworkString("tr")
	hook.Add("PlayerSay", "1", function(ply, str)
		if str:sub(1,1) ~= "!" and not str:find("http") and not str:find("/", nil, true) then
			if checkA(ply) then
				translate(str, "auto", "ja", function(out) 
					net.Start("tr")
						net.WriteTable({ply, out, str})
					net.Broadcast()
				end)
				
				--return ""
			end
			
			if checkB(ply) then
				translate(str, "ja", "en", function(out) 
					net.Start("tr")
						net.WriteTable({ply, out, str})
					net.Broadcast()
				end)
			end
		end
	end)
end

hook.Remove("OnPlayerChat", 1)
hook.Remove("PlayerSay", 1)

