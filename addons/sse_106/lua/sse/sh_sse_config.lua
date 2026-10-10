SSE.Config.FrameTitleFont = "!Agency FB@50#1000"
SSE.Config.ButtonFont = "!Agency FB@40#1"

SSE.Config.HUDDistance = 300
SSE.Config.HUDInteractLang = "Drücke [%s] zum interagieren!"

-- Design der Interaktions-Anzeige (wenn man ein SSE-Entity ansieht)
SSE.Config.HUD = {
    TitleFont = "!Agency FB@45#1000",
    AurebeshFont = "!Aurebesh@22#500", -- benötigt resource/fonts/aurebesh.ttf (Schriftname "Aurebesh")
    InteractFont = "!Roboto@22#800",
    TitleColor = Color(255, 255, 255),
    AurebeshColor = Color(235, 235, 235),
    InteractColor = Color(255, 255, 255),
    Background = Color(15, 15, 18, 170),
    Accent = Color(252, 178, 73, 200),
}



SSE.Config.Boards = {} -- Dont Touch this unless you know what you're doing!
-- This is the config for the boards. You can add as many boards as you want.

SSE.Config.Boards["Default"] = {
    model = "models/hunter/plates/plate3x5.mdl",
    background = Color(50, 50, 50),
    width = 2372,
    height = 1420,
    pages = {
        [1] = {
            --material = "path/to/material.png",
            --imgur = "ri2f55g",
        },
    } 
}
SSE.Config.Boards["Example"] = {
    model = "models/hunter/plates/plate2x2.mdl",
    background = Color(50, 50, 50),
    width = 960,
    height = 960,
    pages = {
        [1] = {
            --material = "shared/RPGRUNDLAGEN.png",
            imgur = "ri2f55g",
        },
        [2] = {
            imgur = "kFOCa5N"
        },
        [3] = {
            imgur = "D3x3hiD"
        }
    } 
}
-- END OF BOARD CONFIGURATION



SSE.Config.AmmoBox = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.AmmoBox["Model"] = "models/reizer_props/srsp/sci_fi/crate_01/crate_01.mdl"
SSE.Config.AmmoBox["Amount"] = 100
SSE.Config.AmmoBox["HUDName"] = "Munitionskiste"



SSE.Config.Trainingsbox = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Trainingsbox["Model"] = "models/reizer_props/srsp/sci_fi/crate_04/crate_04.mdl"
SSE.Config.Trainingsbox["HUDName"] = "Trainingsbox"



SSE.Config.Healbox = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Healbox["Model"] = "models/reizer_props/srsp/sci_fi/crate_03/crate_03.mdl"
SSE.Config.Healbox["HUDName"] = "Medizinische Ressourcen"


SSE.Config.TempWepStorage = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.TempWepStorage["Model"] = "models/reizer_props/srsp/sci_fi/armory_01/armory_01.mdl"
SSE.Config.TempWepStorage["KeepWeapons"] = {"weapon_fists","mvp_perfecthands"}
SSE.Config.TempWepStorage["HUDName"] = "Waffenabnahme"


SSE.Config.WeaponDrop = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.WeaponDrop["Model"] = "models/reizer_props/srsp/sci_fi/crate_04/crate_04.mdl"
SSE.Config.WeaponDrop["HUDName"] = "Waffenkiste"




-- Turbolaser Access Console Config
SSE.Config.TurbolaserConsole = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.TurbolaserConsole["Model"] = "models/reizer_props/srsp/sci_fi/console_02_1/console_02_1.mdl"
SSE.Config.TurbolaserConsole["TurbolaserClass"] = {"lvs_turbo_laser"}
SSE.Config.TurbolaserConsole["TurbolaserName"] = "Turbolaser"
SSE.Config.TurbolaserConsole["FrameTitle"] = "Turbolaserkonsole"
SSE.Config.TurbolaserConsole["HUDName"] = "Turbolaserkonsole"

