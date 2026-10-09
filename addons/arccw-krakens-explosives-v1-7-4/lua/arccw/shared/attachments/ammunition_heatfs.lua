att.PrintName = "HEAT-FS Projectile"
att.Description = "HEAT-FS (High Explosive Anti-Tank Fin-Stabilized) rounds are designed to penetrate armored vehicles. They use a shaped charge that focuses an explosive blast on a small point to melt through the armor, allowing the round to disable or destroy the target. The 'FS' indicates that the round is fin-stabilized, helping it maintain accuracy during flight."
att.Icon = Material("entities/kraken/heatfs_ammo.png")

att.AutoStats = true
att.Slot = "k_rocket_ammo"

att.Override_ShootEntity = "arccw_rocket_heatfs"