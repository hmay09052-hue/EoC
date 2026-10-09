include("shared.lua")

local C = EOCDroids.Config

local colorBack = Color(15, 15, 15, 230)
local colorWhite = Color(255, 255, 255)
local colorDebug = Color(237, 42, 255)
local colorWire = Color(255, 255, 255, 26)
local matGlow = Material("sprites/light_glow02_add")
local matLaser = Material("cable/redlaser")
local matFire = Material("effects/fire_cloud1")
local matRing = Material("particle/particle_ring_wave_addnofog")

-- ============================================================
-- WAFFENMODELL (nur clientseitig, an der rechten Hand)
-- ============================================================
-- Position/Winkel der rechten Hand: Knochen, sonst Attachment
function ENT:GetHandTransform()
    if self.HandBone == nil then
        self.HandBone = self:LookupBone("ValveBiped.Bip01_R_Hand") or false
        local att = self:LookupAttachment("anim_attachment_RH")
        self.HandAttachment = (att and att > 0) and att or false
    end

    if self.HandBone then
        local matrix = self:GetBoneMatrix(self.HandBone)
        if matrix then return matrix:GetTranslation(), matrix:GetAngles() end
    end

    if self.HandAttachment then
        local att = self:GetAttachment(self.HandAttachment)
        if att then return att.Pos, att.Ang end
    end
end

local function PickWeaponModel(w)
    local list = w.Models or (w.Model and { w.Model }) or {}
    local count = #list
    for i, mdl in ipairs(list) do
        -- Der letzte Eintrag ist der HL2-Ersatz
        if i == count and count > 1 and not C.WeaponFallbackModels then return end
        if EOCDroids.IsValidModel(mdl) then return mdl end
    end
end

function ENT:DrawWeaponModel()
    local w = self:GetWeaponData()
    if not w then return end

    local mdl = w.CachedModel
    if mdl == nil then
        mdl = PickWeaponModel(w) or false
        w.CachedModel = mdl
    end
    if not mdl then return end

    if not IsValid(self.WeaponModel) or self.WeaponModelPath ~= mdl then
        if IsValid(self.WeaponModel) then self.WeaponModel:Remove() end
        self.WeaponModel = ClientsideModel(mdl, RENDERGROUP_OPAQUE)
        self.WeaponModelPath = mdl
        if not IsValid(self.WeaponModel) then return end
        self.WeaponModel:SetNoDraw(true)

        -- HL2-Waffen (mit ValveBiped-Knochen) sitzen per Bonemerge exakt in der Hand
        self.WeaponBonemerge = self.HandBone ~= false and self.WeaponModel:LookupBone("ValveBiped.Bip01_R_Hand") ~= nil
        if self.WeaponBonemerge then
            self.WeaponModel:SetParent(self)
            self.WeaponModel:AddEffects(EF_BONEMERGE)
        end
    end

    if self.WeaponBonemerge then
        self.WeaponModel:DrawModel()
        return
    end

    local handPos, handAng = self:GetHandTransform()
    if not handPos then return end

    local pos, ang = LocalToWorld(w.Offset or Vector(5, -2.7, 0), w.AngOffset or Angle(180, 180, 0), handPos, handAng)
    self.WeaponModel:SetModelScale(self:GetModelScale(), 0)
    self.WeaponModel:SetPos(pos)
    self.WeaponModel:SetAngles(ang)
    self.WeaponModel:SetupBones()
    self.WeaponModel:DrawModel()
end

function ENT:DrawWeaponGlow()
    local w = self:GetWeaponData()
    if not w or not w.Glow then return end

    local pos, ang = self:GetHandTransform()
    if not pos then return end

    local scale = self:GetModelScale()
    render.SetMaterial(matGlow)
    for _, dist in ipairs({ -32, 32 }) do
        local p = pos + ang:Forward() * dist * scale
        render.DrawSprite(p, 40 * scale, 40 * scale, w.Glow)
    end
end

function ENT:OnRemove()
    if IsValid(self.WeaponModel) then
        self.WeaponModel:Remove()
    end
    if self.JetSound then
        self.JetSound:Stop()
        self.JetSound = nil
    end
    self:OnDroidRemovedClient()
end

function ENT:OnDroidRemovedClient()
end

