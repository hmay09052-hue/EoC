EoCSport = EoCSport or {}

--[[
Bone-Posen für die Übungen (Weg B/C aus dem Konzept).

Jede Pose besteht aus
  pitch  Neigung des ganzen Körpers in Grad (90 = flach auf dem Bauch,
         -90 = flach auf dem Rücken)
  pivot  Höhe des Drehpunkts über den Füßen (0 = Füße, ~38 = Hüfte)
  dz/dx  Verschiebung nach oben / vorn
  bones  Bone-Winkel (ManipulateBoneAngles) relativ zur Stand-Animation.
         Kurznamen ohne "ValveBiped.Bip01_" sind erlaubt.

Die Werte sind Startwerte für ValveBiped-Models (Klon-Models). Feinjustieren
geht im Spiel mit eoc_sport_posetool (Admins): Werte live ändern, mit
"Als Lua kopieren" in die Zwischenablage holen und hier einfügen.
]]

local A = Angle

local CROSSED_ARMS = {
    R_UpperArm = A(20, -57, -6),
    R_Forearm = A(-44, -107, 16),
    R_Hand = A(14, -33, -7),
    L_UpperArm = A(-29, -59, 1),
    L_Forearm = A(51, -120, -19),
    L_Hand = A(26, 32, -15),
}

local function merge(...)
    local out = {}
    for _, t in ipairs({ ... }) do
        for k, v in pairs(t) do out[k] = v end
    end
    return out
end

EoCSport.Poses = {
    stand = {},

    -- Liegestütze
    pushup_up = {
        pitch = 66, pivot = 0, dz = 0, dx = 0,
        bones = {
            R_UpperArm = A(0, -68, 0), L_UpperArm = A(0, -68, 0),
            R_Hand = A(0, 0, 70), L_Hand = A(0, 0, -70),
            Head1 = A(0, -25, 0),
            R_Foot = A(0, 40, 0), L_Foot = A(0, 40, 0),
        },
    },
    pushup_down = {
        pitch = 80, pivot = 0, dz = 0, dx = 0,
        bones = {
            R_UpperArm = A(0, -25, 0), L_UpperArm = A(0, -25, 0),
            R_Forearm = A(0, -75, 0), L_Forearm = A(0, -75, 0),
            R_Hand = A(0, 0, 70), L_Hand = A(0, 0, -70),
            Head1 = A(0, -35, 0),
            R_Foot = A(0, 50, 0), L_Foot = A(0, 50, 0),
        },
    },

    -- Sit-ups (Rückenlage, Knie angewinkelt, Arme verschränkt)
    situp_down = {
        pitch = -90, pivot = 38, dz = -33, dx = 0,
        bones = merge(CROSSED_ARMS, {
            R_Thigh = A(0, -50, 0), L_Thigh = A(0, -50, 0),
            R_Calf = A(0, 100, 0), L_Calf = A(0, 100, 0),
        }),
    },
    situp_up = {
        pitch = -90, pivot = 38, dz = -33, dx = 0,
        bones = merge(CROSSED_ARMS, {
            R_Thigh = A(0, -50, 0), L_Thigh = A(0, -50, 0),
            R_Calf = A(0, 100, 0), L_Calf = A(0, 100, 0),
            Spine = A(0, 25, 0), Spine1 = A(0, 22, 0), Spine2 = A(0, 18, 0),
            Neck1 = A(0, 10, 0),
        }),
    },

    -- Kniebeugen
    squat_down = {
        pitch = 0, pivot = 0, dz = -19, dx = -11,
        bones = {
            R_Thigh = A(0, -80, 0), L_Thigh = A(0, -80, 0),
            R_Calf = A(0, 100, 0), L_Calf = A(0, 100, 0),
            R_Foot = A(0, -20, 0), L_Foot = A(0, -20, 0),
            Spine = A(0, 18, 0), Spine1 = A(0, 8, 0),
            R_UpperArm = A(0, -80, 0), L_UpperArm = A(0, -80, 0),
        },
    },

    -- Hampelmann
    jack_open = {
        pitch = 0, pivot = 0, dz = 2, dx = 0,
        bones = {
            R_UpperArm = A(0, -165, 0), L_UpperArm = A(0, -165, 0),
            R_Thigh = A(14, 0, 0), L_Thigh = A(-14, 0, 0),
        },
    },

    -- Burpee-Sprung
    burpee_jump = {
        pitch = 0, pivot = 0, dz = 14, dx = 0,
        bones = {
            R_UpperArm = A(0, -165, 0), L_UpperArm = A(0, -165, 0),
            R_Foot = A(0, 30, 0), L_Foot = A(0, 30, 0),
        },
    },

    -- Klimmzüge (Position kommt vom Server, hier nur Körper und Arme)
    pullup_hang = {
        pitch = 0, pivot = 0, dz = 0, dx = 0,
        bones = {
            R_UpperArm = A(0, -172, 0), L_UpperArm = A(0, -172, 0),
            R_Calf = A(0, 20, 0), L_Calf = A(0, 20, 0),
        },
    },
    pullup_top = {
        pitch = 0, pivot = 0, dz = 22, dx = 0,
        bones = {
            R_UpperArm = A(0, -150, 0), L_UpperArm = A(0, -150, 0),
            R_Forearm = A(0, -110, 0), L_Forearm = A(0, -110, 0),
            R_Calf = A(0, 35, 0), L_Calf = A(0, 35, 0),
        },
    },

    -- Planke (Unterarmstütz)
    plank = {
        pitch = 78, pivot = 0, dz = 0, dx = 0,
        bones = {
            R_UpperArm = A(0, -78, 0), L_UpperArm = A(0, -78, 0),
            R_Forearm = A(0, -85, 0), L_Forearm = A(0, -85, 0),
            Head1 = A(0, -25, 0),
            R_Foot = A(0, 45, 0), L_Foot = A(0, 45, 0),
        },
    },

    -- Laufen auf der Stelle
    run_mid = {
        pitch = 0, pivot = 0, dz = 1, dx = 0,
        bones = {
            R_Forearm = A(0, -70, 0), L_Forearm = A(0, -70, 0),
        },
    },
    run_a = {
        pitch = 0, pivot = 0, dz = 0, dx = 0,
        bones = {
            R_Thigh = A(0, -70, 0), R_Calf = A(0, 85, 0),
            R_UpperArm = A(0, 30, 0), L_UpperArm = A(0, -40, 0),
            R_Forearm = A(0, -70, 0), L_Forearm = A(0, -70, 0),
        },
    },
    run_b = {
        pitch = 0, pivot = 0, dz = 0, dx = 0,
        bones = {
            L_Thigh = A(0, -70, 0), L_Calf = A(0, 85, 0),
            L_UpperArm = A(0, 30, 0), R_UpperArm = A(0, -40, 0),
            R_Forearm = A(0, -70, 0), L_Forearm = A(0, -70, 0),
        },
    },
}

-- Bei Lua-Refresh dieser Datei die Posen neu aufbereiten.
if EoCSport.PreparePoses then EoCSport.PreparePoses() end
