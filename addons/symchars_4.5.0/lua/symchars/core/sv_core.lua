--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Start, Erstsync, Befehle
-------------------------------------------------------------------------------------------------------------]]

local C = symchars.chars
local UT = symchars.utils

symchars.ready = false
local waiting = {}

local function SendInitial(ply)
    if not IsValid(ply) then return end
    symchars.settings.Sync(ply)
    symchars.factions.SyncAll(ply)
    symchars.trainings.SyncAll(ply)
    C.SyncAll(ply)
    symchars.whitelist.Sync(ply)
    symchars.holo.SyncAll(ply)
    symchars.net.Send("ready", { first = not ply.symchars_greeted }, ply)
    ply.symchars_greeted = true
end
symchars.SendInitial = SendInitial

local function Boot()
    local steps = {
        function(nextStep) symchars.db.Init(nextStep) end,
        function(nextStep) symchars.settings.Load(nextStep) end,
        function(nextStep) symchars.factions.Load(nextStep) end,
        function(nextStep) C.LoadAll(nextStep) end,
        function(nextStep) symchars.trainings.Load(nextStep) end,
        function(nextStep) symchars.whitelist.Load(nextStep) end,
        function(nextStep) symchars.docs.Load(nextStep) end,
    }
    local i = 0
    local function nextStep()
        i = i + 1
        if steps[i] then
            local ok, err = pcall(steps[i], nextStep)
            if not ok then
                ErrorNoHaltWithStack("[SymChars] Startfehler in Schritt " .. i .. ": " .. tostring(err) .. "\n")
                nextStep()
            end
            return
        end

        symchars.ready = true
        symchars.print("Version " .. symchars.version .. " bereit.")
        hook.Run("symchars_ready")

        for ply in pairs(waiting) do
            if IsValid(ply) then SendInitial(ply) end
        end
        waiting = {}

        -- Bei Lua-Refresh: aktive Charaktere der Spieler wiederherstellen
        for _, ply in ipairs(player.GetAll()) do
            local id = ply:GetNW2Int("symchars_charid", 0)
            if id ~= 0 and C.Get(id) then
                ply.symchars_char = C.Get(id)
                C.Get(id):StartSession()
            end
            SendInitial(ply)
        end

        if symchars.worldReady then symchars.holo.SpawnSaved() end
    end
    nextStep()
end

hook.Add("InitPostEntity", "symchars_world", function()
    symchars.worldReady = true
    if symchars.ready then symchars.holo.SpawnSaved() end
end)

if GAMEMODE then
    -- Lua-Refresh: Welt existiert bereits
    symchars.worldReady = true
end

timer.Simple(0, Boot)

symchars.net.Receive("hello", function(ply)
    if symchars.ready then
        SendInitial(ply)
    else
        waiting[ply] = true
    end
end, 3)

---------------------------------------------------------------------------------------------------------------
-- Menü öffnen
---------------------------------------------------------------------------------------------------------------
function symchars.OpenMenu(ply, tab, extra)
    local data = istable(extra) and extra or {}
    data.tab = tab
    symchars.net.Send("menu_open", data, ply)
end

local function IsMenuCommand(text)
    local lower = string.lower(string.Trim(text))
    for _, cmd in ipairs(symchars.Config("chatcommands") or {}) do
        if lower == string.lower(cmd) then return true end
    end
    return false
end

local function NamedAction(ply, action, search)
    local actor = ply:GetCharacter()
    local _, target = UT.FindCharByName(search)
    if not target then symchars.Notify(ply, "Charakter nicht gefunden.", "error") return end
    local def = C.GetAction(action)
    if not def or not C.HasActionPermission(action, ply, actor, target) then
        symchars.Notify(ply, "Dir fehlt die Berechtigung.", "error")
        return
    end
    local ok, err = def.Execute(ply, actor, target)
    if ok == false then symchars.Notify(ply, err or "Fehlgeschlagen.", "error") return end
    symchars.Notify(ply, def.Name .. ": " .. UT.BuildDisplayName(target), "succ")
end

hook.Add("PlayerSay", "symchars_commands", function(ply, text)
    if IsMenuCommand(text) then
        symchars.OpenMenu(ply, "characters")
        return ""
    end

    local cmd, rest = string.match(text, "^[/!](%S+)%s+(.+)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    if cmd == "promote" or cmd == "befördern" or cmd == "befo" .. "erdern" then
        NamedAction(ply, "promote", rest) return ""
    elseif cmd == "demote" or cmd == "degradieren" then
        NamedAction(ply, "demote", rest) return ""
    elseif cmd == "invite" or cmd == "einladen" then
        NamedAction(ply, "invite", rest) return ""
    end
end)

-- Ist die Menü-Taste F4, öffnet F4 nicht zusätzlich das DarkRP-F4-Menü
hook.Add("ShowSpare2", "symchars_f4", function(ply)
    if (symchars.Config("openkey") or 0) == KEY_F4 then return true end
end)

for _, name in ipairs({ "chars", "characters", "symchars" }) do
    concommand.Add(name, function(ply)
        if IsValid(ply) then symchars.OpenMenu(ply, "characters") end
    end)
end

-- Konsole: symchars_reload_data (lädt alle Daten neu)
concommand.Add("symchars_reload_data", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    symchars.ready = false
    Boot()
end)
