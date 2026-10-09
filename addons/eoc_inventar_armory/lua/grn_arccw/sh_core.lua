GRNArcCW = GRNArcCW or {}
local M = GRNArcCW
local C = M.Config

M.Allowed = {}
for _, name in ipairs(C.Whitelist or {}) do
    if isstring(name) and name ~= "" then M.Allowed[name] = true end
end

function M.IsAllowed(attName, ply)
    if not C.EnforceWhitelist then return true end
    if attName == nil or attName == "" then return true end
    if C.AdminsBypassWhitelist and IsValid(ply) and ply:IsAdmin() then return true end
    return M.Allowed[attName] == true
end

-- Läuft auf Server und Client. ArcCW fragt diesen Hook bei jedem Anbringen
-- und Abnehmen; Abnehmen bleibt immer erlaubt, damit sich alte Teile
-- entfernen lassen.
hook.Add("ArcCW_PlayerCanAttach", "GRNArcCW_Whitelist", function(ply, wep, attName, slot, detach)
    if detach == true then return end
    if isstring(detach) then
        -- Attach() fragt beim Tauschen erst das alte Teil mit dem neuen
        -- Namen als "detach"-Argument ab. Das alte Teil darf immer runter.
        return
    end
    if not M.IsAllowed(attName, ply) then return false end
end)

-- Liste aller Aufsätze, die in einen Slot einer Waffe passen und
-- freigegeben sind (für das Menü).
function M.GetSlotOptions(wep, slotIndex)
    local out = {}
    if not IsValid(wep) or not wep.Attachments or not ArcCW then return out end
    local slot = wep.Attachments[slotIndex]
    if not istable(slot) then return out end

    local slots = { slotIndex }
    table.Add(slots, slot.MergeSlots or {})

    local seen = {}
    for _, si in ipairs(slots) do
        local s = wep.Attachments[si]
        if istable(s) then
            for _, attName in ipairs(ArcCW:GetAttsForSlot(s.Slot, wep)) do
                if not seen[attName] and M.IsAllowed(attName, LocalPlayer and LocalPlayer() or nil) then
                    seen[attName] = true
                    out[#out + 1] = { att = attName, slot = si }
                end
            end
        end
    end
    return out
end
