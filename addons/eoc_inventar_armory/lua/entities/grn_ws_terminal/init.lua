AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    GRNSerials.InitStation(self)
end

function ENT:Use(activator)
    GRNSerials.UseStation(self, activator)
end

function ENT:OnTakeDamage()
    return 0
end
