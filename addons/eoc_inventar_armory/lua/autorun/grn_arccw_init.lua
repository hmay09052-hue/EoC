GRNArcCW = GRNArcCW or {}

if SERVER then
    AddCSLuaFile("grn_arccw/sh_config.lua")
    AddCSLuaFile("grn_arccw/sh_core.lua")
    AddCSLuaFile("grn_arccw/cl_html.lua")
    AddCSLuaFile("grn_arccw/cl_menu.lua")
end

include("grn_arccw/sh_config.lua")
include("grn_arccw/sh_core.lua")

if CLIENT then
    include("grn_arccw/cl_html.lua")
    include("grn_arccw/cl_menu.lua")
end
