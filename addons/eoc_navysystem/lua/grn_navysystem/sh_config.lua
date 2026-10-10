GRN_NAVY = GRN_NAVY or {}
GRN_NAVY.Config = GRN_NAVY.Config or {}
local C = GRN_NAVY.Config

-- ─────────────────────────────────────────────
--  Language setting
--  Options: "en" (English), "es" (Spanish),
--           "pt" (Portuguese), "fr" (French),
--           "de" (German)
-- ─────────────────────────────────────────────
C.Language = "en"

C.UseMySQL = false
C.MySQL = {
    Host = "127.0.0.1",
    Port = 3306,
    Database = "gmod",
    Username = "root",
    Password = ""
}

C.StaffGroups = {
    ["superadmin"] = true,
    ["admin"] = true,
    ["moderator"] = true,
    ["eventmaster"] = true,
    ["SuperAdmin"] = true,
    ["Admin"] = true,
    ["Moderator"] = true,
    ["EventMaster"] = true,
}

C.Commands = {
    Navy = {"!navy", "/navy"},
    Whitelist = {"!whitelistnavy", "/whitelistnavy"}
}

C.Teams = {
    republic = { key = "republic", nameKey = "team_republic", name = "Republic", aiTeam = 1, color = Color(70, 160, 255) },
    cis      = { key = "cis",      nameKey = "team_cis",      name = "Separatists", aiTeam = 2, color = Color(255, 90, 90) },
}

C.CapitalShips = {
    republic = {
        { id = "venator",    name = "Venator",    class = "aura_lvs_venator_mk2",    max = 2, bombRadius = 5000, bombRange = 16000, moveSpeed = 550 },
        { id = "arquitens",  name = "Arquitens",  class = "aura_lvs_arquitens",      max = 3, bombRadius = 3500, bombRange = 12000, moveSpeed = 650 },
        { id = "acclamator", name = "Acclamator", class = "aura_lvs_acclamator_mk2", max = 2, bombRadius = 4200, bombRange = 14000, moveSpeed = 600 },
    },
    cis = {
        { id = "munificent", name = "Munificent", name2 = "Munificent", class = "aura_lvs_munificent_mk2", max = 3, bombRadius = 3800, bombRange = 13000, moveSpeed = 620 },
        { id = "providence", name = "Providence", class = "aura_lvs_providence_mk2", max = 2, bombRadius = 5000, bombRange = 16000, moveSpeed = 560 },
    }
}

C.Fighters = {
    republic = {
        { id = "arc170", name = "ARC-170", class = "lvs_starfighter_arc170", max = 8 },
        { id = "vwing", name = "V-Wing", class = "lvs_starfighter_vwing", max = 10 },
        { id = "laat", name = "LAAT/i", class = "lvs_repulsorlift_gunship", max = 4 },
        { id = "nbt630", name = "NBT-630", class = "lvs_starfighter_nbt630", max = 6 },
    },
    cis = {
        { id = "trifighter", name = "Tri-Fighter", class = "lvs_starfighter_droidtrifighter", max = 10 },
        { id = "vulture", name = "Vulture Droid", class = "lvs_starfighter_vulturedroid", max = 12 },
        { id = "hyena", name = "Hyena Bomber", class = "lvs_starfighter_hyenabomber", max = 6 },
        { id = "hmp", name = "Droid Gunship", class = "lvs_gunship_hmp", max = 4 },
    }
}

