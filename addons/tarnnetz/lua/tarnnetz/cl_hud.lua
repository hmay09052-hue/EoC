if not CLIENT then return end

Tarnnetz = Tarnnetz or {}

local C = Tarnnetz.Config
local L = C.Lang
local P = Tarnnetz.UIColors

-- Anzeige unten mittig, solange die Tarnung aktiv ist, die Abklingzeit läuft oder das Tarnnetz in der Hand ist
local nearestDist
local nextScan = 0

hook.Add('HUDPaint', 'Tarnnetz.HUD', function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local active = Tarnnetz.IsActive(ply)
    local cooldown = Tarnnetz.CooldownLeft(ply)
    local wep = ply:GetActiveWeapon()
    local holding = IsValid(wep) and wep:GetClass() == C.WeaponClass
    if not active and cooldown <= 0 and not holding then return end

    -- Droiden in Sichtweite des Radars (2,5-facher Enttarnungsradius) alle 0,2 s suchen
    if CurTime() > nextScan then
        nextScan = CurTime() + 0.2
        local _, d = Tarnnetz.NearestDroid(ply, C.Radius * 2.5)
        nearestDist = d
    end

    local paused = ply:GetNWBool('Tarnnetz.Paused', false)
    local camo = active and Tarnnetz.GetCamo(ply)

    local w, h = 340, 74
    local x, y = ScrW() / 2 - w / 2, ScrH() - h - 120

    local status, statusCol
    if active and paused then
        status, statusCol = L.hudPaused, P.red
    elseif active then
        status, statusCol = L.hudActive, P.green
    elseif cooldown > 0 then
        status, statusCol = L.hudCooldown .. string.format('  %ds', math.ceil(cooldown)), P.red
    else
        status, statusCol = 'Bereit', P.soft
    end

    -- Fläche
    if SYMUI then
        SYMUI.HudPanel(x, y, w, h, { accent = statusCol })
    else
        surface.SetDrawColor(P.bg)
        surface.DrawRect(x, y, w, h)
        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(x, y, w, h, 1)
        surface.SetDrawColor(statusCol)
        surface.DrawRect(x, y, 3, h)
    end

    -- Kopfzeile
    local tw = draw.SimpleText(string.upper(L.title), 'Tarnnetz_Head', x + 14, y + 6, P.white)
    draw.SimpleText('//  ' .. string.upper(status), 'Tarnnetz_Sub', x + 22 + tw, y + 17, statusCol, 0, 1)
    if camo then
        draw.SimpleText(camo.short or camo.name, 'Tarnnetz_Sub', x + w - 12, y + 17, P.yellow, 2, 1)
    end

    -- Droiden-Abstand
    local barX, barY, barW, barH = x + 14, y + 50, w - 28, 8
    local label, frac, col
    if nearestDist then
        local m = Tarnnetz.Meters(nearestDist)
        label = string.format('%s: %d m', L.hudDroid, m)
        frac = 1 - math.Clamp((nearestDist - C.Radius) / (C.Radius * 1.5), 0, 1)
        col = nearestDist <= C.Radius and P.red or (frac > 0.6 and Color(255, 150, 60) or P.yellow)
    else
        label, frac, col = L.hudNone, 0, P.green
    end
    draw.SimpleText(label, 'Tarnnetz_Small', barX, barY - 4, P.soft, 0, 4)

    if SYMUI then
        SYMUI.Bar(barX, barY, barW, barH, frac, col, { segments = 10 })
    else
        surface.SetDrawColor(0, 0, 0, 170)
        surface.DrawRect(barX, barY, barW, barH)
        surface.SetDrawColor(col)
        surface.DrawRect(barX, barY, math.floor(barW * frac), barH)
    end
end)
