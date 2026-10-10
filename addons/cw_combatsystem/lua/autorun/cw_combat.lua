CW_Combat = CW_Combat or {}

AddCSLuaFile("cw_combat/sh_config.lua")
AddCSLuaFile("cw_combat/sh_net.lua")

include("cw_combat/sh_config.lua")
include("cw_combat/sh_net.lua")

if SERVER then
    include("cw_combat/sv_armor.lua")
    include("cw_combat/sv_medic.lua")
    include("cw_combat/sv_injury.lua")
    print("[CW-Combat] Server-System geladen!")
end