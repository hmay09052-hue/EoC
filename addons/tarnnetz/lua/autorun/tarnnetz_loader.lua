--[[-------------------------------------------------------------------------------------------------------------
    Tarnnetz
    Linksklick: Tarnmuster wählen und Tarnnetz aktivieren (NoTarget + Tarnmuster auf der Rüstung)
    Rechtsklick: Tarnnetz deaktivieren
    Kommt ein Droide näher als der eingestellte Radius (Standard 10 m), bricht das Tarnnetz.
-------------------------------------------------------------------------------------------------------------]]

if SERVER then
    AddCSLuaFile()
end

Tarnnetz = Tarnnetz or {}

local base = 'tarnnetz/'

include(base .. 'sh_config.lua')
include(base .. 'sh_core.lua')

if SERVER then
    AddCSLuaFile(base .. 'sh_config.lua')
    AddCSLuaFile(base .. 'sh_core.lua')
    AddCSLuaFile(base .. 'cl_menu.lua')
    AddCSLuaFile(base .. 'cl_hud.lua')

    include(base .. 'sv_core.lua')
else
    include(base .. 'cl_menu.lua')
    include(base .. 'cl_hud.lua')
end
