if not SERVER then return end

GRN_DEFCON = GRN_DEFCON or {}

local C = GRN_DEFCON.Config
local NET_SYNC = "GRN_Defcon_Sync"
local NET_REQUEST = "GRN_Defcon_Request"
local NET_OPEN_SETTINGS = "GRN_Defcon_OpenSettings"
local NET_TERMINAL_DATA = "GRN_Defcon_TerminalData"
local NET_TERMINAL_ACTION = "GRN_Defcon_TerminalAction"
local DATA_LEVEL_FILE = "grn_defcon/level.txt"
local DATA_CUSTOM_FILE = tostring(C.CustomLevelsDataFile or "grn_defcon/custom_levels.json")
local GLOBAL_LEVEL_KEY = "GRN_Defcon_CurrentLevel"

util.AddNetworkString(NET_SYNC)
util.AddNetworkString(NET_REQUEST)
util.AddNetworkString(NET_OPEN_SETTINGS)
util.AddNetworkString(NET_TERMINAL_DATA)
util.AddNetworkString(NET_TERMINAL_ACTION)

local function TrimText(value, maximum)
    local text = string.Trim(tostring(value or ""))
    if #text > maximum then
        text = string.sub(text, 1, maximum)
    end
    return text
end

local function NormalizeHexColor(value)
    local color = string.upper(TrimText(value, 7))
    if not string.match(color, "^#%x%x%x%x%x%x$") then
        return "#55B8FF"
    end
    return color
end

local function HexToRGB(hex)
    hex = string.gsub(hex or "", "#", "")
    return tonumber(string.sub(hex, 1, 2), 16) or 85,
        tonumber(string.sub(hex, 3, 4), 16) or 184,
        tonumber(string.sub(hex, 5, 6), 16) or 255
end

local function BuildGlow(hex)
    local r, g, b = HexToRGB(hex)
    return string.format("rgba(%d, %d, %d, .30)", r, g, b)
end

local function NormalizeLevelID(value)
    local id = math.floor(tonumber(value) or -1)
    local maximum = math.max(1, math.floor(tonumber(C.MaximumLevelID) or 999))
    if id < 1 or id > maximum then return nil end
    return id
end

local function NormalizeLevelData(id, source, custom)
    source = istable(source) and source or {}
    local color = NormalizeHexColor(source.Color or source.color)

    return {
        ID = id,
        Name = TrimText(source.Name or source.name or "UNNAMED", 48),
        State = TrimText(source.State or source.state or "CUSTOM SECURITY STATE", 64),
        Short = TrimText(source.Short or source.short or "CUSTOM DEFCON", 64),
        Description = TrimText(source.Description or source.description or "Custom DEFCON level.", 240),
        Color = color,
        Glow = BuildGlow(color),
        Custom = custom == true
    }
end

local function BuildBaseLevels()
    local levels = {}
    for rawID, rawData in pairs(C.Levels or {}) do
        local id = NormalizeLevelID(rawID)
        if id then
            levels[id] = NormalizeLevelData(id, rawData, false)
        end
    end
    return levels
end

local BaseLevels = BuildBaseLevels()
local CustomLevels = {}
GRN_DEFCON.Levels = {}

local function RebuildLevels()
    local merged = {}
    for id, data in pairs(BaseLevels) do
        merged[id] = table.Copy(data)
    end
    for id, data in pairs(CustomLevels) do
        merged[id] = table.Copy(data)
    end
    GRN_DEFCON.Levels = merged
end

local function CountCustomLevels()
    local count = 0
    for _ in pairs(CustomLevels) do count = count + 1 end
    return count
end

local function LoadCustomLevels()
    CustomLevels = {}
    if not file.Exists(DATA_CUSTOM_FILE, "DATA") then
        RebuildLevels()
        return
    end

    local decoded = util.JSONToTable(file.Read(DATA_CUSTOM_FILE, "DATA") or "")
    if not istable(decoded) then
        RebuildLevels()
        return
    end

    for rawID, rawData in pairs(decoded) do
        local id = NormalizeLevelID(rawID)
        if id and not BaseLevels[id] and istable(rawData) then
            CustomLevels[id] = NormalizeLevelData(id, rawData, true)
        end
    end

    RebuildLevels()
end

local function SaveCustomLevels()
    local serializable = {}
    for id, data in pairs(CustomLevels) do
        serializable[tostring(id)] = {
            Name = data.Name,
            State = data.State,
            Short = data.Short,
            Description = data.Description,
            Color = data.Color
        }
    end

    file.CreateDir("grn_defcon")
    file.Write(DATA_CUSTOM_FILE, util.TableToJSON(serializable, true))
end

LoadCustomLevels()

