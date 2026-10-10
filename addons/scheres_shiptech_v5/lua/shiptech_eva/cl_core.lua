--[[
    ShipTech EVA – Client: Zustand, Schadensstellen (Effekte & Hologramme), HUD am Schweißgerät,
    Minigame "Schweißpunkte"
]]

local C = ShipTech.Config
local EC = C.EVA
local EVA = ShipTech.EVA
local P = ShipTech.Colors
local E = EOCUI

---------------------------------------------------------------------------
-- Zustand
---------------------------------------------------------------------------
EVA.State = EVA.State or { breaches = {} }
net.Receive("ShipTechEVA_State", function()
    local t = util.JSONToTable(net.ReadString())
    if t then
        EVA.State = t
        EVA.ByAnchor = {}
        for _, b in ipairs(t.breaches or {}) do EVA.ByAnchor[b.a] = b end
        hook.Run("ShipTechEVA_StateUpdated", t)
    end
end)

function EVA.BreachAt(entIndex)
    return EVA.ByAnchor and EVA.ByAnchor[entIndex]
end

net.Receive("ShipTechEVA_FX", function()
    local kind = net.ReadString()
    local pos = net.ReadVector()
    if kind == "breach" then
        util.ScreenShake(LocalPlayer():GetPos(), 6, 6, 1.5, 6000)
        surface.PlaySound("ambient/materials/metal_stress" .. math.random(1, 5) .. ".wav")
    elseif kind == "sealed" then
        sound.Play("buttons/button3.wav", pos, 70, 100, 1)
    elseif kind == "shock" then
        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetMagnitude(5)
        ed:SetScale(2)
        ed:SetRadius(5)
        util.Effect("ElectricSpark", ed)
    end
end)

---------------------------------------------------------------------------
-- HUD (nur mit Hüllenschweißgerät in der Hand)
---------------------------------------------------------------------------
local function Meters(u) return math.Round(u * 0.01905) .. " m" end

local function NearestBreach(pos)
    local best, bd
    for _, b in ipairs((EVA.State and EVA.State.breaches) or {}) do
        if b.pos then
            local d = b.pos:Distance(pos)
            if not bd or d < bd then best, bd = b, d end
        end
    end
    return best, bd
end

hook.Add("HUDPaint", "ShipTechEVA_HUD", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end
    local w = lp:GetActiveWeapon()
    if not IsValid(w) or w:GetClass() ~= "st_eva_welder" then return end

    local x, y, pw, ph = 30, ScrH() - 150, 360, 110
    E.Cut(x, y, pw, ph, Color(6, 8, 11, 220), 12, "tlbr")
    E.CutOutline(x, y, pw, ph, ColorAlpha(P.yellow, 120), 12, "tlbr")
    draw.SimpleText("HÜLLENSCHWEISSGERÄT", "ShipTech_UIMed", x + 16, y + 6, P.text)
    E.Aurebesh("Huellenschweissgeraet", "eocui.aure.small", x + 18, y + 34, ColorAlpha(P.text, 90))

    draw.SimpleText("HÜLLENPLATTEN", "ShipTech_UISub", x + 16, y + 62, P.muted)
    draw.SimpleText(lp:GetNW2Int("ST_EVA_Plates", 0) .. " / " .. EC.MaxPlates, "ShipTech_UISub", x + pw - 16, y + 62, P.soft, TEXT_ALIGN_RIGHT)

    local b, bd = NearestBreach(lp:GetPos())
    draw.SimpleText("NÄCHSTER SCHADEN", "ShipTech_UISub", x + 16, y + 84, P.muted)
    if b then
        draw.SimpleText(string.upper(EVA.SectorName(b.s)) .. " · " .. Meters(bd), "ShipTech_UISub", x + pw - 16, y + 84, P.red, TEXT_ALIGN_RIGHT)
    else
        draw.SimpleText("KEINER", "ShipTech_UISub", x + pw - 16, y + 84, P.green, TEXT_ALIGN_RIGHT)
    end
end)

