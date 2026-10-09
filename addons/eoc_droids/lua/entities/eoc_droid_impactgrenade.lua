AddCSLuaFile()

DEFINE_BASECLASS("eoc_droid_grenade")

ENT.Type = "anim"
ENT.Base = "eoc_droid_grenade"
ENT.PrintName = "Droiden-Aufschlaggranate"
ENT.Spawnable = false

ENT.Models = { "models/forrezzur/impactgrenade.mdl", "models/weapons/w_grenade.mdl" }
ENT.ExplodeOnImpact = true
ENT.Radius = 230
ENT.Damage = 75
ENT.GlowColor = Color(255, 170, 30)

function ENT:Initialize()
    BaseClass.Initialize(self)
    -- kurz scharf machen, damit sie nicht in der Hand explodiert
    self.ArmTime = CurTime() + 0.15
end
