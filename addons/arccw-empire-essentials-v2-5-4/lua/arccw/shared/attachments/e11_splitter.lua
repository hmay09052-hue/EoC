att.PrintName = "E-11 Splitter"
att.Icon = Material("entities/kraken/empire-v2/attachments/powerpack.png", "mips smooth")
att.Description = "Transforms weapon into a shotgun."
att.Desc_Pros = {}
att.Desc_Cons = {}

att.Slot = "e11_k_muzzles"
att.ActivateElements = {"e11_k_splitter"}

att.Add_Num = 4
att.Mult_Range = 1.25

att.Mult_AccuracyMOA = 50
att.Mult_HipDispersion = 2
att.Mult_SightsDispersion = 2

att.Mult_Damage = 0.9
att.Mult_DamageMin = 0.9

att.Hook_GetShootSound = function(wep, sound)
    return false
end
att.Hook_AddShootSound = function(wep, data)
    wep:MyEmitSound("arccw/kraken/empire/e-series/e11e.wav", data.volume, data.pitch, 1, CHAN_WEAPON - 1)
end