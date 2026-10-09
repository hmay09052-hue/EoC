GRNSerials = GRNSerials or {}

-- Waffen mit Seriennummer & Geschichte. Lädt nach grn_inventory_init
-- (alphabetisch), weil es dessen Items und Hooks nutzt.
if SERVER then
    AddCSLuaFile("grn_serials/sh_config.lua")
    AddCSLuaFile("grn_serials/sh_core.lua")
    AddCSLuaFile("grn_serials/sh_items.lua")
    AddCSLuaFile("grn_serials/cl_html.lua")
    AddCSLuaFile("grn_serials/cl_core.lua")
    AddCSLuaFile("grn_serials/cl_stations.lua")
end

include("grn_serials/sh_config.lua")
include("grn_serials/sh_core.lua")
include("grn_serials/sh_items.lua")

if SERVER then
    include("grn_serials/sv_db.lua")
    include("grn_serials/sv_core.lua")
    include("grn_serials/sv_net.lua")
    include("grn_serials/sv_stations.lua")
else
    include("grn_serials/cl_html.lua")
    include("grn_serials/cl_core.lua")
    include("grn_serials/cl_stations.lua")
end
