--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Datenbank (NUR SERVER, wird nie an Spieler gesendet)

    mysql = false  -> SQLite (garrysmod/sv.db), keine weitere Einrichtung noetig
    mysql = true   -> MySQL ueber MySQLOO (gmsv_mysqloo_win64.dll / linux im lua/bin Ordner des Servers)

    Bestehende Daten des alten symchars (Tabelle sy_characters, data/symchars/...) werden automatisch
    uebernommen. Wenn der alte symchars mit MySQL lief, hier DIESELBEN Zugangsdaten eintragen.
-------------------------------------------------------------------------------------------------------------]]

symchars.dbconfig = {
    mysql = false,
    host = "127.0.0.1",
    port = 3306,
    user = "root",
    password = "",
    database = "gmod",
}
