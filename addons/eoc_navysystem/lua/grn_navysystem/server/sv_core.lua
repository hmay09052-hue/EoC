GRN_NAVY = GRN_NAVY or {}
local GN = GRN_NAVY
local C = GN.Config

GN.Whitelist = GN.Whitelist or {}
GN.ManagedShips = GN.ManagedShips or {}
GN.ActiveRTS = GN.ActiveRTS or {}
GN.DB = GN.DB or {}

for _, n in pairs(GN.Net) do util.AddNetworkString(n) end

local function log(msg)
    print("[GRN_NavySystem] " .. tostring(msg))
end

function GN:Escape(v)
    return sql.SQLStr(tostring(v or ""), true)
end

function GN:SetupNative()
    sql.Query("CREATE TABLE IF NOT EXISTS " .. C.PersistenceTable .. " (jobcmd TEXT PRIMARY KEY, teamkey TEXT NOT NULL, enabled INTEGER NOT NULL DEFAULT 1)")
end

function GN:LoadNative()
    self.Whitelist = {}
    local rows = sql.Query("SELECT * FROM " .. C.PersistenceTable)
    if istable(rows) then
        for _, row in ipairs(rows) do
            self.Whitelist[row.jobcmd] = {
                team = row.teamkey,
                enabled = tonumber(row.enabled or 1) == 1,
            }
        end
    end
end

function GN:SaveWhitelistNative()
    sql.Query("DELETE FROM " .. C.PersistenceTable)
    for jobcmd, data in pairs(self.Whitelist or {}) do
        sql.Query(string.format(
            "INSERT OR REPLACE INTO %s (jobcmd, teamkey, enabled) VALUES ('%s','%s',%d)",
            C.PersistenceTable,
            self:Escape(jobcmd),
            self:Escape(data.team or "republic"),
            data.enabled and 1 or 0
        ))
    end
end

function GN:ConnectMySQL(cb)
    if not C.UseMySQL then return cb(false) end
    if not mysqloo then
        log(GRN_NAVY.T("log_mysqloo_missing"))
        return cb(false)
    end
    local db = mysqloo.connect(C.MySQL.Host, C.MySQL.Username, C.MySQL.Password, C.MySQL.Database, C.MySQL.Port)
    db.onConnected = function()
        log(GRN_NAVY.T("log_mysql_connected"))
        GN.DB.Conn = db
        local q = db:query("CREATE TABLE IF NOT EXISTS grn_navy_whitelist (jobcmd VARCHAR(128) PRIMARY KEY, teamkey VARCHAR(32) NOT NULL, enabled TINYINT(1) NOT NULL DEFAULT 1)")
        function q:onSuccess() cb(true) end
        function q:onError(err)
            log(GRN_NAVY.T("log_mysql_table_error") .. err)
            cb(false)
        end
        q:start()
    end
    db.onConnectionFailed = function(_, err)
        log(GRN_NAVY.T("log_mysql_fail") .. tostring(err))
        cb(false)
    end
    db:connect()
end

function GN:LoadMySQL(cb)
    if not self.DB.Conn then return cb(false) end
    self.Whitelist = {}
    local q = self.DB.Conn:query("SELECT * FROM grn_navy_whitelist")
    function q:onSuccess(data)
        for _, row in ipairs(data or {}) do
            GN.Whitelist[row.jobcmd] = {
                team = row.teamkey,
                enabled = tonumber(row.enabled or 1) == 1,
            }
        end
        cb(true)
    end
    function q:onError(err)
        log(GRN_NAVY.T("log_mysql_load_error") .. tostring(err))
        cb(false)
    end
    q:start()
end

function GN:SaveWhitelistMySQL()
    if not self.DB.Conn then return end
    local q1 = self.DB.Conn:query("TRUNCATE TABLE grn_navy_whitelist")
    function q1:onSuccess()
        for jobcmd, data in pairs(GN.Whitelist or {}) do
            local qq = GN.DB.Conn:query(string.format(
                "INSERT INTO grn_navy_whitelist (jobcmd, teamkey, enabled) VALUES ('%s','%s',%d)",
                GN:Escape(jobcmd), GN:Escape(data.team or "republic"), data.enabled and 1 or 0
            ))
            function qq:onError(err) log(GRN_NAVY.T("log_mysql_save_row_error") .. tostring(err)) end
            qq:start()
        end
    end
    function q1:onError(err)
        log(GRN_NAVY.T("log_mysql_clear_error") .. tostring(err))
    end
    q1:start()
end

function GN:LoadPersistence()
    self:SetupNative()
    self:ConnectMySQL(function(ok)
        if ok then
            GN:LoadMySQL(function(mysqlOk)
                if not mysqlOk then GN:LoadNative() end
            end)
        else
            GN:LoadNative()
        end
    end)
end

function GN:SaveWhitelist()
    self:SaveWhitelistNative()
    if C.UseMySQL and self.DB.Conn then
        self:SaveWhitelistMySQL()
    end
end

function GN:GetCapitalCount(teamKey, id)
    local count = 0
    for ent, meta in pairs(self.ManagedShips) do
        if IsValid(ent) and meta.team == teamKey and meta.id == id then
            count = count + 1
        end
    end
    for _, ent in ipairs(ents.FindByClass("vanilla_hyperspace_ship")) do
        if IsValid(ent) then
            local pending = ent.GRN_NavyPendingData
            if pending and pending.type == "capital_spawn" and pending.teamKey == teamKey and pending.def and pending.def.id == id then
                count = count + 1
            end
        end
    end
    return count
end

function GN:PushStateToRTS(teamKey)
    for ply, data in pairs(self.ActiveRTS or {}) do
        if IsValid(ply) and data and data.enabled and (not teamKey or data.team == teamKey) then
            self:PushState(ply)
        end
    end
end

function GN:ResolveEntityModel(className, fallbackEnt)
    if IsValid(fallbackEnt) then
        local mdl = fallbackEnt:GetModel()
        if isstring(mdl) and mdl ~= "" then return mdl end
    end
    local stored = scripted_ents.GetStored(className)
    local t = stored and stored.t or nil
    if istable(t) then
        local candidates = {t.Model, t.WorldModel, t.VehicleModel, t.ShipModel, t.MDL, t.mdl}
        for _, mdl in ipairs(candidates) do
            if isstring(mdl) and mdl ~= "" then return mdl end
        end
    end
    return nil
