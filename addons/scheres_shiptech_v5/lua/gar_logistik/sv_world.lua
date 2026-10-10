-- Map-Verankerung (Terminals, Frachtrampen) und Frachtcontainer

local cfg = GARLog.Config
local DB = GARLog.DB

GARLog.StaticEnts = GARLog.StaticEnts or {}   -- Terminals & Frachtrampen
local STATIC = { garlog_terminal = true, garlog_cargopad = true }

---------------------------------------------------------------------------
-- Anker
---------------------------------------------------------------------------
function GARLog.RegisterStatic(ent)
    GARLog.StaticEnts[ent] = true
    GARLog.MarkDirty("loc")
end

function GARLog.UnregisterStatic(ent)
    GARLog.StaticEnts[ent] = nil
    GARLog.MarkDirty("loc")
end

function GARLog.LocationOnMap(locId)
    for ent in pairs(GARLog.StaticEnts) do
        if IsValid(ent) and ent:GetLocationID() == locId then return true end
    end
    return false
end

local function IsIntactStorage(ent, key)
    return key == "s:storage" and IsValid(ent) and ent.GARLogStructure and not ent:GetDestroyed()
end

-- Nächster Anker eines bestimmten Standorts
function GARLog.FindAnchor(locId, pos, range)
    local loc = GARLog.GetLoc(locId)
    if not loc then return end
    local r2, best, bd = range * range
    if loc.fob then
        local f = GARLog.FOBs[loc.fob]
        if not f then return end
        for ent, key in pairs(f.ents) do
            if IsIntactStorage(ent, key) then
                local d = ent:GetPos():DistToSqr(pos)
                if d <= r2 and (not bd or d < bd) then best, bd = ent, d end
            end
        end
        return best
    end
    for ent in pairs(GARLog.StaticEnts) do
        if IsValid(ent) and ent:GetLocationID() == locId then
            local d = ent:GetPos():DistToSqr(pos)
            if d <= r2 and (not bd or d < bd) then best, bd = ent, d end
        end
    end
    return best
end

-- Nächster Standort, in den an dieser Position entladen werden kann
function GARLog.FindReceiver(pos, range)
    local r2, bestLoc, bestEnt, bd = range * range
    for ent in pairs(GARLog.StaticEnts) do
        if IsValid(ent) then
            local id = ent:GetLocationID()
            if GARLog.GetLoc(id) then
                local d = ent:GetPos():DistToSqr(pos)
                if d <= r2 and (not bd or d < bd) then bestLoc, bestEnt, bd = id, ent, d end
            end
        end
    end
    for _, f in pairs(GARLog.FOBs) do
        for ent, key in pairs(f.ents) do
            if IsIntactStorage(ent, key) then
                local d = ent:GetPos():DistToSqr(pos)
                if d <= r2 and (not bd or d < bd) then bestLoc, bestEnt, bd = f.locId, ent, d end
            end
        end
    end
    return bestLoc, bestEnt
end

function GARLog.DescribePos(pos)
    local f = GARLog.FOB.At(pos)
    if f then return f.name end
    local id = GARLog.FindReceiver(pos, 3000)
    if id then return "bei " .. GARLog.LocName(id) end
    return "im Feld"
end

---------------------------------------------------------------------------
-- Speichern der Map-Entities (pro Map)
---------------------------------------------------------------------------
local function SaveKey() return "statics_" .. game.GetMap() end

function GARLog.SaveStatics()
    if GARLog.ShuttingDown or GARLog.CleaningUp or GARLog.LoadingStatics then return end
    local list = {}
    for ent in pairs(GARLog.StaticEnts) do
        if IsValid(ent) and not ent.GARLogRemoving then
            local p, a = ent:GetPos(), ent:GetAngles()
            list[#list + 1] = {
                c = ent:GetClass(), l = ent:GetLocationID(),
                p = { math.Round(p.x, 2), math.Round(p.y, 2), math.Round(p.z, 2) },
                a = { math.Round(a.p, 2), math.Round(a.y, 2), math.Round(a.r, 2) },
            }
        end
    end
    DB.Save(SaveKey(), list)
end

function GARLog.QueueSaveStatics()
    if GARLog.ShuttingDown or GARLog.CleaningUp or GARLog.LoadingStatics then return end
    timer.Create("GARLog_SaveStatics", 2, 1, GARLog.SaveStatics)
end

