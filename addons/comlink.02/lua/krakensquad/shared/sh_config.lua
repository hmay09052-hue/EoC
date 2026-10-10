KrakenSquad.Config = KrakenSquad.Config or {}

local DEFAULTS = {
    language     = "de",
    keybind      = KEY_G,
    maxMembers   = 100, -- bis zu 100 Personen pro Squad
    -- Einheits-Squads (SymChars): jede Haupteinheit hat automatisch einen eigenen Squad,
    -- alle Mitglieder der Einheit und ihrer Untereinheiten sind darin.
    unitSquads           = true,
    unitSquadMaxMembers  = 100,
    -- Wer eines dieser SymChars-Rechte in seiner Einheit hat, ist automatisch Squadführer
    -- (Rechte: admin, promotions, invite, kick, transfer – "promotions" gilt standardmäßig ab Sergeant)
    unitSquadLeaderFlags = { "promotions" },
    blockDamage  = false,
    showAvatars  = true,
    framework    = "auto",
    adminGroups  = "superadmin,admin",
    commMarkers  = true,
    ordersViewAll = false,

    sounds = {
        comms        = "kraken/squads/comms.wav",
        ping         = "kraken/squads/ping.wav",
        radialHover  = "kraken/squads/radial_hover.wav",
        radialSelect = "kraken/squads/radial_select.wav",
        invite       = "kraken/squads/invite.wav",
        command      = "kraken/squads/command.wav",
    },
    npcModels = {
        creator    = "models/props_combine/combine_interface001.mdl",
        publicList = "models/props_combine/combine_interface001.mdl",
    },
    npcTexts = { creatorTitle = "SQUAD CREATOR", listTitle = "SQUAD LIST" },
    npcAnimations = { creator = "idle_all_01", publicList = "idle_all_01" },
    npcTerminal = {
        model     = "models/props_combine/combine_interface001.mdl",
        title     = "ORDERS TERMINAL",
        animation = "",
    },

    positions = {
        { name = "Truppführer",    icon = "squads_system/roles/squadleader.png",   color = { 170,  80, 255 }, isOfficer  = true },
        { name = "Stellv. Führer", icon = "squads_system/roles/squadcoleader.png", color = { 200, 140, 255 }, isOfficer  = true },
        { name = "Sanitäter",      icon = "squads_system/roles/medic.png",         color = { 230,  60,  60 }, isMedic    = true, medicComms = { "need_healing" } },
        { name = "Scharfschütze",  icon = "squads_system/roles/marksman.png",      color = {  80, 200, 255 }, isMarksman = true },
        { name = "Schwere Waffen", icon = "squads_system/roles/heavy.png",         color = { 240, 210,  60 } },
        { name = "Infanterist",    icon = "squads_system/roles/rifleman.png",      color = { 180, 185, 195 } },
    },

    communications = {
        { id = "need_healing",      chatMsg = "%PLAYER% braucht einen Sanitäter!", icon = "squads_system/request_medic.png",   color = { 230, 100, 100 }, duration = 10 },
        { id = "watching_here",     chatMsg = "%PLAYER% überwacht diesen Sektor!",       icon = "squads_system/observing.png",       color = {  80, 200, 255 }, duration = 5 },
        { id = "need_support",      chatMsg = "%PLAYER% fordert Verstärkung an!",             icon = "squads_system/request_backup.png",  color = { 200, 120, 255 }, duration = 5 },
        { id = "on_position",       chatMsg = "%PLAYER% ist in Position!", icon = "squads_system/in_position.png",     color = {  80, 220, 120 }, duration = 5 },
        { id = "awaiting_commands", chatMsg = "%PLAYER% wartet auf Befehle!",        icon = "squads_system/standingby.png",      color = { 255, 180,  60 }, duration = 5 },
        { id = "sector_clear",      chatMsg = "%PLAYER% meldet: Sektor gesichert!",     icon = "squads_system/sector_clear.png",    color = { 100, 230, 150 }, duration = 5 },
        { id = "ping_normal",       chatMsg = "%PLAYER% hat eine Position markiert!",           icon = "squads_system/ping.png",            color = { 255, 190,  50 }, duration = 5, triggerPing = "normal" },
        { id = "ping_enemy",        chatMsg = "%PLAYER% hat Feinde gesichtet!",     icon = "squads_system/hostile_spotted.png", color = { 230,  60,  60 }, duration = 5, triggerPing = "enemy"  },
    },

    commands = {
        { id = "assemble",           chatMsg = "%PLAYER% befiehlt: Sammeln bei mir!",               icon = "squads_system/rally_on_me.png",      color = { 255, 220,  80 } },
        { id = "all_around_defense", chatMsg = "%PLAYER% befiehlt: Rundumverteidigung!",    icon = "squads_system/holdthisground.png",   color = {  80, 180, 255 } },
        { id = "defend_position",    chatMsg = "%PLAYER% befiehlt: Position halten!",          icon = "squads_system/holdthisground.png",   color = { 100, 200, 140 } },
        { id = "attack",             chatMsg = "%PLAYER% befiehlt: Vorrücken und angreifen!",           icon = "squads_system/movein_andengage.png", color = { 230,  80,  80 } },
        { id = "cease_fire",         chatMsg = "%PLAYER% befiehlt: Feuer einstellen!",                 icon = "squads_system/standingby.png",       color = { 200, 200, 100 } },
        { id = "retreat",            chatMsg = "%PLAYER% befiehlt: Rückzug!",                 icon = "squads_system/retreat.png",          color = { 255, 140,  60 } },
        { id = "spread_out",         chatMsg = "%PLAYER% befiehlt: Ausschwärmen!", icon = "squads_system/spreadout.png",        color = { 160, 200, 255 } },
        { id = "seek_cover",         chatMsg = "%PLAYER% befiehlt: In Deckung!",              icon = "squads_system/gettocover.png",       color = { 180, 160, 120 } },
    },

    xpRewards    = { enabled = false, frequency = 25, amount = 100, notify = true },
    sharedMoney  = { enabled = false, percentage = 15 },
    presetSquads = {},
    orderPresets = {},
    layout       = {},
    colors       = {
        accent = { 255, 190,  50 },
        ally   = {  80, 160, 255 },
        enemy  = { 230,  85,  85 },
        health = { 255, 255, 255 },
    },
    chatCommands = {
        create = "!createsquad", invite = "!invitesquad",
        kick   = "!kicksquad",   squads = "!squads",
        admin  = "!squadsadmin",
    },
    respawn = {
        enabled          = true,
        inCombatEnabled  = true,
        inCombatDuration = 5,
        timeoutEnabled   = true,
        timeoutDuration  = 30,
        respawnDelay     = 0,
    },
    mrs = { enabled = false, useShortName = false, showIcons = true },
}

