-- GAR Logistik – Kriegslogistik & Feldbasen
-- Lädt Config, Server- und Client-Dateien

GARLog = GARLog or {}
GARLog.Version = "2.0.0"

local SHARED = {
    "gar_logistik/sh_config.lua",
    "gar_logistik/sh_core.lua",
}

local SERVER_FILES = {
    "gar_logistik/sv_data.lua",
    "gar_logistik/sv_core.lua",
    "gar_logistik/sv_fob.lua",
    "gar_logistik/sv_world.lua",
    "gar_logistik/sv_net.lua",
    "gar_logistik/sv_tech.lua",
}

local CLIENT_FILES = {
    "shiptech/cl_eocui.lua", -- gemeinsames Design (eine Kopie für ShipTech, Logistik und EVA)
    "gar_logistik/cl_ui.lua",
    "gar_logistik/cl_core.lua",
    "gar_logistik/cl_world.lua",
    "gar_logistik/cl_menu.lua",
    "gar_logistik/cl_builder.lua",
    "gar_logistik/cl_tech.lua",
}

if SERVER then
    for _, f in ipairs(SHARED) do AddCSLuaFile(f) include(f) end
    for _, f in ipairs(CLIENT_FILES) do AddCSLuaFile(f) end
    for _, f in ipairs(SERVER_FILES) do include(f) end
else
    for _, f in ipairs(SHARED) do include(f) end
    for _, f in ipairs(CLIENT_FILES) do include(f) end
end

MsgC(Color(252, 178, 73), "[GAR Logistik] ", color_white, "v" .. GARLog.Version .. " geladen.\n")
