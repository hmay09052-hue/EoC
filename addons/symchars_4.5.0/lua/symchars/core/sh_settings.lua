--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Ingame-Einstellungen
    Startwerte kommen aus sh_config.lua, Aenderungen werden in der Datenbank gespeichert und an alle gesendet.
-------------------------------------------------------------------------------------------------------------]]

symchars.settings = symchars.settings or {}

local S = symchars.settings
local U = symchars.util

S.values = S.values or {}
S.meta = {}
S.order = {}

S.categories = {
    { id = "general", name = "Allgemein" },
    { id = "design", name = "Design" },
    { id = "chars", name = "Charaktere" },
    { id = "rights", name = "Rechte in den Einheiten" },
    { id = "display", name = "Anzeige" },
    { id = "trainings", name = "Fortbildungen" },
    { id = "content", name = "Dokumente" },
}

local function Define(key, typ, category, label, desc, extra)
    local meta = extra or {}
    meta.key, meta.type, meta.category, meta.label, meta.desc = key, typ, category, label, desc
    S.meta[key] = meta
    S.order[#S.order + 1] = key
end

-- Allgemein
Define("openkey", "key", "general", "Menü-Taste", "Taste, mit der das Menü geöffnet und geschlossen wird (Feld anklicken, dann Taste drücken). Leer = keine Taste, nur Chatbefehl/Konsole.")
Define("chatcommands", "stringlist", "general", "Chatbefehle", "Befehle, die das Menü öffnen.")
Define("forcemenuondeath", "bool", "general", "Menü nach Tod", "Öffnet das Menü nach jedem Tod.")
Define("changesonpos", "bool", "general", "Wechsel ohne Respawn", "Bei Einheiten- oder Jobwechsel an Ort und Stelle bleiben.")
Define("communityName", "string", "general", "Community-Name", "Steht klein in Aurebesh links in der Menüleiste.", { max = 48 })

-- Design
Define("accentcolor", "color", "design", "Akzentfarbe", "Farbe für Rahmen, Markierungen und Buttons.")
Define("hologramcolor", "color", "design", "Hologrammfarbe", "Farbe der Hologramme in Menü und Welt.")
Define("backgroundurl", "image", "design", "Hintergrundbild", "Imgur-Link oder direkter https-Bildlink. Leer = Spielwelt.")
Define("blurbackground", "bool", "design", "Hintergrund weichzeichnen", "")
Define("darkoverlay", "number", "design", "Abdunklung", "0 bis 255.", { min = 0, max = 255 })
Define("usemusic", "bool", "design", "Menü-Musik", "")
Define("musicurl", "string", "design", "Musik-Link", "Direkter Link zu einer mp3/ogg oder ein Sound-Pfad.", { max = 300 })
Define("musicvolume", "number", "design", "Musik-Lautstärke", "0 bis 100.", { min = 0, max = 100 })

-- Charaktere
Define("usefactions", "bool", "chars", "Einheitensystem", "Aus = nur DarkRP-Jobs mit Whitelist.")
Define("useroleplayid", "bool", "chars", "RP-ID verwenden", "")
Define("usesurnamefield", "bool", "chars", "Nachnamen-Feld", "")
Define("minnamechars", "number", "chars", "Minimale Namenslänge", "", { min = 1, max = 32 })
Define("maxnamechars", "number", "chars", "Maximale Namenslänge", "", { min = 3, max = 64 })
Define("slotsdefault", "number", "chars", "Slots (Standard)", "Charakter-Slots für alle Spieler.", { min = 1, max = 20 })
Define("slotsbygroup", "slots", "chars", "Slots pro Usergroup", "Höchster passender Wert zählt.")
Define("designateddefaultfaction", "faction", "chars", "Standard-Einheit", "Hierhin kommen entlassene Charaktere.")
Define("defaultjob", "job", "chars", "Standard-Job", "Job für Charaktere ohne Einheit.")
Define("blockjobchange", "bool", "chars", "Jobwechsel sperren", "F4-Jobwechsel nur innerhalb der eigenen Einheit erlauben.")
Define("savemoney", "bool", "chars", "Geld pro Charakter", "Geld wird pro Charakter gespeichert.")
Define("rpidprefix", "string", "chars", "RP-ID Präfix", "z.B. CT-", { max = 12 })
Define("rpidlength", "number", "chars", "RP-ID Ziffern", "", { min = 1, max = 10 })
Define("rpidrules", "rpidrules", "chars", "RP-ID Sonderregeln", "Andere Präfixe für bestimmte Einheiten oder Jobs.")
Define("forbiddennames", "stringlist", "chars", "Verbotene Namen", "Teilwörter, die im Namen nicht vorkommen dürfen.")
Define("disabledvariables", "stringlist", "chars", "Deaktivierte Zusatzfelder", "z.B. nationality")
Define("nationalities", "nationalities", "chars", "Nationalitäten", "Auswahl bei der Erstellung und welche Jobs damit gesperrt sind.")

-- Rechte ab Rang (Rangname, mehrere mit Komma; gilt in jeder Einheit ab diesem Rang aufwärts)
local RIGHT_DESC = "Rangname, z.B. Sergeant (mehrere mit Komma). Gilt in jeder Einheit ab diesem Rang aufwärts. Leer = nur angehakte Rang-Rechte. Pro Einheit im Einheiten-Editor änderbar."
Define("rightpromotions", "string", "rights", "Befördern / Degradieren ab Rang", RIGHT_DESC, { max = 96 })
Define("rightkick", "string", "rights", "Entlassen ab Rang", RIGHT_DESC, { max = 96 })
Define("rightinvite", "string", "rights", "Aufnehmen ab Rang", RIGHT_DESC, { max = 96 })
Define("righttransfer", "string", "rights", "Versetzen ab Rang", RIGHT_DESC, { max = 96 })

-- Anzeige
Define("useoverheadhud", "bool", "display", "Namensschild über Spielern", "Zeigt Name und Rang (keine Einheit).")
Define("overheaddistance", "number", "display", "Namensschild-Reichweite", "", { min = 50, max = 1000 })
Define("displayroleplayid", "bool", "display", "RP-ID im DarkRP-Namen", "z.B. CT-7567 Rex")

-- Fortbildungen
Define("trainingsse", "bool", "trainings", "SSE-Fahrzeuge freischalten", "Fortbildungen schalten Fahrzeuge im SSE-Fahrzeugterminal frei.")
Define("trainingssefilter", "bool", "trainings", "Fahrzeuge ohne Fortbildung sperren", "Fahrzeuge einer Fortbildung sind ohne sie auch für den Job gesperrt.")
Define("trainingannounce", "bool", "trainings", "Bestanden ankündigen", "Meldung an die Einheit, wenn jemand eine Fortbildung besteht.")
Define("trainingfreigabe", "string", "trainings", "ID der Fortbildungs-Freigabe", "Wer diese Fortbildung hat, darf Fortbildungen eintragen.", { max = 48 })

-- Inhalte
Define("docsmaxblocks", "number", "content", "Max. Blöcke pro Dokument", "", { min = 20, max = 2000 })
Define("docsallowimages", "bool", "content", "Bilder in Dokumenten", "")

local colorCache = {}

function S.Default(key)
    local v = symchars.defaults and symchars.defaults[key]
    return v
end

function symchars.Config(key)
    local v = S.values[key]
    if v == nil then v = S.Default(key) end

    local meta = S.meta[key]
    if meta and meta.type == "color" then
        local cached = colorCache[key]
        if cached and cached.src == v then return cached.col end
        local col = U.TableToColor(v, Color(255, 255, 255))
        colorCache[key] = { src = v, col = col }
        return col
    end

    return v
end

-- Normalisiert einen Wert nach Typ. Gibt nil zurueck, wenn ungueltig.
function S.Normalize(key, value)
    local meta = S.meta[key]
    if not meta then return nil end
    local t = meta.type

    if t == "bool" then
        return value == true
    elseif t == "number" or t == "key" then
        local n = tonumber(value)
        if not n then return nil end
        n = math.floor(n)
        if meta.min and n < meta.min then n = meta.min end
        if meta.max and n > meta.max then n = meta.max end
        return n
    elseif t == "string" or t == "faction" or t == "job" then
        return U.Clean(value, meta.max or 96)
    elseif t == "image" then
        return U.ImageURL(value)
    elseif t == "color" then
        if not istable(value) then return nil end
        return U.ColorToTable(value)
    elseif t == "stringlist" then
        return U.StringList(value, 200, 64)
    elseif t == "slots" then
        local out = {}
        if istable(value) then
            for group, count in pairs(value) do
                local g = U.Clean(group, 32)
                local c = tonumber(count)
                if g ~= "" and c then out[g] = math.Clamp(math.floor(c), 0, 20) end
            end
        end
        return out
    elseif t == "nationalities" then
        local out, seen = {}, {}
        for _, n in ipairs(istable(value) and value or {}) do
            if istable(n) then
                local id = U.ID(n.id)
                if id ~= "" and not seen[id] then
                    seen[id] = true
                    out[#out + 1] = { id = id, name = U.Clean(n.name, 48) ~= "" and U.Clean(n.name, 48) or id, blockedjobs = U.StringList(n.blockedjobs, 64, 64) }
                end
            end
            if #out >= 20 then break end
        end
        return out
    elseif t == "rpidrules" then
        local out = {}
        if istable(value) then
            for _, rule in ipairs(value) do
                if istable(rule) then
                    out[#out + 1] = {
                        prefix = U.Clean(rule.prefix, 12),
                        length = U.Int(rule.length, 4, 1, 10),
                        units = U.IDList(rule.units, 64),
                        jobs = U.StringList(rule.jobs, 64, 64),
                    }
                end
                if #out >= 50 then break end
            end
        end
        return out
    end

    return nil
end

if CLIENT then
    symchars.net.Receive("settings", function(data)
        if not istable(data) then return end
        S.values = data
        colorCache = {}
        hook.Run("symchars_settings_changed")
    end)
end
