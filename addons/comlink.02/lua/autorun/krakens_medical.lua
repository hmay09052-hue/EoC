KrakensMedical = KrakensMedical or {}

if not KF then
    ErrorNoHalt("[Kraken's Medical System] Kraken's Framework (KF) is required but not loaded. Install krakens-framework.\n")
    return
end

local VERSION = "1.0.5"
KrakensMedical.Version = VERSION
KrakensMedical.Log = KF.CreateLogger("[Kraken's Medical System]")

KF.RegisterAddon("krakens_medical", "Kraken's Medical System", {
    version = VERSION,
    prefix = "KMS",
    namespace = KrakensMedical,
})

if SERVER then
    resource.AddWorkshop("3565959952")

    local netStrings = {
        "KMS_SyncConfig",
        "KMS_SyncSelf",
        "KMS_SyncPatient",
        "KMS_Watch",
        "KMS_Treat",
        "KMS_Drag",
        "KMS_Release",
        "KMS_Downed",
        "KMS_Progress",
        "KMS_Triage",
        "KMS_Notify",
        "KMS_RequestSync",
        "KMS_AdminAction",
        "KMS_AdminResponse",
        "KMS_OpenMenu",
        "KMS_NPCPlace",
        "KMS_NPCQuote",
        "KMS_NPCAccept",
        "KMS_GiveItem",
        "KMS_StoreItem",
        "KMS_StorageOpen",
        "KMS_StorageSync",
        "KMS_Stratagem",
        "KMS_StratagemStep",
        "KMS_VehicleLoad",
        "KMS_CancelTreat",
        "KMS_VehInvOpen",
        "KMS_VehInvMove",
        "KMS_VehInvSync",
        "KMS_SimSetup",
        "KMS_SimStart",
        "KMS_ExamQ",
        "KMS_ExamAnswer",
        "KMS_QuickUse",
        "KMS_LootItem",
        "KMS_LootOpen",
        "KMS_MedbayDeploy",
    }
    for _, name in ipairs(netStrings) do
        util.AddNetworkString(name)
    end
end

local function LoadFile(path)
    local prefix = string.sub(string.GetFileFromFilename(path), 1, 3)
    if prefix == "sh_" then
        if SERVER then AddCSLuaFile(path) end
        include(path)
    elseif prefix == "sv_" then
        if SERVER then include(path) end
    elseif prefix == "cl_" then
        if SERVER then AddCSLuaFile(path) else include(path) end
    else
        if SERVER then AddCSLuaFile(path) end
        include(path)
    end
end

local function LoadFolder(folder, skip)
    skip = skip or {}
    local files, dirs = file.Find(folder .. "/*", "LUA")
    local sorted = {}
    for _, f in ipairs(files or {}) do
        if string.EndsWith(f, ".lua") and not skip[folder .. "/" .. f] then
            sorted[#sorted + 1] = f
        end
    end
    table.sort(sorted, function(a, b)
        local pa = a:sub(1, 3) == "sh_" and 1 or (a:sub(1, 3) == "sv_" and 2 or 3)
        local pb = b:sub(1, 3) == "sh_" and 1 or (b:sub(1, 3) == "sv_" and 2 or 3)
        if pa ~= pb then return pa < pb end
        return a < b
    end)
    for _, f in ipairs(sorted) do LoadFile(folder .. "/" .. f) end
    table.sort(dirs or {}, function(a, b)
        local priority = { shared = 1, languages = 2, server = 3, client = 4 }
        return (priority[a] or 99) < (priority[b] or 99)
    end)
    for _, d in ipairs(dirs or {}) do
        local sub = folder .. "/" .. d
        if not skip[sub] then LoadFolder(sub, skip) end
    end
end

local function LoadAddon()
    LoadFile("krakens_medical/sh_core.lua")
    LoadFolder("krakens_medical/languages")
    if CLIENT then KF.Lang.SetLanguage(KrakensMedical.AID, KF.Lang.DetectLanguage(KrakensMedical.AID)) end
    LoadFolder("krakens_medical", {
        ["krakens_medical/sh_core.lua"] = true,
        ["krakens_medical/languages"] = true,
    })
end

LoadAddon()

if SERVER then
    concommand.Add("kms_reload", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        LoadAddon()
        if KrakensMedical.Data then
            KrakensMedical.Data.LoadAll()
            KrakensMedical.SyncConfig(nil)
        end
    end)
end

hook.Run("KrakensMedical.Loaded")
KrakensMedical.Log("success", "v" .. VERSION .. " loaded")
