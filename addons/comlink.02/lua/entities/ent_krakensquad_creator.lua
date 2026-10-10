AddCSLuaFile()
ENT.Type     = "anim"
ENT.PrintName = "Squad Creator"
ENT.Category = "Kraken's Squads"
ENT.Spawnable  = true
ENT.AdminOnly  = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

KrakenSquad.SetupNPCEntity(ENT, {
    netMessage      = "KS.NPCCreator",
    fallbackLangKey = "npc_create_squad",
    modelKey        = "creator",
    titleKey        = "creatorTitle",
    titleFallback   = "create_squad",
    animKey         = "creator",
})
