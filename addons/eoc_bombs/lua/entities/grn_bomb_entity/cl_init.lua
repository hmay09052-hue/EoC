-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
include('shared.lua')

function ENT:Draw()
    self:DrawModel()

    if not self:GetNWBool('GRN_BombGlow', false) then return end
    local pos = self:GetPos() + Vector(0,0,18)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        SY_RoundedBox(6, -120, -18, 240, 36, Color(15,15,15,220))
        draw.SimpleText(self:GetNWString('GRN_BombName', 'Bomb'), 'Trebuchet24', 0, -2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.upper(self:GetNWString('GRN_BombType', 'explosive')), 'Trebuchet18', 0, 14, Color(0,220,220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