function GARLog.SpawnStatics()
    local data = DB.Load(SaveKey())
    if not istable(data) then return end
    GARLog.LoadingStatics = true
    for ent in pairs(GARLog.StaticEnts) do
        if IsValid(ent) then ent.GARLogRemoving = true ent:Remove() end
    end
    for _, d in ipairs(data) do
        if STATIC[d.c] and istable(d.p) and istable(d.a) then
            local e = ents.Create(d.c)
            if IsValid(e) then
                e:SetPos(Vector(d.p[1], d.p[2], d.p[3]))
                e:SetAngles(Angle(d.a[1], d.a[2], d.a[3]))
                e:Spawn()
                e:Activate()
                e:SetLocationID(d.l or "")
                local ph = e:GetPhysicsObject()
                if IsValid(ph) then ph:EnableMotion(false) end
            end
        end
    end
    GARLog.LoadingStatics = false
end

hook.Add("InitPostEntity", "GARLog_Statics", function() timer.Simple(2, GARLog.SpawnStatics) end)
hook.Add("PreCleanupMap", "GARLog_Statics", function() GARLog.CleaningUp = true end)
hook.Add("PostCleanupMap", "GARLog_Statics", function()
    GARLog.CleaningUp = false
    timer.Simple(0.5, GARLog.SpawnStatics)
end)
hook.Add("PhysgunDrop", "GARLog_Statics", function(_, ent)
    if IsValid(ent) and STATIC[ent:GetClass()] then GARLog.QueueSaveStatics() end
end)

---------------------------------------------------------------------------
-- Frachtcontainer
---------------------------------------------------------------------------
local function ActiveContainers()
    local n = 0
    for id, c in pairs(GARLog.Containers) do
        if IsValid(c.ent) then n = n + 1 else GARLog.Containers[id] = nil end
    end
    return n
end

local function ContainerSpawn(locId, anchor, ply)
    local model = GARLog.ResolveModel(cfg.Container.Model, cfg.Container.Fallback)
    local mi = GARLog.FOB.Bounds(model)
    local lift = -mi.z + 6

    -- freie Frachtrampe des Standorts
    for ent in pairs(GARLog.StaticEnts) do
        if IsValid(ent) and ent:GetClass() == "garlog_cargopad" and ent:GetLocationID() == locId then
            local top = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z)
            local free = true
            for _, e in ipairs(ents.FindInSphere(top, 70)) do
                if e:GetClass() == "garlog_container" then free = false break end
            end
            if free then return top + Vector(0, 0, lift), Angle(0, ent:GetAngles().y, 0) end
        end
    end

    -- sonst zwischen Anker und Spieler
    local from = anchor:WorldSpaceCenter()
    local dir = ply:GetPos() - anchor:GetPos()
    dir.z = 0
    if dir:LengthSqr() < 1 then dir = anchor:GetForward() end
    dir:Normalize()
    local target = anchor:GetPos() + dir * (anchor:BoundingRadius() + 60)
    local tr = util.TraceLine({ start = from, endpos = target + Vector(0, 0, 20), filter = { anchor, ply }, mask = MASK_SOLID })
    local pos = tr.Hit and (tr.HitPos - dir * 30) or target
    local down = util.TraceLine({ start = pos + Vector(0, 0, 40), endpos = pos - Vector(0, 0, 200), mask = MASK_SOLID_BRUSHONLY })
    return (down.Hit and down.HitPos or pos) + Vector(0, 0, lift), Angle(0, dir:Angle().y, 0)
end

function GARLog.PackContainer(ply, locId, items, reqId)
    if not GARLog.Can(ply, "container.pack") then return nil, "Keine Berechtigung zum Packen von Containern." end
    local loc = GARLog.GetLoc(locId)
    if not loc then return nil, "Unbekannter Standort." end

    local anchor
    if loc.fob then
        local f = GARLog.FOBs[loc.fob]
        if not f or ply:GetPos():DistToSqr(f.pos) > f.radius * f.radius then return nil, "Du musst dich in der Feldbasis befinden." end
        anchor = GARLog.FindAnchor(locId, ply:GetPos(), f.radius * 2)
        if not anchor then return nil, "Kein intaktes Versorgungslager in der Feldbasis." end
    else
        anchor = GARLog.FindAnchor(locId, ply:GetPos(), cfg.Container.PackRange)
        if not anchor then
            return nil, "Container können nur an einem Logistik-Terminal / einer Frachtrampe von " .. loc.name .. " gepackt werden."
        end
    end

    if ActiveContainers() >= cfg.Container.MaxActive then return nil, "Zu viele Container im Umlauf (max. " .. cfg.Container.MaxActive .. ")." end

    items = GARLog.SanitizeItems(items, 100000)
    if not next(items) then return nil, "Keine Fracht ausgewählt." end
    local vol = GARLog.ItemVolume(items)
    if vol > cfg.Container.Capacity then
        return nil, string.format("Fracht zu groß (%s / %s FE).", GARLog.FmtNum(vol), GARLog.FmtNum(cfg.Container.Capacity))
    end
    if not GARLog.TakeStock(locId, items) then return nil, "Nicht genug Bestand in " .. loc.name .. "." end

    local pos, ang = ContainerSpawn(locId, anchor, ply)
    local ent = ents.Create("garlog_container")
    if not IsValid(ent) then
        GARLog.AddStock(locId, items, true)
        return nil, "Container konnte nicht erstellt werden."
    end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()

    local id = GARLog.NextId("nextCnt")
    local by = GARLog.Name(ply)
    ent:SetCargo(id, items, locId, reqId, by)
    GARLog.Containers[id] = { id = id, ent = ent, src = locId, req = reqId, by = by, t = os.time() }

    GARLog.Log(string.format("Container C-%d in %s gepackt von %s: %s", id, loc.name, by, GARLog.ItemsText(items)))
    GARLog.MarkDirty("trn")
    return ent
