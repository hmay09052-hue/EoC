AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DC-15xr"
SWEP.Trivia_Class = "Blaster Sniper Rifle"
SWEP.SubCategory = "5Snipers"
SWEP.Trivia_Desc = "Modified DC-15X with railgun capabilities. Capable of charging shots for increased damage and range.\n\nA favorite among Republic marksmen for its versatility and raw power."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0001000000000000"
SWEP.DefaultWMBodygroups = "0001000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_dc15x_railgun.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_dc15x.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-8, 3.5, -4.5),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}


-- special properties
SWEP.ChargeTime = 2.0 
SWEP.ChargeShakeIntensity = 0.5
SWEP.ChargeShakeMax = 2.0 

SWEP.ChargeStartSound = "arccw/kraken/republic/dc15xr/chargestart.wav"
SWEP.ChargeLoopSound = "arccw/kraken/republic/dc15xr/chargeloop.wav"
SWEP.ChargeEndSound = "arccw/kraken/republic/dc15xr/chargeend.wav"

SWEP.IsCharging = false
SWEP.ChargeStartTime = 0
SWEP.ChargeLoopPlaying = false
SWEP.ChargeSoundCSP = nil

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 110
SWEP.DamageMin = 51
SWEP.RangeMin = 0
SWEP.Range = 900
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 12

SWEP.Recoil = 1.8
SWEP.RecoilSide = 1.5
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 120
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
        Mode = 1,
        PrintName = "STANDARD",
    },
    {
        Mode = 1,
        PrintName = "CHARGED SHOT ONLY",
        Override_Damage = 240,
        Override_DamageMin = 150,
        Override_Range = 1200,
        Override_DamageType = DMG_DISSOLVE,
        Override_Tracer = "railgun_tracer_blue",
        Override_AccuracyMOA = 0,
        Override_HipDispersion = 100,
        Mult_Recoil = 2.22,
        Mult_RecoilRise = 2,
    },
    {
        Mode = 0,
    }
}

function SWEP:IsRailgunMode()
    local idx = self:GetFireMode()
    if idx == 2 then return true end
    if SERVER and game.SinglePlayer() then
        local fm = self:GetCurrentFiremode()
        if fm and fm.PrintName == "CHARGED SHOT ONLY" then return true end
    end
    return false
end

SWEP.AccuracyMOA = 1
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.85
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

-- Ammo, Sounds & MuzzleEffect

SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_DC15X"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC15X_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.RailgunShootSound = "ArcCW_Kraken.SW_DC15XR"
SWEP.RailgunDistantShootSound = "ArcCW_Kraken.SW_DC15XR_Distant"

SWEP.Hook_GetShootSound = function(wep, sound)
    if wep:GetFireMode() == 2 then
        return wep.RailgunShootSound
    end
end

SWEP.Hook_GetDistantShootSound = function(wep, sound)
    if wep:GetFireMode() == 2 then
        return wep.RailgunDistantShootSound
    end
end

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 255)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.95, -5, 1.7),
    Ang = Angle(1.2, 0, 0),
     Magnification = 1,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(-1, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, -2)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, 0, 5)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(4, -3, -2)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.BarrelLength = 45

function SWEP:InitializeChargeSystem()
    self.IsCharging = false
    self.ChargeStartTime = 0
    self.ChargeLoopPlaying = false
    self.ChargeComplete = false
    self.LastChargeShakeTime = 0
    self.ChargeFired = false
    self.ChargeReady = false
    self.ChargeRequireRelease = false
    self.LastFireModeIndex = self:GetFireMode()
end

function SWEP:GetChargeProgress()
    if not self.IsCharging or self.ChargeStartTime == 0 then return 0 end
    return math.Clamp((CurTime() - self.ChargeStartTime) / self.ChargeTime, 0, 1)
end

