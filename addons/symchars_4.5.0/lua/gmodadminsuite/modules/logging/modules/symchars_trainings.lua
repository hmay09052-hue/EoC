local MODULE = GAS.Logging:MODULE()

MODULE.Category = "SymChars"
MODULE.Name = "Fortbildungen"
MODULE.Colour = Color(95, 200, 120)

MODULE:Setup(function()
    MODULE:Hook("symchars_training_granted", "blogs_symchars_training_granted", function(actor, char, training)
        local t = symchars.trainings.Get(training)
        MODULE:Log(tostring(actor) .. " hat " .. symchars.utils.BuildDisplayName(char) .. " (#" .. char.charID .. ") die Fortbildung " .. (t and t.name or training) .. " eingetragen")
    end)
    MODULE:Hook("symchars_training_revoked", "blogs_symchars_training_revoked", function(actor, char, training)
        local t = symchars.trainings.Get(training)
        MODULE:Log(tostring(actor) .. " hat " .. symchars.utils.BuildDisplayName(char) .. " (#" .. char.charID .. ") die Fortbildung " .. (t and t.name or training) .. " entzogen")
    end)
end)

GAS.Logging:AddModule(MODULE)
