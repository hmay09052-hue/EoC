--[[
    ShipTech – Erweiterungen (Server)
    Brände · Hyperraumsprung · Startcheckliste · Szenarien & Abläufe · Fahrzeuge · Werkzeug · Ingame-Konfiguration
]]

local C = ShipTech.Config

local function Def(id) return ShipTech.SystemById[id] end
local function Sys(id) return ShipTech.State.systems[id] end
local function StageOf(h) return ShipTech.StageOf(h) end
local function Deny(ply, text) ShipTech.Notify(ply, text, 1) end
local function Ok(ply, text) ShipTech.Notify(ply, text, 0) end
local function Nick(ply) return (IsValid(ply) and ply:IsPlayer()) and ply:Nick() or "Ablauf" end

---------------------------------------------------------------------------
-- BRÄNDE
---------------------------------------------------------------------------
local function FireOf(ent) return ent:GetNW2Float("ST_Fire", 0) end

function ShipTech.Ignite(ent, reason)
    if not C.Fire.Enabled or not IsValid(ent) or FireOf(ent) > 0 then return end
    ent:SetNW2Float("ST_Fire", 0.25)
    local what = ent.SysId and Def(ent.SysId) and Def(ent.SysId).name or ent.PrintName
    ShipTech.Chat("crit", "BRAND an " .. ent.PrintName .. " (" .. what .. ")!" .. (reason and (" – " .. reason) or ""))
    ShipTech.Log("BRAND", "Brand ausgebrochen: " .. ent.PrintName .. (reason and (" (" .. reason .. ")") or ""))
end

-- Zufällige Konsole eines Systems mit Chance in Brand setzen
function ShipTech.MaybeIgnite(id, chance)
    if not C.Fire.Enabled or math.random() >= (chance or 0) then return end
    local list = ShipTech.ConsoleList("system", id)
    if #list > 0 then ShipTech.Ignite(list[math.random(#list)]) end
end

function ShipTech.Extinguish(ent, amount, ply)
    local f = FireOf(ent)
    if f <= 0 then return false end
    f = f - amount
    if f <= 0 then
        ent:SetNW2Float("ST_Fire", 0)
        ShipTech.Log("BRAND", "Brand gelöscht: " .. ent.PrintName, ply)
        if IsValid(ply) then Ok(ply, "Brand an " .. ent.PrintName .. " gelöscht.") end
    else
        ent:SetNW2Float("ST_Fire", f)
    end
    return true
end

function ShipTech.ExtinguishAll()
    for _, e in ipairs(ShipTech.ConsoleList()) do e:SetNW2Float("ST_Fire", 0) end
end

function ShipTech.IsBurning(id)
    for _, e in ipairs(ShipTech.ConsoleList("system", id)) do
        if FireOf(e) > 0 then return true end
    end
    return false
end

-- zusätzliche Zieltemperatur durch Brand an einem System
local fireHeat = {}
function ShipTech.FireHeat(id) return fireHeat[id] or 0 end

hook.Add("ShipTech_FastTick", "ShipTech_Fires", function(dt)
    local S = ShipTech.State
    fireHeat = {}
    local count = 0
    for _, e in ipairs(ShipTech.ConsoleList()) do
        local f = FireOf(e)
        if f > 0 then
            count = count + 1
            f = math.min(1, f + C.Fire.GrowPerSecond * dt)
            e:SetNW2Float("ST_Fire", f)

            if e.SysId and Sys(e.SysId) then
                local s = Sys(e.SysId)
                if s.health > 0 then
                    ShipTech.SetHealth(e.SysId, s.health - C.Fire.DamagePerMinute * f * dt / 60, "Brand")
                end
                fireHeat[e.SysId] = math.max(fireHeat[e.SysId] or 0, 30 * f)
            end

            -- Spieler in der Nähe verbrennen sich
            if C.Fire.PlayerDamage > 0 then
                local pos = e:WorldSpaceCenter()
                for _, ply in ipairs(player.GetAll()) do
                    if ply:Alive() and ply:GetPos():DistToSqr(pos) < C.Fire.PlayerRadius ^ 2 then
                        local d = DamageInfo()
                        d:SetDamage(C.Fire.PlayerDamage * f * dt)
                        d:SetDamageType(DMG_BURN)
                        d:SetAttacker(e)
                        d:SetInflictor(e)
                        ply:TakeDamageInfo(d)
                    end
                end
            end

            -- Ausbreitung
            if f >= 1 and math.random() < C.Fire.SpreadChance * dt then
                local pos = e:GetPos()
                for _, o in ipairs(ShipTech.ConsoleList()) do
                    if o ~= e and FireOf(o) <= 0 and o:GetPos():DistToSqr(pos) < C.Fire.SpreadRadius ^ 2 then
                        ShipTech.Ignite(o, "Brand hat übergegriffen")
                        break
                    end
                end
            end
        end
    end
    S.fires = count
    ShipTech.AutoAlarm("fire", count > 0, count > 1 and (count .. " Brandherde") or nil)
end)

