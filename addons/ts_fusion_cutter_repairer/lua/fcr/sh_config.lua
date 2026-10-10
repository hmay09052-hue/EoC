FCR = FCR or {}
FCR.Config = FCR.Config or {}

local C = FCR.Config

C.Language = "de" -- en / es / ru / de / fr / pt / uk
C.FallbackLanguage = "en"
C.SystemName = false -- optional custom override
C.Debug = false
C.RepairDistance = 210
C.RepairRangeGrace = 48
C.TraceHullHalfSize = 10
C.UseNearestPointRange = true
C.MonitorInterval = 0.08
C.MaxAttempts = 3
C.RequireAimLock = true
C.FreezePlayerDuringRepair = true
C.CancelIfWeaponSwitched = true
C.ConsumeAttemptOnPhaseFailure = true
C.ResetDelay = 0.9
C.RepairToFull = true
C.SessionLockPerVehicle = true
C.AllowSpectators = false

C.AllowedUsergroups = {}
C.AllowedJobs = {}

-- Waffen, die das Reparaturprotokoll starten können / das HUD anzeigen
-- (weapon_garlog_datapad = GAR-Datapad, ein Werkzeug für Logistik, Bau & Technik)
C.ToolClasses = {
    ["ts_fusioncutter_repairer"] = true,
    ["weapon_garlog_datapad"] = true,
}

C.HUD = {
    Enabled = true,
    Width = 316,
    Height = 84,
    OffsetY = 118,
    ShowWhenAiming = true,
    FadeSpeed = 8
}

C.Sounds = {
    Start = "buttons/button14.wav",
    PhaseAdvance = "fcr/f_completed.mp3",
    Success = "fcr/completed.wav",
    Failure = "fcr/fail.mp3",
    Cancel = "buttons/button19.wav",
    Invalid = "items/medshotno1.wav",
    Phase1Tick = "buttons/blip1.wav",
    Phase2Click = "fcr/beepclick2.mp3",
    Phase3Click = "fcr/beepclick.mp3"
}

-- Farben passend zum Echoes of Clones HUD (grn_hud_v1)
C.Colors = {
    Bg = Color(7, 9, 12),
    BgSoft = Color(8, 11, 15),
    Surface = Color(14, 18, 23),
    SurfaceAlt = Color(20, 25, 31),
    Smoke = Color(5, 7, 10),
    Stroke = Color(207, 216, 228, 38),
    StrokeStrong = Color(207, 216, 228, 77),
    Text = Color(244, 241, 233),
    TextSoft = Color(216, 219, 225),
    Muted = Color(157, 163, 173),
    Dim = Color(101, 107, 117),
    Warm = Color(252, 178, 73),
    Heat = Color(252, 178, 73),
    Danger = Color(225, 88, 88),
    Success = Color(74, 203, 130),
    Violet = Color(90, 170, 255),
    Teal = Color(80, 200, 220),
    Gold = Color(252, 178, 73),
    WhiteWarm = Color(244, 241, 233),
    Phase1 = Color(252, 178, 73),
    Phase1Alt = Color(74, 203, 130),
    Phase2 = Color(252, 178, 73),
    Phase2Alt = Color(80, 200, 220),
    Phase3 = Color(252, 178, 73),
    Phase3Alt = Color(225, 88, 88)
}

C.Panel = {
    MaxWidth = 1380,
    MaxHeight = 860,
    WidthFrac = 0.84,
    HeightFrac = 0.82,
    CenterBiasX = 18,
    CenterBiasY = 0
}

C.Phase1 = {
    AreaW = 1040,
    AreaH = 520,
    SegmentCount = 8,
    SafeRadius = 34,
    MaxDeviation = 44,
    SampleInterval = 0.055,
    FinishRadius = 36,
    StartPadding = 74,
    VerticalVariance = 118
}

C.Phase2 = {
    AreaW = 1040,
    AreaH = 520,
    NodeCount = 7,
    MinSpacing = 116,
    Padding = 94,
    NodeRadius = 42,
    TrollEnabled = false,
    TrollChance = 0.45,
    TrollMinInterval = 0.95,
    TrollMaxInterval = 1.75,
    TrollDuration = 0.78,
    StartInputLock = 0.28,
    InputCooldown = 0.10
}

C.Phase3 = {
    AreaW = 1040,
    AreaH = 520,
    PointCount = 7,
    PointLifetime = 1.05,
    Radius = 40,
    SpawnPadding = 94
}

C.Difficulty = {
    Enabled = true,
    UseVehicleBaseHealth = true,
    Levels = {
        {
            Id = "easy",
            Name = "EASY",
            MinHealth = 0,
            MaxHealth = 800,
            Phase1 = {
                SegmentCount = 6,
                SafeRadius = 38,
                MaxDeviation = 48,
                FinishRadius = 40,
                StartPadding = 76,
                VerticalVariance = 84
            },
            Phase2 = {
                NodeCount = 5,
                MinSpacing = 132,
                Padding = 102,
                NodeRadius = 46,
                StartInputLock = 0.28,
                InputCooldown = 0.10
            },
            Phase3 = {
                PointCount = 5,
                PointLifetime = 1.28,
                Radius = 42,
                SpawnPadding = 102
            }
        },
        {
            Id = "medium",
            Name = "MEDIUM",
            MinHealth = 800,
            MaxHealth = 1200,
            Phase1 = {
                SegmentCount = 8,
                SafeRadius = 34,
                MaxDeviation = 44,
                FinishRadius = 36,
                StartPadding = 74,
                VerticalVariance = 118
            },
            Phase2 = {
                NodeCount = 7,
                MinSpacing = 116,
                Padding = 94,
                NodeRadius = 42,
                StartInputLock = 0.28,
                InputCooldown = 0.10
            },
            Phase3 = {
                PointCount = 7,
                PointLifetime = 1.05,
                Radius = 40,
                SpawnPadding = 94
            }
        },
        {
            Id = "hard",
            Name = "HARD",
            MinHealth = 1200,
            MaxHealth = math.huge,
            Phase1 = {
                SegmentCount = 11,
                SafeRadius = 29,
                MaxDeviation = 36,
                FinishRadius = 32,
                StartPadding = 72,
                VerticalVariance = 146
            },
            Phase2 = {
                NodeCount = 9,
                MinSpacing = 98,
                Padding = 84,
                NodeRadius = 38,
                TrollEnabled = true,
                TrollChance = 0.62,
                TrollMinInterval = 0.72,
                TrollMaxInterval = 1.28,
                TrollDuration = 0.68,
                StartInputLock = 0.32,
                InputCooldown = 0.11
            },
            Phase3 = {
                PointCount = 10,
                PointLifetime = 0.84,
                Radius = 36,
                SpawnPadding = 80
            }
        }
    }
}

