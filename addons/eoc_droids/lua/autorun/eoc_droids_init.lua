--[[
    EoC Droids - KUS-Nextbots fuer Echoes of Clones
    Ueberarbeitet auf Basis von SummeNextbots (Summe) + CIS DLC.
    Laeuft eigenstaendig: keine SummeLibrary und keine fremden Lua-Addons noetig.
]]--

EOCDroids = EOCDroids or {}
EOCDroids.Version = "2.0.0"

local shared = {
    "eoc_droids/sh_config.lua",
    "eoc_droids/sh_weapons.lua",
    "eoc_droids/sh_util.lua",
}

local server = {
    "eoc_droids/sv_main.lua",
}

local client = {
    "eoc_droids/cl_main.lua",
}

for _, path in ipairs(shared) do
    if SERVER then AddCSLuaFile(path) end
    include(path)
end

for _, path in ipairs(client) do
    if SERVER then
        AddCSLuaFile(path)
    else
        include(path)
    end
end

if SERVER then
    AddCSLuaFile("effects/eoc_droid_laser.lua")

    for _, path in ipairs(server) do
        include(path)
    end
end

MsgC(Color(255, 60, 60), "[EoC Droids] ", color_white, "Version " .. EOCDroids.Version .. " geladen.\n")
