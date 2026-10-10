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
SWEP.PrintName = "Handschellen"

//
// Handcuff Vars
SWEP.CuffTime = 0.9 // Seconds to handcuff
SWEP.CuffSound = Sound( "buttons/lever7.wav" )

SWEP.CuffMaterial = "models/props_pipes/GutterMetal01a"
SWEP.CuffRope = "cable/red"
SWEP.CuffStrength = 1.0
SWEP.CuffRegen = 1.6
SWEP.RopeLength = 100
SWEP.CuffReusable = true

SWEP.CuffBlindfold = false
SWEP.CuffGag = false

SWEP.CuffStrengthVariance = 0.1 // Randomise strangth
SWEP.CuffRegenVariance = 0.3 // Randomise regen
