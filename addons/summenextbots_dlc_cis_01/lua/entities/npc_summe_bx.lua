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
ENT.PrintName = "BX Commandodroid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/npc/bx100_commando_droid/regular/bx100_commando_droid_regular.mdl"
ENT.Weapon = "weapon_npc_e5bx"
ENT.HP = 150
ENT.ShootingRange = 1000
ENT.LooseRadius = 2000
ENT.Proficiency = .05

ENT.Melee = true
ENT.MeleeDamage = 15
ENT.MeleeDelay = 3

ENT.ThrowGrenades = true
ENT.Grenades = {"summe_gr_impact"}

ENT.Sounds = false

ENT.Anims = {
    ["shoot"] = {"shoot_smg1"},
    ["reload"] = {"reload_shotgun1"},
    ["walk_slow"] = {"walk_aiming_SMG1_all", "walk_hold_smg1"},
    ["walk_fast"] = {"run_all"},
    ["melee"] = {"swing"},
}