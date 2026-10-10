AddCSLuaFile()

SWEP.PrintName      = 'Tarnnetz'
SWEP.Author         = 'Echoes of Clones'
SWEP.Instructions   = 'Linksklick: Tarnmuster wählen und aktivieren\nRechtsklick: Tarnnetz deaktivieren'
SWEP.Category       = 'EoC | Ausrüstung'

SWEP.Spawnable      = true
SWEP.AdminOnly      = false

SWEP.Slot           = 1
SWEP.SlotPos        = 5
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = false

SWEP.ViewModel      = 'models/weapons/c_arms.mdl'
SWEP.WorldModel     = ''
SWEP.UseHands       = true

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = 'none'

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = 'none'

function SWEP:Initialize()
    self:SetHoldType('normal')
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then return end

    Tarnnetz.OpenMenu(self:GetOwner())
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)
    if CLIENT then return end

    local ply = self:GetOwner()
    if not Tarnnetz.IsActive(ply) then
        Tarnnetz.Notify(ply, Tarnnetz.Config.Lang.notActive, 0)
        return
    end

    Tarnnetz.Deactivate(ply, 'manual')
end

function SWEP:Reload() end

function SWEP:DrawWorldModel() end

function SWEP:ShouldDrawViewModel()
    return false
end