SSE.Config.TurbolaserConsole2 = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.TurbolaserConsole2["Model"] = "models/kingpommes/starwars/misc/turbolaser_seat_dummy.mdl"
SSE.Config.TurbolaserConsole2["TurbolaserClass"] = {"lvs_turbo_laser"}
SSE.Config.TurbolaserConsole2["TurbolaserName"] = "Turbolaser"
SSE.Config.TurbolaserConsole2["FrameTitle"] = "Turbolaserkonsole"
SSE.Config.TurbolaserConsole2["HUDName"] = "Turbolaserkonsole"



SSE.Config.EventSpawn = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.EventSpawn["Alternative"] = false -- Only change this if the event spawn is not working properly. If it's not working properly, set this to true. Restart Server/Map after changing.




SSE.Config.VehicleRequisition = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.VehicleRequisition["Model"] = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl"
SSE.Config.VehicleRequisition["HUDName"] = "Fahrzeugterminal"
SSE.Config.VehicleRequisition.Lang = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.VehicleRequisition.Lang["Title"] = "Fahrzeugterminal"
SSE.Config.VehicleRequisition.Lang["ChooseSpawn"] = "Spawnpoints"
SSE.Config.VehicleRequisition.Lang["VehStored"] = "Fahrzeug im Hangar geparkt!"
SSE.Config.VehicleRequisition.Lang["NoAccess"] = "Du hast keinen Zugriff zu republikanischen Fahrzeugen!"
SSE.Config.VehicleRequisition.Lang["NoAccessVeh"] = "Du hast keinen Zugriff zu diesem Fahrzeug!"
SSE.Config.VehicleRequisition.Lang["VehDestroyed"] = "Dein Fahrzeug wurde im Hangar zur Reparatur geparkt."
SSE.Config.VehicleRequisition["GetVehicles"] = function(ply) -- Example for DARKRP
    if !DarkRP then return {} end
    local jobTable = ply:getJobTable()
    return jobTable.vehicles or {}
end


SSE.Config.WeaponBox = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.WeaponBox["Model"] = "models/reizer_props/srsp/sci_fi/armory_02/armory_02.mdl"
SSE.Config.WeaponBox["FrameTitle"] = "Waffenkiste"
SSE.Config.WeaponBox["NoWeps"] = "Es befindet sich keine Waffe in der Kiste!"
SSE.Config.WeaponBox["GetWeapons"] = function(ply) -- Example for DARKRP
    if !DarkRP then return {} end
    local jobTable = ply:getJobTable()
    return jobTable.weaponbox or {}
end
SSE.Config.WeaponBox["HUDName"] = "Waffenkiste"



SSE.Config.Broadcast = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Broadcast["Model"] = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl"
SSE.Config.Broadcast["Enabled"] = "Sprachanlage aktiviert, bitte Spracheingabe."
SSE.Config.Broadcast["Disabled"] = "Spracheingabe deaktiviert"
SSE.Config.Broadcast["Sound"] = "ambient/alarms/klaxon1.wav"
SSE.Config.Broadcast["HUDName"] = "Ankündigungskonsole"


SSE.Config.GalaxyMap = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.GalaxyMap["Model"] = "models/lt_c/holograms/console_hr.mdl"
SSE.Config.GalaxyMap["HUDName"] = "Galaxiekarte"


SSE.Config.URLConsole = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.URLConsole["Model"] = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl"


SSE.Config.Closet = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Closet["Model"] = "models/reizer_props/srsp/sci_fi/armory_02_1/armory_02_1.mdl"
SSE.Config.Closet["HUDName"] = "Kleiderschrank"
SSE.Config.Closet["FrameTitle"] = "Kleiderschrank"
SSE.Config.Closet["Save"] = "Speichern"
SSE.Config.Closet["Load"] = "Laden"
SSE.Config.Closet["GetModels"] = function(ply) -- Example for DARKRP
    if !DarkRP then return {} end
    return ply:getJobTable().model
end



SSE.Config.Holotable = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Holotable["Model"] = "models/reizer_props/srsp/sci_fi/command_table_02/command_table_02.mdl"


SSE.Config.RadarConsole = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.RadarConsole["Model"] = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl"
SSE.Config.RadarConsole["FrameTitle"] = "Radarkonsole"
SSE.Config.RadarConsole["IgnoreClasses"] = {"lvs_turbo_laser"}
SSE.Config.RadarConsole["Rescan"] = "Rescan"
SSE.Config.RadarConsole["HUDName"] = "Air Traffic Control"



