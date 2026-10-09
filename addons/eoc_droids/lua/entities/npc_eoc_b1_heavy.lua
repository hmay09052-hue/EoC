AddCSLuaFile()

ENT.Base = "npc_eoc_b1"
ENT.PrintName = "B1 Schwerer Kampfdroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Hohe Feuerrate und verstaerkte Panzerung.
ENT.Model = "models/npc/b1_battledroids/heavy/b1_battledroid_heavy.mdl"
ENT.Weapon = "e5_heavy"
ENT.HP = 170
ENT.Scale = 1.08
ENT.DamageScale = 0.7
ENT.ShootingRange = 1000
ENT.Inaccuracy = 0.3
ENT.Speed = 85
ENT.ShootWhileMoving = false
ENT.StrafeChance = 0
ENT.MeleeDamage = 25
ENT.Grenades = { "eoc_droid_impactgrenade" }
ENT.NameTagColor = Color(170, 30, 30, 230)
