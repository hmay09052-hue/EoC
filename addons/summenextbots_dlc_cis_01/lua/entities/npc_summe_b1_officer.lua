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
ENT.PrintName = "B1 Officerdroid"
ENT.Category = "Summe (Nextbots)"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/npc/b1_battledroids/officer/b1_battledroid_officer.mdl"
ENT.Weapon = "weapon_npc_rg4d"
ENT.HP = 60
ENT.ShootingRange = 460
ENT.LooseRadius = 1500
ENT.Proficiency = 0

ENT.Melee = true
ENT.MeleeDamage = 25
ENT.MeleeDelay = 3

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
ENT.Anims = {
    ["shoot"] = {"shoot_shotgun", "shootp1", "layer_walk_aiming", "crouch_shoot_smg1"},
    ["reload"] = {"reload_ar2", "reload_smg1", "reload_shotgun1", "crouch_reload_smg1"},
    ["walk_slow"] = {"walkAlertHOLDALL1", "walkAIMALL1", "walkHOLDALL1_ar2", "walk_holding_RPG_all"},
    ["walk_fast"] = {"run_protected_all", "run_all", "run_alert_holding_all", "run_alert_aiming_ar2_all", "crouchRUNAIMINGALL1"},
    ["melee"] = {"swing"},
}

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsBoosting", { KeyName = "CommandPostName", Edit = { type = "Generic", order = 1, category = "Settings"}})
end

function ENT:EveryThreeSeconds()
    local ents_ = ents.FindInSphere(self:GetPos(), 500)
    local droids = 0

    for k, v in pairs(ents_) do
        if not v.SummeNextbot then continue end
        if v == self then continue end
        local hp, maxHp = v:Health(), v:GetMaxHealth()
        if hp >= maxHp then continue end

        v:SetHealth(math.Clamp(hp + maxHp * .2, 0, maxHp))

        local effectdata = EffectData()
        effectdata:SetOrigin(v:GetPos() + Vector(0, 0, 50))
        util.Effect("ManhackSparks", effectdata)

        v:MakeSound("items/ammo_pickup.wav", 0)

        droids = droids + 1
    end

    if droids <= 0 then return end

    self:SetIsBoosting(true)
    timer.Simple(0.7, function()
        if not IsValid(self) then return end
        self:SetIsBoosting(false)
    end)
end

local material = Material("particle/particle_ring_wave_addnofog")
local red = Color(255,53,53,84)
ENT.intPol = 0

function ENT:Draw()
    self:DrawModel()
    self:DrawNameTag()

    if not self:GetIsBoosting() then self.intPol = 0 return end

    render.SetMaterial(material)
    self.intPol = Lerp(FrameTime() * 3, self.intPol, 500 * 2)
    render.DrawQuadEasy(self:GetPos(), Vector(0, 0, 1), self.intPol, self.intPol, red, 0)
end