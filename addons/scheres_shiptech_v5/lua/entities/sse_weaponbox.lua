AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName   = "Weapon Box"
ENT.Author      = "Lt. Sammy"
ENT.Contact     = ""
ENT.Purpose     = ""
ENT.Instructions    = ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()
    self:SetModel("models/lordtrilobite/starwars/props/kyber_crate_phys.mdl")
    self:SetMoveType(MOVETYPE_VPHYSICS)   
    self:SetSolid(SOLID_VPHYSICS)       

    self.SSE_HUDName = SSE.Config.WeaponBox["HUDName"]

    if SERVER then 
        self:PhysicsInit(SOLID_VPHYSICS) 
        self:SetUseType(SIMPLE_USE)
    end
    self:PhysWake()
end

if SERVER then
    function ENT:Use(activator, caller)
        net.Start("SSE_WeaponBox")
        net.Send(activator)
    end
end

if CLIENT then
    function ENT:Draw()
        self.BaseClass.Draw(self)  -- We want to override rendering, so don't call baseclass.
    end
end

if SERVER then
    util.AddNetworkString("SSE_WeaponBox")
    util.AddNetworkString("SSE_WeaponBox_GIVE")
    util.AddNetworkString("SSE_WeaponBox_TAKE")
    
    net.Receive("SSE_WeaponBox_GIVE", function(len, ply)
        local wep = net.ReadString()
        weaponbox = SSE.Config.WeaponBox["GetWeapons"](ply)

        if !table.HasValue(weaponbox, wep) then return end

        ply:Give(wep)
        ply:SelectWeapon(wep)
        ply:EmitSound("items/ammo_pickup.wav")
    end)
    
    net.Receive("SSE_WeaponBox_TAKE", function(len, ply)
        local wep = net.ReadString()
        ply:StripWeapon(wep)
        ply:EmitSound("items/ammo_pickup.wav")
    end)
end

if CLIENT then
    function SSE_WeaponBox(data) 
        if !istable then LocalPlayer():ChatPrint("*** ".. SSE.Config.WeaponBox["NoWeps"]) return end
        if table.IsEmpty(data) then LocalPlayer():ChatPrint("*** ".. SSE.Config.WeaponBox["NoWeps"]) return end

        if ValidPanel(SSE_WeaponBoxFrame) then SSE_WeaponBoxFrame:Remove() end
        SSE_WeaponBoxFrame = SSE:DefaultFrame()
        SSE_WeaponBoxFrame:SetSize(SSEW(500),SSEH(600))
        SSE_WeaponBoxFrame:Center()
        SSE_WeaponBoxFrame:SetNewTitle(SSE.Config.WeaponBox["FrameTitle"])
        SSE_WeaponBoxFrame:SetSizable(false)
        SSE_WeaponBoxFrame:SetDraggable(false)
    
        local content = SSE:ScrollBar(SSE_WeaponBoxFrame) 
        content:Dock(FILL)
  
        for _, v in ipairs(data) do
            local text = v
            local wepTbl = weapons.Get(v)
        
            if istable(wepTbl) then
                text = wepTbl.PrintName
            end
    
            local btn = SSE:Button(content, text, function() 
                if LocalPlayer():HasWeapon(v) then
                    net.Start("SSE_WeaponBox_TAKE")
                    net.WriteString(v)
                    net.SendToServer()
                else
                    net.Start("SSE_WeaponBox_GIVE")
                    net.WriteString(v)
                    net.SendToServer()      
                end
            end, "bc")
    
            btn:Dock(TOP)
            btn:DockMargin(5,10,5,0)
    
            function btn:Think() 
                if LocalPlayer():HasWeapon(v) then
                    self.akzent = Color(0,200,0)
                    self.akzenthover = Color(0,255,0,255)
                else
                    self.akzent = Color(200,0,0)
                    self.akzenthover = Color(255,0,0,255)
                end
            end
        end        
    end
    
    net.Receive("SSE_WeaponBox", function(len, ply)
        weaponbox = SSE.Config.WeaponBox["GetWeapons"](LocalPlayer())
        SSE_WeaponBox(weaponbox) 
    end)
end