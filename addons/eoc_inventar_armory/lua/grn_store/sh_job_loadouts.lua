GRNStore = GRNStore or {}
GRNStore.Config = GRNStore.Config or {}

local C = GRNStore.Config
C.Armory = C.Armory or {}
local A = C.Armory

-- =========================================================
-- ARMORY LOADOUTS - ECHOES OF CLONES JOBS
-- =========================================================
-- Source: the `weaponbox` field of every DarkRP.createJob in jobs.lua.
-- The key of every entry MUST be exactly the `command` of the DarkRP job.
-- `weapons` of the job is NOT duplicated here: those stay the normal spawn
-- weapons of the job.
--
-- Items reference GRN Inventory item IDs (see grn_inventory/sh_job_armory_items.lua).
-- Armor items from grn_inventory/sh_armor.lua can be added here as well;
-- the armory crate then issues them like weapons (see ARMOR below).
--
-- After changing this file do a FULL server restart (not just a map change).

-- Short helper: J("arccw_k_dc15s") -> "eoc_job_arccw_k_dc15s"
local function J(...)
    local out = {}
    for _, class in ipairs({ ... }) do
        out[#out + 1] = "eoc_job_" .. class
    end
    return out
end

local function merge(...)
    local out, seen = {}, {}
    for _, list in ipairs({ ... }) do
        for _, id in ipairs(list) do
            if not seen[id] then
                seen[id] = true
                out[#out + 1] = id
            end
        end
    end
    return out
end

-- ---------------------------------------------------------
-- Kits (exactly the weaponbox contents of the jobs)
-- ---------------------------------------------------------
local KIT = {}

-- 501st Torrent Company
KIT.T501_PVT = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_republicshield", "arccw_k_nade_thermal")
KIT.T501_MAN = J("arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal")
KIT.T501_NCO = merge(KIT.T501_MAN, J("arccw_k_dc17_akimbo", "weapon_cuff_handcuffs"))
KIT.T501_OFF = merge(KIT.T501_MAN, J("arccw_k_dc17ext_akimbo", "weapon_cuff_handcuffs"))
KIT.T501_CPT = J("arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc15s", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17sa_dual", "weapon_cuff_handcuffs")

-- 501st BARC
KIT.BARC_MAN = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar")
KIT.BARC_NCO = merge(J("arccw_k_dc17_akimbo", "weapon_cuff_handcuffs"), KIT.BARC_MAN)

-- 501st ARF
KIT.ARF_MAN = J("arccw_k_dc15s", "recondroidkit", "arccw_k_dc15a", "arccw_k_dc15x", "arccw_k_nade_smoke", "arccw_k_nade_thermal")
KIT.ARF_NCO = merge(J("arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs"), KIT.ARF_MAN)

-- 501st Heavy
KIT.HEAVY_MAN = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun")
KIT.HEAVY_NCO = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun")

-- 501st Airborne
KIT.AB_MAN = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dp24", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar")
KIT.AB_NCO = J("arccw_k_dc15s", "arccw_k_dp24", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar")

-- 501st Medical
KIT.MED_MAN = J("arccw_k_dc15s", "arccw_k_dc15se", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "arccw_k_nade_thermal", "weapon_cuff_handcuffs", "arccw_k_nade_bacta")
KIT.MED_NCO = J("arccw_k_dc15s", "arccw_k_dc15se", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15a", "arccw_k_nade_thermal")
KIT.MED_LT = J("arccw_k_dc15s", "arccw_k_dc17ext_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15se", "arccw_k_dc15a", "arccw_k_nade_thermal")

-- 501st Engineering
KIT.ENG_MAN = J("arccw_k_dc15s", "arccw_sops_republic_dlt23v", "arccw_k_dc15a", "arccw_k_nade_thermal")
KIT.ENG_NCO = J("arccw_k_dc15s", "arccw_k_dc17_akimbo", "arccw_sops_republic_dlt23v", "arccw_k_dc15a", "arccw_k_nade_thermal", "weapon_cuff_handcuffs", "cw_flamethrower")
KIT.ENG_LT = J("arccw_k_dc15s", "cw_flamethrower", "arccw_k_dc17ext_akimbo", "arccw_sops_republic_dlt23v", "arccw_k_dc15a", "arccw_k_nade_thermal", "weapon_cuff_handcuffs")

-- 501st lore characters
KIT.LORE_STD = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_republicshield", "arccw_k_nade_c14", "arccw_k_nade_thermal")
KIT.REX = J("jet_mk5", "arccw_k_dc15a", "arccw_k_dc15s_grenadier", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17sa_dual", "weapon_cuff_handcuffs")
KIT.HARDCASE = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal")
KIT.CORIC = J("jet_mk5", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_c14", "arccw_k_nade_thermal")

-- Schocktruppen
KIT.ST_MAN = J("arccw_k_dc15s_stun", "arccw_k_stw48", "arccw_k_dc15a_stun", "arccw_k_coruscantguardshield", "arccw_k_nade_thermal", "lscs_shock")
KIT.ST_NCO = J("arccw_k_dc15s_stun", "arccw_k_stw48", "arccw_k_dc17_akimbo", "arccw_k_dc15a_stun", "arccw_k_coruscantguardshield", "arccw_k_nade_thermal")
KIT.ST_OFF = J("arccw_k_dc17ext_akimbo", "arccw_k_stw48", "arccw_k_dc15s_stun", "arccw_k_dc15a_stun", "arccw_k_coruscantguardshield", "arccw_k_nade_thermal", "lscs_shock")
KIT.ST_THORN = J("arccw_k_dc17ext_akimbo", "arccw_k_stw48", "arccw_k_dc15s_stun", "arccw_k_dc15a_stun", "arccw_k_coruscantguardshield", "arccw_k_nade_thermal")
KIT.STK9 = KIT.ST_NCO

-- Republic Navy
KIT.RN_CREW = J("arccw_k_dc15s", "arccw_k_dc17sa", "shield_2_deployer")
KIT.RN_NCO = J("arccw_k_dc15s", "arccw_k_dc17_akimbo", "arccw_k_dc17sa", "shield_2_deployer", "weapon_cuff_handcuffs")
KIT.RN_OFF = J("arccw_k_dc15s", "arccw_k_dc17ext_akimbo", "arccw_k_dc17sa", "shield_2_deployer", "weapon_cuff_handcuffs")
KIT.RN_STAFF = J("arccw_k_dc15s", "arccw_k_dc17sa_dual", "arccw_k_dc17sa", "shield_2_deployer", "weapon_cuff_handcuffs")

-- Republic Navy AVP
KIT.AVP_MAN = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dp23c", "arccw_k_nade_thermal")
KIT.AVP_NCO = J("arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dp23c", "weapon_cuff_handcuffs", "arccw_k_dc17_akimbo", "arccw_k_nade_thermal")

-- ---------------------------------------------------------
-- Rüstungssätze pro Einheit (Items aus grn_inventory/sh_armor.lua)
-- Reihenfolge: Kopf, Brust, Rücken, Hose
-- ---------------------------------------------------------
local ARMOR = {}
ARMOR.T501  = { "armor_helmet_p1", "armor_chest_standard", "armor_back_standard", "armor_hip_cadet" }
ARMOR.HEAVY = { "armor_helmet_heavy", "armor_chest_heavy", "armor_back_standard", "armor_hip_heavy" }
ARMOR.ARF   = { "armor_helmet_arf", "armor_chest_light", "armor_back_arc", "armor_hip_cadet" }
ARMOR.BARC  = { "armor_helmet_barc", "armor_chest_standard", "armor_back_standard", "armor_hip_cadet" }
ARMOR.AB    = { "armor_helmet_airborne", "armor_chest_standard", "armor_back_jetpack", "armor_hip_cadet" }
ARMOR.MED   = { "armor_helmet_p1", "armor_chest_medic", "armor_back_medic", "armor_hip_cadet" }
ARMOR.ENG   = { "armor_helmet_p1", "armor_chest_standard", "armor_back_tools", "armor_hip_tools" }
ARMOR.ST    = { "armor_helmet_p1", "armor_chest_guard", "armor_back_standard", "armor_hip_cadet" }
ARMOR.NAVY  = { "armor_helmet_pilot", "armor_chest_light", "armor_hip_cadet" }

-- Helm-Zubehör: jede 501st-Einheit kann sich eins davon im Kleiderschrank nehmen.
local HELMET_ACC = { "armor_acc_macrobinoculars", "armor_acc_rangefinder", "armor_acc_sunvisor" }
-- Rang- und Ausrüstungsteile: der Kleiderschrank zeigt nur, was der Rang
-- tragen darf (Freigabe in grn_inventory/sh_armor.lua, C.Armor.RankGear).
local RANK_GEAR = {
    "armor_rank_pauldron", "armor_rank_kama",
    "armor_holster_dual", "armor_holster_right",
}
for _, unit in ipairs({ "T501", "HEAVY", "ARF", "BARC", "AB", "MED", "ENG" }) do
    ARMOR[unit] = merge(ARMOR[unit], HELMET_ACC, RANK_GEAR)
end

-- Hängt einen Rüstungssatz an die genannten Waffen-Kits.
local function withArmor(armorKit, ...)
    for _, kitName in ipairs({ ... }) do
        if KIT[kitName] then KIT[kitName] = merge(KIT[kitName], armorKit) end
    end
end

withArmor(ARMOR.T501, "T501_PVT", "T501_MAN", "T501_NCO", "T501_OFF", "T501_CPT")
withArmor(ARMOR.HEAVY, "HEAVY_MAN", "HEAVY_NCO")
withArmor(ARMOR.ARF, "ARF_MAN", "ARF_NCO")
withArmor(ARMOR.BARC, "BARC_MAN", "BARC_NCO")
withArmor(ARMOR.AB, "AB_MAN", "AB_NCO")
withArmor(ARMOR.MED, "MED_MAN", "MED_NCO", "MED_LT")
withArmor(ARMOR.ENG, "ENG_MAN", "ENG_NCO", "ENG_LT")
withArmor(ARMOR.ST, "ST_MAN", "ST_NCO", "ST_OFF", "ST_THORN", "STK9")
withArmor(ARMOR.NAVY, "RN_CREW", "RN_NCO", "RN_OFF", "RN_STAFF", "AVP_MAN", "AVP_NCO")

-- Lore-Charaktere (passen auf kein Präfix):
-- Kix nutzt KIT.MED_NCO (Sanitäter), Boomer KIT.ARF_NCO (ARF),
-- Hardcase bekommt den Heavy-Satz, alle anderen den Torrent-Satz.
withArmor(ARMOR.HEAVY, "HARDCASE")
withArmor(ARMOR.T501, "LORE_STD", "REX", "CORIC")

-- ---------------------------------------------------------
-- Command -> kit
-- ---------------------------------------------------------
local byCommand = {}

local function add(command, name, items)
    byCommand[command] = { Name = name, Items = items }
end

local function ranks(prefix, namePrefix, list, items)
    for _, rank in ipairs(list) do
        add(prefix .. rank[1], namePrefix .. " | " .. rank[2], items)
    end
end

local MAN_RANKS = { { "pvt", "Private" }, { "pfc", "Private First Class" }, { "spc", "Specialist" }, { "lcpl", "Lance Corporal" } }
local NCO_RANKS = { { "cpl", "Corporal" }, { "ccpl", "Chief Corporal" }, { "fcpl", "First Corporal" }, { "sgt", "Sergeant" }, { "fsgt", "First Sergeant" }, { "sgm", "Sergeant Major" } }

-- Ausbildungsakademie
add("teamf", "Echoes of Clones Team on Duty", J("arccw_k_nade_detonite"))
-- "teambutzbach" (Gefangener) intentionally gets NO armory equipment.
-- "ausbilder" and "cadetss" only have weapon_fists in their weaponbox, which
-- they already receive through `weapons`, so they have no armory entry.

-- 501st Torrent Company
add("501st_pvt", "501st Torrent Company | Private", KIT.T501_PVT)
add("501st_pfc", "501st Torrent Company | Private First Class", KIT.T501_MAN)
add("501st_spc", "501st Torrent Company | Specialist", KIT.T501_MAN)
add("501st_lcpl", "501st Torrent Company | Lance Corporal", KIT.T501_MAN)
ranks("501st_", "501st Torrent Company", NCO_RANKS, KIT.T501_NCO)
add("501st_lt", "501st Torrent Company | Lieutenant", KIT.T501_OFF)
add("501st_1lt", "501st Torrent Company | First Lieutenant", KIT.T501_OFF)
add("501st_cpt", "501st Torrent Company | Captain", KIT.T501_CPT)

-- 501st BARC
ranks("501stbarc_", "501st BARC", MAN_RANKS, KIT.BARC_MAN)
ranks("501stbarc_", "501st BARC", NCO_RANKS, KIT.BARC_NCO)

-- 501st ARF
ranks("501starf_", "501st ARF", MAN_RANKS, KIT.ARF_MAN)
ranks("501starf_", "501st ARF", NCO_RANKS, KIT.ARF_NCO)

-- 501st Heavy Platoon
ranks("501stheavy_", "501st Heavy Platoon", MAN_RANKS, KIT.HEAVY_MAN)
ranks("501stheavy_", "501st Heavy Platoon", NCO_RANKS, KIT.HEAVY_NCO)

-- 501st Airborne Platoon
ranks("501stab_", "501st Airborne Platoon", MAN_RANKS, KIT.AB_MAN)
ranks("501stab_", "501st Airborne Platoon", NCO_RANKS, KIT.AB_NCO)

-- 501st Medical Platoon
ranks("501stmed_", "501st Medical Platoon", MAN_RANKS, KIT.MED_MAN)
ranks("501stmed_", "501st Medical Platoon", NCO_RANKS, KIT.MED_NCO)
add("501stmed_lt", "501st Medical Platoon | Lieutenant", KIT.MED_LT)

-- 501st Engineering Platoon
ranks("501steng_", "501st Engineering Platoon", MAN_RANKS, KIT.ENG_MAN)
ranks("501steng_", "501st Engineering Platoon", NCO_RANKS, KIT.ENG_NCO)
add("501steng_lt", "501st Engineering Platoon | Lieutenant", KIT.ENG_LT)

-- 501st lore characters
add("501strex", "501st | Rex", KIT.REX)
add("501stkix", "501st | Kix", KIT.MED_NCO)
add("501sthardcase", "501st | Hardcase", KIT.HARDCASE)
add("501stdogma", "501st | Dogma", KIT.LORE_STD)
add("501stboomer", "501st | Boomer", KIT.ARF_NCO)
add("501stappo", "501st | Appo", KIT.LORE_STD)
add("501stjesse", "501st | Jesse", KIT.LORE_STD)
add("501stecho", "501st | Echo", KIT.LORE_STD)
add("501stfives", "501st | Fives", KIT.LORE_STD)
add("501stkano", "501st | Kano", KIT.LORE_STD)
add("501stcoric", "501st | Coric", KIT.CORIC)

-- Schocktruppen
ranks("st_", "Schocktruppen", MAN_RANKS, KIT.ST_MAN)
ranks("st_", "Schocktruppen", NCO_RANKS, KIT.ST_NCO)
add("st_lt", "Schocktruppen | Lieutenant", KIT.ST_OFF)
add("st_foxoffizier", "Schocktruppen | Fox", KIT.ST_OFF)
add("st_thornoffizier", "Schocktruppen | Thorn", KIT.ST_THORN)

-- Schocktruppen K9
ranks("stk9_", "Schocktruppen K9", MAN_RANKS, KIT.STK9)
ranks("stk9_", "Schocktruppen K9", NCO_RANKS, KIT.STK9)
add("stk9_hound", "Schocktruppen K9 | Hound", KIT.STK9)

-- Republic Navy
add("rnm", "Republic Navy | Crewman", KIT.RN_CREW)
add("rnu", "Republic Navy | Petty Officer", KIT.RN_NCO)
add("rnspo", "Republic Navy | Senior Petty Officer", KIT.RN_NCO)
add("rncpo", "Republic Navy | Chief Petty Officer", KIT.RN_NCO)
add("rnwo", "Republic Navy | Warrant Officer", KIT.RN_NCO)
add("rnswo", "Republic Navy | Senior Warrant Officer", KIT.RN_NCO)
add("rncwo", "Republic Navy | Chief Warrant Officer", KIT.RN_NCO)
add("rnsl", "Republic Navy | Sub Lieutenant", KIT.RN_OFF)
add("rno", "Republic Navy | Lieutenant", KIT.RN_OFF)
add("rnlc", "Republic Navy | Lieutenant Commander", KIT.RN_STAFF)
add("rnso", "Republic Navy | Commander", KIT.RN_STAFF)
add("rncpt", "Republic Navy | Captain", KIT.RN_STAFF)
add("rnva", "Republic Navy | Vize Admiral", KIT.RN_STAFF)
add("rnadm", "Republic Navy | Admiral", KIT.RN_STAFF)
add("rnfa", "Republic Navy | Fleet Admiral", KIT.RN_STAFF)

-- Republic Navy AVP
ranks("avp_", "Republic Navy AVP", MAN_RANKS, KIT.AVP_MAN)
ranks("avp_", "Republic Navy AVP", NCO_RANKS, KIT.AVP_NCO)

-- Droids (b1ce, b1ace, b1hce, bxe, drocom, b2ce) have no weaponbox and
-- therefore no armory equipment.

A.JobLoadouts = {
    Enabled = true,

    -- When a job matches, ONLY its loadout is shown (no base/store weapons).
    ExclusiveWhenMatched = true,

    -- Jobs without an entry above (droids, cadets, prisoners...) do not see
    -- the free BaseWeapons. Store-bought weapons stay visible.
    ShowBaseWeaponsWithoutLoadout = false,

    -- On job change, armory equipment of the previous job is removed from the
    -- inventory (only items that are not part of the new job's loadout).
    RemoveUnauthorizedOnJobChange = true,

    ByCommand = byCommand,
}

-- =========================================================
-- Lookup tables (do not edit)
-- =========================================================
local function normalizeJobKey(value)
    value = string.lower(string.Trim(tostring(value or "")))
    value = string.gsub(value, "á", "a")
    value = string.gsub(value, "é", "e")
    value = string.gsub(value, "í", "i")
    value = string.gsub(value, "ó", "o")
    value = string.gsub(value, "ú", "u")
    value = string.gsub(value, "ü", "u")
    value = string.gsub(value, "ä", "a")
    value = string.gsub(value, "ö", "o")
    value = string.gsub(value, "ñ", "n")
    value = string.gsub(value, "[^%w]+", "")
    return value
end

A.JobLoadouts.ByName = {}
A.JobLoadouts.ByModel = {}
A.JobLoadouts.ByNormalizedCommand = {}

for command, loadout in pairs(A.JobLoadouts.ByCommand or {}) do
    if istable(loadout) then
        local commandKey = normalizeJobKey(command)
        if commandKey ~= "" then
            A.JobLoadouts.ByNormalizedCommand[commandKey] = loadout
        end

        local nameKey = normalizeJobKey(loadout.Name)
        if nameKey ~= "" then
            A.JobLoadouts.ByName[nameKey] = loadout
        end
    end
end
