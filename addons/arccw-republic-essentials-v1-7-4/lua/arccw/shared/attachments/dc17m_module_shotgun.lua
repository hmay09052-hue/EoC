att.PrintName = "DC-17m Shotgun Module"
att.Icon = Material("entities/arccw/kraken/atts/dc17m_shotgunmodule.png")
att.Description = "Switches the DC-17m barrel to the anti-personnel shotgun configuration. Fires 9 energy pellets per shot in a tight spread pattern with devastating close-range power."

att.Desc_Pros = {}
att.Desc_Cons = {}

att.AutoStats = true
att.NotForNPCs = true
att.Slot = "dc17m_barrel"
att.SortOrder = 1
att.ActivateElements = {"dc17m_shotgun"}

att.OverrideClipSize = 20
att.Override_Num = 9
att.Override_DamageType = DMG_BUCKSHOT
att.Override_NoRandSpread = true
att.Override_CanBash = true
att.Override_Firemodes = {
    { Mode = 1 },
    { Mode = 0 },
}

att.Override_ShotgunSpreadPattern = {
    [1] = Angle(0, 0, 0),
    [2] = Angle(0, 1, 0),
    [3] = Angle(0, -1, 0),
    [4] = Angle(2.1, 0, 0),
    [5] = Angle(-2.1, 0, 0),
    [6] = Angle(1.4, 1.2, 0),
    [7] = Angle(-1.4, 1.2, 0),
    [8] = Angle(1.4, -1.2, 0),
    [9] = Angle(-1.4, -1.2, 0),
}

att.Override_IronSightStruct = {
    Pos = Vector(-6.498, -10.992, 0.6),
    Ang = Vector(-1.846, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
    ViewModelFOV = 55,
}

att.Mult_Damage = 0.375
att.Mult_DamageMin = 0.667
att.Mult_Range = 0.5

att.Mult_RPM = 0.3

att.Mult_Recoil = 3.385
att.Mult_RecoilSide = 2.857

att.Mult_HipDispersion = 0.5
att.Mult_MoveDispersion = 0.5

att.Hook_GetShootSound = function(wep, sound)
    if wep:GetBuff_Override("Silencer") then return end
    return "ArcCW_Kraken.SW_DP23"
end

att.Hook_GetDistantShootSound = function(wep, sound)
    if wep:GetBuff_Override("Silencer") then return end
    return "ArcCW_Kraken.SW_DP23_Distant"
end
