GRNInventory = GRNInventory or {}
GRNInventory.Config = GRNInventory.Config or {}

local INV = GRNInventory
local C = INV.Config

-- ============================================================
-- ARMOR SYSTEM - ECHOES OF CLONES
-- ============================================================
-- Armor items live in the normal inventory grid. Drag them onto an armor
-- slot (around the character preview) to wear them.
--
-- What armor does:
--   * Armor        -> adds to the player's max armor (filled on spawn)
--   * Health       -> adds to the player's max health (filled on spawn)
--   * DamageReduction -> 0.05 = 5% less incoming damage (capped below)
--   * CarryWeight  -> extra inventory weight capacity in KG
--
-- Visuals: the armor model is bone-merged onto the player. Because the
-- Nevelgrad clothing parts are built for the modular clone base model, the
-- visual part is only drawn on models listed in BaseModels (VisualMode
-- "base_only"). The stats ALWAYS work, on every player model.
-- Echoes of Clones: the jobs use complete player models (501st_trooper_v2,
-- st_ph1_trooper ...), so the visuals are switched off ("never").
C.Armor = {
    -- false = no armor slots in the inventory (HEAD/SHOULDER/CHEST/BACK/HIP hidden).
    Enabled = true,

    -- "base_only" = draw armor models only on BaseModels
    -- "always"    = draw on every player model (may clip on full-armor models)
    -- "never"     = stats only, no visuals (Jobs haben komplette Models)
    VisualMode = "never",

    BaseModels = {
        ["models/nevelgrad/players/clones/base_trooper.mdl"] = true,
    },

    -- Upper limit for the summed DamageReduction of all worn pieces.
    MaxDamageReduction = 0.35,

    -- Damage types that armor reduction ignores (fall damage, drowning...).
    IgnoreDamageTypes = bit.bor(DMG_FALL, DMG_DROWN, DMG_RADIATION),

    -- Armor slots shown around the character. Side = "left" / "right".
    -- Order inside a side follows the order of this list.
    Slots = {
        { ID = "head",     Label = "KOPF",     Side = "left",  Icon = "fa-helmet-safety", Hint = "Helm" },
        { ID = "shoulder", Label = "SCHULTER", Side = "left",  Icon = "fa-shield",        Hint = "Schulterpanzer" },
        { ID = "chest",    Label = "BRUST",    Side = "left",  Icon = "fa-shirt",         Hint = "Brustpanzer" },
        { ID = "back",     Label = "RÜCKEN",   Side = "right", Icon = "fa-suitcase",      Hint = "Rucksack / Jetpack" },
        { ID = "hip",      Label = "HÜFTE",    Side = "right", Icon = "fa-vest",          Hint = "Gürtel / Hüftpanzer" },
    },

    -- Character preview inside the inventory.
    Doll = {
        FOV = 26,
        Yaw = 18,          -- rotation of the character (0 = facing camera)
        Spin = false,      -- slow rotation
        SpinSpeed = 12,
        Sequence = "idle_all_01",
        Margin = 1.26,     -- space around the character (bigger = smaller model)
    },

    -- Rendered item icons (from the item model). Bump the version to force
    -- every client to re-render its cached icons.
    IconVersion = 1,
    IconSize = 128,

    -- Also render icons for weapons that have no IconURL (uses the SWEP world model).
    RenderWeaponIcons = true,

    -- Rüstung aus der Waffenkammer wird direkt angelegt, wenn der passende
    -- Slot noch frei ist (sonst landet sie nur im Inventar).
    AutoEquipFromArmory = true,

    -- Job-Bindung pro Einheit: Präfixe der DarkRP-Job-Commands. Ein Eintrag
    -- passt auf jeden Command, der so beginnt ("501stheavy_" -> 501stheavy_pvt,
    -- 501stheavy_sgt ...). Lore-Charaktere stehen einzeln dabei.
    -- Wird unten bei den Items als AllowedJobs = jobs(UNIT.HEAVY) genutzt.
    UnitJobs = {
        T501  = { "501st_", "501strex", "501stdogma", "501stappo", "501stjesse", "501stecho", "501stfives", "501stkano", "501stcoric" },
        HEAVY = { "501stheavy_", "501sthardcase" },
        ARF   = { "501starf_", "501stboomer" },
        BARC  = { "501stbarc_" },
        AB    = { "501stab_" },
        MED   = { "501stmed_", "501stkix" },
        ENG   = { "501steng_" },
        ST    = { "st_", "stk9_" },
        NAVY  = { "rn", "avp_" },
    },
}

