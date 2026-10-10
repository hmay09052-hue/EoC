--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - Admin-Menü (Klick auf einen Spieler im TAB-Menü)
    Wie im alten Scoreboard: erkennt ULX / SAM / xAdmin / ServerGuard / FAdmin und zeigt nur Befehle,
    für die man im Admin-Mod die Berechtigung hat. Dazu Officer eintragen, Stummschalten, Profil, Kopieren.
-------------------------------------------------------------------------------------------------------------]]

local CFG = EOCSB.Config
local L = CFG.Lang


local AdminMods = {
    ulx = {
        detect = function() return ulx ~= nil end,
        target = function(ply) return "$" .. ply:UniqueID() end,
        hasPermission = function(perm)
            if not ULib or not ULib.ucl or not ULib.ucl.query then return false end
            local ok, res = pcall(ULib.ucl.query, LocalPlayer(), perm)
            return ok and res ~= nil and res ~= false
        end,
        commands = {
            goto = { cmd = { "ulx", "goto" }, perm = "ulx goto" }, bring = { cmd = { "ulx", "bring" }, perm = "ulx bring" },
            freeze = { cmd = { "ulx", "freeze" }, perm = "ulx freeze" }, unfreeze = { cmd = { "ulx", "unfreeze" }, perm = "ulx freeze" },
            kick = { cmd = { "ulx", "kick" }, perm = "ulx kick" }, ban = { cmd = { "ulx", "ban" }, perm = "ulx ban" },
            jail = { cmd = { "ulx", "jail" }, perm = "ulx jail" }, slay = { cmd = { "ulx", "slay" }, perm = "ulx slay" },
            gag = { cmd = { "ulx", "gag" }, perm = "ulx gag" }, strip = { cmd = { "ulx", "strip" }, perm = "ulx strip" },
            god = { cmd = { "ulx", "god" }, perm = "ulx god" }, spectate = { cmd = { "ulx", "spectate" }, perm = "ulx spectate" },
            slap = { cmd = { "ulx", "slap" }, perm = "ulx slap" },
        },
    },
    sam = {
        detect = function() return sam ~= nil end,
        target = function(ply) return ply:SteamID() end,
        hasPermission = function(perm)
            local lp = LocalPlayer()
            if not lp.HasPermission then return false end
            local ok, res = pcall(lp.HasPermission, lp, perm)
            return ok and res == true
        end,
        commands = {
            goto = { cmd = { "sam", "goto" }, perm = "goto" }, bring = { cmd = { "sam", "bring" }, perm = "bring" },
            freeze = { cmd = { "sam", "freeze" }, perm = "freeze" }, unfreeze = { cmd = { "sam", "unfreeze" }, perm = "unfreeze" },
            kick = { cmd = { "sam", "kick" }, perm = "kick" }, ban = { cmd = { "sam", "ban" }, perm = "ban" },
            jail = { cmd = { "sam", "jail" }, perm = "jail" }, slay = { cmd = { "sam", "slay" }, perm = "slay" },
            gag = { cmd = { "sam", "gag" }, perm = "gag" }, strip = { cmd = { "sam", "strip" }, perm = "strip" },
            god = { cmd = { "sam", "god" }, perm = "god" },
        },
    },
    fadmin = {
        detect = function() return FAdmin ~= nil end,
        target = function(ply) return tostring(ply:UserID()) end,
        hasPermission = function(perm)
            if not FAdmin or not FAdmin.Access or not FAdmin.Access.PlayerHasPrivilege then return false end
            local ok, res = pcall(FAdmin.Access.PlayerHasPrivilege, LocalPlayer(), perm)
            return ok and res == true
        end,
        commands = {
            goto = { cmd = { "fadmin", "goto" }, perm = "Teleport" }, bring = { cmd = { "fadmin", "bring" }, perm = "Teleport" },
            freeze = { cmd = { "fadmin", "freeze" }, perm = "Freeze" }, unfreeze = { cmd = { "fadmin", "unfreeze" }, perm = "Freeze" },
            kick = { cmd = { "fadmin", "kick" }, perm = "Kick" }, ban = { cmd = { "fadmin", "ban" }, perm = "Ban" },
            jail = { cmd = { "fadmin", "jail" }, perm = "Jail" }, slay = { cmd = { "fadmin", "slay" }, perm = "Slay" },
            gag = { cmd = { "fadmin", "voicemute" }, perm = "Voicemute" }, strip = { cmd = { "fadmin", "stripweapons" }, perm = "StripWeapons" },
            god = { cmd = { "fadmin", "god" }, perm = "God" }, spectate = { cmd = { "fspectate" }, perm = "FSpectate" },
            slap = { cmd = { "fadmin", "slap" }, perm = "Slap" },
        },
    },
    serverguard = {
        detect = function() return serverguard ~= nil end,
        target = function(ply) return tostring(ply:UniqueID()) end,
        hasPermission = function(perm)
            if not serverguard or not serverguard.player or not serverguard.player.HasPermission then return false end
            local ok, res = pcall(serverguard.player.HasPermission, serverguard.player, LocalPlayer(), perm)
            return ok and res == true
        end,
        commands = {
            goto = { cmd = { "sg", "goto" }, perm = "Goto" }, bring = { cmd = { "sg", "bring" }, perm = "Bring" },
            freeze = { cmd = { "sg", "freeze" }, perm = "Freeze" }, unfreeze = { cmd = { "sg", "freeze" }, perm = "Freeze" },
            kick = { cmd = { "sg", "kick" }, perm = "Kick" }, ban = { cmd = { "sg", "ban" }, perm = "Ban" },
            jail = { cmd = { "sg", "jail" }, perm = "Jail" }, slay = { cmd = { "sg", "slay" }, perm = "Slay" },
            gag = { cmd = { "sg", "gag" }, perm = "Gag" }, strip = { cmd = { "sg", "stripweapons" }, perm = "Strip Weapons" },
            god = { cmd = { "sg", "god" }, perm = "God mode" },
        },
    },
    xadmin = {
        detect = function() return xAdmin ~= nil end,
        target = function(ply) return ply:SteamID() end,
        hasPermission = function(perm)
            local lp = LocalPlayer()
            if not lp.xAdminHasPermission then return false end
            local ok, res = pcall(lp.xAdminHasPermission, lp, perm)
            return ok and res == true
        end,
        commands = {
            goto = { cmd = { "xadmin", "goto" }, perm = "goto" }, bring = { cmd = { "xadmin", "bring" }, perm = "bring" },
            freeze = { cmd = { "xadmin", "freeze" }, perm = "freeze" }, unfreeze = { cmd = { "xadmin", "unfreeze" }, perm = "unfreeze" },
            kick = { cmd = { "xadmin", "kick" }, perm = "kick" }, ban = { cmd = { "xadmin", "ban" }, perm = "ban" },
            jail = { cmd = { "xadmin", "jail" }, perm = "jail" }, slay = { cmd = { "xadmin", "slay" }, perm = "slay" },
            gag = { cmd = { "xadmin", "gag" }, perm = "gag" }, strip = { cmd = { "xadmin", "strip" }, perm = "strip" },
            god = { cmd = { "xadmin", "god" }, perm = "god" },
        },
    },
}

