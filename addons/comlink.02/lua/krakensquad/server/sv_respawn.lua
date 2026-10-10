KrakenSquad._PendingRespawn        = {}
KrakenSquad._RespawnDeathTime      = {}
KrakenSquad._RespawnSpectateTarget = {}

local Pending = KrakenSquad._PendingRespawn
local Net     = KrakenSquad.Net

local function Cfg() return KrakenSquad.GetConfig("respawn") end

local function IsInCombat(ply)
    local cfg = Cfg()
    if not cfg.inCombatEnabled then return false end
    local last = ply:GetNWFloat("KS.LastDamage", 0)
    return last > 0 and CurTime() - last < (cfg.inCombatDuration or 5)
end

local function IsDowned(ply)
    return ply.KMSState ~= nil and ply.KMSState.conscious == false
end

local SPAWN_OFFSETS = {
    Vector(-60, 0, 0),  Vector(60, 0, 0),
    Vector(0, -60, 0),  Vector(0, 60, 0),
    Vector(-60, -60, 0), Vector(60, 60, 0),
    Vector(-60, 60, 0),  Vector(60, -60, 0),
}

local function FindSpawnPos(target)
    local pos = target:GetPos()
    for _, off in ipairs(SPAWN_OFFSETS) do
        local test = pos + off + Vector(0, 0, 10)
        local tr = util.TraceLine({ start = test + Vector(0, 0, 36), endpos = test, mask = MASK_PLAYERSOLID })
        if not tr.Hit or tr.Fraction > 0.5 then
            local hull = util.TraceHull({
                start = test, endpos = test,
                mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 72),
                mask = MASK_PLAYERSOLID,
            })
            if not hull.Hit then return test, target:GetAngles() end
        end
    end
    return pos + Vector(0, 0, 10), target:GetAngles()
end

local function GetCPSpawnTargets(ply)
    if not BattleGrid or not BattleGrid.ServerCommandPosts then return {} end
    if not BattleGrid:IsCPSystemEnabled() or not BattleGrid:IsFactionSystemEnabled() then return {} end
    local faction = BattleGrid:GetPlayerFaction(ply)
    if not faction then return {} end
    local out = {}
    for _, cp in ipairs(BattleGrid.ServerCommandPosts) do
        if cp.state == BattleGrid.CPState.CAPTURED and cp.owner == faction.id and IsValid(cp.entity) then
            out[#out + 1] = {
                entIdx = cp.entity:EntIndex(),
                name   = BattleGrid:GetCPDisplayName(cp),
                pos    = cp.pos,
            }
        end
    end
    return out
end

local function FindCPSpawnPos(cpData)
    local off    = (BattleGrid:GetCPConfig().spawnOffset or 200)
    local center = cpData.pos
    local offsets = {
        Vector(off, 0, 0), Vector(-off, 0, 0),
        Vector(0, off, 0), Vector(0, -off, 0),
        Vector(off * 0.7,  off * 0.7,  0), Vector(-off * 0.7,  off * 0.7,  0),
        Vector(off * 0.7, -off * 0.7,  0), Vector(-off * 0.7, -off * 0.7,  0),
    }
    for _, o in ipairs(offsets) do
        local startPos = center + o + Vector(0, 0, 64)
        local tr = util.TraceLine({ start = startPos, endpos = startPos - Vector(0, 0, 256), mask = MASK_PLAYERSOLID })
        if tr.Hit and not tr.StartSolid then
            local test = tr.HitPos + Vector(0, 0, 1)
            local hull = util.TraceHull({
                start = test, endpos = test,
                mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 72),
                mask = MASK_PLAYERSOLID,
            })
            if not hull.Hit then
                local ang = (center - test):Angle()
                ang.p = 0
                return test, ang
            end
        end
    end
    return center + Vector(0, 0, 10), Angle()
end

local function CleanupState(ply)
    Pending[ply]                            = nil
    KrakenSquad._RespawnDeathTime[ply]      = nil
    KrakenSquad._RespawnSpectateTarget[ply] = nil
    ply:SetNWBool("KS.InRespawn", false)
    timer.Remove("KS.RespawnTimeout." .. ply:SteamID64())
end

local function CancelRespawn(ply)
    if not Pending[ply] then return end
    CleanupState(ply)
    KF.Net.Send("KS.RespawnCancel", nil, ply)
end

local function ForceDefaultSpawn(ply)
    if not Pending[ply] then return end
    if KF.Integrations.LifecycleOwned(ply) then CancelRespawn(ply) return end
    CleanupState(ply)
    ply:Spawn()
    KrakenSquad.Notify(ply, "info", KrakenSquad.L("respawn_forced"))
end

