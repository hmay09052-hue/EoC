include("shared.lua")

local ACCENT = Color(252, 178, 73)
local TEXT = Color(236, 233, 224)

surface.CreateFont("GRNWardrobeLabel", { font = "Roboto Condensed", size = 64, weight = 800, extended = true })
surface.CreateFont("GRNWardrobeSub", { font = "Roboto Condensed", size = 26, weight = 600, extended = true })

local function wardrobeEntityConfig()
    local W = GRNStore and GRNStore.Config and GRNStore.Config.Armory and GRNStore.Config.Armory.Wardrobe
    return istable(W) and istable(W.Entity) and W.Entity or {}
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    local cfg = wardrobeEntityConfig()
    local maxDist = tonumber(cfg.LabelMaxDistance) or 700
    local eye = EyePos()
    local pos = self:GetPos() + Vector(0, 0, tonumber(cfg.LabelOffset) or 92)
    if eye:DistToSqr(pos) > maxDist * maxDist then return end

    -- Always faces the viewer.
    local yaw = (eye - pos):Angle().y + 90
    cam.Start3D2D(pos, Angle(0, yaw, 90), 0.08)
        local label = tostring(cfg.Label or "KLEIDERSCHRANK")
        surface.SetFont("GRNWardrobeLabel")
        local w = surface.GetTextSize(label)
        draw.RoundedBox(0, -w / 2 - 24, -44, w + 48, 108, Color(10, 12, 16, 200))
        draw.RoundedBox(0, -w / 2 - 24, -44, 6, 108, ACCENT)
        draw.SimpleText(label, "GRNWardrobeLabel", 0, -6, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("RÜSTUNG · AUSRÜSTEN", "GRNWardrobeSub", 0, 40, ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
