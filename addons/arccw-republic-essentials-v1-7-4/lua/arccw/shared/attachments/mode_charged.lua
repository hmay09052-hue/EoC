att.PrintName = "Charged Mode"
att.Icon = Material("entities/arccw/kraken/atts/charged2.png")
att.Description = "Set the weapon mode to charged shot. Designed for pistols. It will greatly improve its performance at long range, but it loses proficiency at short range."

att.Slot = "sw_mode_pistol"

att.Override_MuzzleEffect = "arccw_kraken_sw_muzzle_red"
att.Override_Tracer = "new_tracer_red"
att.Override_DamageType = DMG_BLAST
att.Override_AmmoPerShot = 3
att.Mult_RPM = 0.7
att.MuzzleFlashColor = Color(250, 0, 0)

att.Desc_Pros = {}
att.Desc_Cons = {}

att.NotForNPCs = true
att.AutoStats = true