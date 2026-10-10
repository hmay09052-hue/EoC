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
-- Returns the current weapon
--
function ENT:GetWeapon()
    local wep = self:GetNWEntity("weapon", false)

    return wep
end

-- FUNCTION
-- Sets a new weapon to the nextbot
--
function ENT:SetWeapon(weaponClass)
    local cWeapon = self:GetWeapon()

    if cWeapon then
        cWeapon:Remove()
    end

    local newWep = ents.Create(weaponClass)
    newWep:Spawn()
    newWep:Activate()
    newWep:SetPos(self:GetAttachment(self:LookupAttachment("anim_attachment_RH")).Pos)
    newWep:SetSolid(SOLID_NONE)
    newWep:SetParent(self)
    newWep:AddEffects(EF_BONEMERGE)
    newWep:SetOwner(self)

    self.NormalWeaponClip = newWep:Clip1()

    self:SetNWEntity("weapon", newWep)

    function newWep:CanPrimaryFire()
        return true
    end
end

-- FUNCTION
-- Returns the current weapon (Alias function)
--
function ENT:GetActiveWeapon()
    return self:GetWeapon()
end

-- FUNCTION
-- Forces the nextbot to open fire
--
function ENT:ShootEnemy()
    local weapon = self:GetWeapon()
    local enemy = self:GetEnemy()

    if not IsValid(weapon) then return end
    if hook.Run("SummeNextbot.CannotTarget", enemy, self) then self:SetEnemy(false) return end

    if self.DisableShooting then return end

    weapon.LastEnemy = enemy

    if weapon:Clip1() > 0 then
        if self.IsReloading then return end
        self:PlayAnimation("shoot")
        weapon:PrimaryAttack()
        if self.Sounds then
            self:MakeSound(table.Random(self.Sounds["attacking"] or {}), 95)
        end
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

ENT.MeleeSounds = {
    "physics/metal/metal_canister_impact_hard1.wav",
    "physics/metal/metal_canister_impact_hard3.wav",
    "physics/metal/metal_canister_impact_hard2.wav",
    "physics/metal/metal_box_strain1.wav",
    "physics/metal/metal_box_strain2.wav",
    "physics/metal/metal_box_strain3.wav",
}

-- FUNCTION
-- Internal function to handle melee attacking
--
function ENT:OnContact(ent)
    if not ent:IsValid() or not ent:IsPlayer() then return end
    if not ent:Alive() then return end
    if ent:IsWorld() then return end
    if hook.Run("SummeNextbot.CannotTarget", ent, self) then return end
    self:DoMelee(ent)
end

ENT.NextMeleeTimer = 0

-- FUNCTION
-- Handles melee attacking
--
function ENT:DoMelee(ent)
    if not self.Melee then return end
    if self.NextMeleeTimer > CurTime() then return end
    self.NextMeleeTimer = CurTime() + self.MeleeDelay or 2

    if not self:IsAbleToSee(ent) then return end

    self.DisableShooting = true

    self:PlayAnimation("melee", true)
    ent:TakeDamage(self.MeleeDamage or 40, self, self)
    self:MakeSound(table.Random(self.MeleeSounds), 0)
    ent:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 128), 0.3, 1)

    ent:SetVelocity(self:GetForward():GetNormalized() * 1000)

    timer.Simple(1, function()
        if not IsValid(self) then return end
        self.DisableShooting = false
    end)
end