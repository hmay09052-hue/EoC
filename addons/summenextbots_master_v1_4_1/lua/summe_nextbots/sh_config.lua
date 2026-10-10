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

SummeNextbots.Config = {}

-- Here you can set the NPCs that you can spawn with the pod and the dispenser.
SummeNextbots.Config.Tool = {
    [1] = {
        name = "B1 Battledroid", -- You can choose the name 
        class = "npc_summe_b1", -- The class
        previewModel = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl", -- Just a model for the UI
    },
    [2] = {
        name = "B1 Heavy Battledroid",
        class = "npc_summe_b1_heavy",
        previewModel = "models/npc/b1_battledroids/heavy/b1_battledroid_heavy.mdl",
    },
    [3] = {
        name = "B1 Officerdroid",
        class = "npc_summe_b1_officer",
        previewModel = "models/npc/b1_battledroids/officer/b1_battledroid_officer.mdl",
    },
    [4] = {
        name = "B2 Superbattledroid",
        class = "npc_summe_b2",
        previewModel = "models/npc/b2_battledroid/b2_battledroid.mdl",
    },
    [5] = {
        name = "BX Commando",
        class = "npc_summe_bx",
        previewModel = "models/sally/tkaro/bx_commando_droid.mdl",
    },
    [6] = {
        name = "Magna Guard",
        class = "npc_summe_magnaguard",
        previewModel = "models/npc_mag_base/npc_droid_mag_base_f.mdl",
    },
}

-- No navmesh means the droids can't walk. Should they be removed then?
SummeNextbots.Config.DespawnIfNoNavmap = false

-- Can droids open doors? May possibly save performance if you disable it.
SummeNextbots.Config.CanOpenDoors = true

-- Should the name and HP bar be present over the heads?
SummeNextbots.Config.ShowNameTags = true

-- Should the NPC check if the new enemy is in his vision field before setting him to the new target? Could cause performance problems.
SummeNextbots.Config.CheckFieldOfVision = true

-- Should headshots do more damage?
SummeNextbots.Config.Headshots = true

-- Enable the debug mode on default for everyone? Admins can activate it anytime via summenextbots_debug in their client console.
SummeNextbots.Config.Debug = false