-- ============================================================
-- NAMENSSCHILD
-- ============================================================
function ENT:DrawNameTag()
    if not C.ShowNameTags then return end

    local pos = self:GetPos()
    local maxDist = C.NameTagDistance
    if EyePos():DistToSqr(pos) > maxDist * maxDist then return end

    local health = self:Health()
    local maxHealth = math.max(self:GetMaxHealth(), 1)
    local height = self:OBBMaxs().z + self.NameTagOffset

    local ang = Angle(0, EyeAngles().y - 90, 90)

    cam.Start3D2D(pos + Vector(0, 0, height), ang, 0.12)
        local width = draw.SimpleText(self.PrintName, "EOCDroids.Title", 0, -40, colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        width = math.max(width, 160)

        EOCDroids.RoundedBox(4, -width / 2, -32, width, 8, colorBack)
        if health > 0 then
            EOCDroids.RoundedBox(4, -width / 2, -32, width * math.Clamp(health / maxHealth, 0, 1), 8, self:GetNameTagColor())
        end
    cam.End3D2D()
end

function ENT:GetNameTagColor()
    return self.NameTagColor
end

-- ============================================================
-- JETPACK-FLAMME
-- ============================================================
local jetBlue = Color(80, 120, 255, 160)
local jetWhite = Color(255, 255, 255, 128)
local jetNone = Color(255, 255, 255, 0)
local jetGlow = Color(255, 174, 0)

function ENT:DrawJetpackFlame()
    local inAir = self:GetNW2Bool("EOCInAir", false)

    if not self.JetSound then
        self.JetSound = CreateSound(self, "thrusters/jet03.wav")
        self.JetSound:SetSoundLevel(C.JetpackSoundLevel)
    end

    if not inAir then
        if self.JetSound:IsPlaying() then self.JetSound:FadeOut(0.2) end
        return
    end

    if not self.JetSound:IsPlaying() then self.JetSound:PlayEx(C.JetpackVolume, 125) end

    local scale = self:GetModelScale()
    local yaw = Angle(0, self:GetAngles().y, 0)
    local pos = self:GetPos() + Vector(0, 0, 42 * scale) - yaw:Forward() * 10 * scale
    local down = Vector(0, 0, -1)
    local scroll = UnPredictedCurTime() * -10

    render.SetMaterial(matFire)
    render.StartBeam(3)
        render.AddBeam(pos, 25 * scale, scroll, jetBlue)
        render.AddBeam(pos + down * 25 * scale, 14 * scale, scroll + 1, jetWhite)
        render.AddBeam(pos + down * 60 * scale, 8 * scale, scroll + 3, jetNone)
    render.EndBeam()

    render.SetMaterial(matGlow)
    render.DrawSprite(pos, 70 * scale, 70 * scale, jetGlow)

    self.JetLightId = self.JetLightId or EOCDroids.NextLightId()
    EOCDroids.Light(pos, jetGlow, 180, 0.1, 2, self.JetLightId)
end

-- ============================================================
-- SCHARFSCHUETZEN-LASER
-- ============================================================
local laserCol = Color(255, 40, 40, 255)

function ENT:DrawAimLaser()
    local target = self:GetNW2Entity("EOCAimTarget")
    if not IsValid(target) then return end

    local handPos = self:GetHandTransform()
    local start = handPos and (handPos + self:GetForward() * 14) or (self:GetPos() + Vector(0, 0, 50))
    local finish = EOCDroids.TargetPos(target)

    render.SetMaterial(matLaser)
    render.DrawBeam(start, finish, 2, 0, 1, laserCol)
    render.SetMaterial(matGlow)
    render.DrawSprite(start, 24, 24, laserCol)
    render.DrawSprite(finish, 18, 18, laserCol)
end

-- ============================================================
-- AURA-RING (Offizier repariert, Captain verstaerkt)
-- ============================================================
function ENT:DrawPulseRing(col, radius)
    if not self:GetNW2Bool("EOCPulse", false) then
        self.PulseSize = 0
        return
    end
    self.PulseSize = Lerp(FrameTime() * 3, self.PulseSize or 0, radius * 2)
    render.SetMaterial(matRing)
    render.DrawQuadEasy(self:GetPos() + Vector(0, 0, 2), Vector(0, 0, 1), self.PulseSize, self.PulseSize, col, 0)
end

-- ============================================================
-- ZEICHNEN
-- ============================================================
function ENT:Draw()
    self:DrawModel()
    self:DrawWeaponModel()
end

-- Draw() laeuft im undurchsichtigen Pass, alles Leuchtende hier im transparenten Pass
function ENT:DrawTranslucent()
    self:DrawWeaponGlow()
    self:DrawExtras()
    self:DrawNameTag()

    if EOCDroids.DebugEnabled then
        self:DrawDebug()
    end
end

-- Fuer die einzelnen Droiden (Schild, Jetpack, ...)
function ENT:DrawExtras()
end

function ENT:DrawDebug()
    local pos = self:GetPos()
    local enemy = self:GetEnemy()

    cam.Start3D2D(pos + Vector(0, 0, 4), Angle(0, 0, 0), 1)
        surface.DrawCircle(0, 0, self.ShootingRange, 255, 0, 0, 255)
        surface.DrawCircle(0, 0, self.LooseRadius, 255, 120, 0, 255)
    cam.End3D2D()

    cam.Start3D2D(pos + Vector(0, 0, self:OBBMaxs().z + 40), Angle(0, EyeAngles().y - 90, 90), 0.12)
        draw.SimpleText(self:GetClass() .. " #" .. self:EntIndex(), "EOCDroids.Debug", 0, 0, colorDebug, TEXT_ALIGN_CENTER)
        draw.SimpleText("HP " .. self:Health(), "EOCDroids.Debug", 0, 36, colorDebug, TEXT_ALIGN_CENTER)
        draw.SimpleText("Ziel: " .. (IsValid(enemy) and tostring(enemy) or "-"), "EOCDroids.Debug", 0, 72, colorDebug, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    render.DrawWireframeBox(pos, Angle(0, 0, 0), self:OBBMins(), self:OBBMaxs(), colorWire, true)

    if IsValid(enemy) then
        render.DrawLine(pos + Vector(0, 0, 50), enemy:GetPos() + Vector(0, 0, 50), colorDebug, true)
    end
end
