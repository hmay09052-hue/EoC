--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Charakter-, Einheiten-, Fortbildungs-, Dokumenten- und Holo-System
    Ein Addon, keine weiteren Abhaengigkeiten (DarkRP wird vorausgesetzt, CAMI/SSE werden genutzt falls vorhanden)
-------------------------------------------------------------------------------------------------------------]]

symchars = symchars or {}
symchars.version = "2.0.0"

local SHARED = {
    "symchars/sh_config.lua",
    "symchars/sh_zivilist.lua",
    "symchars/core/sh_core.lua",
    "symchars/core/sh_net.lua",
    "symchars/core/sh_settings.lua",
    "symchars/factions/sh_factions.lua",
    "symchars/chars/sh_chars.lua",
    "symchars/chars/sh_data.lua",
    "symchars/chars/sh_utils.lua",
    "symchars/chars/sh_authority.lua",
    "symchars/chars/sh_actions.lua",
    "symchars/core/sh_history.lua",
    "symchars/core/sh_whitelist.lua",
    "symchars/trainings/sh_trainings.lua",
    "symchars/docs/sh_docs.lua",
    "symchars/holo/sh_holo.lua",
}

local SERVER_FILES = {
    "symchars/sv_config.lua",
    "symchars/core/sv_db.lua",
    "symchars/core/sv_settings.lua",
    "symchars/factions/sv_factions.lua",
    "symchars/chars/sv_chars.lua",
    "symchars/core/sv_history.lua",
    "symchars/core/sv_whitelist.lua",
    "symchars/trainings/sv_trainings.lua",
    "symchars/docs/sv_docs.lua",
    "symchars/holo/sv_holo.lua",
    "symchars/core/sv_core.lua",
}

local CLIENT_FILES = {
    "symchars/ui/cl_theme.lua",
    "symchars/ui/cl_aurebesh.lua",
    "symchars/ui/cl_images.lua",
    "symchars/ui/cl_controls.lua",
    "symchars/ui/cl_notify.lua",
    "symchars/ui/cl_hologram.lua",
    "symchars/ui/cl_menu.lua",
    "symchars/ui/cl_characters.lua",
    "symchars/ui/cl_create.lua",
    "symchars/ui/cl_units.lua",
    "symchars/ui/cl_manager.lua",
    "symchars/ui/cl_docs.lua",
    "symchars/ui/cl_admin.lua",
    "symchars/ui/cl_overhead.lua",
    "symchars/holo/cl_holo.lua",
}

if SERVER then
    for _, path in ipairs(SHARED) do AddCSLuaFile(path) end
    for _, path in ipairs(CLIENT_FILES) do AddCSLuaFile(path) end

    resource.AddSingleFile("resource/fonts/symchars_bignoodle.ttf")
    resource.AddSingleFile("resource/fonts/symchars_aurebesh.ttf")
    resource.AddSingleFile("resource/fonts/symchars_robotocondensed.ttf")
end

for _, path in ipairs(SHARED) do include(path) end

if SERVER then
    for _, path in ipairs(SERVER_FILES) do include(path) end
else
    -- Design-Dateien wurden schon von autorun/!symchars_ui.lua geladen
    local early = {
        ["symchars/ui/cl_theme.lua"] = true,
        ["symchars/ui/cl_aurebesh.lua"] = true,
        ["symchars/ui/cl_controls.lua"] = true,
    }
    for _, path in ipairs(CLIENT_FILES) do
        if not (early[path] and symchars.ui and symchars.ui._early) then include(path) end
    end
end

hook.Run("symchars_loaded")
