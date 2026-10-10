local KMS = KrakensMedical
local AID = "krakens_medical"
KMS.AID = AID

KMS.Lang = setmetatable({}, { __index = function(_, key)
    local fn = KF.Lang[key]
    if not isfunction(fn) then return fn end
    return function(...) return fn(AID, ...) end
end })

KMS.LangOverlay = {}

function KMS.ExtendLang(key, names)
    if isstring(key) and istable(names) then KMS.LangOverlay[key] = names end
end

function KMS.L(key, ...)
    local names = KMS.LangOverlay[key]
    local text = names and (names[KF.Lang.GetCurrent(AID)] or names.en or key) or KF.Lang.Get(AID, key)
    local args = { ... }
    for i = 1, #args do
        local safe = string.gsub(tostring(args[i]), "%%", "%%%%")
        text = string.gsub(text, "%%" .. i, safe)
    end
    return text
end

local L = KMS.L

KF.Whitelist.AccessProfiles.krakens_medical = {
    mode = "any",
    keys = {
        usergroups = "usergroups",
        jobs = "jobs",
        jobCategories = "jobCategories",
        steamIds = "steamIds",
        helixFactions = "helixFactions",
        helixClasses = "helixClasses",
        nutFactions = "nutFactions",
        nutClasses = "nutClasses",
    },
    hookName = "KMS_CheckWhitelist",
}

KMS.WhitelistKeys = { "usergroups", "jobs", "jobCategories", "steamIds", "helixFactions", "helixClasses", "nutFactions", "nutClasses" }

KMS.DisplayUnitsPerMeter = 39.37

function KMS.WhitelistHasEntries(whitelist)
    if not istable(whitelist) then return false end
    for _, key in ipairs(KMS.WhitelistKeys) do
        if istable(whitelist[key]) and #whitelist[key] > 0 then return true end
    end
    return false
end

function KMS.CheckWhitelist(ply, whitelist)
    if not KMS.WhitelistHasEntries(whitelist) then return false end
    return KF.Whitelist.CheckProfile("krakens_medical", ply, whitelist) == true
end

function KMS.NPCAccess(ply, npc)
    if not KMS.WhitelistHasEntries(npc.whitelist) then return true end
    return KF.Whitelist.CheckProfile("krakens_medical", ply, npc.whitelist) == true
end

hook.Add("Initialize", "KMS_CAMI", function()
    if not CAMI then return end
    CAMI.RegisterPrivilege({ Name = "kms_admin", MinAccess = "admin" })
    CAMI.RegisterPrivilege({ Name = "kms_heal", MinAccess = "admin" })
    CAMI.RegisterPrivilege({ Name = "kms_debug", MinAccess = "superadmin" })
end)

local function CamiAccess(ply, privilege)
    if not CAMI or not IsValid(ply) then return false end
    local allowed
    CAMI.PlayerHasAccess(ply, privilege, function(result) allowed = result end)
    return allowed == true
end

local accessCache = {}

function KMS.ClearAccessCache(ply)
    if ply ~= nil then accessCache[ply] = nil else accessCache = {} end
end

if SERVER then
    hook.Add("OnPlayerChangedTeam", "KMS_AccessCache", KMS.ClearAccessCache)
    hook.Add("PlayerChangedUserGroup", "KMS_AccessCache", KMS.ClearAccessCache)
    hook.Add("CAMI.PlayerUsergroupChanged", "KMS_AccessCache", KMS.ClearAccessCache)
    hook.Add("PlayerDisconnected", "KMS_AccessCache", KMS.ClearAccessCache)
end

KMS.PlayerData = KMS.PlayerData or {}

function KMS.EarnedTier(ply)
    if CLIENT or not IsValid(ply) or not ply:IsPlayer() then return 0 end
    local record = KMS.PlayerData[ply:SteamID64() or ""]
    return record and record.tier or 0
end

local function AccessInfo(ply)
    local cached = accessCache[ply]
    if cached and cached.until_ > CurTime() then return cached end
    local info = {
        until_ = CurTime() + 10,
        tier = math.max(KMS.CheckWhitelist(ply, KMS.Settings.doctorWhitelist) and 2
            or KMS.CheckWhitelist(ply, KMS.Settings.medicWhitelist) and 1 or 0, KMS.EarnedTier(ply)),
        exempt = KMS.CheckWhitelist(ply, KMS.Settings.immuneWhitelist),
        vehwl = KMS.CheckWhitelist(ply, KMS.Settings.medVehicleWhitelist),
        admin = KF.Admin.HasAccess(ply, AID) == true
            or KMS.CheckWhitelist(ply, KMS.Settings.adminWhitelist)
            or CamiAccess(ply, "kms_admin"),
    }
    accessCache[ply] = info
    return info
end

function KMS.IsAdmin(ply)
    if CLIENT then return IsValid(ply) and ply:GetNWBool("kms_medadmin", false) end
    if not IsValid(ply) then return KF.Admin.HasAccess(ply, AID) == true end
    return AccessInfo(ply).admin == true
end

function KMS.CanHeal(ply)
    return KMS.IsAdmin(ply) or CamiAccess(ply, "kms_heal")
end

function KMS.CanDebug(ply)
    if not IsValid(ply) then return true end
    return ply:IsSuperAdmin() or CamiAccess(ply, "kms_debug")
end

function KMS.Exempt(ply)
    if CLIENT then return IsValid(ply) and ply:GetNWBool("kms_exempt", false) end
    return IsValid(ply) and ply:IsPlayer() and AccessInfo(ply).exempt == true
end

function KMS.Cloaked(ply)
    local body = ply:GetNWEntity("kms_ragdoll")
    if not IsValid(body) then
        if IsValid(ply:GetNWEntity("kms_loaded_in")) then return false end
        body = ply
    end
    return body:GetNoDraw() or body:GetColor().a <= 20
end

KMS.Parts = {
    { id = "head", bone = "ValveBiped.Bip01_Head1" },
    { id = "torso", bone = "ValveBiped.Bip01_Spine2" },
    { id = "arm_l", limb = true, bone = "ValveBiped.Bip01_L_Forearm" },
    { id = "arm_r", limb = true, bone = "ValveBiped.Bip01_R_Forearm" },
    { id = "leg_l", limb = true, leg = true, bone = "ValveBiped.Bip01_L_Calf" },
    { id = "leg_r", limb = true, leg = true, bone = "ValveBiped.Bip01_R_Calf" },
}

KMS.PartById = {}
for _, part in ipairs(KMS.Parts) do
    KMS.PartById[part.id] = part
end

KMS.HitgroupToPart = {
    [HITGROUP_HEAD] = "head",
    [HITGROUP_CHEST] = "torso",
    [HITGROUP_STOMACH] = "torso",
    [HITGROUP_LEFTARM] = "arm_l",
    [HITGROUP_RIGHTARM] = "arm_r",
    [HITGROUP_LEFTLEG] = "leg_l",
    [HITGROUP_RIGHTLEG] = "leg_r",
}

KMS.MaxCost = 2000000000
KMS.WoundEpsilon = 0.001
KMS.BodyBleedCap = 126.7
KMS.TraumaThresholds = { head = 1.25, torso = 1.5 }
KMS.HRNormalLow = 60
KMS.HRNormalHigh = 160
KMS.ReachMargin = 1.5
KMS.WatchMargin = 2
KMS.InteractRangeSqr = 150 * 150
KMS.MedCallCooldown = 30

function KMS.LinearConversion(from, to, value, outFrom, outTo)
    if from == to then return outTo end
    return outFrom + (outTo - outFrom) * math.Clamp((value - from) / (to - from), 0, 1)
end

