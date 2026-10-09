att.PrintName = "VALKEN-38 Scope (x8/IR)"
att.Icon = Material("entities/arccw/kraken/atts/valkenscope.png", "mips smooth")
att.Description = "Long range sniper optic. Used by the VALKEN-38 Blaster models."

att.Desc_Pros = {
    "autostat.holosight",
    "autostat.zoom",
}
att.Desc_Cons = {
}
att.AutoStats = true
att.Slot = "optic"

att.Model = "models/arccw/kraken/republic/atts/valken38_scope.mdl"

att.AdditionalSights = {
    {
        Pos = Vector(0, 12, -1.48),
        Ang = Angle(0, 0, 0),
        Magnification = 4,
        ZoomLevels = 2,
        ZoomSound = "arccw/kraken/interaction/zoom-in.wav",
        IgnoreExtra = true,
        Thermal = true,
        ThermalHighlightColor = Color(50, 50, 255),
        ThermalFullColor = true,
		ThermalNoCC = true,
    },
}

att.ModelOffset = Vector(2, 0, 0)

att.Holosight = true
att.HolosightReticle = Material("miras/sniper_republic2.png", "mips smooth")
att.HolosightNoFlare = true
att.HolosightSize = 9
att.HolosightBone = "holosight"
att.HolosightPiece = "models/arccw/kraken/republic/atts/valken38_hsp.mdl"

att.Colorable = true
att.HolosightBlackbox = true

att.HolosightMagnification = 2

att.Mult_SightTime = 1.2
att.Mult_SpeedMult = 0.925