C.Supplies = {
    republic = {
        {
            id = "ammo",
            nameKey = "supply_ammo",
            name = "Ammo Crate",
            class = "lvs_item_ammocrate",
            max = 8,
            viaTransport = true,
        },
        {
            id = "repair",
            nameKey = "supply_repair",
            name = "Repair",
            class = "lvs_vehicle_repair",
            max = 6,
            viaTransport = true,
        },
        {
            id = "airrefill",
            nameKey = "supply_airrefill",
            name = "Air Resupply",
            class = "lvs_vehicle_air_refil",
            max = 6,
            viaTransport = true,
        },
        {
            id = "laatc_atte",
            nameKey = "supply_laat_atte",
            name = "LAAT/C with AT-TE",
            class = "lvs_walker_atte",
            max = 2,
            viaTransport = true,
            isVehicle = true,
            transport = {
                model = "models/blu/laat_c.mdl",
                modelScale = 1,
                cruiseAltitude = 2200,
                landingHeight = 180,
                speed = 1600,
                exitSpeed = 2000,
                groundTime = 6,
                hasHealth = true,
                maxHealth = 3500,
                payloadOffset = Vector(0,0,0),
                payloadAngles = Angle(0,0,0),
                arrivalSound = "laat_bf2/boost_1.wav",
                flightSound = "laat_bf2/engine_loop.mp3",
                landingSound = "lvs/vehicles/laat/landing.wav",
                hoverSound = "lvs/vehicles/laat/loop.wav",
                takeoffSound = "laat_bf2/takeoff_1.wav",
                departSound = "laat_bf2/laat_loop.wav",
            }
        },
    },
    cis = {
        {
            id = "ammo",
            nameKey = "supply_ammo",
            name = "Ammo Crate",
            class = "lvs_item_ammocrate",
            max = 8,
            viaTransport = true,
        },
        {
            id = "repair",
            nameKey = "supply_repair",
            name = "Repair",
            class = "lvs_vehicle_repair",
            max = 6,
            viaTransport = true,
        },
        {
            id = "airrefill",
            nameKey = "supply_airrefill",
            name = "Air Resupply",
            class = "lvs_vehicle_air_refil",
            max = 6,
            viaTransport = true,
        },
    }
}



C.EscapePods = {
    republic = {
        { id = "escapepod", nameKey = "pod_escapepod", name = "Escape Pod", class = "lvs_cgi_escapepod", max = 8, maxPlayers = 5, speed = 2400, landOffset = 70 },
    },
    cis = {
        { id = "escapepod", nameKey = "pod_escapepod", name = "Escape Pod", class = "lvs_cgi_escapepod", max = 8, maxPlayers = 5, speed = 2400, landOffset = 70 },
    }
}

C.Destruction = {
    Enabled = true,
    TriggerHealth = 1,
    Length = 12,
    ExplosionSize = 4,
    FinalSize = 12,
    Flip = 0,
    TurnRate = 2.2,
    FallRate = 38,
    ForwardRate = 32,
}

C.TransportDefaults = {
    republic = {
        class = "grn_navy_transport",
        model = "models/blu/laat.mdl",
        modelScale = 1,
        cruiseAltitude = 2200,
        landingHeight = 120,
        speed = 1600,
        exitSpeed = 2000,
        groundTime = 5,
        collision = false,
        hasHealth = true,
        maxHealth = 3000,
        arrivalSound = "laat_bf2/boost_1.wav",
        flightSound = "laat_bf2/engine_loop.mp3",
        landingSound = "lvs/vehicles/laat/landing.wav",
        hoverSound = "lvs/vehicles/laat/loop.wav",
        takeoffSound = "laat_bf2/takeoff_1.wav",
        departSound = "laat_bf2/laat_loop.wav",
    },
    cis = {
        class = "grn_navy_transport",
        model = "models/salty/cis-hmp-gunship.mdl",
        modelScale = 0.6,
        cruiseAltitude = 2000,
        landingHeight = 150,
        speed = 1800,
        exitSpeed = 2200,
        groundTime = 5,
        collision = false,
        hasHealth = true,
        maxHealth = 2000,
        arrivalSound = "lvs/vehicles/laat/flyby3.wav",
        flightSound = "lvs/vehicles/rho_class/eng_tone.mp3",
        landingSound = "lvs/vehicles/rho_class/shutdown.wav",
        hoverSound = "hmp/hmp_gunship_engineidleing.wav",
        takeoffSound = "hmp/throttlepunch_6.mp3",
        departSound = "hmp/hmp_gunship_engineidleing.wav",
    }
}

C.RTS = {
    MoveTick = 0.05,
    SelectDistance = 200000,
    DefaultHeight = 3000,
    MinHeight = 900,
    MaxHeight = 12000,
    PanSpeed = 32,
    RotateStep = 2,
    EdgeScroll = 12,
    ExitModeKey = KEY_O,
    ZoomStep = 250,
    ShipTurnRate = 10,
    ShipAcceleration = 120,
    FighterSpawnOffset = Vector(0, 0, -700),
    FighterFacingOffset = Angle(0, 180, 0),
    SupplySpawnOffset = Vector(0, 0, -1000),
    SupplyFacingOffset = Angle(0, 180, 0),
    EscapePodSpawnOffset = Vector(0, 0, -500),
    EscapePodFacingOffset = Angle(0, 180, 0),
}

C.PersistenceTable = "grn_navy_whitelist"
