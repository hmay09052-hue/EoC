--------------
-- CHANNELS --
--------------

hradio.Channels = {}

-- Talkers / Listeners: Liste von TEAM_-Variablen (aus der jobs.lua), die sprechen / zuhören dürfen.
-- GetTalkers / GetListeners: Gibt die Funktion true zurück, darf der Spieler sprechen / zuhören.
-- Gibt sie false zurück, zählt nur die Team-Liste.
-- Die Channels werden in derselben Reihenfolge angezeigt, in der sie hier stehen.

-- Prüft, ob ein Spieler in einer der angegebenen Job-Kategorien ist
local function PlyInCategory(ply, ...)
    if not IsValid(ply) then return false end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    if not job then return false end

    for _, cat in ipairs({...}) do
        if job.category == cat then
            return true
        end
    end

    return false
end

-- Alle republikanischen Jobs (alles außer Droiden)
local function IsRepublic(ply)
    if not IsValid(ply) then return false end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    return job ~= nil and job.category ~= "Droiden"
end

-- Fügt mehrere Team-Listen zu einer zusammen (nicht existierende TEAM_-Variablen werden übersprungen)
local function Merge(...)
    local out = {}
    for _, tbl in ipairs({...}) do
        for _, t in pairs(tbl) do
            out[#out + 1] = t
        end
    end
    return out
end


-------------------------------------------------------------------------------------------------
-------------------------------------- TEAM-GRUPPEN ---------------------------------------------
-------------------------------------------------------------------------------------------------

-- Team on Duty (hört/spricht in allen Einheiten-Channels mit)
local T_STAFF = { TEAM_TEAMF }

-- Leitung (Sicherheitslevel Aurek)
local T_LEITUNG = {
    TEAM_RN_FLEETADMIRAL, TEAM_RN_ADMIRAL, TEAM_RN_VIZEADMIRAL,
    TEAM_ST_THORNOFFIZIER, TEAM_RN_CAPTAIN, TEAM_ST_FOXOFFIZIER,
    TEAM_RN_COMMANDER, TEAM_RN_LIEUTENANTCOMMANDER,
    TEAM_501ST_REX, TEAM_501ST_CPT,
}

-- Offiziere (Sicherheitslevel Besh)
local T_OFFIZIERE = {
    TEAM_RN_LIEUTENANT, TEAM_501ST_1LT, TEAM_RN_SUBLIEUTENANT, TEAM_501ST_LT,
    TEAM_501ST_MEDIC_LT, TEAM_501ST_ENGINEER_LT, TEAM_ST_LT,
    TEAM_RN_CHIEFWARRANTOFFICER, TEAM_RN_SENIORWARRANTOFFICER, TEAM_RN_WARRANTOFFICER,
}

-- Ausbildungsakademie
local T_AKADEMIE = { TEAM_AUSBILDER, TEAM_CADET }

-- 501st Torrent Company
local T_501_TORRENT = {
    TEAM_501ST_CPT, TEAM_501ST_1LT, TEAM_501ST_LT, TEAM_501ST_SGM, TEAM_501ST_FSGT, TEAM_501ST_SGT,
    TEAM_501ST_FCPL, TEAM_501ST_CCPL, TEAM_501ST_CPL, TEAM_501ST_LCPL, TEAM_501ST_SPC, TEAM_501ST_PFC, TEAM_501ST_PVT,
    TEAM_501ST_REX, TEAM_501ST_DOGMA, TEAM_501ST_APPO, TEAM_501ST_KANO, -- Lorecharaktere
}

-- 501st BARC
local T_501_BARC = {
    TEAM_501ST_BARC_SGM, TEAM_501ST_BARC_FSGT, TEAM_501ST_BARC_SGT, TEAM_501ST_BARC_FCPL, TEAM_501ST_BARC_CCPL,
    TEAM_501ST_BARC_CPL, TEAM_501ST_BARC_LCPL, TEAM_501ST_BARC_SPC, TEAM_501ST_BARC_PFC, TEAM_501ST_BARC_PVT,
}

-- 501st ARF
local T_501_ARF = {
    TEAM_501ST_ARF_SGM, TEAM_501ST_ARF_FSGT, TEAM_501ST_ARF_SGT, TEAM_501ST_ARF_FCPL, TEAM_501ST_ARF_CCPL,
    TEAM_501ST_ARF_CPL, TEAM_501ST_ARF_LCPL, TEAM_501ST_ARF_SPC, TEAM_501ST_ARF_PFC, TEAM_501ST_ARF_PVT,
}

-- 501st Heavy Platoon
local T_501_HEAVY = {
    TEAM_501ST_HEAVY_SGM, TEAM_501ST_HEAVY_FSGT, TEAM_501ST_HEAVY_SGT, TEAM_501ST_HEAVY_FCPL, TEAM_501ST_HEAVY_CCPL,
    TEAM_501ST_HEAVY_CPL, TEAM_501ST_HEAVY_LCPL, TEAM_501ST_HEAVY_SPC, TEAM_501ST_HEAVY_PFC, TEAM_501ST_HEAVY_PVT,
    TEAM_501ST_HARDCASE, -- Lorecharakter
}

-- 501st Airborne Platoon
local T_501_AIRBORNE = {
    TEAM_501ST_AIRBORNE_SGM, TEAM_501ST_AIRBORNE_FSGT, TEAM_501ST_AIRBORNE_SGT, TEAM_501ST_AIRBORNE_FCPL, TEAM_501ST_AIRBORNE_CCPL,
    TEAM_501ST_AIRBORNE_CPL, TEAM_501ST_AIRBORNE_LCPL, TEAM_501ST_AIRBORNE_SPC, TEAM_501ST_AIRBORNE_PFC, TEAM_501ST_AIRBORNE_PVT,
}

-- 501st Medical Platoon
local T_501_MEDIC = {
    TEAM_501ST_MEDIC_LT, TEAM_501ST_MEDIC_SGM, TEAM_501ST_MEDIC_FSGT, TEAM_501ST_MEDIC_SGT, TEAM_501ST_MEDIC_FCPL,
    TEAM_501ST_MEDIC_CCPL, TEAM_501ST_MEDIC_CPL, TEAM_501ST_MEDIC_LCPL, TEAM_501ST_MEDIC_SPC, TEAM_501ST_MEDIC_PFC, TEAM_501ST_MEDIC_PVT,
    TEAM_501ST_KIX, TEAM_501ST_CORIC, -- Lorecharaktere
}

-- 501st Engineering Platoon
local T_501_ENGINEER = {
    TEAM_501ST_ENGINEER_LT, TEAM_501ST_ENGINEER_SGM, TEAM_501ST_ENGINEER_FSGT, TEAM_501ST_ENGINEER_SGT, TEAM_501ST_ENGINEER_FCPL,
    TEAM_501ST_ENGINEER_CCPL, TEAM_501ST_ENGINEER_CPL, TEAM_501ST_ENGINEER_LCPL, TEAM_501ST_ENGINEER_SPC, TEAM_501ST_ENGINEER_PFC, TEAM_501ST_ENGINEER_PVT,
}

-- 501st ARC-Trooper (Lorecharaktere, nur im TC-Funk)
local T_501_ARC = { TEAM_501ST_JESSE, TEAM_501ST_ECHO, TEAM_501ST_FIVES, TEAM_501ST_BOOMER }

-- Komplette 501st
local T_501 = Merge(T_501_TORRENT, T_501_BARC, T_501_ARF, T_501_HEAVY, T_501_AIRBORNE, T_501_MEDIC, T_501_ENGINEER, T_501_ARC)

-- Notfalleinheiten (Forn): Medical + Engineering
local T_NOTFALL = Merge(T_501_MEDIC, T_501_ENGINEER)

-- Spezialeinheiten (Isk): ARC / Recon
local T_SPEZIAL = Merge(T_501_BARC, T_501_ARF)

-- Schocktruppen K9
local T_K9 = {
    TEAM_STK9_SGM, TEAM_STK9_FSGT, TEAM_STK9_SGT, TEAM_STK9_HOUND, TEAM_STK9_FCPL, TEAM_STK9_CCPL,
    TEAM_STK9_CPL, TEAM_STK9_LCPL, TEAM_STK9_SPC, TEAM_STK9_PFC, TEAM_STK9_PVT,
}

-- Schocktruppen + K9
local T_SCHOCK = {
    TEAM_ST_THORNOFFIZIER, TEAM_ST_FOXOFFIZIER, TEAM_ST_LT, TEAM_ST_SGM, TEAM_STK9_SGM, TEAM_ST_FSGT, TEAM_STK9_FSGT,
    TEAM_ST_SGT, TEAM_STK9_SGT, TEAM_STK9_HOUND, TEAM_ST_FCPL, TEAM_STK9_FCPL, TEAM_ST_CCPL, TEAM_STK9_CCPL,
    TEAM_ST_CPL, TEAM_STK9_CPL, TEAM_ST_LCPL, TEAM_STK9_LCPL, TEAM_ST_SPC, TEAM_STK9_SPC, TEAM_ST_PFC, TEAM_STK9_PFC,
    TEAM_ST_PVT, TEAM_STK9_PVT,
}

-- Republic Navy
local T_NAVY = {
    TEAM_RN_FLEETADMIRAL, TEAM_RN_ADMIRAL, TEAM_RN_VIZEADMIRAL, TEAM_RN_CAPTAIN, TEAM_RN_COMMANDER,
    TEAM_RN_LIEUTENANTCOMMANDER, TEAM_RN_LIEUTENANT, TEAM_RN_SUBLIEUTENANT, TEAM_RN_CHIEFWARRANTOFFICER,
    TEAM_RN_SENIORWARRANTOFFICER, TEAM_RN_WARRANTOFFICER, TEAM_RN_CHIEFPETTYOFFICER, TEAM_RN_SENIORPETTYOFFICER,
    TEAM_RN_PETTYOFFICER, TEAM_RN_CREWMAN,
}

-- Republic Navy AVP (Piloten)
local T_AVP = {
    TEAM_AVP_SGM, TEAM_AVP_FSGT, TEAM_AVP_SGT, TEAM_AVP_FCPL, TEAM_AVP_CCPL,
    TEAM_AVP_CPL, TEAM_AVP_LCPL, TEAM_AVP_SPC, TEAM_AVP_PFC, TEAM_AVP_PVT,
}

-- Zusammengesetzte Gruppen
local T_ANKUENDIGUNG   = Merge(T_STAFF, T_LEITUNG)
local T_EINSATZLEITUNG = Merge(T_STAFF, T_LEITUNG, T_OFFIZIERE)


-------------------------------------------------------------------------------------------------
------------------------------------------ REPUBLIK ---------------------------------------------
-------------------------------------------------------------------------------------------------

hradio.AddChannel({
    Name = "Ankündigung",
    Talkers = T_ANKUENDIGUNG,                                -- Nur Leitung + Team on Duty darf sprechen
    Listeners = {},
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return IsRepublic(ply) end, -- Alle Republik-Jobs hören zu
    Mutable = false,
    Colour = Color(252, 178, 73)
})

hradio.AddChannel({
    Name = "Einsatzleitung",
    Talkers = T_EINSATZLEITUNG,
    Listeners = T_EINSATZLEITUNG,
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(255, 140, 40)
})

hradio.AddChannel({
    Name = "Ausbildungsakademie",
    Talkers = Merge(T_STAFF, T_AKADEMIE),
    Listeners = Merge(T_STAFF, T_AKADEMIE),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(235, 235, 235)
})

hradio.AddChannel({
    Name = "TC",
    Talkers = Merge(T_STAFF, T_501),
    Listeners = Merge(T_STAFF, T_501),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(45, 120, 255)
})

hradio.AddChannel({
    Name = "Notfalleinheiten",
    Talkers = Merge(T_STAFF, T_NOTFALL),
    Listeners = Merge(T_STAFF, T_NOTFALL),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(0, 210, 230)
})

hradio.AddChannel({
    Name = "Spezialeinheiten",
    Talkers = Merge(T_STAFF, T_SPEZIAL),
    Listeners = Merge(T_STAFF, T_SPEZIAL),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(200, 90, 255)
})

hradio.AddChannel({
    Name = "ST",
    Talkers = Merge(T_STAFF, T_SCHOCK),
    Listeners = Merge(T_STAFF, T_SCHOCK),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(220, 40, 40)
})

hradio.AddChannel({
    Name = "Republic Navy",
    Talkers = Merge(T_STAFF, T_NAVY, T_AVP),
    Listeners = Merge(T_STAFF, T_NAVY, T_AVP),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(150, 160, 175)
})

hradio.AddChannel({
    Name = "AVP",
    Talkers = Merge(T_STAFF, T_AVP),
    Listeners = Merge(T_STAFF, T_AVP),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(110, 160, 220)
})


-------------------------------------------------------------------------------------------------
--------------------------------------- UNTEREINHEITEN ------------------------------------------
-------------------------------------------------------------------------------------------------
-- Eigene Funks pro Untereinheit. 501st-Einheiten in Blautönen, ST-Einheiten in Rottönen.

hradio.AddChannel({
    Name = "BARC",                                           -- 501st BARC
    Talkers = Merge(T_STAFF, T_501_BARC),
    Listeners = Merge(T_STAFF, T_501_BARC),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(80, 150, 255)
})

hradio.AddChannel({
    Name = "ARF",                                            -- 501st ARF
    Talkers = Merge(T_STAFF, T_501_ARF),
    Listeners = Merge(T_STAFF, T_501_ARF),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(100, 175, 235)
})

hradio.AddChannel({
    Name = "HP",                                             -- 501st Heavy Platoon
    Talkers = Merge(T_STAFF, T_501_HEAVY),
    Listeners = Merge(T_STAFF, T_501_HEAVY),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(60, 95, 210)
})

hradio.AddChannel({
    Name = "AP",                                             -- 501st Airborne Platoon
    Talkers = Merge(T_STAFF, T_501_AIRBORNE),
    Listeners = Merge(T_STAFF, T_501_AIRBORNE),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(120, 200, 255)
})

hradio.AddChannel({
    Name = "MP",                                             -- 501st Medical Platoon
    Talkers = Merge(T_STAFF, T_501_MEDIC),
    Listeners = Merge(T_STAFF, T_501_MEDIC),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(150, 185, 255)
})

hradio.AddChannel({
    Name = "EP",                                             -- 501st Engineering Platoon
    Talkers = Merge(T_STAFF, T_501_ENGINEER),
    Listeners = Merge(T_STAFF, T_501_ENGINEER),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(70, 130, 190)
})

hradio.AddChannel({
    Name = "K9",                                             -- Schocktruppen K9
    Talkers = Merge(T_STAFF, T_K9),
    Listeners = Merge(T_STAFF, T_K9),
    GetTalkers = function(ply) return false end,
    GetListeners = function(ply) return false end,
    Mutable = true,
    Colour = Color(255, 90, 90)
})

-- Allgemeine Funks: alle Republik-Jobs (keine Droiden)

hradio.AddChannel({
    Name = "ATC",
    Talkers = {},
    Listeners = {},
    GetTalkers = function(ply) return IsRepublic(ply) end,
    GetListeners = function(ply) return IsRepublic(ply) end,
    Mutable = true,
    Colour = Color(90, 190, 255)
})

hradio.AddChannel({
    Name = "RN-Anfrage",
    Talkers = {},
    Listeners = {},
    GetTalkers = function(ply) return IsRepublic(ply) end,
    GetListeners = function(ply) return IsRepublic(ply) end,
    Mutable = true,
    Colour = Color(175, 180, 190)
})

hradio.AddChannel({
    Name = "Medizinischer Notfall-Funk",
    Talkers = {},
    Listeners = {},
    GetTalkers = function(ply) return IsRepublic(ply) end,
    GetListeners = function(ply) return IsRepublic(ply) end,
    Mutable = true,
    Colour = Color(255, 110, 110)
})

hradio.AddChannel({
    Name = "Technischer Notfall-Funk",
    Talkers = {},
    Listeners = {},
    GetTalkers = function(ply) return IsRepublic(ply) end,
    GetListeners = function(ply) return IsRepublic(ply) end,
    Mutable = true,
    Colour = Color(230, 200, 60)
})

hradio.AddChannel({
    Name = "Straftaten-Funk",
    Talkers = {},
    Listeners = {},
    GetTalkers = function(ply) return IsRepublic(ply) end,
    GetListeners = function(ply) return IsRepublic(ply) end,
    Mutable = true,
    Colour = Color(200, 30, 30)
})


-------------------------------------------------------------------------------------------------
------------------------------------------ DROIDEN ----------------------------------------------
-------------------------------------------------------------------------------------------------

hradio.AddChannel({
    Name = "Droiden-Netzwerk",
    Talkers = Merge(T_STAFF),
    Listeners = Merge(T_STAFF),
    GetTalkers = function(ply) return PlyInCategory(ply, "Droiden") end,
    GetListeners = function(ply) return PlyInCategory(ply, "Droiden") end,
    Mutable = true,
    Colour = Color(130, 130, 230)
})


-------------------------------------------------------------------------------------------------
--------------------------------------- FREIE FUNKS ---------------------------------------------
-------------------------------------------------------------------------------------------------

for i = 1, 10 do
    hradio.AddChannel({
        Name = "Funkeinheit " .. i,
        Talkers = {},
        Listeners = {},
        GetTalkers = function(ply) return true end,
        GetListeners = function(ply) return true end,
        Mutable = true,
        Colour = Color(70, 210, 100)
    })
end

-- END CONFIG
