BattleGrid.DB = {}

local function DBQuery(query)
    local result = sql.Query(query)
    if result == false then
        BattleGrid:Error("SQL error: ", sql.LastError(), " | Query: ", string.sub(query, 1, 200))
    end
    return result
end

local function EnsureColumns(tbl, cols)
    local present = {}
    for _, col in ipairs(sql.Query("PRAGMA table_info(" .. tbl .. ")") or {}) do
        present[col.name] = true
    end
    for _, def in ipairs(cols) do
        if not present[def:match("^([%w_]+)")] then
            DBQuery("ALTER TABLE " .. tbl .. " ADD COLUMN " .. def)
        end
    end
end

function BattleGrid.DB:Initialize()
    DBQuery("CREATE TABLE IF NOT EXISTS battlegrid_config (key TEXT PRIMARY KEY, value TEXT NOT NULL)")

    DBQuery([[CREATE TABLE IF NOT EXISTS battlegrid_waypoints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier TEXT UNIQUE NOT NULL, map TEXT NOT NULL, name TEXT NOT NULL,
        icon TEXT DEFAULT '',
        color_r INTEGER DEFAULT 255, color_g INTEGER DEFAULT 255, color_b INTEGER DEFAULT 255,
        pos_x REAL NOT NULL, pos_y REAL NOT NULL, pos_z REAL NOT NULL,
        state TEXT NOT NULL, creator_steamid TEXT DEFAULT '', created_at INTEGER DEFAULT 0,
        description TEXT DEFAULT '')]])
    EnsureColumns("battlegrid_waypoints", { "description TEXT DEFAULT ''", "faction_id TEXT DEFAULT ''" })

    DBQuery([[CREATE TABLE IF NOT EXISTS battlegrid_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier TEXT UNIQUE NOT NULL, map TEXT NOT NULL, name TEXT NOT NULL,
        color_r INTEGER DEFAULT 255, color_g INTEGER DEFAULT 255, color_b INTEGER DEFAULT 255,
        pos1_x REAL NOT NULL, pos1_y REAL NOT NULL, pos1_z REAL NOT NULL,
        pos2_x REAL NOT NULL, pos2_y REAL NOT NULL, pos2_z REAL NOT NULL,
        area_type TEXT NOT NULL DEFAULT 'Rectangular',
        state TEXT NOT NULL, creator_steamid TEXT DEFAULT '', created_at INTEGER DEFAULT 0)]])
    EnsureColumns("battlegrid_areas", { "faction_id TEXT DEFAULT ''" })

    DBQuery([[CREATE TABLE IF NOT EXISTS battlegrid_commandposts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier TEXT UNIQUE NOT NULL, map TEXT NOT NULL, name TEXT NOT NULL,
        pos_x REAL NOT NULL, pos_y REAL NOT NULL, pos_z REAL NOT NULL,
        angle_p REAL DEFAULT 0, angle_y REAL DEFAULT 0, angle_r REAL DEFAULT 0,
        capture_radius REAL DEFAULT 512, ticks_required INTEGER DEFAULT 10,
        default_owner TEXT DEFAULT '', prefix TEXT DEFAULT '', created_at INTEGER DEFAULT 0)]])
    EnsureColumns("battlegrid_commandposts", {
        "prefix TEXT DEFAULT ''",
        "angle_p REAL DEFAULT 0", "angle_y REAL DEFAULT 0", "angle_r REAL DEFAULT 0",
        "npc_enabled INTEGER DEFAULT -1", "npc_max INTEGER DEFAULT -1", "npc_interval REAL DEFAULT -1",
        "npc_spawn_types TEXT DEFAULT ''",
        "fast_travel_enabled INTEGER DEFAULT -1",
    })

    BattleGrid._configCache = {}
    for _, row in ipairs(sql.Query("SELECT key, value FROM battlegrid_config") or {}) do
        BattleGrid._configCache[row.key] = row.value
    end
    for key, value in pairs(BattleGrid.ConfigDefaults) do
        if BattleGrid._configCache[key] == nil then BattleGrid:SetConfig(key, value) end
    end
end

function BattleGrid:SetConfig(key, value)
    value = tostring(value)
    self._configCache[key] = value
    DBQuery("INSERT OR REPLACE INTO battlegrid_config (key, value) VALUES (" .. sql.SQLStr(key) .. ", " .. sql.SQLStr(value) .. ")")
end

function BattleGrid:GetAllConfig()
    return table.Copy(self._configCache)
end