end

function GN:SpawnEntityProper(className, pos, ang, owner)
    local stored = scripted_ents.GetStored(className)
    local sent = stored and stored.t or nil
    local tr = {
        Hit = true,
        HitWorld = true,
        HitPos = pos,
        HitNormal = Vector(0,0,1),
        StartPos = pos + Vector(0,0,64),
    }

    local ent = nil
    if istable(sent) and isfunction(sent.SpawnFunction) then
        local ok, res = pcall(sent.SpawnFunction, sent, IsValid(owner) and owner or NULL, tr, className)
        if ok and IsValid(res) then
            ent = res
        end
    end

    if not IsValid(ent) then
        ent = ents.Create(className)
        if not IsValid(ent) then return false, GRN_NAVY.T("err_cannot_create_ent") .. tostring(className) end
        ent:SetPos(pos)
        ent:SetAngles(ang or angle_zero)
        if IsValid(owner) and ent.SetCreator then ent:SetCreator(owner) end
        ent:Spawn()
        ent:Activate()
    else
        ent:SetPos(pos)
        ent:SetAngles(ang or angle_zero)
    end

    if IsValid(owner) then
        ent:SetOwner(owner)
    end

    return true, ent
end

function GN:CreateHyperspaceEntity(pos, ang, className, owner, opts)
    if not scripted_ents.GetStored("vanilla_hyperspace_ship") then
        return false, GRN_NAVY.T("err_hyperspace_missing")
    end
    local fx = ents.Create("vanilla_hyperspace_ship")
    if not IsValid(fx) then return false, GRN_NAVY.T("err_hyperspace_anim_fail") end
    opts = opts or {}
    fx:SetPos(pos)
    fx:SetAngles(ang or angle_zero)
    fx:SetOwner(IsValid(owner) and owner or NULL)
    local visualModel = opts.actualModel or self:ResolveEntityModel(className)
    if isstring(visualModel) and visualModel ~= "" then
        fx:SetKeyValue("SpawnModel", "1")
        fx:SetKeyValue("ActualModel", visualModel)
    else
        fx:SetKeyValue("SpawnModel", "0")
    end
    fx:SetKeyValue("Entity", className)
    fx:SetKeyValue("AI", tostring(opts.ai and 1 or 0))
    fx:SetKeyValue("Freeze", tostring(opts.freeze and 1 or 0))
    fx:SetKeyValue("Flip", tostring(opts.flip and 1 or 0))
    fx:SetKeyValue("Retreat", tostring(opts.retreat and 1 or 0))
    fx:SetKeyValue("NoSpawnOnRemove", tostring(opts.noSpawn and 1 or 0))
    fx:SetKeyValue("JumpDistance", tostring(opts.jumpDistance or 15800))
    fx:SetKeyValue("JumpStep", tostring(opts.jumpStep or 450))
    fx:SetKeyValue("Shake", tostring(opts.shake and 1 or 0))
    fx:SetKeyValue("Sound", tostring(opts.sound and 1 or 0))
    fx.GRN_NavyPendingData = opts.pendingData
    fx:Spawn()
    fx:Activate()
    local wake = ents.Create("vanilla_highwake")
    if IsValid(wake) then
        wake:SetPos(pos)
        wake:SetAngles(ang or angle_zero)
        wake:Spawn()
        wake:Activate()
    end
    return true, fx
end

local function forceCapitalShipReady(ent, teamKey)
    if not IsValid(ent) then return end

    ent.GRN_NavyCapital = true
    ent:SetCollisionGroup(COLLISION_GROUP_NONE)
    ent:SetNotSolid(false)
    ent:SetSolid(SOLID_VPHYSICS)
    if ent.DrawShadow then ent:DrawShadow(true) end

    local phys = ent.GetPhysicsObject and ent:GetPhysicsObject() or nil
    if IsValid(phys) then
        phys:EnableCollisions(true)
        phys:EnableMotion(false)
        -- FIX COLISION: asignar masa alta para que el engine trate al objeto
        -- como solido estatico en vez de fantasma cuando Motion esta desactivado
        if phys:GetMass() < 50000 then
            phys:SetMass(50000)
        end
        phys:Wake()
    end

    if ent.SetEnableTurrets then
        ent:SetEnableTurrets(true)
    end
    ent.ENABLETURRETS = true

    if ent.bases == nil and ent.SpawnBigTurrets and ent.TURRETS and ent.TURRETANGLES then
        local ok = pcall(function()
            ent.bullet_filter_ents = ent.bullet_filter_ents or {}
            ent.spawn_angles = ent.spawn_angles or ent:GetAngles()
            ent:SpawnBigTurrets()
        end)
        if not ok then
            ent.bases = ent.bases or {}
            ent.guns = ent.guns or {}
        end
    end

    if ent.SetAITEAM then
        local ai = C.Teams[teamKey] and C.Teams[teamKey].aiTeam or 0
        ent:SetAITEAM(ai)
        ent:SetNWInt("SelfAITeam", ai)
    end
    if ent.SetAI then ent:SetAI(true) end
end

function GN:RegisterShip(ent, teamKey, def, owner)
    self.ManagedShips[ent] = {
        team = teamKey,
        id = def.id,
        def = def,
        owner = owner,
        targetPos = nil,
        speed = def.moveSpeed or 600,
    }
    ent.GRN_NavyCapital = true
    ent.GRN_NavyTeam = teamKey
    ent.GRN_NavyDefID = def.id
    ent:SetNWString("GRN_NavyTeam", teamKey)
    ent:SetNWString("GRN_NavyName", def.name or ent.PrintName or ent:GetClass())
    forceCapitalShipReady(ent, teamKey)
    timer.Simple(0, function() if IsValid(ent) then forceCapitalShipReady(ent, teamKey) end end)
    timer.Simple(0.35, function() if IsValid(ent) then forceCapitalShipReady(ent, teamKey) end end)
    timer.Simple(1.0, function() if IsValid(ent) then forceCapitalShipReady(ent, teamKey) end end)
    ent:CallOnRemove("GRN_NavyCleanup", function(ship)
        GN.ManagedShips[ship] = nil
    end)
end

