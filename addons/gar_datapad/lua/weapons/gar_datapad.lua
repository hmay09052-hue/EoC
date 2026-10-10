--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Waffe
    Auswaehlen im Inventar -> Datapad wird hochgenommen und der Bildschirm startet.
    Schliessen (X, ESC oder Rechtsklick) -> Datapad wird weggesteckt, die vorherige Waffe kommt zurueck.
    Modell: Easzy's Tablet F4 (Workshop 2526015939)
-------------------------------------------------------------------------------------------------------------]]

AddCSLuaFile()

SWEP.PrintName          = "Datapad"
SWEP.Author             = "GAR"
SWEP.Instructions       = "Auswaehlen zum Oeffnen. ESC, Rechtsklick oder X zum Schliessen."
SWEP.Category           = "GAR"

SWEP.Spawnable          = true
SWEP.AdminOnly          = true
SWEP.AutomaticFrameAdvance = true

SWEP.Slot               = (GAR_DP and GAR_DP.Config and GAR_DP.Config.WeaponSlot) or 1
SWEP.SlotPos            = 1

SWEP.ViewModel          = "models/easzy/ez_tablet_f4/v_tablet.mdl"
SWEP.WorldModel         = "models/easzy/ez_tablet_f4/w_tablet.mdl"
SWEP.UseHands           = true
SWEP.HoldType           = "slam"
SWEP.ViewModelFOV       = 50
SWEP.BobScale           = 0
SWEP.SwayScale          = 0

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = false
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false
SWEP.ShouldDropOnDie    = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

-- Ecken des Tablet-Bildschirms im Viewmodel (lokale Koordinaten)
SWEP.ScreenTopLeft      = Vector(15.65, 6.01, 3.97)
SWEP.ScreenBottomRight  = Vector(15.65, -6.02, -3.98)

if SERVER then
    util.AddNetworkString("gar_datapad_screen")     -- Server -> Client: Bildschirm an/aus
    util.AddNetworkString("gar_datapad_close")      -- Client -> Server: bitte schliessen
    util.AddNetworkString("gar_datapad_thirdperson")
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "ScreenOn")
    self:NetworkVar("Bool", 1, "Busy")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    if CLIENT then self:AttachToHand() end
end

-- Das Weltmodell sitzt an der rechten Hand (wie bei Easzy)
function SWEP:AttachToHand()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local bone = owner:LookupBone("ValveBiped.Bip01_R_Finger2")
    if bone then self:FollowBone(owner, bone) end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.6)
    if CLIENT then return end
    if not self:GetScreenOn() and not self:GetBusy() then self:OpenScreen() end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.6)
    if CLIENT then return end
    if self:GetScreenOn() then self:CloseScreen(true) end
end

function SWEP:Reload() end