---------------------------------------------------------------------------
-- Schadensstellen: entweichende Luft, Funken, Warnlicht
---------------------------------------------------------------------------
local nextFX = 0
hook.Add("Think", "ShipTechEVA_BreachFX", function()
    if RealTime() < nextFX then return end
    nextFX = RealTime() + 0.08
    local eye = LocalPlayer():EyePos()
    for _, b in ipairs((EVA.State and EVA.State.breaches) or {}) do
        local a = Entity(b.a or 0)
        if IsValid(a) and a:GetPos():DistToSqr(eye) < 2500 * 2500 then
            local pos = a:WorldSpaceCenter()
            local up = a:GetUp()
            local em = ParticleEmitter(pos)
            if em then
                for _ = 1, b.g do
                    local p = em:Add("particle/particle_smokegrenade", pos)
                    if p then
                        p:SetVelocity(up * math.Rand(180, 320) + VectorRand() * 40)
                        p:SetDieTime(math.Rand(0.6, 1.2))
                        p:SetStartAlpha(110)
                        p:SetEndAlpha(0)
                        p:SetStartSize(6)
                        p:SetEndSize(math.Rand(30, 60))
                        p:SetColor(220, 230, 240)
                        p:SetAirResistance(30)
                    end
                end
                em:Finish()
            end
            if math.random() < 0.15 then
                local ed = EffectData()
                ed:SetOrigin(pos)
                ed:SetMagnitude(2)
                ed:SetScale(1)
                ed:SetRadius(2)
                util.Effect("ElectricSpark", ed)
            end
            local dl = DynamicLight(a:EntIndex() + 4096)
            if dl then
                dl.pos = pos + up * 20
                dl.r, dl.g, dl.b = 255, 40, 30
                dl.brightness = 2
                dl.size = 220
                dl.decay = 800
                dl.dietime = CurTime() + 0.2
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Hologramme über den EVA-Entities
---------------------------------------------------------------------------
local W = 560
function EVA.DrawEntityHolo(ent)
    local lp = LocalPlayer()
    local dist = lp:EyePos():Distance(ent:GetPos())
    if dist > 700 then return end
    local cls = ent:GetClass()
    local title, sub, col = ent.PrintName, nil, P.yellow
    if cls == "shiptech_eva_anchor" then
        local b = EVA.BreachAt(ent:EntIndex())
        if not b then
            -- intakte Ankerpunkte nur für Admins mit Physgun/Toolgun sichtbar
            local w = lp:GetActiveWeapon()
            if not (IsValid(w) and (w:GetClass() == "weapon_physgun" or w:GetClass() == "gmod_tool")) then return end
            title, sub = "ANKERPUNKT · " .. string.upper(EVA.SectorName(ent:GetHullSector())), "INTAKT"
            col = P.green
        else
            local steps = EVA.Steps({ stage = b.g, wires = b.w })
            local nxt = steps[b.d + 1]
            title = "HÜLLENBRUCH · " .. string.upper(EVA.SectorName(b.s))
            sub = string.upper(EVA.StageDef(b.g).name) .. "  ·  SCHRITT " .. (b.d + 1) .. "/" .. #steps .. ": " .. (nxt and EVA.StepNames[nxt] or "")
            col = P.red
        end
    elseif cls == "shiptech_eva_locker" then
        local n = #((EVA.State and EVA.State.breaches) or {})
        sub = n > 0 and (n .. " SCHADENSSTELLE(N) OFFEN") or "HÜLLE INTAKT"
        col = n > 0 and P.red or P.green
    elseif cls == "shiptech_eva_supply" then
        sub = "HÜLLENPLATTE AUFNEHMEN [E]"
        col = P.cyan
    else
        return
    end
    local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)) + Vector(0, 0, 14)
    local ang = Angle(0, lp:EyeAngles().y - 90, 90)
    surface.SetAlphaMultiplier(math.Clamp((700 - dist) / 150, 0, 1))
    render.OverrideDepthEnable(true, false)
    cam.Start3D2D(pos, ang, 0.06)
        E.Cut(-W / 2, -120, W, 120, Color(6, 8, 11, 225), 16, "tlbr")
        E.CutOutline(-W / 2, -120, W, 120, ColorAlpha(col, 160), 16, "tlbr")
        draw.SimpleText(title, "ShipTech_HoloMed", 0, -92, P.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        E.Aurebesh(title, "eocui.aure.small", 0, -66, ColorAlpha(P.text, 90), TEXT_ALIGN_CENTER)
        if sub then draw.SimpleText(sub, "ShipTech_HoloSmall", 0, -34, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
    cam.End3D2D()
    render.OverrideDepthEnable(false, false)
    surface.SetAlphaMultiplier(1)
end

---------------------------------------------------------------------------
-- Minigame "Schweißpunkte"
-- Für jeden Schweißpunkt die linke Maustaste gedrückt halten: die Hitze steigt.
-- Im grünen Bereich loslassen = Punkt verschweißt. Zu früh = nochmal. 100 % = Riss.
-- Nur echte Klicks im Spielfeld zählen (ein noch gehaltener Klick vom Schweißgerät nicht).
---------------------------------------------------------------------------
ShipTech.Minigames.weld = function(p, diff, finish, fr)
    local count = 3 + diff                   -- Riss 4, Leck 5, Bresche 6 Punkte
    local maxTears = 4
    local rate = 40 + diff * 8               -- Hitze pro Sekunde
    local zoneW = 24 - diff * 3              -- Breite des grünen Bereichs
    local done, tears = 0, 0
    local heat, holding = 0, false
    local zoneLo = 0
    local msg, msgCol, msgT = nil, nil, 0
    local flash = 0

    local function NewZone()
        zoneLo = math.random(50, 88 - zoneW)
    end
    NewZone()

    local function Say(text, col)
        msg, msgCol, msgT = text, col, RealTime()
    end

    local function Tear()
        tears = tears + 1
        holding = false
        heat = 0
        flash = RealTime()
        surface.PlaySound("ambient/energy/zap2.wav")
        Say("Überhitzt – die Naht ist gerissen!", P.red)
        if tears >= maxTears then finish(false) end
    end

    local function Release()
        if not holding then return end
        holding = false
        if heat >= zoneLo and heat <= zoneLo + zoneW then
            done = done + 1
            surface.PlaySound("ambient/energy/spark" .. math.random(1, 6) .. ".wav")
            Say("Punkt verschweißt!", P.green)
            heat = 0
            if done >= count then
                finish(true)
            else
                NewZone()
            end
        else
            Say("Zu kalt – nochmal ansetzen.", P.orange)
            heat = 0
        end
    end

    p:SetCursor("hand")
    p.OnMousePressed = function(s, code)
        if fr.Done or code ~= MOUSE_LEFT then return end
        holding = true
        heat = 0
    end
    p.OnMouseReleased = function(s, code)
        if fr.Done or code ~= MOUSE_LEFT then return end
        Release()
    end

    p.Think = function(s)
        if fr.Done or not holding then return end
        if not input.IsMouseDown(MOUSE_LEFT) then return Release() end
        heat = heat + rate * FrameTime()
        if math.random() < 0.15 then surface.PlaySound("ambient/energy/spark" .. math.random(1, 6) .. ".wav") end
        if heat >= 100 then Tear() end
    end

    p.Paint = function(s, w, h)
        surface.SetDrawColor(11, 14, 18)
        surface.DrawRect(0, 0, w, h)

        -- Naht mit Schweißpunkten
        local x0, x1, y = 70, w - 70, 150
        surface.SetDrawColor(70, 76, 84)
        surface.DrawRect(x0, y - 2, x1 - x0, 4)
        for i = 1, count do
            local x = x0 + (i - 1) * (x1 - x0) / math.max(1, count - 1)
            if i <= done then
                E.Circle(x, y, 16, Color(255, 210, 120), 20)
            elseif i == done + 1 then
                local glow = holding and (heat / 100) or (0.4 + 0.3 * math.abs(math.sin(RealTime() * 4)))
                E.Circle(x, y, 20, Color(64, 196, 255, 90 + 140 * glow), 20)
                if holding then E.Circle(x, y, 10 + heat * 0.12, Color(255, 140 + heat, 60, 230), 16) end
            else
                E.Circle(x, y, 12, Color(70, 76, 84), 16)
            end
        end

        -- Hitzeanzeige
        local bx, by, bw, bh = 70, 250, w - 140, 34
        surface.SetDrawColor(20, 24, 30)
        surface.DrawRect(bx, by, bw, bh)
        surface.SetDrawColor(74, 203, 130, 160)
        surface.DrawRect(bx + bw * zoneLo / 100, by, bw * zoneW / 100, bh)
        surface.SetDrawColor(205, 62, 56, 120)
        surface.DrawRect(bx + bw * 0.95, by, bw * 0.05, bh)
        local hc = heat > zoneLo + zoneW and P.red or (heat >= zoneLo and P.green or P.yellow)
        surface.SetDrawColor(hc)
        surface.DrawRect(bx, by + bh - 8, bw * math.min(heat, 100) / 100, 8)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(bx + bw * math.min(heat, 100) / 100 - 2, by - 6, 4, bh + 12)
        surface.SetDrawColor(ColorAlpha(P.text, 40))
        surface.DrawOutlinedRect(bx, by, bw, bh, 1)
        draw.SimpleText("HITZE " .. math.floor(heat) .. " %", "ShipTech_UISub", bx, by + bh + 16, P.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Im grünen Bereich loslassen", "ShipTech_UISub", bx + bw, by + bh + 16, P.green, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        if RealTime() - flash < 0.3 then
            surface.SetDrawColor(205, 62, 56, 70)
            surface.DrawRect(0, 0, w, h)
        end
        draw.SimpleText("SCHWEISSPUNKTE " .. done .. " / " .. count, "ShipTech_UIBold", w / 2, 22, P.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Risse: " .. tears .. " / " .. maxTears, "ShipTech_UISmall", w - 20, 22, tears > 0 and P.red or P.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        if msg and RealTime() - msgT < 1.5 then
            draw.SimpleText(msg, "ShipTech_UIBold", w / 2, 340, msgCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("Linke Maustaste ins Feld drücken und halten – die Hitze steigt. Im grünen Bereich loslassen.",
            "ShipTech_UISmall", w / 2, h - 14, P.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end
end
ShipTech.GameNames.weld = "Schweißpunkte"
