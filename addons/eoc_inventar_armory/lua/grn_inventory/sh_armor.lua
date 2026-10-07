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
        { ID = "accessory", Label = "ZUBEHÖR", Side = "left",  Icon = "fa-binoculars",    Hint = "Helm-Zubehör (nur mit Helm sichtbar)" },
        { ID = "chest",    Label = "BRUST",    Side = "left",  Icon = "fa-shirt",         Hint = "Brustpanzer" },
        { ID = "back",     Label = "RÜCKEN",   Side = "right", Icon = "fa-suitcase",      Hint = "Rucksack / Jetpack" },
        { ID = "hip",      Label = "HOSE",     Side = "right", Icon = "fa-socks",         Hint = "Beinpanzer / Hose" },
        -- Rang- und Ausrüstungsteile (nur Optik, 501st)
        { ID = "pauldron", Label = "PAULDRON", Side = "left",  Icon = "fa-shield",        Hint = "Pauldron (ab First Corporal)" },
        { ID = "strap",    Label = "GURT",     Side = "left",  Icon = "fa-ribbon",        Hint = "Rang-Gurt (Specialist / Corporal / Chief Corporal)" },
        { ID = "kama",     Label = "KAMA",     Side = "right", Icon = "fa-vest-patches",  Hint = "Kama (ab Sergeant)" },
        { ID = "holster",  Label = "HOLSTER",  Side = "right", Icon = "fa-gun",           Hint = "Holster (dual / rechts)" },
        { ID = "ammo",     Label = "MUNITION", Side = "right", Icon = "fa-box-archive",   Hint = "Extra-Munition" },
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
    IconVersion = 2,
    IconSize = 128,

    -- Also render icons for weapons that have no IconURL (uses the SWEP world model).
    RenderWeaponIcons = true,

    -- Rüstung aus der Waffenkammer wird direkt angelegt, wenn der passende
    -- Slot noch frei ist (sonst landet sie nur im Inventar).
    AutoEquipFromArmory = true,

    -- Rüstung am Spieler über die Bodygroups des Job-Models.
    -- Angelegtes Teil = Bodygroup "On", leerer Slot = Bodygroup "Off".
    Bodygroups = {
        Enabled = true,

        -- Welche Bodygroup zu welchem Rüstungsslot gehört. Gefunden wird sie
        -- über ihren Namen im Model: erst exakter Name, dann Namensteil
        -- (Groß/Klein egal). Prüfen mit dem Konsolenbefehl grn_armor_bodygroups.
        Groups = {
            helmet   = { Slot = "head",  Names = { "helm", "helmet", "head", "kopf" } },
            torso    = { Slot = "chest", Names = { "oberteil", "torso", "chest", "brust", "upper" } },
            legs     = { Slot = "hip",   Names = { "hose", "hosen", "legs", "leg", "beine", "bein", "pants", "trousers", "unterteil", "lower", "bottom", "hip" } },
            backpack = { Slot = "back",  Names = { "rucksack", "backpack", "pack", "bag" } },

            -- Helm-Zubehör: an, wenn eines der Items im Slot "accessory" steckt
            -- UND ein Helm getragen wird (Requires).
            macrobinoculars = { Items = { "armor_acc_macrobinoculars" }, Requires = "head", Names = { "macrobinoculars", "macrobinocular", "binocular", "fernglas" } },
            rangefinder     = { Items = { "armor_acc_rangefinder" },     Requires = "head", Names = { "rangefinder", "entfernungsmesser" } },
            sunvisor        = { Items = { "armor_acc_sunvisor" },        Requires = "head", Names = { "sunvisor", "visor", "sonnenblende" } },

            -- Rang- und Ausrüstungsteile. Strap und Holster sind je EINE Bodygroup,
            -- das Item bestimmt den Wert (PlayerBodygroups).
            pauldron = { Slot = "pauldron", Names = { "pauldron" } },
            kama     = { Slot = "kama",     Names = { "kama", "karma" } },
            strap    = { Slot = "strap",    Names = { "strap", "straps", "gurt" } },
            holster  = { Slot = "holster",  Names = { "holster", "holsters" } },
            ammo     = { Slot = "ammo",     Names = { "extra munition", "extra_ammo", "extraammo", "ammo", "munition" } },
        },

        -- Werte pro Model-Gruppe. Match = Anfang des Model-Pfads.
        -- Optional pro Gruppe Index = <Nummer>, falls die Namenssuche nicht passt.
        -- Ein Item kann seinen eigenen "An"-Wert setzen: PlayerBodygroups = { backpack = 2 }
        -- (z. B. das Jetpack der Airborne).
        Profiles = {
            {
                Name = "501st",
                Match = { "models/silent/501st_ph1/" },
                Values = {
                    helmet   = { On = 0, Off = 1 },
                    torso    = { On = 0, Off = 2 },
                    legs     = { On = 0, Off = 1 },
                    backpack = { On = 1, Off = 0 },
                    macrobinoculars = { On = 1, Off = 0 },
                    rangefinder     = { On = 1, Off = 0 },
                    sunvisor        = { On = 0, Off = 1 },
                    pauldron = { On = 1, Off = 0 },
                    kama     = { On = 1, Off = 0 },
                    strap    = { On = 3, Off = 0 }, -- 1 Chief Corporal, 2 Corporal Sidebag, 3 Corporal, 4 Specialist
                    holster  = { On = 2, Off = 0 }, -- 1 dual, 2 rechts
                    ammo     = { On = 1, Off = 0 },
                },
            },
            {
                Name = "Schocktruppen",
                Match = { "models/starwars/grady/eoc/st/", "models/starwars/grady/merlin/st/" },
                Values = {
                    helmet   = { On = 0, Off = 1 },
                    torso    = { On = 0, Off = 1 },
                    legs     = { On = 0, Off = 1 },
                    backpack = { On = 1, Off = 0 },
                },
            },
        },
    },

    -- Bilder der Rüstungsteile: ist das Nevelgrad-Model eines Items (Model)
    -- installiert, wird es direkt gerendert. Sonst wird das Bild aus dem
    -- Job-Model (IconModel, alle Teile "On") gerendert und auf die Körperstelle
    -- des Slots gezoomt. Radius = Bildausschnitt.
    UnitModels = {
        T501  = "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl",
        HEAVY = "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl",
        ARF   = "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl",
        BARC  = "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl",
        AB    = "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl",
        MED   = "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl",
        ENG   = "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl",
        ST    = "models/starwars/grady/eoc/st/st_ph1_trooper.mdl",
        AVP   = "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl",
    },
    IconCamera = {
        head     = { Bone = "ValveBiped.Bip01_Head1",     Radius = 9,  Dir = Vector(1, 0.35, 0.12) },
        accessory = { Bone = "ValveBiped.Bip01_Head1",    Radius = 9,  Dir = Vector(1, 0.35, 0.12) },
        pauldron = { Bone = "ValveBiped.Bip01_L_UpperArm", Radius = 11, Dir = Vector(0.5, 1, 0.3) },
        strap    = { Bone = "ValveBiped.Bip01_Spine2",    Radius = 15, Dir = Vector(1, 0.2, 0.1) },
        kama     = { Bone = "ValveBiped.Bip01_Pelvis",    Radius = 17, Dir = Vector(-1, 0.4, 0.05) },
        holster  = { Bone = "ValveBiped.Bip01_R_Thigh",   Radius = 11, Dir = Vector(0.4, -1, 0.1) },
        ammo     = { Bone = "ValveBiped.Bip01_Spine1",    Radius = 14, Dir = Vector(1, 0.3, 0.05) },
        chest    = { Bone = "ValveBiped.Bip01_Spine2",    Radius = 17, Dir = Vector(1, 0.3, 0.1) },
        back     = { Bone = "ValveBiped.Bip01_Spine2",    Radius = 17, Dir = Vector(-1, 0.35, 0.15) },
        hip      = { Bone = "ValveBiped.Bip01_Pelvis",    Radius = 15, Dir = Vector(1, 0.3, 0.05) },
    },

    -- Rang-Teile: welche Ränge (Ende des Job-Commands) sie tragen dürfen.
    RankGear = {
        Units = { "T501", "HEAVY", "ARF", "BARC", "AB", "MED", "ENG" }, -- nur 501st
        PauldronRanks = { "fcpl", "sgt", "fsgt", "sgm", "lt", "1lt", "cpt" }, -- ab First Corporal
        KamaRanks = { "sgt", "fsgt", "sgm", "lt", "1lt", "cpt" },     -- ab Sergeant
        SpecialistStrapRanks = { "spc" },
        CorporalStrapRanks = { "cpl" },
        ChiefCorporalStrapRanks = { "ccpl" },
    },

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
            local rankOK = binding.ranks == nil
            if not rankOK then
                for rank in pairs(binding.ranks) do
                    if string.sub(command, -(#rank + 1)) == "_" .. rank then rankOK = true break end
                end
            end
            for _, prefix in ipairs(rankOK and binding.prefixes or {}) do
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

-- Like jobs(), but only for the given ranks (end of the command):
-- rankJobs({ "sgt", "fsgt" }, UNIT.T501, UNIT.HEAVY) -> 501st_sgt, 501stheavy_fsgt ...
local function rankJobs(ranks, ...)
    local list = jobs(...)
    local binding = jobBindings[#jobBindings]
    binding.ranks = {}
    for _, rank in ipairs(ranks) do binding.ranks[string.lower(rank)] = true end
    fillJobBinding(binding)
    return list
end

function INV.RefreshArmorJobBindings()
    for _, binding in ipairs(jobBindings) do fillJobBinding(binding) end
end

hook.Add("PostGamemodeLoaded", "GRNInventory_ArmorJobBindings", INV.RefreshArmorJobBindings)
hook.Add("DarkRPFinishedLoading", "GRNInventory_ArmorJobBindings", INV.RefreshArmorJobBindings)
hook.Add("InitPostEntity", "GRNInventory_ArmorJobBindings", INV.RefreshArmorJobBindings)

local UNIT = C.Armor.UnitJobs or {}
local UNIT_MODEL = C.Armor.UnitModels or {}
local P = "models/nevelgrad/clothe_parties/clone/"

-- Helmets ----------------------------------------------------
armor("armor_helmet_p1", {
    Name = "Phase-I-Helm",
    Description = "Standardhelm der Phase-I-Klonkrieger.",
    Slot = "head", Model = P .. "helmet/helmet_clone_p1_standart.mdl",
    Icon = "fa-helmet-safety", Rarity = "common",
    Armor = 15, Weight = 2.0, Size = { W = 1, H = 1 },
    IconModel = UNIT_MODEL.T501,
})

armor("armor_helmet_arf", {
    Name = "ARF-Helm",
    Description = "Helm der Advanced Recon Force mit integriertem Scanner-Visier.",
    Slot = "head", Model = P .. "helmet/helmet_clone_p2_arf.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 15, DamageReduction = 0.02, Weight = 2.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.ARF),
    IconModel = UNIT_MODEL.ARF,
})

armor("armor_helmet_barc", {
    Name = "BARC-Helm",
    Description = "Helm der BARC-Speedereinheit.",
    Slot = "head", Model = P .. "helmet/helmet_clone_barc.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 15, DamageReduction = 0.02, Weight = 2.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.BARC),
    IconModel = UNIT_MODEL.BARC,
})

armor("armor_helmet_pilot", {
    Name = "Pilotenhelm",
    Description = "Phase-I-Pilotenhelm mit Lebenserhaltungsanschlüssen.",
    Slot = "head", Model = P .. "helmet/helmet_clone_p1_pilot.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 10, Weight = 1.8, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.NAVY),
    IconModel = UNIT_MODEL.AVP,
})

armor("armor_helmet_airborne", {
    Name = "Airborne-Helm",
    Description = "Verstärkter Helm des Airborne-Zugs.",
    Slot = "head", Model = P .. "helmet/helmet_clone_airborne.mdl",
    Icon = "fa-helmet-safety", Rarity = "uncommon",
    Armor = 20, DamageReduction = 0.02, Weight = 2.2, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.AB),
    IconModel = UNIT_MODEL.AB,
})

armor("armor_helmet_heavy", {
    Name = "Schwerer Helm",
    Description = "Stark gepanzerter AT-RT- / Heavy-Trooper-Helm.",
    Slot = "head", Model = P .. "helmet/helmet_clone_atrt_heavy.mdl",
    Icon = "fa-helmet-safety", Rarity = "rare",
    Armor = 25, DamageReduction = 0.04, Weight = 3.0, Size = { W = 1, H = 1 },
    AllowedJobs = jobs(UNIT.HEAVY),
    IconModel = UNIT_MODEL.HEAVY,
})

armor("armor_helmet_arc", {
    Name = "ARC-Helm",
    Description = "Helm der Advanced Recon Commandos mit Entfernungsmesser.",
    Slot = "head", Model = P .. "helmet/helmet_clone_arc.mdl",
    Icon = "fa-helmet-safety", Rarity = "epic",
    Armor = 25, DamageReduction = 0.05, Weight = 2.5, Size = { W = 1, H = 1 },
    IconModel = UNIT_MODEL.T501,
})

-- Helm-Zubehör (Slot "accessory") ---------------------------
-- Sichtbar nur zusammen mit einem Helm. Keine Werte, nur Optik.
local ACC = P .. "accessories/"

armor("armor_acc_macrobinoculars", {
    Name = "Makrofernglas",
    Description = "Am Helm befestigtes Makrofernglas.",
    Slot = "accessory", Model = ACC .. "accessories_clone_macrobinoculars.mdl",
    Icon = "fa-binoculars", Rarity = "uncommon",
    Weight = 0.5, Size = { W = 1, H = 1 },
    IconModel = UNIT_MODEL.T501,
})

armor("armor_acc_rangefinder", {
    Name = "Entfernungsmesser",
    Description = "Ausklappbarer Entfernungsmesser am Helm.",
    Slot = "accessory", Model = ACC .. "accessories_clone_rangefinder.mdl",
    Icon = "fa-crosshairs", Rarity = "uncommon",
    Weight = 0.5, Size = { W = 1, H = 1 },
    IconModel = UNIT_MODEL.T501,
})

armor("armor_acc_sunvisor", {
    Name = "Sonnenblende",
    Description = "Sonnenblende über dem Helmvisier.",
    Slot = "accessory", Model = ACC .. "accessories_clone_sunvisor.mdl",
    Icon = "fa-sun", Rarity = "common",
    Weight = 0.3, Size = { W = 1, H = 1 },
    IconModel = UNIT_MODEL.T501,
})

-- Rang- und Ausrüstungsteile (nur Optik) -------------------
local RG = C.Armor.RankGear or {}
local RANK_UNITS = {}
for _, unit in ipairs(RG.Units or {}) do RANK_UNITS[#RANK_UNITS + 1] = UNIT[unit] end
local function gear(id, data)
    data.Rarity = data.Rarity or "common"
    data.Weight = data.Weight or 0.3
    data.Size = data.Size or { W = 1, H = 1 }
    data.IconModel = data.IconModel or UNIT_MODEL.T501
    data.AllowedJobs = data.AllowedJobs or jobs(unpack(RANK_UNITS))
    armor(id, data)
end

gear("armor_rank_pauldron", {
    Name = "Pauldron", Description = "Stoff-Pauldron über der Schulter (ab First Corporal).",
    AllowedJobs = rankJobs(RG.PauldronRanks or {}, unpack(RANK_UNITS)),
    Slot = "pauldron", Icon = "fa-shield", Model = P .. "pauldron/pauldron_clone_standart.mdl",
})

gear("armor_rank_kama", {
    Name = "Kama", Description = "Kama der Unteroffiziere und Offiziere (ab Sergeant).",
    Slot = "kama", Icon = "fa-vest-patches", Model = P .. "kama/kama_clone_standart.mdl",
    AllowedJobs = rankJobs(RG.KamaRanks or {}, unpack(RANK_UNITS)),
})

gear("armor_rank_strap_spc", {
    Name = "Specialist-Strap", Description = "Rang-Gurt der Specialists.",
    Slot = "strap", Icon = "fa-ribbon", Model = P .. "pauldron/pauldron_clone_strap.mdl", PlayerBodygroups = { strap = 4 },
    AllowedJobs = rankJobs(RG.SpecialistStrapRanks or {}, unpack(RANK_UNITS)),
})

gear("armor_rank_strap_cpl", {
    Name = "Corporal-Strap", Description = "Rang-Gurt der Corporals.",
    Slot = "strap", Icon = "fa-ribbon", Model = P .. "pauldron/pauldron_clone_strap.mdl", PlayerBodygroups = { strap = 3 },
    AllowedJobs = rankJobs(RG.CorporalStrapRanks or {}, unpack(RANK_UNITS)),
})

gear("armor_rank_strap_cpl_sidebag", {
    Name = "Corporal-Sidebag-Strap", Description = "Rang-Gurt der Corporals mit Seitentasche.",
    Slot = "strap", Icon = "fa-ribbon", Model = P .. "pauldron/pauldron_clone_strap.mdl", PlayerBodygroups = { strap = 2 },
    AllowedJobs = rankJobs(RG.CorporalStrapRanks or {}, unpack(RANK_UNITS)),
})

gear("armor_rank_strap_ccpl", {
    Name = "Chief-Corporal-Strap", Description = "Rang-Gurt der Chief Corporals.",
    Slot = "strap", Icon = "fa-ribbon", Model = P .. "pauldron/pauldron_clone_strap.mdl", PlayerBodygroups = { strap = 1 },
    AllowedJobs = rankJobs(RG.ChiefCorporalStrapRanks or {}, unpack(RANK_UNITS)),
})

gear("armor_holster_dual", {
    Name = "Holster (Dual)", Description = "Zwei Pistolenholster.",
    Slot = "holster", Icon = "fa-gun", PlayerBodygroups = { holster = 1 },
})

gear("armor_holster_right", {
    Name = "Holster (rechts)", Description = "Pistolenholster rechts.",
    Slot = "holster", Icon = "fa-gun", PlayerBodygroups = { holster = 2 },
})

gear("armor_ammo_extra", {
    Name = "Extra-Munition", Description = "Zusätzliche Magazintaschen.",
    Slot = "ammo", Icon = "fa-box-archive", PlayerBodygroups = { ammo = 1 },
})

-- Chest ------------------------------------------------------
armor("armor_chest_standard", {
    Name = "Klon-Brustpanzer",
    Description = "Standard-Plastoid-Brustpanzer der Klonarmee.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "common",
    Armor = 40, DamageReduction = 0.05, Weight = 6.0, Size = { W = 2, H = 2 },
    IconModel = UNIT_MODEL.T501,
})

armor("armor_chest_heavy", {
    Name = "Brustpanzer (Schwer)",
    Description = "Schwerer Brustpanzer des Heavy-Zugs. Viel Schutz, viel Gewicht.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "rare",
    Armor = 60, DamageReduction = 0.08, Weight = 9.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.HEAVY),
    IconModel = UNIT_MODEL.HEAVY,
})

armor("armor_chest_light", {
    Name = "Brustpanzer (Leicht)",
    Description = "Leichter Brustpanzer für Aufklärer, Piloten und Flottenpersonal.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "common",
    Armor = 25, DamageReduction = 0.03, Weight = 4.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ARF, UNIT.NAVY),
    IconModel = UNIT_MODEL.ARF,
})

armor("armor_chest_medic", {
    Name = "Brustpanzer (Sanitäter)",
    Description = "Brustpanzer des Sanitätszugs mit Halterungen für Medpacks.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "uncommon",
    Armor = 35, DamageReduction = 0.04, Weight = 5.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.MED),
    IconModel = UNIT_MODEL.MED,
})

