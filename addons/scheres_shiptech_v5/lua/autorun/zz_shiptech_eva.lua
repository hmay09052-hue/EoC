--[[
    ShipTech EVA – Außenhülle
    Hüllenbrüche an Ankerpunkten, EVA-Spind (Luftschleuse), Versorgungspunkte, Hüllenschweißgerät.
    Hängt sich an ShipTech an (ShipTech selbst bleibt unverändert nutzbar).
    Dateiname mit "zz_", damit dieses Addon NACH ShipTech geladen wird.
]]

if not ShipTech or not ShipTech.Config then
    MsgC(Color(205, 62, 56), "[ShipTech EVA] ", color_white, "ShipTech wurde nicht gefunden – EVA ist deaktiviert.\n")
    return
end

ShipTech.EVA = ShipTech.EVA or {}
ShipTech.EVA.Version = "2.0.0"

local function Shared(path)
    if SERVER then AddCSLuaFile(path) end
    include(path)
end
local function Server(path) if SERVER then include(path) end end
local function Client(path) if SERVER then AddCSLuaFile(path) else include(path) end end

Shared("shiptech_eva/sh_config.lua")
Shared("shiptech_eva/sh_core.lua")
Server("shiptech_eva/sv_core.lua")
Client("shiptech_eva/cl_core.lua")
Client("shiptech_eva/cl_ui.lua")

if SERVER then
    MsgC(Color(252, 178, 73), "[ShipTech EVA] ", color_white, "Außenhülle v" .. ShipTech.EVA.Version .. " geladen.\n")
end
