GRNStore = GRNStore or {}
GRNStore.Config = GRNStore.Config or {}
local C = GRNStore.Config

-- =========================================================
-- CloneFall Store - Main configuration
-- =========================================================

C.StoreName = "Echoes of Clones Shop"
C.CurrencyName = "Credits"

-- User groups allowed to open the store STAFF panel.
-- Actual validation is always performed server-side.
C.StaffGroups = {
    superadmin = true,
    admin = true,
    owner = true,
}

-- If enabled, IsSuperAdmin always has access even if not listed above.
C.SuperAdminAlwaysStaff = true

-- =========================================================
-- Economy
-- =========================================================
C.Economy = {
    UseDarkRP = true,
    AllowFallbackNWInt = true,
    FallbackNWInt = "grn_store_money",
}

-- =========================================================
-- Entity / vendor
-- =========================================================
C.Entity = {
    Class = "grn_store_terminal",

    -- Change this model to the character/NPC you want to use as the vendor.
    Model = "models/navy/gnavyadmiral.mdl",

    -- Idle sequence. If the model does not have it, ACT_IDLE is used as a fallback.
    IdleSequence = "idle_all_01",
    PlaybackRate = 1,

    UseDistance = 180,
    MenuMaxDistance = 450,

    -- 3D2D image above the entity. Rendered with DHTML, not a downloaded material.
    IconURL = "https://r2.fivemanage.com/CAL8kaFVELoEmru99DXu6/StoreIcon.png",
    IconWidth = 180,
    IconHeight = 180,
    IconScale = 0.13,
    IconOffset = Vector(0, 0, 88),
    IconMaxDistance = 900,
    IconVisibilityCheckInterval = 0.12,

    -- Allows only admins to spawn the entity from the Q menu.
    Spawnable = true,
    AdminOnly = true,
}

-- =========================================================
-- 3D preview integrated into HTML cards through a Lua overlay
-- =========================================================
C.Preview = {
    Enabled = true,
    FallbackModel = "models/player/kleiner.mdl",

    -- If a product does not have a valid previewModel, a fallback model is used
    -- depending on its type. This prevents the red ERROR model.
    TypeFallbacks = {
        weapon = "models/weapons/w_pistol.mdl",
        model = "models/player/kleiner.mdl",
        entity = "models/props_junk/wood_crate001a.mdl",
        vehicle = "models/props_vehicles/car004a_physics.mdl",
        pet = "models/headcrabclassic.mdl",
        upgrade = "models/items/battery.mdl",
        rank = "models/items/battery.mdl",
        other = "models/props_junk/wood_crate001a.mdl",
    },

    FOV = 50,
    Spin = true,
    SpinSpeed = 10,

    -- Maximum number of simultaneously visible DModelPanels to protect FPS.
    MaxVisiblePanels = 24,
}

-- =========================================================
-- Inventory / purchase delivery
-- =========================================================
C.Inventory = {
    -- Purchased permanent weapons remain stored in the store and are
    -- manually retrieved from the Personal Armory.
    WeaponsUseArmory = true,
    RegrantWeaponsOnSpawn = false,
    ReapplyEquippedModelOnSpawn = true,
    AutoEquipModelsOnPurchase = false,

    SpawnCooldown = 5,
    MaxSpawnedPerPlayer = 5,
    SpawnDistance = 120,
}

