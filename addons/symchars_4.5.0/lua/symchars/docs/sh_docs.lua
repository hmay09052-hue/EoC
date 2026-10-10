--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Dokumente (wie Google Docs: mehrere Personen bearbeiten gleichzeitig, live)

    Dokument: { id, folder ("public" oder Einheit-ID), title, blocks = {...}, perms, createdBy, createdAt, updatedAt, updatedBy }
    Block:    { id, t, text, checked, src, w, cap, rows, align, color, indent }
        t = p | h1 | h2 | h3 | ul | ol | todo | quote | code | callout | hr | img | table

    Formatierung im Text:
        **fett**   *kursiv*   __unterstrichen__   ~~durchgestrichen~~   `code`
        {#ff8800|farbiger Text}   [Linktext](https://...)   \* = Zeichen ohne Formatierung

    Rechte:
        perms.read  = { mode = "all" | "unit" | "rank" | "units", units = {}, minRank = 0 }
        perms.write = { mode = "managers" | "unit" | "rank" | "units", units = {}, minRank = 0 }
        Ersteller und Dokument-Admins dürfen immer bearbeiten.
-------------------------------------------------------------------------------------------------------------]]

symchars.docs = symchars.docs or {}

local D = symchars.docs
local U = symchars.util
local F = symchars.factions
local A = symchars.authority

D.TYPES = {
    { id = "p", name = "Text" },
    { id = "h1", name = "Überschrift 1" },
    { id = "h2", name = "Überschrift 2" },
    { id = "h3", name = "Überschrift 3" },
    { id = "ul", name = "Aufzählung" },
    { id = "ol", name = "Nummerierung" },
    { id = "todo", name = "Checkliste" },
    { id = "quote", name = "Zitat" },
    { id = "callout", name = "Hinweisbox" },
    { id = "code", name = "Code / Funk" },
    { id = "hr", name = "Trennlinie" },
    { id = "img", name = "Bild" },
    { id = "table", name = "Tabelle" },
}

D.TEXT_TYPES = { p = true, h1 = true, h2 = true, h3 = true, ul = true, ol = true, todo = true, quote = true, code = true, callout = true }

local TYPESET = {}
for _, t in ipairs(D.TYPES) do TYPESET[t.id] = true end

D.READ_MODES = {
    { id = "all", name = "Alle Spieler" },
    { id = "unit", name = "Mitglieder der Einheit" },
    { id = "rank", name = "Einheit ab Mindestrang" },
    { id = "units", name = "Bestimmte Einheiten" },
}

D.WRITE_MODES = {
    { id = "managers", name = "Dokument-Verwalter der Einheit" },
    { id = "unit", name = "Alle Mitglieder der Einheit" },
    { id = "rank", name = "Einheit ab Mindestrang" },
    { id = "units", name = "Bestimmte Einheiten" },
}

local MAX_TEXT = 4000

function D.NewBlockID()
    return string.format("%x%x", math.random(0x1000, 0xffff), math.random(0x10000, 0xfffff))
end

