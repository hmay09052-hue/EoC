local WS = GRNSerials
local C = WS.Config
local DB = WS.DB
local ST = WS.STATUS

util.AddNetworkString("ws_announce")
util.AddNetworkString("ws_hud")
util.AddNetworkString("ws_killfeed")
util.AddNetworkString("ws_jam")
util.AddNetworkString("ws_clean")

WS.Registry = WS.Registry or {}   -- serial -> Datensatz (im Speicher)
WS.Dirty = WS.Dirty or {}         -- serial -> true (noch nicht gespeichert)
WS.Entities = WS.Entities or {}   -- serial -> SWEP-Entity

local function now() return os.time() end
local function sid(ply) return IsValid(ply) and ply:IsPlayer() and ply:SteamID64() or nil end

-- ---------------------------------------------------------
-- Datensätze
-- ---------------------------------------------------------
function WS.Get(serial)
    if not isstring(serial) or serial == "" then return nil end
    local rec = WS.Registry[serial]
    if rec then return rec end
    rec = DB.LoadWeapon(serial)
    if rec then WS.Registry[serial] = rec end
    return rec
end

function WS.MarkDirty(rec)
    if rec then WS.Dirty[rec.serial] = true end
end

function WS.SaveNow(rec)
    if not rec then return end
    DB.SaveWeapon(rec)
    WS.Dirty[rec.serial] = nil
end

-- Gebündelt in einer Transaktion: nur geänderte Datensätze.
function WS.Flush()
    if not next(WS.Dirty) then return end
    sql.Begin()
    for serial in pairs(WS.Dirty) do
        local rec = WS.Registry[serial]
        if rec then DB.SaveWeapon(rec) end
    end
    sql.Commit()
    WS.Dirty = {}
end

local LIMITS = {
    kill = function() return C.History.KillDetail end,
    death = function() return C.History.DeathDetail end,
    repair = function() return C.History.ServiceDetail end,
    clean = function() return C.History.ServiceDetail end,
    barrel = function() return C.History.ServiceDetail end,
}

function WS.Event(serial, typ, actor, target, data)
    DB.AddEvent(serial, typ, actor, target, data)
    local limit = LIMITS[typ]
    if limit and math.random(1, 10) == 1 then DB.TrimEvents(serial, typ, limit()) end
end

function WS.Chronicle(regiment, serial, text)
    DB.Query("INSERT INTO ws_regiment_chronicle (regiment_id, serial, text, ts) VALUES (?, ?, ?, ?)", regiment or "", serial, text, now())
end

function WS.DisplayName(rec)
    if not rec then return "" end
    if rec.is_tradition and rec.honor_name and rec.honor_name ~= "" then return rec.honor_name end
    if rec.nickname and rec.nickname ~= "" then return rec.nickname end
    local stored = weapons.GetStored(rec.class)
    return stored and stored.PrintName or rec.class
end

function WS.WeaponLabel(rec)
    local stored = weapons.GetStored(rec.class)
    return (stored and stored.PrintName) or rec.class
end

-- Neue Waffe mit unveränderlicher Seriennummer.
function WS.Create(class, regiment, batch)
    local n = DB.NextCounter()
    local year = os.date("%y")
    local body = string.format("%06d", n % 1000000)
    local serial = string.format("%s-%s-%s-%d", WS.PrefixForClass(class), year, body, WS.Luhn(year .. body))
    local stored = weapons.GetStored(class)
    local rec = {
        serial = serial, class = class, base = (stored and stored.ArcCW) and "arccw" or (stored and stored.Base) or "",
        created_at = now(), condition = 100, dirt = 0, rounds_fired = 0,
        regiment_id = regiment, status = ST.STORED, nick_changed_at = 0, is_tradition = false,
        kills_total = 0, holders = 0, longest_kill = 0, locked = false, batch = batch,
        captured_once = false, barrel_rounds = 0, last_transfer = 0, status_since = now(),
    }
    DB.InsertWeapon(rec)
    WS.Registry[serial] = rec
    WS.Event(serial, "created", nil, nil, { class = class, regiment = regiment, batch = batch })
    return rec
end

function WS.SetStatus(rec, status)
    if rec.status ~= status then
        rec.status = status
        rec.status_since = now()
    end
    WS.MarkDirty(rec)
end

-- ---------------------------------------------------------
-- Netzvariablen am SWEP
-- ---------------------------------------------------------
function WS.SyncEntity(rec)
    local wep = WS.Entities[rec.serial]
    if not IsValid(wep) then return end
    wep:SetNW2String("ws_serial", rec.serial)
    wep:SetNW2Float("ws_cond", math.Round(rec.condition, 2))
    wep:SetNW2Float("ws_dirt", math.Round(rec.dirt, 2))
    wep:SetNW2String("ws_name", (rec.is_tradition and rec.honor_name) or rec.nickname or "")
    wep:SetNW2Bool("ws_tradition", rec.is_tradition == true)
    wep:SetNW2Bool("ws_locked", rec.locked == true)
end

local function bindEntity(rec, wep)
    local old = WS.Entities[rec.serial]
    if IsValid(old) and old ~= wep then
        -- Eine Nummer existiert nur einmal: das ältere Entity verliert sie.
        old:SetNW2String("ws_serial", "")
    end
    WS.Entities[rec.serial] = wep
    WS.SyncEntity(rec)
end

local function unbindEntity(rec)
    local wep = WS.Entities[rec.serial]
    if IsValid(wep) and wep:GetNW2String("ws_serial", "") == rec.serial then
        wep:SetNW2String("ws_serial", "")
    end
    WS.Entities[rec.serial] = nil
end

function WS.FindOwnerItem(ply, serial)
    local state = GRNInventory and GRNInventory.GetState and GRNInventory.GetState(ply)
    if not state then return nil end
    for _, item in ipairs(state.items or {}) do
        if item.serial == serial then return item end
    end
end

local function hudNotice(ply, kind, text)
    if not IsValid(ply) then return end
    net.Start("ws_hud")
        net.WriteString(kind or "info")
        net.WriteString(text or "")
    net.Send(ply)
end
WS.HUDNotice = hudNotice

