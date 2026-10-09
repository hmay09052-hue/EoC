EOCDroids.Config = EOCDroids.Config or {}
local C = EOCDroids.Config

-- ============================================================
-- ALLGEMEIN
-- ============================================================
C.Category = "EoC Droiden"             -- Kategorie im Spawnmenue (Entities + NPCs)
C.AdminOnlySpawn = true                -- Droiden nur fuer Admins im Spawnmenue
C.ToolAdminOnly = true                 -- Pod-/Dispenser-/No-Target-Tool nur fuer Admins
C.MaxDroids = 80                       -- Maximale Anzahl gleichzeitig aktiver Droiden
C.MaxPerType = 15                      -- Max. Droiden pro Typ in einem Pod/Dispenser
C.MaxPerDeployer = 40                  -- Max. Droiden insgesamt in einem Pod/Dispenser

-- Darf ein Spieler mit Tools Droiden einsetzen? (Standard: Admins)
function C.CanUseTools(ply)
    if not IsValid(ply) then return false end
    if not C.ToolAdminOnly then return true end
    return ply:IsAdmin()
end

-- ============================================================
-- KAMPF
-- ============================================================
C.DamageMultiplier = 1                 -- Schaden der Droiden (1 = Standard)
C.HealthMultiplier = 1                 -- Leben der Droiden (1 = Standard)
C.FriendlyFire = false                 -- Droiden verletzen sich gegenseitig
C.Headshots = true                     -- Kopftreffer machen mehr Schaden
C.HeadshotMultiplier = 2
C.GrenadeDamage = 90
C.GrenadeRadius = 280
C.RocketDamage = 85
C.RocketRadius = 220

-- ============================================================
-- KI / ZIELE
-- ============================================================
C.AIInterval = 0.15                    -- Wie oft die KI "denkt" (Sekunden)
C.EnemySearchInterval = 0.5            -- Wie oft nach neuen Zielen gesucht wird
C.AISleepDistance = 5000               -- Kein Spieler in dieser Distanz -> KI schlaeft (spart Leistung)
C.AlertRadius = 900                    -- Droiden warnen Verbuendete in diesem Radius vor Gegnern
C.LoseTargetTime = 8                   -- Sekunden ohne Sichtkontakt bis das Ziel vergessen wird
C.Wander = true                        -- Droiden patrouillieren ohne Ziel
C.IgnoreNoclip = true                  -- Spieler im Noclip werden ignoriert
C.CanOpenDoors = true                  -- Droiden oeffnen Tueren
C.OpenLockedDoors = false              -- Auch verschlossene Tueren (Breacher kann es immer)

-- Spieler in diesen Jobs (team.GetName) werden NICHT angegriffen, z.B. KUS-Jobs
C.IgnoreTeams = {
    -- ["KUS Kommandant"] = true,
}

-- Sollen Droiden auch NPCs/Nextbots (z.B. Klon-NPCs) angreifen?
C.TargetNPCs = true
-- NPC-Klassen, die NIE angegriffen werden
C.FriendlyNPCClasses = {
    ["npc_bullseye"] = true,
}

-- ============================================================
-- OPTIK / SOUND
-- ============================================================
C.ShowNameTags = true                  -- Name + Lebensbalken ueber dem Kopf
C.NameTagDistance = 600
C.DynamicLights = true                 -- Laser, Muendungsfeuer und Einschlaege beleuchten die Umgebung
C.MaxDynamicLights = 12                -- Obergrenze gleichzeitiger Lichter (Leistung)
C.EffectDistance = 3500                -- Ab dieser Distanz keine Licht-/Partikeleffekte
C.ImpactDecals = true
C.Voices = true                        -- Sprachausgabe ("Roger Roger")
C.VoiceCooldown = { 6, 14 }            -- Pause zwischen Sprueche eines Droiden
C.GlobalVoicesPerSecond = 4            -- Max. Sprueche pro Sekunde auf dem ganzen Server
C.RagdollTime = 15
C.JetpackVolume = 0.2                  -- Lautstaerke der Jetpacks (0-1)
C.JetpackSoundLevel = 62               -- Reichweite in dB (niedriger = nur in der Naehe hoerbar)
C.WeaponFallbackModels = true          -- HL2-Waffenmodell nutzen, wenn das Blaster-Model fehlt                     -- Sekunden bis Server-Ragdolls entfernt werden

