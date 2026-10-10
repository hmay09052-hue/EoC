local lply = LocalPlayer()

hradio = hradio or {}

local function refreshLocalPlayer()
    lply = LocalPlayer()
    return IsValid(lply)
end

local function ensureState()
    if not refreshLocalPlayer() then return false end

    lply.hradio = lply.hradio or {}
    lply.hradio.MutedChannels = lply.hradio.MutedChannels or {}
    lply.hradio.ActiveChannel = lply.hradio.ActiveChannel or 0

    return true
end

local function setVoiceEnabled(enabled)
    if permissions and permissions.EnableVoiceChat then
        permissions.EnableVoiceChat(enabled == true)
    end
end

local function stopLocalRadioVoice(sendToServer)
    if not ensureState() then return end

    local wasTalking = lply.hradio.RadioTalkStarted == true or lply.hradio.IsTalking == true

    lply.hradio.RadioTalkStarted = false
    lply.hradio.IsTalking = false
    lply.hradio.LastStopTime = SysTime()

    setVoiceEnabled(false)

    if sendToServer and wasTalking then
        net.Start("hRadio_PlyStopTalking")
        net.SendToServer()
    end
end

local function denyLocalRadioVoice()
    if not ensureState() then return end

    stopLocalRadioVoice(true)
    lply:ConCommand("-voicerecord")
end

local function closeRadioMenu()
    if not ensureState() then return end

    -- nur den Funk schließen, ein offenes Squad-Menü bleibt
    if hradio.CloseComlinkApp then
        hradio.CloseComlinkApp("radio")
    end

    if IsValid(lply.hradio.RadioMenu) then
        lply.hradio.RadioMenu:Remove()
        lply.hradio.RadioMenu = nil
    end

    lply.hradio.ImguiRadioMenuOpen = false
    lply.hradio.ImguiRadioMenuPending = false
    gui.EnableScreenClicker(false)
end

local function anyRadioMenuOpen()
    if not ensureState() then return false end
    return IsValid(lply.hradio.RadioMenu) or (hradio.IsComlinkOpen and hradio.IsComlinkOpen("radio"))
end

hradio.CloseRadioMenu = closeRadioMenu

concommand.Add("+hradio_talk", function(ply)
    if not ensureState() then return end

    if hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked() then
        denyLocalRadioVoice()

        if hradio.ShowGRNCommsBlocked then
            hradio.ShowGRNCommsBlocked()
        end

        return
    end

    local channelId = tonumber(lply.hradio.ActiveChannel) or 0

    if channelId <= 0 then
        denyLocalRadioVoice()
        return
    end

    local chan = hradio.Channels and hradio.Channels[channelId]

    if not chan then
        denyLocalRadioVoice()
        return
    end

    local canTalk = false

    if chan.GetTalkers then
        canTalk = chan.GetTalkers(ply) == true
    end

    if not canTalk and chan.Talkers then
        canTalk = chan.Talkers[ply:Team()] == true
    end

    if not canTalk then
        denyLocalRadioVoice()
        return
    end

    setVoiceEnabled(true)

    lply.hradio.IsTalking = true
    lply.hradio.RadioTalkStarted = true
    lply.hradio.LastStartTime = SysTime()

    if hradio.RemoveOriginalVCHud then
        hradio.RemoveOriginalVCHud(lply)

        timer.Simple(RealFrameTime() * 2, function()
            if IsValid(lply) and hradio.RemoveOriginalVCHud then
                hradio.RemoveOriginalVCHud(lply)
            end
        end)
    end

    if hradio.Config.UISounds then
        sound.Play("buttons/button19.wav", lply:EyePos(), 75, 100, 0.5)
    end

    net.Start("hRadio_PlyStartTalking")
    net.SendToServer()
end)

concommand.Add("-hradio_talk", function()
    if not ensureState() then return end

    local wasTalking = lply.hradio.RadioTalkStarted == true or lply.hradio.IsTalking == true

    lply.hradio.RadioTalkStarted = false
    lply.hradio.IsTalking = false
    lply.hradio.LastStopTime = SysTime()

    setVoiceEnabled(false)

    if wasTalking then
        if hradio.Config.UISounds then
            sound.Play("buttons/button18.wav", lply:EyePos(), 75, 100, 0.5)
        end

        net.Start("hRadio_PlyStopTalking")
        net.SendToServer()
    end
end)

-- Normale Sprachtaste: Ist ein Funk aktiv (z.B. per F1-F3 angeschaltet), geht die Stimme über Funk.
-- Ohne dieses Signal weiß der Server nicht, dass gefunkt wird, und niemand im Funk hört einen.
function hradio.StartVoiceRadio()
    if not ensureState() then return end
    if lply.hradio.RadioTalkStarted or lply.hradio.VoiceRadio then return end
    if hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked() then return end

    local channelId = tonumber(lply.hradio.ActiveChannel) or 0
    if channelId <= 0 or not hradio.CanTalkOnChannel or not hradio.CanTalkOnChannel(channelId, lply) then return end

    lply.hradio.VoiceRadio = true
    lply.hradio.IsTalking = true
    lply.hradio.LastStartTime = SysTime()

    net.Start("hRadio_PlyStartTalking")
    net.SendToServer()
end

function hradio.StopVoiceRadio()
    if not ensureState() then return end
    if not lply.hradio.VoiceRadio then return end

    lply.hradio.VoiceRadio = false
    lply.hradio.IsTalking = false
    lply.hradio.LastStopTime = SysTime()

    net.Start("hRadio_PlyStopTalking")
    net.SendToServer()
end

hook.Add("PlayerStartVoice", "hRadio_VoiceKey", function(ply)
    if ply ~= LocalPlayer() then return end

    hradio.StartVoiceRadio()
end)

hook.Add("PlayerEndVoice", "hRadio_VoiceKey", function(ply)
    if ply ~= LocalPlayer() then return end

    hradio.StopVoiceRadio()
end)

concommand.Add("+hradio_menu", function(ply)
    if not ensureState() then return end

    if hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked() then
        closeRadioMenu()

        if hradio.ShowGRNCommsBlocked then
            hradio.ShowGRNCommsBlocked()
        end

        return
    end

    -- Comlink: gleiche Umschaltung wie die H-Taste (mit Sperre gegen Doppel-Auslösung)
    if hradio.ToggleComlink and not IsValid(lply.hradio.RadioMenu) then
        hradio.ToggleComlink("radio")
        return
    end

    if anyRadioMenuOpen() then
        closeRadioMenu()
        return
    end

    lply.hradio.ImguiRadioMenuOpen = false
    lply.hradio.ImguiRadioMenuPending = false

    -- Comlink über dem Handgelenk (Ego-Perspektive), siehe helio_radio_3d2dmenu.lua
    if hradio.OpenComlink then
        hradio.OpenComlink("radio")
    elseif hradio.OpenMenu2D then
        lply.hradio.RadioMenu = hradio.OpenMenu2D()
    end
end)

concommand.Add("-hradio_menu", function()
end)


