hradio.Config = {}
hradio.Config.MenuPosition = {}

hradio.Config.UISounds = true
hradio.Config.IncomingTransmissionSounds = true
hradio.Config.ShowMutedNotifications = true

hradio.Config.AnimName = "hradio_sw_comlink"
hradio.Config.UseCloseAnim = true
hradio.Config.AnimClose = "hradio_sw_comlink_close"
hradio.Config.OpenDelay = 0.4

hradio.Config.UseMasterHands = false
hradio.Config.OverrideIndexWithBoneName = true

hradio.Config.BoneIndex = 4
hradio.Config.IndividualBoneIndexes = {
    ["models/error.mdl"] = 0,
    ["models/weapons/v_hands.mdl"] = 1
}

hradio.Config.MenuPosition.Up = 8.3
hradio.Config.MenuPosition.Forward = 0.4
hradio.Config.MenuPosition.Right = -2.6
hradio.Config.MenuPosition.UpRot = -80
hradio.Config.MenuPosition.FwdRot = 90
hradio.Config.MenuPosition.RgtRot = -10
hradio.Config.MenuScale = 0.021 -- Größe des Menüs (kleiner = kleineres Menü)
hradio.Config.MenuTopMargin = 0.1 -- Freier Rand oben (Anteil der Bildschirmhöhe), damit nichts in die HUD-Leiste (DEFCON usw.) ragt
hradio.Config.MenuBottomMargin = 0.02 -- Freier Rand unten (Anteil der Bildschirmhöhe)

hradio.Config.AlwaysUse3PMenu = false

-- Comlink-Menü (nur Ego-Perspektive): Taste öffnet/schließt das Funkmenü über dem Comlink am Handgelenk.
-- Sitzt das Menü nicht richtig über dem Comlink, MenuPosition oben anpassen.
hradio.Config.ComlinkKey = KEY_H

-- Menü steht gerade (aufrecht zur Kamera) über dem Comlink und wandert mit dem Arm mit.
-- false = altes Verhalten: Menü liegt schräg auf dem Arm (dann gilt MenuPosition oben).
hradio.Config.MenuUpright = true
hradio.Config.MenuUprightOffset = {
    Up = 1.5,     -- Abstand über dem Comlink (größer = höher)
    Right = 0,    -- seitlich verschieben (positiv = nach rechts)
    Forward = 0   -- nach vorne/hinten (positiv = weiter weg)
}
hradio.Config.MenuUprightTilt = 0 -- nach hinten kippen in Grad, 0 = genau gerade

-- Lage des Comlink-Geräts im Modell (aus c_vmaniphradio_comlink.mdl ausgelesen), Menü sitzt mittig darüber
hradio.Config.ComlinkBone = "ValveBiped.Bip01_L_Forearm"
hradio.Config.ComlinkLocalPos = Vector(10.48, -0.13, 1.64)

-- Eigene Hände für den Comlink-Arm (z.B. Klon-Hände). nil = Hände des Spielermodells
hradio.Config.ComlinkHandsModel = nil
hradio.Config.ComlinkViewModelFOV = 0 -- Sichtfeld für den Arm, 0 = automatisch (wie das Waffen-Viewmodel)
hradio.Config.ComlinkVisibleChannels = 4 -- So viele Funks sind gleichzeitig sichtbar, Rest per Mausrad / Pfeile

-- Squad-Menü auf dem Comlink (gleicher Arm wie der Funk). Es ist immer nur eine App offen.
-- Die Taste kann jeder Spieler im Squad-Einstellungsmenü ändern (Comlink > SQUAD > Einstellungen),
-- Server-Standard: Squad-Admin (!squadsadmin) > Keybinds. SquadKey gilt, wenn dort nichts eingestellt ist.
hradio.Config.SquadEnabled = true
hradio.Config.SquadKey = KEY_G
hradio.Config.SquadVisibleMembers = 5 -- So viele Mitglieder sind gleichzeitig sichtbar, Rest per Mausrad / Pfeile

-- Medic-Menü (Kraken's Medical System) auf dem Comlink – gleicher Arm, gleiche Größe und gleiches Design.
-- Öffnen/Schließen mit K (nur Ego-Perspektive), zusätzlich über den Chat-Befehl des Medical-Systems (!medical).
-- Der Textfunk (J) wird in lua/crypto_radio/sh_config.lua eingestellt.
hradio.Config.MedicEnabled = true
hradio.Config.MedicKey = nil -- nil = Taste aus dem Medical-System (Standard K, änderbar unter Volles Menü > Einstellungen)
hradio.Config.MedicThirdPersonClassic = false -- true = in der Third Person das alte 2D-Medizinmenü öffnen

-- Schnellbehandlung (Feld SCHNELL rechts neben dem Medic-Menü): Bei Behandlung/Medikamenten/Erweitert erscheint eine
-- Folge aus Pfeiltasten in zufälliger Reihenfolge. Richtig eingegeben = Behandlung sofort fertig, falsch = von vorn.
hradio.Config.MedicQuickTreat = true -- immer an; false = für alle aus
hradio.Config.MedicQuickTreatLength = 4 -- 4 = jede Pfeiltaste genau einmal; mehr = länger/schwerer (max. 12)
hradio.Config.BoneName = "ValveBiped.Bip01_L_Hand" -- Wird benutzt, wenn OverrideIndexWithBoneName = true

hradio.Config.ExemptFrom1PMenu = {
    ["weapon_example"] = true,
    ["weapon_hands"] = true
}

-- Schnellwahl-Funks: Im Funkmenü einen Kanal auf eine Taste legen, Taste drücken schaltet den Kanal an/aus.
hradio.Config.HotkeysEnabled = true
hradio.Config.HotkeySlots = {
    {Key = KEY_F1, Label = "F1"},
    {Key = KEY_F2, Label = "F2"},
    {Key = KEY_F3, Label = "F3"}
}
hradio.Config.ShowHotkeyHUD = true -- F1/F2/F3-Boxen oben rechts anzeigen (nur belegte Tasten)
hradio.Config.HotkeyHUDY = 0 -- Zusätzlicher Abstand von oben (Anteil der Bildschirmhöhe)
hradio.Config.HotkeyHUDOffset = 50 -- Abstand der F-Boxen von oben in Pixeln (bei 1080p), direkt unter der Datumszeile. Größer = weiter unten
hradio.Config.HotkeyHUDOffsetX = 42 -- Abstand der F-Boxen vom rechten Rand in Pixeln (bei 1080p). Größer = weiter links

include("sh_helio_config_channels.lua")
