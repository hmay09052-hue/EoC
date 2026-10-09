AddCSLuaFile()

-- Gemeinsame Basis fuer Boarding-Pod und Droiden-Dispenser.
-- Faellt (optional) vom Himmel bzw. bohrt sich durch Decken und setzt dann Droiden einzeln ab.
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Droiden-Absetzer"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.DeployModels = { "models/props_borealis/bluebarrel001.mdl" }
ENT.FallbackModel = "models/props_borealis/bluebarrel001.mdl"
ENT.Label = "Droiden-Absetzer"
ENT.DrillThrough = false     -- true = bohrt sich durch Decken (Boarding-Pod)
ENT.DropHeight = 3000
ENT.FallSpeed = 1600
ENT.SpawnRadius = 110
ENT.ModelOffsetZ = 0

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Falling")
    self:NetworkVar("Int", 0, "Remaining")
end

if SERVER then
    local C = EOCDroids.Config

    function ENT:Initialize()
        if not self:GetModel() or self:GetModel() == "" or not EOCDroids.IsValidModel(self:GetModel()) then
            self:SetModel(EOCDroids.PickModel(self.DeployModels, self.FallbackModel))
        end

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end

        local hp = self.DeployHealth or C.DeployerHealth
        self:SetMaxHealth(hp)
        self:SetHealth(hp)

        self.Queue = self.Queue or {}
        self:SetRemaining(#self.Queue)
        self.NextSpawn = 0

        self.TargetPos = self:GetPos() + Vector(0, 0, self.ModelOffsetZ)

        if self.Drop then
            self:StartFall()
        else
            self:SetPos(self.TargetPos)
            self:Land(true)
        end
    end

    function ENT:StartFall()
        local target = self.TargetPos
        local start

        if self.DrillThrough then
            -- Von weit oben, ignoriert Decken (bohrt sich durch)
            start = target + Vector(0, 0, self.DropHeight)
            local tr = util.TraceLine({ start = target + Vector(0, 0, 20), endpos = start, mask = MASK_SOLID_BRUSHONLY })
            if tr.HitSky then start = tr.HitPos - Vector(0, 0, 60) end
            if not util.IsInWorld(start) then start = target + Vector(0, 0, 1200) end
        else
            -- Nur unter freiem Himmel / bis zur naechsten Decke
            local tr = util.TraceLine({ start = target + Vector(0, 0, 20), endpos = target + Vector(0, 0, self.DropHeight), mask = MASK_SOLID_BRUSHONLY })
            start = tr.HitPos - Vector(0, 0, self:OBBMaxs().z + 20)
        end

        if start.z <= target.z + 50 then
            self:SetPos(target)
            self:Land(true)
            return
        end

        self.FallStart = CurTime()
        self.StartPos = start
        self:SetPos(start)
        self:SetFalling(true)
        self:SetNotSolid(true)
        self:EmitSound("ambient/levels/citadel/zapper_warmup1.wav", 90, 70)
    end

    function ENT:Land(silent)
        self:SetFalling(false)
        self:SetNotSolid(false)
        self.NextSpawn = CurTime() + 1.5
        self.EmptySince = nil

        if silent then return end

        local pos = self.TargetPos
        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect("HelicopterMegaBomb", ed)
        util.Effect("ThumperDust", ed)
        util.ScreenShake(pos, 15, 5, 1.2, 1500)
        self:EmitSound("ambient/explosions/explode_4.wav", 120, 90)
        util.BlastDamage(self, self, pos, 160, 60)
    end

    function ENT:Think()
        local now = CurTime()

        if self:GetFalling() then
            local t = now - self.FallStart
            local pos = self.StartPos - Vector(0, 0, self.FallSpeed * t)

            if pos.z <= self.TargetPos.z then
                self:SetPos(self.TargetPos)
                self:Land(false)
            else
                self:SetPos(pos)

                if self.DrillThrough and now >= (self.NextDrillFx or 0) and bit.band(util.PointContents(pos), CONTENTS_SOLID) ~= 0 then
                    self.NextDrillFx = now + 0.08
                    local ed = EffectData()
                    ed:SetOrigin(pos)
                    ed:SetMagnitude(4)
                    ed:SetScale(3)
                    ed:SetRadius(8)
                    util.Effect("Sparks", ed)
                    util.Effect("ManhackSparks", ed)
                    self:EmitSound("npc/manhack/grind" .. math.random(1, 5) .. ".wav", 100, 80)
                end
            end

            self:NextThink(now)
            return true
        end

        if #self.Queue > 0 then
            if now >= self.NextSpawn then
                self.NextSpawn = now + C.DeployerSpawnInterval
                self:SpawnNext()
            end
        elseif C.RemoveEmptyDeployerAfter > 0 then
            self.EmptySince = self.EmptySince or now
            if now - self.EmptySince > C.RemoveEmptyDeployerAfter then
                self:Remove()
                return
            end
        end

        self:NextThink(now + 0.5)
        return true
    end

    -- Sucht einen freien Platz rund um den Absetzer
    function ENT:FindSpawnSpot()
        local center = self:GetPos()
        local mins, maxs = Vector(-18, -18, 0), Vector(18, 18, 80)
        local radius = self.SpawnRadius + self:BoundingRadius() * 0.5
        local offset = math.Rand(0, 360)

        for ring = 0, 2 do
            for i = 0, 7 do
                local ang = math.rad(offset + i * 45)
                local r = radius + ring * 60
                local pos = center + Vector(math.cos(ang) * r, math.sin(ang) * r, 0)

                local ground = util.TraceLine({ start = pos + Vector(0, 0, 60), endpos = pos - Vector(0, 0, 200), mask = MASK_NPCSOLID_BRUSHONLY })
                if ground.Hit and not ground.StartSolid then
                    local spot = ground.HitPos + Vector(0, 0, 4)
                    local hull = util.TraceHull({ start = spot, endpos = spot, mins = mins, maxs = maxs, mask = MASK_NPCSOLID })
                    if not hull.Hit then return spot end
                end
            end
        end

        return center + Vector(0, 0, 10)
    end

    function ENT:SpawnNext()
        if EOCDroids.Count() >= C.MaxDroids then return end

        local class = table.remove(self.Queue, 1)
        self:SetRemaining(#self.Queue)
        if not class then return end

        local droid = ents.Create(class)
        if not IsValid(droid) then return end

        local spot = self:FindSpawnSpot()
        droid:SetPos(spot)
        droid:SetAngles(Angle(0, (spot - self:GetPos()):Angle().y, 0))
        droid:Spawn()
        droid:Activate()

        if IsValid(self.Creator) then
            cleanup.Add(self.Creator, "npcs", droid)
        end

        self:EmitSound("doors/door_metal_thin_open1.wav", 80, 90)
    end

    function ENT:OnTakeDamage(dmg)
        if self:GetFalling() or self:Health() <= 0 then return end
        self:SetHealth(math.max(self:Health() - dmg:GetDamage(), 0))

        if self:Health() <= 0 then
            local pos = self:WorldSpaceCenter()
            local ed = EffectData()
            ed:SetOrigin(pos)
            util.Effect("Explosion", ed)
            util.Effect("HelicopterMegaBomb", ed)
            util.BlastDamage(self, self, pos, 250, 60)
            self:Remove()
        end
    end
else
    local colorBar = Color(0, 127, 150, 230)
    local colorBack = Color(15, 15, 15, 230)
    local colorWhite = Color(255, 255, 255)
    local matGlow = Material("sprites/light_glow02_add")
    local fireCol = Color(255, 140, 40)

    function ENT:Draw()
        if self:GetFalling() and self.DrillThrough then
            self:SetRenderAngles(Angle(0, (CurTime() * 400) % 360, 0))
        else
            self:SetRenderAngles(self:GetAngles())
        end
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        if self:GetFalling() then
            local pos = self:GetPos()
            render.SetMaterial(matGlow)
            render.DrawSprite(pos, 220, 220, fireCol)
            EOCDroids.Light(pos, fireCol, 400, 0.1, 3, self.LightId)
            self.LightId = self.LightId or EOCDroids.NextLightId()
            return
        end

        local pos = self:GetPos()
        if EyePos():DistToSqr(pos) > 700 * 700 then return end

        local ang = Angle(0, EyeAngles().y - 90, 90)
        local health = self:Health()
        local maxHealth = math.max(self:GetMaxHealth(), 1)

        cam.Start3D2D(pos + Vector(0, 0, self:OBBMaxs().z + 20), ang, 0.15)
            local width = draw.SimpleText(self.Label, "EOCDroids.Title", 0, -40, colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            width = math.max(width, 200)
            EOCDroids.RoundedBox(4, -width / 2, -32, width, 8, colorBack)
            EOCDroids.RoundedBox(4, -width / 2, -32, width * math.Clamp(health / maxHealth, 0, 1), 8, colorBar)
            draw.SimpleText("Droiden: " .. self:GetRemaining(), "EOCDroids.Title", 0, -16, colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        cam.End3D2D()
    end
end
