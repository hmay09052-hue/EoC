local MODULE = GAS.Logging:MODULE()

MODULE.Category = "SymChars"
MODULE.Name = "Character Deleted"
MODULE.Colour = Color(218,214,14)

MODULE:Setup(function()
    MODULE:Hook("symchars_deleted", "blogs_symchars_deleted", function(actor, target, targetID, old, new)
        old = istable(old) and (util.TableToJSON(old) or tostring(old)) or tostring(old)
        new = istable(new) and (util.TableToJSON(new) or tostring(new)) or tostring(new)
        MODULE:Log(actor .. " deleted " .. target .. "(" .. targetID .. ")" .. " | old: " .. old .. " | new: " .. new)
    end)
end)

GAS.Logging:AddModule(MODULE)
