--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - TAB-Menü (Scoreboard) mit Officer-System und Admin-Menü

    Eigenständig: braucht KEIN Kraken-Framework.
    SymChars wird NICHT mitgeliefert und NICHT verändert. Läuft SymChars auf dem Server, liest das TAB-Menü
    nur dessen Daten aus (Name + RP-ID, Einheit, Untereinheit, Rang, Design/Aurebesh).
    Ohne SymChars fällt alles auf DarkRP-Name und Job zurück.
-------------------------------------------------------------------------------------------------------------]]

EOCSB = EOCSB or {}
EOCSB.Version = "1.1.0"

local CLIENT_FILES = {
    "eocsb/cl_logo_1.lua",
    "eocsb/cl_logo_2.lua",
    "eocsb/cl_logo_3.lua",
    "eocsb/cl_theme.lua",
    "eocsb/cl_officer.lua",
    "eocsb/cl_commands.lua",
    "eocsb/cl_scoreboard.lua",
}

if SERVER then
    AddCSLuaFile("eocsb/sh_config.lua")
    AddCSLuaFile("eocsb/sh_util.lua")
    for _, path in ipairs(CLIENT_FILES) do AddCSLuaFile(path) end
end

include("eocsb/sh_config.lua")
include("eocsb/sh_util.lua")

if SERVER then
    include("eocsb/sv_officer.lua")
    include("eocsb/sv_info.lua")
    print("[EoC Scoreboard] v" .. EOCSB.Version .. " geladen")
else
    for _, path in ipairs(CLIENT_FILES) do include(path) end
end
