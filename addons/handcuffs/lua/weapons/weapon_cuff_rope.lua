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
SWEP.Instructions = "A weak restraint."

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.AdminSpawnable = true

SWEP.Slot = 2
SWEP.PrintName = "Leine"

//
// Handcuff Vars
SWEP.CuffTime = 0.5 // Seconds to handcuff
SWEP.CuffSound = Sound( "buttons/lever7.wav" )

SWEP.CuffMaterial = "models/props_foliage/tree_deciduous_01a_trunk"
SWEP.CuffRope = "cable/rope"
SWEP.CuffStrength = 1.2
SWEP.CuffRegen = 0.8
SWEP.RopeLength = 200
SWEP.CuffReusable = true

SWEP.CuffBlindfold = false
SWEP.CuffGag = false

SWEP.CuffStrengthVariance = 0.1 // Randomise strangth
SWEP.CuffRegenVariance = 0.2 // Randomise regen
