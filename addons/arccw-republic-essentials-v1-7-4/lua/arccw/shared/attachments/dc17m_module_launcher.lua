att.PrintName = "DC-17m Launcher Module"
att.Icon = Material("entities/arccw/kraken/atts/dc17m_launchermodule.png")
att.Description = "Switches the DC-17m barrel to the anti-armor grenade launcher configuration. Fires explosive 40mm grenades with devastating area-of-effect damage."

att.Desc_Pros = {}
att.Desc_Cons = {}

att.AutoStats = true
att.NotForNPCs = true
att.Slot = "dc17m_barrel"
att.SortOrder = 3
att.ActivateElements = {"dc17m_launcher"}

att.OverrideClipSize = 1
att.Override_ShootEntity = "arccw_atfire_dc17m"
att.Override_Ammo = "ar2"

att.Override_HeatFix = false

att.Override_Firemodes = {
    { Mode = 1 },
    { Mode = 0 },
}

att.Override_MuzzleEffect = "muzzleflash_m82"
att.Override_MuzzleFlashColor = Color(224, 166, 59)

att.Override_TracerCol = Color(80, 98, 255)
att.Override_TracerNum = 1
att.Mult_TracerWidth = 1

att.Override_ActivePos = Vector(-2, 0, -1)

att.Mult_RPM = 0.2

att.Mult_Recoil = 6.154
att.Mult_RecoilSide = 4.286

att.Mult_HipDispersion = 0.5

att.Hook_TranslateAnimation = function(wep, anim)
    if anim == "fire" or anim == "fire_iron" then
        return "fire_at"
    end
    if anim == "reload" then
        return "fix"
    end
end

att.Hook_GetShootSound = function(wep, sound)
    if wep:GetBuff_Override("Silencer") then return end
    return "arccw/rep_ubgl/gl_fire.ogg"
end

att.Hook_GetDistantShootSound = function(wep, sound)
    if wep:GetBuff_Override("Silencer") then return end
    return "arccw/rep_ubgl/gl_fire_dist.ogg"
end
