/*
╔╗──╔═══╦═══╦╗╔═╦═══╦═══╗  ╔══╦╗──╔╗  ╔═══╦═══╦═══╦════╗╔╗─╔╦═══╦═══╗
║║──║╔══╣╔═╗║║║╔╣╔══╩╗╔╗║  ║╔╗║╚╗╔╝║  ║╔═╗║╔═╗║╔═╗╠══╗═╠╝║╔╝║╔═╗║╔══╝
║║──║╚══╣║─║║╚╝╝║╚══╗║║║║  ║╚╝╚╗╚╝╔╝  ║║─╚╣║─║║╚═╝║─╔╝╔╩╗║╚╗╠╝╔╝║╚══╗
║║─╔╣╔══╣╚═╝║╔╗║║╔══╝║║║║  ║╔═╗╠╗╔╝─  ║║─╔╣╚═╝║╔╗╔╝╔╝╔╝─║║─║║─║╔╩══╗║
║╚═╝║╚══╣╔═╗║║║╚╣╚══╦╝╚╝║  ║╚═╝║║║──  ║╚═╝║╔═╗║║║╚╦╝═╚═╦╝╚╦╝╚╗║║╔══╝║
╚═══╩═══╩╝─╚╩╝╚═╩═══╩═══╝  ╚═══╝╚╝──  ╚═══╩╝─╚╩╝╚═╩════╩══╩══╝╚╝╚═══╝
*/

AddCSLuaFile()

SWEP.Base = "weapon_cuff_base"

SWEP.Category = "Handcuffs"
SWEP.Author = "my_hat_stinks"
SWEP.Instructions = "Stretchable restraint."

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.AdminSpawnable = true

SWEP.Slot = 2
SWEP.PrintName = "ARC Handschellen"

//
// Handcuff Vars
SWEP.CuffTime = 0.2 // Seconds to handcuff
SWEP.CuffSound = Sound( "buttons/lever7.wav" )

SWEP.CuffMaterial = "models/props_pipes/GutterMetal01a"
SWEP.CuffRope = "cable/red"
SWEP.CuffStrength = 9.1
SWEP.CuffRegen = 9.6
SWEP.RopeLength = 10
SWEP.CuffReusable = true

SWEP.CuffBlindfold = true
SWEP.CuffGag = true

SWEP.CuffStrengthVariance = 0.1 // Randomise strangth
SWEP.CuffRegenVariance = 0.3 // Randomise regen
