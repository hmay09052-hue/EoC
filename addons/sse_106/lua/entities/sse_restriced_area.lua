AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Restricted Area Sign"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.RestrictedSign["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox


 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


if SERVER then
        

    function ENT:Use( activator, caller )



    end


end


if CLIENT then

    -- Warnschild im Server-Design: rote Kopfleiste mit Warnstreifen, Aurebesh-Zeile, Hinweise
    local function DrawSign()
        local UI = SSE.UI
        local cfg = SSE.Config.RestrictedSign
        local red = cfg["Color1"] or UI.col.red
        local x, y, w, h = -380, -20, 760, 330

        UI.Cut(x, y, w, h, Color(9, 11, 14, 235), 24, "tlbr")
        UI.CutOutline(x, y, w, h, UI.Alpha(red, 220), 24, "tlbr")

        -- Kopfleiste mit Warnstreifen
        local hh = 120
        UI.Cut(x, y, w, hh, UI.Alpha(red, 230), 24, "tl")
        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 70)
        for sx = x + 30, x + w - hh - 22, 48 do
            surface.DrawPoly({ { x = sx, y = y + hh }, { x = sx + hh, y = y }, { x = sx + hh + 22, y = y }, { x = sx + 22, y = y + hh } })
        end
        draw.SimpleText(string.upper(cfg["Text1"]), "sse.world.big", 0, y + hh / 2 - 6, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        UI.Aurebesh(cfg["Text1"], "sse.world.aure.big", 0, y + hh + 10, UI.Alpha(red, 230), TEXT_ALIGN_CENTER)
        draw.SimpleText(string.upper(cfg["Text2"]), "sse.world.title", 0, y + hh + 92, cfg["Color2"] or UI.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        UI.Box(x + 60, y + hh + 138, w - 120, 2, UI.Alpha(red, 160))
        draw.SimpleText(string.upper(cfg["Text4"]), "sse.world.small", 0, y + hh + 165, cfg["Color4"] or UI.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.upper(cfg["Text3"]), "sse.world.small", 0, y + hh + 195, cfg["Color3"] or UI.col.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    function ENT:Draw()
        self:DrawModel()

        -- Get Model Height
        local min, max = self:GetModelBounds()
        local height = max.z - min.z

        local imgui = SSE.Imgui

        if imgui.Entity3D2D(self, Vector(0, 0, height+25), Angle(0, 90, 90), 0.1, 1000, 500) then
            DrawSign()
            imgui.End3D2D()
        end

        if imgui.Entity3D2D(self, Vector(0, 0, height+25), Angle(0, -90, 90), 0.1, 1000, 500) then
            DrawSign()
            imgui.End3D2D()
        end
    end


end