function WS.Announce(text, regiment, kind)
    local targets = {}
    for _, p in ipairs(player.GetAll()) do
        if not regiment or WS.GetRegiment(p) == regiment then targets[#targets + 1] = p end
    end
    if #targets == 0 then return end
    net.Start("ws_announce")
        net.WriteString(kind or "info")
        net.WriteString(text)
    net.Send(targets)
end

-- ---------------------------------------------------------
-- Besitzerkette
-- ---------------------------------------------------------
local function startHolding(rec, ply, how)
    DB.Query("INSERT INTO ws_holders (serial, holder_sid64, holder_name, from_ts, kills, ended) VALUES (?, ?, ?, ?, 0, NULL)",
        rec.serial, sid(ply), ply:Nick(), now())
    rec.holders = (rec.holders or 0) + 1
    rec.owner_sid64, rec.owner_name = sid(ply), ply:Nick()
    rec.last_transfer = now()
    WS.Event(rec.serial, "owner", sid(ply), nil, { name = ply:Nick(), how = how })
end

local function endHolding(rec, ended)
    DB.Query("UPDATE ws_holders SET to_ts = ?, ended = ? WHERE serial = ? AND to_ts IS NULL", now(), ended, rec.serial)
end

local function addHolderKill(rec)
    DB.Query("UPDATE ws_holders SET kills = kills + 1 WHERE serial = ? AND to_ts IS NULL", rec.serial)
end

-- ---------------------------------------------------------
-- Ausgabe: konkrete Waffe einem Inventar-Gegenstand zuteilen
-- ---------------------------------------------------------
local function poolCandidate(ply, class, regiment)
    local sid64 = sid(ply)

    -- 1) gezielt am Terminal gewählt
    local wanted = ply.WSWantedSerial
    ply.WSWantedSerial = nil
    if istable(wanted) and wanted.class == class then
        local rec = WS.Get(wanted.serial)
        if rec and rec.status == ST.STORED and not rec.locked and rec.condition > 0 then return rec end
    end

    -- 2) "meine" Waffe: die zuletzt getragene dieser Klasse, falls eingelagert
    local last = DB.Row([[SELECT w.serial FROM ws_holders h JOIN ws_weapons w ON w.serial = h.serial
        WHERE h.holder_sid64 = ? AND w.class = ? AND w.status = 'STORED' AND w.is_tradition = 0 AND w.locked = 0 AND w.condition > 0
        ORDER BY h.from_ts DESC LIMIT 1]], sid64, class)
    if last then return WS.Get(last.serial) end

    -- 3) beste Waffe dieser Klasse aus der Regimentskammer
    local row = DB.Row([[SELECT serial FROM ws_weapons WHERE class = ? AND status = 'STORED' AND is_tradition = 0
        AND locked = 0 AND condition > 0 AND (regiment_id = ? OR (? IS NULL AND regiment_id IS NULL))
        ORDER BY condition DESC, created_at ASC LIMIT 1]], class, regiment, regiment)
    if row then return WS.Get(row.serial) end
end

function WS.AssignItem(ply, item, def, how)
    if not C.Enabled or not IsValid(ply) or not item or not def then return nil end
    local class = def.WeaponClass
    if def.Type ~= "weapon" or not WS.ClassTracked(class) then return nil end

    -- Bereits zugeteilt und gültig: behalten.
    if item.serial then
        local rec = WS.Get(item.serial)
        if rec and rec.class == class and rec.owner_sid64 == sid(ply)
                and (rec.status == ST.ISSUED or rec.status == ST.DROPPED) then
            if rec.status == ST.DROPPED then WS.SetStatus(rec, ST.ISSUED) end
            return rec
        end
        item.serial = nil -- veraltet / doppelt -> neue Zuteilung
    end

    local regiment = WS.GetRegiment(ply)
    local rec = poolCandidate(ply, class, regiment) or WS.Create(class, regiment)

    item.serial = rec.serial
    rec.item_id = item.id
    WS.SetStatus(rec, ST.ISSUED)
    if not rec.regiment_id and regiment then rec.regiment_id = regiment end
    startHolding(rec, ply, how or "Ausgabe")
    WS.Event(rec.serial, "issue", sid(ply), nil, { name = ply:Nick(), regiment = regiment })
    WS.SaveNow(rec)
    if GRNInventory and GRNInventory.SavePlayer then GRNInventory.SavePlayer(ply) end
    return rec
end

-- Zurück in die Kammer (Rückgabe, Tod, Neustart ...).
function WS.Store(rec, ended, actor, eventType)
    if not rec then return end
    endHolding(rec, ended)
    unbindEntity(rec)
    if rec.status == ST.CAPTURED and rec.captured_once then
        WS.GrantMilestone(rec, "homecoming", nil)
    end
    rec.owner_sid64, rec.owner_name = nil, nil
    WS.SetStatus(rec, rec.condition <= 0 and ST.BROKEN or ST.STORED)
    WS.Event(rec.serial, eventType or "return", sid(actor), nil, { reason = ended })
    WS.SaveNow(rec)
end

local REMOVE_TEXT = {
    ["return"] = "zurückgegeben",
    death = "gefallen",
    restart = "Serverneustart",
    character = "Charakterwechsel",
    drop = "abgelegt",
    removed = "entfernt",
}

hook.Add("GRNArmory_ItemIssued", "GRNSerials_Issue", function(ply, itemID, def)
    local state = GRNInventory.GetState(ply)
    for _, item in ipairs(state and state.items or {}) do
        if item.id == itemID and not item.serial then
            WS.AssignItem(ply, item, def, "Ausgabe")
            return
        end
    end
end)

hook.Add("GRNInventory_WeaponGiven", "GRNSerials_Bind", function(ply, item, weapon, def)
    local rec = WS.AssignItem(ply, item, def, "Ausgabe")
    if rec then bindEntity(rec, weapon) end
end)

