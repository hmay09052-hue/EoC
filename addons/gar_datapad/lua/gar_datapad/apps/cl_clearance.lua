--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Freigaben (Admins und ab GrantMinLevel)
    Sicherheitsstufen von Hand vergeben oder wieder auf "automatisch (Rang)" stellen.
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S
local CFG = GAR_DP.Config

local function RulesFor(char)
    local faction = char:GetFaction()
    if faction then
        local chain = { faction }
        for _, anc in ipairs(symchars.factions.GetAncestors(faction) or {}) do chain[#chain + 1] = anc end
        for _, f in ipairs(chain) do
            if CFG.ClearanceByUnit[f.uniqueID] then return CFG.ClearanceByUnit[f.uniqueID], f.name end
        end
    end
    return CFG.ClearanceByRank, "Standard"
end

local function RuleRankName(faction, rank)
    if isnumber(rank) then
        local data = faction and faction:GetRank(rank)
        return data and (data.name .. " (" .. rank .. ")") or ("Rang " .. rank)
    end
    return tostring(rank)
end

local function BuildDetail(parent, char)
    parent:Clear()
    D.PersonHeader(parent, char)
    local maxGrant = GAR_DP.MaxGrant(LocalPlayer())

    local box = vgui.Create("DPanel", parent)
    box:Dock(TOP)
    box:SetTall(S(130))
    box:DockMargin(0, S(6), 0, 0)
    box.Paint = function(_, w, h)
        local tp = char:GetPlayer()
        local auto = GAR_DP.AutoClearance(char, IsValid(tp) and (GAR_DP.JobOf(tp)) or nil)
        local manual = GAR_DP.manual[char:GetID()]
        local final = IsValid(tp) and GAR_DP.Clearance(tp) or GAR_DP.CharClearance(char)
        local half = (w - S(20)) / 2
        local la, lf = GAR_DP.LevelData(auto), GAR_DP.LevelData(final)
        local y = 0
        D.KeyValue("Automatisch (Rang / Einheit / Job)", "Stufe " .. auto .. "  ·  " .. la.name, 0, y, half, la.color)
        D.KeyValue("Aktuell gültig", "Stufe " .. final .. "  ·  " .. lf.name, half + S(20), y, half, lf.color)
        y = y + S(48)
        D.KeyValue("Von Hand", manual and ("Stufe " .. manual.level .. "  ·  von " .. (manual.by or "?") .. ", " .. GAR_DP.FormatDate(manual.at, true)) or "Nicht gesetzt", 0, y, w)
        if IsValid(tp) and GAR_DP.IsAdmin(tp) then
            D.Text("Admin: hat immer Stufe 6.", "gdp.small", 0, y + S(50), D.col.yellow)
        end
    end

    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(S(56))
    row:DockMargin(0, S(6), 0, S(10))
    row.Paint = nil

    local field = D.Field(row, "Stufe von Hand setzen", S(34), LEFT)
    field:SetWide(S(360))
    field:DockMargin(0, 0, S(10), 0)
    local combo = D.Combo(field)
    combo:Dock(FILL)
    local manual = GAR_DP.manual[char:GetID()]
    combo:AddChoice("Automatisch (nach Rang)", 0, not manual)
    for lvl = 1, maxGrant do
        local ld = GAR_DP.LevelData(lvl)
        combo:AddChoice("Stufe " .. lvl .. "  ·  " .. ld.name, lvl, manual and manual.level == lvl, ld.color)
    end

    local btnWrap = vgui.Create("DPanel", row)
    btnWrap:Dock(LEFT)
    btnWrap:SetWide(S(200))
    btnWrap:DockPadding(0, S(20), 0, 0)
    btnWrap.Paint = nil
    local save = D.Button(btnWrap, "Übernehmen", "primary", function()
        GAR_DP.Request("clearance_set", { charID = char:GetID(), level = combo:GetSelectedData() or 0 }, function(res)
            if res then GAR_DP.Notify("Freigabe für " .. D.CharName(char) .. " gespeichert.", "info") end
        end)
    end)
    save:Dock(FILL)

    -- Regeln der Einheit
    local rules, source = RulesFor(char)
    local ruleBox = vgui.Create("DPanel", parent)
    ruleBox:Dock(FILL)
    ruleBox.Paint = function(_, w, h)
        D.Section("Rangregeln  ·  " .. source, 0, 0, w)
        local y = S(32)
        local faction = char:GetFaction()
        for _, rule in ipairs(rules or {}) do
            if y > h - S(20) then break end
            local ld = GAR_DP.LevelData(rule.level)
            D.Text("ab " .. RuleRankName(faction, rule.rank), "gdp.small", 0, y, D.col.dim)
            D.LevelChip(rule.level, w * 0.45, y - S(2))
            D.Text(ld.name, "gdp.small", w * 0.45 + S(70), y, ld.color)
            y = y + S(22)
        end
        if y < h - S(40) then
            D.DrawWrapped("Regeln werden in lua/gar_datapad/sh_config.lua festgelegt (ClearanceByRank, ClearanceByUnit, ClearanceByJob). Eine Stufe von Hand ersetzt die automatische Stufe.", "gdp.tiny", 0, y + S(8), w, D.col.muted)
        end
    end
end

GAR_DP.RegisterApp({
    id = "clearance",
    short = "Freigaben",
    name = "Freigaben",
    desc = "Sicherheitsstufen 1 bis 6 einsehen und von Hand vergeben. Nur Oberkommando und Admins.",
    icon = "key",
    order = 7,
    build = function(parent)
        local selected
        local left = vgui.Create("DPanel", parent)
        left:Dock(LEFT)
        left:SetWide(math.floor(parent:GetWide() * 0.3))
        left:DockMargin(0, 0, S(14), 0)
        left.Paint = nil

        local right = vgui.Create("DPanel", parent)
        right:Dock(FILL)
        right.Paint = function(_, w, h) D.Frame(0, 0, w, h) end
        right:DockPadding(S(14), S(12), S(14), S(12))

        local list = D.CharList(left, {
            onSelect = function(char) selected = char BuildDetail(right, char) end,
            isSelected = function(char) return selected and selected:GetID() == char:GetID() end,
            extra = function(row, w, h)
                local m = GAR_DP.manual[row.char:GetID()]
                if m then
                    local cw = D.ChipSize("S" .. m.level)
                    D.LevelChip(m.level, w - cw - S(8), S(6), true)
                end
            end,
        })
        list:Dock(FILL)
        hook.Add("gar_datapad_manual", list, function() if selected then BuildDetail(right, selected) end end)

        -- Uebersicht der Stufen
        local overview = vgui.Create("DPanel", right)
        overview:Dock(FILL)
        overview.Paint = function(_, w, h)
            D.Heading("Sicherheitsstufen", "gdp.h1", 0, 0, D.col.text)
            local y = S(56)
            for lvl = 1, 6 do
                local ld = GAR_DP.LevelData(lvl)
                D.Box(0, y, w, S(48), D.col.panel2)
                D.Box(0, y, S(4), S(48), ld.color)
                D.Text(tostring(lvl), "gdp.h1", S(18), y + S(24), ld.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                D.Text(string.upper(ld.name), "gdp.h3", S(56), y + S(24), D.col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                y = y + S(54)
            end
            D.DrawWrapped("Wähle links eine Person, um ihre Freigabe zu ändern.", "gdp.small", 0, y + S(6), w, D.col.muted)
        end
    end,
})