-- ============================================================
-- POD / DISPENSER
-- ============================================================
C.DeployerSpawnInterval = 3            -- Sekunden zwischen zwei Droiden aus einem Pod/Dispenser
C.DeployerHealth = 1500
C.RemoveEmptyDeployerAfter = 120       -- Leerer Pod/Dispenser verschwindet nach X Sekunden (0 = nie)

C.DispenserModels = {
    "models/props/starwars/vehicles/sbd_dispenser.mdl",
    "models/props/starwars/vehicles/droideka_dispenser.mdl",
    "models/props/starwars/vehicles/bd_dispenser.mdl",
}

-- ============================================================
-- SPAWNLISTE (Tools + NPC-Tab)
-- key = interner Name (nur a-z, 0-9, _), class = Entity-Klasse
-- ============================================================
C.Spawnlist = {
    { key = "b1",          name = "B1 Kampfdroide",              class = "npc_eoc_b1",           model = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl" },
    { key = "b1_officer",  name = "B1 Offiziersdroide",          class = "npc_eoc_b1_officer",   model = "models/npc/b1_battledroids/officer/b1_battledroid_officer.mdl" },
    { key = "b1_heavy",    name = "B1 Schwerer Kampfdroide",     class = "npc_eoc_b1_heavy",     model = "models/npc/b1_battledroids/heavy/b1_battledroid_heavy.mdl" },
    { key = "b1_sniper",   name = "B1 Scharfschuetzendroide",    class = "npc_eoc_b1_sniper",    model = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl" },
    { key = "b1_jetpack",  name = "B1 Jetpack-Droide",           class = "npc_eoc_b1_jetpack",   model = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl" },
    { key = "b1_breacher", name = "B1 Breacher-Droide",          class = "npc_eoc_b1_breacher",  model = "models/npc/b1_battledroids/heavy/b1_battledroid_heavy.mdl" },
    { key = "b2",          name = "B2 Superkampfdroide",         class = "npc_eoc_b2",           model = "models/npc/b2_battledroid/b2_battledroid.mdl" },
    { key = "b2_rocket",   name = "B2-RP Raketen-Superkampfdroide", class = "npc_eoc_b2_rocket", model = "models/npc/b2_battledroid/b2_battledroid.mdl" },
    { key = "b2_jetpack",  name = "B2-X Jetpack-Superkampfdroide", class = "npc_eoc_b2_jetpack", model = "models/npc/b2_battledroid/b2_battledroid.mdl" },
    { key = "bx",          name = "BX Kommandodroide",           class = "npc_eoc_bx",           model = "models/npc/bx100_commando_droid/regular/bx100_commando_droid_regular.mdl" },
    { key = "bx_captain",  name = "BX Kommandodroide Captain",   class = "npc_eoc_bx_captain",   model = "models/npc/bx100_commando_droid/regular/bx100_commando_droid_regular.mdl" },
    { key = "bx_blade",    name = "BX Vibroklingen-Droide",      class = "npc_eoc_bx_vibroblade", model = "models/npc/bx100_commando_droid/regular/bx100_commando_droid_regular.mdl" },
    { key = "droideka",    name = "Droideka",                    class = "npc_eoc_droideka",     model = "models/npc/starwars/droidekas/droideka.mdl" },
    { key = "magnaguard",  name = "IG-100 MagnaGuard",           class = "npc_eoc_magnaguard",   model = "models/tfa/comm/gg/npc_reb_magna_guard_combined.mdl" },
    { key = "crab",        name = "LM-432 Krabbendroide",        class = "npc_eoc_crab",         model = "models/npc/starwars/crabby/crabdroid.mdl" },
    { key = "aqua",        name = "Aqua-Droide",                 class = "npc_eoc_aqua",         model = "models/player/valley/aquadroid/aquadroid.mdl" },
}

-- Debug-Modus fuer alle (Admins koennen ihn per eoc_droids_debug fuer sich umschalten)
C.Debug = false
