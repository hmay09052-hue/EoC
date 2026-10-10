GRN_DEFCON = GRN_DEFCON or {}

if SERVER then
    AddCSLuaFile("grn_defcon/config.lua")
    AddCSLuaFile("grn_defcon/sh_config.lua")
    AddCSLuaFile("grn_defcon/cl_defcon.lua")
    AddCSLuaFile("grn_defcon/cl_terminal_menu.lua")

    include("grn_defcon/config.lua")
    include("grn_defcon/sv_defcon.lua")
else
    include("grn_defcon/config.lua")
    include("grn_defcon/cl_defcon.lua")
    include("grn_defcon/cl_terminal_menu.lua")
end
