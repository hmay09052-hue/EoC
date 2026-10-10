--[[
   _____ _    _ __  __ __  __ ______                   
  / ____| |  | |  \/  |  \/  |  ____|                  
 | (___ | |  | | \  / | \  / | |__                     
  \___ \| |  | | |\/| | |\/| |  __|                    
  ____) | |__| | |  | | |  | | |____                   
 |_____/_\____/|_| _|_|_|__|_|______|___ _______ _____ 
 | \ | |  ____\ \ / /__   __|  _ \ / __ \__   __/ ____|
 |  \| | |__   \ V /   | |  | |_) | |  | | | | | (___  
 | . ` |  __|   > <    | |  |  _ <| |  | | | |  \___ \ 
 | |\  | |____ / . \   | |  | |_) | |__| | | |  ____) |
 |_| \_|______/_/ \_\  |_|  |____/ \____/  |_| |_____/ 
                                                       
    Created by Summe: https://steamcommunity.com/id/DerSumme/ 
    Purchased content: https://discord.gg/k6YdMwj9w2
]]--

AddCSLuaFile()
ENT.Base = "summe_nextbot"
ENT.PrintName = "Droideka"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

ENT.Model = "models/npc/starwars/droidekas/droideka.mdl"
ENT.Weapon = "weapon_npc_droideka"
ENT.HP = 300
ENT.ShootingRange = 400
ENT.LooseRadius = 1500
ENT.Proficiency = 0

ENT.Speed = 200

ENT.ThrowGrenades = false
ENT.Grenades = {"summe_gr_impact"}

ENT.Sounds = false

ENT.Anims = {
    ["shoot"] = {"range_attack1"},
    ["reload"] = {"idle"},
    ["walk_slow"] = {"walk"},
    ["walk_fast"] = {"walk"},
}

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "ShieldStatus", { KeyName = "ShieldStatus", Edit = { type = "Boolean", order = 1, category = "Settings"}})
end

function ENT:SwitchShield(value)
    if value then
        self:SetShieldStatus(true)
        self:StopSound("summe/nextbots/droids/droideka/droids_droideka_roll_main_loop_01.mp3")
        --self:SetSequence(0)
    else
        self:SetShieldStatus(false)
    end
end

function ENT:SetWeapon(weaponClass)
    local currentWeapon = self:GetWeapon()

    if currentWeapon then
        currentWeapon:Remove()
    end

    local newWep = ents.Create(weaponClass)
    newWep:Spawn()
    newWep:Activate()
    newWep:SetPos(self:GetPos() + Vector(0, 0, 20))
    newWep:SetSolid(SOLID_NONE)
    newWep:SetParent(self)
    newWep:AddEffects(EF_BONEMERGE)
    newWep:SetOwner(self)

    self.NormalWeaponClip = newWep:Clip1()

    self:SetNWEntity("weapon", newWep)

    function newWep:CanPrimaryFire()
        return true
    end
end

function ENT:DoNormal()
    if self.Path:GetAge() < 5 then return end
    if self:GetShieldStatus() then return end
    self:SwitchShield(true)
end

function ENT:ShootEnemy()
    local weapon = self:GetWeapon()
    local enemy = self:GetEnemy()

    if not IsValid(weapon) then return end
    if hook.Run("SummeNextbot.CannotTarget", enemy, self) then self:SetEnemy(false) return end

    weapon.LastEnemy = enemy

    if weapon:Clip1() > 0 then
        if self.IsReloading then return end
        self:PlayAnimation("shoot")
        weapon:PrimaryAttack()
        self:SwitchShield(true)
    else
        if self.IsReloading then return end
        self.IsReloading = true
        --self:PlayAnimation("reload")
        timer.Simple(3, function()
            if not IsValid(weapon) then return end
            weapon:SetClip1(self.NormalWeaponClip)
            self.IsReloading = false
        end)
    end
end

function ENT:RunTo(pos, speed)

    if self.Path:GetAge() < 1 then return end

    self:StopSound("summe/nextbots/droids/droideka/droids_droideka_roll_main_loop_01.mp3")
    self:EmitSound("summe/nextbots/droids/droideka/droids_droideka_roll_main_loop_01.mp3", 120, 100, 1, CHAN_AUTO)

    self:SwitchShield(false)
    if speed and speed < 300 then
        self:PlayAnimation("walk_slow", true)
        --self:SetActivity(ACT_RUN)
    else
        self:PlayAnimation("walk_fast", true)
        --self:SetActivity(ACT_WALK)
    end
    self.loco:SetDesiredSpeed(speed or 200)
    self:PathFollowerCompute(pos)
end

function ENT:OnTakeDamage(dmgInfo)
    if self:GetShieldStatus() then
        if dmgInfo:GetDamageType() == DMG_BLAST then
            dmgInfo:ScaleDamage(1.3)
        end
        dmgInfo:ScaleDamage(.3)
    else
        dmgInfo:ScaleDamage(1)
    end

    if self:Health() < 1 then
        self:Remove()
    end
end

function ENT:OnRemove()
    if SERVER then
        self.Explo = ents.Create( "env_explosion" )
        self.Explo:SetKeyValue( "spawnflags", 144 )
        self.Explo:SetKeyValue( "iMagnitude", 15 )
        self.Explo:SetKeyValue( "iRadiusOverride", 256 )
        self.Explo:SetPos( self:GetPos() )
        self.Explo:Spawn()
        self.Explo:Fire( "explode", "", 0 )
    end
    self:StopSound("summe/nextbots/droids/droideka/droids_droideka_roll_main_loop_01.mp3")
end

if CLIENT then

    local colorRed = Color(150, 0, 0, 230)
    local colorGrey = Color(15, 15, 15, 230)
    local colorWhite = Color(255,255,255)

    local shieldMat = Material("Models/effects/splodearc_sheet")
    
    function ENT:Draw()
        self:DrawModel()

        self:DrawNameTag(colorRed, 5)

        if not self:GetShieldStatus() then return end
        render.SetColorMaterial()
        local pos = self:GetPos() + Vector(0, 0, 30)
        render.DrawSphere(pos, 50, 30, 30, Color( 0, 175, 175, self:Health() * .1))
        render.SetMaterial(shieldMat)
        render.DrawSphere(pos, 49, 30, 30, Color( 83, 255, 255, self:Health() * .1))
    end

end