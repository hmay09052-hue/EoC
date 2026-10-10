KrakensStore = KrakensStore or {}

if not KF then
    ErrorNoHalt("[Kraken's Store] Kraken's Framework (KF) is required but not loaded. Install krakens-framework.\n")
    return
end

local VERSION = "2.0.0"
KrakensStore.Version = VERSION
KrakensStore.Log = KF.CreateLogger("[Kraken's Store]")

KF.RegisterAddon("krakens_store", "Kraken's Store", {
    version = VERSION,
    prefix = "KS",
    namespace = KrakensStore,
})

KrakensStore.NetNames = {
    "KrakensStore_OpenMenu",
    "KrakensStore_OpenWorkbench",
    "KrakensStore_StoreState",
    "KrakensStore_SyncStoreData",
    "KrakensStore_SyncSettings",
    "KrakensStore_SyncInventory",
    "KrakensStore_UpdateItem",
    "KrakensStore_EntitySync",
    "KrakensStore_Notification",
    "KrakensStore_AdminResponse",
    "KrakensStore_AdminData",
    "KrakensStore_RequestSync",
    "KrakensStore_RequestPurchase",
    "KrakensStore_RequestSell",
    "KrakensStore_RequestEquip",
    "KrakensStore_RequestUseOption",
    "KrakensStore_NPCPlacement",
    "KrakensStore_AdminAction",
    "KrakensStore_RequestAdminData",
}

KrakensStore.SyncCooldown = 10

if SERVER then
    CreateConVar("ks_qa_enabled", "0", FCVAR_ARCHIVE, "Load the Kraken's Store QA runners on the next reload. Development servers only.")
    resource.AddWorkshop("3565959952")
    for _, name in ipairs(KrakensStore.NetNames) do
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

local LANGUAGES = { "de", "en", "es", "fr", "pt", "ru", "uk" }
local FILES = { "sh_types", "sv_db", "sv_inventory", "sv_net", "sv_qa", "cl_menu", "cl_admin" }

local function LoadAddon()
    LoadFile("krakens_store/sh_core.lua")
    for _, code in ipairs(LANGUAGES) do LoadFile("krakens_store/languages/lang_" .. code .. ".lua") end
    if CLIENT then
        KF.Lang.SetLanguage(KrakensStore.AID, KF.Lang.DetectLanguage(KrakensStore.AID))
    end
    for _, name in ipairs(FILES) do LoadFile("krakens_store/" .. name .. ".lua") end
    hook.Run("KrakensStore_RegisterCategories")
    hook.Run("KrakensStore_RegisterItems")
end

LoadAddon()

if SERVER then
    concommand.Add("ks_reload", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        LoadAddon()
        KrakensStore.Boot(true)
        if IsValid(ply) then ply:ChatPrint(KrakensStore.L("msg_addon_reloaded")) end
    end)
end

hook.Run("KrakensStore.Loaded")
KrakensStore.Log("success", "v" .. VERSION .. " loaded")
