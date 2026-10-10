BattleGrid.ServerCommandPosts = BattleGrid.ServerCommandPosts or {}

local STATE = BattleGrid.CPState

function BattleGrid:BroadcastCommandPosts(ply)
    local out = {}
    for _, cp in ipairs(self.ServerCommandPosts) do
        table.insert(out, {
            identifier          = cp.identifier,
            name                = cp.name,
            prefix              = cp.prefix,
            pos                 = cp.pos,
            radius              = cp.radius,
            owner               = cp.owner,
            state               = cp.state,
            ticks               = cp.ticks,
            ticksRequired       = cp.ticksRequired,
            attacker            = cp.attacker,
            default_owner       = cp.default_owner,
            npc_enabled         = cp.npc_enabled,
            npc_max             = cp.npc_max,
            npc_interval        = cp.npc_interval,
            npc_spawn_types     = cp.npc_spawn_types,
            fast_travel_enabled = cp.fast_travel_enabled,
        })
    end
    self.Net:SendJSON("SyncCommandPosts", out, ply)
end

local function ResetOwnership(cp)
    local owner = cp.default_owner or ""
    if owner ~= "" and not BattleGrid:GetFactionByID(owner) then owner = "" end
    cp.owner = owner
    cp.state = owner ~= "" and STATE.CAPTURED or STATE.NEUTRAL
    cp.ticks = 0
    cp.attacker = ""
end

function BattleGrid:SaveCommandPost(cp)
    self.DB:SaveCommandPost(cp)
    self:BroadcastCommandPosts()
end

function BattleGrid:AddCommandPost(cp)
    cp.prefix = cp.prefix or ""
    cp.default_owner = cp.default_owner or ""
    cp.npc_spawn_types = cp.npc_spawn_types or ""
    cp._spawnedNPCs = {}
    cp._nextNPCSpawn = 0
    ResetOwnership(cp)
    table.insert(self.ServerCommandPosts, cp)
    self:SaveCommandPost(cp)
    return cp
end

function BattleGrid:DeleteCommandPost(id)
    local cp = self:GetCPByID(id)
    if not cp then return false end
    if IsValid(cp.entity) and not cp.entity._bgRemoving then
        cp.entity._bgRemoving = true
        cp.entity:Remove()
    end
    for _, npc in ipairs(cp._spawnedNPCs or {}) do
        if IsValid(npc) then npc:Remove() end
    end
    table.RemoveByValue(self.ServerCommandPosts, cp)
    self.DB:DeleteRow("battlegrid_commandposts", id)
    self:BroadcastCommandPosts()
    return true
end

local function SpawnCPEntity(cp)
    local ent = ents.Create("battlegrid_commandpost")
    if not IsValid(ent) then return end
    ent:SetCPIdentifier(cp.identifier)
    ent:SetPos(cp.pos)
    ent:SetAngles(cp.angles or angle_zero)
    ent:Spawn()
    ent:Activate()
    ent:ApplyCPData(cp)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    cp.entity = ent
end

