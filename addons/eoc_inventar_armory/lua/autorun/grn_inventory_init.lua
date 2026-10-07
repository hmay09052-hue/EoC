GRNInventory = GRNInventory or {}

if SERVER then
    AddCSLuaFile("grn_inventory/sh_config.lua")
    AddCSLuaFile("grn_inventory/sh_core.lua")
    AddCSLuaFile("grn_inventory/sh_job_armory_items.lua")
    AddCSLuaFile("grn_inventory/sh_armor.lua")
    AddCSLuaFile("grn_inventory/cl_icons.lua")
    AddCSLuaFile("grn_inventory/cl_armor.lua")
    AddCSLuaFile("grn_inventory/cl_core.lua")

    AddCSLuaFile("entities/grn_inventory_drop/shared.lua")
    AddCSLuaFile("entities/grn_inventory_drop/cl_init.lua")
    AddCSLuaFile("weapons/weapon_grn_inventory_backpack.lua")

    -- Bundled first-person backpack animation assets. These resource entries
    -- make the addon self-contained when distributed through FastDL/resources.
    local backpackResources = {
        "models/weapons/ais/stalker2/bpa/v_bpa.mdl",
        "models/weapons/ais/stalker2/bpa/v_bpa.dx80.vtx",
        "models/weapons/ais/stalker2/bpa/v_bpa.dx90.vtx",
        "models/weapons/ais/stalker2/bpa/v_bpa.vvd",
        "materials/models/weapons/sweps/stalker2/bpa/mi_bpa_sta_09_a_01_fov.vmt",
        "materials/models/weapons/sweps/stalker2/bpa/mi_bpa_sta_09_a_01_fov_e.vtf",
        "materials/models/weapons/sweps/stalker2/bpa/mi_bpa_sta_09_a_01_fov_n.vtf",
        "materials/models/weapons/sweps/stalker2/bpa/mi_bpa_sta_09_a_01_fov_rgb.vtf",
        "sound/weapons/stalker2/bpa/s_inventory_close_01 (sfx).ogg",
        "sound/weapons/stalker2/bpa/s_inventory_close_02 (sfx).ogg",
        "sound/weapons/stalker2/bpa/s_inventory_close_03 (sfx).ogg",
        "sound/weapons/stalker2/bpa/s_inventory_close_04 (sfx).ogg",
        "sound/weapons/stalker2/bpa/s_inventory_open_01 (sfx).ogg",
        "sound/weapons/stalker2/bpa/s_inventory_open_02 (sfx).ogg",
        "sound/weapons/stalker2/bpa/s_inventory_open_03 (sfx).ogg",
        "sound/weapons/stalker2/bpa/s_inventory_open_04 (sfx).ogg"
    }

    for _, path in ipairs(backpackResources) do
        resource.AddFile(path)
    end
end

include("grn_inventory/sh_config.lua")
include("grn_inventory/sh_job_armory_items.lua")
include("grn_inventory/sh_armor.lua")
include("grn_inventory/sh_core.lua")

if SERVER then
    include("grn_inventory/sv_core.lua")
else
    include("grn_inventory/cl_icons.lua")
    include("grn_inventory/cl_armor.lua")
    include("grn_inventory/cl_core.lua")
end
