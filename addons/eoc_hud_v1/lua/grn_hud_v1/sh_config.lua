GRN_HUD_V1 = GRN_HUD_V1 or {}
GRN_HUD_V1.Config = GRN_HUD_V1.Config or {}

GRN_HUDV1 = GRN_HUDV1 or {}
GRN_HUDV1.Config = GRN_HUD_V1.Config

local C = GRN_HUD_V1.Config

C.Enabled = true
C.HideDefaultHUD = true
C.DefaultHudOn = true
C.DefaultOverlayOn = true

C.UpdateInterval = 0.10
C.CompassInterval = 0.04
C.NetworkInterval = 0.50

C.BrandLogoURL = "https://r2.fivemanage.com/CAL8kaFVELoEmru99DXu6/scheres_eoc_logo.png"
C.ShowScreenOverlay = true
C.ShowDebugStats = false
C.ShowRadioPanel = true
C.ShowAmmoPanel = true
C.ShowVoiceSpeaker = true
C.ShowLocalVoiceIndicator = true

C.DHTMLReadyFallbackDelay = 1.25

C.VoiceShowSelf = true

C.RadioUseHelios = true
C.RadioDefaultFrequency = 100
C.RadioDefaultEnabled = false
C.RadioFrequencyNWInt = "grn_radio_frequency"
C.RadioEnabledNWBool = "grn_radio_enabled"

C.LSCSIntegrationEnabled = true
C.LSCSHideOriginalHUD = true
C.LSCSShowForceWhenDrained = true
C.LSCSUpdateInterval = 0.08

C.JetpackIntegrationEnabled = true
C.JetpackHideOriginalHUD = true
C.JetpackUpdateInterval = 0.08

-- Weapon switch menu (replaces the default HL2 weapon selection).
-- Mouse wheel / slot keys open it, left click selects, right click cancels.
-- Respects hud_fastswitch 1 (selects instantly).
C.WeaponSwitchEnabled = true
C.WeaponSwitchSlots = 6
C.WeaponSwitchTimeout = 3
C.WeaponSwitchSounds = true
C.WeaponSwitchVolume = 0.5      -- 0.0 - 1.0
C.WeaponSwitchFastTimeout = 1.5 -- how long the menu stays visible with hud_fastswitch 1
C.WeaponSwitchUpdateInterval = 0.10

C.OverheadEnabled = true
C.OverheadMaxDistance = 850
C.OverheadZOffset = 18
C.Overhead3D2DScale = 0.050
C.OverheadUpdateInterval = 0.35
C.OverheadCloakNWBools = {
    "Cloaked",
    "lscs_cloak",
    "LSCS_Cloak",
}

-- Player OverHead reference-style presentation.
-- Name -> thin divider -> DarkRP job. No background and no HP/armor bars.
-- Typography enlarged for better readability at normal gameplay distances.
C.OverheadLineWidth = 240
C.OverheadLineMinWidth = 220
C.OverheadLineMaxWidth = 460
C.OverheadLineThickness = 2
C.OverheadShadowOffset = 2
