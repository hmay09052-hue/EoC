--[[
    ShipTech – Erweiterungen (Client)
    Brand-Effekte · Hyperraum-Effekte · Ingame-Konfiguration · Techniker-Handbuch
]]

local C = ShipTech.Config
local P = ShipTech.Colors
local UI = ShipTech.UI
local T = ShipTech.Theme

---------------------------------------------------------------------------
-- BRAND: Flammen, Rauch, Licht, Knistern
---------------------------------------------------------------------------
local fireSounds = {}
local nextParticles = 0

function ShipTech.StopFireSound(ent)
    local snd = fireSounds[ent]
    if snd then
        snd:Stop()
        fireSounds[ent] = nil
    end
end

hook.Add("Think", "ShipTech_FireFX", function()
    if RealTime() < nextParticles then return end
    nextParticles = RealTime() + 0.06
    local eye = LocalPlayer():EyePos()

    for ent, snd in pairs(fireSounds) do
        if not IsValid(ent) or ent:GetNW2Float("ST_Fire", 0) <= 0 then
            snd:Stop()
            fireSounds[ent] = nil
        end
    end

    for _, ent in ipairs(ShipTech.ConsoleList()) do
        local f = ent:GetNW2Float("ST_Fire", 0)
        if f > 0 and ent:GetPos():DistToSqr(eye) < 2000 * 2000 then
            local base = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z * 0.6))
            local em = ParticleEmitter(base)
            if em then
                for _ = 1, math.ceil(2 * f + 1) do
                    local p = em:Add("particles/flamelet" .. math.random(1, 5), base + VectorRand() * 14 * f)
                    if p then
                        p:SetVelocity(Vector(0, 0, math.Rand(40, 90)) + VectorRand() * 10)
                        p:SetDieTime(math.Rand(0.4, 0.8))
                        p:SetStartAlpha(230)
                        p:SetEndAlpha(0)
                        p:SetStartSize(math.Rand(10, 18) * (0.5 + f))
                        p:SetEndSize(2)
                        p:SetRoll(math.Rand(0, 360))
                        p:SetRollDelta(math.Rand(-2, 2))
                    end
                end
                local s = em:Add("particle/particle_smokegrenade", base + Vector(0, 0, 30))
                if s then
                    s:SetVelocity(Vector(0, 0, math.Rand(30, 60)) + VectorRand() * 15)
                    s:SetDieTime(math.Rand(2, 3.5))
                    s:SetStartAlpha(90 * f)
                    s:SetEndAlpha(0)
                    s:SetStartSize(20)
                    s:SetEndSize(math.Rand(70, 110))
                    s:SetColor(40, 40, 40)
                    s:SetAirResistance(40)
                end
                em:Finish()
            end

            local dl = DynamicLight(ent:EntIndex())
            if dl then
                dl.pos = base + Vector(0, 0, 20)
                dl.r, dl.g, dl.b = 255, 120, 30
                dl.brightness = 2 + math.random() * f
                dl.size = 180 + 120 * f
                dl.decay = 600
                dl.dietime = CurTime() + 0.2
            end

            if not fireSounds[ent] then
                local snd = CreateSound(ent, "ambient/fire/fire_small_loop1.wav")
                snd:PlayEx(0.6, 100)
                fireSounds[ent] = snd
            end
        end
    end
end)

---------------------------------------------------------------------------
-- HYPERRAUM: Sprungblitz, Sternenstreifen, Hinweis im HUD
---------------------------------------------------------------------------
local hyperFX = 0
local hyperKind = ""

-- ersetzt den einfachen Effekt-Empfänger aus cl_core
net.Receive("ShipTech_FX", function()
    local kind = net.ReadString()
    if kind == "hyper_in" or kind == "hyper_out" then
        hyperFX = RealTime()
        hyperKind = kind
        surface.PlaySound(kind == "hyper_in" and "ambient/machines/teleport1.wav" or "ambient/machines/teleport3.wav")
        util.ScreenShake(LocalPlayer():GetPos(), 4, 8, 2, 2000)
        return
    end
    -- alle anderen Effekte wie bisher
    if kind == "hit" then
        surface.PlaySound(C.Sounds.Hit)
        util.ScreenShake(LocalPlayer():GetPos(), 8, 6, 1.4, 1000)
    elseif kind == "shieldhit" then
        ShipTech.ShieldFlash = RealTime()
        surface.PlaySound(C.Sounds.ShieldHit)
        util.ScreenShake(LocalPlayer():GetPos(), 2, 4, 0.6, 1000)
    end
end)

local streaks = {}
for i = 1, 120 do
    streaks[i] = { a = math.Rand(0, math.pi * 2), d = math.Rand(0.05, 1), l = math.Rand(0.1, 0.5) }
end