-- =========================================================
-- PERSONAL ARMORY (entity linked to grn_inventory + grn_store)
-- =========================================================
C.Armory = {
    Enabled = true,
    Name = "Persönliche Waffenkammer",

    Entity = {
        Class = "grn_armory_terminal",
        Model = "models/reizer_props/srsp/sci_fi/armory_02/armory_02.mdl",
        UseDistance = 180,
        MenuMaxDistance = 450,

        -- 3D2D icon rendered with DHTML to support a remote URL.
        IconURL = "https://r2.fivemanage.com/CAL8kaFVELoEmru99DXu6/StoreIcon.png",
        IconWidth = 180,
        IconHeight = 180,
        IconScale = 0.13,
        IconOffset = Vector(0, 0, 72),
        IconMaxDistance = 900,
        IconVisibilityCheckInterval = 0.12,

        Spawnable = true,
        AdminOnly = true,
    },

    -- These weapons ALWAYS appear for free even if the player has no
    -- store record. InventoryItemID makes the name/icon/class read directly
    -- from the same item used by grn_inventory.
    BaseWeapons = {
        {
            ID = "base_dc15s",
            InventoryItemID = "onyx_dc15a",
            FallbackClassName = "arccw_cgi_k_dc15s", -- fallback si falta grn_inventory
            PreviewModel = "models/kraken/cgi/world/w_cgi_dc15s.mdl",
            TypeLabel = "Blaster · Carbine",
            Stats = {
                Damage = "42", Range = "460 m", RPM = "300 RPM", Magazine = "35",
                Accuracy = "16 MOA", Recoil = "0.75", Aim = "350 ms",
                Spread = "75 MOA", MoveSpread = "120 MOA",
            },
        },
        {
            ID = "base_dc17",
            InventoryItemID = "onyx_pistol",
            FallbackClassName = "arccw_cgi_k_dc17",
            PreviewModel = "models/kraken/cgi/world/w_cgi_dc17.mdl",
            TypeLabel = "Blaster · Handblaster",
            Stats = {
                Damage = "34", Range = "260 m", RPM = "420 RPM", Magazine = "18",
                Accuracy = "11 MOA", Recoil = "0.54", Aim = "240 ms",
                Spread = "58 MOA", MoveSpread = "92 MOA",
            },
        },
    },

    -- Overrides by store product, SWEP class, or base ID.
    -- If a purchase matches a grn_inventory item, InventoryItemID
    -- reuses that exact item/icon. If it matches none, the
    -- armory automatically creates a persistent item for grn_inventory.
    --
    -- EquipSlot may be "primary" or "secondary" for custom weapons.
    -- InventoryWeight / InventorySizeW / InventorySizeH are optional.
    -- Example:
    -- ["mi_producto"] = { InventoryItemID = "onyx_carbine", PreviewModel = "models/...mdl" },
    -- ["weapon_mi_swep"] = {
    --     PreviewModel = "models/...mdl",
    --     EquipSlot = "primary",
    --     InventoryWeight = 6,
    --     InventorySizeW = 2,
    --     InventorySizeH = 1,
    --     FOV = 34,
    --     PreviewAngle = Angle(0, 0, 0),
    --     PreviewScale = 1,
    -- },
    WeaponOverrides = {
        ["arccw_k_a180_pistol"] = { InventoryItemID = "arccw_k_a180_pistol" },
        ["arccw_k_blurrg"] = { InventoryItemID = "arccw_k_blurrg" },
        ["arccw_k_blurrg_ext"] = { InventoryItemID = "arccw_k_blurrg_ext" },
        ["arccw_k_caradune"] = { InventoryItemID = "arccw_k_caradune" },
        ["arccw_k_dc17"] = { InventoryItemID = "arccw_k_dc17" },
        ["arccw_k_dc17ext"] = { InventoryItemID = "arccw_k_dc17ext" },
        ["arccw_k_dc17_stun"] = { InventoryItemID = "arccw_k_dc17_stun" },
        ["arccw_k_dc17_training"] = { InventoryItemID = "arccw_k_dc17_training" },
        ["arccw_k_dc17s"] = { InventoryItemID = "arccw_k_dc17s" },
        ["arccw_k_dc17sa"] = { InventoryItemID = "arccw_k_dc17sa" },
        ["arccw_k_defender"] = { InventoryItemID = "arccw_k_defender" },
        ["arccw_k_dh11"] = { InventoryItemID = "arccw_k_dh11" },
        ["arccw_k_dh16"] = { InventoryItemID = "arccw_k_dh16" },
        ["arccw_sops_galactic_dh16"] = { InventoryItemID = "arccw_sops_galactic_dh16" },
        ["arccw_k_dh17"] = { InventoryItemID = "arccw_k_dh17" },
        ["arccw_k_dh17_pistol"] = { InventoryItemID = "arccw_k_dh17_pistol" },
        ["arccw_k_dh17e"] = { InventoryItemID = "arccw_k_dh17e" },
        ["arccw_k_dl18"] = { InventoryItemID = "arccw_k_dl18" },
        ["arccw_k_dt12"] = { InventoryItemID = "arccw_k_dt12" },
        ["arccw_k_dx2"] = { InventoryItemID = "arccw_k_dx2" },
        ["arccw_k_e11pistol"] = { InventoryItemID = "arccw_k_e11pistol" },
        ["arccw_k_e11pistol_e"] = { InventoryItemID = "arccw_k_e11pistol_e" },
        ["arccw_cgi_k_e11sa"] = { InventoryItemID = "arccw_cgi_k_e11sa" },
        ["arccw_cgi_k_ec17"] = { InventoryItemID = "arccw_cgi_k_ec17" },
        ["arccw_k_ec17"] = { InventoryItemID = "arccw_k_ec17" },
        ["arccw_k_glie44"] = { InventoryItemID = "arccw_k_glie44" },
        ["arccw_k_gn76"] = { InventoryItemID = "arccw_k_gn76" },
        ["arccw_k_huttdefender"] = { InventoryItemID = "arccw_k_huttdefender" },
        ["arccw_k_ionpistol"] = { InventoryItemID = "arccw_k_ionpistol" },
        ["arccw_k_j1"] = { InventoryItemID = "arccw_k_j1" },
        ["arccw_sops_galactic_jawapistol"] = { InventoryItemID = "arccw_sops_galactic_jawapistol" },
        ["arccw_sops_galactic_k0bu"] = { InventoryItemID = "arccw_sops_galactic_k0bu" },
        ["arccw_k_kyd21"] = { InventoryItemID = "arccw_k_kyd21" },
        ["arccw_sops_galactic_m5d"] = { InventoryItemID = "arccw_sops_galactic_m5d" },
        ["arccw_k_pulse40"] = { InventoryItemID = "arccw_k_pulse40" },
        ["arccw_cgi_k_dc17"] = { InventoryItemID = "arccw_cgi_k_dc17" },
        ["arccw_k_purge_dc17"] = { InventoryItemID = "arccw_k_purge_dc17" },
        ["arccw_k_purge_dc17ext"] = { InventoryItemID = "arccw_k_purge_dc17ext" },
        ["arccw_k_rg4d"] = { InventoryItemID = "arccw_k_rg4d" },
        ["arccw_cgi_k_rk3"] = { InventoryItemID = "arccw_cgi_k_rk3" },
        ["arccw_k_rk3"] = { InventoryItemID = "arccw_k_rk3" },
        ["arccw_cgi_k_rk3_stun"] = { InventoryItemID = "arccw_cgi_k_rk3_stun" },
        ["arccw_k_rk3_stun"] = { InventoryItemID = "arccw_k_rk3_stun" },
        ["arccw_cgi_k_rk3_training"] = { InventoryItemID = "arccw_cgi_k_rk3_training" },
        ["arccw_k_rk3_training"] = { InventoryItemID = "arccw_k_rk3_training" },
        ["arccw_k_s5"] = { InventoryItemID = "arccw_k_s5" },
        ["arccw_k_se14"] = { InventoryItemID = "arccw_k_se14" },
        ["arccw_k_shorepistol"] = { InventoryItemID = "arccw_k_shorepistol" },
        ["arccw_k_smuggler"] = { InventoryItemID = "arccw_k_smuggler" },
        ["arccw_k_tiepilotblaster"] = { InventoryItemID = "arccw_k_tiepilotblaster" },
        ["arccw_k_westar35"] = { InventoryItemID = "arccw_k_westar35" },
        ["arccw_sops_republic_x11"] = { InventoryItemID = "arccw_sops_republic_x11" },
        ["arccw_sops_galactic_z5"] = { InventoryItemID = "arccw_sops_galactic_z5" },
        ["arccw_sops_galactic_a180"] = { InventoryItemID = "arccw_sops_galactic_a180" },
        ["arccw_k_a280cfe_pistol"] = { InventoryItemID = "arccw_k_a280cfe_pistol" },
        ["arccw_k_bryar"] = { InventoryItemID = "arccw_k_bryar" },
        ["arccw_k_dc15sa"] = { InventoryItemID = "arccw_k_dc15sa" },
        ["arccw_k_cgi_dc17sa"] = { InventoryItemID = "arccw_k_cgi_dc17sa" },
        ["arccw_sops_galactic_de10"] = { InventoryItemID = "arccw_sops_galactic_de10" },
        ["arccw_k_defender_s"] = { InventoryItemID = "arccw_k_defender_s" },
        ["arccw_k_dh42"] = { InventoryItemID = "arccw_k_dh42" },
        ["arccw_k_dl18e"] = { InventoryItemID = "arccw_k_dl18e" },
        ["arccw_sops_galactic_dt40"] = { InventoryItemID = "arccw_sops_galactic_dt40" },
        ["arccw_k_e5r"] = { InventoryItemID = "arccw_k_e5r" },
        ["arccw_k_glie44_e"] = { InventoryItemID = "arccw_k_glie44_e" },
        ["arccw_k_nn14"] = { InventoryItemID = "arccw_k_nn14" },
        ["arccw_k_power5"] = { InventoryItemID = "arccw_k_power5" },
        ["arccw_k_relbyk23"] = { InventoryItemID = "arccw_k_relbyk23" },
        ["arccw_k_relbyk8"] = { InventoryItemID = "arccw_k_relbyk8" },
        ["arccw_k_rskf60"] = { InventoryItemID = "arccw_k_rskf60" },
        ["arccw_k_s5c"] = { InventoryItemID = "arccw_k_s5c" },
        ["arccw_k_cgi_westar35p"] = { InventoryItemID = "arccw_k_cgi_westar35p" },
        ["arccw_k_b2hand"] = { InventoryItemID = "arccw_k_b2hand" },
        ["arccw_k_bryar_extended"] = { InventoryItemID = "arccw_k_bryar_extended" },
        ["arccw_k_cyclerpistol"] = { InventoryItemID = "arccw_k_cyclerpistol" },
        ["arccw_sops_galactic_dg29"] = { InventoryItemID = "arccw_sops_galactic_dg29" },
        ["arccw_k_dl18d"] = { InventoryItemID = "arccw_k_dl18d" },
        ["arccw_k_hsb200"] = { InventoryItemID = "arccw_k_hsb200" },
        ["arccw_cgi_k_imperial_dc15sa"] = { InventoryItemID = "arccw_cgi_k_imperial_dc15sa" },
        ["arccw_k_s5e"] = { InventoryItemID = "arccw_k_s5e" },
        ["arccw_k_434deathhammer"] = { InventoryItemID = "arccw_k_434deathhammer" },
        ["arccw_k_dc92"] = { InventoryItemID = "arccw_k_dc92" },
        ["arccw_k_de18"] = { InventoryItemID = "arccw_k_de18" },
        ["arccw_k_dl44"] = { InventoryItemID = "arccw_k_dl44" },
        ["arccw_k_dl44e"] = { InventoryItemID = "arccw_k_dl44e" },
        ["arccw_sops_galactic_mw20"] = { InventoryItemID = "arccw_sops_galactic_mw20" },
        ["arccw_k_nn4"] = { InventoryItemID = "arccw_k_nn4" },
        ["arccw_k_sacrosk11"] = { InventoryItemID = "arccw_k_sacrosk11" },
        ["arccw_k_dc17_akimbo"] = { InventoryItemID = "arccw_k_dc17_akimbo" },
        ["arccw_k_dc17ext_akimbo"] = { InventoryItemID = "arccw_k_dc17ext_akimbo" },
        ["arccw_k_dc17s_dual"] = { InventoryItemID = "arccw_k_dc17s_dual" },
        ["arccw_k_dc17sa_dual"] = { InventoryItemID = "arccw_k_dc17sa_dual" },
        ["arccw_k_s195"] = { InventoryItemID = "arccw_k_s195" },
        ["arccw_k_westar35_akimbo"] = { InventoryItemID = "arccw_k_westar35_akimbo" },
        ["arccw_k_dl44_akimbo"] = { InventoryItemID = "arccw_k_dl44_akimbo" },
        ["arccw_k_de18_akimbo"] = { InventoryItemID = "arccw_k_de18_akimbo" },
        ["arccw_k_9228"] = { InventoryItemID = "arccw_k_9228" },
        ["arccw_k_a274su"] = { InventoryItemID = "arccw_k_a274su" },
        ["arccw_k_a280cfe_carbine"] = { InventoryItemID = "arccw_k_a280cfe_carbine" },
        ["arccw_k_baragwing"] = { InventoryItemID = "arccw_k_baragwing" },
        ["arccw_k_dc15s_stun"] = { InventoryItemID = "arccw_k_dc15s_stun" },
        ["arccw_k_dc15s_train"] = { InventoryItemID = "arccw_k_dc15s_train" },
        ["arccw_k_dh17c"] = { InventoryItemID = "arccw_k_dh17c" },
        ["arccw_k_dp24"] = { InventoryItemID = "arccw_k_dp24" },
        ["arccw_k_dp24c"] = { InventoryItemID = "arccw_k_dp24c" },
        ["arccw_k_fpee3p"] = { InventoryItemID = "arccw_k_fpee3p" },
        ["arccw_k_gau9c"] = { InventoryItemID = "arccw_k_gau9c" },
        ["arccw_k_charriccarbine"] = { InventoryItemID = "arccw_k_charriccarbine" },
        ["arccw_k_dc15sc"] = { InventoryItemID = "arccw_k_dc15sc" },
        ["arccw_k_dc15se"] = { InventoryItemID = "arccw_k_dc15se" },
        ["arccw_k_dh17_carbine"] = { InventoryItemID = "arccw_k_dh17_carbine" },
        ["arccw_k_dlt20c_galexp"] = { InventoryItemID = "arccw_k_dlt20c_galexp" },
        ["arccw_k_ee3"] = { InventoryItemID = "arccw_k_ee3" },
        ["arccw_k_ee3r"] = { InventoryItemID = "arccw_k_ee3r" },
        ["arccw_sops_empire_ee4"] = { InventoryItemID = "arccw_sops_empire_ee4" },
        ["arccw_k_el16"] = { InventoryItemID = "arccw_k_el16" },
        ["arccw_k_el16c"] = { InventoryItemID = "arccw_k_el16c" },
        ["arccw_k_el16hfe"] = { InventoryItemID = "arccw_k_el16hfe" },
        ["arccw_k_esb_ee3"] = { InventoryItemID = "arccw_k_esb_ee3" },
        ["arccw_sops_galactic_galaar15c"] = { InventoryItemID = "arccw_sops_galactic_galaar15c" },
        ["arccw_sops_galactic_k3bu"] = { InventoryItemID = "arccw_sops_galactic_k3bu" },
        ["arccw_cgi_k_dc15s_purge"] = { InventoryItemID = "arccw_cgi_k_dc15s_purge" },
        ["arccw_k_westarm5i"] = { InventoryItemID = "arccw_k_westarm5i" },
        ["arccw_k_zerzium"] = { InventoryItemID = "arccw_k_zerzium" },
        ["arccw_k_a620"] = { InventoryItemID = "arccw_k_a620" },
        ["arccw_k_a620su"] = { InventoryItemID = "arccw_k_a620su" },
        ["arccw_k_dc15s"] = { InventoryItemID = "arccw_k_dc15s" },
        ["arccw_k_dc15s_grenadier"] = { InventoryItemID = "arccw_k_dc15s_grenadier" },
        ["arccw_k_dc19"] = { InventoryItemID = "arccw_k_dc19" },
        ["arccw_sops_republic_dc19"] = { InventoryItemID = "arccw_sops_republic_dc19" },
        ["arccw_k_ee3k"] = { InventoryItemID = "arccw_k_ee3k" },
        ["arccw_k_purge_dc15s"] = { InventoryItemID = "arccw_k_purge_dc15s" },
        ["arccw_k_t45"] = { InventoryItemID = "arccw_k_t45" },
        ["arccw_k_dx11"] = { InventoryItemID = "arccw_k_dx11" },
        ["arccw_cgi_k_e11d"] = { InventoryItemID = "arccw_cgi_k_e11d" },
        ["arccw_sops_galactic_prototypeblaster"] = { InventoryItemID = "arccw_sops_galactic_prototypeblaster" },
        ["arccw_k_relbv15"] = { InventoryItemID = "arccw_k_relbv15" },
        ["arccw_k_dc15a_stun"] = { InventoryItemID = "arccw_k_dc15a_stun" },
        ["arccw_k_dc15a_train"] = { InventoryItemID = "arccw_k_dc15a_train" },
        ["arccw_sops_galactic_deathwatchblaster"] = { InventoryItemID = "arccw_sops_galactic_deathwatchblaster" },
        ["arccw_k_dp9"] = { InventoryItemID = "arccw_k_dp9" },
        ["arccw_cgi_k_e10"] = { InventoryItemID = "arccw_cgi_k_e10" },
        ["arccw_k_e10"] = { InventoryItemID = "arccw_k_e10" },
        ["arccw_cgi_k_e11_stun"] = { InventoryItemID = "arccw_cgi_k_e11_stun" },
        ["arccw_k_e11_stun"] = { InventoryItemID = "arccw_k_e11_stun" },
        ["arccw_cgi_k_e11_training"] = { InventoryItemID = "arccw_cgi_k_e11_training" },
        ["arccw_k_e11_training"] = { InventoryItemID = "arccw_k_e11_training" },
        ["arccw_k_e9"] = { InventoryItemID = "arccw_k_e9" },
        ["arccw_k_huttsplitter"] = { InventoryItemID = "arccw_k_huttsplitter" },
        ["arccw_cgi_k_dc15a_purge"] = { InventoryItemID = "arccw_cgi_k_dc15a_purge" },
        ["arccw_k_m45"] = { InventoryItemID = "arccw_k_m45" },
        ["arccw_k_m45x"] = { InventoryItemID = "arccw_k_m45x" },
        ["arccw_k_a180_rifle"] = { InventoryItemID = "arccw_k_a180_rifle" },
        ["arccw_k_a280"] = { InventoryItemID = "arccw_k_a280" },
        ["arccw_k_a280c"] = { InventoryItemID = "arccw_k_a280c" },
        ["arccw_sops_galactic_a280cfe"] = { InventoryItemID = "arccw_sops_galactic_a280cfe" },
        ["arccw_k_a280s"] = { InventoryItemID = "arccw_k_a280s" },
        ["arccw_k_cgi_an14"] = { InventoryItemID = "arccw_k_cgi_an14" },
        ["arccw_sops_galactic_b0l3"] = { InventoryItemID = "arccw_sops_galactic_b0l3" },
        ["arccw_k_cgi_btx32"] = { InventoryItemID = "arccw_k_cgi_btx32" },
        ["arccw_k_c11"] = { InventoryItemID = "arccw_k_c11" },
        ["arccw_k_cgi_dc10"] = { InventoryItemID = "arccw_k_cgi_dc10" },
        ["arccw_k_dc15a"] = { InventoryItemID = "arccw_k_dc15a" },
        ["arccw_k_dc15a_grenadier"] = { InventoryItemID = "arccw_k_dc15a_grenadier" },
        ["arccw_sops_galactic_dca4"] = { InventoryItemID = "arccw_sops_galactic_dca4" },
        ["arccw_k_dt57"] = { InventoryItemID = "arccw_k_dt57" },
        ["arccw_k_e105"] = { InventoryItemID = "arccw_k_e105" },
        ["arccw_k_e10r"] = { InventoryItemID = "arccw_k_e10r" },
        ["arccw_cgi_k_e11"] = { InventoryItemID = "arccw_cgi_k_e11" },
        ["arccw_k_e11"] = { InventoryItemID = "arccw_k_e11" },
        ["arccw_k_e11t"] = { InventoryItemID = "arccw_k_e11t" },
        ["arccw_k_e5"] = { InventoryItemID = "arccw_k_e5" },
        ["arccw_k_e5c"] = { InventoryItemID = "arccw_k_e5c" },
        ["arccw_k_republic_e9"] = { InventoryItemID = "arccw_k_republic_e9" },
        ["arccw_k_f10"] = { InventoryItemID = "arccw_k_f10" },
        ["arccw_k_f11"] = { InventoryItemID = "arccw_k_f11" },
        ["arccw_k_gau10r"] = { InventoryItemID = "arccw_k_gau10r" },
        ["arccw_cgi_k_imperial_dc17m_rifle"] = { InventoryItemID = "arccw_cgi_k_imperial_dc17m_rifle" },
        ["arccw_k_ka74"] = { InventoryItemID = "arccw_k_ka74" },
        ["arccw_k_mk2paladin"] = { InventoryItemID = "arccw_k_mk2paladin" },
        ["arccw_k_purge_dc15a"] = { InventoryItemID = "arccw_k_purge_dc15a" },
        ["arccw_k_stw48"] = { InventoryItemID = "arccw_k_stw48" },
        ["arccw_k_stw48c"] = { InventoryItemID = "arccw_k_stw48c" },
        ["arccw_sops_empire_stw48"] = { InventoryItemID = "arccw_sops_empire_stw48" },
        ["arccw_k_umbaranrifle"] = { InventoryItemID = "arccw_k_umbaranrifle" },
        ["arccw_k_vsspyke"] = { InventoryItemID = "arccw_k_vsspyke" },
        ["arccw_cgi_k_westarm5"] = { InventoryItemID = "arccw_cgi_k_westarm5" },
        ["arccw_k_cgi_westar35r"] = { InventoryItemID = "arccw_k_cgi_westar35r" },
        ["arccw_k_cgi_westar35sc"] = { InventoryItemID = "arccw_k_cgi_westar35sc" },
        ["arccw_k_m45c"] = { InventoryItemID = "arccw_k_m45c" },
        ["arccw_k_a280cfe_rifle"] = { InventoryItemID = "arccw_k_a280cfe_rifle" },
        ["arccw_k_a280_extended"] = { InventoryItemID = "arccw_k_a280_extended" },
        ["arccw_k_a280su"] = { InventoryItemID = "arccw_k_a280su" },
        ["arccw_k_a287"] = { InventoryItemID = "arccw_k_a287" },
        ["arccw_k_a650"] = { InventoryItemID = "arccw_k_a650" },
        ["arccw_k_bk43"] = { InventoryItemID = "arccw_k_bk43" },
        ["arccw_k_bowcaster"] = { InventoryItemID = "arccw_k_bowcaster" },
        ["arccw_k_dc17m_rifle_republic"] = { InventoryItemID = "arccw_k_dc17m_rifle_republic" },
        ["arccw_k_cgi_dc21"] = { InventoryItemID = "arccw_k_cgi_dc21" },
        ["arccw_k_dlt20s"] = { InventoryItemID = "arccw_k_dlt20s" },
        ["arccw_k_e105e"] = { InventoryItemID = "arccw_k_e105e" },
        ["arccw_k_e22"] = { InventoryItemID = "arccw_k_e22" },
        ["arccw_k_e4"] = { InventoryItemID = "arccw_k_e4" },
        ["arccw_sops_galactic_galaar15"] = { InventoryItemID = "arccw_sops_galactic_galaar15" },
        ["arccw_k_dc17m_rifle"] = { InventoryItemID = "arccw_k_dc17m_rifle" },
        ["arccw_k_westarm5"] = { InventoryItemID = "arccw_k_westarm5" },
        ["arccw_k_cgi_westar35c"] = { InventoryItemID = "arccw_k_cgi_westar35c" },
        ["arccw_k_dc15le"] = { InventoryItemID = "arccw_k_dc15le" },
        ["arccw_k_e105d"] = { InventoryItemID = "arccw_k_e105d" },
        ["arccw_k_e11d"] = { InventoryItemID = "arccw_k_e11d" },
        ["arccw_k_e5bx"] = { InventoryItemID = "arccw_k_e5bx" },
        ["arccw_k_cgi_e7"] = { InventoryItemID = "arccw_k_cgi_e7" },
        ["arccw_k_f11d"] = { InventoryItemID = "arccw_k_f11d" },
        ["arccw_k_a475"] = { InventoryItemID = "arccw_k_a475" },
        ["arccw_k_bowcaster_ext"] = { InventoryItemID = "arccw_k_bowcaster_ext" },
        ["arccw_k_geonosianblaster"] = { InventoryItemID = "arccw_k_geonosianblaster" },
        ["arccw_k_t21"] = { InventoryItemID = "arccw_k_t21" },
        ["arccw_k_an11"] = { InventoryItemID = "arccw_k_an11" },
        ["arccw_k_iqa11c"] = { InventoryItemID = "arccw_k_iqa11c" },
        ["arccw_k_dlt20a"] = { InventoryItemID = "arccw_k_dlt20a" },
        ["arccw_k_iqa11"] = { InventoryItemID = "arccw_k_iqa11" },
        ["arccw_k_mx1aquiles"] = { InventoryItemID = "arccw_k_mx1aquiles" },
        ["arccw_sops_republic_rx21"] = { InventoryItemID = "arccw_sops_republic_rx21" },
        ["arccw_k_ca87"] = { InventoryItemID = "arccw_k_ca87" },
        ["arccw_k_dlt19x"] = { InventoryItemID = "arccw_k_dlt19x" },
        ["arccw_k_dlt20x"] = { InventoryItemID = "arccw_k_dlt20x" },
        ["arccw_k_iqa11e"] = { InventoryItemID = "arccw_k_iqa11e" },
        ["arccw_k_rr11k"] = { InventoryItemID = "arccw_k_rr11k" },
        ["arccw_sops_galactic_deadmansrevenge"] = { InventoryItemID = "arccw_sops_galactic_deadmansrevenge" },
        ["arccw_sops_galactic_deadmanstale"] = { InventoryItemID = "arccw_sops_galactic_deadmanstale" },
        ["arccw_sops_galactic_mandorifle"] = { InventoryItemID = "arccw_sops_galactic_mandorifle" },
        ["arccw_sops_galactic_emprifle"] = { InventoryItemID = "arccw_sops_galactic_emprifle" },
        ["arccw_k_a180_shotgun"] = { InventoryItemID = "arccw_k_a180_shotgun" },
        ["arccw_k_cgi_btx12"] = { InventoryItemID = "arccw_k_cgi_btx12" },
        ["arccw_k_cyclerobrez"] = { InventoryItemID = "arccw_k_cyclerobrez" },
        ["arccw_k_dc17m_shotgun_republic"] = { InventoryItemID = "arccw_k_dc17m_shotgun_republic" },
        ["arccw_cgi_k_e11shotgun"] = { InventoryItemID = "arccw_cgi_k_e11shotgun" },
        ["arccw_k_dp23"] = { InventoryItemID = "arccw_k_dp23" },
        ["arccw_k_dp23c"] = { InventoryItemID = "arccw_k_dp23c" },
        ["arccw_k_ee9"] = { InventoryItemID = "arccw_k_ee9" },
        ["arccw_cgi_k_imperial_dc17m_shotgun"] = { InventoryItemID = "arccw_cgi_k_imperial_dc17m_shotgun" },
        ["arccw_k_dc17m_shotgun"] = { InventoryItemID = "arccw_k_dc17m_shotgun" },
        ["arccw_k_jnd41"] = { InventoryItemID = "arccw_k_jnd41" },
        ["arccw_k_sb2"] = { InventoryItemID = "arccw_k_sb2" },
        ["arccw_k_cgi_sc16"] = { InventoryItemID = "arccw_k_cgi_sc16" },
        ["arccw_k_scatter"] = { InventoryItemID = "arccw_k_scatter" },
        ["arccw_sops_galactic_scatterpistol"] = { InventoryItemID = "arccw_sops_galactic_scatterpistol" },
        ["arccw_k_sg6"] = { InventoryItemID = "arccw_k_sg6" },
        ["arccw_k_umbaranshotgun"] = { InventoryItemID = "arccw_k_umbaranshotgun" },
        ["arccw_k_cgi_westar35sg"] = { InventoryItemID = "arccw_k_cgi_westar35sg" },
        ["arccw_sops_galactic_wookieslug"] = { InventoryItemID = "arccw_sops_galactic_wookieslug" },
        ["arccw_k_edgesh"] = { InventoryItemID = "arccw_k_edgesh" },
        ["arccw_k_md12"] = { InventoryItemID = "arccw_k_md12" },
        ["arccw_k_sx21"] = { InventoryItemID = "arccw_k_sx21" },
        ["arccw_sops_republic_md12x"] = { InventoryItemID = "arccw_sops_republic_md12x" },
        ["arccw_k_ee3e"] = { InventoryItemID = "arccw_k_ee3e" },
        ["arccw_k_ee3s"] = { InventoryItemID = "arccw_k_ee3s" },
        ["arccw_k_umbaransniper"] = { InventoryItemID = "arccw_k_umbaransniper" },
        ["arccw_k_relbyv10"] = { InventoryItemID = "arccw_k_relbyv10" },
        ["arccw_k_x8"] = { InventoryItemID = "arccw_k_x8" },
        ["arccw_k_a280cfe_sniper"] = { InventoryItemID = "arccw_k_a280cfe_sniper" },
        ["arccw_k_a180_sniper"] = { InventoryItemID = "arccw_k_a180_sniper" },
        ["arccw_k_valken38i"] = { InventoryItemID = "arccw_k_valken38i" },
        ["arccw_k_dc17m_sniper_republic"] = { InventoryItemID = "arccw_k_dc17m_sniper_republic" },
        ["arccw_k_e9x"] = { InventoryItemID = "arccw_k_e9x" },
        ["arccw_k_dc17m_sniper"] = { InventoryItemID = "arccw_k_dc17m_sniper" },
        ["arccw_k_valken38"] = { InventoryItemID = "arccw_k_valken38" },
        ["arccw_sops_empire_e11x"] = { InventoryItemID = "arccw_sops_empire_e11x" },
        ["arccw_k_nt240"] = { InventoryItemID = "arccw_k_nt240" },
        ["arccw_k_dc15x"] = { InventoryItemID = "arccw_k_dc15x" },
        ["arccw_k_dc15xr"] = { InventoryItemID = "arccw_k_dc15xr" },
        ["arccw_k_e11s"] = { InventoryItemID = "arccw_k_e11s" },
        ["arccw_k_cgi_westarm5_sniper"] = { InventoryItemID = "arccw_k_cgi_westarm5_sniper" },
        ["arccw_k_nt242e"] = { InventoryItemID = "arccw_k_nt242e" },
        ["arccw_k_nt242x"] = { InventoryItemID = "arccw_k_nt242x" },
        ["arccw_k_cgi_iqa11"] = { InventoryItemID = "arccw_k_cgi_iqa11" },
        ["arccw_sops_empire_dlt19d"] = { InventoryItemID = "arccw_sops_empire_dlt19d" },
        ["arccw_cgi_k_e11x"] = { InventoryItemID = "arccw_cgi_k_e11x" },
        ["arccw_k_nt242"] = { InventoryItemID = "arccw_k_nt242" },
        ["arccw_sops_empire_firepuncher"] = { InventoryItemID = "arccw_sops_empire_firepuncher" },
        ["arccw_sops_empire_shortfirepuncher"] = { InventoryItemID = "arccw_sops_empire_shortfirepuncher" },
        ["arccw_sops_republic_773firepuncher"] = { InventoryItemID = "arccw_sops_republic_773firepuncher" },
        ["arccw_sops_republic_773firepuncher_short"] = { InventoryItemID = "arccw_sops_republic_773firepuncher_short" },
        ["arccw_sops_republic_t702"] = { InventoryItemID = "arccw_sops_republic_t702" },
        ["arccw_k_e5s"] = { InventoryItemID = "arccw_k_e5s" },
        ["arccw_k_cycler"] = { InventoryItemID = "arccw_k_cycler" },
        ["arccw_cgi_k_imperial_dc17m_sniper"] = { InventoryItemID = "arccw_cgi_k_imperial_dc17m_sniper" },
        ["arccw_k_cgi_nt220"] = { InventoryItemID = "arccw_k_cgi_nt220" },
        ["arccw_k_cgi_nt240x"] = { InventoryItemID = "arccw_k_cgi_nt240x" },
        ["arccw_k_cgi_westar35s"] = { InventoryItemID = "arccw_k_cgi_westar35s" },
        ["arccw_sops_galactic_b1na"] = { InventoryItemID = "arccw_sops_galactic_b1na" },
        ["arccw_k_cr2"] = { InventoryItemID = "arccw_k_cr2" },
        ["arccw_k_cr2c"] = { InventoryItemID = "arccw_k_cr2c" },
        ["arccw_cgi_k_dlt19_stun"] = { InventoryItemID = "arccw_cgi_k_dlt19_stun" },
        ["arccw_k_dlt19_stun"] = { InventoryItemID = "arccw_k_dlt19_stun" },
        ["arccw_cgi_k_dlt19_training"] = { InventoryItemID = "arccw_cgi_k_dlt19_training" },
        ["arccw_k_dlt19_training"] = { InventoryItemID = "arccw_k_dlt19_training" },
        ["arccw_k_dlt23"] = { InventoryItemID = "arccw_k_dlt23" },
        ["arccw_sops_empire_dlt34"] = { InventoryItemID = "arccw_sops_empire_dlt34" },
        ["arccw_k_fwmb10"] = { InventoryItemID = "arccw_k_fwmb10" },
        ["arccw_cgi_k_t21p"] = { InventoryItemID = "arccw_cgi_k_t21p" },
        ["arccw_k_t39"] = { InventoryItemID = "arccw_k_t39" },
        ["arccw_sops_galactic_tl30"] = { InventoryItemID = "arccw_sops_galactic_tl30" },
        ["arccw_k_cgi_westar35smg"] = { InventoryItemID = "arccw_k_cgi_westar35smg" },
        ["arccw_k_z1p"] = { InventoryItemID = "arccw_k_z1p" },
        ["arccw_k_z6"] = { InventoryItemID = "arccw_k_z6" },
        ["arccw_k_z6adv"] = { InventoryItemID = "arccw_k_z6adv" },
        ["arccw_sops_republic_z6chaingun"] = { InventoryItemID = "arccw_sops_republic_z6chaingun" },
        ["arccw_cgi_k_z6i"] = { InventoryItemID = "arccw_cgi_k_z6i" },
        ["arccw_k_z6i"] = { InventoryItemID = "arccw_k_z6i" },
        ["arccw_cgi_k_z6ichain"] = { InventoryItemID = "arccw_cgi_k_z6ichain" },
        ["arccw_k_cgi_btx42pistol"] = { InventoryItemID = "arccw_k_cgi_btx42pistol" },
        ["arccw_k_cr2hp"] = { InventoryItemID = "arccw_k_cr2hp" },
        ["arccw_k_cr2s"] = { InventoryItemID = "arccw_k_cr2s" },
        ["arccw_k_dc40"] = { InventoryItemID = "arccw_k_dc40" },
        ["arccw_cgi_k_dlt19"] = { InventoryItemID = "arccw_cgi_k_dlt19" },
        ["arccw_k_dlt19"] = { InventoryItemID = "arccw_k_dlt19" },
        ["arccw_sops_empire_dlt23v"] = { InventoryItemID = "arccw_sops_empire_dlt23v" },
        ["arccw_sops_republic_dlt23v"] = { InventoryItemID = "arccw_sops_republic_dlt23v" },
        ["arccw_k_dlt74"] = { InventoryItemID = "arccw_k_dlt74" },
        ["arccw_k_eweb"] = { InventoryItemID = "arccw_k_eweb" },
        ["arccw_cgi_k_evoblaster"] = { InventoryItemID = "arccw_cgi_k_evoblaster" },
        ["arccw_k_fwmb10h"] = { InventoryItemID = "arccw_k_fwmb10h" },
        ["arccw_sops_empire_heavyrepeater"] = { InventoryItemID = "arccw_sops_empire_heavyrepeater" },
        ["arccw_k_rt97"] = { InventoryItemID = "arccw_k_rt97" },
        ["arccw_cgi_k_t21b"] = { InventoryItemID = "arccw_cgi_k_t21b" },
        ["arccw_sops_empire_tl40"] = { InventoryItemID = "arccw_sops_empire_tl40" },
        ["arccw_sops_empire_tl50"] = { InventoryItemID = "arccw_sops_empire_tl50" },
        ["arccw_k_cgi_westar35_gau"] = { InventoryItemID = "arccw_k_cgi_westar35_gau" },
        ["arccw_k_cgi_westarm5_heavy"] = { InventoryItemID = "arccw_k_cgi_westarm5_heavy" },
        ["arccw_k_z4"] = { InventoryItemID = "arccw_k_z4" },
        ["arccw_k_z6b"] = { InventoryItemID = "arccw_k_z6b" },
        ["arccw_cgi_k_z6iadv"] = { InventoryItemID = "arccw_cgi_k_z6iadv" },
        ["arccw_k_dc40c"] = { InventoryItemID = "arccw_k_dc40c" },
        ["arccw_k_dlt19_heavy"] = { InventoryItemID = "arccw_k_dlt19_heavy" },
        ["arccw_cgi_k_dlt19s"] = { InventoryItemID = "arccw_cgi_k_dlt19s" },
        ["arccw_k_fwmb10k"] = { InventoryItemID = "arccw_k_fwmb10k" },
        ["arccw_sops_galactic_r1ca"] = { InventoryItemID = "arccw_sops_galactic_r1ca" },
        ["arccw_k_rt97c"] = { InventoryItemID = "arccw_k_rt97c" },
        ["arccw_k_rt97h"] = { InventoryItemID = "arccw_k_rt97h" },
        ["arccw_k_cgi_t20"] = { InventoryItemID = "arccw_k_cgi_t20" },
        ["arccw_cgi_k_t21"] = { InventoryItemID = "arccw_cgi_k_t21" },
        ["arccw_k_cgi_t22"] = { InventoryItemID = "arccw_k_cgi_t22" },
        ["arccw_k_tl50"] = { InventoryItemID = "arccw_k_tl50" },
        ["arccw_k_valken40tt"] = { InventoryItemID = "arccw_k_valken40tt" },
        ["arccw_k_dl99"] = { InventoryItemID = "arccw_k_dl99" },
        ["arccw_k_dt29"] = { InventoryItemID = "arccw_k_dt29" },
        ["arccw_sops_quadblaster_republic"] = { InventoryItemID = "arccw_sops_quadblaster_republic" },
        ["arccw_sops_quadblaster_empire"] = { InventoryItemID = "arccw_sops_quadblaster_empire" },
        ["arccw_k_t21b"] = { InventoryItemID = "arccw_k_t21b" },
        ["arccw_sops_republic_z6x"] = { InventoryItemID = "arccw_sops_republic_z6x" },
        ["arccw_k_dlt16_galexp"] = { InventoryItemID = "arccw_k_dlt16_galexp" },
        ["arccw_k_dlt19_galexp"] = { InventoryItemID = "arccw_k_dlt19_galexp" },
        ["arccw_k_dlt19d"] = { InventoryItemID = "arccw_k_dlt19d" },
        ["arccw_k_dlt19h_galexp"] = { InventoryItemID = "arccw_k_dlt19h_galexp" },
        ["arccw_k_nade_bacta"] = { InventoryItemID = "arccw_k_nade_bacta" },
        ["arccw_k_nade_decoy"] = { InventoryItemID = "arccw_k_nade_decoy" },
        ["arccw_k_nade_flashbang"] = { InventoryItemID = "arccw_k_nade_flashbang" },
        ["arccw_k_nade_smoke"] = { InventoryItemID = "arccw_k_nade_smoke" },
        ["arccw_k_nade_sonar"] = { InventoryItemID = "arccw_k_nade_sonar" },
        ["arccw_k_nade_stun"] = { InventoryItemID = "arccw_k_nade_stun" },
        ["arccw_k_nade_blaststick"] = { InventoryItemID = "arccw_k_nade_blaststick" },
        ["arccw_k_nade_c25"] = { InventoryItemID = "arccw_k_nade_c25" },
        ["arccw_k_nade_thermal"] = { InventoryItemID = "arccw_k_nade_thermal" },
        ["arccw_k_nade_dioxis"] = { InventoryItemID = "arccw_k_nade_dioxis" },
        ["arccw_k_nade_impact"] = { InventoryItemID = "arccw_k_nade_impact" },
        ["arccw_k_weapon_antimaterial"] = { InventoryItemID = "arccw_k_weapon_antimaterial" },
        ["arccw_k_nade_plasmagrenade"] = { InventoryItemID = "arccw_k_nade_plasmagrenade" },
        ["arccw_k_nade_shock"] = { InventoryItemID = "arccw_k_nade_shock" },
        ["arccw_k_nade_thermite"] = { InventoryItemID = "arccw_k_nade_thermite" },
        ["arccw_k_nade_c14"] = { InventoryItemID = "arccw_k_nade_c14" },
        ["arccw_k_nade_detonite"] = { InventoryItemID = "arccw_k_nade_detonite" },
        ["arccw_k_nade_sequencecharger"] = { InventoryItemID = "arccw_k_nade_sequencecharger" },
        ["arccw_k_nade_thermalimploder"] = { InventoryItemID = "arccw_k_nade_thermalimploder" },
        ["arccw_k_nade_antitankmine"] = { InventoryItemID = "arccw_k_nade_antitankmine" },
        ["arccw_k_dc17m_launcher_republic"] = { InventoryItemID = "arccw_k_dc17m_launcher_republic" },
        ["arccw_sops_galactic_fc1"] = { InventoryItemID = "arccw_sops_galactic_fc1" },
        ["arccw_k_weapon_g125"] = { InventoryItemID = "arccw_k_weapon_g125" },
        ["arccw_k_dc17m_launcher"] = { InventoryItemID = "arccw_k_dc17m_launcher" },
        ["arccw_k_cgi_rps4"] = { InventoryItemID = "arccw_k_cgi_rps4" },
        ["arccw_k_cgi_z6x_ion"] = { InventoryItemID = "arccw_k_cgi_z6x_ion" },
        ["arccw_k_launcher_e60r"] = { InventoryItemID = "arccw_k_launcher_e60r" },
        ["arccw_k_launcher_hh12_empire"] = { InventoryItemID = "arccw_k_launcher_hh12_empire" },
        ["arccw_k_launcher_plx1_empire"] = { InventoryItemID = "arccw_k_launcher_plx1_empire" },
        ["arccw_k_launcher_rps6_empire"] = { InventoryItemID = "arccw_k_launcher_rps6_empire" },
        ["arccw_k_launcher_hh12"] = { InventoryItemID = "arccw_k_launcher_hh12" },
        ["arccw_k_launcher_plx1"] = { InventoryItemID = "arccw_k_launcher_plx1" },
        ["arccw_k_launcher_rps6"] = { InventoryItemID = "arccw_k_launcher_rps6" },
        ["arccw_k_launcher_smartlauncher"] = { InventoryItemID = "arccw_k_launcher_smartlauncher" },
        ["arccw_k_melee_bobaton"] = { InventoryItemID = "arccw_k_melee_bobaton" },
        ["arccw_k_coruscantguardshield"] = { InventoryItemID = "arccw_k_coruscantguardshield" },
        ["arccw_k_melee_dagger"] = { InventoryItemID = "arccw_k_melee_dagger" },
        ["arccw_k_melee_hammer"] = { InventoryItemID = "arccw_k_melee_hammer" },
        ["arccw_k_melee_staff"] = { InventoryItemID = "arccw_k_melee_staff" },
        ["arccw_cgi_k_empireshield"] = { InventoryItemID = "arccw_cgi_k_empireshield" },
        ["arccw_k_republicshield"] = { InventoryItemID = "arccw_k_republicshield" },
        ["arccw_k_melee_pike"] = { InventoryItemID = "arccw_k_melee_pike" },
        ["arccw_k_melee_empireshield"] = { InventoryItemID = "arccw_k_melee_empireshield" },
        ["arccw_k_melee_preatorian"] = { InventoryItemID = "arccw_k_melee_preatorian" },
        ["arccw_k_melee_riotbaton"] = { InventoryItemID = "arccw_k_melee_riotbaton" },
        ["arccw_k_melee_riotstaff"] = { InventoryItemID = "arccw_k_melee_riotstaff" },
        ["arccw_k_cgi_vibrokatana"] = { InventoryItemID = "arccw_k_cgi_vibrokatana" },
        ["arccw_sops_vibroknife"] = { InventoryItemID = "arccw_sops_vibroknife" },
        ["arccw_k_dc17m_allinone"] = { InventoryItemID = "arccw_k_dc17m_allinone" },
        ["arccw_k_arccaster"] = { InventoryItemID = "arccw_k_arccaster" },
        ["arccw_sops_galactic_iondisruptor"] = { InventoryItemID = "arccw_sops_galactic_iondisruptor" },
    },

    Preview = {
        Enabled = true,
        FOV = 34,
        Spin = true,
        SpinSpeed = 9,
        FallbackModel = "models/weapons/w_pistol.mdl",
        AmbientLight = Color(72, 88, 105),
    },

    -- "Take weapon" moves the weapon to grn_inventory; it is then equipped from I.
    -- "Return all" removes only the items retrieved during this armory
    -- session, without using StripWeapons or affecting weapons outside the system.
    SetsPDataKey = "grn_armory_sets_v1",
    MaxSets = 4,
    MaxWeaponsPerSet = 8,
}

