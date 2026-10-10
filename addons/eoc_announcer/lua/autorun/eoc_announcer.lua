--[[
    EoC Auto-Announcer
    Schickt automatisch alle X Minuten Nachrichten in den Server-Chat.
    Keine Commands nötig – läuft ab Serverstart von selbst.
]]

local EoC = {}

---------------------------------------------------------------------
-- KONFIGURATION
---------------------------------------------------------------------
EoC.Interval    = 300                          -- Sekunden (300 = 5 Minuten)
EoC.Prefix      = "[EoC] "
EoC.PrefixColor = Color(252, 178, 73)           -- Farbe vom [EoC]
EoC.TextColor   = Color(236, 233, 224)         -- Farbe vom Text

-- false = alle Nachrichten zusammen alle 5 Min
-- true  = pro 5 Min immer nur die nächste Nachricht (abwechselnd)
EoC.Rotate      = false

EoC.Messages = {
    "Bei Fragen, Bugs oder Beschwerden könnt ihr euch gerne an unser Team wenden.",
    "Bist du schon auf unserem Discord? discord.com/invite/97FNg4GxdW",
}
---------------------------------------------------------------------

if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("EoC_Announce")

    local index = 1

    local function Send(msg)
        net.Start("EoC_Announce")
            net.WriteString(msg)
        net.Broadcast()
    end

    timer.Create("EoC_AutoAnnouncer", EoC.Interval, 0, function()
        if #player.GetHumans() == 0 then return end

        if EoC.Rotate then
            Send(EoC.Messages[index])
            index = index % #EoC.Messages + 1
        else
            for _, msg in ipairs(EoC.Messages) do
                Send(msg)
            end
        end
    end)
end

if CLIENT then
    net.Receive("EoC_Announce", function()
        -- Präfix in der SymChars-Akzentfarbe, damit der Chat zum restlichen Design passt
        local prefixColor = (SYMUI and SYMUI.Accent and SYMUI.Accent()) or EoC.PrefixColor
        chat.AddText(prefixColor, EoC.Prefix, EoC.TextColor, net.ReadString())
    end)
end
