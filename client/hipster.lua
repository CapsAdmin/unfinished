local SEED = "56a6s5as"
local intensity = 0.08

function R(min, max, seed)
    seed = seed or SEED
    min = min or 0
    max = max or 2

    return min + (max - min) * ((util.CRC(seed) * 0.000000001)%1)
end

local mat = Material("particle/Particle_Glow_04_Additive")

local hipsters = {}

for i=1, R(20) do
    local col = HSVToColor(R()*360, R(0.8, 1), intensity)

    hipsters[i] =
    {
        col = col,
        size = {x = R(500,4000, SEED .. "a"), y = R(500,4000, SEED .. "b")},
        pos = {x = R(ScrW(), nil, SEED .. "a"), y = R(ScrH(), nil, SEED .. "a")},
    }

    SEED = SEED .. tostring(i)
end

hook.Add("PostRenderVGUI", "hip", function()
    surface.SetMaterial(mat)
    for key, hipster in pairs(hipsters) do
        surface.SetDrawColor(hipster.col)
        surface.DrawTexturedRect(
            hipster.pos.x - (hipster.size.x * 0.5),
            hipster.pos.y - (hipster.size.y * 0.5),

            hipster.size.x,
            hipster.size.y
        )
    end
end)