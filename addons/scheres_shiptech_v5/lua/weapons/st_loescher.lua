--[[
    ShipTech – Feuerlöscher
    Linksklick halten: auf brennende Konsolen (und brennende Personen) sprühen.
]]

AddCSLuaFile()

local EC = ShipTech and ShipTech.Config and ShipTech.Config.Extinguisher or {}

SWEP.PrintName    = "Feuerlöscher"
SWEP.Author       = "ShipTech"
SWEP.Category     = "ShipTech – Schiffstechnik"
SWEP.Purpose      = "Löscht Brände an Konsolen"
SWEP.Instructions = "Linksklick halten: sprühen"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true   -- Techniker bekommen ihn automatisch über ihren Job

local EXT_MODEL = EC.Model or "models/props/cs_office/fire_extinguisher.mdl"
SWEP.ViewModel    = "models/weapons/c_arms.mdl"   -- nur Hände, der Löscher wird selbst gezeichnet
SWEP.WorldModel   = EXT_MODEL
SWEP.UseHands     = true
SWEP.Slot         = 5
SWEP.SlotPos      = 2
SWEP.DrawAmmo     = false

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "Charge")
end

function SWEP:Initialize()
    self:SetHoldType("slam")
    self:SetCharge(100)
end

function SWEP:Think()
    -- Druck baut sich langsam wieder auf
    if SERVER and (self.LastSpray or 0) < CurTime() - 1 and self:GetCharge() < 100 then
        self:SetCharge(math.min(100, self:GetCharge() + FrameTime() * 8))
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.08)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if self:GetCharge() <= 0 then
        if SERVER and (self.NextEmpty or 0) < CurTime() then
            self.NextEmpty = CurTime() + 1
            owner:EmitSound("buttons/button10.wav", 60, 100, 0.5)
        end
        return
    end

    if CLIENT and IsFirstTimePredicted() then
        local em = ParticleEmitter(owner:GetShootPos())
        if em then
            for _ = 1, 3 do
                local p = em:Add("particle/particle_smokegrenade", owner:GetShootPos() + owner:GetAimVector() * 24 - Vector(0, 0, 8))
                if p then
                    p:SetVelocity(owner:GetAimVector() * math.Rand(500, 700) + VectorRand() * 40)
                    p:SetDieTime(math.Rand(0.6, 1.0))
                    p:SetStartAlpha(160)
                    p:SetEndAlpha(0)
                    p:SetStartSize(4)
                    p:SetEndSize(math.Rand(28, 44))
                    p:SetColor(235, 240, 245)
                    p:SetAirResistance(120)
                end
            end
            em:Finish()
        end
    end

    if not SERVER then return end
    self.LastSpray = CurTime()
    self:SetCharge(math.max(0, self:GetCharge() - 1.2))
    if (self.NextSound or 0) < CurTime() then
        self.NextSound = CurTime() + 0.4
        owner:EmitSound("ambient/machines/steam_release_2.wav", 60, 140, 0.35)
    end

    local range = EC.Range or 320
    local tr = util.TraceLine({ start = owner:GetShootPos(), endpos = owner:GetShootPos() + owner:GetAimVector() * range, filter = owner })
    local hit = tr.HitPos

    -- brennende Konsolen in der Nähe des Treffpunkts löschen
    for _, e in ipairs(ShipTech.ConsoleList()) do
        if e:GetNW2Float("ST_Fire", 0) > 0 then
            local center = e:WorldSpaceCenter()
            if center:DistToSqr(hit) < 140 * 140 or (tr.Entity == e) then
                ShipTech.Extinguish(e, EC.Power or 0.06, owner)
            end
        end
    end
    -- brennende Personen / Objekte
    if IsValid(tr.Entity) and tr.Entity:IsOnFire() then tr.Entity:Extinguish() end
end

function SWEP:SecondaryAttack() end

if CLIENT then
    util.PrecacheModel(EXT_MODEL)

    local function Prop(self, key)
        if not IsValid(self[key]) then
            self[key] = ClientsideModel(EXT_MODEL, RENDERGROUP_OPAQUE)
            if IsValid(self[key]) then self[key]:SetNoDraw(true) end
        end
        return self[key]
    end

    -- Ego-Ansicht: Feuerlöscher vor der Kamera
    function SWEP:PostDrawViewModel(vm)
        local m = Prop(self, "ST_VMProp")
        if not IsValid(m) then return end
        local pos, ang = vm:GetPos(), vm:GetAngles()
        local off = EC.ViewOffset or Vector(20, -9, -13)
        local a = Angle(ang.p, ang.y, ang.r)
        local rot = EC.ViewAngle or Angle(0, 90, 0)
        a:RotateAroundAxis(a:Up(), rot.y)
        a:RotateAroundAxis(a:Right(), rot.p)
        a:RotateAroundAxis(a:Forward(), rot.r)
        m:SetPos(pos + ang:Forward() * off.x - ang:Right() * off.y + ang:Up() * off.z)
        m:SetAngles(a)
        m:SetupBones()
        m:DrawModel()
    end

    -- In der Hand anderer Spieler
    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        local bone = IsValid(owner) and owner:LookupBone("ValveBiped.Bip01_R_Hand")
        local mat = bone and owner:GetBoneMatrix(bone)
        if not mat then
            self:DrawModel()
            return
        end
        local m = Prop(self, "ST_WMProp")
        if not IsValid(m) then return end
        local pos, ang = mat:GetTranslation(), mat:GetAngles()
        local off = EC.WorldOffset or Vector(3, -2, -6)
        local rot = EC.WorldAngle or Angle(0, 0, 180)
        ang:RotateAroundAxis(ang:Up(), rot.y)
        ang:RotateAroundAxis(ang:Right(), rot.p)
        ang:RotateAroundAxis(ang:Forward(), rot.r)
        m:SetPos(pos + ang:Forward() * off.x + ang:Right() * off.y + ang:Up() * off.z)
        m:SetAngles(ang)
        m:SetupBones()
        m:DrawModel()
    end

    function SWEP:OnRemove()
        if IsValid(self.ST_VMProp) then self.ST_VMProp:Remove() end
        if IsValid(self.ST_WMProp) then self.ST_WMProp:Remove() end
    end
    SWEP.Holster = function(self)
        if IsValid(self.ST_VMProp) then self.ST_VMProp:Remove() end
        return true
    end

    function SWEP:DrawHUD()
        local P = ShipTech.Colors
        local w, h = 200, 40
        local x, y = ScrW() - w - 30, ScrH() - 140
        ShipTech.Box(x, y, w, h, P.bg)
        draw.SimpleText("LÖSCHMITTEL", "ShipTech_UISub", x + 10, y + 12, P.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local f = self:GetCharge() / 100
        ShipTech.Box(x + 10, y + 24, w - 20, 8, P.panel2)
        surface.SetDrawColor(f > 0.25 and P.cyan or P.red)
        surface.DrawRect(x + 10, y + 24, (w - 20) * f, 8)
    end
end
