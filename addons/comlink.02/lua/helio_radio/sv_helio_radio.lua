hradio.debug = false
if GetConVar("developer"):GetInt() > 0 then hradio.debug = true end

-------------------
-- Network Setup --
-------------------

util.AddNetworkString("hRadio_PlyStartTalking")
util.AddNetworkString("hRadio_PlyStopTalking")

util.AddNetworkString("hRadio_PlyOwnRadioStart")
util.AddNetworkString("hRadio_PlyOwnRadioEnd")

util.AddNetworkString("hRadio_IncomingTransmissionStart")
util.AddNetworkString("hRadio_IncomingTransmissionEnd")

util.AddNetworkString("hRadio_PlyChangeChannel")
util.AddNetworkString("hRadio_PlyChangeChannelFeedback")

util.AddNetworkString("hRadio_PlyMuteUnmuteChannel")
util.AddNetworkString("hRadio_PlyMuteUnmuteChannelFeedback")
util.AddNetworkString("hRadio_GRNCommsState")
util.AddNetworkString("hRadio_PlyJoinedChannels")

-----------------------------
-- GRN Comms integration --
-----------------------------

function hradio.IsGRNCommsBlocked()
    if GRNComms and GRNComms.IsHeliosRadioBlocked then
        return GRNComms.IsHeliosRadioBlocked() == true
    end

    return GetGlobalBool("GRNComms_HeliosBlocked", false)
end

local function grnBlockedMessage()
    if GRNComms and GRNComms.Config and GRNComms.Config.HeliosBlockedMessage then
        return tostring(GRNComms.Config.HeliosBlockedMessage)
    end

    return "Der Funk ist ausgefallen, weil die Antenne beschädigt ist."
end

local function sendGRNState(target, blocked)
    net.Start("hRadio_GRNCommsState")
    net.WriteBool(blocked == true)
    net.WriteString(grnBlockedMessage())

    if IsValid(target) then
        net.Send(target)
    else
        net.Broadcast()
    end
end

local function denyRadioUse(ply)
    if not IsValid(ply) then return end
    sendGRNState(ply, true)
end

--------------------
-- Initialization --
--------------------

hook.Add("PlayerInitialSpawn", "hRadio_InitializeTable", function(ply)
	ply.hradio = {} -- Jeder Join startet frisch: kein Funk beigetreten, kein Funk aktiv
	timer.Simple(1, function()
		if IsValid(ply) then
			sendGRNState(ply, hradio.IsGRNCommsBlocked())
		end
	end)
end)

-----------------------
-- Utility Functions --
-----------------------

function hradio.CheckTalkers(ply, chanID)
	if !hradio.Channels[chanID] then return end -- Check if channel exists
	local chan = hradio.Channels[chanID]
	if chan.GetTalkers(ply) or chan.Talkers[ply:Team()] then
		return true
	else
		return false
	end
end

-- Hört der Spieler diesen Funk? Nur wenn er beigetreten ist (auf F1-F3 gelegt) oder ihn gerade aktiv hat.
-- Funks, die man nicht stummschalten kann (z.B. Ankündigung), hört man immer.
function hradio.HasJoined(ply, chanID)
	local chan = hradio.Channels[chanID]
	if not chan then return false end
	if not chan.Mutable then return true end

	ply.hradio = ply.hradio or {}
	if ply.hradio.ActiveChannel == chanID then return true end

	return ply.hradio.JoinedChannels ~= nil and ply.hradio.JoinedChannels[chanID] == true
end

