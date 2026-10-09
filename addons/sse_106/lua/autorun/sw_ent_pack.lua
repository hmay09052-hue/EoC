AddCSLuaFile()

SSE = {}
SSE.Config = {}
SSE.Version = "1.0.5"


if CLIENT then
    include("sse/cl_lib.lua")
    include("sse/sh_sse_config.lua")
    SSE.Imgui = include("sse/cl_imgui.lua")

end

if SERVER then
    AddCSLuaFile("sse/cl_lib.lua")
    AddCSLuaFile("sse/sh_sse_config.lua")
    AddCSLuaFile("sse/cl_imgui.lua")

    include("sse/sh_sse_config.lua")


    resource.AddFile("resource/fonts/agencyfb.ttf")
    local aurebesh = "resource/fonts/" .. (SSE.Config.HUDAurebeshFile or "")
    if SSE.Config.HUDShowAurebesh and file.Exists(aurebesh, "GAME") then
        resource.AddFile(aurebesh)
    end
    
end