local function SendSync(ply)
    local cfg = Cfg()
    local squad = ply:GetKSSquad()
    if not squad then return end

    local memberData = {}
    for _, m in ipairs(squad:GetMembers()) do
        if m ~= ply then
            memberData[#memberData + 1] = { uid = m:UserID(), alive = m:Alive() and not IsDowned(m), combat = IsInCombat(m) }
        end
    end
    local cps = GetCPSpawnTargets(ply)

    KF.Net.Send("KS.RespawnSync", function()
        net.WriteBool(cfg.timeoutEnabled or false)
        net.WriteFloat(cfg.timeoutDuration or 30)
        net.WriteBool(cfg.inCombatEnabled or false)
        net.WriteFloat(cfg.respawnDelay or 0)
        net.WriteUInt(#memberData, 8)
        for _, d in ipairs(memberData) do
            net.WriteUInt(d.uid, 16)
            net.WriteBool(d.alive)
            net.WriteBool(d.combat)
        end
        net.WriteUInt(#cps, 8)
        for _, cp in ipairs(cps) do
            net.WriteInt(cp.entIdx, 32)
            net.WriteString(cp.name)
            net.WriteVector(cp.pos)
        end
    end, ply)
end

local function InitRespawn(ply)
    if Pending[ply] or ply:IsBot() then return end
    if not KF.Integrations.PlayerInWorld(ply) then return end
    if KF.Integrations.LifecycleOwned(ply) then return end
    local cfg = Cfg()
    if not cfg.enabled or not ply:GetKSSquad() then return end

    if BattleGrid and BattleGrid._RespawnPending and BattleGrid._RespawnPending[ply] then
        BattleGrid._RespawnPending[ply] = nil
        ply:SetNWBool("BG.InRespawn", false)
        BattleGrid.Net:Send("RespawnCancel", nil, ply)
    end

    Pending[ply] = true
    KrakenSquad._RespawnDeathTime[ply] = CurTime()
    ply:SetNWBool("KS.InRespawn", true)
    SendSync(ply)

    if cfg.timeoutEnabled then
        timer.Create("KS.RespawnTimeout." .. ply:SteamID64(), cfg.timeoutDuration or 30, 1, function()
            if IsValid(ply) then ForceDefaultSpawn(ply) end
        end)
    end
end

local function MarkCombat(ent)
    if not ent:IsPlayer() or not ent:KSInSquad() then return end
    local cfg = Cfg()
    if not cfg.enabled or not cfg.inCombatEnabled then return end
    ent:SetNWFloat("KS.LastDamage", CurTime())
end

hook.Add("EntityTakeDamage", "KrakenSquad.CombatTracker", MarkCombat)
hook.Add("KMS_PlayerDamaged", "KrakenSquad.CombatTracker", MarkCombat)

hook.Add("PlayerDeath",     "KrakenSquad.RespawnDeath",    InitRespawn)
hook.Add("PostPlayerDeath", "KrakenSquad.RespawnFallback", InitRespawn)

hook.Add("PlayerDeathThink", "KrakenSquad.BlockRespawn", function(ply)
    if Pending[ply] then return true end
end)

hook.Add("PlayerSpawn", "KrakenSquad.RespawnCleanup", function(ply)
    if Pending[ply] then CancelRespawn(ply) end
end)

function KrakenSquad.RespawnHandleSquadChange(ply)
    if not IsValid(ply) or not Pending[ply] then return end
    if ply:GetKSSquad() then SendSync(ply) else ForceDefaultSpawn(ply) end
end

hook.Add("PlayerDisconnected", "KrakenSquad.RespawnDisconnect", function(ply)
    Pending[ply]                            = nil
    KrakenSquad._RespawnDeathTime[ply]      = nil
    KrakenSquad._RespawnSpectateTarget[ply] = nil
    timer.Remove("KS.RespawnTimeout." .. ply:SteamID64())
end)

local function ApplySpawn(ply, pos, ang)
    CleanupState(ply)
    ply:Spawn()
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        ply:SetPos(pos)
        ply:SetEyeAngles(ang)
    end)
end

Net.Receive("KS.RespawnRequest", function(_, ply)
    if not Pending[ply] then return end
    if KF.Integrations.LifecycleOwned(ply) then CancelRespawn(ply) return end
    local cfg = Cfg()
    if not cfg.enabled then return end

    local delay = cfg.respawnDelay or 0
    local death = KrakenSquad._RespawnDeathTime[ply]
    if delay > 0 and death and CurTime() - death < delay then return end

    local target = net.ReadInt(32)
    if target == -1 then ForceDefaultSpawn(ply) return end

    if target < -1 then
        local cpEnt = Entity(-target)
        if not IsValid(cpEnt) or cpEnt:GetClass() ~= "battlegrid_commandpost" then return end
        if not BattleGrid then return end
        local cpData = BattleGrid:GetCPByID(cpEnt:GetCPIdentifier())
        if not cpData or cpData.state ~= BattleGrid.CPState.CAPTURED then return end
        local faction = BattleGrid:GetPlayerFaction(ply)
        if not faction or cpData.owner ~= faction.id then return end
        ApplySpawn(ply, FindCPSpawnPos(cpData))
        return
    end

    local mate = Player(target)
    if not IsValid(mate) or not mate:Alive() or IsDowned(mate) then return end
    local squad = ply:GetKSSquad()
    if not squad or not mate:KSInSquad(squad:GetID()) then return end
    if cfg.inCombatEnabled and IsInCombat(mate) then return end
    ApplySpawn(ply, FindSpawnPos(mate))
end, { rateKey = "respawn_request" })

Net.Receive("KS.RespawnResync", function(_, ply)
    if Pending[ply] then SendSync(ply) end
end, { rateKey = "respawn_resync" })

Net.Receive("KS.RespawnSpectate", function(_, ply)
    if not Pending[ply] then return end
    local uid = net.ReadInt(32)
    local target = uid < 0 and Entity(-uid) or Player(uid)
    KrakenSquad._RespawnSpectateTarget[ply] = IsValid(target) and target or nil
end, { rateKey = "respawn_spectate" })

hook.Add("SetupPlayerVisibility", "KrakenSquad.RespawnPVS", function(ply)
    if not Pending[ply] then return end
    local target = KrakenSquad._RespawnSpectateTarget[ply]
    if IsValid(target) then AddOriginToPVS(target:GetPos()) end
end)

timer.Create("KS.RespawnAlive", 1, 0, function()
    for ply in pairs(Pending) do
        if not IsValid(ply) then
            Pending[ply] = nil
        elseif ply:Alive() or KF.Integrations.LifecycleOwned(ply) then
            CancelRespawn(ply)
        end
    end
end)
