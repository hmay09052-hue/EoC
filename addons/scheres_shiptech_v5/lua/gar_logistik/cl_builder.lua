-- GAR-Datapad (Feldbasis-Teil): Bauplanung, Hologramm-Platzierung, HUD-Hinweise, FOB-Radius

local cfg = GARLog.Config
local UI = GARLog.UI
local C = UI.C

GARLog.Builder = GARLog.Builder or {}
local B = GARLog.Builder

local function Can(perm) return GARLog.LocalCan(perm) end

local function HoldingBuilder()
    local lp = LocalPlayer()
    if not IsValid(lp) then return false end
    return GARLog.IsTool(lp:GetActiveWeapon())
end
B.Holding = HoldingBuilder

-- Lagerdaten (für Bauvorschau & FOB-Grenzen) nur abonnieren, solange das Datapad in der Hand ist
-- (20 s Nachlauf, damit schneller Waffenwechsel keine kompletten Neu-Syncs auslöst)
local lastHold = -100
timer.Create("GARLog_BuilderSub", 0.5, 0, function()
    local holding = HoldingBuilder()
    if holding then lastHold = CurTime() end
    GARLog.SetSubscribed("tool", holding or CurTime() - lastHold < 20)
    if not holding and B.Ghost then B.Cancel() end
end)

---------------------------------------------------------------------------
-- Prüfungen (Client-Vorschau, der Server prüft verbindlich)
---------------------------------------------------------------------------
function B.Context()
    local fob = GARLog.FOBAtPos(LocalPlayer():GetPos())
    local loc = fob and GARLog.Loc("fob_" .. fob.id)
    return fob, loc
end

function B.Check(def, fob, loc)
    if def.sse and not GARLog.ClassInstalled(def.class) then return false, "NICHT INSTALLIERT" end
    if def.core and not fob then
        if not Can("build.found") then return false, "KEINE BERECHTIGUNG" end
        if #GARLog.FOBList() >= cfg.FOB.MaxFOBs then return false, "MAX. FELDBASEN" end
        return true, "FELDBASIS GRÜNDEN"
    end
    if not fob then return false, "KEINE FELDBASIS" end
    if not Can("build") then return false, "KEINE BERECHTIGUNG" end
    if not loc then return false, "DATEN LADEN..." end
    local cnt = ((loc.f or {}).cnt or {})[def.key] or 0
    if cnt >= (def.max or 99) then return false, "MAXIMUM ERREICHT" end
    for res, n in pairs(def.cost or {}) do
        if (loc.s[res] or 0) < n then return false, "MATERIAL FEHLT" end
    end
    return true
end

local function hullFilter(e)
    return not (e:IsPlayer() or e:IsNPC() or e:IsWeapon())
end

function B.Validate(g, tr)
    if not tr.Hit or tr.HitSky then return false, "KEIN UNTERGRUND IN REICHWEITE" end
    local minZ = math.cos(math.rad(cfg.FOB.MaxSlope))
    if tr.HitNormal.z < minZ then return false, "UNTERGRUND ZU STEIL" end

    local mi, ma = g.mi, g.ma
    local r = math.max(-mi.x, -mi.y, ma.x, ma.y) * 0.6
    local slopeLift = r * math.tan(math.acos(math.Clamp(tr.HitNormal.z, minZ, 1)))
    local h = ma.z - mi.z
    local lift = math.min(6 + slopeLift, h * 0.5)
    local base = tr.HitPos + Vector(0, 0, lift)
    local hull = util.TraceHull({
        start = base, endpos = base + Vector(0, 0, 1),
        mins = Vector(-r, -r, 0), maxs = Vector(r, r, math.max(h - lift - 4, 8)),
        mask = MASK_SOLID, filter = hullFilter,
    })
    if hull.StartSolid or hull.Hit then return false, "BAUPLATZ BLOCKIERT" end

    local fob, loc = GARLog.FOBAtPos(tr.HitPos), nil
    if fob then loc = GARLog.Loc("fob_" .. fob.id) end
    if g.def.core and not fob then
        for _, o in ipairs(GARLog.FOBList()) do
            if o.pos:DistToSqr(tr.HitPos) < cfg.FOB.MinDistance ^ 2 then return false, "ZU NAH AN " .. string.upper(o.name) end
        end
        local ok, why = B.Check(g.def, nil, nil)
        if not ok then return false, why end
        return true, "NEUE FELDBASIS: " .. string.upper(g.name or "")
    end
    if not fob then return false, "AUSSERHALB DER FELDBASIS" end
    local ok, why = B.Check(g.def, fob, loc)
    if not ok then return false, why end
    return true, "BEREIT – " .. string.upper(fob.name)
