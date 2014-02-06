if IsValid(my) then my:Remove() end

my = vgui.Create("DPanel") -- frame is make my main yes, yes
my:SetSize(400,400) -- set size to 100 widht and 100 height in pixelz
my:Dock(LEFT)
my:Dock(TOP)-- center this shit
my:SetPaintBackground(false)

local uhoh = vgui.Create("DModelPanel", my) -- make button and parent it to my (the main framz)
uhoh:Dock(FILL) -- make it fill the frame
uhoh:SetModel(LocalPlayer():GetModel()) -- set the text on the button
uhoh:SetFOV(15)
uhoh:SetLookAt(Vector(0,0,200))
uhoh:SetCamPos(Vector(5000,0,200))
uhoh.LayoutEntity = function(self, ent)
   ent:SetSequence(0)
end
local smooth_x, smooth_y = 0,0
uhoh:GetEntity().BuildBonePositions = function(s)
   if not vgui.CursorVisible() then
      my:SetSize(399,400)
      return
   end
   my:SetSize(400,400)

   local index = s:LookupBone(BONE_HEAD)
   local mat = s:GetBoneMatrix(index)

   local msx, msy = gui.MousePos()

   msx = ENGINEER_LOOK_AT_X or msx
   msy = ENGINEER_LOOK_AT_Y or msy


   local x,y = my:GetPos()
   x = x + my:GetWide()*0.5
   y = y + my:GetTall()*0.5
   x,y = -((x-msx)/ScrW()), (((y)-msy)/ScrH())

   y = math.Clamp(y*40, -30, 30)
   x = math.Clamp(x*40, -30, 30)

   smooth_x = smooth_x + ((x - smooth_x) * FrameTime()*18)
   smooth_y = smooth_y + ((y - smooth_y) * FrameTime()*18)

   mat:Rotate(Angle(0, smooth_y, smooth_x))
   mat:Scale(Vector()*60)
   s:SetBoneMatrix(index, mat)
   s:SetEyeTarget(VectorRand()*1000)

end