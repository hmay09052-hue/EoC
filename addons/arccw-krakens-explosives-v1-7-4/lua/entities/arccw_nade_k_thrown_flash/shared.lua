AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Flashbang"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_grenade_flash.mdl"
ENT.PhysBoxSize = false
ENT.SphereSize = false
ENT.PhysMat = "grenade"
ENT.LifeTime = 1.5
ENT.ExplodeOnImpact = false
ENT.SmokeTrail = false
ENT.BounceSound = "ArcCW_Kraken.Explosives.Bounce"
ENT.ExplosionSounds = "ArcCW_Kraken.Explosives.Explosion"
DEFINE_BASECLASS("arccw_kraken_nade_base")

local glowMat = Material("sprites/light_glow02_add")
local flashMat = Material("sprites/physg_glow1")

function ENT:Initialize()
    if SERVER then
        BaseClass.Initialize(self)
        util.SpriteTrail(self, 0, Color(255, 255, 100, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
    end
end

function ENT:Think()
    ArcCW_Kraken_GrenadeEntitySweep(self)
    if BaseClass.Think then return BaseClass.Think(self) end
end

function ENT:EntityFacingFactor(theirent)
    local dir = theirent:EyeAngles():Forward()
    local facingdir = (self:GetPos() - (theirent.GetShootPos and theirent:GetShootPos() or theirent:GetPos())):GetNormalized()
    return (facingdir:Dot(dir) + 1) / 2
end
function ENT:EntityFacingUs(theirent)
    local dir = theirent:EyeAngles():Forward()
    local facingdir = (self:GetPos() - (theirent.GetShootPos and theirent:GetShootPos() or theirent:GetPos())):GetNormalized()
    if facingdir:Dot(dir) > -0.25 then return true end
end
function ENT:Detonate()
    if self.Defused then return end
    self.Defused = true
    local tr = {}
    tr.start = self:GetPos()
    tr.mask = MASK_SOLID
    for _, v in ipairs(player.GetAll()) do
        tr.endpos = v:GetShootPos()
        tr.filter = {self, v, v:GetActiveWeapon()}
        local traceres = util.TraceLine(tr)
        if not traceres.Hit or traceres.Fraction >= 1 or traceres.Fraction <= 0 then
            v:SetNWFloat("ARC9_GSR_LastFlash", CurTime())
            v:SetNWEntity("ARC9_GSR_LastFlashBy", self:GetOwner())
            v:SetNWFloat("ARC9_GSR_FlashDistance", v:GetShootPos():Distance(self:GetPos()))
            v:SetNWFloat("ARC9_GSR_FlashFactor", self:EntityFacingFactor(v))
            if v:GetNWFloat("ARC9_GSR_FlashDistance", v:GetShootPos():Distance(self:GetPos())) < 1500 and v:GetNWFloat("FlashFactor", self:EntityFacingFactor(v)) < tr.endpos:Distance(self:GetPos(v)) then
                if v:GetNWFloat("ARC9_GSR_FlashDistance", v:GetShootPos():Distance(self:GetPos())) < 1000 then
                    v:SetDSP(37, false)
                elseif v:GetNWFloat("ARC9_GSR_FlashDistance", v:GetShootPos():Distance(self:GetPos())) < 800 then
                    v:SetDSP(36, false)
                elseif v:GetNWFloat("ARC9_GSR_FlashDistance", v:GetShootPos():Distance(self:GetPos())) < 600 then
                    v:SetDSP(35, false)
                end
            end
        end
    end
    if self:WaterLevel() > 0 then
        local tr = util.TraceLine({
            start = self:GetPos(),
            endpos = self:GetPos() + Vector(0, 0, 1) * 1024,
            filter = self,
        })
        local tr2 = util.TraceLine({
            start = tr.HitPos,
            endpos = self:GetPos(),
            filter = self,
            mask = MASK_WATER
        })
        ParticleEffect("explosion_water", tr2.HitPos + Vector(0, 0, 8), Angle(0, 0, 0), nil)
        self:EmitSound("weapons/underwater_explode3.wav", 100)
    else
        ParticleEffect("bumpmine_detonate", self:GetPos(), Angle(0, 0, 0), nil)
        ParticleEffect("weapon_decoy_ground_effect_shot", self:GetPos(), Angle(0, 0, 0), nil)
        ParticleEffect("explosion_hegrenade_brief", self:GetPos(), Angle(0, 0, 0), nil)
        self:EmitSound("kraken/explosives/flashbang/flashbang_explode1.wav")
    end
    for _, v in ipairs(ents.GetAll()) do
        if v:IsNPC() and self:EntityFacingUs(v) then
            tr.endpos = v.GetShootPos and v:GetShootPos() or v:GetPos()
            tr.filter = {self, v, v.GetActiveWeapon and v:GetActiveWeapon() or v}
            local traceres = util.TraceLine(tr)
            if not traceres.Hit or traceres.Fraction >= 1 or traceres.Fraction <= 0 then
                local flashdistance = tr.endpos:Distance(self:GetPos())
                local flashtime = CurTime()
                local flashdist = 600
                local flashdistfade = 400
                local flashdur = 3
                local flashfade = 2
                local distancefac = 1 - math.Clamp((flashdistance - flashdist + flashdistfade) / flashdistfade, 0, 1)
                local intensity = 1 - math.Clamp(((CurTime() - flashtime) / distancefac - flashdur + flashfade) / flashfade, 0, 1)
                if intensity > 0.2 then
                    v:SetEnemy(nil)
                    v:SetNPCState(NPC_STATE_PLAYDEAD)
                    timer.Simple(intensity * gsr_flashtime * 2, function()
                        if not IsValid(v) then return end
                        v:SetNPCState(NPC_STATE_IDLE)
                    end)
                    if v.ClearEnemyMemory then
                        v:ClearEnemyMemory()
                    end
                end
            end
        end
    end
    if SERVER then
        local dir = self.HitVelocity or self:GetVelocity()
        self:FireBullets({
            Attacker = self,
            Damage = 0,
            Tracer = 0,
            Distance = 256,
            Dir = dir,
            Src = self:GetPos(),
            Callback = function(att, tr, dmg)
                if self.Scorch then
                    util.Decal("Scorch", tr.StartPos, tr.HitPos - (tr.HitNormal * 16), self)
                end
            end
        })
    end
    self.deactivated = true
    self:Remove()
end

function ENT:DrawTranslucent()
    self:Draw()
end

function ENT:Draw()
    self:DrawModel()
    if CLIENT then
        local spawnTime = self.SpawnTime or self:GetCreationTime()
        local timeElapsed = CurTime() - spawnTime
        local fuseProgress = math.Clamp(timeElapsed / self.LifeTime, 0, 1)
        local pulse = 0.6 + 0.4 * math.sin(CurTime() * (8 + fuseProgress * 16))
        render.SetMaterial(glowMat)
        local coreSize = (10 + fuseProgress * 12) * pulse
        local flashColor = Color(220, 230, 255, 200)
        render.DrawSprite(self:GetPos(), coreSize, coreSize, flashColor)
        if fuseProgress > 0.7 then
            local brightPulse = math.sin(CurTime() * 30)
            if brightPulse > 0.2 then
                render.SetMaterial(flashMat)
                local brightSize = (fuseProgress - 0.7) * 60
                render.DrawSprite(self:GetPos(), brightSize, brightSize, Color(255, 255, 255, 220))
            end
        end
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = self:GetPos()
            dlight.r = 220
            dlight.g = 230
            dlight.b = 255
            dlight.brightness = (0.8 + fuseProgress * 1.5) * pulse
            dlight.decay = 100
            dlight.size = 70 + fuseProgress * 50
            dlight.dietime = CurTime() + 0.05
        end
    end
end