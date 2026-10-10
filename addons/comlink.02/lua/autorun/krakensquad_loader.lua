KrakenSquad = KrakenSquad or {}
KrakenSquad.VERSION = "1.3.3"
KrakenSquad.StartTime = CurTime()

if not KF then
    MsgC(Color(230, 85, 85), "[Kraken's Strike Squad] ", color_white,
        "Kraken's Framework (KF) is not installed.\n")
    return
end

if SERVER then resource.AddWorkshop("3565959952") end

local DIR_PRIORITY = { shared = 1, server = 2, client = 3 }

local function LoadFile(path)
    local fname = path:match("([^/]+)$") or path
    local prefix = fname:sub(1, 3)
    if prefix == "sh_" then
        if SERVER then AddCSLuaFile(path) end
        include(path)
    elseif prefix == "sv_" and SERVER then
        include(path)
    elseif prefix == "cl_" then
        if SERVER then AddCSLuaFile(path) else include(path) end
    end
end

local function LoadFolder(folder)
    local files, dirs = file.Find(folder .. "/*", "LUA")
    table.sort(files or {}, function(a, b)
        local ac, bc = a:EndsWith("_core.lua"), b:EndsWith("_core.lua")
        if ac ~= bc then return ac end
        return a < b
    end)
    for _, f in ipairs(files or {}) do
        if f:EndsWith(".lua") then LoadFile(folder .. "/" .. f) end
    end
    table.sort(dirs or {}, function(a, b)
        return (DIR_PRIORITY[a] or 99) < (DIR_PRIORITY[b] or 99)
    end)
    for _, d in ipairs(dirs) do LoadFolder(folder .. "/" .. d) end
end

LoadFolder("krakensquad")
hook.Run("KrakenSquad.Loaded")

MsgC(Color(100, 180, 255), "[Kraken's Strike Squad] ", color_white,
    "v" .. KrakenSquad.VERSION .. " loaded.\n")
