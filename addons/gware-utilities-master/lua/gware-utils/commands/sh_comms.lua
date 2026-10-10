local L = gWare.Utils.Lang.GetPhrase

local command = gWare.Utils.RegisterCommand({
    prefix = "Funk",
    triggers = {"funk", "comms"},
})

command:OnServerSide(function(ply, text)
    local args = text:Split("*")

    if #args < 2 then
        VoidLib.Notify(ply, L("notify_invalid-comms_name"), L("notify_invalid-comms_desc"), VoidUI.Colors.Red, 8)
        return ""
    end

    local namePart = args[1]
    local message = args[2]:sub(2)

    if not message or message == "" then
        VoidLib.Notify(ply, L("notify_invalid-comms_name"), L("notify_invalid-comms_desc"), VoidUI.Colors.Red, 8)
        return
    end

    local receiver = nil
    local receiverName = namePart
    local receiverColor = VoidUI.Colors.Blue
    local sendToAll = false

    local function cleanName(name)
        return name:gsub("[^%w]", ""):lower()
    end

    if namePart:lower() ~= "höchst" and namePart:lower() ~= "öffentlich" then
        for _, target in pairs(player.GetAll()) do
            if string.find(cleanName(target:Name()), cleanName(namePart)) then
                receiver = target
                receiverName = target:Name()
                receiverColor = team.GetColor(target:Team())
                break
            end
        end

        if not receiver then
            sendToAll = true
        end
    else
        sendToAll = true
    end

    if sendToAll then
        net.Start(command:GetNetID())
            net.WriteString(message)
            net.WriteString(namePart)
            net.WriteString(ply:Name())
            net.WriteTeam(ply)
            net.WriteColor(receiverColor)
        net.Broadcast()
    else
        if IsValid(receiver) then
            net.Start(command:GetNetID())
                net.WriteString(message)
                net.WriteString(receiverName)
                net.WriteString(ply:Name())
                net.WriteTeam(ply)
                net.WriteColor(receiverColor)
            net.Send(receiver)

            net.Start(command:GetNetID())
                net.WriteString(message)
                net.WriteString(receiverName)
                net.WriteString(ply:Name())
                net.WriteTeam(ply)
                net.WriteColor(receiverColor)
            net.Send(ply)

            sound.Play("funksound.mp3", receiver:GetPos())
        else
            VoidLib.Notify(ply, L("notify_invalid_player"), L("notify_invalid_player_desc"), VoidUI.Colors.Red, 8)
        end
    end
end)

command:OnReceive(function()
    local col = gWare.Utils.Colors

    local message = net.ReadString()
    local receiverName = net.ReadString()
    local senderName = net.ReadString()
    local senderColor = team.GetColor(net.ReadTeam())
    local receiverColor = net.ReadColor()

    local toTranslated = (" " .. L"general_to" .. " ")

    if receiverName == "Serverwide" then
        gWare.Utils.PrintCommand(command:GetPrefix(),
            senderColor, senderName, color_white, col.Orange, toTranslated, receiverColor, receiverName, col.Brackets, " » ", color_white, message
        )
    else
        gWare.Utils.PrintCommand(command:GetPrefix(),
            senderColor, senderName, color_white, col.Orange, toTranslated, receiverColor, receiverName, col.Brackets, " » ", color_white, message
        )

        local receiver = nil
        for _, target in pairs(player.GetAll()) do
            if target:Name() == receiverName then
                receiver = target
                break
            end
        end

        if IsValid(receiver) then
            sound.Play("funksound.mp3", receiver:GetPos())
        end
    end
end)
