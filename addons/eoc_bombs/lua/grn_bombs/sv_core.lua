util.AddNetworkString('grn_bombs_open_menu')
util.AddNetworkString('grn_bombs_sync')
util.AddNetworkString('grn_bombs_save')
util.AddNetworkString('grn_bombs_delete')
util.AddNetworkString('grn_bombs_spawn')
util.AddNetworkString('grn_bombs_open_minigame')
util.AddNetworkString('grn_bombs_minigame_result')
util.AddNetworkString('grn_bombs_notify')

GRN_Bombs = GRN_Bombs or {}
GRN_Bombs.Stored = GRN_Bombs.Stored or {}

local function ensureDataDir()
    if not file.IsDir('grn_bombs', 'DATA') then file.CreateDir('grn_bombs') end
end

local function sanitizeBomb(data, existingId)
    if not istable(data) then return nil end
    local id = tonumber(existingId or data.id or 0) or 0
    local bomb = {
        id = id,
        name = tostring(data.name or ''):sub(1, 64),
        category = tostring(data.category or 'General'):sub(1, 32),
        type = tostring(data.type or 'explosive'),
        model = tostring(data.model or 'models/props_c17/oildrum001a.mdl'):sub(1, 260),
        minigame = tostring(data.minigame or 'wirecutting'),
        difficulty = tostring(data.difficulty or 'medium'),
        timer = math.Clamp(tonumber(data.timer) or 60, 5, 600),
        codeValue = tostring(data.codeValue or '7342'):gsub('[^%d]', ''):sub(1, 12),
        codeHint = tostring(data.codeHint or ''):sub(1, 64),
        radius = math.Clamp(tonumber(data.radius) or 300, 10, 5000),
        damage = math.Clamp(tonumber(data.damage) or 500, 0, 999999),
        force = math.Clamp(tonumber(data.force) or 800, 0, 999999),
        effects = {},
        particles = tostring(data.particles or 'none'),
        particleCount = math.Clamp(tonumber(data.particleCount) or 5, 1, 50),
        rewardMoney = tobool(data.rewardMoney),
        moneyAmt = math.Clamp(tonumber(data.moneyAmt) or 0, 0, 100000000),
        moneyNotify = tostring(data.moneyNotify or 'chat'),
        reqWeapon = tobool(data.reqWeapon),
        weaponClass = tostring(data.weaponClass or ''):sub(1, 64),
        weaponMsg = tostring(data.weaponMsg or ''):sub(1, 128),
        visible = data.visible == nil and true or tobool(data.visible),
        beep = data.beep == nil and true or tobool(data.beep),
        glow = tobool(data.glow),
    }
    if bomb.name == '' then return nil end
    if bomb.codeValue == '' then bomb.codeValue = '7342' end
    if bomb.category == '' then bomb.category = 'General' end
    if bomb.type ~= 'explosive' and bomb.type ~= 'training' and bomb.type ~= 'gas' then bomb.type = 'explosive' end
    local allowedMinigames = {wirecutting=true, code=true, sequence=true, hackpad=true, timer=true, lockpick=true, buttons=true, custom=true}
    if not allowedMinigames[bomb.minigame] then bomb.minigame = 'wirecutting' end
    if not util.IsValidModel(bomb.model) then bomb.model = 'models/props_c17/oildrum001a.mdl' end
    if istable(data.effects) then
        for _, effect in ipairs(data.effects) do
            effect = tostring(effect):sub(1, 64)
            if effect ~= '' then table.insert(bomb.effects, effect) end
        end
    end
    return bomb
end

function GRN_Bombs.SaveData()
    ensureDataDir()
    file.Write(GRN_Bombs.Config.DataFile, util.TableToJSON(GRN_Bombs.Stored, true))
end

function GRN_Bombs.LoadData()
    ensureDataDir()
    if not file.Exists(GRN_Bombs.Config.DataFile, 'DATA') then
        GRN_Bombs.Stored = table.Copy(GRN_Bombs.Config.DefaultTemplates or {})
        GRN_Bombs.SaveData()
        return
    end
    local raw = file.Read(GRN_Bombs.Config.DataFile, 'DATA') or '[]'
    local parsed = util.JSONToTable(raw)
    if not istable(parsed) then
        GRN_Bombs.Stored = table.Copy(GRN_Bombs.Config.DefaultTemplates or {})
        GRN_Bombs.SaveData()
        return
    end
    GRN_Bombs.Stored = {}
    for _, entry in ipairs(parsed) do
        local bomb = sanitizeBomb(entry)
        if bomb then table.insert(GRN_Bombs.Stored, bomb) end
    end
end

function GRN_Bombs.GetNextId()
    local max = 0
    for _, bomb in ipairs(GRN_Bombs.Stored) do
        max = math.max(max, tonumber(bomb.id) or 0)
    end
    return max + 1
end

function GRN_Bombs.FindBomb(id)
    id = tonumber(id)
    for index, bomb in ipairs(GRN_Bombs.Stored) do
        if tonumber(bomb.id) == id then return bomb, index end
    end
