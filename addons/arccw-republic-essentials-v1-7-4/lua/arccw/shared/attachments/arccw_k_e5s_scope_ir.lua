att.PrintName = "E-5S Scope (x8/IR)"
att.Icon = Material("entities/arccw/kraken/atts/e5sscope.png", "mips smooth")
att.Description = "Long range sniper optic. Used by the E-5S Blaster models."

att.Desc_Pros = {
    "autostat.holosight",
    "autostat.zoom",
}
att.Desc_Cons = {
}
att.AutoStats = true
att.Slot = "optic"

att.Model = "models/arccw/kraken/cis/atts/e5s_scope.mdl"

att.AdditionalSights = {
    {
        Pos = Vector(0, 7, -1.05),
        Ang = Angle(0, 0, 0),
        Magnification = 4,
        ZoomLevels = 2,
        ZoomSound = "arccw/kraken/interaction/zoom-in.wav",
        IgnoreExtra = true,
        Thermal = true,
        ThermalHighlightColor = Color(255, 50, 50),
        ThermalFullColor = true,
		ThermalNoCC = true,
    },
}

att.ModelOffset = Vector(4, 0, -0.3)

att.Holosight = true
att.HolosightReticle = Material("miras/sniper_republic2.png", "mips smooth")
att.HolosightNoFlare = true
att.HolosightSize = 8
att.HolosightBone = "holosight"
att.HolosightPiece = "models/arccw/kraken/cis/atts/e5s_scope_hsp.mdl"

att.Colorable = true
att.HolosightBlackbox = true

att.HolosightMagnification = 2

att.Mult_SightTime = 1.2
att.Mult_SpeedMult = 0.925