hook.Add("InitPostEntity", "BattleGrid.LoadCommandPosts", function()
    local rows = BattleGrid.DB:LoadCommandPosts()
    for _, row in ipairs(rows) do
        local cp = {
            identifier          = row.identifier,
            name                = row.name,
            prefix              = row.prefix,
            pos                 = row.pos,
            angles              = row.angles,
            radius              = row.radius,
            ticksRequired       = row.ticksRequired,
            default_owner       = row.default_owner,
            npc_enabled         = row.npc_enabled,
            npc_max             = row.npc_max,
            npc_interval        = row.npc_interval,
            npc_spawn_types     = row.npc_spawn_types,
            fast_travel_enabled = row.fast_travel_enabled,
            _spawnedNPCs        = {},
            _nextNPCSpawn       = 0,
        }
        ResetOwnership(cp)
        table.insert(BattleGrid.ServerCommandPosts, cp)
        SpawnCPEntity(cp)
    end
    BattleGrid:BroadcastCommandPosts()
    BattleGrid:Log("Loaded " .. #rows .. " command posts from database.")
end)

-- Entity removal caused by map cleanup or shutdown must not delete the post from the database.
hook.Add("PreCleanupMap", "BattleGrid.CPCleanup", function() BattleGrid._cpRemoveSuppressed = true end)
hook.Add("ShutDown", "BattleGrid.CPCleanup", function() BattleGrid._cpRemoveSuppressed = true end)
hook.Add("PostCleanupMap", "BattleGrid.CPCleanup", function()
    BattleGrid._cpRemoveSuppressed = nil
    for _, cp in ipairs(BattleGrid.ServerCommandPosts) do
        if not IsValid(cp.entity) then SpawnCPEntity(cp) end
    end
    BattleGrid:BroadcastCommandPosts()
end)

local function OverrideValue(v)
    return v ~= nil and (tonumber(v) or -1) or nil
end

BattleGrid.Net:Receive("AdminSaveCommandPost", function(_, ply)
    local data = BattleGrid.Net:ReadJSON()
    if not data or not isstring(data.identifier) or not isstring(data.name) then return end
    local nameLen = utf8.len(data.name) or 0
    if nameLen < 1 or nameLen > 64 then return end

    local cp = BattleGrid:GetCPByID(data.identifier)
    if not cp then return end

    local prevDefault = cp.default_owner
    cp.name          = data.name
    cp.prefix        = isstring(data.prefix) and string.sub(data.prefix, 1, 8) or ""
    cp.radius        = math.max(1, tonumber(data.radius) or cp.radius)
    cp.ticksRequired = math.max(1, math.floor(tonumber(data.ticksRequired) or cp.ticksRequired))
    cp.default_owner = isstring(data.defaultOwner) and data.defaultOwner or ""
    if data.npc_enabled ~= nil then cp.npc_enabled = OverrideValue(data.npc_enabled) end
    if data.npc_max ~= nil then cp.npc_max = OverrideValue(data.npc_max) end
    if data.npc_interval ~= nil then cp.npc_interval = OverrideValue(data.npc_interval) end
    if data.fast_travel_enabled ~= nil then cp.fast_travel_enabled = OverrideValue(data.fast_travel_enabled) end
    if isstring(data.npc_spawn_types) and BattleGrid.ConfigValidators.cp_npc_spawn_types(data.npc_spawn_types) then
        cp.npc_spawn_types = data.npc_spawn_types
    end

    if prevDefault ~= cp.default_owner then ResetOwnership(cp) end
    if IsValid(cp.entity) then cp.entity:ApplyCPData(cp) end
    BattleGrid:SaveCommandPost(cp)
end, { maxLen = 4096, permission = "BattleGrid.Admin", rateLimit = 0.5 })

BattleGrid.Net:Receive("AdminDeleteCommandPost", function()
    local id = net.ReadString()
    if #id <= 32 then BattleGrid:DeleteCommandPost(id) end
end, { maxLen = 512, permission = "BattleGrid.Admin", rateLimit = 0.5 })

local FAST_TRAVEL_COMBAT_COOLDOWN = 60

local function MarkCombat(ply)
    if IsValid(ply) and ply:IsPlayer() then ply._bgLastDamageTime = CurTime() end
end

hook.Add("EntityTakeDamage", "BattleGrid.FastTravelCombat", function(ent, dmg)
    if dmg:GetDamage() > 0 then MarkCombat(ent) end
end)
hook.Add("KMS_PlayerDamaged", "BattleGrid.FastTravelCombat", MarkCombat)

local function SendTravelDeny(ply, reason)
    BattleGrid.Net:Send("FastTravelResult", function()
        net.WriteBool(false)
        net.WriteString(reason)
    end, ply)
end

BattleGrid.Net:Receive("FastTravel", function(_, ply)
    if not ply:Alive() or not BattleGrid:GetConfigBool("cp_fast_travel_enabled") or not BattleGrid:IsCPSystemEnabled() then return end

    local cpID = net.ReadString()
    if cpID == "" or #cpID > 32 then return end

    local Compat = BattleGrid.Compat
    if ply:GetNWBool("BG.InRespawn", false) then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_GENERIC") end
    if Compat.IsRestrained(ply) or not Compat.IsConscious(ply) then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_RESTRAINED") end

    local faction = BattleGrid:GetPlayerFaction(ply)
    local cp = BattleGrid:GetCPByID(cpID)
    if not faction or not cp then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_GENERIC") end
    if cp.fast_travel_enabled == 0 then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_DISABLED") end
    if CurTime() - (ply._bgLastDamageTime or 0) < FAST_TRAVEL_COMBAT_COOLDOWN then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_COMBAT") end
    if cp.state == STATE.CONTESTED then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_CONTESTED") end
    if cp.state == STATE.NEUTRAL then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_NEUTRAL") end
    if cp.owner ~= faction.id then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_ENEMY") end

    local hookResult, hookReason = hook.Run("BattleGrid.CanFastTravel", ply, cp)
    if hookResult == false then return SendTravelDeny(ply, hookReason or "FAST_TRAVEL_DENIED_GENERIC") end

    local travelCost = BattleGrid:CalcFastTravelCost(ply:GetPos(), cp.pos)
    if not Compat.CanAfford(ply, travelCost) then return SendTravelDeny(ply, "FAST_TRAVEL_DENIED_NO_MONEY") end

    local spawnPos, spawnAng = BattleGrid:FindSpawnPos(cp.pos, BattleGrid:GetConfigNumber("cp_spawn_offset"))

    BattleGrid.Net:Send("FastTravelResult", function()
        net.WriteBool(true)
        net.WriteString("")
    end, ply)

    timer.Simple(1.2, function()
        if not IsValid(ply) or not ply:Alive() or not Compat.CanAfford(ply, travelCost) then return end
        Compat.TakeMoney(ply, travelCost)
        ply:SetPos(spawnPos)
        ply:SetEyeAngles(spawnAng)
        ply:SetLocalVelocity(vector_origin)
    end)
end, { maxLen = 512, rateLimit = 1.5 })

local function GatherCPPresence(cp, allPlayers, allNPCs)
    local radiusSqr = cp.radius * cp.radius
    local counts = {}
    for _, ply in ipairs(allPlayers) do
        if ply:Alive() and BattleGrid.Compat.IsConscious(ply) and ply:GetPos():DistToSqr(cp.pos) <= radiusSqr then
            local faction = BattleGrid:GetPlayerFaction(ply)
            if faction then counts[faction.id] = (counts[faction.id] or 0) + 1 end
        end
    end
    for _, npc in ipairs(allNPCs) do
        if IsValid(npc) and npc._bgFaction and npc:Health() > 0 and npc:GetPos():DistToSqr(cp.pos) <= radiusSqr then
            counts[npc._bgFaction] = (counts[npc._bgFaction] or 0) + 1
        end
    end

    local dominant, dominantCount, tied = nil, 0, false
    local hasPresence, enemyPresent = false, false
    for fid, count in pairs(counts) do
        hasPresence = true
        if fid ~= cp.owner then enemyPresent = true end
        if count > dominantCount then
            dominant, dominantCount, tied = fid, count, false
        elseif count == dominantCount then
            tied = true
        end
    end
    if tied then dominant = nil end

    return {
        counts = counts,
        dominant = dominant,
        ownerPresent = cp.owner ~= "" and (counts[cp.owner] or 0) > 0,
        enemyPresent = enemyPresent,
        hasPresence = hasPresence,
    }
end

local function FinishCapture(cp, newOwner)
    cp.owner = newOwner
    cp.state = STATE.CAPTURED
    cp.ticks = 0
    cp.attacker = ""
end

local function DecayContested(cp)
    cp.ticks = math.max(0, cp.ticks - 1)
    if cp.ticks <= 0 then
        cp.state = cp.owner ~= "" and STATE.CAPTURED or STATE.NEUTRAL
        cp.attacker = ""
    end
end

local function FirstEnemyFaction(counts, ownerID)
    for fid, count in pairs(counts) do
        if fid ~= ownerID and count > 0 then return fid end
    end
end

local TICK_HANDLERS = {
    [STATE.NEUTRAL] = function(cp, p)
        if not p.dominant then return end
        if cp.attacker == p.dominant then
            cp.ticks = cp.ticks + 1
        else
            cp.attacker = p.dominant
            cp.ticks = 1
        end
        cp.state = STATE.CONTESTED
        if cp.ticks >= cp.ticksRequired then FinishCapture(cp, p.dominant) end
    end,

    [STATE.CAPTURED] = function(cp, p)
        if not p.enemyPresent then return end
        cp.state = STATE.CONTESTED
        cp.ticks = 1
        cp.attacker = p.ownerPresent and (FirstEnemyFaction(p.counts, cp.owner) or "") or (p.dominant or "")
    end,

    [STATE.CONTESTED] = function(cp, p)
        if not p.enemyPresent then
            DecayContested(cp)
            return
        end
        if p.dominant and p.dominant ~= cp.owner then cp.attacker = p.dominant end

        local attackerCount = cp.attacker ~= "" and (p.counts[cp.attacker] or 0) or 0
        local ownerCount = p.counts[cp.owner] or 0
        if attackerCount > ownerCount then
            cp.ticks = cp.ticks + 1
        elseif ownerCount > attackerCount then
            cp.ticks = math.max(0, cp.ticks - 1)
        end

        if cp.owner ~= "" and cp.ticks >= math.ceil(cp.ticksRequired / 2) then
            cp.owner = ""
        end
        if cp.ticks >= cp.ticksRequired then
            FinishCapture(cp, cp.attacker)
        elseif cp.ticks <= 0 and cp.owner == "" then
            cp.state = STATE.NEUTRAL
            cp.attacker = ""
        end
    end,
}

local function CaptureTick()
    if not BattleGrid:IsCPSystemEnabled() then return end

    local allPlayers = player.GetAll()
    local allNPCs = ents.FindByClass("npc_*")
    local changed = false

    for _, cp in ipairs(BattleGrid.ServerCommandPosts) do
        local presence = GatherCPPresence(cp, allPlayers, allNPCs)
        local prevState, prevOwner = cp.state, cp.owner

        if presence.hasPresence then
            TICK_HANDLERS[cp.state](cp, presence)
        elseif cp.state == STATE.CONTESTED then
            DecayContested(cp)
        end

        if cp.state ~= prevState or cp.owner ~= prevOwner then
            changed = true
            if cp.owner ~= prevOwner then
                BattleGrid:Warn("CP '", cp.name, "' owner: '", prevOwner, "' -> '", cp.owner, "'")
            end
            BattleGrid:Log("CP '", cp.name, "' state: ", prevState, " -> ", cp.state, " | ticks: ", cp.ticks, "/", cp.ticksRequired)
        end
    end

    if changed then BattleGrid:BroadcastCommandPosts() end
end

hook.Add("BattleGrid.ConfigUpdated", "BattleGrid.CPCaptureTimer", function()
    timer.Create("BattleGrid.CPCaptureTick", 1 / math.max(BattleGrid:GetConfigNumber("cp_tick_rate"), 0.1), 0, CaptureTick)
end)

local function ParseSpawnTypes(raw)
    local tbl = raw ~= "" and util.JSONToTable(raw) or nil
    return istable(tbl) and #tbl > 0 and tbl or nil
end

local function PickNPCClass(cp, faction, cfg)
    local spawnTypes = ParseSpawnTypes(cp.npc_spawn_types) or ParseSpawnTypes(cfg.npcSpawnTypes)
    if not spawnTypes then
        if #faction.npcs == 0 then return nil end
        return faction.npcs[math.random(#faction.npcs)]
    end

    local classCounts = {}
    for _, npc in ipairs(cp._spawnedNPCs) do
        local cls = npc._bgNPCClass
        classCounts[cls] = (classCounts[cls] or 0) + 1
    end
    for _, entry in ipairs(spawnTypes) do
        local maxForClass = tonumber(entry.max) or 0
        if isstring(entry.class) and maxForClass > 0 and (classCounts[entry.class] or 0) < maxForClass then
            return entry.class
        end
    end
    return nil
end

local function SpawnFactionNPC(npcClass, pos, ang)
    local npcData = list.Get("NPC")[npcClass]
    if not npcData then return nil end

    local npc = ents.Create(npcData.Class or npcClass)
    if not IsValid(npc) then return nil end

    npc:SetPos(pos)
    npc:SetAngles(ang)
    if npcData.Model then npc:SetModel(npcData.Model) end
    if npcData.Health then
        local hp = tonumber(npcData.Health) or 100
        npc:SetHealth(hp)
        npc:SetMaxHealth(hp)
    end
    for k, v in pairs(npcData.KeyValues or {}) do npc:SetKeyValue(k, v) end

    npc:Spawn()
    npc:Activate()

    for _, wep in ipairs(npcData.Weapons or {}) do npc:Give(wep) end
    return npc
end

timer.Create("BattleGrid.CPNPCSpawnTick", 1, 0, function()
    if not BattleGrid:IsCPSystemEnabled() then return end

    local cfg = BattleGrid:GetCPConfig()
    local now = CurTime()

    for _, cp in ipairs(BattleGrid.ServerCommandPosts) do
        for k = #cp._spawnedNPCs, 1, -1 do
            if not IsValid(cp._spawnedNPCs[k]) then table.remove(cp._spawnedNPCs, k) end
        end

        local enabled = cp.npc_enabled
        if enabled == nil or enabled == -1 then enabled = cfg.npcEnabled and 1 or 0 end
        if enabled ~= 1 then continue end

        local spawnFaction = cp.owner ~= "" and cp.state ~= STATE.NEUTRAL and BattleGrid:GetFactionByID(cp.owner) or nil
        if not spawnFaction then
            for _, npc in ipairs(cp._spawnedNPCs) do
                if IsValid(npc) then npc:Remove() end
            end
            cp._spawnedNPCs = {}
            continue
        end

        local maxNPCs = (cp.npc_max and cp.npc_max ~= -1) and cp.npc_max or cfg.npcMaxPerCP
        local interval = (cp.npc_interval and cp.npc_interval ~= -1) and cp.npc_interval or cfg.npcSpawnInterval
        if #cp._spawnedNPCs >= maxNPCs or now < cp._nextNPCSpawn then continue end

        local npcClass = PickNPCClass(cp, spawnFaction, cfg)
        if not npcClass then continue end

        local spawnPos, spawnAng = BattleGrid:FindSpawnPos(cp.pos, math.Clamp(cp.radius * 0.4, 100, 500), { mask = MASK_NPCSOLID, jitter = 40 })
        local npc = SpawnFactionNPC(npcClass, spawnPos, spawnAng)
        if not npc then
            BattleGrid:Error("Failed to spawn NPC '", npcClass, "' at CP '", cp.name, "'")
            continue
        end

        npc._bgFaction = spawnFaction.id
        npc._bgNPCClass = npcClass
        table.insert(cp._spawnedNPCs, npc)
        cp._nextNPCSpawn = now + interval

        timer.Simple(0.15, function()
            if not IsValid(npc) then return end
            BattleGrid.Net:Send("CPNPCSpawnEffect", function()
                net.WriteUInt(npc:EntIndex(), 14)
                net.WriteVector(spawnPos)
            end)
        end)
    end
end)

BattleGrid._RespawnPending = BattleGrid._RespawnPending or {}
BattleGrid._InitialSpawnDone = BattleGrid._InitialSpawnDone or {}

local function ClearRespawnState(ply)
    BattleGrid._RespawnPending[ply] = nil
    if IsValid(ply) then ply:SetNWBool("BG.InRespawn", false) end
end

hook.Add("PostPlayerDeath", "BattleGrid.RespawnInit", function(ply)
    local Compat = BattleGrid.Compat
    if BattleGrid._RespawnPending[ply] or not BattleGrid._InitialSpawnDone[ply] then return end
    if not BattleGrid:CanUseCPRespawn(ply) or not KF.Integrations.PlayerInWorld(ply) then return end
    if not Compat.HasCharacter(ply) or Compat.HasSquad(ply) or Compat.SquadHandlesRespawn(ply) or Compat.IsSpectating(ply) then return end

    BattleGrid._RespawnPending[ply] = true
    ply:SetNWBool("BG.InRespawn", true)
end)

hook.Add("PlayerDeathThink", "BattleGrid.RespawnBlockDefault", function(ply)
    if BattleGrid._RespawnPending[ply] then return true end
end)

hook.Add("PlayerSpawn", "BattleGrid.RespawnCleanup", function(ply)
    BattleGrid._InitialSpawnDone[ply] = true
    ClearRespawnState(ply)
end)

hook.Add("PlayerDisconnected", "BattleGrid.RespawnDisconnect", function(ply)
    BattleGrid._RespawnPending[ply] = nil
    BattleGrid._InitialSpawnDone[ply] = nil
end)

BattleGrid.Net:Receive("RespawnRequest", function(_, ply)
    if not BattleGrid._RespawnPending[ply] or BattleGrid.Compat.HasSquad(ply) then return end

    local cpID = net.ReadString()
    if cpID == "" or #cpID > 32 then return end

    if cpID == "__default__" then
        ClearRespawnState(ply)
        ply:Spawn()
        return
    end

    local cp = BattleGrid:GetCPByID(cpID)
    local faction = BattleGrid:GetPlayerFaction(ply)
    if not cp or not faction or not BattleGrid:CanRespawnAtCP(faction, cp) then return end

    local spawnPos, spawnAng = BattleGrid:FindSpawnPos(cp.pos, BattleGrid:GetConfigNumber("cp_spawn_offset"))
    ClearRespawnState(ply)
    BattleGrid:Log("Player ", ply:Nick(), " respawned at CP '", cp.name, "' (faction: ", faction.id, ")")

    ply:Spawn()
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        ply:SetPos(spawnPos)
        ply:SetEyeAngles(spawnAng)
        ply:SetLocalVelocity(vector_origin)
    end)
end, { maxLen = 512, rateLimit = 0.2 })
