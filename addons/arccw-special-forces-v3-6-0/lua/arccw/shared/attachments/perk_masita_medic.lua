att.PrintName = "Combat Medic"
att.Icon = Material("entities/kraken/sops/atts/combat_medic.png")
att.Description = "You're a Combat Medic, you are the sole reason why the team is still kicking."
att.Desc_Pros = {
}
att.Desc_Cons = {
}
att.AutoStats = true
att.Slot = "perk"

att.NotForNPC = true

att.UBGL = true
att.UBGL_PrintName = "Healing Darts"
att.UBGL_Automatic = true
att.UBGL_ClipSize = 1
att.UBGL_Ammo = "ar2"
att.UBGL_RPM = 50
att.UBGL_Recoil = 1
att.UBGL_Capacity = 1

local function Ammo(wep)
    return wep.Owner:GetAmmoCount("ar2")
end

att.UBGL_Fire = function(wep, ubgl)
    wep.Owner:FireBullets({
        Src = wep.Owner:EyePos(),
        Num = 1,
        Damage = 0,
        Force = 0,
        Attacker = wep.Owner,
        Dir = wep.Owner:EyeAngles():Forward(),
        Callback = function(_, tr, dmg)
            local ent = tr.Entity
            local dist = (tr.HitPos - tr.StartPos):Length() * ArcCW.HUToM
            local dmgmax = 25
            local dmgmin = 1
            local delta = dist / 5
            delta = math.Clamp(delta, 0, 1)
            local amt = Lerp(delta, dmgmax, dmgmin)

            ent:SetHealth(math.Clamp(ent:Health() + (amt), 10, (ent:GetMaxHealth() * 1.5)))
        end
    })

    wep:EmitSound("masita/perks/combatheal_var_08.mp3", 100)

end

att.UBGL_Reload = function(wep, ubgl)
    if wep:Clip2() >= 1 then return end

    if Ammo(wep) <= 0 then return end

    local reserve = Ammo(wep)

    reserve = reserve + wep:Clip2()

    local clip = 1

    local load = math.Clamp(clip, 0, reserve)

    wep.Owner:SetAmmo(reserve - load, "pistol")

    wep:SetClip2(load)
end