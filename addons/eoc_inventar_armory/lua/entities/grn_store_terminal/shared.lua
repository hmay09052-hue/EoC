ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = (GRNStore and GRNStore.Config and GRNStore.Config.StoreName) or "Echoes of Clones Store"
ENT.Author = "GRN"
ENT.Category = "GRN Store"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.AutomaticFrameAdvance = true

local cfg = GRNStore and GRNStore.Config and GRNStore.Config.Entity
ENT.Spawnable = not cfg or cfg.Spawnable ~= false
ENT.AdminOnly = not cfg or cfg.AdminOnly ~= false
