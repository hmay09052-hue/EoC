local MODULE = GAS.Logging:MODULE()

MODULE.Category = "SymChars"
MODULE.Name = "Job Changes"
MODULE.Colour = Color(218,214,14)

MODULE:Setup(function()
    MODULE:Hook("symchars_jobchanged", "blogs_symchars_jobchanged", function(actor, target, targetID, old, new)
        old = istable(old) and (util.TableToJSON(old) or tostring(old)) or tostring(old)
        new = istable(new) and (util.TableToJSON(new) or tostring(new)) or tostring(new)
        MODULE:Log(actor .. " changed the job for " .. target .. "(" .. targetID .. ")" .. " to " .. new .. " | old: " .. old)
    end)
end)

GAS.Logging:AddModule(MODULE)
