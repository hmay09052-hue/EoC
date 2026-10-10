AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Spawnable = false

function ENT:Draw()
    self:DrawModel()
end

function ENT:Initialize()
    if SERVER then
        self:SetModel( "models/items/ar2_grenade.mdl" )
        self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:SetMass(1)
    end
        self:DrawShadow( true )

        -- Smoke trail attached to the projectile
        self.SmokeTrail = ents.Create("env_smoketrail")
        if IsValid(self.SmokeTrail) then
            self.SmokeTrail:SetPos(self:GetPos())
            self.SmokeTrail:SetKeyValue("startsize", "8")
            self.SmokeTrail:SetKeyValue("endsize", "32")
            self.SmokeTrail:SetKeyValue("spawnrate", "20")
            self.SmokeTrail:SetKeyValue("lifetime", "1.2")
            self.SmokeTrail:SetKeyValue("minspeed", "0")
            self.SmokeTrail:SetKeyValue("maxspeed", "10")
            self.SmokeTrail:SetKeyValue("spawnradius", "2")
            self.SmokeTrail:SetKeyValue("startcolor", "180 180 180")
            self.SmokeTrail:SetKeyValue("endcolor", "100 100 100")
            self.SmokeTrail:SetParent(self)
            self.SmokeTrail:Spawn()
            self.SmokeTrail:Activate()
        end

        -- Looping flight sound while projectile is in the air
        util.PrecacheSound("pinglauncher/m79_projectile.wav")
        self.FlightSound = CreateSound(self, "pinglauncher/m79_projectile.wav")
        if self.FlightSound then
            -- volume 0.85, pitch 100; tweak as needed
            self.FlightSound:PlayEx(0.85, 100)
        end
    end
    self.ExplodeTimer = CurTime() + 100000
end

function ENT:PhysicsCollide( data, phys )
    if  (20 < data.Speed and 0.25 < data.DeltaTime) then
    if self.FlightSound then self.FlightSound:Stop() end
    self.ExplodeTimer = 0
    end
end

function ENT:Think()
    if SERVER and (self.ExplodeTimer and self.ExplodeTimer <= CurTime()) then
        self:Explode()
    end
    self:NextThink(CurTime())
    return true
end

function ENT:Explode()
	local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    util.Effect("Explosion", effectdata)
    util.BlastDamage( self, self.Owner, self:GetPos(), 150, 100 )
    if self.FlightSound then self.FlightSound:Stop() end
    -- Place a scorch decal on the ground where the explosion occurs
    local spos = self:GetPos()
    local trs = util.TraceLine({
        start = spos + Vector(0,0,64),
        endpos = spos + Vector(0,0,-256),
        filter = self,
        mask = MASK_SOLID
    })
    if trs.Hit and not trs.HitSky then
        util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
    end
    self:Remove()
end

function ENT:OnRemove()
    -- Cleanup smoke trail
    if SERVER and IsValid(self.SmokeTrail) then
        self.SmokeTrail:Remove()
    end
    if self.FlightSound then self.FlightSound:Stop() end
    self:StopSound("pinglauncher/m79_projectile.wav")
end