EoCSport = EoCSport or {}

--[[
Posen für die Übungen.

Körper:
  pitch  Neigung des ganzen Körpers in Grad (90 = flach auf dem Bauch,
         -90 = flach auf dem Rücken)
  pivot  Höhe des Drehpunkts über den Füßen (0 = Füße, ~38 = Hüfte)
  dz/dx  Verschiebung nach oben / vorn

aim (Arme, Beine, Wirbelsäule):
  Richtung, in die das Glied zeigen soll, als V(vorn, links, oben).
  Beispiel: V(0, 0, -1) = senkrecht nach unten, V(1, 0, 0) = nach vorn.
  Der Bone-Winkel wird im Spiel aus der echten Lage des Models berechnet,
  deshalb passen die Richtungen auf jedes ValveBiped-Model.
  frame = "world" (Standard): bezogen auf Boden und Blickrichtung
  frame = "body":  bezogen auf den geneigten Körper
  frame = "torso": bezogen auf den Oberkörper (z. B. verschränkte Arme)
  Möglich für: Spine, R_/L_UpperArm, R_/L_Forearm, R_/L_Thigh, R_/L_Calf

bones (optional): feste Zusatzwinkel für andere Bones (Kopf, Hände, Füße).

Feinjustieren im Spiel mit eoc_sport_posetool (Admins).
]]

local V = Vector

-- Rechts/links spiegeln: aus einer Richtung für den rechten Arm/das rechte
-- Bein die linke machen (links = +y).
local function Mirror(t)
    local out = {}
    for name, a in pairs(t) do
        out[name] = a
        local other
        if string.StartWith(name, "R_") then other = "L_" .. string.sub(name, 3) end
        if other and not t[other] then
            local dir = isvector(a) and a or a.dir
            local m = V(dir.x, -dir.y, dir.z)
            out[other] = isvector(a) and m or { dir = m, frame = a.frame }
        end
    end
    return out
end

EoCSport.Poses = {
    stand = {},

    -- Liegestütze: Arme senkrecht unter den Schultern
    pushup_up = {
        pitch = 66,
        aim = Mirror({
            R_UpperArm = V(0, -0.15, -1),
            R_Forearm = V(0, -0.1, -1),
        }),
    },
    -- unten: Ellbogen nach hinten-außen, Unterarme senkrecht
    pushup_down = {
        pitch = 76,
        aim = Mirror({
            R_UpperArm = V(-0.55, -0.75, -0.25),
            R_Forearm = V(0.05, -0.05, -1),
        }),
    },

    -- Sit-ups: Rückenlage, Knie angewinkelt, Arme vor der Brust verschränkt
    situp_down = {
        pitch = -90, pivot = 38, dz = -33,
        aim = Mirror({
            R_Thigh = V(0.7, -0.05, 0.7),
            R_Calf = V(0.75, 0, -0.65),
            R_UpperArm = { dir = V(0.6, 0, -0.8), frame = "torso" },
            R_Forearm = { dir = V(0.35, 1, 0.25), frame = "torso" },
        }),
    },
    situp_up = {
        pitch = -90, pivot = 38, dz = -33,
        aim = Mirror({
            Spine = V(-0.45, 0, 0.9),
            R_Thigh = V(0.7, -0.05, 0.7),
            R_Calf = V(0.75, 0, -0.65),
            R_UpperArm = { dir = V(0.6, 0, -0.8), frame = "torso" },
            R_Forearm = { dir = V(0.35, 1, 0.25), frame = "torso" },
        }),
    },

    -- Kniebeugen: Oberschenkel fast waagerecht, Arme nach vorn
    squat_down = {
        dz = -12, dx = -10,
        aim = Mirror({
            Spine = V(0.35, 0, 0.94),
            R_Thigh = V(0.9, -0.15, -0.4),
            R_Calf = V(-0.3, -0.05, -0.95),
            R_UpperArm = V(1, -0.1, 0.05),
            R_Forearm = V(1, -0.05, 0.05),
        }),
    },

    -- Hampelmann: Arme über den Kopf, Beine auseinander
    jack_open = {
        aim = Mirror({
            R_UpperArm = V(0, -0.55, 0.85),
            R_Forearm = V(0, -0.4, 0.9),
            R_Thigh = V(0, -0.3, -0.95),
            R_Calf = V(0, -0.3, -0.95),
        }),
    },

    -- Burpee-Sprung: Arme nach oben
    burpee_jump = {
        dz = 12,
        aim = Mirror({
            R_UpperArm = V(0.1, -0.2, 1),
            R_Forearm = V(0.1, -0.2, 1),
        }),
    },

    -- Klimmzüge (Position kommt vom Server)
    pullup_hang = {
        aim = Mirror({
            R_UpperArm = V(0.1, -0.2, 1),
            R_Forearm = V(0.1, -0.2, 1),
            R_Calf = V(-0.2, 0, -1),
        }),
    },
    pullup_top = {
        dz = 22,
        aim = Mirror({
            R_UpperArm = V(0.1, -0.85, -0.45),
            R_Forearm = V(0, 0.4, 0.92),
            R_Calf = V(-0.35, 0, -0.95),
        }),
    },

    -- Planke: Oberarme senkrecht, Unterarme flach nach vorn
    plank = {
        pitch = 78,
        aim = Mirror({
            R_UpperArm = V(0, -0.1, -1),
            R_Forearm = V(1, 0.15, -0.05),
        }),
    },

    -- Laufen auf der Stelle
    run_mid = {
        dz = 1,
        aim = Mirror({
            R_UpperArm = V(0, -0.1, -1),
            R_Forearm = V(0.85, 0.1, 0.5),
        }),
    },
    run_a = {
        aim = {
            R_Thigh = V(0.9, 0, -0.35),
            R_Calf = V(0.05, 0, -1),
            L_UpperArm = V(0.45, 0.05, -0.9),
            L_Forearm = V(0.8, -0.1, 0.6),
            R_UpperArm = V(-0.45, -0.05, -0.9),
            R_Forearm = V(0.6, 0.1, 0.5),
        },
    },
    run_b = {
        aim = {
            L_Thigh = V(0.9, 0, -0.35),
            L_Calf = V(0.05, 0, -1),
            R_UpperArm = V(0.45, -0.05, -0.9),
            R_Forearm = V(0.8, 0.1, 0.6),
            L_UpperArm = V(-0.45, 0.05, -0.9),
            L_Forearm = V(0.6, -0.1, 0.5),
        },
    },
}

-- Bei Lua-Refresh dieser Datei die Posen neu aufbereiten.
if EoCSport.PreparePoses then EoCSport.PreparePoses() end
