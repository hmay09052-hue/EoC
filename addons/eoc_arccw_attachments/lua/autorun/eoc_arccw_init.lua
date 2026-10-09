GRNArcCW = GRNArcCW or {}

if SERVER then
    AddCSLuaFile("eoc_arccw/sh_config.lua")
    AddCSLuaFile("eoc_arccw/sh_core.lua")
    AddCSLuaFile("eoc_arccw/cl_html.lua")
    AddCSLuaFile("eoc_arccw/cl_menu.lua")
end

include("eoc_arccw/sh_config.lua")
include("eoc_arccw/sh_core.lua")

if SERVER then
    include("eoc_arccw/sv_shotlog.lua")
end

if CLIENT then
    include("eoc_arccw/cl_html.lua")
    include("eoc_arccw/cl_menu.lua")
end
