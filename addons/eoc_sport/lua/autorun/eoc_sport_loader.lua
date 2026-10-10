EoCSport = EoCSport or {}

local shared = {
    "eoc_sport/sh_config.lua",
    "eoc_sport/sh_core.lua",
}

local client = {
    "eoc_sport/cl_poses.lua",
    "eoc_sport/cl_anim.lua",
    "eoc_sport/cl_view.lua",
    "eoc_sport/cl_hud.lua",
    "eoc_sport/cl_menu.lua",
}

if SERVER then
    for _, path in ipairs(shared) do AddCSLuaFile(path) end
    for _, path in ipairs(client) do AddCSLuaFile(path) end
end

for _, path in ipairs(shared) do include(path) end

if SERVER then
    include("eoc_sport/sv_core.lua")
else
    for _, path in ipairs(client) do include(path) end
end
