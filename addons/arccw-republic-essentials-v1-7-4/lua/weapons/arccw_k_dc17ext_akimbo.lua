AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Dual DC-17 Extended"
SWEP.Trivia_Class = "Hand Blaster"
SWEP.SubCategory = "1Pistols"
SWEP.Trivia_Desc = "The DC-17 repeater hand blaster, also known more simply as the DC-17 hand blaster or DC-17 blaster pistol, was a model of heavy blaster pistol and the Grand Army of the Republic's standard-issue sidearm. Produced by BlasTech Industries, the DC-17 was usually given to weapon teams, the crews of vehicles, and officers. The weapon was one of the most reliable and toughest models of blaster pistols created, as well as having remarkable stopping power in its small design. The weapon was also well balanced, possessed a respectable rate of fire, and lightweight."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000000"

SWEP.MirrorVMWM = false
SWEP.NoHideLeftHandInCustomization = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_dc17ext_akimbo.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_dc17ext.mdl"
SWEP.ViewModelFOV = 54

SWEP.HideViewmodel = false
SWEP.WorldModelOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.09
}

-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 31
SWEP.DamageMin = 19
SWEP.RangeMin = 0
SWEP.Range = 250
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 48

SWEP.Recoil = 1.13
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.67

SWEP.Delay = 60 / 190
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}

SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

-- Ammo, Sounds & MuzzleEffect

SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_DC17"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC17_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 250)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(0,0,0),
    Ang = Angle(0,0,0),
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

SWEP.SprintPos = Vector(0, -6, -5)
SWEP.SprintAng = Angle(35, 0, 0)

SWEP.CustomizePos = Vector(0, 0, 0)
SWEP.CustomizeAng = Angle(0, 0, 0)


SWEP.ActivePos = Vector(0, 0, -1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.HolsterPos = Vector(0, 0, 0)
SWEP.HolsterAng = Vector(-30, 0, 0)

SWEP.BarrelLength = 25

-- Attachments
SWEP.Attachments = {
    {
        PrintName = "Energization",
        Slot = {"ammo"}
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_pistol"},
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
        PrintName = "Internal Modifications",
        Slot = {"uc_fg"},
    }, 
}

-- ANIMATIONS
local path = "arccw/kraken/republic/dc17/handling/akimbo/"

SWEP.Akimbo = true

SWEP.Animations = {
    ["fire_left"] = {
        Source = "shoot1_left",
    },
    ["fire_right"] = {
        Source = "shoot1_right",
    },
    ["reload"] = {
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_DUEL,
        Source = "reload",
        SoundTable = {
		    {s = "weapons/csgo/movement1.wav", t = 0/30},
            {s = path .. "usp_clipout.wav", t = 5/30},
            {s = path .. "usp_clipout.wav", t = 8/30},
			{s = "weapons/csgo/movement2.wav", t = 19/30},
			{s = path .. "usp_clipin.wav", t = 45/30},
			{s = path .. "usp_clipin.wav", t = 55/30},
			{s = "weapons/csgo/movement3.wav", t = 65/30},
        },
    },
    ["reload_empty"] = {
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_DUEL,
        Source = "reload_empty",
        SoundTable = {
		    {s = "weapons/csgo/movement1.wav", t = 0/30},
            {s = path .. "usp_clipout.wav", t = 7/30},
            {s = path .. "usp_clipout.wav", t = 8/30},
			{s = "weapons/csgo/movement2.wav", t = 19/30},
            {s = path .. "usp_clipin.wav", t = 50/30},
            {s = path .. "usp_clipin.wav", t = 55/30},
			{s = "weapons/csgo/movement3.wav", t = 65/30},
            {s = path .. "usp_sliderelease.wav", t = 75/30},
            {s = path .. "usp_sliderelease.wav", t = 77/30},
        },
    },
    ["ready"] = {
        Source = "draw",
        SoundTable = {
            {s = path .. "usp_draw.wav", t = 0/30},
            {s = path .. "usp_sliderelease.wav", t = 11/30},
            {s = path .. "usp_sliderelease.wav", t = 14/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = "CSGO.Item.Movement", t = 0/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["exit_inspect"] = {
        Source = "lookat01",
        MinProgress = 0.9,
        FireASAP = true,
        SoundTable = {
            {s = "weapons/csgo/movement1.wav", t = 2/30},
            {s = "weapons/csgo/movement2.wav", t = 60/30},
			{s = "weapons/csgo/movement3.wav", t = 113/30},
        },
    },
}

function SWEP:DrawWorldModel()
    if IsValid(self:GetOwner()) then
        -- Held: don't draw (we do it via PostPlayerDraw, bone-merged)
        return
    end
    self:DrawModel()
end

if CLIENT then
    SWEP.HandWM = {
        RH = { -- Right Hand
            model = "models/arccw/kraken/republic/world/w_dc17ext.mdl",
            att   = "anim_attachment_RH",
            bone  = "ValveBiped.Bip01_R_Hand",
            pos   = Vector(8,  -1.5,  3),  
            ang   = Angle(0,   90,  -2), 
            scale = 0.9
        },
        LH = { -- Left Hand
            model = "models/arccw/kraken/republic/world/w_dc17ext.mdl",
            att   = "anim_attachment_LH",
            bone  = "ValveBiped.Bip01_L_Hand",
            pos   = Vector(7,  -0.4,  3),  
            ang   = Angle(0,   90,   2),
            scale = 0.9
        }
    }

    local function buildWM(wep, key)
        wep._wm = wep._wm or {}
        if IsValid(wep._wm[key]) then return end
        local cfg = wep.HandWM[key]; if not cfg then return end
        local m = ClientsideModel(cfg.model, RENDERGROUP_OPAQUE)
        if not IsValid(m) then return end
        m:SetNoDraw(true)

        -- Skin: use cfg.skin if set, otherwise try to copy from wep.WM
        if cfg.skin then
            m:SetSkin(cfg.skin)
        elseif IsValid(wep.WM) then
            m:SetSkin(wep.WM:GetSkin() or 0)
        end

        -- Bodygroups: use cfg.bodygroups if set, otherwise try to copy from wep.WM
        if cfg.bodygroups then
            if isstring(cfg.bodygroups) then
                -- String format: "000110011000" — each char is the value for that bodygroup index
                for i = 0, #cfg.bodygroups - 1 do
                    local val = tonumber(cfg.bodygroups[i + 1]) or 0
                    m:SetBodygroup(i, val)
                end
            elseif istable(cfg.bodygroups) then
                -- Table format: {[0] = 1, [2] = 3} — sparse bodygroup overrides
                for i, val in pairs(cfg.bodygroups) do
                    m:SetBodygroup(i, val)
                end
            end
        elseif IsValid(wep.WM) then
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

            ent:SetPos(pos)
            ent:SetAngles(ang)
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

    -- Safety cleanup
    function SWEP:OnRemove()  removeAllWM(self) end
    function SWEP:Holster()   removeAllWM(self) return true end
    function SWEP:OwnerChanged() removeAllWM(self) end
end
