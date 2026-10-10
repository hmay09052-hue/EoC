AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 4

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Special Forces"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Quad Blaster (Republic)"
SWEP.Trivia_Class = "Blaster Heavy Repeater"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The reciprocating quad blaster, often shortened to 'Cip-Quad' was an experimental weapon developed during the Clone Wars by Merr-Sonn Munitions."
SWEP.IconOverride = "entities/kraken/sops/quad_republic.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00100000000"
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sops/new/v_quadblaster_republic.mdl"
SWEP.WorldModel = "models/arccw/kraken/sops/new/w_quadblaster_republic.mdl"
SWEP.ViewModelFOV = 54
SWEP.MirrorVMWM = true
SWEP.WorldModelOffset = {
    pos = Vector(-7, 6, -8),
    ang = Angle(0, 5, 180)
}

-- Special Properties
SWEP.InfiniteAmmo = true
SWEP.BottomlessClip = true

-- Damage & Tracer
SWEP.Damage = 40
SWEP.DamageMin = 24
SWEP.RangeMin = 0
SWEP.Range = 340
SWEP.Penetration = 10

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 50

SWEP.DamageType = DMG_BLAST
SWEP.MuzzleVelocity = 400
SWEP.TraceNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)
SWEP.HullSize = 0.5

SWEP.Recoil = 0.35
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.3
SWEP.MaxRecoilBlowback = 1
SWEP.RecoilPunch = 1
SWEP.RecoilVMShake = 1

SWEP.Num = 1
SWEP.Delay = 60 / 180
SWEP.Firemode = 2
SWEP.Firemodes = {
    {
        Mode = 2,
    },
    {
        Mode = 0
    }
}

SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.68
SWEP.SightedSpeedMult = 0.83
SWEP.SightTime = 0.23

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100 
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.1

SWEP.NoFlash = true
SWEP.MuzzleEffectAttachment = "1"
SWEP.ProceduralViewBobAttachment = 1

SWEP.ShootSound = "ArcCW_Kraken.SOPS_QUADBLASTER_REPUBLIC"
SWEP.DistantShootSound = "ArcCW_Kraken.SOPS_QUADBLASTER_REPUBLIC_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

-- Ironsight
SWEP.IronSightStruct = false

-- Holdtype
SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "duel"
SWEP.HoldtypeSights = "duel"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 14, -5)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(3, 0, 0)
SWEP.SprintAng = Angle(-10, 40, -40)

SWEP.HolsterPos = Vector(0, 14, -5)
SWEP.HolsterAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(20.9, -10, 3.9)
SWEP.CustomizeAng = Angle(12.1, 50.5, 45)

