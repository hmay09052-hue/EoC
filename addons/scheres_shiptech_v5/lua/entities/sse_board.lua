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

            draw.RoundedBox(0, x, y, w, h, boardData.background)

            if pageMaterial != nil then
                surface.SetDrawColor( 255, 255, 255, 255 ) -- Set the drawing color
                surface.SetMaterial( pageMaterial ) -- Use our cached material
                surface.DrawTexturedRect(x, y, w, h)
            else 
                draw.SimpleText("Board not configured", imgui.xFont("!Arial@50"), 0, 0, Color(255,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
 
            if imgui.xTextButton(">", "!Arial@50", w/2-100, h/2-100, 75, 75, 1, Color(145,145,145), Color(255,255,255), Color(255,0,0)) then
                self:NextPage()
            end

            if imgui.xTextButton("<", "!Arial@50", -w/2+25, h/2-100, 75, 75, 1, Color(145,145,145), Color(255,255,255), Color(255,0,0)) then
                self:PreviousPage()
            end

        imgui.End3D2D()
        end
    end
end