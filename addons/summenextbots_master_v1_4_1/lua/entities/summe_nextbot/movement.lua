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

-- FUNCTION/HOOK
-- Forces the nextbot to move on ground
--
function ENT:RunTo(pos, speed, minAge)
    if not SummeNextbots.NavMap then return end

    minAge = minAge or 1

    if self.Path:GetAge() < minAge then return end
    if not self:IsOnGround() then return end

    if speed and speed < 300 then
        self:PlayAnimation("walk_slow", true)

    else
        self:PlayAnimation("walk_fast", true)
    end

    self.loco:SetDesiredSpeed(speed or 200)
    self:PathFollowerCompute(pos)
end

-- FUNCTION/HOOK
-- Forces the nextbot to do a high jump to a specific destination
--
function ENT:JumpTo(pos)
    if not SummeNextbots.NavMap then return end

    self.loco:JumpAcrossGap(pos, self:GetPos())
    self:PlayAnimation("jump", true)
end