end

-- An ein Fahrzeug (LAAT, AT-TE, ...) koppeln, damit Container geflogen / gefahren werden können
local function IsCarrier(v)
    return IsValid(v) and (v.LVS or v:IsVehicle() or v.IsSimfphyscar or v.IsGlideVehicle) and IsValid(v:GetPhysicsObject())
end

function GARLog.AttachContainer(ply, ent)
    if not IsValid(ent) or ent:GetClass() ~= "garlog_container" then return false, "Ungültiger Container." end
    if not GARLog.Can(ply, "container.move") then return false, "Keine Berechtigung." end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 260 * 260 then return false, "Zu weit vom Container entfernt." end
    if ent:GetAttached() and IsValid(ent.AttachWeld) then return false, "Container ist bereits gekoppelt." end

    local best, bd
    for _, v in ipairs(ents.FindInSphere(ent:GetPos(), cfg.Container.AttachRange)) do
        if v ~= ent and IsCarrier(v) then
            local d = v:GetPos():DistToSqr(ent:GetPos())
            if not bd or d < bd then best, bd = v, d end
        end
    end
    if not best then
        return false, "Kein Fahrzeug in der Nähe (max. " .. math.floor(cfg.Container.AttachRange * 0.01905) .. " m)."
    end

    local weld = constraint.Weld(ent, best, 0, 0, 0, true, false)
    if not IsValid(weld) then return false, "Ankoppeln fehlgeschlagen." end
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:SetMass(cfg.Container.AttachedMass or 30) phys:Wake() end
    ent.AttachWeld = weld
    ent:SetAttached(true)
    ent:EmitSound("buttons/lever7.wav", 70)
    return true
end

function GARLog.DetachContainer(ply, ent)
    if not IsValid(ent) or ent:GetClass() ~= "garlog_container" then return false end
    if not GARLog.Can(ply, "container.move") then return false, "Keine Berechtigung." end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 400 * 400 then return false, "Zu weit vom Container entfernt." end
    if IsValid(ent.AttachWeld) then ent.AttachWeld:Remove() end
    ent.AttachWeld = nil
    ent:SetAttached(false)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:SetMass(cfg.Container.Mass or 300) phys:Wake() end
    ent:EmitSound("buttons/lever8.wav", 70)
    return true
end

function GARLog.StartUnload(ply, ent)
    if not IsValid(ent) or ent:GetClass() ~= "garlog_container" then return false, "Ungültiger Container." end
    if not GARLog.Can(ply, "container.unload") then return false, "Keine Berechtigung zum Entladen." end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 260 * 260 then return false, "Zu weit vom Container entfernt." end
    if ent:GetUnloadEnd() > 0 then return false, "Container wird bereits entladen." end
    if not next(ent.Items or {}) then return false, "Container ist leer." end

    local locId = GARLog.FindReceiver(ent:GetPos(), cfg.Container.UnloadRange)
    if not locId then return false, "Kein Lager in Reichweite (Versorgungslager / Frachtrampe / Terminal)." end

    ent:SetUnloadEnd(CurTime() + cfg.Container.UnloadTime)
    ent.UnloadTarget, ent.Unloader, ent.UnloaderPly = locId, GARLog.Name(ply), ply
    ent:EmitSound(cfg.Sounds.Unload, 70)
    timer.Create("GARLog_Unload_" .. ent:EntIndex(), cfg.Container.UnloadTime, 1, function()
        if IsValid(ent) then GARLog.Protected("Entladen", GARLog.FinishUnload, ent) end
    end)
    return true
end

