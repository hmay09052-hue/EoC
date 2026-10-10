--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - Officer-System (Client + Menü)
-------------------------------------------------------------------------------------------------------------]]

EOCSB.OfficerData = EOCSB.OfficerData or {}

local CFG = EOCSB.Config
local L = CFG.Lang

local ACTION_JOIN, ACTION_LEAVE, ACTION_ASSIGN, ACTION_CLEAR = 1, 2, 3, 4
EOCSB.OFFICER_JOIN, EOCSB.OFFICER_LEAVE, EOCSB.OFFICER_ASSIGN, EOCSB.OFFICER_CLEAR = ACTION_JOIN, ACTION_LEAVE, ACTION_ASSIGN, ACTION_CLEAR

local _sidCache, _sidCacheAt = {}, 0
local function FindPlayerBySID(sid)
    if RealTime() - _sidCacheAt > 1 then
        _sidCache = {}
        for _, p in ipairs(player.GetAll()) do _sidCache[p:SteamID64() or ""] = p end
        _sidCacheAt = RealTime()
    end
    local p = _sidCache[sid]
    return IsValid(p) and p or nil
end

-- Daten ({ sid, name }) und Spieler (nil = offline) eines Postens
function EOCSB.GetOfficerHolder(rankId)
    local o = EOCSB.OfficerData[rankId]
    if not o then return nil end
    return o, FindPlayerBySID(o.sid)
end

function EOCSB.GetPlayerOfficerRank(ply)
    if not IsValid(ply) then return nil end
    local sid = ply:SteamID64() or ""
    for _, r in ipairs(CFG.OfficerRanks or {}) do
        local o = EOCSB.OfficerData[r.id]
        if o and o.sid == sid then return r end
    end
end

function EOCSB.IsOfficer(ply)
    return EOCSB.GetPlayerOfficerRank(ply) ~= nil
end

-- Name des Officers (ohne Rang davor)
function EOCSB.GetOfficerLine(o, ply)
    if IsValid(ply) then return EOCSB.GetName(ply) end
    return o and o.name or ""
end

function EOCSB.CanEnterOfficers()
    local lp = LocalPlayer()
    if EOCSB.IsAdmin(lp) then return true end
    if not CFG.OfficerSelfAssign then return false end
    local allowed = CFG.OfficerAllowedGroups or {}
    if #allowed == 0 then return true end
    return EOCSB.InGroupList(lp, allowed)
end

-- spiegelt die Server-Regeln, damit nur funktionierende Knöpfe erscheinen
function EOCSB.OfficerRuleOk(ply, rank)
    if EOCSB.IsAdmin(LocalPlayer()) and CFG.OfficerAdminIgnoresJobs then return true end
    return EOCSB.OfficerAllowed(ply, rank)
end

function EOCSB.SendOfficerAction(action, rankId, target)
    net.Start("EOCSB_OfficerAction")
    net.WriteUInt(action, 3)
    net.WriteString(rankId)
    if action == ACTION_ASSIGN then net.WriteEntity(target) end
    net.SendToServer()
end

net.Receive("EOCSB_OfficerSync", function()
    local data = {}
    for _ = 1, net.ReadUInt(8) do
        local id = net.ReadString()
        data[id] = { sid = net.ReadString(), name = net.ReadString() }
    end
    EOCSB.OfficerData = data
end)

net.Receive("EOCSB_OfficerAnnounce", function()
    local rank = EOCSB.GetOfficerRankDef(net.ReadString())
    local name = net.ReadString()
    local joined = net.ReadBool()
    if not rank then return end
    chat.AddText(rank.color, "[" .. L.officer_tag .. "] ", color_white, name,
        Color(200, 200, 200), " " .. (joined and L.officer_is_now or L.officer_no_longer) .. " ", rank.color, rank.name)
    if CFG.OfficerAnnounceSound and CFG.OfficerAnnounceSound ~= "" then
        surface.PlaySound(CFG.OfficerAnnounceSound)
    end
end)