-- ============================================================
-- ARMOR ITEMS
-- ============================================================
-- Fields:
--   Slot            armor slot ID from C.Armor.Slots
--   Model           bone-merged visual model (also used for the icon)
--   Armor / Health / DamageReduction / CarryWeight   (see top of file)
--   Skin, Bodygroups = { [index] = value }  optional, for the visual model
--   AllowedJobs = { ["501st_pvt"] = true }   optional job command whitelist
--   AllowedCategories = { ["501st Elite Legion"] = true } optional
--   IconCamDir = Vector(1, 0.45, 0.2), IconZoom = 1   optional icon camera
local function armor(id, data)
    data.Type = "armor"
    data.Stack = 1
    data.Icon = data.Icon or "fa-shield-halved"
    data.IconURL = data.IconURL or ""
    data.DropModel = data.DropModel or data.Model
    data.IconModel = data.IconModel or data.Model
    data.Rarity = data.Rarity or "uncommon"
    data.Size = data.Size or { W = 1, H = 1 }
    data.Weight = tonumber(data.Weight) or 2
    if isfunction(INV.RegisterItem) then
        INV.RegisterItem(id, data)
    else
        C.Items[id] = data
    end
end

-- Job binding -------------------------------------------------
-- jobs({ "501stheavy_", "501sthardcase" }) -> AllowedJobs table with every
-- DarkRP job command that starts with one of the prefixes. DarkRP creates its
-- jobs after addon autorun, so every table is filled again once RPExtraTeams
-- exists (see the hooks below). A placeholder keeps the table non-empty,
-- because an empty AllowedJobs would mean "every job".
local jobBindings = {}