end

---------------------------------------------------------------------------
-- Hologramm
---------------------------------------------------------------------------
function B.Cancel()
    local g = B.Ghost
    if g and IsValid(g.ent) then g.ent:Remove() end
    B.Ghost = nil
end

function B.StartGhost(key, name)
    local def = GARLog.BuildDefs[key]
    if not def then return end
    B.Cancel()
    local ent = ClientsideModel(GARLog.DefModel(def), RENDERGROUP_TRANSLUCENT)
    if not IsValid(ent) then return end
    ent:SetNoDraw(true)
    local mi, ma = ent:GetModelBounds()
    B.Ghost = { key = key, def = def, ent = ent, yaw = 0, name = name, mi = mi, ma = ma, valid = false, reason = "", nextCheck = 0 }
    if IsValid(GARLog.Menu.Frame) then GARLog.Menu.Frame:Close() end
end

function B.Select(key)
    local def = GARLog.BuildDefs[key]
    if not def then return end
    local fob, loc = B.Context()
    local ok, why = B.Check(def, fob, loc)
    if not ok then
        UI.ErrorSound()
        chat.AddText(C.yellow, cfg.ChatTag .. " ", C.red, def.name .. ": " .. (why or "nicht möglich"))
        return
    end
    if def.core and not fob then
        UI.Prompt("FELDBASIS GRÜNDEN", "Name der neuen Feldbasis (z.B. FOB Aurek):", "Name", "FOB ", function(v)
            B.StartGhost(key, v)
        end, cfg.FOB.NameLength)
        return
    end
    B.StartGhost(key)
end

function B.Place()
    local g = B.Ghost
    if not g then return end
    if not g.valid or not g.ground then
        UI.ErrorSound()
        return
    end
    GARLog.Action("build.place", {
        key = g.key, x = g.ground.x, y = g.ground.y, z = g.ground.z, yaw = g.ang.y, name = g.name,
    })
    -- Shift halten = weiteres Exemplar platzieren
    if not input.IsKeyDown(KEY_LSHIFT) or g.def.core then B.Cancel() else g.nextCheck = CurTime() + 0.5 end
end

hook.Add("Think", "GARLog_Ghost", function()
    local g = B.Ghost
    if not g then return end
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then B.Cancel() return end
    local eye = lp:EyePos()
    local tr = util.TraceLine({ start = eye, endpos = eye + lp:GetAimVector() * cfg.FOB.BuildRange, filter = lp, mask = MASK_SOLID_BRUSHONLY })
    g.ground = tr.HitPos
    g.ang = Angle(0, math.NormalizeAngle(lp:EyeAngles().y + 180 + g.yaw), 0)
    g.pos = tr.HitPos + Vector(0, 0, -g.mi.z + 1)
    if CurTime() >= g.nextCheck then
        g.nextCheck = CurTime() + 0.1
        g.valid, g.reason = B.Validate(g, tr)
    end
end)

hook.Add("PlayerBindPress", "GARLog_Ghost", function(_, bind, pressed)
    local g = B.Ghost
    if not g or not pressed then return end
    if bind:find("+attack2", 1, true) then
        B.Cancel()
        UI.Click()
        return true
    end
    if bind:find("+attack", 1, true) then
        B.Place()
        return true
    end
    if bind:find("+reload", 1, true) then
        g.yaw = g.yaw + (input.IsKeyDown(KEY_LSHIFT) and -15 or 15)
        return true
    end
    if bind:find("invnext", 1, true) then g.yaw = g.yaw - 5 return true end
    if bind:find("invprev", 1, true) then g.yaw = g.yaw + 5 return true end
end)

local ringMat = Material("trails/laser")
local ringCol = Color(252, 178, 73, 160)
local RING_SEG = 48

local function DrawRing(center, radius)
    render.SetMaterial(ringMat)
    render.StartBeam(RING_SEG + 1)
    for i = 0, RING_SEG do
        local a = i / RING_SEG * math.pi * 2
        render.AddBeam(center + Vector(math.cos(a) * radius, math.sin(a) * radius, 10), 8, i / 4, ringCol)
    end
    render.EndBeam()
end