SWEP.Attachments = {     
    {
        PrintName = "Energization", 
        DefaultAttName = "Standard",
        Slot = {"ammo", "ammo_masita", "ammo_stun"},
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = {"perk", "mw3_pro"},
    },
    {
        PrintName = "Internal Modifications",
        DefaultAttName = "None",
        Slot = {"uc_fg"},
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}


-- Don't touch this unless you know what you're doing
SWEP.Animations = {
    ["idle"] = {
        Source = "idle_deployed"
    },
    ["fire"] = {
        Source = "idle_shooting"
    },
    ["draw"] = {
        Source = "deploy",
        SoundTable = {
            {
                s = "ArcCW_Kraken.Draw",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["holster"] = {
        Source = "retract",
        SoundTable = {
            {
                s = "ArcCW_Kraken.Holster",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["reload"] = {
        Source = "retract",
    },
}

if CLIENT then
    function SWEP:PlaceHandsOnGun()
        local leftElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_L_Forearm")
        self:GetOwner():ManipulateBoneAngles(leftElbow, Angle(20, -20, 0))

        local rightShoulder = self:GetOwner():LookupBone("ValveBiped.Bip01_R_UpperArm")
        self:GetOwner():ManipulateBoneAngles(rightShoulder, Angle(0, 15, 0))

        local rightElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_R_Forearm")
        self:GetOwner():ManipulateBoneAngles(rightElbow, Angle(-30, -40, 0))
    end

    function SWEP:ResetBoneAngles()
        local leftElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_L_Forearm")
        self:GetOwner():ManipulateBoneAngles(leftElbow, Angle(0, 0, 0))

        local rightShoulder = self:GetOwner():LookupBone("ValveBiped.Bip01_R_UpperArm")
        self:GetOwner():ManipulateBoneAngles(rightShoulder, Angle(0, 0, 0))

        local rightElbow = self:GetOwner():LookupBone("ValveBiped.Bip01_R_Forearm")
        self:GetOwner():ManipulateBoneAngles(rightElbow, Angle(0, 0, 0))
    end
end

function SWEP:DrawWorldModel()
    if IsValid(self.Owner) then 
        self:SetPoseParameter("head_pitch", self.Owner:EyeAngles()[1])
        self:InvalidateBoneCache()
    end
    self:DrawModel()
end

function SWEP:Deploy()
    if SERVER then
        self:SetSequence(2)
        self:GetOwner():GetViewModel():SendViewModelMatchingSequence(2)
    end
end

function SWEP:Holster()
    if SERVER then
        self:SetSequence(3)
    end
    if CLIENT then
        self:ResetBoneAngles()
    end

    return true
end

function SWEP:ReloadTicker()end

function SWEP:Anims() end

function SWEP:Reload()
    if self:GetCurrentFiremode().Mode == 2 then
        if CurTime() > (self.ReloadWaitTime or 0) then
            if self:Clip1() < self:GetMaxClip1() and self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()) > 0 then
                local ammo = math.Clamp(50, 0, self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()))
                ammo = math.min(ammo, self:GetMaxClip1() - self:Clip1())
                self:SetClip1(math.Clamp(self:Clip1() + ammo, 0, self:GetMaxClip1()))
                self:GetOwner():RemoveAmmo(ammo, self:GetPrimaryAmmoType())

                if self:Clip1() == self:GetMaxClip1() then
                    self.ReloadWaitTime = 0
                else
                    self.ReloadWaitTime = CurTime() + 0.5
                end
            end
        end
    end
end

function SWEP:ShouldReload()
    return self:GetCurrentFiremode().Mode == 2 and CurTime() > (self.ReloadWaitTime or 0) and self:Clip1() < self:GetMaxClip1() and self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()) > 0
end

function SWEP:Think()

    self.Anims()
    self.ReloadTicker()
    
    if SERVER then
        if self:GetCurrentFiremode().Mode == 2 then
            self:GetOwner():GetViewModel():SendViewModelMatchingSequence(3)
            self:SetHoldType("normal")
            self:SetSequence(1)
            self.ReloadTicker = function()
                if self:GetCurrentFiremode().Mode == 0 then
                    if CurTime() then
                        if self:Clip1() < self:GetMaxClip1() and self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()) > 0 then
                            local ammo = math.Clamp(50, 0, self:GetOwner():GetAmmoCount(self:GetPrimaryAmmoType()))
                            ammo = math.min(ammo, self:GetMaxClip1()-self:Clip1())
                            self:SetClip1(math.Clamp(self:Clip1() + ammo, 0, self:GetMaxClip1()))
                            self:GetOwner():RemoveAmmo( ammo, self:GetPrimaryAmmoType() )
                            if self:Clip1() == self:GetMaxClip1() then
                                self.ReloadTicker = function()end
                            else
                                self.ReloadWaitTime = CurTime() + 0.5
                            end
                        end
                    end
                else
                    self.ReloadTicker = function()end
                end
            end
        end
        if self:GetCurrentFiremode().Mode == 0 then
            self:SetSequence(3)
        end
        if self:GetOwner():KeyDown(IN_ATTACK) then
            self:SetSequence(5)
            self:GetOwner():GetViewModel():SendViewModelMatchingSequence(5)
            self:SetHoldType("duel")
        end
        if self:GetOwner():KeyReleased(IN_ATTACK) then
            self:SetSequence(1)
        end
        if self:GetSequence() == 5 then
            self:SetCycle( math.min(self:GetCycle() + 5*FrameTime(), 1))
        else
            self:SetCycle( math.min(self:GetCycle() + 0.5*FrameTime(), 1))
        end
        if self:GetCycle() >= 1 then
            if tonumber(self:GetSequence()) == 5 then
                self:SetCycle( 0 )
            end
        end
    end
    self:NextThink(CurTime())
    return true
end
