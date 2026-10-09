local toxicInGas = false
local lastDSPSet = 0
local dspActive = false

-- Performance: Gasfelder nur 5x/s suchen statt in jedem Frame (zweimal) ents.FindByClass
local gasCache, gasCacheTime = {}, 0
local function GetGasFields()
    local now = RealTime()
    if now >= gasCacheTime then
        gasCache = ents.FindByClass("arccw_ent_gas_field")
        gasCacheTime = now + 0.2
    end
    return gasCache
end

hook.Add("RenderScreenspaceEffects", "GasBlurEffect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local nearestGas = nil
    local minDistSqr = math.huge

    local plyPos = ply:GetPos()
    for _, ent in ipairs(GetGasFields()) do
        local distSqr = IsValid(ent) and plyPos:DistToSqr(ent:GetPos()) or math.huge
        if distSqr < minDistSqr then
            minDistSqr = distSqr
            nearestGas = ent
        end
    end

    if nearestGas and minDistSqr <= 480 * 480 then
        local factor = 1 - (math.sqrt(minDistSqr) / 480)
        DrawMotionBlur(0.1 * factor, 0.85 * factor, 0.01)
        DrawColorModify({
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0.02 * factor,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = -0.1 * factor,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1 - (0.5 * factor),
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        })
    end
end)


hook.Add("Think", "ToxicGasPlayerCheck", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local inGas = false

    local plyPos = ply:GetPos()
    for _, ent in ipairs(GetGasFields()) do
        if IsValid(ent) and plyPos:DistToSqr(ent:GetPos()) <= (ent.Radius or 600) ^ 2 then
            inGas = true
            break
        end
    end

    toxicInGas = inGas

    if toxicInGas then
        if CurTime() - lastDSPSet > 1.5 then
            ply:ConCommand("dsp_room 1")
            lastDSPSet = CurTime()
            dspActive = true
        end
    elseif dspActive then
        -- Performance: nur einmal zurücksetzen statt jeden Frame einen Konsolenbefehl auszuführen
        ply:ConCommand("dsp_room 0")
        dspActive = false
    end
end)
