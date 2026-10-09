local MAT_BLUEFLARE = CLIENT and Material("effects/blueflare1") or nil -- Performance: einmal laden statt jeden Frame
AddCSLuaFile()
ENT.Base = "arccw_gsr_plantable"
ENT.PrintName = "Sequencer Charge"
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_detonite.mdl"
ENT.WeaponClass = "arccw_k_nade_detonite"
ENT.Bury = 2
ENT.DetectionRange = 70
ENT.ArmDelay = 3

function ENT:OnPlant()
    self:EmitSound("kraken/shared/beeps3.wav", 75, 100, 1, CHAN_AUTO)
end
function ENT:Think()
    if SERVER and self:GetArmed() then
        for _, i in ipairs(ents.FindInSphere(self:GetPos(), self.DetectionRange)) do
            if IsValid(i) and ((i:IsPlayer() and i:GetVelocity():Length2DSqr() >= 22500) or i:IsNPC() or i:IsNextBot()) then
                self:Detonate()
                break
            end
        end
        self:NextThink(CurTime() + 0.15)
        return true
    end
end
function ENT:Detonate()
    if not SERVER or not self:IsValid() then return end
    local pos = self:GetPos() + self:GetUp() * 6
    
    if self:WaterLevel() >= 1 then
        ArcCW_Kraken_WaterExplosionFX(pos)
        self:EmitSound("weapons/underwater_explode3.wav", 125)
    else
        ArcCW_Kraken_GrenadeExplosionFX(pos)
        local trs = util.TraceLine({start = pos + Vector(0, 0, 64), endpos = pos + Vector(0, 0, -32), filter = self})
        util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
    end
    
    local oldowner = self.Attacker or self:GetOwner()
    if not IsValid(oldowner) then oldowner = self end
    local d = Lerp(self:GetUp():Dot(Vector(0, 0, 1)), 0.25, 1)
    self:SetOwner(NULL)
    ArcCW_Kraken_LOSBlastDamage(self, oldowner, pos, 200, 500 * d)
    ArcCW_Kraken_LOSBlastDamage(self, oldowner, pos, 400, 250 * d)
    self:Remove()
end
function ENT:Draw()
    if not CLIENT then return end
    self:DrawModel()
    if self:GetArmed() and math.sin(CurTime()) >= 0.75 then
        local pos = self:GetPos() + self:GetUp() * 3
        cam.Start3D()
        render.SetMaterial(MAT_BLUEFLARE)
        render.DrawSprite(pos, 16, 16, Color(0, 183, 255))
        self:EmitSound("kraken/shared/click3.wav", 75)
        cam.End3D()
    end
end