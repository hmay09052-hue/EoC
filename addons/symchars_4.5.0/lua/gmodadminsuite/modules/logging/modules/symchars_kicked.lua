local MODULE = GAS.Logging:MODULE()

MODULE.Category = "SymChars"
MODULE.Name = "Character Kicked"
MODULE.Colour = Color(218,214,14)

MODULE:Setup(function()
    MODULE:Hook("symchars_kicked", "blogs_symchars_kicked", function(actor, target, targetID, old, new)
        old = istable(old) and (util.TableToJSON(old) or tostring(old)) or tostring(old)
        new = istable(new) and (util.TableToJSON(new) or tostring(new)) or tostring(new)
        MODULE:Log(actor .. " kicked " .. target .. "(" .. targetID .. ")" .. " to faction " .. new .. " | old: " .. old)
    end)
end)

GAS.Logging:AddModule(MODULE)
