-- Feldbasen: Gründung, Bau, Strom, Verbrauch, Reparaturaufträge, SSE-Anbindung

local cfg = GARLog.Config

GARLog.FOBs    = GARLog.FOBs or {}
GARLog.FOBEnts = GARLog.FOBEnts or {}   -- Entity -> FOB-ID (schneller Lookup)
GARLog.FOB     = GARLog.FOB or {}

local FOB = GARLog.FOB
local FOBs, FOBEnts = GARLog.FOBs, GARLog.FOBEnts
FOB.RepairByEnt = FOB.RepairByEnt or {}

---------------------------------------------------------------------------
-- Abfragen
---------------------------------------------------------------------------
function FOB.Get(id) return FOBs[id] end

function FOB.OfEnt(ent)
    local id = FOBEnts[ent]
    return id and FOBs[id]
end

-- Feldbasis, in deren Radius die Position liegt (nächstes Zentrum gewinnt)
function FOB.At(pos)
    local best, bestD
    for _, f in pairs(FOBs) do
        local d = pos:DistToSqr(f.pos)
        if d <= f.radius * f.radius and (not bestD or d < bestD) then best, bestD = f, d end
    end
    return best
end

-- Erste einsatzbereite Struktur eines Typs (optional im Umkreis)
function FOB.FindOperational(f, key, pos, range)
    if not f then return end
    local r2 = range and range * range
    for ent, k in pairs(f.ents) do
        if k == key and IsValid(ent) and ent.GARLogStructure and ent:IsOperational()
            and (not pos or ent:GetPos():DistToSqr(pos) <= r2) then
            return ent
        end
    end
end

