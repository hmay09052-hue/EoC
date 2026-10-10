AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Shock Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_grenade_shock.mdl"
ENT.FuseTime = 2
DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.Radius = 450
ENT.Damage = 250
ENT.ImpactDamage = 2
ENT.DamageFalloffStart = 96

local glowMat = Material("sprites/light_glow02_add")
local shockMat = Material("sprites/physg_glow1")

local string_lower = string.lower
local string_find = string.find
local function IsDroidEntity(ent)
    if not IsValid(ent) then return false end
    local cls = ent.GetClass and ent:GetClass()
    if isstring(cls) and string_find(string_lower(cls), "droid", 1, true) then return true end
    if ent.GetModel then
        local mdl = ent:GetModel()
        if isstring(mdl) and string_find(string_lower(mdl), "droid", 1, true) then return true end
    end
    if ent.GetName then
        local name = ent:GetName()
        if isstring(name) and string_find(string_lower(name), "droid", 1, true) then return true end
    end
    return false
end
local function AddElectricDeathFX(target)
    local function spawn_sparks(anchor)
        if not IsValid(anchor) then return end
        for i = 1, 4 do
            local spark = ents.Create("env_spark")
            if IsValid(spark) then
                spark:SetKeyValue("Magnitude", "3")
                spark:SetKeyValue("TrailLength", "2")
                spark:SetPos(anchor:WorldSpaceCenter() + VectorRand() * 8)
                spark:Spawn()
                spark:Activate()
                if IsValid(anchor) then
                    spark:SetParent(anchor)
                end
                spark:Fire("StartSpark", "", 0)
                spark:Fire("StopSpark",  "", 0.45)
                SafeRemoveEntityDelayed(spark, 0.6)
            end
        end
        for j = 1, 6 do
            timer.Simple(0.05 * j, function()
                if not IsValid(anchor) then return end
                local ed = EffectData()
                ed:SetOrigin(anchor:WorldSpaceCenter() + VectorRand() * 10)
                util.Effect("StunstickImpact", ed, true, true)
            end)
        end
    end
    if IsValid(target) and target:IsPlayer() then
        timer.Simple(0, function()
            local rag = target:GetRagdollEntity()
            if IsValid(rag) then
                spawn_sparks(rag)
            else
                spawn_sparks(target)
            end
        end)
    else
        spawn_sparks(target)
    end
end
local function InstantKillDroid(ent, attacker, inflictor)
    if not IsValid(ent) then return end
    local dmg = DamageInfo()
    dmg:SetDamageType(DMG_SHOCK)
    dmg:SetAttacker(IsValid(attacker) and attacker or ent)
    dmg:SetInflictor(IsValid(inflictor) and inflictor or ent)
    dmg:SetDamage(100000)
    dmg:SetDamageForce(Vector(0,0,0))
    ent:TakeDamageInfo(dmg)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        local anchor = ent
        if ent:IsPlayer() then
            local rag = ent:GetRagdollEntity()
            if IsValid(rag) then anchor = rag end
        end
        AddElectricDeathFX(anchor)
    end)
