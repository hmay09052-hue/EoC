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
-- If the nextbot has an enemy, this decides how to proceed.
--
function ENT:DoConfrontEnemy(ent)
    if not ent or not IsValid(ent) then return end

    local shootRange, looseRange = self:EnemyInRange()
    local entPos = ent:GetPos()

    if shootRange then
        self:PathFollowerStop()
        self:ShootEnemy()

        if self.ThrowGrenades and math.random(0, 100) > 99 then
            self:ThrowGrenade()
        end

        self.loco:FaceTowards(entPos)
    else

        if not looseRange then
            self:SetEnemy(false)
            return
        end

        if ent == self:GetNewEnemy() then
            self:RunTo(entPos, self.Speed * 3)
        end

    end
end

-- FUNCTION
-- If the nextbot does not has an enemy, this makes it patrol around.
--
function ENT:DoNormal()
    if self.Path:GetAge() < 5 then return end
    self:RunTo(self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 700, self.Speed * .75)
end

ENT.EveryThreeSecondsCooldown = 0

-- FUNCTION
-- Main nextbot coroutine
--
function ENT:RunBehaviour()
    self.Path = Path("Follow")
    self.Path:ResetAge()
    self.Path:Compute(self, self:GetPos())

    while true do

        if self:HasEnemy() then
            self:DoConfrontEnemy(self:GetEnemy())
        else
            self:DoNormal()
        end

        self:GetNewEnemy()

        self.Path:Update(self)

        if self.ResetSequences then
            self:ResetSequenceInfo()
        end

        if self.loco:IsStuck() then
			self:HandleStuck()
			continue
		end

        self:OpenDoors()

        if self.EveryThreeSecondsCooldown <= CurTime() then
            self:EveryThreeSeconds()
            self.EveryThreeSecondsCooldown = CurTime() + 3
        end

        coroutine.wait(0.1)
    end
end

-- FUNCTION
-- This helper function just computes a new path to a wished destination.
--
function ENT:PathFollowerCompute(pos)
    self.Path:Compute(self, pos)
end

-- FUNCTION
-- This helper function just forces the nextbot to stop and "delete" the path.
--
function ENT:PathFollowerStop()
    --self:ResetActivity()
    coroutine.yield()
    self.Path:Compute(self, self:GetPos())
end

-- FUNCTION
-- We probably dont need it anway
--
function ENT:IsMoving()
    return false
end

-- FUNCTION
-- We probably dont need it anway
--
function ENT:IsOnGround()
    return true
end

-- FUNCTION
-- Helper function to emit sounds, maybe neeeds a rework in the future? FIXME
--
function ENT:MakeSound(sound, percentage)
    if not self.Sounds then return end
    if self.Sounds == {} then return end

    if sound == nil then return end
    if not sound then return end
    if istable(sound) then return end

    if math.random(0, 100) >= percentage then
        self:EmitSound(sound, 90, 100, 1, CHAN_VOICE)
    end
end

-- FUNCTION
-- Helper function to create animations on the nextbot, maybe neeeds a rework in the future? FIXME
--
function ENT:PlayAnimation(category, shouldResetSequenceInfo)
    if self.LastAnimation == category then return end

    local anim = table.Random(self.Anims[category] or {})

    if istable(anim) then return end
    if anim == nil then return end
    
    self:SetSequence(anim)
    self.LastAnimation = category
    
    if shouldResetSequenceInfo then
        self.ResetSequences = true
    else
        self.ResetSequences = false
    end
end

-- FUNCTION/HOOK
-- Handles the damage taking
--
function ENT:OnInjured(dmgInfo)
    if self.Sounds then
	    self:MakeSound(table.Random(self.Sounds["hit"] or {}), 80)
    end
    
    --if self:HasEnemy() then return end

    -- Headshot stuff
    if not SummeNextbots.Config.Headshots then return end
    local newVec = self:WorldToLocal(dmgInfo:GetDamagePosition())
    if newVec.z > (self.HeadPosZ - 10) then
        dmgInfo:ScaleDamage(2)
    end
end

-- FUNCTION/HOOK
-- Handles the killing of the nextbot
--
function ENT:OnKilled(dmgInfo)
    hook.Call("OnNPCKilled", GAMEMODE, self, dmgInfo:GetAttacker(), dmgInfo:GetInflictor())

    if self.Sounds then
        self:MakeSound(table.Random(self.Sounds["killed"] or {}), 30)
    end

    self:BecomeRagdoll(dmgInfo)
    timer.Simple(0.1, function()
        if not IsValid(self) then return end
        self:Remove()
    end)
end

-- FUNCTION
-- Should return the AimVec, but its broken on nextbots FIXME
--
function ENT:GetAimVector()
    return self:GetForward()
end

-- Valid door entity classes to look for
local doors = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true,
}

ENT.OpenDoorsCooldown = 0

-- FUNCTION
-- Looks every second for doors in the surrounding area and opens them if possible
--
function ENT:OpenDoors()
    if self.OpenDoorsCooldown >= CurTime() then return end
    if not SummeNextbots.Config.CanOpenDoors then return end -- To deactivate it, maybe saves performance

    local ents = ents.FindInSphere(self:GetPos(), 50)
    for k,v in pairs(ents) do
        if doors[v:GetClass()] then
            if v.IsOpen then continue end

            -- TODO: Check if the door is openable by touching or using
        
            v:Fire("Open")
            v.IsOpen = true

            timer.Simple(5, function()
                v:Fire("Close")
                v.IsOpen = false
            end)
        end
    end

    self.OpenDoorsCooldown = CurTime() + 1
end

-- FUNCTION
-- Lets the nextbot throw a grenade
--
function ENT:ThrowGrenade()
    if self.ThrowedGrenade then return end

	local ent = self:GetEnemy()
	if not IsValid(ent) then return end
	local pos = ent:GetPos()

	timer.Simple(0.8, function()
		if IsValid(self) then
			self.Grenade = ents.Create(table.Random(self.Grenades))
			local att = self:GetAttachment(2)
			self.Grenade:SetPos(att.Pos)
			self.Grenade:SetAngles(att.Ang)
			self.Grenade:SetOwner(self)
			self.Grenade:Spawn()
			self.Grenade:Activate()
			self.Grenade:SetMoveType( MOVETYPE_NONE )
			self.Grenade:SetParent( self, 2 )
			self.Grenade.BlastRadius = 200
			self.Grenade.BlastDMG = 80
		end
	end)
	timer.Simple(1, function()
		if IsValid(self) and IsValid(self.Grenade) then
			self.Grenade:SetMoveType( MOVETYPE_VPHYSICS )
			self.Grenade:SetParent( nil )
			self.Grenade:SetPos(self:GetAttachment(2).Pos)
			local prop = self.Grenade:GetPhysicsObject()
			if IsValid(prop) then
				prop:Wake()
				prop:EnableGravity(true)
				prop:SetVelocity( (self:GetAimVector() * 500)+(self:GetUp()*(math.random(10,50)*5)) )
			end
		end
	end)

	self.ThrowedGrenade = true

	timer.Simple(math.random(10,15), function()
		if IsValid(self) then
			self.ThrowedGrenade = false
		end
	end)
end