function KMS.InterpolatePoints(value, points, randomRound)
    if #points == 1 then return points[1][2] end
    local lower
    for i = 1, #points do
        if points[i][1] < value then
            lower = i
            break
        end
    end
    if lower == 1 then return points[1][2] end
    if not lower then return points[#points][2] end
    local hi, lo = points[lower - 1], points[lower]
    local output = KMS.LinearConversion(lo[1], hi[1], value, lo[2], hi[2])
    if randomRound then return math.ceil(output - math.random()) end
    return output
end

function KMS.SelectWeighted(entries, weights, total)
    if total <= 0 then return nil end
    local roll = math.random() * total
    for i, entry in ipairs(entries) do
        roll = roll - weights[i]
        if roll <= 0 then return entry end
    end
    return entries[#entries]
end

KMS.DamageDomain = 100
KMS.WoundSizeFloor = 0.125
KMS.WoundSizeWorst = 2
KMS.LargeWoundSize = 0.5
KMS.LimpDamage = 0.3
KMS.FractureDamage = 0.5
KMS.PenetrationDamage = 0.35
KMS.WoundUnitDamage = 0.35
KMS.IVDripRate = 4.1667
KMS.PainUnconscious = 0.5
KMS.MinCardiacOutput = 0.395
KMS.NormalSpO2 = 97
KMS.OxygenUse = -0.25
KMS.OxygenIntake = 0.00368
KMS.CategorySize = { 0.1875, 0.375, 0.75 }

KMS.Wounds = {
    abrasion = { bleed = 0.002, pain = 0.35 },
    avulsion = { bleed = 0.175, pain = 1, limp = true, frac = true },
    burn = { bleed = 0, pain = 0.65 },
    contusion = { bleed = 0, pain = 0.25 },
    crush = { bleed = 0.02, pain = 0.75, limp = true, frac = true },
    cut = { bleed = 0.015, pain = 0.15 },
    laceration = { bleed = 0.075, pain = 0.25 },
    puncture = { bleed = 0.045, pain = 0.45, limp = true },
    velocity = { bleed = 0.25, pain = 0.85, limp = true, frac = true },
}

function KMS.WoundSize(aceDamage)
    return KMS.LinearConversion(0.1, KMS.WoundSizeWorst, aceDamage, KMS.WoundSizeFloor, 1)
end

function KMS.WoundCategory(woundSize)
    return math.Clamp(3 - math.floor(math.log(woundSize) / math.log(KMS.LargeWoundSize)), 1, 3)
end

function KMS.WoundBleed(wound)
    return KMS.Wounds[wound.t].bleed * (wound.w or KMS.WoundSizeFloor) * KMS.BodyBleedCap
end

function KMS.WoundEvents(wound)
    return wound.n / math.min(1, (wound.d or KMS.WoundUnitDamage) / KMS.WoundUnitDamage)
end

function KMS.WoundFlow(wound)
    return KMS.WoundBleed(wound) * KMS.WoundEvents(wound)
end

local FLAT = { { 0, 1 } }

local AREA_SPREAD = {
    { "torso", 0.65 }, { "head", 0.2 },
    { "arm_l", 0.45 }, { "arm_r", 0.45 },
    { "leg_l", 0.45 }, { "leg_r", 0.45 },
}

local FALL_SPREAD = {
    { "leg_l", 1 }, { "leg_r", 1 },
    { "torso", 0.3 }, { "head", 0.05 },
}

local EXPLOSIVE_WOUNDS = {
    { t = "avulsion", weight = { { 1, 1 }, { 0.75, 0 } } },
    { t = "cut", weight = { { 1.5, 0 }, { 0.4, 1 }, { 0, 0 } } },
    { t = "contusion", weight = { { 0.5, 0 }, { 0.4, 1 } }, size = 2.25, pain = 1 },
}

local FRAG_WOUNDS = {
    { t = "avulsion", weight = { { 1.5, 1 }, { 1, 0 } } },
    { t = "velocity", weight = { { 1.5, 0 }, { 1, 1 }, { 0.75, 0 } } },
    { t = "puncture", weight = { { 1, 0 }, { 0.75, 1 }, { 0.4, 0 } } },
    { t = "cut", weight = { { 0.75, 0 }, { 0.4, 1 }, { 0.4, 0 } } },
    { t = "contusion", weight = { { 0.5, 0 }, { 0.4, 1 } }, size = 2.25, pain = 1 },
}

KMS.DamageClasses = {
    bullet = {
        thresholds = { { 18, 8 }, { 5, 2 }, { 2.5, 1 }, { 0, 1 } },
        focused = true,
        wounds = {
            { t = "avulsion", weight = { { 1, 1 }, { 0.4, 0 } } },
            { t = "contusion", weight = { { 0.4, 0 }, { 0.4, 1 } }, size = 3, pain = 2 },
            { t = "velocity", weight = { { 1.6, 0 }, { 1.6, 1 }, { 0.4, 1 }, { 0.4, 0 } }, size = 1 },
        },
    },
    grenade = {
        thresholds = { { 18, 8 }, { 9, 4 }, { 3.5, 3 }, { 1.5, 2 }, { 0.75, 2 }, { 0.25, 1 }, { 0, 0 } },
        spread = AREA_SPREAD,
        wounds = FRAG_WOUNDS,
    },
    explosive = {
        thresholds = { { 18, 12 }, { 7.5, 6 }, { 2, 3 }, { 1, 2 }, { 0.5, 1 }, { 0, 0 } },
        spread = AREA_SPREAD,
        wounds = EXPLOSIVE_WOUNDS,
    },
    shell = {
        thresholds = { { 18, 8 }, { 9, 4 }, { 4, 2 }, { 2, 2 }, { 0.75, 1 }, { 0.25, 1 }, { 0, 0 } },
        spread = AREA_SPREAD,
        wounds = FRAG_WOUNDS,
    },
    vehiclehit = {
        thresholds = { { 5, 3 }, { 4, 2 }, { 2, 2 }, { 0.75, 1 }, { 0.25, 1 }, { 0, 0 } },
        spread = AREA_SPREAD,
        wounds = EXPLOSIVE_WOUNDS,
    },
    vehiclecrash = {
        thresholds = { { 2, 3 }, { 1.5, 2 }, { 1, 2 }, { 0.75, 1 }, { 0.05, 1 } },
        spread = AREA_SPREAD,
        wounds = {
            { t = "abrasion", weight = { { 0.35, 0 }, { 0.35, 1 } } },
            { t = "avulsion", weight = { { 0.02, 1 }, { 0.02, 0 } } },
            { t = "contusion", weight = { { 0.4, 0 }, { 0.4, 1 } } },
            { t = "crush", weight = { { 0.15, 1 }, { 0.15, 0 } } },
            { t = "cut", weight = { { 0.15, 1 }, { 0.15, 0 } } },
            { t = "laceration", weight = FLAT },
        },
    },
    collision = {
        thresholds = { { 7.5, 4 }, { 1, 1 }, { 0.25, 1 }, { 0.1, 0.5 }, { 0, 0.25 } },
        spread = AREA_SPREAD,
        wounds = {
            { t = "avulsion", weight = { { 1, 2 }, { 0.45, 0.5 }, { 0.45, 0 } } },
            { t = "abrasion", weight = { { 0.45, 0 }, { 0.25, 1 }, { 0, 0 } } },
            { t = "contusion", weight = { { 0.45, 0 }, { 0.25, 1 } } },
            { t = "crush", weight = { { 0.45, 1 }, { 0.25, 0 } } },
            { t = "cut", weight = { { 0.15, 1 }, { 0.15, 0 } } },
            { t = "laceration", weight = FLAT },
        },
    },
    falling = {
        thresholds = { { 7.5, 4 }, { 1, 1 }, { 0.25, 1 }, { 0.1, 0.75 }, { 0, 0.5 } },
        spread = FALL_SPREAD,
        wounds = {
            { t = "abrasion", weight = { { 0.45, 0 }, { 0.25, 1 }, { 0, 0 } }, size = 2.75 },
            { t = "contusion", weight = { { 0.45, 0 }, { 0.25, 1 } }, size = 2.75 },
            { t = "crush", weight = { { 0.45, 1 }, { 0.25, 0 } }, size = 1.75 },
        },
    },
    backblast = {
        thresholds = { { 1, 6 }, { 1, 4 }, { 0.5, 4 }, { 0.5, 2 }, { 0, 2 } },
        spread = AREA_SPREAD,
        wounds = {
            { t = "avulsion", weight = { { 0.35, 0 }, { 0.35, 1 } } },
            { t = "contusion", weight = { { 0.4, 0 }, { 0.4, 1 } } },
            { t = "cut", weight = { { 0.15, 1 }, { 0.15, 0 } } },
        },
    },
    stab = {
        thresholds = { { 0.15, 1 }, { 0.15, 0 } },
        focused = true,
        wounds = {
            { t = "cut", weight = { { 0.15, 1 }, { 0.15, 0 } } },
            { t = "puncture", weight = { { 0.05, 1 }, { 0.05, 0 } } },
        },
    },
    punch = {
        thresholds = { { 0.15, 1 }, { 0.15, 0 } },
        focused = true,
        wounds = {
            { t = "contusion", weight = { { 0.4, 0 }, { 0.4, 1 } } },
            { t = "crush", weight = { { 0.15, 1 }, { 0.15, 0 } } },
            { t = "laceration", weight = FLAT },
        },
    },
    burn = {
        thresholds = FLAT,
        wounds = { { t = "burn", weight = FLAT } },
    },
    plasma = {
        thresholds = FLAT,
        focused = true,
        wounds = {
            { t = "burn", weight = FLAT },
            { t = "laceration", weight = { { 0.5, 1 }, { 0.4, 0 } } },
        },
    },
    unknown = {
        thresholds = { { 0.15, 1 }, { 0.15, 0 } },
        wounds = {
            { t = "abrasion", weight = { { 0.35, 0 }, { 0.35, 1 } } },
            { t = "cut", weight = { { 0.15, 1 }, { 0.15, 0 } } },
            { t = "velocity", weight = { { 0.4, 1 }, { 0.4, 0 } } },
        },
    },
}

KMS.Bandages = { "bandage_field", "bandage_packing", "bandage_elastic", "bandage_quickclot" }

KMS.BandageStats = {
    bandage_field = {
        abrasion = { eff = { 3.25, 2.75, 2.25 }, reopen = { 0.25, 0.55, 0.8 }, delay = { 180, 900 } },
        avulsion = { eff = { 1.25, 1, 0.75 }, reopen = { 0.45, 0.45, 0.45 }, delay = { 120, 210 } },
        burn = { eff = { 1, 1, 1 }, reopen = { 0.1, 0.1, 0.1 }, delay = { 120, 210 } },
        contusion = { eff = { 1, 1, 1 }, reopen = { 0, 0, 0 }, delay = { 0, 0 } },
        crush = { eff = { 1.25, 0.75, 0.5 }, reopen = { 0.15, 0.25, 0.35 }, delay = { 180, 900 } },
        cut = { eff = { 4.25, 3.25, 1.25 }, reopen = { 0.1, 0.25, 0.45 }, delay = { 270, 900 } },
        laceration = { eff = { 1, 0.75, 0.5 }, reopen = { 0.25, 0.45, 0.55 }, delay = { 90, 720 } },
        puncture = { eff = { 2.25, 1.5, 1 }, reopen = { 0.45, 0.45, 0.45 }, delay = { 180, 780 } },
        velocity = { eff = { 2.25, 1.75, 1.25 }, reopen = { 0.65, 0.65, 0.65 }, delay = { 90, 450 } },
    },
    bandage_packing = {
        abrasion = { eff = { 3.25, 2.75, 2.25 }, reopen = { 0.55, 0.85, 1 }, delay = { 720, 1440 } },
        avulsion = { eff = { 1.25, 1, 0.75 }, reopen = { 0.65, 0.65, 0.65 }, delay = { 900, 1500 } },
        burn = { eff = { 1, 1, 1 }, reopen = { 0.1, 0.1, 0.1 }, delay = { 120, 210 } },
        contusion = { eff = { 1, 1, 1 }, reopen = { 0, 0, 0 }, delay = { 0, 0 } },
        crush = { eff = { 1.25, 0.75, 0.5 }, reopen = { 0.55, 0.65, 0.75 }, delay = { 540, 900 } },
        cut = { eff = { 4.25, 3.25, 1.25 }, reopen = { 0.55, 0.65, 0.75 }, delay = { 630, 900 } },
        laceration = { eff = { 1, 0.75, 0.5 }, reopen = { 0.6, 0.75, 0.85 }, delay = { 450, 1800 } },
        puncture = { eff = { 2.25, 1.5, 1 }, reopen = { 0.95, 0.95, 0.95 }, delay = { 900, 2700 } },
        velocity = { eff = { 2.25, 1.75, 1.25 }, reopen = { 0.95, 0.95, 0.95 }, delay = { 720, 1800 } },
    },
    bandage_elastic = {
        abrasion = { eff = { 4.25, 3.25, 2.75 }, reopen = { 0.55, 0.85, 1 }, delay = { 60, 150 } },
        avulsion = { eff = { 2.25, 1.5, 1 }, reopen = { 0.65, 0.65, 0.65 }, delay = { 90, 150 } },
        burn = { eff = { 1, 1, 1 }, reopen = { 0.1, 0.1, 0.1 }, delay = { 120, 210 } },
        contusion = { eff = { 2, 2, 2 }, reopen = { 0, 0, 0 }, delay = { 0, 0 } },
        crush = { eff = { 2.25, 1.75, 1.5 }, reopen = { 0.55, 0.65, 0.75 }, delay = { 60, 90 } },
        cut = { eff = { 5, 3.75, 2.25 }, reopen = { 0.55, 0.65, 0.75 }, delay = { 60, 90 } },
        laceration = { eff = { 2.25, 1.5, 1 }, reopen = { 0.6, 0.75, 0.85 }, delay = { 60, 180 } },
        puncture = { eff = { 2.75, 2, 1.5 }, reopen = { 0.95, 0.95, 0.95 }, delay = { 90, 300 } },
        velocity = { eff = { 2.5, 1.75, 1.5 }, reopen = { 0.95, 0.95, 0.95 }, delay = { 90, 180 } },
    },
    bandage_quickclot = {
        abrasion = { eff = { 2.25, 1.25, 0.75 }, reopen = { 0.2, 0.3, 0.4 }, delay = { 720, 1440 } },
        avulsion = { eff = { 0.75, 0.5, 0.5 }, reopen = { 0.15, 0.15, 0.15 }, delay = { 900, 1500 } },
        burn = { eff = { 1, 1, 1 }, reopen = { 0.1, 0.1, 0.1 }, delay = { 120, 210 } },
        contusion = { eff = { 1, 1, 1 }, reopen = { 0, 0, 0 }, delay = { 0, 0 } },
        crush = { eff = { 0.75, 0.5, 0.5 }, reopen = { 0.25, 0.4, 0.45 }, delay = { 540, 900 } },
        cut = { eff = { 2.25, 1.25, 0.75 }, reopen = { 0.15, 0.15, 0.15 }, delay = { 630, 900 } },
        laceration = { eff = { 0.75, 0.75, 0.5 }, reopen = { 0.35, 0.35, 0.35 }, delay = { 450, 1800 } },
        puncture = { eff = { 1.25, 0.75, 0.5 }, reopen = { 0.45, 0.45, 0.45 }, delay = { 900, 2700 } },
        velocity = { eff = { 1.25, 0.75, 0.5 }, reopen = { 0.45, 0.45, 0.45 }, delay = { 720, 1800 } },
    },
}

KMS.Meds = {
    morphine = { rampTime = 25, timeKey = "morphineTime", painReduce = 0.75, viscosity = -8, maxDose = 3, hr = { { -5, -15 }, { -10, -25 }, { -15, -30 } } },
    epinephrine = { rampTime = 8, timeKey = "epiTime", painReduce = 0, viscosity = 0, maxDose = 8, hr = { { 15, 25 }, { 15, 45 }, { 10, 35 } } },
    adenosine = { rampTime = 12, timeKey = "adenosineTime", painReduce = 0, viscosity = 0, maxDose = 4, hr = { { -5, -15 }, { -20, -35 }, { -20, -40 } } },
    painkillers = { rampTime = 50, timeKey = "painkillersTime", painReduce = 0.3, viscosity = 4, maxDose = 6, hr = { { -5, -10 }, { -5, -15 }, { -10, -20 } } },
}

KMS.Items = {
    { id = "bandage_field" },
    { id = "bandage_packing" },
    { id = "bandage_elastic" },
    { id = "bandage_quickclot" },
    { id = "tourniquet" },
    { id = "splint" },
    { id = "morphine" },
    { id = "epinephrine" },
    { id = "adenosine" },
    { id = "painkillers" },
    { id = "iv_saline" },
    { id = "iv_saline_500" },
    { id = "iv_saline_1500" },
    { id = "iv_plasma" },
    { id = "iv_plasma_500" },
    { id = "iv_plasma_250" },
    { id = "iv_blood" },
    { id = "iv_blood_500" },
    { id = "iv_blood_250" },
    { id = "surgical_kit" },
    { id = "pak" },
}

KMS.ItemById = {}
for _, item in ipairs(KMS.Items) do
    KMS.ItemById[item.id] = item
end

KMS.ItemKinds = { "bandage", "med", "iv" }

KMS.ItemSchema = {
    id = { type = "identifier", maxLen = 32 },
    kind = { type = "enum", values = KMS.ItemKinds, default = "bandage" },
    name = { type = "string", maxLen = 48, default = "" },
    icon = { type = "string", maxLen = 260, default = "" },
    tier = { type = "number", min = 0, max = 2, integer = true, default = 0 },
    applyTime = { type = "number", min = 1, max = 60, integer = true, default = 5 },
    power = { type = "number", min = 25, max = 400, integer = true, default = 100 },
    stability = { type = "number", min = 25, max = 400, integer = true, default = 100 },
    painReduce = { type = "number", min = 0, max = 100, integer = true, default = 30 },
    hrEffect = { type = "number", min = -40, max = 40, integer = true, default = 0 },
    duration = { type = "number", min = 30, max = 3600, integer = true, default = 300 },
    maxDose = { type = "number", min = 1, max = 10, integer = true, default = 4 },
    heal = { type = "number", min = 0, max = 100, integer = true, default = 0 },
    stamina = { type = "number", min = 0, max = 100, integer = true, default = 0 },
    volume = { type = "number", min = 100, max = 2000, integer = true, default = 500 },
}

KMS.ItemConfig = KMS.ItemConfig or { custom = {}, disabled = {}, renames = {} }
KMS.ItemDisabled = KMS.ItemDisabled or {}

local baseItems, baseTreatments, baseBandages

local function EnsureItemBase()
    if baseItems then return end
    baseItems = KMS.Items
    baseTreatments = KMS.Treatments
    baseBandages = KMS.Bandages
    KMS.BaseItemIds = {}
    for _, item in ipairs(baseItems) do
        KMS.BaseItemIds[item.id] = true
    end
end

function KMS.SanitizeItems(raw)
    EnsureItemBase()
    local config = { custom = {}, disabled = {}, renames = {} }
    if not istable(raw) then return config end
    local count = 0
    for id, record in pairs(istable(raw.custom) and raw.custom or {}) do
        if isstring(id) and istable(record) and count < 24 then
            local clean = KF.Sanitize.Apply(record, KMS.ItemSchema)
            if clean and clean.id == id and id ~= "" and not KMS.BaseItemIds[id] then
                count = count + 1
                config.custom[id] = clean
            end
        end
    end
    for id in pairs(istable(raw.disabled) and raw.disabled or {}) do
        if KMS.BaseItemIds[id] then config.disabled[id] = true end
    end
    local activeBandages = 0
    for _, id in ipairs(baseBandages) do
        if not config.disabled[id] then activeBandages = activeBandages + 1 end
    end
    for _, record in pairs(config.custom) do
        if record.kind == "bandage" then activeBandages = activeBandages + 1 end
    end
    if activeBandages == 0 then config.disabled.bandage_field = nil end
    for id, name in pairs(istable(raw.renames) and raw.renames or {}) do
        if isstring(id) and isstring(name) and name ~= "" then
            config.renames[id] = string.sub(name, 1, 48)
        end
    end
    return config
end

function KMS.CustomBandageStats(record)
    local stats = {}
    local power = record.power / 100
    local reopen = 100 / record.stability
    local delay = record.stability / 100
    for woundType, base in pairs(KMS.BandageStats.bandage_field) do
        stats[woundType] = {
            eff = { base.eff[1] * power, base.eff[2] * power, base.eff[3] * power },
            reopen = { math.min(1, base.reopen[1] * reopen), math.min(1, base.reopen[2] * reopen), math.min(1, base.reopen[3] * reopen) },
            delay = { base.delay[1] * delay, base.delay[2] * delay },
        }
    end
    return stats
end

local appliedOverlays = {}

function KMS.ApplyItemConfig(raw)
    local config = KMS.SanitizeItems(raw)
    KMS.ItemConfig = config
    KMS.ItemDisabled = config.disabled
    for _, key in ipairs(appliedOverlays) do
        KMS.LangOverlay[key] = nil
    end
    appliedOverlays = {}
    local function Overlay(id, name)
        if not name or name == "" then return end
        KMS.ExtendLang("item_" .. id, { en = name })
        KMS.ExtendLang("treat_" .. id, { en = name })
        appliedOverlays[#appliedOverlays + 1] = "item_" .. id
        appliedOverlays[#appliedOverlays + 1] = "treat_" .. id
    end
    for _, id in ipairs(KMS.CustomIds or {}) do
        KMS.BandageStats[id] = nil
        KMS.Meds[id] = nil
    end
    KMS.CustomIds = {}
    KMS.Items = {}
    KMS.Treatments = {}
    KMS.Bandages = {}
    for _, item in ipairs(baseItems) do
        KMS.Items[#KMS.Items + 1] = item
    end
    for _, treatment in ipairs(baseTreatments) do
        if not (treatment.item and config.disabled[treatment.item]) then
            KMS.Treatments[#KMS.Treatments + 1] = treatment
        end
    end
    for _, id in ipairs(baseBandages) do
        if not config.disabled[id] then KMS.Bandages[#KMS.Bandages + 1] = id end
    end
    for id, name in pairs(config.renames) do
        Overlay(id, name)
    end
    local ids = {}
    for id in pairs(config.custom) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local record = config.custom[id]
        KMS.CustomIds[#KMS.CustomIds + 1] = id
        KMS.Items[#KMS.Items + 1] = { id = id, custom = true }
        Overlay(id, record.name ~= "" and record.name or id)
        local treatment
        if record.kind == "bandage" then
            KMS.BandageStats[id] = KMS.CustomBandageStats(record)
            KMS.Bandages[#KMS.Bandages + 1] = id
            treatment = { id = id, cat = "bandage", item = id, tier = record.tier, needsWound = true, custom = true }
        elseif record.kind == "med" then
            KMS.Meds[id] = {
                rampTime = 15,
                painReduce = record.painReduce / 100,
                viscosity = 0,
                maxDose = record.maxDose,
                duration = record.duration,
                heal = record.heal / 100,
                stamina = record.stamina / 100,
                hr = { { record.hrEffect * 0.6, record.hrEffect }, { record.hrEffect * 0.6, record.hrEffect }, { record.hrEffect * 0.6, record.hrEffect } },
            }
            treatment = { id = id, cat = "meds", item = id, time = record.applyTime, tier = record.tier, limbsOnly = true, trainedKey = "trainedTimeInjector", med = true, custom = true }
        else
            treatment = { id = id, cat = "meds", item = id, time = record.applyTime, tier = record.tier, limbsOnly = true, ivMl = record.volume, trainedKey = "trainedTimeIV", custom = true }
        end
        KMS.Treatments[#KMS.Treatments + 1] = treatment
    end
    KMS.ItemById = {}
    for _, item in ipairs(KMS.Items) do
        KMS.ItemById[item.id] = item
    end
    KMS.TreatmentById = {}
    for _, treatment in ipairs(KMS.Treatments) do
        KMS.TreatmentById[treatment.id] = treatment
    end
    if CLIENT then
        for _, item in ipairs(KMS.Items) do
            if KMS.ItemIcons[item.id] == nil then
                KMS.ItemIcons[item.id] = KMS.ResolveItemIcon(item.id)
            end
        end
        for id, record in pairs(config.custom) do
            if record.icon ~= "" then
                if KMS.ItemIcons[record.icon] then
                    KMS.ItemIcons[id] = KMS.ItemIcons[record.icon]
                elseif file.Exists("materials/" .. record.icon, "GAME") then
                    KMS.ItemIcons[id] = Material(record.icon, "smooth mips")
                end
            end
        end
    end
    hook.Run("KMS_ItemsApplied")
end

function KMS.RegisterItem(def, names)
    if not istable(def) or not isstring(def.id) or KMS.ItemById[def.id] then return false end
    KMS.Items[#KMS.Items + 1] = def
    KMS.ItemById[def.id] = def
    for _, key in ipairs({ "loadoutDefault", "loadoutMedic", "loadoutDoctor" }) do
        local loadout = KMS.DefaultSettings and KMS.DefaultSettings[key]
        if loadout then loadout[def.id] = 0 end
    end
    if names then KMS.ExtendLang("item_" .. def.id, names) end
    if CLIENT and KMS.ItemIcons then KMS.ItemIcons[def.id] = KMS.ResolveItemIcon(def.id) end
    return true
end

function KMS.PersistentInv()
    return KMS.Settings.invMode == "persistent" and not KMS.Settings.infiniteSupplies
end

function KMS.IsDowned(ply)
    if SERVER then
        local state = ply.KMSState
        return state ~= nil and state.conscious == false
    end
    return IsValid(ply:GetNWEntity("kms_ragdoll")) or IsValid(ply:GetNWEntity("kms_loaded_in"))
end

KMS.Categories = { "bandage", "advanced", "meds", "examine", "triage" }

KMS.InvCategories = { "bandage", "meds", "advanced" }

KMS.StratagemDifficulties = { "easy", "medium", "hard" }
KMS.StratagemRoleModes = { "inherit", "easy", "medium", "hard" }

KMS.StratagemTuning = {
    easy = { length = 4 },
    medium = { length = 6 },
    hard = { length = 8 },
}

KMS.SimDifficulties = { "easy", "medium", "hard", "nightmare" }

KMS.SimTuning = {
    easy = { wounds = { 2, 3 }, maxSize = 2, blood = 0.92, fracture = 0, arrest = false, time = 300 },
    medium = { wounds = { 3, 5 }, maxSize = 3, blood = 0.8, fracture = 40, arrest = false, time = 240 },
    hard = { wounds = { 5, 7 }, maxSize = 3, blood = 0.68, fracture = 70, arrest = true, time = 210 },
    nightmare = { wounds = { 8, 11 }, maxSize = 3, blood = 0.56, fracture = 100, arrest = true, time = 180 },
}

function KMS.StratagemDifficultyFor(tier)
    local override = tier >= 2 and KMS.Settings.stratagemDifficultyDoctor
        or tier >= 1 and KMS.Settings.stratagemDifficultyMedic
        or "inherit"
    if override ~= "inherit" and table.HasValue(KMS.StratagemDifficulties, override) then
        return override
    end
    return KMS.Settings.stratagemDifficulty
end

function KMS.ItemCategory(itemId)
    for _, def in ipairs(KMS.Treatments) do
        if def.item == itemId and def.cat ~= "examine" and def.cat ~= "triage" then
            return def.cat
        end
    end
    return "advanced"
end

KMS.Treatments = {
    { id = "check_pulse", cat = "examine", time = 2.5, tier = 0 },
    { id = "check_bp", cat = "examine", time = 2.5, tier = 0 },
    { id = "check_response", cat = "examine", time = 2.5, tier = 0 },
    { id = "bandage_field", cat = "bandage", item = "bandage_field", tier = 0, needsWound = true },
    { id = "bandage_packing", cat = "bandage", item = "bandage_packing", tier = 0, needsWound = true },
    { id = "bandage_elastic", cat = "bandage", item = "bandage_elastic", tier = 0, needsWound = true },
    { id = "bandage_quickclot", cat = "bandage", item = "bandage_quickclot", tier = 0, needsWound = true },
    { id = "tourniquet", cat = "bandage", item = "tourniquet", time = 7, tier = 0, limbsOnly = true, trainedKey = "trainedTimeTourniquet" },
    { id = "remove_tourniquet", cat = "bandage", time = 7, tier = 0, limbsOnly = true, needsTourniquet = true, returnsItem = "tourniquet", returnsToPatient = true, trainedKey = "trainedTimeTourniquet" },
    { id = "painkillers", cat = "meds", item = "painkillers", time = 5, tier = 0, limbsOnly = true, trainedKey = "trainedTimeInjector" },
    { id = "morphine", cat = "meds", item = "morphine", time = 5, tier = 0, limbsOnly = true, trainedKey = "trainedTimeInjector" },
    { id = "epinephrine", cat = "meds", item = "epinephrine", time = 5, tier = 1, limbsOnly = true, trainedKey = "trainedTimeInjector" },
    { id = "adenosine", cat = "meds", item = "adenosine", time = 5, tier = 1, limbsOnly = true, trainedKey = "trainedTimeInjector" },
    { id = "iv_saline", cat = "meds", item = "iv_saline", time = 12, tier = 1, limbsOnly = true, ivScale = 1, trainedKey = "trainedTimeIV" },
    { id = "iv_saline_500", cat = "meds", item = "iv_saline_500", time = 12, tier = 1, limbsOnly = true, ivScale = 0.5, trainedKey = "trainedTimeIV" },
    { id = "iv_saline_1500", cat = "meds", item = "iv_saline_1500", time = 12, tier = 1, limbsOnly = true, ivScale = 1.5, trainedKey = "trainedTimeIV" },
    { id = "iv_plasma", cat = "meds", item = "iv_plasma", time = 12, tier = 1, limbsOnly = true, ivScale = 1, trainedKey = "trainedTimeIV" },
    { id = "iv_plasma_500", cat = "meds", item = "iv_plasma_500", time = 12, tier = 1, limbsOnly = true, ivScale = 0.5, trainedKey = "trainedTimeIV" },
    { id = "iv_plasma_250", cat = "meds", item = "iv_plasma_250", time = 12, tier = 1, limbsOnly = true, ivScale = 0.25, trainedKey = "trainedTimeIV" },
    { id = "iv_blood", cat = "meds", item = "iv_blood", time = 12, tier = 1, limbsOnly = true, ivScale = 1, trainedKey = "trainedTimeIV" },
    { id = "iv_blood_500", cat = "meds", item = "iv_blood_500", time = 12, tier = 1, limbsOnly = true, ivScale = 0.5, trainedKey = "trainedTimeIV" },
    { id = "iv_blood_250", cat = "meds", item = "iv_blood_250", time = 12, tier = 1, limbsOnly = true, ivScale = 0.25, trainedKey = "trainedTimeIV" },
    { id = "splint", cat = "advanced", item = "splint", time = 7, tier = 0, limbsOnly = true, needsFracture = true, trainedKey = "trainedTimeSplint" },
    { id = "cpr", cat = "advanced", time = 15, tier = 0, torsoOnly = true, noSelf = true },
    { id = "surgical", cat = "advanced", item = "surgical_kit", tier = 2, locationKey = "surgicalLocation", returnsItem = "surgical_kit", noSelf = true },
    { id = "pak", cat = "advanced", item = "pak", tier = 2, locationKey = "pakLocation", noSelf = true },
}

KMS.TreatmentById = {}
for _, treatment in ipairs(KMS.Treatments) do
    KMS.TreatmentById[treatment.id] = treatment
end

KMS.TriageLevels = {
    { id = 0, key = "triage_none", color = Color(101, 107, 117) },
    { id = 1, key = "triage_t1", color = Color(225, 88, 88) },
    { id = 2, key = "triage_t2", color = Color(255, 190, 50) },
    { id = 3, key = "triage_t3", color = Color(74, 203, 130) },
    { id = 4, key = "triage_t4", color = Color(30, 30, 30) },
}

KMS.TriageById = {}
for _, level in ipairs(KMS.TriageLevels) do
    KMS.TriageById[level.id] = level
end

local function DefaultLoadout(defaults)
    local loadout = {}
    for _, item in ipairs(KMS.Items) do
        loadout[item.id] = defaults[item.id] or 0
    end
    return loadout
end

KMS.DefaultSettings = {
    enabled = true,
    language = "de",
    mapPresets = {},
    keyMenu = KEY_K,
    keyInteract = KEY_LALT,
    keyQuickUse = 0,
    commandEnabled = true,
    chatCommand = "!medical",
    damageScale = 100,
    directDamage = 100,
    bleedCoef = 100,
    painCoef = 100,
    treatTimeCoef = 100,
    trainedTimeTourniquet = 7,
    trainedTimeSplint = 7,
    trainedTimeInjector = 5,
    trainedTimeIV = 12,
    untrainedTimeTourniquet = 7,
    untrainedTimeSplint = 7,
    untrainedTimeInjector = 5,
    untrainedTimeIV = 12,
    reopenEnabled = false,
    bandageRollover = true,
    fractureMode = "splint_heal",
    fractureChance = 80,
    fractureThreshold = 50,
    limpingEnabled = true,
    disarmEnabled = false,
    fatalMode = "always",
    reviveEnabled = true,
    giveUpEnabled = false,
    giveUpDelay = 60,
    arrestTime = 300,
    arrestStableTimeScale = 100,
    wakeChance = 10,
    wakeHealth = 25,
    wakeInterval = 15,
    wakeEpiBoost = 1.5,
    cprChance = 40,
    cprChanceMin = 40,
    painKoChance = 10,
    deathChance = 100,
    limbTrauma = false,
    limbTraumaThreshold = 5,
    arrestBleedout = true,
    bandageEffectiveness = 100,
    woundReopenChance = 100,
    ivFlowRate = 100,
    morphineCooldown = 0,
    morphineTime = 1800,
    epiTime = 120,
    adenosineTime = 120,
    painkillersTime = 420,
    maxBlood = 6000,
    ivVolume = 1000,
    tourniquetWarnTime = 120,
    maxTreatDistance = 110,
    selfTreatment = true,
    diagnosisMode = "direct",
    holsterToTreat = false,
    medicMode = "everyone",
    medicWhitelist = {},
    doctorWhitelist = {},
    adminWhitelist = {},
    immuneWhitelist = {},
    healCommand = "!heal",
    reviveCommand = "!revive",
    downedIndicator = true,
    downedIndicatorAll = false,
    surgicalLocation = "crate",
    pakLocation = "crate",
    locationsBoostTraining = false,
    medbayEnabled = true,
    medbayDeployTime = 3,
    npcModels = {
        supply = "models/kleiner.mdl",
        billing = "models/kleiner.mdl",
        simulator = "models/kleiner.mdl",
        exam = "models/kleiner.mdl",
        medbay = "models/items/item_item_crate.mdl",
    },
    pakRequireStable = true,
    consumePak = false,
    infiniteSupplies = false,
    loadoutDefault = DefaultLoadout({ bandage_field = 2, tourniquet = 1, morphine = 1, painkillers = 2 }),
    loadoutMedic = DefaultLoadout({ bandage_field = 4, bandage_packing = 4, bandage_elastic = 4, bandage_quickclot = 2, tourniquet = 2, splint = 2, morphine = 2, epinephrine = 2, adenosine = 1, painkillers = 4, iv_saline = 2, iv_plasma = 1, iv_blood = 1 }),
    loadoutDoctor = DefaultLoadout({ bandage_field = 6, bandage_packing = 6, bandage_elastic = 6, bandage_quickclot = 4, tourniquet = 3, splint = 3, morphine = 3, epinephrine = 3, adenosine = 2, painkillers = 6, iv_saline = 3, iv_plasma = 2, iv_blood = 2, surgical_kit = 2, pak = 1 }),
    crateCooldown = 30,
    notifySounds = true,
    hudEnabled = true,
    interactEnabled = true,
    bloodEffects = true,
    medicCallEnabled = true,
    medicCallRange = 5000,
    arrestTimerVisible = true,
    blasterMode = false,
    koEnabled = false,
    koTime = 30,
    koWeapons = {},
    dragTime = 2,
    carryTime = 4,
    releaseTime = 1,
    tierOverrides = {},
    itemSharing = true,
    quickUseEnabled = true,
    invMode = "loadout",
    invDeath = "keep",
    invDropExpiry = 300,
    invLootDowned = false,
    stratagemMode = false,
    stratagemDifficulty = "medium",
    stratagemDifficultyMedic = "inherit",
    stratagemDifficultyDoctor = "inherit",
    medVehicles = {},
    medVehicleInvDefault = DefaultLoadout({ bandage_field = 6, bandage_packing = 4, bandage_elastic = 4, bandage_quickclot = 2, tourniquet = 2, splint = 2, morphine = 2, epinephrine = 2, painkillers = 4, iv_saline = 2, iv_blood = 1 }),
    medVehicleAccess = "everyone",
    medVehicleWhitelist = {},
    medVehicleLoss = "respawn",
    medVehicleRespawnTime = 60,
    staminaEnabled = true,
    staminaCapacity = 100,
    staminaRecovery = 100,
    sprintDrain = 100,
    fatigueAccum = 100,
    painSway = 100,
    fractureSway = 100,
    bloodEndurance = 100,
    weaponSway = 100,
    arc9Integration = true,
    arccwIntegration = true,
    staminaEncumbrance = true,
    staminaFeedback = "off",
    staminaProfiles = {},
    damageProfiles = {},
}

KMS.Settings = KMS.Settings or table.Copy(KMS.DefaultSettings)

KMS.Languages = { "en", "es", "de", "fr", "pt", "ru", "uk" }
KMS.FractureModes = { "disabled", "splint_heal", "splint_nosprint", "splint_nojog" }
KMS.FatalModes = { "always", "arrest", "never" }
KMS.DiagnosisModes = { "direct", "examine" }
KMS.MedicModes = { "everyone", "whitelist" }
KMS.LocationModes = { "anywhere", "crate" }
KMS.MedVehicleAccessModes = { "everyone", "medic", "doctor", "whitelist" }
KMS.InvModes = { "loadout", "persistent" }
KMS.InvDeathModes = { "keep", "drop", "lose" }
KMS.VehicleLossModes = { "respawn", "remove" }
KMS.ExamRewards = { "tier", "usergroup", "job", "command" }
KMS.StaminaFeedbackModes = { "off", "bar" }

local ARCADE_VALUES = {
    damageScale = 80, bleedCoef = 60, painCoef = 60, treatTimeCoef = 60,
    reopenEnabled = false, fractureMode = "splint_heal", fractureChance = 8, fractureThreshold = 50,
    limpingEnabled = true, fatalMode = "never", reviveEnabled = true,
    arrestTime = 180, arrestStableTimeScale = 25, wakeChance = 40, cprChance = 60,
    morphineCooldown = 0, morphineTime = 300,
    surgicalLocation = "anywhere", pakLocation = "anywhere", pakRequireStable = false, infiniteSupplies = true,
    dragTime = 0, carryTime = 0, releaseTime = 0,
    diagnosisMode = "direct",
}

KMS.Presets = {
    {
        id = "realistic",
        group = "base",
        deriveFromDefaults = true,
        values = {
            reopenEnabled = true,
            fatalMode = "always",
            diagnosisMode = "examine",
        },
    },
    {
        id = "arcade",
        group = "base",
        deriveFromDefaults = true,
        values = ARCADE_VALUES,
    },
    {
        id = "arcade_supplies",
        group = "base",
        deriveFromDefaults = true,
        values = table.Merge(table.Copy(ARCADE_VALUES), { infiniteSupplies = false }),
    },
    {
        id = "starwars",
        group = "themed",
        deriveFromDefaults = true,
        values = {
            damageScale = 100, bleedCoef = 100, painCoef = 110, treatTimeCoef = 100,
            reopenEnabled = true, fractureMode = "splint_nosprint", fractureChance = 12,
            limpingEnabled = true, fatalMode = "arrest", reviveEnabled = true,
            arrestTime = 300, arrestStableTimeScale = 50, wakeChance = 10, cprChance = 45,
            morphineCooldown = 60, morphineTime = 1800,
            surgicalLocation = "crate", pakLocation = "crate", pakRequireStable = true, infiniteSupplies = false,
            dragTime = 2, carryTime = 4, releaseTime = 1,
        },
    },
}

KMS.PresetById = {}
KMS.PresetKeys = {}
local presetKeySeen = {}
for _, preset in ipairs(KMS.Presets) do
    KMS.PresetById[preset.id] = preset
    for key in pairs(preset.values) do
        if not presetKeySeen[key] then
            presetKeySeen[key] = true
            KMS.PresetKeys[#KMS.PresetKeys + 1] = key
        end
    end
end

for _, preset in ipairs(KMS.Presets) do
    if preset.deriveFromDefaults then
        for _, key in ipairs(KMS.PresetKeys) do
            if preset.values[key] == nil then
                preset.values[key] = KMS.DefaultSettings[key]
            end
        end
    end
end

local WL_SCHEMA = {}
for _, key in ipairs(KMS.WhitelistKeys) do
    WL_SCHEMA[key] = { type = "stringList", maxItems = 128, itemMaxLen = 128 }
end

local SETTING_ENUMS = {
    language = KMS.Languages,
    fractureMode = KMS.FractureModes,
    fatalMode = KMS.FatalModes,
    diagnosisMode = KMS.DiagnosisModes,
    medicMode = KMS.MedicModes,
    surgicalLocation = KMS.LocationModes,
    pakLocation = KMS.LocationModes,
    invMode = KMS.InvModes,
    invDeath = KMS.InvDeathModes,
    stratagemDifficulty = KMS.StratagemDifficulties,
    stratagemDifficultyMedic = KMS.StratagemRoleModes,
    stratagemDifficultyDoctor = KMS.StratagemRoleModes,
    medVehicleAccess = KMS.MedVehicleAccessModes,
    medVehicleLoss = KMS.VehicleLossModes,
    staminaFeedback = KMS.StaminaFeedbackModes,
}

local LOADOUT_KEYS = { loadoutDefault = true, loadoutMedic = true, loadoutDoctor = true, medVehicleInvDefault = true }

local WHITELIST_SETTINGS = { medicWhitelist = true, doctorWhitelist = true, medVehicleWhitelist = true, immuneWhitelist = true, adminWhitelist = true }

KMS.SettingBounds = {
    damageScale = { 10, 500 },
    directDamage = { 1, 100 },
    keyMenu = { 0, 159 },
    keyInteract = { 0, 159 },
    keyQuickUse = { 0, 159 },
    medbayDeployTime = { 0, 30 },
    bleedCoef = { 0, 500 },
    painCoef = { 0, 500 },
    treatTimeCoef = { 10, 500 },
    trainedTimeTourniquet = { 1, 60 },
    trainedTimeSplint = { 1, 60 },
    trainedTimeInjector = { 1, 60 },
    trainedTimeIV = { 1, 60 },
    untrainedTimeTourniquet = { 1, 60 },
    untrainedTimeSplint = { 1, 60 },
    untrainedTimeInjector = { 1, 60 },
    untrainedTimeIV = { 1, 60 },
    limbTraumaThreshold = { 1, 25 },
    medicCallRange = { 500, 50000 },
    fractureChance = { 0, 100 },
    fractureThreshold = { 5, 200 },
    arrestTime = { 10, 3600 },
    giveUpDelay = { 0, 600 },
    wakeChance = { 0, 100 },
    wakeHealth = { 1, 100 },
    wakeEpiBoost = { 1, 30 },
    wakeInterval = { 1, 120 },
    cprChance = { 0, 100 },
    cprChanceMin = { 0, 100 },
    morphineCooldown = { 0, 3600 },
    morphineTime = { 90, 3600 },
    epiTime = { 30, 3600 },
    adenosineTime = { 45, 3600 },
    painkillersTime = { 180, 3600 },
    maxBlood = { 1000, 20000 },
    ivVolume = { 100, 5000 },
    tourniquetWarnTime = { 30, 3600 },
    medVehicleRespawnTime = { 5, 3600 },
    maxTreatDistance = { 32, 500 },
    crateCooldown = { 0, 3600 },
    invDropExpiry = { 30, 3600 },
    arrestStableTimeScale = { 10, 100 },
    painKoChance = { 0, 100 },
    deathChance = { 0, 100 },
    bandageEffectiveness = { 10, 500 },
    woundReopenChance = { 0, 500 },
    ivFlowRate = { 10, 2500 },
    koTime = { 5, 600 },
    dragTime = { 0, 30 },
    carryTime = { 0, 30 },
    releaseTime = { 0, 30 },
    staminaCapacity = { 25, 400 },
    staminaRecovery = { 25, 400 },
    sprintDrain = { 0, 400 },
    fatigueAccum = { 0, 400 },
    painSway = { 0, 400 },
    fractureSway = { 0, 400 },
    bloodEndurance = { 25, 400 },
    weaponSway = { 0, 400 },
}

-- defaults: fills items missing from a saved loadout (e.g. items added by a later update)
local function SanitizeLoadout(value, defaults)
    local loadout = DefaultLoadout({})
    if not istable(value) then return loadout end
    for _, item in ipairs(KMS.Items) do
        local fallback = value[item.id] == nil and defaults and defaults[item.id] or 0
        loadout[item.id] = KF.Sanitize.Clean.Number(value[item.id], fallback, 0, 999, true)
    end
    return loadout
end

local function SanitizeTierOverrides(value)
    local overrides = {}
    if not istable(value) then return overrides end
    for _, treatment in ipairs(KMS.Treatments) do
        local tier = tonumber(value[treatment.id])
        if tier and tier >= 0 and tier <= 2 and math.floor(tier) ~= treatment.tier then
            overrides[treatment.id] = math.floor(tier)
        end
    end
    return overrides
end

local function SanitizeMedVehicles(value)
    local vehicles = {}
    if not istable(value) then return vehicles end
    local count = 0
    for class, raw in pairs(value) do
        if isstring(class) and class ~= "" and #class <= 128 and count < 256 then
            count = count + 1
            local entry = {}
            if istable(raw) and istable(raw.inv) then
                entry.inv = SanitizeLoadout(raw.inv)
            end
            vehicles[string.lower(class)] = entry
        end
    end
    return vehicles
end

KMS.StaminaProfileDefaults = { priority = 0, capacity = 100, drain = 100, recovery = 100, fatigueRes = 100, stability = 100 }
KMS.StaminaProfileBounds = { priority = { 0, 100 }, capacity = { 10, 400 }, drain = { 10, 400 }, recovery = { 10, 400 }, fatigueRes = { 10, 400 }, stability = { 10, 400 } }

KMS.DamageProfileDefaults = { priority = 0, damage = 100, bleed = 100, pain = 100, fracture = 100, healing = 100 }
KMS.DamageProfileBounds = { priority = { 0, 100 }, damage = { 10, 400 }, bleed = { 0, 400 }, pain = { 0, 400 }, fracture = { 0, 400 }, healing = { 10, 400 } }

local function SanitizeProfiles(value, defaults, bounds)
    local profiles = {}
    if not istable(value) then return profiles end
    local count = 0
    for id, raw in pairs(value) do
        if isstring(id) and id ~= "" and #id <= 32 and istable(raw) and count < 24 then
            count = count + 1
            local profile = {
                name = string.sub(KF.Sanitize.Clean.String(raw.name, id), 1, 48),
                whitelist = KF.Sanitize.Apply(istable(raw.whitelist) and raw.whitelist or {}, WL_SCHEMA),
            }
            for field, default in pairs(defaults) do
                local fieldBounds = bounds[field]
                profile[field] = KF.Sanitize.Clean.Number(raw[field], default, fieldBounds[1], fieldBounds[2], true)
            end
            profiles[id] = profile
        end
    end
    return profiles
end

function KMS.SanitizeSetting(key, value)
    local default = KMS.DefaultSettings[key]
    if default == nil then return nil end
    if LOADOUT_KEYS[key] then return SanitizeLoadout(value, default) end
    if key == "tierOverrides" then return SanitizeTierOverrides(value) end
    if key == "mapPresets" then
        local presets = {}
        local count = 0
        for map, presetId in pairs(istable(value) and value or {}) do
            if isstring(map) and map ~= "" and #map <= 64 and KMS.PresetById[tostring(presetId)] and count < 128 then
                count = count + 1
                presets[string.lower(map)] = tostring(presetId)
            end
        end
        return presets
    end
    if key == "npcModels" then
        local models = {}
        for typeKey, fallback in pairs(KMS.DefaultSettings.npcModels) do
            local model = istable(value) and value[typeKey]
            model = isstring(model) and string.Trim(model) or ""
            models[typeKey] = (model ~= "" and #model <= 260 and string.EndsWith(string.lower(model), ".mdl")) and model or fallback
        end
        return models
    end
    if key == "koWeapons" then
        local weapons = {}
        for _, class in ipairs(istable(value) and value or {}) do
            if isstring(class) and class ~= "" and #weapons < 128 then
                weapons[#weapons + 1] = string.sub(class, 1, 128)
            end
        end
        return weapons
    end
    if WHITELIST_SETTINGS[key] then
        return KF.Sanitize.Apply(istable(value) and value or {}, WL_SCHEMA)
    end
    if key == "medVehicles" then return SanitizeMedVehicles(value) end
    if key == "staminaProfiles" then return SanitizeProfiles(value, KMS.StaminaProfileDefaults, KMS.StaminaProfileBounds) end
    if key == "damageProfiles" then return SanitizeProfiles(value, KMS.DamageProfileDefaults, KMS.DamageProfileBounds) end
    if isbool(default) then return value == true end
    if isnumber(default) then
        local bounds = KMS.SettingBounds[key]
        return KF.Sanitize.Clean.Number(value, default, bounds and bounds[1] or 0, bounds and bounds[2] or KMS.MaxCost, true)
    end
    local clean = string.sub(KF.Sanitize.Clean.String(value, default), 1, 64)
    if SETTING_ENUMS[key] and not table.HasValue(SETTING_ENUMS[key], clean) then return default end
    return clean
end

function KMS.ApplySettings(raw)
    local merged = table.Copy(KMS.DefaultSettings)
    for key in pairs(KMS.DefaultSettings) do
        if istable(raw) and raw[key] ~= nil then
            local clean = KMS.SanitizeSetting(key, raw[key])
            if clean ~= nil then merged[key] = clean end
        end
    end
    KMS.Settings = merged
    return merged
end

function KMS.Coef(key)
    return (KMS.Settings[key] or 100) / 100
end

KMS.NPCTypes = { "supply", "billing", "simulator", "exam" }
KMS.NPCs = KMS.NPCs or {}

KMS.FacilityTypes = { supply = true, simulator = true }
KMS.FacilityRangeSqr = 250 * 250

function KMS.MedVehicleEntry(class)
    return isstring(class) and KMS.Settings.medVehicles[string.lower(class)] or nil
end

function KMS.MedVehicleTemplate(class)
    local entry = KMS.MedVehicleEntry(class)
    if not entry then return nil end
    return entry.inv or KMS.Settings.medVehicleInvDefault
end

function KMS.IsMedVehicle(ent)
    return IsValid(ent) and ent:GetNWBool("kms_medvehicle", false)
end

function KMS.VehInvAccess(ply)
    if CLIENT then return IsValid(ply) and ply:GetNWBool("kms_vehaccess", false) end
    local mode = KMS.Settings.medVehicleAccess
    if mode == "everyone" then return true end
    if mode == "whitelist" then return AccessInfo(ply).vehwl == true end
    return KMS.MedicTier(ply) >= (mode == "doctor" and 2 or 1)
end

function KMS.InsideMedVehicle(ply)
    if ply:IsPlayer() and KMS.IsMedVehicle(KMS.VehicleBase(ply:GetVehicle())) then return true end
    return KMS.IsMedVehicle(ply:GetNWEntity("kms_loaded_in"))
end

function KMS.VehicleBase(ent)
    if not IsValid(ent) then return nil end
    local root = ent
    while IsValid(root:GetParent()) do
        root = root:GetParent()
    end
    if root:IsVehicle() or ent:IsVehicle() or root.IsSimfphyscar == true or root.LFS == true or root.LVS == true then
        return root
    end
    return nil
end

function KMS.SameVehicle(a, b)
    local root = KMS.VehicleBase(a:GetVehicle())
    if not IsValid(root) then return false end
    if b:IsPlayer() and KMS.VehicleBase(b:GetVehicle()) == root then return true end
    return b:GetNWEntity("kms_loaded_in") == root
end

function KMS.ClearSight(actor, target)
    local trace = util.TraceLine({
        start = actor:EyePos(),
        endpos = target:WorldSpaceCenter(),
        mask = MASK_SOLID_BRUSHONLY,
        filter = actor,
    })
    return not trace.Hit
end

KMS.NPCSchema = {
    id = { type = "identifier", maxLen = 64 },
    name = { type = "string", maxLen = 64, default = "" },
    model = { type = "string", maxLen = 260, default = "models/kleiner.mdl" },
    npcType = { type = "enum", values = KMS.NPCTypes, default = "supply" },
    whitelist = { type = "table", schema = WL_SCHEMA },
    healTime = { type = "number", min = 3, max = 120, integer = true, default = 10 },
    examTier = { type = "number", min = 1, max = 2, integer = true, default = 1 },
    rewardType = { type = "enum", values = KMS.ExamRewards, default = "tier" },
    rewardValue = { type = "string", maxLen = 128, default = "" },
    examQuestions = { type = "number", min = 3, max = 15, integer = true, default = 8 },
    examPass = { type = "number", min = 50, max = 100, integer = true, default = 70 },
    examSeconds = { type = "number", min = 0, max = 120, integer = true, default = 30 },
    examCooldown = { type = "number", min = 0, max = 86400, integer = true, default = 900 },
    examDifficulty = { type = "enum", values = KMS.StratagemDifficulties, default = "medium" },
    baseCost = { type = "number", min = 0, max = KMS.MaxCost, integer = true, default = 100 },
    woundCost = { type = "number", min = 0, max = KMS.MaxCost, integer = true, default = 25 },
    fractureCost = { type = "number", min = 0, max = KMS.MaxCost, integer = true, default = 100 },
    bloodCost = { type = "number", min = 0, max = KMS.MaxCost, integer = true, default = 200 },
    spawnMap = { type = "string", maxLen = 128, default = "" },
    spawnPos = {
        type = "table",
        schema = {
            x = { type = "number", default = 0 },
            y = { type = "number", default = 0 },
            z = { type = "number", default = 0 },
        },
    },
    spawnAng = {
        type = "table",
        schema = {
            p = { type = "number", default = 0 },
            y = { type = "number", default = 0 },
            r = { type = "number", default = 0 },
        },
    },
}

KMS.VehicleSchema = {
    id = { type = "identifier", maxLen = 64 },
    class = { type = "string", maxLen = 128, default = "" },
    map = { type = "string", maxLen = 128, default = "" },
    dupe = { type = "string", maxLen = 65536, default = "" },
    pos = {
        type = "table",
        schema = {
            x = { type = "number", default = 0 },
            y = { type = "number", default = 0 },
            z = { type = "number", default = 0 },
        },
    },
    ang = {
        type = "table",
        schema = {
            p = { type = "number", default = 0 },
            y = { type = "number", default = 0 },
            r = { type = "number", default = 0 },
        },
    },
}

function KMS.SanitizePlayer(raw)
    local record = { tier = 0, exams = {}, invs = {} }
    if not istable(raw) then return record end
    record.tier = KF.Sanitize.Clean.Number(raw.tier, 0, 0, 2, true)
    if istable(raw.exams) then
        local count = 0
        for id, readyAt in pairs(raw.exams) do
            if isstring(id) and count < 64 then
                record.exams[id] = KF.Sanitize.Clean.Number(readyAt, 0, 0, 2 ^ 31, true)
                count = count + 1
            end
        end
    end
    if istable(raw.invs) then
        local count = 0
        for id, inv in pairs(raw.invs) do
            if isstring(id) and istable(inv) and count < 32 then
                local clean = {}
                for itemId, amount in pairs(inv) do
                    if KMS.ItemById[itemId] then
                        clean[itemId] = KF.Sanitize.Clean.Number(amount, 0, 0, 999, true)
                    end
                end
                record.invs[id] = clean
                count = count + 1
            end
        end
    end
    return record
end

function KMS.SanitizeVehicle(raw)
    if not istable(raw) then return nil end
    local vehicle = KF.Sanitize.Apply(raw, KMS.VehicleSchema)
    if not vehicle or vehicle.id == "" or vehicle.class == "" then return nil end
    vehicle.inv = SanitizeLoadout(raw.inv)
    return vehicle
end

function KMS.SanitizeNPC(raw)
    if not istable(raw) then return nil end
    local npc = KF.Sanitize.Apply(raw, KMS.NPCSchema)
    if not npc or npc.id == "" then return nil end
    if npc.name == "" then npc.name = npc.id end
    npc.supplies = SanitizeLoadout(raw.supplies)
    npc.storage = SanitizeLoadout(raw.storage)
    return npc
end

function KMS.WhitelistTier(ply)
    if SERVER and IsValid(ply) and ply:IsPlayer() then return AccessInfo(ply).tier end
    if KMS.CheckWhitelist(ply, KMS.Settings.doctorWhitelist) then return 2 end
    if KMS.CheckWhitelist(ply, KMS.Settings.medicWhitelist) then return 1 end
    return 0
end

function KMS.MedicTier(ply)
    if KMS.Settings.medicMode == "everyone" then return 2 end
    return KMS.WhitelistTier(ply)
end

function KMS.BoostTier(tier, near)
    if KMS.Settings.locationsBoostTraining and tier < 2 and near then return tier + 1 end
    return tier
end

function KMS.TreatmentTier(id)
    local override = KMS.Settings.tierOverrides[id]
    if override ~= nil then return override end
    local def = KMS.TreatmentById[id]
    return def and def.tier or 0
end

function KMS.LoadoutFor(tier)
    if tier >= 2 then return KMS.Settings.loadoutDoctor end
    if tier >= 1 then return KMS.Settings.loadoutMedic end
    return KMS.Settings.loadoutDefault
end

function KMS.BloodClass(frac)
    if frac >= 0.85 then return 1 end
    if frac >= 0.7 then return 2 end
    if frac >= 0.6 then return 3 end
    return 4
end

function KMS.PainBand(pain)
    if pain >= 0.7 then return 3 end
    if pain >= 0.35 then return 2 end
    if pain >= 0.1 then return 1 end
    return 0
end

function KMS.PartHasOpenWound(partState)
    for _, wound in ipairs(partState and partState.wounds or {}) do
        if not wound.b then return true end
    end
    return false
end

function KMS.PartHasBleedingWound(partState)
    for _, wound in ipairs(partState and partState.wounds or {}) do
        if not wound.b and KMS.Wounds[wound.t].bleed > 0 then return true end
    end
    return false
end

function KMS.WoundScore(wound)
    return KMS.WoundFlow(wound) + wound.s
end

function KMS.PartHasBandagedWound(partState)
    for _, wound in ipairs(partState and partState.wounds or {}) do
        if wound.b then return true end
    end
    return false
end

function KMS.TreatmentAvailable(def, snapshot, partId)
    local part = KMS.PartById[partId]
    if not part then return false end
    if def.limbsOnly and not part.limb then return false end
    if def.torsoOnly and partId ~= "torso" then return false end
    if def.headOnly and partId ~= "head" then return false end
    local partState = snapshot and snapshot.parts and snapshot.parts[partId]
    if def.needsWound and not KMS.PartHasOpenWound(partState) then return false end
    if def.needsFracture and not (partState and partState.frac and not partState.splint) then return false end
    if def.healsFracture and not (partState and partState.frac) then return false end
    if def.needsTourniquet and not (partState and partState.tq) then return false end
    if def.id == "tourniquet" and partState and partState.tq then return false end
    if def.id == "cpr" then
        local states = snapshot and snapshot.states
        local offer = states and (states.arrest or (KMS.Settings.diagnosisMode == "examine" and states.conscious == false))
        if not offer then return false end
    end
    if def.id == "surgical" and not (partState and KMS.PartHasBandagedWound(partState) and not KMS.PartHasBleedingWound(partState)) then return false end
    return true
end

function KMS.TreatTime(def, tier, isSelf, baseOverride)
    local duration = (baseOverride or def.time) * KMS.Coef("treatTimeCoef")
    if def.needsWound then
        if isSelf then
            duration = duration + 4
        end
        if (tier or 0) >= 1 then
            duration = duration - 2
        end
        return math.max(2.25, duration)
    end
    return math.max(0.5, duration)
end

hook.Add("Move", "KMS_Mobility", function(ply, mv)
    local walk = ply:GetWalkSpeed()
    local cap
    local mobility = math.max(ply:GetNWInt("kms_mobility", 0), ply:GetNWInt("kms_stam_tier", 0))
    if mobility > 0 then
        cap = mobility == 2 and walk * 0.6 or math.min(walk, ply:GetRunSpeed() * 0.8)
    end
    local hauling = ply:GetNWString("kms_hauling", "")
    if hauling == "drag" then
        cap = math.min(cap or walk, walk)
    elseif hauling == "carry" then
        local jog = ply:GetRunSpeed() * 0.8
        cap = math.min(cap or jog, jog)
    end
    if ply:GetNWFloat("kms_stagger", 0) > CurTime() then
        cap = math.min(cap or walk, walk * 0.5)
    end
    if cap and mv:GetMaxClientSpeed() > cap then
        mv:SetMaxClientSpeed(cap)
        mv:SetMaxSpeed(cap)
    end
end)

hook.Add("SetupMove", "KMS_NoJump", function(ply, mv)
    if (ply:GetNWInt("kms_mobility", 0) == 2 or ply:GetNWInt("kms_stam_tier", 0) >= 1 or ply:GetNWString("kms_hauling", "") == "carry")
        and bit.band(mv:GetButtons(), IN_JUMP) ~= 0 then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    end
end)

local NOARMS_MASK = bit.bnot(bit.bor(IN_ATTACK, IN_ATTACK2, IN_RELOAD))
local ATTACK_MASK = bit.bnot(IN_ATTACK)

hook.Add("StartCommand", "KMS_NoArms", function(ply, cmd)
    if not ply:Alive() then return end
    local disarm = KMS.Settings.disarmEnabled and ply:GetNWBool("kms_noarms", false)
    local holster = KMS.Settings.holsterToTreat and ply:GetNWBool("kms_treatlock", false)
    if disarm or holster then
        cmd:SetButtons(bit.band(cmd:GetButtons(), NOARMS_MASK))
    end
    if ply:GetNWString("kms_hauling", "") ~= "" then
        cmd:SetButtons(bit.band(cmd:GetButtons(), ATTACK_MASK))
    end
end)

if CLIENT then
    KMS.StatusColors = {
        clear = Color(244, 241, 233),
        critical = Color(225, 88, 88),
        open = Color(255, 150, 60),
        treated = Color(90, 170, 255),
        warning = Color(255, 190, 50),
    }

    local function MenuIcon(name)
        local path = "medical_system/body/menu/" .. name .. ".png"
        if file.Exists("materials/" .. path, "GAME") then
            return Material(path, "smooth mips")
        end
    end

    KMS.MenuIcons = {
        triage = MenuIcon("triage-card"),
        examine = MenuIcon("examine-patient"),
        bandage = MenuIcon("bandage-fractures"),
        meds = MenuIcon("medication"),
        advanced = MenuIcon("advanced-threatments"),
        drag = MenuIcon("drag-n-carry"),
        toggle = MenuIcon("switch-menu"),
        config = MenuIcon("configuration"),
        inventory = MenuIcon("inventory"),
    }
    KMS.MenuIcons.interactions = KMS.MenuIcons.toggle

    local ITEM_ICON_FILES = {
        bandage_field = "field_dressing", bandage_packing = "compress", bandage_elastic = "elastic",
        bandage_quickclot = "quick_clot", tourniquet = "tourniquet", splint = "splint",
        morphine = "morphine", epinephrine = "ephinefrina", adenosine = "adenosine", painkillers = "painkiller",
        iv_saline = "saline", iv_saline_500 = "saline", iv_saline_1500 = "saline",
        iv_plasma = "plasma", iv_plasma_500 = "plasma", iv_plasma_250 = "plasma",
        iv_blood = "bloodbag", iv_blood_500 = "bloodbag", iv_blood_250 = "bloodbag",
        surgical_kit = "surgical_kit", pak = "personalaidkit",
    }
    KMS.ItemIconFiles = ITEM_ICON_FILES

    function KMS.ResolveItemIcon(id)
        local path = ITEM_ICON_FILES[id] and ("medical_system/medical_items/" .. ITEM_ICON_FILES[id] .. ".png")
        if not path or not file.Exists("materials/" .. path, "GAME") then
            path = "medical_system/body/items/" .. id .. ".png"
        end
        if file.Exists("materials/" .. path, "GAME") then
            return Material(path, "smooth mips")
        end
    end

    KMS.ItemIcons = {}
    for _, item in ipairs(KMS.Items) do
        KMS.ItemIcons[item.id] = KMS.ResolveItemIcon(item.id)
    end

    local UX = "kraken/sw_squadrons/ux/navigation/"

    KMS.Sounds = {
        Open = UX .. "navigation_activate_01.mp3",
        Close = UX .. "navigation_back_01.mp3",
        Hover = UX .. "navigation_slider_02.mp3",
        Click = UX .. "navigation_activate_01.mp3",
        Error = UX .. "navigation_error_01.mp3",
    }

    function KMS.PlaySound(key)
        local path = KMS.Sounds[key]
        if path then KF.Helpers.PlaySound(path) end
    end

    function KMS.DrawIcon(mat, x, y, w, h, color, shadowAlpha)
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)
        surface.SetMaterial(mat)
        if shadowAlpha then
            surface.SetDrawColor(0, 0, 0, shadowAlpha)
            surface.DrawTexturedRect(x + 1, y + 1, w, h)
        end
        surface.SetDrawColor(color)
        surface.DrawTexturedRect(x, y, w, h)
        render.PopFilterMin()
        render.PopFilterMag()
    end

    function KMS.Ellipsize(text, font, maxW, keepEnd)
        surface.SetFont(font)
        if surface.GetTextSize(text) <= maxW then return text end
        local ell = "..."
        local budget = maxW - surface.GetTextSize(ell)
        if budget <= 0 then return ell end
        local out = ""
        if keepEnd then
            for i = #text, 1, -1 do
                local nextStr = string.sub(text, i, i) .. out
                if surface.GetTextSize(nextStr) > budget then break end
                out = nextStr
            end
            return ell .. out
        end
        for i = 1, #text do
            local nextStr = out .. string.sub(text, i, i)
            if surface.GetTextSize(nextStr) > budget then break end
            out = nextStr
        end
        return out .. ell
    end

    -- Echoes of Clones Server-Design (grn_hud_v1): gelber Akzent, dunkle Panels, helle Haarlinien
    KMS.ThemeAccent = Color(255, 190, 50)
    local THEME = {
        Background     = Color(7, 9, 12, 240),
        BackgroundDark = Color(5, 7, 10, 250),
        Panel          = Color(8, 11, 15, 220),
        PanelDark      = Color(7, 9, 12, 235),
        PanelElevated  = Color(14, 18, 23, 235),
        PanelLight     = Color(20, 25, 31, 240),
        PanelHover     = Color(24, 29, 36, 245),
        Border         = Color(207, 216, 228, 38),
        BorderLight    = Color(207, 216, 228, 77),
        TextPrimary    = Color(244, 241, 233),
        TextBright     = Color(244, 241, 233),
        TextSecondary  = Color(216, 219, 225),
        TextMuted      = Color(157, 163, 173),
        TextDisabled   = Color(101, 107, 117),
        Success        = Color(74, 203, 130),
        Error          = Color(225, 88, 88),
        Warning        = Color(255, 150, 60),
        Info           = Color(90, 170, 255),
    }

    local function RegisterAppearance()
        if SYMUI then SYMUI.HookKraken() end -- SymChars-Design
        local palette = KF.UI.DefaultDarkPalette()
        for key, color in pairs(THEME) do
            palette[key] = Color(color.r, color.g, color.b, color.a)
        end
        KF.UI.SetTheme(AID, palette)
        KF.UI.ApplyAccentColor(AID, KMS.ThemeAccent)
        KF.Fonts.Register(AID, {
            prefix = "KMS",
            primary = "Roboto Condensed",
            secondary = "Roboto",
            accent = "Aurebesh",
            sizes = {
                display = 84, title = 48, header = 32, subheader = 24, body = 18,
                button = 20, small = 14, tiny = 12, stat = 16, price = 22,
            },
        })
        KF.Fonts.Create(AID)
    end

    RegisterAppearance()
    hook.Add("InitPostEntity", "KMS_Appearance", RegisterAppearance)
    hook.Add("OnScreenSizeChanged", "KMS_Appearance", RegisterAppearance)
end

function KMS.PartLabel(partId)
    return L("part_" .. partId)
end

function KMS.ItemLabel(itemId)
    return L("item_" .. itemId)
end

local ANTPERCENT = 0.8
local SIM_BODYMASS = 70
local JOULES_PER_ML_O2 = 20.9
local VO2MAX_STRENGTH = 4.1
local BIOMECH_EFFICIENCY = 0.23
local REE = 18.83
local RESPIRATORY_BUFFER = 60
local MUSCLE_TEAR_RATE = 0.00004
local MUSCLE_RECOVERY = 0.00000386
local AE1_RELEASE, AE2_RELEASE, AN_RELEASE = 13.3, 16.7, 113.3
local AE1_RECOVERY, AE2_RECOVERY, AN_RECOVERY = 6.60, 5.83, 56.70
local AE1_MAX, AE2_MAX, AN_MAX = 4000000, 84000, 2300
local VO2MAX = 55
local VO2_POWER = VO2MAX * SIM_BODYMASS * BIOMECH_EFFICIENCY * JOULES_PER_ML_O2 / 60
local PEAK_POWER = VO2MAX_STRENGTH * VO2_POWER
local TOTAL_RELEASE = AE1_RELEASE + AE2_RELEASE + AN_RELEASE
local AE1_POWER = PEAK_POWER / TOTAL_RELEASE * AE1_RELEASE * ANTPERCENT ^ 1.28 * 1.362
local AE2_POWER = PEAK_POWER / TOTAL_RELEASE * AE2_RELEASE * ANTPERCENT ^ 1.28 * 1.362
local AE_POWER = AE1_POWER + AE2_POWER
local AN_POWER = PEAK_POWER - AE_POWER
local AE_WATTS_PER_ATP = AE1_POWER / AE1_RELEASE
local AN_WATTS_PER_ATP = AN_POWER / AN_RELEASE
local RESP_DECAY = (RESPIRATORY_BUFFER - 1) / RESPIRATORY_BUFFER
local RESP_DIVISOR = 1 / (RESPIRATORY_BUFFER * 4.72 * VO2MAX)
local MAX_POWER_FATIGUE_RATIO = 0.057 / PEAK_POWER
local WALK_MPS, SPRINT_MPS = 1.9, 6
local GEAR_MASS = 15
local JUMP_ENERGY = 420

function KMS.HandlingPenalty(scale, ply)
    if not KMS.Settings.staminaEnabled then return 0 end
    ply = ply or (CLIENT and LocalPlayer())
    if not IsValid(ply) then return 0 end
    local coef = ply:GetNWFloat("kms_handling", 1)
    return math.Clamp((coef - 1) / 6, 0, 1) * KMS.Coef("weaponSway") * (scale or 1)
end

local function BaseWeapon(ply)
    local wep = IsValid(ply) and ply:GetActiveWeapon()
    if not IsValid(wep) then return nil end
    return wep
end

hook.Add("EntityFireBullets", "KMS_StaminaSpread", function(ent, data)
    if not KMS.Settings.staminaEnabled or not ent:IsPlayer() then return end
    local wep = BaseWeapon(ent)
    if wep and (wep.ARC9 or wep.ArcCW) then return end
    local penalty = KMS.HandlingPenalty(2, ent)
    if penalty <= 0.02 then return end
    data.Spread = data.Spread * (1 + penalty) + Vector(0.005, 0.005, 0) * penalty
    return true
end, HOOK_LOW)

local function IntegrationPenalty(enabledKey, wep, scale)
    if not KMS.Settings[enabledKey] then return 0 end
    local owner = wep.GetOwner and wep:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return 0 end
    return KMS.HandlingPenalty(scale, owner)
end

hook.Add("ARC9_SwayHook", "KMS_Stamina", function(wep, value)
    local penalty = IntegrationPenalty("arc9Integration", wep, 0.8)
    if penalty <= 0.02 then return end
    return (tonumber(value) or 1) * (1 + penalty)
end)

hook.Add("ARC9_SpreadHook", "KMS_Stamina", function(wep, value)
    local penalty = IntegrationPenalty("arc9Integration", wep, 0.25)
    if penalty <= 0.02 or not isnumber(value) then return end
    return value * (1 + penalty)
end)

hook.Add("ARC9_FreeAimRadiusHook", "KMS_Stamina", function(wep, value)
    local penalty = IntegrationPenalty("arc9Integration", wep, 0.3)
    if penalty <= 0.02 or not isnumber(value) then return end
    return value * (1 + penalty)
end)

hook.Add("ARC9_HoldBreathTimeHook", "KMS_Stamina", function(wep, value)
    local penalty = IntegrationPenalty("arc9Integration", wep, 0.5)
    if penalty <= 0.02 or not isnumber(value) or value <= 0 then return end
    return value / (1 + penalty)
end)

hook.Add("A_Hook_Add_Sway", "KMS_Stamina", function(wep, data)
    local penalty = IntegrationPenalty("arccwIntegration", wep, 1.2)
    if penalty <= 0.02 or not istable(data) then return end
    data.add = (data.add or 0) + penalty
end)

hook.Add("Hook_ModDispersion", "KMS_Stamina", function(wep, disp)
    local penalty = IntegrationPenalty("arccwIntegration", wep, 0.3)
    if penalty <= 0.02 or not isnumber(disp) then return end
    return disp * (1 + penalty)
end)

if SERVER then
    local function ProfileResolver(settingKey)
        local cache, sorted = {}, nil
        local resolver = {}
        function resolver.Get(ply)
            local cached = cache[ply]
            if cached and cached.until_ > CurTime() then return cached.profile end
            if not sorted then
                sorted = {}
                for id, profile in pairs(KMS.Settings[settingKey]) do
                    sorted[#sorted + 1] = { id = id, profile = profile }
                end
                table.sort(sorted, function(a, b)
                    if a.profile.priority ~= b.profile.priority then return a.profile.priority > b.profile.priority end
                    return a.id < b.id
                end)
            end
            local resolved
            for _, entry in ipairs(sorted) do
                if KMS.CheckWhitelist(ply, entry.profile.whitelist) then
                    resolved = entry.profile
                    break
                end
            end
            cache[ply] = { until_ = CurTime() + 10, profile = resolved }
            return resolved
        end
        function resolver.Refresh()
            sorted = nil
            cache = {}
        end
        function resolver.Clear(ply)
            cache[ply] = nil
        end
        return resolver
    end

    local staminaResolver = ProfileResolver("staminaProfiles")
    local damageResolver = ProfileResolver("damageProfiles")

    function KMS.StaminaProfile(ply)
        return staminaResolver.Get(ply)
    end

    function KMS.DamageProfile(ply)
        return damageResolver.Get(ply)
    end

    function KMS.RefreshDamageProfiles()
        damageResolver.Refresh()
    end

    local function ClearProfile(ply)
        staminaResolver.Clear(ply)
        damageResolver.Clear(ply)
    end

    hook.Add("OnPlayerChangedTeam", "KMS_StamProfile", ClearProfile)
    hook.Add("PlayerChangedUserGroup", "KMS_StamProfile", ClearProfile)
    hook.Add("CAMI.PlayerUsergroupChanged", "KMS_StamProfile", ClearProfile)
    hook.Add("PlayerDisconnected", "KMS_StamProfile", ClearProfile)

    local function NewStamina()
        return { ae1 = AE1_MAX, ae2 = AE2_MAX, an = AN_MAX, anFat = 0, dmg = 0, resp = 0, fatigue = 0 }
    end

    local function SetQuant(ply, key, value, step, default)
        value = math.Round(value / step) * step
        if math.abs(ply:GetNWFloat(key, default) - value) >= step * 0.5 then
            ply:SetNWFloat(key, value)
        end
    end

    function KMS.ResetStamina(ply)
        ply.KMSStam = nil
        if ply:GetNWInt("kms_stam_tier", 0) ~= 0 then ply:SetNWInt("kms_stam_tier", 0) end
        SetQuant(ply, "kms_exhaust", 0, 0.05, 0)
        SetQuant(ply, "kms_handling", 1, 0.05, 1)
    end

    function KMS.RestoreStamina(ply, frac)
        local s = ply.KMSStam
        if not s then return end
        s.ae1 = math.min(AE1_MAX, s.ae1 + AE1_MAX * frac)
        s.ae2 = math.min(AE2_MAX, s.ae2 + AE2_MAX * frac)
        s.an = math.min(AN_MAX, s.an + AN_MAX * frac)
        s.anFat = math.max(0, s.anFat - frac)
        s.resp = math.max(0, s.resp - frac)
        s.dmg = math.max(0, s.dmg - frac * 0.5)
    end

    function KMS.SyncAccess(ply)
        local exempt = KMS.Settings.enabled and KMS.Exempt(ply) or false
        ply:SetNWBool("kms_exempt", exempt)
        ply:SetNWBool("kms_medadmin", KMS.IsAdmin(ply))
        ply:SetNWBool("kms_vehaccess", KMS.VehInvAccess(ply))
        return exempt
    end

    function KMS.RefreshStamina()
        staminaResolver.Refresh()
        if KMS.Settings.staminaEnabled then return end
        for _, ply in ipairs(player.GetAll()) do
            KMS.ResetStamina(ply)
        end
    end

    local function HandlingCoef(ply, state, fatigue, profile)
        local stance
        if ply:Crouching() then
            stance = 1 + fatigue ^ 2 * 0.1
        else
            stance = 1 + fatigue ^ 2 * 2
        end
        local fracBase = 0
        if state and KMS.Settings.fractureMode ~= "disabled" then
            local perFrac, perSplint = 4 * KMS.Coef("fractureSway"), 2 * KMS.Coef("fractureSway")
            local splintPenalty = KMS.Settings.fractureMode ~= "splint_heal"
            for _, partId in ipairs({ "arm_l", "arm_r" }) do
                local partState = state.parts[partId]
                if partState.frac then
                    if not partState.splint then
                        fracBase = fracBase + perFrac
                    elseif splintPenalty then
                        fracBase = fracBase + perSplint
                    end
                end
            end
        end
        local painMult = 1 + 4 * (state and KMS.PerceivedPain(state) or 0) * KMS.Coef("painSway")
        local coef = math.max(stance, fracBase) * painMult * (100 / ((profile and profile.stability) or 100))
        return math.Clamp(coef, 1, 25)
    end

    function KMS.TickStamina(ply, dt)
        if not KMS.Settings.staminaEnabled then return end
        local s = ply.KMSStam
        if not s then
            s = NewStamina()
            ply.KMSStam = s
        end
        local profile = KMS.StaminaProfile(ply)
        local capMult = ((profile and profile.capacity) or 100) / 100 * KMS.Coef("staminaCapacity")
        local anMax = AN_MAX * capMult
        local ae2Max = AE2_MAX * capMult
        s.an = math.min(s.an, anMax)
        s.ae2 = math.min(s.ae2, ae2Max)

        local state = ply.KMSState
        local conscious = state == nil or (state.conscious and not state.arrest)

        local work = REE
        if conscious and ply:GetMoveType() == MOVETYPE_WALK and not IsValid(ply:GetVehicle())
            and (ply:OnGround() or ply:WaterLevel() >= 2) then
            local vel = ply:GetVelocity()
            local len = vel:Length()
            local walkRef = math.max(ply:GetWalkSpeed(), 1)
            local runRef = math.max(ply:GetRunSpeed(), walkRef)
            local speed
            if len <= walkRef or runRef <= walkRef then
                speed = math.min(len / walkRef, 1) * WALK_MPS
            else
                speed = WALK_MPS + math.min((len - walkRef) / (runRef - walkRef), 1) * (SPRINT_MPS - WALK_MPS)
            end
            if speed > 0.1 then
                local fwdAngle = math.deg(math.asin(math.Clamp(vel.z / math.max(1, len), -1, 1)))
                local gradient = math.abs(fwdAngle)
                if fwdAngle < 0 then gradient = gradient * 0.15 end
                gradient = gradient * 0.1
                local duty = 1
                if ply:WaterLevel() >= 2 and not ply:OnGround() then
                    duty = 6.5
                    gradient = 0
                elseif ply:Crouching() then
                    duty = 1.5
                end
                if state then
                    duty = duty * (1 + 0.1 * KMS.PerceivedPain(state))
                    duty = duty * (1 + (1 - state.blood / KMS.Settings.maxBlood) * KMS.Coef("bloodEndurance"))
                end
                if ply.KMSDragging and ply.KMSDragMode == "carry" then
                    duty = duty * 3
                end
                local gearMass = KMS.Settings.staminaEncumbrance and GEAR_MASS or 0
                local mass = SIM_BODYMASS + gearMass
                local loadTerm = (gearMass / SIM_BODYMASS) ^ 2
                if speed > 2 then
                    work = (2.1 * SIM_BODYMASS + 4 * mass * loadTerm + mass * (0.9 * speed * speed + 0.66 * speed * gradient)) * BIOMECH_EFFICIENCY * duty
                else
                    work = (1.05 * SIM_BODYMASS + 2 * mass * loadTerm + mass * (1.15 * speed * speed + 0.66 * speed * gradient)) * BIOMECH_EFFICIENCY * duty
                end
                work = math.max(work, REE)
                local drain = ((profile and profile.drain) or 100) / 100
                if speed > 2 then drain = drain * KMS.Coef("sprintDrain") end
                work = REE + (work - REE) * drain
            end
        end
        if s.jumpWork then
            work = work + s.jumpWork / dt
            s.jumpWork = nil
        end

        local oxygen = 1 - 0.131 * s.resp ^ 2
        local accum = KMS.Coef("fatigueAccum") * (100 / ((profile and profile.fatigueRes) or 100))
        local recovery = KMS.Coef("staminaRecovery") * (((profile and profile.recovery) or 100) / 100)
        if state then
            recovery = recovery * (1 - 0.4 * math.Clamp((math.abs(state.hr - 95) - 45) / 60, 0, 1))
        end

        s.dmg = s.dmg + (work / PEAK_POWER) ^ 3.2 * MUSCLE_TEAR_RATE * accum * dt
        s.dmg = math.Clamp(s.dmg - MUSCLE_RECOVERY * recovery * dt, 0, 1)
        local muscleFactor = math.sqrt(1 - s.dmg)

        local ae1Power = AE1_POWER * math.sqrt(s.ae1 / AE1_MAX) * oxygen * muscleFactor
        local ae2Power = AE2_POWER * math.sqrt(s.ae2 / ae2Max) * oxygen * muscleFactor
        local ae1Use = math.min(work, ae1Power)
        local ae2Use = math.min(work - ae1Use, ae2Power)
        local anUse = math.max(0, work - ae1Use - ae2Use)

        s.ae1 = math.max(0, s.ae1 - ae1Use / AE_WATTS_PER_ATP * dt)
        s.ae2 = math.max(0, s.ae2 - ae2Use / AE_WATTS_PER_ATP * dt)
        s.an = math.max(0, s.an - anUse / AN_WATTS_PER_ATP * dt)
        s.anFat = math.min(1, s.anFat + anUse * MAX_POWER_FATIGUE_RATIO * 1.1 * accum * dt)

        s.ae1 = math.min(s.ae1 + oxygen * recovery * AE1_RECOVERY * (AE1_POWER - ae1Use) / AE1_POWER * dt, AE1_MAX)
        s.ae2 = math.min(s.ae2 + oxygen * recovery * AE2_RECOVERY * (AE2_POWER - ae2Use) / AE2_POWER * dt, ae2Max)
        local aeSurplus = ae1Power + ae2Power - ae1Use - ae2Use
        local anScale = math.max(s.anFat, math.Clamp(1 - s.an / anMax, 0, 1) * 0.75) ^ 2
        s.an = math.Clamp(s.an + aeSurplus / VO2_POWER * AN_RECOVERY * recovery * anScale * dt, 0, anMax)
        s.anFat = math.Clamp(s.anFat - aeSurplus * MAX_POWER_FATIGUE_RATIO * recovery * s.anFat ^ 2 * dt, 0, 1)

        s.resp = s.resp * RESP_DECAY ^ dt
        local aeRatio = math.min(AE_POWER / math.max(1, ae1Power + ae2Power), 2)
        s.resp = math.min(s.resp + work * RESP_DIVISOR * aeRatio * dt, 1)

        local aePct = (s.ae1 / AE1_MAX + s.ae2 / ae2Max) / 2
        local anPct = s.an / anMax
        local fatigue = 1 - math.min(aePct, anPct)
        s.fatigue = fatigue

        local tier = ply:GetNWInt("kms_stam_tier", 0)
        if not conscious then
            tier = 0
        elseif tier == 2 then
            if fatigue < 0.7 then tier = fatigue > 0.6 and 1 or 0 end
        elseif tier == 1 then
            if fatigue >= 1 then tier = 2 elseif fatigue < 0.6 then tier = 0 end
        else
            if fatigue >= 1 then tier = 2 elseif fatigue > 0.7 then tier = 1 end
        end
        if ply:GetNWInt("kms_stam_tier", 0) ~= tier then
            ply:SetNWInt("kms_stam_tier", tier)
        end

        SetQuant(ply, "kms_exhaust", fatigue, 0.05, 0)
        SetQuant(ply, "kms_handling", conscious and HandlingCoef(ply, state, fatigue, profile) or 1, 0.05, 1)
    end

    function KMS.StaminaState(ply)
        if not ply.KMSStam and KMS.Settings.staminaEnabled then
            KMS.TickStamina(ply, 0.5)
        end
        return ply.KMSStam
    end

    hook.Add("KeyPress", "KMS_StamJump", function(ply, key)
        if key ~= IN_JUMP or not KMS.Settings.staminaEnabled then return end
        if not ply:OnGround() or ply:GetMoveType() ~= MOVETYPE_WALK then return end
        local s = ply.KMSStam
        if s then s.jumpWork = (s.jumpWork or 0) + JUMP_ENERGY end
    end)

    hook.Add("PlayerSpawn", "KMS_StamSpawn", function(ply)
        KMS.ResetStamina(ply)
    end)
end

if CLIENT then
    local swayPhase = 0

    hook.Add("CalcView", "KMS_StamSway", function(ply, pos, angles, fov)
        if not KMS.Settings.staminaEnabled then return end
        if not IsValid(ply) or not ply:Alive() or KMS.IsDowned(ply) then return end
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and (wep.ARC9 or wep.ArcCW) then return end
        local exhaust = ply:GetNWFloat("kms_exhaust", 0)
        local amp = KMS.HandlingPenalty(0.3) + exhaust * exhaust * 1.1
        if amp < 0.02 then return end
        swayPhase = swayPhase + KF.Anim.GetFrameTime() * (0.9 + amp)
        angles.p = angles.p + math.sin(swayPhase * math.pi * 2) * amp * 0.9
        angles.y = angles.y + math.sin(swayPhase * math.pi * 1.3) * amp * 0.7
    end)
end