local ORDER = { "ulx", "sam", "xadmin", "serverguard", "fadmin" }

local detected, detectedAt = nil, 0
function EOCSB.GetAdminMod()
    if detected and RealTime() - detectedAt < 5 then return AdminMods[detected] end
    detected = nil
    for _, id in ipairs(ORDER) do
        if AdminMods[id].detect() then detected = id break end
    end
    detectedAt = RealTime()
    return detected and AdminMods[detected] or nil
end

function EOCSB.HasCommandPermission(cmdID)
    local mod = EOCSB.GetAdminMod()
    local data = mod and mod.commands[cmdID]
    if not data then return false end
    local ok, res = pcall(mod.hasPermission, data.perm)
    if not ok then return EOCSB.IsAdmin(LocalPlayer()) end
    return res
end

function EOCSB.ExecuteCommand(cmdID, target)
    if not IsValid(target) then return end
    local mod = EOCSB.GetAdminMod()
    local data = mod and mod.commands[cmdID]
    if not data then return end
    local args = {}
    for _, v in ipairs(data.cmd) do args[#args + 1] = v end
    args[#args + 1] = mod.target(target)
    RunConsoleCommand(unpack(args))
end

---------------------------------------------------------------------------------------------------------------
-- Fenster (SymChars-Stil)
---------------------------------------------------------------------------------------------------------------
local function Entries(target, UI)
    local sections = {}
    local function Section(title) local s = { title = title, items = {} } sections[#sections + 1] = s return s end

    -- Admin-Befehle
    local mod = EOCSB.GetAdminMod()
    if mod then
        local sec
        for _, cmd in ipairs(CFG.Commands or {}) do
            if mod.commands[cmd.id] and EOCSB.HasCommandPermission(cmd.id) then
                sec = sec or Section(L.cmd_admin)
                sec.items[#sec.items + 1] = { label = cmd.name, color = cmd.color, fn = function() EOCSB.ExecuteCommand(cmd.id, target) end }
            end
        end
    end

    -- Officer eintragen
    if EOCSB.CanEnterOfficers() then
        local isAdmin = EOCSB.IsAdmin(LocalPlayer())
        local sec
        for _, rank in ipairs(CFG.OfficerRanks or {}) do
            local o = EOCSB.GetOfficerHolder(rank.id)
            local already = o and o.sid == target:SteamID64()
            if not already and EOCSB.OfficerRuleOk(target, rank) and (isAdmin or (not o and not EOCSB.GetPlayerOfficerRank(target))) then
                sec = sec or Section(L.cmd_officer)
                sec.items[#sec.items + 1] = {
                    label = rank.name .. (o and "  (ersetzen)" or ""), color = rank.color,
                    fn = function()
                        if not IsValid(target) then return end
                        if target == LocalPlayer() and not o then
                            EOCSB.SendOfficerAction(EOCSB.OFFICER_JOIN, rank.id)
                        else
                            EOCSB.SendOfficerAction(EOCSB.OFFICER_ASSIGN, rank.id, target)
                        end
                    end,
                }
            end
        end
    end

    -- Allgemein
    local gen = Section(L.cmd_general)
    if target ~= LocalPlayer() then
        local muted = target:IsMuted()
        gen.items[#gen.items + 1] = { label = muted and "Stummschaltung aufheben" or "Stummschalten", color = muted and UI.col.green or UI.col.red,
            fn = function() if IsValid(target) then target:SetMuted(not target:IsMuted()) end end }
    end
    gen.items[#gen.items + 1] = { label = "Steam-Profil öffnen", color = UI.col.blue,
        fn = function() gui.OpenURL("https://steamcommunity.com/profiles/" .. (target:SteamID64() or "0")) end }
    gen.items[#gen.items + 1] = { label = "Name kopieren", fn = function() SetClipboardText(EOCSB.GetName(target)) end }
    gen.items[#gen.items + 1] = { label = "Job kopieren", fn = function() SetClipboardText(team.GetName(target:Team()) or "") end }
    gen.items[#gen.items + 1] = { label = "Usergroup kopieren", fn = function() SetClipboardText(target:GetUserGroup() or "") end }
    gen.items[#gen.items + 1] = { label = "SteamID kopieren", fn = function() SetClipboardText(target:SteamID() or "") end }
    gen.items[#gen.items + 1] = { label = "SteamID64 kopieren", fn = function() SetClipboardText(target:SteamID64() or "") end }
    return sections
end

function EOCSB.OpenCommandMenu(target)
    local UI = EOCSB.UI
    local S = EOCSB.D.S
    if IsValid(EOCSB.CommandPanel) then EOCSB.CommandPanel:Remove() end
    if not IsValid(target) then return end

    local sections = Entries(target, UI)
    local entryH, secH, headH = S(38), S(34), S(108)
    local panelW = S(330)
    local panelH = headH + S(16)
    for _, sec in ipairs(sections) do panelH = panelH + secH + #sec.items * (entryH + S(4)) end
    panelH = math.min(panelH, ScrH() - S(40))

    local mx, my = gui.MousePos()
    local panel = vgui.Create("DPanel")
    panel:SetSize(panelW, panelH)
    panel:SetPos(math.Clamp(mx + S(10), S(10), ScrW() - panelW - S(10)), math.Clamp(my - S(20), S(10), ScrH() - panelH - S(10)))
    panel:MakePopup()
    panel:SetKeyboardInputEnabled(false)
    panel:SetDrawOnTop(true)
    panel.canClose = false
    timer.Simple(0.15, function() if IsValid(panel) then panel.canClose = true end end)

    -- schließt bei Klick daneben
    panel.Think = function(s)
        if not IsValid(target) then s:Remove() return end
        if s.canClose and (input.IsMouseDown(MOUSE_LEFT) or input.IsMouseDown(MOUSE_RIGHT)) then
            local x, y = s:CursorPos()
            if x < 0 or y < 0 or x > s:GetWide() or y > s:GetTall() then s:Remove() end
        end
    end

    -- Fenster: dunkle Fläche, Rahmen, Akzent-Ecken, Name mit Aurebesh, Linie
    local D = EOCSB.D
    panel.Paint = function(_, w, h)
        if not IsValid(target) then return true end
        local name = EOCSB.GetName(target)
        D.PaintFrame(w, h, name)
        D.TextFit(EOCSB.GetRankName(target), "symchars.small.bold", S(22), S(80), EOCSB.GetRankColor(target) or D.Col("dim"), w * 0.5)
        D.Text(target:SteamID() or "", "symchars.tiny", w - S(22), S(82), D.Col("muted"), TEXT_ALIGN_RIGHT)
        return true
    end

    local scroll = D.Scroll(panel)
    scroll:SetPos(S(22), headH)
    scroll:SetSize(panelW - S(32), panelH - headH - S(16))

    for _, sec in ipairs(sections) do
        local head = vgui.Create("DPanel", scroll)
        head:Dock(TOP)
        head:SetTall(secH)
        head.Paint = function(_, w, h)
            D.Text(string.upper(sec.title), "symchars.h4", 0, h / 2 + S(2), D.Col("dim"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        for _, entry in ipairs(sec.items) do
            local btn = D.Button(scroll, entry.label, "default", function()
                panel:Remove()
                entry.fn()
            end)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, S(4))
            btn:SetTall(entryH)
            btn:SetFont("symchars.small.bold")
            btn:SetAlign(TEXT_ALIGN_LEFT)
            if entry.color then btn:SetAccentColor(entry.color) end
        end
    end

    EOCSB.CommandPanel = panel
end