end
function ENT:Initialize()
    if not SERVER then return end
    BaseClass.Initialize(self)
    self:SetModel(self.Model)
    self:SetSkin(self.Skin or 0)
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        phys:SetBuoyancyRatio(0)
    end
    self:SetPhysicsAttacker(self:GetOwner(), 10)
    self:EmitSound("kraken/explosives/shock/beep.wav")
    util.SpriteTrail(self, 0, Color(35, 202, 228, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
end
function ENT:PhysicsCollide(data, physobj)
    if not SERVER or self.Defused then return end
    local tgt, speed = data.HitEntity, data.Speed

    if speed < 15 and (not IsValid(tgt) or tgt:IsWorld()) then
        timer.Simple(0, function() if IsValid(self) then self:SetMoveType(MOVETYPE_NONE) end end)
        self:EmitSound("kraken/explosives/shock/charge.wav")
        return
    end

    if speed > 25 then self:EmitSound("ArcCW_Kraken.Explosives.Bounce") end

    if speed > 75 and IsValid(tgt) and not tgt:IsWorld() and (self.NextHit or 0) < CurTime() then
        self.NextHit = CurTime() + 0.1
        local dmginfo = DamageInfo()
        dmginfo:SetDamageType(DMG_GENERIC)
        dmginfo:SetDamage(self.ImpactDamage)
        dmginfo:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageForce(data.OurOldVelocity * 0.5)
        tgt:TakeDamageInfo(dmginfo)
    end
end

function ENT:Think()
    if self.Defused or not SERVER then return end
    ArcCW_Kraken_GrenadeEntitySweep(self)
    if self.SpawnTime and CurTime() - self.SpawnTime >= self.FuseTime then self:Detonate() return end
    self:NextThink(CurTime() + 0.1)
    return true
end
function ENT:Detonate()
    if not SERVER or self.Defused then return end
    self.Defused = true

    local pos = self:GetPos()
    local attacker = IsValid(self.Owner) and self.Owner or self
    local radius = self.Radius

    if self:WaterLevel() >= 1 then
        local effectdata = EffectData()
        effectdata:SetOrigin(pos)
        util.Effect("WaterSurfaceExplosion", effectdata)
        self:EmitSound("weapons/underwater_explode3.wav", 125, 100, 1, CHAN_AUTO)
    else
        local explode = ents.Create("info_particle_system")
        if IsValid(explode) then
            explode:SetKeyValue("effect_name", "Generic_explo_flash")
            explode:SetOwner(attacker)
            explode:SetPos(pos)
            explode:Spawn()
            explode:Activate()
            explode:Fire("start", "", 0)
            explode:Fire("kill", "", 30)
        end
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
    end

    for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
        if not IsValid(ent) then continue end
        local targetPos = ent:WorldSpaceCenter()
        local tr = util.TraceLine({start = pos, endpos = targetPos, filter = {self, ent}, mask = MASK_SOLID_BRUSHONLY})
        if tr.Hit and tr.Fraction < 0.98 then continue end
        local distSqr = ent:GetPos():DistToSqr(pos)
        local distFrac = math.max(1 - (distSqr / (radius * radius)), 0.25)
        if IsDroidEntity(ent) then
            InstantKillDroid(ent, attacker, self)
        elseif ent:IsPlayer() and ent:Alive() then
            local dmginfo = DamageInfo()
            dmginfo:SetDamageType(DMG_SHOCK)
            dmginfo:SetAttacker(attacker)
            dmginfo:SetDamage(self.Damage * distFrac)
            dmginfo:SetDamageForce((targetPos - pos):GetNormalized() * 500 * distFrac)
            dmginfo:SetInflictor(self)
            ent:TakeDamageInfo(dmginfo)

            AddElectricDeathFX(ent)
        elseif ent:IsNPC() then
            local dmginfo = DamageInfo()
            dmginfo:SetDamageType(DMG_SHOCK)
            dmginfo:SetAttacker(attacker)
            dmginfo:SetDamage(self.Damage * distFrac)
            dmginfo:SetDamageForce((targetPos - pos):GetNormalized() * 500 * distFrac)
            dmginfo:SetInflictor(self)
            ent:TakeDamageInfo(dmginfo)

            AddElectricDeathFX(ent)
        elseif ent:IsNextBot() then
            local dmginfo = DamageInfo()
            dmginfo:SetDamageType(DMG_SHOCK)
            dmginfo:SetAttacker(attacker)
            dmginfo:SetDamage(self.Damage * distFrac)
            dmginfo:SetDamageForce((targetPos - pos):GetNormalized() * 500 * distFrac)
            dmginfo:SetInflictor(self)
            ent:TakeDamageInfo(dmginfo)
            AddElectricDeathFX(ent)
        end
    end

    util.Decal("Scorch", pos, pos - Vector(0, 0, 30))
    self:Remove()
end

local sparkMat = Material("effects/spark")

function ENT:DrawTranslucent()
    self:Draw()
end
function ENT:Draw()
    self:DrawModel()
    if CLIENT then
        local pos = self:GetPos()
        local flicker = math.random() > 0.3 and 1 or 0.4
        local pulse = 0.7 + math.sin(CurTime() * 15) * 0.3
        local glowSize = 14 * pulse * flicker
        
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, glowSize, glowSize, Color(80, 140, 255, 180 * flicker))
        
        if math.random() > 0.85 then
            local sparkOffset = VectorRand() * 6
            render.SetMaterial(sparkMat)
            render.DrawSprite(pos + sparkOffset, 4, 4, Color(180, 200, 255, 255))
        end
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 80
            dlight.g = 140
            dlight.b = 255
            dlight.brightness = 1.5 * flicker * pulse
            dlight.decay = 1000
            dlight.size = 80
            dlight.dietime = CurTime() + 0.1
        end
    end
end