function GN:SpawnCapitalShip(ply, teamKey, shipID, pos)
    local def = self:GetCapitalDef(teamKey, shipID)
    if not def then return false, GRN_NAVY.T("err_capital_invalid") end
    if self:GetCapitalCount(teamKey, shipID) >= (def.max or 1) then
        return false, GRN_NAVY.T("err_capital_limit")
    end
    if not scripted_ents.GetStored(def.class) then
        return false, GRN_NAVY.T("err_capital_noent") .. def.class
    end

    local ang = Angle(0, ply:EyeAngles().y, 0)
    local ok, res = self:CreateHyperspaceEntity(pos, ang, def.class, ply, {
        ai = true,
        shake = true,
        sound = true,
        noSpawn = true,
        actualModel = self:ResolveEntityModel(def.class),
        pendingData = {
            type = "capital_spawn",
            teamKey = teamKey,
            def = def,
            owner = ply,
            pos = pos,
            ang = ang,
        }
    })
    if not ok then return false, res end
    return true, res
end

function GN:GetFighterCount(teamKey, id)
    local count = 0
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.GRN_NavySpawned and ent.GRN_NavyType == "fighter" and ent.GRN_NavyTeam == teamKey and ent.GRN_NavyDefID == id then
            count = count + 1
        end
    end
    return count
end

function GN:GetSupplyCount(teamKey, id)
    local count = 0
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.GRN_NavySpawned and ent.GRN_NavyTeam == teamKey and ent.GRN_NavyDefID == id then
            if ent.GRN_NavyType == "supply" or ent.GRN_NavyType == "supply_transport" then
                count = count + 1
            end
        end
    end
    return count
end

function GN:GetEscapePodCount(teamKey, id)
    local count = 0
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.GRN_NavySpawned and ent.GRN_NavyTeam == teamKey and ent.GRN_NavyDefID == id and ent.GRN_NavyType == "escape_pod" then
            count = count + 1
        end
    end
    return count
end

function GN:NormalizeWorldDropTarget(targetPos, filterEnt)
    if not isvector(targetPos) then return nil end
    local tr = util.TraceHull({
        start = targetPos + Vector(0,0,600),
        endpos = targetPos - Vector(0,0,12000),
        mins = Vector(-100,-100,0),
        maxs = Vector(100,100,120),
        mask = MASK_SOLID,
        filter = filterEnt,
    })
    if tr.Hit then
        return tr.HitPos + tr.HitNormal * 20
    end
    return targetPos
end

function GN:GetSeatCount(ent)
    if not IsValid(ent) then return 0 end
    local count = 0
    if ent.GetDriverSeat and IsValid(ent:GetDriverSeat()) then count = count + 1 end
    if ent.GetPassengerSeats then
        for _, pod in pairs(ent:GetPassengerSeats() or {}) do
            if IsValid(pod) then count = count + 1 end
        end
    end
    return count
end

