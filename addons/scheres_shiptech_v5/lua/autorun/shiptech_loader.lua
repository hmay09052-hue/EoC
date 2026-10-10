--[[
    ShipTech – Schiffstechnik, Wartung & Event-System
    Lädt alle Dateien in der richtigen Reihenfolge.
]]

ShipTech = ShipTech or {}
ShipTech.Version = "1.0.0"

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

Shared("shiptech/sh_config.lua")
Shared("shiptech/sh_core.lua")
Shared("shiptech/sh_entities.lua")
Shared("shiptech/sh_integration.lua")
Shared("shiptech/sh_logistik.lua")
Shared("shiptech/sh_cooling.lua")

Server("shiptech/sv_state.lua")
Server("shiptech/sv_actions.lua")
Server("shiptech/sv_event.lua")
Server("shiptech/sv_features.lua")
Server("shiptech/sv_cooling.lua")
Server("shiptech/sv_persist.lua")

Client("shiptech/cl_eocui.lua")
Client("shiptech/cl_core.lua")
Client("shiptech/cl_draw.lua")
Client("shiptech/cl_minigames.lua")
Client("shiptech/cl_ui.lua")
Client("shiptech/cl_event.lua")
Client("shiptech/cl_features.lua")

if SERVER then
    MsgC(Color(252, 178, 73), "[ShipTech] ", color_white, "Schiffstechnik v" .. ShipTech.Version .. " geladen.\n")
end
