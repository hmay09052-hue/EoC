att.PrintName = "Tri-barrel Launcher"
att.Icon = Material("entities/kraken/g125_mode.png")
att.Description = "Under-barrel tri-barreled projectile launcher. Press USE + RELOAD to switch to launcher mode. Overheats after a full 3-round burst."

att.Slot = "g125_mode"

att.AutoStats = true
att.NotForNPCs = true

att.Desc_Pros = {
    "+ Under-barrel projectile launcher",
}
att.Desc_Cons = {
    "- Requires smg1_grenade ammo",
    "- Overheats after 3-round burst",
}

att.UBGL = true
att.UBGL_PrintName = "Fuel Rod"
att.UBGL_Automatic = false
att.UBGL_ClipSize = 3
att.UBGL_Ammo = "smg1_grenade"
att.UBGL_RPM = 90
att.UBGL_Recoil = 3
att.UBGL_RecoilSide = 1.5
att.UBGL_RecoilRise = 1.2
att.UBGL_BaseAnims = true
att.MuzzleFlashColor = Color(0, 250, 0)

att.UBGL_Fire = function(wep, ubgl)

    local muzzleAttach = wep:LookupAttachment("muzzle") or 0
    ParticleEffectAttach("blaster_muzzle_green", PATTACH_POINT_FOLLOW, wep, muzzleAttach)

    if SERVER then
        wep:FireRocket("arccw_g125_projectile", 2500)
    end

    local pitch = util.SharedRandom("ubgl_pitch", 90, 105)
    wep:EmitSound("kraken/launchers/grenadelauncher/fire1.wav", 120, pitch, 1, CHAN_WEAPON)
    wep:SetClip2(wep:Clip2() - 1)

    if wep:Clip2() <= 0 then
        wep:PlayAnimation("fix", 1, true)
        local cooldown = wep:GetAnimKeyTime("fix") or 2.5
        wep:SetNextSecondaryFire(CurTime() + cooldown)
        wep:SetNextPrimaryFire(CurTime() + cooldown)
    end
end

att.UBGL_Reload = function(wep, ubgl)
    local capacity = 3
    local owner = wep:GetOwner()
    if not IsValid(owner) then return end
    local ammoType = "smg1_grenade"
    local available = owner:GetAmmoCount(ammoType)
    local needed = capacity - wep:Clip2()
    if needed <= 0 or available <= 0 then return end

    wep:PlayAnimation("fix", 1, true)
    local reloadTime = wep:GetAnimKeyTime("fix") or 2.5
    wep:SetNextSecondaryFire(CurTime() + reloadTime)
    wep:SetNextPrimaryFire(CurTime() + reloadTime)

    local amt = math.min(needed, available)
    if SERVER then
        owner:RemoveAmmo(amt, ammoType)
    end
    wep:SetClip2(wep:Clip2() + amt)
end