-- =========================================================
-- Staff editor safety limits
-- =========================================================
C.Limits = {
    MaxCategories = 40,
    MaxProducts = 500,
    MaxPrice = 2000000000,
    MaxNameLength = 64,
    MaxDescriptionLength = 500,
    MaxClassLength = 160,
    MaxPreviewModelLength = 200,
}

-- Base categories. Staff may edit name/icon/description,
-- but cannot delete them while ProtectBaseCategories is true.
C.ProtectBaseCategories = true
C.DefaultCategories = {
    { id = "models",   name = "MODELLE",  icon = "fa-solid fa-user-astronaut", desc = "Charaktermodelle und Skins im Shop." },
    { id = "upgrades", name = "UPGRADES", icon = "fa-solid fa-arrow-up-right-dots", desc = "Dauerhafte Spieler-Upgrades." },
}

-- Legacy categories removed from this version of the store.
-- loadStore() also removes them from an existing data/grn_store/store.json.
C.RemovedCategoryIDs = {
    weapons = true,
    weapon = true,
    pistols = true,
    dual = true,
    carbines = true,
    rifles = true,
    shotguns = true,
    snipers = true,
    heavy = true,
    explosives = true,
    melee = true,
    special = true,
    vehicles = true,
    entities = true,
    pets = true,
    ranks = true,
}