function D.SanitizeBlock(raw)
    if not istable(raw) then return nil end
    local t = TYPESET[raw.t] and raw.t or "p"
    local b = { id = U.Clean(raw.id, 16), t = t }
    if b.id == "" or not string.match(b.id, "^[%w]+$") then b.id = D.NewBlockID() end

    if D.TEXT_TYPES[t] then
        b.text = U.Clean(raw.text, MAX_TEXT, t == "code" or t == "quote" or t == "callout" or t == "p")
        if t == "todo" then b.checked = raw.checked == true end
        if t == "ul" or t == "ol" or t == "todo" then b.indent = U.Int(raw.indent, 0, 0, 3) end
        if t == "callout" then
            local hex = U.Trim(raw.color)
            b.color = string.match(hex, "^#%x%x%x%x%x%x$") and hex or "#fcb249"
        end
        if t == "p" or t == "h1" or t == "h2" or t == "h3" then
            b.align = (raw.align == "c" or raw.align == "r") and raw.align or "l"
        end
    elseif t == "img" then
        b.src = U.ImageURL(raw.src)
        b.w = math.Clamp(tonumber(raw.w) or 1, 0.2, 1)
        b.cap = U.Clean(raw.cap, 200)
        b.align = (raw.align == "l" or raw.align == "r") and raw.align or "c"
    elseif t == "table" then
        b.rows = {}
        local rows = istable(raw.rows) and raw.rows or {}
        local cols = 1
        for r = 1, math.min(#rows, 30) do
            if istable(rows[r]) then cols = math.max(cols, math.min(#rows[r], 8)) end
        end
        for r = 1, math.max(1, math.min(#rows, 30)) do
            local row = {}
            local src = istable(rows[r]) and rows[r] or {}
            for c = 1, cols do row[c] = U.Clean(src[c], 300) end
            b.rows[r] = row
        end
        b.head = raw.head ~= false
    end
    return b
end

function D.SanitizePerms(raw)
    raw = istable(raw) and raw or {}
    local function rule(r, modes, default)
        r = istable(r) and r or {}
        local mode = default
        for _, m in ipairs(modes) do if m.id == r.mode then mode = r.mode end end
        return { mode = mode, units = U.IDList(r.units, 32), minRank = U.Int(r.minRank, 0, 0, 64) }
    end
    return { read = rule(raw.read, D.READ_MODES, "unit"), write = rule(raw.write, D.WRITE_MODES, "managers") }
end

function D.DefaultPerms(folder)
    if folder == "public" then
        return { read = { mode = "all", units = {}, minRank = 0 }, write = { mode = "managers", units = {}, minRank = 0 } }
    end
    return { read = { mode = "unit", units = {}, minRank = 0 }, write = { mode = "managers", units = {}, minRank = 0 } }
end

function D.EmptyBlocks()
    return { { id = D.NewBlockID(), t = "h1", text = "Neues Dokument", align = "l" }, { id = D.NewBlockID(), t = "p", text = "", align = "l" } }
end

---------------------------------------------------------------------------------------------------------------
-- Rechte
---------------------------------------------------------------------------------------------------------------
local function InUnitTree(char, unit)
    local own = char and char:GetFaction()
    return own ~= nil and (own.uniqueID == unit or F.IsDescendant(own, unit))
end

local function MatchRule(char, folder, rule, isWrite)
    if not char then return false end
    local mode = rule.mode
    if mode == "all" then return true end
    if mode == "managers" then
        if folder == "public" then return false end
        return A.HasFlag(char, folder, "docs")
    end
    if mode == "unit" then
        if folder == "public" then return true end
        return InUnitTree(char, folder)
    end
    if mode == "rank" then
        if folder == "public" then return char:GetRank() >= rule.minRank end
        return InUnitTree(char, folder) and char:GetRank() >= rule.minRank
    end
    if mode == "units" then
        for _, unit in ipairs(rule.units) do
            if InUnitTree(char, unit) and char:GetRank() >= rule.minRank then return true end
        end
        return false
    end
    return false
end

function D.IsAdmin(ply)
    return symchars.HasPriv(ply, "symchars_docs_admin")
end

-- meta: { folder, perms, createdBySteam }
function D.CanRead(ply, char, meta)
    if D.IsAdmin(ply) then return true end
    if not meta then return false end
    if IsValid(ply) and meta.createdBySteam == ply:SteamID64() then return true end
    if meta.folder ~= "public" and A.HasFlag(char, meta.folder, "docs") then return true end
    return MatchRule(char, meta.folder, meta.perms.read, false)
end

function D.CanWrite(ply, char, meta)
    if D.IsAdmin(ply) then return true end
    if not meta then return false end
    if IsValid(ply) and meta.createdBySteam == ply:SteamID64() then return true end
    if meta.folder ~= "public" and A.HasFlag(char, meta.folder, "docs") then return true end
    return MatchRule(char, meta.folder, meta.perms.write, true)
end

-- Darf Rechte/Titel ändern oder löschen
function D.CanManage(ply, char, meta)
    if D.IsAdmin(ply) then return true end
    if not meta then return false end
    if IsValid(ply) and meta.createdBySteam == ply:SteamID64() then return true end
    return meta.folder ~= "public" and A.HasFlag(char, meta.folder, "docs")
end

function D.CanCreateIn(ply, char, folder)
    if D.IsAdmin(ply) then return true end
    if folder == "public" or not char then return false end
    return A.HasFlag(char, folder, "docs")
end

---------------------------------------------------------------------------------------------------------------
-- Formatierung (Parser)
---------------------------------------------------------------------------------------------------------------
-- Gibt eine Liste von Runs zurück: { text, b, i, u, s, code, color, link }
function D.ParseInline(text)
    text = tostring(text or "")
    local runs = {}
    local st = { b = false, i = false, u = false, s = false, code = false }
    local colors = {}
    local buf = {}

    local function flush(link)
        if #buf == 0 then return end
        runs[#runs + 1] = {
            text = table.concat(buf), b = st.b, i = st.i, u = st.u or link ~= nil, s = st.s, code = st.code,
            color = colors[#colors], link = link,
        }
        buf = {}
    end

    local len = #text
    local p = 1
    while p <= len do
        local c = string.sub(text, p, p)
        local two = string.sub(text, p, p + 1)

        if st.code then
            if c == "`" then
                flush()
                st.code = false
                p = p + 1
            else
                buf[#buf + 1] = c
                p = p + 1
            end
        elseif c == "\\" and p < len then
            buf[#buf + 1] = string.sub(text, p + 1, p + 1)
            p = p + 2
        elseif two == "**" then
            flush() st.b = not st.b p = p + 2
        elseif two == "__" then
            flush() st.u = not st.u p = p + 2
        elseif two == "~~" then
            flush() st.s = not st.s p = p + 2
        elseif c == "*" then
            flush() st.i = not st.i p = p + 1
        elseif c == "`" then
            flush() st.code = true p = p + 1
        elseif two == "{#" and string.match(string.sub(text, p + 2, p + 8), "^%x%x%x%x%x%x|") then
            flush()
            colors[#colors + 1] = U.HexToColor(string.sub(text, p + 2, p + 7), Color(255, 255, 255))
            p = p + 9
        elseif c == "}" and #colors > 0 then
            flush()
            colors[#colors] = nil
            p = p + 1
        elseif c == "[" then
            local close = string.find(text, "](", p + 1, true)
            local urlEnd = close and string.find(text, ")", close + 2, true)
            local url = close and urlEnd and string.sub(text, close + 2, urlEnd - 1)
            if url and string.match(url, "^https?://[^%s]+$") then
                flush()
                buf[#buf + 1] = string.sub(text, p + 1, close - 1)
                flush(url)
                p = urlEnd + 1
            else
                buf[#buf + 1] = c
                p = p + 1
            end
        else
            buf[#buf + 1] = c
            p = p + 1
        end
    end
    flush()
    return runs
end

function D.PlainText(text)
    local out = {}
    for _, run in ipairs(D.ParseInline(text)) do out[#out + 1] = run.text end
    return table.concat(out)
end

function D.Excerpt(blocks, maxLen)
    local parts = {}
    for _, b in ipairs(blocks or {}) do
        if b.text and b.text ~= "" then parts[#parts + 1] = D.PlainText(b.text) end
        if #table.concat(parts, " ") > (maxLen or 200) then break end
    end
    local s = table.concat(parts, " ")
    local limit = maxLen or 200
    if (utf8.len(s) or #s) > limit then s = U.Clean(s, limit) .. "..." end
    return s
end
