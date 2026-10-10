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

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

ENT.Model = "models/npc/b1battledroids/b1_base.mdl"
ENT.Weapon = "rw_swnpc_e5"
ENT.HP = 300
ENT.ShootingRange = 860
ENT.LooseRadius = 1500
ENT.Proficiency = 0
ENT.Speed = 100

ENT.Melee = false
ENT.MeleeDamage = 25
ENT.MeleeDelay = 3

ENT.ThrowGrenades = false
--ENT.Grenades = {"rw_sw_ent_nade_impact", "rw_sw_ent_nade_stun", "rw_sw_ent_nade_thermal", "rw_sw_ent_nade_smoke"}