SSE.Config.Scanner = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Scanner["Model"] = "models/hunter/plates/plate2x2.mdl"
SSE.Config.Scanner["Vehicles"] = "FAHRZEUGE"
SSE.Config.Scanner["Lifeforms"] = "LEBENSFORMEN"
SSE.Config.Scanner["Droids"] = "DROIDEN"
SSE.Config.Scanner["Sound"] = "buttons/button19.wav"
SSE.Config.Scanner["Size"] = 480 

SSE.Config.Scanner["BackgroundColor"] = Color(0, 0, 200, 200)
SSE.Config.Scanner["SelfColor"] = Color(0, 255, 0, 200)
SSE.Config.Scanner["Target"] = Color(255, 0, 0, 200)



SSE.Config.LiveScanner = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.LiveScanner["Model"] = "models/hunter/plates/plate1x1.mdl"
SSE.Config.LiveScanner["Size"] = 245

SSE.Config.LiveScanner["BackgroundColor"] = Color(0, 0, 200, 200)
SSE.Config.LiveScanner["SelfColor"] = Color(0, 255, 0, 200)
SSE.Config.LiveScanner["Target"] = Color(255, 0, 0, 200)

SSE.Config.LiveScanner["ShowNames"] = false



SSE.Config.Datapad = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Datapad["Model"] = "models/lt_c/sci_fi/computers/crystal_hdd.mdl"
SSE.Config.Datapad["FrameTitle"] = "Datapad"
SSE.Config.Datapad["Save"] = "Speichern"
SSE.Config.Datapad["Font"] = "!Agency FB@40#1"



SSE.Config.RestrictedSign = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.RestrictedSign["Model"] = "models/reizer_props/srsp/sci_fi/barrel_04/barrel_04.mdl"

SSE.Config.RestrictedSign["Text1"] = "WARNING"
SSE.Config.RestrictedSign["Font1"] = "!Agency FB@100#1000"
SSE.Config.RestrictedSign["Color1"] = Color(255,0,0)

SSE.Config.RestrictedSign["Text2"] = "RESTRICTED MILITARY AREA"
SSE.Config.RestrictedSign["Font2"] = "!Agency FB@75#1000"
SSE.Config.RestrictedSign["Color2"] = Color(255,0,0)

SSE.Config.RestrictedSign["Text3"] = "AUFNAHME- UND FOTOGRAFIEVERBOT"
SSE.Config.RestrictedSign["Font3"] = "!Agency FB@40#1000"
SSE.Config.RestrictedSign["Color3"] = Color(255,255,255)


SSE.Config.RestrictedSign["Text4"] = "NO TRESPASSING"
SSE.Config.RestrictedSign["Font4"] = "!Agency FB@40#1000"
SSE.Config.RestrictedSign["Color4"] = Color(255,255,255)



SSE.Config.Battlepad = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Battlepad["Model"] = "models/reizer_props/srsp/sci_fi/command_table_02/command_table_02.mdl"
SSE.Config.Battlepad["Size"] = 400
SSE.Config.Battlepad["EnemyEntities"] = {"lvs_fakehover_aat", "lvs_walker_hsd"}
SSE.Config.Battlepad["FriendlyEntities"] = {"lvs_fakehover_iftx"}
SSE.Config.Battlepad["BackgroundColor"] = Color(0, 0, 200, 200)



SSE.Config.Foodbox = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Foodbox["Model"] = "models/reizer_props/srsp/sci_fi/crate_05/crate_05.mdl"
SSE.Config.Foodbox["HUDName"] = "Essenskiste"
SSE.Config.Foodbox["MaxFood"] = 100
SSE.Config.Foodbox["AddFood"] = 10


SSE.Config.HealCanister = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.HealCanister["Model"] = "models/reizer_props/alysseum_project/medicine_obj/med_canister_01/med_canister_01.mdl"
SSE.Config.HealCanister["HUDName"] = "Medidroide"
SSE.Config.HealCanister["AddHealth"] = 30
SSE.Config.HealCanister["DefaultHealth"] = 500
SSE.Config.HealCanister["Delay"] = 2 -- Delay in seconds
SSE.Config.HealCanister["Sound"] = "items/medshot4.wav"



