--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Aktionen in der Verwaltung
    Restriction(ply, actorChar, targetChar) -> erlaubt, Grund
    input: "none" | "confirm" | "text" | "number" | "rank" | "unit" | "transfer" | "job" | "customs"
    Ausgeführt wird serverseitig (sv_chars.lua setzt action.Execute).
-------------------------------------------------------------------------------------------------------------]]

symchars.chars.actions = symchars.chars.actions or {}
symchars.chars.actionOrder = {}

local C = symchars.chars
local A = symchars.authority
local F = symchars.factions

function C.AddAction(def)
    if not def.index then return end
    def.Name = def.Name or def.index
    def.input = def.input or "none"
    def.category = def.category or "unit"
    if not isfunction(def.Restriction) then def.Restriction = function() return true end end
    local existing = C.actions[def.index]
    if existing and existing.Execute and not def.Execute then def.Execute = existing.Execute end
    if not existing then C.actionOrder[#C.actionOrder + 1] = def.index end
    C.actions[def.index] = def
end

function C.GetAction(index) return C.actions[index] end

function C.HasActionPermission(index, ply, actorChar, targetChar)
    local action = C.actions[index]
    if not action then return false end
    if isnumber(actorChar) then actorChar = C.Get(actorChar) end
    if isnumber(targetChar) then targetChar = C.Get(targetChar) end
    if not targetChar then return false end
    local ok, reason = action.Restriction(ply, actorChar, targetChar)
    return ok == true, reason
end

local function Priv(ply, name)
    return symchars.HasPriv(ply, "symchars_char_admin") or symchars.HasPriv(ply, name)
end

local function UsesFactions()
    return symchars.Config("usefactions") == true
end

---------------------------------------------------------------------------------------------------------------
-- Einheit
---------------------------------------------------------------------------------------------------------------
C.AddAction({
    index = "promote",
    Name = "Befördern",
    Color = Color(95, 200, 120),
    category = "unit",
    input = "none",
    Restriction = function(ply, actor, target)
        if not UsesFactions() then return false end
        local faction = target:GetFaction()
        if not faction or target:GetRank() >= #faction:GetRanks() then return false end
        if Priv(ply, "symchars_char_ranksmanage") then return true, "Admin" end
        local ok, kind, byRank = A.CanActOn(actor, target, "promotions")
        if not ok then return false end
        if (kind == "same" or byRank) and target:GetRank() + 1 >= actor:GetRank() then return false end
        return true, A.KindText(kind)
    end,
})

C.AddAction({
    index = "demote",
    Name = "Degradieren",
    Color = Color(205, 70, 60),
    category = "unit",
    input = "none",
    Restriction = function(ply, actor, target)
        if not UsesFactions() then return false end
        if target:GetRank() <= 1 then return false end
        if Priv(ply, "symchars_char_ranksmanage") then return true, "Admin" end
        local ok, kind = A.CanActOn(actor, target, "promotions")
        if not ok then return false end
        return true, A.KindText(kind)
    end,
})

C.AddAction({
    index = "setrank",
    Name = "Rang setzen",
    Color = Color(252, 178, 73),
    category = "unit",
    input = "rank",
    Restriction = function(ply, actor, target)
        if not UsesFactions() or not target:GetFaction() then return false end
        if Priv(ply, "symchars_char_ranksmanage") then return true, "Admin" end
        local ok, kind = A.CanActOn(actor, target, "promotions")
        if not ok then return false end
        return true, A.KindText(kind)
    end,
})

C.AddAction({
    index = "transfer",
    Name = "Versetzen",
    Color = Color(80, 170, 230),
    category = "unit",
    input = "transfer",
    Restriction = function(ply, actor, target)
        if not UsesFactions() or not target:GetFaction() then return false end
        if Priv(ply, "symchars_char_changefaction") then return true, "Admin" end
        local ok, kind = A.CanActOn(actor, target, "transfer")
        if not ok then return false end
        return true, A.KindText(kind)
    end,
})

C.AddAction({
    index = "kick",
    Name = "Entlassen",
    Color = Color(225, 130, 40),
    category = "unit",
    input = "confirm",
    Restriction = function(ply, actor, target)
        if not UsesFactions() then return false end
        local faction = target:GetFaction()
        if not faction then return false end
        local fallback = F.FindFallback(faction.uniqueID)
        if not fallback or faction.uniqueID == symchars.Config("designateddefaultfaction") then return false end
        if Priv(ply, "symchars_char_kick") then return true, "Admin" end
        local ok, kind = A.CanActOn(actor, target, "kick")
        if not ok then return false end
        return true, A.KindText(kind)
    end,
})

C.AddAction({
    index = "invite",
    Name = "In meine Einheit einladen",
    Color = Color(252, 178, 73),
    category = "unit",
    input = "none",
    Restriction = function(ply, actor, target)
        if not UsesFactions() or not actor then return false end
        local own = actor:GetFaction()
        if not own or target.faction == own.uniqueID then return false end
        if not target:IsOnline() then return false end
        local ok, kind = A.HasFlag(actor, own.uniqueID, "invite")
        if not ok then return false end
        return true, A.KindText(kind)
    end,
})

---------------------------------------------------------------------------------------------------------------
-- Admin
---------------------------------------------------------------------------------------------------------------
C.AddAction({
    index = "changname",
    Name = "Name ändern",
    category = "admin",
    input = "text",
    Restriction = function(ply) return Priv(ply, "symchars_char_changename"), "Admin" end,
})

C.AddAction({
    index = "rpidchange",
    Name = "RP-ID ändern",
    category = "admin",
    input = "text",
    Restriction = function(ply)
        if not symchars.Config("useroleplayid") then return false end
        return Priv(ply, "symchars_char_ranksmanage"), "Admin"
    end,
})

C.AddAction({
    index = "changemoney",
    Name = "Geld setzen",
    category = "admin",
    input = "number",
    Restriction = function(ply) return Priv(ply, "symchars_char_changemoney"), "Admin" end,
})

C.AddAction({
    index = "changefact",
    Name = "Einheit setzen",
    category = "admin",
    input = "unit",
    Restriction = function(ply)
        if not UsesFactions() then return false end
        return Priv(ply, "symchars_char_changefaction"), "Admin"
    end,
})

C.AddAction({
    index = "jobchange",
    Name = "Job setzen",
    category = "admin",
    input = "job",
    Restriction = function(ply)
        if UsesFactions() then return false end
        return Priv(ply, "symchars_char_jobchange"), "Admin"
    end,
})

C.AddAction({
    index = "customs",
    Name = "Custom-Charakter",
    Color = Color(120, 130, 230),
    category = "admin",
    input = "customs",
    Restriction = function(ply)
        return Priv(ply, "symchars_char_customchar"), "Admin"
    end,
})

C.AddAction({
    index = "deletechar",
    Name = "Charakter löschen",
    Color = Color(205, 60, 60),
    category = "admin",
    input = "confirm",
    Restriction = function(ply) return Priv(ply, "symchars_char_delete"), "Admin" end,
})
