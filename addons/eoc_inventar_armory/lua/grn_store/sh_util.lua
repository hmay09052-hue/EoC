GRNStore = GRNStore or {}
local S = GRNStore

function S.ClampString(value, maxLen)
    value = tostring(value or "")
    value = string.Trim(value)
    if maxLen and #value > maxLen then
        value = string.sub(value, 1, maxLen)
    end
    return value
end

function S.Slug(value)
    value = string.lower(S.ClampString(value, 80))
    value = string.gsub(value, "[^%w_%-]+", "_")
    value = string.gsub(value, "_+", "_")
    value = string.gsub(value, "^_+", "")
    value = string.gsub(value, "_+$", "")
    if value == "" then value = "item" end
    return string.sub(value, 1, 64)
end

function S.TableHasKey(tbl, key)
    return istable(tbl) and tbl[key] == true
end

function S.CopyPlain(tbl)
    if not istable(tbl) then return {} end
    return table.Copy(tbl)
end
