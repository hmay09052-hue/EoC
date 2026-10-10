AddCSLuaFile()

hradio.Channels = {}
hradio.Channelcount = 0
hradio.ChannelMaxBitSize = 32

function hradio.AddChannel(input)
    hradio.Channels = hradio.Channels or {}

    if not isstring(input.Name) or
       not istable(input.Talkers) or
       not istable(input.Listeners) or
       not isfunction(input.GetTalkers) or
       not isfunction(input.GetListeners) or
       not isbool(input.Mutable) or
       not IsColor(input.Colour) then

        hradio.errorcatcher.CatchLater(
            "Invalid radio channel configuration: " .. tostring(input.Name or "UNKNOWN")
        )

        return
    end

    local data = {
        Name = input.Name,
        Listeners = {},
        Talkers = {},
        GetTalkers = input.GetTalkers,
        GetListeners = input.GetListeners,
        Mutable = input.Mutable,
        Color = input.Colour
    }

    for _, teamId in ipairs(input.Listeners) do
        data.Listeners[teamId] = true
    end

    for _, teamId in ipairs(input.Talkers) do
        data.Talkers[teamId] = true
    end

    table.insert(hradio.Channels, data)

    hradio.Channelcount = #hradio.Channels
    hradio.ChannelMaxBitSize = math.max(
        1,
        math.ceil(math.log(math.max(hradio.Channelcount, 1)) / math.log(2) + 1)
    )
end
