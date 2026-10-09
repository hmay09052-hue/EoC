att.PrintName = "WESTAR-M5 Scope (x4)"
att.Icon = Material("entities/arccw/kraken/atts/m5scope.png", "mips smooth")
att.Description = "Long range sniper optic. Used by the WESTAR-M5  Blaster models."

att.Desc_Pros = {
    "autostat.holosight",
    "autostat.zoom",
}
att.Desc_Cons = {
}
att.AutoStats = true
att.Slot = "optic"

att.Model = "models/arccw/kraken/republic/atts/westarm5_scope.mdl"

att.AdditionalSights = {
    {
        Pos = Vector(0, 12, -1.15),
        Ang = Angle(0, 0, 0),
        Magnification = 2,
        IgnoreExtra = true
    },
}

att.ModelOffset = Vector(1, 0, 0)
att.ModelScale = Vector(0.8, 0.8, 0.8)

att.Holosight = true
att.HolosightReticle = Material("miras/x2_universal.png", "mips smooth")
att.HolosightNoFlare = true
att.HolosightSize = 6.5
att.HolosightBone = "holosight"
att.HolosightPiece = "models/arccw/kraken/republic/atts/westarm5_scope_hsp.mdl"

att.Colorable = true
att.HolosightBlackbox = false

att.HolosightMagnification = 2

att.Mult_SightTime = 1.2
att.Mult_SpeedMult = 0.925