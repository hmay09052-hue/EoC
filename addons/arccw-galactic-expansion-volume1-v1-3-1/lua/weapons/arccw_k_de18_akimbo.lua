AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.HasHoloHUD1 = true
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 2 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DE-18 Akimbo"
SWEP.Trivia_Class = "Blaster Pistol"
SWEP.Trivia_Desc = "Blaster Pistol designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/de18_akimbo.png"

-- Viewmodel & Entity Properties
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/galactic/v_akimbo_de18.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_de18.mdl"

SWEP.ViewModelFOV = 65

SWEP.NoHideLeftHandInCustomization = true
SWEP.WorldModelOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.09
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 12
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatFix = true
SWEP.HeatDelayTime = 0.5

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 72
SWEP.DamageMin = 39
SWEP.RangeMin = 0
SWEP.Range = 170
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(179, 0, 250)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_purple"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 30

SWEP.Recoil = 2
SWEP.RecoilSide = 0.65
SWEP.RecoilRise = 0.85
SWEP.RecoilPunch = 1.5

SWEP.Delay = 60 / 160
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.1,
        RunawayBurst = false,
        Mult_RPM = 2,
    },
	{
		Mode = 0,
   	}
}

local s = "ArcCW_Kraken.OverheatWarn"
local p = {
    [2] = 80,
    [1] = 90,
    [0] = 100,
}
SWEP.Hook_AddShootSound = function(wep, data)
    local pitch = p[wep:Clip1()]
    if pitch then
        wep:MyEmitSound(s, 100, pitch, 0.5, CHAN_AUTO)
    end
end

SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.955
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_DL18_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_DL18_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = false
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(179, 0, 250)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(0, 0, 0),
    Ang = Angle(0, 0, 0),
     Magnification = 1.5,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "duel"
SWEP.HoldtypeSights = "duel"
SWEP.HoltypeCustomize = "normal"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL

SWEP.SprintPos = Vector(0, -20, -10)
SWEP.SprintAng = Angle(35, 0, 0)

SWEP.CustomizePos = Vector(0, 0, 0)
SWEP.CustomizeAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(0, -5.226, 1)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(0, -4, -1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.HolsterPos = Vector(0, 0, 0)
SWEP.HolsterAng = Vector(-30, 0, 0)

SWEP.BarrelLength = 20

-- Attachments
SWEP.Attachments = {
    {
        PrintName = "Energization",
        DefaultAttName = "Standard",
        Slot = {"ammo", "special_ammo"}
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
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
        Source = "idle",
    },
    ["bash"] = {
        Source = "bash",
    },
    ["idle_iron"] = {
        Source = "idle",
    },
	["fire"] = {
        Source = {"shoot_l", "shoot_r"},
        Mult = 2,
    },
    ["fire_iron"] = {
        Source = {"shoot_l", "shoot_r"},
        Mult = 2,
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 25/30},
        },
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "arccw/kraken/empire/draw_pistol.wav",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {
                s = "arccw/kraken/empire/draw_pistol.wav",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["enter_inspect"] = {
        Source = "lookat01",
        Mult = 2,
    },
    ["idle_inspect"] = {
        Source = "lookat01",
        Mult = 2,
    },
}


function SWEP:DrawWorldModel()
    if IsValid(self:GetOwner()) then
        -- Held: no dibujar (lo hacemos por PostPlayerDraw pegado a los huesos)
        return
    end
    self:DrawModel()
end

if CLIENT then
    SWEP.HandWM = {
        RH = { -- Right Hand
            model = "models/arccw/kraken/galactic/worldmodels/w_de18.mdl",
            att   = "anim_attachment_RH",
            bone  = "ValveBiped.Bip01_R_Hand",
            pos   = Vector(1,  8,  3),  
            ang   = Angle(0,   0,  0), 
            scale = 1
        },
        LH = { -- Left Hand
            model = "models/arccw/kraken/galactic/worldmodels/w_de18.mdl",
            att   = "anim_attachment_LH",
            bone  = "ValveBiped.Bip01_L_Hand",
            pos   = Vector(0.6,  8,  3),  
            ang   = Angle(0,   0,   0),
            scale = 1
        }
    }

    local function buildWM(wep, key)
        wep._wm = wep._wm or {}
        if IsValid(wep._wm[key]) then return end
        local cfg = wep.HandWM[key]; if not cfg then return end
        local m = ClientsideModel(cfg.model, RENDERGROUP_OPAQUE)
        if not IsValid(m) then return end
        m:SetNoDraw(true)

        if IsValid(wep.WM) then
            m:SetSkin(wep.WM:GetSkin() or 0)
            for i = 0, (wep.WM:GetNumBodyGroups() or 0) - 1 do
                m:SetBodygroup(i, wep.WM:GetBodygroup(i))
            end
        end
        wep._wm[key] = m
    end

    local function removeAllWM(wep)
        if not wep._wm then return end
        for k, ent in pairs(wep._wm) do
            if IsValid(ent) then ent:Remove() end
            wep._wm[k] = nil
        end
    end

    local function handTransform(ply, cfg)

        local pos, ang
        local attId = cfg.att and ply:LookupAttachment(cfg.att)
        if attId and attId > 0 then
            local att = ply:GetAttachment(attId)
            if att then pos, ang = att.Pos, att.Ang end
        end

        if not pos then
            local b = ply:LookupBone(cfg.bone or "")
            if not b then return end
            local m = ply:GetBoneMatrix(b)
            if not m then return end
            pos, ang = m:GetTranslation(), m:GetAngles()
        end
        if not pos then return end


        local off  = cfg.pos or vector_origin
        local aoff = cfg.ang or angle_zero
        ang:RotateAroundAxis(ang:Right(),   aoff.p or aoff.pitch or aoff.x or 0)
        ang:RotateAroundAxis(ang:Up(),      aoff.y or aoff.yaw   or aoff.y or 0)
        ang:RotateAroundAxis(ang:Forward(), aoff.r or aoff.roll  or aoff.z or 0)
        pos = pos + ang:Right()*off.x + ang:Forward()*off.y + ang:Up()*off.z
        return pos, ang
    end

    function SWEP:DrawDualWM(ply)

        if ply ~= self:GetOwner() then return end
        if ply:GetActiveWeapon() ~= self then return end

        for key, cfg in pairs(self.HandWM) do
            buildWM(self, key)
            local ent = self._wm and self._wm[key]
            if not IsValid(ent) then goto cont end

            local pos, ang = handTransform(ply, cfg)
            if not pos then goto cont end

            if cfg.scale and cfg.scale ~= 1 then
                local mx = Matrix(); mx:Scale(Vector(cfg.scale, cfg.scale, cfg.scale))
                ent:EnableMatrix("RenderMultiply", mx)
            end

            ent:SetRenderOrigin(pos)
            ent:SetRenderAngles(ang)
            ent:SetupBones()
            ent:DrawModel()
            ::cont::
        end
    end
    

    hook.Add("PostPlayerDraw", "KRK_Akimbo_DrawHandsWM", function(ply)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.DrawDualWM then
            wep:DrawDualWM(ply)
        end
    end)

    -- Limpieza de seguridad
    function SWEP:OnRemove()  removeAllWM(self) end
    function SWEP:Holster()   removeAllWM(self) return true end
    function SWEP:OwnerChanged() removeAllWM(self) end
end
