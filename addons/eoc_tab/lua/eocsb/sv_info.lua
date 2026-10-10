--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - Informationen (Server): aktueller Standort
-------------------------------------------------------------------------------------------------------------]]

local CFG = EOCSB.Config
local FILE = "eocsb/location.txt"

local function LoadLocation()
    local saved = file.Read(FILE, "DATA")
    saved = saved and string.Trim(saved) or ""
    SetGlobalString("EOCSB_Location", saved ~= "" and saved or CFG.DefaultLocation)
end

function EOCSB.SetLocation(text)
    text = string.sub(string.Trim(tostring(text or "")), 1, 48)
    if text == "" then text = CFG.DefaultLocation end
    SetGlobalString("EOCSB_Location", text)
    file.CreateDir("eocsb")
    file.Write(FILE, text)
end

hook.Add("Initialize", "EOCSB_Location", LoadLocation)
LoadLocation()

local function CanSetLocation(ply)
    if EOCSB.IsAdmin(ply) or EOCSB.InGroupList(ply, CFG.LocationGroups) then return true end
    return CFG.OfficersCanSetLocation and EOCSB.IsOfficer and EOCSB.IsOfficer(ply)
end

hook.Add("PlayerSay", "EOCSB_LocationCommand", function(ply, text)
    local cmd = string.lower(CFG.LocationCommand or "")
    if cmd == "" then return end
    local lower = string.lower(text)
    if lower ~= cmd and string.sub(lower, 1, #cmd + 1) ~= cmd .. " " then return end

    if not CanSetLocation(ply) then
        ply:ChatPrint("[Standort] Dafür hast du keine Berechtigung.")
        return ""
    end
    local arg = string.Trim(string.sub(text, #cmd + 1))
    if arg == "" then
        ply:ChatPrint("[Standort] Aktuell: " .. GetGlobalString("EOCSB_Location", CFG.DefaultLocation) .. "  -  Benutzung: " .. CFG.LocationCommand .. " <Ort>")
        return ""
    end
    EOCSB.SetLocation(arg)
    for _, p in ipairs(player.GetAll()) do
        p:ChatPrint("[Standort] Neuer Standort: " .. GetGlobalString("EOCSB_Location"))
    end
    return ""
end)