hook.Add("PostDrawTranslucentRenderables", "GARLog_Ghost", function(depth, sky)
    if depth or sky then return end
    local g = B.Ghost
    if not g and not HoldingBuilder() then return end
    if g and IsValid(g.ent) and g.pos then
        g.ent:SetPos(g.pos)
        g.ent:SetAngles(g.ang)
        local col = g.valid and C.green or C.red
        render.SetColorModulation(col.r / 255, col.g / 255, col.b / 255)
        render.SetBlend(0.45)
        g.ent:DrawModel()
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
    end

    -- FOB-Grenzen anzeigen, solange das Datapad aktiv ist
    if g or HoldingBuilder() then
        local lp = LocalPlayer()
        for _, f in ipairs(GARLog.FOBList()) do
            if lp:GetPos():DistToSqr(f.pos) < (f.r + 2500) ^ 2 then DrawRing(f.pos, f.r) end
        end
    end
end)

---------------------------------------------------------------------------
-- HUD des Datapads (kontextabhängige Hinweise)
---------------------------------------------------------------------------
local function HintBox(lines, accent, bottom)
    local w = 0
    for _, l in ipairs(lines) do
        surface.SetFont(l[3] or "GARLog_Section")
        w = math.max(w, surface.GetTextSize(l[1]))
    end
    w = w + 40
    local h = #lines * 22 + 16
    local x, y = ScrW() / 2 - w / 2, (bottom or (ScrH() - 150)) - h
    surface.SetDrawColor(C.bg)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(C.line)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(accent or C.yellow)
    surface.DrawRect(x, y, w, 2)
    for i, l in ipairs(lines) do
        draw.SimpleText(l[1], l[3] or "GARLog_Section", ScrW() / 2, y + 8 + (i - 1) * 22 + 11, l[2] or C.text, 1, 1)
    end
end

-- Schiff / Fahrzeug im Visier (gleiche Reichweite wie das Fusion-Cutter-Protokoll), 10x pro Sekunde geprüft
local aimNext, aimEnt = 0, nil
local function AimedVehicle(lp)
    local now = CurTime()
    if now < aimNext then return IsValid(aimEnt) and aimEnt or nil end
    aimNext, aimEnt = now + 0.1, nil
    if FCR and FCR.Util and FCR.Config then
        local fc = FCR.Config
        local tr = FCR.Util.GetTargetTrace(lp, (fc.RepairDistance or 210) + (fc.RepairRangeGrace or 0))
        local ent = FCR.Util.ResolveRepairEntity(tr.Entity)
        if FCR.Util.IsSupportedVehicle(ent) then aimEnt = ent end
    else
        local tr = lp:GetEyeTrace()
        local ent = tr.Entity
        if IsValid(ent) and GARLog.IsVehicle(ent) and tr.HitPos:DistToSqr(lp:GetShootPos()) <= cfg.FOB.WorkRange ^ 2 then aimEnt = ent end
    end
    return aimEnt
end

