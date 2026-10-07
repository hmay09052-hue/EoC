ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = (GRNStore and GRNStore.Config and GRNStore.Config.Armory and GRNStore.Config.Armory.Name) or "Personal Armory"
ENT.Author = "GRN"
ENT.Category = "GRN Store"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local cfg = GRNStore and GRNStore.Config and GRNStore.Config.Armory and GRNStore.Config.Armory.Entity
ENT.Spawnable = not cfg or cfg.Spawnable ~= false
ENT.AdminOnly = not cfg or cfg.AdminOnly ~= false