function FOB.PlayersIn(f)
    local list = {}
    for _, p in ipairs(player.GetHumans()) do
        if p.GARLogInFOB == f.id then list[#list + 1] = p end
    end
    return list
end

-- Ausfälle & Baustatus der Feldbasis: nur an anwesende Spieler aus cfg.FOBAlertRoles
local function NotifyFOB(f, text, kind)
    GARLog.NotifyInFOB(f.id, text, kind, cfg.FOBAlertRoles)
end
FOB.NotifyFOB = NotifyFOB

-- Kompakte Liste aller Feldbasen für alle Clients (HUD, Bau-Vorschau) – nur bei Änderungen
function FOB.PublishList()
    local parts = {}
    for id, f in SortedPairs(FOBs) do
        parts[#parts + 1] = string.format("%d|%d|%d|%d|%d|%d|%d|%s", id, math.Round(f.pos.x), math.Round(f.pos.y), math.Round(f.pos.z),
            f.radius, f.powered and 1 or 0, f.antenna and 1 or 0, (f.name:gsub("[|;]", "")))
    end
    SetGlobal2String("GARLog_FOBs", table.concat(parts, ";"))
end

---------------------------------------------------------------------------
-- Anlegen / Auflösen
---------------------------------------------------------------------------
function FOB.RecalcCounts(f)
    local c = {}
    for ent, key in pairs(f.ents) do
        if IsValid(ent) then c[key] = (c[key] or 0) + 1 end
    end
    f.counts = c
end

function FOB.RecalcCapacity(f)
    local loc = GARLog.GetLoc(f.locId)
    if not loc then return end
    local n = 0
    for ent, key in pairs(f.ents) do
        if key == "s:storage" and IsValid(ent) and ent.GARLogStructure and not ent:GetDestroyed() then n = n + 1 end
    end
    f.storages = n
    local per = cfg.Structures.storage.capacity or {}
    for _, res in ipairs(GARLog.ResOrder) do
        loc.cap[res] = (cfg.FOB.BaseCapacity[res] or 0) + n * (per[res] or 0)
    end
    local lost = GARLog.ClampStock(f.locId)
    if next(lost) and not GARLog.ShuttingDown then
        GARLog.Log(f.name .. ": Lagerkapazität gesunken – Vorräte verloren: " .. GARLog.ItemsText(lost), "err")
        NotifyFOB(f, f.name .. ": Versorgungslager ausgefallen – Vorräte verloren!", "err")
    end
    GARLog.MarkDirty("loc")
end

function FOB.Create(name, pos, founder)
    local id = GARLog.NextId("nextFob")
    local f = {
        id = id, locId = "fob_" .. id, name = name, pos = pos, radius = cfg.FOB.Radius,
        ents = {}, counts = {}, storages = 0, powered = false, antenna = false, present = 0,
        created = os.time(), founder = founder,
    }
    FOBs[id] = f
    local loc = GARLog.CreateLocation(f.locId, name, "FOB", "fob", false)
    loc.fob = id
    FOB.RecalcCapacity(f)
    GARLog.Log(string.format("Feldbasis '%s' gegründet von %s.", name, founder), "ok")
    FOB.PublishList()
    hook.Run("GARLog_FOBCreated", f)
    return f
end

function FOB.Dissolve(f, reason)
    if f.dissolving then return end
    f.dissolving = true

    local list = {}
    for ent in pairs(f.ents) do list[#list + 1] = ent end
    for _, ent in ipairs(list) do
        if IsValid(ent) then
            ent.GARLogDissolve = true
            ent:Remove()
        end
    end
    for ent, id in pairs(FOBEnts) do
        if id == f.id then FOBEnts[ent] = nil end
    end

    FOBs[f.id] = nil
    GARLog.RemoveLocation(f.locId, "Feldbasis aufgelöst")
    for _, p in ipairs(player.GetAll()) do
        if p.GARLogInFOB == f.id then p.GARLogInFOB = nil end
    end
    if not GARLog.ShuttingDown then
        GARLog.Log(string.format("Feldbasis '%s' aufgelöst (%s).", f.name, reason or "—"), "warn")
        FOB.PublishList()
    end
    hook.Run("GARLog_FOBRemoved", f)
    GARLog.MarkDirty("loc")
end

function FOB.Register(ent, f, def)
    f.ents[ent] = def.key
    FOBEnts[ent] = f.id
    ent.GARLogFOB = f.id
    ent.GARLogKey = def.key
    ent:SetNW2Int("GARLogFOB", f.id)
    ent:SetNW2String("GARLogKey", def.key)
    if ent.SetFOBName then ent:SetFOBName(f.name) end
    FOB.RecalcCounts(f)
    if def.key == "s:storage" then FOB.RecalcCapacity(f) end
    GARLog.MarkDirty("loc")
end

function FOB.Unregister(ent)
    local id = FOBEnts[ent]
    FOBEnts[ent] = nil
    local f = id and FOBs[id]
    if not f then return end
    local key = f.ents[ent]
    f.ents[ent] = nil

    local o = FOB.RepairByEnt[ent]
    if o then
        FOB.RepairByEnt[ent] = nil
        if not GARLog.ShuttingDown then GARLog.CloseRepair(o, GARLog.REP_CANCELLED) end
    end

    if f.dissolving or GARLog.ShuttingDown then return end
    FOB.RecalcCounts(f)
    if key == "s:storage" and not ent.GARLogReplaced then FOB.RecalcCapacity(f) end
    if not next(f.ents) then FOB.Dissolve(f, "Alle Strukturen entfernt") end
    GARLog.MarkDirty("loc")
end

hook.Add("EntityRemoved", "GARLog_FOB", function(ent)
    if FOBEnts[ent] then FOB.Unregister(ent) end
end)

function FOB.Rename(ply, f, name)
    if not GARLog.Can(ply, "fob.manage") then return false, "Keine Berechtigung." end
    name = GARLog.CleanText(name, cfg.FOB.NameLength)
    if name == "" then return false, "Ungültiger Name." end
    local old = f.name
    f.name = name
    local loc = GARLog.GetLoc(f.locId)
    if loc then loc.name = name end
    for ent in pairs(f.ents) do
        if IsValid(ent) and ent.SetFOBName then ent:SetFOBName(name) end
    end
    GARLog.Log(string.format("Feldbasis '%s' umbenannt in '%s' (%s).", old, name, GARLog.Name(ply)))
    GARLog.MarkDirty("loc")
    FOB.PublishList()
    return true
end

---------------------------------------------------------------------------
-- Platzierung
---------------------------------------------------------------------------
local boundsCache = {}
function FOB.Bounds(model)
    local b = boundsCache[model]
    if b then return b[1], b[2] end
    local mi, ma = Vector(-24, -24, 0), Vector(24, 24, 48)
    local e = ents.Create("prop_physics")
    if IsValid(e) then
        e:SetModel(model)
        local a, z = e:GetModelBounds()
        if a and z and a ~= z then mi, ma = a, z end
        e:Remove()
    end
    boundsCache[model] = { mi, ma }
    return mi, ma
end

local function NearStatic(pos, range)
    local r2 = range * range
    for ent in pairs(GARLog.StaticEnts or {}) do
        if IsValid(ent) and ent:GetPos():DistToSqr(pos) < r2 then return ent end
    end
end

local function blockFilter(e)
    return not (e:IsPlayer() or e:IsNPC() or e:IsNextBot() or e:IsWeapon())
end

-- Rückgabe: ok, Fehlertext, Info
function FOB.CheckPlacement(ply, def, pos, yaw)
    if cfg.FOB.DisabledMaps[game.GetMap()] then return false, "Auf dieser Karte können keine Feldbasen errichtet werden." end
    if ply:EyePos():DistToSqr(pos) > (cfg.FOB.BuildRange + 60) ^ 2 then return false, "Bauplatz zu weit entfernt." end

    local tr = util.TraceLine({ start = pos + Vector(0, 0, 40), endpos = pos - Vector(0, 0, 80), mask = MASK_SOLID_BRUSHONLY })
    if not tr.Hit or tr.HitSky then return false, "Kein fester Untergrund." end
    local minZ = math.cos(math.rad(cfg.FOB.MaxSlope))
    if tr.HitNormal.z < minZ then return false, "Untergrund zu steil." end

    local ground = tr.HitPos
    local model = GARLog.DefModel(def)
    local mi, ma = FOB.Bounds(model)
    local final = ground + Vector(0, 0, -mi.z + 1)

    -- Kollision (vereinfachter Zylinder um das Modell, Hangneigung berücksichtigt)
    local r = math.max(-mi.x, -mi.y, ma.x, ma.y) * 0.6
    local slopeLift = r * math.tan(math.acos(math.Clamp(tr.HitNormal.z, minZ, 1)))
    local h = ma.z - mi.z
    local lift = math.min(6 + slopeLift, h * 0.5)
    local base = ground + Vector(0, 0, lift)
    local hull = util.TraceHull({
        start = base, endpos = base + Vector(0, 0, 1),
        mins = Vector(-r, -r, 0), maxs = Vector(r, r, math.max(h - lift - 4, 8)),
        mask = MASK_SOLID, filter = blockFilter,
    })
    if hull.StartSolid or hull.Hit then return false, "Bauplatz blockiert." end

    local f = FOB.At(ground)
    local founding = false
    if def.core and not f then
        founding = true
        if not GARLog.Can(ply, "build.found") then return false, "Keine Berechtigung, eine Feldbasis zu gründen." end
        if table.Count(FOBs) >= cfg.FOB.MaxFOBs then return false, "Maximale Anzahl an Feldbasen erreicht." end
        for _, o in pairs(FOBs) do
            if o.pos:DistToSqr(ground) < cfg.FOB.MinDistance ^ 2 then return false, "Zu nah an " .. o.name .. "." end
        end
        if NearStatic(ground, 1500) then return false, "Zu nah an einem Flottenstandort." end
    else
        if not f then return false, "Außerhalb einer Feldbasis – zuerst ein Versorgungslager errichten." end
        if not GARLog.Can(ply, "build") then return false, "Keine Berechtigung zum Bauen." end
        if (f.counts[def.key] or 0) >= (def.max or 99) then return false, def.name .. ": Maximum erreicht (" .. (def.max or 99) .. ")." end
        if def.cost and next(def.cost) and not GARLog.HasStock(f.locId, def.cost) then
            return false, "Nicht genug Material im Versorgungslager (" .. GARLog.ItemsText(def.cost) .. ")."
        end
    end

    return true, nil, { ground = ground, final = final, fob = f, founding = founding, model = model }
end

function FOB.Place(ply, key, pos, yaw, name)
    local def = GARLog.BuildDefs[key]
    if not def then return false, "Unbekanntes Bauteil." end
    if def.sse and not GARLog.ClassInstalled(def.class) then return false, def.name .. " ist auf dem Server nicht installiert." end
    local wep = ply:GetActiveWeapon()
    if not ply:Alive() or not GARLog.IsTool(wep) then return false, "Datapad erforderlich." end
    if (ply.GARLogNextPlace or 0) > CurTime() then return false, "Langsam..." end
    ply.GARLogNextPlace = CurTime() + 0.75

    local ok, err, info = FOB.CheckPlacement(ply, def, pos, yaw)
    if not ok then return false, err end

    local f, paid = info.fob, {}
    if info.founding then
        name = GARLog.CleanText(name, cfg.FOB.NameLength)
        if name == "" then name = "FOB " .. (GARLog.Meta.nextFob or 1) end
        f = FOB.Create(name, info.ground, GARLog.Name(ply))
    else
        paid = table.Copy(def.cost or {})
        if next(paid) and not GARLog.TakeStock(f.locId, paid) then return false, "Nicht genug Material." end
    end

    local site = ents.Create("garlog_site")
    if not IsValid(site) then
        if info.founding then FOB.Dissolve(f, "Fehler") elseif next(paid) then GARLog.AddStock(f.locId, paid) end
        return false, "Baustelle konnte nicht erstellt werden."
    end
    site:SetPos(info.final)
    site:SetAngles(Angle(0, math.NormalizeAngle(tonumber(yaw) or 0), 0))
    site:SetupSite(def, info.model, paid, ply)
    site:Spawn()
    site:Activate()
    FOB.Register(site, f, def)
    site:EmitSound(cfg.Sounds.Place, 70)

    if info.founding then
        GARLog.Notify(ply, string.format("Feldbasis '%s' gegründet. Baue das Versorgungslager mit dem Datapad auf (LMB halten).", f.name), "ok")
    end
    if cfg.FOB.InstantBuild then site:AddProgress(ply, 1e6) end
    return true
end

---------------------------------------------------------------------------
-- Fertigstellung einer Baustelle
---------------------------------------------------------------------------
local function ClearPlayers(ent)
    local mi, ma = ent:WorldSpaceAABB()
    local stuck = false
    for _, e in ipairs(ents.FindInBox(mi, ma)) do
        if e:IsPlayer() and e:Alive() then stuck = true break end
    end
    if not stuck then return end
    local oldGroup = ent:GetCollisionGroup()
    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
    local tname = "GARLog_Unstuck_" .. ent:EntIndex()
    timer.Create(tname, 1, 60, function()
        if not IsValid(ent) then timer.Remove(tname) return end
        local a, b = ent:WorldSpaceAABB()
        for _, e in ipairs(ents.FindInBox(a, b)) do
            if e:IsPlayer() then return end
        end
        ent:SetCollisionGroup(oldGroup)
        timer.Remove(tname)
    end)
end

function FOB.CompleteSite(site, builder)
    local def = site.Def
    local f = FOB.OfEnt(site)
    if not def or not f then site:Remove() return end

    local ent = ents.Create(def.class)
    if not IsValid(ent) then
        if next(site.Paid or {}) then GARLog.AddStock(f.locId, site.Paid) end
        GARLog.Log(def.name .. ": Klasse '" .. def.class .. "' existiert nicht – Material zurückgebucht.", "err")
        site:Remove()
        return
    end

    ent:SetPos(site:GetPos())
    ent:SetAngles(site:GetAngles())
    ent.GARLogPaid = site.Paid
    ent.GARLogBuilder = site.BuilderName
    ent:Spawn()
    ent:Activate()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

    FOB.Register(ent, f, def)
    if def.sse then FOB.SetupSSE(ent, f, def) end

    site.GARLogReplaced = true
    site:Remove()
    ClearPlayers(ent)
    if def.key == "s:storage" then
        FOB.RecalcCapacity(f)
        -- Pionierpaket: Erstausstattung, sobald das erste Lager steht
        if not f.startGiven then
            f.startGiven = true
            if next(cfg.FOB.StartStock or {}) then
                local added = GARLog.AddStock(f.locId, cfg.FOB.StartStock)
                if next(added) then GARLog.Log(f.name .. ": Pionierpaket eingelagert: " .. GARLog.ItemsText(added), "ok") end
            end
        end
    end

    ent:EmitSound(cfg.Sounds.BuildDone, 75)
    GARLog.Log(string.format("%s: %s fertiggestellt%s.", f.name, def.name, builder and (" (" .. builder .. ")") or ""), "ok")
    NotifyFOB(f, string.format("%s: %s ist einsatzbereit.", f.name, def.name), "ok")
    hook.Run("GARLog_StructureBuilt", ent, f, def)
end

---------------------------------------------------------------------------
-- SSE-Anbindung: Verbrauch aus Lagern, Strombedarf
---------------------------------------------------------------------------
local Measure = {
    health      = function(p) return p:Health() end,
    armor       = function(p) return p:Armor() end,
    healtharmor = function(p) return p:Health() + p:Armor() end,
    energy      = function(p) return (p.getDarkRPVar and p:getDarkRPVar("Energy")) or 0 end,
    ammo        = function(p)
        local w = p:GetActiveWeapon()
        if not IsValid(w) then return 0 end
        local a, b, s = w:GetPrimaryAmmoType(), w:GetSecondaryAmmoType(), 0
        if a and a >= 0 then s = s + p:GetAmmoCount(a) end
        if b and b >= 0 and b ~= a then s = s + p:GetAmmoCount(b) end
        return s
    end,
}

-- Ersetzt ENT:Use der Instanz: prüft Strom & Bestand, misst den Effekt und bucht ihn ab
function GARLog.WrapSSE(ent, locId, cons, needsPower)
    if ent.GARLogWrapped then return end
    -- Wichtig: aus der Entity-Tabelle lesen. ent.Use liefert zuerst die C-Funktion Entity:Use
    -- (Metatabelle) – die würde den Wrapper erneut auslösen (Endlosschleife).
    local tab = ent:GetTable()
    local orig = tab and rawget(tab, "Use")
    if not isfunction(orig) then
        local stored = scripted_ents.Get(ent:GetClass())
        orig = stored and stored.Use
    end
    if not isfunction(orig) then return end
    if not cons and not needsPower then return end
    ent.GARLogWrapped = true
    ent.GARLogLoc = locId

    tab.Use = function(self, activator, caller, useType, value)
        if not IsValid(activator) or not activator:IsPlayer() then
            return orig(self, activator, caller, useType, value)
        end
        if needsPower and self.GARLogFOB then
            local f = FOBs[self.GARLogFOB]
            if f and not f.powered then
                GARLog.NotifyOnce(activator, "nopower", "Kein Strom – Generator der Feldbasis aus oder ohne Treibstoff.", "err")
                return
            end
        end
        local loc = GARLog.GetLoc(self.GARLogLoc)
        if not cons or not loc then return orig(self, activator, caller, useType, value) end

        if (loc.stock[cons.res] or 0) <= 0 then
            GARLog.NotifyOnce(activator, "empty_" .. cons.res,
                string.format("%s: %s erschöpft – Nachschub anfordern!", loc.name, GARLog.Res[cons.res].name), "err")
            return
        end

        local m = Measure[cons.measure]
        local before = m and m(activator) or 0
        local r = orig(self, activator, caller, useType, value)
        if m and IsValid(activator) then
            local gained = m(activator) - before
            if gained > 0 then GARLog.ConsumeFrac(self.GARLogLoc, cons.res, gained / (cons.per or 10)) end
        end
        return r
    end
end

function FOB.SetupSSE(ent, f, def)
    if def.platform and ent.SetPlatformName then
        ent:SetPlatformName(f.name .. " – Landeplatz " .. (f.counts[def.key] or 1))
    end
    GARLog.WrapSSE(ent, f.locId, cfg.SSEConsume[ent:GetClass()], def.power)
    if def.power then ent:SetNW2Bool("GARLogNeedsPower", true) end
end

-- SSE-Verbrauchsgüter auf der Map (z.B. Venator-Waffenkammer) -> Schiffslager
local function LinkMapSSE(ent)
    if not cfg.ShipSSELink.Enabled or not IsValid(ent) then return end
    if ent.GARLogFOB or ent.GARLogWrapped then return end
    local cons = cfg.SSEConsume[ent:GetClass()]
    if cons and GARLog.GetLoc(cfg.ShipSSELink.Location) then
        GARLog.WrapSSE(ent, cfg.ShipSSELink.Location, cons, false)
    end
end

hook.Add("OnEntityCreated", "GARLog_SSELink", function(ent)
    if not cfg.ShipSSELink.Enabled or not cfg.SSEConsume[ent:GetClass()] then return end
    timer.Simple(0.5, function() LinkMapSSE(ent) end)
end)

hook.Add("InitPostEntity", "GARLog_SSELink", function()
    timer.Simple(3, function()
        for class in pairs(cfg.SSEConsume) do
            for _, e in ipairs(ents.FindByClass(class)) do LinkMapSSE(e) end
        end
    end)
end)

---------------------------------------------------------------------------
-- Bauen & Reparieren (GAR-Datapad)
---------------------------------------------------------------------------
function GARLog.WorkOn(ply, ent, dt)
    if not IsValid(ent) then return false end
    local mult = GARLog.HasRole(ply, "techniker") and cfg.FOB.TechnicianBonus or 1

    if ent:GetClass() == "garlog_site" then
        if not GARLog.Can(ply, "build") then
            GARLog.NotifyOnce(ply, "perm_build", "Keine Berechtigung zum Bauen.", "err")
            return true
        end
        ent:AddProgress(ply, dt * mult)
        return true
    end

    if ent.GARLogStructure then
        if ent:GetHP() >= ent:GetMaxHP() then return false end
        if not GARLog.Can(ply, "build") then
            GARLog.NotifyOnce(ply, "perm_build", "Keine Berechtigung zum Reparieren.", "err")
            return true
        end
        local f = FOB.OfEnt(ent)
        if not f then return false end
        local amount = math.min(cfg.Repair.Rate * dt * mult, ent:GetMaxHP() - ent:GetHP())
        if not GARLog.ConsumeFrac(f.locId, "tech", amount * cfg.Repair.CostPerHP) then
            GARLog.NotifyOnce(ply, "notech", f.name .. ": Keine Ersatzteile im Lager – Reparatur nicht möglich.", "err")
            return true
        end
        ent:Repair(amount)
        return true
    end

    -- LVS-Fahrzeuge an einer Technikerstation (nur Ersatzweg, wenn das Fusion-Cutter-Addon fehlt;
    -- sonst läuft die Reparatur über das Fusion-Cutter-Protokoll, siehe sv_tech.lua)
    if GARLog.UseFCR and GARLog.UseFCR() then return false end
    if ent.LVS and isfunction(ent.GetHP) and isfunction(ent.GetMaxHP) and isfunction(ent.SetHP) then
        local hp, max = ent:GetHP(), ent:GetMaxHP()
        if hp >= max then return false end
        if not GARLog.Can(ply, "repair.vehicle") and not GARLog.Can(ply, "build") then
            GARLog.NotifyOnce(ply, "perm_build", "Keine Berechtigung zum Reparieren.", "err")
            return true
        end
        local f = FOB.At(ent:GetPos())
        if not FOB.FindOperational(f, "s:techstation", ent:GetPos(), cfg.Repair.VehicleRange) then
            GARLog.NotifyOnce(ply, "noveh", "Fahrzeugreparatur nur in Reichweite einer aktiven Technikerstation.", "err")
            return true
        end
        local amount = math.min(cfg.Repair.Rate * cfg.Repair.VehicleRate * dt * mult, max - hp)
        if not GARLog.ConsumeFrac(f.locId, "tech", amount * cfg.Repair.VehicleCost) then
            GARLog.NotifyOnce(ply, "notech", f.name .. ": Keine Ersatzteile im Lager.", "err")
            return true
        end
        ent:SetHP(hp + amount)
        if hp + amount >= max and GARLog.OnVehicleServiced then GARLog.OnVehicleServiced(ply, ent, f.locId) end
        return true
    end

    return false
end

function FOB.Dismantle(ply, ent)
    if not IsValid(ent) then return false, "Ungültiges Ziel." end
    local f = FOB.OfEnt(ent)
    if not f then return false, "Gehört zu keiner Feldbasis." end
    if not GARLog.Can(ply, "build.dismantle") then return false, "Keine Berechtigung zum Abbauen." end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 320 * 320 then return false, "Zu weit entfernt." end

    local def = GARLog.BuildDefs[f.ents[ent]]
    local paid = ent.GARLogPaid or ent.Paid or (def and def.cost) or {}
    local factor = ent:GetClass() == "garlog_site" and 1 or cfg.FOB.DismantleRefund
    local refund = {}
    for id, n in pairs(paid) do
        local v = math.floor(n * factor)
        if v > 0 then refund[id] = v end
    end

    local name, fobName = def and def.name or ent:GetClass(), f.name
    ent.GARLogDismantled = true
    ent:Remove()

    if FOBs[f.id] and next(refund) then GARLog.AddStock(f.locId, refund) end
    GARLog.Log(string.format("%s: %s abgebaut von %s%s.", fobName, name, GARLog.Name(ply),
        next(refund) and (" (Rückgewinnung: " .. GARLog.ItemsText(refund) .. ")") or ""))
    return true
end

---------------------------------------------------------------------------
-- Zustand & automatische Reparaturaufträge
---------------------------------------------------------------------------
function FOB.OnHealthChanged(ent)
    local f = FOB.OfEnt(ent)
    if not f then return end

    local frac = ent:GetHP() / math.max(1, ent:GetMaxHP())
    -- Datapads nur bei 5-%-Schritten aktualisieren (im Gefecht ändert sich HP sonst ständig)
    local bucket = math.floor(frac * 20)
    if ent.GARLogHPBucket ~= bucket then
        ent.GARLogHPBucket = bucket
        GARLog.MarkDirty("loc")
    end
    local o = FOB.RepairByEnt[ent]
    if o and o.st >= GARLog.REP_DONE then
        FOB.RepairByEnt[ent], o = nil, nil
    end

    if frac >= 0.999 then
        if o then
            FOB.RepairByEnt[ent] = nil
            GARLog.CloseRepair(o, GARLog.REP_DONE, "Instandgesetzt")
        end
        return
    end

    local prio = frac <= 0 and 4 or (frac < 0.35 and 3 or 2)
    if o then
        local fr = math.floor(frac * 20) / 20
        if o.fr ~= fr then
            o.fr, o.pr = fr, prio
            GARLog.MarkDirty("rep")
        end
    elseif frac < cfg.Repair.Threshold then
        local def = GARLog.BuildDefs[f.ents[ent]]
        local name = def and def.name or "Struktur"
        o = GARLog.CreateRepair({
            k = "auto", loc = f.locId, title = name .. " – " .. f.name,
            ent = ent:EntIndex(), pos = ent:WorldSpaceCenter(), fr = math.Round(frac, 2), pr = prio,
        })
        FOB.RepairByEnt[ent] = o
        GARLog.NotifyPerm("repair.work", string.format("Reparaturauftrag R-%d: %s in %s (%d%%).", o.id, name, f.name, math.floor(frac * 100)), prio >= 3 and "warn" or "info")
    end
end

function FOB.OnDestroyed(ent)
    local f = FOB.OfEnt(ent)
    if not f then return end
    local def = GARLog.BuildDefs[f.ents[ent]]
    local name = def and def.name or "Struktur"
    GARLog.Log(string.format("%s: %s zerstört!", f.name, name), "err")
    NotifyFOB(f, string.format("%s: %s wurde zerstört!", f.name, name), "err")
    if f.ents[ent] == "s:storage" then FOB.RecalcCapacity(f) end
end

function FOB.OnRestored(ent)
    local f = FOB.OfEnt(ent)
    if not f then return end
    if f.ents[ent] == "s:storage" then FOB.RecalcCapacity(f) end
end

---------------------------------------------------------------------------
-- Takt: Anwesenheit, Strom, Treibstoff, Antennen, Anzeige-Werte
---------------------------------------------------------------------------
function FOB.UpdatePresence()
    local before = {}
    for id, f in pairs(FOBs) do before[id] = f.present f.present = 0 end
    for _, p in ipairs(player.GetAll()) do
        local f = p:Alive() and FOB.At(p:GetPos()) or nil
        p.GARLogInFOB = f and f.id or nil
        if f then f.present = f.present + 1 end
    end
    for id, f in pairs(FOBs) do
        if before[id] ~= f.present then GARLog.MarkDirty("loc") break end
    end
end

local function TickOne(f)
    local loc = GARLog.GetLoc(f.locId)
    if not loc then return end
    local genDef = cfg.Structures.generator

    local running = 0
    for ent, key in pairs(f.ents) do
        if key == "s:generator" and IsValid(ent) and ent.GARLogStructure and ent:GetOn() and not ent:GetDestroyed() then
            running = running + 1
        end
    end

    local powered = false
    if running > 0 then
        powered = GARLog.ConsumeFrac(f.locId, "fuel", running * (genDef.fuelPerMin or 4) / 60 * cfg.TickInterval)
    end

    local antenna = false
    for ent, key in pairs(f.ents) do
        if IsValid(ent) and ent.GARLogStructure then
            local p = powered and not ent:GetDestroyed()
            if key == "s:generator" then p = p and ent:GetOn() end
            if ent:GetPowered() ~= p then ent:SetPowered(p) end
            if key == "s:antenna" and ent:IsOperational() then antenna = true end
            if ent.SupplyRes then
                local v, c = loc.stock[ent.SupplyRes] or 0, loc.cap[ent.SupplyRes] or 0
                if ent:GetSupply() ~= v then ent:SetSupply(v) end
                if ent:GetSupplyCap() ~= c then ent:SetSupplyCap(c) end
            end
        end
    end

    if f.powered ~= powered then
        f.powered = powered
        GARLog.MarkDirty("loc")
        if not GARLog.ShuttingDown then
            if powered then
                NotifyFOB(f, f.name .. ": Stromversorgung hergestellt.", "ok")
            else
                local why = running > 0 and "kein Treibstoff" or "kein Generator in Betrieb"
                NotifyFOB(f, f.name .. ": Stromausfall (" .. why .. ")!", "err")
                GARLog.Log(f.name .. ": Stromausfall (" .. why .. ").", "warn")
            end
        end
    end

    if f.antenna ~= antenna then
        f.antenna = antenna
        GARLog.MarkDirty("loc")
        GARLog.Log(f.name .. (antenna and ": Funkverbindung zur Flotte steht." or ": Funkverbindung zur Flotte verloren!"), antenna and "ok" or "warn")
        hook.Run("GARLog_AntennaChanged", f.id, antenna)
    end
end

function FOB.Tick(now, tickN)
    if tickN % 5 == 0 then FOB.UpdatePresence() end
    local changed = false
    for _, f in pairs(FOBs) do
        local pw, an = f.powered, f.antenna
        TickOne(f)
        if f.powered ~= pw or f.antenna ~= an then changed = true end
    end
    if changed then FOB.PublishList() end
end

-- Für andere Scripte (z.B. Funk): Hat diese Position Funkabdeckung einer FOB-Antenne?
function GARLog.HasCommsCoverage(pos)
    local f = FOB.At(pos)
    return f ~= nil and f.antenna == true, f
end

---------------------------------------------------------------------------
-- Sync-Daten einer Feldbasis
---------------------------------------------------------------------------
function FOB.SyncInfo(id)
    local f = FOBs[id]
    if not f then return nil end
    local st = {}
    for ent, key in pairs(f.ents) do
        if IsValid(ent) then
            local e = { k = key, i = ent:EntIndex() }
            if ent.GARLogStructure then
                e.hp = math.Round(ent:GetHP() / math.max(1, ent:GetMaxHP()), 2)
                if ent:GetDestroyed() then e.d = true end
                if ent:GetPowered() then e.p = true end
            elseif ent.GetProgress then
                e.b = math.Round(ent:GetProgress(), 2)
            end
            st[#st + 1] = e
        end
    end
    table.sort(st, function(a, b) return a.i < b.i end)
    return {
        id = f.id, x = math.Round(f.pos.x), y = math.Round(f.pos.y), z = math.Round(f.pos.z), r = f.radius,
        pw = f.powered, an = f.antenna, pr = f.present, cnt = f.counts, st = st,
        fd = f.founder, ct = f.created, sto = f.storages or 0,
    }
end
