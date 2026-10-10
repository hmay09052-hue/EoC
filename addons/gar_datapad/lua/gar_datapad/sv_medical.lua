--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Live-Patientendaten aus Kraken's Medical System
    Ohne Kraken's Medical werden nur Leben und Ruestung gezeigt.
-------------------------------------------------------------------------------------------------------------]]

local function KMS() return KrakensMedical end

local function PartInfo(state)
    local parts = {}
    for id, part in pairs(state.parts or {}) do
        local open, bandaged, worst = 0, 0, 0
        for _, wound in ipairs(part.wounds or {}) do
            local n = tonumber(wound.n) or 1
            if wound.b then bandaged = bandaged + n else open = open + n end
            worst = math.max(worst, tonumber(wound.s) or 1)
        end
        parts[#parts + 1] = { id = id, open = open, bandaged = bandaged, worst = worst, frac = part.frac == true, splint = part.splint == true, tq = part.tq == true }
    end
    return parts
end

local function Snapshot(ply, viewer)
    local char = GAR_DP.Char(ply)
    local entry = {
        key = ply:EntIndex(),
        charID = char and char:GetID() or 0,
        name = char and symchars.utils.BuildDisplayName(char) or ply:Nick(),
        unit = char and char:GetFaction() and char:GetFaction().name or "",
        hp = ply:Health(), maxhp = ply:GetMaxHealth(), armor = ply:Armor(), alive = ply:Alive(),
        dist = math.floor(viewer:GetPos():Distance(ply:GetPos()) / 39.37),
    }

    local K = KMS()
    local state = ply.KMSState
    if K and state then
        local maxBlood = (K.Settings and K.Settings.maxBlood) or 6000
        entry.kms = true
        entry.blood = math.Round((state.blood or maxBlood) / maxBlood * 100)
        entry.hr = math.Round(state.hr or 0)
        entry.spo2 = math.Round(state.spo2 or 0)
        entry.pain = math.Round((state.pain or 0) * 100) / 100
        entry.conscious = state.conscious ~= false
        entry.arrest = state.arrest == true
        entry.triage = tonumber(state.triage) or ply:GetNWInt("kms_triage", 0)
        if K.ComputeBP then
            local ok, sys, dia = pcall(K.ComputeBP, state)
            if ok then entry.bp = sys .. "/" .. dia end
        end
        if K.BleedRate then
            local ok, rate = pcall(K.BleedRate, state)
            if ok then entry.bleed = math.Round(tonumber(rate) or 0, 1) end
        end
        local call = ply:GetNWFloat("kms_medcall", 0)
        if call > 0 then entry.medcall = math.floor(CurTime() - call) end
        entry.parts = PartInfo(state)
    end
    return entry
end

-- Anzahl Notrufe und bewusstlose Spieler (fuer die Startseite)
function GAR_DP.MedicalCounts()
    local calls, downed = 0, 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetNWFloat("kms_medcall", 0) > 0 then calls = calls + 1 end
        if ply.KMSState and ply.KMSState.conscious == false then downed = downed + 1 end
    end
    return calls, downed
end

GAR_DP.Handle("med_scan", function(ply)
    if not GAR_DP.CanUse(ply, "medical") then return false, "Nur Sanitaeter" end
    local list = {}
    for _, target in ipairs(player.GetAll()) do
        if GAR_DP.Char(target) or target:Alive() then list[#list + 1] = Snapshot(target, ply) end
    end
    return true, { kms = KMS() ~= nil, patients = list }
end)
