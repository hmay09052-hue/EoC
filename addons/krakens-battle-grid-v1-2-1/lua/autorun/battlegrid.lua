BattleGrid = BattleGrid or {}
BattleGrid.Version = "1.2.1"
BattleGrid.Debug = false

if SERVER then
    resource.AddWorkshop("3565959952")
end

if not KF then
    MsgC(Color(230, 85, 85), "[Kraken's Battle Grid] ", color_white, "Kraken's Framework (KF) is not installed or failed to load.\n")
    return
end

for _, name in ipairs({
    "sh_core", "sh_language", "sh_factions",
    "sv_core", "sv_markers", "sv_commandposts",
    "cl_core", "cl_markers", "cl_map", "cl_commandposts", "cl_admin",
}) do
    local path = "battlegrid/" .. name .. ".lua"
    local realm = string.sub(name, 1, 2)
    if realm == "sv" then
        if SERVER then include(path) end
    else
        if SERVER then AddCSLuaFile(path) end
        if realm == "sh" or CLIENT then include(path) end
    end
end

hook.Run("BattleGrid.Initialized")
