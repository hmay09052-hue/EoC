AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Requistion Terminal"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.VehicleRequisition["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.VehicleRequisition["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


if SERVER then
    function ENT:Use( activator, caller )
        if activator.SSE_CurrentVeh then
            if activator.SSE_CurrentVeh:IsValid() then
                activator.SSE_CurrentVeh:Remove()
                activator:ChatPrint("*** "..SSE.Config.VehicleRequisition.Lang["VehStored"])
                activator.SSE_CurrentVeh = nil
            else
                activator.SSE_CurrentVeh = nil
                activator:ChatPrint("*** "..SSE.Config.VehicleRequisition.Lang["VehDestroyed"])
            end
        else
            net.Start("SSE_VehicleSpawn")
            net.Send(activator)
        end
    end

    util.AddNetworkString("SSE_VehicleSpawn")
    util.AddNetworkString("SSE_VehicleSpawn_Spawn")
    util.AddNetworkString("SSE_VehicleSpawn_Notify")

    net.Receive("SSE_VehicleSpawn_Spawn", function(len, ply)
        local class = net.ReadString()
        local pos = net.ReadVector()
        local ang = net.ReadAngle()
        local name = net.ReadString()

        vehicles = SSE.Config.VehicleRequisition["GetVehicles"](ply)

        if not table.HasValue(vehicles, class) then 
            ply:ChatPrint("*** "..SSE.Config.VehicleRequisition.Lang["NoAccessVeh"]) 
            return 
        end

        local vehicle = ents.Create(class)
        vehicle:SetPos(pos)
        vehicle:SetAngles(ang)
        vehicle:SetOwner(ply)
        vehicle:Spawn()

        ply.SSE_CurrentVeh = vehicle

        local vehicleName = vehicle:GetClass()
        local entTbl = scripted_ents.Get(vehicleName)
        local vehicleDisplayName = entTbl and entTbl.PrintName or vehicleName

        local actionMsg =  "[AKTION] " .. ply:Nick() .. " parkt ein " .. vehicleDisplayName .. " im " .. name .. " aus."

        net.Start("SSE_VehicleSpawn_Notify")
        net.WriteString(actionMsg)
        net.Broadcast()
    end)
end








if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self)
    end

    local function SpawnBlocked(spawn)
        local entsTbl = ents.FindInBox( spawn:GetPos() + Vector( -200, -200, -200 ), spawn:GetPos() + Vector( 200, 200, 200 ) )
        for k, v in ipairs(entsTbl) do
            if v:IsPlayer() or v.LFS or v.LVS then
                return true
            end
        end
        return false
    end

    function SSE_VehicleSpawnSelectSpawn(class)
        if ValidPanel(SSE_VehicleSpawnGUI) then SSE_VehicleSpawnGUI:Remove() end
        SSE_VehicleSpawnGUI = SSE:DefaultFrame(SSE.Config.VehicleRequisition.Lang["ChooseSpawn"])
        SSE_VehicleSpawnGUI:SetSize(SSEW(500),SSEH(800))
        SSE_VehicleSpawnGUI:Center()

        local fahrzeugeList = SSE:ScrollBar(SSE_VehicleSpawnGUI) 
        fahrzeugeList:Dock(FILL)

        for k, v in SortedPairs(ents.FindByClass("sse_vehspawn")) do
            local text = v:GetPlatformName()
            local btn = SSE:Button(fahrzeugeList, text, function()  
                net.Start("SSE_VehicleSpawn_Spawn")
                    net.WriteString(class)
                    net.WriteVector(v:GetPos())
                    net.WriteAngle(v:GetAngles())
                    net.WriteString(v:GetPlatformName())
                net.SendToServer() 

                if ValidPanel(SSE_VehicleSpawnGUI) then SSE_VehicleSpawnGUI:Remove() end
            end, "bc")
            btn:Dock(TOP)
            btn:DockMargin(0,0,0,SSEH(5))

            function btn:PaintOver(w,h)
                if SpawnBlocked(v) then
                    self:SetEnabled(false)
                    self.akzent = Color(200,0,0,255)
                    self.akzenthover = Color(255,0,0,255)
                else
                    self:SetEnabled(true)
                    self.akzent = Color(0,200,0,255)
                    self.akzenthover = Color(0,255,0,255)
                end
            end
        end
    end

    function SSE_VehicleSpawnFrame(fahrzeuge)
        if !fahrzeuge then LocalPlayer():ChatPrint("*** "..SSE.Config.VehicleRequisition.Lang["NoAccess"]) return end
        if !istable(fahrzeuge) then LocalPlayer():ChatPrint("*** "..SSE.Config.VehicleRequisition.Lang["NoAccess"]) return end
        if table.IsEmpty(fahrzeuge) then LocalPlayer():ChatPrint("*** "..SSE.Config.VehicleRequisition.Lang["NoAccess"]) return end

        if ValidPanel(SSE_VehicleSpawnGUI) then SSE_VehicleSpawnGUI:Remove() end
        SSE_VehicleSpawnGUI = SSE:DefaultFrame(SSE.Config.VehicleRequisition.Lang["Title"] )
        SSE_VehicleSpawnGUI:SetSize(SSEW(500),SSEH(800))
        SSE_VehicleSpawnGUI:Center()

        local fahrzeugeList = SSE:ScrollBar(SSE_VehicleSpawnGUI) 
        fahrzeugeList:Dock(FILL)

        for k, v in pairs(fahrzeuge) do
            local entTbl = scripted_ents.Get(v)
            local text = v
            if entTbl then
                text = entTbl.PrintName
            end
            local btn = SSE:Button(fahrzeugeList, text, function() SSE_VehicleSpawnSelectSpawn(v) end, "lc")
            btn:Dock(TOP)
            btn:DockMargin(0,0,0,SSEH(5))
        end
    end

    net.Receive( "SSE_VehicleSpawn", function( len, ply )
            vehicles = SSE.Config.VehicleRequisition["GetVehicles"](LocalPlayer())
            SSE_VehicleSpawnFrame(vehicles) 
    end )

end


if CLIENT then
    net.Receive("SSE_VehicleSpawn_Notify", function()
        local actionMsg = net.ReadString()
        
        chat.AddText(Color(255, 255, 0), actionMsg)
    end)
end
