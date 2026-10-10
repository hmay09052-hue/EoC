--[[
    EoC Range – DC-15x Trainingsvariante (1 Schaden)
    Erbt alles von der DC-15x aus den ArcCW Republic Essentials; nur der Schaden ist auf 1 gesetzt.
    Wird im Scharfschützen-Modus benutzt.
]]
AddCSLuaFile()

SWEP.Base        = "arccw_k_dc15x"
SWEP.Spawnable   = true
SWEP.AdminOnly   = false
SWEP.Category    = "EoC Range"
SWEP.PrintName   = "DC-15x Training"
SWEP.Trivia_Desc = "Trainingsversion der DC-15x für den Schießstand. Verursacht nur 1 Schaden."

SWEP.Damage    = 1
SWEP.DamageMin = 1

-- orange wie bei den anderen Trainingswaffen der Republic Essentials
SWEP.Tracer           = "new_tracer_orange"
SWEP.TracerCol        = Color(250, 120, 0)
SWEP.MuzzleEffect     = "arccw_kraken_sw_muzzle_orange"
SWEP.MuzzleFlashColor = Color(250, 120, 0)
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD]     = 1,
    [HITGROUP_CHEST]    = 1,
    [HITGROUP_STOMACH]  = 1,
    [HITGROUP_LEFTARM]  = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG]  = 1,
    [HITGROUP_RIGHTLEG] = 1,
}
