--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - TAB-Menü
    Kopfleiste (Logo, eigener Charakter) | Kommandostruktur | Truppenliste | Informationen | Fußzeile
    Hintergrund: genau EIN Blur und EINE gleichmäßige Abdunklung - keine weiteren Ebenen.
-------------------------------------------------------------------------------------------------------------]]

local CFG = EOCSB.Config
local L = CFG.Lang
local D = EOCSB.D
local S = D.S
local floor = math.floor

local function BarH() return S(92) end

---------------------------------------------------------------------------------------------------------------
-- Daten
---------------------------------------------------------------------------------------------------------------
local function SortPlayers(list)
    table.sort(list, function(a, b)
        local wa, wb = EOCSB.GetRankWeight(a), EOCSB.GetRankWeight(b)
        if wa ~= wb then return wa > wb end
        return EOCSB.GetName(a) < EOCSB.GetName(b)
    end)
end

local function BuildGroups()
    local order = {}
    if EOCSB.HasSymChars() and symchars.factions.GetHierarchyList then
        for i, e in ipairs(symchars.factions.GetHierarchyList()) do order[e.id] = i end
    end

    local roots, rootList = {}, {}
    local function Root(key, name, col, sort)
        local r = roots[key]
        if not r then
            r = { name = name, color = col, sort = sort, count = 0, subs = {}, subList = {} }
            roots[key] = r
            rootList[#rootList + 1] = r
        end
        return r
    end
    local function Sub(root, key, name, col, sort, isRoot)
        local s = root.subs[key]
        if not s then
            s = { name = name, color = col, sort = sort, isRoot = isRoot, players = {} }
            root.subs[key] = s
            root.subList[#root.subList + 1] = s
        end
        return s
    end

    for _, ply in ipairs(player.GetAll()) do
        local f = EOCSB.GetFaction(ply)
        local root, sub
        if f then
            local top = symchars.factions.GetRoot(f) or f
            root = Root("f:" .. top.uniqueID, top.name, top:GetColor(), order[top.uniqueID] or 9000)
            sub = Sub(root, "f:" .. f.uniqueID, f.name, f:GetColor(), f == top and -1 or (order[f.uniqueID] or 9000), f == top)
        else
            local tid = ply:Team()
            root = Root("other", CFG.OtherGroupName, D.Col("dim"), 99999)
            sub = Sub(root, "t:" .. tid, team.GetName(tid) or "?", team.GetColor(tid) or D.Col("dim"), tid, false)
        end
        root.count = root.count + 1
        sub.players[#sub.players + 1] = ply
    end

    table.sort(rootList, function(a, b) return a.sort < b.sort end)
    for _, r in ipairs(rootList) do
        table.sort(r.subList, function(a, b) return a.sort < b.sort end)
        for _, s in ipairs(r.subList) do SortPlayers(s.players) end
    end
    return rootList
end

local function Signature()
    local parts = {}
    for _, ply in ipairs(player.GetAll()) do
        local f = EOCSB.GetFaction(ply)
        parts[#parts + 1] = ply:EntIndex() .. (f and f.uniqueID or ("t" .. ply:Team())) .. EOCSB.GetRankWeight(ply) .. EOCSB.GetName(ply)
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

local function DefconInfo()
    local level = GetGlobalInt("GRN_Defcon_CurrentLevel", 0)
    if not GRN_DEFCON or level <= 0 then return nil end
    local data = (GRN_DEFCON.ClientLevels and GRN_DEFCON.ClientLevels[level])
        or (GRN_DEFCON.Config and GRN_DEFCON.Config.Levels and GRN_DEFCON.Config.Levels[level]) or {}
    return level, data.Name or "", EOCSB.HexColor(data.Color, D.Col("text"))
end

local function SecurityCount()
    local n = 0
    for _, ply in ipairs(player.GetAll()) do
        if EOCSB.IsSecurity(ply) then n = n + 1 end
    end
    return n
end

---------------------------------------------------------------------------------------------------------------
-- Zeilen: deckend, abwechselnd zwei Töne, Farbbalken links
---------------------------------------------------------------------------------------------------------------
local function RowBase(s, w, h, index, barCol, highlight)
    s.hov = D.Approach(s.hov or 0, s:IsHovered() and 1 or 0, 14)
    D.Box(0, 0, w, h, D.Lerp(s.hov, index % 2 == 0 and D.fill.row2 or D.fill.row, D.fill.hover))
    if highlight then
        D.Outline(0, 0, w, h, D.Accent(170))
    elseif s.hov > 0.01 then
        D.Outline(0, 0, w, h, D.Alpha(D.Accent(), 150 * s.hov))
    end
    D.Box(0, 0, S(4), h, barCol)
end

local function UnitSection(parent, group)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(S(44))
    p:DockMargin(0, S(12), 0, S(4))
    p.Paint = function(_, w)
        D.Section(group.name .. "  (" .. group.count .. ")", 0, S(6), w, D.Readable(group.color, 140))
    end
end

local function SubHeader(parent, sub)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(S(30))
    p:DockMargin(0, S(4), 0, S(3))
    p.Paint = function(_, w, h)
        local col = D.Readable(sub.color, 140)
        local name = string.upper(sub.name)
        D.Text(name, "symchars.h4", 0, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local tw = D.TextSize(name, "symchars.h4")
        D.Text(tostring(#sub.players), "symchars.tiny.bold", tw + S(10), h / 2, D.Col("muted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

local function PlayerRow(parent, ply, unitCol, index)
    local row = vgui.Create("DButton", parent)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, S(2))
    row:SetTall(S(52))
    row:SetText("")
    row.ply = ply
    row.Paint = function(s, w, h)
        local p = s.ply
        if not IsValid(p) then return true end
        local isLP = p == LocalPlayer()
        local alive = p:Alive()
        RowBase(s, w, h, index, D.Readable(unitCol, 110), isLP)

        local rankX = floor(w * 0.56)
        local nameMax = rankX - S(40)

        -- Name mit CT-Nummer, Aurebesh darunter
        local name = EOCSB.GetName(p)
        local nameCol = alive and (isLP and D.Accent() or D.Col("text")) or D.Col("muted")
        D.TextFit(name, "symchars.body.bold", S(20), h / 2 + S(3), nameCol, nameMax, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        D.Aurebesh(name, "s", S(21), h / 2 + S(4), D.Alpha(D.Col("dim"), alive and 120 or 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, nameMax)

        -- Rang (Farbe der Rangstufe)
        local rc = EOCSB.GetRankColor(p) or D.Col("dim")
        D.TextFit(string.upper(EOCSB.GetRankName(p)), "symchars.h4", rankX, h / 2, alive and rc or D.Alpha(rc, 110), w - rankX - S(130), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- rechts: Officer-Posten und Ping
        local rx = w - S(16)
        if CFG.ShowPing then
            D.Text(p:IsBot() and "BOT" or (p:Ping() .. " ms"), "symchars.tiny.bold", rx, h / 2, D.Col("muted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            rx = rx - S(60)
        end
        local officer = EOCSB.GetPlayerOfficerRank(p)
        if officer then
            D.Text(officer.short, "symchars.small.bold", rx, h / 2, officer.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        return true
    end
    row.OnCursorEntered = function() D.Sound("hover") end
    row.DoClick = function(s) D.Sound("click") EOCSB.OpenCommandMenu(s.ply) end
    row.DoRightClick = row.DoClick
end

---------------------------------------------------------------------------------------------------------------
-- Linke Spalte: Kommandostruktur
---------------------------------------------------------------------------------------------------------------
local function ColumnHead(parent, text)
    local head = vgui.Create("DPanel", parent)
    head:Dock(TOP)
    head:SetTall(S(44))
    head:DockMargin(0, 0, 0, S(4))
    head.Paint = function(_, w) D.Section(text, 0, S(6), w) end
end

local function BuildCommand(col)
    ColumnHead(col, L.command)
    local open = function() EOCSB.OpenOfficerMenu() end
    for i, rank in ipairs(CFG.OfficerRanks or {}) do
        local row = vgui.Create("DButton", col)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, S(2))
        row:SetTall(S(58))
        row:SetText("")
        row.Paint = function(s, w, h)
            local o, ply = EOCSB.GetOfficerHolder(rank.id)
            local rc = D.Readable(rank.color, 130)
            RowBase(s, w, h, i, o and rc or D.Alpha(rc, 90), false)
            local maxW = w - S(20) - S(50)
            if o then
                D.TextFit(EOCSB.GetOfficerLine(o, ply), "symchars.body.bold", S(20), h / 2 + S(3), ply and D.Col("text") or D.Col("muted"), maxW, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            else
                D.Text(L.vacant, "symchars.body.bold", S(20), h / 2 + S(3), D.Col("faint"), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            end
            D.TextFit(rank.name, "symchars.tiny", S(20), h / 2 + S(4), rc, maxW, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            D.Text(rank.short, "symchars.tiny.bold", w - S(16), h / 2, D.Col("dim"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            return true
        end
        row.OnCursorEntered = function() D.Sound("hover") end
        row.DoClick = function() D.Sound("click") open() end
    end

    local btn = D.Button(col, L.manage, "default", open)
    btn:Dock(TOP)
    btn:DockMargin(0, S(14), 0, 0)
    btn:SetTall(S(46))
end

---------------------------------------------------------------------------------------------------------------
-- Rechte Spalte: Informationen (Kennzahl-Karten)
---------------------------------------------------------------------------------------------------------------
local function InfoCard(col, h, valueFn, label)
    local p = vgui.Create("DPanel", col)
    p:Dock(TOP)
    p:SetTall(h)
    p:DockMargin(0, 0, 0, S(6))
    p.Paint = function(_, w, hh)
        local value, barCol, sub, tint = valueFn()
        barCol = barCol or D.Accent()
        D.Box(0, 0, w, hh, D.fill.card)
        D.Outline(0, 0, w, hh, D.Col("line"))
        D.Box(0, 0, S(3), hh, barCol)
        D.TextFit(value, "symchars.h1", S(18), S(6), tint and barCol or D.Col("text"), w - S(30))
        D.TextFit(string.upper(sub or label), "symchars.tiny.bold", S(18), hh - S(26), D.Col("muted"), w - S(30))
    end
end

local function BuildInfo(col)
    ColumnHead(col, L.info)
    local h = S(80)
    InfoCard(col, h, function()
        local level, name, c = DefconInfo()
        if not level then return "DEFCON -", D.Col("muted"), L.defcon_unknown, true end
        return "DEFCON " .. level, c, name ~= "" and name or L.defcon, true
    end)
    InfoCard(col, h, function() return GetGlobalString("EOCSB_Location", CFG.DefaultLocation) end, L.location)
    InfoCard(col, h, function() return CFG.GalacticYear .. "  " .. os.date("%H:%M") end, L.time)
    InfoCard(col, h, function() return tostring(player.GetCount()), D.Col("green") end, L.troops)
    InfoCard(col, h, function() return tostring(SecurityCount()), D.Col("red") end, L.security)
    InfoCard(col, h, function() return EOCSB.FormatTime(CurTime()) end, L.optime)
end

---------------------------------------------------------------------------------------------------------------
-- Hauptfenster
---------------------------------------------------------------------------------------------------------------
local BOARD = {}

function BOARD:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetAlpha(0)
    self:AlphaTo(255, 0.12)

    self.left = vgui.Create("DPanel", self)
    self.left.Paint = nil
    BuildCommand(self.left)

    self.right = vgui.Create("DPanel", self)
    self.right.Paint = nil
    BuildInfo(self.right)

    self.center = vgui.Create("DPanel", self)
    self.center.Paint = nil
    ColumnHead(self.center, L.list)
    self.scroll = D.Scroll(self.center)
    self.scroll:Dock(FILL)
    self.nextCheck = 0
end

function BOARD:PerformLayout(w, h)
    local bar = BarH()
    local x0, x1 = S(150), w - S(56)
    local y0 = bar + S(34) + S(46)
    local y1 = h - S(60)
    local sideW = math.min(S(340), floor((x1 - x0) * 0.22))
    local gap = S(36)

    self.left:SetPos(x0, y0)
    self.left:SetSize(sideW, y1 - y0)
    self.right:SetPos(x1 - sideW, y0)
    self.right:SetSize(sideW, y1 - y0)
    self.center:SetPos(x0 + sideW + gap, y0)
    self.center:SetSize(x1 - x0 - sideW * 2 - gap * 2, y1 - y0)
end

function BOARD:Think()
    if RealTime() < self.nextCheck then return end
    self.nextCheck = RealTime() + 0.5
    local sig = Signature()
    if sig == self.sig then return end
    self.sig = sig
    self.scroll:Clear()
    local index = 0
    for gi, group in ipairs(BuildGroups()) do
        UnitSection(self.scroll, group)
        for _, sub in ipairs(group.subList) do
            if not sub.isRoot then SubHeader(self.scroll, sub) end
            for _, ply in ipairs(sub.players) do
                index = index + 1
                PlayerRow(self.scroll, ply, sub.color, index)
            end
        end
    end
end

function BOARD:Paint(w, h)
    local UI = EOCSB.UI

    -- genau ein Blur + eine gleichmäßige Abdunklung über den ganzen Bildschirm
    if CFG.Blur ~= false then UI.Blur(self, 5) end
    draw.NoTexture()
    D.Box(0, 0, w, h, Color(4, 6, 9, CFG.DarkOverlay or 215))

    -- SymChars-Linie links
    UI.Rail(w, h)

    -- Kopfleiste
    local bar = BarH()
    D.Box(0, 0, w, bar, D.fill.bar)
    D.Box(0, bar - 1, w, 1, D.Accent(140))

    -- Server-Logo in der Mitte
    local mat = EOCSB.Logo()
    if mat then
        local lh = bar - S(16)
        local lw = floor(lh * mat:Width() / math.max(1, mat:Height()))
        surface.SetMaterial(mat)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(floor(w / 2 - lw / 2), S(8), lw, lh)
        draw.NoTexture()
    end

    -- rechts: eigener Charakter
    local lp = LocalPlayer()
    if IsValid(lp) then
        local rx = w - S(56)
        local infoW = math.min(S(360), floor(w * 0.2))
        D.Box(rx - infoW, S(16), 1, bar - S(32), D.Col("line2"))
        local name = EOCSB.GetName(lp)
        local f = EOCSB.GetFaction(lp)
        local sub = EOCSB.GetRankName(lp) .. (f and ("  ·  " .. f.name) or "")
        D.TextFit(name, "symchars.body.bold", rx, bar / 2 - S(2), D.Col("text"), infoW - S(16), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        D.TextFit(sub, "symchars.tiny", rx, bar / 2 + S(2), EOCSB.GetRankColor(lp) or D.Col("dim"), infoW - S(16), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        D.Aurebesh(name, "s", rx, bar / 2 + S(22), D.Alpha(D.Col("dim"), 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, infoW - S(16))
    end

    -- Seitentitel
    local ty = bar + S(34)
    D.Text(string.upper(L.page_title), "symchars.h4", S(150), ty, D.Col("dim"))
    D.Aurebesh(L.page_title, "s", S(150), ty + S(22), D.Alpha(D.Col("dim"), 100))
    D.Text(player.GetCount() .. " " .. string.upper(L.list_online), "symchars.h4", w - S(56), ty, D.Col("dim"), TEXT_ALIGN_RIGHT)

    -- Fußzeile
    D.Box(S(150), h - S(46), w - S(206), 1, D.Col("line2"))
    D.Text(string.upper(L.list_hint), "symchars.h4", S(150), h - S(38), D.Col("muted"))
    D.Aurebesh(L.list_hint, "s", w - S(56), h - S(34), D.Alpha(D.Col("dim"), 100), TEXT_ALIGN_RIGHT)
end

vgui.Register("eocsb.Board", BOARD, "EditablePanel")

function EOCSB.OpenScoreboard()
    if IsValid(EOCSB.Board) then EOCSB.Board:Remove() end
    EOCSB.Board = vgui.Create("eocsb.Board")
    if CFG.MouseOnOpen then
        EOCSB.Board:MakePopup()
        EOCSB.Board:SetKeyboardInputEnabled(false)
    end
end

function EOCSB.CloseScoreboard()
    if IsValid(EOCSB.Board) then EOCSB.Board:Remove() end
    EOCSB.Board = nil
end

hook.Add("ScoreboardShow", "EOCSB_Scoreboard", function()
    if not EOCSB.HasDesign() then return end -- ohne SymChars bleibt das normale Scoreboard
    EOCSB.OpenScoreboard()
    return true
end)

hook.Add("ScoreboardHide", "EOCSB_Scoreboard", function()
    if not IsValid(EOCSB.Board) then return end
    EOCSB.CloseScoreboard()
    return true
end)

-- ohne Maus beim Öffnen: Rechtsklick gibt die Maus frei
hook.Add("PlayerBindPress", "EOCSB_Scoreboard", function(_, bind, pressed)
    if not pressed or not IsValid(EOCSB.Board) or CFG.MouseOnOpen then return end
    if string.find(bind, "+attack2", 1, true) then
        EOCSB.Board:MakePopup()
        EOCSB.Board:SetKeyboardInputEnabled(false)
        return true
    end
end)

-- Standard-Scoreboards (FAdmin/DarkRP) abschalten
hook.Add("InitPostEntity", "EOCSB_RemoveOtherBoards", function()
    hook.Remove("ScoreboardShow", "FAdmin_scoreboard")
    hook.Remove("ScoreboardHide", "FAdmin_scoreboard")
    -- altes Kraken BF2-Scoreboard (eigenes TAB + Officer-Menü) abschalten
    hook.Remove("ScoreboardShow", "BF2SB")
    hook.Remove("ScoreboardHide", "BF2SB")
    if not EOCSB.HasDesign() then
        print("[EoC Scoreboard] SymChars-Design (SYMUI) nicht gefunden - TAB-Menü ist aus.")
    end
end)
