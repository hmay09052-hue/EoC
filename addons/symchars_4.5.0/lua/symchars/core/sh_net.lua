--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Netzwerk
    Eine einzige Netzwerknachricht. Daten werden als JSON komprimiert und bei Bedarf in Stuecke geteilt.
-------------------------------------------------------------------------------------------------------------]]

symchars.net = symchars.net or {}

local NET = "symchars.net"
local CHUNK = 60000
local MAX_CLIENT_BYTES = 1500000 -- maximale Groesse einer Nachricht vom Client (komprimiert)

if SERVER then
    util.AddNetworkString(NET)
end

local handlers = symchars.net.handlers or {}
symchars.net.handlers = handlers

local buffers = {}
local nextId = 0

function symchars.net.Json(value) return util.TableToJSON(value) or "{}" end
function symchars.net.Unjson(text) return util.JSONToTable(text or "", false, true) end

local function Encode(action, data)
    local json = util.TableToJSON({ a = action, d = data }) or "{}"
    return util.Compress(json) or ""
end

local function Decode(raw)
    local json = util.Decompress(raw or "")
    if not json or json == "" then return nil end
    -- ignoreConversions: Schlüssel bleiben Strings (SteamID64 würde sonst zur ungenauen Zahl)
    -- Daher gilt: Listen statt Tabellen mit Zahlen-Schlüsseln senden.
    local tbl = util.JSONToTable(json, false, true)
    if not istable(tbl) or not isstring(tbl.a) then return nil end
    return tbl.a, tbl.d
end

local function SendRaw(raw, sendFn)
    nextId = (nextId + 1) % 65535
    local total = math.max(1, math.ceil(#raw / CHUNK))
    for i = 1, total do
        local part = string.sub(raw, (i - 1) * CHUNK + 1, i * CHUNK)
        net.Start(NET)
            net.WriteUInt(nextId, 16)
            net.WriteUInt(i, 16)
            net.WriteUInt(total, 16)
            net.WriteUInt(#part, 32)
            net.WriteData(part, #part)
        sendFn()
    end
end

function symchars.net.Receive(action, fn, cooldown)
    handlers[action] = { fn = fn, cooldown = cooldown or 0 }
end

local function Dispatch(sender, raw)
    local action, data = Decode(raw)
    if not action then return end
    local handler = handlers[action]
    if not handler then return end

    if SERVER then
        if handler.cooldown > 0 then
            sender.symchars_netcd = sender.symchars_netcd or {}
            local last = sender.symchars_netcd[action] or 0
            if last > CurTime() then return end
            sender.symchars_netcd[action] = CurTime() + handler.cooldown
        end

        local ok, err = pcall(handler.fn, sender, data)
        if not ok then
            ErrorNoHaltWithStack("[SymChars] Fehler in Aktion '" .. action .. "': " .. tostring(err) .. "\n")
        end
    else
        local ok, err = pcall(handler.fn, data)
        if not ok then
            ErrorNoHaltWithStack("[SymChars] Fehler in Aktion '" .. action .. "': " .. tostring(err) .. "\n")
        end
    end
end

net.Receive(NET, function(len, ply)
    local id = net.ReadUInt(16)
    local index = net.ReadUInt(16)
    local total = net.ReadUInt(16)
    local size = net.ReadUInt(32)

    if SERVER then
        if not IsValid(ply) then return end
        -- einfache Flutbremse
        local now = CurTime()
        ply.symchars_netwin = ply.symchars_netwin or { t = now, n = 0 }
        if now - ply.symchars_netwin.t > 1 then ply.symchars_netwin.t, ply.symchars_netwin.n = now, 0 end
        ply.symchars_netwin.n = ply.symchars_netwin.n + 1
        if ply.symchars_netwin.n > 60 then return end
        if size > CHUNK or total > math.ceil(MAX_CLIENT_BYTES / CHUNK) then return end
    end

    local data = net.ReadData(size)
    local key = (SERVER and ply:UserID() or 0) .. ":" .. id

    if total == 1 then
        Dispatch(ply, data)
        return
    end

    local buf = buffers[key]
    if not buf or buf.total ~= total then
        buf = { total = total, parts = {}, count = 0, time = CurTime() }
        buffers[key] = buf
    end

    if not buf.parts[index] then
        buf.parts[index] = data
        buf.count = buf.count + 1
    end

    if buf.count >= total then
        buffers[key] = nil
        Dispatch(ply, table.concat(buf.parts))
    end
end)

timer.Create("symchars_net_cleanup", 30, 0, function()
    local now = CurTime()
    for key, buf in pairs(buffers) do
        if now - buf.time > 60 then buffers[key] = nil end
    end
end)

if SERVER then
    -- target: Spieler, Liste von Spielern oder nil (an alle)
    function symchars.net.Send(action, data, target)
        if istable(target) and #target == 0 then return end
        local raw = Encode(action, data)
        SendRaw(raw, function()
            if target == nil then
                net.Broadcast()
            else
                net.Send(target)
            end
        end)
    end

    -- typ: "info" | "succ" | "error"
    function symchars.Notify(ply, text, typ, len)
        if not istable(ply) and not IsValid(ply) then return end
        symchars.net.Send("notify", { t = tostring(text or ""), k = typ or "info", l = len }, ply)
    end

    function symchars.NotifyAll(text, typ, len)
        symchars.net.Send("notify", { t = tostring(text or ""), k = typ or "info", l = len })
    end
else
    function symchars.net.SendToServer(action, data)
        local raw = Encode(action, data)
        SendRaw(raw, function() net.SendToServer() end)
    end
end