end

function GRN_Bombs.SyncMenu(ply, focusId)
    net.Start('grn_bombs_sync')
        net.WriteTable(GRN_Bombs.Stored)
        net.WriteUInt(tonumber(focusId or 0), 16)
    net.Send(ply)
end

local function resolvePhrase(msgKey, ...)
    local lang = (GRN_Bombs.Config and GRN_Bombs.Config.DefaultLanguage) or 'en'
    if isfunction(GRN_Bombs.GetPhrase) then
        return GRN_Bombs.GetPhrase(msgKey, lang, ...)
    end

    local phrases = GRN_Bombs.Phrases or {}
    local tbl = phrases[lang] or phrases.en or {}
    local en = phrases.en or {}
    local phrase = tbl[msgKey] or en[msgKey] or tostring(msgKey or '')
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, phrase, ...)
        if ok then return formatted end
    end
    return phrase
end

function GRN_Bombs.Notify(ply, msgKey, ...)
    if not IsValid(ply) then return end
    net.Start('grn_bombs_notify')
        net.WriteString(resolvePhrase(msgKey, ...))
    net.Send(ply)
end

function GRN_Bombs.OpenMenu(ply)
    if not GRN_Bombs.HasAccess(ply) then
        GRN_Bombs.Notify(ply, 'no_access')
        return
    end
    net.Start('grn_bombs_open_menu')
    net.Send(ply)
    timer.Simple(0.1, function()
        if IsValid(ply) then GRN_Bombs.SyncMenu(ply) end
    end)
end

local function handleChatCommand(ply, text)
    local msg = string.Trim(string.lower(text or ''))
    for _, cmd in ipairs(GRN_Bombs.Config.ChatCommands) do
        if msg == string.lower(cmd) then
            GRN_Bombs.OpenMenu(ply)
            return ''
        end
    end
end
hook.Add('PlayerSay', 'grn_bombs_chat_commands', handleChatCommand)

hook.Add('Initialize', 'grn_bombs_init_load', function()
    GRN_Bombs.LoadData()
end)

net.Receive('grn_bombs_save', function(_, ply)
    if not GRN_Bombs.HasAccess(ply) then return end
    local payload = net.ReadTable()
    local requestedId = tonumber(payload.id)
    local bomb = sanitizeBomb(payload, requestedId)
    if not bomb then
        GRN_Bombs.Notify(ply, 'invalid')
        return
    end
    local _, index = GRN_Bombs.FindBomb(requestedId)
    if index then
        bomb.id = requestedId
        GRN_Bombs.Stored[index] = bomb
    else
        bomb.id = GRN_Bombs.GetNextId()
        table.insert(GRN_Bombs.Stored, bomb)
    end
    GRN_Bombs.SaveData()
    GRN_Bombs.SyncMenu(ply, bomb.id)
    GRN_Bombs.Notify(ply, 'saved')
end)

net.Receive('grn_bombs_delete', function(_, ply)
    if not GRN_Bombs.HasAccess(ply) then return end
    local id = net.ReadUInt(16)
    local _, index = GRN_Bombs.FindBomb(id)
    if not index then
        GRN_Bombs.Notify(ply, 'missing')
        return
    end
    table.remove(GRN_Bombs.Stored, index)
    GRN_Bombs.SaveData()
    GRN_Bombs.SyncMenu(ply)
    GRN_Bombs.Notify(ply, 'deleted')
end)

net.Receive('grn_bombs_spawn', function(_, ply)
    if not GRN_Bombs.HasAccess(ply) then return end
    local id = net.ReadUInt(16)
    local bomb = GRN_Bombs.FindBomb(id)
    if not bomb then
        GRN_Bombs.Notify(ply, 'missing')
        return
    end
    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end
    local pos = tr.HitPos + tr.HitNormal * 12
    if pos:Distance(ply:GetShootPos()) > GRN_Bombs.Config.SpawnDistance * 10 then
        pos = ply:GetShootPos() + ply:GetAimVector() * GRN_Bombs.Config.SpawnDistance
    end
    local ent = ents.Create(GRN_Bombs.Config.EntityClass)
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    ent:Spawn()
    ent:Activate()
    ent:SetBombData(table.Copy(bomb), ply)
    undo.Create('grn_bombs')
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
    undo.Finish('grn_bombs')
    GRN_Bombs.Notify(ply, 'spawned')
end)

net.Receive('grn_bombs_minigame_result', function(_, ply)
    local ent = net.ReadEntity()
    local success = net.ReadBool()
    if not IsValid(ent) or ent:GetClass() ~= GRN_Bombs.Config.EntityClass then return end
    ent:ReceiveMinigameResult(ply, success)
end)

function GRN_Bombs.OpenMinigame(ply, ent, bombData)
    net.Start('grn_bombs_open_minigame')
        net.WriteEntity(ent)
        net.WriteTable(bombData)
    net.Send(ply)
end
