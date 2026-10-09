att.PrintName = "Clone Medic Training"
att.Icon = Material("entities/arccw/kraken/atts/medic.png")
att.Description = [[The best medics of the whole Republic Clone Army. Their training greatly benefits them at medium and long distances. In addition, they have better control over the heat of their weapon.]]
att.Desc_Pros = {}
att.Desc_Cons = {}
att.Desc_Neutrals = {}
att.Slot = {"perk"}

att.AutoStats = true
att.NotForNPC = true


att.UBGL = true
att.UBGL_PrintName = "Healing Darts"
att.UBGL_Automatic = true
att.UBGL_ClipSize = 25
att.UBGL_Ammo = "ar2"
att.UBGL_RPM = 125
att.UBGL_Recoil = 0.5
att.UBGL_Capacity = 25

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

    wep:EmitSound("ArcCW_Kraken.SW_HEALINGDARTS", 100)

end

att.UBGL_Reload = function(wep, ubgl)
    if wep:Clip2() >= 1 then return end

    if Ammo(wep) <= 0 then return end

    local reserve = Ammo(wep)

    reserve = reserve + wep:Clip2()

    local clip = 1

    local load = math.Clamp(clip, 0, reserve)

    wep.Owner:SetAmmo(reserve - load, "ar2")

    wep:SetClip2(load)
end