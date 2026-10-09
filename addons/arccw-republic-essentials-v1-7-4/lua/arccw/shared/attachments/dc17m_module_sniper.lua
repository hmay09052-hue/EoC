att.PrintName = "DC-17m Sniper Module"
att.Icon = Material("entities/arccw/kraken/atts/dc17m_snipermodule.png")
att.Description = "Switches the DC-17m barrel to the long-range sniper configuration. Fires extremely powerful single shots with limited ammunition and no overheat fix."

att.Desc_Pros = {}
att.Desc_Cons = {}

att.AutoStats = true
att.NotForNPCs = true
att.Slot = "dc17m_barrel"
att.SortOrder = 2
att.ActivateElements = {"dc17m_sniper"}

att.OverrideClipSize = 5
att.Override_Firemodes = {
    { Mode = 1 },
    { Mode = 0 },
}
att.Override_Tracer = "railgun_tracer_blue"
att.Override_HeatFix = false

att.Override_ActivePos = Vector(-2, 0, -1)

att.Mult_Damage = 2.042
att.Mult_DamageMin = 6.333
att.Mult_Range = 1.5

att.Mult_RPM = 0.2

att.Mult_Recoil = 2.769
att.Mult_RecoilSide = 4.286

att.Mult_HipDispersion = 0.5

att.Hook_GetCapacity = function(wep, cap)
    return 5
end

att.Mult_HeatCapacity = 0.2

att.Add_BarrelLength = 15

att.Hook_TranslateAnimation = function(wep, anim)
    if anim == "fire_iron" then
        return "fire"
    end
end

att.Hook_GetShootSound = function(wep, sound)
    if wep:GetBuff_Override("Silencer") then return end
    return "ArcCW_Kraken.SW_DC17M_SNIPER"
end

att.Hook_GetDistantShootSound = function(wep, sound)
    if wep:GetBuff_Override("Silencer") then return end
    return "ArcCW_Kraken.SW_DC17M_SNIPER_Distant"
end
