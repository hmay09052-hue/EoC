BattleGrid.ServerWaypoints = BattleGrid.ServerWaypoints or {}
BattleGrid.ServerAreas = BattleGrid.ServerAreas or {}

local function IsValidMarkerBase(data)
    local nameLen = utf8.len(data.name) or 0
    if nameLen < 1 or nameLen > BattleGrid.Limits.NAME then return false end
    if #data.identifier < 1 or #data.identifier > 32 then return false end
    return string.match(data.identifier, "^[%w%._%-]+$") ~= nil
end

local MARKER_TYPES = {
    waypoints = {
        list = BattleGrid.ServerWaypoints,
        dbTable = "battlegrid_waypoints",
        schema = BattleGrid.WaypointSchema,
        sync = "SyncWaypoints", create = "CreateWaypoint", delete = "DeleteWaypoint",
        permPublic = "BattleGrid.PublicWaypoint", permPermanent = "BattleGrid.PermanentWaypoint",
        limitKey = "waypoints", limitLangKey = "WP_LIMIT_REACHED",
        announceLangKey = "WP_ANNOUNCED", createdHook = "BattleGrid.WaypointCreated",
        load = function() return BattleGrid.DB:LoadWaypoints() end,
        save = function(data) BattleGrid.DB:SaveWaypoint(data) end,
        validate = function(data)
            if not IsValidMarkerBase(data) then return false end
            if (utf8.len(data.description) or math.huge) > BattleGrid.Limits.DESCRIPTION then return false end
            if not BattleGrid:IsAllowedIcon(data.icon) then return false end
            return BattleGrid:IsValidVector(data.pos)
        end,
    },
    areas = {
        list = BattleGrid.ServerAreas,
        dbTable = "battlegrid_areas",
        schema = BattleGrid.AreaSchema,
        sync = "SyncAreas", create = "CreateArea", delete = "DeleteArea",
        permPublic = "BattleGrid.PublicArea", permPermanent = "BattleGrid.PermanentArea",
        limitKey = "areas", limitLangKey = "AREA_LIMIT_REACHED",
        announceLangKey = "AREA_ANNOUNCED", createdHook = "BattleGrid.AreaCreated",
        load = function() return BattleGrid.DB:LoadAreas() end,
        save = function(data) BattleGrid.DB:SaveArea(data) end,
        validate = function(data)
            if not IsValidMarkerBase(data) then return false end
            if data.type ~= BattleGrid.AreaTypes.RECTANGULAR and data.type ~= BattleGrid.AreaTypes.ROUND then return false end
            return BattleGrid:IsValidVector(data.pos1) and BattleGrid:IsValidVector(data.pos2)
        end,
    },
}

function BattleGrid:ForEachMarkerType(fn)
    for _, def in pairs(MARKER_TYPES) do fn(def) end
end

-- Normal / Normal (Permanent) markers are private to their creator; public ones are
-- additionally restricted to the creator's faction when the faction system is active.
local function CanPlayerSeeMarker(ply, item)
    if item.steamid == ply:SteamID64() then return true end
    if item.state == BattleGrid.States.NORMAL or item.state == BattleGrid.States.PERMANENT then return false end
    if item.faction_id and item.faction_id ~= "" and BattleGrid:IsFactionSystemEnabled() then
        local faction = BattleGrid:GetPlayerFaction(ply)
        return faction ~= nil and faction.id == item.faction_id
    end
    return true
end

