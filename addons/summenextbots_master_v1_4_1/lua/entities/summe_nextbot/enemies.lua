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


-- FUNCTION
-- Forces a new entity to be the new enemy of the nextbots, doesnt matter whether its in the realistic view direction
--
function ENT:SetEnemy(ent)
    --if IsValid(ent) and SummeNextbots.Config.CheckFieldOfVision then
    --    if not self:IsAbleToSee(ent) then return end
    --end

	self:SetNWEntity("targetEnemy", ent)
end

-- FUNCTION
-- Returns the current enemy entity
--
function ENT:GetEnemy()
	return self:GetNWEntity("targetEnemy", false)
end

-- FUNCTION
-- Returns whether the nextbot has an enemy
--
function ENT:HasEnemy()
    local enemy = self:GetEnemy()
    if IsValid(enemy) then return true end
	return false
end

-- FUNCTION
-- Should be called, when trying to set a new enemy. This considers also, whether the new enemy is visible by the nextbot
--
function ENT:TryNewEnemy(ent)
    if not SummeNextbots.Config.CheckFieldOfVision then self:SetEnemy(ent) return end

    local weapon = self:GetWeapon()
    if not weapon or not IsValid(weapon) then self:SetEnemy(ent) return end -- fallback if no weapon

    local tr = util.TraceLine({
        start = weapon:GetPos() + Vector(0, 0, 50),
        endpos = ent:HeadTarget(ent:GetPos()) - Vector(0, 0, 10),
        filter = {weapon, self},
    })

    -- Also includes LFS fix
    if tr.Entity != ent and not tr.Entity.AITEAM then return end

    self:SetEnemy(ent)
end

-- FUNCTION
-- Returns, whether the enemy is in shooting / loosing range
--
function ENT:EnemyInRange()
    if not IsValid(self:GetEnemy()) then return end

    local entPos = self:GetEnemy():GetPos()
    local dist = self:GetPos():DistToSqr(entPos)

    local shootingRange = self.ShootingRange

    if not SummeNextbots.NavMap then
        shootingRange = self.LooseRadius
    end
        
    return dist < shootingRange * shootingRange, dist < self.LooseRadius * self.LooseRadius
end

-- FUNCTION
-- Searching for new enemies
--
function ENT:GetNewEnemy()
    if self.Path:GetAge() < 1 then return end     --  |        This should fix the continous searching
    local ents_ = player.FindInSphere(self:EyePos(), self.LooseRadius)

    for _, ent in RandomPairs(ents_) do
        if hook.Run("SummeNextbot.CannotTarget", ent, self) then continue end
        self:TryNewEnemy(ent)
    end

    return self:GetEnemy()
end