AddCSLuaFile("helio_radio/sh_helio_errorcatcher.lua")
AddCSLuaFile("helio_radio/sh_helio_channels.lua")
AddCSLuaFile("helio_radio/sh_helio_config_general.lua")
AddCSLuaFile("helio_radio/sh_helio_config_channels.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_init.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_2dmenu.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_3d2dmenu.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_squadmenu.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_medicmenu.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_aurebesh_atlas.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_commands.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_hotkeys.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_networking.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_notifications.lua")
AddCSLuaFile("helio_radio/cl/helio_radio_oldvcremoval.lua")
AddCSLuaFile("libs/imgui.lua")

if SERVER then
    resource.AddFile("materials/vgui/hradio/eoc_logo.png")
    resource.AddFile("materials/vgui/hradio/speaker.png")
    resource.AddFile("materials/vgui/hradio/aurebesh_atlas.png")
    resource.AddFile("resource/fonts/rajdhani-regular.ttf")
    resource.AddFile("resource/fonts/symchars_aurebesh.ttf")
    resource.AddFile("resource/fonts/symchars_bignoodle.ttf")
    resource.AddFile("resource/fonts/symchars_robotocondensed.ttf")

    -- Comlink-Arm (H = Funk, G = Squad, J = Textfunk, K = Medic)
    resource.AddFile("models/weapons/c_vmaniphradio_comlink.mdl")
    resource.AddFile("materials/models/helios/sw/comlink/holocom.vmt")
    resource.AddSingleFile("materials/models/helios/sw/comlink/holocom_color.vtf")
    resource.AddSingleFile("materials/models/helios/sw/comlink/holocom_illum.vtf")

    local function Load()
        hradio = {}

        include("helio_radio/sh_helio_errorcatcher.lua")
        include("helio_radio/sh_helio_channels.lua")
        include("helio_radio/sh_helio_config_general.lua")
        include("helio_radio/sv_helio_radio.lua")
    end

    hook.Add("PostGamemodeLoaded", "hRadio_Load", Load)
    concommand.Add("sv_hRadio_Reload", Load)
end

if CLIENT then
    local Colors = {
        Darker = Color(5, 7, 10),
        Dark = Color(12, 15, 19),
        Darkred = Color(92, 28, 34),
        Gray = Color(31, 36, 43),
        Grayer = Color(214, 220, 229),
        Grayish = Color(154, 162, 173),
        Green = Color(94, 200, 121),
        White = Color(244, 241, 233),
        Red = Color(177, 55, 65),
        LightRed = Color(225, 88, 88),
        Yellow = Color(255, 190, 50),
        Accent = Color(255, 190, 50)
    }
    -- SymChars-Design
    if SYMUI then
        Colors.Yellow = SYMUI.LiveAccent()
        Colors.Accent = SYMUI.LiveAccent()
        Colors.White = SYMUI.col.text
        Colors.Grayer = SYMUI.col.text
        Colors.Grayish = SYMUI.col.dim
        Colors.Green = SYMUI.col.green
        Colors.LightRed = SYMUI.col.red
        Colors.Darker = Color(6, 8, 11)
        Colors.Dark = Color(11, 14, 18)
        Colors.Gray = Color(27, 32, 40)
    end

    local function Load()
        hradio = {}
        hradio.Colors = Colors

        include("helio_radio/sh_helio_errorcatcher.lua")
        include("helio_radio/sh_helio_channels.lua")
        include("helio_radio/sh_helio_config_general.lua")

        include("helio_radio/cl/helio_radio_init.lua")
        include("helio_radio/cl/helio_radio_oldvcremoval.lua")
        include("helio_radio/cl/helio_radio_networking.lua")
        include("helio_radio/cl/helio_radio_commands.lua")
        include("helio_radio/cl/helio_radio_hotkeys.lua")
        include("helio_radio/cl/helio_radio_3d2dmenu.lua")
        include("helio_radio/cl/helio_radio_squadmenu.lua")
        include("helio_radio/cl/helio_radio_medicmenu.lua")
        include("helio_radio/cl/helio_radio_2dmenu.lua")
        include("helio_radio/cl/helio_radio_notifications.lua")

        if table.Count(hradio.errorcatcher.startupErrors) > 0 then
            hradio.errorcatcher.open()
        end
    end

    hook.Add("InitPostEntity", "hRadio_Radio", Load)
    concommand.Add("cl_hRadio_Reload", Load)
end
