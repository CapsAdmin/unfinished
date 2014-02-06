local text = [[Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer vel enim quis neque pellentesque vulputate a vel orci. Sed mattis adipiscing lorem et convallis. Aenean mattis iaculis tortor, facilisis posuere justo mollis vitae. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse libero elit, aliquet nec euismod sit amet, viverra id urna. Aliquam rutrum feugiat felis ut condimentum. Ut eget augue et sem vestibulum aliquet.Phasellus a nunc a purus mollis interdum. Nunc sit amet consectetur mauris. Integer a massa sed leo porta congue sit amet ac diam. Cras auctor velit vitae elit varius vitae molestie odio placerat. In at felis nisl, at pulvinar neque. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Morbi laoreet, massa nec placerat adipiscing, velit nunc interdum erat, ut venenatis magna enim non magna. Nulla facilisi.In volutpat pellentesque tellus, vel dictum augue ullamcorper cursus. Nulla facilisi. Sed sed mi sed quam tempor malesuada. In hac habitasse platea dictumst. Integer imperdiet volutpat lectus, lobortis facilisis tellus vestibulum nec. Vivamus rhoncus neque ut urna faucibus nec mattis tortor iaculis. Nulla risus augue, tristique nec commodo at, hendrerit quis dui.Cras fringilla ultricies massa vel malesuada. Aliquam libero ante, pharetra dapibus blandit eget, cursus eu eros. Nullam euismod tincidunt nunc, sit amet egestas ante iaculis vel. Etiam lobortis rhoncus diam ut gravida. Integer massa est, faucibus et ornare at, semper non tellus. Mauris vitae enim nulla, in dignissim augue. Fusce sit amet eros in augue consectetur vehicula eu venenatis velit. Nam id metus velit, cursus fringilla lorem. Aenean imperdiet tempus urna. Pellentesque ipsum augue, hendrerit a consectetur sed, suscipit vel odio. Aenean massa nulla, pellentesque semper sodales ut, rutrum et est. Cras nec erat nec metus laoreet faucibus eget quis leo. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nunc sodales risus sed risus vestibulum semper.Sed vitae urna augue. Maecenas lacinia ullamcorper arcu, ac luctus felis laoreet id. Duis congue, ligula quis scelerisque suscipit, dui ligula mattis eros, eu convallis purus nisi a lorem. Donec rhoncus fermentum augue eget molestie. Nulla ultricies, arcu vel scelerisque tincidunt, purus magna dapibus lacus, nec sollicitudin velit ipsum vel neque. Morbi ullamcorper nulla eget lectus bibendum consectetur. Ut tristique nisi nec leo elementum dictum venenatis purus posuere. Maecenas augue risus, tincidunt in mattis et, sollicitudin id quam.]]
local font = "hudnumber5"

text = text:reverse()

local function DrawScreen()
    local time = CurTime() * 30
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont(font)
    local i = 0
    for letter in text:gmatch("(.)") do
        i = i + 1
        local c = HSVToColor(math.abs(i+#text+time)%255, 1, 1)
        local _,size = surface.GetTextSize(letter)
        size = size * 0.7
       surface.SetTextColor(c.r, c.g, c.b, 255)
       surface.SetTextPos((time%(#text*size)) - (i*size), (math.sin(i+time*0.1)*10) + 128 - 12.5)
       surface.DrawText(letter)
    end
end





local new = GetRenderTarget("test_rt", 256, 256, true)

hook.Add("RenderScene", "test", function()
    local old, w, h = render.GetRenderTarget(), ScrW(), ScrH()
    
    render.SetRenderTarget(new)
        local c = HSVToColor((CurTime()*60)%360, 0.5, 0.2)
          render.Clear(c.r, c.g, c.b, 255, false) 
        render.SetViewPort(0, 0, 256, 256)
            cam.Start2D()
                DrawScreen()
            cam.End2D()
        render.SetViewPort(0, 0, w, h)
    render.SetRenderTarget(old)
end)


local mat = CreateMaterial("test_rt_mat", "VertexLitGeneric", 
    {
        ["$basetexture"] = "test_rt",
    }
)

local ENT = this

function ENT:RenderOverride()
    SetMaterialOverride(mat)
        self:DrawModel()
    SetMaterialOverride()
end