AddCSLuaFile()

SSE = {}
SSE.Config = {}
SSE.Version = "1.0.6"


if CLIENT then
    include("sse/cl_lib.lua")
    include("sse/sh_sse_config.lua")
    SSE.Imgui = include("sse/cl_imgui.lua")
    -- Server-Design (SymChars-Look mit Aurebesh), nach der Config laden
    include("sse/cl_theme.lua")

end

if SERVER then
    AddCSLuaFile("sse/cl_lib.lua")
    AddCSLuaFile("sse/sh_sse_config.lua")
    AddCSLuaFile("sse/cl_imgui.lua")
    AddCSLuaFile("sse/cl_theme.lua")
    AddCSLuaFile("sse/cl_aurebesh_atlas.lua")

    include("sse/sh_sse_config.lua")


    resource.AddFile("resource/fonts/agencyfb.ttf")
    -- Serverschriften (gleiche Dateien wie im Serverpaket)
    resource.AddFile("resource/fonts/symchars_bignoodle.ttf")
    resource.AddFile("resource/fonts/symchars_robotocondensed.ttf")
    resource.AddFile("resource/fonts/symchars_aurebesh.ttf")
    
end
