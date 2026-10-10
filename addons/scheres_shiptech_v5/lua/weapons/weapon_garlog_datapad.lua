AddCSLuaFile()

-- GAR-Datapad: EIN Werkzeug für Logistik, Feldbasis, Schiffs-/Fahrzeugreparatur und Technik
--   LMB auf Schiff/Fahrzeug  -> Fusion-Cutter-Reparaturprotokoll
--   LMB halten auf Baustelle -> bauen / beschädigte Struktur reparieren
--   LMB sonst                -> Logistik
--   RMB                      -> Bauplanung (auf Struktur der Feldbasis: abbauen)
--   R                        -> Technik-Kontrollterminal

SWEP.PrintName    = "GAR-Datapad"
SWEP.Author       = "GAR Logistik"
SWEP.Category     = "GAR Logistik"
SWEP.Instructions = "LMB: Logistik / Reparatur / Bauen | RMB: Bauplanung | R: Technik-Kontrollterminal"
SWEP.Purpose      = "Logistik, Feldbasis, Wartung & Instandsetzung"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = "models/lt_c/sci_fi/holo_tablet.mdl"
SWEP.UseHands     = false
SWEP.ViewModelFOV = 62

SWEP.Slot    = 4
SWEP.SlotPos = 2
SWEP.DrawAmmo      = false
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true    -- Halten = bauen / reparieren
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

-- Position des Datapads in der Ego-Ansicht / in der Hand (wie das Comlink)
SWEP.VMOffset = Vector(17, -4, -8)
SWEP.VMAngle  = Angle(-60, 180, 0)
SWEP.WMOffset = Vector(4, -2, -1)
SWEP.WMAngle  = Angle(0, 0, 180)

local WORK_DT = 0.25

function SWEP:Initialize()
    self:SetHoldType("slam")
end

function SWEP:Deploy()
    self:SetHoldType("slam")
    return true
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + WORK_DT)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local pressed = owner:KeyPressed(IN_ATTACK)

    -- 1) Schiffe & Fahrzeuge: Fusion-Cutter-Reparaturprotokoll (nur beim Drücken)
    if pressed and GARLog.TryVehicleRepair(owner, self) then return end

    -- 2) Baustellen & Strukturen der Feldbasis (halten)
    local start = owner:GetShootPos()
    local tr = util.TraceLine({
        start = start, endpos = start + owner:GetAimVector() * GARLog.Config.FOB.WorkRange,
        filter = owner, mask = MASK_SHOT,
    })
    if IsValid(tr.Entity) and GARLog.WorkOn(owner, tr.Entity, WORK_DT) then
        local now = CurTime()
        if (self.NextSpark or 0) < now then
            self.NextSpark = now + 0.35
            local fx = EffectData()
            fx:SetOrigin(tr.HitPos)
            fx:SetNormal(tr.HitNormal)
            fx:SetMagnitude(1)
            fx:SetScale(1)
            fx:SetRadius(3)
            util.Effect("ManhackSparks", fx, true, true)
            self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 60, 100, 0.35)
        end
        return
    end

    -- 3) sonst: Logistik
    if pressed then GARLog.OpenMenu(owner, 1, nil, nil, GARLog.APP_LOGISTIK) end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local tr = owner:GetEyeTrace()
    local ent = tr.Entity
    if IsValid(ent) and GARLog.FOBEnts[ent] and tr.HitPos:DistToSqr(owner:GetShootPos()) < 300 * 300 then
        GARLog.OpenEntityMenu(owner, 4, ent)
        return
    end
    GARLog.OpenBuilder(owner)
end

function SWEP:Reload()
    if not SERVER then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if (self.NextReloadMenu or 0) > CurTime() then return end
    self.NextReloadMenu = CurTime() + 0.8
    GARLog.OpenTechnik(owner)
end

if CLIENT then
    function SWEP:GetPadModel()
        if not IsValid(self.PadModel) then
            self.PadModel = ClientsideModel(GARLog.Config.DatapadModel, RENDERGROUP_OPAQUE)
            if IsValid(self.PadModel) then self.PadModel:SetNoDraw(true) end
        end
        return self.PadModel
    end

    function SWEP:ViewModelDrawn(vm)
        local mdl = self:GetPadModel()
        if not IsValid(mdl) then return end
        local p, a = LocalToWorld(self.VMOffset, self.VMAngle, vm:GetPos(), vm:GetAngles())
        mdl:SetPos(p)
        mdl:SetAngles(a)
        mdl:SetupBones()
        mdl:DrawModel()
    end

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        local bone = IsValid(owner) and owner:LookupBone("ValveBiped.Bip01_R_Hand")
        local matrix = bone and owner:GetBoneMatrix(bone)
        if not matrix then self:DrawModel() return end
        local pos, ang = LocalToWorld(self.WMOffset, self.WMAngle, matrix:GetTranslation(), matrix:GetAngles())
        self:SetRenderOrigin(pos)
        self:SetRenderAngles(ang)
        self:SetupBones()
        self:DrawModel()
        self:SetRenderOrigin()
        self:SetRenderAngles()
    end

    function SWEP:DrawHUD()
        if GARLog.Builder and GARLog.Builder.DrawHUD then GARLog.Builder.DrawHUD(self) end
    end

    function SWEP:OnRemove()
        if IsValid(self.PadModel) then self.PadModel:Remove() end
    end

    function SWEP:Holster()
        if IsValid(self.PadModel) then self.PadModel:Remove() end
        return true
    end
end
