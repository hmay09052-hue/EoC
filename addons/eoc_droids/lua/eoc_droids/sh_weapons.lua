-- Waffen der Droiden. Die Droiden schiessen selbst (kein extra Waffen-Entity pro Droide),
-- das Waffenmodell wird nur clientseitig an die Hand gezeichnet. Das spart viele Entities.
--
-- Damage     Schaden pro Projektil
-- Bullets    Projektile pro Schuss
-- Delay      Sekunden zwischen zwei Schuessen
-- Burst      Schuesse pro Salve (nil = Dauerfeuer), BurstPause = Pause nach der Salve
-- Clip       Magazin, Reload = Nachladezeit
-- Spread     Streuung
-- Color      Laserfarbe: red, blue, green, yellow, cyan, purple, orange
-- Models     Weltmodelle, das erste vorhandene wird genutzt (letztes = HL2-Ersatz, immer vorhanden)
--            Models mit ValveBiped-Knochen werden per Bonemerge in die Hand gesetzt,
--            andere ueber Offset/AngOffset relativ zur rechten Hand
-- HoldType   "smg", "pistol", "shotgun" oder "melee" (waehlt die passenden Animationen)

EOCDroids.Weapons = {
    e5 = {
        Damage = 11, Bullets = 1, Delay = 0.32, Burst = 4, BurstPause = 0.7,
        Clip = 24, Reload = 2.4, Spread = 0.025, Color = "red", TracerScale = 1,
        Sound = "w/e5.wav", FallbackSound = "weapons/ar2/fire1.wav",
        Models = { "models/kuro/sw_battlefront/weapons/e5_blaster.mdl", "models/weapons/w_irifle.mdl" },
    },
    e5_heavy = {
        Damage = 9, Bullets = 1, Delay = 0.09, Burst = 14, BurstPause = 1.1,
        Clip = 70, Reload = 3.6, Spread = 0.05, Color = "red", TracerScale = 1.1,
        Sound = "w/e5.wav", FallbackSound = "weapons/ar2/fire1.wav",
        Models = { "models/kuro/sw_battlefront/weapons/e5c_blaster.mdl", "models/kuro/sw_battlefront/weapons/e5_blaster.mdl", "models/weapons/w_irifle.mdl" },
    },
    e5_sniper = {
        Damage = 70, Bullets = 1, Delay = 3.2, Clip = 5, Reload = 3,
        Spread = 0, Color = "red", TracerScale = 1.8, ChargeTime = 1.4,
        Sound = "w/e5.wav", FallbackSound = "weapons/ar2/npc_ar2_altfire.wav",
        Models = { "models/kuro/sw_battlefront/weapons/e5_blaster.mdl", "models/weapons/w_irifle.mdl" },
    },
    e5_bx = {
        Damage = 12, Bullets = 1, Delay = 0.2, Burst = 5, BurstPause = 0.5,
        Clip = 25, Reload = 2, Spread = 0.03, Color = "yellow", TracerScale = 1,
        Sound = "weapons/e5_commando_blaster/e5_commando_fire.ogg", FallbackSound = "weapons/ar2/fire1.wav",
        Models = { "models/kuro/sw_battlefront/weapons/e5_blaster.mdl", "models/weapons/w_irifle.mdl" },
    },
    rg4d = {
        Damage = 10, Bullets = 1, Delay = 0.45, Clip = 12, Reload = 1.8,
        Spread = 0.03, Color = "red", TracerScale = 0.9,
        Sound = "w/e5.wav", FallbackSound = "weapons/pistol/pistol_fire2.wav",
        Models = { "models/kuro/sw_battlefront/weapons/rg4d_blaster.mdl", "models/weapons/w_pistol.mdl" },
        HoldType = "pistol",
    },
    shotgun = {
        HoldType = "shotgun",
        Damage = 8, Bullets = 7, Delay = 1.0, Clip = 6, Reload = 3,
        Spread = 0.085, Color = "orange", TracerScale = 0.9,
        Sound = "w/e5.wav", FallbackSound = "weapons/shotgun/shotgun_fire6.wav",
        Models = { "models/kuro/sw_battlefront/weapons/e5c_blaster.mdl", "models/kuro/sw_battlefront/weapons/e5_blaster.mdl", "models/weapons/w_irifle.mdl" },
    },
    b2_wrist = {
        Damage = 12, Bullets = 1, Delay = 0.16, Burst = 8, BurstPause = 0.8,
        Clip = 40, Reload = 2.8, Spread = 0.045, Color = "red", TracerScale = 1.3,
        Sound = "w/e5.wav", FallbackSound = "weapons/ar2/fire1.wav",
    },
    droideka = {
        Damage = 14, Bullets = 2, Delay = 0.22, Burst = 10, BurstPause = 0.9,
        Clip = 40, Reload = 2.5, Spread = 0.06, Color = "red", TracerScale = 1.3,
        Sound = "w/e5.wav", FallbackSound = "weapons/ar2/fire1.wav",
    },
    crab = {
        Damage = 9, Bullets = 2, Delay = 0.2, Burst = 8, BurstPause = 0.8,
        Clip = 40, Reload = 2.5, Spread = 0.07, Color = "red", TracerScale = 1.2,
        Sound = "w/e5.wav", FallbackSound = "weapons/ar2/fire1.wav",
    },
    aqua = {
        Damage = 9, Bullets = 3, Delay = 0.14, Burst = 6, BurstPause = 0.8,
        Clip = 40, Reload = 2.5, Spread = 0.08, Color = "red", TracerScale = 1.2,
        Sound = "summe/nextbots/weapons/cannons_eweb_laser_close_var_04.mp3", FallbackSound = "weapons/ar2/fire1.wav",
    },
    magnastaff = {
        Melee = true,
        Models = { "models/tfa/comm/gg/prp_magna_guard_weapon_combined.mdl", "models/weapons/w_stunbaton.mdl" },
        HoldType = "melee",
        Glow = Color(255, 50, 193),
    },
    vibroblade = {
        Melee = true,
        HoldType = "melee",
        Models = { "models/weapons/w_crowbar.mdl" },
        Glow = Color(255, 140, 40),
    },
}

-- Laserfarben fuer den Tracer-Effekt (Index wird ueber das Netzwerk geschickt)
EOCDroids.LaserColors = {
    [1] = Color(255, 45, 45),     -- red
    [2] = Color(70, 140, 255),    -- blue
    [3] = Color(60, 255, 90),     -- green
    [4] = Color(255, 215, 40),    -- yellow
    [5] = Color(40, 235, 255),    -- cyan
    [6] = Color(215, 60, 255),    -- purple
    [7] = Color(255, 140, 30),    -- orange
}

EOCDroids.LaserColorIds = {
    red = 1, blue = 2, green = 3, yellow = 4, cyan = 5, purple = 6, orange = 7,
}
