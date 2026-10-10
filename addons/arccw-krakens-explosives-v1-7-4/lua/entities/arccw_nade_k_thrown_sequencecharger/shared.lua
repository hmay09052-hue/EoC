local MAT_BLUEFLARE = CLIENT and Material("effects/blueflare1") or nil -- Performance: einmal laden statt jeden Frame
AddCSLuaFile()
ENT.Base = "arccw_gsr_plantable"
ENT.PrintName = "Sequencer Charge"
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_sequencer_charge.mdl"
ENT.WeaponClass = "arccw_k_nade_sequencecharger"

ENT.Bury = 3
ENT.DetectionRange = 96
ENT.ArmDelay = 3

function ENT:OnPlant()
    self:EmitSound("kraken/shared/beeps2.wav", 75, 100, 1, CHAN_AUTO)
end
function ENT:Think()
    if not SERVER or not self:GetArmed() then return end
    
    for _, v in ipairs(ents.FindInSphere(self:GetPos(), self.DetectionRange)) do
        if IsValid(v) then
            if (v:IsPlayer() and v:GetVelocity():Length2DSqr() >= 22500) or v:IsNPC() or v:IsNextBot() then
                self:Detonate()
                break
            end
            if v.LFS or v.LVS then
                v:StopEngine()
                v:SetShield(0)
                v:SetHP(v:GetHP() / 10)
                self:Detonate()
                break
            end
        end
    end
    self:NextThink(CurTime() + 0.15)
    return true
end
function ENT:Detonate()
    if not SERVER or not self:IsValid() then return end
    local pos = self:GetPos() + self:GetUp() * 6
    
    if self:WaterLevel() >= 1 then
        ArcCW_Kraken_WaterExplosionFX(pos)
        ArcCW_Kraken_WaterExplosionFX(pos + Vector(0, 0, 32))
        self:EmitSound("weapons/underwater_explode3.wav", 125)
    else
        -- AT Mine heavy explosion x2 (double layered for bigger visual)
        ArcCW_Kraken_HeavyExplosionFX(pos)
        ArcCW_Kraken_HeavyExplosionFX(pos + Vector(0, 0, 48))
        local trs = util.TraceLine({start = pos + Vector(0, 0, 64), endpos = pos + Vector(0, 0, -32), filter = self})
        util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
        self:EmitSound("kraken/explosives/seismiccharge/close" .. math.random(1, 3) .. ".wav", 125)
    end
    
    local oldowner = self.Attacker or self:GetOwner()
    if not IsValid(oldowner) then oldowner = self end
    util.ScreenShake(self:GetPos(), 25, self.DetectionRange * 20, 7, self.DetectionRange * 20)
    self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
    self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
    self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
    local d = Lerp(self:GetUp():Dot(Vector(0, 0, 1)), 0.25, 1)
    self:SetOwner(NULL)
    ArcCW_Kraken_LOSBlastDamage(self, oldowner, pos, 650, 1200 * d)
    ArcCW_Kraken_LOSBlastDamage(self, oldowner, pos, 225, 356 * d)
    self:Remove()
end
function ENT:Draw()
    if not CLIENT then return end
    self:DrawModel()
    if self:GetArmed() and math.sin(CurTime()) >= 0.75 then
        local pos = self:GetPos() + self:GetUp() * 5
        cam.Start3D()
        render.SetMaterial(MAT_BLUEFLARE)
        render.DrawSprite(pos, 16, 16, Color(255, 0, 0))
        self:EmitSound("kraken/shared/beeps1.wav", 75)
        cam.End3D()
    end
end