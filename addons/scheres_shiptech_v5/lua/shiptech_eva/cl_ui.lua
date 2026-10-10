--[[
    ShipTech EVA – Menüs: EVA-Spind (Luftschleuse), Event-Reiter "Außenhülle", Handbuch
]]

local C = ShipTech.Config
local EC = C.EVA
local EVA = ShipTech.EVA
local UI = ShipTech.UI
local T = ShipTech.Theme

local function Act(action, ent, args)
    net.Start("ShipTechEVA_Action")
    net.WriteString(action)
    net.WriteEntity(ent)
    net.WriteString(util.TableToJSON(args or {}))
    net.SendToServer()
end

---------------------------------------------------------------------------
-- EVA-Spind
---------------------------------------------------------------------------
function EVA.OpenLocker(ent)
    if IsValid(UI.Current) then UI.Current:Remove() end
    local f = UI.Frame("Luftschleuse", 1000, 640, "Außenhülle", function()
        local n = #(EVA.State.breaches or {})
        return n > 0 and (n .. " SCHÄDEN") or "HÜLLE INTAKT", n > 0 and T.red or T.green
    end)
    UI.Current = f
    local oldThink = f.Think
    f.Think = function(s)
        if oldThink then oldThink(s) end
        if not IsValid(ent) or LocalPlayer():GetPos():Distance(ent:GetPos()) > 300 then s:Close() end
    end

    local left = UI.Scroll(f)
    left:Dock(LEFT)
    left:SetWide(440)
    left:DockMargin(0, 0, 18, 0)

    local right = vgui.Create("DPanel", f)
    right:Dock(FILL)

    local function rebuild()
        if not IsValid(left) then return end
        left:Clear()
        local lp = LocalPlayer()
        local can = EVA.CanEVA(lp)
        local plates = lp:GetNW2Int("ST_EVA_Plates", 0)
        local hasWelder = lp:HasWeapon("st_eva_welder")

        local status = vgui.Create("DPanel", left)
        status:Dock(TOP)
        status:SetTall(116)
        status:DockMargin(0, 0, 6, 8)
        status.Paint = function(s, w, h)
            UI.Plate(0, 0, w, h, T.panel, T.line, 12, "tlbr")
            draw.SimpleText(can and "EINSATZBEREIT" or "NUR FÜR TECHNIKER", "ShipTech_UIMed", 14, 10, can and T.green or T.red)
            EOCUI.Aurebesh("Ausseneinsatz", "eocui.aure.small", 16, 40, ColorAlpha(T.text, 80))
            draw.SimpleText("HÜLLENPLATTEN " .. lp:GetNW2Int("ST_EVA_Plates", 0) .. " / " .. EC.MaxPlates, "ShipTech_UISub", 14, 70, T.soft)
            local hull = ShipTech.LogiActive() and ShipTech.StockOf and ShipTech.StockOf("hull")
            if hull then draw.SimpleText("IM LAGER: " .. hull, "ShipTech_UISub", w - 14, 70, T.muted, TEXT_ALIGN_RIGHT) end
            draw.SimpleText("Anzug & Sauerstoff: passives RP", "ShipTech_UISub", 14, 92, T.muted)
        end

        local function btn(text, col, fn, enabled, tip)
            local b = UI.Button(left, text, col, fn)
            b:Dock(TOP)
            b:SetTall(42)
            b:DockMargin(0, 0, 6, 6)
            b:SetEnabled(enabled ~= false)
            if tip then b:SetTooltip(tip) end
            return b
        end

        UI.Header(left, "Ausrüstung")
        if hasWelder then
            local r = btn("Hüllenschweißgerät zurückgeben", T.orange, function() Act("return_welder", ent) end)
            r.Solid = false
        else
            btn("HÜLLENSCHWEISSGERÄT NEHMEN", T.accent, function() Act("take_welder", ent) end, can)
        end

        UI.Header(left, "Hüllenplatten")
        local free = EC.MaxPlates - plates
        btn("1 Hüllenplatte nehmen", T.accent, function() Act("take_plates", ent, { n = 1 }) end, can and free > 0)
        btn("AUFFÜLLEN (" .. math.max(0, free) .. ")", T.accent, function() Act("take_plates", ent, { n = free }) end, can and free > 0,
            "Bis zum Maximum von " .. EC.MaxPlates .. " Platten auffüllen. Leck = 1 Platte, Bresche = 2 Platten.")
        if plates > 0 then
            local back = btn("Alle Platten zurück ins Lager", T.orange, function() Act("return_plates", ent) end)
            back.Solid = false
        end

        UI.Header(left, "So geht's")
        UI.Note(left, "Mit dem Hüllenschweißgerät auf den Ankerpunkt der Schadensstelle zielen und Linksklick: Schritt für Schritt freilegen, Platten setzen, verschweißen. Alles alleine machbar.", T.muted)
    end
    rebuild()

    -- rechts: Schadensstellen
    right.Paint = function(s, w, h)
        local y = 0
        local tw = draw.SimpleText("SCHADENSSTELLEN", "ShipTech_UIMed", 0, y, T.text)
        surface.SetDrawColor(T.lineS)
        surface.DrawRect(tw + 10, y + 18, w - tw - 10, 1)
        y = y + 40
        local br = EVA.State.breaches or {}
        if #br == 0 then draw.SimpleText("Keine Hüllenbrüche.", "ShipTech_UI", 0, y, T.green) end
        for _, b in ipairs(br) do
            local steps = EVA.Steps({ stage = b.g, wires = b.w })
            UI.Plate(0, y, w, 46, T.panel, ColorAlpha(T.red, 120), 6, "br")
            draw.SimpleText("SEKTOR " .. string.upper(EVA.SectorName(b.s)) .. " · " .. string.upper(EVA.StageDef(b.g).name), "ShipTech_UIBold", 12, y + 14, T.red, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local nxt = steps[b.d + 1]
            local need = EVA.StageDef(b.g).plates
            draw.SimpleText("Schritt " .. (b.d + 1) .. "/" .. #steps .. ": " .. (nxt and EVA.StepNames[nxt] or "–") .. (need > 0 and ("   ·   " .. need .. " Platte(n)") or ""),
                "ShipTech_UISub", 12, y + 34, T.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            UI.DrawBar(w - 170, y + 20, 156, 8, b.d / #steps, T.accent)
            y = y + 52
        end
    end

    local last = ""
    local function check()
        local lp = LocalPlayer()
        local sig = lp:GetNW2Int("ST_EVA_Plates", 0) .. tostring(lp:HasWeapon("st_eva_welder"))
        if sig ~= last then
            last = sig
            rebuild()
        end
    end
    local t0 = f.Think
    local nextCheck = 0
    f.Think = function(s)
        if t0 then t0(s) end
        if RealTime() > nextCheck then
            nextCheck = RealTime() + 0.3
            check()
        end
    end
end

net.Receive("ShipTechEVA_Open", function()
    local ent = net.ReadEntity()
    if IsValid(ent) and ent:GetClass() == "shiptech_eva_locker" then EVA.OpenLocker(ent) end
end)

---------------------------------------------------------------------------
-- Event-Menü: Reiter "Außenhülle"
---------------------------------------------------------------------------
hook.Add("ShipTech_EventMenuTabs", "ShipTechEVA", function(sheet, content, f, Send)
    local p = UI.Scroll(content)
    sheet:AddSheet("Außenhülle", p)

    local function row(h)
        local r = vgui.Create("DPanel", p)
        r:Dock(TOP)
        r:SetTall(h or 40)
        r:DockMargin(0, 0, 0, 6)
        r.Paint = function() end
        return r
    end
    local function buttons(list)
        local r = row(42)
        local btns = {}
        for _, b in ipairs(list) do btns[#btns + 1] = UI.Button(r, b[1], b[2], b[3]) end
        r.PerformLayout = function(s, w, h)
            local bw = (w - (#btns - 1) * 6) / #btns
            for i, b in ipairs(btns) do
                b:SetPos((i - 1) * (bw + 6), 0)
                b:SetSize(bw, h)
            end
        end
    end
    local function combo(parent, choices)
        local c = UI.StyleCombo(vgui.Create("DComboBox", parent))
        for i, ch in ipairs(choices) do c:AddChoice(ch[1], ch[2], i == 1) end
        return c
    end
    local function val(c) local _, v = c:GetSelected() return v end

    UI.Header(p, "Hüllenbruch")
    local r = row(36)
    local sec = combo(r, { { "Zufälliger Sektor", 0 }, { "Bug", 1 }, { "Steuerbord", 2 }, { "Heck", 3 }, { "Backbord", 4 } })
    sec:Dock(LEFT)
    sec:SetWide(260)
    local stg = combo(r, { { "Riss", 1 }, { "Leck", 2 }, { "Bresche", 3 } })
    stg:Dock(LEFT)
    stg:SetWide(200)
    stg:DockMargin(6, 0, 0, 0)
    local go = UI.Button(r, "HÜLLENBRUCH AUSLÖSEN", T.red, function() Send("eva_breach", { sector = val(sec), stage = val(stg) }) end)
    go:Dock(FILL)
    go:DockMargin(6, 0, 0, 0)
    buttons({
        { "Alle Brüche reparieren", T.green, function() Send("eva_repair_all") end },
        { "Alle Brüche verschlimmern", T.orange, function() Send("eva_worsen_all") end },
    })
    UI.Note(p, "Ankerpunkte, EVA-Spinde und Versorgungspunkte setzt man über das Spawnmenü (Entities → ShipTech – Außeneinsatz) und speichert sie mit shiptech_save. Schadensstellen entstehen nur an freien Ankerpunkten des passenden Sektors.", T.muted)
end)

---------------------------------------------------------------------------
-- Handbuch-Seite
---------------------------------------------------------------------------
table.insert(ShipTech.Handbook, { title = "Außenhülle", text = {
    "Hüllenbrüche entstehen, wenn Treffer durch einen leeren Schildsektor gehen, oder durch Eventler. Die Schadensstelle sitzt an einem Ankerpunkt außen.",
    "Solange ein Bruch offen ist: Systeme im Sektor höchstens 'Beschädigt', Schildregeneration halbiert. Nach einiger Zeit wird ein Riss zum Leck, ein Leck zur Bresche.",
    "1. Am EVA-Spind das Hüllenschweißgerät nehmen und Hüllenplatten auffüllen (bis zu " .. EC.MaxPlates .. "). Versorgungspunkte an der Hülle geben ebenfalls Platten (E).",
    "2. Zur Schadensstelle, mit dem Schweißgerät auf den Ankerpunkt zielen und Linksklick: freilegen, Platten setzen (Leck 1, Bresche 2), verschweißen, ggf. Leitungen prüfen.",
    "3. Schweißpunkte: Maustaste halten, die Hitze steigt – im grünen Bereich loslassen. Alles ist alleine machbar.",
    "Anzug und Sauerstoff werden nur ausgespielt (passives RP).",
} })