hook.Add("GRNInventory_ItemRemoved", "GRNSerials_Removed", function(ply, item, def, reason)
    if not item.serial then return end
    local rec = WS.Get(item.serial)
    if not rec or rec.owner_sid64 ~= sid(ply) then return end
    if rec.status ~= ST.ISSUED and rec.status ~= ST.DROPPED then return end

    reason = reason or "removed"
    if reason == "drop" then
        local ent = GRNInventory.RemoveDropEntity
        endHolding(rec, "abgelegt")
        unbindEntity(rec)
        WS.SetStatus(rec, ST.DROPPED)
        WS.Event(rec.serial, "dropped", sid(ply), nil, { name = ply:Nick() })
        WS.SaveNow(rec)
        if IsValid(ent) then
            ent.GRNSerial = rec.serial
            ent:SetNW2String("ws_serial", rec.serial)
        end
        return
    end

    if reason == "death" then
        WS.Store(rec, REMOVE_TEXT.death, nil, "auto_return")
        return
    end
    WS.Store(rec, REMOVE_TEXT[reason] or reason, reason == "return" and ply or nil, reason == "return" and "return" or "auto_return")
end)

-- Aufheben einer abgelegten Waffe: Besitzerwechsel mit Grund.
hook.Add("GRNInventory_PickedUp", "GRNSerials_PickedUp", function(ply, ent, itemID)
    local serial = ent.GRNSerial
    local rec = serial and WS.Get(serial)
    if not rec or rec.status ~= ST.DROPPED then return end
    local state = GRNInventory.GetState(ply)
    for i = #(state and state.items or {}), 1, -1 do
        local item = state.items[i]
        if item.id == itemID and not item.serial then
            item.serial = rec.serial
            rec.item_id = item.id
            WS.SetStatus(rec, ST.ISSUED)
            startHolding(rec, ply, "aufgehoben")
            WS.SaveNow(rec)
            return
        end
    end
end)

hook.Add("EntityRemoved", "GRNSerials_DropRemoved", function(ent)
    local serial = ent.GRNSerial
    if not serial then return end
    -- Nicht aufgehoben (Lebensdauer abgelaufen): zurück in die Kammer.
    timer.Simple(0, function()
        local rec = WS.Get(serial)
        if rec and rec.status == ST.DROPPED then WS.Store(rec, "vom Boden geborgen", nil, "auto_return") end
    end)
end)

-- Nicht mehr im Inventar referenzierte Ausgaben beim Start zurückholen.
local function restartSweep()
    local restartRemoves = not (GRNInventory and GRNInventory.Config and GRNInventory.Config.Respawn
        and GRNInventory.Config.Respawn.RemoveWeaponsOnServerRestart == false)
    if not restartRemoves then return end
    for _, row in ipairs(DB.Rows("SELECT serial FROM ws_weapons WHERE status IN ('ISSUED', 'DROPPED')")) do
        local rec = WS.Get(row.serial)
        if rec then WS.Store(rec, REMOVE_TEXT.restart, nil, "auto_return") end
    end
end

