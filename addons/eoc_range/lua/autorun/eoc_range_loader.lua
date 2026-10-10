--[[
    EoC Range – Schießstand, Disziplinen, Ranglisten und Schützenabzeichen
    Lädt alle Dateien in der richtigen Reihenfolge.
]]

EoCRange = EoCRange or {}
EoCRange.Version = "1.0.0"

-- Kurzform aus dem Konzept (Range.Config.UnitLevel ...), nur wenn der Name frei ist
if Range == nil then Range = EoCRange end

local function Shared(path)
    if SERVER then AddCSLuaFile(path) end
    include(path)
end

local function Server(path)
    if SERVER then include(path) end
end

local function Client(path)
    if SERVER then
        AddCSLuaFile(path)
    else
        include(path)
    end
end

Shared("eoc_range/sh_config.lua")
Shared("eoc_range/sh_core.lua")
Shared("eoc_range/sh_disciplines.lua")

Server("eoc_range/sv_db.lua")
Server("eoc_range/sv_integration.lua")
Server("eoc_range/sv_core.lua")
Server("eoc_range/sv_admin.lua")

Client("eoc_range/cl_core.lua")
Client("eoc_range/cl_draw.lua")
Client("eoc_range/cl_ui.lua")

if SERVER then
    MsgC(Color(255, 190, 50), "[EoC Range] ", color_white, "Schießstand v" .. EoCRange.Version .. " geladen.\n")
end