C.RemovedCategoryNames = {
    ["weapons"] = true,
    ["armas"] = true,
    ["pistols"] = true,
    ["dual weapons"] = true,
    ["carbines"] = true,
    ["rifles"] = true,
    ["shotguns"] = true,
    ["sniper rifles"] = true,
    ["heavy weapons"] = true,
    ["explosives"] = true,
    ["melee"] = true,
    ["special weapons"] = true,
    ["vehicles"] = true,
    ["vehiculos"] = true,
    ["vehículos"] = true,
    ["entities"] = true,
    ["entidades"] = true,
    ["pets"] = true,
    ["mascotas"] = true,
    ["ranks"] = true,
    ["rangos"] = true,
}

C.RemovedProductIDs = {
    service_pistol = true,
    pistol_service = true,
    weapon_service_pistol = true,
    citizen_model = true,
    model_citizen = true,
    supply_crate = true,
    entity_supply_crate = true,
}

C.RemovedProductNames = {
    ["service pistol"] = true,
    ["pistola de servicio"] = true,
    ["citizen model"] = true,
    ["modelo ciudadano"] = true,
    ["supply crate"] = true,
    ["caja de suministros"] = true,
}


-- Functional default products. You may delete them from the Staff panel.
-- className = actual class that is granted/spawned.
-- previewModel = model shown in the 3D overlay. If left empty,
-- the client tries to resolve the SWEP WorldModel or the entity Model.
C.DefaultProducts = {
    {
        id = "vision_nocturna",
        name = "Nachtsicht",
        category = "upgrades",
        type = "upgrade",
        price = 12000,
        className = "grn_nightvision",
        previewModel = "models/items/battery.mdl",
        rarity = "blue",
        purchaseType = "permanent",
        duration = 0,
        description = "Schaltet dauerhaft die Nachtsicht frei.",
    },
    {
        id = "visor",
        name = "Visor",
        category = "upgrades",
        type = "upgrade",
        price = 10000,
        className = "grn_visorzoom",
        previewModel = "models/vortexgaming/tc13u/armor/visor.mdl",
        rarity = "blue",
        purchaseType = "permanent",
        duration = 0,
        description = "Schaltet dauerhaft den Visier-Zoom frei.",
    },
}