---------------------------------------------------------------------------------------------------------------
-- Menü
---------------------------------------------------------------------------------------------------------------
function EOCSB.OpenOfficerMenu()
    if not EOCSB.HasDesign() then return end
    local UI = EOCSB.UI
    local D = EOCSB.D
    local S = D.S
    if IsValid(EOCSB.OfficerPanel) then EOCSB.OfficerPanel:Remove() end

    local frame = D.Frame(L.officer_title, S(1060), S(700))
    EOCSB.OfficerPanel = frame

    local isAdmin = EOCSB.IsAdmin(LocalPlayer())
    local canEnter = EOCSB.CanEnterOfficers()
    local selected = nil

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body.Paint = nil

    -- Links: Soldaten -----------------------------------------------------------------------------------------
    local left = vgui.Create("DPanel", body)
    left:Dock(LEFT)
    left:DockMargin(0, 0, S(24), 0)
    left.Paint = function(_, w, h)
        D.Section(L.officer_players, 0, 0, w)
        if canEnter then D.TextFit(L.officer_hint, "symchars.tiny", 0, h - S(18), UI.col.muted, w) end
    end
    left:DockPadding(0, S(40), 0, canEnter and S(26) or 0)

    local plist = D.Scroll(left)
    plist:Dock(FILL)

    local function BuildPlayerList()
        plist:Clear()
        local players = player.GetAll()
        table.sort(players, function(a, b)
            local ra, rb = EOCSB.GetPlayerOfficerRank(a), EOCSB.GetPlayerOfficerRank(b)
            if (ra ~= nil) ~= (rb ~= nil) then return ra ~= nil end
            return EOCSB.GetName(a) < EOCSB.GetName(b)
        end)
        for _, ply in ipairs(players) do
            local rank = EOCSB.GetPlayerOfficerRank(ply)
            local btn = D.Button(plist, EOCSB.GetName(ply), "default", function()
                if not canEnter then return end
                selected = (selected == ply) and nil or ply
            end)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, S(6))
            btn:SetTall(S(50))
            btn:SetFont("symchars.body.bold")
            btn:SetAlign(TEXT_ALIGN_LEFT)
            btn:SetSubText(EOCSB.GetRankName(ply) .. (rank and ("  ·  " .. rank.name) or ""))
            btn.Think = function(s)
                s:SetSelected(IsValid(selected) and selected == ply)
            end
        end
    end

    -- Rechts: Posten ------------------------------------------------------------------------------------------
    local right = vgui.Create("DPanel", body)
    right:Dock(FILL)
    right.Paint = function(_, w) D.Section(L.officer_posts, 0, 0, w) end
    right:DockPadding(0, S(40), 0, 0)

    local slots = D.Scroll(right)
    slots:Dock(FILL)

    for _, rank in ipairs(CFG.OfficerRanks or {}) do
        local rowH = S(78)
        local row = vgui.Create("DPanel", slots)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, S(8))
        row:SetTall(rowH)

        local btnW, btnH = S(140), S(40)

        local function StateButton(getState)
            local b = D.Button(row, "", "default")
            b:SetFont("symchars.button.small")
            b.state = nil
            b.getState = getState
            -- wird von der Zeile aufgerufen (unsichtbare Panels führen kein Think aus)
            b.Refresh = function(s)
                s.state = s.getState()
                s:SetVisible(s.state ~= nil)
                if s.state then
                    s:SetLabel(s.state.label)
                    s:SetStyle(s.state.style)
                end
            end
            b.DoClick = function(s) if s.state then s.state.fn() end end
            return b
        end

        local primary = StateButton(function()
            local o = EOCSB.GetOfficerHolder(rank.id)
            local lp = LocalPlayer()
            local mine = o and o.sid == (lp:SteamID64() or "")
            if IsValid(selected) and selected ~= lp then
                if o and o.sid == selected:SteamID64() then return nil end
                if not EOCSB.OfficerRuleOk(selected, rank) then return nil end
                if not isAdmin and (o or not canEnter or EOCSB.GetPlayerOfficerRank(selected)) then return nil end
                local target = selected
                return { label = L.btn_assign, style = "primary", fn = function() EOCSB.SendOfficerAction(ACTION_ASSIGN, rank.id, target) end }
            end
            if mine then
                return { label = L.btn_leave, style = "default", fn = function() EOCSB.SendOfficerAction(ACTION_LEAVE, rank.id) end }
            end
            if not o and canEnter and EOCSB.OfficerRuleOk(lp, rank) then
                return { label = L.btn_join, style = "primary", fn = function() EOCSB.SendOfficerAction(ACTION_JOIN, rank.id) end }
            end
        end)

        local remove = StateButton(function()
            if not isAdmin then return nil end
            local o = EOCSB.GetOfficerHolder(rank.id)
            if not o or o.sid == (LocalPlayer():SteamID64() or "") then return nil end
            return { label = L.btn_remove, style = "danger", fn = function() EOCSB.SendOfficerAction(ACTION_CLEAR, rank.id) end }
        end)

        row.PerformLayout = function(_, w, h)
            local x = w - btnW
            remove:SetSize(btnW, btnH)
            remove:SetPos(x, (h - btnH) / 2)
            primary:SetSize(btnW, btnH)
            primary:SetPos(remove:IsVisible() and (x - btnW - S(8)) or x, (h - btnH) / 2)
        end
        row.Think = function(s)
            primary:Refresh()
            remove:Refresh()
            s:InvalidateLayout()
        end

        -- Karte wie die Kennzahlen in SymChars
        row.Paint = function(_, w, h)
            local o, ply = EOCSB.GetOfficerHolder(rank.id)
            local col = D.Readable(rank.color, 130)
            D.Box(0, 0, w, h, D.fill.card)
            D.Outline(0, 0, w, h, UI.col.line)
            D.Box(0, 0, S(3), h, col)
            local maxW = w - btnW * 2 - S(40)
            D.TextFit(string.upper(rank.name), "symchars.h3", S(16), S(8), col, maxW)
            if rank.hint then
                local tw = D.TextSize(string.upper(rank.name), "symchars.h3")
                D.Text(rank.hint, "symchars.tiny", S(16) + tw + S(10), S(16), UI.col.muted)
            end
            if o then
                local name = EOCSB.GetOfficerLine(o, ply)
                D.TextFit(name, "symchars.body.bold", S(16), h - S(14), ply and UI.col.text or UI.col.muted, maxW, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                if not ply then
                    local nw = D.TextSize(name, "symchars.body.bold")
                    D.Text(L.officer_offline, "symchars.tiny", S(16) + nw + S(10), h - S(17), UI.col.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                end
            else
                D.Text(L.officer_vacant, "symchars.body", S(16), h - S(14), UI.col.faint, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            end
        end
    end

    body.PerformLayout = function(_, w)
        left:SetWide(math.floor(w * 0.36))
    end

    local lastSig = ""
    local baseThink = frame.Think
    frame.Think = function(s)
        if baseThink then baseThink(s) end
        local sig = player.GetCount() .. ":"
        for _, r in ipairs(CFG.OfficerRanks or {}) do
            local o = EOCSB.OfficerData[r.id]
            sig = sig .. (o and o.sid or "-") .. ","
        end
        if sig ~= lastSig then
            lastSig = sig
            if not IsValid(selected) then selected = nil end
            BuildPlayerList()
        end
    end
end

net.Receive("EOCSB_OfficerOpen", function()
    EOCSB.OpenOfficerMenu()
end)
