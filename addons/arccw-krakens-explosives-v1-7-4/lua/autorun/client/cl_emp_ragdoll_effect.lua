-- Performance: Ragdoll-Liste nur 4x/s neu suchen statt jeden Frame
local ragCache, ragCacheTime = {}, 0
hook.Add("Think", "EMP_Ragdoll_ElectricFX", function()
    local now = RealTime()
    if now >= ragCacheTime then
        ragCache = ents.FindByClass("prop_ragdoll")
        ragCacheTime = now + 0.25
    end
    for _, rag in ipairs(ragCache) do
        if IsValid(rag) and rag:GetNWBool("Electrified") and math.random() < 0.2 then
            local origin = rag:LocalToWorld(rag:OBBCenter())

            local emitter = ParticleEmitter(origin)

            local spark = EffectData()
            spark:SetOrigin(origin)
            util.Effect("ManhackSparks", spark)

            local sprite = emitter:Add("sprites/glow04_noz", origin + VectorRand() * 5)
            if sprite then
                sprite:SetDieTime(0.15)
                sprite:SetStartAlpha(200)
                sprite:SetEndAlpha(0)
                sprite:SetStartSize(12)
                sprite:SetEndSize(0)
                sprite:SetColor(100, 200, 255)
                sprite:SetRoll(math.Rand(-90, 90))
                sprite:SetLighting(false)
            end

            emitter:Finish()
        end
    end
end)
