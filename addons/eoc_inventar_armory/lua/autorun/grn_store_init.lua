GRNStore = GRNStore or {}

if SERVER then
    AddCSLuaFile("grn_store/config.lua")
    AddCSLuaFile("grn_store/sh_util.lua")
    AddCSLuaFile("grn_store/sh_job_loadouts.lua")
    AddCSLuaFile("grn_store/cl_html.lua")
    AddCSLuaFile("grn_store/cl_store.lua")
    AddCSLuaFile("grn_store/cl_worldicon.lua")
    AddCSLuaFile("grn_store/cl_armory_html.lua")
    AddCSLuaFile("grn_store/cl_armory.lua")
    AddCSLuaFile("grn_store/cl_armory_worldicon.lua")

    AddCSLuaFile("entities/grn_store_terminal/shared.lua")
    AddCSLuaFile("entities/grn_store_terminal/cl_init.lua")
    AddCSLuaFile("entities/grn_armory_terminal/shared.lua")
    AddCSLuaFile("entities/grn_armory_terminal/cl_init.lua")

    include("grn_store/config.lua")
    include("grn_store/sh_job_loadouts.lua")
    include("grn_store/sh_util.lua")
    include("grn_store/sv_store.lua")
    include("grn_store/sv_armory.lua")
else
    include("grn_store/config.lua")
    include("grn_store/sh_job_loadouts.lua")
    include("grn_store/sh_util.lua")
    include("grn_store/cl_html.lua")
    include("grn_store/cl_store.lua")
    include("grn_store/cl_worldicon.lua")
    include("grn_store/cl_armory_html.lua")
    include("grn_store/cl_armory.lua")
    include("grn_store/cl_armory_worldicon.lua")
end
