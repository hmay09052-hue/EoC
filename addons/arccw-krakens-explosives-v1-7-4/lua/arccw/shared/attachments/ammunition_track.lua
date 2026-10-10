att.PrintName = "Trackable Rocket"
att.Description = "A rocket equipped with tracking capabilities, allowing it to follow targets more effectively."
att.Icon = Material("entities/kraken/rocket_saclos.png")

att.AutoStats = true
att.Slot = "k_rocket_ammo"

att.Override_ShootEntity = "arccw_rocket_track"