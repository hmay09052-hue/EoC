BattleGrid.FactionList = BattleGrid.FactionList or {}

local CLASS_PREFIX = { helix = "ix_class", nutscript = "ns_class" }
local FACTION_PREFIX = { helix = "ix_faction", nutscript = "ns_faction" }

function BattleGrid:GetFramework()
    local fw = KF.Integrations.DetectFramework()
    if fw == "sandbox" then return "unknown" end
    return fw
end

local function idFromPrefixed(prefix, jid)
    local tag = prefix .. ":"
    if string.StartsWith(jid, tag) then return string.sub(jid, #tag + 1) end
    return nil
end

local function CollectFrameworkGroups(fw)
    local jobsByFaction = {}
    for _, cls in ipairs(KF.Integrations.GetClasses()) do
        local key = cls.faction
        jobsByFaction[key] = jobsByFaction[key] or {}
        table.insert(jobsByFaction[key], {
            id = CLASS_PREFIX[fw] .. ":" .. (cls.uniqueID or tostring(cls.id)),
            name = cls.name or cls.uniqueID or BattleGrid:L("FACTION_JOB_UNKNOWN"),
        })
    end

    local groups = {}
    for _, faction in ipairs(KF.Integrations.GetFactions()) do
        local jobs = { {
            id = FACTION_PREFIX[fw] .. ":" .. (faction.uniqueID or tostring(faction.index)),
            name = BattleGrid:L("FACTION_ENTIRE"),
        } }
        for _, job in ipairs(jobsByFaction[faction.index] or {}) do
            table.insert(jobs, job)
        end
        table.insert(groups, { name = faction.name, jobs = jobs })
    end
    return groups
end

function BattleGrid:GetFrameworkJobs()
    local fw = self:GetFramework()

    if fw == "darkrp" then
        local categoryMap = {}
        for _, job in ipairs(RPExtraTeams or {}) do
            local cat = job.category or BattleGrid:L("FACTION_CATEGORY_OTHER")
            categoryMap[cat] = categoryMap[cat] or {}
            table.insert(categoryMap[cat], {
                id = job.command or tostring(job.team),
                name = job.name or job.command or BattleGrid:L("FACTION_JOB_UNKNOWN"),
            })
        end
        local groups = {}
        for cat, jobs in SortedPairs(categoryMap) do
            table.insert(groups, { name = cat, jobs = jobs })
        end
        return groups
    elseif CLASS_PREFIX[fw] then
        return CollectFrameworkGroups(fw)
    end

    return {}
end

function BattleGrid:PlayerMatchesJobList(ply, jobList)
    if not IsValid(ply) or not jobList or #jobList == 0 then return false end

    local fw = self:GetFramework()

    if fw == "darkrp" then
        local teamID = ply:Team()
        local rpCommandMap = {}
        for _, rpJob in ipairs(RPExtraTeams or {}) do
            if rpJob.command then rpCommandMap[rpJob.command] = rpJob.team end
        end
        for _, jid in ipairs(jobList) do
            if jid == tostring(teamID) or rpCommandMap[jid] == teamID then return true end
        end
    elseif CLASS_PREFIX[fw] then
        local accessors = KF.Integrations.GetAccessors(fw)
        local char = accessors.getChar and accessors.getChar(ply)
        if not char then return false end

        local factionIdx = accessors.getFaction and accessors.getFaction(char)
        local factionData = factionIdx and accessors.factionData and accessors.factionData(factionIdx)
        local factionID = factionData and factionData.uniqueID

        local classIdx = accessors.getClass and accessors.getClass(char)
        local classData = classIdx and accessors.classData and accessors.classData(classIdx)
        local classID = classData and classData.uniqueID

        for _, jid in ipairs(jobList) do
            local fid = idFromPrefixed(FACTION_PREFIX[fw], jid)
            if fid and (fid == factionID or fid == tostring(factionIdx)) then return true end

            local cid = idFromPrefixed(CLASS_PREFIX[fw], jid)
            if cid and (cid == classID or cid == tostring(classIdx)) then return true end
        end
    end

    return false
end

function BattleGrid:GetPlayerFaction(ply)
    if not IsValid(ply) or not self:IsFactionSystemEnabled() then return nil end
    for _, faction in ipairs(self.FactionList) do
        if self:PlayerMatchesJobList(ply, faction.jobs) then return faction end
    end
    return nil
end

function BattleGrid:SameFaction(ply1, ply2)
    if not self:IsFactionSystemEnabled() then return true end
    local f1 = self:GetPlayerFaction(ply1)
    local f2 = self:GetPlayerFaction(ply2)
    if not f1 or not f2 then return true end
    return f1.id == f2.id
end

function BattleGrid:GetFactionByID(id)
    for _, f in ipairs(self.FactionList) do
        if f.id == id then return f end
    end
    return nil
end

local function StringList(list)
    local out = {}
    for _, v in ipairs(istable(list) and list or {}) do
        if isstring(v) then out[#out + 1] = v end
    end
    return out
end

local function ReloadFactions()
    local data = util.JSONToTable(BattleGrid:GetConfig("factions_data")) or {}
    BattleGrid.FactionList = {}
    for _, f in ipairs(data) do
        if istable(f) and isstring(f.id) and f.id ~= "" and isstring(f.name) and f.name ~= "" then
            local c = istable(f.color) and f.color or {}
            table.insert(BattleGrid.FactionList, {
                id    = f.id,
                name  = f.name,
                desc  = isstring(f.desc) and f.desc or "",
                icon  = isstring(f.icon) and f.icon or "",
                color = Color(
                    math.Clamp(tonumber(c.r) or 255, 0, 255),
                    math.Clamp(tonumber(c.g) or 255, 0, 255),
                    math.Clamp(tonumber(c.b) or 255, 0, 255)),
                jobs  = StringList(f.jobs),
                npcs  = StringList(f.npcs),
            })
        end
    end
    hook.Run("BattleGrid.FactionsUpdated")
end

if SERVER then
    BattleGrid.ConfigValidators.factions_data = function(json)
        local factions = util.JSONToTable(json)
        if not istable(factions) or #factions > 20 then return false end
        for _, f in ipairs(factions) do
            if not istable(f) or not isstring(f.id) or #f.id < 1 or #f.id > 32 then return false end
            if not isstring(f.name) or #f.name < 1 or #f.name > 64 then return false end
            if f.desc ~= nil and (not isstring(f.desc) or #f.desc > 256) then return false end
            if f.jobs ~= nil and (not istable(f.jobs) or #f.jobs > 100) then return false end
            if f.npcs ~= nil and (not istable(f.npcs) or #f.npcs > 50) then return false end
        end
        return true
    end

    local function ClearOrphanedFactionRefs()
        for _, cp in ipairs(BattleGrid.ServerCommandPosts or {}) do
            if cp.owner ~= "" and not BattleGrid:GetFactionByID(cp.owner) then
                cp.owner = ""
                cp.state = BattleGrid.CPState.NEUTRAL
                cp.ticks = 0
                cp.attacker = ""
            end
        end
        BattleGrid:ForEachMarkerType(function(def)
            for _, item in ipairs(def.list) do
                if item.faction_id and item.faction_id ~= "" and not BattleGrid:GetFactionByID(item.faction_id) then
                    item.faction_id = ""
                    if BattleGrid:ShouldPersistState(item.state) then def.save(item) end
                end
            end
        end)
    end

    hook.Add("BattleGrid.ConfigUpdated", "BattleGrid.Factions", function()
        ReloadFactions()
        ClearOrphanedFactionRefs()
        timer.Create("BattleGrid.FactionResync", 1, 1, function()
            BattleGrid:BroadcastMarkers()
            BattleGrid:BroadcastCommandPosts()
        end)
    end)

    local function ResyncPlayerMarkers(ply)
        timer.Simple(0, function()
            if IsValid(ply) and BattleGrid:IsFactionSystemEnabled() then BattleGrid:BroadcastMarkers(ply) end
        end)
    end

    hook.Add("OnPlayerChangedTeam", "BattleGrid.Factions.JobChange", ResyncPlayerMarkers)
    hook.Add("PlayerLoadedCharacter", "BattleGrid.Factions.JobChange", ResyncPlayerMarkers)
    hook.Add("PlayerJoinedClass", "BattleGrid.Factions.JobChange", ResyncPlayerMarkers)
    hook.Add("PlayerLoadedChar", "BattleGrid.Factions.JobChange", ResyncPlayerMarkers)
    return
end

hook.Add("BattleGrid.ConfigUpdated", "BattleGrid.Factions", ReloadFactions)

local S = KF.Scale
local _cachedFaction, _cachedFrame = nil, 0

function BattleGrid:GetLocalFaction()
    if not self:IsFactionSystemEnabled() then return nil end
    local frame = FrameNumber()
    if frame ~= _cachedFrame then
        _cachedFaction = self:GetPlayerFaction(LocalPlayer())
        _cachedFrame = frame
    end
    return _cachedFaction
end

function BattleGrid:ShouldShowPlayer(other)
    return self:SameFaction(LocalPlayer(), other)
end

function BattleGrid:DrawFactionHUD(w, h)
    if not self:IsFactionSystemEnabled() then return end
    if #self.FactionList >= 2 and self:IsCPSystemEnabled() then return end
    local faction = self:GetLocalFaction()
    if not faction then return end

    local accent = BattleGrid.C("Accent")
    local pad = S(16)
    local iconSize = S(24)

    surface.SetFont(BattleGrid.F("small"))
    local textW = surface.GetTextSize(faction.name)
    local boxW = math.max(iconSize, textW) + pad * 2
    local boxH = iconSize + S(22)
    local boxX = w - pad - boxW
    local boxY = pad - 4

    draw.RoundedBox(4, boxX, boxY, boxW, boxH, KF.UI.ColorAlpha(BattleGrid.C("PanelDark"), 180))

    local iconX = boxX + (boxW - iconSize) / 2
    local iconY = pad

    if faction.icon ~= "" then
        BattleGrid:DrawIcon(faction.icon, iconX, iconY, iconSize, iconSize, faction.color)
    else
        surface.SetDrawColor(faction.color)
        draw.NoTexture()
        BattleGrid:DrawCircle(iconX + iconSize / 2, iconY + iconSize / 2, iconSize / 3, 12)
    end

    draw.SimpleText(faction.name, BattleGrid.F("small"), boxX + boxW / 2, iconY + iconSize + S(4), faction.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function BattleGrid:GetServerNPCs()
    local categoryMap = {}
    for class, data in pairs(list.Get("NPC") or {}) do
        local cat = data.Category or BattleGrid:L("FACTION_CATEGORY_OTHER")
        if cat:sub(1, 1) == "#" then
            cat = language.GetPhrase(cat:sub(2)) or cat
        end
        categoryMap[cat] = categoryMap[cat] or {}
        table.insert(categoryMap[cat], { id = class, name = data.Name or class })
    end
    local groups = {}
    for cat, npcs in SortedPairs(categoryMap) do
        table.sort(npcs, function(a, b) return a.name < b.name end)
        table.insert(groups, { name = cat, npcs = npcs })
    end
    return groups
end
