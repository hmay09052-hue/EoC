AddCSLuaFile()
ENT.Type      = "anim"
ENT.PrintName = "Squad List"
ENT.Category  = "Kraken's Squads"
ENT.Spawnable  = true
ENT.AdminOnly  = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

KrakenSquad.SetupNPCEntity(ENT, {
    netMessage      = "KS.NPCList",
    fallbackLangKey = "npc_view_squads",
    modelKey        = "publicList",
    titleKey        = "listTitle",
    titleFallback   = "public_squads",
    animKey         = "publicList",
})
