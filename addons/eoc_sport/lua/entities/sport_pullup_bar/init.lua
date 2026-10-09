AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local function Cfg()
    return EoCSport.Config.PullupBar
end

function ENT:SpawnFunction(ply, tr, class)
    if not tr.Hit or not EoCSport.IsAdmin(ply) then return end

    local ent = ents.Create(class)
    ent:SetPos(tr.HitPos + Vector(0, 0, Cfg().Height))
    -- Stange quer zur Blickrichtung, damit man direkt davor steht
    ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
    ent:Spawn()
    ent:Activate()
    return ent
end

function ENT:Initialize()
    self:SetModel(Cfg().Model)
    self:SetMaterial(Cfg().Material)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

    -- Höhe über dem Boden für die Pfosten merken
    local tr = util.TraceLine({ start = self:GetPos(), endpos = self:GetPos() - Vector(0, 0, 400), filter = self, mask = MASK_SOLID_BRUSHONLY })
    self:SetNW2Float("EoCSport_PostHeight", tr.Hit and (self:GetPos().z - tr.HitPos.z) or Cfg().Height)
end

function ENT:Use()
end

function ENT:OnRemove()
    local user = self:GetNW2Entity("EoCSport_User")
    if IsValid(user) and EoCSport.Sessions and EoCSport.Sessions[user] then
        EoCSport.Stop(user, "bar")
    end
end
