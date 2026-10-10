att.PrintName = "E-11 Flashlight (WIP)"
att.Icon = Material("entities/kraken/empire-v2/attachments/zoom.png", "mips smooth")
att.Description = "Mountable flashlight. Illuminates targets for the user, but may give away their position."
att.Desc_Pros = {}
att.Desc_Cons = {}

att.AutoStats = true

att.Slot = "e11_flashlight_disabled"
att.ActivateElements = {"e11_flashlight"}

att.Flashlight = true
att.FlashlightFOV = 50
att.FlashlightFarZ = 512 -- how far it goes
att.FlashlightNearZ = 1 -- how far away it starts
att.FlashlightAttenuationType = ArcCW.FLASH_ATT_LINEAR -- LINEAR, CONSTANT, QUADRATIC are available
att.FlashlightColor = Color(255, 255, 255)
att.FlashlightTexture = "effects/flashlight001"
att.FlashlightBrightness = 4

att.ToggleStats = {
    {
        PrintName = "High",
        Flashlight = true
    },
    {
        PrintName = "Eco",
        Flashlight = true,
        FlashlightFOV = 50,
        FlashlightFarZ = 365,
        FlashlightBrightness = 1
    },
    {
        PrintName = "Off",
        Flashlight = false,
    }
}