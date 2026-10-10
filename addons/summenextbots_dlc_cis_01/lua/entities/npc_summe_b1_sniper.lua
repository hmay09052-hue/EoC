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
ENT.PrintName = "B1 Sniperdroid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl"
ENT.Weapon = "weapon_npc_e5s"
ENT.HP = 10
ENT.ShootingRange = 1000
ENT.LooseRadius = 2000
ENT.Proficiency = .2

ENT.Melee = true
ENT.MeleeDamage = 25
ENT.MeleeDelay = 3

ENT.ThrowGrenades = false
ENT.Grenades = {"summe_gr_grenade"}

ENT.Sounds = {
    ["hit"] = {
        "summe/nextbots/droids/b1/clonewars/huh.mp3",
        "summe/nextbots/droids/b1/clonewars/no.mp3",
        "summe/nextbots/droids/b1/clonewars/oh-no.mp3",
        "summe/nextbots/droids/b1/clonewars/problem.mp3",
        "summe/nextbots/droids/b1/clonewars/uh-oh.mp3",
        "summe/nextbots/droids/b1/clonewars/ouch.mp3",
    },
    ["killed"] = {
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_01.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_02.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_03.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_04.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_05.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_06.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_07.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_08.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_09.mp3",
        "summe/nextbots/droids/b1/clonewars/scream.mp3",
    },
    ["attacking"] = {
        "summe/nextbots/droids/b1/clonewars/blast-em.mp3",
        "summe/nextbots/droids/b1/clonewars/charge.mp3",
        "summe/nextbots/droids/b1/clonewars/cut-chatter.mp3",
        "summe/nextbots/droids/b1/clonewars/hold-it.mp3",
        "summe/nextbots/droids/b1/clonewars/my-programming.mp3",
        "summe/nextbots/droids/b1/clonewars/prepare-fire.mp3",
        "summe/nextbots/droids/b1/clonewars/roger-roger.mp3",
        "summe/nextbots/droids/b1/clonewars/said-hold-it.mp3",
        "summe/nextbots/droids/b1/clonewars/surrender-jedi.mp3",
        "summe/nextbots/droids/b1/clonewars/what-was-that.mp3",
        "summe/nextbots/droids/b1/clonewars/youre-welcome.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_012.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_013.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_014.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_015.mp3",
    }
}

ENT.Anims = {
    ["shoot"] = {"crouch_shoot_smg1"},
    ["reload"] = {"reload_ar2", "reload_smg1", "reload_shotgun1", "crouch_reload_smg1"},
    ["walk_slow"] = {"walk_all", "walkAIMALL1", "walkHOLDALL1_ar2", "walk_holding_RPG_all"},
    ["walk_fast"] = {"run_protected_all", "run_all", "run_alert_holding_all", "run_alert_aiming_ar2_all", "crouchRUNAIMINGALL1"},
    ["melee"] = {"swing"},
}


local MaterialGlow = Material("sprites/light_glow02_add")
local ColorGlow = Color(255,255,255)

function ENT:Draw()
    self:DrawModel()
    self:DrawNameTag()

    local enemy = self:GetNWEntity("targetEnemy", false)
    if not enemy then return end

    if enemy != LocalPlayer() then return end

    local pos, ang = self:GetPos(), self:GetAngles()
    local drawpos = pos + ang:Forward() * 25 + ang:Right() * -4 + ang:Up() * 45

    render.SetMaterial(MaterialGlow)
    render.DrawSprite(drawpos, 75, 75, ColorGlow)
end

function ENT:ShootEnemy()
    local weapon = self:GetWeapon()
    local enemy = self:GetEnemy()
    local self_ = self

    if not IsValid(weapon) then return end
    if hook.Run("SummeNextbot.CannotTarget", enemy, self) then self:SetEnemy(false) return end

    if self.DisableShooting then return end

    weapon.LastEnemy = enemy

    local tr = util.TraceLine({
        start = weapon:GetPos() + Vector(0, 0, 50),
        endpos = enemy:HeadTarget(enemy:GetPos()) - Vector(0, 0, 10),
        filter = {weapon, self},
    })

    if tr.Entity != enemy then return end

    if weapon:Clip1() > 0 then
        if self.IsReloading then return end
        self:PlayAnimation("shoot")
        weapon:PrimaryAttack()
        if self.Sounds then
            self:MakeSound(table.Random(self.Sounds["attacking"] or {}), 95)
        end
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

function ENT:OnNPCSpawn()
    self:SetMaterial("phoenix_storms/wire/pcb_red")
    self:SetColor(Color(133,216,0))
end