SSE.Config.ArmorCanister = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.ArmorCanister["Model"] = "models/reizer_props/srsp/sci_fi/barrel_03/barrel_03.mdl"
SSE.Config.ArmorCanister["HUDName"] = "Plastoiddroide"
SSE.Config.ArmorCanister["AddHealth"] = 10
SSE.Config.ArmorCanister["DefaultHealth"] = 500
SSE.Config.ArmorCanister["Delay"] = 2 -- Delay in seconds
SSE.Config.ArmorCanister["Sound"] = "ambient/energy/spark1.wav"

SSE.Config.Lightswitch = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Lightswitch["Model"] = "models/reizer_props/alysseum_project/misc_stuff/electrical_splitter_01/electrical_splitter_01.mdl"
SSE.Config.Lightswitch["Sound"] = "buttons/lever1.wav"
SSE.Config.Lightswitch["HUDName"] = "Hauptenergieversorgung"
SSE.Config.Lightswitch["Delay"] = 120 -- In Seconds
SSE.Config.Lightswitch["EngineLightstyle"] = {"rp_venator_extensive_v1_4"} -- Add more if you have more
SSE.Config.Lightswitch["RenderModels"] = false -- Can cause lags.. i wouldnt recommend using this


SSE.Config.TrainingRoomBoard = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.TrainingRoomBoard["Model"] = "models/lt_c/holo_wall_unit.mdl"
SSE.Config.TrainingRoomBoard["BackgroundColor"] = Color(27, 27, 194, 200)

SSE.Config.TrainingRoomBoard["EditLine1"] = "Edit Line 1"
SSE.Config.TrainingRoomBoard["EditLine2"] = "Edit Line 2"
SSE.Config.TrainingRoomBoard["EditLine3"] = "Edit Line 3"
SSE.Config.TrainingRoomBoard["Save"] = "Speichern"
SSE.Config.TrainingRoomBoard["GiveUp"] = "Raum abmelden"
SSE.Config.TrainingRoomBoard["RoomOccupied"] = "Raum belegt durch:"
SSE.Config.TrainingRoomBoard["RoomAvailable"] = "Raum verfügbar!"
SSE.Config.TrainingRoomBoard["Contact"] = "Kontaktiere die Republic Navy um diesen Raum anzufragen!"


SSE.Config.TrainingRoomControlPanel = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.TrainingRoomControlPanel["Model"] = "models/reizer_props/srsp/sci_fi/console_02_1/console_02_1.mdl"
SSE.Config.TrainingRoomControlPanel["HUDName"] = "Trainingsraumverwaltung"
SSE.Config.TrainingRoomControlPanel["FrameTitle"] = "Trainingsraumverwaltung"
SSE.Config.TrainingRoomControlPanel["NewOwner"] = "*** Du bist nun der Rauminhaber des Raums: "
SSE.Config.TrainingRoomControlPanel["SelectOwner"] = "Inhaber auswählen - "
SSE.Config.TrainingRoomControlPanel["SetToFree"] = "Raum abmelden"
SSE.Config.TrainingRoomControlPanel["Free"] = "Frei"


SSE.Config.Sink = {} -- Dont Touch this unless you know what you're doing!
SSE.Config.Sink["Model"] = "models/lt_c/sci_fi/counter_sinks.mdl"
SSE.Config.Sink["HUDName"] = "Waschbecken"
SSE.Config.Sink["Sound"] = "ambient/water/water_spray1.wav"


-- Coming soon
SSE.Config.Teleporter = {}
SSE.Config.Teleporter["Model"] = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl"
SSE.Config.Teleporter["HUDName"] = "Taxi Terminal"
SSE.Config.Teleporter["PoorAsFuck"] = "Du hast nicht genug Geld, um diese Konsole zu benutzen!"
SSE.Config.Teleporter["Sound"] = "lvs/vehicles/laat/flyby4.wav"
SSE.Config.Teleporter["BlackscreenTime"] = 4
SSE.Config.Teleporter["FrameTitle"] = "Defektes Terminal"