armor("armor_chest_guard", {
    Name = "Brustpanzer (Wache)",
    Description = "Verstärkter Brustpanzer der Schocktruppen.",
    Slot = "chest", Model = P .. "chest/chest_clone_standart.mdl",
    Icon = "fa-shirt", Rarity = "uncommon",
    Armor = 45, DamageReduction = 0.06, Weight = 6.5, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ST),
    IconModel = UNIT_MODEL.ST,
})

-- Back -------------------------------------------------------
armor("armor_back_standard", {
    Name = "Standard-Rucksack",
    Description = "Feldrucksack. Erhöht die Tragkraft.",
    Slot = "back", Model = P .. "backpack/backpack_clone_standart.mdl",
    Icon = "fa-suitcase", Rarity = "common",
    CarryWeight = 15, Weight = 2.0, Size = { W = 2, H = 2 },
    IconModel = UNIT_MODEL.T501,
})

armor("armor_back_jetpack", {
    Name = "Jetpack-Gestell",
    Description = "Jetpack-Gestell der Airborne. Etwas mehr Tragkraft.",
    Slot = "back", Model = P .. "backpack/backpack_clone_jetpack.mdl",
    Icon = "fa-jet-fighter-up", Rarity = "rare",
    Armor = 5, CarryWeight = 5, Weight = 4.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.AB),
    IconModel = UNIT_MODEL.AB,
    PlayerBodygroups = { backpack = 2 }, -- Airborne-Model: Rucksack-Bodygroup 2 = Jetpack
})