function hradio.StartTalking(ply)
	ply.hradio = ply.hradio or {}
	if hradio.IsGRNCommsBlocked() then
		ply.hradio.IsTalking = false
		denyRadioUse(ply)
		return
	end
	if !(ply.hradio and ply.hradio.ActiveChannel) then ply.hradio.ActiveChannel = 0 end
	if ply.hradio.ActiveChannel == 0 then return end
	if hradio.debug then print("Player " .. ply:Name() .. " started talking on channel " .. ply.hradio.ActiveChannel) end

	local chanID = ply.hradio.ActiveChannel
	local chan = hradio.Channels[chanID]

	if chan and !chan.GetTalkers(ply) and !chan.Talkers[ply:Team()] then -- Reset invalid channels to 0
		ply.hradio.ActiveChannel = 0
		return
	end

	ply.hradio.TalkToken = (ply.hradio.TalkToken or 0) + 1
	ply.hradio.IsTalking = true

	if !chan then

		hradio.errorcatcher.Catch(string.format("%s tried to use the radio with an invalid channel: %s", ply:Name(), tostring(chanID)))
		return

	end -- make sure the channel exists

	net.Start("hRadio_IncomingTransmissionStart")
	net.WriteUInt(chanID, hradio.ChannelMaxBitSize)
	net.WriteString(ply:SteamID64())

	local recip = {}

	for _, v in ipairs(player.GetAll()) do
		v.hradio = v.hradio or {}
		local muted = v.hradio.MutedChannels and v.hradio.MutedChannels[chanID]
		if not muted and hradio.HasJoined(v, chanID) and (chan.GetListeners(v) or chan.Listeners[v:Team()]) then
			table.insert(recip, v)
		end
	end

	net.Send(recip)

end

function hradio.StopTalking(ply)
	if not IsValid(ply) then return end
	ply.hradio = ply.hradio or {}
	if not ply.hradio.ActiveChannel or ply.hradio.ActiveChannel == 0 then
		ply.hradio.IsTalking = false
		return
	end
	local token = (ply.hradio.TalkToken or 0) + 1
	ply.hradio.TalkToken = token
	timer.Simple(0.2, function() -- Nicht abschalten, wenn inzwischen wieder gesendet wird
		if IsValid(ply) and ply.hradio and ply.hradio.TalkToken == token then ply.hradio.IsTalking = false end
	end)

	if hradio.debug then print("Player " .. ply:Name() .. " stopped talking on channel " .. ply.hradio.ActiveChannel) end

	local chan = ply.hradio.ActiveChannel
	if !chan then return end
	if !hradio.Channels[chan] then

		hradio.errorcatcher.Catch(string.format("%s has tried to use the radio with an invalid channel: %s", ply:Name(), tostring(chan)))
		ply.hradio.ActiveChannel = 0
		return

	end -- make sure the channel exists

	local key = chan
	chan = hradio.Channels[chan]

	for k,v in ipairs(player.GetAll()) do
		if hradio.HasJoined(v, key) and (chan.GetListeners(v) or chan.Listeners[v:Team()]) then
			net.Start("hRadio_IncomingTransmissionEnd")
			net.WriteUInt(key, hradio.ChannelMaxBitSize)
			net.WriteString(ply:SteamID64())
			net.Send(v)
		end
	end

end

----------------
-- Networking --
----------------

net.Receive("hRadio_PlyMuteUnmuteChannel", function(_, ply) -- Manage muting of channels

	local chan = net.ReadUInt(hradio.ChannelMaxBitSize)
	local status = net.ReadBool()

	if !chan or !hradio.Channels[chan] then hradio.errorcatcher.Catch("Player " .. ply:Name() .. " tried to un/mute an invalid channel") return end -- Check if channel exists
	if !hradio.Channels[chan].Mutable then return end -- Prevent muting of immutable channels

	ply.hradio.MutedChannels = ply.hradio.MutedChannels or {} -- Create the table if it doesn't exist
	ply.hradio.MutedChannels[chan] = status

	net.Start("hRadio_PlyMuteUnmuteChannelFeedback") -- Tell the client whether they succeeded in muting the channel
	net.WriteUInt(chan, hradio.ChannelMaxBitSize)
	net.WriteBool(status)
	net.Send(ply)

end)

net.Receive("hRadio_PlyChangeChannel", function(_, ply)

	local chan = net.ReadUInt(hradio.ChannelMaxBitSize)
	if hradio.IsGRNCommsBlocked() then
		denyRadioUse(ply)
		return
	end

	if !hradio.Channels[chan] and chan != 0 then return end -- Check if channel exists
	if !hradio.CheckTalkers(ply, chan) and chan != 0 then return end -- Check if permissions are correct

	ply.hradio.ActiveChannel = chan
	net.Start("hRadio_PlyChangeChannelFeedback") -- Tell the player whether they successfully changed the channel and what they changed it to
	net.WriteUInt(chan,hradio.ChannelMaxBitSize)
	net.Send(ply)

end)

net.Receive("hRadio_PlyStartTalking", function(ln, ply)
	hradio.StartTalking(ply)
end)

