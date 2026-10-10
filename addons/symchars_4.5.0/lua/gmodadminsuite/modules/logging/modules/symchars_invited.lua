local MODULE = GAS.Logging:MODULE()

MODULE.Category = "SymChars"
MODULE.Name = "Character Invited"
MODULE.Colour = Color(218,214,14)

MODULE:Setup(function()
    MODULE:Hook("symchars_invited", "blogs_symchars_invited", function(actor, target, targetID, old, new)
        old = istable(old) and (util.TableToJSON(old) or tostring(old)) or tostring(old)
        new = istable(new) and (util.TableToJSON(new) or tostring(new)) or tostring(new)
        MODULE:Log(actor .. " invited " .. target .. "(" .. targetID .. ")" .. " | old: " .. old .. " | new: " .. new)
    end)
end)

GAS.Logging:AddModule(MODULE)
