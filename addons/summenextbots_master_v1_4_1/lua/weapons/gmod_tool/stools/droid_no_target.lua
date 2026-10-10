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

TOOL.Category = "Summe Nextbots"
TOOL.Name = "No-Target"
TOOL.Command = nil
TOOL.ConfigName = nil
 
if CLIENT then
    language.Add("Tool.droid_no_target.name", "No-Target")
    language.Add("Tool.droid_no_target.desc", "Makes you or other players invisible to NPCs")
    language.Add("Tool.droid_no_target.0", "Left click: Hitted player becomes NoTarget | Right click: Hitted player becomes Target | Reload: Toggle on yourself")
end

function TOOL:LeftClick(trace)
    if not IsFirstTimePredicted() then return false end

    if SERVER then
        local ent = trace.Entity

        if not IsValid(ent) or not ent:IsPlayer() then return end

        ent:SetNoTarget(true)
        SummeLibrary:Chat(self:GetOwner(), "nextbots", string.format("%s is now invisible to NPCs and has been given the NOTARGET flag.", ent:Name()))
        SummeLibrary:Notify(ent, "success", "Summe Nextbots", "You have received the NOTARGET flag. NPCs will no longer see and attack you.")
    end

    return true
end
 
function TOOL:RightClick(trace)
    if not IsFirstTimePredicted() then return false end

    if SERVER then
        local ent = trace.Entity

        if not IsValid(ent) or not ent:IsPlayer() then return end

        ent:SetNoTarget(false)
        SummeLibrary:Chat(self:GetOwner(), "nextbots", string.format("%s is now no longer invisible to NPCs.", ent:Name()))
        SummeLibrary:Notify(ent, "warning", "Summe Nextbots", "You are no longer immune to NPCs.")
    end

    return true
end

function TOOL:Reload(trace)
    if not IsFirstTimePredicted() then return false end

    if SERVER then
        local ent = self:GetOwner()

        if not IsValid(ent) or not ent:IsPlayer() then return end

        if ent:IsFlagSet(FL_NOTARGET) then
            ent:SetNoTarget(false)
            SummeLibrary:Notify(ent, "warning", "Summe Nextbots", "You are no longer immune to NPCs.")
        else
            ent:SetNoTarget(true)
            SummeLibrary:Notify(ent, "success", "Summe Nextbots", "You have received the NOTARGET flag. NPCs will no longer see and attack you.")
        end
    end

    return true
end