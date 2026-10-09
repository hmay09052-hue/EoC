AddCSLuaFile()
ENT.Type                     = "anim"
ENT.Base                     = "base_entity"
ENT.RenderGroup              = RENDERGROUP_TRANSLUCENT
ENT.PrintName                = "Base Projectile"
ENT.Category                 = ""
ENT.Spawnable                = false
ENT.Model                    = ""

local gunship = {
    ["npc_combinegunship"] = true,
    ["npc_combinedropship"] = true,
    ["npc_helicopter"] = true,
    ["npc_strider"] = true,
}

local smokeimages = {"particle/particle_smokegrenade"}
local function GetSmokeImage()
    return smokeimages[math.random(#smokeimages)]
end

ENT.Material = false
ENT.IsRocket = false
ENT.Sticky = false
ENT.InstantFuse = true
ENT.TimeFuse = false
ENT.RemoteFuse = false
ENT.ImpactFuse = false
ENT.StickyFuse = false
ENT.NoBounce = false
ENT.BounceWall = false
ENT.RemoveOnImpact = false
ENT.ExplodeOnImpact = false
ENT.ExplodeOnDamage = false
ENT.ExplodeUnderwater = false
ENT.Defusable = false
ENT.DefuseOnDamage = false
ENT.ImpactDamage = 25
ENT.ImpactDamageSpeed = 1000
ENT.Delay = 5
ENT.Armed = false
ENT.RocketTrailParticle = "rockettrail"
ENT.RocketTrail = false
ENT.SmokeTrail = false
ENT.SmokeColor = Color(255, 165, 0)
ENT.Flare = true
ENT.FlareColor = nil
ENT.FlareSizeMin = 50
ENT.FlareSizeMax = 100
ENT.AudioLoop = nil
ENT.BounceSounds = nil
ENT.CollisionSphere = nil
ENT.GunshipWorkaround = true

ENT.DynamicLightEnabled = false
ENT.DynamicLightColor = Color(255, 150, 50)
ENT.DynamicLightBrightness = 2

ENT.Boost = 0
ENT.Lift = 0
ENT.DynamicLightSize = 120
ENT.DynamicLightFlicker = false
ENT.DynamicLightPulse = false
ENT.DynamicLightPulseSpeed = 4

ENT.SpriteTrailEnabled = false
ENT.SpriteTrailColor = Color(255, 200, 100)
ENT.SpriteTrailLength = 0.3
ENT.SpriteTrailWidth = 8
ENT.SpriteTrailEndWidth = 0
ENT.SpriteTrailTexture = "trails/laser"

ENT.GlowSpriteEnabled = false
ENT.GlowSpriteColor = Color(255, 200, 100)
ENT.GlowSpriteSize = 24
ENT.GlowSpriteMaterial = "sprites/light_glow02_add"

ENT.PreDetonationGlow = false
ENT.PreDetonationTime = 0.5
ENT.PreDetonationColor = Color(255, 100, 50)
ENT.PreDetonationPulseSpeed = 12

ENT.RotationEnabled = false
ENT.RotationSpeed = 180

ENT.SecondaryParticles = false
ENT.SecondaryParticleRate = 0.05
ENT.SecondaryParticleColor = Color(255, 200, 100)

ENT.BounceSparkEnabled = false
function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Weapon")
end
function ENT:Initialize()
    if SERVER then
        self:SetModel(self.Model)
        self:SetMaterial(self.Material or "")
        if self.CollisionSphere then
            self:PhysicsInitSphere(self.CollisionSphere)
        else
            self:PhysicsInit(SOLID_VPHYSICS)
        end
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
        if self.Defusable then
            self:SetUseType(SIMPLE_USE)
        end
        local phys = self:GetPhysicsObject()
        if !phys:IsValid() then
            self:Remove()
            return
        end
        phys:EnableDrag(false)
        phys:SetDragCoefficient(0)
        phys:SetBuoyancyRatio(0)
        phys:Wake()
        if self.IsRocket then
            phys:EnableGravity(false)
			phys:SetMass(5)
        end
        if self.SpriteTrailEnabled then
            self:CreateSpriteTrail()
        end
    end
    self.SpawnTime = CurTime()
    self.NPCDamage = IsValid(self:GetOwner()) and self:GetOwner():IsNPC() and self:GetOwner():IsNextBot()
    if self.AudioLoop then
        self.LoopSound = CreateSound(self, self.AudioLoop)
        self.LoopSound:Play()
	   if self:GetNWBool("HasDetonated") then
       self.LoopSound:Stop()
       end
    end
    if self.InstantFuse then
        self.ArmTime = CurTime()
        self.Armed = true
    end
    if self.RocketTrail then
	   ParticleEffectAttach(self.RocketTrailParticle, PATTACH_ABSORIGIN_FOLLOW, self, 0)
	   if self:GetNWBool("HasDetonated") then
       self.RocketTrail = false
       end
    end
	self.HitSkybox = false
    self.LastParticleTime = 0
    self.LastDLightUpdate = 0
    self:OnInitialize()
end
function ENT:OnRemove()
    if self.LoopSound then
        self.LoopSound:Stop()
    end
	self:StopParticles()
    if IsValid(self.TrailEntity) then
        self.TrailEntity:Remove()
    end
end
function ENT:CreateSpriteTrail()
    if CLIENT then return end
    if not self.SpriteTrailEnabled then return end
    local trail = util.SpriteTrail(self, 0, self.SpriteTrailColor, false, self.SpriteTrailWidth, self.SpriteTrailEndWidth, self.SpriteTrailLength, 1 / (self.SpriteTrailLength + 0.01), self.SpriteTrailTexture)
    self.TrailEntity = trail
end
function ENT:OnTakeDamage(dmg)
    if self.Detonated then return end
    if self.ExplodeOnDamage then
        if IsValid(self:GetOwner()) and IsValid(dmg:GetAttacker()) then self:SetOwner(dmg:GetAttacker())
        else self.Attacker = dmg:GetAttacker() or self.Attacker end
        self:PreDetonate(data)
    elseif self.DefuseOnDamage and dmg:GetDamageType() != DMG_BLAST then
        self:EmitSound("physics/plastic/plastic_box_break" .. math.random(1, 2) .. ".wav", 70, math.Rand(95, 105))
        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        fx:SetNormal(self:GetAngles():Forward())
        fx:SetAngles(self:GetAngles())
        util.Effect("ManhackSparks", fx)
        self.Detonated = true
        self:Remove()
    end
end
function ENT:PhysicsCollide(data, collider, physobj)
    if IsValid(data.HitEntity) and data.HitEntity:GetClass() == "func_breakable_surf" then
        self:FireBullets({
            Attacker = self:GetOwner(),
            Inflictor = self,
            Damage = 0,
            Distance = 32,
            Tracer = 0,
            Src = self:GetPos(),
            Dir = data.OurOldVelocity:GetNormalized(),
	        })
        local pos, ang, vel = self:GetPos(), self:GetAngles(), data.OurOldVelocity
        self:SetAngles(ang)
        self:SetPos(pos)
        self:GetPhysicsObject():SetVelocityInstantaneous(vel * 0.5)
        return
    end
    if self.BounceWall then
        local ang = data.HitNormal:Angle()
        ang.p = math.abs( ang.p )
        ang.y = math.abs( ang.y )
        ang.r = math.abs( ang.r )
        if ang.p > 90 or ang.p < 60 then
		self:SetNWBool("HasDetonated",true)
        local impulse = (data.OurOldVelocity - 2 * data.OurOldVelocity:Dot(data.HitNormal) * data.HitNormal)*0.25
        collider:ApplyForceCenter(impulse)
        else
        self:PreDetonate(data)
        end
    end
    if self.ImpactFuse and !self.Armed then
        self.ArmTime = CurTime()
        self.Armed = true
        if self:Impact(data, collider) then
            return
        end
        if self.Delay == 0 or self.ExplodeOnImpact then
            self:PreDetonate(data)
        end
    elseif self.ImpactDamage > 0 and IsValid(data.HitEntity) and (engine.ActiveGamemode() != "terrortown" or !data.HitEntity:IsPlayer()) then
        local dmg = DamageInfo()
        dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self.Attacker)
        dmg:SetInflictor(self)
        dmg:SetDamage(Lerp((data.OurOldVelocity:Length() - 0.6 * self.ImpactDamageSpeed) / 0.4 * self.ImpactDamageSpeed, self.ImpactDamage / 5, self.ImpactDamage))
        dmg:SetDamageType(DMG_CRUSH + DMG_CLUB)
        dmg:SetDamageForce(data.OurOldVelocity)
        dmg:SetDamagePosition(data.HitPos)
        data.HitEntity:TakeDamageInfo(dmg)
    elseif !self.ImpactFuse then
        self:Impact(data, collider)
    end
    if self.Sticky then
        local hitEntity = data.HitEntity
        local hitPos = data.HitPos
        
        timer.Simple(0, function()
            if not IsValid(self) then return end
            
            self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
            self:SetPos(hitPos)
            self:SetAngles(self:GetAngles())
            
            if hitEntity:IsWorld() or (IsValid(hitEntity) and hitEntity:GetSolid() == SOLID_BSP) then
                self:SetMoveType(MOVETYPE_NONE)
                self:SetPos(hitPos)
            else
                self:SetPos(hitPos)
                if IsValid(hitEntity) then
                    self:SetParent(hitEntity)
                end
            end
        end)
        
        self.Attacker = self:GetOwner()
        self:SetOwner(NULL)
        self:EmitSound("physics/flesh/flesh_impact_bullet" .. math.random(1, 5) .. ".wav", 125)
        if self.StickyFuse and !self.Armed then
            self.ArmTime = CurTime()
            self.Armed = true
        end
        self:Stuck()
		self:SetNWBool("HasDetonated",true)
    end
    if self.NoBounce then
	  timer.Simple(0, function()
       self:SetPos(self:GetPos())
	   self:GetPhysicsObject():SetVelocityInstantaneous(data.OurNewVelocity * 0.1)
	  end)
	  self:SetNWBool("HasDetonated",true)
    end
    if data.DeltaTime < 0.1 then return end
    if !self.BounceSounds then return end
    local s = table.Random(self.BounceSounds)
    self:EmitSound(s)
end
function ENT:OnThink()
end
function ENT:OnInitialize()
end
local math_Rand = math.Rand
local VectorRand = VectorRand
function ENT:DoDynamicLight()
    if not CLIENT then return end
    if not self.DynamicLightEnabled then return end
    if self:GetNWBool("HasDetonated") then return end
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = self:GetPos()
        dlight.r = self.DynamicLightColor.r
        dlight.g = self.DynamicLightColor.g
        dlight.b = self.DynamicLightColor.b
        local brightness = self.DynamicLightBrightness
        if self.DynamicLightFlicker then
            brightness = brightness * math_Rand(0.7, 1.0)
        end
        if self.DynamicLightPulse then
            brightness = brightness * (0.7 + 0.3 * math.sin(CurTime() * self.DynamicLightPulseSpeed))
        end
        dlight.brightness = brightness
        dlight.decay = self.DynamicLightSize * 5
        dlight.size = self.DynamicLightSize
        dlight.dietime = CurTime() + 0.1
    end
end
function ENT:DoPreDetonationGlow()
    if not CLIENT then return end
    if not self.PreDetonationGlow then return end
    if not self.Armed then return end
    if not self.ArmTime then return end
    if not self.Delay then return end
    if not self.PreDetonationTime then return end
    local timeLeft = (self.ArmTime + self.Delay) - CurTime()
    if timeLeft > self.PreDetonationTime then return end
    local intensity = 1 - (timeLeft / self.PreDetonationTime)
    intensity = math.Clamp(intensity, 0, 1)
    local pulse = 0.6 + 0.4 * math.sin(CurTime() * self.PreDetonationPulseSpeed * (1 + intensity))
    local dlight = DynamicLight(self:EntIndex() + 10000)
    if dlight then
        dlight.pos = self:GetPos()
        dlight.r = self.PreDetonationColor.r
        dlight.g = self.PreDetonationColor.g
        dlight.b = self.PreDetonationColor.b
        dlight.brightness = 3 * intensity * pulse
        dlight.decay = 200
        dlight.size = 150 * intensity
        dlight.dietime = CurTime() + 0.05
    end
end
function ENT:DoSecondaryParticles()
    if not CLIENT then return end
    if not self.SecondaryParticles then return end
    if self:GetNWBool("HasDetonated") then return end
    if CurTime() - (self.LastParticleTime or 0) < self.SecondaryParticleRate then return end
    self.LastParticleTime = CurTime()
    local emitter = ParticleEmitter(self:GetPos())
    if not emitter then return end
    local particle = emitter:Add("sprites/light_glow02_add", self:GetPos() + VectorRand() * 4)
    if particle then
        particle:SetVelocity(VectorRand() * 20 - self:GetVelocity() * 0.1)
        particle:SetLifeTime(0)
        particle:SetDieTime(math_Rand(0.2, 0.4))
        particle:SetStartAlpha(200)
        particle:SetEndAlpha(0)
        particle:SetStartSize(math_Rand(2, 4))
        particle:SetEndSize(0)
        particle:SetColor(self.SecondaryParticleColor.r, self.SecondaryParticleColor.g, self.SecondaryParticleColor.b)
        particle:SetGravity(Vector(0, 0, -50))
    end
    emitter:Finish()
end
function ENT:DoSmokeTrail()
    if not (CLIENT and self.SmokeTrail and not self:GetNWBool("HasDetonated")) then return end
    local emitter = ParticleEmitter(self:GetPos())
    if not emitter then return end
    local smoke = emitter:Add(GetSmokeImage(), self:GetPos())
    if smoke then
        smoke:SetStartAlpha(50)
        smoke:SetEndAlpha(0)
        smoke:SetStartSize(10)
        smoke:SetEndSize(math_Rand(50, 75))
        smoke:SetRoll(math_Rand(-180, 180))
        smoke:SetRollDelta(math_Rand(-1, 1))
        smoke:SetPos(self:GetPos())
        smoke:SetVelocity(-self:GetAngles():Forward() * 400 + VectorRand() * 10)
        smoke:SetColor(self.SmokeColor)
        smoke:SetLighting(true)
        smoke:SetDieTime(math_Rand(0.75, 1.25))
        smoke:SetGravity(Vector(0, 0, 0))
    end
    emitter:Finish()
end
function ENT:Think(data)
    if not IsValid(self) or self:GetNoDraw() then return end
    if self.Defused or self.Detonated then return end
    
    if not self.SpawnTime then
        self.SpawnTime = CurTime()
    end
    
    if self.LifeTime and self.SpawnTime + self.LifeTime < CurTime() then
        self:PreDetonate(data)
        return
    end
    
    if not self.Armed and isnumber(self.TimeFuse) and self.SpawnTime + self.TimeFuse < CurTime() then
        self.ArmTime = CurTime()
        self.Armed = true
    end
    
    if self.Armed and self.ArmTime and self.ArmTime + self.Delay < CurTime() then
        self:PreDetonate(data)
        return
    end
    
    if self.ExplodeUnderwater and self:WaterLevel() > 0 then
        self:PreDetonate(data)
        return
    elseif self:WaterLevel() > 0 then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableGravity(true)
            phys:EnableMotion(true)
            phys:EnableDrag(false)
            phys:SetMass(10)
        end
        self:SetNWBool("HasDetonated", true)
        self:StopParticles()
    end
    
    local drunk = false
    
    if self.FireAndForget or self.SemiActive then
        if self.SemiActive and IsValid(self.Weapon) then
            self.ShootEntData = self.Weapon:RunHook("Hook_GetShootEntData", {})
        end
        
        if self.ShootEntData and self.ShootEntData.Target and IsValid(self.ShootEntData.Target) then
            local target = self.ShootEntData.Target
            if target.UnTrackable then self.ShootEntData.Target = nil end
            
            local tpos = target:EyePos()
            if self.TopAttack and not self.TopAttackReached then
                tpos = tpos + Vector(0, 0, self.TopAttackHeight)
                local dist = (tpos - self:GetPos()):Length()
                if dist <= 2000 then
                    self.TopAttackReached = true
                    self.SuperSteerTime = CurTime() + self.SuperSteerBoostTime
                end
            end
            
            local dir = (tpos - self:GetPos()):GetNormalized()
            local dot = dir:Dot(self:GetAngles():Forward())
            local ang = dir:Angle()
            
            if self.SuperSeeker or dot >= self.SeekerAngle or not self.TopAttackReached or (self.SuperSteerTime and self.SuperSteerTime >= CurTime()) then
                local p = self:GetAngles().p
                local y = self:GetAngles().y
                p = math.ApproachAngle(p, ang.p, FrameTime() * self.SteerSpeed)
                y = math.ApproachAngle(y, ang.y, FrameTime() * self.SteerSpeed)
                self:SetAngles(Angle(p, y, 0))
            elseif self.NoReacquire then
                self.ShootEntData.Target = nil
                drunk = true
            end
        else
            drunk = true
        end
    elseif self.SACLOS then
        if IsValid(self:GetOwner()) then
            local tpos = self:GetOwner():GetEyeTrace().HitPos
            local dir = (tpos - self:GetPos()):GetNormalized()
            local dot = dir:Dot(self:GetAngles():Forward())
            local ang = dir:Angle()
            
            if dot >= self.SeekerAngle then
                local p = self:GetAngles().p
                local y = self:GetAngles().y
                p = math.ApproachAngle(p, ang.p, FrameTime() * self.SteerSpeed)
                y = math.ApproachAngle(y, ang.y, FrameTime() * self.SteerSpeed)
                self:SetAngles(Angle(p, y, 0))
            else
                drunk = true
            end
        else
            drunk = true
        end
    end
    
    if drunk then
        self:SetAngles(self:GetAngles() + (AngleRand() * FrameTime() * 1000 / 360))
    end
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) and (self.Boost > 0 or self.Lift > 0) then
        phys:AddVelocity(Vector(0, 0, self.Lift) + self:GetForward() * self.Boost)
    end
    
    if SERVER and not self.Detonated and not self.Defused then
        local vel = self:GetVelocity()
        if vel:LengthSqr() > 2500 then
            local sweepDist = math.max(vel:Length() * engine.TickInterval() * 3, 32)
            local tr = util.TraceHull({
                start = self:GetPos(),
                endpos = self:GetPos() + vel:GetNormalized() * sweepDist,
                filter = {self, self:GetOwner()},
                mins = Vector(-4, -4, -4),
                maxs = Vector(4, 4, 4),
                mask = MASK_SHOT,
            })
            if tr.Hit and IsValid(tr.Entity) and not tr.Entity:IsWorld() then
                local hitEnt = tr.Entity
                if hitEnt:IsPlayer() or hitEnt:IsNPC() or hitEnt:IsNextBot() or hitEnt:IsVehicle() or hitEnt.LVS or hitEnt.LFS or gunship[hitEnt:GetClass()] then
                    self:SetPos(tr.HitPos)
                    self:PreDetonate(data)
                end
            end
        end
    end
    
    self:DoSmokeTrail()
    self:DoDynamicLight()
    self:DoPreDetonationGlow()
    self:DoSecondaryParticles()
    self:OnThink()