-- =========================================================
-- Products required by integrations
-- =========================================================
-- These products are automatically registered even if
-- data/grn_store/store.json already exists. Only the required technical fields
-- are forced so integrations keep working; price/name/description can
-- be edited from the Staff panel.
C.RequiredProducts = {
    {
        id = "vision_nocturna",
        name = "Nachtsicht",
        category = "upgrades",
        type = "upgrade",
        price = 12000,
        className = "grn_nightvision",
        previewModel = "models/items/battery.mdl",
        rarity = "blue",
        purchaseType = "permanent",
        duration = 0,
        description = "Schaltet dauerhaft die Nachtsicht frei.",
        forceFields = {
            "category",
            "type",
            "className",
            "previewModel",
            "purchaseType",
            "duration",
        },
    },
    {
        id = "visor",
        name = "Visor",
        category = "upgrades",
        type = "upgrade",
        price = 10000,
        className = "grn_visorzoom",
        previewModel = "models/vortexgaming/tc13u/armor/visor.mdl",
        rarity = "blue",
        purchaseType = "permanent",
        duration = 0,
        description = "Schaltet dauerhaft den Visier-Zoom frei.",
        forceFields = {
            "category",
            "type",
            "className",
            "previewModel",
            "purchaseType",
            "duration",
        },
    },
}

