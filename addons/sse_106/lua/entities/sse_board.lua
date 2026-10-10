AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Board"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable = true

if SERVER then
        
    function ENT:Initialize()
        self:SetModel("models/hunter/plates/plate3x5.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        
        if IsValid(phys) then
            phys:EnableMotion(false)
        end
    end

    util.AddNetworkString("SSE_Board_SetPage")
    net.Receive( "SSE_Board_SetPage", function( len, ply )
        local ent = net.ReadEntity()
        local page = net.ReadInt(8)
        ent:SetPage(page)
    end)

    function ENT:UpdateBoardData( name, old, new )
        if not SSE.Config.Boards[new] then return end
        local boardData = SSE.Config.Boards[new]   

        self:SetModel( boardData.model  )
        self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
    end

end

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "Board", { KeyName = "Boards",	Edit = { type = "Text"  } } ) 
    self:NetworkVar( "Int", 0, "Page" ) 


    if SERVER then
        self:SetBoard("Default")
        self:SetPage(1)
        self:NetworkVarNotify( "Board", self.UpdateBoardData )
    end

end


if CLIENT then


    ENT.RenderGroup = RENDERGROUP_TRANSLUCENT


    function ENT:NextPage()
          
        if not SSE.Config.Boards[self:GetBoard()] then return end
        local boardData = SSE.Config.Boards[self:GetBoard()]   
 

        if self:GetPage() >= #boardData.pages then return end

        net.Start("SSE_Board_SetPage")
            net.WriteEntity(self)
            net.WriteInt(self:GetPage()+1, 8)
        net.SendToServer()
    end 

    function ENT:PreviousPage()
                  
        if not SSE.Config.Boards[self:GetBoard()] then return end
         local boardData = SSE.Config.Boards[self:GetBoard()]   
       
    
            if self:GetPage() <= 1 then return end
    
            net.Start("SSE_Board_SetPage")
                net.WriteEntity(self)
                net.WriteInt(self:GetPage()-1, 8)
            net.SendToServer()

    end


    function ENT:DrawTranslucent()
        
      local imgui = SSE.Imgui
        if not SSE.Config.Boards[self:GetBoard()] then return end
        local boardData = SSE.Config.Boards[self:GetBoard()]

        local page = boardData.pages[self:GetPage()]

        local pageMaterial = nil 

        if page.material then
            pageMaterial = Material(page.material)
        end
        if page.imgur then
            if not SSE_Imgur_Materials[page.imgur] then

                SSE.GetImgur(page.imgur, function(mat)
                    SSE_Imgur_Materials[page.imgur] = mat
                end)
            else 
                pageMaterial = SSE_Imgur_Materials[page.imgur]
            end
        end

        local x, y, w, h = -boardData.width/2, -boardData.height/2, boardData.width, boardData.height
        --self:DrawModel()

  
 
        if imgui.Entity3D2D(self, Vector(0, 0, 0), Angle(0, 90, 0), 0.1, 1000, 500) then
            local UI = SSE.UI
            local accent = UI.Accent()
            local pageCount = #boardData.pages

            UI.Box(x, y, w, h, boardData.background)

            if pageMaterial != nil then
                surface.SetDrawColor( 255, 255, 255, 255 )
                surface.SetMaterial( pageMaterial )
                surface.DrawTexturedRect(x, y, w, h)
                draw.NoTexture()
            else 
                UI.WorldPanel(x, y, w, h, accent, { sweep = false })
                UI.WorldHeading("Tafel nicht eingerichtet", 0, -60, accent, TEXT_ALIGN_CENTER)
            end

            -- Rahmen im Server-Design
            UI.Outline(x, y, w, h, UI.Alpha(accent, 200), 3)
            UI.Box(x, y, w, 6, accent)
            local m = 60
            for _, p in ipairs({ { x, y + h, 1, -1 }, { x + w, y + h, -1, -1 } }) do
                surface.SetDrawColor(accent)
                surface.DrawRect(p[3] > 0 and p[1] or p[1] - m, p[2] - 6, m, 6)
                surface.DrawRect(p[3] > 0 and p[1] or p[1] - 6, p[2] - m, 6, m)
            end

            -- Seitenleiste unten: Seitenzahl + Blättern
            if pageCount > 1 then
                local bh = 80
                local by = y + h - bh - 25
                local barW = 420
                UI.Cut(-barW / 2, by, barW, bh, Color(6, 8, 11, 225), 16, "tlbr")
                UI.CutOutline(-barW / 2, by, barW, bh, UI.Alpha(accent, 150), 16, "tlbr")
                UI.Text("SEITE " .. self:GetPage() .. " / " .. pageCount, "sse.world.h", 0, by + bh / 2 - 8, UI.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                UI.Aurebesh("Seite " .. self:GetPage(), "sse.world.aure", 0, by + bh - 24, UI.Alpha(accent, 200), TEXT_ALIGN_CENTER)

                if self:GetPage() < pageCount and UI.WorldButton(imgui, ">", w / 2 - 125, by, 100, bh, accent, "sse.world.h") then
                    self:NextPage()
                end

                if self:GetPage() > 1 and UI.WorldButton(imgui, "<", -w / 2 + 25, by, 100, bh, accent, "sse.world.h") then
                    self:PreviousPage()
                end
            end

        imgui.End3D2D()
        end
    end
end