hradio.debug = false

local developer = GetConVar("developer")
if developer and developer:GetInt() > 0 then
    hradio.debug = true
end

local lply = LocalPlayer()

hradio = hradio or {}

if IsValid(lply) then
    lply.hradio = lply.hradio or {}
    lply.hradio.MutedChannels = lply.hradio.MutedChannels or {}
    lply.hradio.LastStartTime = lply.hradio.LastStartTime or SysTime()
    lply.hradio.LastStopTime = lply.hradio.LastStopTime or SysTime()
    lply.hradio.ImguiRadioMenuOpen = false
    lply.hradio.ImguiRadioMenuPending = false
    lply.hradio.IsTalking = false
    lply.hradio.RadioTalkStarted = false
end

local scale = math.Clamp(ScrH() / 1080, 0.75, 1.15)

surface.CreateFont("hRadio_Title", {
    font = SYMUI and SYMUI.FontFace("body") or "Open Sans Semibold",
    size = math.floor(21 * scale),
    weight = 700,
    antialias = true
})

surface.CreateFont("hRadio_Main", {
    font = SYMUI and SYMUI.FontFace("body") or "Open Sans Semibold",
    size = math.floor(18 * scale),
    weight = 700,
    antialias = true
})

surface.CreateFont("hRadio_Small", {
    font = SYMUI and SYMUI.FontFace("body") or "Open Sans Semibold",
    size = math.floor(13 * scale),
    weight = 650,
    antialias = true
})

surface.CreateFont("hRadio_Tiny", {
    font = SYMUI and SYMUI.FontFace("body") or "Open Sans Semibold",
    size = math.floor(10 * scale),
    weight = 650,
    antialias = true
})

surface.CreateFont("hRadio_Micro", {
    font = SYMUI and SYMUI.FontFace("body") or "Open Sans Semibold",
    size = math.floor(8 * scale),
    weight = 600,
    antialias = true
})