-- ---------------------------------------------------------
-- Tod des Trägers / Bergung
-- ---------------------------------------------------------
local function equippedSerials(ply)
    local out = {}
    local state = GRNInventory and GRNInventory.GetState and GRNInventory.GetState(ply)
    if not state then return out end
    for _, item in ipairs(state.items or {}) do
        if item.serial then
            local rec = WS.Get(item.serial)
            if rec and rec.owner_sid64 == sid(ply) then out[#out + 1] = rec end
        end
    end
    return out
end
WS.CarriedRecords = equippedSerials

hook.Add("PlayerDeath", "GRNSerials_CarrierDeath", function(victim, inflictor, attacker)
    local pos = victim:GetPos()
    for _, rec in ipairs(equippedSerials(victim)) do
        if rec.status == ST.ISSUED then
            WS.SetStatus(rec, ST.DROPPED)
            WS.Event(rec.serial, "death", sid(victim), sid(attacker), {
                name = victim:Nick(),
                killer = IsValid(attacker) and (attacker:IsPlayer() and attacker:Nick() or attacker:GetClass()) or "Unbekannt",
                map = game.GetMap(),
                pos = string.format("%d %d %d", pos.x, pos.y, pos.z),
            })
        end
    end
end)

hook.Add("GRNInventory_DeathResolved", "GRNSerials_Recovered", function(ply, revived)
    if not revived then return end
    for _, rec in ipairs(equippedSerials(ply)) do
        if rec.status == ST.DROPPED then
            WS.SetStatus(rec, ST.ISSUED)
            WS.Event(rec.serial, "recovered", sid(ply), nil, { name = ply:Nick() })
        end
    end
end)

-- ---------------------------------------------------------
-- Schießen: nur im Speicher zählen
-- ---------------------------------------------------------
hook.Add("Hook_PostFireBullets", "GRNSerials_Fire", function(wep)
    if not IsValid(wep) then return end
    local serial = wep:GetNW2String("ws_serial", "")
    if serial == "" then return end
    local rec = WS.Registry[serial]
    if not rec then return end

    local W = C.Wear
    rec.rounds_fired = rec.rounds_fired + 1
    rec.barrel_rounds = (rec.barrel_rounds or 0) + 1
    rec.dirt = math.min(100, rec.dirt + W.DirtPerShot)
    local loss = W.ConditionPerShot * (rec.dirt >= W.DirtyThreshold and W.DirtyMultiplier or 1)
    local before = rec.condition
    rec.condition = math.max(0, rec.condition - loss)
    WS.MarkDirty(rec)

    if rec.rounds_fired % 10 == 0 or rec.condition <= 0 then
        wep:SetNW2Float("ws_cond", math.Round(rec.condition, 2))
        wep:SetNW2Float("ws_dirt", math.Round(rec.dirt, 2))
    end

    local owner = wep:GetOwner()
    if before > 0 and rec.condition <= 0 then
        wep:SetNW2Float("ws_cond", 0)
        WS.Event(rec.serial, "broken", sid(owner), nil, { rounds = rec.rounds_fired })
        hudNotice(owner, "critical", "Waffe blockiert – zur Werkbank bringen.")
    elseif before >= 25 and rec.condition < 25 then
        hudNotice(owner, "warn", "Kritischer Zustand – Ladehemmungen häufen sich.")
    end

    -- Ladehemmung
    local tier = WS.TierFor(rec.condition)
    local every = tonumber(tier.JamEvery) or 0
    if every > 0 and wep.SetMalfunctionJam then
        local chance = 1 / every
        if rec.dirt >= W.DirtyThreshold then chance = chance * W.DirtyMultiplier end
        if math.random() < chance then
            wep:SetMalfunctionJam(true)
            if IsValid(owner) and owner:IsPlayer() then
                net.Start("ws_jam") net.WriteEntity(wep) net.Send(owner)
            end
        end
    end

    if rec.rounds_fired % 50 == 0 then WS.CheckMilestones(rec, owner) end
end)

-- Wasser / Schlamm und "am Boden"
local MUD = { [MAT_SLOSH] = true }
timer.Create("GRNSerials_Environment", 2, 0, function()
    if not C.Enabled then return end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local wep = ply:GetActiveWeapon()
            local rec = IsValid(wep) and WS.Registry[wep:GetNW2String("ws_serial", "")]
            if rec then
                local wet = ply:WaterLevel() >= 2
                if not wet and ply:OnGround() and ply:GetVelocity():Length2DSqr() > 100 then
                    local tr = util.TraceLine({ start = ply:GetPos() + Vector(0, 0, 4), endpos = ply:GetPos() - Vector(0, 0, 16), filter = ply })
                    wet = tr.Hit and MUD[tr.MatType] == true
                end
                if wet and (ply.WSLastMud or 0) + 30 < CurTime() then
                    ply.WSLastMud = CurTime()
                    rec.dirt = math.min(100, rec.dirt + C.Wear.DirtWaterMud)
                    WS.MarkDirty(rec)
                    WS.SyncEntity(rec)
                end
            end
        else
            for _, rec in ipairs(equippedSerials(ply)) do
                if rec.status == ST.DROPPED then
                    rec.dirt = math.min(100, rec.dirt + C.Wear.DirtPerMinuteDown / 30)
                    WS.MarkDirty(rec)
                end
            end
        end

        -- Bewegung für die Anti-Farm-Regel merken
        local pos = ply:GetPos()
        if not ply.WSLastPos or ply.WSLastPos:DistToSqr(pos) > 64 * 64 or ply:EyeAngles() ~= ply.WSLastAng then
            ply.WSLastMove = CurTime()
        end
        ply.WSLastPos, ply.WSLastAng = pos, ply:EyeAngles()
    end
end)

-- ---------------------------------------------------------
-- Kills mit Anti-Farm-Regeln
-- ---------------------------------------------------------
local function killAllowed(attacker, victim)
    local A = C.AntiFarm
    if victim:IsPlayer() then
        if (CurTime() - (victim.WSLastMove or CurTime())) > A.IdleSeconds then return false, "idle" end
        local key = victim:SteamID64()
        attacker.WSVictims = attacker.WSVictims or {}
        local list = attacker.WSVictims[key] or {}
        local t = now()
        for i = #list, 1, -1 do if t - list[i] > 3600 then table.remove(list, i) end end
        if #list >= A.SameVictimPerHour then return false, "farm" end
        list[#list + 1] = t
        attacker.WSVictims[key] = list
    end
    return true
end

local function victimName(v)
    if v:IsPlayer() then return v:Nick() end
    local name = list.Get("NPC")[v:GetClass()]
    return (name and name.Name) or v:GetClass()
end

local function onKill(victim, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or not IsValid(victim) or attacker == victim then return end
    local wep = attacker:GetActiveWeapon()
    if not IsValid(wep) then return end
    local rec = WS.Registry[wep:GetNW2String("ws_serial", "")]
    if not rec then return end

    if victim:IsNPC() or victim:IsNextBot() then
        if not C.AntiFarm.CountNPCKills then return end
    end

    local vf, af = WS.GetFaction(victim), WS.GetFaction(attacker)
    if vf == af then
        if victim:IsPlayer() then
            WS.Event(rec.serial, "teamkill", sid(attacker), sid(victim), { name = attacker:Nick(), victim = victim:Nick(), map = game.GetMap() })
        end
        return
    end

    local ok = killAllowed(attacker, victim)
    if not ok then return end

    local dist = attacker:GetPos():Distance(victim:GetPos()) / (C.UnitsPerMeter or 52.49)
    rec.kills_total = rec.kills_total + 1
    WS.MarkDirty(rec)
    addHolderKill(rec)
    WS.Event(rec.serial, "kill", sid(attacker), victim:IsPlayer() and sid(victim) or nil, {
        name = attacker:Nick(), victim = victimName(victim), faction = vf, dist = math.Round(dist), map = game.GetMap(),
    })

    if dist > (rec.longest_kill or 0) then
        rec.longest_kill = math.Round(dist, 1)
        local ms = WS.MilestoneDef("longshot")
        if ms and dist >= ms.Value then
            WS.Chronicle(rec.regiment_id, rec.serial, string.format("%s trifft mit %s (%s) auf %d m.", attacker:Nick(), WS.DisplayName(rec), rec.serial, math.Round(dist)))
        end
    end
    WS.CheckMilestones(rec, attacker)

    -- Killfeed mit Ehren- bzw. Spitzname
    local shown = rec.is_tradition and rec.honor_name or nil
    if not shown and rec.nickname and rec.nickname ~= "" then
        local def = WS.MilestoneDef("survivor")
        if def and WS.HasMilestone(rec, def.ID) then
            shown = rec.nickname
        end
    end
    if shown then
        net.Start("ws_killfeed")
            net.WriteString(attacker:Nick())
            net.WriteString(victimName(victim))
            net.WriteString(shown)
            net.WriteBool(rec.is_tradition == true)
        net.Broadcast()
    end
end

hook.Add("PlayerDeath", "GRNSerials_Kill", function(victim, inflictor, attacker) onKill(victim, attacker) end)
hook.Add("OnNPCKilled", "GRNSerials_KillNPC", function(npc, attacker) onKill(npc, attacker) end)

-- ---------------------------------------------------------
-- Meilensteine
-- ---------------------------------------------------------
function WS.MilestoneDef(id)
    for _, m in ipairs(C.Milestones or {}) do
        if m.ID == id or m.Type == id then return m end
    end
end

-- Erreichte Meilensteine pro Waffe im Speicher, damit Kills nicht jedes
-- Mal die Datenbank fragen.
function WS.HasMilestone(rec, id)
    if not rec._ms then
        rec._ms = {}
        for _, row in ipairs(DB.Rows("SELECT milestone FROM ws_milestones WHERE serial = ?", rec.serial)) do rec._ms[row.milestone] = true end
    end
    return rec._ms[id] == true
end

function WS.GrantMilestone(rec, id, holder)
    local def = WS.MilestoneDef(id)
    if not def then return end
    if WS.HasMilestone(rec, def.ID) then return end
    rec._ms[def.ID] = true
    DB.Query("INSERT INTO ws_milestones (serial, milestone, holder_sid64, holder_name, ts) VALUES (?, ?, ?, ?, ?)",
        rec.serial, def.ID, sid(holder), IsValid(holder) and holder:Nick() or nil, now())
    WS.Event(rec.serial, "milestone", sid(holder), nil, { id = def.ID, name = def.Name })
    local text = string.format("%s (%s): Meilenstein „%s“%s", WS.DisplayName(rec), rec.serial, def.Name,
        IsValid(holder) and (" – getragen von " .. holder:Nick()) or "")
    WS.Chronicle(rec.regiment_id, rec.serial, text)
    if IsValid(holder) then hudNotice(holder, "milestone", "Meilenstein: " .. def.Name) end
    if rec.regiment_id then WS.Announce(text, rec.regiment_id, "milestone") end
end

function WS.CheckMilestones(rec, holder)
    for _, m in ipairs(C.Milestones or {}) do
        if not WS.HasMilestone(rec, m.ID) then
            local reached = false
            if m.Type == "kills" then reached = rec.kills_total >= m.Value
            elseif m.Type == "rounds" then reached = rec.rounds_fired >= m.Value
            elseif m.Type == "longshot" then reached = (rec.longest_kill or 0) >= m.Value
            elseif m.Type == "holders" then
                reached = (tonumber(DB.Value("SELECT COUNT(*) FROM ws_holders WHERE serial = ? AND ended = 'gefallen'", rec.serial)) or 0) >= m.Value
            end
            if reached then WS.GrantMilestone(rec, m.ID, holder) end
        end
    end
end

function WS.MilestoneCount(serial)
    return tonumber(DB.Value("SELECT COUNT(*) FROM ws_milestones WHERE serial = ?", serial)) or 0
end

-- ---------------------------------------------------------
-- Reinigung (Reinigungsset aus dem Inventar)
-- ---------------------------------------------------------
function WS.StartCleaning(ply)
    local wep = ply:GetActiveWeapon()
    local rec = IsValid(wep) and WS.Registry[wep:GetNW2String("ws_serial", "")]
    if not rec then
        hudNotice(ply, "warn", "Nimm eine Waffe mit Seriennummer in die Hand.")
        return false
    end
    if ply.WSCleaning then return false end
    ply.WSCleaning = { serial = rec.serial, wep = wep, done = CurTime() + C.CleaningTime }
    if wep.PlayAnimation and wep.SelectAnimation then
        pcall(function() wep:PlayAnimation(wep:SelectAnimation("enter_inspect") or "idle", 1, true) end)
    end
    net.Start("ws_clean") net.WriteFloat(C.CleaningTime) net.Send(ply)
    local tname = "GRNSerials_Clean_" .. ply:EntIndex()
    timer.Create(tname, 0.25, 0, function()
        local job = IsValid(ply) and ply.WSCleaning
        if not job then timer.Remove(tname) return end
        if not ply:Alive() or ply:GetActiveWeapon() ~= job.wep or ply:KeyDown(IN_ATTACK) then
            ply.WSCleaning = nil
            timer.Remove(tname)
            net.Start("ws_clean") net.WriteFloat(0) net.Send(ply)
            hudNotice(ply, "warn", "Reinigung abgebrochen.")
            if GRNInventory and GRNInventory.AddItem then GRNInventory.AddItem(ply, C.CleaningKitItem, 1) end
            return
        end
        if CurTime() >= job.done then
            ply.WSCleaning = nil
            timer.Remove(tname)
            local r = WS.Get(job.serial)
            if r then
                local before = r.dirt
                r.dirt = 0
                WS.Event(r.serial, "clean", sid(ply), nil, { name = ply:Nick(), before = math.Round(before, 1), after = 0 })
                WS.SaveNow(r)
                WS.SyncEntity(r)
            end
            hudNotice(ply, "ok", "Waffe gereinigt.")
        end
    end)
    return true
end

-- ---------------------------------------------------------
-- Werkbank: Reparatur und Laufwechsel (Waffenmeister)
-- ---------------------------------------------------------
local function takeParts(ply, amount)
    if amount <= 0 then return true end
    if not (GRNInventory and GRNInventory.HasItem(ply, C.SparePartsItem, amount)) then return false end
    GRNInventory.RemoveItem(ply, C.SparePartsItem, amount)
    if GRNInventory.Sync then GRNInventory.Sync(ply) end
    return true
end

function WS.RepairCost(rec)
    return math.ceil((100 - rec.condition) / 25) * (C.RepairPartsPer25 or 1)
end

function WS.Repair(armorer, rec)
    if not WS.IsArmorer(armorer) then return false, "Nur der Waffenmeister kann reparieren." end
    if rec.status == ST.RETIRED then return false, "Ausgemusterte Waffen werden nicht repariert." end
    if rec.condition >= 100 then return false, "Die Waffe ist bereits in einwandfreiem Zustand." end
    local cost = WS.RepairCost(rec)
    if not takeParts(armorer, cost) then return false, "Nicht genug Ersatzteile (" .. cost .. " benötigt)." end
    local before = rec.condition
    rec.condition = 100
    if rec.status == ST.BROKEN then WS.SetStatus(rec, ST.STORED) end
    WS.Event(rec.serial, "repair", sid(armorer), nil, { name = armorer:Nick(), before = math.Round(before, 1), after = 100, parts = cost })
    WS.SaveNow(rec)
    WS.SyncEntity(rec)
    return true, string.format("%s repariert (%d Ersatzteile).", rec.serial, cost)
end

function WS.CanBarrelChange(rec)
    local class = string.lower(rec.class or "")
    for _, p in ipairs(C.BarrelChangeClasses or {}) do
        if string.find(class, p, 1, true) then return true end
    end
    return false
end

function WS.BarrelChange(armorer, rec)
    if not WS.IsArmorer(armorer) then return false, "Nur der Waffenmeister kann den Lauf wechseln." end
    if not WS.CanBarrelChange(rec) then return false, "Diese Waffe hat keinen Wechsellauf." end
    if not takeParts(armorer, C.BarrelChangeParts or 2) then return false, "Nicht genug Ersatzteile." end
    local rounds = rec.barrel_rounds or 0
    rec.barrel_rounds = 0
    rec.condition = math.min(100, rec.condition + 15)
    WS.Event(rec.serial, "barrel", sid(armorer), nil, { name = armorer:Nick(), rounds = rounds })
    WS.SaveNow(rec)
    WS.SyncEntity(rec)
    return true, "Lauf gewechselt (" .. rounds .. " Schuss auf dem alten Lauf)."
end

function WS.Retire(actor, rec)
    if not (WS.IsArmorer(actor) or WS.IsAdmin(actor)) then return false, "Keine Berechtigung." end
    if rec.status == ST.ISSUED or rec.status == ST.DROPPED then return false, "Die Waffe muss erst zurückgegeben werden." end
    WS.SetStatus(rec, ST.RETIRED)
    WS.Event(rec.serial, "retired", sid(actor), nil, { name = actor:Nick() })
    WS.Chronicle(rec.regiment_id, rec.serial, string.format("%s (%s) wurde ausgemustert. %d Kills, %d Schuss.",
        WS.DisplayName(rec), rec.serial, rec.kills_total, rec.rounds_fired))
    WS.SaveNow(rec)
    return true, rec.serial .. " ausgemustert. Die Akte bleibt im Archiv."
end

-- ---------------------------------------------------------
-- Spitzname
-- ---------------------------------------------------------
function WS.SetNickname(ply, rec, nick)
    if rec.owner_sid64 ~= sid(ply) then return false, "Nur der aktuelle Träger darf den Spitznamen ändern." end
    if rec.is_tradition then return false, "Traditionswaffen tragen einen festen Ehrennamen." end
    local N = C.Nickname
    if now() - (rec.nick_changed_at or 0) < N.Cooldown then
        return false, "Der Spitzname kann erst später wieder geändert werden."
    end
    nick = string.Trim(tostring(nick or ""))
    nick = string.gsub(nick, "[%c<>\"]", "")
    if utf8.len(nick) and utf8.len(nick) > N.MaxLength then return false, "Höchstens " .. N.MaxLength .. " Zeichen." end
    local lower = string.lower(nick)
    for _, w in ipairs(N.BlockedWords or {}) do
        if string.find(lower, w, 1, true) then return false, "Dieser Name ist nicht erlaubt." end
    end
    rec.nickname = nick ~= "" and nick or nil
    rec.nick_changed_at = now()
    WS.Event(rec.serial, "nickname", sid(ply), nil, { name = ply:Nick(), nickname = rec.nickname })
    WS.SaveNow(rec)
    WS.SyncEntity(rec)
    return true, rec.nickname and ("Spitzname gesetzt: " .. rec.nickname) or "Spitzname entfernt."
end

-- ---------------------------------------------------------
-- Traditionswaffen
-- ---------------------------------------------------------
local function regimentTraditionCount(regiment)
    return tonumber(DB.Value("SELECT COUNT(*) FROM ws_weapons WHERE regiment_id = ? AND is_tradition = 1 AND status != 'RETIRED'", regiment)) or 0
end

function WS.CanPropose(ply)
    return WS.IsAdmin(ply) or WS.HasRank(ply, C.TraditionProposeRank)
end

function WS.CanConfirm(ply)
    return (C.TraditionAdminGroups or {})[IsValid(ply) and ply:GetUserGroup() or ""] or WS.HasRank(ply, C.TraditionConfirmRank)
end

function WS.Propose(ply, rec, honor)
    local T = C.Tradition
    local regiment = WS.GetRegiment(ply)
    if not WS.CanPropose(ply) then return false, "Erst ab Rang " .. string.upper(C.TraditionProposeRank) .. "." end
    if not WS.IsAdmin(ply) and rec.regiment_id ~= regiment then return false, "Die Waffe gehört nicht deinem Regiment." end
    if rec.is_tradition then return false, "Bereits Traditionswaffe." end
    if rec.status == ST.RETIRED then return false, "Ausgemustert." end
    if (now() - rec.created_at) < T.MinAgeDays * 86400 then return false, "Mindestens " .. T.MinAgeDays .. " Tage alt." end
    if WS.MilestoneCount(rec.serial) < T.MinMilestones then return false, "Mindestens ein Meilenstein nötig." end
    if rec.condition <= T.MinCondition then return false, "Zustand muss über " .. T.MinCondition .. " % liegen." end
    if regimentTraditionCount(rec.regiment_id) >= T.MaxPerRegiment then return false, "Das Regiment hat bereits " .. T.MaxPerRegiment .. " Traditionswaffen." end
    honor = string.Trim(string.gsub(tostring(honor or ""), "[%c<>\"]", ""))
    if honor == "" or (utf8.len(honor) or 99) > C.Nickname.MaxLength then return false, "Ehrenname fehlt oder ist zu lang." end
    DB.Query("INSERT OR REPLACE INTO ws_tradition_proposals (serial, regiment_id, proposer_sid64, proposer_name, honor_name, ts) VALUES (?, ?, ?, ?, ?, ?)",
        rec.serial, rec.regiment_id, sid(ply), ply:Nick(), honor, now())
    WS.Event(rec.serial, "tradition_proposed", sid(ply), nil, { name = ply:Nick(), honor = honor })
    return true, "Vorschlag eingereicht: " .. honor
end

function WS.Confirm(ply, rec, accept)
    if not WS.CanConfirm(ply) then return false, "Nur die Regimentsführung kann bestätigen." end
    local prop = DB.Row("SELECT * FROM ws_tradition_proposals WHERE serial = ?", rec.serial)
    if not prop then return false, "Kein offener Vorschlag." end
    if not WS.IsAdmin(ply) and prop.regiment_id ~= WS.GetRegiment(ply) then return false, "Anderes Regiment." end
    DB.Query("DELETE FROM ws_tradition_proposals WHERE serial = ?", rec.serial)
    if not accept then
        WS.Event(rec.serial, "tradition_rejected", sid(ply), nil, { name = ply:Nick() })
        return true, "Vorschlag abgelehnt."
    end
    if regimentTraditionCount(rec.regiment_id) >= C.Tradition.MaxPerRegiment then return false, "Höchstzahl erreicht." end
    rec.is_tradition = true
    rec.honor_name = prop.honor_name
    WS.Event(rec.serial, "tradition", sid(ply), nil, { name = ply:Nick(), honor = prop.honor_name })
    WS.SaveNow(rec)
    WS.SyncEntity(rec)
    local text = string.format("%s (%s) wird Traditionswaffe des Regiments %s: „%s“.", WS.WeaponLabel(rec), rec.serial, WS.RegimentName(rec.regiment_id), rec.honor_name)
    WS.Chronicle(rec.regiment_id, rec.serial, text)
    WS.Announce(text, C.Tradition.AnnounceServerWide and nil or rec.regiment_id, "tradition")
    return true, "Traditionswaffe ernannt."
end

local function itemIDForClass(rec)
    if rec.item_id and GRNInventory.GetItemDefinition(rec.item_id) then return rec.item_id end
    local guess = "eoc_job_" .. rec.class
    if GRNInventory.GetItemDefinition(guess) then return guess end
    for id, def in pairs(GRNInventory.Config.Items or {}) do
        if istable(def) and def.Type == "weapon" and def.WeaponClass == rec.class then return id end
    end
end

-- Übergabe-Zeremonie: Offizier übergibt die Waffe an einen neuen Träger.
function WS.Ceremony(officer, rec, target)
    if not rec.is_tradition then return false, "Nur Traditionswaffen werden feierlich übergeben." end
    if not WS.CanPropose(officer) then return false, "Erst ab Rang " .. string.upper(C.TraditionProposeRank) .. "." end
    if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return false, "Kein gültiger neuer Träger." end
    if not WS.IsAdmin(officer) and WS.GetRegiment(target) ~= rec.regiment_id then return false, "Der neue Träger gehört nicht zum Regiment." end
    local radius = (C.Tradition.CeremonyRadius or 3) * (C.UnitsPerMeter or 52.49)
    if target:GetPos():DistToSqr(officer:GetPos()) > radius * radius then return false, "Der neue Träger muss im Umkreis von " .. C.Tradition.CeremonyRadius .. " m stehen." end

    local oldHolder
    if rec.status == ST.ISSUED then
        oldHolder = player.GetBySteamID64(rec.owner_sid64 or "")
        if not IsValid(oldHolder) then return false, "Der bisherige Träger ist nicht anwesend." end
        if oldHolder == target then return false, "Der Träger hat die Waffe bereits." end
        if oldHolder:GetPos():DistToSqr(officer:GetPos()) > radius * radius then return false, "Der bisherige Träger muss im Umkreis von " .. C.Tradition.CeremonyRadius .. " m stehen." end
    elseif rec.status ~= ST.STORED then
        return false, "Die Waffe ist nicht verfügbar (" .. (WS.StatusLabels[rec.status] or rec.status) .. ")."
    end

    local itemID = itemIDForClass(rec)
    if not itemID then return false, "Kein Inventar-Gegenstand für diese Waffenklasse." end
    if GRNInventory.HasItem(target, itemID, 1) then return false, "Der neue Träger hat diese Waffenart schon im Inventar." end

    if IsValid(oldHolder) then
        local item = WS.FindOwnerItem(oldHolder, rec.serial)
        if item then GRNInventory.RemoveItemUID(oldHolder, item.uid, "return") end
        if GRNInventory.Sync then GRNInventory.Sync(oldHolder) end
    end

    target.WSWantedSerial = { serial = rec.serial, class = rec.class }
    local added = GRNInventory.AddItem(target, itemID, 1)
    if tonumber(added) ~= 1 then
        target.WSWantedSerial = nil
        return false, "Kein Platz im Inventar des neuen Trägers."
    end
    local state = GRNInventory.GetState(target)
    for _, item in ipairs(state.items) do
        if item.id == itemID and not item.serial then
            WS.AssignItem(target, item, GRNInventory.GetItemDefinition(itemID), "Zeremonie")
            break
        end
    end
    target.GRNArmoryIssuedItems = target.GRNArmoryIssuedItems or {}
    target.GRNArmoryIssuedItems[itemID] = (tonumber(target.GRNArmoryIssuedItems[itemID]) or 0) + 1
    if GRNInventory.Sync then GRNInventory.Sync(target) end

    local text = string.format("„%s“ (%s, %s) geht an %s.", rec.honor_name or WS.DisplayName(rec), WS.WeaponLabel(rec), rec.serial, target:Nick())
    WS.Event(rec.serial, "ceremony", sid(officer), sid(target), { officer = officer:Nick(), from = IsValid(oldHolder) and oldHolder:Nick() or "Vitrine", to = target:Nick() })
    WS.Chronicle(rec.regiment_id, rec.serial, text)
    WS.Announce(text, C.Tradition.AnnounceServerWide and nil or rec.regiment_id, "tradition")
    return true, "Übergabe abgeschlossen."
end

-- Traditionswaffen nur über die Zeremonie ausgeben (der Pool überspringt sie
-- ohnehin); nach Ablauf automatisch zurück in die Vitrine.
timer.Create("GRNSerials_TraditionReturn", 30, 0, function()
    local secs = tonumber(C.Tradition.AutoReturnSeconds) or 0
    if secs <= 0 then return end
    for _, row in ipairs(DB.Rows("SELECT serial FROM ws_weapons WHERE is_tradition = 1 AND status = 'ISSUED' AND status_since < ?", now() - secs)) do
        local rec = WS.Get(row.serial)
        local holder = rec and player.GetBySteamID64(rec.owner_sid64 or "")
        if IsValid(holder) then
            local item = WS.FindOwnerItem(holder, rec.serial)
            if item then
                GRNInventory.RemoveItemUID(holder, item.uid, "return")
                if GRNInventory.Sync then GRNInventory.Sync(holder) end
                hudNotice(holder, "info", "„" .. (rec.honor_name or rec.serial) .. "“ ist zurück in der Vitrine.")
            end
        elseif rec then
            WS.Store(rec, "zurück in die Vitrine", nil, "auto_return")
        end
    end
end)

-- ---------------------------------------------------------
-- Admin
-- ---------------------------------------------------------
function WS.AdminEdit(admin, rec, fields)
    if not WS.IsAdmin(admin) then return false, "Keine Berechtigung." end
    local changes = {}
    if fields.condition then rec.condition = math.Clamp(tonumber(fields.condition) or rec.condition, 0, 100) changes.condition = rec.condition end
    if fields.dirt then rec.dirt = math.Clamp(tonumber(fields.dirt) or rec.dirt, 0, 100) changes.dirt = rec.dirt end
    if fields.nickname ~= nil then rec.nickname = fields.nickname ~= "" and string.sub(tostring(fields.nickname), 1, 48) or nil changes.nickname = rec.nickname end
    if fields.honor_name ~= nil and rec.is_tradition then rec.honor_name = tostring(fields.honor_name) changes.honor = rec.honor_name end
    if fields.locked ~= nil then rec.locked = fields.locked == true changes.locked = rec.locked end
    if fields.tradition == false and rec.is_tradition then rec.is_tradition = false changes.tradition = false end
    if fields.status and WS.STATUS[fields.status] then
        if fields.status == ST.CAPTURED then rec.captured_once = true end
        if rec.status == ST.CAPTURED and fields.status == ST.STORED then
            WS.GrantMilestone(rec, "homecoming", nil)
        end
        if (rec.status == ST.ISSUED or rec.status == ST.DROPPED) and fields.status ~= rec.status then
            local holder = player.GetBySteamID64(rec.owner_sid64 or "")
            local item = IsValid(holder) and WS.FindOwnerItem(holder, rec.serial)
            if item then
                item.serial = nil -- Spieler behält den Gegenstand ohne diese Nummer
                if GRNInventory.SavePlayer then GRNInventory.SavePlayer(holder) end
            end
            endHolding(rec, "Admin")
            unbindEntity(rec)
            rec.owner_sid64, rec.owner_name = nil, nil
        end
        WS.SetStatus(rec, fields.status)
        changes.status = fields.status
    end
    if fields.reset then
        rec.condition, rec.dirt, rec.locked = 100, 0, false
        changes.reset = true
    end
    WS.Event(rec.serial, "admin", sid(admin), nil, { name = admin:Nick(), changes = changes })
    WS.SaveNow(rec)
    WS.SyncEntity(rec)
    return true, "Gespeichert."
end

-- Rollback eines Spielers auf einen Zeitpunkt (z. B. nach einem Exploit):
-- entfernt seine Kills und Meilensteine danach und korrigiert die Summen.
function WS.Rollback(admin, sid64, ts)
    if not WS.IsAdmin(admin) then return false, "Keine Berechtigung." end
    ts = tonumber(ts) or now()
    WS.Flush()
    local count = 0
    for _, row in ipairs(DB.Rows("SELECT serial, COUNT(*) AS n FROM ws_events WHERE actor_sid64 = ? AND type = 'kill' AND ts >= ? GROUP BY serial", sid64, ts)) do
        local rec = WS.Get(row.serial)
        local n = tonumber(row.n) or 0
        if rec then
            rec.kills_total = math.max(0, rec.kills_total - n)
            DB.Query("UPDATE ws_holders SET kills = MAX(0, kills - ?) WHERE serial = ? AND holder_sid64 = ? AND (to_ts IS NULL OR to_ts >= ?)", n, rec.serial, sid64, ts)
            WS.Event(rec.serial, "admin", sid(admin), sid64, { name = admin:Nick(), rollback = n, since = ts })
            WS.SaveNow(rec)
            count = count + n
        end
    end
    DB.Query("DELETE FROM ws_events WHERE actor_sid64 = ? AND type = 'kill' AND ts >= ?", sid64, ts)
    DB.Query("DELETE FROM ws_milestones WHERE holder_sid64 = ? AND ts >= ?", sid64, ts)
    for _, rec in pairs(WS.Registry) do rec._ms = nil end
    return true, count .. " Kill(s) zurückgesetzt."
end

-- ---------------------------------------------------------
-- Speichern & Aufräumen
-- ---------------------------------------------------------
timer.Create("GRNSerials_Save", C.History.SaveInterval or 60, 0, WS.Flush)
hook.Add("ShutDown", "GRNSerials_Save", WS.Flush)
hook.Add("PlayerDisconnected", "GRNSerials_Save", function(ply)
    for _, rec in ipairs(equippedSerials(ply)) do WS.MarkDirty(rec) end
    timer.Simple(0, WS.Flush)
end)

local lastCleanup = ""
timer.Create("GRNSerials_Cleanup", 600, 0, function()
    local day = os.date("%Y-%m-%d")
    if lastCleanup == day or tonumber(os.date("%H")) ~= (C.History.CleanupHour or 4) then return end
    lastCleanup = day
    WS.Flush()
    for typ, limit in pairs(LIMITS) do
        for _, row in ipairs(DB.Rows("SELECT DISTINCT serial FROM ws_events WHERE type = ?", typ)) do
            DB.TrimEvents(row.serial, typ, limit())
        end
    end
    -- Speicher frei machen: nur Waffen im Einsatz bleiben im Registry.
    for serial, rec in pairs(WS.Registry) do
        if rec.status ~= ST.ISSUED and rec.status ~= ST.DROPPED and not WS.Dirty[serial] then WS.Registry[serial] = nil end
    end
end)

hook.Add("Initialize", "GRNSerials_Init", function()
    DB.Init()
    restartSweep()
end)
if GAMEMODE then DB.Init() end
