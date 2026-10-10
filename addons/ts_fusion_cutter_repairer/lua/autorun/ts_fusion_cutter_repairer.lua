FCR = FCR or {}

local base = "fcr/"
local sharedFiles = {
    base .. "sh_lang.lua",
    base .. "sh_config.lua",
    base .. "sh_util.lua"
}

local clientFiles = {
    base .. "cl_fonts.lua",
    base .. "cl_ui.lua",
    base .. "cl_hud.lua"
}

local serverFiles = {
    base .. "sv_core.lua"
}

for _, filePath in ipairs(sharedFiles) do
    AddCSLuaFile(filePath)
    include(filePath)
end

for _, filePath in ipairs(clientFiles) do
    AddCSLuaFile(filePath)
    if CLIENT then
        include(filePath)
    end
end

for _, filePath in ipairs(serverFiles) do
    if SERVER then
        include(filePath)
    end
end

if SERVER then
    local resources = {
        "resource/fonts/sfdistantgalaxy.ttf",
        "models/cosmo/starwarscutter.dx80.vtx",
        "models/cosmo/starwarscutter.dx90.vtx",
        "models/cosmo/starwarscutter.mdl",
        "models/cosmo/starwarscutter.phy",
        "models/cosmo/starwarscutter.sw.vtx",
        "models/cosmo/starwarscutter.vvd",
        "materials/models/stcosmo/diffuse.vtf",
        "materials/models/stcosmo/material.vmt",
        "materials/models/stcosmo/normal.vtf",
        "sound/fcr/beepclick.mp3",
        "sound/fcr/beepclick2.mp3",
    }

    for _, filePath in ipairs(resources) do
        resource.AddSingleFile(filePath)
    end
end
