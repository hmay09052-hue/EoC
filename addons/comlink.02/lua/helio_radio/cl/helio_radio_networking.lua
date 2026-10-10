hradio = hradio or {}

hradio.GRNCommsBlocked = GetGlobalBool("GRNComms_HeliosBlocked", false)
hradio.GRNCommsBlockedMessage = "Der Funk ist ausgefallen, weil die Antenne beschädigt ist."
hradio.IncomingTransmissions = hradio.IncomingTransmissions or {}

local nextBlockedNotice = 0

local function localPlayer()
    local ply = LocalPlayer()

    if not IsValid(ply) then return nil end

    ply.hradio = ply.hradio or {}
    ply.hradio.MutedChannels = ply.hradio.MutedChannels or {}

    return ply
end

function hradio.IsGRNCommsBlocked()
    return hradio.GRNCommsBlocked == true or GetGlobalBool("GRNComms_HeliosBlocked", false)
end

function hradio.ShowGRNCommsBlocked(message)
    if CurTime() < nextBlockedNotice then return end

    nextBlockedNotice = CurTime() + 1
    message = tostring(message or hradio.GRNCommsBlockedMessage)

    notification.AddLegacy(message, NOTIFY_ERROR, 4)
    surface.PlaySound("buttons/button10.wav")
    chat.AddText(Color(252, 178, 73), "[FUNK] ", Color(244, 241, 233), message)
end

local function closeRadioMenus()
    local ply = localPlayer()
    if not ply then return end

    if IsValid(ply.hradio.RadioMenu) then
        ply.hradio.RadioMenu:Remove()
    end

    -- nur den Funk schließen, ein offenes Squad-Menü bleibt
    if hradio.CloseComlinkApp then
        hradio.CloseComlinkApp("radio", true)
    end

    ply.hradio.ImguiRadioMenuOpen = false
    ply.hradio.IsTalking = false

    gui.EnableScreenClicker(false)
end

function hradio.ChangeMuteStatus(chan, status)
    local ply = localPlayer()
    if not ply then return end

    if hradio.IsGRNCommsBlocked() then
        hradio.ShowGRNCommsBlocked()
        return
    end

    if hradio.Config.UISounds then
        surface.PlaySound("buttons/button16.wav")
    end

    net.Start("hRadio_PlyMuteUnmuteChannel")
    net.WriteUInt(chan, hradio.ChannelMaxBitSize)
    net.WriteBool(status)
    net.SendToServer()
end

function hradio.ChangeActiveChannel(newchan)
    local ply = localPlayer()
    if not ply then return end

    if hradio.IsGRNCommsBlocked() then
        hradio.ShowGRNCommsBlocked()
        return
    end

    -- Wird gerade per Sprachtaste gefunkt: alten Funk sauber beenden, danach auf dem neuen weitersenden
    local wasVoiceRadio = ply.hradio.VoiceRadio == true
    if wasVoiceRadio and hradio.StopVoiceRadio then
        hradio.StopVoiceRadio()
    end

    ply.hradio.ActiveChannel = newchan

    net.Start("hRadio_PlyChangeChannel")
    net.WriteUInt(newchan, hradio.ChannelMaxBitSize)
    net.SendToServer()

    if wasVoiceRadio and newchan ~= 0 and hradio.StartVoiceRadio then
        hradio.StartVoiceRadio()
    end
end

net.Receive("hRadio_GRNCommsState", function()
    local ply = localPlayer()
    if not ply then return end

    local wasBlocked = hradio.GRNCommsBlocked == true
    local blocked = net.ReadBool()
    local message = net.ReadString()

    hradio.GRNCommsBlocked = blocked

    if message ~= "" then
        hradio.GRNCommsBlockedMessage = message
    end

    if blocked then
        if permissions and permissions.EnableVoiceChat then
            permissions.EnableVoiceChat(false)
        end

        ply:ConCommand("-voicerecord")
        closeRadioMenus()

        for _, transmission in ipairs(hradio.IncomingTransmissions or {}) do
            local from = transmission[1]

            if IsValid(from) and from.hradio then
                from.hradio.IsTalking = false

                if IsValid(from.hradio.modelpanel) then
                    from.hradio.modelpanel:Remove()
                end
            end
        end

        hradio.IncomingTransmissions = {}
        hradio.ShowGRNCommsBlocked(hradio.GRNCommsBlockedMessage)
    elseif wasBlocked then
        notification.AddLegacy("Der Funk ist wieder verfügbar.", NOTIFY_GENERIC, 4)
        surface.PlaySound("buttons/button9.wav")
        chat.AddText(
            Color(252, 178, 73),
            "[FUNK] ",
            Color(244, 241, 233),
            "Alle Funks funktionieren wieder."
        )
    end
end)

