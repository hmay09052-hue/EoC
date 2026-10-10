local ORDERS_PATH = "krakensquad/orders.json"
local ML  = KrakenSquad.MAX_LENGTHS
local Net = KrakenSquad.Net

local nextOrderID = 1

local function CountActive()
    local n = 0
    for _ in pairs(KrakenSquad.ActiveOrders) do n = n + 1 end
    return n
end

local function QueueSave()
    timer.Create("KS.OrdersSave", 5, 1, function()
        local data = {}
        for _, o in pairs(KrakenSquad.ActiveOrders) do
            if o.permanent and o.status ~= "succeeded" and o.status ~= "failed" then
                data[#data + 1] = o
            end
        end
        file.Write(ORDERS_PATH, util.TableToJSON(data, true))
    end)
end

local function ResolveTargetSquad(id, name)
    if id then
        local s = KrakenSquad.GetSquad(id)
        if s then return s end
    end
    if name and name ~= "" then
        for _, s in pairs(KrakenSquad.Cache) do
            if s:GetTitle() == name then return s end
        end
    end
end

local function OrderTargetsPlayer(order, ply)
    if not (order.targetSquadID or (order.targetSquadName and order.targetSquadName ~= "")) then
        return true
    end
    local squad = ply:GetKSSquad()
    if not squad then return false end
    return (order.targetSquadID and squad:GetID() == order.targetSquadID)
        or (order.targetSquadName and squad:GetTitle() == order.targetSquadName)
end

function KrakenSquad.SyncOrdersTo(ply)
    if not IsValid(ply) then return end
    local data = {}
    local showAll = KrakenSquad.GetConfig("ordersViewAll")
    for _, o in pairs(KrakenSquad.ActiveOrders) do
        if (o.permanent or o.expire > CurTime())
           and (showAll or (KrakenSquad.PlayerMatchesFilters(ply, o.filters) and OrderTargetsPlayer(o, ply))) then
            data[#data + 1] = o
        end
    end
    KF.Net.SendJSON("KS.OrderSync", data, ply)
end

local function BroadcastOrders()
    timer.Create("KS.OrdersBroadcast", 0.2, 1, function()
        for _, ply in ipairs(player.GetAll()) do KrakenSquad.SyncOrdersTo(ply) end
    end)
end

if file.Exists(ORDERS_PATH, "DATA") then
    local data = util.JSONToTable(file.Read(ORDERS_PATH, "DATA"))
    if data then
        local maxID = 0
        for _, o in ipairs(data) do
            if o.id and o.permanent and o.status ~= "succeeded" and o.status ~= "failed" then
                KrakenSquad.ActiveOrders[o.id] = o
                if o.id > maxID then maxID = o.id end
            end
        end
        nextOrderID = maxID + 1
    end
end

local function SanitizeObjectives(input, dst)
    for i = 1, math.min(#input, ML.maxObjectives) do
        local obj = input[i]
        local prio = obj.priority
        if prio ~= "main" and prio ~= "secondary" then prio = "main" end
        dst[#dst + 1] = {
            text     = (obj.text or ""):Trim():sub(1, ML.objectiveText),
            priority = prio,
            done     = obj.done or false,
        }
    end
end

local function ResolveTarget(data)
    local id   = tonumber(data.targetSquadID)
    if id then id = math.floor(id) end
    local name = tostring(data.targetSquadName or ""):Trim():sub(1, ML.squadName)
    local squad = ResolveTargetSquad(id, name)
    if squad then return squad:GetID(), squad:GetTitle() end
    return nil, ""
end

function KrakenSquad.CreateOrder(data, issuer)
    local id = nextOrderID
    nextOrderID = nextOrderID + 1
    local isPermanent = data.permanent == true
    local targetID, targetName = ResolveTarget(data)

    local order = {
        id              = id,
        title           = (data.title or ""):Trim():sub(1, ML.orderTitle),
        description     = (data.description or ""):Trim():sub(1, ML.orderDescription),
        duration        = isPermanent and 0 or math.Clamp(tonumber(data.duration) or 300, 30, 7200),
        permanent       = isPermanent,
        objectives      = {},
        filters         = data.filters or {},
        targetSquadID   = targetID,
        targetSquadName = targetName,
        issuer          = IsValid(issuer) and issuer:Nick() or KrakenSquad.L("order_fallback_issuer"),
        issuerSID       = IsValid(issuer) and issuer:SteamID64() or nil,
        created         = CurTime(),
    }
    order.expire = isPermanent and 0 or (CurTime() + order.duration)
    if data.objectives then SanitizeObjectives(data.objectives, order.objectives) end

    KrakenSquad.ActiveOrders[id] = order
    QueueSave()
    BroadcastOrders()
    return order
end

function KrakenSquad.DeleteOrder(id)
    KrakenSquad.ActiveOrders[id] = nil
    QueueSave()
    BroadcastOrders()
end

function KrakenSquad.EditOrder(id, data)
    local o = KrakenSquad.ActiveOrders[id]
    if not o then return end

    if data.title       then o.title       = data.title:Trim():sub(1, ML.orderTitle) end
    if data.description then o.description = data.description:Trim():sub(1, ML.orderDescription) end
    if data.duration    then
        o.duration = math.Clamp(tonumber(data.duration) or 300, 30, 7200)
        o.expire   = CurTime() + o.duration
    end
    if data.permanent ~= nil then
        o.permanent = data.permanent
        o.expire    = o.permanent and 0 or (CurTime() + (o.duration or 300))
    end
    if data.objectives then
        o.objectives = {}
        SanitizeObjectives(data.objectives, o.objectives)
    end
    if data.targetSquadID ~= nil or data.targetSquadName ~= nil then
        o.targetSquadID, o.targetSquadName = ResolveTarget(data)
    end

    QueueSave()
    BroadcastOrders()
    KF.Net.Send("KS.OrderStatusNotify", function()
        net.WriteUInt(id, 32)
        net.WriteString("updated")
        net.WriteString(o.title or "")
    end, player.GetAll())
    return o
end

function KrakenSquad.SetOrderStatus(id, status)
    local o = KrakenSquad.ActiveOrders[id]
    if not o then return end
    o.status = status
    KF.Net.Send("KS.OrderStatusNotify", function()
        net.WriteUInt(id, 32)
        net.WriteString(status)
        net.WriteString(o.title or "")
    end, player.GetAll())
    if status == "succeeded" or status == "failed" then
        KrakenSquad.ActiveOrders[id] = nil
    end
    QueueSave()
    BroadcastOrders()
end

timer.Create("KS.OrderCleanup", 30, 0, function()
    local changed = false
    for id, o in pairs(KrakenSquad.ActiveOrders) do
        if not o.permanent and o.expire <= CurTime() then
            KrakenSquad.ActiveOrders[id] = nil
            changed = true
        end
    end
    if changed then QueueSave(); BroadcastOrders() end
end)

Net.Receive("KS.OrderCreate", function(_, ply)
    local isTerminal = net.ReadBool()
    if isTerminal then
        if not KrakenSquad.IsNearTerminal(ply) then return end
    elseif not KrakenSquad.IsAdmin(ply) then return end

    local data = KF.Net.ReadJSON(16384)
    if not data or not data.title or #data.title < 1 then return end
    if CountActive() >= ML.maxOrders then return end
    KrakenSquad.CreateOrder(data, ply)
end, { rateKey = "order_create" })

Net.Receive("KS.OrderDelete", function(_, ply)
    KrakenSquad.DeleteOrder(net.ReadUInt(32))
end, { admin = true })

Net.Receive("KS.OrderEdit", function(_, ply)
    local isTerminal = net.ReadBool()
    local id   = net.ReadUInt(32)
    local data = KF.Net.ReadJSON(16384)
    if not data then return end
    if isTerminal then
        if not KrakenSquad.IsNearTerminal(ply) then return end
    elseif not KrakenSquad.IsAdmin(ply) then return end

    local o = KrakenSquad.ActiveOrders[id]
    if not o then return end
    if not KrakenSquad.IsAdmin(ply) and o.issuerSID ~= ply:SteamID64() then return end
    KrakenSquad.EditOrder(id, data)
end, { rateKey = "order_edit" })

Net.Receive("KS.OrderStatus", function(_, ply)
    local id     = net.ReadUInt(32)
    local status = net.ReadString()
    if status ~= "succeeded" and status ~= "failed" and status ~= "active" then return end
    KrakenSquad.SetOrderStatus(id, status)
end, { admin = true })

Net.Receive("KS.NPCTerminal", function(_, ply) KrakenSquad.SyncOrdersTo(ply) end)

Net.Receive("KS.OrderPresetSave", function(_, ply)
    local preset = KF.Net.ReadJSON(8192)
    if not preset or not preset.name then return end
    preset.name = preset.name:Trim():sub(1, ML.orderPresetName)
    if preset.name == "" then return end

    local presets = KrakenSquad.GetConfig("orderPresets") or {}
    for i, p in ipairs(presets) do
        if p.name == preset.name then
            presets[i] = preset
            KrakenSquad.SetConfig("orderPresets", presets)
            KrakenSquad.SaveConfig()
            KrakenSquad.SyncConfigToAll()
            return
        end
    end
    table.insert(presets, preset)
    KrakenSquad.SetConfig("orderPresets", presets)
    KrakenSquad.SaveConfig()
    KrakenSquad.SyncConfigToAll()
end, { admin = true, rateKey = "admin" })

Net.Receive("KS.OrderPresetDelete", function(_, ply)
    local idx = net.ReadUInt(16)
    local presets = KrakenSquad.GetConfig("orderPresets") or {}
    if not presets[idx] then return end
    table.remove(presets, idx)
    KrakenSquad.SetConfig("orderPresets", presets)
    KrakenSquad.SaveConfig()
    KrakenSquad.SyncConfigToAll()
end, { admin = true })