function B.DrawHUD()
    local g = B.Ghost
    if g then
        local lines = {
            { "PLATZIEREN: " .. string.upper(g.def.name), C.white, "GARLog_Head" },
            { g.reason or "", g.valid and C.green or C.red },
        }
        if g.def.cost and next(g.def.cost) and not (g.def.core and g.valid and g.reason and g.reason:find("NEUE", 1, true)) then
            lines[#lines + 1] = { "KOSTEN: " .. GARLog.ItemsText(g.def.cost) .. "   //   BAUZEIT " .. GARLog.FmtTime(g.def.time or 0), C.soft }
        end
        lines[#lines + 1] = { "LMB PLATZIEREN   ·   RMB ABBRECHEN   ·   R / MAUSRAD DREHEN   ·   SHIFT+LMB MEHRERE", C.muted, "GARLog_Tiny" }
        HintBox(lines, g.valid and C.green or C.red)
        return
    end

    local lp = LocalPlayer()

    -- Schiffe & Fahrzeuge
    local veh = AimedVehicle(lp)
    if veh then
        local hp, max = GARLog.VehicleHealth(veh)
        if max > 0 and hp < max then
            local fcrHud = FCR and FCR.Config and FCR.Config.HUD and FCR.Config.HUD.Enabled
            local cost = math.ceil((max - hp) * cfg.VehicleRepair.CostPerHP)
            local lines = {}
            if not fcrHud then
                lines[#lines + 1] = { GARLog.VehicleLabel(veh) .. "  –  " .. math.floor(hp / max * 100) .. "%", C.orange, "GARLog_Head" }
            end
            if not Can("repair.vehicle") then
                lines[#lines + 1] = { "REPARATUR NUR DURCH TECHNIKER", C.red }
            elseif GARLog.FCRAvailable() and cfg.VehicleRepair.UseFCR ~= false then
                lines[#lines + 1] = { "LMB: FUSION-CUTTER-REPARATURPROTOKOLL STARTEN", C.yellow }
                if cost > 0 then lines[#lines + 1] = { "KOSTEN: " .. GARLog.FmtNum(cost) .. " TEC AUS DEM NÄCHSTEN LAGER", C.soft } end
            else
                lines[#lines + 1] = { "LMB HALTEN: REPARIEREN (AN EINER AKTIVEN TECHNIKERSTATION)", C.yellow }
            end
            local bottom
            if fcrHud then bottom = ScrH() - (FCR.Config.HUD.OffsetY or 118) - (FCR.Config.HUD.Height or 84) - 10 end
            HintBox(lines, C.orange, bottom)
            return
        end
    end

    local tr = lp:GetEyeTrace()
    local ent = tr.Entity
    local near = IsValid(ent) and tr.HitPos:DistToSqr(lp:GetShootPos()) <= cfg.FOB.WorkRange ^ 2
    if near and ent:GetClass() == "garlog_site" then
        HintBox({
            { "BAUSTELLE: " .. string.upper(ent:GetTitle()) .. "  –  " .. math.floor(ent:GetProgress() * 100) .. "%", C.cyan, "GARLog_Head" },
            { GARLog.HasRole(lp, "techniker") and "LMB HALTEN ZUM AUFBAUEN (TECHNIKER-BONUS AKTIV)" or "LMB HALTEN ZUM AUFBAUEN", C.soft },
            { "RMB: BAUSTELLE ABBRECHEN (MATERIAL ZURÜCK)", C.muted, "GARLog_Tiny" },
        }, C.cyan)
    elseif near and ent.GARLogStructure and ent:GetHP() < ent:GetMaxHP() then
        HintBox({
            { string.upper(ent:GetDef().name or "Struktur") .. "  –  " .. math.floor(ent:GetHP() / math.max(1, ent:GetMaxHP()) * 100) .. "%", ent:GetDestroyed() and C.red or C.orange, "GARLog_Head" },
            { "LMB HALTEN ZUM REPARIEREN (KOSTET ERSATZTEILE)", C.soft },
            { "RMB: ABBAUEN", C.muted, "GARLog_Tiny" },
        }, C.orange)
    else
        local y = ScrH() - 120
        if near and ent:GetNW2Int("GARLogFOB", 0) > 0 then
            local def = GARLog.BuildDefs[ent:GetNW2String("GARLogKey", "")]
            draw.SimpleTextOutlined(string.upper(def and def.name or "Struktur") .. "  –  RMB ZUM ABBAUEN", "GARLog_Section",
                ScrW() / 2, y - 22, C.soft, 1, 1, 1, Color(0, 0, 0, 200))
        end
        draw.SimpleTextOutlined("LMB: LOGISTIK   |   RMB: BAUPLANUNG   |   R: TECHNIK-TERMINAL   |   LMB HALTEN AUF BAUSTELLE: BAUEN", "GARLog_Section",
            ScrW() / 2, y, C.yellow, 1, 1, 1, Color(0, 0, 0, 200))
    end
end

---------------------------------------------------------------------------
-- Bauplanung (Tab der Feldbasis-App im Datapad)
---------------------------------------------------------------------------
local function CostLine(cost, loc)
    local parts = {}
    for _, res in ipairs(GARLog.ResOrder) do
        local n = (cost or {})[res]
        if n and n > 0 then parts[#parts + 1] = { GARLog.FmtNum(n) .. " " .. GARLog.Res[res].short, loc and (loc.s[res] or 0) >= n } end
    end
    return parts
end

function B.BuildCatalog(parent)
    local self = {}

    -- Statusleiste der aktuellen Feldbasis
    local strip = UI.Framed(parent)
    strip:Dock(TOP)
    strip:SetTall(64)
    strip:DockMargin(0, 0, 0, 10)
    local base = strip.Paint
    strip.Paint = function(s, w, h)
        base(s, w, h)
        local fob, loc = B.Context()
        if not fob then
            surface.SetDrawColor(C.orange)
            surface.DrawRect(0, 0, 2, h)
            draw.SimpleText("KEINE FELDBASIS IN REICHWEITE", "GARLog_Head", 14, 20, C.orange, 0, 1)
            draw.SimpleText("Errichte ein Versorgungslager, um eine neue Feldbasis zu gründen. Material kommt per Container / Shuttle.", "GARLog_Small", 14, 44, C.soft, 0, 1)
            return
        end
        surface.SetDrawColor(C.yellow)
        surface.DrawRect(0, 0, 2, h)
        local nw = draw.SimpleText(string.upper(fob.name), "GARLog_Head", 14, 20, C.white, 0, 1)
        local x = 14 + nw + 10
        x = x + UI.Tag(fob.pw and "STROM" or "KEIN STROM", x, 20, fob.pw and C.green or C.red) + 6
        x = x + UI.Tag(fob.an and "FUNK" or "KEIN FUNK", x, 20, fob.an and C.green or C.orange) + 6
        if loc and loc.f then UI.Tag(loc.f.sto .. " LAGER", x, 20, C.soft) end
        if not loc then
            draw.SimpleText("Lagerdaten werden geladen...", "GARLog_Small", 14, 44, C.muted, 0, 1)
            return
        end
        local tx = 14
        for _, res in ipairs({ "build", "tech", "med", "fuel", "ammo" }) do
            local r = GARLog.Res[res]
            local text = r.short .. " " .. GARLog.FmtNum(loc.s[res] or 0)
            surface.SetFont("GARLog_Section")
            local tw = surface.GetTextSize(text)
            surface.SetDrawColor(r.color)
            surface.DrawRect(tx, 38, 2, 14)
            draw.SimpleText(text, "GARLog_Section", tx + 8, 45, C.white, 0, 1)
            tx = tx + tw + 26
        end
    end

    -- Kategorien
    local cats = vgui.Create("DPanel", parent)
    cats:Dock(TOP)
    cats:SetTall(36)
    cats:DockMargin(0, 0, 0, 10)
    cats.Paint = nil

    local hint = UI.Label(parent, "Karte anklicken: Hologramm platzieren (R / Mausrad drehen). Danach mit dem Datapad auf der Baustelle LMB halten. Techniker bauen doppelt so schnell. Material wird beim Platzieren aus dem Versorgungslager abgezogen.", "GARLog_Small", C.muted)
    hint:Dock(BOTTOM)
    hint:DockMargin(0, 8, 0, 0)

    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    local grid = vgui.Create("DPanel", scroll)
    grid:Dock(TOP)
    grid.Paint = nil

    local catBtns = {}
    local function ShowCat(kind)
        for k, b in pairs(catBtns) do b.Active = k == kind end
        grid:Clear()
        local cards = {}
        for _, key in ipairs(GARLog.BuildOrder) do
            local def = GARLog.BuildDefs[key]
            if def.kind == kind and (not def.sse or GARLog.ClassInstalled(def.class)) then
                local card = vgui.Create("DButton", grid)
                card:SetText("")
                card.Paint = function(s, w, h)
                    local fob, loc = B.Context()
                    local ok, why = B.Check(def, fob, loc)
                    local hov = s:IsHovered() and ok
                    surface.SetDrawColor(hov and C.panel2 or C.panel)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(hov and ColorAlpha(C.yellow, 150) or C.line)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    surface.SetDrawColor(ok and C.yellow or C.muted)
                    surface.DrawRect(0, 0, 2, h)

                    draw.SimpleText(string.upper(def.name), "GARLog_Head", 12, 18, ok and C.white or C.soft, 0, 1)
                    local cnt = loc and ((loc.f or {}).cnt or {})[key] or 0
                    UI.Tag(cnt .. "/" .. (def.max or 99), w - 10, 18, C.soft, nil, true)

                    local y = 38
                    for _, line in ipairs(s.DescLines or {}) do
                        draw.SimpleText(line, "GARLog_Tiny", 12, y, C.muted, 0, 1)
                        y = y + 14
                    end

                    local x = 12
                    if def.core and not fob then
                        x = x + UI.Tag("KOSTENLOS (GRÜNDUNG)", x, h - 44, C.green) + 6
                    else
                        for _, p in ipairs(CostLine(def.cost, loc)) do
                            x = x + UI.Tag(p[1], x, h - 44, p[2] and C.green or C.red) + 6
                        end
                    end
                    x = 12
                    x = x + UI.Tag("BAUZEIT " .. GARLog.FmtTime(def.time or 0), x, h - 18, C.soft) + 6
                    if def.needsPower then x = x + UI.Tag("BRAUCHT STROM", x, h - 18, C.orange) + 6 end
                    if def.sse then UI.Tag("SSE", x, h - 18, C.blue) end
                    if not ok or why then UI.Tag(why or "", w - 10, h - 18, ok and C.green or C.red, nil, true) end
                end
                card.DoClick = function()
                    UI.Click()
                    B.Select(key)
                end
                card.PerformLayout = function(s, w)
                    local desc = def.desc or (def.sse and ("SSE-Ausstattung für die Feldbasis" .. (GARLog.Config.SSEConsume[def.class] and " – verbraucht Vorräte aus dem Lager." or "."))) or ""
                    s.DescLines = {}
                    surface.SetFont("GARLog_Tiny")
                    local cur = ""
                    for word in string.gmatch(desc, "%S+") do
                        local test = cur == "" and word or (cur .. " " .. word)
                        if surface.GetTextSize(test) > w - 24 and cur ~= "" then
                            s.DescLines[#s.DescLines + 1] = cur
                            cur = word
                            if #s.DescLines >= 3 then break end
                        else
                            cur = test
                        end
                    end
                    if cur ~= "" and #s.DescLines < 3 then s.DescLines[#s.DescLines + 1] = cur end
                end
                cards[#cards + 1] = card
            end
        end
        local cols, ch = 3, 140
        grid:SetTall(math.ceil(#cards / cols) * (ch + 8))
        grid.PerformLayout = function(_, w)
            local cw = math.floor((w - 6 - (cols - 1) * 8) / cols)
            for i, c in ipairs(cards) do
                local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
                c:SetPos(col * (cw + 8), row * (ch + 8))
                c:SetSize(cw, ch)
            end
        end
        grid:InvalidateLayout()
    end

    for _, cdef in ipairs({ { "structure", "STRUKTUREN" }, { "sse", "AUSSTATTUNG (SSE)" } }) do
        local b = UI.Button(cats, cdef[2], function() ShowCat(cdef[1]) end)
        b:Dock(LEFT)
        b:SetWide(200)
        b:DockMargin(0, 0, 6, 0)
        catBtns[cdef[1]] = b
    end
    ShowCat("structure")
    return self
end

function B.OpenMenu()
    if B.Ghost then return end
    GARLog.OpenMenu(1, nil, GARLog.Menu.APP_FELDBASIS)
end

GARLog.Menu.RegisterApp(GARLog.Menu.APP_FELDBASIS, {
    label = "FELDBASIS", title = "PIONIER-KOMMANDO", sub = "DATAPAD // FELDBASIS & BAUPLANUNG",
    status = function()
        local fob = B.Context()
        if fob then return string.upper(fob.name), C.green end
        return "KEINE FELDBASIS IN REICHWEITE", C.orange
    end,
    tabs = {
        { label = "BAUPLANUNG", sub = "Strukturen & Ausstattung", build = function(p) return B.BuildCatalog(p) end },
        { label = "FELDBASEN",  sub = "Status, Lager, Strukturen", build = function(p, ctx)
            ctx.onlyFob = true
            return GARLog.Menu.BuildLocations(p, ctx)
        end },
    },
})

-- Abbau bestätigen (RMB auf Struktur)
function B.ConfirmDismantle(ent)
    if not IsValid(ent) then return end
    local def = GARLog.BuildDefs[ent:GetNW2String("GARLogKey", "")]
    local name = def and def.name or "Struktur"
    local isSite = ent:GetClass() == "garlog_site"
    local refund = isSite and "100 %" or (math.floor(cfg.FOB.DismantleRefund * 100) .. " %")
    UI.Confirm(isSite and "BAUSTELLE ABBRECHEN" or "STRUKTUR ABBAUEN",
        name .. (isSite and " abbrechen?" or " abbauen?") .. " Rückgewinnung: " .. refund .. " des Materials. Wird die letzte Struktur entfernt, wird die Feldbasis aufgelöst.",
        isSite and "ABBRECHEN" or "ABBAUEN", function()
            if IsValid(ent) then GARLog.Action("build.dismantle", { ent = ent:EntIndex() }) end
        end, C.red)
end

---------------------------------------------------------------------------
-- Laufzeitmessung (garlog_perf_cl)
---------------------------------------------------------------------------
B.DrawHUD = GARLog.Timed("HUD (Datapad-Hinweise)", B.DrawHUD)
do
    local hooks = hook.GetTable()
    hook.Add("PostDrawTranslucentRenderables", "GARLog_Ghost", GARLog.Timed("Hologramm & FOB-Ringe", hooks.PostDrawTranslucentRenderables.GARLog_Ghost))
end