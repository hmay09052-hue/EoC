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

hook.Add("SummeNextbot.CannotTarget", "dadad", function(target, npc)
    if target:HasGodMode() then return true end
end)

hook.Add("SummeNextbot.CannotTarget", "dada32d", function(target, npc)
    if not target:Alive() then return true end
end)

hook.Add("SummeNextbot.CannotTarget", "dada3232d", function(target, npc)
    return target:IsFlagSet(FL_NOTARGET)
end)

hook.Add("PreRegisterSENT", "MakeThings234342Fun", function(ent, class)
    if ent.Base ~= "summe_nextbot" then return end

    SummeLibrary:Print("nextbots", "> Registering NPC: "..class)
    return true
end)

hook.Add("PlayerCanPickupWeapon", "231423423434", function(ply, wep)
    if wep.Base == "weapon_summes_npcbase" then return false end
end)

hook.Add("InitPostEntity", "NavMeshChecker", function()
    timer.Simple(10, function()
        if not navmesh.IsLoaded() then
            SummeLibrary:Error("nextbots", "No navmesh found for "..game.GetMap())
            SummeNextbots.NavMap = false
        else
            SummeLibrary:Success("nextbots", "Navmesh found and loaded!")
            SummeNextbots.NavMap = true
        end
    end)
end)