armor("armor_back_arc", {
    Name = "ARC-Rucksack",
    Description = "Kommando-Rucksack mit Zusatzpanzerung und Stauraum.",
    Slot = "back", Model = P .. "backpack/backpack_clone_arc.mdl",
    Icon = "fa-suitcase", Rarity = "epic",
    Armor = 10, CarryWeight = 20, Weight = 3.0, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ARF),
    IconModel = UNIT_MODEL.ARF,
})

armor("armor_back_medic", {
    Name = "Sanitätsrucksack",
    Description = "Großer Rucksack für Bacta und Verbandsmaterial.",
    Slot = "back", Model = P .. "backpack/backpack_clone_standart.mdl",
    Icon = "fa-suitcase-medical", Rarity = "uncommon",
    CarryWeight = 25, Weight = 2.5, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.MED),
    IconModel = UNIT_MODEL.MED,
})

armor("armor_back_tools", {
    Name = "Werkzeugrucksack",
    Description = "Rucksack der Pioniere für Werkzeug und Ersatzteile.",
    Slot = "back", Model = P .. "backpack/backpack_clone_standart.mdl",
    Icon = "fa-toolbox", Rarity = "uncommon",
    CarryWeight = 20, Weight = 2.5, Size = { W = 2, H = 2 },
    AllowedJobs = jobs(UNIT.ENG),
    IconModel = UNIT_MODEL.ENG,
})

