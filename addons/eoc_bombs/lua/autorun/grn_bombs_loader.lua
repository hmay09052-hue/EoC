if SERVER then
    AddCSLuaFile()
end

GRN_Bombs = GRN_Bombs or {}

local base = 'grn_bombs/'

include(base .. 'sh_config.lua')
include(base .. 'sh_lang.lua')
include(base .. 'sh_html.lua')

if SERVER then
    AddCSLuaFile(base .. 'sh_config.lua')
    AddCSLuaFile(base .. 'sh_lang.lua')
    AddCSLuaFile(base .. 'sh_html.lua')
    AddCSLuaFile(base .. 'cl_menu.lua')
    AddCSLuaFile(base .. 'cl_minigames.lua')

    include(base .. 'sv_core.lua')
else
    include(base .. 'cl_minigames.lua')
    include(base .. 'cl_menu.lua')
end