hook.Add("HUDPaint", "ShipTech_Hyper", function()
    local S = ShipTech.State
    local w, h = ScrW(), ScrH()
    local t = RealTime() - hyperFX

    if t < 2.5 then
        -- Sternenstreifen vom Bildzentrum
        local cx, cy = w / 2, h / 2
        local grow = math.Clamp(t / 1.2, 0, 1)
        local alpha = 255 * (1 - math.Clamp((t - 1.2) / 1.3, 0, 1))
        surface.SetDrawColor(200, 225, 255, alpha)
        local maxR = math.sqrt(w * w + h * h) / 2
        for _, s in ipairs(streaks) do
            local r1 = s.d * maxR * grow
            local r2 = r1 + s.l * maxR * grow
            surface.DrawLine(cx + math.cos(s.a) * r1, cy + math.sin(s.a) * r1, cx + math.cos(s.a) * r2, cy + math.sin(s.a) * r2)
        end
        -- Blitz
        local flash = 255 * math.Clamp(1 - math.abs(t - 0.9) / 0.5, 0, 1)
        surface.SetDrawColor(220, 235, 255, flash)
        surface.DrawRect(0, 0, w, h)
    end

    if S and S.hyper and S.hyper.phase == "hyperspace" then
        local txt = "IM HYPERRAUM" .. ((S.hyper.dest or "") ~= "" and (" // KURS " .. string.upper(S.hyper.dest)) or "")
        surface.SetFont("ShipTech_UIBold")
        local tw = surface.GetTextSize(txt)
        ShipTech.Box(w / 2 - tw / 2 - 20, h - 70, tw + 40, 34, P.bg)
        surface.SetDrawColor(P.cyan)
        surface.DrawRect(w / 2 - tw / 2 - 20, h - 38, tw + 40, 2)
        draw.SimpleText(txt, "ShipTech_UIBold", w / 2, h - 53, P.cyan, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif S and S.hyper and S.hyper.phase == "countdown" then
        local left = math.max(0, math.ceil((S.hyper.t or 0) - CurTime()))
        draw.SimpleText("HYPERRAUMSPRUNG IN " .. left, "ShipTech_HUD", w / 2, 120, P.cyan, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- leichter Blaustich im Hyperraum
hook.Add("RenderScreenspaceEffects", "ShipTech_HyperTint", function()
    local S = ShipTech.State
    if not S or not S.hyper or S.hyper.phase ~= "hyperspace" then return end
    DrawColorModify({
        ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.01, ["$pp_colour_addb"] = 0.04,
        ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"] = 1, ["$pp_colour_colour"] = 0.9,
        ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
    })
end)

---------------------------------------------------------------------------
-- TECHNIKER-HANDBUCH (Lernhilfe)
---------------------------------------------------------------------------
function ShipTech.OpenHandbook(topic)
    if IsValid(ShipTech.HandbookFrame) then ShipTech.HandbookFrame:Remove() end
    local f = UI.Frame("Techniker-Handbuch", 900, 620, "Lernhilfe")
    ShipTech.HandbookFrame = f

    local nav = vgui.Create("DPanel", f)
    nav:Dock(LEFT)
    nav:SetWide(210)
    nav:DockMargin(0, 0, 16, 0)
    nav.Paint = function(s, w, h) ShipTech.Box(0, 0, w, h, T.panel) end
    nav:DockPadding(8, 8, 8, 8)

    local content = UI.Scroll(f)
    content:Dock(FILL)

    local btns = {}
    local function show(i)
        content:Clear()
        local page = ShipTech.Handbook[i]
        for k, b in ipairs(btns) do b.Active = (k == i) end
        UI.Header(content, page.title)
        for n, line in ipairs(page.text) do
            local row = vgui.Create("DPanel", content)
            row:Dock(TOP)
            row:DockMargin(0, 0, 8, 6)
            row:DockPadding(16, 10, 12, 10)
            row.Paint = function(s, w, h)
                ShipTech.Box(0, 0, w, h, T.panel)
                surface.SetDrawColor(T.accent)
                surface.DrawRect(0, 0, 2, h)
            end
            local l = UI.Label(row, line, "ShipTech_UI", T.text)
            l:Dock(TOP)
            row.PerformLayout = function(s)
                s:SizeToChildren(false, true)
            end
            row:InvalidateLayout(true)
        end
    end

    for i, page in ipairs(ShipTech.Handbook) do
        local b = UI.Button(nav, string.upper(page.title), T.accent, function() show(i) end)
        b.Solid = false
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 6)
        b:SetTall(38)
        btns[i] = b
    end
    show(math.Clamp(tonumber(topic) or 1, 1, #ShipTech.Handbook))
end
concommand.Add("shiptech_handbuch", function() ShipTech.OpenHandbook() end)

---------------------------------------------------------------------------
-- INGAME-KONFIGURATION (nur Superadmins)
---------------------------------------------------------------------------
local function ValueToText(entry, v)
    if entry.type == "set" then
        local list = {}
        for k in pairs(v or {}) do list[#list + 1] = k end
        table.sort(list)
        return table.concat(list, ", ")
    elseif entry.type == "list" then
        return table.concat(v or {}, ", ")
    end
    return tostring(v or "")
end

local function SendSet(key, value, reset)
    net.Start("ShipTech_ConfigSet")
    net.WriteString(key)
    net.WriteBool(reset and true or false)
    net.WriteString(util.TableToJSON({ v = value }))
    net.SendToServer()
end

function ShipTech.OpenAdminConfig()
    if IsValid(ShipTech.AdminFrame) then ShipTech.AdminFrame:Remove() end
    local f = UI.Frame("Konfiguration", 1100, 760, "Admin // Einstellungen werden sofort gespeichert",
        function() return "NUR SUPERADMIN", T.red end)
    ShipTech.AdminFrame = f

    local cats, order = {}, {}
    for _, e in ipairs(ShipTech.ConfigSchema) do
        if not cats[e.cat] then
            cats[e.cat] = {}
            order[#order + 1] = e.cat
        end
        table.insert(cats[e.cat], e)
    end

    local nav = vgui.Create("DPanel", f)
    nav:Dock(LEFT)
    nav:SetWide(220)
    nav:DockMargin(0, 0, 16, 0)
    nav:DockPadding(8, 8, 8, 8)
    nav.Paint = function(s, w, h) ShipTech.Box(0, 0, w, h, T.panel) end

    local content = UI.Scroll(f)
    content:Dock(FILL)

    local btns, current = {}, 1

    local function row(e)
        local r = vgui.Create("DPanel", content)
        r:Dock(TOP)
        r:SetTall(46)
        if e.type == "set" or e.type == "list" or e.type == "model" then r:SetTall(74) end
        r:DockMargin(0, 0, 8, 4)
        local changed = ShipTech.ConfigOverrides and ShipTech.ConfigOverrides[e.key] ~= nil
        r.Paint = function(s, w, h)
            ShipTech.Box(0, 0, w, h, T.panel)
            surface.SetDrawColor(changed and T.accent or T.line)
            surface.DrawRect(0, 0, 2, h)
            draw.SimpleText(string.upper(e.label), "ShipTech_UIBold", 14, 18, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(e.key .. (changed and "  //  GEÄNDERT" or ""), "ShipTech_UISub", 14, 36, changed and T.accent or T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local reset = UI.Button(r, "STANDARD", T.dim, function() SendSet(e.key, nil, true) end)
        reset.Solid = false
        reset:SetSize(100, 30)
        reset:SetTooltip("Diese Einstellung auf den Wert aus sh_config.lua zurücksetzen")

        local cur = ShipTech.GetConfigValue(e.key)
        local ctrl
        if e.type == "bool" then
            ctrl = UI.Button(r, cur and "AN" or "AUS", cur and T.green or T.red, function(b)
                SendSet(e.key, not cur)
            end)
            ctrl.Solid = false
            ctrl:SetSize(110, 30)
        elseif e.type == "number" then
            ctrl = UI.TextEntry(r, tostring(cur))
            ctrl:SetText(tostring(cur or ""))
            ctrl:SetNumeric(true)
            ctrl:SetSize(140, 30)
            ctrl:SetTooltip("Bereich: " .. tostring(e.min) .. " – " .. tostring(e.max) .. " · Enter zum Speichern")
            ctrl.OnEnter = function(s) SendSet(e.key, tonumber(s:GetValue())) end
        else
            ctrl = UI.TextEntry(r, e.type == "model" and "models/..." or "Einträge mit Komma trennen")
            ctrl:SetText(e.type == "model" and tostring(cur or "") or ValueToText(e, cur))
            ctrl:SetTooltip("Enter zum Speichern")
            ctrl.OnEnter = function(s) SendSet(e.key, s:GetValue()) end
        end

        r.PerformLayout = function(s, w, h)
            reset:SetPos(w - 112, 8)
            if e.type == "bool" or e.type == "number" then
                ctrl:SetPos(w - 112 - 10 - ctrl:GetWide(), 8)
            else
                ctrl:SetPos(14, 44)
                ctrl:SetSize(w - 28, 24)
            end
        end
    end

    local function show(i)
        current = i
        content:Clear()
        for k, b in ipairs(btns) do b.Active = (k == i) end
        UI.Header(content, order[i])
        UI.Note(content, "Zahlen und Listen mit ENTER speichern. Geänderte Werte sind gelb markiert und gelten sofort für alle Spieler.", T.muted)
        for _, e in ipairs(cats[order[i]]) do row(e) end
    end

    for i, cat in ipairs(order) do
        local b = UI.Button(nav, string.upper(cat), T.accent, function() show(i) end)
        b.Solid = false
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 6)
        b:SetTall(38)
        btns[i] = b
    end
    show(1)

    hook.Add("ShipTech_ConfigUpdated", f, function() show(current) end)
end

net.Receive("ShipTech_OpenAdmin", function() ShipTech.OpenAdminConfig() end)
