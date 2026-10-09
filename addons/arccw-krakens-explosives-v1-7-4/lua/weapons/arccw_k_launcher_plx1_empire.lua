AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Explosives - Rocket Launchers"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Empire PLX-1"
SWEP.Trivia_Class = "Rocket Launcher"
SWEP.Trivia_Desc = "The Merr-Sonn PLX, or Plex, was a powerful missile launcher that was in service almost from the beginning of the Clone Wars and continued to be used in different militaries well after the conclusion of that cataclysmic conflict."
SWEP.Trivia_Manufacturer = "Merr-Sonn Munitions, Inc."
SWEP.Trivia_Calibre = "Rocket"
SWEP.Trivia_Country = "Galactic Republic"

SWEP.DefaultBodygroups = "0010000000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.NoHideLeftHandInCustomization = false
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_plx1_empire.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_plx1_empire.mdl"

SWEP.ViewModelFOV = 65

SWEP.WorldModelOffset = {
    pos = Vector(-3, 1.3, -6),
    ang = Angle(0, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
}

SWEP.HasHoloHUD = true
SWEP.HoloHUD_Red = true
SWEP.HasLockOn = true
SWEP.LockOnType = "javelin"

SWEP.ShootEntity = "arccw_rocket_plx1"
SWEP.MuzzleVelocity = 12000

SWEP.Recoil = 4
SWEP.RecoilSide = 4
SWEP.RecoilRise = 4
SWEP.RecoilPunch = 5
SWEP.RecoilVMShake = 4
SWEP.VisualRecoilMult = 4

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 1

SWEP.Delay = 60 / 180
SWEP.Num = 1
SWEP.Firemodes = {
    {
        Mode = -1,
        PrintName = "TOP",
        TopAttack = true
    },
    {
        Mode = -1,
        PrintName = "TOP",
        TopAttack = false
    },
}

SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 300
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 500

SWEP.SpeedMult = 0.65
SWEP.SightedSpeedMult = 0.64
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.62

SWEP.Primary.Ammo = "RPG_Round"
SWEP.ShootVol = 120
SWEP.ShootPitch = 95
SWEP.ShootPitchVariation = 0.2

SWEP.FirstShootSound = "kraken/explosives/heat_ignite.ogg"
SWEP.ShootSound = "kraken/explosives/heat_ignite.ogg"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "muzzleflash_m79"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 192, 0)