-- Hose (Slot "hip") ----------------------------------------
armor("armor_hip_cadet", {
    Name = "Panzerhose (Standard)",
    Description = "Plastoid-Beinpanzer der Klon-Infanterie.",
    Slot = "hip", Model = P .. "hip/hip_clone_cadet.mdl",
    Icon = "fa-vest", Rarity = "common",
    Armor = 10, Weight = 1.5, Size = { W = 2, H = 1 },
    IconModel = UNIT_MODEL.T501,
})

armor("armor_hip_heavy", {
    Name = "Panzerhose (Schwer)",
    Description = "Schwerer Beinpanzer des Heavy-Zugs.",
    Slot = "hip", Model = P .. "hip/hip_clone_cadet.mdl",
    Icon = "fa-vest", Rarity = "rare",
    Armor = 15, DamageReduction = 0.02, Weight = 2.5, Size = { W = 2, H = 1 },
    AllowedJobs = jobs(UNIT.HEAVY),
    IconModel = UNIT_MODEL.HEAVY,
})

armor("armor_hip_tools", {
    Name = "Panzerhose (Pionier)",
    Description = "Beinpanzer der Pioniere mit Werkzeugtaschen.",
    Slot = "hip", Model = P .. "hip/hip_clone_cadet.mdl",
    Icon = "fa-screwdriver-wrench", Rarity = "uncommon",
    Armor = 10, Weight = 1.5, Size = { W = 2, H = 1 },
    AllowedJobs = jobs(UNIT.ENG),
    IconModel = UNIT_MODEL.ENG,
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

-- Bodygroup profile (C.Armor.Bodygroups.Profiles) for a player model, or nil.
function INV.GetArmorBodygroupProfile(model)
    local cfg = C.Armor and C.Armor.Bodygroups
    if not istable(cfg) or cfg.Enabled == false then return nil end
    local norm = string.lower(string.Replace(tostring(model or ""), "\\", "/"))
    if norm == "" then return nil end
    for _, profile in ipairs(cfg.Profiles or {}) do
        for _, prefix in ipairs(istable(profile.Match) and profile.Match or { profile.Match }) do
            prefix = string.lower(tostring(prefix or ""))
            if prefix ~= "" and string.sub(norm, 1, #prefix) == prefix then return profile end
        end
    end
    return nil
end

-- Finds the armor bodygroups on an entity (player or clientside model).
-- Returns { [groupKey] = { index, on, off, slot, items, requires } } (cached per model).
local bodygroupCache, bodygroupCacheCfg = {}, nil
function INV.ResolveArmorBodygroups(ent)
    if not IsValid(ent) then return nil end
    local model = string.lower(tostring(ent:GetModel() or ""))
    local profile = INV.GetArmorBodygroupProfile(model)
    if not profile then return nil end

    local cfg = C.Armor.Bodygroups
    if bodygroupCacheCfg ~= cfg then bodygroupCache, bodygroupCacheCfg = {}, cfg end
    if bodygroupCache[model] then return bodygroupCache[model] end

    local names = {}
    for i = 0, ent:GetNumBodyGroups() - 1 do
        names[i] = string.lower(tostring(ent:GetBodygroupName(i) or ""))
    end

    -- Fixed indices first, then name search; one bodygroup per key.
    local keys = {}
    for key, values in pairs(profile.Values or {}) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b)
        local fa, fb = profile.Values[a].Index ~= nil, profile.Values[b].Index ~= nil
        if fa ~= fb then return fa end
        return a < b
    end)

    local out, used = {}, {}
    for _, key in ipairs(keys) do
        local values = profile.Values[key]
        local group = istable(cfg.Groups) and cfg.Groups[key] or nil
        local index = tonumber(values.Index)
        if not index and group then
            for _, wanted in ipairs(group.Names or {}) do
                wanted = string.lower(tostring(wanted))
                for i, name in pairs(names) do
                    if name == wanted and not used[i] then index = i break end
                end
                if index then break end
            end
            if not index then
                for _, wanted in ipairs(group.Names or {}) do
                    wanted = string.lower(tostring(wanted))
                    for i, name in pairs(names) do
                        if not used[i] and string.find(name, wanted, 1, true) then index = i break end
                    end
                    if index then break end
                end
            end
        end
        if index and group and names[index] then
            used[index] = true
            local items
            if istable(group.Items) then
                items = {}
                for _, id in ipairs(group.Items) do items[id] = true end
            end
            out[key] = { index = index, on = tonumber(values.On) or 0, off = tonumber(values.Off) or 0,
                slot = group.Slot, items = items, requires = group.Requires }
        end
    end

    -- Tell the admin which configured bodygroups this model is missing.
    if SERVER then
        local missing = {}
        for _, key in ipairs(keys) do
            if not out[key] then missing[#missing + 1] = key end
        end
        if #missing > 0 then
            local present = {}
            for i = 0, #names do if names[i] then present[#present + 1] = "[" .. i .. "] " .. names[i] end end
            MsgC(Color(252, 178, 73), "[GRN Inventory] ", color_white, model .. ": Bodygroup nicht gefunden für "
                .. table.concat(missing, ", ") .. ". Vorhanden: " .. table.concat(present, ", ") .. "\n")
        end
    end

    bodygroupCache[model] = out
    return out
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
