--[[
    Command: /akt <message>
    Description: Prints a text in global chat with a [Akt] prefix
    Example Command: /akt schaltet den Reaktor aus.
    Example Chat: [Akt] 501st CMD Menschlich schaltet den Reaktor aus.
]]

local command = gWare.Utils.RegisterCommand({
    prefix = "AKTION",
    triggers = {"akt", "act"},
})

command:OnServerSide(function(ply, message)
    if gWare.Utils.IsMessageEmpty(message, ply) then return "" end

    net.Start(command:GetNetID())
        net.WriteString(message)
        net.WriteString(ply:Name())
    net.Broadcast()
end)

command:OnReceive(function()
    local receivedMessage = net.ReadString()
    local name = net.ReadString()

    local formattedMessage = string.format("[AKTION] %s %s", name, receivedMessage)

    chat.AddText(Color(255, 255, 0), formattedMessage)
end)


--[[ 
    Command: /eakt <message>
    Description: Prints a text in global chat with a [EVENTAKTION] prefix in blue and the rest in white
    Example Command: /eakt schaltet den Reaktor aus.
    Example Chat: [EVENTAKTION] 501st CMD Menschlich: schaltet den Reaktor aus.
]]

local command = gWare.Utils.RegisterCommand({
    prefix = "EVENTAKTION",
    triggers = {"eakt"},
})

command:OnServerSide(function(ply, message)
    if gWare.Utils.IsMessageEmpty(message, ply) then return "" end

    net.Start(command:GetNetID())
        net.WriteString(message)
        net.WriteString(ply:Name())
    net.Broadcast()
end)

command:OnReceive(function()
    local receivedMessage = net.ReadString()
    local name = net.ReadString()
    
    chat.AddText(Color(0, 0, 255), "[EVENTAKTION] ", Color(255, 255, 255), string.format("%s %s", name, receivedMessage))
end)