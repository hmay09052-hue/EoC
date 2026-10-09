AddCSLuaFile()

ENT.Base = "npc_eoc_b1"
ENT.PrintName = "B1 Breacher-Droide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Sturmdroide fuer den Nahbereich: Schrotblaster, sprengt auch verschlossene Tueren auf.
ENT.Model = { "models/npc/b1_battledroids/heavy/b1_battledroid_heavy.mdl", "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl" }
ENT.Weapon = "shotgun"
ENT.HP = 120
ENT.DamageScale = 0.85
ENT.ShootingRange = 450
ENT.Inaccuracy = 0.1
ENT.Speed = 125
ENT.RunMultiplier = 2.6
ENT.StrafeChance = 0.1
ENT.MeleeDamage = 30
ENT.CanBreach = true
ENT.Grenades = { "eoc_droid_impactgrenade" }
ENT.Tint = Color(235, 185, 140)
ENT.NameTagColor = Color(210, 90, 20, 230)
