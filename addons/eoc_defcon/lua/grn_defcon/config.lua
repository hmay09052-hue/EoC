GRN_DEFCON = GRN_DEFCON or {}
GRN_DEFCON.Config = GRN_DEFCON.Config or {}

local C = GRN_DEFCON.Config

-- Existing commands. Levels created from the terminal also work here.
C.ChatCommand = "/defcon"                 -- /defcon opens the system, /defcon 3 sets the level directly
C.CommandOpensMenu = true                 -- /defcon (or grn_defcon) without a number opens the DEFCON menu
C.ConsoleCommand = "grn_defcon"           -- Example: grn_defcon 3
C.SettingsChatCommand = "/defconsettings"
C.SettingsConsoleCommand = "defconsettings"
C.DefaultLevel = 5
C.PersistLevel = true

-- Permissions required to change DEFCON.
C.UseCAMI = true
C.CAMIPrivilege = "DEFCON - Change Level"
C.AllowedUsergroups = {
    superadmin = true,
    admin = true,
	user = true,
	User = true,
    moderator = true
}

-- STAFF button permissions for creating, editing and deleting custom levels.
C.ManageCAMIPrivilege = "DEFCON - Manage Levels"
C.ManagementUsergroups = {
    superadmin = true,
    admin = true,
    moderator = true,
    staff = true
}

-- Limits for levels created from the terminal.
C.MaximumLevelID = 999
C.MaximumCustomLevels = 32
C.CustomLevelsDataFile = "grn_defcon/custom_levels.json"

-- Announcements shown when the level changes.
C.BroadcastChatMessage = true
C.ShowPopupNotification = true
C.NotificationDuration = 6
C.ChangeSound = "https://r2.fivemanage.com/CAL8kaFVELoEmru99DXu6/btf2.wav"
C.ChangeSoundVolume = 1
C.ShowChangedBy = true

-- Compact HUD.
C.Enabled = true
C.PositionX = 0.011
C.PositionY = 0.020
C.WidthScale = 0.32
C.HeightScale = 0.12
C.MinimumWidth = 420
C.MaximumWidth = 620
C.MinimumHeight = 112
C.MaximumHeight = 148

-- Per-player customization.
C.AllowPlayerHUDCustomization = true
C.UserMinimumScale = 0.55
C.UserMaximumScale = 1.65

-- HUD display text.
C.SecurityNetworkLabel = ""
C.OnlineLabel = "ONLINE"
C.DirectiveLabel = "BASE DIRECTIVE ACTIVE"
C.SecurityCodePrefix = ""
C.AllowClientPreviewCommand = false

-- DEFCON terminal entity configuration.
C.Terminal = {
    Model = "models/lordtrilobite/starwars/isd/imp_console_medium01.mdl",
    Spawnable = true,
    AdminOnly = true,
    UseDistance = 155,
    DrawDistance = 900,
    MenuWidthScale = 0.90,
    MenuHeightScale = 0.88,

    Display = {
        Enabled = true,
        Pos = Vector(4.2, -0.4, 86),
        Ang = Angle(0, 90, 90),
        Scale = 0.055,
        -- Pixel offsets inside the 3D2D canvas. Negative X moves the display left.
        OffsetX = -350,
        OffsetY = 0,
        Width = 720,
        Height = 430,
        Title = "DEFCON KONTROLLE",
        Subtitle = "GALAKTISCHE REPUBLIK",
        Prompt = "[E] DRÜCKEN ZUM ÖFFNEN"
    }
}

-- Base levels. Levels created from the terminal are stored separately in /data.
C.Levels = {
    [5] = {
        Name = "NORMALBETRIEB",
        State = "NORMALER BETRIEB",
        Short = "KEINE KRITISCHEN BEDROHUNGEN",
        Description = "Einheiten führen Freigang bzw. zugewiesene Sonderaufgaben aus, Funkdisziplin ist locker zu handhaben.",
        Color = "#55e18f",
        Glow = "rgba(85, 225, 143, .28)"
    },
    [4] = {
        Name = "BEREITSCHAFTSALARM",
        State = "ERHÖHTE WACHSAMKEIT",
        Short = "VERSTÄRKTE ÜBERWACHUNG",
        Description = "Alle Einheiten stellen sich auf eine mögliche Gefahrensituation ein, Waffen sind gesichert zu führen, Einheitshöchst haben sich bei der Einsatzleitung zu melden.",
        Color = "#55b8ff",
        Glow = "rgba(85, 184, 255, .28)"
    },
    [3] = {
        Name = "ANGRIFFSALARM",
        State = "EINSATZBEREITSCHAFT",
        Short = "EINHEITEN IN ALARMBEREITSCHAFT",
        Description = "Ein bestätigter Angriff steht bevor, alle Einheiten beziehen umgehend ihre Gefechtsstationen, Waffen sind zu entsichern und schussbereit zu halten.",
        Color = "#ffd85a",
        Glow = "rgba(255, 216, 90, .28)"
    },
    [2] = {
        Name = "INFILTRATIONSALARM",
        State = "EINDRINGLINGE AN BORD",
        Short = "SICHERUNG DER KERNBEREICHE",
        Description = "Feindliche Eindringlinge wurden innerhalb der Basis geortet, alle Einheiten ziehen sich auf die kritischen Sektoren zurück und verteidigen diese eigenständig.",
        Color = "#ff994d",
        Glow = "rgba(255, 153, 77, .31)"
    },
    [1] = {
        Name = "EVAKUIERUNGSALARM",
        State = "MAXIMALER NOTFALL",
        Short = "ALLE EINHEITEN AUSRÜCKEN",
        Description = "Sofortige Evakuierung zum nächstgelegenen Evakuierungspunkt ist zu befehlen, Einheiten die diesen nicht erreichen gelten als verloren.",
        Color = "#ff4f5e",
        Glow = "rgba(255, 79, 94, .34)"
    }
}