local function fillJobBinding(binding)
    local list = binding.list
    for command in pairs(list) do list[command] = nil end
    list["__eoc_armor_binding"] = true

    for _, job in pairs(istable(RPExtraTeams) and RPExtraTeams or {}) do
        local command = istable(job) and tostring(job.command or "") or ""
        if command ~= "" then
            for _, prefix in ipairs(binding.prefixes) do
                if string.sub(command, 1, #prefix) == prefix then
                    list[command] = true
                    break
                end
            end
        end
    end
end

local function jobs(...)
    local prefixes = {}
    for _, value in ipairs({ ... }) do
        for _, prefix in ipairs(istable(value) and value or { value }) do
            prefix = tostring(prefix or "")
            if prefix ~= "" then prefixes[#prefixes + 1] = prefix end
        end
    end
    local binding = { prefixes = prefixes, list = {} }
    jobBindings[#jobBindings + 1] = binding
    fillJobBinding(binding)
    return binding.list
end

function INV.RefreshArmorJobBindings()
    for _, binding in ipairs(jobBindings) do fillJobBinding(binding) end
end

hook.Add("PostGamemodeLoaded", "GRNInventory_ArmorJobBindings", INV.RefreshArmorJobBindings)
hook.Add("DarkRPFinishedLoading", "GRNInventory_ArmorJobBindings", INV.RefreshArmorJobBindings)
hook.Add("InitPostEntity", "GRNInventory_ArmorJobBindings", INV.RefreshArmorJobBindings)

local UNIT = C.Armor.UnitJobs or {}
local P = "models/nevelgrad/clothe_parties/clone/"

-- Helmets ----------------------------------------------------
armor("armor_helmet_p1", {
    Name = "Phase-I-Helm",
    Description = "Standardhelm der Phase-I-Klonkrieger.",
    Slot = "head", Model = P .. "helmet/helmet_clone_p1_standart.mdl",
    Icon = "fa-helmet-safety", Rarity = "common",
    Armor = 15, Weight = 2.0, Size = { W = 1, H = 1 },
})

armor("armor_helmet_arf", {
    Name = "ARF-Helm",
    Description = "Helm der Advanced Recon Force mit integriertem Scanner-Visier.",
    Slot = "head", Model = P .. "helmet/helmet_clone_p1_arf.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 15, DamageReduction = 0.02, Weight = 2.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.ARF),
})

armor("armor_helmet_barc", {
    Name = "BARC-Helm",
    Description = "Helm der BARC-Speedereinheit.",
    Slot = "head", Model = P .. "helmet/helmet_clone_barc.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 15, DamageReduction = 0.02, Weight = 2.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.BARC),
})

armor("armor_helmet_pilot", {
    Name = "Pilotenhelm",
    Description = "Phase-I-Pilotenhelm mit Lebenserhaltungsanschlüssen.",
    Slot = "head", Model = P .. "helmet/helmet_clone_p1_pilot.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 10, Weight = 1.8, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.NAVY),
})

armor("armor_helmet_airborne", {
    Name = "Airborne-Helm",
    Description = "Verstärkter Helm des Airborne-Zugs.",
    Slot = "head", Model = P .. "helmet/helmet_clone_airborne.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 20, DamageReduction = 0.02, Weight = 2.2, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.AB),
})

armor("armor_helmet_heavy", {
    Name = "Schwerer Helm",
    Description = "Stark gepanzerter AT-RT- / Heavy-Trooper-Helm.",
    Slot = "head", Model = P .. "helmet/helmet_clone_atrt_heavy.mdl",
    Icon = "fa-helmet-safety", Rarity = "rare",
    Armor = 25, DamageReduction = 0.04, Weight = 3.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.HEAVY),
})

armor("armor_helmet_arc", {
    Name = "ARC-Helm",
    Description = "Helm der Advanced Recon Commandos mit Entfernungsmesser.",
    Slot = "head", Model = P .. "helmet/helmet_clone_arc.mdl",
    Icon = "fa-helmet-safety", Rarity = "epic",
    Armor = 25, DamageReduction = 0.05, Weight = 2.5, Size = { W = 1, H = 1 },
})

-- Shoulder ---------------------------------------------------
-- Kein Nevelgrad-Model für Schulterteile: Symbol = FontAwesome-Icon.
armor("armor_shoulder_standard", {
    Name = "Schulterpanzer (Standard)",
    Description = "Plastoid-Schulterplatten der Klon-Infanterie.",
    Slot = "shoulder",
    Icon = "fa-shield", Rarity = "common",
    Armor = 10, Weight = 1.5, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.T501, UNIT.AB, UNIT.ENG, UNIT.ST),
})

armor("armor_shoulder_heavy", {
    Name = "Schulterpanzer (Schwer)",
    Description = "Verstärkte Schulterplatten des Heavy-Zugs.",
    Slot = "shoulder",
    Icon = "fa-shield", Rarity = "rare",
    Armor = 20, DamageReduction = 0.03, Weight = 3.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.HEAVY),
})

armor("armor_shoulder_light", {
    Name = "Schulterpanzer (Leicht)",
    Description = "Leichte Schulterplatten für Aufklärer und Sanitäter.",
    Slot = "shoulder",
    Icon = "fa-shield", Rarity = "common",
    Armor = 5, Weight = 1.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.ARF, UNIT.BARC, UNIT.MED),
})

-- Chest ------------------------------------------------------
armor("armor_chest_standard", {
    Name = "Klon-Brustpanzer",
    Description = "Standard-Plastoid-Brustpanzer der Klonarmee.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "common",
    Armor = 40, DamageReduction = 0.05, Weight = 6.0, Size = { W = 2, H = 2 },
})

