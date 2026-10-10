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
SWEP.PrintName = "Team Handschellen"

//
// Handcuff Vars
SWEP.CuffTime = 0.1 // Seconds to handcuff
SWEP.CuffSound = Sound( "buttons/lever7.wav" )

SWEP.CuffMaterial = "phoenix_storms/cube"
SWEP.CuffRope = "cable/cable2"
SWEP.CuffStrength = 2.0
SWEP.CuffRegen = 1.6
SWEP.RopeLength = 100
SWEP.CuffReusable = true

SWEP.CuffBlindfold = false
SWEP.CuffGag = true

SWEP.CuffStrengthVariance = 0.1 // Randomise strangth
SWEP.CuffRegenVariance = 0.3 // Randomise regen
