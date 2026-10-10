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
ENT.PrintName = "B2-X Superbattledroid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/npc/b2_battledroid/b2_battledroid.mdl"
ENT.Weapon = "weapon_npc_b2"
ENT.HP = 100
ENT.ShootingRange = 800
ENT.LooseRadius = 2000
ENT.Proficiency = 0
ENT.Speed = 60

ENT.Scale = 1.15

ENT.ThrowGrenades = false
ENT.Grenades = {"summe_gr_impact"}

ENT.Sounds = {
    ["hit"] = {
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_01.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_02.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_03.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_04.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_05.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_06.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_07.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_08.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_09.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_10.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_11.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_12.mp3",
    },
    ["killed"] = {
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_01.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_02.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_03.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_04.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_05.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_06.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_07.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_08.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_09.mp3",
    },
    ["attacking"] = {
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_01.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_02.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_03.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_04.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_05.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_06.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_07.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_08.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_09.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_010.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_011.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_012.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_013.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_014.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_015.mp3",
    },
}

ENT.Anims = {
    ["shoot"] = {"idle_alert_02", "d2_coast03_Odessa_Stand_RPG"},
    ["reload"] = {"pace_all"},
    ["walk_slow"] = {"walk_all"},
    ["walk_fast"] = {"walk_all"},
    ["melee"] = {"swing"},
}

function ENT:DoConfrontEnemy(ent)
    if not ent or not IsValid(ent) then return end

    local shootRange, looseRange = self:EnemyInRange()

    if shootRange then
        self:PathFollowerStop()

        if self:GetNWBool("IsInAir", false) and math.random(0, 100) > 95 then
            self:ShootMissle()
            return
        end

        self:ShootEnemy()

        self.loco:FaceTowards(ent:GetPos())
    else

        if not looseRange then
            self:SetEnemy(nil)
            return
        end

        if ent == self:GetNewEnemy() then
            if self.IsJetBoosting then return end
            if math.random(1, 200) >= 195 then
                self.IsJetBoosting = true
                self:JumpTo(ent:GetPos())
                
                timer.Simple(2, function()
                    self.IsJetBoosting = false 
                end)
            else
                self:RunTo(ent:GetPos(), self.Speed * 3)
            end
        end
    end
end

function ENT:ShootMissle()
    if IsValid(self.Missle) then return end
    local enemy = self:GetEnemy()
    if not enemy then return end

    self:EmitSound("summe/nextbots/weapons/simple_oneshot_juggernaut_rocketlauncher_close_var_01.mp3", 100, 100, 1, CHAN_WEAPON)

    local enemyPos = enemy:GetPos()
    local selfPos = self:GetPos() + Vector(0, 0, 40)
    local dir = (enemyPos - selfPos):GetNormalized()

    self.Missle = ents.Create("summe_b2missle")
    self.Missle:SetPos(self:EyePos())
    self.Missle:SetAngles(self:EyeAngles())
    self.Missle:SetOwner(self)
    self.Missle:Spawn()
end

function ENT:OnNPCSpawn()
	self.loco:SetGravity(70)
    self.loco:SetStepHeight(40)
    self.loco:SetDeathDropHeight(1000)
end

if SERVER then
    function ENT:Think()
        if not self.loco:IsOnGround() then
            self:SetNWBool("IsInAir", true)
        end
    end 

    function ENT:OnLandOnGround()
        self:SetNWBool("IsInAir", false)
    end

    function ENT:OnRemove()
        if self:GetNWBool("IsInAir", false) then
            self.Explo = ents.Create( "env_explosion" )
            self.Explo:SetKeyValue( "spawnflags", 144 )
            self.Explo:SetKeyValue( "iMagnitude", 15 )
            self.Explo:SetKeyValue( "iRadiusOverride", 256 )
            self.Explo:SetPos( self:GetPos() )
            self.Explo:Spawn()
            self.Explo:Fire( "explode", "", 0 )
        end
    end
end

if CLIENT then
    local colorRed = Color(150, 0, 0, 230)
    local colorGrey = Color(15, 15, 15, 230)
    local colorWhite = Color(255,255,255)
    local MaterialGlow = Material("sprites/light_glow02_add")
    local ColorGlow = Color(255,174,0)

    function ENT:Draw()
        self:DrawModel()
        self:DrawNameTag(colorRed, 5)

        if not self.JetPackSound then
            self.JetPackSound = CreateSound(self, "thrusters/jet03.wav")
            self.JetPackSound:SetSoundLevel(80)
        end

        if self:GetNWBool("IsInAir", false) then
            self:DrawJetpackFire()

            self.JetPackSound:PlayEx(0.5, 125)
        else
            self.JetPackSound:FadeOut(0.1)
        end
    end
    
    local MatHeatWave = Material( "sprites/heatwave" )
    local MatFire = Material( "effects/fire_cloud1" )

    local JetpackFireBlue = Color( 0 , 0 , 255 , 128 )
    local JetpackFireWhite = Color( 255 , 255 , 255 , 128 )
    local JetpackFireNone = Color( 255 , 255 , 255 , 0 )
    local JetpackFireRed = Color( 255 , 128 , 128 , 255 )

    function ENT:DrawJetpackFire()

        local forwardA = self:GetAngles()
        forwardA.pitch = 0

        local normal = Vector(0, 0, -1)
        local pos = self:GetPos() + Vector(0, 0, 40) + forwardA:Forward() * -10
        local scale = 0.25

        local scroll = 1000 + UnPredictedCurTime() * -10

        --the trace makes sure that the light or the flame don't end up inside walls
        --although it should be cached somehow, and only do the trace every tick

        local tracelength = 50

        render.SetMaterial( MatFire )

        render.StartBeam( 3 )
            render.AddBeam( pos, 8 * scale , scroll , JetpackFireBlue )
            render.AddBeam( pos + normal * 60 * scale , 32 * scale , scroll + 1, JetpackFireWhite )
            render.AddBeam( pos + normal * tracelength , 32 * scale , scroll + 3, JetpackFireNone )
        render.EndBeam()

        render.SetMaterial( MatFire )

        render.StartBeam( 3 )
            render.AddBeam( pos, 100 * scale , scroll , JetpackFireBlue )
            render.AddBeam( pos + normal * 60 * scale , 40 * scale , scroll + 1, JetpackFireWhite )
            render.AddBeam( pos + normal * tracelength , 32 * scale , scroll + 3, JetpackFireNone )
        render.EndBeam()

        render.SetMaterial(MaterialGlow)
        render.DrawSprite(pos, 75, 75, ColorGlow)
    end

    function ENT:OnRemove()
        if self.JetPackSound then
            self.JetPackSound:Stop()
        end
    end
end