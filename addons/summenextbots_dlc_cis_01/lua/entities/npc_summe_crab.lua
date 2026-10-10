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
ENT.PrintName = "Crab Droid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/npc/starwars/crabby/crabdroid.mdl"
ENT.Weapon = "weapon_npc_crab"
ENT.HP = 500
ENT.ShootingRange = 800
ENT.LooseRadius = 2000
ENT.Proficiency = .2

ENT.Melee = true
ENT.MeleeDamage = 50
ENT.MeleeDelay = 3

ENT.Sounds = {}

ENT.ThrowGrenades = false
ENT.Grenades = {"summe_gr_impact"}

ENT.Anims = {
    ["shoot"] = {0},
    ["reload"] = {0},
    ["walk_slow"] = {"walk"},
    ["walk_fast"] = {"walk"},
    ["melee"] = {"walk"},
    ["jump"] = {0},
}

local walkSounds = {
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_1.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_2.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_3.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_4.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_5.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_6.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_7.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_8.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_9.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_10.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_11.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_12.mp3",
}

ENT.LastWalkSound = 0

function ENT:RunTo(pos, speed)

    if self.LastWalkSound <= CurTime() then
        self:EmitSound(table.Random(walkSounds), 120, 100, 1, CHAN_AUTO) 
        self.LastWalkSound = CurTime() + .3
    end
    if self.Path:GetAge() < 1 then return end
    if self.IsJumping then return end

    if speed and speed < 300 then
        self:PlayAnimation("walk_slow", true)
    else
        self:PlayAnimation("walk_fast", true)
    end
    self.loco:SetDesiredSpeed(speed or 200)
    self:PathFollowerCompute(pos)
end


function ENT:SetWeapon(weaponClass)
    local currentWeapon = self:GetWeapon()

    if currentWeapon then
        currentWeapon:Remove()
    end

    local newWep = ents.Create(weaponClass)
    newWep:Spawn()
    newWep:Activate()
    newWep:SetPos(self:GetPos() + Vector(0, 0, 20))
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

function ENT:DoConfrontEnemy(ent)
    if not ent or not IsValid(ent) then return end

    local shootRange, looseRange = self:EnemyInRange()

    --print(shootRange, looseRange)

    if shootRange then
        self:PathFollowerStop()

        if not self.IsJumping then
            self:ShootEnemy()
        end

        self.loco:FaceTowards(ent:GetPos())
    else
        --print(3)

        if not looseRange then
            self:SetEnemy(nil)
            return
        end

        if ent == self:GetNewEnemy() then
            if self.IsJumping then return end
            if math.random(1, 200) >= 100 then
                self.IsJumping = true
                self:JumpTo(ent:GetPos())
                
                timer.Simple(2, function()
                    self.IsJumping = false 
                end)
            else
                self:RunTo(ent:GetPos(), self.Speed * 3)
            end
        end
    end
end

function ENT:OnLandOnGround(ent)
    local radius = math.random(300, 1000)
    local pos = self:GetPos()
    util.ScreenShake(pos, 20, 5, 1, radius)

    for k, v in pairs(player.FindInSphere(pos, radius)) do
        v:TakeDamage(math.random(0, 75), self, self)
        v:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 128), 0.3, 1)
    end

    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    timer.Simple(2, function()
        if not IsValid(self) then return end

        self:SetCollisionGroup(COLLISION_GROUP_NONE)
    end)
end

function ENT:OnTakeDamage(dmgInfo)
    if self:Health() < 1 then
        self.Explo = ents.Create( "env_explosion" )
        self.Explo:SetKeyValue( "spawnflags", 144 )
        self.Explo:SetKeyValue( "iMagnitude", 15 )
        self.Explo:SetKeyValue( "iRadiusOverride", 256 )
        self.Explo:SetPos( self:GetPos() )
        self.Explo:Spawn()
        self.Explo:Fire( "explode", "", 0 )
        self:Remove()
    end
end

function ENT:OnNPCSpawn()
	--self.loco:SetGravity(130)
    self.loco:SetStepHeight(40)
end

function ENT:OnRemove()
    if SERVER then
        self.Explo = ents.Create( "env_explosion" )
        self.Explo:SetKeyValue( "spawnflags", 144 )
        self.Explo:SetKeyValue( "iMagnitude", 15 )
        self.Explo:SetKeyValue( "iRadiusOverride", 256 )
        self.Explo:SetPos( self:GetPos() )
        self.Explo:Spawn()
        self.Explo:Fire( "explode", "", 0 )
    end
end