function GARLog.FinishUnload(ent)
    local locId, ply = ent.UnloadTarget, ent.UnloaderPly
    ent:SetUnloadEnd(0)

    if not GARLog.GetLoc(locId) or GARLog.FindReceiver(ent:GetPos(), cfg.Container.UnloadRange + 100) ~= locId then
        if IsValid(ply) then GARLog.Notify(ply, "Entladen abgebrochen – Container wurde bewegt.", "err") end
        return
    end

    local added, over = GARLog.AddStock(locId, ent.Items or {})
    if not next(added) then
        if IsValid(ply) then GARLog.Notify(ply, GARLog.LocName(locId) .. ": Lager voll – nichts entladen.", "err") end
        return
    end

    ent:SetItems(over)
    local id = ent:GetContainerID()
    GARLog.Log(string.format("Container C-%d in %s entladen von %s: %s%s", id, GARLog.LocName(locId), ent.Unloader or "?",
        GARLog.ItemsText(added), next(over) and (" (Rest im Container: " .. GARLog.ItemsText(over) .. ")") or ""), "ok")
    if IsValid(ply) then
        GARLog.Notify(ply, string.format("Container C-%d entladen: %s", id, GARLog.ItemsText(added)), "ok")
    end
    if ent.Req then
        GARLog.DeliverRequest(ent.Req, added, locId, ent.Unloader)
        ent.Req = nil
    end
    if not next(over) then
        ent.GARLogUnloaded = true
        ent:Remove()
    end
    GARLog.MarkDirty("trn")
end

function GARLog.OnContainerRemoved(ent)
    local id = ent:GetContainerID()
    GARLog.Containers[id] = nil
    GARLog.MarkDirty("trn")
    timer.Remove("GARLog_Unload_" .. ent:EntIndex())
    if ent.GARLogUnloaded or GARLog.ShuttingDown then return end

    local items = ent.Items or {}
    if not next(items) then return end

    if ent.GARLogDestroyed then
        GARLog.Log(string.format("Container C-%d zerstört – Fracht verloren: %s", id, GARLog.ItemsText(items)), "err")
        if ent.Req then GARLog.FailRequestDelivery(ent.Req, "Container zerstört") end
    else
        -- Aufräumen / Entfernen: Fracht zurück ins Ursprungslager
        if GARLog.GetLoc(ent.Src) then GARLog.AddStock(ent.Src, items) end
        GARLog.Log(string.format("Container C-%d entfernt – Fracht an %s zurückgebucht.", id, GARLog.LocName(ent.Src)), "warn")
        if ent.Req then GARLog.FailRequestDelivery(ent.Req, "Container entfernt") end
    end
end

-- Beim Herunterfahren: Containerinhalt zurück ins Ursprungslager (Container überleben keinen Neustart)
hook.Add("GARLog_PreSave", "GARLog_Containers", function()
    for _, c in pairs(GARLog.Containers) do
        local e = c.ent
        if IsValid(e) and not e.GARLogUnloaded then
            if next(e.Items or {}) and GARLog.GetLoc(e.Src) then GARLog.AddStock(e.Src, e.Items) end
            e.GARLogUnloaded = true
        end
    end
end)

-- Standortbeschreibung aktuell halten, gerissene Kopplungen (Fahrzeug weg) zurücksetzen
timer.Create("GARLog_ContainerPos", 10, 0, function()
    if not next(GARLog.Containers) then return end
    GARLog.MarkDirty("trn")
    for _, c in pairs(GARLog.Containers) do
        local e = c.ent
        if IsValid(e) and e:GetAttached() and not IsValid(e.AttachWeld) then
            e:SetAttached(false)
            local phys = e:GetPhysicsObject()
            if IsValid(phys) then phys:SetMass(cfg.Container.Mass or 300) phys:Wake() end
        end
    end
end)

---------------------------------------------------------------------------
-- Admin-Befehle
---------------------------------------------------------------------------
local function AdminOnly(ply)
    return not IsValid(ply) or ply:IsSuperAdmin()
end

concommand.Add("garlog_savestatics", function(ply)
    if not AdminOnly(ply) then return end
    GARLog.SaveStatics()
    print("[GAR Logistik] Terminals & Frachtrampen gespeichert.")
end)

concommand.Add("garlog_setstock", function(ply, _, args)
    if not AdminOnly(ply) then return end
    local loc, res, n = args[1], args[2], tonumber(args[3])
    if not GARLog.GetLoc(loc) or not GARLog.Res[res] or not n then
        print("Benutzung: garlog_setstock <standort> <ressource> <menge>")
        return
    end
    GARLog.SetStock(loc, res, n)
    GARLog.Log(string.format("Admin: Bestand %s / %s auf %s gesetzt.", GARLog.LocName(loc), GARLog.Res[res].name, GARLog.FmtNum(n)), "warn")
end)

concommand.Add("garlog_resetstock", function(ply, _, args)
    if not AdminOnly(ply) then return end
    if args[1] ~= "confirm" then print("Setzt alle festen Lager auf Startwerte zurück: garlog_resetstock confirm") return end
    for _, def in ipairs(cfg.Locations) do
        for _, res in ipairs(GARLog.ResOrder) do GARLog.SetStock(def.id, res, (def.start or {})[res] or 0) end
    end
    GARLog.Log("Admin: Alle festen Lager auf Startwerte zurückgesetzt.", "warn")
end)
