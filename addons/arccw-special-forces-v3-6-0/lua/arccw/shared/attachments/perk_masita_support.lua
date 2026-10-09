att.PrintName = "Combat Support"
att.Icon = Material("entities/kraken/sops/atts/combat_medic.png")
att.Description = "You're a Combat Support, everything you do will award you ammo, along other benefits for your group."
att.Desc_Pros = {
}
att.Desc_Cons = {
}
att.AutoStats = true
att.Slot = "perk"

att.NotForNPC = true
att.MagExtender = true

att.Hook_BulletHit = function(wep, data)
    if CLIENT then return end
        local ent = data.tr.Entity

        if ent then
            if math.Rand(0, 100) > 25 then return end
            if ent.Health and ent:Health() > 0 then
                wep.Owner:GiveAmmo(2, wep.Primary.Ammo, true)
             end
         end
         if wep.Owner:IsPlayer() and data.tr.Entity and data.tr.HitGroup == HITGROUP_HEAD then
            wep:SetClip1(wep:Clip1() + 1)
            wep.Owner:GiveAmmo(1, wep.Primary.Ammo, true)
         end
end