armor("armor_chest_heavy", {
    Name = "Brustpanzer (Schwer)",
    Description = "Schwerer Brustpanzer des Heavy-Zugs. Viel Schutz, viel Gewicht.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "rare",
    Armor = 60, DamageReduction = 0.08, Weight = 9.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.HEAVY),
})

armor("armor_chest_light", {
    Name = "Brustpanzer (Leicht)",
    Description = "Leichter Brustpanzer für Aufklärer, Piloten und Flottenpersonal.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "common",
    Armor = 25, DamageReduction = 0.03, Weight = 4.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ARF, UNIT.NAVY),
})

armor("armor_chest_medic", {
    Name = "Brustpanzer (Sanitäter)",
    Description = "Brustpanzer des Sanitätszugs mit Halterungen für Medpacks.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "uncommon",
    Armor = 35, DamageReduction = 0.04, Weight = 5.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.MED),
})

armor("armor_chest_guard", {
    Name = "Brustpanzer (Wache)",
    Description = "Verstärkter Brustpanzer der Schocktruppen.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "uncommon",
    Armor = 45, DamageReduction = 0.06, Weight = 6.5, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ST),
})

-- Back -------------------------------------------------------
armor("armor_back_standard", {
    Name = "Standard-Rucksack",
    Description = "Feldrucksack. Erhöht die Tragkraft.",
    Slot = "back", Model = P .. "backpack/backpack_clone_standart.mdl",
    Icon = "fa-suitcase", Rarity = "common",
    CarryWeight = 15, Weight = 2.0, Size = { W = 2, H = 2 },
})

armor("armor_back_jetpack", {
    Name = "Jetpack-Gestell",
    Description = "Jetpack-Gestell der Airborne. Etwas mehr Tragkraft.",
    Slot = "back", Model = P .. "backpack/backpack_clone_jetpack.mdl",
    Icon = "fa-jet-fighter-up", Rarity = "rare",
    Armor = 5, CarryWeight = 5, Weight = 4.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.AB),
})

armor("armor_back_arc", {
    Name = "ARC-Rucksack",
    Description = "Kommando-Rucksack mit Zusatzpanzerung und Stauraum.",
    Slot = "back", Model = P .. "backpack/backpack_clone_arc.mdl",
    Icon = "fa-suitcase", Rarity = "epic",
    Armor = 10, CarryWeight = 20, Weight = 3.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ARF),
})

armor("armor_back_medic", {
    Name = "Sanitätsrucksack",
    Description = "Großer Rucksack für Bacta und Verbandsmaterial.",
    Slot = "back", Model = P .. "backpack/backpack_clone_standart.mdl",
    Icon = "fa-suitcase-medical", Rarity = "uncommon",
    CarryWeight = 25, Weight = 2.5, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.MED),
})

armor("armor_back_tools", {
    Name = "Werkzeugrucksack",
    Description = "Rucksack der Pioniere für Werkzeug und Ersatzteile.",
    Slot = "back", Model = P .. "backpack/backpack_clone_standart.mdl",
    Icon = "fa-toolbox", Rarity = "uncommon",
    CarryWeight = 20, Weight = 2.5, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ENG),
})

-- Hip --------------------------------------------------------
armor("armor_hip_cadet", {
    Name = "Kadetten-Hüftpanzer",
    Description = "Ausrüstungsgürtel mit Hüftplatten.",
    Slot = "hip", Model = P .. "hip/hip_clone_cadet.mdl",
    Icon = "fa-vest", Rarity = "common",
    Armor = 10, Weight = 1.5, Size = { W = 2, H = 1 },
})

armor("armor_hip_heavy", {
    Name = "Hüftpanzer (Schwer)",
    Description = "Schwere Hüftplatten des Heavy-Zugs.",
    Slot = "hip", Model = P .. "hip/hip_clone_cadet.mdl",
    Icon = "fa-vest", Rarity = "rare",
    Armor = 15, DamageReduction = 0.02, Weight = 2.5, Size = { W = 2, H = 1 },
    AllowedJobs = jobs(UNIT.HEAVY),
})

