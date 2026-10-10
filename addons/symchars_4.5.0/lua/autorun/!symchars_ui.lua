--[[-------------------------------------------------------------------------------------------------------------
    SymChars UI-Basis
    Lädt das Design (Farben, Schriften, Formen, Bedienelemente, Derma-Skin) vor allen anderen Addons,
    damit jedes Addon des Servers im SymChars-Look zeichnen kann. Global: SYMUI
    Der Dateiname beginnt mit "!", damit GMod ihn vor den anderen autorun-Dateien lädt.
-------------------------------------------------------------------------------------------------------------]]

local FILES = {
    "symchars/ui/cl_theme.lua",
    "symchars/ui/cl_aurebesh.lua",
    "symchars/ui/cl_controls.lua",
    "symchars/ui/cl_compat.lua",
}

if SERVER then
    for _, path in ipairs(FILES) do AddCSLuaFile(path) end
    resource.AddSingleFile("resource/fonts/symchars_bignoodle.ttf")
    resource.AddSingleFile("resource/fonts/symchars_aurebesh.ttf")
    resource.AddSingleFile("resource/fonts/symchars_robotocondensed.ttf")
    return
end

symchars = symchars or {}

-- Ohne das volle SymChars (nur die UI-Basis installiert) gelten die Standardfarben
if not symchars.Config then
    symchars.Config = function() return nil end
end

for _, path in ipairs(FILES) do include(path) end

symchars.ui._early = true
SYMUI = symchars.ui
