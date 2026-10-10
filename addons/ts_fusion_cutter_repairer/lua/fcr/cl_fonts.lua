FCR = FCR or {}
FCR.Fonts = FCR.Fonts or {}

-- Schriften passend zum Echoes of Clones HUD (grn_hud_v1)
local title = SYMUI and SYMUI.FontFace("head") or "Bebas Neue"
local main = SYMUI and SYMUI.FontFace("body") or "Montserrat"

surface.CreateFont("FCR.Title", {
    font = title,
    size = 34,
    weight = 400,
    extended = true,
    antialias = true
})

surface.CreateFont("FCR.Subtitle", {
    font = title,
    size = 22,
    weight = 400,
    extended = true,
    antialias = true
})

surface.CreateFont("FCR.HUDTitle", {
    font = title,
    size = 24,
    weight = 400,
    extended = true,
    antialias = true
})

surface.CreateFont("FCR.HUDValue", {
    font = title,
    size = 22,
    weight = 400,
    extended = true,
    antialias = true
})

surface.CreateFont("FCR.HUDTiny", {
    font = main,
    size = 11,
    weight = 700,
    extended = true,
    antialias = true
})

surface.CreateFont("FCR.HUDBody", {
    font = main,
    size = 13,
    weight = 600,
    extended = true,
    antialias = true
})
