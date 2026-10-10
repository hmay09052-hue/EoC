AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Unit Sign"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable       = true

function ENT:Initialize()

    self:SetModel( "models/reizer_props/alysseum_project/clones/misc_props/misc_stuff_01/misc_stuff_01.mdl" )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox

    self:DrawShadow( false )
 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 


        self:SetSubMaterial(0, "vgui/null")
    end
    self:PhysWake()
end


function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "Unit", { KeyName = "Unit",	Edit = { type = "Text"  } } ) 
	self:NetworkVar( "Vector",	0, "UnitColor",	{ KeyName = "unitcolor",	Edit = { type = "VectorColor",	order = 4 } } )

    if SERVER then
        self:SetUnit("912TH")
        self:SetUnitColor(Vector(0, 0, 255))
    end

end



if CLIENT then
    
    function ENT:Draw()
        self:DrawModel()

        
        local imgui = SSE.Imgui

        if imgui.Entity3D2D(self, Vector(0, 0, 16), Angle(0, 90, 90), 0.1, 1000, 500) then
            local UI = SSE.UI
            local unit = string.upper(self:GetUnit())
            local col = UI.Readable(self:GetUnitColor():ToColor(), 90)

            local tw, th = UI.TextSize(unit, "sse.world.huge")
            UI.Box(-tw / 2 - 30, -th / 2 + 8, 6, th - 16, col)
            UI.Box(tw / 2 + 24, -th / 2 + 8, 6, th - 16, col)
            UI.TextShadow(unit, "sse.world.huge", 0, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4)
            UI.Aurebesh(unit, "sse.world.aure.big", 0, th / 2 + 4, UI.Alpha(col, 210), TEXT_ALIGN_CENTER)

            imgui.End3D2D()
        end
    end
end