net.Receive("hRadio_PlyStopTalking", function(ln, ply)
	hradio.StopTalking(ply)
end)

-----------
-- Logic --
-----------

local function canHear(listener, talker)
	listener.hradio = listener.hradio or {}
	if !talker.hradio then talker.hradio = {} end
	if hradio.IsGRNCommsBlocked() then
		if talker.hradio.IsTalking then return false, false end
		return
	end

	if talker.hradio.IsTalking then
		local chan = talker.hradio.ActiveChannel

		if !chan then return end
		if chan == 0 then return end
		if !hradio.Channels[chan] then

			hradio.errorcatcher.Catch(string.format("%s tried to use the radio with an invalid channel: %s", talker:Name(), tostring(chan)))
			return

		end -- Only if the channel exists, can't be too safe
		-- Stumm / nicht beigetreten / kein Zuhörer: kein Funk, aber normale Nähe-Sprache bleibt
		if listener.hradio.MutedChannels and listener.hradio.MutedChannels[chan] then return end
		if not hradio.HasJoined(listener, chan) then return end

		chan = hradio.Channels[chan]
		if chan.GetListeners(listener) or chan.Listeners[listener:Team()] then
			return true, false
		end

	end
end

hook.Add("PlayerCanHearPlayersVoice", "hRadio_Think", canHear)

-- VoiceBox FX Integration
-- https://www.gmodstore.com/market/view/voicebox-fx
local function voiceboxCanHear(listener, talker)
	VoiceBox.FX.IsRadioComm(listener:EntIndex(), talker:EntIndex(), false)
	listener.hradio = listener.hradio or {}

	if !talker.hradio then talker.hradio = {} end
	if hradio.IsGRNCommsBlocked() then
		if talker.hradio.IsTalking then return false, false end
		return
	end

	if talker.hradio.IsTalking then
		local chan = talker.hradio.ActiveChannel

		if !chan then return end
		if chan == 0 then return end
		if !hradio.Channels[chan] then

			hradio.errorcatcher.Catch(string.format("%s tried to use the radio with an invalid channel: %s", talker:Name(), tostring(chan)))
			return

		end -- Only if the channel exists, can't be too safe
		-- Stumm / nicht beigetreten / kein Zuhörer: kein Funk, aber normale Nähe-Sprache bleibt
		if listener.hradio.MutedChannels and listener.hradio.MutedChannels[chan] then return end
		if not hradio.HasJoined(listener, chan) then return end

		chan = hradio.Channels[chan]
		if chan.GetListeners(listener) or chan.Listeners[listener:Team()] then
			VoiceBox.FX.IsRadioComm(listener:EntIndex(), talker:EntIndex(), not VoiceBox.FX.__PlayerCanHearPlayersVoice(listener, talker))
			return true, false
		end

	end
end
if VoiceBox and VoiceBox.FX then
	hook.Add("PlayerCanHearPlayersVoice", "hRadio_Think", voiceboxCanHear)
else
	hook.Add("VoiceBox.FX", "hRadio", function()
		hook.Add("PlayerCanHearPlayersVoice", "hRadio_Think", voiceboxCanHear)
	end)
end

hook.Add("GRNComms_StateChanged", "hRadio_GRNCommsStateChanged", function(blocked)
	blocked = blocked == true

	if blocked then
		for _, ply in ipairs(player.GetAll()) do
			if ply.hradio and ply.hradio.IsTalking then
				hradio.StopTalking(ply)
				ply.hradio.IsTalking = false
			end
		end
	end

	sendGRNState(nil, blocked)
end)

timer.Create("hRadio_GRNCommsInitialSync", 1, 1, function()
	sendGRNState(nil, hradio.IsGRNCommsBlocked())
end)


-- Der Client meldet, welchen Funks er beigetreten ist (die auf F1-F3 liegen)
net.Receive("hRadio_PlyJoinedChannels", function(_, ply)
	local count = math.min(net.ReadUInt(5), 16)
	local joined = {}

	for i = 1, count do
		local chanID = net.ReadUInt(hradio.ChannelMaxBitSize)
		if hradio.Channels[chanID] then
			joined[chanID] = true
		end
	end

	ply.hradio = ply.hradio or {}
	ply.hradio.JoinedChannels = joined
end)
