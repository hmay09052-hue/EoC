--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Charakterauswahl
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S
local U = symchars.util
local UT = symchars.utils

---------------------------------------------------------------------------------------------------------------
-- Karte
---------------------------------------------------------------------------------------------------------------
local CARD = {}

function CARD:Init()
    self:SetText("")
    self._hover = 0
    self._sel = 0
    self:SetCursor("hand")
end

function CARD:SetChar(char) self.char = char end
function CARD:SetCreate(free) self.create = true self.free = free end
function CARD:SetSelected(on) self.selected = on end

function CARD:OnCursorEntered() UI.Sound("hover") end
function CARD:DoClickInternal() UI.Sound("click") end

function CARD:Think()
    self._hover = UI.Approach(self._hover, self:IsHovered() and 1 or 0, 12)
    self._sel = UI.Approach(self._sel, self.selected and 1 or 0, 10)
end

function CARD:Paint(w, h)
    local accent = UI.Accent()
    local hv, sel = self._hover, self._sel
    local active = math.max(sel, hv * 0.45)

    UI.Box(0, 0, w, h, UI.Lerp(hv, Color(6, 8, 10, 215), Color(14, 17, 21, 230)))
    if sel > 0.01 then UI.Glow(0, 0, w, h, UI.Alpha(accent, 255 * sel), S(12), 1) end
    UI.Outline(0, 0, w, h, UI.Lerp(active, UI.col.line3, accent), sel > 0.5 and S(3) or S(2))

    local pad = S(22)

    if self.create then
        local col = self.free and accent or UI.col.muted
        UI.Text(self.free and "NEUEN CHARAKTER ERSTELLEN" or "KEIN FREIER SLOT", "symchars.h1", pad, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local r = S(24)
        if self.free then
            UI.RoundIcon("plus", w - r - S(40), h / 2, r, accent, UI.col.ink)
        else
            UI.Icon("lock", w - S(70), h / 2 - S(18), S(36), col)
        end
        UI.Outline(w - S(16), h / 2 - S(28), S(8), S(8), UI.Alpha(col, 200))
        UI.Box(w - S(16), h / 2 - S(10), S(8), S(8), col)
        UI.Box(w - S(16), h / 2 + S(4), S(8), S(14), UI.Alpha(col, 160))
        return true
    end

    local char = self.char
    if not char then return true end
    local faction = char:GetFaction()
    local nameW = w - pad * 2 - S(60)

    UI.TextFit(UT.BuildDisplayName(char), "symchars.name", pad, S(14), UI.col.text, nameW)
    UI.Aurebesh(UT.BuildDisplayName(char), "symchars.aure.small", pad + S(2), S(52), UI.Alpha(UI.col.dim, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, nameW)

    local rank = char:GetRankName()
    local line = rank ~= "" and rank or U.JobName(char.job)
    if faction then line = line .. "  ·  " .. faction.name end
    UI.TextFit(line, "symchars.body.bold", pad, S(72), faction and UI.Lerp(0.35, faction:GetColor(), UI.col.cyan) or UI.col.cyan, nameW)

    local rowY = S(106)
    UI.Icon("credits", pad, rowY, S(24), UI.col.text)
    UI.Text(U.FormatMoney(char.money), "symchars.body", pad + S(32), rowY + S(12), UI.col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    UI.Icon("clock", pad, rowY + S(32), S(24), UI.col.text)
    local hours = symchars.history.TotalHours(char.charID)
    local played = char._historyLoaded and U.FormatHours(hours) or ("zuletzt " .. U.FormatAgo(char.lastActive))
    UI.Text(played, "symchars.body", pad + S(32), rowY + S(44), UI.col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Häkchen-Badge bei Auswahl / aktiv gespielt
    local playing = LocalPlayer():GetCharacterID() == char.charID
    if sel > 0.05 or playing then
        local r = S(19)
        UI.Circle(w - S(58), S(36), r, UI.Alpha(accent, 255 * math.max(sel, playing and 0.6 or 0)), 28)
        UI.Icon("check", w - S(58) - r * 0.7, S(36) - r * 0.7, r * 1.4, UI.col.ink)
    end
    if playing then
        UI.Chip("aktiv", "symchars.tiny.bold", w - S(110), h - S(38), UI.col.ink, UI.col.green)
    end

    UI.EdgeMarks(w - S(16), S(14), h - S(28), UI.Lerp(active, UI.col.line3, accent), char.charID)
    return true
end

vgui.Register("symchars.CharCard", CARD, "DButton")

---------------------------------------------------------------------------------------------------------------
-- Akte (rechte Spalte)
---------------------------------------------------------------------------------------------------------------
local function PaintTab(x, y, text, active)
    local tw = UI.TextSize(string.upper(text), "symchars.h4") + S(40)
    local th = S(32)
    UI.Cut(x, y, tw, th, active and UI.col.cream or UI.Alpha(UI.col.slate, 230), S(14), "tr")
    UI.Box(x, y, S(4), th, active and UI.Accent() or UI.col.line2)
    UI.Text(string.upper(text), "symchars.h4", x + S(16), y + th / 2, active and UI.col.ink or UI.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    return th
end

local function Dossier(panel, w, h, char)
    UI.Cut(0, 0, w, h, Color(9, 12, 16, 228), S(18), "tlbr")
    UI.CutOutline(0, 0, w, h, UI.col.line2, S(18), "tlbr")
    if not char then
        UI.Text("KEIN CHARAKTER", "symchars.h2", w / 2, h / 2, UI.col.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local pad = S(22)
    local y = S(18)
    local faction = char:GetFaction()

    y = y + PaintTab(pad, y, "Akte", true) + S(14)

    local function Row(label, value, col)
        UI.Text(string.upper(label), "symchars.tiny.bold", pad, y, UI.col.muted)
        surface.SetDrawColor(UI.col.line)
        for dx = pad + S(110), w - pad, S(6) do surface.DrawRect(dx, y + S(12), S(2), 1) end
        y = y + S(18)
        UI.TextFit(value, "symchars.body", pad + S(2), y, col or UI.col.text, w - pad * 2)
        y = y + S(30)
    end

    Row("Name", char.name)
    if symchars.Config("useroleplayid") then Row("RP-ID", UT.BuildRoleplayID(char) ~= "" and UT.BuildRoleplayID(char) or "-") end
    if symchars.Config("usefactions") then
        Row("Einheit", faction and symchars.factions.GetDisplayName(faction) or "-", faction and faction:GetColor())
        Row("Rang", char:GetRankName() ~= "" and char:GetRankName() or "-")
    else
        Row("Job", U.JobName(char.job))
    end

    y = y + S(6)
    y = y + PaintTab(pad, y, "Dienst", false) + S(12)

    local cx = pad
    local function Chip(text, fg, bg)
        local cw = UI.TextSize(string.upper(text), "symchars.tiny.bold") + S(14)
        if cx + cw > w - pad then cx = pad y = y + S(30) end
        local pw = UI.Chip(text, "symchars.tiny.bold", cx, y, fg, bg)
        cx = cx + pw + S(6)
    end
    if faction then Chip(faction.short ~= "" and faction.short or faction.name, UI.col.text, UI.Darken(faction:GetColor(), 0.45)) end
    if char:GetRankName() ~= "" then Chip(char:GetRankName(), UI.col.ink, UI.Accent()) end
    if char:IsCustom() then Chip("Custom", UI.col.text, Color(70, 76, 160)) end
    local count = 0
    for id in pairs(char:GetTrainings()) do
        local t = symchars.trainings.Get(id)
        if t and char:HasTraining(id) then
            count = count + 1
            if count <= 8 then Chip(t.short ~= "" and t.short or t.name, UI.col.ink, t.color or UI.col.cyan) end
        end
    end
    if count > 8 then Chip("+" .. (count - 8), UI.col.text, UI.col.panel3) end
    y = y + S(40)

    y = y + PaintTab(pad, y, "Statistik", false) + S(12)
    local hours = symchars.history.TotalHours(char.charID)
    Row("Spielzeit", char._historyLoaded and U.FormatHours(hours) or "lädt…")
    Row("Credits", U.FormatMoney(char.money))
    Row("Erstellt", U.FormatDate(char.createdAt))

    local desc = char:GetData("description", "")
    if desc ~= "" and y < h - S(90) then
        y = y + S(4)
        y = y + PaintTab(pad, y, "Beschreibung", false) + S(10)
        local lines = math.max(1, math.floor((h - y - S(16)) / S(24)))
        UI.DrawWrapped(desc, "symchars.small", pad, y, w - pad * 2, UI.col.dim, lines)
    end
end

---------------------------------------------------------------------------------------------------------------
-- Seite
---------------------------------------------------------------------------------------------------------------
local function Build(parent, opts)
    local page = vgui.Create("DPanel", parent)
    page:Dock(FILL)
    page.Paint = nil

    local list = UI.Scroll(page)
    local model = UI.HoloModel(page, "solid")
    model:SetSpin(0)
    local dossier = vgui.Create("DPanel", page)
    local play = UI.Button(page, "Spielen", "primary")
    play:SetFont("symchars.h2")
    play:SetIcon("arrow_right")
    local delete = UI.Button(page, "Löschen", "danger")
    delete:SetFont("symchars.h3")
    delete:SetIcon("trash")

    local selected

    local function Select(char)
        selected = char
        for _, card in ipairs(list:GetCanvas():GetChildren()) do
            if card.SetSelected then card:SetSelected(card.char ~= nil and char ~= nil and card.char.charID == char.charID) end
        end
        if char then
            model:SetHoloModel(char.model)
            symchars.history.Request(char.charID)
        else
            model:SetHoloModel("")
        end
        local playing = char and LocalPlayer():GetCharacterID() == char.charID
        play:SetVisible(char ~= nil)
        play:SetText(playing and "Weiterspielen" or "Spielen")
        delete:SetVisible(char ~= nil and not playing)
    end

    local function Rebuild()
        if not IsValid(list) then return end
        list:Clear()
        local chars = symchars.chars.GetByOwner(LocalPlayer():SteamID64())
        local slots = UT.GetSlots(LocalPlayer())
        local keep

        for _, char in ipairs(chars) do
            local card = vgui.Create("symchars.CharCard", list)
            card:Dock(TOP)
            card:DockMargin(S(14), S(14), S(18), S(10))
            card:SetTall(S(186))
            card:SetChar(char)
            card.DoClick = function() Select(char) end
            card.DoDoubleClick = function() Select(char) play:DoClick() end
            if selected and selected.charID == char.charID then keep = char end
        end

        local create = vgui.Create("symchars.CharCard", list)
        create:Dock(TOP)
        create:DockMargin(S(14), S(14), S(18), S(14))
        create:SetTall(S(92))
        create:SetCreate(#chars < slots)
        create.DoClick = function()
            if #chars >= slots then
                symchars.Notify("Du hast keinen freien Slot (" .. #chars .. "/" .. slots .. ").", "error")
                return
            end
            UI.menu:ShowPage("create")
        end

        local current = LocalPlayer():GetCharacter()
        Select(keep or (current and symchars.chars.Get(current.charID)) or chars[1])
    end

    dossier.Paint = function(_, w, h) Dossier(dossier, w, h, selected) end

    play.DoClick = function()
        if not selected then return end
        if LocalPlayer():GetCharacterID() == selected.charID then
            UI.CloseMenu()
            return
        end
        symchars.net.SendToServer("char_select", { id = selected.charID })
        play:SetEnabled(false)
        play:SetText("Lädt…")
        timer.Simple(4, function()
            if IsValid(play) then
                play:SetEnabled(true)
                play:SetText("Spielen")
            end
        end)
    end

    delete.DoClick = function()
        if not selected then return end
        local char = selected
        UI.Confirm("Charakter löschen", "Möchtest du '" .. UT.BuildDisplayName(char) .. "' wirklich löschen? Das kann nicht rückgängig gemacht werden.", function()
            symchars.net.SendToServer("char_delete", { id = char.charID })
        end, nil, "Löschen")
    end

    page.PerformLayout = function(_, w, h)
        local leftW = math.min(S(600), w * 0.34)
        local rightW = math.min(S(470), w * 0.27)
        list:SetPos(0, 0)
        list:SetSize(leftW, h)
        dossier:SetPos(w - rightW, 0)
        dossier:SetSize(rightW, h - S(150))
        model:SetPos(leftW + S(20), 0)
        model:SetSize(w - leftW - rightW - S(40), h)
        play:SetSize(rightW, S(68))
        play:SetPos(w - rightW, h - S(68))
        delete:SetSize(rightW, S(48))
        delete:SetPos(w - rightW, h - S(68) - S(60))
    end

    hook.Add("symchars_char_updated", page, function() Rebuild() end)
    hook.Add("symchars_chars_synced", page, function() Rebuild() end)
    Rebuild()
    if #symchars.chars.GetByOwner(LocalPlayer():SteamID64()) == 0 and opts.autoCreate ~= false then
        timer.Simple(0, function() if IsValid(UI.menu) and UI.menu.pageId == "characters" then UI.menu:ShowPage("create") end end)
    end
end

UI.RegisterPage({ id = "characters", name = "Charaktere", order = 1, build = Build })

symchars.net.Receive("char_selected", function()
    UI.CloseMenu()
end)
