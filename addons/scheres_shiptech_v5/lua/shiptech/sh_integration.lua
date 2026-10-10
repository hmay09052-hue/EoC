--[[
    ShipTech – Kopplung an das Militärische Funksystem (crypto_radio)
    Beschädigte Kommunikation = Funksprüche gestört (Störsender-Effekt),
    ausgefallene Kommunikation = zusätzlich kein Langstreckenfunk.
    Am Funksystem selbst muss nichts geändert werden.
]]

local C = ShipTech.Config

local function CommsStage()
    local c = ShipTech.Sys and ShipTech.Sys("comms")
    if not c then return 0 end
    return ShipTech.StageOf(c.health)
end

function ShipTech.CommsJammed()
    if not C.CryptoRadio.Enabled then return false end
    return CommsStage() >= C.CryptoRadio.JamAtStage
end

function ShipTech.CommsAntennaDown()
    if not C.CryptoRadio.Enabled then return false end
    return CommsStage() >= C.CryptoRadio.AntennaDownStage
end

local function WrapCryptoRadio()
    if not CryptoRadio or CryptoRadio._ShipTechWrapped then return end
    if not CryptoRadio.IsJammed or not CryptoRadio.IsAntennaDown then return end
    CryptoRadio._ShipTechWrapped = true

    local oldJammed = CryptoRadio.IsJammed
    CryptoRadio.IsJammed = function(pos, ...)
        if ShipTech.CommsJammed() then return true end
        return oldJammed(pos, ...)
    end

    local oldAntenna = CryptoRadio.IsAntennaDown
    CryptoRadio.IsAntennaDown = function(...)
        if ShipTech.CommsAntennaDown() then return true end
        return oldAntenna(...)
    end

    MsgC(Color(252, 178, 73), "[ShipTech] ", color_white, "Funksystem (crypto_radio) gekoppelt.\n")
end

hook.Add("InitPostEntity", "ShipTech_CryptoRadio", WrapCryptoRadio)
timer.Simple(1, WrapCryptoRadio)
