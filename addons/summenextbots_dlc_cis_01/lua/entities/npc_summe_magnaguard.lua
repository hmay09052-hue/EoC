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
ENT.PrintName = "Magna Guard"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/tfa/comm/gg/npc_reb_magna_guard_combined.mdl"
ENT.Weapon = "weapon_npc_magnastick"
ENT.HP = 600
ENT.ShootingRange = 80
ENT.LooseRadius = 2000
ENT.Proficiency = 0

ENT.Melee = true
ENT.MeleeDamage = 50
ENT.MeleeDelay = 2

ENT.ThrowGrenades = false
ENT.Grenades = {"summe_gr_impact"}

ENT.Sounds = {
    ["hit"] = {
        "summe/nextbots/droids/b1/clonewars/huh.mp3",
        "summe/nextbots/droids/b1/clonewars/no.mp3",
        "summe/nextbots/droids/b1/clonewars/oh-no.mp3",
        "summe/nextbots/droids/b1/clonewars/problem.mp3",
        "summe/nextbots/droids/b1/clonewars/uh-oh.mp3",
        "summe/nextbots/droids/b1/clonewars/ouch.mp3",
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
        "summe/nextbots/droids/b1/clonewars/scream.mp3",
    },
    ["attacking"] = {
        "summe/nextbots/droids/b1/clonewars/blast-em.mp3",
        "summe/nextbots/droids/b1/clonewars/charge.mp3",
        "summe/nextbots/droids/b1/clonewars/cut-chatter.mp3",
        "summe/nextbots/droids/b1/clonewars/hold-it.mp3",
        "summe/nextbots/droids/b1/clonewars/my-programming.mp3",
        "summe/nextbots/droids/b1/clonewars/prepare-fire.mp3",
        "summe/nextbots/droids/b1/clonewars/roger-roger.mp3",
        "summe/nextbots/droids/b1/clonewars/said-hold-it.mp3",
        "summe/nextbots/droids/b1/clonewars/surrender-jedi.mp3",
        "summe/nextbots/droids/b1/clonewars/what-was-that.mp3",
        "summe/nextbots/droids/b1/clonewars/youre-welcome.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_012.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_013.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_014.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_015.mp3",
    },
}

ENT.MeleeSounds = {
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_01.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_02.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_03.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_04.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_05.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_06.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_07.mp3",
}

ENT.Anims = {
    ["shoot"] = {"shoot_shotgun", "shootp1", "layer_walk_aiming", "crouch_shoot_smg1"},
    ["reload"] = {"reload_ar2", "reload_smg1", "reload_shotgun1", "crouch_reload_smg1"},
    ["walk_slow"] = {"walk_all", "walkAIMALL1", "walkHOLDALL1_ar2", "walk_holding_RPG_all"},
    ["walk_fast"] = {"run_protected_all", "run_all", "run_alert_holding_all", "run_alert_aiming_ar2_all", "crouchRUNAIMINGALL1"},
    ["melee"] = {"MeleeAttack01"},
}

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsResurrected", {})
end

function ENT:OnNPCSpawn()
	if not self:GetIsResurrected() then
        self:SetBodygroup(1,1)
    end
end

function ENT:OnKilled(dmgInfo)
    if math.random(0, 100) > 75 and not self:GetIsResurrected() then
        local RagdollEnt = ents.Create("prop_ragdoll")
        RagdollEnt:SetModel("models/npc_mag_base/npc_droid_mag_base_f.mdl")
        RagdollEnt:SetPos(self:GetPos())
        RagdollEnt:Spawn()

        self:Remove()

        timer.Simple(3, function()

            local BoomBoom4 = ents.Create("env_explosion")
            BoomBoom4:SetKeyValue("spawnflags", 144)
            BoomBoom4:SetKeyValue("iMagnitude", 0)
            BoomBoom4:SetKeyValue("iRadiusOverride", 10)
            BoomBoom4:SetPos(RagdollEnt:GetPos())
            BoomBoom4:Spawn()
            BoomBoom4:Fire("explode", "", 0)

            local NewNPC = ents.Create("npc_summe_magnaguard")
            NewNPC:SetPos(RagdollEnt:GetPos() + Vector(0, 0, 10))
            NewNPC:SetIsResurrected(true)
            NewNPC:Spawn()

            RagdollEnt:Remove()
        end)
    else
        hook.Call("OnNPCKilled", GAMEMODE, self, dmgInfo:GetAttacker(), dmgInfo:GetInflictor())

        self:MakeSound(table.Random(self.Sounds["killed"] or {}), 30)

        self:BecomeRagdoll(dmgInfo)
        timer.Simple(0.1, function()
            if not IsValid(self) then return end
            self:Remove()
        end)
    end
end

local purple = Color(148,0,148)

function ENT:Draw()
    self:DrawModel()
    if self:GetIsResurrected() then
        self:DrawNameTag(purple)
    else
        self:DrawNameTag()
    end
end

function ENT:DoMelee(ent)
    if not self.Melee then return end
    if self.NextMeleeTimer > CurTime() then return end
    self.NextMeleeTimer = CurTime() + self.MeleeDelay or 2

    if not self:IsAbleToSee(ent) then return end

    self.DisableShooting = true

    self:PlayAnimation("melee", true)
    ent:TakeDamage(self.MeleeDamage or 40, self, self)
    self:MakeSound(table.Random(self.MeleeSounds), 0)
    ent:ScreenFade(SCREENFADE.IN, Color(234, 72, 255, 52), 0.3, 1)

    ent:SetVelocity(self:GetForward():GetNormalized() * 1400)

    timer.Simple(1, function()
        if not IsValid(self) then return end
        self.DisableShooting = false
    end)
end

function ENT:ShootEnemy()
end