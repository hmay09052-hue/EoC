--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Klon-Datapad im Easzy-Tablet
    Benoetigt: SymChars 2 (Charaktere/Einheiten, Design, Netzwerk)
    Modelle:   Easzy's Tablet F4 (Workshop 2526015939)
-------------------------------------------------------------------------------------------------------------]]

GAR_DP = GAR_DP or {}

local SHARED = {
    "gar_datapad/sh_config.lua",
    "gar_datapad/sh_core.lua",
    "gar_datapad/sh_galaxy_data.lua",
    "gar_datapad/sh_galaxy.lua",
}

local SERVER_FILES = {
    "gar_datapad/sv_db.lua",
    "gar_datapad/sv_net.lua",
    "gar_datapad/sv_weapon.lua",
}

local CLIENT_FILES = {
    "gar_datapad/cl_ui.lua",
    "gar_datapad/cl_controls.lua",
    "gar_datapad/cl_tablet.lua",
    "gar_datapad/apps/cl_personnel.lua",
    "gar_datapad/apps/cl_penal.lua",
    "gar_datapad/apps/cl_archive.lua",
    "gar_datapad/apps/cl_galaxy.lua",
    "gar_datapad/apps/cl_clearance.lua",
}

if SERVER then
    for _, path in ipairs(SHARED) do AddCSLuaFile(path) end
    for _, path in ipairs(CLIENT_FILES) do AddCSLuaFile(path) end
end

-- SymChars muss zuerst geladen sein (Charaktere, Design, Netzwerk). Die Reihenfolge der Autorun-Dateien
-- verschiedener Addons ist nicht festgelegt, deshalb wird erst geladen, wenn SymChars bereit ist.
local function Load()
    if GAR_DP._loaded then return end
    if not (symchars and symchars.net and symchars.chars and symchars.factions) then return end
    if CLIENT and not symchars.ui then return end
    GAR_DP._loaded = true

    for _, path in ipairs(SHARED) do include(path) end
    if SERVER then
        for _, path in ipairs(SERVER_FILES) do include(path) end
    else
        for _, path in ipairs(CLIENT_FILES) do include(path) end
    end
    MsgC(Color(252, 178, 73), "[GAR Datapad] ", color_white, "Version " .. GAR_DP.version .. " geladen.\n")
end

Load()
hook.Add("symchars_loaded", "gar_datapad_load", Load)
hook.Add("Initialize", "gar_datapad_load", function()
    Load()
    if not GAR_DP._loaded then
        MsgC(Color(205, 62, 56), "[GAR Datapad] ", color_white, "SymChars 2 wurde nicht gefunden - Datapad ist deaktiviert.\n")
    end
end)