net.Receive("hRadio_IncomingTransmissionStart", function()
    local ply = localPlayer()
    if not ply then return end

    local chan = net.ReadUInt(hradio.ChannelMaxBitSize)
    local steamid = net.ReadString()

    if hradio.IsGRNCommsBlocked() then return end

    local from = player.GetBySteamID64(steamid)
    if not IsValid(from) then return end

    from.hradio = from.hradio or {}

    if ply.hradio.MutedChannels[chan] and not hradio.Config.ShowMutedNotifications then
        return
    end

    if not hradio.debug and from == ply then return end

    from.hradio.IsTalking = true
    from.hradio.LastStartTime = SysTime()

    if not ply.hradio.MutedChannels[chan] and hradio.Config.IncomingTransmissionSounds then
        surface.PlaySound("buttons/blip1.wav")
    end

    hradio.RemoveOriginalVCHud(from)

    if IsValid(from.hradio.modelpanel) then
        from.hradio.modelpanel:Remove()
    end

    from.hradio.modelpanel = vgui.Create("DModelPanel")
    from.hradio.modelpanel:SetPaintedManually(true)

    function from.hradio.modelpanel:LayoutEntity()
        return
    end

    for i = #hradio.IncomingTransmissions, 1, -1 do
        if hradio.IncomingTransmissions[i][1] == from then
            table.remove(hradio.IncomingTransmissions, i)
        end
    end

    table.insert(hradio.IncomingTransmissions, {from, chan})
end)

net.Receive("hRadio_IncomingTransmissionEnd", function()
    local ply = localPlayer()
    if not ply then return end

    local chan = net.ReadUInt(hradio.ChannelMaxBitSize)
    local from = player.GetBySteamID64(net.ReadString())

    if not IsValid(from) then return end

    if ply.hradio.MutedChannels[chan] and not hradio.Config.ShowMutedNotifications then
        return
    end

    if not hradio.debug and from == ply then return end

    from.hradio = from.hradio or {}
    from.hradio.IsTalking = false
    from.hradio.LastStopTime = SysTime()

    if not ply.hradio.MutedChannels[chan] and hradio.Config.IncomingTransmissionSounds then
        surface.PlaySound("buttons/button5.wav")
    end

    timer.Simple(0.2, function()
        for i = #hradio.IncomingTransmissions, 1, -1 do
            local transmission = hradio.IncomingTransmissions[i]

            if transmission[1] == from and transmission[2] == chan then
                table.remove(hradio.IncomingTransmissions, i)
                break
            end
        end
    end)

    if IsValid(from.hradio.modelpanel) then
        from.hradio.modelpanel:Remove()
    end
end)

net.Receive("hRadio_PlyOwnRadioStart", function()
    local ply = localPlayer()
    if not ply then return end

    ply.hradio.IsTalking = true
    ply.hradio.LastStartTime = SysTime()

    surface.PlaySound("buttons/button19.wav")
end)

net.Receive("hRadio_PlyOwnRadioEnd", function()
    local ply = localPlayer()
    if not ply then return end

    ply.hradio.IsTalking = false
    ply.hradio.LastStopTime = SysTime()

    surface.PlaySound("buttons/button18.wav")
end)

net.Receive("hRadio_PlyChangeChannelFeedback", function()
    local ply = localPlayer()
    if not ply then return end

    local channel = net.ReadUInt(hradio.ChannelMaxBitSize)

    ply.hradio.ActiveChannel = channel
    hook.Run("hRadio_PlyChangeChannelFeedback", channel)
end)

net.Receive("hRadio_PlyMuteUnmuteChannelFeedback", function()
    local ply = localPlayer()
    if not ply then return end

    local channel = net.ReadUInt(hradio.ChannelMaxBitSize)
    local status = net.ReadBool()

    ply.hradio.MutedChannels[channel] = status
end)
