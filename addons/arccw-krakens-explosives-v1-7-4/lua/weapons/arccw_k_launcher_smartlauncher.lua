AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Explosives - Rocket Launchers"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Smart Launcher"
SWEP.Trivia_Class = "Rocket Launcher"
SWEP.Trivia_Desc = "The Smart Rocket was a powerful rocket/missile hybrid used by both the Galactic Empire and Rebel Alliance during the Galactic Civil War, and later by the Resistance and First Order in their conflict decades later. The Smart Rocket was also used by the Galactic Republic prior to the formation of the Empire."
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Rocket"
SWEP.Trivia_Mechanism = "Kabum"
SWEP.Trivia_Country = " Universal"

SWEP.DefaultBodygroups = "0100000000000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_smartlauncher.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_smartlauncher.mdl"

SWEP.ViewModelFOV = 60

SWEP.WorldModelOffset = {
    pos = Vector(-4.5, 1.3, -5),
    ang = Angle(0, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
}

SWEP.HasHoloHUD = true
SWEP.HasLockOn = true
SWEP.LockOnType = "stinger"

SWEP.ShootEntity = "arccw_rocket_smartrocket"
SWEP.MuzzleVelocity = 10000

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 1

SWEP.Recoil = 4
SWEP.RecoilSide = 4
SWEP.RecoilRise = 4
SWEP.RecoilPunch = 5
SWEP.RecoilVMShake = 4
SWEP.VisualRecoilMult = 4

SWEP.Delay = 60 / 60
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
}

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 300
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 500

SWEP.SpeedMult = 0.925
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

SWEP.Primary.Ammo = "RPG_Round"
SWEP.ShootVol = 120
SWEP.ShootPitch = 95
SWEP.ShootPitchVariation = 0.2

SWEP.FirstShootSound = "kraken/launchers/smartlauncher/bazooka_fp.wav"
SWEP.ShootSound = "kraken/launchers/smartlauncher/bazooka_fp.wav"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "muzzleflash_m79"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 142, 0)

SWEP.IronSightStruct = {
    Pos = Vector(0, -40, 0),
    Ang = Vector(0, 0, 0),
     Magnification = 8,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "rpg"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, -4, 0)
SWEP.ActiveAng = Angle(5, 0, -5)

