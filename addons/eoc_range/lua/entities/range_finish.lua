--[[
    EoC Range – Zielzone (Parcours). Die Zeit stoppt, sobald der Schütze sie betritt.
    Die Bahn-Nr. ist gleichzeitig die Parcours-Nr.
]]
AddCSLuaFile()

ENT.Base        = "range_zone"
ENT.PrintName   = "Zielzone (Parcours)"
ENT.Category    = "EoC Range"
ENT.Spawnable   = true
ENT.AdminOnly   = true
ENT.RangeKind   = "finish"
ENT.ZoneColor   = Color(225, 88, 88)
ENT.DefaultSize = Vector(96, 96, 110)
