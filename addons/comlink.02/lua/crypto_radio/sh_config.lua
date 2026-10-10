CryptoRadio = CryptoRadio or {}

CryptoRadio.RANGE_SHORT = 1
CryptoRadio.RANGE_LONG  = 2

CryptoRadio.Config = {
    -- Maximale Distanz für /funk und /vfunk in Units (1 Unit ~ 1,9 cm -> 3000 ~ 57 m)
    -- 0 = unbegrenzt (alle Funks reichen so weit wie sie wollen)
    ShortRange = 0,

    -- Abklingzeit in Sekunden zwischen zwei Funksprüchen
    ShortCooldown = 1,
    LongCooldown  = 4,

    -- Maximale Länge einer Nachricht (Zeichen)
    MaxLength = 300,

    -- Tote Spieler können keine Funksprüche empfangen
    DeadCanReceive = false,

    -- Umstehende Spieler (in diesem Radius um den Sender) bekommen den Funk mit.
    -- Normaler Funk ist für sie lesbar, verschlüsselter Funk nur als Zeichensalat.
    -- 0 = deaktiviert
    OverhearRange = 300,

    -- Reichweite für /akt, /me, /eakt, /makt, /scan (Units)
    ActionRange = 600,
    ActionCooldown = 1,

    -- /scan Ablauf (Prozentwerte) und Zeit zwischen den Schritten (Sekunden)
    ScanSteps    = { 10, 25, 39, 53, 55, 75, 86, 99, 100 },
    ScanInterval = 1.2,

    -- Langstrecke fällt aus, wenn die GRN-Antenne zerstört ist (Helio/GRNComms)
    LongRangeNeedsAntenna = true,

    -- Einträge im Funklog (pro Client)
    ClientLogSize = 80,

    -- Störsender
    JammerRadius    = 1500,  -- Units
    JamStrength     = 0.45,  -- Anteil zerstörter Zeichen bei Kurzstrecke (0-1)
    JamStrengthLong = 0.65,  -- Anteil zerstörter Zeichen bei Langstrecke (0-1)
    JammerHealth    = 150,

    -- Comlink (Strivon Comlink): Taste J öffnet den Textfunk über dem Comlink am Arm
    -- (gleicher Arm und Stil wie Funk = H und Squad = G, nur Ego-Perspektive).
    -- Kein Datapad nötig: jeder Spieler kann senden und empfangen. Nur in der Ego-Perspektive.
    ComlinkEnabled = true,
    ComlinkKey = KEY_J,
    ComlinkVisibleRecipients = 4, -- so viele Empfänger sind gleichzeitig sichtbar, Rest per Mausrad
    ComlinkCloseAfterSend = true, -- Comlink nach dem Senden schließen

    -- Funksprüche (Klartext) zusätzlich in der Serverkonsole ausgeben
    ServerConsoleLog = false,

    -- Chat-Befehle (Name ohne / oder !)
    Commands = {
        funk   = { radio = true, range = 1, encrypted = false },
        vfunk  = { radio = true, range = 1, encrypted = true },
        lfunk  = { radio = true, range = 2, encrypted = false },
        vlfunk = { radio = true, range = 2, encrypted = true },

        akt    = { action = "akt" },
        me     = { action = "me" },
        eakt   = { action = "eakt" },
        makt   = { action = "makt" },
        scan   = { scan = true },
    },

    Sounds = {
        -- Piepton beim Empfänger. Alternativen zum Ausprobieren:
        -- "buttons/button17.wav", "buttons/button16.wav", "buttons/combine_button1.wav",
        -- "npc/scanner/combat_scan1.wav", "buttons/button3.wav"
        Beep      = "buttons/button9.wav",
        BeepCount = 2,      -- wie oft gepiept wird (Piep-Piep)
        BeepDelay = 0.14,   -- Abstand zwischen den Pieptönen (Sekunden)
        Send    = "npc/combine_soldier/vo/on1.wav",    -- Sender (für Umstehende hörbar)
        Error   = "buttons/button10.wav",
        Click   = "buttons/lightswitch2.wav",
        ScanTick = "buttons/blip2.wav",
        ScanDone = "buttons/button9.wav",
    },
}

-- Name, der im Funk / Chat angezeigt wird
function CryptoRadio.GetName(ply)
    if not IsValid(ply) then return "Unbekannt" end
    return ply:Nick()
end

-- Ist das Ziel für diese Funkart erreichbar (Distanz)?
function CryptoRadio.InRadioRange(posA, posB, range)
    local max = CryptoRadio.Config.ShortRange or 0
    if range == CryptoRadio.RANGE_LONG or max <= 0 then return true end
    return posA:DistToSqr(posB) <= max ^ 2
end

function CryptoRadio.ToMeters(units)
    return math.Round(units * 0.01905)
end

-- Ist diese Position im Radius eines aktiven Störsenders?
function CryptoRadio.IsJammed(pos)
    local r2 = CryptoRadio.Config.JammerRadius ^ 2
    for _, ent in ipairs(ents.FindByClass("crypto_jammer")) do
        if IsValid(ent) and ent.GetActive and ent:GetActive() and ent:GetPos():DistToSqr(pos) <= r2 then
            return true
        end
    end
    return false
end

-- Ist die GRN-Antenne (Helio Funk) ausgefallen?
function CryptoRadio.IsAntennaDown()
    if SERVER and GRNComms and GRNComms.IsHeliosRadioBlocked then
        return GRNComms.IsHeliosRadioBlocked() == true
    end
    return GetGlobalBool("GRNComms_HeliosBlocked", false)
end
