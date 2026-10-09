att.PrintName = "Long Engagements Mode"
att.Icon = Material("entities/arccw/kraken/atts/le_mode.png")
att.Description = "Set the weapon mode to long range. It will greatly improve its performance at long range, but it loses proficiency at short range."

att.Slot = "sw_mode_rifle"

att.Override_MuzzleEffect = "arccw_kraken_sw_muzzle_red"
att.Override_Tracer = "new_tracer_red"
att.Override_DamageType = DMG_BLAST
att.Override_AmmoPerShot = 5
att.Mult_RPM = 1.5

att.Mult_DamageMin = 0.4
att.Mult_Recoil = 2
att.Mult_RecoilSide = 1.2
att.Mult_VisualRecoilMult = 1.2

att.MuzzleFlashColor = Color(250, 0, 0)

att.Desc_Pros = {}
att.Desc_Cons = {}

att.NotForNPCs = true
att.AutoStats = true