function SWEP:ApplyChargeShake()
    local progress = self:GetChargeProgress()
    local intensity = Lerp(progress, self.ChargeShakeIntensity, self.ChargeShakeMax)
    
    local shakeAngle = Angle(
        math.Rand(-1, 1) * intensity,
        math.Rand(-1, 1) * intensity * 0.2,
        math.Rand(-1, 1) * intensity * 0.1
    )
    
    if CLIENT then
        if self.OurViewPunch then
            self:OurViewPunch(shakeAngle)
        else
            local owner = self:GetOwner()
            if IsValid(owner) then
                owner:ViewPunch(shakeAngle)
            end
        end
    end
    
    if SERVER and game.SinglePlayer() then
        local owner = self:GetOwner()
        if IsValid(owner) then
            owner:ViewPunch(shakeAngle)
        end
    end
end

function SWEP:StartCharging()
    if self.IsCharging then return end
    
    self.IsCharging = true
    self.ChargeStartTime = CurTime()
    self.ChargeComplete = false
    self.ChargeLoopPlaying = false
    self.ChargeFired = false
    self.ChargeReady = false
    
    self:EmitSound(self.ChargeStartSound, 75, 100, 1, CHAN_WEAPON)

    local initialShake = Angle(-1.5, math.Rand(-0.5, 0.5), 0)
    if CLIENT and self.OurViewPunch then
        self:OurViewPunch(initialShake)
    elseif SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            owner:ViewPunch(initialShake)
        end
    end
end

function SWEP:StopAllChargeSounds()

    if self.ChargeLoopPlaying then
        self:StopSound(self.ChargeLoopSound)
        self.ChargeLoopPlaying = false
    end
    
    self:StopSound(self.ChargeStartSound)

    self:StopSound(self.ChargeEndSound)
end

function SWEP:StopCharging()
    if not self.IsCharging then return end
    
    self.IsCharging = false
    self.ChargeStartTime = 0
    self.ChargeComplete = false
    self.ChargeFired = false
    self.ChargeReady = false
    
    self:StopAllChargeSounds()
end

function SWEP:CanStartCharging()
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
    
    if self.ChargeRequireRelease then return false end

    local clip = self:Clip1()
    if clip <= 0 then return false end
    
    if self:GetNextPrimaryFire() > CurTime() then return false end
    if self:GetReloading() then return false end
    if self:GetInCustomize() then return false end
    if self:GetState() == ArcCW.STATE_SPRINT then return false end
    if self:GetPriorityAnim() then return false end
    
    return true
end

SWEP.Hook_Think = function(wep)
    if wep.IsCharging == nil then
        wep:InitializeChargeSystem()
    end
    
    local owner = wep:GetOwner()
    if not IsValid(owner) then return end
    
    local currentFM = wep:GetFireMode()
    if wep.LastFireModeIndex ~= currentFM then
        wep.LastFireModeIndex = currentFM
        if wep.IsCharging then
            wep:StopCharging()
        end
        wep.ChargeFired = false
        wep.ChargeRequireRelease = false
    end
    
    local isRailgun = (currentFM == 2)
    
    if not isRailgun then
        if wep.IsCharging then
            wep:StopCharging()
        end
        return
    end
    
    local attackPressed = owner:KeyDown(IN_ATTACK)
    
    if attackPressed then
        if not wep.IsCharging and not wep.ChargeFired and wep:CanStartCharging() then
            wep:StartCharging()
        elseif wep.IsCharging and not wep.ChargeFired then
            local progress = wep:GetChargeProgress()
            
            if CurTime() - (wep.LastChargeShakeTime or 0) > 0.05 then
                wep:ApplyChargeShake()
                wep.LastChargeShakeTime = CurTime()
            end
            
            if progress >= 1 and not wep.ChargeReady then
                wep.ChargeReady = true
                wep.ChargeComplete = true
                
                wep:StopAllChargeSounds()          

                wep:EmitSound(wep.ChargeEndSound, 75, 100, 1, CHAN_ITEM)    

                local finalShake = Angle(-3, math.Rand(-1, 1), 0)
                if CLIENT and wep.OurViewPunch then
                    wep:OurViewPunch(finalShake)
                elseif SERVER then
                    owner:ViewPunch(finalShake)
                end
            end
        end
    else

        if wep.IsCharging and not wep.ChargeComplete then
            wep:StopCharging()
        end

        wep.ChargeRequireRelease = false
    end
