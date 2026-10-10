--[[
    EoC Range – Startzone (Parcours). Die Zeit läuft, sobald der Schütze sie verlässt.
    Die Bahn-Nr. ist gleichzeitig die Parcours-Nr.
]]
AddCSLuaFile()

ENT.Base        = "range_zone"
ENT.PrintName   = "Startzone (Parcours)"
ENT.Category    = "EoC Range"
ENT.Spawnable   = true
ENT.AdminOnly   = true
ENT.RangeKind   = "start"
ENT.ZoneColor   = Color(74, 203, 130)
ENT.DefaultSize = Vector(96, 96, 110)
