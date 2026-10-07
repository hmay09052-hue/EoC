GRNInventory = GRNInventory or {}
GRNInventory.Config = GRNInventory.Config or {}

local INV = GRNInventory
local C = INV.Config
C.Items = C.Items or {}

-- ============================================================
-- JOB EQUIPMENT / ARMORY - ECHOES OF CLONES
-- ============================================================
-- Generated from the client's `weaponbox` job fields.
-- These items are stored in GRN Inventory and equipped individually from the I menu.
-- JobEquipment marks items that come from the Armory crate.
-- They now use the same four equipment slots as the rest of the inventory, so
-- the player only carries the equipment they actually selected.

-- Public helper so other files / addons can register items:
-- GRNInventory.RegisterItem("my_id", { Name = "...", Type = "weapon", WeaponClass = "...", EquipSlot = "primary" })
function INV.RegisterItem(id, data)
    id = tostring(id or "")
    if id == "" or not istable(data) then return end
    if data.Type == "weapon" and data.EquipSlot == "primary" and istable(C.SpecialWeaponClasses)
        and C.SpecialWeaponClasses[tostring(data.WeaponClass or "")] == true then
        data.EquipSlot = "specialized"
    end
    data.Name = data.Name or id
    data.Stack = math.max(1, math.floor(tonumber(data.Stack) or 1))
    data.Size = data.Size or { W = 1, H = 1 }
    data.Weight = tonumber(data.Weight) or 1
    data.Rarity = data.Rarity or "uncommon"
    data.Icon = data.Icon or "fa-gun"
    data.IconURL = data.IconURL or ""
    data.DropModel = data.DropModel or "models/props_junk/cardboard_box004a.mdl"
    data.Description = data.Description or ""
    C.Items[id] = data
    return data
end

local function register(id, data)
    data.JobEquipment = true
    data.Stack = 1
    data.Size = data.Size or { W = 1, H = 1 }
    data.Weight = tonumber(data.Weight) or 1
    data.Rarity = data.Rarity or "uncommon"
    data.Icon = data.Icon or "fa-gun"
    data.IconURL = data.IconURL or ""
    data.DropModel = data.DropModel or "models/props_junk/cardboard_box004a.mdl"
    data.Description = data.Description or "Für deinen aktuellen Job freigegebene Ausrüstung."
    C.Items[id] = data
end

local function weapon(id, name, className, slot, icon, weight)
    if slot == "primary" and istable(C.SpecialWeaponClasses) and C.SpecialWeaponClasses[className] == true then
        slot = "specialized"
    end

    register(id, {
        Name = name,
        Description = "Von der Waffenkammer für deinen aktuellen Job ausgegebene Ausrüstung.",
        Type = "weapon",
        EquipSlot = slot or "utility",
        WeaponClass = className,
        Icon = icon or "fa-gun",
        Rarity = "uncommon",
        Weight = tonumber(weight) or 1,
        Stack = 1,
        Size = { W = 1, H = 1 },
        DropModel = "models/props_junk/cardboard_box004a.mdl"
    })
end


