--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Aurebesh ohne Schriftart
    Die Zeichen liegen als Bild (Atlas) in dieser Datei. So erscheint Aurebesh sofort beim ersten Beitritt,
    auch wenn die Schriftart beim Spieler nicht installiert ist (Schriften lädt GMod erst nach einem Neustart).
    Erzeugt aus resource/fonts/symchars_aurebesh.ttf.
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui

local ATLAS_W, ATLAS_H = 1024, 256
local PX = 64                      -- Schriftgröße beim Erzeugen
local PADX = 4
local BAND_H = 50               -- Höhe eines Zeichens im Atlas
local BAND_TOP = 0.063      -- Abstand Zeilenoberkante -> Zeichen (relativ zur Größe)
local LINE_H = 1.126       -- Zeilenhöhe (relativ zur Größe)
local SPACE = 0.58        -- Leerzeichenbreite (relativ zur Größe)

-- Zeichen = { x, y, Zellbreite, Vorschub }
local GLYPHS = {
    ["A"] = { 0, 0, 68, 59.375 },
    ["B"] = { 70, 0, 69, 60.938 },
    ["C"] = { 141, 0, 44, 35.938 },
    ["D"] = { 187, 0, 57, 48.438 },
    ["E"] = { 246, 0, 63, 54.688 },
    ["F"] = { 311, 0, 63, 54.688 },
    ["G"] = { 376, 0, 71, 62.5 },
    ["H"] = { 449, 0, 57, 48.438 },
    ["I"] = { 508, 0, 30, 21.875 },
    ["J"] = { 540, 0, 63, 54.688 },
    ["K"] = { 605, 0, 69, 60.938 },
    ["L"] = { 676, 0, 57, 48.438 },
    ["M"] = { 735, 0, 55, 46.875 },
    ["N"] = { 792, 0, 63, 54.688 },
    ["O"] = { 857, 0, 74, 65.625 },
    ["P"] = { 933, 0, 57, 48.438 },
    ["Q"] = { 0, 52, 63, 54.688 },
    ["R"] = { 65, 52, 57, 48.438 },
    ["S"] = { 124, 52, 63, 54.688 },
    ["T"] = { 189, 52, 63, 54.688 },
    ["U"] = { 254, 52, 65, 56.25 },
    ["V"] = { 321, 52, 63, 54.688 },
    ["W"] = { 386, 52, 71, 62.5 },
    ["X"] = { 459, 52, 60, 51.563 },
    ["Y"] = { 521, 52, 63, 54.688 },
    ["Z"] = { 586, 52, 69, 60.938 },
    ["0"] = { 657, 52, 60, 51.563 },
    ["1"] = { 719, 52, 57, 48.438 },
    ["2"] = { 778, 52, 57, 48.438 },
    ["3"] = { 837, 52, 57, 48.438 },
    ["4"] = { 896, 52, 57, 48.438 },
    ["5"] = { 955, 52, 57, 48.438 },
    ["6"] = { 0, 104, 57, 48.438 },
    ["7"] = { 59, 104, 57, 48.438 },
    ["8"] = { 118, 104, 60, 51.563 },
    ["9"] = { 180, 104, 57, 48.438 },
    ["-"] = { 239, 104, 48, 39.063 },
    ["."] = { 289, 104, 32, 23.438 },
    [","] = { 323, 104, 19, 10.938 },
    [":"] = { 344, 104, 35, 26.563 },
    ["!"] = { 381, 104, 30, 21.875 },
    ["?"] = { 413, 104, 30, 21.875 },
}

local PNG = "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"

local FILE = "symchars/aurebesh_f1bfdc2d.png"
local mat

local function Load()
    if mat ~= nil then return mat end
    mat = false
    if not util.Base64Decode or not file or not file.Write then return mat end
    if not file.Exists(FILE, "DATA") then
        local raw = util.Base64Decode(PNG)
        if not raw or raw == "" then return mat end
        file.CreateDir("symchars")
        file.Write(FILE, raw)
    end
    local m = Material("data/" .. FILE, "smooth mips")
    if m and not m:IsError() then mat = m end
    return mat
end

-- Schriftgrößen der bisherigen Aurebesh-Fonts
local SIZES = { ["symchars.aure.small"] = 11, ["symchars.aure"] = 15, ["symchars.aure.big"] = 22 }
local FIXED = { ["symchars.world.aure"] = 22 }

local function SizeOf(font)
    font = font or "symchars.aure"
    if FIXED[font] then return FIXED[font] end
    return UI.S(SIZES[font] or 15)
end

-- Breite in Pixeln (für Ausrichtung und Kürzen)
local function Width(text, size)
    local scale = size / PX
    local w = 0
    for i = 1, #text do
        local c = string.sub(text, i, i)
        local g = GLYPHS[c]
        if g then w = w + g[4] * scale elseif c == " " then w = w + SPACE * size end
    end
    return w
end

function UI.AurebeshSize(text, font)
    local size = SizeOf(font)
    return Width(UI.ToAurebesh(text), size), LINE_H * size
end

function UI.AurebeshHeight(font)
    return LINE_H * SizeOf(font)
end

local fontVersion = UI.Aurebesh
UI.AurebeshFont = fontVersion

function UI.Aurebesh(text, font, x, y, col, ax, ay, maxW)
    local m = Load()
    if not m then return fontVersion(text, font, x, y, col, ax, ay, maxW) end
    text = UI.ToAurebesh(text)
    if text == "" then return end
    local size = SizeOf(font)
    local scale = size / PX
    local w = Width(text, size)
    if maxW and w > maxW then
        while #text > 0 and w > maxW do
            text = string.sub(text, 1, -2)
            w = Width(text, size)
        end
    end

    local left = x
    if ax == TEXT_ALIGN_CENTER then left = x - w / 2 elseif ax == TEXT_ALIGN_RIGHT then left = x - w end
    local lineTop = y
    if ay == TEXT_ALIGN_CENTER then lineTop = y - LINE_H * size / 2 elseif ay == TEXT_ALIGN_BOTTOM then lineTop = y - LINE_H * size end
    local top = lineTop + BAND_TOP * size

    col = col or UI.Alpha(UI.col.dim, 170)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    surface.SetMaterial(m)
    local cx = left
    local cellH = BAND_H * scale
    for i = 1, #text do
        local c = string.sub(text, i, i)
        local g = GLYPHS[c]
        if g then
            surface.DrawTexturedRectUV(cx - PADX * scale, top, g[3] * scale, cellH,
                g[1] / ATLAS_W, g[2] / ATLAS_H, (g[1] + g[3]) / ATLAS_W, (g[2] + BAND_H) / ATLAS_H)
            cx = cx + g[4] * scale
        elseif c == " " then
            cx = cx + SPACE * size
        end
    end
end