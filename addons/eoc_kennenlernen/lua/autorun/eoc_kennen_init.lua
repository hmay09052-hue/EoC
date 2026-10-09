EOC_KENNEN = EOC_KENNEN or {}

if SERVER then
    AddCSLuaFile("eoc_kennen/sh_config.lua")
    AddCSLuaFile("eoc_kennen/sh_core.lua")
    AddCSLuaFile("eoc_kennen/cl_core.lua")

    include("eoc_kennen/sh_config.lua")
    include("eoc_kennen/sh_core.lua")
    include("eoc_kennen/sv_core.lua")
else
    include("eoc_kennen/sh_config.lua")
    include("eoc_kennen/sh_core.lua")
    include("eoc_kennen/cl_core.lua")
end