end
function ENT:Use(ply)
    if !self.Defusable then return end
    self:EmitSound("items/ammocrate_open.wav")
    if self.PickupAmmo then
        ply:GiveAmmo(1, self.PickupAmmo, true)
    end
    self:Remove()
end
function ENT:RemoteDetonate()
    self:EmitSound("buttons/button14.wav")
    self.ArmTime = CurTime()
    self.Armed = true
end
function ENT:PreDetonate(data)
    if CLIENT then return end
    if !self.Detonated then
        self.Detonated = true
        if !IsValid(self.Attacker) and !IsValid(self:GetOwner()) then self.Attacker = game.GetWorld() end
        self:Detonate(data)
		self:SetNWBool("HasDetonated",true)
  end
end
function ENT:Detonate(data)
end
function ENT:Impact()
end
function ENT:Stuck()
end
function ENT:DrawTranslucent()
    self:Draw()
end
local mat = Material("sprites/light_glow02_add")
local glowMat = Material("sprites/light_glow02_add")
local glowCache = {} -- Performance: Material-Cache statt Lookup pro Frame
function ENT:Draw()
    self:DrawModel()
    if self:GetNWBool("HasDetonated") then return end
    if self.GlowSpriteEnabled and self.GlowSpriteColor then
        local customGlow = glowMat
        if self.GlowSpriteMaterial then
            customGlow = glowCache[self.GlowSpriteMaterial]
            if not customGlow then customGlow = Material(self.GlowSpriteMaterial) glowCache[self.GlowSpriteMaterial] = customGlow end
        end
        render.SetMaterial(customGlow)
        local size = self.GlowSpriteSize
        if self.DynamicLightPulse then
            size = size * (0.8 + 0.2 * math.sin(CurTime() * self.DynamicLightPulseSpeed))
        end
        render.DrawSprite(self:GetPos(), size, size, self.GlowSpriteColor)
    end
    if self.Flare and self.FlareColor then
        local mult = self.SafetyFuse and math.Clamp((CurTime() - (self.SpawnTime + self.SafetyFuse)) / self.SafetyFuse, 0.1, 1) or 1
        render.SetMaterial(mat)
        render.DrawSprite(self:GetPos() + (self:GetAngles():Forward() * -20), mult * math.Rand(self.FlareSizeMin, self.FlareSizeMax), mult * math.Rand(self.FlareSizeMin, self.FlareSizeMax), self.FlareColor)
    end
    if self.PreDetonationGlow and self.Armed and self.ArmTime then
        local timeLeft = (self.ArmTime + self.Delay) - CurTime()
        if timeLeft <= self.PreDetonationTime and timeLeft > 0 then
            local intensity = 1 - (timeLeft / self.PreDetonationTime)
            local pulse = 0.5 + 0.5 * math.sin(CurTime() * self.PreDetonationPulseSpeed * (1 + intensity))
            render.SetMaterial(glowMat)
            local glowSize = 32 * intensity * pulse
            render.DrawSprite(self:GetPos(), glowSize, glowSize, Color(self.PreDetonationColor.r, self.PreDetonationColor.g, self.PreDetonationColor.b, 200 * intensity))
        end
    end
end
hook.Add("EntityTakeDamage", "ArcCW_Kraken_Proj_Collision", function(ent, dmginfo)
    if IsValid(dmginfo:GetInflictor())
            and scripted_ents.IsBasedOn(dmginfo:GetInflictor():GetClass(), "arccw_kraken_proj_base")
            and dmginfo:GetDamageType() == DMG_CRUSH then dmginfo:SetDamage(0) return true end
end)