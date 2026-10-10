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
ENT.PrintName = "Aqua Battledroid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/player/valley/aquadroid/aquadroid.mdl"
ENT.Weapon = "weapon_npc_aqua"
ENT.HP = 100
ENT.ShootingRange = 1000
ENT.LooseRadius = 2000
ENT.Proficiency = .2

ENT.Melee = false
ENT.MeleeDamage = 25
ENT.MeleeDelay = 3

ENT.ThrowGrenades = false
ENT.Grenades = {"summe_gr_grenade"}

ENT.Scale = 1.15

ENT.Sounds = false

ENT.Anims = {
    ["shoot"] = {"idlepackage"},
    ["reload"] = {"takepackage"},
    ["walk_slow"] = {"walk_holding_package_all", "walk_all_Moderate"},
    ["walk_fast"] = {"run_all"},
}

if SERVER then

    ENT.AllowShooting = true

    function ENT:ShootEnemy()

        if not self.AllowShooting then return end

        local weapon = self:GetWeapon()
        local enemy = self:GetEnemy()
    
        if not IsValid(weapon) then return end
        if hook.Run("SummeNextbot.CannotTarget", enemy, self) then self:SetEnemy(false) return end
    
        weapon.LastEnemy = enemy
    
        if weapon:Clip1() > 0 then
            if self.IsReloading then return end
            self:PlayAnimation("shoot")
    
            if math.random(0, 100) > 98 then
                self:SpecialAbility()
                return
            end

            weapon:PrimaryAttack()

        else
            if self.IsReloading then return end
            self.IsReloading = true
            self:MakeSound("weapons/bf3/standard_reload2.ogg", 0)
            self:PlayAnimation("reload")
            timer.Simple(3, function()
                if not IsValid(weapon) then return end
                weapon:SetClip1(self.NormalWeaponClip)
                self.IsReloading = false
            end)
        end
    end

    util.AddNetworkString("SummeNextbots.Auqa.SpecialAbility")

    function ENT:SpecialAbility()
        self.AllowShooting = false

        self:EmitSound("summe/nextbots/weapons/aqua/blasters_relby-v10_bossk_charge_var_02.mp3", 100, 100, 1, CHAN_WEAPON)

        timer.Simple(1, function()
            if not IsValid(self) then return end

            local ents_ = player.FindInSphere(self:EyePos(), self.ShootingRange)
            local weapon = self:GetWeapon()
            local entsCount = 0

            for k, v in RandomPairs(ents_) do
                local tr = util.TraceLine({
                    start = self:GetPos() + Vector(0, 0, 170),
                    endpos = v:HeadTarget(v:GetPos()) - Vector(0, 0, 10),
                    filter = {weapon, self},
                })
            
                if tr.Entity != v then
                    ents_[k] = nil
                    continue 
                end

                if hook.Run("SummeNextbot.CannotTarget", v, self) then
                    ents_[k] = nil
                    continue 
                end

                if entsCount > 5 then
                    ents_[k] = nil
                    continue
                end

                entsCount = entsCount + 1

                v:ScreenFade(SCREENFADE.IN, color_white, 1, 2)

                self:EmitSound("summe/nextbots/weapons/aqua/blaster_iondisruptor_laser_addon_close_var_0".. math.random(4, 8).. ".mp3", 100, 100, 1, CHAN_WEAPON)
            end

            timer.Create("SummeNextbots.Auqa.SpecialAbDmg", 0.1, 10, function()
                for k, v in pairs(ents_) do
                    if not IsValid(v) or not v:Alive() then continue end
                    if not IsValid(self) then return end

                    local d = DamageInfo()
                    d:SetDamage(13)
                    d:SetAttacker(self)
                    d:SetDamageType(DMG_SHOCK) 

                    v:TakeDamageInfo(d)
                end
            end)

            net.Start("SummeNextbots.Auqa.SpecialAbility")
            net.WriteEntity(self)
            net.WriteTable(ents_)
            net.Broadcast()

            timer.Simple(3, function()
                self:EmitSound("summe/nextbots/weapons/aqua/blasters_deathray_charge_start_var_01.mp3", 100, 100, 1, CHAN_WEAPON)
                self.AllowShooting = true
            end)
        end)
    end
end

if CLIENT then
    local colorRed = Color(150, 0, 0, 230)
    local colorGrey = Color(15, 15, 15, 230)
    local colorWhite = Color(255,255,255)
    local Laser = Material("cable/physbeam")
    local LaserSmall = Material("cable/blue_elec")
    local MaterialGlow = Material("sprites/light_glow02_add")
    local MaterialGlow2 = Material("sprites/blueflare1_noz_gmod")
    local ColorGlow = Color(0,217,255)
    local ColorGlow2 = Color(0,119,2555)

    net.Receive("SummeNextbots.Auqa.SpecialAbility", function(len)
        local nextbot = net.ReadEntity()
        local players = net.ReadTable()

        nextbot.targets = players
        nextbot.specialthing = true

        timer.Simple(1, function()
            if not IsValid(nextbot) then return end

            nextbot.specialthing = false
        end)
    end)

    function ENT:Draw()
        self:DrawModel()

        self:DrawNameTag(colorRed, 5)

        if self.specialthing then

            local pos = self:GetPos() + Vector(0, 0, 170)

            local Vector1 = self:LocalToWorld( Vector( 0, 0, 50 ) )
            local Vector2 = self:LocalToWorld( Vector( 0, 0, 165 ) ) 
            render.SetMaterial( Laser )
            render.DrawBeam( Vector1, Vector2, 40, 1, 2, Color( 255, 255, 255, 255 ) ) 

            render.SetMaterial(MaterialGlow)
            render.DrawSprite(Vector2, 200, 200, ColorGlow)

            render.SetMaterial(MaterialGlow2)
            render.DrawSprite(Vector2, 20, 20, ColorGlow2)

            for k, v in pairs(self.targets) do
                if not IsValid(v) or not v:Alive() then continue end

                local randVec = v:GetPos() + Vector(0, 0, math.random(0, 80))

                render.SetMaterial(LaserSmall)
                render.DrawBeam(pos, randVec, 10, 1, 5, color_white)

                render.SetMaterial(MaterialGlow)
                render.DrawSprite(randVec, 50, 50, ColorGlow)
            end
        end
    end
end