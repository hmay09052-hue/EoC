BattleGrid.AID = "battlegrid"

BattleGrid.Sounds = {
    Hover = "kraken/sw_squadrons/ux/navigation/navigation_slider_02.mp3",
    Click = "kraken/sw_squadrons/ux/navigation/navigation_activate_01.mp3",
}

BattleGrid.Limits = {
    NAME        = 32,
    DESCRIPTION = 128,
}

BattleGrid.JammerDifficulty = {
    { cables = 4, decoys = 0, swapInterval = 0, labelKey = "JAMMER_HACK_LABEL_EASY",    adminKey = "ADMIN_JAMMER_DIFF_EASY" },
    { cables = 5, decoys = 0, swapInterval = 0, labelKey = "JAMMER_HACK_LABEL_MEDIUM",  adminKey = "ADMIN_JAMMER_DIFF_MEDIUM" },
    { cables = 5, decoys = 1, swapInterval = 0, labelKey = "JAMMER_HACK_LABEL_HARD",    adminKey = "ADMIN_JAMMER_DIFF_HARD" },
    { cables = 6, decoys = 0, swapInterval = 4, labelKey = "JAMMER_HACK_LABEL_EXTREME", adminKey = "ADMIN_JAMMER_DIFF_EXTREME" },
}

function BattleGrid:GetJammerDifficulty(level)
    return self.JammerDifficulty[math.Clamp(math.floor(tonumber(level) or 1), 1, #self.JammerDifficulty)]
end

BattleGrid.ConfigDefaults = {
    language                  = "en",
    blocked_maps              = "",
    announce_public_markers   = "1",
    open_key                  = tostring(KEY_M),

    default_public_waypoints  = "5",
    default_public_areas      = "4",

    map_camera_distance       = "15361",
    map_default_zoom          = "10000",
    map_overlay_alpha         = "4",

    jammer_model              = "models/props_combine/combine_interface001.mdl",
    jammer_default_health     = "5000",
    jammer_default_radius     = "1000",
    jammer_hackable           = "1",
    jammer_hack_time          = "6",
    jammer_shock_damage       = "15",
    jammer_default_difficulty = "1",
    jammer_hack_whitelist     = "[]",

    factions_enabled          = "0",
    factions_data             = "[]",

    cp_enabled                = "0",
    cp_tick_rate              = "1",
    cp_ticks_to_capture       = "10",
    cp_capture_radius         = "512",
    cp_default_owner          = "",
    cp_announce_captures      = "1",
    cp_spawn_offset           = "200",
    cp_capture_sound          = "kraken/sw_squadrons/award/eor_victory_02.mp3",
    cp_loss_sound             = "kraken/sw_squadrons/ux/unlock/lootbox_starcardselect_01.mp3",

    cp_respawn_enabled        = "1",
    cp_fast_travel_enabled    = "1",
    cp_fast_travel_cost       = "0",
    cp_fast_travel_dist_scale = "0",
    cp_fast_travel_dist_mult  = "0.1",

    cp_npc_enabled            = "0",
    cp_npc_max_per_cp         = "4",
    cp_npc_spawn_interval     = "15",
    cp_npc_spawn_types        = "",

    radar_map_enabled         = "0",
    custom_icons              = "[]",
    group_limits              = util.TableToJSON({
        superadmin = { waypoints = 999, areas = 999 },
        admin      = { waypoints = 10,  areas = 5 },
    }),
}

-- Server-side validators for config values that are more than a plain string (filled by sv_core / sh_factions).
BattleGrid.ConfigValidators = {}

function BattleGrid:GetConfig(key)
    local value
    if SERVER then
        value = self._configCache and self._configCache[key]
    else
        value = (self._pendingCfg and self._pendingCfg[key]) or (self._cfg and self._cfg[key])
    end
    if value == nil then value = self.ConfigDefaults[key] end
    return value
end

function BattleGrid:GetConfigBool(key)
    return self:GetConfig(key) == "1"
end

function BattleGrid:GetConfigNumber(key)
    return tonumber(self:GetConfig(key)) or tonumber(self.ConfigDefaults[key]) or 0
end

function BattleGrid:IsMapAllowed()
    return self._mapAllowed ~= false
end

hook.Add("BattleGrid.ConfigUpdated", "BattleGrid.MapAllowed", function()
    local map = game.GetMap()
    BattleGrid._mapAllowed = true
    for entry in string.gmatch(BattleGrid:GetConfig("blocked_maps"), "[^,]+") do
        if string.Trim(entry) == map then BattleGrid._mapAllowed = false end
    end
end)

local _bgLog = KF.CreateLogger("[BattleGrid]")

function BattleGrid:Log(...)
    if not self.Debug then return end
    _bgLog("info", ...)
end

function BattleGrid:Warn(...)
    _bgLog("warn", ...)
end

function BattleGrid:Error(...)
    _bgLog("error", ...)
end

function BattleGrid:GetPrefixText()
    return "[" .. self:L("ADDON_NAME") .. "] "
end

function BattleGrid:GenerateUID(name)
    local t = string.format("%08x", math.floor(SysTime() * 1000) % 0xFFFFFFFF)
    local n = string.gsub(string.upper(string.sub(name or "X", 1, 3)), "[^%w]", "")
    local r = string.format("%04x%04x", math.random(0, 65535), math.random(0, 65535))
    return n .. t .. r
end

function BattleGrid:DistanceFadeAlpha(dist, maxDist, baseAlpha)
    if dist > maxDist * 0.8 then
        return math.Clamp(baseAlpha * (1 - (dist - maxDist * 0.8) / (maxDist * 0.2)), 0, baseAlpha)
    end
    return baseAlpha
end

function BattleGrid:IsValidVector(v)
    if not isvector(v) then return false end
    local x, y, z = v.x, v.y, v.z
    if x ~= x or y ~= y or z ~= z then return false end
    if math.abs(x) > 50000 or math.abs(y) > 50000 or math.abs(z) > 50000 then return false end
    return true
end

function BattleGrid.ColorCopy(src)
    if not src then return Color(255, 255, 255, 255) end
    return Color(src.r or 255, src.g or 255, src.b or 255, src.a or 255)
end

function BattleGrid:BrightenColor(col, amount)
    return Color(
        math.Clamp(col.r + amount, 0, 255),
        math.Clamp(col.g + amount, 0, 255),
        math.Clamp(col.b + amount, 0, 255),
        col.a or 255
    )
end

function BattleGrid:FindByIdentifier(list, id)
    for _, item in ipairs(list) do
        if item.identifier == id then return item end
    end
    return nil
end

BattleGrid.States = {
    NORMAL = "Normal",
    PERMANENT = "Normal (Permanent)",
    PUBLIC = "Public",
    PUBLIC_PERMANENT = "Public (Permanent)",
}

local STATE_LANG_KEYS = {
    ["Normal"]               = "STATE_NORMAL",
    ["Normal (Permanent)"]   = "STATE_PERMANENT",
    ["Public"]               = "STATE_PUBLIC",
    ["Public (Permanent)"]   = "STATE_PUBLIC_PERMANENT",
}

function BattleGrid:GetStateDisplay(state)
    local key = STATE_LANG_KEYS[state]
    return key and self:L(key) or state
end

function BattleGrid:GetStateChoices()
    local choices = {}
    for _, key in ipairs({ "NORMAL", "PERMANENT", "PUBLIC", "PUBLIC_PERMANENT" }) do
        local v = self.States[key]
        choices[#choices + 1] = { v, self:GetStateDisplay(v) }
    end
    return choices
end

function BattleGrid:ShouldPersistState(state)
    return state == self.States.PUBLIC_PERMANENT or state == self.States.PERMANENT
end

function BattleGrid:CanEditMarker(ply, item)
    return item.steamid == ply:SteamID64() or self:HasPermission(ply, "BattleGrid.Admin")
end

function BattleGrid:CanDeleteMarker(ply, item, publicPermission, permanentPermission)
    if item.state == self.States.NORMAL then
        return item.steamid == ply:SteamID64()
    end
    if item.state == self.States.PUBLIC then
        return self:HasPermission(ply, publicPermission)
    end
    if self:ShouldPersistState(item.state) then
        return self:HasPermission(ply, permanentPermission)
    end
    return false
end

BattleGrid.AreaTypes = {
    RECTANGULAR = "Rectangular",
    ROUND = "Round",
}

local AREA_TYPE_LANG_KEYS = {
    ["Rectangular"] = "AREA_TYPE_RECT",
    ["Round"]       = "AREA_TYPE_ROUND",
}

function BattleGrid:GetAreaTypeDisplay(areaType)
    local key = AREA_TYPE_LANG_KEYS[areaType]
    return key and self:L(key) or areaType
end

BattleGrid.WaypointSchema = {
    { key = "identifier", type = "string" },
    { key = "name", type = "string", default = "" },
    { key = "color", type = "color", default = BattleGrid.ColorCopy(color_white) },
    { key = "pos", type = "vector", default = Vector(0, 0, 0) },
    { key = "state", type = "string", default = BattleGrid.States.NORMAL },
    { key = "icon", type = "string", default = "" },
    { key = "description", type = "string", default = "" },
}

BattleGrid.AreaSchema = {
    { key = "identifier", type = "string" },
    { key = "name", type = "string", default = "" },
    { key = "color", type = "color", default = BattleGrid.ColorCopy(color_white) },
    { key = "pos1", type = "vector", default = Vector(0, 0, 0) },
    { key = "pos2", type = "vector", default = Vector(0, 0, 0) },
    { key = "state", type = "string", default = BattleGrid.States.NORMAL },
    { key = "type", type = "string", default = BattleGrid.AreaTypes.RECTANGULAR },
}

BattleGrid.DefaultIcons = {
    "icon16/flag_red.png",
    "icon16/flag_blue.png",
    "icon16/flag_green.png",
    "icon16/flag_yellow.png",
    "icon16/star.png",
    "icon16/heart.png",
    "icon16/cross.png",
    "icon16/bomb.png",
    "icon16/shield.png",
    "icon16/wrench.png",
    "icon16/world.png",
    "icon16/eye.png",
    "icon16/exclamation.png",
    "icon16/lightning.png",
    "icon16/user.png",
    "icon16/group.png",
    "icon16/house.png",
    "icon16/arrow_up.png",
    "icon16/arrow_down.png",
    "icon16/bullet_go.png",
    "battlegrid/icons/alligator.png",
    "battlegrid/icons/alphag.png",
    "battlegrid/icons/arc170.png",
    "battlegrid/icons/attack.png",
    "battlegrid/icons/awing.png",
    "battlegrid/icons/belbullah.png",
    "battlegrid/icons/coaksheath.png",
    "battlegrid/icons/corsair.png",
    "battlegrid/icons/counter.png",
    "battlegrid/icons/cr90.png",
    "battlegrid/icons/delta7.png",
    "battlegrid/icons/destroy.png",
    "battlegrid/icons/eta2.png",
    "battlegrid/icons/faction_cis.png",
    "battlegrid/icons/faction_imp.png",
    "battlegrid/icons/faction_neu.png",
    "battlegrid/icons/faction_reb.png",
    "battlegrid/icons/faction_rep.png",
    "battlegrid/icons/gauntelet.png",
    "battlegrid/icons/headhunter.png",
    "battlegrid/icons/hyena.png",
    "battlegrid/icons/icon_aux_ion.png",
    "battlegrid/icons/icon_aux_multilock.png",
    "battlegrid/icons/icon_countermeasures.png",
    "battlegrid/icons/icon_engine.png",
    "battlegrid/icons/icon_hull.png",
    "battlegrid/icons/icon_main_weapon.png",
    "battlegrid/icons/icon_shields.png",
    "battlegrid/icons/ig200.png",
    "battlegrid/icons/lvs_starfighter_nantex.png",
    "battlegrid/icons/n1.png",
    "battlegrid/icons/recusant.png",
    "battlegrid/icons/repair.png",
    "battlegrid/icons/skipray.png",
    "battlegrid/icons/snowspeeder.png",
    "battlegrid/icons/soulless.png",
    "battlegrid/icons/tie_adv_v1.png",
    "battlegrid/icons/tie_advanced.png",
    "battlegrid/icons/tie_bomber.png",
    "battlegrid/icons/tie_defender.png",
    "battlegrid/icons/tie_fighter.png",
    "battlegrid/icons/tie_interceptor.png",
    "battlegrid/icons/trifighter.png",
    "battlegrid/icons/tunnel.png",
    "battlegrid/icons/uwing.png",
    "battlegrid/icons/xwing.png",
    "battlegrid/icons/ywing.png",
    "battlegrid/icons/z95.png",
}

BattleGrid.AllIcons = table.Copy(BattleGrid.DefaultIcons)

function BattleGrid:IsAllowedIcon(path)
    return path == "" or table.HasValue(self.AllIcons, path)
end

hook.Add("BattleGrid.ConfigUpdated", "BattleGrid.SyncIcons", function()
    BattleGrid.AllIcons = table.Copy(BattleGrid.DefaultIcons)
    for _, path in ipairs(util.JSONToTable(BattleGrid:GetConfig("custom_icons")) or {}) do
        table.insert(BattleGrid.AllIcons, path)
    end
end)

BattleGrid.CPState = {
    NEUTRAL   = "neutral",
    CAPTURED  = "captured",
    CONTESTED = "contested",
}

function BattleGrid:IsFactionSystemEnabled()
    return self:GetConfigBool("factions_enabled")
end

function BattleGrid:IsCPSystemEnabled()
    return self:IsMapAllowed() and self:GetConfigBool("cp_enabled") and self:IsFactionSystemEnabled()
end

function BattleGrid:GetCPConfig()
    return {
        tickRate         = self:GetConfigNumber("cp_tick_rate"),
        ticksToCapture   = self:GetConfigNumber("cp_ticks_to_capture"),
        captureRadius    = self:GetConfigNumber("cp_capture_radius"),
        defaultOwner     = self:GetConfig("cp_default_owner"),
        spawnOffset      = self:GetConfigNumber("cp_spawn_offset"),
        npcEnabled       = self:GetConfigBool("cp_npc_enabled"),
        npcMaxPerCP      = self:GetConfigNumber("cp_npc_max_per_cp"),
        npcSpawnInterval = self:GetConfigNumber("cp_npc_spawn_interval"),
        npcSpawnTypes    = self:GetConfig("cp_npc_spawn_types"),
    }
end

function BattleGrid:GetCPByID(id)
    return self:FindByIdentifier(SERVER and self.ServerCommandPosts or self.Cache.CommandPosts, id)
end

function BattleGrid:GetCPStateKey(state)
    if state == self.CPState.CONTESTED then return "CP_STATE_CONTESTED" end
    if state == self.CPState.CAPTURED then return "CP_STATE_CAPTURED" end
    return "CP_STATE_NEUTRAL"
end

function BattleGrid:GetCPDisplayName(cp)
    local prefix = cp.prefix or ""
    return prefix ~= "" and (prefix .. "  " .. cp.name) or cp.name
end

function BattleGrid:CalcFastTravelCost(playerPos, cpPos)
    local base = self:GetConfigNumber("cp_fast_travel_cost")
    if base <= 0 then return 0 end
    if not self:GetConfigBool("cp_fast_travel_dist_scale") then return base end
    return math.floor(base + playerPos:Distance(cpPos) * self:GetConfigNumber("cp_fast_travel_dist_mult"))
end

function BattleGrid:CanUseCPRespawn(ply)
    if not self:GetConfigBool("cp_respawn_enabled") or not self:IsCPSystemEnabled() then return false end
    return self:GetPlayerFaction(ply) ~= nil
end

function BattleGrid:CanRespawnAtCP(faction, cp)
    return cp.state == self.CPState.CAPTURED and cp.owner == faction.id
end

if SERVER then
    local SPAWN_DIRS = {
        Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0),
        Vector(0.7, 0.7, 0), Vector(-0.7, 0.7, 0), Vector(0.7, -0.7, 0), Vector(-0.7, -0.7, 0),
        Vector(0.5, 0.86, 0), Vector(-0.5, 0.86, 0), Vector(0.86, 0.5, 0), Vector(-0.86, 0.5, 0),
    }

    function BattleGrid:FindSpawnPos(center, offset, opts)
        opts = opts or {}
        local mask = opts.mask or MASK_PLAYERSOLID
        local jitter = opts.jitter or 0

        for _, dir in ipairs(SPAWN_DIRS) do
            local jitterVec = jitter > 0 and Vector(math.Rand(-jitter, jitter), math.Rand(-jitter, jitter), 0) or vector_origin
            local startPos = center + dir * offset + jitterVec + Vector(0, 0, 64)
            local tr = util.TraceLine({
                start = startPos,
                endpos = startPos - Vector(0, 0, 256),
                mask = mask,
            })
            if tr.Hit and not tr.StartSolid then
                local testPos = tr.HitPos + Vector(0, 0, 1)
                local hull = util.TraceHull({
                    start = testPos,
                    endpos = testPos,
                    mins = Vector(-16, -16, 0),
                    maxs = Vector(16, 16, 72),
                    mask = mask,
                })
                if not hull.Hit then
                    local ang = (center - testPos):Angle()
                    ang.p = 0
                    return testPos, ang
                end
            end
        end

        return center + Vector(math.Rand(-60, 60), math.Rand(-60, 60), 10), Angle(0, math.Rand(0, 360), 0)
    end

    concommand.Add("battlegrid_debug", function(ply, _, args)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        if args[1] == "1" or args[1] == "true" then
            BattleGrid.Debug = true
        elseif args[1] == "0" or args[1] == "false" then
            BattleGrid.Debug = false
        else
            BattleGrid.Debug = not BattleGrid.Debug
        end
        _bgLog("success", "Debug logging " .. (BattleGrid.Debug and "enabled" or "disabled"))
    end)
end

BattleGrid.Net = {}

local PREFIX = "BattleGrid."

if SERVER then
    -- "RespawnCancel" is no longer sent by Battle Grid itself but Kraken's Strike Squad and JLTS still use it.
    for _, name in ipairs({
        "ClientReady", "SyncConfig", "AdminSetConfig", "AdminDeleteAll",
        "SyncWaypoints", "CreateWaypoint", "DeleteWaypoint",
        "SyncAreas", "CreateArea", "DeleteArea",
        "SyncJammers", "JammerStartHack", "JammerHackResult", "JammerHackClose",
        "SyncCommandPosts", "AdminSaveCommandPost", "AdminDeleteCommandPost", "CPNPCSpawnEffect",
        "RespawnRequest", "RespawnCancel",
        "FastTravel", "FastTravelResult",
    }) do
        util.AddNetworkString(PREFIX .. name)
    end
end

local function WriteJSON(data)
    local packed = util.Compress(util.TableToJSON(data) or "[]") or ""
    net.WriteUInt(#packed, 16)
    net.WriteData(packed, #packed)
end

function BattleGrid.Net:SendJSON(name, data, ply)
    net.Start(PREFIX .. name)
    WriteJSON(data)
    if IsValid(ply) then net.Send(ply) else net.Broadcast() end
end

function BattleGrid.Net:SendJSONToServer(name, data)
    net.Start(PREFIX .. name)
    WriteJSON(data)
    net.SendToServer()
end

function BattleGrid.Net:ReadJSON()
    local len = net.ReadUInt(16)
    if len == 0 then return nil end
    local json = util.Decompress(net.ReadData(len), 1048576)
    if not json or json == "" then return nil end
    local ok, result = pcall(util.JSONToTable, json)
    if ok and istable(result) then return result end
    return nil
end

function BattleGrid.Net:Send(name, writeFunc, ply)
    net.Start(PREFIX .. name)
    if writeFunc then writeFunc() end
    if IsValid(ply) then net.Send(ply) else net.Broadcast() end
end

function BattleGrid.Net:SendToServer(name, writeFunc)
    net.Start(PREFIX .. name)
    if writeFunc then writeFunc() end
    net.SendToServer()
end

function BattleGrid.Net:SendSchemaToServer(name, data, schema)
    self:SendToServer(name, function()
        KF.Net.WriteSchema(data, schema)
    end)
end

function BattleGrid.Net:Receive(name, handler, opts)
    opts = opts or {}
    KF.Net.Receive(PREFIX .. name, handler, {
        maxLen = opts.maxLen,
        rateLimit = opts.rateLimit,
        permCheck = opts.permission and function(ply)
            return BattleGrid:HasPermission(ply, opts.permission)
        end or nil,
    })
end

if CAMI then
    CAMI.RegisterPrivilege({ Name = "BattleGrid.PublicWaypoint",    MinAccess = "admin",      Description = "Can create public waypoints" })
    CAMI.RegisterPrivilege({ Name = "BattleGrid.PermanentWaypoint", MinAccess = "admin",      Description = "Can create permanent public waypoints" })
    CAMI.RegisterPrivilege({ Name = "BattleGrid.PublicArea",        MinAccess = "admin",      Description = "Can create public areas" })
    CAMI.RegisterPrivilege({ Name = "BattleGrid.PermanentArea",     MinAccess = "admin",      Description = "Can create permanent public areas" })
    CAMI.RegisterPrivilege({ Name = "BattleGrid.Admin",             MinAccess = "superadmin", Description = "Can access the Battle Grid admin panel" })
end

function BattleGrid:HasPermission(ply, perm)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end

    if CAMI and CAMI.PlayerHasAccess then
        local hasAccess, done = false, false
        CAMI.PlayerHasAccess(ply, perm, function(b)
            hasAccess = b
            done = true
        end)
        if done then return hasAccess end
    end

    return ply:IsAdmin() and perm ~= "BattleGrid.Admin"
end

-- Every optional third-party integration goes through here so the rest of the addon never touches foreign globals.
BattleGrid.Compat = {}
local Compat = BattleGrid.Compat

function Compat.IsConscious(ply)
    return not ply.KMSState or ply.KMSState.conscious == true
end

function Compat.IsRestrained(ply)
    if ply.isArrested and ply:isArrested() then return true end
    if ply.IsRestricted and ply:IsRestricted() then return true end
    return ply.getNetVar ~= nil and ply:getNetVar("restricted") == true
end

function Compat.HasCharacter(ply)
    if EvolutionCharacters and EvolutionCharacters.GetActiveCharacterData then
        return EvolutionCharacters:GetActiveCharacterData(ply) ~= nil
    end
    return true
end

function Compat.IsSpectating(ply)
    return ply:GetNWBool("JLTS_Spectating", false)
end

function Compat.HasSquad(ply)
    return KrakenSquad ~= nil and isfunction(ply.GetKSSquad) and ply:GetKSSquad() ~= nil
end

function Compat.SquadHandlesRespawn(ply)
    if not KrakenSquad then return false end
    if SERVER then return KrakenSquad._PendingRespawn ~= nil and KrakenSquad._PendingRespawn[ply] ~= nil end
    return KrakenSquad._RespawnActive == true
end

function Compat.CanAfford(ply, amount)
    if amount <= 0 then return true end
    if ply.canAfford then return ply:canAfford(amount) end
    if ply.GetCharacter and ply:GetCharacter() then return ply:GetCharacter():HasMoney(amount) end
    if ply.getChar and ply:getChar() then return ply:getChar():hasMoney(amount) end
    return true
end

function Compat.TakeMoney(ply, amount)
    if amount <= 0 then return end
    if ply.addMoney then ply:addMoney(-amount)
    elseif ply.GetCharacter and ply:GetCharacter() then ply:GetCharacter():TakeMoney(amount)
    elseif ply.getChar and ply:getChar() then ply:getChar():takeMoney(amount) end
end

if CLIENT then
    BattleGrid.Cache = BattleGrid.Cache or {}
    BattleGrid.Cache.Waypoints    = BattleGrid.Cache.Waypoints or {}
    BattleGrid.Cache.Areas        = BattleGrid.Cache.Areas or {}
    BattleGrid.Cache.Jammers      = BattleGrid.Cache.Jammers or {}
    BattleGrid.Cache.CommandPosts = BattleGrid.Cache.CommandPosts or {}

    function Compat.CompassState()
        return BF2HUD and BF2HUD.GetCompassState and BF2HUD.GetCompassState() or nil
    end

    function Compat.HUDScale(n)
        return BF2HUD and BF2HUD.Scaled and BF2HUD.Scaled(n) or n
    end

    function Compat.RadarGeometry()
        return BF2HUD and BF2HUD.GetRadarGeometry and BF2HUD.GetRadarGeometry() or nil
    end

    function Compat.HasBF2HUD()
        return BF2HUD ~= nil
    end

    function Compat.SquadMembers(ply)
        if not Compat.HasSquad(ply) then return {} end
        return ply:GetKSSquad():GetMembers() or {}
    end

    function Compat.PlayerDisplayName(ply)
        local fw = KrakenSquad and KrakenSquad.Framework
        if fw and fw.GetPlayerName then return fw.GetPlayerName(ply) end
        return ply:Nick()
    end

    local BF2_HUD_HOOKS = {
        "BF2HUD_MainHUD", "BF2HUD_DrawHitMarkers", "BF2HUD_DrawSimpleOverhead",
        "BF2HUD_DrawCompass", "BF2HUD_DrawRadar", "BF2HUD_DrawKillFeed",
        "BF2HUD_WeaponSelect_Draw", "BF2HUD_LVS_HUD", "BF2HUD_Notifications",
        "BF2HUD_VoiceChat", "BF2HUD_DrawCrosshair",
    }
    local hiddenHooks

    -- Other addons' HUD and camera hooks compete with the respawn screen (hook order is undefined), so they are
    -- parked while it is open and restored afterwards unless their owner re-registered them meanwhile.
    function Compat.SetExternalHUDHidden(hidden, ownCalcViewHook)
        if hidden == (hiddenHooks ~= nil) then return end
        local active = hook.GetTable()
        if hidden then
            hiddenHooks = { HUDPaint = {}, CalcView = {} }
            for _, name in ipairs(BF2_HUD_HOOKS) do
                local fn = (active.HUDPaint or {})[name]
                if fn then hiddenHooks.HUDPaint[name] = fn; hook.Remove("HUDPaint", name) end
            end
            for name, fn in pairs(active.CalcView or {}) do
                if name ~= ownCalcViewHook then hiddenHooks.CalcView[name] = fn; hook.Remove("CalcView", name) end
            end
        else
            for event, hooks in pairs(hiddenHooks) do
                for name, fn in pairs(hooks) do
                    if not (active[event] or {})[name] then hook.Add(event, name, fn) end
                end
            end
            hiddenHooks = nil
        end
    end

    function Compat.ImportBF2F4Factions()
        local catalog = StarWarsBF2UI and StarWarsBF2UI.Catalog
        if not catalog or not catalog.factions then return nil end

        local result = {}
        for _, f4Faction in ipairs(catalog.factions) do
            if f4Faction.name and f4Faction.name ~= "" then
                local displayName = f4Faction.name
                if displayName == "__auto__" then displayName = BattleGrid:L("FACTION_AUTO") end

                local faction = {
                    id = string.lower(string.gsub(displayName, "%s+", "_")),
                    name = displayName,
                    desc = f4Faction.desc or "",
                    icon = f4Faction.icon or "",
                    color = { r = 255, g = 255, b = 255 },
                    jobs = {},
                }
                for _, cat in ipairs(f4Faction.categories or {}) do
                    for _, job in ipairs(cat.jobs or {}) do
                        local jid = job.command or tostring(job.team or "")
                        if jid ~= "" then table.insert(faction.jobs, jid) end
                    end
                end
                table.insert(result, faction)
            end
        end
        return result
    end

    function Compat.HasBF2F4()
        return StarWarsBF2UI ~= nil
    end
end
