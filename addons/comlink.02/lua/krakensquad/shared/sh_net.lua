KrakenSquad.RATE_LIMITS = {
    create           = 2,
    invite           = 1,
    communicate      = 0.5,
    command          = 0.5,
    admin            = 0.5,
    layout           = 1,
    chat_cmd         = 1,
    respawn_request  = 0.25,
    respawn_spectate = 0.05,
    respawn_resync   = 0.5,
    switch_preset    = 1,
    order_create     = 0.5,
    order_edit       = 0.5,
}

KrakenSquad.MAX_LENGTHS = {
    squadName         = 32,
    squadNameMin      = 3,
    maxMembers        = 100,
    maxOrders         = 50,
    maxObjectives     = 10,
    orderTitle        = 64,
    orderDescription  = 256,
    objectiveText     = 128,
    orderPresetName   = 64,
    commID            = 32,
    cmdID             = 32,
}

if SERVER then
    local NET = {
        "KS.SquadCreated", "KS.SquadRemoved", "KS.MembersUpdated", "KS.Broadcast",
        "KS.Communications", "KS.CommsPing", "KS.InvitePlayer", "KS.InviteDecision",
        "KS.RequestCreate", "KS.RequestLeave", "KS.RequestKick", "KS.RequestPosChange",
        "KS.RequestComm", "KS.RequestCommand", "KS.RequestJoinPublic", "KS.RequestSquads",
        "KS.AdminConfigSync", "KS.AdminConfigUpdate",
        "KS.AdminPresetCreate", "KS.AdminPresetUpdate", "KS.AdminPresetDelete",
        "KS.LayoutSync", "KS.LayoutUpdate",
        "KS.NPCCreator", "KS.NPCList", "KS.NPCTerminal",
        "KS.OrderCreate", "KS.OrderDelete", "KS.OrderEdit",
        "KS.OrderStatus", "KS.OrderStatusNotify", "KS.OrderSync",
        "KS.OrderPresetSave", "KS.OrderPresetDelete",
        "KS.MedicAlert", "KS.MarkSync",
        "KS.RemoveNPC", "KS.RemoveAllNPCs",
        "KS.RespawnRequest", "KS.RespawnSync", "KS.RespawnCancel",
        "KS.RespawnResync", "KS.RespawnSpectate",
        "KS.OpenPublicList", "KS.OpenAdminMenu",
        "KS.RequestSwitchPreset", "KS.RequestJoinUnit",
    }
    for _, n in ipairs(NET) do util.AddNetworkString(n) end
end

KrakenSquad.Net = KrakenSquad.Net or {}

if SERVER then
    function KrakenSquad.Net.CheckRate(ply, key)
        return KF.Net.CheckRate(ply, key, KrakenSquad.RATE_LIMITS)
    end
end

function KrakenSquad.Net.Receive(name, cb, opts)
    opts = opts or {}
    net.Receive(name, function(len, ply)
        if SERVER then
            if opts.admin   and not KrakenSquad.IsAdmin(ply)                    then return end
            if opts.rateKey and not KrakenSquad.Net.CheckRate(ply, opts.rateKey) then return end
        end
        local ok, err = pcall(cb, len, ply)
        if not ok then
            ErrorNoHalt(("[KrakenSquad] %s (%s): %s\n"):format(name,
                IsValid(ply) and ply:SteamID() or "?", err))
        end
    end)
end