function GN:GetFreeSeats(ent)
    local seats = {}
    if not IsValid(ent) then return seats end
    if ent.GetDriverSeat and IsValid(ent:GetDriverSeat()) and not IsValid(ent:GetDriverSeat():GetDriver()) then
        seats[#seats + 1] = ent:GetDriverSeat()
    end
    if ent.GetPassengerSeats then
        for _, pod in pairs(ent:GetPassengerSeats() or {}) do
            if IsValid(pod) and not IsValid(pod:GetDriver()) then
                seats[#seats + 1] = pod
            end
        end
    end
    return seats
end

function GN:PlacePlayerInSeat(ply, seat)
    if not IsValid(ply) or not IsValid(seat) then return false end
    ply:ExitVehicle()
    timer.Simple(0, function()
        if IsValid(ply) and IsValid(seat) then
            ply:EnterVehicle(seat)
        end
    end)
    return true
end


function GN:GetCapitalSpawnTransform(capitalEnt, offset, angOffset)
    if not IsValid(capitalEnt) then return nil, nil end
    local baseAng = capitalEnt:GetAngles()
    local pos = capitalEnt:LocalToWorld(offset or Vector(0, 0, -700))
    local ang = baseAng + (angOffset or angle_zero)
    return pos, ang
end

function GN:PlacePlayersInVehicle(ent, playerIDs)
    local pendingIDs = table.Copy(playerIDs or {})
    if #pendingIDs <= 0 then return 0 end

    local assigned = 0
    local tries = 0
    local tag = "GRN_NavySeatAssign_" .. ent:EntIndex() .. "_" .. math.floor(CurTime() * 1000)
    timer.Create(tag, 0.25, 20, function()
        if not IsValid(ent) then timer.Remove(tag) return end
        tries = tries + 1
        local seats = self:GetFreeSeats(ent)
        for i = #pendingIDs, 1, -1 do
            local uid = pendingIDs[i]
            local targ = Player(uid)
            if not IsValid(targ) then
                table.remove(pendingIDs, i)
            elseif #seats > 0 then
                local seat = table.remove(seats, 1)
                if self:PlacePlayerInSeat(targ, seat) then
                    assigned = assigned + 1
                    table.remove(pendingIDs, i)
                end
            end
        end
        if #pendingIDs <= 0 or tries >= 20 then
            ent.GRN_NavyAssignedPlayers = assigned
            timer.Remove(tag)
        end
    end)

    return assigned
end

function GN:BuildTransportConfig(teamKey, def)
    local base = table.Copy((C.TransportDefaults and C.TransportDefaults[teamKey]) or {})
    local over = istable(def.transport) and def.transport or {}
    for k, v in pairs(over) do base[k] = v end
    base.class = base.class or "grn_navy_transport"
    base.PayloadClass = def.class
    base.PayloadOffset = base.payloadOffset or vector_origin
    base.PayloadAngles = base.payloadAngles or angle_zero
    base.TransportAngles = base.transportAngles or angle_zero
    base.Model = base.model or "models/blu/laat.mdl"
    base.ModelScale = base.modelScale
    base.CruiseAltitude = base.cruiseAltitude or 2200
    base.LandingHeight = base.landingHeight or 120
    base.Speed = base.speed or 1600
    base.ExitSpeed = base.exitSpeed or 2000
    base.GroundTime = base.groundTime or 5
    base.Collision = base.collision == true
    base.HasHealth = base.hasHealth ~= false
    base.MaxHealth = base.maxHealth or 3000
    base.Sounds = {
        Arrival = base.arrivalSound or "",
        Flight = base.flightSound or "",
        Landing = base.landingSound or "",
        Hover = base.hoverSound or "",
        Takeoff = base.takeoffSound or "",
        Depart = base.departSound or "",
    }
    return base
end

function GN:SpawnFighterWithPlayers(ply, teamKey, fighterID, playerIDs, capitalEnt)
    local def = self:GetFighterDef(teamKey, fighterID)
    if not def then return false, GRN_NAVY.T("err_fighter_invalid") end
    if self:GetFighterCount(teamKey, fighterID) >= (def.max or 1) then
        return false, GRN_NAVY.T("err_fighter_limit")
    end
    if not scripted_ents.GetStored(def.class) then return false, GRN_NAVY.T("err_capital_noent") .. def.class end
    if not IsValid(capitalEnt) or not self.ManagedShips[capitalEnt] or self.ManagedShips[capitalEnt].team ~= teamKey then
        return false, GRN_NAVY.T("err_fighter_no_capital")
    end

    local spawnPos, spawnAng = self:GetCapitalSpawnTransform(
        capitalEnt,
        (C.RTS and C.RTS.FighterSpawnOffset) or Vector(0, 0, -700),
        (C.RTS and C.RTS.FighterFacingOffset) or Angle(0, 180, 0)
    )

    local ent = ents.Create(def.class)
    if not IsValid(ent) then return false, GRN_NAVY.T("err_fighter_spawn_fail") end
    ent:SetPos(spawnPos)
    ent:SetAngles(spawnAng)
    ent:Spawn()
    ent:Activate()
    ent.GRN_NavySpawned = true
    ent.GRN_NavyType = "fighter"
    ent.GRN_NavyTeam = teamKey
    ent.GRN_NavyDefID = fighterID
    ent:SetNWString("GRN_NavyTeam", teamKey)
    if ent.SetAI then ent:SetAI(false) end
    if ent.SetAITEAM then ent:SetAITEAM(C.Teams[teamKey].aiTeam or 0) end

    local assigned = self:PlacePlayersInVehicle(ent, playerIDs or {})
    return true, ent, assigned
end

function GN:SpawnSupply(ply, teamKey, supplyID, capitalEnt, targetPos)
    local def = self:GetSupplyDef(teamKey, supplyID)
    if not def then return false, GRN_NAVY.T("err_supply_invalid") end
    if self:GetSupplyCount(teamKey, supplyID) >= (def.max or 1) then return false, GRN_NAVY.T("err_supply_limit") end
    if not scripted_ents.GetStored(def.class) then return false, GRN_NAVY.T("err_capital_noent") .. def.class end

    if def.viaTransport ~= false then
        if not IsValid(capitalEnt) or not self.ManagedShips[capitalEnt] or self.ManagedShips[capitalEnt].team ~= teamKey then
            return false, GRN_NAVY.T("err_fighter_no_capital")
        end
        if not isvector(targetPos) then
            return false, GRN_NAVY.T("err_supply_no_target")
        end

        local transportCfg = self:BuildTransportConfig(teamKey, def)
        if not scripted_ents.GetStored(transportCfg.class) then
            return false, GRN_NAVY.T("err_supply_transport_missing") .. tostring(transportCfg.class)
        end

        targetPos = self:NormalizeWorldDropTarget(targetPos, capitalEnt) or targetPos
        local _, targetAng = self:GetCapitalSpawnTransform(
            capitalEnt,
            (C.RTS and C.RTS.SupplySpawnOffset) or Vector(0,0,-1000),
            (C.RTS and C.RTS.SupplyFacingOffset) or Angle(0,180,0)
        )

        local ent = ents.Create(transportCfg.class)
        if not IsValid(ent) then return false, GRN_NAVY.T("err_supply_transport_fail") end
        ent.TransportData = transportCfg
        ent.TargetPos = targetPos
        ent.ApproachDir = (targetPos - capitalEnt:GetPos())
        if ent.ApproachDir:LengthSqr() <= 0 then ent.ApproachDir = -capitalEnt:GetForward() end
        ent:SetPos(capitalEnt:LocalToWorld((C.RTS and C.RTS.SupplySpawnOffset) or Vector(0,0,-1000)) + Vector(0,0,transportCfg.CruiseAltitude or 2200))
        ent:SetAngles(targetAng)
        ent.GRN_NavyTeam = teamKey
        ent.GRN_NavyDefID = supplyID
        ent.GRN_NavySpawned = true
        ent.GRN_NavyType = "supply_transport"
        ent:Spawn()
        ent:Activate()
        return true, ent
    end

    targetPos = self:NormalizeWorldDropTarget(targetPos or ply:GetEyeTrace().HitPos, capitalEnt) or ply:GetEyeTrace().HitPos
    local ent = ents.Create(def.class)
    if not IsValid(ent) then return false, GRN_NAVY.T("err_supply_spawn_fail") end
    ent:SetPos(targetPos + Vector(0,0,25))
    ent:Spawn()
    ent:Activate()
    ent.GRN_NavySpawned = true
    ent.GRN_NavyType = "supply"
    ent.GRN_NavyTeam = teamKey
    ent.GRN_NavyDefID = supplyID
    ent:SetNWString("GRN_NavyTeam", teamKey)
    return true, ent
end

function GN:SpawnEscapePod(ply, teamKey, podID, playerIDs, capitalEnt, targetPos)
    local def = self:GetEscapePodDef(teamKey, podID)
    if not def then return false, GRN_NAVY.T("err_pod_invalid") end
    if self:GetEscapePodCount(teamKey, podID) >= (def.max or 1) then
        return false, GRN_NAVY.T("err_pod_limit")
    end
    if not scripted_ents.GetStored(def.class) then return false, GRN_NAVY.T("err_capital_noent") .. def.class end
    if not IsValid(capitalEnt) or not self.ManagedShips[capitalEnt] or self.ManagedShips[capitalEnt].team ~= teamKey then
        return false, GRN_NAVY.T("err_fighter_no_capital")
    end
    if not isvector(targetPos) then
        return false, GRN_NAVY.T("err_pod_no_target")
    end

    local maxPlayers = math.Clamp(tonumber(def.maxPlayers or 5) or 5, 1, 5)
    local unique = {}
    local finalIDs = {}
    for _, uid in ipairs(playerIDs or {}) do
        uid = tonumber(uid)
        if uid and not unique[uid] then
            unique[uid] = true
            finalIDs[#finalIDs + 1] = uid
            if #finalIDs >= maxPlayers then break end
        end
    end
    if #finalIDs <= 0 then
        return false, GRN_NAVY.T("err_pod_no_players")
    end

    targetPos = self:NormalizeWorldDropTarget(targetPos, capitalEnt) or targetPos
    local spawnPos, spawnAng = self:GetCapitalSpawnTransform(
        capitalEnt,
        (C.RTS and C.RTS.EscapePodSpawnOffset) or Vector(0,0,-500),
        (C.RTS and C.RTS.EscapePodFacingOffset) or Angle(0,180,0)
    )

    local ent = ents.Create(def.class)
    if not IsValid(ent) then return false, GRN_NAVY.T("err_pod_spawn_fail") end
    ent:SetPos(spawnPos)
    ent:SetAngles((targetPos - spawnPos):Angle())
    ent:Spawn()
    ent:Activate()
    ent.GRN_NavySpawned = true
    ent.GRN_NavyType = "escape_pod"
    ent.GRN_NavyTeam = teamKey
    ent.GRN_NavyDefID = podID
    ent:SetNWString("GRN_NavyTeam", teamKey)
    if ent.SetAI then ent:SetAI(false) end
    if ent.SetAITEAM then ent:SetAITEAM(C.Teams[teamKey].aiTeam or 0) end
    if ent.SetEngineActive then pcall(ent.SetEngineActive, ent, true) end

    local assigned = self:PlacePlayersInVehicle(ent, finalIDs)
    local speed = tonumber(def.speed or 2400) or 2400
    local landOffset = tonumber(def.landOffset or 70) or 70
    local tag = "GRN_NavyEscapePodMove_" .. ent:EntIndex()
    timer.Create(tag, 0.05, 0, function()
        if not IsValid(ent) then timer.Remove(tag) return end
        local pos = ent:GetPos()
        local dest = targetPos + Vector(0,0,landOffset)
        local toTarget = dest - pos
        local dist = toTarget:Length()
        if dist <= math.max(speed * 0.05, 140) then
            ent:SetPos(dest)
            ent:SetAngles(Angle(0, ent:GetAngles().y, 0))
            timer.Remove(tag)
            timer.Simple(1, function()
                if not IsValid(ent) then return end
                local seats = {}
                if ent.GetDriverSeat and IsValid(ent:GetDriverSeat()) then seats[#seats+1] = ent:GetDriverSeat() end
                if ent.GetPassengerSeats then
                    for _, seat in pairs(ent:GetPassengerSeats() or {}) do
                        if IsValid(seat) then seats[#seats+1] = seat end
                    end
                end
                for _, seat in ipairs(seats) do
                    local occ = seat:GetDriver()
                    if IsValid(occ) then
                        occ:ExitVehicle()
                        timer.Simple(0, function()
                            if IsValid(occ) then occ:SetPos(dest + Vector(math.random(-80,80), math.random(-80,80), 10)) end
                        end)
                    end
                end
            end)
            return
        end
        local dir = toTarget:GetNormalized()
        ent:SetPos(pos + dir * speed * 0.05)
        ent:SetAngles(LerpAngle(0.2, ent:GetAngles(), dir:Angle()))
    end)

    return true, ent, assigned
end

function GN:Bombard(ship, pos)
    if not IsValid(ship) then return false, GRN_NAVY.T("err_ship_invalid") end
    local meta = self.ManagedShips[ship]
    if not meta then return false, GRN_NAVY.T("err_ship_not_registered") end
    if not scripted_ents.GetStored("heart_turbolaser_spawner") then
        return false, GRN_NAVY.T("err_turbolaser_missing")
    end

    local owner = IsValid(meta.owner) and meta.owner or ship
    meta.targetPos = nil
    meta.curSpeed = 0
    meta.keepYaw = ship:GetAngles().y
    local phys = ship.GetPhysicsObject and ship:GetPhysicsObject() or nil
    if IsValid(phys) then
        phys:EnableMotion(false)
        if phys.SetVelocityInstantaneous then phys:SetVelocityInstantaneous(vector_origin) end
        if phys.GetAngleVelocity and phys.AddAngleVelocity then
            local angVel = phys:GetAngleVelocity()
            if isvector(angVel) and angVel:LengthSqr() > 0.0001 then
                phys:AddAngleVelocity(-angVel)
            end
        end
        phys:Wake()
    end
    ship:SetAngles(Angle(0, meta.keepYaw, 0))
    local salvoCount = 6
    for i = 1, salvoCount do
        timer.Simple((i - 1) * 0.22, function()
            if not IsValid(ship) then return end
            local strikePos = pos + Vector(math.Rand(-meta.def.bombRadius, meta.def.bombRadius), math.Rand(-meta.def.bombRadius, meta.def.bombRadius), 0)
            local startPos = strikePos + Vector(math.Rand(-900, 900), math.Rand(-900, 900), math.Rand(5000, 7200))
            local dir = (strikePos - startPos):GetNormalized()
            local spawner = ents.Create("heart_turbolaser_spawner")
            if not IsValid(spawner) then return end
            spawner:SetPos(startPos)
            spawner:SetAngles(dir:Angle())
            spawner:SetOwner(owner)
            spawner:SetVar("speed", 9000)
            spawner:SetVar("damage", 220)
            spawner:SetVar("radius", 300)
            spawner:SetVar("scale", 10)
            spawner:SetVar("r", meta.team == "cis" and 255 or 120)
            spawner:SetVar("g", meta.team == "cis" and 40 or 190)
            spawner:SetVar("b", meta.team == "cis" and 40 or 255)
            spawner:SetVar("delay", 0.08)
            spawner:SetVar("shots", 3)
            spawner:SetVar("spread", 2)
            spawner:Spawn()
            spawner:Activate()
            timer.Simple(1.2, function()
                if IsValid(spawner) then spawner:Remove() end
            end)
        end)
    end
    return true
end

function GN:GetManagedShipsForTeam(teamKey)
    local t = {}
    for ent, meta in pairs(self.ManagedShips) do
        if IsValid(ent) and meta.team == teamKey then
            t[#t + 1] = ent
        end
    end
    return t
end


hook.Add("GRN_Navy_HyperspaceFinished", "GRN_Navy_HyperspaceFinished", function(hyperEnt, spawnedEnt)
    if not IsValid(hyperEnt) then return end
    local pending = hyperEnt.GRN_NavyPendingData
    if not pending then return end

    if pending.type == "capital_spawn" then
        local finalEnt = spawnedEnt
        if not IsValid(finalEnt) then
            local okSpawn, res = GN:SpawnEntityProper(pending.def.class, pending.pos or hyperEnt:GetPos(), pending.ang or hyperEnt:GetAngles(), pending.owner)
            if okSpawn then
                finalEnt = res
            else
                if IsValid(pending.owner) then
                    pending.owner:ChatPrint(GRN_NAVY.T("chat_bombard_error") .. GRN_NAVY.T("err_capital_spawn_fail") .. tostring(res))
                end
            end
        end
        if IsValid(finalEnt) then
            GN:RegisterShip(finalEnt, pending.teamKey, pending.def, pending.owner)
        end
        GN:PushStateToRTS(pending.teamKey)
    elseif pending.type == "capital_retreat" then
        GN:PushStateToRTS(pending.teamKey)
    end
end)

function GN:BuildState(ply)
    local ok, teamKey = self:IsRTSAllowed(ply)
    local state = {
        allowed = ok,
        team = ok and teamKey or nil,
        jobs = self:GetJobs(),
        whitelist = self.Whitelist,
        players = {},
        capitals = C.CapitalShips[teamKey or "republic"] or {},
        fighters = C.Fighters[teamKey or "republic"] or {},
        supplies = (function()
            local out = {}
            for _, v in ipairs(C.Supplies[teamKey or "republic"] or {}) do
                local t = table.Copy(v)
                if t.nameKey then t.name = GRN_NAVY.T(t.nameKey) end
                out[#out+1] = t
            end
            return out
        end)(),
        escapePods = (function()
            local out = {}
            for _, v in ipairs(C.EscapePods[teamKey or "republic"] or {}) do
                local t = table.Copy(v)
                if t.nameKey then t.name = GRN_NAVY.T(t.nameKey) end
                out[#out+1] = t
            end
            return out
        end)(),
        ships = {},
    }
    for _, v in ipairs(player.GetAll()) do
        local pTeam = self:GetPlayerJobCommand(v)
        local wl = self.Whitelist[pTeam]
        state.players[#state.players + 1] = {
            id = v:UserID(),
            name = v:Nick(),
            steamid = v:SteamID(),
            alive = v:Alive(),
            teamName = team.GetName(v:Team()) or GRN_NAVY.T("no_team"),
            navyTeam = wl and wl.team or nil,
        }
    end
    for ent, meta in pairs(self.ManagedShips) do
        if IsValid(ent) and meta.team == teamKey then
            state.ships[#state.ships + 1] = {
                entIndex = ent:EntIndex(),
                name = ent:GetNWString("GRN_NavyName", ent.PrintName or meta.id),
                team = meta.team,
                health = ent.Health and ent:Health() or 0,
                maxHealth = (ent.GetMaxHP and ent:GetMaxHP()) or (ent.GetMaxHealth and ent:GetMaxHealth()) or 1,
                shield = ent.GetShield and ent:GetShield() or 0,
                maxShield = ent.GetMaxShield and ent:GetMaxShield() or 0,
                pos = ent:GetPos(),
            }
        end
    end
    return state
end

function GN:PushState(ply)
    net.Start(self.Net.PushState)
    net.WriteTable(self:BuildState(ply))
    net.Send(ply)
end

function GN:SetRTS(ply, enabled)
    self.ActiveRTS[ply] = self.ActiveRTS[ply] or {}
    self.ActiveRTS[ply].enabled = enabled
    self.ActiveRTS[ply].team = select(2, self:IsRTSAllowed(ply))
    net.Start(self.Net.ToggleRTS)
    net.WriteBool(enabled)
    net.Send(ply)
    if enabled then
        self:PushState(ply)
    end
end

hook.Add("Think", "GRN_Navy_MoveShips", function()
    local now = CurTime()
    for ent, meta in pairs(GN.ManagedShips) do
        if not IsValid(ent) then GN.ManagedShips[ent] = nil continue end

        -- Performance: stehende Schiffe nur 10x/s pflegen, Bereitschafts-Status 2x/s erzwingen
        -- (vorher jedes Schiff in jedem Tick). Fahrende Schiffe werden weiter jeden Tick bewegt.
        local moving = isvector(meta.targetPos)
        if not moving and (meta.nextIdleUpdate or 0) > now then continue end
        if not moving then meta.nextIdleUpdate = now + 0.1 end

        if (meta.nextReadyCheck or 0) <= now then
            meta.nextReadyCheck = now + 0.5
            forceCapitalShipReady(ent, meta.team)
        end

        local phys = ent.GetPhysicsObject and ent:GetPhysicsObject() or nil
        if IsValid(phys) then
            phys:EnableCollisions(true)
            phys:EnableMotion(false)
            -- FIX COLISION: masa alta necesaria para colision solida con Motion desactivado
            if phys:GetMass() < 50000 then
                phys:SetMass(50000)
            end
            if phys.SetVelocityInstantaneous then
                phys:SetVelocityInstantaneous(vector_origin)
            end
            if phys.GetAngleVelocity and phys.AddAngleVelocity then
                local angVel = phys:GetAngleVelocity()
                if isvector(angVel) and angVel:LengthSqr() > 0.0001 then
                    phys:AddAngleVelocity(-angVel)
                end
            end
            -- FIX COLISION 2: NO llamar Wake() cuando la nave esta quieta.
            -- Wake() + EnableMotion(false) en el mismo frame hace que el engine
            -- marque el objeto como dormido sin colisiones activas.
            if isvector(meta.targetPos) then
                phys:Wake()
            end
        end

        if not isvector(meta.targetPos) then
            meta.curSpeed = 0
            local keepYaw = meta.keepYaw or ent:GetAngles().y
            ent:SetAngles(Angle(0, keepYaw, 0))
            if IsValid(phys) and phys.SetAngles then
                phys:SetAngles(Angle(0, keepYaw, 0))
            end
            continue
        end

        local cur = ent:GetPos()
        local delta = meta.targetPos - cur
        local dist = delta:Length()
        if dist < 140 then
            -- FIX: Usar el keepYaw de navegacion, NO el angulo actual del entity
            -- (el angulo actual puede estar corrompido por la fisica en ese frame)
            local arrivalYaw = meta.keepYaw or ent:GetAngles().y
            meta.targetPos = nil
            meta.curSpeed = 0
            meta.keepYaw = arrivalYaw
            -- Forzar angulo limpio inmediatamente al llegar
            local arrivalAng = Angle(0, arrivalYaw, 0)
            ent:SetAngles(arrivalAng)
            local phys2 = ent.GetPhysicsObject and ent:GetPhysicsObject() or nil
            if IsValid(phys2) then
                if phys2.SetAngles then phys2:SetAngles(arrivalAng) end
                if phys2.SetAngleVelocity then phys2:SetAngleVelocity(Vector(0,0,0)) end
                if phys2.AddAngleVelocity then
                    local av = phys2:GetAngleVelocity()
                    if isvector(av) and av:LengthSqr() > 0.0001 then
                        phys2:AddAngleVelocity(-av)
                    end
                end
                phys2:Wake()
            end
            continue
        end

        local desiredYaw = delta:Angle().y
        local curYaw = meta.keepYaw or ent:GetAngles().y
        local turnRate = tonumber(meta.turnRate) or tonumber((C.RTS and C.RTS.ShipTurnRate) or 10)

        -- FIX GIRO 180: math.ApproachAngle puede tomar el camino largo entre angulos opuestos.
        -- Calculamos el delta normalizado para siempre girar por el lado corto.
        local rawDelta = (desiredYaw - curYaw) % 360
        if rawDelta > 180 then rawDelta = rawDelta - 360 end
        local maxStep = turnRate * FrameTime() * 60
        local yaw = curYaw + math.Clamp(rawDelta, -maxStep, maxStep)
        meta.keepYaw = yaw

        local moveAng = Angle(0, yaw, 0)
        local forward = moveAng:Forward()
        local dir = delta:GetNormalized()
        local alignment = math.Clamp(forward:Dot(dir), 0.1, 1)

        meta.curSpeed = meta.curSpeed or 0
        local maxSpeed = math.max(tonumber(meta.speed) or 600, 100)
        local brakeDist = math.max(maxSpeed * 1.75, 1200)
        local slowFactor = math.Clamp(dist / brakeDist, 0.18, 1)
        local desiredSpeed = maxSpeed * slowFactor * alignment
        local accel = (tonumber(meta.accel) or tonumber((C.RTS and C.RTS.ShipAcceleration) or 120)) * FrameTime() * 60
        meta.curSpeed = math.Approach(meta.curSpeed, desiredSpeed, accel)

        local step = math.min(meta.curSpeed * FrameTime(), dist)
        local newPos = cur + forward * step
        newPos.z = cur.z + math.Clamp(meta.targetPos.z - cur.z, -step * 0.18, step * 0.18)

        if IsValid(phys) then
            if phys.SetPos then phys:SetPos(newPos) end
            if phys.SetAngles then phys:SetAngles(moveAng) end
            if phys.SetVelocityInstantaneous then phys:SetVelocityInstantaneous(vector_origin) end
            if phys.GetAngleVelocity and phys.AddAngleVelocity then
                local angVel = phys:GetAngleVelocity()
                if isvector(angVel) and angVel:LengthSqr() > 0.0001 then
                    phys:AddAngleVelocity(-angVel)
                end
            end
            phys:Wake()
        end

        ent:SetPos(newPos)
        ent:SetAngles(moveAng)
    end
end)

local function findCommand(msg, set)
    msg = string.Trim(string.lower(msg or ""))
    for _, cmd in ipairs(set) do
        if msg == string.lower(cmd) then return true end
    end
    return false
end

hook.Add("PlayerSay", "GRN_Navy_Commands", function(ply, text)
    if findCommand(text, C.Commands.Navy) then
        local ok = GN:IsRTSAllowed(ply)
        if not ok then
            ply:ChatPrint(GRN_NAVY.T("chat_job_disabled"))
            return ""
        end
        GN:SetRTS(ply, not (GN.ActiveRTS[ply] and GN.ActiveRTS[ply].enabled))
        return ""
    elseif findCommand(text, C.Commands.Whitelist) then
        if not GN:IsStaff(ply) then
            ply:ChatPrint(GRN_NAVY.T("chat_no_whitelist_access"))
            return ""
        end
        net.Start(GN.Net.OpenWhitelist)
        net.WriteTable({ jobs = GN:GetJobs(), whitelist = GN.Whitelist })
        net.Send(ply)
        return ""
    end
end)

net.Receive(GN.Net.RequestState, function(_, ply)
    GN:PushState(ply)
end)

net.Receive(GN.Net.ToggleRTS, function(_, ply)
    local enabled = net.ReadBool()
    local ok = GN:IsRTSAllowed(ply)
    if enabled and not ok then
        ply:ChatPrint(GRN_NAVY.T("chat_job_disabled"))
        return
    end
    GN:SetRTS(ply, enabled)
end)

net.Receive(GN.Net.SubmitWhitelist, function(_, ply)
    if not GN:IsStaff(ply) then return end
    local rows = net.ReadTable() or {}
    local new = {}
    for _, row in ipairs(rows) do
        if row.jobcmd and (row.team == "republic" or row.team == "cis") then
            new[row.jobcmd] = {
                team = row.team,
                enabled = row.enabled ~= false,
            }
        end
    end
    GN.Whitelist = new
    GN:SaveWhitelist()
    GN:PushState(ply)
    ply:ChatPrint(GRN_NAVY.T("chat_whitelist_saved"))
end)

net.Receive(GN.Net.Action, function(_, ply)
    local action = net.ReadString()
    local data = net.ReadTable() or {}
    local ok, teamKey = GN:IsRTSAllowed(ply)
    if not ok then return end

    if action == "spawn_capital" then
        local pos = data.pos
        if not isvector(pos) then pos = ply:GetPos() + ply:GetForward() * 1500 + Vector(0,0,1200) end
        local success, res = GN:SpawnCapitalShip(ply, teamKey, data.shipID, pos)
        if not success then
            ply:ChatPrint("[GRN Navy] " .. tostring(res))
        else
            ply:ChatPrint(GRN_NAVY.T("chat_capital_jumping"))
        end
        GN:PushState(ply)
    elseif action == "spawn_fighter" then
        local cap = Entity(tonumber(data.capitalEnt or 0))
        local success, ent, assigned = GN:SpawnFighterWithPlayers(ply, teamKey, data.fighterID, data.playerIDs or {}, cap)
        if not success then ply:ChatPrint(GRN_NAVY.T("chat_bombard_error") .. tostring(ent)) else ply:ChatPrint(GRN_NAVY.T("chat_fighter_deployed") .. tostring(assigned or 0)) end
        GN:PushState(ply)
    elseif action == "spawn_supply" then
        local cap = Entity(tonumber(data.capitalEnt or 0))
        local success, res = GN:SpawnSupply(ply, teamKey, data.supplyID, cap, data.targetPos)
        if not success then ply:ChatPrint("[GRN Navy] " .. tostring(res)) else ply:ChatPrint(GRN_NAVY.T("chat_supply_deployed")) end
        GN:PushState(ply)
    elseif action == "spawn_escape_pod" then
        local cap = Entity(tonumber(data.capitalEnt or 0))
        local success, ent, assigned = GN:SpawnEscapePod(ply, teamKey, data.podID, data.playerIDs or {}, cap, data.targetPos)
        if not success then ply:ChatPrint(GRN_NAVY.T("chat_bombard_error") .. tostring(ent)) else ply:ChatPrint(GRN_NAVY.T("chat_pod_deployed") .. tostring(assigned or 0)) end
        GN:PushState(ply)
    elseif action == "remove_ship" then
        local ent = Entity(tonumber(data.entIndex or 0))
        local meta = GN.ManagedShips[ent]
        if IsValid(ent) and meta and meta.team == teamKey then
            local entPos, entAng = ent:GetPos(), ent:GetAngles()
            local owner = IsValid(meta.owner) and meta.owner or ply
            local retreatModel = GN:ResolveEntityModel(meta.def.class, ent)
            GN.ManagedShips[ent] = nil
            ent:Remove()
            local okFx, fxRes = GN:CreateHyperspaceEntity(entPos, entAng, meta.def.class, owner, {
                ai = false,
                shake = true,
                sound = true,
                retreat = true,
                noSpawn = true,
                actualModel = retreatModel,
                pendingData = {
                    type = "capital_retreat",
                    teamKey = teamKey,
                    def = meta.def,
                    owner = owner,
                }
            })
            if okFx then
                ply:ChatPrint(GRN_NAVY.T("chat_ship_withdrawn_fx"))
            else
                ply:ChatPrint(GRN_NAVY.T("chat_ship_withdrawn_nofx") .. tostring(fxRes))
            end
            GN:PushState(ply)
        end
    end
end)

net.Receive(GN.Net.OrderMove, function(_, ply)
    local ok, teamKey = GN:IsRTSAllowed(ply)
    if not ok then return end
    local ent = Entity(net.ReadUInt(16))
    local pos = net.ReadVector()
    if not GN:IsCapitalShip(ent) then return end
    local meta = GN.ManagedShips[ent]
    if not meta or meta.team ~= teamKey then return end
    forceCapitalShipReady(ent, teamKey)
    meta.targetPos = Vector(pos.x, pos.y, math.max(pos.z, 250))
    meta.keepYaw = ent:GetAngles().y
end)

net.Receive(GN.Net.Bombard, function(_, ply)
    local ok, teamKey = GN:IsRTSAllowed(ply)
    if not ok then return end
    local ent = Entity(net.ReadUInt(16))
    local pos = net.ReadVector()
    if not GN:IsCapitalShip(ent) then return end
    local meta = GN.ManagedShips[ent]
    if not meta or meta.team ~= teamKey then return end
    local dist = ent:GetPos():Distance(pos)
    if dist > (meta.def.bombRange or 12000) then
        ply:ChatPrint(GRN_NAVY.T("chat_bombard_too_far"))
        return
    end
    local success, err = GN:Bombard(ent, pos)
    if not success then
        ply:ChatPrint(GRN_NAVY.T("chat_bombard_error") .. tostring(err or GRN_NAVY.T("err_bombard_generic")))
        return
    end
    ply:ChatPrint(GRN_NAVY.T("chat_bombard_started"))
end)



function GN:TriggerCapitalDestruction(ent, attacker)
    if not IsValid(ent) or ent.GRN_NavyDestroying then return false end
    local meta = self.ManagedShips[ent]
    if not meta then return false end
    if not scripted_ents.GetStored("vanilla_shipdestruction") then return false end

    ent.GRN_NavyDestroying = true
    local cfg = C.Destruction or {}
    local fx = ents.Create("vanilla_shipdestruction")
    if not IsValid(fx) then return false end
    fx:SetPos(ent:GetPos())
    fx:SetAngles(ent:GetAngles())
    fx:SetModel(ent:GetModel() or "")
    fx.vLength = tonumber(cfg.Length or 12) or 12
    fx.ExplosionSize = tonumber(cfg.ExplosionSize or 4) or 4
    fx.FinalSize = tonumber(cfg.FinalSize or 12) or 12
    fx.Flip = tonumber(cfg.Flip or 0) or 0
    fx.TurnRate = tonumber(cfg.TurnRate or 2.2) or 2.2
    fx.FallRate = tonumber(cfg.FallRate or 38) or 38
    fx.ForwardRate = tonumber(cfg.ForwardRate or 32) or 32
    fx:Spawn()
    fx:Activate()

    self.ManagedShips[ent] = nil
    ent:Remove()
    self:PushStateToRTS(meta.team)
    return true
end

hook.Add("EntityTakeDamage", "GRN_Navy_CapitalDestruction", function(ent, dmg)
    if not GRN_NAVY or not GRN_NAVY.Config or not GRN_NAVY.Config.Destruction or not GRN_NAVY.Config.Destruction.Enabled then return end
    if not GRN_NAVY:IsCapitalShip(ent) or ent.GRN_NavyDestroying then return end
    local hp = ent.Health and ent:Health() or 0
    local threshold = tonumber((GRN_NAVY.Config.Destruction or {}).TriggerHealth or 1) or 1
    if (hp - dmg:GetDamage()) > threshold then return end
    timer.Simple(0, function()
        if IsValid(ent) then
            GRN_NAVY:TriggerCapitalDestruction(ent, dmg:GetAttacker())
        end
    end)
end)
hook.Add("PlayerDisconnected", "GRN_Navy_Disconnect", function(ply)
    GN.ActiveRTS[ply] = nil
end)

hook.Add("PlayerInitialSpawn", "GRN_Navy_InitialInfo", function(ply)
    timer.Simple(5, function()
        if IsValid(ply) then
            ply:ChatPrint(GRN_NAVY.T("chat_welcome"))
        end
    end)
end)

GN:LoadPersistence()