end

local OriginalPrimaryAttack = nil

function SWEP:PrimaryAttack()
    if self.IsCharging == nil then
        self:InitializeChargeSystem()
    end
    
    local currentFM = self:GetFireMode()
    local isRailgun = (currentFM == 2)
    
    if not isRailgun then
        local base = self.BaseClass
        while base do
            if base.PrimaryAttack and base.PrimaryAttack ~= self.PrimaryAttack then
                base.PrimaryAttack(self)
                break
            end
            base = base.BaseClass
        end
        return
    end
    
    if self.ChargeReady and self.ChargeComplete and not self.ChargeFired then
        self.ChargeFired = true
        self.ChargeReady = false
        self.IsCharging = false
        self.ChargeStartTime = 0
        self.ChargeComplete = false
        self.ChargeRequireRelease = true
        
        self:StopAllChargeSounds()
        
        local base = self.BaseClass
        while base do
            if base.PrimaryAttack and base.PrimaryAttack ~= self.PrimaryAttack then
                base.PrimaryAttack(self)
                break
            end
            base = base.BaseClass
        end
        
        timer.Simple(0.1, function()
            if IsValid(self) then
                self.ChargeFired = false
            end
        end)
        
        return
    end

end

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "DC_15X_Rifle",
               Scale = Vector(0, 0, 0),                
               Offset = {
                pos = Vector(-0.05, 19.2, 0.7),
                ang = Angle(-90, -90, 0)
               },
               IsMuzzleDevice = true
           }
        }
    }
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = {"optic", "kraken_holohud"},
        Bone = "DC_15X_Rifle",
        Offset = {
            vpos = Vector(-0.05, 0, 1.7),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        Bone = "DC_15X_Rifle",
        Offset = {
            vpos = Vector(-0.7, 15, 0.5),
            vang = Angle(0, -90, -90),
        },
    },
    {
        PrintName = "Muzzle",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "DC_15X_Rifle",
        Offset = {
            vpos = Vector(-0.05, 19.2, 0.7),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Foregrip",
        Slot = {"foregrip"},
        Bone = "DC_15X_Rifle",
        Offset = {
            vpos = Vector(-0.05, 8, -0.9),
            vang = Angle(90, -90, -90),   
        }, 
    },
    {
        PrintName = "Ammunition",
        Slot = {"ammo"}
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Charm",
        Slot = {"charm"},
        Bone = "DC_15X_Rifle",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.1, -4.67, 0.15),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "DC_15X_Rifle",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(1.05, -7.5, 0.3),
            vang = Angle(0, -90, 0),
        },
    },
}

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["fire_iron"] = {},
    ["idle"] = {
        Time = 9,
        Source = "idle",
    },
    ["fire"] = {
        Source = "fire"
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {s = "weapon_hand/reload_gentle/hits_and_grabs/023d-00000b29.mp3", t = 0.1 / 10},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = "weapon_hand/reload_heavy/mag_load/023d-00000f0b.mp3", t = 0.1 / 10},
        },
    },
    ["reload"] = {
        Source = "reload",
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.7,
        Mult = 1.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "weapon_hand/023d-00000d8c.mp3", t = 0.2 },
            {s = "weapon_hand/reload_heavy/mag_eject/023d-000005ce.mp3", t = 0.4 },
            {s = "weapon_hand/reload_heavy/hits/023d-00000ae4.mp3", t = 0.6 },   
            {s = "weapon_hand/reload_heavy/mag_load/023d-0000055c.mp3", t = 1.4 },   
            {s = "weapon_hand/reload_heavy/locknload/0215-00001edd.mp3", t = 1.6 },   
        },
    },
}
