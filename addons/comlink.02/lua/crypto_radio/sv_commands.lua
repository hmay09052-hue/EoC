-- Chat-Befehle: /funk /vfunk /lfunk /vlfunk /akt /me /eakt /makt /scan

local cfg = CryptoRadio.Config
local Notify = CryptoRadio.Notify

local function Normalize(s)
    return string.lower(s):gsub("[%s_]", "")
end

-- Sucht einen Spieler anhand eines (Teil-)Namens
local function FindPlayer(sender, token)
    local norm = Normalize(token)
    if norm == "" then return nil, "Kein Empfänger angegeben." end

    local exact, starts, contains = {}, {}, {}
    for _, p in ipairs(player.GetAll()) do
        if p ~= sender then
            local n = Normalize(CryptoRadio.GetName(p))
            if n == norm then
                exact[#exact + 1] = p
            elseif string.sub(n, 1, #norm) == norm then
                starts[#starts + 1] = p
            elseif string.find(n, norm, 1, true) then
                contains[#contains + 1] = p
            end
        end
    end

    for _, list in ipairs({ exact, starts, contains }) do
        if #list == 1 then return list[1] end
        if #list > 1 then
            local names = {}
            for i = 1, math.min(#list, 5) do names[i] = CryptoRadio.GetName(list[i]) end
            return nil, "Mehrere Spieler gefunden für \"" .. token .. "\": " .. table.concat(names, ", ")
        end
    end

    return nil, "Kein Spieler gefunden für \"" .. token .. "\"."
end

local ALL_TOKENS = { ["*"] = true, ["alle"] = true, ["all"] = true }

-- Zerlegt "Empfänger Nachricht" -> Liste von Spielern, Nachricht
local function ParseRadio(sender, rest, range)
    rest = string.Trim(rest)
    if rest == "" then return nil, nil, "usage" end

    -- 1) Vollständiger Name (auch mit Leerzeichen) am Anfang, längster Treffer gewinnt
    local lowerRest = string.lower(rest)
    local best, bestLen
    for _, p in ipairs(player.GetAll()) do
        if p ~= sender then
            local n = string.lower(CryptoRadio.GetName(p))
            if #n > 0 and string.sub(lowerRest, 1, #n) == n then
                local nextChar = string.sub(rest, #n + 1, #n + 1)
                if (nextChar == " " or nextChar == "") and (not bestLen or #n > bestLen) then
                    best, bestLen = p, #n
                end
            end
        end
    end
    if best then
        return { best }, string.Trim(string.sub(rest, bestLen + 1))
    end

    -- 2) "Name mit Leerzeichen" in Anführungszeichen oder erstes Wort (Komma = mehrere)
    local token, msg = rest:match('^"([^"]+)"%s*(.*)$')
    if not token then
        token, msg = rest:match("^(%S+)%s*(.*)$")
    end
    if not token then return nil, nil, "usage" end

    -- Alle erreichbaren Empfänger
    if ALL_TOKENS[string.lower(token)] then
        local list = {}
        for _, p in ipairs(player.GetAll()) do
            if p ~= sender and not CryptoRadio.CanReceive(sender, p, range) then
                list[#list + 1] = p
            end
        end
        if #list == 0 then
            return nil, nil, "Kein Empfänger erreichbar."
        end
        return list, msg
    end

    local targets = {}
    for part in string.gmatch(token, "[^,]+") do
        local p, err = FindPlayer(sender, part)
        if not p then return nil, nil, err end
        targets[#targets + 1] = p
    end
    return targets, msg
end

local ACTION_USAGE = {
    akt  = "/akt <Aktion>",
    me   = "/me <Aktion>",
    eakt = "/eakt <technische Aktion>",
    makt = "/makt <medizinische Aktion>",
}

hook.Add("PlayerSay", "CryptoRadio_Commands", function(ply, text)
    local cmd, rest = text:match("^[/!](%S+)%s*(.*)$")
    if not cmd then return end

    cmd = string.lower(cmd)
    local def = cfg.Commands[cmd]
    if not def then return end

    rest = rest or ""

    -- Funk
    if def.radio then
        local targets, msg, err = ParseRadio(ply, rest, def.range)
        if err == "usage" or (targets and (not msg or string.Trim(msg) == "")) then
            Notify(ply, "Benutzung: /" .. cmd .. " <Empfänger> <Nachricht>   (mehrere: Name1,Name2 | alle: *)", true)
            return ""
        end
        if not targets then
            Notify(ply, err, true)
            return ""
        end

        CryptoRadio.Transmit(ply, targets, def.range, def.encrypted, msg)
        return ""
    end

    -- Aktionen
    local now = CurTime()
    if (ply.CryptoRadioNextAction or 0) > now then return "" end
    ply.CryptoRadioNextAction = now + cfg.ActionCooldown

    rest = rest:gsub("[\r\n\t]", " ")
    rest = string.Trim(rest)

    if def.scan then
        if not ply:Alive() then return "" end
        CryptoRadio.StartScan(ply, rest)
        return ""
    end

    if def.action then
        if rest == "" then
            Notify(ply, "Benutzung: " .. (ACTION_USAGE[def.action] or ("/" .. cmd .. " <Text>")), true)
            return ""
        end
        if (utf8.len(rest) or 0) > cfg.MaxLength then
            Notify(ply, "Der Text ist zu lang (max. " .. cfg.MaxLength .. " Zeichen).", true)
            return ""
        end
        CryptoRadio.SendAction(ply, def.action, rest, 0)
        return ""
    end
end)
