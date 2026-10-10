local K = EOC_KENNEN

function K.Cfg()
    return K.Config or {}
end

function K.GetCharID(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end
    return ply:GetNW2Int("symchars_charid", 0)
end

function K.GetChar(ply)
    if not IsValid(ply) or not ply.GetCharacter then return nil end
    local ok, char = pcall(ply.GetCharacter, ply)
    if ok then return char end
    return nil
end

function K.GetRoleplayID(char)
    if not char or not symchars or not symchars.utils or not symchars.utils.BuildRoleplayID then return "" end
    local ok, rpid = pcall(symchars.utils.BuildRoleplayID, char)
    if ok and isstring(rpid) then return rpid end
    return ""
end

function K.GetRankName(char)
    if not char or not char.GetRankName then return "" end
    local ok, rank = pcall(char.GetRankName, char)
    if ok and isstring(rank) then return rank end
    return ""
end

-- Baut den Anzeigenamen für Unbekannte aus dem Format der Config
function K.FormatUnknown(char, format)
    local rpid = K.GetRoleplayID(char)
    if rpid == "" then return K.Cfg().UnknownFallback or "Unbekannt" end

    local text = string.Replace(format or "{rpid}", "{rpid}", rpid)
    text = string.Replace(text, "{rank}", K.GetRankName(char))
    text = string.Trim(string.gsub(text, "%s+", " "))
    return text
end

function K.CanSeeAll(ply)
    if not IsValid(ply) then return false end
    local groups = K.Cfg().SeeAllGroups or {}
    return groups[ply:GetUserGroup()] == true
end
