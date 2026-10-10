ENT.Base = "lvs_base_starfighter"

ENT.PrintName = "Republic Escape Pod"
ENT.Author = "Luna, Ace, and Tic"
ENT.Information = "Galactic Republic Escape pod"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable			= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/ace/sw/rh/escapepod.mdl"

ENT.AITEAM = 2

ENT.MaxVelocity = 1750
ENT.MaxThrust = 23400

ENT.ThrustVtol = 55
ENT.ThrustRateVtol = 3

ENT.TurnRatePitch = 1
ENT.TurnRateYaw = 1
ENT.TurnRateRoll = 1.25

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.MaxHealth = 1200

ENT.LAATC_PICKUPABLE = true
ENT.LAATC_PICKUP_POS = Vector(-225,0,0)
ENT.LAATC_PICKUP_Angle = Angle(0,0,0)
ENT.LAATC_DROP_DISTANCE = 100000

ENT.FlyByAdvance = 0.35
ENT.FlyBySound = "lvs/vehicles/arc170/flyby.wav" 
ENT.DeathSound = "lvs/vehicles/generic_starfighter/crash.wav"

ENT.EngineSounds = {
	{
		sound = "lvs/vehicles/arc170/loop.wav",
		Pitch = 80,
		PitchMin = 0,
		PitchMax = 255,
		PitchMul = 40,
		FadeIn = 0,
		FadeOut = 1,
		FadeSpeed = 1.5,
		UseDoppler = true,
		SoundLevel = 80,
	},
}

hook.Add("LoadFlareConfiguration", "EscapePod", function ()
    UF:RegisterFlareVehicleConfiguration("lvs_cgi_escapepod",
            {
                {
                    pos = Vector(-110,50,7.42), -- Position where to eject flares.
                    dir = UF.CONST.LEFT, -- In which direction to eject flares, defaults available: UF.CONST.BACKWARDS, UF.CONST.RIGHT, UF.CONST.LEFT.
                    dirMulti = 1000, -- Optional velocity multiplier for ejecting flares.
                },
		{
                    pos = Vector(-110,-50,7.42), -- Position where to eject flares.
                    dir = UF.CONST.RIGHT, -- In which direction to eject flares, defaults available: UF.CONST.BACKWARDS, UF.CONST.RIGHT, UF.CONST.LEFT.
                    dirMulti = 1000, -- Optional velocity multiplier for ejecting flares.
                },
		{
                    pos = Vector(-110,0,57), -- Position where to eject flares.
                    dir = UF.CONST.BACKWARDS, -- In which direction to eject flares, defaults available: UF.CONST.BACKWARDS, UF.CONST.RIGHT, UF.CONST.LEFT.
                    dirMulti = 1000, -- Optional velocity multiplier for ejecting flares.
                },
		{
                    pos = Vector(-110,0,-45), -- Position where to eject flares.
                    dir = UF.CONST.BACKWARDS, -- In which direction to eject flares, defaults available: UF.CONST.BACKWARDS, UF.CONST.RIGHT, UF.CONST.LEFT.
                    dirMulti = 1000, -- Optional velocity multiplier for ejecting flares.
                },
            },
            1, -- Which seat should control the flares. Default 0.
            56, -- The total times the flares can be used. Default 16.
            5 -- The amount of individual flares that should be deployed per burst. Default 5.
    )
end)