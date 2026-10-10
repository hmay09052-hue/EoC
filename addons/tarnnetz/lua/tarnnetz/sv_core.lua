Tarnnetz = Tarnnetz or {}

local C = Tarnnetz.Config
local L = C.Lang

util.AddNetworkString('tarnnetz_open')
util.AddNetworkString('tarnnetz_select')
util.AddNetworkString('tarnnetz_notify')
util.AddNetworkString('tarnnetz_chat')

-- Spieler mit aktiver Tarnung -> { mat, oldMat, hadNoTarget, paused }
Tarnnetz.Active = Tarnnetz.Active or {}

local SND_ON    = 'buttons/combine_button1.wav'
local SND_OFF   = 'buttons/combine_button2.wav'
local SND_BREAK = 'ambient/energy/zap1.wav'

function Tarnnetz.Notify(ply, msg, kind)
    net.Start('tarnnetz_notify')
        net.WriteString(msg)
        net.WriteUInt(kind or 0, 2) -- 0 = Info, 1 = Erfolg, 2 = Warnung
    net.Send(ply)
end

local function SetCooldown(ply, seconds)
    if seconds and seconds > 0 then
        ply:SetNWFloat('Tarnnetz.Cooldown', CurTime() + seconds)
    end
end

local function CanActivate(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    if Tarnnetz.IsActive(ply) then return false, L.alreadyOn end

    local left = Tarnnetz.CooldownLeft(ply)
    if left > 0 then return false, string.format(L.cooldown, math.ceil(left)) end

    if not ply:HasWeapon(C.WeaponClass) then return false end
    if Tarnnetz.NearestDroid(ply, C.Radius) then return false, L.tooClose end

    return true
end

function Tarnnetz.OpenMenu(ply)
    local ok, err = CanActivate(ply)
    if not ok then
        if err then Tarnnetz.Notify(ply, err, 2) end
        return
    end

    net.Start('tarnnetz_open')
    net.Send(ply)
end

function Tarnnetz.Activate(ply, index)
    local camo = C.Camos[index]
    if not camo then return end

    local ok, err = CanActivate(ply)
    if not ok then
        if err then Tarnnetz.Notify(ply, err, 2) end
        return
    end

    Tarnnetz.Active[ply] = {
        mat = camo.mat,
        oldMat = ply:GetMaterial(),
        hadNoTarget = ply:IsFlagSet(FL_NOTARGET),
        paused = false,
    }

    ply:SetMaterial(camo.mat)
    ply:SetNoTarget(true)
    ply:SetNWBool('Tarnnetz.Active', true)
    ply:SetNWBool('Tarnnetz.Paused', false)
    ply:SetNWInt('Tarnnetz.Camo', index)

    ply:EmitSound(SND_ON, 60, 110)
    Tarnnetz.Notify(ply, string.format(L.activated, camo.name, Tarnnetz.Meters(C.Radius)), 1)

    if C.ChatMessage then
        local recipients = player.GetHumans()
        if (C.ChatRange or 0) > 0 then
            local pos, rangeSqr = ply:GetPos(), C.ChatRange * C.ChatRange
            recipients = {}
            for _, p in ipairs(player.GetHumans()) do
                if p:GetPos():DistToSqr(pos) <= rangeSqr then recipients[#recipients + 1] = p end
            end
        end
        net.Start('tarnnetz_chat')
            net.WriteEntity(ply)
        net.Send(recipients)
    end

    hook.Run('Tarnnetz.Activated', ply, index)
end

-- reason: 'manual', 'detected' oder 'silent' (Tod, Respawn, Jobwechsel ...)
function Tarnnetz.Deactivate(ply, reason)
    local data = Tarnnetz.Active[ply]
    Tarnnetz.Active[ply] = nil
    if not data or not IsValid(ply) then return end

    -- Material nur zurücksetzen, wenn es noch unser Tarnmuster ist
    if ply:GetMaterial() == data.mat then
        ply:SetMaterial(data.oldMat or '')
    end
    -- NoTarget nur entfernen, wenn der Spieler es vorher nicht schon hatte (z.B. vom Admin-Tool)
    if not data.hadNoTarget then
        ply:SetNoTarget(false)
    end

    ply:SetNWBool('Tarnnetz.Active', false)
    ply:SetNWBool('Tarnnetz.Paused', false)
    ply:SetNWInt('Tarnnetz.Camo', 0)

    if reason == 'detected' then
        SetCooldown(ply, C.Cooldown)
        ply:EmitSound(SND_BREAK, 70, 100)
        Tarnnetz.Notify(ply, L.detected, 2)
    elseif reason == 'manual' then
        SetCooldown(ply, C.ManualCooldown)
        ply:EmitSound(SND_OFF, 60, 100)
        Tarnnetz.Notify(ply, L.deactivated, 0)
    end

    hook.Run('Tarnnetz.Deactivated', ply, reason)
end

---------------------------------------------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------------------------------------------
net.Receive('tarnnetz_select', function(_, ply)
    if (ply._tarnnetzNext or 0) > CurTime() then return end
    ply._tarnnetzNext = CurTime() + 0.5

    Tarnnetz.Activate(ply, net.ReadUInt(8))
end)

---------------------------------------------------------------------------------------------------------------
-- Droiden-Nähe prüfen
---------------------------------------------------------------------------------------------------------------
timer.Create('Tarnnetz.ProximityCheck', C.CheckInterval, 0, function()
    for ply, data in pairs(Tarnnetz.Active) do
        if not IsValid(ply) then
            Tarnnetz.Active[ply] = nil
        elseif not ply:Alive() then
            Tarnnetz.Deactivate(ply, 'silent')
        else
            local near = Tarnnetz.NearestDroid(ply, C.Radius) ~= nil

            if C.ProximityMode == 'pause' then
                if near and not data.paused then
                    data.paused = true
                    if not data.hadNoTarget then ply:SetNoTarget(false) end
                    ply:SetNWBool('Tarnnetz.Paused', true)
                    ply:EmitSound(SND_BREAK, 60, 120)
                    Tarnnetz.Notify(ply, L.paused, 2)
                elseif not near and data.paused then
                    data.paused = false
                    ply:SetNoTarget(true)
                    ply:SetNWBool('Tarnnetz.Paused', false)
                    Tarnnetz.Notify(ply, L.resumed, 1)
                end
            elseif near then
                Tarnnetz.Deactivate(ply, 'detected')
            end
        end
    end
end)

---------------------------------------------------------------------------------------------------------------
-- Aufräumen
---------------------------------------------------------------------------------------------------------------
local function Silent(ply) Tarnnetz.Deactivate(ply, 'silent') end

hook.Add('PlayerDeath', 'Tarnnetz.Reset', Silent)
hook.Add('PlayerSilentDeath', 'Tarnnetz.Reset', Silent)
hook.Add('PlayerSpawn', 'Tarnnetz.Reset', Silent)
hook.Add('PlayerDisconnected', 'Tarnnetz.Reset', Silent)
hook.Add('OnPlayerChangedTeam', 'Tarnnetz.Reset', Silent)