KrakenSquad.Defaults = DEFAULTS

function KrakenSquad.GetConfig(key)
    if not key then return KrakenSquad.Config end
    local v = KrakenSquad.Config[key]
    if v ~= nil then return v end
    return DEFAULTS[key]
end

function KrakenSquad.SetConfig(key, value) KrakenSquad.Config[key] = value end

function KrakenSquad.GetPositions()      return KrakenSquad.GetConfig("positions") end
function KrakenSquad.GetCommunications() return KrakenSquad.GetConfig("communications") end
function KrakenSquad.GetCommands()       return KrakenSquad.GetConfig("commands") end

-- Fallback colors by role name, for positions saved without an explicit color.
-- Order matters: more specific keywords first ("coleader" before "leader").
local ROLE_COLOR_KEYWORDS = {
    { { "coleader", "co-leader", "stellv", "xo" },                          { 200, 140, 255 } },
    { { "leader", "führer", "fuehrer", "commander", "kommandant", "lead" }, { 170,  80, 255 } },
    { { "medic", "sani", "arzt", "doctor" },                                { 230,  60,  60 } },
    { { "tech", "engineer", "ingenieur", "pionier" },                       { 255, 140,  30 } },
    { { "marksman", "sniper", "scharfschütze", "scharfschuetze", "dmr" },   {  80, 200, 255 } },
    { { "arf" },                                                            {  80, 220,  80 } },
    { { "heavy", "schwer", "mg", "gunner" },                                { 240, 210,  60 } },
    { { "pilot" },                                                          {  60, 120, 255 } },
    { { "funker", "radio", "comms" },                                       {  40, 220, 200 } },
    { { "rifleman", "schütze", "schuetze", "trooper", "soldat" },           { 180, 185, 195 } },
}
local DEFAULT_ROLE_COLOR = { 180, 185, 195 }

local roleColorCache = setmetatable({}, { __mode = "k" })

function KrakenSquad.GetPositionColor(pd)
    if not pd then return Color(DEFAULT_ROLE_COLOR[1], DEFAULT_ROLE_COLOR[2], DEFAULT_ROLE_COLOR[3]) end
    local cached = roleColorCache[pd]
    if cached then return cached end

    local c = pd.color
    if not (istable(c) and (c[1] or c["1"])) then
        c = DEFAULT_ROLE_COLOR
        local name = (pd.name or ""):lower()
        for _, entry in ipairs(ROLE_COLOR_KEYWORDS) do
            for _, kw in ipairs(entry[1]) do
                if name:find(kw, 1, true) then c = entry[2] break end
            end
            if c ~= DEFAULT_ROLE_COLOR then break end
        end
    end
    local col = Color(c[1] or c["1"] or 255, c[2] or c["2"] or 255, c[3] or c["3"] or 255)
    roleColorCache[pd] = col
    return col