SWEP.IronSightStruct = {
    Pos = Vector(0, -40, 0),
    Ang = Angle(0, 0, 0),
    Magnification = 8,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "rpg"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(3, -2, 4)
SWEP.ActiveAng = Angle(8, 0, 19)

SWEP.SprintPos = Vector(0, 3, -0)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(6, 4, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.Attachments = {
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "tag_launcher_offset",
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(14, -4.5, -1),
            vang = Angle(0, 0, 90),
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
        Slot = {"charm"},
        Bone = "tag_launcher_offset",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(5, -4.5, -1),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

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

-- Hook_DrawHUD removed: replaced by centralized HoloHUD (cl_kraken_holohud.lua)

SWEP.NextBeepTime = 0
SWEP.TargetEntity = nil
SWEP.StartTrackTime = 0
SWEP.LockTime = 2

function SWEP:Think()
    self.BaseClass.Think(self)
    
    if !IsValid(self:GetOwner()) then return end

    if self:Clip1() > 0 and self:GetNWState() == ArcCW.STATE_SIGHTS then

        if self.NextBeepTime > CurTime() then return end

        local tracktime = math.Clamp((CurTime() - self.StartTrackTime) / self.LockTime, 0, 2)

        if tracktime >= 1 and self.TargetEntity then
            if CLIENT then
                self:EmitSound("kraken/explosives/reticle_locked2.ogg", 75, 100)
            end
            self.NextBeepTime = CurTime() + 0.15
        elseif tracktime >= 0 and self.TargetEntity then
            if CLIENT then
                self:EmitSound("kraken/explosives/reticle_tracking2.ogg", 75, 100)
            end
            self.NextBeepTime = CurTime() + 0.4
        else
            if CLIENT then
                self:EmitSound("", 75, 100)
            end
            self.NextBeepTime = CurTime() + 0.4
        end
        local Radius = 14000
        local closest = Radius 

        local targets = ents.FindInSphere(self:GetOwner():GetPos(), Radius)

        local best = nil
        local targetscore = 0

        for _, ent in ipairs(targets) do
            if ent:IsWorld() then continue end
            if ent == self:GetOwner() then continue end
            if ent.IsProjectile then continue end
            if ent.UnTrackable then continue end
            if ent:GetClass():find("prop_") then continue end
			
            local aa, bb = ent:GetRotatedAABB(ent:OBBMins(), ent:OBBMaxs())
            local vol = math.abs(bb.x - aa.x) * math.abs(bb.y - aa.y) * math.abs(bb.z - aa.z)
			if vol <= 20000 then continue end

            local dot = (ent:GetPos() - self:GetOwner():GetShootPos()):GetNormalized():Dot(self:GetOwner():GetAimVector())
            local entscore = 1
            if ent:IsPlayer() then entscore = entscore + 5 end
            if ent:IsNPC() or ent:IsNextBot() then entscore = entscore + 2 end
            if ent:IsVehicle() or ent.LVS then entscore = entscore + 10 end
            if ent:Health() > 0 then entscore = entscore + 5 end

            entscore = entscore + dot * 5

            if entscore > targetscore then
                local tr = util.TraceLine({
                    start = self:GetOwner():GetShootPos(),
                    endpos = ent:WorldSpaceCenter(),
                    filter = self:GetOwner(),
                    mask = MASK_SHOT
                })
                if tr.Entity == ent then
                best = ent
                bestang = dot
                targetscore = entscore
                end
            end
        end

        if !best then self.TargetEntity = nil return end

        if !self.TargetEntity then
            self.StartTrackTime = CurTime()
        end

        self.TargetEntity = best
    else
        self.TargetEntity = nil
    end
end

local path = "kraken/launchers/plx1/"

SWEP.Animations = {
	["enter_sights"] = {
		Source = "idle",
	},
    ["fire"] = {
        Source = "shoot1",
    },
    ["dryfire"] = {
        Source = "firemode",
		MinProgress = 0.01,
		FireASAP = true,
    },
    ["reload"] = {
        Source = "reload",
		MinProgress = 0.95,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
			{s = path .. "wfoly_plr_la_gromeo_reload_start.ogg", t = 0/30},
			{s = path .. "wfoly_plr_la_gromeo_reload_rotate.ogg", t = 22/30},
			{s = path .. "wfoly_plr_la_gromeo_reload_rockettip_01.ogg", t = 38/30},
			{s = path .. "wfoly_plr_la_gromeo_reload_grabrocket.ogg", t = 78/30},
			{s = path .. "wfoly_plr_la_gromeo_reload_load_01.ogg", t = 82/30},
			{s = path .. "wfoly_plr_la_gromeo_reload_flipup.ogg", t = 102/30},
			{s = path .. "wfoly_plr_la_gromeo_reload_arm.ogg", t = 128/30},
			{s = path .. "wfoly_plr_la_gromeo_reload_end.ogg", t = 152/30},
        },
    },
    ["ready"] = {
        Source = "draw",
        SoundTable = {
            {s = path .. "wfoly_plr_la_gromeo_raise_first_up.ogg", t = 3/30},
			{s = path .. "wfoly_plr_la_gromeo_raise_first_settle.ogg", t = 18/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
		MinProgress = 0.4,
        SoundTable = {
            {s = path .. "wfoly_plr_la_gromeo_raise_up.ogg", t = 7/30},
			{s = path .. "wfoly_plr_la_gromeo_raise_settle.ogg", t = 22/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = path .. "wfoly_plr_la_gromeo_drop.ogg", t = 0/30},
            {s = path .. "wfoly_plr_la_gromeo_drop_mech.ogg", t = 5/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["bash"] = {
        Source = "melee_miss",
    },
}