-- If data/grn_store/store.json already exists, weapon products are also
-- registered as required so this new configuration can add them
-- without deleting the saved catalog. It does not force price/name; it only adds
-- missing products using the normal RequiredProducts logic.
for _, product in ipairs(C.DefaultProducts) do
    if product.type == "weapon" then
        C.RequiredProducts[#C.RequiredProducts + 1] = {
            id = product.id,
            name = product.name,
            category = product.category,
            type = product.type,
            price = product.price,
            className = product.className,
            previewModel = product.previewModel,
            rarity = product.rarity,
            purchaseType = product.purchaseType,
            duration = product.duration,
            description = product.description,
            forceFields = {
                "category",
                "type",
                "className",
                "previewModel",
                "purchaseType",
                "duration",
            },
        }
    end
end

-- Product types allowed by the Staff panel. models/vortexgaming/tc13u/armor/visor.mdl
C.AllowedProductTypes = {
    weapon = true,
    model = true,
    vehicle = true,
    entity = true,
    pet = true,
    upgrade = true,
    rank = true,
    other = true,
}

C.AllowedRarities = {
    cyan = true,
    blue = true,
    green = true,
    gold = true,
    red = true,
}

C.AllowedPurchaseTypes = {
    permanent = true,
    temporary = true,
    consumable = true,
}

-- Optional custom handlers. They run ONLY server-side.
-- If a function returns true, delivery is considered handled.
-- Example:
-- C.CustomGrantHandlers["mi_upgrade"] = function(ply, product, action)
--     if action == "purchase" then
--         ply:SetMaxHealth(ply:GetMaxHealth() + 25)
--         return true
--     end
-- end
C.CustomGrantHandlers = C.CustomGrantHandlers or {}
