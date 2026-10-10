if SERVER then
    AddCSLuaFile("grn_navysystem/sh_config.lua")
    AddCSLuaFile("grn_navysystem/sh_lang.lua")
    AddCSLuaFile("grn_navysystem/sh_core.lua")
    AddCSLuaFile("grn_navysystem/client/cl_core.lua")
    include("grn_navysystem/sh_config.lua")
    include("grn_navysystem/sh_lang.lua")
    include("grn_navysystem/sh_core.lua")
    include("grn_navysystem/server/sv_core.lua")
else
    include("grn_navysystem/sh_config.lua")
    include("grn_navysystem/sh_lang.lua")
    include("grn_navysystem/sh_core.lua")
    include("grn_navysystem/client/cl_core.lua")
end