armor("armor_hip_tools", {
    Name = "Werkzeuggurt",
    Description = "Gürtel mit Hüftplatten und Werkzeugtaschen der Pioniere.",
    Slot = "hip", Model = P .. "hip/hip_clone_cadet.mdl",
    Icon = "fa-screwdriver-wrench", Rarity = "uncommon",
    Armor = 10, Weight = 1.5, Size = { W = 2, H = 1 },
    AllowedJobs = jobs(UNIT.ENG),
})

-- ============================================================
-- SHARED HELPERS (do not edit)
-- ============================================================
INV.ArmorSlotByID = {}
for index, slot in ipairs(C.Armor.Slots or {}) do
    slot.Order = index
    INV.ArmorSlotByID[slot.ID] = slot
end

function INV.GetArmorSlotForDefinition(def)
    if not istable(def) or def.Type ~= "armor" then return nil end
    if C.Armor and C.Armor.Enabled == false then return nil end
    local slot = tostring(def.Slot or "")
    return INV.ArmorSlotByID[slot] and slot or nil
end

-- Performance: wird pro Spieler und Frame (PostPlayerDraw) aufgerufen -> Ergebnis je Model cachen
local armorVisualCache, armorVisualCacheCfg = {}, nil
function INV.ArmorVisualAllowed(model)
    local cfg = C.Armor or {}
    local mode = tostring(cfg.VisualMode or "base_only")
    if mode == "never" then return false end
    if mode == "always" then return true end
    if armorVisualCacheCfg ~= cfg.BaseModels then
        armorVisualCache, armorVisualCacheCfg = {}, cfg.BaseModels
    end
    local key = model or ""
    local cached = armorVisualCache[key]
    if cached ~= nil then return cached end
    local norm = string.lower(string.Replace(tostring(key), "\\", "/"))
    cached = istable(cfg.BaseModels) and cfg.BaseModels[norm] == true
    armorVisualCache[key] = cached
    return cached
end

-- Model used to render the small icon of any item.
function INV.GetIconModel(def)
    if not istable(def) then return nil end
    if isstring(def.IconModel) and def.IconModel ~= "" then return def.IconModel end
    if def.Type == "armor" and isstring(def.Model) then return def.Model end
    if def.Type == "weapon" then
        -- The SWEP's own world model is the most reliable picture.
        local stored = isstring(def.WeaponClass) and weapons.GetStored(def.WeaponClass) or nil
        local wm = stored and tostring(stored.WorldModel or "") or ""
        if wm ~= "" and string.EndsWith(string.lower(wm), ".mdl") then return wm end
        local mdl = tostring(def.DropModel or "")
        if mdl ~= "" and not string.find(mdl, "cardboard_box", 1, true) then return mdl end
    end
    return nil
end

-- ============================================================
-- UI SOUNDS (inventory + armory)
-- ============================================================
-- Each entry: first existing sound wins. The kraken/... files come with
-- Kraken's Framework (Tactical Armory). If that is not installed, the
-- sounds of the character system (symchars) are used.
C.UISounds = {
    Enabled = true,
    Open   = { "kraken/sw_squadrons/ux/navigation/navigation_tab_01.mp3", "buttons/button24.wav" },
    Close  = { "kraken/sw_squadrons/ux/navigation/navigation_back_01.mp3", "ui/buttonclickrelease.wav" },
    Hover  = { "kraken/sw_squadrons/ux/navigation/navigation_slider_02.mp3", "ui/buttonrollover.wav" },
    Click  = { "kraken/sw_squadrons/ux/navigation/navigation_activate_01.mp3", "ui/buttonclickrelease.wav" },
    Equip  = { "buttons/button14.wav" },
    Drag   = { "ui/buttonrollover.wav" },
    Error  = { "kraken/sw_squadrons/ux/navigation/navigation_error_01.mp3", "buttons/button10.wav" },
    Notify = { "buttons/blip1.wav" },
    HoverCooldown = 0.06,
}
