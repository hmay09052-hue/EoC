GRN_HUD_V1 = GRN_HUD_V1 or {}
GRN_HUD_V1.Version = "3.1.1"

local READY_NET = "GRN_HUD_EOC_ClientReady"

local function safeInclude(path)
    local ok, result = pcall(include, path)
    if not ok then
        ErrorNoHalt("[GRN HUD] " .. tostring(result) .. "\n")
        return false
    end
    return true
end

if SERVER then
    AddCSLuaFile("autorun/grn_hud_v1_init.lua")
    AddCSLuaFile("grn_hud_v1/sh_config.lua")
    AddCSLuaFile("grn_hud_v1/cl_hud.lua")
    AddCSLuaFile("grn_hud_v1/cl_overhead.lua")

    safeInclude("grn_hud_v1/sh_config.lua")

    util.AddNetworkString(READY_NET)
    net.Receive(READY_NET, function(_, ply)
        if not IsValid(ply) then return end
    end)

    return
end

safeInclude("grn_hud_v1/sh_config.lua")
safeInclude("grn_hud_v1/cl_hud.lua")
safeInclude("grn_hud_v1/cl_overhead.lua")
