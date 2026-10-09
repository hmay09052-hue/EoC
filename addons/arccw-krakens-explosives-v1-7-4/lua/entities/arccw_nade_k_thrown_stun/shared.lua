AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Stun Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_grenade_base.mdl"
ENT.FuseTime = 1.5
DEFINE_BASECLASS("arccw_kraken_nade_base")

local BLUR_DURATION = 15
local glowMat = Material("sprites/light_glow02_add")
local pulseMat = Material("sprites/glow04_noz")
local flashMat = Material("sprites/glow04_noz")

local function isCowerSupportedForNPC(npc)
    for _, a in pairs(npc:GetSequenceList()) do
        if (npc:GetSequenceActivity(npc:LookupSequence(a)) == ACT_COWER) then
            return true
        end
    end
    return false
end

local lethalToNpcs = {
    "npc_barnacle", "npc_crow", "npc_pigeon", "npc_seagull", 
    "npc_zombie", "npc_fastzombie", "npc_zombie_torso", "npc_zombine", 
    "npc_headcrab", "npc_headcrab_black", "npc_headcrab_fast", 
    "npc_lambdaplayer"
}

function ENT:Initialize()
    if not SERVER then return end
    BaseClass.Initialize(self)
    self:SetModel(self.Model)
    self:SetSkin(self.Skin or 0)
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:SetBuoyancyRatio(0) end
    self:SetPhysicsAttacker(self:GetOwner(), 10)
    self:EmitSound("kraken/explosives/shock/beep.wav", 90, 100, 1, CHAN_AUTO)
    sound.EmitHint(SOUND_DANGER, self:GetPos(), 200, 8, nil)
    util.SpriteTrail(self, 0, Color(200, 200, 200, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
end

function ENT:PhysicsCollide(data, physobj)
    if not SERVER or self.Defused then return end
    local tgt = data.HitEntity

    if data.Speed > 75 then
        self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
        if IsValid(tgt) and not tgt:IsWorld() and (self.NextHit or 0) < CurTime() then
            self.NextHit = CurTime() + 0.1
            local dmginfo = DamageInfo()
            dmginfo:SetDamageType(DMG_CLUB)
            dmginfo:SetDamage(5)
            dmginfo:SetAttacker(self:GetOwner())
            dmginfo:SetInflictor(self)
            dmginfo:SetDamageForce(data.OurOldVelocity * 0.5)
            tgt:TakeDamageInfo(dmginfo)
        end
    elseif data.Speed > 50 then self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
    elseif data.Speed > 25 then self:EmitSound("ArcCW_Kraken.Explosives.Bounce") end
end

function ENT:Think()
    if self.Defused then return end
    ArcCW_Kraken_GrenadeEntitySweep(self)
    if SERVER and self.SpawnTime and CurTime() - self.SpawnTime >= self.FuseTime then self:Detonate() end
end
function ENT:Detonate()
    if not SERVER or not self:IsValid() or self.Defused then return end
    self.Defused = true

    local pos = self:GetPos()
    local effectdata = EffectData()
    effectdata:SetOrigin(pos)

    if self:WaterLevel() >= 1 then
        util.Effect("WaterSurfaceExplosion", effectdata)
        self:EmitSound("weapons/underwater_explode3.wav", 125, 100, 1, CHAN_AUTO)
    else
        ParticleEffect("Generic_explo_flash", pos, Angle(0, 0, 0), nil)
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
        util.ScreenShake(pos, 25, 4, 0.75, 500)
    end

    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
    ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 500, 32)

    for _, e in ipairs(ents.FindInSphere(pos, 500)) do
        if not IsValid(e) or not e:IsLineOfSightClear(pos) then continue end
        if e:IsNPC() then
            e:StartEngineTask(89, 0)
            if isCowerSupportedForNPC(e) then e:SetSchedule(SCHED_COWER)
            elseif table.HasValue(lethalToNpcs, e:GetClass()) then
                local dmginfo = DamageInfo()
                dmginfo:SetDamageType(DMG_BLAST)
                dmginfo:SetAttacker(attacker)
                dmginfo:SetDamage(e:Health())
                dmginfo:SetInflictor(self)
                e:TakeDamageInfo(dmginfo)
            end
        elseif e:IsPlayer() then self:ApplyBlurEffect(e) end
    end

    local dir = self.HitVelocity or self:GetVelocity()
    if self.Boost and self.Boost <= 0 then dir = Vector(0, 0, -1) end

    self:FireBullets({Attacker = self, Damage = 0, Tracer = 0, Distance = 256, Dir = dir, Src = pos, Callback = function(att, tr, dmg)
        util.Decal("Scorch", tr.StartPos, tr.HitPos - (tr.HitNormal * 16), self)
        end
    })
    
    sound.EmitHint(SOUND_DANGER, pos, 500, 6, nil)
    self:Remove()
end
function ENT:ApplyBlurEffect(ply)
    if SERVER then
        net.Start("ARC9_StunBlurEffect")
        net.WriteFloat(BLUR_DURATION)
        net.Send(ply)
    end
end

function ENT:DrawTranslucent()
    self:Draw()
end

function ENT:Draw()
    self:DrawModel()
    if CLIENT then
        local pos = self:GetPos()
        local spawnTime = self.SpawnTime or self:GetCreationTime()
        local timeElapsed = CurTime() - spawnTime
        local fuseProgress = math.Clamp(timeElapsed / self.FuseTime, 0, 1)
        local pulse = 0.7 + math.sin(CurTime() * (8 + fuseProgress * 12)) * 0.3
        local glowSize = (12 + fuseProgress * 10) * pulse
        
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, glowSize, glowSize, Color(255, 200, 100, 180 * pulse))
        
        if fuseProgress > 0.6 then
            local criticalPulse = math.sin(CurTime() * 20)
            if criticalPulse > 0.3 then
                render.SetMaterial(flashMat)
                render.DrawSprite(pos, 16, 16, Color(255, 255, 200, 180))
            end
        end
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 200
            dlight.b = 100
            dlight.brightness = (1 + fuseProgress) * pulse
            dlight.decay = 1000
            dlight.size = 80 + fuseProgress * 40
            dlight.dietime = CurTime() + 0.05
        end
    end
end

if CLIENT then
    local colorModify = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }
    
    net.Receive("ARC9_StunBlurEffect", function()
        local duration = net.ReadFloat()
        local endTime = CurTime() + duration
        
        hook.Add("RenderScreenspaceEffects", "ARC9_StunBlurEffect", function()
            local timeLeft = endTime - CurTime()
            if timeLeft <= 0 then
                hook.Remove("RenderScreenspaceEffects", "ARC9_StunBlurEffect")
                return
            end
            
            local fraction = timeLeft / duration
            DrawMotionBlur(0.4, fraction, 0.05)
            
            local colorFraction = fraction * 1
            colorModify["$pp_colour_brightness"] = -colorFraction * 0.5
            colorModify["$pp_colour_colour"] = 1 - colorFraction * 0.1
            DrawColorModify(colorModify)
            
            local bloomParams = {
                darken = 0.5 * fraction,
                multiply = 0.5 * fraction,
                sizex = 4,
                sizey = 4,
                passes = 2,
                colour = 2 * fraction,
            }
            DrawBloom(bloomParams.darken, bloomParams.multiply, bloomParams.sizex, bloomParams.sizey, bloomParams.passes, bloomParams.colour, 1, 1, 1)
        end)
    end)
end

if SERVER then
    util.AddNetworkString("ARC9_StunBlurEffect")
end