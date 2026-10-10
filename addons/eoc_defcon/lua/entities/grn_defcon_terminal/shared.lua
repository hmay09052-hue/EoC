ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "DEFCON Terminal"
ENT.Author = "GRN"
ENT.Category = "GRN - DEFCON"
local terminalConfig = (GRN_DEFCON and GRN_DEFCON.Config and GRN_DEFCON.Config.Terminal) or {}
ENT.Spawnable = terminalConfig.Spawnable ~= false
ENT.AdminOnly = terminalConfig.AdminOnly ~= false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
end