end

function KrakenSquad.GetCommunicationByID(id)
    for _, c in ipairs(KrakenSquad.GetCommunications()) do if c.id == id then return c end end
end

function KrakenSquad.GetCommandByID(id)
    for _, c in ipairs(KrakenSquad.GetCommands()) do if c.id == id then return c end end
end

-- Alte englische Standard-Chatnachrichten (z.B. aus einer gespeicherten config.json) -> Deutsch
local CHAT_EN = {
    need_healing = "%PLAYER% is requesting medical assistance!",
    watching_here = "%PLAYER% is surveilling this sector!",
    need_support = "%PLAYER% is requesting backup!",
    on_position = "%PLAYER% has reached the designated point!",
    awaiting_commands = "%PLAYER% is standing by for orders!",
    sector_clear = "%PLAYER% confirms the area is secured!",
    ping_normal = "%PLAYER% has flagged a location!",
    ping_enemy = "%PLAYER% has spotted hostile activity!",
    assemble = "%PLAYER% orders: Rally on me!",
    all_around_defense = "%PLAYER% orders: Form perimeter defense!",
    defend_position = "%PLAYER% orders: Hold this ground!",
    attack = "%PLAYER% orders: Move in! Engage!",
    cease_fire = "%PLAYER% orders: Hold fire!",
    retreat = "%PLAYER% orders: Fall back!",
    spread_out = "%PLAYER% orders: Disperse! Widen formation!",
    seek_cover = "%PLAYER% orders: Get to cover!",
}
local CHAT_DE = {
    need_healing = "%PLAYER% braucht einen Sanitäter!",
    watching_here = "%PLAYER% überwacht diesen Sektor!",
    need_support = "%PLAYER% fordert Verstärkung an!",
    on_position = "%PLAYER% ist in Position!",
    awaiting_commands = "%PLAYER% wartet auf Befehle!",
    sector_clear = "%PLAYER% meldet: Sektor gesichert!",
    ping_normal = "%PLAYER% hat eine Position markiert!",
    ping_enemy = "%PLAYER% hat Feinde gesichtet!",
    assemble = "%PLAYER% befiehlt: Sammeln bei mir!",
    all_around_defense = "%PLAYER% befiehlt: Rundumverteidigung!",
    defend_position = "%PLAYER% befiehlt: Position halten!",
    attack = "%PLAYER% befiehlt: Vorrücken und angreifen!",
    cease_fire = "%PLAYER% befiehlt: Feuer einstellen!",
    retreat = "%PLAYER% befiehlt: Rückzug!",
    spread_out = "%PLAYER% befiehlt: Ausschwärmen!",
    seek_cover = "%PLAYER% befiehlt: In Deckung!",
}

function KrakenSquad.ChatText(data)
    local msg = data and data.chatMsg or ""
    if CHAT_DE[data.id] and (msg == "" or msg == CHAT_EN[data.id]) then return CHAT_DE[data.id] end
    return msg
end

-- Anzeigename eines Befehls / einer Meldung (übersetzt)
function KrakenSquad.ItemName(item)
    if not item then return "" end
    local text = KrakenSquad.L(item.id)
    if text ~= item.id then return text end
    return item.name or item.id
end

function KrakenSquad.FormatText(txt, ply)
    if not isstring(txt) then return "" end
    local name = IsValid(ply) and ply:Nick() or KrakenSquad.L("unknown_player")
    return txt:gsub("%%PLAYER%%", name)
end

function KrakenSquad.IsAdmin(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    for g in KrakenSquad.GetConfig("adminGroups"):gmatch("([^,]+)") do
        if ply:IsUserGroup(g:Trim()) then return true end
    end
    return false
end

KrakenSquad.ActiveOrders = KrakenSquad.ActiveOrders or {}

function KrakenSquad.GetMRSConfig() return KrakenSquad.GetConfig("mrs") end
function KrakenSquad.MRSAvailable() return MRS and MRS.GetActiveRankData ~= nil end

function KrakenSquad.GetPlayerMRSData(ply)
    local cfg = KrakenSquad.GetMRSConfig()
    if not cfg.enabled or not KrakenSquad.MRSAvailable() then return end
    local group, rank, rankID = MRS.GetActiveRankData(ply)
    if not rank or rank.hidden then return end
    return {
        name   = cfg.useShortName and rank.srt_name or rank.name,
        icon   = (cfg.showIcons and CLIENT) and MRS.GetRankIcon(rank.icon) or nil,
        group  = group,
        rankID = rankID,
    }
end

function KrakenSquad.PlayerMatchesFilters(ply, filters)
    if not filters or #filters == 0 then return true end
    for _, f in ipairs(filters) do
        if KF.Integrations.MatchesFilter(ply, f.type, f.value) then return true end
    end
    return false
end