function BattleGrid:GetPlayerLimits(ply)
    local groups = util.JSONToTable(self:GetConfig("group_limits")) or {}
    local limits = groups[ply:GetUserGroup()]
    if istable(limits) then
        return { waypoints = tonumber(limits.waypoints) or 0, areas = tonumber(limits.areas) or 0 }
    end
    return {
        waypoints = self:GetConfigNumber("default_public_waypoints"),
        areas = self:GetConfigNumber("default_public_areas"),
    }
end

function BattleGrid.DB:DeleteRow(tbl, identifier)
    DBQuery("DELETE FROM " .. tbl .. " WHERE identifier = " .. sql.SQLStr(identifier))
end

function BattleGrid.DB:DeleteAllRows(tbl)
    DBQuery("DELETE FROM " .. tbl .. " WHERE map = " .. sql.SQLStr(game.GetMap()))
end

local function RowColor(row)
    return Color(tonumber(row.color_r) or 255, tonumber(row.color_g) or 255, tonumber(row.color_b) or 255)
end

function BattleGrid.DB:SaveWaypoint(data)
    local col = data.color or color_white
    DBQuery(string.format(
        "INSERT OR REPLACE INTO battlegrid_waypoints (identifier, map, name, icon, color_r, color_g, color_b, pos_x, pos_y, pos_z, state, creator_steamid, created_at, description, faction_id) VALUES (%s, %s, %s, %s, %d, %d, %d, %f, %f, %f, %s, %s, %d, %s, %s)",
        sql.SQLStr(data.identifier), sql.SQLStr(game.GetMap()), sql.SQLStr(data.name), sql.SQLStr(data.icon or ""),
        col.r, col.g, col.b, data.pos.x, data.pos.y, data.pos.z,
        sql.SQLStr(data.state), sql.SQLStr(data.steamid or ""), os.time(),
        sql.SQLStr(data.description or ""), sql.SQLStr(data.faction_id or "")
    ))
end

function BattleGrid.DB:LoadWaypoints()
    local result = {}
    for _, row in ipairs(sql.Query("SELECT * FROM battlegrid_waypoints WHERE map = " .. sql.SQLStr(game.GetMap())) or {}) do
        table.insert(result, {
            identifier = row.identifier,
            name = row.name,
            icon = row.icon,
            description = row.description or "",
            color = RowColor(row),
            pos = Vector(tonumber(row.pos_x) or 0, tonumber(row.pos_y) or 0, tonumber(row.pos_z) or 0),
            state = row.state,
            steamid = row.creator_steamid,
            faction_id = row.faction_id or "",
        })
    end
    return result
end

function BattleGrid.DB:SaveArea(data)
    local col = data.color or color_white
    DBQuery(string.format(
        "INSERT OR REPLACE INTO battlegrid_areas (identifier, map, name, color_r, color_g, color_b, pos1_x, pos1_y, pos1_z, pos2_x, pos2_y, pos2_z, area_type, state, creator_steamid, created_at, faction_id) VALUES (%s, %s, %s, %d, %d, %d, %f, %f, %f, %f, %f, %f, %s, %s, %s, %d, %s)",
        sql.SQLStr(data.identifier), sql.SQLStr(game.GetMap()), sql.SQLStr(data.name),
        col.r, col.g, col.b,
        data.pos1.x, data.pos1.y, data.pos1.z, data.pos2.x, data.pos2.y, data.pos2.z,
        sql.SQLStr(data.type), sql.SQLStr(data.state), sql.SQLStr(data.steamid or ""), os.time(),
        sql.SQLStr(data.faction_id or "")
    ))
end

function BattleGrid.DB:LoadAreas()
    local result = {}
    for _, row in ipairs(sql.Query("SELECT * FROM battlegrid_areas WHERE map = " .. sql.SQLStr(game.GetMap())) or {}) do
        table.insert(result, {
            identifier = row.identifier,
            name = row.name,
            color = RowColor(row),
            pos1 = Vector(tonumber(row.pos1_x) or 0, tonumber(row.pos1_y) or 0, tonumber(row.pos1_z) or 0),
            pos2 = Vector(tonumber(row.pos2_x) or 0, tonumber(row.pos2_y) or 0, tonumber(row.pos2_z) or 0),
            type = row.area_type,
            state = row.state,
            steamid = row.creator_steamid,
            faction_id = row.faction_id or "",
        })
    end
    return result
end

