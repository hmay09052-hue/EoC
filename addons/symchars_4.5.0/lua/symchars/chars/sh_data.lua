--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Zusatzfelder fuer Charaktere (werden bei der Erstellung abgefragt)

    symchars.chars.AddDataVar({
        var = "description",          -- interner Name -> CHAR:GetDescription() / CHAR:SetDescription()
        default = "",
        IsField = true,               -- bei der Erstellung anzeigen
        FieldName = "Beschreibung",
        FieldInfo = "Hilfetext",
        type = "string" | "text" | "choice",
        maxLength = 300,
        choices = { { "Anzeige", "wert" }, ... },   -- nur bei type = "choice"
        OnValidate = function(value) return true end -- false, "Fehlertext"
    })
    Felder koennen ingame unter Einstellungen > Deaktivierte Zusatzfelder abgeschaltet werden.
-------------------------------------------------------------------------------------------------------------]]

local C = symchars.chars
local U = symchars.util

C.data = C.data or {}
C.dataOrder = C.dataOrder or {}

function C.AddDataVar(def)
    if not istable(def) or not isstring(def.var) or def.var == "" then return end
    if def.default == nil then def.default = "" end
    def.IsField = def.IsField == true
    def.type = def.type or "string"
    def.maxLength = def.maxLength or (def.type == "text" and 1000 or 120)
    if not isfunction(def.OnValidate) then def.OnValidate = function() return true end end

    local name = string.upper(string.sub(def.var, 1, 1)) .. string.sub(def.var, 2)
    local CHAR = C.Meta()
    CHAR["Get" .. name] = function(self) return self:GetData(def.var, C.DataDefault(def)) end
    CHAR["Set" .. name] = function(self, value) self:SetData(def.var, value) end

    if not C.data[def.var] then C.dataOrder[#C.dataOrder + 1] = def.var end
    C.data[def.var] = def
end

-- Auswahlmöglichkeiten (Liste oder Funktion, die eine Liste liefert)
function C.DataChoices(def)
    if isfunction(def.choices) then return def.choices() or {} end
    return def.choices or {}
end

function C.DataDefault(def)
    if isfunction(def.default) then return def.default() end
    return def.default
end

-- Bereinigt einen vom Client gesendeten Datensatz. Gibt data, fehlertext zurueck.
function C.SanitizeData(raw)
    local out = {}
    raw = istable(raw) and raw or {}
    for _, var in ipairs(C.dataOrder) do
        local def = C.data[var]
        if def and def.IsField and symchars.utils.VarIsEnabled(var) then
            local value = raw[var]
            if def.type == "choice" then
                local valid = false
                for _, choice in ipairs(C.DataChoices(def)) do
                    if choice[2] == value then valid = true break end
                end
                value = valid and value or C.DataDefault(def)
            else
                value = U.Clean(value, def.maxLength, def.type == "text")
            end
            local ok, err = def.OnValidate(value)
            if ok == false then return nil, err or (def.FieldName or var) .. " ist ungültig." end
            out[var] = value
        end
    end
    return out
end

C.AddDataVar({
    var = "description",
    default = "",
    IsField = true,
    FieldName = "Beschreibung",
    FieldInfo = "Eine kurze Beschreibung oder Vorgeschichte deines Charakters.",
    type = "text",
    maxLength = 600,
    OnValidate = function(value)
        if U.Trim(value) == "" then return false, "Dein Charakter braucht eine Beschreibung." end
        return true
    end,
})

-- Nationalität: Auswahl kommt aus den Einstellungen (Republikanisch / Separatistisch).
-- Sie entscheidet, welche Startklassen und Jobs möglich sind.
C.AddDataVar({
    var = "nationality",
    default = function()
        local first = (symchars.Config("nationalities") or {})[1]
        return first and first.id or ""
    end,
    IsField = true,
    FieldName = "Nationalität",
    FieldInfo = "Bestimmt, welche Startklassen dir offenstehen.",
    type = "choice",
    choices = function()
        local out = {}
        for _, n in ipairs(symchars.Config("nationalities") or {}) do out[#out + 1] = { n.name, n.id } end
        return out
    end,
})
