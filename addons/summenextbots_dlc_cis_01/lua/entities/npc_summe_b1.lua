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
ENT.PrintName = "B1 Battledroid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl"
ENT.Weapon = "weapon_npc_e5"
ENT.HP = 50
ENT.ShootingRange = 5000
ENT.LooseRadius = 2000
ENT.Proficiency = .2

ENT.Melee = true
ENT.MeleeDamage = 15
ENT.MeleeDelay = 3

ENT.ThrowGrenades = true
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
    ["shoot"] = {"shoot_shotgun", "shootp1", "layer_walk_aiming", "crouch_shoot_smg1"},
    ["reload"] = {"reload_ar2", "reload_smg1", "reload_shotgun1", "crouch_reload_smg1"},
    ["walk_slow"] = {"walk_all", "walkAIMALL1", "walkHOLDALL1_ar2", "walk_holding_RPG_all"},
    ["walk_fast"] = {"run_protected_all", "run_all", "run_alert_holding_all", "run_alert_aiming_ar2_all", "crouchRUNAIMINGALL1"},
    ["melee"] = {"swing"},
}