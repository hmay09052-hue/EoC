att.PrintName = "The Commando"
att.Icon = Material("entities/kraken/sops/atts/commando.png")
att.Description = "You're a Commando, an ace when it comes to Blaster Carabines or Rifles. Your reload speed and accuracy will increase when using an assault or carabine blaster along other benefits."
att.Desc_Pros = {
}
att.Desc_Cons = {
}
att.AutoStats = true
att.Slot = "perk"

att.NotForNPC = true

att.Mult_AccuracyMOA = 0.1
att.Mult_HipDispersion = 0.25
att.Mult_Damage = 1.5
att.Mult_Range = 2
att.Mult_Penetration = 3
att.Mult_ReloadTime = 0.65

att.Hook_Compatible = function(wep)
    if (wep.Primary.Ammo ~= "ar2" and wep.Primary.Ammo ~= "smg1") then return false end
end