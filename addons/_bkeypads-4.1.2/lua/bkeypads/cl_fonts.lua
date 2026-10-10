local FONT_CIRCULAR = "Circular Std Medium"
local FONT_RUBIK = "Rubik"
local FONT_ROBOTO = "Roboto"

local FONT_16 = 16

-- Battlefront Theme (Schriften aus dem Serverpaket)
local FONT_SYM = "Roboto Condensed"
local FONT_SYM_BOLD = "BigNoodleTitling"

local dyslexia = bKeypads.Settings:Get("dyslexia")
local dyslexia_weight
if dyslexia then
	FONT_CIRCULAR = "Comic Sans MS"
	FONT_RUBIK = "Comic Sans MS"
	FONT_ROBOTO = "Comic Sans MS"
	FONT_SYM = "Comic Sans MS"
	FONT_SYM_BOLD = "Comic Sans MS"

	FONT_16 = 19

	dyslexia_weight = 700
end

surface.CreateFont("bKeypads.DermaDefaultDyslexia", {
	font = "Comic Sans MS",
	size = 19,
	weight = 700
})

surface.CreateFont("bKeypads.Tutorial.Caption", {
	font = FONT_CIRCULAR,
	size = 32,
	weight = dyslexia_weight,
	shadow = true
})

surface.CreateFont("bKeypads.Keycards.3D2D.Level", {
	font = FONT_SYM_BOLD,
	weight = 900,
	extended = true,
	size = 46
})

surface.CreateFont("bKeypads.Keycards.3D2D.Team", {
	font = FONT_SYM,
	weight = 700,
	extended = true,
	size = 26
})

local levelBoxSize = 43
local levelBoxFontSize1 = levelBoxSize * (38 / 45)
local levelBoxFontSize2 = levelBoxFontSize1 * (28 / 38)
surface.CreateFont("bKeypads.Keycards.3D2D.Levels.1", {
	font = FONT_SYM_BOLD,
	weight = 900,
	size = levelBoxFontSize1 * 0.8
})
surface.CreateFont("bKeypads.Keycards.3D2D.Levels.2", {
	font = FONT_SYM_BOLD,
	weight = 900,
	size = levelBoxFontSize2 * 0.8
})

surface.CreateFont("bKeypads.ToolScreenNoPermission", {
	font = "Verdana",
	shadow = true,
	size = 24
})

surface.CreateFont("bKeypads.PicURLFont", {
	font = "Roboto Mono",
	size = 14
})

surface.CreateFont("bKeypads.LevelSelect.Shadow", {
	font = "Roboto Mono",
	size = 14,
	weight = 700,
	shadow = true
})

surface.CreateFont("bKeypads.LevelSelect", {
	font = "Roboto Mono",
	size = 14,
	weight = 700
})

surface.CreateFont("bKeypads.PINBtn", {
	size = 46,
	font = FONT_SYM_BOLD,
	weight = 900
})

surface.CreateFont("bKeypads.PINAsterisk", {
	size = 26,
	font = FONT_SYM_BOLD,
	weight = 900
})

surface.CreateFont("bKeypads.PaymentFont", {
	size = 44,
	font = FONT_SYM_BOLD,
	weight = dyslexia_weight or 900,
})

surface.CreateFont("bKeypads.SlideTextFont", {
	size = 255,
	font = "Uni Sans Heavy CAPS"
})

surface.CreateFont("bKeypads.OwnedByFont.1", {
	font = FONT_RUBIK,
	weight = 700,
	shadow = true,
	size = FONT_16
})

surface.CreateFont("bKeypads.OwnedByFont.2", {
	font = FONT_RUBIK,
	weight = 700,
	shadow = true,
	size = FONT_16
})

surface.CreateFont("bKeypads.KeypadLabelFont", {
	font = FONT_SYM_BOLD,
	size = 42,
	weight = dyslexia_weight or 900,
	extended = true
})

surface.CreateFont("bKeypads.TutorialFont", {
	font = FONT_CIRCULAR,
	size = FONT_16,
	weight = dyslexia_weight
})

if bKeypads.CreateTooltipFont then
	bKeypads:CreateTooltipFont()
end
