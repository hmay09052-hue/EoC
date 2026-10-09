GRNArcCW = GRNArcCW or {}
GRNArcCW.Config = GRNArcCW.Config or {}
local C = GRNArcCW.Config

-- =========================================================
-- ArcCW-Aufsätze (Echoes of Clones)
-- Ersetzt das ArcCW-Anpassungsmenü (Taste C) durch ein Menü im
-- Server-Design und lässt nur die unten freigegebenen Aufsätze zu.
-- =========================================================

-- Eigenes Menü statt des ArcCW-Standardmenüs verwenden.
C.ReplaceCustomizeMenu = true

-- Nur Aufsätze aus C.Whitelist dürfen angebracht werden. Bereits ab Werk
-- verbaute Teile einer Waffe bleiben dran, können aber nach dem Abnehmen
-- nicht wieder angebracht werden, wenn sie nicht freigegeben sind.
C.EnforceWhitelist = true

-- Schusslog (Server): data/eoc_arccw/schusslog_JJJJ-MM-TT.txt
C.ShotLog = {
    Enabled = true,
    FlushInterval = 30,       -- Sekunden: Schüsse/Treffer gesammelt schreiben
    LogAttachments = true,    -- Aufsätze an/ab mitschreiben
    PrintToConsole = false,   -- zusätzlich in die Serverkonsole
    RecentLines = 300,        -- im Speicher für "eoc_schusslog"
    ShowLines = 40,
    AdminGroups = { superadmin = true, admin = true },
}

-- UI-Sounds ("" = aus)
C.Sounds = {
    open = "weapons/arccw/extra.wav",
    close = "weapons/arccw/extra2.wav",
    click = "ui/buttonclick.wav",
    hover = "ui/buttonrollover.wav",
    equip = "",
    error = "items/medshotno1.wav",
}

-- Admins dürfen auch nicht freigegebene Aufsätze anbringen.
C.AdminsBypassWhitelist = false

-- Abdunkelung links/rechts. Die Mitte bleibt frei, damit die Waffe im
-- Viewmodel sichtbar ist.
C.SidePanelWidth = 0.27

-- Freigegebene Aufsätze (Kurzname = Dateiname in lua/arccw/shared/attachments).
-- Stand: Kraken ArcCW-Pakete, die auf dem Server laufen.
C.Whitelist = {
    -- empire-essentials
    "a280_barrel_long",
    "a280_stock_carbine",
    "ammo_extended",
    "ammo_gl_bacta",
    "ammo_gl_dioxis",
    "ammo_gl_impact",
    "ammo_gl_smoke",
    "ammo_greentibanna",
    "ammo_heatbased",
    "ammo_highexplosive",
    "ammo_hitscan",
    "ammo_orangetibanna",
    "ammo_purpletibanna",
    "dc15ai_stock",
    "dc17m_mag_drum",
    "dc17m_mag_extended",
    "dc17m_sniper_mag_extended",
    "dh17_stock",
    "dlt19_bipod",
    "dlt19_iron_long",
    "dlt19_iron_short",
    "dlt19h_iron_long",
    "dlt19h_iron_short",
    "dlt19x_iron_long",
    "dlt19x_iron_short",
    "e11_flashlight",
    "e11_freezer",
    "e11_powercell_large",
    "e11_powerpack",
    "e11_splitter",
    "e11_stock_complete",
    "e11_stock_extended",
    "e11_stock_short",
    "e11_supressor",
    "perk_deathtrooper_training",
    "perk_fortheempire",
    "perk_purgetrooper_training",
    "perk_scouttrooper_training",
    "perk_stormtrooper_training",
    "tl50_muzzle_long",
    "tl50_muzzle_repeater",
    "valken38_bipod",
    -- krakens-explosives
    "ammunition_ap",
    "ammunition_cluster",
    "ammunition_heat",
    "ammunition_heatfs",
    "ammunition_track",
    "mode_g125",
    -- republic-essentials
    "arccw_k_dc15a_scope_ir",
    "arccw_k_dc15x_scope_ir",
    "arccw_k_dc17m_scope",
    "arccw_k_dlt15a_scope",
    "arccw_k_dlt15x_scope",
    "arccw_k_e5s_scope",
    "arccw_k_e5s_scope_ir",
    "arccw_k_valken38_scope",
    "arccw_k_valken38_scope_ir",
    "arccw_k_westarm5_scope",
    "arccw_k_westarm5_scope_ir",
    "b2_rocket",
    "dc17_cooling",
    "dc17_module",
    "dc17_powerpack",
    "dc17m_module_launcher",
    "dc17m_module_shotgun",
    "dc17m_module_sniper",
    "mode_at",
    "mode_charged",
    "mode_heatbased",
    "mode_le",
    "mode_overcharged",
    "mode_overpressure",
    "mode_scatter",
    "mode_scatter_pistol",
    "mode_supersonic",
    "perk_cloneairborne",
    "perk_clonearc",
    "perk_clonearf",
    "perk_clonebarc",
    "perk_clonemedic",
    "perk_clonetrooper",
    "perk_comando",
    "ubgl_dc15",
    "universal_vibroknife",
    "valken38_sling",
    -- special-forces
    "a180_barrel_extended",
    "a180_grip",
    "a280cfe_barrel_short",
    "a280cfe_barrel_sniper",
    "a280cfe_powerpack",
    "a280cfe_stock_assault",
    "a280cfe_stock_heavy",
    "bipod_specialforces",
    "perk_masita_berserker",
    "perk_masita_commando",
    "perk_masita_demolition",
    "perk_masita_firebug",
    "perk_masita_gunslinger",
    "perk_masita_medic",
    "perk_masita_sharpshooter",
    "perk_masita_support",
    "rx21_powerpack",
    "sops_ubgl_grapple_hook",
    "wepcamo_asimov",
    "wepcamo_camo",
    "wepcamo_digital",
    "wepcamo_disarray",
    "wepcamo_hyper",
    "wepcamo_tiger",
    "wepcamo_uk",
    "wepcamo_us",
}

-- Anzeigenamen der Slot-Kategorien im Menü (Schlüssel = ArcCW-Slotname).
-- Nicht aufgeführte Slots zeigen den Namen aus der Waffe.
C.SlotIcons = {
    optic = "fa-crosshairs",
    kraken_holohud = "fa-crosshairs",
    ammo = "fa-battery-three-quarters",
    ammo_rocket = "fa-bomb",
    k_rocket_ammo = "fa-rocket",
    perk = "fa-medal",
    rep_vibrocamo = "fa-palette",
    vibroknife = "fa-khanda",
    sw_sling = "fa-link",
}

C.SlotIconPatterns = {
    { "scope", "fa-crosshairs" },
    { "iron", "fa-crosshairs" },
    { "optic", "fa-crosshairs" },
    { "mode", "fa-sliders" },
    { "stock", "fa-grip-lines" },
    { "grid", "fa-grip-lines" },
    { "barrel", "fa-ruler-horizontal" },
    { "muzzle", "fa-wind" },
    { "mag", "fa-battery-three-quarters" },
    { "powerpack", "fa-battery-full" },
    { "powercell", "fa-battery-full" },
    { "bipod", "fa-person-rifle" },
    { "grip", "fa-hand" },
    { "ubgl", "fa-bomb" },
    { "grapple", "fa-anchor" },
    { "module", "fa-microchip" },
    { "cooling", "fa-snowflake" },
}