weapon("eoc_job_arccw_k_nade_detonite", "Detonite Charge", "arccw_k_nade_detonite", "utility", "fa-bomb", 0.7)
weapon("eoc_job_arccw_k_dc15s", "DC-15S", "arccw_k_dc15s", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_dc15s_grenadier", "DC-15S Grenadier", "arccw_k_dc15s_grenadier", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_dc15a", "DC-15A", "arccw_k_dc15a", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_republicshield", "Republic Shield", "arccw_k_republicshield", "utility", "fa-shield-halved", 3.0)
weapon("eoc_job_arccw_k_nade_thermal", "Thermal Grenade", "arccw_k_nade_thermal", "utility", "fa-bomb", 0.7)
weapon("eoc_job_arccw_k_dc15le", "DC-15LE", "arccw_k_dc15le", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_launcher_smartlauncher", "Smart Launcher", "arccw_k_launcher_smartlauncher", "primary", "fa-gun", 3.5)
weapon("eoc_job_arccw_k_nade_c14", "C-14 Charge", "arccw_k_nade_c14", "utility", "fa-bomb", 0.7)
weapon("eoc_job_arccw_k_dc17_akimbo", "DC-17 Akimbo", "arccw_k_dc17_akimbo", "secondary", "fa-gun", 1.5)
weapon("eoc_job_weapon_cuff_handcuffs", "Handcuffs", "weapon_cuff_handcuffs", "utility", "fa-link", 1.0)
weapon("eoc_job_arccw_k_dc17ext_akimbo", "DC-17 Extended Akimbo", "arccw_k_dc17ext_akimbo", "secondary", "fa-gun", 1.5)
weapon("eoc_job_arccw_k_z6", "Z-6", "arccw_k_z6", "primary", "fa-gun", 4.0)
weapon("eoc_job_arccw_k_dc17sa_dual", "DC-17SA Dual", "arccw_k_dc17sa_dual", "secondary", "fa-gun", 1.5)
weapon("eoc_job_jet_mk5", "Jetpack MK5", "jet_mk5", "utility", "fa-jet-fighter-up", 4.0)
weapon("eoc_job_arccw_k_cr2c", "CR-2C", "arccw_k_cr2c", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_nade_smoke", "Smoke Grenade", "arccw_k_nade_smoke", "utility", "fa-bomb", 0.7)
weapon("eoc_job_arccw_k_nade_sonar", "Sonar Grenade", "arccw_k_nade_sonar", "utility", "fa-bomb", 0.7)
weapon("eoc_job_recondroidkit", "Recon Droid Kit", "recondroidkit", "utility", "fa-robot", 2.0)
weapon("eoc_job_arccw_k_dc15x", "DC-15X", "arccw_k_dc15x", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_nade_decoy", "Decoy Grenade", "arccw_k_nade_decoy", "utility", "fa-bomb", 0.7)
weapon("eoc_job_arccw_sops_republic_z6chaingun", "Z-6 Chaingun", "arccw_sops_republic_z6chaingun", "primary", "fa-gun", 4.0)
weapon("eoc_job_arccw_k_dp24", "DP-24", "arccw_k_dp24", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_nade_impact", "Impact Grenade", "arccw_k_nade_impact", "utility", "fa-bomb", 0.7)
weapon("eoc_job_arccw_k_dc15se", "DC-15SE", "arccw_k_dc15se", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_nade_bacta", "Bacta Grenade", "arccw_k_nade_bacta", "utility", "fa-bomb", 0.7)
weapon("eoc_job_arccw_sops_republic_dlt23v", "DLT-23V", "arccw_sops_republic_dlt23v", "primary", "fa-gun", 2.5)
weapon("eoc_job_cw_flamethrower", "Flamethrower", "cw_flamethrower", "primary", "fa-fire", 3.5)
weapon("eoc_job_arccw_k_dc15s_stun", "DC-15S Stun", "arccw_k_dc15s_stun", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_stw48", "ST-W48", "arccw_k_stw48", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_dc15a_stun", "DC-15A Stun", "arccw_k_dc15a_stun", "primary", "fa-gun", 2.5)
weapon("eoc_job_arccw_k_coruscantguardshield", "Coruscant Guard Shield", "arccw_k_coruscantguardshield", "utility", "fa-shield-halved", 3.0)
weapon("eoc_job_lscs_shock", "LSCS Shock", "lscs_shock", "utility", "fa-bolt", 1.0)
weapon("eoc_job_arccw_k_dc17sa", "DC-17SA", "arccw_k_dc17sa", "secondary", "fa-gun", 1.5)
weapon("eoc_job_shield_2_deployer", "Shield Deployer", "shield_2_deployer", "utility", "fa-shield-halved", 3.0)
weapon("eoc_job_arccw_k_dp23c", "DP-23C", "arccw_k_dp23c", "primary", "fa-gun", 2.5)

-- Visual upgrade: if the SWEP is installed, automatically use its PrintName
-- and WorldModel. The configured class does not change.
local function refreshWeaponMetadata()
    for _, def in pairs(C.Items or {}) do
        if istable(def) and def.JobEquipment == true and tostring(def.Type or "") == "weapon" then
            local className = tostring(def.WeaponClass or "")
            local stored = className ~= "" and weapons.GetStored(className) or nil
            if istable(stored) then
                local printName = string.Trim(tostring(stored.PrintName or ""))
                if printName ~= "" and printName ~= "Scripted Weapon" then
                    def.Name = printName
                end
                local worldModel = string.Trim(tostring(stored.WorldModel or ""))
                if worldModel ~= "" then
                    def.DropModel = worldModel
                end
            end
        end
    end
end

hook.Add("InitPostEntity", "GRNInventory_EOCJobEquipment_Metadata", function()
    timer.Simple(0, refreshWeaponMetadata)
    timer.Simple(2, refreshWeaponMetadata)
end)
