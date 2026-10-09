local healingIntensity = 0
local bactaCache, bactaCacheTime = {}, 0

hook.Add("Think", "BactaHealingCheck", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then 
        healingIntensity = math.max(0, healingIntensity - FrameTime() * 2)
        return 
    end
    
    local inHealZone = false
    local closestDist = math.huge
    
    -- Performance: Bacta-Granaten nur 5x/s suchen statt jeden Frame
    local now = RealTime()
    if now >= bactaCacheTime then
        bactaCache = ents.FindByClass("arccw_nade_k_thrown_bacta")
        bactaCacheTime = now + 0.2
    end
    local plyPos = ply:GetPos()
    for _, ent in ipairs(bactaCache) do
        if IsValid(ent) and ent:GetNWBool("IsDetonated", false) then
            local dist = plyPos:Distance(ent:GetPos())
            if dist < 300 then
                inHealZone = true
                closestDist = math.min(closestDist, dist)
            end
        end
    end
    
    local dt = FrameTime()
    
    if inHealZone then
        local distFactor = 1 - (closestDist / 300)
        healingIntensity = Lerp(dt * 3, healingIntensity, distFactor * 0.7)
    else
        healingIntensity = math.max(0, healingIntensity - dt * 1.5)
    end
end)