function BattleGrid:BroadcastMarkers(ply)
    for _, p in ipairs(IsValid(ply) and { ply } or player.GetAll()) do
        for _, def in pairs(MARKER_TYPES) do
            local visible = {}
            for _, item in ipairs(def.list) do
                if CanPlayerSeeMarker(p, item) then visible[#visible + 1] = item end
            end
            self.Net:SendJSON(def.sync, visible, p)
        end
    end
end

function BattleGrid:DeleteAllMarkers(kind)
    local def = MARKER_TYPES[kind]
    if not def then return false end
    self.DB:DeleteAllRows(def.dbTable)
    table.Empty(def.list)
    self:BroadcastMarkers()
    return true
end

local function CountOwnedByState(list, steamID64, state, excludeID)
    local count = 0
    for _, item in ipairs(list) do
        if item.steamid == steamID64 and item.state == state and item.identifier ~= excludeID then
            count = count + 1
        end
    end
    return count
end

local function CreateMarker(def, data, ply)
    if not BattleGrid:IsMapAllowed() or not def.validate(data) then return end
    local STATES = BattleGrid.States

    data.steamid = ply:SteamID64()
    local existing = BattleGrid:FindByIdentifier(def.list, data.identifier)
    local isOwner = not existing or existing.steamid == data.steamid
    if isOwner then
        local faction = BattleGrid:GetPlayerFaction(ply)
        data.faction_id = faction and faction.id or ""
    else
        if not BattleGrid:HasPermission(ply, "BattleGrid.Admin") then return end
        data.steamid = existing.steamid
        data.faction_id = existing.faction_id
    end
    if existing and BattleGrid:ShouldPersistState(existing.state) and not BattleGrid:ShouldPersistState(data.state)
        and not BattleGrid:HasPermission(ply, def.permPermanent) then
        return
    end

    if data.state == STATES.NORMAL then
        if isOwner and CountOwnedByState(def.list, data.steamid, STATES.NORMAL, data.identifier) >= 50 then return end
    elseif data.state == STATES.PUBLIC then
        if not BattleGrid:HasPermission(ply, def.permPublic) then return end
        local limit = BattleGrid:GetPlayerLimits(ply)[def.limitKey]
        if isOwner and CountOwnedByState(def.list, data.steamid, STATES.PUBLIC, data.identifier) >= limit then
            ply:ChatPrint(BattleGrid:GetPrefixText() .. BattleGrid:L(def.limitLangKey))
            return
        end
    elseif BattleGrid:ShouldPersistState(data.state) then
        if not BattleGrid:HasPermission(ply, def.permPermanent) then return end
    else
        return
    end

    if BattleGrid:ShouldPersistState(data.state) then
        def.save(data)
    elseif existing and BattleGrid:ShouldPersistState(existing.state) then
        BattleGrid.DB:DeleteRow(def.dbTable, data.identifier)
    end

    if existing then
        table.RemoveByValue(def.list, existing)
    end
    table.insert(def.list, data)
    BattleGrid:BroadcastMarkers()
    hook.Run(def.createdHook, data, ply)

    if (data.state == STATES.PUBLIC or data.state == STATES.PUBLIC_PERMANENT) and BattleGrid:GetConfigBool("announce_public_markers") then
        local msg = BattleGrid:GetPrefixText() .. BattleGrid:L(def.announceLangKey, data.name, ply:Nick())
        for _, p in ipairs(player.GetAll()) do p:ChatPrint(msg) end
    end
end

local function DeleteMarker(def, id, ply)
    if #id > 32 or not string.match(id, "^[%w%._%-]+$") then return end
    local item = BattleGrid:FindByIdentifier(def.list, id)
    if not item or not BattleGrid:CanDeleteMarker(ply, item, def.permPublic, def.permPermanent) then return end

    table.RemoveByValue(def.list, item)
    if BattleGrid:ShouldPersistState(item.state) then
        BattleGrid.DB:DeleteRow(def.dbTable, id)
    end
    BattleGrid:BroadcastMarkers()
end

for kind, def in pairs(MARKER_TYPES) do
    hook.Add("BattleGrid.Initialized", "BattleGrid.Load." .. kind, function()
        for _, item in ipairs(def.load()) do table.insert(def.list, item) end
        BattleGrid:Log("Loaded " .. #def.list .. " " .. kind .. " from database.")
    end)

    BattleGrid.Net:Receive(def.create, function(_, ply)
        CreateMarker(def, KF.Net.ReadSchema(def.schema), ply)
    end, { maxLen = 4096, rateLimit = 1 })

    BattleGrid.Net:Receive(def.delete, function(_, ply)
        DeleteMarker(def, net.ReadString(), ply)
    end, { maxLen = 512, rateLimit = 0.5 })
end
