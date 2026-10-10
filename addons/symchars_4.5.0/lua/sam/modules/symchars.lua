--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - SAM-Befehle
    !chars          Menü öffnen
    !promote <spieler>, !demote <spieler>, !setunit <spieler> <einheit-id>
-------------------------------------------------------------------------------------------------------------]]

if SAM_LOADED then return end

local sam, command = sam, sam.command

command.set_category("SymChars")

local function Run(ply, target, action, value)
    local char = IsValid(target) and target:GetCharacter()
    if not char then
        if IsValid(ply) then symchars.Notify(ply, "Der Spieler hat keinen Charakter.", "error") end
        return
    end
    local def = symchars.chars.GetAction(action)
    if not def or not def.Execute then return end
    local ok, err = def.Execute(ply, IsValid(ply) and ply:GetCharacter() or nil, char, value)
    if IsValid(ply) then
        if ok == false then symchars.Notify(ply, err or "Fehlgeschlagen.", "error")
        else symchars.Notify(ply, def.Name .. ": " .. symchars.utils.BuildDisplayName(char), "succ") end
    end
end

command.new("promote")
    :SetPermission("symchars_char_ranksmanage", "admin")
    :AddArg("player", { single_target = true })
    :Help("Befördert den Charakter eines Spielers um einen Rang")
    :OnExecute(function(ply, targets) Run(ply, targets[1], "promote") end)
:End()

command.new("demote")
    :SetPermission("symchars_char_ranksmanage", "admin")
    :AddArg("player", { single_target = true })
    :Help("Degradiert den Charakter eines Spielers um einen Rang")
    :OnExecute(function(ply, targets) Run(ply, targets[1], "demote") end)
:End()

command.new("setunit")
    :SetPermission("symchars_char_changefaction", "admin")
    :AddArg("player", { single_target = true })
    :AddArg("text", { hint = "einheit-id" })
    :Help("Setzt die Einheit eines Charakters")
    :OnExecute(function(ply, targets, unit) Run(ply, targets[1], "changefact", unit) end)
:End()

command.new("chars")
    :Help("Öffnet das Charaktermenü")
    :OnExecute(function(ply) if IsValid(ply) then symchars.OpenMenu(ply, "characters") end end)
:End()
