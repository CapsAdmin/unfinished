if IsValid(head_panel) then head_panel:Remove() end

local pnl = vgui.Create("DModelPanel") -- make button and parent it to my (the main framz)

pnl:SetPos(0,0)
pnl:SetSize(500, 500)
pnl:Center()

pnl:SetModel(LocalPlayer():GetModel()) -- set the text on the button

pnl:SetCamPos(Vector(100,0,72))
pnl:SetLookAt(Vector(0,0,65))
pnl:SetFOV(9)

local smooth_x = 0
local smooth_y = 0

pnl.LayoutEntity = function(self, ent)   
	local speed = FrameTime() * 18
	local msx, msy = gui.MousePos()

	local x, y = self:LocalToScreen()

	x = x + self:GetWide() * 0.5
	y = y + self:GetTall() * 0.5

	x = (x - msx) / ScrW()
	y = (y - msy) / ScrH()

	y = math.Clamp(y * 40, -30, 30)
	x = math.Clamp(x * 40, -30, 30)

	smooth_x = smooth_x + ((x - smooth_x) * speed)
	smooth_y = smooth_y + ((y - smooth_y) * speed)

	local bone = ent:LookupBone("valvebiped.bip01_head1")
	
	if bone then
		ent:ManipulateBoneAngles(bone, Angle(0, smooth_y, -smooth_x))		
		ent:SetSequence(0)
	end
end

head_panel = pnl