-- Bacta-Granate
SWEP.Base = "weapon_base"
SWEP.PrintName = "Bacta-Granate"
SWEP.Slot = 3

function SWEP:PrimaryAttack()
    if CLIENT then return end
    
    local ply = self:GetOwner()
    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 1000,
        filter = ply
    })
    
    local ent = ents.Create("cw_bacta_effect")
    ent:SetPos(tr.HitPos)
    ent:Spawn()
    
    self:Remove()
end

-- Bacta-Effekt-Entity
ENT = {}
ENT.Type = "anim"

function ENT:Initialize()
    self:SetModel("models/items/healthkit.mdl")
    self:EmitSound("weapons/explode3.wav")
    
    timer.Simple(1, function()
        if IsValid(self) then
            for _, v in ipairs(ents.FindInSphere(self:GetPos(), 200)) do
                if v:IsPlayer() and not v:GetNWBool("CW_FatalInjury") then
                    v:SetHealth(math.min(v:Health() + 40, 100))
                end
            end
            self:Remove()
        end
    end)
end