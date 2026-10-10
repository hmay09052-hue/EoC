AddCSLuaFile()
ENT.Type      = "anim"
ENT.PrintName = "Orders Terminal"
ENT.Category  = "Kraken's Squads"
ENT.Spawnable  = true
ENT.AdminOnly  = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

KrakenSquad.SetupNPCEntity(ENT, {
    netMessage      = "KS.NPCTerminal",
    fallbackLangKey = "npc_orders_terminal",
    terminal        = true,
    titleFallback   = "orders_terminal",
})