function BattleGrid.DB:SaveCommandPost(cp)
    local ang = cp.angles or angle_zero
    DBQuery(string.format(
        "INSERT OR REPLACE INTO battlegrid_commandposts (identifier, map, name, pos_x, pos_y, pos_z, angle_p, angle_y, angle_r, capture_radius, ticks_required, default_owner, prefix, npc_enabled, npc_max, npc_interval, npc_spawn_types, fast_travel_enabled, created_at) VALUES (%s, %s, %s, %f, %f, %f, %f, %f, %f, %f, %d, %s, %s, %d, %d, %f, %s, %d, %d)",
        sql.SQLStr(cp.identifier), sql.SQLStr(game.GetMap()), sql.SQLStr(cp.name),
        cp.pos.x, cp.pos.y, cp.pos.z, ang.p, ang.y, ang.r,
        cp.radius, cp.ticksRequired,
        sql.SQLStr(cp.default_owner or ""), sql.SQLStr(cp.prefix or ""),
        tonumber(cp.npc_enabled) or -1, tonumber(cp.npc_max) or -1, tonumber(cp.npc_interval) or -1,
        sql.SQLStr(cp.npc_spawn_types or ""), tonumber(cp.fast_travel_enabled) or -1,
        os.time()
    ))
end

function BattleGrid.DB:LoadCommandPosts()
    local result = {}
    for _, row in ipairs(sql.Query("SELECT * FROM battlegrid_commandposts WHERE map = " .. sql.SQLStr(game.GetMap())) or {}) do
        table.insert(result, {
            identifier = row.identifier,
            name = row.name,
            pos = Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z)),
            angles = Angle(tonumber(row.angle_p) or 0, tonumber(row.angle_y) or 0, tonumber(row.angle_r) or 0),
            radius = tonumber(row.capture_radius) or 512,
            ticksRequired = tonumber(row.ticks_required) or 10,
            default_owner = row.default_owner or "",
            prefix = row.prefix or "",
            npc_enabled = tonumber(row.npc_enabled) or -1,
            npc_max = tonumber(row.npc_max) or -1,
            npc_interval = tonumber(row.npc_interval) or -1,
            npc_spawn_types = row.npc_spawn_types or "",
            fast_travel_enabled = tonumber(row.fast_travel_enabled) or -1,
        })
    end
    return result
end

BattleGrid.DB:Initialize()

hook.Add("BattleGrid.Initialized", "BattleGrid.ApplyConfig", function()
    hook.Run("BattleGrid.ConfigUpdated")
end)

function BattleGrid:SyncConfigTo(ply)
    self.Net:SendJSON("SyncConfig", self:GetAllConfig(), ply)
end

local function IsJSONTable(value)
    return value == "" or istable(util.JSONToTable(value))
end

local V = BattleGrid.ConfigValidators
V.group_limits = IsJSONTable
V.custom_icons = IsJSONTable
V.jammer_hack_whitelist = IsJSONTable
V.cp_npc_spawn_types = IsJSONTable

local function IsSafePath(value)
    return not string.find(value, "%.%.") and not string.find(value, "[\r\n]")
end
V.jammer_model = IsSafePath
V.cp_capture_sound = IsSafePath
V.cp_loss_sound = IsSafePath

BattleGrid.Net:Receive("AdminSetConfig", function(_, ply)
    local data = BattleGrid.Net:ReadJSON()
    if not data or not isstring(data.key) or not isstring(data.value) then return end
    local key, value = data.key, data.value
    if BattleGrid.ConfigDefaults[key] == nil or #value > 65535 then return end
    if V[key] and not V[key](value) then return end

    BattleGrid:SetConfig(key, value)
    BattleGrid:Warn("Config '", key, "' changed to '", string.sub(value, 1, 100), "' by ", ply:Nick(), " [", ply:SteamID(), "]")
    BattleGrid:SyncConfigTo()
    hook.Run("BattleGrid.ConfigUpdated")
end, { maxLen = 65536, permission = "BattleGrid.Admin", rateLimit = 0.5 })

BattleGrid.Net:Receive("AdminDeleteAll", function(_, ply)
    local kind = net.ReadString()
    if BattleGrid:DeleteAllMarkers(kind) then
        BattleGrid:Warn("Admin ", ply:Nick(), " [", ply:SteamID(), "] deleted all ", kind)
    end
end, { maxLen = 512, permission = "BattleGrid.Admin", rateLimit = 1 })

BattleGrid.Net:Receive("ClientReady", function(_, ply)
    BattleGrid:SyncConfigTo(ply)
    BattleGrid:BroadcastMarkers(ply)
    BattleGrid:BroadcastCommandPosts(ply)
    BattleGrid:BroadcastJammers(ply)
end, { maxLen = 64, rateLimit = 5 })