---------------------------------------------------------------------------
-- STARTCHECKLISTE
---------------------------------------------------------------------------
local Actions = ShipTech.Actions

Actions.check_confirm = function(ply, ent)
    if ent.ConsoleKind ~= "terminal" and ent.ConsoleKind ~= "wall" then return end
    if not ShipTech.IsNavy(ply) then return Deny(ply, "Nur Navy-Personal kann die Startcheckliste bestätigen.") end
    local S = ShipTech.State
    local i = S.checklist.n + 1
    local step = ShipTech.ChecklistSteps[i]
    if not step then return Deny(ply, "Die Startcheckliste ist bereits abgeschlossen.") end
    if not step.check(S) then return Deny(ply, "Schritt " .. i .. " ist noch nicht erfüllt: " .. step.hint) end
    S.checklist.n = i
    S.checklist.by[i] = ply:Nick()
    ShipTech.Chat("navy", "Startcheckliste " .. i .. "/" .. #ShipTech.ChecklistSteps .. ": " .. step.name .. " – bestätigt von " .. ply:Nick())
    ShipTech.Log("CHECKLISTE", "Schritt " .. i .. " bestätigt: " .. step.name, ply)
    if i == #ShipTech.ChecklistSteps then
        ShipTech.Chat("navy", "STARTCHECKLISTE ABGESCHLOSSEN – das Schiff ist startklar.")
    end
    ShipTech.MarkDirty()
end

Actions.check_reset = function(ply, ent)
    if ent.ConsoleKind ~= "terminal" and ent.ConsoleKind ~= "wall" then return end
    if not ShipTech.IsNavy(ply) then return Deny(ply, "Keine Berechtigung.") end
    ShipTech.State.checklist = { n = 0, by = {} }
    ShipTech.Log("CHECKLISTE", "Startcheckliste zurückgesetzt", ply)
    ShipTech.MarkDirty()
end

---------------------------------------------------------------------------
-- HYPERRAUMSPRUNG
-- idle -> calc (Kurs wird berechnet) -> ready -> routed (Energie umgeleitet) -> countdown -> hyperspace
---------------------------------------------------------------------------
local hyperFailNext = false

local function SetPhase(phase, t)
    local H = ShipTech.State.hyper
    H.phase = phase
    H.t = t or 0
    ShipTech.MarkDirty()
end

local function JumpProblems()
    local S = ShipTech.State
    local h = S.systems.hyperdrive
    local p = {}
    if not h.on then p[#p + 1] = "Hyperantrieb ist nicht hochgefahren" end
    if not h.navyClear then p[#p + 1] = "Navy-Freigabe für den Hyperantrieb fehlt" end
    if (h.eff or 0) < C.Hyper.MinEfficiency then p[#p + 1] = "Hyperantrieb-Effizienz zu niedrig (" .. math.Round((h.eff or 0) * 100) .. " %)" end
    if h.alloc < C.Hyper.MinAlloc then p[#p + 1] = "zu wenig Energie für den Hyperantrieb (" .. h.alloc .. "/" .. C.Hyper.MinAlloc .. " E)" end
    if not S.systems.engines.on then p[#p + 1] = "Triebwerke sind offline" end
    if ShipTech.IsBurning("hyperdrive") then p[#p + 1] = "Brand am Hyperantrieb" end
    return p
end
ShipTech.JumpProblems = JumpProblems

local function ExitHyperspace(reason, damaged)
    local H = ShipTech.State.hyper
    ShipTech.FX("hyper_out")
    if damaged then
        ShipTech.Chat("crit", "NOTAUSTRITT AUS DEM HYPERRAUM – " .. reason)
    else
        ShipTech.Chat("navy", "Rücksturz aus dem Hyperraum. Ankunft: " .. (H.dest ~= "" and H.dest or "unbekannt"))
    end
    ShipTech.Log("HYPERRAUM", "Austritt aus dem Hyperraum" .. (reason and (" (" .. reason .. ")") or ""))
    SetPhase("idle")
end
ShipTech.ExitHyperspace = ExitHyperspace

local function DoJump()
    local S = ShipTech.State
    local h = S.systems.hyperdrive
    local problems = JumpProblems()
    local chance = 0.6 + 0.4 * (h.maint / 100) - 0.25 * #h.faults
    local fail = hyperFailNext or #problems > 0 or math.random() > chance
    hyperFailNext = false
    if fail then
        ShipTech.Chat("crit", "SPRUNG FEHLGESCHLAGEN – Hyperantrieb überlastet!")
        ShipTech.Log("HYPERRAUM", "Sprung fehlgeschlagen" .. (#problems > 0 and (": " .. table.concat(problems, ", ")) or ""))
        ShipTech.SetHealth("hyperdrive", math.min(h.health, 30), "Fehlgeschlagener Hyperraumsprung")
        ShipTech.MaybeIgnite("hyperdrive", 0.8)
        ShipTech.FX("hit")
        SetPhase("idle")
        return
    end
    ShipTech.FX("hyper_in")
    ShipTech.Chat("navy", "Sprung in den Hyperraum erfolgreich. Kurs: " .. (S.hyper.dest ~= "" and S.hyper.dest or "unbekannt"))
    ShipTech.Log("HYPERRAUM", "Sprung in den Hyperraum – Ziel: " .. S.hyper.dest)
    h.maint = math.max(0, h.maint - 15)
    SetPhase("hyperspace")
end

-- Phasen-Ablauf
hook.Add("ShipTech_FastTick", "ShipTech_Hyper", function()
    local S = ShipTech.State
    local H = S.hyper
    local now = CurTime()
    if H.phase == "calc" and now >= H.t then
        SetPhase("ready")
        ShipTech.Chat("navy", "Kursberechnung abgeschlossen: " .. H.dest .. ". Energie zum Hyperantrieb umleiten.")
    elseif H.phase == "countdown" then
        local left = math.ceil(H.t - now)
        if left ~= H.last and left > 0 and (left <= 5 or left % 5 == 0) then
            H.last = left
            ShipTech.Chat("navy", "Hyperraumsprung in " .. left .. " ...")
        end
        if now >= H.t then DoJump() end
    elseif H.phase == "hyperspace" then
        local h = S.systems.hyperdrive
        if h.health <= 0 or not h.on then ExitHyperspace("Hyperantrieb ausgefallen", true) end
    end
end)

-- Vorbereitung (Kurs, Energie) nur am Kontrollterminal
local function NeedBridge(ply, ent)
    if ent.ConsoleKind ~= "terminal" then
        Deny(ply, "Die Sprungvorbereitung erfolgt am Brücken-Kontrollterminal.")
        return false
    end
    if not ShipTech.IsNavy(ply) then
        Deny(ply, "Nur Navy-Personal kann den Hyperraumsprung vorbereiten.")
        return false
    end
    return true
end

-- Sprung, Rücksturz und Abbruch des Countdowns nur an der Navigationsstation
local function NeedNav(ply, ent)
    if ent.ConsoleKind ~= "nav" then
        Deny(ply, "Gesprungen wird nur an der Navigationsstation.")
        return false
    end
    if not ShipTech.IsNavy(ply) then
        Deny(ply, "Nur Navy-Personal kann den Hyperraumsprung auslösen.")
        return false
    end
    return true
end

Actions.hyper_calc = function(ply, ent, a)
    if not NeedBridge(ply, ent) then return end
    local S = ShipTech.State
    if S.hyper.phase ~= "idle" then return Deny(ply, "Es läuft bereits ein Sprungablauf.") end
    local sens = S.systems.sensors
    if (sens.eff or 0) < C.Hyper.MinSensors then return Deny(ply, "Sensoren zu schwach für eine Kursberechnung (" .. math.Round((sens.eff or 0) * 100) .. " %).") end
    local dest = string.Trim(string.sub(tostring(a.dest or ""), 1, 60))
    if dest == "" then return Deny(ply, "Bitte ein Ziel eingeben.") end
    ShipTech.StartMinigame(ply, ent, "sequence", "Navigationscomputer: " .. dest, 2, function(ok)
        if not ok then return Deny(ply, "Kursberechnung fehlgeschlagen – erneut versuchen.") end
        if ShipTech.State.hyper.phase ~= "idle" then return end
        local t = C.Hyper.CalcTime / math.max(0.4, math.min(1, sens.eff or 0.4))
        ShipTech.State.hyper.dest = dest
        SetPhase("calc", CurTime() + t)
        ShipTech.Chat("navy", "Navigationscomputer berechnet Kurs nach " .. dest .. " (" .. math.ceil(t) .. " s).")
        ShipTech.Log("HYPERRAUM", "Kursberechnung gestartet: " .. dest, ply)
    end)
end

Actions.hyper_route = function(ply, ent)
    if not NeedBridge(ply, ent) then return end
    local S = ShipTech.State
    if S.hyper.phase ~= "ready" then return Deny(ply, "Zuerst einen Kurs berechnen.") end
    local h = S.systems.hyperdrive
    if h.alloc < C.Hyper.MinAlloc then
        -- Energie automatisch von Geschützen und Schilden umleiten
        local need = C.Hyper.MinAlloc - h.alloc
        for _, id in ipairs({ "weapons", "shields", "engines", "sensors" }) do
            local s = S.systems[id]
            local take = math.min(need, math.max(0, s.alloc - 5))
            s.alloc = s.alloc - take
            h.alloc = h.alloc + take
            need = need - take
            if need <= 0 then break end
        end
        if h.alloc < C.Hyper.MinAlloc then return Deny(ply, "Nicht genug Energie verfügbar, um den Hyperantrieb zu versorgen.") end
    end
    SetPhase("routed")
    ShipTech.Chat("navy", "Energie zum Hyperantrieb umgeleitet (" .. h.alloc .. " E). Bereit zum Sprung.")
    ShipTech.Log("HYPERRAUM", "Energie umgeleitet", ply)
end

Actions.hyper_jump = function(ply, ent, a)
    if not NeedNav(ply, ent) then return end
    local S = ShipTech.State
    if S.hyper.phase ~= "routed" then return Deny(ply, "Kurs berechnen und Energie umleiten, bevor gesprungen werden kann.") end
    local problems = JumpProblems()
    if #problems > 0 then return Deny(ply, "Sprung nicht möglich: " .. table.concat(problems, ", ")) end
    local allowed, why = hook.Run("ShipTech_CanJump", ply, a and a.force)
    if allowed == false then return Deny(ply, why or "Sprung derzeit gesperrt.") end
    if a and a.force then ShipTech.Log("HYPERRAUM", "NOTSPRUNG angeordnet", ply) end
    S.hyper.last = nil
    SetPhase("countdown", CurTime() + C.Hyper.Countdown)
    ShipTech.Chat("navy", "Hyperraumsprung eingeleitet – alle Mann festhalten! Sprung in " .. C.Hyper.Countdown .. " Sekunden.")
    ShipTech.Log("HYPERRAUM", "Sprung eingeleitet: " .. S.hyper.dest, ply)
end

Actions.hyper_abort = function(ply, ent)
    if ent.ConsoleKind ~= "nav" and ent.ConsoleKind ~= "terminal" then return end
    if not ShipTech.IsNavy(ply) then return Deny(ply, "Keine Berechtigung.") end
    local S = ShipTech.State
    if S.hyper.phase == "idle" or S.hyper.phase == "hyperspace" then return end
    SetPhase("idle")
    ShipTech.Chat("navy", "Sprungablauf abgebrochen.")
    ShipTech.Log("HYPERRAUM", "Sprungablauf abgebrochen", ply)
end

Actions.hyper_exit = function(ply, ent)
    if not NeedNav(ply, ent) then return end
    if ShipTech.State.hyper.phase ~= "hyperspace" then return end
    ExitHyperspace()
end

---------------------------------------------------------------------------
-- SZENARIEN & ZEITGESTEUERTE ABLÄUFE
---------------------------------------------------------------------------
local seqId = 0

local function SeqTimer(id, i) return "ShipTech_Seq_" .. id .. "_" .. i end

function ShipTech.CancelSequence(id)
    local S = ShipTech.State
    for i, q in ipairs(S.sequences) do
        if q.id == id then
            for k = 1, q.total do timer.Remove(SeqTimer(id, k)) end
            table.remove(S.sequences, i)
            ShipTech.MarkDirty()
            return true
        end
    end
    return false
end

function ShipTech.CancelAllSequences()
    for k = 1, seqId do
        for i = 1, 40 do timer.Remove(SeqTimer(k, i)) end
    end
    if ShipTech.State then ShipTech.State.sequences = {} end
end

local function RandomSector()
    local list = ShipTech.State.sectorList
    return #list > 0 and list[math.random(#list)] or nil
end

-- steps: { {sekunden, aktion, werte}, ... }
function ShipTech.RunSequence(name, steps, ply)
    local E = ShipTech.EventActions
    if #steps == 0 then return end
    seqId = seqId + 1
    local id = seqId
    local S = ShipTech.State
    local last = 0
    for _, st in ipairs(steps) do last = math.max(last, st[1]) end
    local q = { id = id, name = name, total = #steps, done = 0, ends = CurTime() + last, by = Nick(ply) }
    table.insert(S.sequences, q)

    for i, st in ipairs(steps) do
        local delay, act, args = st[1], st[2], table.Copy(st[3] or {})
        timer.Create(SeqTimer(id, i), math.max(0.05, delay), 1, function()
            local cur = ShipTech.State
            if not cur then return end
            if args.sector == "*" then args.sector = RandomSector() end
            local fn = E[act]
            if fn and not (act == "outage" and not args.sector) then
                ShipTech.SuppressAutoOrder = true
                local ok, err = pcall(fn, ply, args)
                ShipTech.SuppressAutoOrder = false
                if not ok then ErrorNoHalt("[ShipTech] Ablauf-Fehler (" .. act .. "): " .. tostring(err) .. "\n") end
            end
            for k, qq in ipairs(cur.sequences) do
                if qq.id == id then
                    qq.done = qq.done + 1
                    if qq.done >= qq.total then
                        table.remove(cur.sequences, k)
                        ShipTech.Log("EVENT", "Ablauf '" .. name .. "' abgeschlossen")
                    end
                    break
                end
            end
            ShipTech.MarkDirty()
        end)
    end
    ShipTech.Log("EVENT", "Ablauf gestartet: " .. name .. " (" .. #steps .. " Schritte)", ply)
    ShipTech.MarkDirty()
    return id
end

---------------------------------------------------------------------------
-- WERKZEUG & FEUERLÖSCHER AUSTEILEN
---------------------------------------------------------------------------
-- Techniker nach Job (ohne Admin-Sonderrecht) – nur sie bekommen bzw. behalten Datapad und Feuerlöscher
function ShipTech.IsTechJob(ply)
    if not IsValid(ply) then return false end
    local name = team.GetName(ply:Team()) or ""
    if C.TechnicianTeams[name] then return true end
    local lower = string.lower(name)
    for _, p in ipairs(C.TechnicianTeamPatterns or {}) do
        if p ~= "" and string.find(lower, string.lower(p), 1, true) then return true end
    end
    return false
end

local function IsTechTool(class)
    return class == C.Tool.Class or class == C.Extinguisher.Class
end

local function CheckTools(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if ShipTech.IsTechJob(ply) then
        if C.Tool.GiveOnSpawn and not ply:HasWeapon(C.Tool.Class) then ply:Give(C.Tool.Class) end
        if C.Extinguisher.GiveOnSpawn and not ply:HasWeapon(C.Extinguisher.Class) then ply:Give(C.Extinguisher.Class) end
    elseif not ShipTech.IsAdmin(ply) then
        if ply:HasWeapon(C.Tool.Class) then ply:StripWeapon(C.Tool.Class) end
        if ply:HasWeapon(C.Extinguisher.Class) then ply:StripWeapon(C.Extinguisher.Class) end
    end
end

hook.Add("PlayerLoadout", "ShipTech_Tools", function(ply)
    timer.Simple(0.5, function() CheckTools(ply) end)
end)

-- Jobwechsel (DarkRP & andere Gamemodes)
hook.Add("OnPlayerChangedTeam", "ShipTech_Tools", function(ply)
    timer.Simple(0.5, function() CheckTools(ply) end)
end)

-- Nicht-Techniker können Datapad und Feuerlöscher weder aufheben noch bekommen
hook.Add("PlayerCanPickupWeapon", "ShipTech_Tools", function(ply, wep)
    if IsValid(wep) and IsTechTool(wep:GetClass()) and not ShipTech.IsTechJob(ply) and not ShipTech.IsAdmin(ply) then
        return false
    end
end)

---------------------------------------------------------------------------
-- FAHRZEUG-ADDONS (LVS / LFS / Turrets)
---------------------------------------------------------------------------
local function InSet(set, ent)
    return IsValid(ent) and set and set[ent:GetClass()] == true
end

local function FindGun(dmg)
    local list = C.Vehicles.GunClasses
    if not list or next(list) == nil then return nil end
    local candidates = { dmg:GetInflictor(), dmg:GetAttacker() }
    local att = dmg:GetAttacker()
    if IsValid(att) and att:IsPlayer() and IsValid(att:GetVehicle()) then
        candidates[#candidates + 1] = att:GetVehicle()
    end
    for _, e in ipairs(candidates) do
        local cur, depth = e, 0
        while IsValid(cur) and depth < 4 do
            if InSet(list, cur) then return cur end
            local owner = cur:GetOwner()
            cur = IsValid(cur:GetParent()) and cur:GetParent() or owner
            depth = depth + 1
        end
    end
end

local nextGunMsg = {}

hook.Add("EntityTakeDamage", "ShipTech_Vehicles", function(target, dmg)
    if not C.Vehicles.Enabled or not ShipTech.State then return end
    local S = ShipTech.State

    -- Schiffsgeschütze: Schaden hängt von Feuerbereitschaft & Zielgenauigkeit ab
    local gun = FindGun(dmg)
    if gun then
        local mods = S.mods or {}
        local ready = (mods.weapons or 0) / 100
        if ready <= 0 then
            dmg:SetDamage(0)
            local att = dmg:GetAttacker()
            if IsValid(att) and att:IsPlayer() and (nextGunMsg[att] or 0) < CurTime() then
                nextGunMsg[att] = CurTime() + 5
                Deny(att, "Schiffsgeschütze ohne Energie oder ausgefallen!")
            end
            return
        end
        if math.random() < (1 - (mods.accuracy or 0) / 100) * 0.5 then
            dmg:SetDamage(0) -- Fehlschuss durch schlechte Kalibrierung
            return
        end
        dmg:ScaleDamage(ready)
    end

    -- Schiffs-Entities: Schaden geht zuerst auf die Schilde
    if InSet(C.Vehicles.ShipClasses, target) then
        local scale = C.Vehicles.ShieldDamageScale
        if scale <= 0 then return end
        local pos = dmg:GetDamagePosition()
        if pos == vector_origin and IsValid(dmg:GetAttacker()) then pos = dmg:GetAttacker():GetPos() end
        local lp = target:WorldToLocal(pos)
        local sector
        if math.abs(lp.x) >= math.abs(lp.y) then
            sector = lp.x >= 0 and 1 or 3          -- Bug / Heck
        else
            sector = lp.y < 0 and 2 or 4           -- Steuerbord / Backbord (Source: +y = links)
        end
        local overflow = ShipTech.DamageShields(dmg:GetDamage() * scale, sector)
        dmg:SetDamage(overflow / scale)
    end
end)

-- Höchstgeschwindigkeit der Schiffs-Entities an die Triebwerke koppeln
hook.Add("ShipTech_FastTick", "ShipTech_VehicleSpeed", function()
    if not C.Vehicles.Enabled or not C.Vehicles.ScaleSpeed then return end
    local list = C.Vehicles.ShipClasses
    if not list or next(list) == nil then return end
    local f = math.Clamp(((ShipTech.State.mods and ShipTech.State.mods.speed) or 0) / 100, 0.05, 1.2)
    for class in pairs(list) do
        for _, e in ipairs(ents.FindByClass(class)) do
            if e.MaxVelocity then
                e.ST_BaseVelocity = e.ST_BaseVelocity or e.MaxVelocity
                e.MaxVelocity = e.ST_BaseVelocity * f
            end
        end
    end
end)

---------------------------------------------------------------------------
-- INGAME-KONFIGURATION
---------------------------------------------------------------------------
ShipTech.ConfigOverrides = ShipTech.ConfigOverrides or {}
-- dynamisch, damit Erweiterungen (z. B. EVA) eigene Einstellungen ergänzen können
local SchemaByKey = setmetatable({}, { __index = function(_, key)
    for _, e in ipairs(ShipTech.ConfigSchema) do
        if e.key == key then return e end
    end
end })

local function SaveOverrides()
    file.Write("shiptech/config.json", util.TableToJSON(ShipTech.ConfigOverrides, true))
end

function ShipTech.SendConfig(target)
    net.Start("ShipTech_ConfigSync")
    net.WriteString(util.TableToJSON(ShipTech.ConfigOverrides))
    if target then net.Send(target) else net.Broadcast() end
end

local function AfterChange(key)
    if key == "FastTick" or key == "SlowTick" then ShipTech.StartTimers() end
end

local function LoadOverrides()
ShipTech.ReloadConfigOverrides = LoadOverrides
    local raw = file.Read("shiptech/config.json", "DATA")
    ShipTech.ConfigOverrides = (raw and util.JSONToTable(raw)) or {}
    for k, v in pairs(ShipTech.ConfigOverrides) do
        if SchemaByKey[k] then ShipTech.SetConfigValue(k, v) end
    end
    ShipTech.StartTimers()
end
LoadOverrides()
ShipTech.ReloadConfigOverrides = LoadOverrides

local function Validate(entry, value)
    if entry.type == "bool" then return value and true or false end
    if entry.type == "number" then
        local n = tonumber(value)
        if not n then return nil end
        return math.Clamp(n, entry.min or -math.huge, entry.max or math.huge)
    end
    if entry.type == "set" then
        local set = {}
        for _, part in ipairs(string.Explode(",", tostring(value))) do
            part = string.Trim(part)
            if part ~= "" then set[part] = true end
        end
        return set
    end
    if entry.type == "list" then
        local list = {}
        for _, part in ipairs(string.Explode(",", tostring(value))) do
            part = string.Trim(part)
            if part ~= "" then list[#list + 1] = part end
        end
        return list
    end
    if entry.type == "model" then
        local m = string.Trim(tostring(value))
        if not string.match(m, "^models/.+%.mdl$") then return nil end
        return m
    end
end

net.Receive("ShipTech_ConfigSet", function(_, ply)
    if not ply:IsSuperAdmin() then return end
    local key = net.ReadString()
    local reset = net.ReadBool()
    local raw = net.ReadString()
    local entry = SchemaByKey[key]
    if not entry then return end

    if reset then
        ShipTech.ConfigOverrides[key] = nil
        local def = ShipTech.ConfigDefaults[key]
        if def ~= nil then ShipTech.SetConfigValue(key, istable(def) and table.Copy(def) or def) end
        ShipTech.Log("KONFIG", entry.label .. " auf Standard zurückgesetzt", ply)
    else
        local parsed = util.JSONToTable(raw)
        local input = raw
        if parsed then input = parsed.v end
        local value = Validate(entry, input)
        if value == nil then return Deny(ply, "Ungültiger Wert für " .. entry.label) end
        ShipTech.SetConfigValue(key, value)
        ShipTech.ConfigOverrides[key] = value
        ShipTech.Log("KONFIG", entry.label .. " geändert", ply)
    end
    SaveOverrides()
    AfterChange(key)
    ShipTech.SendConfig()
    Ok(ply, "Einstellung gespeichert: " .. entry.label)
end)

local function OpenAdmin(ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then return Deny(ply, "Nur Superadmins können die Konfiguration ändern.") end
    ShipTech.SendConfig(ply)
    net.Start("ShipTech_OpenAdmin")
    net.Send(ply)
end
concommand.Add("shiptech_admin", OpenAdmin)

hook.Add("PlayerSay", "ShipTech_AdminCmd", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!shiptechadmin" or t == "/shiptechadmin" then
        OpenAdmin(ply)
        return ""
    end
end)

hook.Add("PlayerInitialSpawn", "ShipTech_ConfigSync", function(ply)
    timer.Simple(2, function() if IsValid(ply) then ShipTech.SendConfig(ply) end end)
end)

---------------------------------------------------------------------------
-- Zusätzliche Event-Aktionen
---------------------------------------------------------------------------
local E = ShipTech.EventActions

E.fire = function(ply, a)
    if a.sys == "*" or not a.sys then
        local def = ShipTech.Systems[math.random(#ShipTech.Systems)]
        a.sys = def.id
    end
    if not Def(a.sys) then return end
    local list = ShipTech.ConsoleList("system", a.sys)
    if #list == 0 then return IsValid(ply) and Deny(ply, "Keine Konsole für " .. Def(a.sys).name .. " platziert.") end
    ShipTech.Ignite(list[math.random(#list)], "Ereignis")
    ShipTech.Log("EVENT", "Brand ausgelöst: " .. Def(a.sys).name, ply)
end

E.extinguish_all = function(ply)
    ShipTech.ExtinguishAll()
    ShipTech.Chat("info", "Alle Brände wurden gelöscht.")
    ShipTech.Log("EVENT", "Alle Brände gelöscht", ply)
end

E.hyper_fail = function(ply)
    hyperFailNext = true
    ShipTech.Log("EVENT", "Nächster Hyperraumsprung wird fehlschlagen", ply)
end

E.hyper_exit = function(ply)
    if ShipTech.State.hyper.phase == "hyperspace" then ExitHyperspace("Ereignis", true) else SetPhase("idle") end
end

E.scenario = function(ply, a)
    local sc = ShipTech.Scenarios[tonumber(a.index) or 0]
    if not sc then return end
    ShipTech.Chat("event", "Szenario gestartet: " .. sc.name)
    ShipTech.RunSequence(sc.name, sc.steps, ply)
end

-- erlaubte Ablauf-Aktionen (zur Laufzeit ermittelt, damit Erweiterungen eigene ergänzen können)
local allowed = setmetatable({}, { __index = function(_, id)
    for _, sa in ipairs(ShipTech.SequenceActions) do
        if sa.id == id then return sa end
    end
end })

E.sequence_run = function(ply, a)
    if not istable(a.steps) then return end
    local steps = {}
    for i, st in ipairs(a.steps) do
        if i > 30 then break end
        local act = tostring(st.action or "")
        if allowed[act] then
            local args = { sys = st.sys, stage = tonumber(st.stage), order = st.order and true or nil }
            if act == "outage" then args.sector = "*" end
            if act == "hit" then args.sector, args.amount, args.count = 0, 30, 5 end
            if act == "combat" then args.on = true end
            steps[#steps + 1] = { math.Clamp(tonumber(st.delay) or 0, 0, 3600), act, args }
        end
    end
    if #steps == 0 then return Deny(ply, "Der Ablauf enthält keine gültigen Schritte.") end
    local name = string.sub(string.Trim(tostring(a.name or "")), 1, 40)
    ShipTech.RunSequence(name ~= "" and name or "Eigener Ablauf", steps, ply)
    Ok(ply, "Ablauf gestartet (" .. #steps .. " Schritte).")
end

E.sequence_cancel = function(ply, a)
    if ShipTech.CancelSequence(tonumber(a.id) or -1) then
        ShipTech.Log("EVENT", "Ablauf abgebrochen", ply)
    end
end

---------------------------------------------------------------------------
-- BELEUCHTUNG: Licht aus bei Stromausfall, Flackern bei Treffern (SSE Lightswitch)
---------------------------------------------------------------------------
local lightsOffByUs = false
local nextLightFlicker = 0

local function SetLights(state)
    if SSE and SSE.SetLights then
        SSE.SetLights(state)
        return
    end
    if not C.Lights.Fallback then return end
    for _, cls in ipairs({ "light", "light_spot", "light_dynamic" }) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            e:Fire(state and "TurnOn" or "TurnOff")
        end
    end
end

local function LightsAreOn()
    if SSE and SSE.GetLights then return SSE.GetLights() ~= false end
    return not lightsOffByUs
end

local function ShouldBeDark(S)
    if not C.Lights.Enabled then return false end
    if C.Lights.OffOnBlackout and (S.supply.output or 0) <= 0 then return true end
    if C.Lights.OffOnGridFailure and S.systems.power.health <= 0 then return true end
    return false
end

function ShipTech.FlickerLights()
    if not C.Lights.Enabled or not C.Lights.Flicker or lightsOffByUs then return end
    if CurTime() < nextLightFlicker or not LightsAreOn() then return end
    nextLightFlicker = CurTime() + C.Lights.FlickerCooldown
    -- nur die Lampen kurz schalten – KEIN Lightmap-Neuladen (das verursacht Blitze und Ruckler)
    local lamps = {}
    for _, cls in ipairs({ "light", "light_spot", "light_dynamic" }) do
        for _, e in ipairs(ents.FindByClass(cls)) do lamps[#lamps + 1] = e end
    end
    if #lamps == 0 then return end
    for _, e in ipairs(lamps) do e:Fire("TurnOff") end
    timer.Simple(0.25, function()
        if lightsOffByUs then return end
        for _, e in ipairs(lamps) do
            if IsValid(e) then e:Fire("TurnOn") end
        end
    end)
end

hook.Add("ShipTech_FastTick", "ShipTech_Lights", function()
    local dark = ShouldBeDark(ShipTech.State)
    if dark and not lightsOffByUs then
        lightsOffByUs = true
        if LightsAreOn() then SetLights(false) end
        ShipTech.Chat("crit", "Beleuchtung ausgefallen – keine Energie für das Lichtnetz!")
        ShipTech.Log("ENERGIE", "Beleuchtung ausgefallen")
    elseif not dark and lightsOffByUs then
        lightsOffByUs = false
        SetLights(true)
        ShipTech.Chat("info", "Beleuchtung wiederhergestellt.")
        ShipTech.Log("ENERGIE", "Beleuchtung wiederhergestellt")
    end
end)

-- Lightswitch kann das Licht ohne Energie nicht einschalten
hook.Add("SSE_CanTurnLightsOn", "ShipTech_Lights", function(ply)
    if lightsOffByUs then
        if IsValid(ply) then Deny(ply, "Keine Energie für die Beleuchtung – Reaktor oder Energienetz reparieren.") end
        return false
    end
end)

hook.Add("ShipTech_ShieldHit", "ShipTech_LightsFlicker", function(_, _, overflow)
    if overflow and overflow > 0 then ShipTech.FlickerLights() end
end)