function GRN_DEFCON.GetLevelData(level)
    local id = NormalizeLevelID(level)
    return id and GRN_DEFCON.Levels[id] or nil
end

function GRN_DEFCON.GetSortedLevels()
    local result = {}
    for id, data in pairs(GRN_DEFCON.Levels or {}) do
        local copy = table.Copy(data)
        copy.ID = id
        result[#result + 1] = copy
    end
    table.sort(result, function(a, b)
        return tonumber(a.ID) > tonumber(b.ID)
    end)
    return result
end

local function GetDefaultLevel()
    local configured = NormalizeLevelID(C.DefaultLevel)
    if configured and GRN_DEFCON.Levels[configured] then return configured end

    for id in pairs(GRN_DEFCON.Levels) do
        return id
    end

    return 1
end

local function LoadSavedLevel()
    if not C.PersistLevel or not file.Exists(DATA_LEVEL_FILE, "DATA") then
        return GetDefaultLevel()
    end

    local saved = NormalizeLevelID(file.Read(DATA_LEVEL_FILE, "DATA"))
    if saved and GRN_DEFCON.Levels[saved] then return saved end
    return GetDefaultLevel()
end

local function SaveLevel(level)
    if not C.PersistLevel then return end
    file.CreateDir("grn_defcon")
    file.Write(DATA_LEVEL_FILE, tostring(level))
end

GRN_DEFCON.CurrentLevel = LoadSavedLevel()
SetGlobalInt(GLOBAL_LEVEL_KEY, GRN_DEFCON.CurrentLevel)

local function GetActorName(actor)
    if not IsValid(actor) then return "SERVER CONSOLE" end
    return actor:Nick()
end

local function IsGroupAllowed(player, groups)
    if not IsValid(player) then return true end
    if player:IsSuperAdmin() then return true end
    local group = string.lower(player:GetUserGroup() or "")
    return istable(groups) and groups[group] == true
end

local function CheckPermission(player, privilege, groups, callback)
    if not IsValid(player) then
        callback(true)
        return
    end

    local fallbackAllowed = IsGroupAllowed(player, groups)
    if not C.UseCAMI or not CAMI or not CAMI.PlayerHasAccess then
        callback(fallbackAllowed)
        return
    end

    CAMI.PlayerHasAccess(player, privilege, function(hasAccess)
        callback(hasAccess == true or fallbackAllowed)
    end)
end

function GRN_DEFCON.CheckChangePermission(player, callback)
    CheckPermission(player, C.CAMIPrivilege, C.AllowedUsergroups, callback)
end

function GRN_DEFCON.CheckManagePermission(player, callback)
    CheckPermission(player, C.ManageCAMIPrivilege, C.ManagementUsergroups, callback)
end

local function RegisterCAMIPrivileges()
    if not C.UseCAMI or not CAMI or not CAMI.RegisterPrivilege then return end

    CAMI.RegisterPrivilege({
        Name = C.CAMIPrivilege,
        MinAccess = "admin",
        Description = "Allows staff to change the synchronized GRN DEFCON level."
    })

    CAMI.RegisterPrivilege({
        Name = C.ManageCAMIPrivilege,
        MinAccess = "superadmin",
        Description = "Allows staff to create, edit and delete custom GRN DEFCON levels."
    })
end

hook.Add("Initialize", "GRN_Defcon_RegisterCAMI", function()
    timer.Simple(0, RegisterCAMIPrivileges)
end)

local function SendFeedback(player, message)
    if IsValid(player) then
        player:ChatPrint("[GRN DEFCON] " .. message)
    else
        MsgC(Color(217, 170, 61), "[GRN DEFCON] ", color_white, message .. "\n")
    end
end

local function SendState(target, announce, actorName)
    local level = GRN_DEFCON.CurrentLevel or GetDefaultLevel()
    local data = GRN_DEFCON.GetLevelData(level) or {}

    net.Start(NET_SYNC)
        net.WriteUInt(level, 16)
        net.WriteBool(announce == true)
        net.WriteString(actorName or "")
        net.WriteString(util.TableToJSON(data) or "{}")

    if IsValid(target) then net.Send(target) else net.Broadcast() end
end

function GRN_DEFCON.SetLevel(level, actor)
    local id = NormalizeLevelID(level)
    local levelData = id and GRN_DEFCON.GetLevelData(id) or nil
    if not id or not levelData then
        return false, "That DEFCON level does not exist."
    end

    local changed = GRN_DEFCON.CurrentLevel ~= id
    GRN_DEFCON.CurrentLevel = id
    SetGlobalInt(GLOBAL_LEVEL_KEY, id)
    SaveLevel(id)

    local actorName = GetActorName(actor)
    SendState(nil, changed, actorName)

    timer.Simple(0.20, function()
        if GRN_DEFCON.CurrentLevel == id then
            SendState(nil, false, "")
        end
    end)

    if changed and C.BroadcastChatMessage then
        local suffix = C.ShowChangedBy and (" by " .. actorName) or ""
        PrintMessage(HUD_PRINTTALK, string.format(
            "[GRN DEFCON] Level changed to DEFCON %d - %s%s.",
            id,
            levelData.Name or "UNKNOWN",
            suffix
        ))
    end

    return true, changed and ("DEFCON changed to " .. id .. ".") or ("DEFCON is already set to " .. id .. ".")
end

local function HandleCommand(player, argument)
    GRN_DEFCON.CheckChangePermission(player, function(allowed)
        if not allowed then
            SendFeedback(player, "You do not have permission to change DEFCON.")
            return
        end

        local id = NormalizeLevelID(argument)
        if not id or not GRN_DEFCON.GetLevelData(id) then
            SendFeedback(player, "Usage: " .. C.ChatCommand .. " <existing level>")
            return
        end

        local _, message = GRN_DEFCON.SetLevel(id, player)
        SendFeedback(player, message or "DEFCON updated.")
    end)
end

local function ValidateTerminalAccess(player)
    if not IsValid(player) then return false end
    if player.GRN_DefconRemoteAccess then return true end
    local terminal = player.GRN_DefconTerminal
    if not IsValid(terminal) or terminal:GetClass() ~= "grn_defcon_terminal" then return false end

    local useDistance = tonumber((C.Terminal or {}).UseDistance) or 155
    if player:GetPos():DistToSqr(terminal:GetPos()) > math.pow(useDistance + 48, 2) then
        return false
    end

    player.GRN_DefconTerminalAccessUntil = CurTime() + 20
    return true
end

local function SendTerminalData(player, canChange, canManage, message, messageType)
    if not IsValid(player) then return end

    net.Start(NET_TERMINAL_DATA)
        net.WriteUInt(GRN_DEFCON.CurrentLevel or GetDefaultLevel(), 16)
        net.WriteBool(canChange == true)
        net.WriteBool(canManage == true)
        net.WriteString(util.TableToJSON(GRN_DEFCON.GetSortedLevels()) or "[]")
        net.WriteString(tostring(message or ""))
        net.WriteUInt(math.Clamp(tonumber(messageType) or 0, 0, 3), 2)
    net.Send(player)
end

local function RefreshTerminalForPlayer(player, message, messageType)
    GRN_DEFCON.CheckChangePermission(player, function(canChange)
        if not IsValid(player) then return end
        GRN_DEFCON.CheckManagePermission(player, function(canManage)
            if not IsValid(player) then return end
            SendTerminalData(player, canChange, canManage, message, messageType)
        end)
    end)
end

function GRN_DEFCON.OpenTerminal(player, terminal)
    if not IsValid(player) or not player:IsPlayer() then return end
    if not IsValid(terminal) or terminal:GetClass() ~= "grn_defcon_terminal" then return end

    local useDistance = tonumber((C.Terminal or {}).UseDistance) or 155
    if player:GetPos():DistToSqr(terminal:GetPos()) > math.pow(useDistance + 32, 2) then return end

    player.GRN_DefconTerminal = terminal
    player.GRN_DefconRemoteAccess = false
    player.GRN_DefconTerminalAccessUntil = CurTime() + 20
    RefreshTerminalForPlayer(player)
end

-- Opens the DEFCON system without a terminal (e.g. via /defcon).
-- Changing levels and staff actions still check the normal permissions.
function GRN_DEFCON.OpenMenu(player)
    if not IsValid(player) or not player:IsPlayer() then return end
    player.GRN_DefconTerminal = nil
    player.GRN_DefconRemoteAccess = true
    RefreshTerminalForPlayer(player)
end

hook.Add("PlayerSay", "GRN_Defcon_ChatCommand", function(player, text)
    local rawText = string.Trim(text or "")
    local loweredText = string.lower(rawText)
    local settingsCommand = string.lower(string.Trim(C.SettingsChatCommand or "/defconsettings"))
    local settingsWithoutSlash = string.Trim(string.gsub(settingsCommand, "^/", ""))

    if loweredText == settingsCommand or loweredText == settingsWithoutSlash then
        net.Start(NET_OPEN_SETTINGS)
        net.Send(player)
        return ""
    end

    local configuredCommand = string.Trim(C.ChatCommand or "/defcon")
    local loweredCommand = string.lower(configuredCommand)
    if loweredText ~= loweredCommand and not string.StartWith(loweredText, loweredCommand .. " ") then return end

    local argument = string.Trim(string.sub(rawText, #configuredCommand + 1))
    if argument == "" and C.CommandOpensMenu ~= false then
        GRN_DEFCON.OpenMenu(player)
        return ""
    end

    HandleCommand(player, argument)
    return ""
end)

concommand.Add(C.ConsoleCommand or "grn_defcon", function(player, _, arguments)
    local argument = arguments and arguments[1] or nil
    if IsValid(player) and (argument == nil or argument == "") and C.CommandOpensMenu ~= false then
        GRN_DEFCON.OpenMenu(player)
        return
    end

    HandleCommand(player, argument)
end)

hook.Add("Initialize", "GRN_Defcon_PublishGlobalState", function()
    SetGlobalInt(GLOBAL_LEVEL_KEY, GRN_DEFCON.CurrentLevel or GetDefaultLevel())
end)

hook.Add("PlayerInitialSpawn", "GRN_Defcon_InitialSync", function(player)
    timer.Simple(1, function()
        if IsValid(player) then SendState(player, false, "") end
    end)
end)

net.Receive(NET_REQUEST, function(_, player)
    if IsValid(player) then SendState(player, false, "") end
end)

net.Receive(NET_TERMINAL_ACTION, function(length, player)
    if length > 8192 then return end
    if (player.GRNNextDefconTerminalAction or 0) > CurTime() then return end
    player.GRNNextDefconTerminalAction = CurTime() + 0.20

    if not ValidateTerminalAccess(player) then
        RefreshTerminalForPlayer(player, "You must remain near the DEFCON terminal.", 2)
        return
    end

    local action = net.ReadUInt(2)

    if action == 0 then
        local level = net.ReadUInt(16)
        GRN_DEFCON.CheckChangePermission(player, function(allowed)
            if not IsValid(player) then return end
            if not allowed then
                RefreshTerminalForPlayer(player, "You do not have permission to change DEFCON.", 2)
                return
            end

            local success, message = GRN_DEFCON.SetLevel(level, player)
            RefreshTerminalForPlayer(player, message, success and 1 or 2)
        end)
        return
    end

    if action == 1 then
        local id = net.ReadUInt(16)
        local name = net.ReadString()
        local state = net.ReadString()
        local short = net.ReadString()
        local description = net.ReadString()
        local color = net.ReadString()

        GRN_DEFCON.CheckManagePermission(player, function(allowed)
            if not IsValid(player) then return end
            if not allowed then
                RefreshTerminalForPlayer(player, "You do not have permission to manage levels.", 2)
                return
            end

            id = NormalizeLevelID(id)
            if not id then
                RefreshTerminalForPlayer(player, "The level number is invalid.", 2)
                return
            end

            if BaseLevels[id] then
                RefreshTerminalForPlayer(player, "Base levels must be edited in config.lua.", 2)
                return
            end

            if not CustomLevels[id] and CountCustomLevels() >= math.max(1, tonumber(C.MaximumCustomLevels) or 32) then
                RefreshTerminalForPlayer(player, "The maximum number of custom levels has been reached.", 2)
                return
            end

            local data = NormalizeLevelData(id, {
                Name = name,
                State = state,
                Short = short,
                Description = description,
                Color = color
            }, true)

            if data.Name == "" then
                RefreshTerminalForPlayer(player, "You must enter a name for the level.", 2)
                return
            end

            local updating = CustomLevels[id] ~= nil
            CustomLevels[id] = data
            RebuildLevels()
            SaveCustomLevels()
            SendState(nil, false, "")
            RefreshTerminalForPlayer(player, updating and "Custom level updated." or "Custom level created.", 1)
        end)
        return
    end

    if action == 2 then
        local id = net.ReadUInt(16)
        GRN_DEFCON.CheckManagePermission(player, function(allowed)
            if not IsValid(player) then return end
            if not allowed then
                RefreshTerminalForPlayer(player, "You do not have permission to delete levels.", 2)
                return
            end

            id = NormalizeLevelID(id)
            if not id or not CustomLevels[id] then
                RefreshTerminalForPlayer(player, "That custom level does not exist.", 2)
                return
            end

            CustomLevels[id] = nil
            RebuildLevels()
            SaveCustomLevels()

            if GRN_DEFCON.CurrentLevel == id then
                GRN_DEFCON.CurrentLevel = GetDefaultLevel()
                SetGlobalInt(GLOBAL_LEVEL_KEY, GRN_DEFCON.CurrentLevel)
                SaveLevel(GRN_DEFCON.CurrentLevel)
                SendState(nil, true, GetActorName(player))
            else
                SendState(nil, false, "")
            end

            RefreshTerminalForPlayer(player, "Custom level deleted.", 1)
        end)
    end
end)