if SERVER then
    local function TimerName(owner, kind) return "gar_datapad_" .. kind .. "_" .. owner:EntIndex() end

    function SWEP:PlayAnim(seqName, rate)
        local owner = self:GetOwner()
        local vm = IsValid(owner) and owner:GetViewModel()
        if not IsValid(vm) then return 0.5 end
        local seq = vm:LookupSequence(seqName)
        if not seq or seq < 0 then return 0.5 end
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(rate or 1)
        return vm:SequenceDuration(seq) / (rate or 1)
    end

    local function ThirdPerson(owner, restore)
        if not (GAR_DP and GAR_DP.Config and GAR_DP.Config.ThirdPersonFix) then return end
        net.Start("gar_datapad_thirdperson")
            net.WriteBool(restore)
        net.Send(owner)
    end

    function SWEP:Deploy()
        local owner = self:GetOwner()
        self:AttachToHand()
        if not IsValid(owner) then return true end
        self:SetScreenOn(false)
        self:SetBusy(false)
        -- direkt nach dem Spawn (Ausruestung wird verteilt) nicht automatisch oeffnen
        if (owner.gdp_spawnTime or 0) + 1.5 > CurTime() then return true end
        -- im selben Tick starten, sonst ist kurz die Ruhepose des Modells zu sehen
        self:OpenScreen()
        return true
    end

    function SWEP:OpenScreen()
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:Alive() or owner:InVehicle() then return end
        if self:GetBusy() or self:GetScreenOn() then return end
        ThirdPerson(owner, false)
        self:SetBusy(true)
        local t = self:PlayAnim("Taking", 1.5)
        timer.Create(TimerName(owner, "open"), t + 0.05, 1, function()
            if not IsValid(self) or not IsValid(owner) or owner:GetActiveWeapon() ~= self then return end
            self:SetBusy(false)
            self:SetScreenOn(true)
            net.Start("gar_datapad_screen")
                net.WriteBool(true)
            net.Send(owner)
        end)
    end

    -- switchBack: danach die vorherige Waffe nehmen
    function SWEP:CloseScreen(switchBack)
        local owner = self:GetOwner()
        if not IsValid(owner) or self:GetBusy() then return end
        timer.Remove(TimerName(owner, "open"))
        net.Start("gar_datapad_screen")
            net.WriteBool(false)
        net.Send(owner)
        self:SetScreenOn(false)
        self:SetBusy(true)
        local t = self:PlayAnim("Leaving", 2)
        timer.Create(TimerName(owner, "close"), t + 0.05, 1, function()
            if not IsValid(owner) then return end
            ThirdPerson(owner, true)
            if not IsValid(self) then return end
            self:SetBusy(false)
            if switchBack and owner:GetActiveWeapon() == self then
                local prev = owner.gdp_prevWeapon
                local class = (prev and IsValid(owner:GetWeapon(prev))) and prev or (GAR_DP and GAR_DP.Config.WeaponAfterClose or "keys")
                if IsValid(owner:GetWeapon(class)) then owner:SelectWeapon(class) end
            end
        end)
    end

    function SWEP:Holster()
        local owner = self:GetOwner()
        if IsValid(owner) then
            timer.Remove(TimerName(owner, "open"))
            timer.Remove(TimerName(owner, "close"))
            if self:GetScreenOn() or self:GetBusy() then
                net.Start("gar_datapad_screen")
                    net.WriteBool(false)
                net.Send(owner)
                ThirdPerson(owner, true)
            end
        end
        self:SetScreenOn(false)
        self:SetBusy(false)
        return true
    end

    function SWEP:OnRemove()
        local owner = self:GetOwner()
        if IsValid(owner) and owner:IsPlayer() and self:GetScreenOn() then
            net.Start("gar_datapad_screen")
                net.WriteBool(false)
            net.Send(owner)
        end
    end

    net.Receive("gar_datapad_close", function(_, ply)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "gar_datapad" and wep:GetScreenOn() then wep:CloseScreen(true) end
    end)
else
    -- Bildschirm-Ecken jedes Bild neu berechnen (Aufloesung, FOV)
    function SWEP:PostDrawViewModel(vm)
        local tl = vm:LocalToWorld(self.ScreenTopLeft):ToScreen()
        local br = vm:LocalToWorld(self.ScreenBottomRight):ToScreen()
        self.gdp_screen = { x = tl.x, y = tl.y, w = br.x - tl.x, h = br.y - tl.y, t = RealTime() }
    end

    function SWEP:DrawWorldModel()
        self:DrawModel()
    end

    net.Receive("gar_datapad_screen", function()
        local on = net.ReadBool()
        if not GAR_DP or not GAR_DP.OpenTablet then return end
        if on then GAR_DP.OpenTablet() else GAR_DP.CloseTablet(true) end
    end)

    local savedThirdPerson
    net.Receive("gar_datapad_thirdperson", function()
        local restore = net.ReadBool()
        if not ConVarExists("simple_thirdperson_enabled") then return end
        if restore then
            if savedThirdPerson == nil then return end
            RunConsoleCommand("simple_thirdperson_enabled", savedThirdPerson)
            savedThirdPerson = nil
        else
            savedThirdPerson = savedThirdPerson or GetConVar("simple_thirdperson_enabled"):GetString()
            RunConsoleCommand("simple_thirdperson_enabled", "0")
        end
    end)
end
