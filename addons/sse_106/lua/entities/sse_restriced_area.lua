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
    
    function ENT:Draw()
        self:DrawModel()

  
        -- Get Model Height
        local min, max = self:GetModelBounds()
        local height = max.z - min.z


        local imgui = SSE.Imgui

        if imgui.Entity3D2D(self, Vector(0, 0, height+25), Angle(0, 90, 90), 0.1, 1000, 500) then

            draw.SimpleText(SSE.Config.RestrictedSign["Text1"], SSE.xFont(SSE.Config.RestrictedSign["Font1"]), 0, 50, SSE.Config.RestrictedSign["Color1"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.RoundedBox(0, -300, 90, 600, 2, Color(255,255,255))
            draw.SimpleText(SSE.Config.RestrictedSign["Text2"], SSE.xFont(SSE.Config.RestrictedSign["Font2"]), 0, 120, SSE.Config.RestrictedSign["Color2"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(SSE.Config.RestrictedSign["Text3"], SSE.xFont(SSE.Config.RestrictedSign["Font3"]), 0, 220, SSE.Config.RestrictedSign["Color3"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(SSE.Config.RestrictedSign["Text4"], SSE.xFont(SSE.Config.RestrictedSign["Font4"]), 0, 180, SSE.Config.RestrictedSign["Color4"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            imgui.End3D2D()
        end

        if imgui.Entity3D2D(self, Vector(0, 0, height+25), Angle(0, -90, 90), 0.1, 1000, 500) then

            draw.SimpleText(SSE.Config.RestrictedSign["Text1"], SSE.xFont(SSE.Config.RestrictedSign["Font1"]), 0, 50, SSE.Config.RestrictedSign["Color1"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.RoundedBox(0, -300, 90, 600, 2, Color(255,255,255))
            draw.SimpleText(SSE.Config.RestrictedSign["Text2"], SSE.xFont(SSE.Config.RestrictedSign["Font2"]), 0, 120, SSE.Config.RestrictedSign["Color2"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(SSE.Config.RestrictedSign["Text3"], SSE.xFont(SSE.Config.RestrictedSign["Font3"]), 0, 220, SSE.Config.RestrictedSign["Color3"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(SSE.Config.RestrictedSign["Text4"], SSE.xFont(SSE.Config.RestrictedSign["Font4"]), 0, 180, SSE.Config.RestrictedSign["Color4"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            imgui.End3D2D()
        end
    end


end