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
ENT.PrintName = "B2 Superbattledroid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/npc/b2_battledroid/b2_battledroid.mdl"
ENT.Weapon = "weapon_npc_b2"
ENT.HP = 100
ENT.ShootingRange = 300
ENT.LooseRadius = 2000
ENT.Proficiency = 0
ENT.Speed = 60

ENT.Scale = 1.15

ENT.ThrowGrenades = false
ENT.Grenades = {"summe_gr_impact"}

ENT.Sounds = {
    ["hit"] = {
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_01.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_02.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_03.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_04.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_05.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_06.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_07.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_08.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_09.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_10.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_11.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_12.mp3",
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
    },
    ["attacking"] = {
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_01.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_02.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_03.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_04.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_05.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_06.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_07.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_08.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_09.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_010.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_011.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_012.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_013.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_014.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_015.mp3",
    },
}

ENT.Anims = {
    ["shoot"] = {"idle_alert_02", "d2_coast03_Odessa_Stand_RPG"},
    ["reload"] = {"pace_all"},
    ["walk_slow"] = {"walk_all"},
    ["walk_fast"] = {"walk_all"},
    ["melee"] = {"swing"},
}

function ENT:ShootEnemy()
    local weapon = self:GetWeapon()
    local enemy = self:GetEnemy()

    if not IsValid(weapon) then return end
    if hook.Run("SummeNextbot.CannotTarget", enemy, self) then self:SetEnemy(false) return end

    weapon.LastEnemy = enemy

    if weapon:Clip1() > 0 then
        if self.IsReloading then return end
        self:PlayAnimation("shoot")
        self:MakeSound(table.Random(self.Sounds["attacking"]), 80)

        if math.random(0, 100) > 98 then
            self:ShootMissle()
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

function ENT:ShootMissle()
    if IsValid(self.Missle) then return end
    local enemy = self:GetEnemy()
    if not enemy then return end

    self:EmitSound("summe/nextbots/weapons/simple_oneshot_juggernaut_rocketlauncher_close_var_01.mp3", 100, 100, 1, CHAN_WEAPON)

    local enemyPos = enemy:GetPos()
    local selfPos = self:GetPos() + Vector(0, 0, 40)
    local dir = (enemyPos - selfPos):GetNormalized()

    self.Missle = ents.Create("summe_b2missle")
    self.Missle:SetPos(self:EyePos())
    self.Missle:SetAngles(self:EyeAngles())
    self.Missle:SetOwner(self)
    self.Missle:Spawn()
end

if CLIENT then
    local colorRed = Color(150, 0, 0, 230)
    local colorGrey = Color(15, 15, 15, 230)
    local colorWhite = Color(255,255,255)

    function ENT:Draw()
        self:DrawModel()

        self:DrawNameTag(colorRed, 5)
    end
end