SWEP.SprintPos = Vector(4.019, -5.226, -2)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CrouchPos = Vector(-4.5, -7, -3)
SWEP.CrouchAng = Angle(0, 0, -29)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.Attachments = {
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "Weapon",
        Offset = {
            vpos = Vector(1.33, 18, 2.8),
            vang = Angle(90, -90, 0),
        },
    }, 
    {
        PrintName = "Ammunition",
        DefaultAttName = "Rocket",
        Slot = {"k_rocket_ammo"}
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = "charm",
        VMScale = Vector(0.5, 0.5, 0.5),
        WMScale = Vector(0.5, 0.5, 0.5),
        Bone = "Weapon",
        Offset = {
            vpos = Vector(1.67, 11.8, 2.54),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Stinger lock-on: air targets only
local COS_10DEG = math.cos(math.rad(10))
local SCAN_INTERVAL = 0.08
local SCAN_DISTANCE = 12000
local MAX_VIS_CHECKS = 10

local AIR_PATTERNS = {"air","fly","helicopter","starfighter","gunship","dropship","xwing","ywings","vwing","laat","arc170","bomber","hover","aircraft","shuttle","interceptor","fighter"}
local GROUND_OVERRIDES = {"walker","ground","fakehover","tank"}
local AIR_NPC_CLASSES = {
    ["npc_helicopter"] = true,
    ["npc_combinegunship"] = true,
    ["npc_combinedropship"] = true,
    ["npc_crow"] = true,
    ["npc_pigeon"] = true,
    ["npc_seagull"] = true,
    ["combine_mine"] = true,
    ["npc_manhack"] = true,
    ["npc_clawscanner"] = true,
    ["npc_cscanner"] = true,
}

local function strfind_any(s, pats)
    for i = 1, #pats do
        if s:find(pats[i], 1, true) then return true end
    end
    return false
end

local function isAirVehicle(ent)
    if not (ent:IsVehicle() or ent.LFS or ent.LVS) then return false end
    local vehType = ""
    if ent.GetVehicleType then
        local ok, vt = pcall(ent.GetVehicleType, ent)
        if ok and vt then vehType = string.lower(vt) end
    end
    local model = string.lower(ent:GetModel() or "")
    local class = string.lower(ent:GetClass() or "")
    local combined = vehType .. " " .. model .. " " .. class
    if strfind_any(vehType, GROUND_OVERRIDES) or class:find("walker", 1, true) then return false end
    return strfind_any(combined, AIR_PATTERNS)
end

local function isAirNPC(ent)
    if not ent:IsNPC() then return false end
    local class = ent:GetClass()
    if AIR_NPC_CLASSES[class] then return true end
    return strfind_any(string.lower(ent:GetModel() or ""), AIR_PATTERNS)
end

local function isValidStingerTarget(ent)
    if ent.IsAirAsset then return true end
    if isAirVehicle(ent) then return true end
    if isAirNPC(ent) then return true end
    return false
end

SWEP.NextBeepTime = 0
SWEP.TargetEntity = nil
SWEP.StartTrackTime = 0
SWEP.LockTime = 1.0

SWEP.Hook_PostFireRocket = function(self, rocket)
    if IsValid(rocket) then
        rocket.Weapon = self
        local tracktime = math.Clamp((CurTime() - self.StartTrackTime) / self.LockTime, 0, 1)
        if tracktime >= 1 and self.TargetEntity and IsValid(self.TargetEntity) then
            rocket.ShootEntData = rocket.ShootEntData or {}
            rocket.ShootEntData.Target = self.TargetEntity
        end
    end
end

function SWEP:Think()
    self.BaseClass.Think(self)

    if not IsValid(self:GetOwner()) then return end
    if self:Clip1() <= 0 or self:GetNWState() ~= ArcCW.STATE_SIGHTS then
        self.TargetEntity = nil
        self.StartTrackTime = 0
        return
    end

    if (self.NextBeepTime or 0) > CurTime() then return end

    local tracktime = 0
    if self.StartTrackTime and self.StartTrackTime > 0 then
        tracktime = math.Clamp((CurTime() - self.StartTrackTime) / self.LockTime, 0, 2)
    end

    if tracktime >= 1 and self.TargetEntity then
        if CLIENT then
            self:EmitSound("kraken/explosives/reticle_locked2.ogg", 75, 100)
        end
        self.NextBeepTime = CurTime() + 0.15
    elseif tracktime > 0 and self.TargetEntity then
        if CLIENT then
            self:EmitSound("kraken/explosives/reticle_tracking2.ogg", 75, 100)
        end
        self.NextBeepTime = CurTime() + 0.4
    else
        self.NextBeepTime = CurTime() + 0.4
    end

    local owner = self:GetOwner()
    local shootPos = owner:GetShootPos()
    local forward = owner:GetAimVector()
    local candidates = ents.FindInCone(shootPos, forward, SCAN_DISTANCE, COS_10DEG)

    local best, bestScore = nil, -math.huge
    local visChecks = 0

    for i = 1, #candidates do
        local ent = candidates[i]
        if not IsValid(ent) then goto CONTINUE end
        if ent:IsWorld() or ent == owner or ent.IsProjectile or ent.UnTrackable then goto CONTINUE end
        local class = ent:GetClass()
        if class and class:find("prop_", 1, true) then goto CONTINUE end
        if not isValidStingerTarget(ent) then goto CONTINUE end
        if visChecks >= MAX_VIS_CHECKS then goto CONTINUE end

        local to = (ent:WorldSpaceCenter() - shootPos)
        local dot = to:GetNormalized():Dot(forward)
        if dot < 0.3 then goto CONTINUE end

        local tr = util.TraceLine({
            start = shootPos,
            endpos = ent:WorldSpaceCenter(),
            filter = owner,
            mask = MASK_SHOT
        })
        visChecks = visChecks + 1
        if tr.Entity ~= ent then goto CONTINUE end

        local score = 1
        if ent.IsAirAsset then score = score + 100 end
        if isAirVehicle(ent) then score = score + 50 end
        if isAirNPC(ent) then score = score + 30 end
        if ent:IsVehicle() or ent.LVS or ent.LFS then score = score + 20 end
        score = score + dot * 10

        if score > bestScore then
            best, bestScore = ent, score
        end
        ::CONTINUE::
    end

    if best and IsValid(best) then
        if self.TargetEntity ~= best then
            self.TargetEntity = best
            self.StartTrackTime = CurTime()
        end
    else
        self.TargetEntity = nil
        self.StartTrackTime = 0
    end
end

local path = "kraken/launchers/smartlauncher/bazooka_"

SWEP.Animations = {
    ["idle"] = { Source = "base_idle" },
    ["idle_iron"] = { Source = false, },
    ["fire"] = { Source = "base_fire" },
    ["fire_iron"] = { Source =  false, },
    ["enter_sights"] = { Source = false, },
    ["dryfire"] = { Source = "base_dryfire" },
    ["dryfire_iron"] = { Source = "iron_dryfire" },
    ["reload"] = { Source = "base_reload", TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, MinProgress = 0.75, MagSwapTime = 0.75, Mult = 0.9,  
    SoundTable = {
        {t = 50 / 32.5, s = path .. "fetch.wav"},
        {t = 78 / 32.5, s = path .. "load1.wav"},
        {t = 87 / 32.5, s = path .. "load2.wav"},
        {t = 114 / 32.5, s = path .. "wire.wav"},
        {t = 160 / 32.5, s = path .. "reshoulder.wav"},
        {t = 199 / 32.5, s = path .. "shoulder.wav"},
    } },
    ["ready"] = { Source = "base_ready", MinProgress = 1, FireASAP = true, 
    SoundTable = {
        {t = 0 / 30, s = path .. "fetch.wav" },
        {t = 47 / 30, s = path .. "fetch.wav"},
        {t = 75 / 30, s = path .. "load1.wav"},
        {t = 84 / 30, s = path .. "load2.wav"},
        {t = 112 / 30, s = path .. "wire.wav"},
        {t = 160 / 30, s = path .. "reshoulder.wav"},
        {t = 196 / 30, s = path .. "shoulder.wav"},
    } },
    ["draw"] = { Source = "base_draw", 
    SoundTable = {
        {t = 50 / 32.5, s = path .. "fetch.wav"},
    } },
    ["holster"] = { Source = "base_holster", 
    SoundTable = {
        {t = 50 / 32.5, s = path .. "fetch.wav"},
    } },
}
