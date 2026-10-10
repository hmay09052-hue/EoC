local MODULE = GAS.Logging:MODULE()

MODULE.Category = "SymChars"
MODULE.Name = "Rank Changes"
MODULE.Colour = Color(218,214,14)

MODULE:Setup(function()
    MODULE:Hook("symchars_rankchanged", "blogs_symchars_rankchanged", function(actor, target, targetID, old, new)
        old = istable(old) and (util.TableToJSON(old) or tostring(old)) or tostring(old)
        new = istable(new) and (util.TableToJSON(new) or tostring(new)) or tostring(new)
        MODULE:Log(actor .. " changed the rank for " .. target .. "(" .. targetID .. ")" .. " to " .. new .. " | old: " .. old)
    end)
end)

GAS.Logging:AddModule(MODULE)
