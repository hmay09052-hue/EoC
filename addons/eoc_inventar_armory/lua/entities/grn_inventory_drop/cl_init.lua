include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    self:DrawModel()
    if not GRNInventory or not GRNInventory.Config or not GRNInventory.Config.ShowWorldLabels then return end

    local lp = LocalPlayer()
    if not IsValid(lp) or lp:GetPos():DistToSqr(self:GetPos()) > (240 * 240) then return end

    local def = GRNInventory.GetItemDefinition(self:GetItemID())
    if not def then return end

    local pos = self:GetPos() + Vector(0, 0, 18)
    local ang = EyeAngles()
    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Up(), -90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
        local SY = SYMUI
        if SY then
            -- Etikett im SymChars-Look (abgeschrägte Platte, Akzentkante, Holo-Schriften)
            local name = string.upper(def.Name or self:GetItemID())
            surface.SetFont("symchars.world.h")
            local w = math.max(300, surface.GetTextSize(name) + 60)
            SY.Cut(-w / 2, -34, w, 68, Color(9, 11, 14, 225), 12, "tlbr")
            SY.CutOutline(-w / 2, -34, w, 68, SY.Accent(120), 12, "tlbr")
            SY.Box(-w / 2, -22, 4, 44, SY.Accent())
            draw.SimpleText(name, "symchars.world.h", 0, -12, SY.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("x" .. tostring(self:GetItemQuantity()), "symchars.world.small", 0, 16, SY.Accent(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
            return
        end
        draw.RoundedBox(4, -150, -30, 300, 60, Color(6, 10, 18, 220))
        surface.SetDrawColor(255, 190, 50, 220)
        surface.DrawRect(-150, -30, 4, 60)
        draw.SimpleText(string.upper(def.Name or self:GetItemID()), "DermaLarge", 0, -13, Color(235, 241, 248), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("x" .. tostring(self:GetItemQuantity()), "DermaDefaultBold", 0, 13, Color(255, 190, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
