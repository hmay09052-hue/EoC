GRNWeaponrio = GRNWeaponrio or {}

if SERVER then
    AddCSLuaFile("grn_armario/sh_config.lua")
    AddCSLuaFile("grn_armario/cl_html.lua")
    AddCSLuaFile("grn_armario/cl_core.lua")
    AddCSLuaFile("entities/grn_armario_locker/shared.lua")
    AddCSLuaFile("entities/grn_armario_locker/cl_init.lua")

    include("grn_armario/sh_config.lua")

    -- Garantiza que el PNG del icono 3D2D llegue a todos los clientes.
    resource.AddFile("materials/grn_armario/armario_icono.png")

    for _, workshopID in ipairs((GRNWeaponrio.Config and GRNWeaponrio.Config.WorkshopIDs) or {}) do
        if isstring(workshopID) and workshopID ~= "" then
            resource.AddWorkshop(workshopID)
        end
    end

    include("grn_armario/sv_core.lua")

    -- Envía automáticamente cualquier recurso local que agregues más adelante
    -- dentro de materials/grn_armario, sound/grn_armario, models/grn_armario, etc.
    local function AddResourceTree(path)
        local files, dirs = file.Find(path .. "/*", "GAME")

        for _, name in ipairs(files or {}) do
            resource.AddFile(path .. "/" .. name)
        end

        for _, dirName in ipairs(dirs or {}) do
            AddResourceTree(path .. "/" .. dirName)
        end
    end

    timer.Simple(0, function()
        AddResourceTree("materials/grn_armario")
        AddResourceTree("sound/grn_armario")
        AddResourceTree("models/grn_armario")
        AddResourceTree("resource/grn_armario")
        AddResourceTree("particles/grn_armario")
    end)
else
    include("grn_armario/sh_config.lua")
    include("grn_armario/cl_html.lua")
    include("grn_armario/cl_core.lua")
end
