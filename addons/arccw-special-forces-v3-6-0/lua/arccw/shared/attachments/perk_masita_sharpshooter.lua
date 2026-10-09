att.PrintName = "Sharpshooter"
att.Icon = Material("entities/kraken/sops/atts/sharpshooter.png")
att.Description = "You're a Sharpshooter, your shots will always be accurate alongside other benefits. Iron sights activate slowmo for better aim."
att.Desc_Pros = {
}
att.Desc_Cons = {
}
att.Desc_Neutrals = {
    "Do not switch weapons when in slowmo!",
}
att.AutoStats = true
att.Slot = "perk"

att.NotForNPC = true
att.Zedtime = 2

att.Mult_Damage = 1.05
att.Mult_DamageMin = 1.2

att.Mult_AccuracyMOA = 0.5
att.Mult_HipDispersion = 0.35
att.Mult_Range = 1
att.Mult_Penetration = 4

att.Hook_Compatible = function(wep)
    if (wep.Primary.Ammo ~= "SniperPenetratedRound" and wep.Primary.Ammo ~= "SniperRound" and wep.Primary.Ammo ~= "ar2") then return false end
end

--[[
att.Hook_Think = function(wep)
    if SERVER then
        if wep.Owner:KeyDown( IN_ATTACK2 ) then
            game.SetTimeScale(0.4)
        else
            game.SetTimeScale(1)
        end
    end
end]]