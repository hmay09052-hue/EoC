--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Bilder aus dem Internet (Imgur-Logos, Banner, Dokumentbilder)
    Bilder werden in data/symchars/img/ zwischengespeichert.
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local U = symchars.util

local DIR = "symchars/img"
local cache = {}     -- url -> { mat = IMaterial | false, w, h, state = "loading" | "ok" | "error" }

file.CreateDir("symchars")
file.CreateDir(DIR)

local function FileFor(url, ext)
    return DIR .. "/" .. util.CRC(url) .. "." .. ext
end

local function LoadMaterial(path)
    local mat = Material("data/" .. path, "smooth mips")
    if not mat or mat:IsError() then return nil end
    return mat
end

local function Store(entry, mat)
    entry.mat = mat
    entry.state = "ok"
    local tex = mat:GetTexture("$basetexture")
    entry.w = tex and tex:Width() or mat:Width()
    entry.h = tex and tex:Height() or mat:Height()
end

-- Gibt Material oder nil zurück (lädt im Hintergrund)
function UI.Image(rawUrl)
    local url = U.ImageURL(rawUrl)
    if url == "" then
        -- alter Materialpfad (z.B. "icon16/user.png" oder "symchars/logo.png")
        local path = U.Trim(rawUrl)
        if path == "" then return nil end
        local entry = cache[path]
        if not entry then
            local mat = Material(path, "smooth mips")
            entry = { state = "error" }
            if mat and not mat:IsError() then Store(entry, mat) end
            cache[path] = entry
        end
        return entry.mat, entry
    end

    local entry = cache[url]
    if entry then return entry.mat, entry end

    entry = { state = "loading" }
    cache[url] = entry

    for _, ext in ipairs({ "png", "jpg" }) do
        local path = FileFor(url, ext)
        if file.Exists(path, "DATA") then
            local mat = LoadMaterial(path)
            if mat then Store(entry, mat) return entry.mat, entry end
        end
    end

    http.Fetch(url, function(body, size, headers, code)
        if code ~= 200 or not body or #body < 16 then entry.state = "error" return end
        local ext
        if string.sub(body, 1, 8) == "\137PNG\r\n\26\n" then
            ext = "png"
        elseif string.sub(body, 1, 3) == "\255\216\255" then
            ext = "jpg"
        else
            entry.state = "error"
            return
        end
        local path = FileFor(url, ext)
        file.Write(path, body)
        local mat = LoadMaterial(path)
        if mat then Store(entry, mat) else entry.state = "error" end
    end, function()
        entry.state = "error"
    end)

    return nil, entry
end

function UI.ImageState(rawUrl)
    local _, entry = UI.Image(rawUrl)
    return entry and entry.state or "error"
end

-- fit: "cover" (füllt, schneidet zu) | "contain" (ganz sichtbar) | "stretch"
function UI.DrawImage(rawUrl, x, y, w, h, col, fit)
    local mat, entry = UI.Image(rawUrl)
    if not mat then
        if entry and entry.state == "loading" then
            local t = (RealTime() * 2) % 1
            surface.SetDrawColor(255, 255, 255, 12 + 18 * math.sin(t * math.pi))
            surface.DrawRect(x, y, w, h)
        end
        return false
    end

    surface.SetMaterial(mat)
    surface.SetDrawColor(col or color_white)
    local iw, ih = entry.w or 1, entry.h or 1
    fit = fit or "cover"

    if fit == "stretch" or iw <= 0 or ih <= 0 then
        surface.DrawTexturedRect(x, y, w, h)
    elseif fit == "contain" then
        local scale = math.min(w / iw, h / ih)
        local dw, dh = iw * scale, ih * scale
        surface.DrawTexturedRect(x + (w - dw) / 2, y + (h - dh) / 2, dw, dh)
    else
        local scale = math.max(w / iw, h / ih)
        local uw, vh = (w / scale) / iw, (h / scale) / ih
        local u0, v0 = (1 - uw) / 2, (1 - vh) / 2
        surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u0 + uw, v0 + vh)
    end
    return true
end

-- Logo einer Einheit, sonst Kürzel in einer Raute
function UI.DrawUnitLogo(faction, x, y, size, alpha)
    faction = symchars.factions.Get(faction)
    if not faction then return end
    local logo = faction.logo ~= "" and faction.logo or faction.icon
    if logo and logo ~= "" and UI.DrawImage(logo, x, y, size, size, Color(255, 255, 255, alpha or 255), "contain") then return end
    local col = faction:GetColor()
    local cx, cy, r = x + size / 2, y + size / 2, size * 0.46
    draw.NoTexture()
    surface.SetDrawColor(col.r, col.g, col.b, (alpha or 255) * 0.25)
    surface.DrawPoly({ { x = cx, y = cy - r }, { x = cx + r, y = cy }, { x = cx, y = cy + r }, { x = cx - r, y = cy } })
    local text = faction.short ~= "" and faction.short or string.sub(faction.name, 1, 2)
    local font = size > UI.S(70) and "symchars.h2" or "symchars.h4"
    UI.Text(string.upper(text), font, cx, cy, Color(col.r, col.g, col.b, alpha or 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
