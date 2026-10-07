ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Kleiderschrank (Rüstung)"
ENT.Author = "GRN"
ENT.Category = "GRN Store"
ENT.RenderGroup = RENDERGROUP_BOTH

local W = GRNStore and GRNStore.Config and GRNStore.Config.Armory and GRNStore.Config.Armory.Wardrobe
local cfg = W and W.Entity
ENT.Spawnable = not cfg or cfg.Spawnable ~= false
ENT.AdminOnly = not cfg or cfg.AdminOnly ~= false
